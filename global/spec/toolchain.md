> **来源**：`global/rules.md` 的分卷（v2.6 起拆出；**不单独编号**，随 `rules.md` 版本生效）
> **原编号**：四（含 四-1～四-5）
> **触发**：安装／升级／卸载任何依赖或工具、新增 MCP、跑工具链核对、遇到 `venv` 或全局安装判断时
> **效力**：与 `rules.md` 同等，受最小红线④保护，修订流程见 `rules.md` 第十节；本文件是该章节的**唯一正文**（〇⑤）。
> **引用写法**：`三-7〔spec/deploy.md〕` 表示该章节正文在所注分卷；未注路径的编号在 `rules.md` 常驻层。

## 四、 工具与 MCP 机制

### 1. 依赖与运行时安装纪律
- **系统级共享**：Python/Node.js/Git 等基础运行时系统安装一份即可。
- **环境隔离**：Agent 专属的 Python 依赖必须安装在 `~/.agent-tools/venvs/你的agent名字/` 中；**Node/项目级 CLI 依赖必须装在项目的 `node_modules/` 并由项目 lock 文件声明**（见 四-4 ⑦），不得装进共享全局前缀（三-5 ②）。venv 按 **agent 名** 隔离、不按会话隔离：同一 agent 名的多个会话共用同一份，通用库的放置与复用细则见 **四-5**。
- **禁止违规存放**：严禁在 `~/.agent-shared` (Git 工作区) 内部创建任何 `venv` 或 `node_modules`。
- **Windows Shell 选型**：
  - **Git Bash 为主**：负责运行 `env/` 下全部 `.sh` 脚本（`start-mcp.sh`、`tools-scan.sh`、`proxy-check.sh`、`git-sync.sh` 等），保证与 Linux/Termux 单套脚本通用，且 `~` 解析与本规范一致；
  - **PowerShell 为辅**：仅用于 Windows 原生**计划任务**的注册与调度（MCP 开机自启、`tmp/` 7 天清理、夜间备份），以及在脚本中调用 `rclone.exe`；
  - **工作区不进 WSL**：WSL 会产生第二个独立的 `~`（位于 ext4 虚拟磁盘内），将工作区劈成两份、破坏"唯一工作区在 `C:\Users\<user>\`"的约定——**禁止在 WSL 内建立或使用 `~/.agent-shared`、`~/.agent-tools`、`~/.agent-docs`、`~/source` 的第二份副本**。确需在 WSL 内运行 agent 时，须先经人类登记（账号标识 OS 段取 `wl`，见 三-8 ②〔spec/accounts.md〕），且只访问 Windows 侧唯一工作区，未登记不得运行。

### 2. MCP 分级管理
- **同机多 Agent 共享**：需要使用文件／Git 类 MCP 工具时，同机 Agent **连接同一个本地 MCP SSE 服务**，**禁止各起 stdio 进程抢文件**；不需要时不必连接，使用平台内置工具即可。服务只绑定 `127.0.0.1`，**不对外网/局域网暴露**。
  - 默认地址：`http://127.0.0.1:9101/sse` (文件系统，访问根目录限制为 `~/.agent-shared` 与 NAS 挂载点)
  - 默认地址：`http://127.0.0.1:9102/sse` (Git 操作)
- **公开市场 MCP**：统一配置在 `env/mcp-config.json`，随 Git 同步。各设备执行 `start-mcp.sh`（或对应 Windows 计划任务）时按配置自动拉起。
- **定制 MCP（手动安装）**：源码不参与同步。安装后**必须**在 `env/mcp-registry.md` 登记，每条包含：

  ```
  | 名称 | 用途 | 来源(仓库/下载地址) | 安装命令 | 版本 | 安装日期 | 已装设备 |
  ```

  换设备或重装系统时，依此登记表人工还原。**未登记的定制 MCP 视为不存在**。

### 3. 跨设备访问（不组网）
- **不使用** Tailscale / ZeroTier 等组网方案，**不提供**远程 MCP。
- 无终端设备（iOS/HarmonyOS 等）**默认只读**：通过 Git 托管平台的客户端 App（或网页）阅读 `memory/`、`handoff/`、`repos.md` 等文本资产，二进制文档经同步工具 App 访问 `~/.agent-docs`。
- **移动端写操作的唯一例外**：仅限在 `handoff/` 下紧急补录一份交接/备忘文件；该提交**必须**由人类在桌面端复核后合并（rebase 或接受 PR），桌面端 agent 发现移动端未复核提交时应提示人类。除此之外移动端不产生任何写入。

### 4. 工具链基线管理

本机已有工具**优先复用，不得重复下载安装**。工具链按下表分层登记，不得混用：

