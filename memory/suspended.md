# Suspended Tasks Registry (`memory/suspended.md`)

> **权威状态文件（`global/rules.md#S3.4b`）**：防撞键 = `项目 + 任务ID`。
> **硬规则**：
> 1. 下表 `Active Suspended Tasks` 中的所有任务，任何设备/Agent/账号**严禁认领或开工**；
> 2. 项目内 `tasks.md` 仍保持 `todo` 不改状态枚举，统一以本表为唯一防撞权威；
> 3. **解挂权仅归人类**：Agent 仅可汇报前置已满足；人类批准后先在 `memory/projects/<项目>.md` 追加 `【解挂】` 行，再将对应行移入下方 `Unblocked History`。

## Active Suspended Tasks

| Project | Task ID | Title | Suspended At | Reason | Unblock Precondition | Branch / Worktree | Decision Source |
|---|---|---|---|---|---|---|---|
| `prnmgt` | `S1` (`T-059 / T-060 / T-061`) | 管理页交互收尾（前端） | 2026-11-12 | 前置依赖项与优先级排期调整 | 人类明确下达解挂指令 | 无活跃 worktree | `handoff/2026-11-13-多设备多Agent协同评估后续任务卡-zhn-tbxg2iah-win.md` |
| `prnmgt` | `S2` (`P0 二次真机调研`) | 二次真机调研 | 2026-11-12 | 需现场真机窗口配合 | 真机窗口就绪且人类解挂 | 无活跃 worktree | `handoff/2026-11-13-多设备多Agent协同评估后续任务卡-zhn-tbxg2iah-win.md` |
| `prnmgt` | `S3` (`v4 / #18`) | 需求/问题 #18 | 2026-11-12 | 延后排期 | 人类明确下达解挂指令 | 无活跃 worktree | `handoff/2026-11-13-多设备多Agent协同评估后续任务卡-zhn-tbxg2iah-win.md` |

## Unblocked History

| Project | Task ID | Title | Unblocked At | Approved By | Resume Baseline |
|---|---|---|---|---|---|
| *(none yet)* | - | - | - | - | - |
