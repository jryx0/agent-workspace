# pCryoxy PC-00 最小依赖申请与批准

- 项目: pCryoxy
- 申请卡: PC-02 前置依赖准备
- 依赖所有者: PC-00 清单/Workspace 所有者
- 基座: `3a994011832a3494e6adbceb6b5937830eb8735b`
- 申请人: copilot@zhn-tbxg2iah-win~zhn-x-w
- WorkBuddy 审核: workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-20 09:25 UTC+8
- 状态: **批准最小变更，等待 PC-00 所有者提交**

## 一、批准范围

PC-00 所有者可以在指定基座上提交以下最小 Workspace 变更：

1. 新增 `crates/plugin-sdk` workspace crate，依赖 `core-ir` 的本地 path；不提前实现完整 SDK、RPC、daemon 或 UI。
2. `plugin-sdk` 的普通依赖加入 `serde = 1.0.229`，启用 `derive`。
3. `plugin-sdk` 的测试/合同依赖加入 `serde_json = 1.0.154`；不得把测试专用 JSON 依赖扩大为运行时必需依赖。
4. 可选 TypeScript 生成特性使用 `ts-rs = 12.0.1`，许可证 MIT，Rust 要求 ≥1.78；当前项目 MSRV 为 1.100.0，满足版本要求。
5. `ts-rs` 必须为 optional、非默认 feature，例如 `typescript`；关闭该 feature 时不编译、不链接、不进入运行时依赖路径。生成代码仅由明确的生成命令触发，禁止在普通测试/生产构建中隐式生成。
6. 由 PC-00 所有者更新并提交 `Cargo.lock`；proto 生成工具本次不申请，若后续确有需要另立申请。

## 二、锁文件事实与边界

- `serde 1.0.229`：已存在于 `3a99401` 对应的现有 `Cargo.lock`。
- `serde_json 1.0.154`：已存在于 `3a99401` 对应的现有 `Cargo.lock`。
- `ts-rs 12.0.1`：当前锁文件未发现；批准加入意味着必须由 PC-00 所有者更新 `Cargo.lock` 并报告新增传递依赖、哈希/来源和许可证信息。
- 本申请不批准全局安装依赖、不批准修改系统配置、不批准 proto 生成器、不批准部署。

## 三、允许修改文件

- 根 `Cargo.toml`：workspace members/dependencies/features 的最小声明；
- `crates/plugin-sdk/Cargo.toml`：crate、path 依赖、serde、serde_json、可选 ts-rs；
- `crates/plugin-sdk/src/lib.rs`：仅最小可编译骨架和公开模块边界，不实现业务契约；
- 根 `Cargo.lock`：由 PC-00 所有者串行更新；
- 必要的最小 workspace 测试/说明文件，需在交接中列出。

禁止修改：`core-ir` 业务实现、PC-01 文件、API Spec 正文、proto 源、daemon、Web UI、系统全局 Cargo 配置。

## 四、PC-00 所有者交付门槛

- [ ] 先按 T2 流程确认基座确实包含 `3a99401`；
- [ ] 认领/依赖申请记录先追加，再修改 Workspace；
- [ ] `cargo metadata --locked` 能解析；
- [ ] 默认构建不启用 `typescript`，证明 ts-rs 不进入默认/运行时路径；
- [ ] 显式启用 `typescript` 的生成检查可运行；生成输出不手改；
- [ ] `cargo test --workspace --locked`、`cargo check --workspace --release --locked`、fmt/clippy 按现行工具链执行；
- [ ] gitleaks 无命中；
- [ ] 交接列出新增包、feature、锁文件 diff、传递依赖、许可证、包体影响和未做的 proto 工作；
- [ ] 提交后把完整提交号交 WorkBuddy 审核；不得自行标 PC-02 通过。

## 五、执行提示词

```text
【pCryoxy｜PC-00 所有者最小依赖提交】

请基于 `3a994011832a3494e6adbceb6b5937830eb8735b`，只做本申请批准的 Workspace 最小变更：

1. 新增 `crates/plugin-sdk`，path 依赖 `core-ir`；
2. serde 1.0.229 + derive；
3. 测试用 serde_json 1.0.154；
4. optional、非默认 `typescript` feature 使用 ts-rs 12.0.1；关闭 feature 时不进入默认/运行时构建；
5. 由你串行更新根 Cargo.lock；proto 生成器不在本次范围。

先做 T2 自检和基座核对，再追加依赖申请/doing 记录后开工。只改根 Cargo.toml、plugin-sdk、Cargo.lock 及必要最小测试/说明；不要改 core-ir、proto、daemon、Web UI 或 API Spec。验证 metadata --locked、默认构建、显式生成 feature、workspace test/check/fmt/clippy 和秘密扫描。交付完整 commit、Cargo.lock diff、实际命令/退出码、传递依赖/许可证/包体影响及未覆盖项，交 WorkBuddy 审核；不要自行标 done，不要认领 PC-02。
```
