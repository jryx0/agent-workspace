# pCryoxy｜done 卡与 PC-04 ABI v2 独立重跑复核，及 main 修复与集成建议

- 发布: workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-22
- 依据: 人类 2026-11-22 00:11 裁定第 4 项「对已 done 的卡和 PC-04 ABI v2 做一次独立重跑测试」；第 3 项「main 修复/合并/推送给出建议」
- 性质: **审核方独立复验**（不是执行方回执转述）。本文件不改任何卡状态、不合并、不推送项目仓、不部署。
- 审核目录: `~/.agent-tools/run/review/pcryoxy-rerun-20261122/`（每个精确提交用 `git archive` 导出到 `src-<sha>/`，与任何 agent worktree 隔离）

## 1. 结论

| 卡 / 对象 | 精确提交 | 独立重跑结果 | 结论 |
|---|---|---|---|
| PC-00 | `c3dae63` | fmt / clippy `-D warnings` / check 全部退出 0 | **复验通过** |
| PC-01 | `3a99401` | fmt、clippy、`core-ir` 合同测试、workspace 测试、release check 全部 0；30 测试通过 0 失败 | **复验通过** |
| PC-00 依赖子任务 1 | `2ccffd0` | metadata、all-features check/test 全部 0；16 通过 0 失败 | **复验通过** |
| PC-02 | `78cf166` | fmt、clippy、test（24 通过 0 失败）、release check、TS 生成 `--check` 全部 0；`check-proto.mjs`（protoc 29.5）通过；`tsc --strict` 编译 fixture 后输出与 `fixtures/api.json` 深度相等 | **复验通过** |
| PC-17 | `1e18654` | WSL Ubuntu-24.04 + Rust 1.100.0 + Zig 0.16.0 按 `tools/build-linux` 构建 release 退出 0；两个 rlib `sha256sum -c` OK；`Cargo.lock` SHA-256 `3e698bce…c119` 与交付记录一致、未改动 | **复验通过** |
| PC-00 依赖子任务 2 | `2908e4e` | fmt、check、test（24 通过 0 失败）、clippy 全部 0 | **复验通过** |
| PC-04 Runtime ABI v2 | `44247c8`（含 `2206139f`） | WSL replay：**62 PASS / 0 FAIL**，`-race` 无 DATA RACE；ABI v1 预检冒烟（1024 并发）、ABI v2 冒烟（真实 create/status/close、8 线程并发）均通过；两次独立 GOCACHE 构建 `cmp` 一致，archive SHA-256 **`8a6d31a78f47e9f16872920247df4457b0c762674a72b401373cbc714ec7abff`**，与执行方申报值逐字一致 | **复验通过**（仅覆盖 ABI v2 专项；PC-04 整卡仍按 v1.2 §2 六条结卡） |
| main HEAD | `152df4e` | `cargo check --workspace --locked` 退出 101：`can't find lib core_ir at …crates\core-ir\src\lib.rs` | **证实 F-04：main 构建不通过** |

工具链：Windows `cargo 1.100.0 (3acc79c0c)` / `rustc 1.100.0 (0ef1bc386)`（`~/.agent-tools/runtimes/rust`）；Linux `go 1.27.4`、`zig 0.16.0`、`rust 1.100.0`（`~/.agent-tools/runtimes/copilot/linux-x86_64-gnu`）；protoc 29.5；TypeScript 取项目 `node_modules`。

证据日志 SHA-256：

- `rust-rerun.log`：`bcc87b0226c22973bdaccc69e6d94235d6956e2a50811ec6266380ba139663d7`
- `pc04-replay.log`：`27b6f4378e36b20d6e7593436d21c88a6a691c7d5960864face6a37045a12034`
- `pc17-build.log`：`f13c421cd5df675e68face35f69580e72685152273523076f24006ce746952f3`

## 2. 过程中的偏差（如实记录）

1. **第一轮 Rust 重跑有 2 项假失败**（`78cf166 test`、`2908e4e test` 退出 101）。原因是审核方脚本问题：多个提交共用一个 `CARGO_TARGET_DIR`，而 `git archive` 导出的文件时间戳是提交时间，cargo 依据 mtime 误判“未变”，复用了上一个提交的编译产物。第二轮在每个提交首次运行前刷新源文件时间戳后，全部通过。第一轮日志保留为 `rust-rerun.run1-shared-target.log`，不作为结论依据。
2. **中间一轮“每提交独立 target”的尝试被中止**：`build_script_build` 进程长时间无进展，审核方终止了本次重跑自己启动的 cargo/rustc 进程（未触及其他 agent 的进程）。日志保留为 `rust-rerun.run2-per-target-aborted.log`。
3. **PC-04 replay 包装脚本最后一步退出 1**：审核方没有预先建 `out/` 目录，replay 在 `cmp` 通过之后的 `cp` 一步失败。所有测试与双构建比较都在此之前完成，结论不受影响；archive 摘要已直接在 `delivery-bridge/first.a`、`second.a` 上核对。
4. **`libpc04_abi.so` 不可复现**：本轮 `042a6949…f387`，执行方两次申报分别为 `3cc78014…`、`1cb313fc…`。执行方已声明“shared library 只作单次冒烟摘要、不声明可复现”。记为**低**：若 `.so` 将来成为交付物，PC-04/PC-18a 须补可复现构建。
5. 审核目录残留 `target-3a99401/`（约 5,768 个文件）未删，属审核方临时产物，不影响任何项目或 agent 目录。

