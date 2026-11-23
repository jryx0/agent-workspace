# pCryoxy PC-06 交付待审核

- 项目: pCryoxy
- 交付者: copilot@zhn-tbxg2iah-win~zhn-x-w
- 日期: 2026-11-23
- 状态: PC-06 保持 doing；实现与本机门禁完成，待审核方复核。
- 分支: `agent/copilot/pc06`
- worktree: `C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc06`
- 基座: `1b1ae3d0b0380e3bbc46269b9e3103967ce50284`（main）
- 提交: `3cf459d6cc9955eb7a00b2ac845eda38b7cc57b3`

## 已完成

新增 `crates/protocol-parser`，只修改 PC-06 文件范围以及加入 workspace/锁文件所需的清单：

- `lib.rs`：一次入口、原子/显式 valid-only 批策略、staged secret 事务、失败回滚与取消清理。
- `canonical.rs`：域名/IP 规范化后的八字段指纹、与现有节点去重、非显示语义冲突拒绝、稳定 NodeId/安全显示名。
- `validate.rs`：VLESS、VMess、Trojan、Shadowsocks、Hysteria2、WireGuard、MASQUE；XHTTP/WS/HTTPUpgrade/gRPC/QUIC/Native 解析；TLS/REALITY、路径与 SNI 规范化；未知能力、重复查询字段、不可表示的 Host/SNI 语义均显式拒绝。
- `subscription.rs`：仅 HTTP/HTTPS、禁重定向、超时与 1 MiB 流式上限；刷新采用“只合并、不删除既有节点”的明确策略，避免删除仍被规则或组引用的节点。
- `tests/parser.rs`：真实格式矩阵、base64 订阅、名称不参与去重、冲突不覆盖、分隔符注入/REALITY-vs-TLS 不碰撞、原子批次、显式 valid-only 子集、staging 回收、受控 HTTP 成功/503 保留旧状态。

凭据候选以 `Zeroizing<Vec<u8>>` 保存；使用 PC-03 Vault 的 HMAC `credential_id`，新凭据先进入 staging，验证或冲突失败时逐个 `delete_staged`。错误只含静态字段码/行号/HTTP 状态，不含链接、URL、原始 credential 或第三方响应正文。

依赖只加入该 crate：URL/base64/JSON/HTTP 客户端、serde、zeroize。`reqwest 0.13.5` 使用显式 `rustls` feature；Cargo.lock 记录了由该 feature 激活的 TLS 依赖，未做全局安装或修改系统 PATH。

## 验证

- `cargo fmt --package protocol-parser -- --check`：exit 0。
- `cargo clippy -p protocol-parser --all-targets --locked --offline -- -D warnings`：exit 0。
- `cargo test -p protocol-parser --locked --offline`：9 passed，0 failed。
- `cargo check --workspace --locked --offline`：exit 0。
- `cargo clippy --workspace --all-targets --locked --offline -- -D warnings`：exit 0。
- `cargo test --workspace --locked --offline`：50 passed，0 failed，4 ignored。
- Gitleaks 对 8 个变更文件逐文件扫描：0 命中。
- 提交后 project worktree 干净。

## 未完成与边界

- 未声明 PC-06 done；未合并、未 push。
- `valid-only` 必须由调用方显式选择，返回 `skipped_lines()`；默认 atomic 遇坏行整批不提交。
- 订阅刷新只追加/去重，既有节点永不自动删除；调用方可在后续审阅中决定显式退役策略，当前不造成悬空引用。
- 未改 `plugin-sdk`、`core-ir` 或 `secure-store` 共享接口。
- 未部署。

下一步由审核方独立复核提交 `3cf459d6cc9955eb7a00b2ac845eda38b7cc57b3`，重点检查真实分享格式覆盖、SecretStore staging/回滚、订阅保留策略、错误脱敏与 lock 依赖影响。通过后由人类或审核方决定结卡与合并。

## 挂起任务（当前全量快照）

| 项目 | 任务ID | 挂起于/裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级 + 复跑 + 更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 + 新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无挂起项；PC-06 当前为 doing，未被挂起。
