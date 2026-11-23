# pCryoxy PC-06 首轮返工交付待复核

- 项目: pCryoxy
- 交付者: copilot@zhn-tbxg2iah-win~zhn-x-w
- 日期: 2026-11-23
- 状态: PC-06 保持 doing；不合并、不推送。
- 分支: `agent/copilot/pc06`
- 基座: `1b1ae3d0b0380e3bbc46269b9e3103967ce50284`
- 原提交: `3cf459d6cc9955eb7a00b2ac845eda38b7cc57b3`
- 返工提交链: `ad37056aff8bf40e497400cc81139d68f6d325bd` → `319fdafd2fd14024f257c88a6256ca6d8e1a4657`
- 裁定依据: [PC-06 首轮审核裁定](./2026-11-23-pCryoxy-PC06首轮审核裁定-3cf459d-zhn-tbxg2iah-win.md)

## 人类裁定落实

- H1：P0 WireGuard 仅支持当前 IR 可表达的 legacy 字段，真实分享链接含 `publickey/address/mtu` 时显式 `unsupported_capability`；完整支持转后续任务，不扩 PC-02 契约。
- H2：订阅网络下载由宿主负责；parser 提供 `SubscriptionFetcher` 抽象与 `SubscriptionFetchLimits`（bytes、大小上限、timeout）。URL/redirect/DNS/代理/HTTP 状态由宿主实现；fetch error 和 URL 被映射为固定 `SubscriptionFetch`，不进入报告。

## 返工清单逐项

| 项 | 修复与证据 |
|---|---|
| P1 | URL IPv6 的 host 仅在建立 `Endpoint` 时去方括号，IR 保存裸 `2001:db8::1`；20 项测试含该断言。 |
| P2/P3 | 线上 `path` 只校验控制字符，不再清理 `//`、`.`、`..`、尾 `/`；`/ws` 与 `/ws/` 产出两个节点并保留原 bytes/decoded string。 |
| P4 | 无法表达为独立 HTTP Host 的 `host` 参数：只有 TLS WS 且 `host == sni` 时可由同一表示映射；否则返回 `unsupported_capability`，不静默丢失。 |
| P5 | VMess `net=tcp|raw,type=http` 返回 `unsupported_capability`；不能把 HTTP 伪装头降级为普通 TCP。 |
| P6 | `ed` 与 `maxEarlyData` 均映射 `TransportOptions::WebSocket.max_early_data`；两者同时出现则拒绝冲突别名；非 WS 传入显式拒绝。 |
| P7 | VLESS/VMess 36 位 UUID 规范化为小写后计算 credential_id；大小写不同的同一 UUID 去重。非 UUID 形状仍按原 bytes 保持兼容。 |
| P8 | VMess `net=grpc,type=multi` 映射 `Grpc { multi_mode: true }`；其他不可表达的 transport type 显式拒绝。 |
| P9 | `Candidate` 携带源行；同批/既有指纹相同但非显示语义不同时返回 `BatchRejected` 的 `line + fingerprint_conflict`，回滚所有 staged secret。 |
| P10 | `publickey/address/mtu` 未在现有 WireGuard IR 中，保持显式拒绝并加测试；legacy `peer/private-key/reserved` 仍按现有 IR 解析。 |
| F-A1 | 按 H2 移除 parser 的 reqwest/TLS 栈；与 main `1b1ae3d` 比较，Cargo.lock 仅新增 16 行 `protocol-parser` workspace 成员引用，新增外部 package 为 0。其余直接复用包已单列申请并由人类批准：见 [依赖复用申请](./2026-11-23-pCryoxy-PC06依赖复用申请-copilot-zhn-tbxg2iah-win.md)。 |
| F-B1 | Windows、aarch64 Android（NDK 29 clang）、x86_64 Linux（隔离 Rust + Zig cc/ar 映射）三项 `cargo check --locked --offline` exit 0；`docs/BUILD.md` 补充工具映射和未来 aws-lc-sys 门槛。 |
| F-C1 | 文件和订阅 boundary 的 group JSON 都返回 `BatchRejected`、0 staging；已有 core-ir `NestedGroupNotSupported` 合同测试继续通过。 |
| F-D1 | 共享初始任务表是 append-only 历史快照，未改写旧 todo 行；文件末尾新增“当前状态覆盖”表，明确 PC-06 当前认领者 copilot、状态 doing。 |

## 参数映射 / 显式拒绝清单

| 协议 | 已映射 | 显式拒绝 |
|---|---|---|
| VLESS | UUID、endpoint、type、`flow`、`encryption`、TLS/REALITY、SNI、path/serviceName、XHTTP mode、WS early data/header、gRPC multi | 不可表示 Host/SNI、错误 transport 参数、REALITY/TLS 错位参数、未知 query、重复 query、冲突别名 |
| VMess | add/port/id/aid/scy、raw/ws/httpupgrade/grpc/quic、TLS/alpn/fp/allowInsecure、path/serviceName、grpc `type=multi` | tcp/raw `type=http`、不可表示 WS Host、未知 JSON 字段、未知 cipher/security/transport type |
| Trojan | credential、endpoint、transport/security/path/serviceName、TLS、WS early data、gRPC multi | 与 VLESS 相同的不可表示 Host、错位参数；password userinfo |
| Shadowsocks | 现有六种 IR cipher、method:password、endpoint | plugin、未知 cipher、畸形 userinfo；不静默忽略 plugin |
| Hysteria2 | auth、endpoint、TLS SNI/alpn/insecure、cc、hop interval | 未知 query/cipher/cc、冲突 hop 别名 |
| WireGuard | private key、endpoint、peer/peers、reserved | `publickey/address/mtu` 及其他完整分享字段 |
| MASQUE | token、endpoint、TLS、SNI、cc | 未知 query、不可表示字段 |
| 批/订阅 | base64 subscription、Atomic、显式 ValidOnly、行号/错误码、1 MiB 上限、Fetcher 的 `max_bytes`/timeout | 非 protocol entry 的 group/JSON/object、空批、超量、重复参数、无效 limits；fetch 失败只返回固定 `SubscriptionFetch` |

## 验证

- `cargo fmt --all -- --check`：exit 0。
- `cargo clippy --workspace --all-targets --locked --offline -- -D warnings`：exit 0。
- `cargo test --workspace --locked --offline`：61 passed，0 failed，4 ignored；其中 parser 20/0。
- `cargo check -p protocol-parser --target x86_64-pc-windows-msvc --locked --offline`：exit 0。
- `cargo check -p protocol-parser --target aarch64-linux-android --locked --offline`：exit 0（NDK 29 aarch64 clang/llvm-ar）。
- `cargo check -p protocol-parser --target x86_64-unknown-linux-gnu --locked --offline`：exit 0（隔离 Rust 1.100、Zig 0.16 cc/ar mapping）。
- Gitleaks：9 个项目文件逐文件 0 命中。
- 返工 commit 后 project worktree 干净。

PC-06 未合并、未 push；等待审核方复核。

## 挂起任务（当前全量快照）

| 项目 | 任务ID | 挂起于/裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级 + 复跑 + 更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 + 新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无挂起项；PC-06 当前 doing。
