# pCryoxy PC-06 首轮审核裁定（3cf459d）

- 审核方：workbuddy @ zhn-tbxg2iah-win~zhn-x-w，2026-11-23 11:10 UTC+8
- 被审：copilot，分支 `agent/copilot/pc06`，项目提交 `3cf459d6cc9955eb7a00b2ac845eda38b7cc57b3`（基座 main `1b1ae3d`）；认领 `6daa2e8`，交付 `0b82eb0`
- 卡面：实施任务卡 v1.1 §PC-06（v1.2 “同 v1.1”）；API-Spec v1.2 §2、§canonical 行（第 300 行）
- **裁定：不通过，退回返工。PC-06 保持 doing，不合并、不推送。**

## 1. 独立复跑（git archive 到 `~/.agent-tools/run/review/pc06-r1/`，独立 target）

| 项 | 结果 |
|---|---|
| `cargo fmt --check` | 0 |
| `cargo clippy -p protocol-parser --all-targets --locked --offline -D warnings` | 0 |
| `cargo test -p protocol-parser --locked --offline` | 0，9/0/0（首次 25 min 超时停在 aws-lc-sys 的 cl.exe，`-vv` 重跑 1m11s 通过，未复现，不计入 PC-06） |
| `cargo tree`（Windows / aarch64-linux-android / x86_64-unknown-linux-gnu） | 0 / 0 / 0（Android、Linux 需先补 8 个包，见 F-B1） |
| `cargo check -p protocol-parser --target aarch64-linux-android` | 0（需 NDK 29 clang：`CC_aarch64_linux_android`） |
| `cargo check -p protocol-parser --target x86_64-unknown-linux-gnu`（WSL，Rust 1.100 Linux + zig 0.16 cc，全部位于 `/mnt/c` 审核目录，无家目录副本） | 0，1m42s |
| workspace clippy / workspace test | **未独立完成**（clippy 在 tauri 依赖处被工具 38 min 截断）；下轮复核补跑 |
| Cargo.lock | 全程 sha256 不变 |

## 2. 审核探针（`probe.rs`，10/10 复现，断言失败即发现成立）

| # | 输入 | 实测 | 定性 |
|---|---|---|---|
| P1 | `vless://u@[2001:db8::1]:443?...` | `InvalidField("endpoint")` | **阻断**：IPv6 字面量真实格式无法导入（卡面“规范化域名/IP”、“真实格式覆盖协议矩阵”） |
| P2 | `path=%2Fws%2F` | 存为 `/ws` | **阻断**：`normalize_path_name`（validate.rs:870-895）改写了**线上 path 本身**（去尾斜杠、并 `//`、解析 `..`），生成配置将访问错误路径。规范化只能作用于指纹键，存储值须保持原样（API-Spec：保持 path 大小写，未授权其他改写） |
| P3 | `/ws` 与 `/ws/` 两节点 | 合并为 1 | **阻断**：同 P2，不同服务端路径被误去重 |
| P4 | `type=ws&security=none&host=cdn.example` | 接受，Host 头丢失 | **阻断**：语义静默丢弃 |
| P5 | vmess `net=tcp,type=http,host=...` | 接受，HTTP 伪装头丢失 | **阻断**：语义静默丢弃 |
| P6 | `type=ws&ed=2048` | 接受，`max_early_data=0` | **阻断**：IR 有该字段却未映射 |
| P7 | 同一 UUID 大小写不同 | 2 个节点 | **须修**：UUID 型凭据（vless/vmess id）staging 前应小写规范化，否则同节点重复 |
| P8 | vmess grpc `type=multi` | `multi_mode=false` | **阻断**：IR 有该字段却未映射 |
| P9 | 同批两条同八字段、flow 不同 | `ParseError::Validation`（无行号、无码） | **阻断**：卡面要求“返回 FingerprintConflict”“坏条目返回行号/错误码”；API-Spec ErrorCode 有 `fingerprint_conflict`。现有测试 `same_fingerprint_with_different_semantics_is_rejected_without_leak` 断言的正是 `Validation`，测试与卡面不符 |
| P10 | `wireguard://<priv>@host:51820?publickey=..&address=..&mtu=..` | `unsupported_capability`（显式拒绝） | **不阻断，转人类／PC-02**：IR `WireGuardOptions` 只有 `peers`、`reserved`，无对端公钥、本地地址、MTU，PC-06 无法在不改契约下支持；显式拒绝而非静默是正确行为。是否扩 IR 由人类裁定 |

静默丢弃（P4/P5/P6/P8）的统一要求：**每个已识别但 IR 无法表达的参数必须返回 `unsupported_capability`（带行号），IR 能表达的必须映射**；不得接受后丢弃。请按协议逐项列出“已映射／显式拒绝”的参数清单随交付提交。

## 3. 其他阻断项