## 3. 对既有裁定的影响

- PC-00、PC-01、PC-02、PC-17 与两个依赖子任务：原裁定“采信执行方结果、审核方未独立重跑”的缺口（核查报告 F-06）**就这 7 个提交而言已补齐**。卡状态不变（仍为 done / 待集成）。
- PC-04 ABI v2：`1e14e63` 自申请自通过的程序瑕疵（F-07）在结果层面由本次独立重跑补强；程序上仍建议今后复审申请由执行方提交。
- 未覆盖：PC-02 Go 绑定冻结 `90aa591`（仍无审核裁定）、PC-03 全部证据。

## 4. 第 3 项建议：main 修复、分支集成与推送

### 4.1 修 main：不回退，快进到已复验的分支链

- 事实：`ec39de4`、`152df4e` 只改 `Cargo.toml`、`Cargo.lock`、`crates/core-ir/Cargo.toml`，把 core-ir 声明进 workspace 但没带源码；源码在 PC-01 分支 `3a99401` 上。
- 全部分支（`3a99401` … `44247c8`）都以 `152df4e` 为祖先，**回退会让整条链与 main 分叉**，代价大于收益。
- 建议：
  1. workbuddy 先对 `ec39de4`、`152df4e` 补一份追认裁定（内容仅 manifest 与 lock；idna 依赖须找出或补录用户批准；不批准就在 PC-00 名下另开修正提交）；
  2. 然后把 main 依次快进到已复验的提交：`3a99401`(PC-01) → `2ccffd0` → `78cf166`(PC-02) → `1e18654`(PC-17) → `2908e4e`。本次重跑已证明每一步都能构建和测试通过，main 在第一步即恢复可构建。
  3. `90aa591`（Go 绑定冻结）须先补审核再并入；`c73d59d`(PC-03)、`44247c8`(PC-04) **不并入**，等各自 done。

### 4.2 我本地那次文档提交

- `2e653c5`（docs/README、01～04、`.gitignore`）目前只在本机 main 上、未推送，它让 main 与分支链分叉，导致无法快进。
- 它和分支链改的文件不重叠（链上只改 `docs/BUILD.md`），建议集成时把它**变基到 `2908e4e` 之上**再推送，不产生合并提交。

### 4.3 谁来合并

- 按用户级规则“代码由其他 agent 执行，workbuddy 负责审核、合并收官”，**建议由 workbuddy 执行合并**。合并前在项目记忆追加“集成认领”行，合并后记录基线 SHA 与 `cargo test --workspace` 结果。
- 集成只是 `git push` 到项目远端，**不涉及部署**（pCryoxy 目前没有部署目标）。

### 4.4 推送与备份

- 立即：`agent/copilot/pc17`、`pc03`、`pc04` 推到 origin 备份。建议由**分支所有者 copilot**推送；若人类同意，也可由 workbuddy 代推（只推不改）。
- copilot 应提交共享仓里 3 份未入库的 pCryoxy 交接文档（`PC04-GeoLifecycle`、`PC04`、`PC18阶段A只读预检…-e64ae0ad`），它们已被裁定引用。
- copilot 处理 pc04 worktree 里未跟踪的 `tests/integration/bridge/pc04-linux-amd64.a`（2.89MB）：删除，或由 PC-00 所有者把 `*.a` 加入 `.gitignore`。

### 4.5 提交身份（F-10）

- 建议各 agent 在每个项目仓设置**仓库级** `user.name` / `user.email`（如 `zhn-copilot <copilot@zhn-tbxg2iah-win>`），不再落到 `~/.gitconfig` 的个人邮箱。
- 已推送的历史不改写（改写会破坏所有提交号引用）；未推送的 pc03/pc04/pc17 也不建议改写，避免与 handoff 中的提交号对不上。

## 5. 待人类确认

1. 是否同意 §4.1 方案（补追认 → 快进到 `2908e4e`），并授权 workbuddy 执行合并与推送项目仓 main？
2. pc17/pc03/pc04 备份推送由 copilot 做，还是授权 workbuddy 代推？
3. `ec39de4`/`152df4e` 引入的 idna 依赖，是否有你的批准记录？没有的话是否现在追认？
