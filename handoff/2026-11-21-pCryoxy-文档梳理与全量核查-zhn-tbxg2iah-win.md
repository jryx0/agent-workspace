# pCryoxy 文档梳理与全量核查

项目: pCryoxy
记录人: workbuddy@zhn-tbxg2iah-win~zhn-x-w
时间: 2026-11-21 23:55 UTC+8
性质: 只读核查 + 项目仓派生文档；不修改任何权威正文、代码、卡状态或他人现场；不合并、不部署

## 1. 当前状态

- 人类 23:40 指令：对 pCryoxy 做全量进度核查，备份原有文档（放项目内、git 忽略），梳理需求、任务卡、工作进展，并给出需求和任务卡的优化。
- 已完成，成果在项目仓提交 `2e653c5692bc74ff7d3815ab36e96cc52c304ff2`（main，**仅本地提交，未推送**）：
  - `docs/README.md` 文档索引
  - `docs/01-需求总表.md` REQ-01～36 映射、状态、G-01～G-08 需求优化
  - `docs/02-任务卡总表.md` 26 张卡的真实状态、专项、T-01～T-09 问题、v1.2 拆环方案与新依赖图
  - `docs/03-工作进展.md` 时间线、在途事项、待人类决定事项
  - `docs/04-核查报告-20261121.md` F-01～F-24（高 7 / 中 10 / 低 7）
  - `.gitignore` 追加 `/docs/_backup-*/`（该文件属 PC-00 所有者独占，本次按人类明确指令改动）
- 原件备份：`~/source/pCryoxy/docs/_backup-20261121/`（75 份 handoff 逐文件 SHA-256 一致，共 1,404,943 字节；项目记忆快照；BUILD.md、AGENTS.md），git 忽略，仅本机留存。

## 2. 高级发现摘要（详见项目 docs/04）

1. F-01 PC-04 受限子集裁定拒绝 sniffing/freedom/finalmask，实质缩减 REQ-08/12/14，无用户裁定。
2. F-02 依赖成环：PC-04↔PC-18（经 PC-08）、PC-20↔PC-21。
3. F-03 PC-18 未认领、依赖未满足即被授权阶段 A / Rust FFI。
4. F-04 main 构建不通过：未审核提交 `ec39de4`/`152df4e` 引用不存在的 core-ir 源码；全部 done 成果未合并。
5. F-05 `agent/copilot/pc17`（done）、`pc03`、`pc04` 未推送远端；共享仓 3 份 pCryoxy handoff 未提交。
6. F-06 审核普遍未独立重跑，而本机已有 rust/go/zig 隔离工具链。
7. F-07 PC-04 ABI v2 复审由 WorkBuddy 自行申请、自行通过（23:16→23:24）。

## 3. 待办（均待人类裁定，本记录不构成授权）

见项目 `docs/04-核查报告-20261121.md` §4 的 9 项；裁定后由 workbuddy 出任务卡 v1.2 并刷新认领入口。

## 4. 现场与附注

- 未使用 worktree；在主 worktree `~/source/pCryoxy` 只新增 docs 与 `.gitignore` 一行，已提交，工作区干净（备份目录被忽略）。
- `~/.agent-tools/run/git.lock` 为 22:44 的空文件，无进程持有（PowerShell 排他打开成功）；本次在持有排他句柄期间完成提交，未删除该文件。
- 共享仓他人未提交改动（1 个修改的 handoff、1 个 skill、6 个未跟踪 handoff）未触碰，本次仅提交本文件与项目记忆追加行。

## 挂起任务（当前全量快照）

继承 2026-11-21 最新已审交接，本轮不解挂任何项目。

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无 suspended 项；pRayShell 已 closed，无 suspended 项。
