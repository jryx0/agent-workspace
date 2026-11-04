# 多设备多 Agent 协同工作架构与规范 (v1.8.2)

> **致所有 Agent：** 你现在接入了一个跨设备（Windows/Linux/iOS/Android/HarmonyOS）、多 Agent 协同的个人/团队工作空间。请严格遵循本规范进行文件读写、记忆存储、工具调用和任务交接。如果你是人类用户，请按此文档进行环境初始化。

## 变更记录

- **v1.8.2 (2026-11-04)**：采纳 trae handoff 评审中 v1.8 尚未覆盖的 4 项——① 三-6 新增 worktree 适用场景（单人单任务直接 clone，仅多 agent 并发同一项目时启用）；② 八 启动自检 7 步标签化（`[Agent自动]`/`[Agent报告]`/`[人类执行]`），明确可自动完成与需人类处置的边界；③ 五-1 新增 commit message 规范（type 枚举 + agent 署名）；④ 移动端只读描述由 3 处收敛为 四-3 单一权威定义。另勘误：五-1 推送命令 `--all --tags` 同用（Git 2.55 已禁止）改为分步推送。
- **v1.8.1 (2026-11-04)**：变更记录瘦身——v1.1–v1.7 详细条目移入 `memory/archive/2026-11-rules-changelog.md`（归档只读），各版本保留一行摘要；正文补全 v1.8 全部条款（此前因工作区误重置丢失，本次重新写入并逐条核验）。
- **v1.8 (2026-11-04)**：① 项目代码根统一 `~/source`（三-2/三-6/七）；② 任务认领机制（三-5 ⑤）；③ 分支准出标准与提交归属（三-6）；④ gitleaks 全局 hook 链式委托（六-1）；⑤ agent 端口段分配（三-5 ④）；⑥ 人类操作优先原则（三-5 ⑥）。
- **v1.7**：新增 三-6 Git Worktree 协作（`.wt/<agent名>/` 布局、`agent/*` 分支、用完即删）。
- **v1.6**：同机并发四前提（venv 隔离 / 禁系统级安装 / 占用确认兜底 / 命名隔离与保留端口）。
- **v1.5**：密钥防泄漏技术化、压缩锁机制、tmp/ 分类标准、agents.md 登记、并发纪律、上下文加载策略等 12 条。
- **v1.4**：新增 `~/.agent-docs` 文档同步区与 `docs://` 约定。
- **v1.3**：路径映射基准、`nas://` 文本约定、Gitee+GitHub 双远端、Git Bash 为主不使用 WSL、设备命名规范。
- **v1.2**：跨设备不组网、MCP 分级管理、记忆 append-only 与压缩机制、密钥手动分发、repos.md 登记。
- **v1.1**：初版结构。

---

## 一、 架构总览与核心原则

- **单一事实源 (SSOT)**：核心资产（规范/记忆/技能/环境清单）托管于 Gitee 私有仓库（**主库**），GitHub 私有仓库作为**备份库**（见 五-1）。本地工作区对应 `~/.agent-shared`。
- **跨设备只同步文本资产**：规范、记忆、技能源码、环境清单、各类登记表。**跨设备不组网、不暴露远程服务**；移动端（iOS/HarmonyOS 无终端设备）为只读消费者，边界与例外见 四-3。
- **存储分层**：本地热数据（Git，文本资产） + 文档实时同步区（`~/.agent-docs`，第三方工具） + NAS 温数据（大文件） + 百度网盘冷数据（定时备份）。
- **物理隔离**：文本配置与状态（存于 `~/.agent-shared`）与 运行环境与工具（存于 `~/.agent-tools`）彻底分离。
- **本机资产不出本机**：运行时、venv、MCP 进程、临时文件、密钥，均属于本机，任何情况下不进入 Git 仓库。

## 二、 统一目录结构基准

在任何设备上，严格遵循以下两大核心目录的划分。

### 0. 路径映射基准 (v1.3 新增)
本规范所有 `~/` 写法在各系统的实际解析如下，脚本与文档中**禁止写死绝对路径**：

