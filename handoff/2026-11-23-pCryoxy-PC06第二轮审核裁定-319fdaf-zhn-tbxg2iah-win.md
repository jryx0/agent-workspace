# pCryoxy PC-06 第二轮审核裁定（319fdaf）

- 项目: pCryoxy
- 审核方: workbuddy@zhn-tbxg2iah-win~zhn-x-w
- 日期: 2026-11-23 12:10 UTC+8
- 被审: 分支 `agent/copilot/pc06`，`3cf459d` → `ad37056` → `319fdafd2fd14024f257c88a6256ca6d8e1a4657`（基座 main `1b1ae3d`）
- 依据: 首轮裁定 `handoff/2026-11-23-pCryoxy-PC06首轮审核裁定-3cf459d-zhn-tbxg2iah-win.md`（含 §6.1 人类 H1/H2）；返工交付 `handoff/2026-11-23-pCryoxy-PC06首轮返工交付待复核-copilot-zhn-tbxg2iah-win.md`

## 1. 结论

**代码层通过；有条件通过，暂不结卡、不合并。** PC-06 保持 doing。满足 §4 三项收口条件后，审核方只核对差异（不再全量复跑）即结卡并合并 main。

## 2. 独立复跑（git archive 319fdaf 到 `~/.agent-tools/run/review/pc06-r2/src`，审核方自有 target，`--locked --offline`）

| 项 | 结果 |
|---|---|
| `cargo fmt --all -- --check` | exit 0 |
| `cargo clippy --workspace --all-targets --locked --offline -- -D warnings` | exit 0（首轮缺项已补） |
| `cargo test --workspace --locked --offline` | 61 passed / 0 failed / 4 ignored；parser 20/0（首轮缺项已补） |
| `cargo tree -p protocol-parser` ×（host / aarch64-linux-android / x86_64-unknown-linux-gnu） | exit 0；无 reqwest / rustls / aws-lc / ring / quinn |
| Android `cargo check`（NDK 29 aarch64-linux-android24-clang） | exit 0 |
| Linux `cargo check`（WSL，Rust 1.100 + Zig 0.16 wrapper，全部在 `/mnt/c` 审核目录，无家目录副本） | exit 0；Cargo.lock sha256 `959243fb…262625d` 前后不变 |
| Gitleaks（`1b1ae3d..319fdaf`，3 commits） | 0 命中 |
| Cargo.lock 包数 | 基座 449 → 首轮 494 → 现 450；唯一新增为 workspace 成员 `protocol-parser`，外部 package delta 0 |

## 3. 首轮问题逐项复核

| 项 | 结论 | 证据 |
|---|---|---|
| P1 IPv6 | 通过 | 正式测试 + 探针 R4：`[2001:DB8:0:0::1]` 与 `[2001:db8::1]` 归一为同一节点 `2001:db8::1` |
| P2/P3 path | 通过 | 正式测试 `/ws` 与 `/ws/` 两节点；探针 R5 `/a/../b//c` 原样保留 |
| P4 WS Host | 通过（显式拒绝口径） | TLS+WS 且 host==sni 接受；host≠sni、security=none、无 sni 均 `unsupported_capability`（R1、Q1） |
| P5 tcp http 伪装 | 通过 | 正式测试显式拒绝，0 staging |
| P6 ed | 通过 | `ed=2048` → `max_early_data=2048`；`ed`+`maxEarlyData` 同现 `invalid_field`；非 WS 带 ed `unsupported_capability`（R2） |
| P7 UUID 大小写 | 通过 | VLESS 正式测试；VMess 探针 R7 去重为 1 |
| P8 grpc multi | 通过 | 正式测试映射 `Grpc { multi_mode: true }` |
| P9 冲突 | 通过 | 同批：line 2 + `fingerprint_conflict`；与既有快照冲突：探针 R3 line 2 + `fingerprint_conflict`，staging 回滚（1→1） |
| P10 / H1 WireGuard | 代码通过；文档未落 | 探针 R6：第 2 行 `unsupported_capability`；但 BUILD/README 未注明“完整 WireGuard 分享链接留待 P1”（见 §4-2） |
| H2 Fetcher | 代码通过；登记未落 | `SubscriptionFetcher` + `SubscriptionFetchLimits`；失败固定 `SubscriptionFetch` 不含 URL，成功合并、失败保留、超限（含自定义 10 字节上限，R8）、坏 body、非法 limits 均 0 staging；PC-18b/PC-20 待办未登记（见 §4-3） |
| F-A1 依赖 | 待人类确认 | 外部 package delta 0，口径成立；申请文件与项目记忆写“人类 11:57 批准”，系 copilot 自行记录，审核方未见人类原话（见 §4-1） |
| F-B1 三平台 offline | 通过 | 见 §2；BUILD.md 已补 NDK/Zig 映射与 aws-lc-sys 门槛 |
| F-C1 嵌套组 | 通过（附建议 A3） | 文件与订阅入口均 `BatchRejected`、0 staging |
| F-D1 状态 | 通过 | 项目记忆新增 §4“当前任务状态覆盖”，PC-06=doing |

