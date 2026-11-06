# 交接单 · 新 agent 接入提示模板（对齐 v1.8.8）

| 项 | 值 |
|---|---|
| 时间 | 2026-11-06 11:06 UTC+8 |
| 执行 agent | workbuddy @ zhn-tbxg2iah-win |
| 状态 | 已完成，随本单一起 commit + git sync |
| worktree / 分支 | 无（改动仅在 `~/.agent-shared`，规范三-6 明确该仓库禁用 worktree） |
| 基线 | `7a49b76`（local = origin = backup） |

## 已完成

- 核对 rules.md 更新：当前 **v1.8.8**（`79ea957`），新增**三-7 部署权限与审核后处置**；标题与变更记录同步，其余章节无改动。
- 新建 `env/new-agent-bootstrap.md`：一次性开场提示词模板（按 〇⑤ 单一原件，只放入口指针 + 红线清单，不复制条款正文），含提示词正文 7 节 + 验收清单 + 版本对齐记录。
- 与上一轮聊天版提示词的差异：补齐三-7 部署权限全章、校准四-5 平台能力优先 / 三-5 ⑦ 同 agent 多会话并发 / 八-8 工具链核对、加 Windows 绝对路径笔误容错与 `git pull` 遇他人未提交改动时的降级报告。
- 同步追加 `memory/org.md` 组织记忆一条。

## 自检（规范八）

| 步 | 结果 |
|---|---|
| 1 | `memory/`、`config/` 存在；`config/` 5 项齐；`keys-checklist.md` 6 行（含表头） |
| 2 | **[Agent报告]** MCP 9101 返回 HTTP 000，服务未启动 → 需人类运行 `env/start-mcp.bat` |
| 3 | 只读比对 local / origin / backup HEAD 均为 `7a49b76`，一致；因他人有未提交改动，**未执行 `pull --rebase`** |
| 4 | 无 `memory/.compact-lock`，可正常写记忆 |
| 5 | `VIRTUAL_ENV` 未激活（本会话无 Python 依赖需求） |
| 6 | `env/mcp-registry.md` 5 行；本会话不需要定制 MCP |
| 7 | **[Agent报告]** `~/.agent-docs` 为本地普通目录（6 文件），同步载体未选定，`docs://` 仅本机可解析 |
| 8 | `tools-scan.sh --check` 通过（stamp `2026-11-05 09:03:31`，未满 30 天，未重复全量扫描） |
| 9 | 已通读 `global/rules.md` 全文，规范注入确认通过 |

## 待办 / 下一步

1. 人类在 WorkBuddy 设置中把全局指令第 1 条路径 `C:\Users\Zhn_X.agent-shared\global\rules.md` 改为 `~/.agent-shared/global/rules.md`（`Zhn_X` 后少一个反斜杠，新会话会读不到）。
2. 下次规范升版（须人类批准）时，把 `env/new-agent-bootstrap.md` 补进二-1 `env/` 目录树与 〇① 模板清单。
3. 按 〇④ 新开任务发「开工前按规范自检」验收注入效果，通过后追加一条 `org.md` 记录。
4. MCP 9101 / 9102 骨架仍待人类启动。

## 关键文件

- `env/new-agent-bootstrap.md` — 本次新增，可直接复制给新 agent
- `env/project-AGENTS-hook.md` — A 全局指令 / B 项目挂接 / C 验证清单
- `global/rules.md` — 唯一权威（v1.8.8）
- `memory/org.md` — 本次追加一条组织记忆