| 逻辑路径 | Linux / Termux | Windows (Git Bash 视角) | Windows (原生) |
|---|---|---|---|
| `~/` | `$HOME`（`/home/<user>`） | `~` → `/c/Users/<user>` | `C:\Users\<user>\` |
| `~/.agent-shared` | `/home/<user>/.agent-shared` | `/c/Users/<user>/.agent-shared` | `C:\Users\<user>\.agent-shared` |
| `~/.agent-tools` | `/home/<user>/.agent-tools` | `/c/Users/<user>/.agent-tools` | `C:\Users\<user>\.agent-tools` |
| NAS 挂载点 | `/mnt/nas` | `/z`（映射盘符 `Z:\`） | `Z:\` |

- Windows 上 `~` 由 Git Bash 解析为 `C:\Users\<user>\`，与规范约定一致；PowerShell 中等价写法为 `$HOME`。
- 移动端（iOS 等）不落本地工作区，只读边界见 四-3。

### 0.5 设备命名规范 (v1.3 新增)
- 格式：`<hostname>-<os>`，**全小写**，去掉空格与非 ASCII 字符；`os` 取枚举值：`win` / `linux` / `termux` / `harmony` / `ios`。全局唯一，冲突时在 hostname 后追加序号。
- 示例：`desktop01-win`、`nuc-linux`、`mate40-harmony`。
- 该名用于三处：`memory/devices/<设备名>.md`、handoff 文件名后缀（三-4）、记忆署名中的 `@设备`（三-1）。
- **设备总登记表** `memory/devices/_devices.md`，每行：`设备名 | os | 是否主设备 | nas 挂载能力 | 备注`。新设备接入时先登记，后使用。

### 1. 共享工作区目录 (~/.agent-shared)
在所有具备终端能力（Windows/Linux/Android-Termux）的设备上，统一使用 `~/.agent-shared` 作为本地工作区根目录（推荐直接 git clone 仓库至此）。
**只存放文本、代码、配置和记忆，严禁存放大型二进制包和依赖环境**。

```
~/.agent-shared/
├── global/
│   └── rules.md            # 本规范文件
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
│   ├── package-lock.json   # Node 依赖
│   ├── mcp-config.json     # 公开市场 MCP 的统一配置（可直接同步安装）
│   ├── mcp-registry.md     # 定制/手动安装 MCP 的登记表（备查，见四-2）
│   ├── agents.md           # Agent 名登记表（agent名 | 所属设备 | 职责），见 三-1
│   ├── repos.md            # 项目代码 Git 地址登记表（见 七）
│   ├── start-mcp.sh        # Linux/Termux/Git Bash 启动脚本
│   ├── start-mcp.bat       # Windows 启动脚本（或以 PowerShell 计划任务替代，见四-1）
│   └── .gitignore.template # 强制 gitignore 模板（见 六）
├── keys-checklist.md       # 密钥核对清单：列出所有应存在于本机 config/ 的密钥项（不含密钥值）
├── tmp/                    # 【本机临时】会话中间产物，用完即清，不入 Git；按 agent 子目录隔离（见 三-3）
└── config/                 # 本机密钥与环境变量（禁止提交，手动分发，见 六）
```

> **注意**：v1.1 中的 `inbox/` 已合并进 `tmp/`，二者定位相同——**本机临时目录，不参与 Git 同步，不承担跨设备传文件职责**。跨设备传小文件走 Git 提交，大文件走 NAS。

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

### 3. 重要文档同步区 (~/.agent-docs) (v1.4 新增)
- **定位**：存放需要跨设备访问的**重要文档、资料库原件**（Office 文档、PDF、图表、设计源文件等）。**不进 Git**，由第三方同步工具（坚果云 / Syncthing / OneDrive）处理，确保多设备间文档实时一致。
- **与其他层的分工**：
  - 小而重要、需要跨设备**频繁查看/编辑**的文档原件 → `~/.agent-docs`（建议单文件 ≤ 100MB，避免触发同步工具的大文件/配额限制）；
  - 超大文件、视频、一次性归档、扫描件 → NAS `docs/`（见 五-2），不要求实时性；
  - 纯文本资产（规范/记忆/技能/清单） → Git 仓库 `~/.agent-shared`，不重复放一份进 `~/.agent-docs`；
  - **单一原件原则**：同一份文档只允许存在一个权威副本。严禁在 `~/.agent-docs` 与 NAS 各维护一份"双活"版本；确需留档时用脚本单向复制，并在副本文件头注明原件位置与复制时间。
- **路径约定**：所有设备统一使用 `~/.agent-docs`（Windows 为 `C:\Users\<user>\.agent-docs`）。若所选同步工具不支持自定义本地目录，则在本机建立符号链接（Windows `mklink /D`、Linux `ln -s`）指向实际同步目录，并将**实际路径**登记进 `memory/devices/<设备名>.md`。
- **工具约定**：全部接入设备必须使用**同一个**同步工具，由人类选定后在设备登记表 `_devices.md` 中记录。参考：坚果云——全平台（含 iOS/HarmonyOS）、国内直连，与本规范的多端组合最匹配；Syncthing——点对点无云中转、隐私性好，但 iOS 支持弱，适合纯桌面/安卓组合。选用云托管工具（坚果云/OneDrive）时，其账号凭证按 六（密钥管理）手动分发并加入 `keys-checklist.md`。
- **引用约定**：handoff 与记忆中引用文档统一写 `docs://<相对 ~/.agent-docs 的路径>`，如 `docs://产品/需求说明书-v2.docx`，解析方式与 `nas://` 相同（查本机设备登记的映射）。**该约定同样是文本约定，不依赖任何驱动**。
- **目录结构建议**（不强制）：按项目/类别建一级目录，如 `docs/产品/`、`docs/资料库/`、`docs/财务/`。
- **移动端**：`~/.agent-docs` 是无终端设备（iOS 等）唯一能直接读写二进制文档的通道（经同步工具的 App），agent 在为移动端准备材料时应优先放此处而非 NAS。

