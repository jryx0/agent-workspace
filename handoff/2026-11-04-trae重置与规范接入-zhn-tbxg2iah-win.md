# 交接：Trae 私有记忆重置 + 规范 v1.7 接入

- 设备：zhn-tbxg2iah-win（主设备暂定）
- Agent：workbuddy@zhn-tbxg2iah-win
- 时间：2026-11-04 17:14 UTC+8
- 工作区：`~/.agent-shared`（无 worktree；主 worktree 即工作区本身）
- 分支：main（跟踪 origin/main，与 backup/main 同步）

## 当前状态

已完成「重置 Trae 侧私有状态 + 按规范 v1.7 执行」这一轮动作。`~/.agent-shared` 结构、双远端、密钥副本、本机档案均已就绪，本轮未新增目录变更。

## 已完成

1. **Trae 私有记忆清空**：删除 `C:\Users\Zhn_X\.trae-cn\memory\projects\<本项目>\20261104\topics.md`，即本项目在 Trae 内的长期记忆已归零，后续上下文一律以 `~/.agent-shared` 为唯一事实源。
2. **规范校验**：`~/.agent-shared/global/rules.md` 与人类本轮下发的 v1.7 一致（版本号、变更记录、三-6 worktree 条款均在），无需覆盖。
3. **启动自检（规范八）结果**：
   - 记忆目录正常；`config/` 含 5 个私钥文件，与 `keys-checklist.md` 登记项一一对应；
   - `env/agents.md` 已登记 workbuddy｜zhn-tbxg2iah-win；
   - `memory/.compact-lock` 不存在，可正常写入记忆；
   - `~/.agent-tools/venvs/workbuddy` 存在（本会话未涉及 Python，未激活）；
   - `~/.agent-docs` 存在（本地普通目录，22 文件；同步载体仍待人类选定，见下方待办）；
   - `git pull --rebase` 结果 Already up to date；
   - **MCP 9101/9102 均未监听** → 需人类执行 `env/start-mcp.bat`（或对应计划任务）。

## 待办

1. **MCP 服务未启动**：9101（文件系统）、9102（Git）端口无监听，`env/mcp-config.json` 仍为空配置。
2. **repos.md 未登记任何项目**：打印机监控项目代码未入表；需补 Git 地址、默认分支、本地克隆路径后再按规范七处理。
3. **线上前端疑似双份部署待核**：人类反馈 `https://prnmgt.parva.dpdns.org/#/overview` 刷新后出现「脚本未执行：页面骨架已下发，但模块脚本没有运行」，且该文案在本仓库代码中不存在；而 `worker/wrangler.toml` 绑定的是 `printer.parva.dpdns.org`（无 hash 路由）。判断为另一套 SPA 前端（或新 Worker）在跑，需先确认域名与部署归属，再定位首屏/路由时序问题。
4. **~/.agent-docs 同步载体未定**：WPS 方案已放弃（2026-11-04 事故复盘见 org.md），`docs://` 目前仅本机可解析。
5. **gitleaks/rclone 状态**：gitleaks 已装并配 pre-commit；rclone 按决策不安装（冷备走 NAS 自带云同步）。

## 关键文件

- `global/rules.md` — 规范 v1.7（唯一事实源）
- `memory/org.md` — 组织级记忆（append-only，已追加本轮条目）
- `memory/devices/zhn-tbxg2iah-win.md` — 本机路径/NAS/代理/端口登记
- `env/agents.md`、`env/repos.md`、`env/mcp-registry.md`、`env/mcp-config.json`
- `keys-checklist.md`

## 下一步指令

1. 人类运行 `env/start-mcp.bat`，随后由 agent 复核 9101/9102 可达；
2. 提供打印机监控项目的 Git 地址，补登记 `env/repos.md` 与 `memory/projects/打印机监控.md`；
3. 确认 `prnmgt.parva.dpdns.org` 与 `printer.parva.dpdns.org` 各自承载的部署（哪套是现行前端），再排查 `#/overview` 刷新异常。