- **F-A1 依赖未走申请**：实施任务卡 v1.1 第 94 行要求“各卡新增依赖先提出申请，所有者串行修改并给出依赖 commit”。本提交直接改 `crates/protocol-parser/Cargo.toml` 与根 `Cargo.lock`（449→494 包，+45），引入 `reqwest 0.13.5 + rustls` → `aws-lc-rs 1.19 / aws-lc-sys 0.47`（约 9.7 MB C 源码）、`ring 0.17.14`、`quinn` 等，无申请、无审计。须补依赖申请（理由、许可、三平台构建影响、替代方案比较：如 rustls `ring` provider／`rustls-no-provider`、是否需要 HTTP/3），经批准后由 PC-00 所有者给出独立依赖 commit，PC-06 rebase 其上。
- **F-B1 “locked offline check 通过”只覆盖 Windows**：Android 缺 `jni 0.22.4`、`jni-macros`、`simd_cesu8`、`simdutf8`、`rustls-platform-verifier-android 0.2.0`；Linux 缺 `openssl-probe 0.2.2`、`rustls-native-certs 0.8.5`、`schannel 0.1.30`。审核方已于 11:00 经人类授权用本机代理补入 `~/.agent-tools/runtimes/rust/cargo` 缓存（lock 未变）。返工交付须给出三平台 `--offline` 证据，并在 BUILD.md 写明 aws-lc-sys 对 NDK clang／Linux C 编译器（zig 须映射 `--target=` 三元组）的要求。
- **F-C1 嵌套拒绝无证据**：卡面“嵌套从 UI、文件或订阅入口均拒绝”，parser 源码与测试无任何 nested/`NestedGroupNotSupported` 覆盖。至少补：文件／订阅入口携带组定义时的拒绝测试，或书面说明 parser 入口不可能产生组并指向拒绝点的测试。
- **F-D1 登记未改状态**：认领 `6daa2e8` 只追加事件行，`memory/projects/pCryoxy.md` 第 30 行任务表仍为 `todo`；请改为 `doing`（认领者 copilot）。

## 4. 已确认通过（返工不得回退）

七协议主路径解析；名称不参与指纹；REALITY 与 WS+TLS、分隔符注入不碰撞（`delimiter_injection_and_transport_security_changes_do_not_collide`）；重复查询键在 staging 前拒绝；Atomic 坏条目给行号且零 staging；ValidOnly 须显式选择、取消清理 staging；整订阅 base64 先解码；HTTP 刷新成功只合并、失败不丢原节点；错误投影不含 URL；Zeroizing 与 `delete_staged` 回滚路径。

## 5. 返工清单（下轮复核逐条验）

1. P1、P2/P3、P4、P5、P6、P7、P8、P9 修复，并把本裁定 `probe.rs` 的 P1–P9 断言（P9 改为断言 `fingerprint_conflict` + 行号）纳入 `tests/`；P10 保持显式拒绝并加测试。
2. 参数映射／拒绝清单（§2 末）。
3. F-A1 依赖申请 → 批准 → 依赖 commit → rebase。
4. F-B1 三平台离线证据与 BUILD.md 说明。
5. F-C1 嵌套拒绝测试。
6. F-D1 任务表状态。
7. workspace fmt / clippy -D warnings / test 全量，Gitleaks。

## 6. 待人类裁定

- **H1（P10）**：WireGuard 真实分享格式需要 IR 增加对端公钥、本地地址、MTU 等字段（PC-02 契约变更）。选项：① 扩 IR（回 PC-02 所有者）后由 PC-06 支持；② P0 保持显式拒绝，WireGuard 仅支持 JSON/手工构造，转 P1。审核建议 ②，避免为 PC-06 重开已冻结契约。
- **H2（F-A1 方向）**：订阅刷新是否必须 HTTPS 客户端内置于 parser crate，还是后移到宿主（PC-18b/PC-20）由已有依赖承担。审核建议依赖申请中二者择一并比较包体与三平台构建成本。

### 6.1 人类裁定结果（2026-11-23 11:36 UTC+8）

- **H1 → P0 保持显式拒绝，完整 WireGuard 分享链接转 P1**（即上文选项 ②；不改 PC-02 IR／契约）。返工要求：常见 `wireguard://` 格式返回明确的“不支持”错误并带行号，不得落为笼统解析错误；补测试固定此行为，审核探针 P10 改为断言“明确拒绝”；交付说明与 BUILD/README 注明“完整 WireGuard 分享链接留待 P1”。
- **H2 → PC-06 移除内置 HTTP 客户端，提供“受控字节输入 + Fetcher 抽象”，下载由宿主（PC-18b/PC-20）承担**。返工要求：
  1. 移除 `reqwest`／`rustls` 及其传递依赖（aws-lc-sys／ring／quinn 等），`Cargo.lock` 回到基座规模；剩余仍属新引入的依赖（如 `base64`）照常走 v1.1 第 94 行依赖申请。
  2. 定义 Fetcher trait 契约：返回字节、大小上限、超时与失败语义、错误不含 URL。
  3. 以假 Fetcher 测试覆盖：成功合并、失败保留旧节点、超大小上限拒绝、错误脱敏、staging 失败回滚。
  4. 交付说明写明下载由宿主实现，并在共享记忆中为 PC-18b、PC-20 各登记一条待办（宿主 HTTPS 客户端选型届时走依赖申请）。
- 因 H2，F-A1 的 reqwest+rustls 部分与 F-B1 的大部分缺包问题随移除消解；但返工仍须给出三平台 `--locked --offline` 构建证据。

证据：`~/.agent-tools/run/review/pc06-r1/{logs/,probe.rs,run2.sh,linux-check.sh}`。
