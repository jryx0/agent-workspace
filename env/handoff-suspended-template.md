# Handoff Summary & Suspended Task Templates (`env/handoff-suspended-template.md`, v3.0)

> 配套规范：`global/rules.md#S3.4`。
> **核心变化（v3.0）**：挂起任务统一维护在单一权威文件 `memory/suspended.md`，**不再在每份 handoff 中重复抄录挂起快照**；主 handoff 文件保持 ≤ 2 KB 摘要，超长日志/核查过程放 `handoff/notes/`。

---

## 1. Handoff Summary Template (`handoff/YYYY-MM-DD-<project>-<slug>-<device>.md`, <= 2KB)

```markdown
---
project: <项目名 或 global>
date: YYYY-MM-DD
author: <agent>@<device>~<account>
status: done | handoff | blocked
---

# <任务简标题>

## 1. Summary & Outcome
- 做了什么（1-3 条核心结果）
- 关键提交 / 产物链接（commit hash、`docs://` 或 `handoff/notes/...`）

## 2. Open Items / Next Steps
- [ ] 待办 1（注明前置条件或责任方）

## 3. Risks & Notes
- 若有详细排查记录/多轮审核，放 `handoff/notes/YYYY-MM-DD-<slug>.md` 并在此引用。
```

---

## 2. Suspend / Unblock Workflow (`memory/suspended.md`)

### A. 人类裁决挂起（Suspend）
1. 在 `memory/projects/<project>.md` 末尾追加一行（append-only）：
   `[@<agent> @<device>~<account> YYYY-MM-DD HH:mm UTC+8 【挂起】<TaskID> <标题>；原因：<原因>；解挂前置：<条件>；现场：<分支/worktree状态>；出处：<裁决来源>]`
2. 在 `memory/suspended.md` 的 `Active Suspended Tasks` 表格追加对应行；
3. 项目内 `tasks.md` 保持 `todo` 不改状态枚举；worktree 默认移除并将成果保留在分支（`[spec/worktree.md#S3.6e]`）。

### B. 人类裁决解挂（Unblock，解挂权仅人类）
1. 在 `memory/projects/<project>.md` 末尾追加一行（append-only）：
   `[@<agent> @<device>~<account> YYYY-MM-DD HH:mm UTC+8 【解挂】<TaskID> <标题>；人类批准时间：<时间>；恢复基线：<分支/commit>]`
2. 将该行从 `memory/suspended.md` 的 `Active Suspended Tasks` 移至底部 `Unblocked History`。