## 三、 核心工作规范

### 1. 记忆管理 (Memory)
- **上下文加载策略（v1.5 新增，控制 token 消耗）**：
  - `org.md` 默认**只读取最近 200 行**（`tail -200`），不全文加载；
  - `memory/archive/` **不默认加载**，仅按需 grep 检索特定主题；
  - 项目记忆只加载当前项目的对应文件，不加载其他项目；
  - handoff 只读取最新一份交接文档，不扫描全目录。
- **Agent 名登记**：agent 名必须在 `env/agents.md` 登记（格式：`agent名 | 所属设备 | 职责`），未登记的 agent 名在署名中**视为无效**；同名 agent 登记在不同设备视为不同实例，署名时以 `agent名@设备名` 区分。
- **append-only 原则**：所有记忆文件只允许在文件末尾追加，**禁止修改、删除或重排已有行**。修正错误信息时追加一条更正记录，不改原文。**唯一例外见 三-2 记忆压缩**。
- **署名规范**：每条追加必须带前缀，格式为：
  `[@agent名 @设备名 YYYY-MM-DD HH:mm UTC+8] 内容`
  无署名或 agent 未登记的记忆条目视为无效，可被压缩时剔除。
- 本机特有信息（路径、端口）只能写在 `memory/devices/本机名.md` 中。
- **冲突避免**：append-only + 各设备写各自文件（handoff 按设备命名）使 Git 冲突几乎不会发生。若仍遇冲突：先 `git pull --rebase`，保留双方行、按时间重排，然后 **push 前执行 `git log --oneline -5` 目视确认历史完整（防止自动解决弄丢压缩提交等关键 commit）**，再 push；无法判断时标记 `<!-- 待人工裁决 -->` 并通知人类。

### 2. 记忆压缩机制 (Compaction)
- **append-only 的唯一例外**：记忆压缩是**唯一允许改写记忆文件（截断/重组）的机制**，且仅限主设备在压缩窗口内执行。窗口外任何改写记忆文件的行为均违规。
- **周期**：每月 1 次（人类用户发起，建议固定在每月第一个周末）。**保留期统一为 90 天**（记忆条目与交接文档一致），压缩流程中**一步同时处理 `memory/` 与 `handoff/` 的归档**，避免两套周期漏处理。
- **执行者**：由人类指定的一台**主设备**（建议：主力 Windows 机）上的任一 agent 执行，同一周期内只允许这一台设备执行压缩。
- **锁文件机制（v1.5 变更）**：压缩前先创建 `memory/.compact-lock`（内容：设备名 + ISO 时间戳）并**单独 commit + push**。其他设备自检时发现锁即**暂停写入记忆**，直至锁被删除。压缩完成后，删锁与压缩内容在同一个 commit 中一并推送。
- **流程**（严格按序）：
  1. `git pull --rebase` 确保最新；
  2. 创建并推送 `memory/.compact-lock`（含设备名+时间戳），从 push 锁起进入压缩窗口，**全流程原则上不超过 30 分钟**；
  3. 读取 `org.md` 及各项目记忆全量内容；
  4. 将超过 90 天的条目提炼为摘要，写入 `memory/archive/YYYY-MM.md`（按主题分节，保留决策结论与关键链接，丢弃过程细节）；同时将超过 90 天的 handoff 移入 `handoff/archive/YYYY-MM/`；
  5. 将 `org.md` 截断为：压缩后的最新摘要 + 保留期内原始条目；同 commit 删除 `.compact-lock`；
  6. 立即 push，commit message 格式：`memory: compact 2026-11 by <agent>@<设备>`；
  7. **验证备份库**：push 后在临时目录对 GitHub backup 远端执行一次 `git clone --depth 1`，确认镜像可用；
  8. **维护各项目 worktree**：对本机 `~/source/` 下各项目执行 `git worktree prune`，并清理已合并的 `agent/*` 本地分支（见 三-6）。
