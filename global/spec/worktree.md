> **来源**：`global/rules.md` 的分卷（v2.6 起拆出；**不单独编号**，随 `rules.md` 版本生效）
> **原编号**：三-6
> **触发**：启用／清理 git worktree、创建或合并 `agent/*` 分支、清理已合并分支时
> **效力**：与 `rules.md` 同等，受最小红线④保护，修订流程见 `rules.md` 第十节；本文件是该章节的**唯一正文**（〇⑤）。
> **引用写法**：`三-7〔spec/deploy.md〕` 表示该章节正文在所注分卷；未注路径的编号在 `rules.md` 常驻层。

### 6. Git Worktree 协作
- **适用场景**：**单人单任务直接 clone 到 `repos.md` 登记路径，不启用 worktree**——worktree 的唯一目的是隔离同机多 agent 对同一项目的并发修改，无并发时启用它只增加清理负担。仅当两个及以上 agent 同时修改同一项目代码时，才按下述布局启用协作模式。
- **范围**：仅 `repos.md` 登记的项目代码仓库；**`~/.agent-shared` 禁用 worktree**（append-only 记忆与压缩机制依赖单一历史，分支化会使其失效）。
- **布局**：主 worktree `~/source/<项目名>`（跟踪 main，人类或共用者使用）；agent 专属 `~/source/<项目名>.wt/<agent名>/`，分支 `agent/<agent名>/<任务>`；同 agent 并发多会话/多任务时 worktree 目录扩展为 `<agent名>-<任务>`（见 三-5 ⑦）。
- **流程**：领任务后（先按 三-5 ⑤ 认领登记）`git worktree add ~/source/<项目名>.wt/<agent名> -b agent/<agent名>/<任务> origin/main` → 开发/构建/测试 → **分支准出**：`git pull --rebase origin main` 且自测（至少构建+冒烟）通过，commit 携带 `Agent: <agent名>` trailer，并以独立提交身份提交（`git -c user.name=zhn-<agent名> -c user.email=<agent邮箱> commit ...`）——**禁止用裸 `git config user.name/user.email`**：worktree 默认与主仓库共用 `.git/config`，会篡改主 worktree 的署名 → push 分支 → 人类合并 → `git worktree remove`。
- **生命周期**：会话结束即 remove，成果靠分支保留而非残留目录；月度压缩时主设备顺带 prune 并清理已合并的 `agent/*` 本地分支（三-2〔spec/memory-compaction.md〕 第 8 步）。**挂起例外**：任务挂起时默认 remove worktree、成果留在分支，并在 handoff 挂起快照「现场」栏登记分支名与基座；确需保留 worktree 须写明路径并禁止其他会话复用（三-4 ②）。
- **依赖**：Python venv 位于 `~/.agent-tools/venvs/`，跨 worktree 直接复用；`node_modules` 每 worktree 独立安装，依赖共享缓存 `~/.agent-tools/cache` 降低代价（pnpm 项目 store 天然共享）。

<!-- anchors：以下每行「|」后的文本须在本文件正文（本注释之外）与 global/rules.md 原位摘要壳中各逐字出现一次；改任一侧须同步另一侧（〇⑤ 受控例外二、第十节）。
三-6 | **单人单任务直接 clone 到 `repos.md` 登记路径，不启用 worktree**
三-6 | **`~/.agent-shared` 禁用 worktree**
三-6 | **禁止用裸 `git config user.name/user.email`**
三-6 | 会话结束即 remove，成果靠分支保留而非残留目录
三-6 | 任务挂起时默认 remove worktree、成果留在分支
-->

