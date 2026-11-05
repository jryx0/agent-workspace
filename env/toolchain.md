# 工具链基线登记表（规范 四-4，v1.8.3 新增）

> 本文件只登记**跨设备通用基线与工具变更日志**；某台设备实际装了什么、什么版本，见 `memory/devices/tools-<设备名>.md`（由 `env/tools-scan.sh --write` 自动生成，勿手工编辑）。
> 二进制文件本身**永不入库**（在 `.gitignore` 之内）；本文件只记"该装什么、什么版本算够、从哪来"。

## 一、三类工具，登记去处不同

| 类别 | 例子 | 登记去处 |
|---|---|---|
| **系统级基线**（跨设备必须一致） | git / python / node / npm / gh / curl / unzip / ssh | 本文件 §二 基线表 |
| **工具区二进制**（单文件，放 `~/.agent-tools/bin`） | gitleaks / rclone / jq | 本文件 §二 + 设备清单（含来源与路径） |
| **项目或 venv 依赖** | pip 包、node_modules | `env/requirements.txt` / 项目自身 lock 文件（不在本表） |
| **MCP 服务** | filesystem / git 等 | `env/mcp-registry.md`（不在本表） |
| **桌面客户端**（人类环境） | WPS、PuTTY、NAS 映射、网盘 | `memory/devices/<设备名>.md`（不在本表） |

## 二、跨设备基线表

`必需` = 不满足则无法按规范运行；`可选` = 按需安装。版本为**最低要求**，高于基线一律直接复用。

| 工具 | 最低版本 | 必需性 | 用途 | 推荐安装方式 |
|---|---|---|---|---|
| git | >= 2.40 | 必需 | 版本控制、双远端同步、worktree | 系统包管理器 / Git for Windows |
| python | >= 3.11 | 必需 | 专属 venv、脚本 | 系统包管理器 / 官方安装包 |
| node | >= 20 | 必需 | 前端与工具链 | 系统包管理器 / nvm |
| npm | 随 node | 必需 | Node 包管理 | 随 node |
| gitleaks | >= 8.20 | 必需 | pre-commit 密钥扫描（六-1） | 官方 GitHub Release（校验版本号） |
| curl / unzip | 任意 | 必需 | 下载与解压 | 系统自带 / 包管理器 |
| ssh / ssh-keygen | 任意 | 必需 | 服务器登录、密钥管理 | 系统自带 / OpenSSH |
| gh | 任意 | 可选 | GitHub 操作、PR | 官方 Release / 包管理器 |
| pnpm | 任意 | 可选 | 前端包管理 | npm / corepack |
| jq | 任意 | 可选 | JSON 处理 | 包管理器 / 官方 Release |
| rclone | 任意 | 可选 | 云存储冷备（**本机按决策不装，走 NAS 自带云同步**） | 官方 Release |
| docker | 任意 | 可选 | 容器化开发 | 官方 Docker Desktop |
| ffmpeg | 任意 | 可选 | 音视频处理 | 官方 Release / 包管理器 |

## 三、来源类型枚举（登记时必填其一）

| 取值 | 含义 | 处置 |
|---|---|---|
| `复用` | 本机已装且满足基线，直接使用 | **首选路径**，禁止重复下载安装 |
| `包管理器` | 由 winget / apt / brew / scoop 等安装 | 记录包名，便于升级与复现 |
| `官方Release` | 从项目官方 Release 页下载 | 必须记录版本号与下载 URL |
| `未知来源` | 绿色版、他人拷贝、无可验证出处 | 可直接用；**密钥相关工具须核验哈希或换官方来源** |

## 四、三条硬规则

1. **探测优先，缺失才装**：任何安装动作前先 `command -v <tool>` + `<tool> --version`；满足基线即登记为 `复用`，**禁止无谓重复安装**（省时间，也避免同机多版本互相干扰）。
2. **首次扫描一次，之后增量**：新设备或新 agent 首次运行时执行一次 `env/tools-scan.sh --write`，生成设备清单并刷新 stamp（`~/.agent-tools/run/tools-scan.stamp`）。此后 **30 天内不再全量扫描**，自检只跑 `--check`（比对基线）；超过 30 天再全量刷新。
3. **新装 / 升级 / 卸载必须登记**：执行 `tools-scan.sh --write` 刷新设备清单，并在本文件 §五 追加一行变更日志（只追加，不改旧行）。**未登记的安装视为不合规**。

补充约束：
- 工具二进制不入 Git；`~/.agent-tools/bin` 为唯一工具区，禁止散落到项目目录。
- 安装来源只认官方 Release 或系统包管理器；来路不明的二进制不得用于处理密钥。
- **不登记** `pip list` / `npm ls` 这类完整包列表（数百行噪音），只登记 agent 干活真正依赖的工具。
- 多版本并存时，设备清单里注明"默认解析哪个"，否则 agent 会用错解释器装包。
- **PATH 可见性按会话而异**：不同 agent 会话注入的 PATH 可能不同（尤其 WorkBuddy 托管的 node/python 运行时）。`tools-scan.sh` 会额外探测托管运行时的磁盘路径，命中即标记「⚠️ 已装但当前 PATH 不可见」而**不是「❌ 未安装」**——这类情形**禁止重复安装**（四-4 ①），处置方式是注入 PATH 或用绝对路径调用。`--check` 不把 PATH 差异计为基线失败。

## 五、工具变更日志（append-only，最新在下）

> 格式：`YYYY-MM-DD | 设备 | 操作(安装/升级/卸载) | 工具 版本 | 来源类型 | 操作者 | 备注`

```
2026-11-04 | zhn-tbxg2iah-win | 安装 | gitleaks 8.30.1 | 官方Release | workbuddy@zhn-tbxg2iah-win | 全局 pre-commit 密钥扫描（六-1），装至 ~/.agent-tools/bin
2026-11-04 | zhn-tbxg2iah-win | 安装 | git 2.55.0 / python 3.13.14 / node 22.22.2 / gh 2.101.0 | 复用 | workbuddy@zhn-tbxg2iah-win | 首次清点（初始化前已存在，登记为复用）
2026-11-05 | zhn-tbxg2iah-win | 安装 | 工具链基线机制本身（tools-scan.sh + toolchain.md） | - | workbuddy@zhn-tbxg2iah-win | v1.8.3 首次全量扫描，可用 11 / 未装 5
2026-11-05 | zhn-tbxg2iah-win | 路径修正 | node/npm 22.22.2-6（PATH 条目，非重装） | 复用 | workbuddy@zhn-tbxg2iah-win | 人类选方案 A：用户级 PATH 中失效的 `versions\24.14.0`（目录不存在）改为磁盘实存的 `22.22.2-6`；无下载、无新装；复测 --check 通过，设备清单已 --write 刷新（trae 交接 2026-11-05-工具链node-PATH失效 处置完毕）
```

## 六、设备清单索引

| 设备 | 清单文件 | 上次扫描 | 备注 |
|---|---|---|---|
| zhn-tbxg2iah-win | `memory/devices/tools-zhn-tbxg2iah-win.md` | 2026-11-05 08:40 | 首发设备；rclone 按决策不装（NAS 自带云同步直推百度网盘）；用户级 PATH 的 node 目录已修正为 `22.22.2-6`（方案 A，复用已装版本） |

> 新设备接入时：① 在此表追加一行；② 执行 `AGENT_DEVICE=<设备名> bash env/tools-scan.sh --write`；③ 提交并 `git sync`。