- **归档只读**：`memory/archive/` 与 `handoff/archive/` 下的文件**一经写入即为只读**，后续周期不得修改既有归档，新月份/新周期新建文件。

### 3. 临时文件与跨设备文件分类
- **严禁**在工作区根目录或 `handoff/` 下生成临时文件，所有中间产物必须写入 `tmp/<agent名>/`（**按 agent 子目录隔离**，防止多 agent 互踩），会话结束时主动清理；各设备可配置定时任务清理 7 天以上的残留文件。
- **跨设备文件分类标准（v1.5 新增，客观可执行）**：

  | 文件类型 | 去向 |
  |---|---|
  | ≤1MB 的文本/代码/配置 | 直接 commit 到对应目录 |
  | 重要文档（Office/PDF/图表，≤100MB） | `~/.agent-docs`，引用写 `docs://` |
  | >100MB、二进制、视频、归档 | NAS `docs/`，引用写 `nas://` |
  | 无法归类的中间产物 | 默认 `tmp/`（本机），并在交接文档中说明去向 |

- 判定困难时**宁可用 tmp/ 也不要污染 Git 仓库**；一旦发现中间产物被误提交，应在同一会话内 `git rm` 并在下一次压缩时清理。

### 4. 任务交接 (Handoff)
- 完成阶段性任务、切换设备或结束会话时，**必须**在 `handoff/` 下生成交接文档，命名：`YYYY-MM-DD-任务名-设备名.md`（带设备名，避免多端同名冲突）。
- 交接文档需包含：当前状态、已完成、待办、关键文件链接（见五-2 引用规范）、当前使用的 worktree 路径与分支（如适用，见 三-6）、下一步指令。
- **归档**：超过 90 天的交接文档，随月度记忆压缩一并移动至 `handoff/archive/YYYY-MM/`。

### 5. 多 Agent 并发纪律 (v1.5 新增，v1.6 扩充)
- **同机并发前提**：同机多个 Agent **可以同时运行**，但必须同时满足以下四条：
  1. **各用各的 venv**：依赖隔离遵循 四-1，装入并激活 `~/.agent-tools/venvs/<自己的名字>/`，禁止共用或激活他人虚拟环境；
  2. **禁止系统级安装**：不得执行系统级 `pip install` / `npm install -g`（Windows 上含"以管理员身份"安装全局包）；缺依赖时装入自己的 venv，并按 五-1 将变更同步进 `env/requirements.txt` 等清单；
  3. **项目目录占用确认（兜底）**：对项目目录的并行操作**默认走 三-6 worktree 模式**（各用各的 checkout，无需占用确认）；仅当共用主 worktree（临时小改动）时，先查 `handoff/` 最新交接文档确认无其他 Agent 占用，开始占用时**必须在交接文档中注明占用者与预计释放时间**，禁止并行操作同一目录；
  4. **命名隔离与端口段**：临时文件一律写入 `tmp/<agent名>/`；Agent 因调试等需要自起的服务必须带 agent 名命名与登记（端口记录进 `memory/devices/<设备名>.md`），**禁止占用 9101/9102 等本规范保留端口**，避免服务与文件被静默互相覆盖。dev server、测试数据库、docker 容器等开发资源按 **agent 端口段**分配（如 trae=9200-9299、workbuddy=9300-9399），端口段登记进设备档案，禁止越段占用。
  5. **任务认领机制**：项目开发任务统一登记在 `memory/projects/<项目名>.md` 的任务登记节（append-only），格式：`任务ID | 描述 | 认领agent | 状态`。agent 领任务先追加认发行（登记即锁定），完成或放弃必须**追加**状态行（不得改写旧行）；未登记认领的任务其他 agent 不得开工，防止重复劳动。
  6. **人类操作优先原则**：人类正在配置或操作的目录、工具、服务（含各类云同步客户端、NAS、网盘），agent **禁止并行修改**，动手前必须确认人类的配置进度与意图；云同步目录内的删除操作一律由人类在客户端/网页 UI 完成，agent 不做本地侧反复删除重试（源自 2026-11-04 agent-docs 配置冲突事故复盘）。
