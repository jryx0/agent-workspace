> **Source**: `global/rules.md` spec volume (v3.0, synced with `rules.md`)
> **Section**: `S3.6`
> **Trigger**: 启用/清理 git worktree、创建或合并 `agent/*` 分支、清理已合并分支时
> **Authority**: 与 `rules.md` 同等效力，受 `R4` 保护；修订见 `[spec/governance.md#S9]`。

## S3.6 Git Worktree Collaboration

- **S3.6a 启用条件**：**单人单任务直接 clone 到 `~/source/<项目>`，不启用 worktree**。仅当两个及以上 Agent/会话并发修改同一项目代码时启用。
- **S3.6b 禁用范围**：仅限 `env/repos.md` 登记的项目仓库；**`~/.agent-shared` 严禁 worktree**（破坏 append-only 与单线历史）。
- **S3.6c 布局**：
  - 主 worktree：`~/source/<项目>`（跟踪默认分支，人类或共用者使用）
  - 并发 worktree：`~/source/<项目>.wt/<agent>/`（同 agent 多会话/多账号扩展为 `<agent>-[<account>-]<task>/`），分支名 `agent/<agent>/<task>`。
- **S3.6d 流程与提交身份**：
  1. 先按 `S3.5c` 完成任务认领登记与防撞核查；
  2. `git worktree add ~/source/<项目>.wt/<dir> -b agent/<agent>/<task> origin/<default>`；
  3. 开发与验证通过后 `git pull --rebase origin <default>`；
  4. 提交须带 `Agent: <agent>` trailer，并使用临时参数指定提交身份：`git -c user.name=zhn-<agent> -c user.email=<agent-email> commit ...`。**禁止使用裸 `git config user.name/user.email`**（worktree 共用 `.git/config`，会污染主 worktree）；
  5. 推送分支 → 人类或审核方合并 → `git worktree remove`。
- **S3.6e 生命周期与挂起**：会话结束即 `git worktree remove`，成果留在分支；月度压缩时清理已合并的 `agent/*` 分支（`[spec/memory-compaction.md#S3.2d]`）。任务挂起时默认 remove worktree 保留分支，并在 `memory/suspended.md` 写明分支与基座 commit；确需保留目录须注明路径并禁止其他会话复用。
- **S3.6f 依赖复用**：Python venv 位于 `~/.agent-tools/venvs/<agent>/` 跨 worktree 复用；`node_modules` 按 worktree 独立安装并复用 `~/.agent-tools/cache`。
