> **来源**：`global/rules.md` 的分卷（v2.6 起拆出；**不单独编号**，随 `rules.md` 版本生效）
> **原编号**：二（含 二-0／0.5／1／2／3）
> **触发**：新建目录、判断文件该落哪一层、接入新设备、处理 `~/.agent-docs` 同步或 `docs://` 引用时
> **效力**：与 `rules.md` 同等，受最小红线④保护，修订流程见 `rules.md` 第十节；本文件是该章节的**唯一正文**（〇⑤）。
> **引用写法**：`三-7〔spec/deploy.md〕` 表示该章节正文在所注分卷；未注路径的编号在 `rules.md` 常驻层。

## 二、 统一目录结构基准

在任何设备上，严格遵循以下两大核心目录的划分。

### 0. 路径映射基准
本规范所有 `~/` 写法在各系统的实际解析如下，脚本与文档中**禁止写死绝对路径**：

| 逻辑路径 | Linux / Termux | Windows (Git Bash 视角) | Windows (原生) |
|---|---|---|---|
| `~/` | `$HOME`（`/home/<user>`） | `~` → `/c/Users/<user>` | `C:\Users\<user>\` |
| `~/.agent-shared` | `/home/<user>/.agent-shared` | `/c/Users/<user>/.agent-shared` | `C:\Users\<user>\.agent-shared` |
| `~/.agent-tools` | `/home/<user>/.agent-tools` | `/c/Users/<user>/.agent-tools` | `C:\Users\<user>\.agent-tools` |
| NAS 挂载点 | `/mnt/nas` | `/z`（映射盘符 `Z:\`） | `Z:\` |

- Windows 上 `~` 由 Git Bash 解析为 `C:\Users\<user>\`，与规范约定一致；PowerShell 中等价写法为 `$HOME`。
- 移动端（iOS 等）不落本地工作区，只读边界见 四-3〔spec/toolchain.md〕。

### 0.5 设备命名规范
- 格式：`<hostname>-<os>`，**全小写**，去掉空格与非 ASCII 字符；`os` 取枚举值：`win` / `linux` / `macos` / `android` / `termux` / `harmony` / `ios`，与账号标识 OS 段（三-8 ②〔spec/accounts.md〕）对应：`win`→`w`、`linux`→`l`、`macos`→`m`、`android`／`termux`→`a`、`harmony`→`h`、`ios`→`i`；WSL 不单设设备 `os`，沿用宿主 `win` 设备、OS 段取 `wl`。已登记的设备名不改。全局唯一，冲突时在 hostname 后追加序号。
- 示例：`desktop01-win`、`nuc-linux`、`mate40-harmony`。
- 该名用于三处：`memory/devices/<设备名>.md`、handoff 文件名后缀（三-4）、记忆署名中的 `@设备`（三-1）。
- **设备总登记表** `memory/devices/_devices.md`，每行：`设备名 | os | 设备简标 | OS段 | 是否主设备 | nas 挂载能力 | 备注`（设备简标与 OS段 见 三-8 ②〔spec/accounts.md〕）。新设备接入时先登记，后使用。

### 1. 共享工作区目录 (~/.agent-shared)
在所有具备终端能力（Windows/Linux/Android-Termux）的设备上，统一使用 `~/.agent-shared` 作为本地工作区根目录（推荐直接 git clone 仓库至此）。
**只存放文本、代码、配置和记忆，严禁存放大型二进制包和依赖环境**。

```
~/.agent-shared/
├── global/
│   ├── rules.md            # 本规范文件（常驻层）
│   └── spec/               # 规范分卷（见 〇 章节分流）
├── memory/                 # 【读/写】长期记忆，全部 append-only
│   ├── org.md              # 组织级记忆（只追加，禁止改写历史行）
│   ├── projects/           # 各项目独立记忆文件
│   ├── devices/           # 各设备特有信息（路径、端口、挂载映射）
│   │   └── _devices.md    # 设备总登记表（见 二-0.5）
│   └── archive/            # 压缩归档（按 月/主题 命名，如 2026-10.md）
├── skills/                 # 【读】共享技能源码（按 coding / official-doc 分类）
├── handoff/                # 【读/写】任务交接（命名：YYYY-MM-DD-任务名-设备名.md）
├── env/                    # 【读】环境配置脚本与依赖清单
│   ├── requirements.txt    # Python 依赖
│   ├── mcp-config.json     # 公开市场 MCP 的统一配置（可直接同步安装）
│   ├── mcp-registry.md     # 定制/手动安装 MCP 的登记表（备查，见四-2〔spec/toolchain.md〕）
│   ├── agents.md           # Agent 名登记表 + 账号登记表（见 三-1 / 三-8〔spec/accounts.md〕）
│   ├── repos.md            # 项目代码登记表 + 项目属性补充表（见 七）
│   ├── toolchain.md        # 工具链基线与工具变更日志（见 四-4〔spec/toolchain.md〕）
│   ├── tools-scan.sh       # 本机工具扫描脚本：--write 生成设备清单 / --check 核对基线（见 四-4〔spec/toolchain.md〕）
│   ├── new-agent-bootstrap.md   # 新 Agent 一次性开场提示词（见 〇①）
│   ├── proxy-check.sh      # 代理与双远端只读核对（见 五-1 / 八-10）
│   ├── git-sync.sh         # 双远端分步推送（见 五-1）
│   ├── project-AGENTS-hook.md # 注入端模板 A/B/C 段（见 〇①②）
│   ├── execution-enforcement.md # 执行纪律保障方案（见 〇⑥）
│   ├── handoff-suspended-template.md # 挂起任务登记模板（见 三-4）
│   ├── start-mcp.sh        # Linux/Termux/Git Bash 启动脚本
│   ├── start-mcp.bat       # Windows 启动脚本（或以 PowerShell 计划任务替代，见四-1〔spec/toolchain.md〕）
│   └── .gitignore.template # 强制 gitignore 模板（见 六）
├── keys-checklist.md       # 密钥核对清单：列出所有应存在于本机 config/ 的密钥项（不含密钥值）
├── tmp/                    # 【本机临时】会话中间产物，用完即清，不入 Git；按 agent 子目录隔离（见 三-3）
└── config/                 # 本机密钥与环境变量（禁止提交，手动分发，见 六）
```


### 2. 本机工具与依赖目录 (~/.agent-tools)
这是当前机器的**物理执行环境根目录**，不参与 Git 同步。所有 Agent 共享此目录下的运行时和工具，但依赖库互相隔离。

```
~/.agent-tools/                 # 本机所有 Agent 共享的工具根目录
├── bin/                        # 共享的可执行文件（加入系统 PATH）
├── venvs/                      # Python 虚拟环境隔离区
│   ├── workbuddy/              # 给 workbuddy 用的 venv
│   ├── codex/                  # 给 codex 用的 venv
│   └── dsh/                    # 给 dsh 用的 venv
├── node/                       # 共享的 Node.js 运行时（可选，或者用系统级）
├── mcp/                        # 本机安装的 MCP（含手动安装的定制 MCP）
├── cache/                      # 包管理器缓存（避免重复下载）
│   ├── pip/
│   └── npm/
└── run/                        # MCP 服务的 PID 文件和运行日志
    ├── fs.pid
    └── fs.log