- **传输层**：同机 agent 共享同一 MCP SSE 服务（四-2），请求由服务进程排队，**禁止**为并发而自起 stdio 实例。
- **Git 操作串行化**：同机多个 agent 执行 `pull/commit/push` 等写操作时，必须先获取本机文件锁（Linux/Git Bash 用 `flock`，Windows 用 PowerShell `Mutex` 或等价锁文件 `~/.agent-tools/run/git.lock`），**同一时刻同机只允许一个 git 写操作**；锁等待超过 60 秒即报告人类而非无限等待。
- **文件写入隔离**：记忆 append-only、handoff/`tmp/` 按设备与 agent 命名，已从命名上消除绝大多数并发写冲突。两 agent 确需写同一文件时，以 Git 提交先后为准，**禁止长时间持有未提交的编辑**（编辑后 10 分钟内必须 commit 或放弃）。
- **项目代码并发**：多 agent 同时修改同一项目代码时，走 三-6 worktree + `agent/*` 分支协作，由人类合并。

### 6. Git Worktree 协作 (v1.7 新增)
- **适用场景**（v1.8.2）：**单人单任务直接 clone 到 `repos.md` 登记路径，不启用 worktree**——worktree 的唯一目的是隔离同机多 agent 对同一项目的并发修改，无并发时启用它只增加清理负担。仅当两个及以上 agent 同时修改同一项目代码时，才按下述布局启用协作模式。
- **范围**：仅 `repos.md` 登记的项目代码仓库；**`~/.agent-shared` 禁用 worktree**（append-only 记忆与压缩机制依赖单一历史，分支化会使其失效）。
- **布局**：主 worktree `~/source/<项目名>`（跟踪 main，人类或共用者使用）；agent 专属 `~/source/<项目名>.wt/<agent名>/`，分支 `agent/<agent名>/<任务>`。
- **流程**：领任务后（先按 三-5 ⑤ 认领登记）`git worktree add ~/source/<项目名>.wt/<agent名> -b agent/<agent名>/<任务> origin/main` → 开发/构建/测试 → **分支准出**：`git pull --rebase origin main` 且自测（至少构建+冒烟）通过，commit 携带 `Agent: <agent名>` trailer，并在该 worktree 内配置独立提交身份（`git config user.name zhn-<agent名>`）→ push 分支 → 人类合并 → `git worktree remove`。
- **生命周期**：会话结束即 remove，成果靠分支保留而非残留目录；月度压缩时主设备顺带 prune 并清理已合并的 `agent/*` 本地分支（三-2 第 8 步）。
- **依赖**：Python venv 位于 `~/.agent-tools/venvs/`，跨 worktree 直接复用；`node_modules` 每 worktree 独立安装，依赖共享缓存 `~/.agent-tools/cache` 降低代价（pnpm 项目 store 天然共享）。

## 四、 工具与 MCP 机制

### 1. 依赖与运行时安装纪律
- **系统级共享**：Python/Node.js/Git 等基础运行时系统安装一份即可。
- **环境隔离**：Agent 专属的 Python 依赖必须安装在 `~/.agent-tools/venvs/你的agent名字/` 中。
- **禁止违规存放**：严禁在 `~/.agent-shared` (Git 工作区) 内部创建任何 `venv` 或 `node_modules`。
- **Windows Shell 选型（v1.3 新增）**：
  - **Git Bash 为主**：负责运行 `env/` 下全部 `.sh` 脚本（`setup.sh`、`start-mcp.sh` 等），保证与 Linux/Termux 单套脚本通用，且 `~` 解析与本规范一致；
  - **PowerShell 为辅**：仅用于 Windows 原生**计划任务**的注册与调度（MCP 开机自启、`tmp/` 7 天清理、夜间备份），以及在脚本中调用 `rclone.exe`；
  - **不使用 WSL**：WSL 会产生第二个独立的 `~`（位于 ext4 虚拟磁盘内），将工作区劈成两份、破坏"唯一工作区在 `C:\Users\<user>\`"的约定，明令禁用。

### 2. MCP 分级管理（v1.2 变更）
- **同机多 Agent 共享**：同机所有 Agent **必须连接同一个本地 MCP SSE 服务**，禁止各起 stdio 进程抢文件。服务只绑定 `127.0.0.1`，**不对外网/局域网暴露**。
  - 默认地址：`http://127.0.0.1:9101/sse` (文件系统，访问根目录限制为 `~/.agent-shared` 与 NAS 挂载点)
  - 默认地址：`http://127.0.0.1:9102/sse` (Git 操作)