| 类别 | 登记去处 |
|---|---|
| 系统级基线（git/python/node/npm/gh/curl/unzip/ssh）与工具区二进制（gitleaks 等，放 `~/.agent-tools/bin`） | `env/toolchain.md`（基线、来源类型、变更日志）+ `memory/devices/tools-<设备名>.md`（本机实测，脚本生成） |
| 项目/venv 依赖 | `env/requirements.txt`、项目 lock 文件 |
| **通用只读解析库**（pypdf 等，见 四-5） | `env/requirements.txt` 固定版本 + `env/toolchain.md` §五 变更日志（**装进 `~/.agent-tools/venvs/<agent名>/`**） |
| **项目级 CLI**（wrangler / vite / tsc / eslint 等） | **项目自身的 `package.json` + lock 文件**（devDependency，装进项目 `node_modules/`，见 ⑦） |
| MCP 服务 | `env/mcp-registry.md`（见 四-2） |
| 桌面客户端（WPS/PuTTY/网盘/NAS 映射） | `memory/devices/<设备名>.md`（属人类环境，不在工具链基线内） |

- **① 探测优先，缺失才装**：任何安装动作前先 `command -v <tool>` + `<tool> --version`；**已装且满足基线即直接用**，登记来源为 `复用`，禁止无谓重复安装（既省时间，也避免同机多版本互相干扰）。解析/转换类需求（PDF、图片、Office 等）还须**先探测平台内置 CLI**（如 `~/.workbuddy/external-packages/` 下的 pdf-cli），满足需求即直接调用、不装第三方库（见 四-5 ①）——平台能力优先于任何安装动作。
- **② 首次扫描一次，之后增量**：新设备或新 agent 首次运行时执行一次
  `bash env/tools-scan.sh --write`
  生成 `memory/devices/tools-<设备名>.md` 并刷新 stamp（`~/.agent-tools/run/tools-scan.stamp`），随后提交并 `git sync`。
  **已有 stamp 且未满 30 天时，其他 agent 不得再全量扫描**，只跑 `bash env/tools-scan.sh --check` 核对基线即可；超过 30 天才重新全量刷新（避免同一台机器被反复扫描、清单反复抖动）。
- **③ 新装 / 升级 / 卸载必须登记**：**系统级工具与工具区二进制**执行 `tools-scan.sh --write` 刷新本机清单，并在 `env/toolchain.md` §五 变更日志**追加一行**（日期 | 设备 | 操作 | 工具与版本 | 来源类型 | 操作者 | 备注）；**项目级 CLI** 则由项目 `package.json`/lock 文件的提交来登记（并在 `memory/projects/<项目名>.md` 追加一条说明）。**未登记的安装视为不合规**——无论装在系统级、用户级托管前缀还是项目外，都不能以"某会话临时装一下"为由跳过登记。
- **④ 来源类型必填其一**：`复用`（本机已装直接用，首选）/ `包管理器`（winget/apt/brew/scoop，记包名）/ `官方Release`（记版本号与下载 URL）/ `未知来源`（绿色版、他处拷贝——可直接用，但**密钥相关工具须核验哈希或换官方来源**）。
- **⑤ 约束**：工具二进制**不入 Git**，`~/.agent-tools/bin` 为唯一工具区，禁止散落到项目目录；不登记 `pip list`/`npm ls` 这类完整包列表（噪音），只登记 agent 干活真正依赖的工具；多版本并存时须在设备清单注明"默认解析哪个"，否则 agent 会用错解释器装包。
- **⑥ GUI 程序（puttygen 等）不做版本探测**：执行 `--version` 会弹窗挂起会话，清单里记为"未探测"即可，只核对存在性。
- **⑦ 项目级 CLI 归项目所有**：wrangler、vite、tsc、eslint 等**只在某个项目里用得到**的命令行工具，必须声明为该项目的 devDependency，装进项目 `node_modules/`，随项目 Git 仓库（lock 文件）走，用 `npx <tool>` / npm scripts 调用。**禁止装成全局**（判定见 三-5 ②，理由见 `memory/archive/2026-11-rules-v2.7-moved.md`）。
  - 探测时还要查项目自身的 `package.json` / lock 文件，不能只看 `command -v`；仅当项目确无依赖声明且确实需要该工具时才安装，且必须按上述方式落到项目本地。
  - **存量整改**：发现历史上已全局安装的项目级 CLI，按"卸载全局 → 项目本地化 → 补登记（`toolchain.md` §五 追加卸载与安装各一行 + 项目记忆说明）"处理，禁止用"补一条登记"把违规状态合法化。

### 5. 通用依赖库的分层放置与复用

