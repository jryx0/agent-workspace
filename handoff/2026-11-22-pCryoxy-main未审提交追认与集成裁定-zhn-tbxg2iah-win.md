# pCryoxy｜main 未审提交 ec39de4/152df4e 追认与分支链集成裁定

- 裁定方: workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-22 08:15
- 人类授权（2026-11-22 08:08）：① 追认 idna 依赖；② 同意按集成建议修 main，并由 workbuddy 合并、推送项目仓；③ 授权 workbuddy 代推 `agent/copilot/pc17`、`pc03`、`pc04` 备份分支。
- 前置证据：`handoff/2026-11-22-pCryoxy-done卡与PC04-ABIv2独立重跑复核及集成建议-zhn-tbxg2iah-win.md`（审核方独立重跑）

## 1. 追认 ec39de4、152df4e

| 提交 | 内容 | 裁定 |
|---|---|---|
| `ec39de42ff6bbbdf8c680781e3829a395a4823cc`（11-19 18:23，copilot） | 根 `Cargo.toml` workspace members 加入 `crates/core-ir`；新建 `crates/core-ir/Cargo.toml`（含 `[[test]] ../../tests/contracts/ir.rs`）；`Cargo.lock` 增 core-ir 包 | **追认通过**。属 PC-00 公共清单变更，应由 PC-00 所有者经审批串行修改；本次按人类指令补审追认 |
| `152df4eca58d5c663d5e59d6979eea55bbf288ee`（11-19 18:36，copilot） | `crates/core-ir` 增 `idna = "=1.1.0"`（精确锁定；该包此前已在 `Cargo.lock` 中，未引入新传递依赖） | **追认通过**（人类 2026-11-22 08:08 追认 idna 依赖） |

- 单看这两个提交，main 构建不通过（缺 `crates/core-ir/src/lib.rs`，审核方实测 `cargo check` 退出 101）。缺失源码由已审 PC-01 提交 `3a99401` 补齐，因此**追认以与分支链一起集成为条件**，不单独作为可用基线。
- 程序缺陷（未审先推 main、PC-00 清单未串行审批）记入核查报告 F-04，不再追责；今后任何 agent 不得直推 `main`。

## 2. 集成裁定

- 允许 main 快进到 `2908e4e`（链：`3a99401` PC-01 → `2ccffd0` 依赖子任务 1 → `78cf166` PC-02 → `95e0efc`/`1e18654` PC-17 → `2908e4e` 依赖子任务 2）；这几个提交均已审核通过，并经审核方独立重跑通过。
- workbuddy 本地文档提交（`2e653c5`、`1c7bfde`）变基到 `2908e4e` 之上后一并推送；与链上改动不重叠。
- **不并入**：`90aa591`（Go 绑定冻结，未审）、`c73d59d`（PC-03 doing）、`44247c8`（PC-04 doing）。
- 推送前在集成后的 main 上执行 `cargo check --workspace --locked` 与 `cargo test --workspace --all-features --locked`，结果记入项目记忆。
- 代推 `agent/copilot/pc17`、`pc03`、`pc04` 到 origin，只推现有引用，不改写、不改 worktree。copilot 后续在这些分支上继续提交并自行推送即可（快进）。
- 本裁定不改任何卡状态，不涉及部署（pCryoxy 无部署目标）。
