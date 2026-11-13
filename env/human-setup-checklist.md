> **来源**：`global/rules.md` v2.5 §九「人类用户的初始化清单（供参考）」
> **读者**：人类，不是 agent。**agent 不得把它当作开工必读**。
> **状态**：v2.6（2026-11-13）起自 `global/rules.md` 移出至此。

## 九、 人类用户的初始化清单 (供参考)

1. 在 Gitee 建私有仓库 `agent-workspace`（主库），在 GitHub 建私有备份仓库，本地 clone 后添加双远端并配置 `git-sync` 推送脚本（见 五-1）。
2. 在系统层面装好 Python、Node.js、Git、rclone（Windows 上另装 Git Bash，随 Git for Windows 自带）。
3. 创建 `~/.agent-tools` 目录，初始化 `venvs`、`mcp`、`bin`、`run` 等子目录。
4. 在 `env/` 下编写一键安装依赖的 `setup.sh`（Linux/Termux）与对应 Windows 脚本，及 `start-mcp.sh` 与 Windows 版 `start-mcp.bat`；将 `env/.gitignore.template` 复制为仓库根目录 `.gitignore`；每台设备安装 gitleaks 并配置 pre-commit hook（见 六-1）。
5. 按 二-0.5 命名本设备并登记进 `memory/devices/_devices.md`，同时在本机 `memory/devices/<设备名>.md` 写入本机挂载映射与端口信息。
6. 建立 Windows 侧的 PowerShell 计划任务：MCP 开机自启、`tmp/` 7 天清理、夜间百度网盘备份（含 `git bundle`）。
7. 选定统一的文档同步工具（建议坚果云），安装并配置全部接入设备，将本地同步目录指向 `~/.agent-docs`（或建符号链接），凭证按 六 手动分发。
8. 参照 `keys-checklist.md` 将密钥手动复制到新设备 `config/`，并逐项核对。
9. 在 `env/mcp-config.json` 配置公开市场 MCP；手动安装的定制 MCP 逐条登记进 `env/mcp-registry.md`。
10. 在 `env/repos.md` 登记所有项目代码仓库地址，并为每个项目填写「项目属性补充表」（见 七-1）。
11. **指定主设备**（负责月度记忆压缩）并写入设备登记表。
12. 按 〇① 为每个账号配置平台全局指令、按 〇② 为 `~/source/` 下各项目挂接 `AGENTS.md`，再按 〇④ 新开任务验收（不再逐个发送规范全文）。
