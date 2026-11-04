# 设备档案：zhn-tbxg2iah-win

- hostname: Zhn-TBXG2IAH
- os: win（Windows，Git Bash 为主、PowerShell 为辅，不使用 WSL）
- **角色：主设备（2026-11-04 暂定，负责月度记忆压缩；人类注明后续会改）**
- 运行时: Git 2.55.0 / Python 3.13.14 / Node v22.22.2
- 工具: gitleaks v8.30.1（~/.agent-tools/bin，已加入用户 PATH；全局 core.hooksPath 指向 ~/.agent-tools/hooks 的 pre-commit）；rclone **不安装**——百度网盘冷备改用 NAS 自带云同步工具（人类在 NAS 侧配置）
- 路径映射:
  - `~/` → `C:\Users\Zhn_X\`
  - `~/.agent-shared` → `C:\Users\Zhn_X\.agent-shared`
  - `~/.agent-tools` → `C:\Users\Zhn_X\.agent-tools`
  - `~/.agent-docs` → `C:\Users\Zhn_X\.agent-docs`（同步工具待人类选定，建议坚果云）
- `nas://` 解析: → `Z:\`（Git Bash `/z/`，SMB 已挂载，2026-11-04 验证可达，总容量 22T）
- 端口登记:
  - 9101 MCP 文件系统（规范保留，未启动）
  - 9102 MCP Git 操作（规范保留，未启动）

