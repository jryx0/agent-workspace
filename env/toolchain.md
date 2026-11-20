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
2026-11-05 | zhn-tbxg2iah-win | 发现/卸载 | wrangler 4.157.0（原全局安装于 `~/.workbuddy/binaries/node/versions/22.22.2-6/node_modules`） | 未知来源（另一会话安装，未登记） | workbuddy@zhn-tbxg2iah-win | v1.8.4 ⑦ 存量整改：按 三-5 ②/四-4 ⑦ 判定全局安装不合规，`npm uninstall -g wrangler` 已卸载；`npm list -g` 与 `command -v` 均已确认清除
2026-11-05 | zhn-tbxg2iah-win | 安装（项目本地） | wrangler 4.157.0 → `~/source/prnmgt/worker/node_modules` | 包管理器（npm，项目 devDependency） | workbuddy@zhn-tbxg2iah-win | 新建 `worker/package.json` + `package-lock.json` 声明 devDependency 4.157.0，`.gitignore` 增加 `worker/node_modules/`；改动提交在 prnmgt 的 `agent/workbuddy/wrangler-localization` 分支（e5d01e8），待人类合并；调用方式改为在工作目录用 `npx wrangler`
2026-11-08 | zhn-tbxg2iah-win | 路径修正 + 补装 python3.exe | python 3.14.2（系统用户级，PATH 条目调整，非重装） | 复用 | workbuddy@zhn-tbxg2iah-win | 人类报「命令行/PowerShell 输 python 弹出『无法打开ms store 连接』」。根因：`%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe`（App Execution Alias 占位符，0 字节 reparse point）在用户 PATH 中排在真实解释器 `Python314\` 之前，故 cmd/PowerShell 命中占位符并触发 Store 跳转；实测 `Get-AppxPackage` 无微软商店版 Python（也无 AppExecutionAlias 注册项），占位符属历史残留。处置：① 重排用户级 PATH，将 `Python314\`、`Python314\Scripts`、`Python\Launcher` 提到最前，`WindowsApps` 移至末位（其余条目原相对顺序保持不变）；② 补装 `Python314\python3.exe`（复制 python.exe，python.org 安装器未附带），使 `python3` 命中真实解释器而非占位符。验证：新终端解析 python/python3/py/pip 均指向 Python314（3.14.2），pwsh 独立子进程实测通过；已 setx 广播 WM_SETTINGCHANGE。改前原值备份于 `~/.agent-tools/run/user-path-backup-20261108-202346.txt`。注：Git Bash 内 `python` 仍解析到托管运行时 3.13.14（WorkBuddy 会话注入 PATH 优先级更高），属预期，非本机 PATH 问题
2026-11-18 | zhn-tbxg2iah-win | 安装（工具区二进制，非全局） | lark-cli 1.0.100（飞书官方 CLI，`lark-cli.exe`） | 官方Release | workbuddy@zhn-tbxg2iah-win~zhn-x-w | 人类指令「按标准规范安装飞书 CLI，不全局安装」。绕开官方向导的两处违规步骤（`npm install -g @larksuite/cli` 与 `npx skills add -g`），直接取 GitHub Release `lark-cli-1.0.100-windows-amd64.zip`（sha256 `93118ca1992b4e5f1a40c14301f6fbde703d5e9160a9113099e409b4bd1c1d8d`，与包内 checksums.txt 一致）解压单文件到 `~/.agent-tools/bin/lark-cli.exe`，PATH 已含工具区，`--version` 验证通过。未装全局 Skills（先用 `--help`/三层命令取证）；未做 `config init`/`auth login`（须人类浏览器配合，凭证存 OS keychain，另在 keys-checklist 登记）。**未跑 `tools-scan.sh --write`**：stamp 未满 30 天（八-8），且 `memory/devices/tools-zhn-tbxg2iah-win.md` 有他人未提交改动（11-17 16:22 在 WSL 环境覆盖了 Windows 清单），按红线⑤不覆盖、不代提交；设备清单待人类处置该改动后另行刷新
2026-11-19 | zhn-tbxg2iah-win | 安装（Agent 工具区，非全局） | rustup 1.29.3 / rustc 1.100.0 / cargo 1.100.0 | 官方Release | copilot@zhn-tbxg2iah-win~zhn-x-w | pCryoxy PC-00，官方 `rustup-init.exe` SHA-256 `38027d51d69a5d05493627a0634dbea52d6cd793c8f072d2373d3f4163eec7db`；`--no-modify-path`；`CARGO_HOME=~/.agent-tools/runtimes/rust/cargo`、`RUSTUP_HOME=~/.agent-tools/runtimes/rust/rustup`；目标 `x86_64-pc-windows-msvc`、`aarch64-linux-android`、`x86_64-linux-android`
2026-11-19 | zhn-tbxg2iah-win | 安装（Agent 工具区，非全局） | Go 1.27.4 windows/amd64 | 官方Release | copilot@zhn-tbxg2iah-win~zhn-x-w | pCryoxy PC-00，`go1.27.4.windows-amd64.zip` SHA-256 `178ab98950ac69ab25069307dc6ade79f3816e414cce95b4da166a115cde1e7e`，安装到 `~/.agent-tools/runtimes/go`
2026-11-19 | zhn-tbxg2iah-win | 安装（Agent 工具区，非全局） | Temurin JDK 21.0.13+9 LTS | 官方Release | copilot@zhn-tbxg2iah-win~zhn-x-w | pCryoxy PC-00，Adoptium `OpenJDK21U-jdk_x64_windows_hotspot_21.0.13_9.zip` SHA-256 `a4dbaa05fca4bd89d84584e58c459bd732efebb1722af80ab13c6516832004f9`，安装到 `~/.agent-tools/runtimes/jdk-21`
2026-11-19 | zhn-tbxg2iah-win | 安装（Agent 工具区，非全局） | Android CLI 23.0.0 / Platform-Tools 37.0.1 / SDK Platform 36、37.0、37.2 / Build-Tools 36.0.0、37.0.0 / NDK 29.0.14206865 | 官方Release | copilot@zhn-tbxg2iah-win~zhn-x-w | pCryoxy PC-00，用户已批准 Android SDK 许可；Google 官方 command-line tools `commandlinetools-win-16111833_latest.zip`（154,957,218 B）与 sdkmanager 安装，`ANDROID_HOME=~/.agent-tools/android-sdk`；ADB `1.0.41`，NDK Clang `21.0.0`
2026-11-19 | zhn-tbxg2iah-win | 安装（Agent 工具区，非全局） | Gradle 9.6.1 | 官方Release | copilot@zhn-tbxg2iah-win~zhn-x-w | pCryoxy PC-00 Android 包装；官方 `gradle-9.6.1-bin.zip` SHA-256 `9c0f7faeeb306cb14e4279a3e084ca6b596894089a0638e68a07c945a32c9e14`，安装到 `~/.agent-tools/runtimes/gradle-9.6.1`
2026-11-20 | zhn-tbxg2iah-win | 安装（Agent 专用，非全局） | protoc 29.5 Windows x86_64 | 官方Release | copilot@zhn-tbxg2iah-win~zhn-x-w | PC-02 有条件批准 `f2dd377`；`https://github.com/protocolbuffers/protobuf/releases/tag/v29.5` 的 `protoc-29.5-win64.zip`，3,189,582 字节，本地观察 SHA-256 `633d3e555fc97f0a1f55b4adb03256cd94b8059e51e7abbae98ff39e58a9dfa5`（非官方 digest）；`~/.agent-tools/venvs/copilot/protoc-29.5-win64/bin/protoc.exe`，实测 `libprotoc 29.5`；不改 PATH；扫描 stamp 未满 30 天，未运行 `--write`
2026-11-20 | zhn-tbxg2iah-win | 安装（Agent 专用，非全局） | Rust 1.100.0 Linux x86_64 GNU：rustc、cargo、rust-std | 官方Release | copilot@zhn-tbxg2iah-win~zhn-x-w | PC-17 用户批准，WorkBuddy 条件审核 `d5694f1`、许可证裁定 `295d1b0`；三包官方 SHA-256 核验后安装于 `~/.agent-tools/runtimes/copilot/linux-x86_64-gnu/rust-1.100.0/`，显式 `--disable-ldconfig`，未修改全局 PATH；154 个文件合计 627,328,398 字节（表观大小）；许可 L2 盘点及执行版本验证未完成，暂不投入构建；详情见 PC-17 交接。
```

## 六、设备清单索引

| 设备 | 清单文件 | 上次扫描 | 备注 |
|---|---|---|---|
| zhn-tbxg2iah-win | `memory/devices/tools-zhn-tbxg2iah-win.md` | 2026-11-19 17:59 | 首发设备；rclone 按决策不装（NAS 自带云同步直推百度网盘）；用户级 PATH 的 node 目录已修正为 `22.22.2-6`（方案 A，复用已装版本）；PC-00 专用 Rust/Go/JDK/Android/Gradle 位于 `~/.agent-tools/runtimes` 与 `~/.agent-tools/android-sdk`，详情见 §五 |

> 新设备接入时：① 在此表追加一行；② 执行 `AGENT_DEVICE=<设备名> bash env/tools-scan.sh --write`；③ 提交并 `git sync`。