- **公开市场 MCP**：统一配置在 `env/mcp-config.json`，随 Git 同步。各设备执行 `start-mcp.sh`（或对应 Windows 计划任务）时按配置自动拉起。
- **定制 MCP（手动安装）**：源码不参与同步。安装后**必须**在 `env/mcp-registry.md` 登记，每条包含：

  ```
  | 名称 | 用途 | 来源(仓库/下载地址) | 安装命令 | 版本 | 安装日期 | 已装设备 |
  ```

  换设备或重装系统时，依此登记表人工还原。**未登记的定制 MCP 视为不存在**。

### 3. 跨设备访问（v1.2 变更：不组网）
- **不使用** Tailscale / ZeroTier 等组网方案，**不提供**远程 MCP。
- 无终端设备（iOS/HarmonyOS 等）**默认只读**：通过 Git 托管平台的客户端 App（或网页）阅读 `memory/`、`handoff/`、`repos.md` 等文本资产，二进制文档经同步工具 App 访问 `~/.agent-docs`。
- **移动端写操作的唯一例外**：仅限在 `handoff/` 下紧急补录一份交接/备忘文件；该提交**必须**由人类在桌面端复核后合并（rebase 或接受 PR），桌面端 agent 发现移动端未复核提交时应提示人类。除此之外移动端不产生任何写入。

## 五、 存储与备份策略 (Git + NAS + 百度网盘)

### 1. Git 同步纪律（v1.3 变更：双远端）
- **主库**：Gitee 私有仓库，remote 名 `origin`，是一切同步的**事实基准**。
- **备份库**：GitHub 私有仓库，remote 名 `backup`，**只允许被推送覆盖，禁止在其上直接提交**。
- **推送纪律**：每次推送必须依次执行
  `git push origin --all && git push origin --tags && git push backup --all && git push backup --tags`
  （封装为脚本 `env/git-sync.sh` 或 git alias `git sync`），**禁止只推一个远端**。拉取永远只从 `origin`。
  > 勘误（v1.8.2）：Git 2.55 起 `--all` 与 `--tags` 不可在同一命令混用（报 `fatal: --all and --tags cannot be used together`），必须分步推送。
- **三重兜底**：夜间备份任务中额外执行 `git bundle create nas-backup.bundle --all`，将 bundle 文件放入 NAS `backup/`，随网盘冷备一起归档——即使两个托管平台同时不可用也可从 bundle 恢复。
- **冲突裁决**：两平台内容不一致时，一律以 Gitee 为准重新覆盖 GitHub。
- **禁止提交内容**：`venvs/`、`node_modules/`、`*.pyc`、`tmp/`、`config/`、任何密钥与大型二进制。
- **依赖更新**：安装新包后，必须立刻更新 `env/requirements.txt` 并与代码改动在同一个 Commit 提交。
- **提交前**：先 `git pull --rebase`，解决冲突并验证通过后再推送。
- **commit message 规范**（v1.8.2）：
  - 格式：`<type>: <简述> by <agent名>@<设备名>`，简述用中文、不超过 40 字。
  - `type` 枚举：`docs`（规范/文档）| `feat`（新功能）| `fix`（修复）| `refactor`（重构）| `memory`（记忆）| `handoff`（交接）| `infra`（环境/工具/密钥）| `scripts`（脚本）。
  - 示例：`docs: 规范升级 v1.8.2 — worktree 适用场景+自检标签化+commit 规范`、`fix: git-sync 兼容 Git 2.55 分步推送 by workbuddy@zhn-tbxg2iah-win`。
  - 压缩提交特例：`memory: compact YYYY-MM by <agent名>@<设备名>`。
  - 目的是让 `git log` 可按 type 过滤、按 agent 追溯；历史提交不追溯改写。

### 2. NAS 存储规则
- 挂载点约定：Linux `/mnt/nas`，Windows `Z:\`。
- 超过 20MB、或无需跨设备实时编辑的数据文件、视频、扫描件，必须存放在 NAS 的 `docs/` 对应目录下，**禁止存入 Git 仓库**；需要跨设备实时编辑的重要文档（一般 ≤100MB）走 `~/.agent-docs`（见 二-3）。
- 需要冷备的文件放入 NAS 的 `backup/` 目录，禁止 Agent 在会话中实时读取。
- **跨设备引用规范**：handoff 与记忆中引用 NAS 文件时，统一使用**相对 NAS 根的路径**，格式：`nas://docs/项目名/文件名`。
  > **`nas://` 是文本引用约定，不是操作系统协议**：不安装任何驱动，操作系统本身不识别它。它只存在于记忆/交接文档中，由**各设备自行解析**——解析映射登记在本机 `memory/devices/<设备名>.md`（如 `nas:// → Z:\` 或 `nas:// → /mnt/nas`）。