## 4. 结卡前收口条件（不改代码逻辑）

1. **人类确认依赖复用批准**：确认 2026-11-23 11:57 已批准 `handoff/2026-11-23-pCryoxy-PC06依赖复用申请-copilot-zhn-tbxg2iah-win.md`（base64、percent-encoding、serde、serde_json、url、zeroize、dev sha2；均为基座锁中已有包）。由审核方在项目记忆补记确认来源。
2. **copilot 补文档提交**：在 `docs/BUILD.md`（或 README）PC-06 小节写明“P0 对常见 `wireguard://` 分享链接（publickey/address/mtu）显式拒绝，完整支持留待 P1”，并在 `SubscriptionFetcher` trait 文档注释写明：超时由宿主执行（parser 仅传递 `limits.timeout`）、宿主须按 `max_bytes` 流式截断、错误类型不得携带 URL 进入 UI/日志。仅文档/注释改动，作为第 3 个返工提交。
3. **copilot 补登记**：在共享项目记忆追加两条待办——PC-18b、PC-20 各自承担订阅 HTTPS 下载实现（实现 `SubscriptionFetcher`、执行超时与流式大小上限、重定向/代理策略、HTTPS 客户端选型走依赖申请）。

## 5. 非阻断建议（可转后续卡，不影响结卡）

- A1：`prepare_subscription` 收到的 `Vec<u8>` 订阅正文含凭据，解析后未零化；建议改为 `Zeroizing<Vec<u8>>` 或在函数内 `zeroize`。
- A2：TLS+WS 带 `host` 但无 `sni` 的真实链接较常见，现一律拒绝；P1 扩 IR（独立 WS Host 头）时一并放开。
- A3：嵌套组测试只断言 `BatchRejected`，未断言错误码；因 P0 parser 不接受任何组 JSON，现状可接受，后续接入组导入时须补专用错误码测试。
- A4（流程）：copilot 的 11:57 记忆条目插在审核方 11:36 条目之前，并在事件流中段新增 `## 4` 标题，不符合 append-only 时间序；今后一律追加到文件末尾。

证据：`~/.agent-tools/run/review/pc06-r2/{run.sh,probe2.rs,linux-check.sh,logs/}`。

## 7. 结卡（2026-11-23 12:20 UTC+8）

- 结卡条件三项已满足：①人类 12:16 在对话中确认已批准 7 个依赖复用（base64、percent-encoding、serde、serde_json、url、zeroize；sha2 仅测试），均为基座已有包；②copilot 文档提交 `7d0ee7d`（BUILD.md 写明 WireGuard P0 拒绝、P1 支持；`SubscriptionFetcher` 文档注释写明超时、流式截断、错误不带 URL 由宿主负责），相对 `319fdaf` 仅改文档 8 行；③共享记忆 `539cbfa` 已在末尾追加 PC-18b、PC-20 待办。
- 合并：`agent/copilot/pc06`@`7d0ee7d` 以 `--no-ff` 并入项目 main，合并提交 `451c3cb`，树与 `7d0ee7d` 一致；已推送 origin（origin/main=`451c3cb`）。
- PC-06 状态：**done**。§5 非阻断项 A1～A4 留作后续改进，不阻塞。
- 下游：PC-07 按 v1.2 卡面依赖 02、06、**04b**，04b 未完成前 PC-07 不可认领（审核方此前提示词误用 v1.1 依赖，已更正）。
