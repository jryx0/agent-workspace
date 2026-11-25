> **Source**: `global/rules.md` spec volume (v3.0, synced with `rules.md`)
> **Section**: `S7` (`S7.1`, `S7.2`)
> **Trigger**: 新增项目、判断项目边界、处理无 Git 仓库/非 `~/source` 项目、或跨项目编码与交付时
> **Authority**: 与 `rules.md` 同等效力，受 `R4` 保护；修订见 `[spec/governance.md#S9]`。

## S7. Project Repositories

- **S7a 代码不进共享仓**：`~/.agent-shared` 严禁存放或同步任何项目源代码。
- **S7b 项目登记与路径**：所有项目在 `env/repos.md` 登记（`项目名 | Git 地址 | 默认分支 | 本地约定克隆路径 | 简述 | 记忆文件`）；标准 Git 项目统一 clone 到 `~/source/<项目>`，记忆写入 `memory/projects/<项目>.md`，Python venv 遵循 `[spec/toolchain.md#S4.5b]` 按 Agent 隔离。

### S7.1 Non-Git / Non-`~/source` Projects
- **S7.1a 判定**：`env/repos.md` 中「Git 地址 = 无」或资产不在 `~/source/<项目>/` 的项目（如 NAS 容器服务、纯文档阶段项目），须在 `env/repos.md` 的「项目属性补充表」完整登记（所有项目均须填写该表）。
- **S7.1b 豁免条款**：此类项目不适用 `S0.1c`（项目 `AGENTS.md` 挂接）、`S3.5d` 本地项目目录占用确认、`[spec/worktree.md#S3.6]` worktree、`S7b` clone 路径约定。**Agent 不得据此误报「接入未完成」，也不得创建 `~/source/<项目>/` 占位目录**。
- **S7.1c 仍适用条款**：`S3.1` 项目独立记忆、`S3.4` 交接与挂起防撞、`S3.5c` 任务认领、`[spec/deploy.md#S3.7]` 部署权限（引擎启停/容器重启/升级均属部署）、`[spec/secrets.md#S6]` 密钥、`S8` 启动自检、`[spec/toolchain.md#S4.5]` 依赖复用。诊断任务默认只读。
- **S7.1d 项目级凭据落点**：`wrangler` OAuth、云厂商 token、NAS SSH 等存于项目本地或平台凭据库时，不放入 `~/.agent-shared/config/`，也不计入 `keys-checklist.md` 存在性核对，但**必须在 `env/repos.md` 属性表注明落点与防入库措施**；登录输出类临时文件须加入项目 `.gitignore`，严禁提交（`R1`）。

### S7.2 Cross-Project Coding & Delivery Baseline
仅包含跨所有技术栈通用的硬底线；语言/框架级规范、目录结构与具体命令一律写在各项目 `AGENTS.md`（不与全局重复）：

- **S7.2a 文件编码与行尾**：源码、脚本（尤其 `.sh`）、配置与 Markdown 统一使用 **UTF-8（无 BOM）+ LF (`\n`)**；仅 Windows 批处理（`.bat`/`.cmd`）允许 CRLF。标准项目仓库应维护 `.gitattributes` 锁定行尾，防止跨 Windows/Linux 产生 `\r` 报错或无效 diff。
- **S7.2b 实测门禁（禁止目测过关）**：改动代码前确认基线可构建/可测试；提交或交接前必须运行项目 `AGENTS.md` 规定的 `build` / `test` / `lint`（含项目要求的跨平台目标检查），并在交接摘要或 commit 说明中附**实测命令与结果**；未实测通过不得宣称完成。
- **S7.2c 依赖与锁文件同步**：增删改任何项目依赖（`package.json`、`Cargo.toml`、`go.mod`、`requirements.txt` 等）必须同步更新对应 lockfile（`pnpm-lock.yaml`/`package-lock.json`/`Cargo.lock`/`go.sum`）并过一致性校验（如 `go mod verify`、`cargo check --locked`），禁止提交半截依赖声明。
- **S7.2d 最小改动与契约先审**：不顺手格式化或重构任务范围外的无关代码（防多 Agent 合并冲突与审查噪音）；涉及跨模块公共接口、数据结构、API 协议或数据库 Schema/DDL 变更时，**先提契约变更说明经人类或审核方确认后再改代码**。
- **S7.2e 路径与配置零硬编码**：代码中严禁写死本机绝对路径（如 `C:\Users\...`）、内网固定 IP 或凭据（`R1`），统一通过环境变量、配置文件或相对路径注入，保证跨设备可复现。