- **各系统解析方式**：Windows 用内建 SMB 映射 `Z:\`（无需额外软件）；Linux/Termux 挂载 SMB 需安装 `cifs-utils` 后 mount 到 `/mnt/nas`；**无挂载能力的设备（iOS、未 root 的部分 Android）遇到 `nas://` 引用时不得尝试访问**，应提示人类或将该文件改为经 Git 传递副本。
- **NAS 降级行为**：挂载点不可达时，Agent 应立即报告人类并暂停涉及大文件的任务；**禁止**将本应存 NAS 的大文件临时塞进 Git 工作区或 `tmp/` 长期驻留（`tmp/` 停留超过 24h 的大文件视为违规）。

### 3. 百度网盘冷备 (5T 免费空间)
- **定位**：仅用于夜间单向冷备，**严禁 Agent 直连 API 进行高频读写**（受限于限速）。
- **凭证**：使用已申请的官方 API（AppKey/SecretKey），密钥本体存于各设备 `~/.agent-shared/config/`（手动分发，见 六）。
- **脚本**：使用 `rclone` 或定时 Python 脚本，每日凌晨将 NAS 的 `backup/` 推送至网盘。增量备份，不覆盖删除。
- **rclone 后端风险（v1.5 新增）**：百度网盘的 rclone 后端长期属实验性状态，可能因限速/接口变更**静默失败**。因此：
  - **先决验证**：备份方案部署后的第一周，人类每日核对 `manifest` 是否正常生成，确认链路稳定后才转入无人值守；
  - **备选方案**：若 rclone 后端不可用，改为"本地/NAS 上加密打包（7z 加密或 rclone crypt）→ 人工手动上传网盘"，**严禁明文上传**；
- **备份验证（v1.2 新增）**：
  - 每次备份完成后脚本生成 `backup/manifest-YYYY-MM-DD.sha256`（文件清单与校验和），随备份一起上传；
  - 每月人类随机抽取 1–2 个文件走一次**恢复演练**（从网盘拉回并比对校验和）；
  - 备份脚本连续 3 天失败时，必须产生人类可感知的告警，禁止静默失败。**告警渠道具体化**：默认**邮件**（无第三方依赖），可选 Server酱 / Bark 手机推送；渠道与凭证配置在本机 `config/` 并登记进 `keys-checklist.md`。

## 六、 密钥管理（v1.2 新增）

- 密钥**永不入 Git**，采用**手动分发**：新设备初始化时，由人类参照根目录 `keys-checklist.md`（该清单只列密钥名称与用途，不含密钥值）逐项手动复制到本机 `~/.agent-shared/config/`。
- `keys-checklist.md` 与密钥文件必须同步维护：新增密钥时，先更新清单再分发；废弃密钥时，清单标注废弃日期。
- 各设备 agent 在启动自检中核对：清单中的每一项在本机 `config/` 是否存在（只查存在性，不读内容）。缺项时报错并提醒人类补齐。

### 1. 防泄漏技术措施 (v1.5 新增)
"密钥不入 Git"不能只靠纪律，仓库根目录**必须**落实：
- **`.gitignore` 强制模板**（存于 `env/.gitignore.template`，clone 后首先复制生效）：
  ```gitignore
  config/
  tmp/
  *venv*/
  node_modules/
  .env
  *.pyc
  ```
