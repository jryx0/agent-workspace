> **Source**: `global/rules.md` spec volume (v3.0, synced with `rules.md`)
> **Section**: `S3.2`
> **Trigger**: 执行月度记忆压缩、人类临时指定压缩、处理 `memory/archive/` 或 `handoff/archive/` 时
> **Authority**: 与 `rules.md` 同等效力，受 `R4` 保护；修订见 `[spec/governance.md#S9]`。

## S3.2 Memory Compaction

- **S3.2a 唯一改写例外**：记忆压缩是**唯一允许改写/截断记忆文件的机制**，且仅限人类指定的**主设备**在压缩窗口内执行；窗口外任何改写历史行均违规。
- **S3.2b 周期与保留期**：每月 1 次（人类发起，建议首周末），`memory/` 与 `handoff/` 保留期统一为 **90 天**并同批次归档。人类临时指定的压缩不受 90 天与频次限制（见 `S3.2e`）。
- **S3.2c 锁协议**：压缩前先创建 `memory/.compact-lock`（写设备名 + ISO 时间戳）并**单独 commit + push**。其他设备自检（`S8.1`）发现锁即暂停写入记忆直至锁删。压缩完成时，删锁与压缩结果在同一个 commit 推送。
- **S3.2d 标准流程（按序执行，窗口 ≤30 分钟）**：
  1. 按 `S5.1` 拉取最新（若有他人未提交改动且本地落后，遵守 `R5` 中止并报告人类）；
  2. 创建并推送 `memory/.compact-lock`；
  3. 读取 `memory/org.md` 及各项目记忆全量；
  4. 将超 90 天条目提炼为摘要写入新建 `memory/archive/YYYY-MM.md`（保留结论、关键链接与未结事项），将超 90 天 handoff 移入 `handoff/archive/YYYY-MM/`；核对 `memory/suspended.md`，确保未解挂项不会随归档丢失（仍在 `memory/suspended.md` 保留并在当月摘要引用）；
  5. 截断 `org.md` 为「归档指针 + 保留期内原始条目」，同 commit 删除 `memory/.compact-lock`；
  6. 执行 `env/git-sync.sh` 推送，commit 格式：`memory: compact YYYY-MM by <agent>@<device>[~<account>]`；
  7. 备份验证：在临时目录对 `backup` 远端执行 `git clone --depth 1` 确认可用后删除临时目录；
  8. 维护项目 worktree：对本机 `~/source/` 各项目执行 `git worktree prune`，清理已合并的 `agent/*` 本地分支（`[spec/worktree.md#S3.6]`）。
- **S3.2e 临时压缩（人类指定窗口）**：
  - 须人类明确给出范围（文件清单）与截止点（时间或条目）；授权仅当次有效，不明确先问人类。
  - 按 `S3.2d` 第 1-3、5-7 步执行；摘要写入新建 `memory/archive/YYYY-MM-DD-<范围>.md`，逐条保留截止点前未结事项（doing/blocked/suspended/待裁定）；被截断文件首行写归档指针与截止点，末尾追加登记行；handoff 仅人类点名时归档，第 8 步可跳过。
- **S3.2f 归档只读**：`memory/archive/` 与 `handoff/archive/` 下文件**一经写入即为只读**，后续不得改写旧归档，新周期新建文件。
