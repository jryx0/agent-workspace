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
  - `~/.agent-docs` → `C:\Users\Zhn_X\.agent-docs`（本地普通目录，同步载体待定，见下方更正节）
  - `~/source` → `C:\Users\Zhn_X\source`（**项目代码根，规范 v1.8**；主 worktree `~/source/<项目名>`，agent worktree `~/source/<项目名>.wt/<agent名>/`；不入 Git）
- **agent 端口段分配（v1.8）**: trae=9200-9299，workbuddy=9300-9399；保留 9101/9102 为 MCP
- `~/.agent-docs` 映射（文档同步区）:
  - 同步工具: **WPS 网盘（企业版，中建三局）**，以共享文件夹方式单独同步
  - 实际联接: `~/.agent-docs`（Junction）→ `C:\Users\Zhn_X\WPSDrive\1645591772\WPS企业云盘\中建三局\我的企业文档\agent-docs`
  - `docs://<路径>` → 解析到 `~/.agent-docs/<路径>`（2026-11-04 联接读写测试通过）
  - ⚠️ **WPS 网盘无 Linux 同步客户端**：Linux/Termux 设备上 `docs://` 引用不可直接解析，走金山文档网页版手动获取，或经 NAS 中转

> **【更正 2026-11-04 17:10】** 上方 WPS 联接映射已废弃：WPS 同步方案放弃（配置冲突事故，复盘见 org.md 同日条目）。当前 `~/.agent-docs` = 本地普通目录（22 文件，内容完整），WPS 企业云盘侧已清空。`docs://` 引用仅本机可解析；同步载体待人类重新选定（候选：坚果云等），选定后更新本节。

- `nas://` 解析: → `Z:\`（Git Bash `/z/`，SMB 已挂载，2026-11-04 验证可达，总容量 22T；规范目录 `Z:\backup\`、`Z:\docs\` 已创建）
- 网络代理: github.com 走 SOCKS5 代理 `socks5://127.0.0.1:10808`（git 全局作用域配置 `http.https://github.com.proxy`，2026-11-04 已验证；Gitee 直连不受影响。代理客户端未运行时 GitHub 推拉会失败，届时先启动代理）
- 密钥: config/ 暂未分发；核对清单含 putty-oraclevps.ppk、putty-printer-monitor.ppk 两项（待人类复制）
- 端口登记:
  - 9101 MCP 文件系统（规范保留，未启动）
  - 9102 MCP Git 操作（规范保留，未启动）