- **gitleaks pre-commit hook**：每台设备安装 [gitleaks](https://github.com/gitleaks/gitleaks) 并配置为 pre-commit hook（`gitleaks protect --staged`）。**hook 必须链式委托**：全局 `core.hooksPath` 指向 `~/.agent-tools/hooks`，该 hook 先执行 gitleaks，随后**转发调用项目自身的 pre-commit**（`$(git rev-parse --git-dir)/hooks/pre-commit`），不得整体覆盖 husky 等项目级钩子。Linux/Termux 与 Windows（Git Bash hook 通用）一致。
- **服务端扫描（可选）**：GitHub 私有库的 push protection/secret scanning 属付费高级功能，Gitee 个人版无此功能；**有条件则开启，无条件以本地 hook 为准**。
- **事故处置**：一旦密钥被提交并推送：
  1. **立即轮换该密钥**——仅删除文件无效，密钥已永久留在 Git 历史中；
  2. 在 `keys-checklist.md` 标注泄漏与轮换日期；
  3. 历史清理：简单场景直接**重建仓库**（删库重推，双远端同步重建），保留场景用 `git filter-repo` 清洗后强推双远端；
  4. 排查泄漏窗口期内的 clone 记录（哪些设备/人拉取过）。

## 七、 项目代码（v1.2 新增）

- 本仓库（`~/.agent-shared`）**不同步任何项目代码**。
- 所有项目代码仓库在 `env/repos.md` 登记，每条包含：

  ```
  | 项目名 | Git 地址 | 默认分支 | 本地约定克隆路径 | 简述 | 记忆文件 |
  ```

- agent 需要处理某项目时，按登记表 clone 到约定的本地路径（**统一为 `~/source/<项目名>`**），项目运行时依赖装进 `~/.agent-tools/venvs/<项目名或agent名>/`。
- 项目相关的记忆写在 `memory/projects/<项目名>.md`，并与登记表中"记忆文件"列对应。

## 八、 Agent 启动自检指令 (必读)

当你（Agent）启动或接入新任务时，请按顺序执行以下自检。标签含义：`[Agent自动]` = agent 自行判定并完成；`[Agent报告]` = agent 只能检查并上报状态，处置权在人类；`[人类执行]` = agent 无法完成，必须请人类操作。

1. **[Agent自动]** 检查 `~/.agent-shared/memory/` 记忆目录是否正常；核对 `keys-checklist.md` 中各项在本机 `config/` 是否存在（缺项即提醒人类）；**检查 `config/` 目录权限**——Linux/Termux 应为 `700`/文件 `600`，Windows 确认未共享给其他用户，权限过宽即提醒人类收紧（缺项与权限整改属 `[人类执行]`）。
2. **[Agent报告]** 检查本地 MCP 服务是否在线（尝试访问 `127.0.0.1:9101`）。如果不在线，提醒用户运行 `~/.agent-shared/env/start-mcp.sh`（Windows 为 `start-mcp.bat` 或对应计划任务）——启动服务涉及人类环境决策，MCP 未起时不得阻塞其他自检项。
3. **[Agent自动]** `git pull --rebase` 同步最新状态；读取 `~/.agent-shared/handoff/` 下最新的交接文档，同步当前上下文（按 三-1 加载策略，只读最新一份、org.md 只读最近 200 行）。远端未配置或网络不可达时降级为 `[Agent报告]`，如实上报并继续。
4. **[Agent自动]** 检查 `memory/.compact-lock` 是否存在：存在则本会话**暂停写入记忆**（其他设备正在压缩），可正常读。
5. **[Agent自动]** 确认当前是否激活了位于 `~/.agent-tools/venvs/` 下的专属虚拟环境（查 `$VIRTUAL_ENV`）。
6. **[Agent自动]** 若本会话需要手动安装的定制 MCP，先查 `env/mcp-registry.md` 确认本机是否已安装及版本是否一致。
7. **[Agent报告]** 若本会话涉及重要文档，确认 `~/.agent-docs` 同步目录可达且同步状态正常（长期未同步/冲突文件堆积时，先提醒人类处理，禁止在未同步状态下直接编辑覆盖；同步冲突的处置一律由人类在客户端完成，见 三-5 ⑥）。

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
10. 在 `env/repos.md` 登记所有项目代码仓库地址。
11. **指定主设备**（负责月度记忆压缩）并写入设备登记表。
12. 将本文件（`global/rules.md`）发送给所有接入的 Agent 阅读。

## 十、 治理（v1.2 新增）

- **裁决人**：本规范的唯一维护者与冲突最终裁决人是仓库所有者（人类用户）。任何 agent 无法解决的冲突、规范未覆盖的场景，一律上报人类裁决，不得自行创设规则。
- **副裁决人 (v1.5 新增)**：人类可指定一名副裁决人（写入本节及 `memory/devices/_devices.md` 备注），在所有者不可用时（离线、授权范围外）代理规范级冲突的临时裁决；副裁决人的裁决需在所有者下次在场时追认。未指定副裁决人时，冲突一律挂起等待所有者。
- **修订流程**：规范变更由人类批准后修改 `global/rules.md`，并在顶部"变更记录"追加条目；所有设备在下一次自检时通过 `git pull` 自然获取新版。
