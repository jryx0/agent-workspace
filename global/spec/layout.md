> **Source**: `global/rules.md` spec volume (v3.0, synced with `rules.md`)
> **Section**: `S2` (`S2.0`, `S2.0b`, `S2.1`, `S2.2`, `S2.3`)
> **Trigger**: 新建目录、判断文件落点、接入新设备、处理 `~/.agent-docs` 同步或 `docs://` 引用时
> **Authority**: 与 `rules.md` 同等效力，受 `R4` 保护；修订见 `[spec/governance.md#S9]`。

## S2. Directory Layout

### S2.0 Path Mapping Baseline
所有规范与脚本一律使用 `~/` 逻辑路径，**禁止写死绝对路径**：

| Logical Path | Linux / Termux | Windows (Git Bash) | Windows (Native) |
|---|---|---|---|
| `~/` | `$HOME` (`/home/<user>`) | `/c/Users/<user>` | `C:\Users\<user>\` |
| `~/.agent-shared` | `/home/<user>/.agent-shared` | `/c/Users/<user>/.agent-shared` | `C:\Users\<user>\.agent-shared` |
| `~/.agent-tools` | `/home/<user>/.agent-tools` | `/c/Users/<user>/.agent-tools` | `C:\Users\<user>\.agent-tools` |
| `~/.agent-docs` | `/home/<user>/.agent-docs` | `/c/Users/<user>/.agent-docs` | `C:\Users\<user>\.agent-docs` |
| NAS Mount | `/mnt/nas` | `/z` (`Z:\`) | `Z:\` |

- PowerShell 中 `~/` 等价 `$HOME`；移动端不落本地工作区，只读边界见 `[spec/toolchain.md#S4.3]`。

### S2.0b Device Naming
- 格式：`<hostname>-<os>`，**全小写**，无空格与非 ASCII 字符；`os` 枚举：`win` / `linux` / `macos` / `android` / `termux` / `harmony` / `ios`，对应账号 OS 段（`[spec/accounts.md#S3.8b]`）：`win→w`、`linux→l`、`macos→m`、`android/termux→a`、`harmony→h`、`ios→i`；WSL 沿用宿主 `win` 设备、OS 段取 `wl`。已登记设备名不改；重名追加序号。
- 用于三处：`memory/devices/<device>.md`、handoff 后缀（`S3.4a`）、署名 `@<device>`（`S3.1c`）。
- **设备总登记表** `memory/devices/_devices.md` 字段：`设备名 | os | 设备简标 | OS段 | 是否主设备 | nas 挂载能力 | 备注`。**新设备先登记，后使用**。

### S2.1 Shared Workspace (`~/.agent-shared`)
**只存放文本、代码、配置和记忆，严禁存放大型二进制包和依赖环境。**

```text
~/.agent-shared/
├── global/
│   ├── rules.md                     # 常驻总规范 (v3.0)
│   └── spec/                        # 按需分卷 (S2/S3.2/S3.6/S3.7/S3.8/S4/S5.2/S6/S7/S9)
├── memory/                          # 长期记忆
│   ├── suspended.md                 # 全项目挂起任务唯一权威状态表 (S3.4b)
│   ├── org.md                       # 组织级记忆 (append-only)
│   ├── projects/                    # 各项目独立记忆 (append-only)
│   ├── devices/                     # 设备档案 + _devices.md + tools-<device>.md
│   └── archive/                     # 只读归档与变更历史
├── skills/                          # 共享技能唯一权威原件
├── handoff/                         # 交接摘要 (≤2KB)
│   ├── notes/                       # 超长核查/裁定/设计过程文档
│   └── archive/                     # 只读归档
├── env/                             # 脚本、登记表、模板
│   ├── startup-check.sh             # T2 一键只读自检脚本 (S8.1)
│   ├── git-sync.sh                  # 内置 proxy-check 的双远端推送 (S5.1b)
│   ├── proxy-check.sh               # 代理与双远端只读核对
│   ├── tools-scan.sh                # 工具链探测与基线核对 (--check / --write)
│   ├── install-skill.sh             # 共享技能一键分发与漂移校验
│   ├── rules-lint.sh                # 规范一致性只读校验 (S9)
│   ├── agents.md                    # Agent 与账号登记表
│   ├── repos.md                     # 项目仓库与属性登记表
│   ├── toolchain.md                 # 工具链基线与变更日志
│   ├── kb-endpoints.md              # 文档知识库外部端点/索引表坐标配置
│   ├── requirements.txt             # 通用 Python 依赖清单
│   ├── mcp-config.json / mcp-registry.md
│   ├── execution-enforcement.md     # L1/L2/L3 执行保障方案与 L1 原件
│   ├── project-AGENTS-hook.md       # 项目挂接块与验证模板
│   ├── new-agent-bootstrap.md       # 新 Agent 接入短提示词
│   ├── handoff-suspended-template.md # 挂起/解挂操作模板
│   ├── human-setup-checklist.md     # 人类初始化清单（非 Agent 必读）
│   ├── start-mcp.sh / start-mcp.bat
│   └── .gitignore.template
├── keys-checklist.md                # 本机 config/ 密钥存在性清单（不含密钥值）
├── tmp/                             # 本机临时区（不入 Git，按 agent/account/session 隔离）
└── config/                          # 本机密钥与凭据（不入 Git，人类手动分发）
```

### S2.2 Local Tools (`~/.agent-tools`)
本机物理执行环境根，不入 Git：
- `bin/`：工具区单文件二进制（加入 `PATH`，如 `gitleaks`、`lark-cli`）
- `venvs/<agent>/`：按 Agent 隔离的 Python 虚拟环境
- `hooks/`：全局 `core.hooksPath`（链式委托 gitleaks）
- `mcp/`：本机定制 MCP 源码与安装目录
- `cache/`：包管理器缓存（`pip/`、`npm/`）
- `run/`：运行态文件（`git.lock`、`tools-scan.stamp`、`self-check/`、PID/日志）
- `backups/`：技能覆盖前自动备份目录

### S2.3 Active Documents (`~/.agent-docs`)
- **定位**：存放跨设备频繁查看/编辑的**重要文档原件**（建议单文件 ≤100MB，不进 Git）。
- **单一原件与同步机制**：
  - 同一份文档只在 `~/.agent-docs` 保留唯一原件；严禁与 NAS 或云盘形成双活。
  - **跨设备原件同步**由人类选定的**统一第三方同步工具**负责（本机现行工具与账号见 `memory/devices/<device>.md` 与 `keys-checklist.md`；如同步工具不支持自定义目录，通过符号链接映射至 `~/.agent-docs`）。全部接入设备须使用同一同步工具。
  - **在线预览与检索索引**由飞书云空间（单向只读预览副本）+ 飞书多维表格（元数据索引）承担，**对外交付**由百度网盘副本承担，**异地冷备**由 NAS 链路独占；以上三者均为派生副本或索引，**禁止反向覆盖 `~/.agent-docs` 原件**（操作细则见 `skills/official-doc/zhn-docs-kb/SKILL.md`，命名细则见 `skills/official-doc/zhn-docs-std/SKILL.md`）。
- **引用与删除**：
  - 记忆/交接中统一写 `docs://<相对 ~/.agent-docs 路径>`（文本约定，不写本机绝对路径）。
  - 同步目录内物理删除与冲突处置一律交人类在同步客户端 UI 完成（`R3`）。
  - 移动端通过同步工具 App 或飞书只读副本访问文档；超大文件/视频/一次性归档放 NAS（`[spec/backup.md#S5.2]`）。