**结论：统一登记 + 分层放置 + 同 agent 多会话共用合规 venv + 平台能力优先复用。** 不搞「所有 agent / 所有会话共用一份全局包」，也不搞「每个会话各装一份」。**管理的核心是登记，不是目录默契**。

| 层 | 放哪 | 谁共用 | 登记去处 |
|---|---|---|---|
| 系统运行时（Python / Node / Git） | 系统装一份 | 全机 | `env/toolchain.md` + `memory/devices/tools-<设备名>.md` |
| 平台自带能力（如 `~/.workbuddy/external-packages/` 下的 pdf-cli） | 平台托管，agent **不碰、不重复安装、不自行升级** | 全平台会话 | 平台维护，**无需登记** |
| **通用只读解析库**（pypdf / pdfplumber 等跨任务复用、无项目绑定） | `~/.agent-tools/venvs/<agent名>/` | **同一 agent 名的所有会话共用一份**（不同设备各自一份） | `env/requirements.txt` 固定版本 + `env/toolchain.md` §五 变更日志 |
| 项目专属依赖 / 项目级 CLI | 项目 `node_modules/` + lock 文件 | 随项目 clone 复现 | 项目 `package.json` + lock（四-4 ⑦） |
| MCP 服务 / 定制工具 | 见 四-2 / 四-4 | 同机多 agent 共享同一服务 | `env/mcp-registry.md` |

- **① 平台能力优先复用（安装前第一探测）**：需要解析/转换 PDF、图片、Office 等能力时，先查平台内置 CLI 与本机已有工具（`~/.workbuddy/external-packages/`、`command -v`、`memory/devices/tools-<设备名>.md`）；满足需求即直接调用，**不得安装第三方库**（起因事故见 `memory/archive/2026-11-rules-v2.7-moved.md`）。
- **② 同 agent 多会话共用一份**：venv 按 **agent 名** 隔离（三-5 ① / 四-1），**不按会话隔离**。同一 agent 名的多个并发会话共用同一个 `venvs/<agent名>/`；开工前先核对 venv 内是否已装且版本符合 `env/requirements.txt`，有则复用，缺则按清单装**一次**并追加变更日志。**禁止每会话各装一份**（重复下载、版本漂移、无法定责）。不同设备视为不同实例，各自维护自己的 venv 与清单（三-1）。
- **③ 跨 agent 不共用**：各 agent 用自己的 venv，禁止激活或改写他人 venv（三-5 ①）。若将来确需跨 agent 共享一批库，须新增 `~/.agent-tools/venvs/_shared/` **只读层**（含版本清单与变更登记），走第十节治理由人类批准后升版实施；**禁止口头破例，禁止改用全局前缀绕过**。
- **④ 禁止以「共享」为由放全局**：`pip install --user`、系统级 `site-packages`、`%APPDATA%\Python\...` 等共享前缀一律违规（三-5 ②）；**不得用「补一条登记」把违规状态合法化**（四-4 ⑦ 存量整改）。
- **⑤ 登记是硬要求**：任何新装 / 升级 / 卸载通用库，必须同时更新 `env/requirements.txt`（写死版本号）并在 `env/toolchain.md` §五 追加一行（日期 | 设备 | 操作 | 库与版本 | 操作者 | 备注），10 分钟内 commit + `git sync`（四-4 ③ / 五-1）。**未登记的安装视为不合规**，与安装位置、会话归属无关。
- **⑥ 存量整改流程**：发现违规副本（用户级 / 系统级 site-packages 等）时按「**确认无会话正在使用** → 卸载违规副本 → 按清单装进合规 venv → 补 `requirements.txt` + 变更日志 + 组织/项目记忆 → commit / sync」处理。若另一会话正在使用该库，须**等其结束或由人类裁决**（三-5 ⑥ 人类操作优先 / 三-5 ⑦ 同 agent 多会话），**禁止直接卸载打断**；历史存量可一并纳入并在登记中注明「存量」。

<!-- anchors：以下每行「|」后的文本须在本文件正文（本注释之外）与 global/rules.md 原位摘要壳中各逐字出现一次；改任一侧须同步另一侧（〇⑤ 受控例外二、第十节）。
四-1 | **系统级共享**：Python/Node.js/Git 等基础运行时系统安装一份即可
四-1 | 严禁在 `~/.agent-shared` (Git 工作区) 内部创建任何 `venv` 或 `node_modules`
四-1 | **工作区不进 WSL**
四-2 | **禁止各起 stdio 进程抢文件**
四-4 ① | 任何安装动作前先 `command -v <tool>` + `<tool> --version`
四-5 ② | venv 按 **agent 名** 隔离（三-5 ① / 四-1），**不按会话隔离**
四-5 ② | **禁止每会话各装一份**
四-5 ⑤ | **未登记的安装视为不合规**，与安装位置、会话归属无关
-->

