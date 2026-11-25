> **Source**: `global/rules.md` spec volume (v3.0, synced with `rules.md`)
> **Section**: `S4` (`S4.1`, `S4.2`, `S4.3`, `S4.4`, `S4.5`)
> **Trigger**: 安装/升级依赖或工具、配置 MCP、排查工具链基线、处理 WSL 或移动端只读边界时
> **Authority**: 与 `rules.md` 同等效力，受 `R4` 保护；修订见 `[spec/governance.md#S9]`。

## S4. Toolchain & MCP

### S4.1 Runtime & Shell Discipline
- **S4.1a Shell 与 WSL 边界**：Windows 统一使用 **Git Bash** 执行规范内所有 `.sh` 脚本；无须为跑脚本搭建 WSL。**工作区（`~/.agent-shared`、`~/.agent-tools`、`~/.agent-docs`、`~/source`）严禁在 WSL 内建第二份副本**；若未来确需在 WSL 内运行 Agent，须人类单独登记 `wl` 账号标识（`[spec/accounts.md#S3.8b]`）并读写 Windows 侧同一工作区。
- **S4.1b 环境清单与固定版本**：跨设备通用 Python 库统一固定版本写入 `env/requirements.txt`；各机独立构建 `~/.agent-tools/venvs/<agent>/`，不把 `venv/`、`node_modules/` 或二进制入 Git。
- **S4.1c 本地 MCP 运行**：MCP Server 绑定 `127.0.0.1`，通过 `env/start-mcp.sh` / `start-mcp.bat`（或计划任务）本机自启，PID 与日志写 `~/.agent-tools/run/`。

### S4.2 MCP Tiered Management
- **S4.2a 公开市场 MCP**：统一登记在 `env/mcp-config.json`，各设备可直接同步安装；密钥仅放本机配置或 `config/`，不进 Git（`R1`）。
- **S4.2b 定制/手动安装 MCP**：源码或安装物放本机 `~/.agent-tools/mcp/`，登记元数据（名称、来源、版本、端口、启动命令）进 `env/mcp-registry.md`；不共享构建产物。
- **S4.2c 端口与授权**：自起服务遵循 `S3.5a` 端口段分配；新增或修改 MCP Server 须人类在客户端确认信任后生效。

### S4.3 Cross-Device Access (No Mesh Networking)
- **S4.3a 终端设备（Windows / Linux / Android-Termux）**：本地运行 `git pull/sync` 与本地工具/MCP，通过 Git 双远端与文档同步区交换数据，不要求跨设备直连组网。
- **S4.3b 移动端 / 无终端只读设备（如 iOS）**：默认**只读**，不落本地工作区，不得尝试访问 `nas://`；通过文档同步 App 或飞书只读副本查看文档。**紧急 handoff 例外**：仅在确需记录紧急人类决策时，可由网页端在 `handoff/` 新增文件并在首行标注 `[mobile-emergency]`，严禁改写 `memory/` 或既有文件。

### S4.4 Toolchain Baseline & Anti-Global Rules
- **S4.4a 基线登记**：跨设备通用工具基线与变更日志维护在 `env/toolchain.md`（`Sec 2` 基线表、`Sec 5` append-only 变更日志）；每台设备实测清单由 `env/tools-scan.sh --write` 自动生成至 `memory/devices/tools-<device>.md`（禁止手改）。
- **S4.4b 扫描节奏**：装任何工具/依赖前先跑 `bash ~/.agent-shared/env/tools-scan.sh --check`；`~/.agent-tools/run/tools-scan.stamp` 未满 **30 天**禁止重跑全量 `--write`（仅新设备首次、满 30 天或工具变动时 `--write`）。
- **S4.4c 探测优先**：安装前先 `command -v <tool>` 与 `--version` 探测；达标即标记「复用」，禁止重复安装。若 `tools-scan.sh` 发现工具已装于托管运行时目录但当前会话 `PATH` 不可见，**禁止重装**，改用注入 PATH 或绝对路径调用。
- **S4.4d 禁全局/用户级安装（落地 `R2`）**：判定标准为**最终落盘位置**而非命令参数——`npm install -g`、`pip install --user`、裸 `pip install` 落入系统目录或 `%APPDATA%\Python\...\site-packages` 一律违规；必须指定目标 venv（如 `~/.agent-tools/venvs/<agent>/Scripts/python -m pip install ...`）或项目本地依赖。
- **S4.4e 工具区二进制**：单文件 CLI（如 `gitleaks`、`lark-cli`、`jq`）只认官方 Release（校验版本/哈希）或系统包管理器，放 `~/.agent-tools/bin/`；禁止散落项目目录，禁止用来源不明二进制处理密钥。
- **S4.4f 变更 10 分钟闭环**：新装/升级/卸载后，立即 `--write` 刷新设备清单 + 在 `env/toolchain.md` `Sec 5` 追加日志（通用 Python 库同步固定版本进 `env/requirements.txt`），10 分钟内 commit + `git sync`。未登记安装视为不合规，禁止用「补登记」将违规落盘合法化。
- **S4.4g 项目级 CLI**：`wrangler`、`vite`、`tsc` 等项目级 CLI 一律作为项目 `devDependency` 写入项目 `package.json` 与 lock 文件，通过 `npx` / 项目脚本调用，不得全局安装。

### S4.5 Layered Reuse of General Libraries
- **S4.5a 复用优先级（由高到低）**：
  1. **平台内置 CLI / 能力**（如 `~/.workbuddy/external-packages/` 中的文档/PDF/图片处理工具）：满足即直接调用，不另装库；
  2. **已装系统/工具区命令**（`command -v`）；
  3. **已登记通用库**（`env/requirements.txt` 与本 Agent 的 `~/.agent-tools/venvs/<agent>/`）；
  4. **确实缺失**时才按 `S4.4` 安装到本 Agent venv 并登记。
- **S4.5b venv 隔离边界**：**按 Agent 名隔离，不按项目、不按会话、不按账号拆份**。同一 Agent 的多会话、多账号、多 worktree 共用 `~/.agent-tools/venvs/<agent>/`；**跨 Agent 严禁共享、激活或改写他人 venv**。
