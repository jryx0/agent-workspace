> **Source**: Extracted from `global/rules.md` (v3.0)
> **Audience**: Human repository owner only (**NOT required reading for Agents**).

# Human Device Initialization Checklist

1. 在 Gitee 建私有主库（`origin`）与 GitHub 私有备份库（`backup`），本地 clone 至 `~/.agent-shared` 并配置按 URL 走代理（禁止全局 git proxy），推送使用 `bash ~/.agent-shared/env/git-sync.sh`（`S5.1`）。
2. 安装系统级基线工具：Git、Python、Node.js（Windows 配套 Git Bash），首次执行 `bash ~/.agent-shared/env/tools-scan.sh --write` 生成设备工具清单（`[spec/toolchain.md#S4.4]`）。
3. 创建 `~/.agent-tools/{bin,venvs,hooks,mcp,cache,run,backups}`；复制 `env/.gitignore.template` 为共享仓 `.gitignore`；安装 `gitleaks` 到 `~/.agent-tools/bin/` 并配置全局链式 `core.hooksPath` 指向 `~/.agent-tools/hooks`（`[spec/secrets.md#S6.1]`）。
4. 按 `[spec/layout.md#S2.0b]` 命名本设备并登记至 `memory/devices/_devices.md`，创建 `memory/devices/<device>.md` 填写本机挂载与端口段；在 `env/agents.md` 登记 Agent 名与三段式账号标识（`[spec/accounts.md#S3.8b]`）。
5. 配置系统计划任务：MCP 自启（`env/start-mcp.sh` / `start-mcp.bat`）、`tmp/` 7 天清理、NAS 夜间冷备（`[spec/backup.md#S5.3]`）。
6. 配置统一文档同步工具（如 WPS 企业盘）指向 `~/.agent-docs`（或建符号链接），按 `[spec/layout.md#S2.3]` 与 `keys-checklist.md` 管理账号。
7. 对照 `keys-checklist.md` 手动分发本机所需密钥到 `~/.agent-shared/config/`（`[spec/secrets.md#S6]`）。
8. 配置公开市场 MCP（`env/mcp-config.json`）与定制 MCP（`env/mcp-registry.md`），登记项目仓库与属性表（`env/repos.md`，`[spec/projects.md#S7]`）。
9. 在 `memory/devices/_devices.md` 指定主设备（月度记忆压缩执行者，`[spec/memory-compaction.md#S3.2]`）。
10. 将 `env/execution-enforcement.md#L1` 粘贴到各平台每个账号的全局指令中；将 `env/project-AGENTS-hook.md` 首部块挂接到 `~/source/` 各标准项目；新开会话按 L3 验收。