```

### 3. 重要文档同步区 (~/.agent-docs)
- **定位**：存放需要跨设备访问的**重要文档、资料库原件**（Office 文档、PDF、图表、设计源文件等）。**不进 Git**，由第三方同步工具（坚果云 / Syncthing / OneDrive）处理，确保多设备间文档实时一致。
- **与其他层的分工**：
  - 小而重要、需要跨设备**频繁查看/编辑**的文档原件 → `~/.agent-docs`（建议单文件 ≤ 100MB，避免触发同步工具的大文件/配额限制）；
  - 超大文件、视频、一次性归档、扫描件 → NAS `docs/`（见 五-2〔spec/backup.md〕），不要求实时性；
  - 纯文本资产（规范/记忆/技能/清单） → Git 仓库 `~/.agent-shared`，不重复放一份进 `~/.agent-docs`；
  - **单一原件原则**：同一份文档只允许存在一个权威副本。严禁在 `~/.agent-docs` 与 NAS 各维护一份"双活"版本；确需留档时用脚本单向复制，并在副本文件头注明原件位置与复制时间。
- **路径约定**：所有设备统一使用 `~/.agent-docs`（Windows 为 `C:\Users\<user>\.agent-docs`）。若所选同步工具不支持自定义本地目录，则在本机建立符号链接（Windows `mklink /D`、Linux `ln -s`）指向实际同步目录，并将**实际路径**登记进 `memory/devices/<设备名>.md`。
- **工具约定**：全部接入设备必须使用**同一个**同步工具，由人类选定后在设备登记表 `_devices.md` 中记录。参考：坚果云——全平台（含 iOS/HarmonyOS）、国内直连，与本规范的多端组合最匹配；Syncthing——点对点无云中转、隐私性好，但 iOS 支持弱，适合纯桌面/安卓组合。选用云托管工具（坚果云/OneDrive）时，其账号凭证按 六（密钥管理）手动分发并加入 `keys-checklist.md`。
- **引用约定**：handoff 与记忆中引用文档统一写 `docs://<相对 ~/.agent-docs 的路径>`，如 `docs://产品/需求说明书-v2.docx`，解析方式与 `nas://` 相同（查本机设备登记的映射）。**该约定同样是文本约定，不依赖任何驱动**。
- **目录结构建议**（不强制）：按项目/类别建一级目录，如 `docs/产品/`、`docs/资料库/`、`docs/财务/`。
- **移动端**：`~/.agent-docs` 是无终端设备（iOS 等）唯一能直接读写二进制文档的通道（经同步工具的 App），agent 在为移动端准备材料时应优先放此处而非 NAS。

