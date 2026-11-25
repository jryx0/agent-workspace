> **Source**: `global/rules.md` spec volume (v3.0, synced with `rules.md`)
> **Section**: `S3.8` (`S3.8a` - `S3.8i`)
> **Trigger**: 新设备/新账号/新 Agent 首次接入、命名或变更账号标识、虚机接入、处理多账号凭据或部署授权边界时
> **Authority**: 与 `rules.md` 同等效力，受 `R4` 保护；修订见 `[spec/governance.md#S9]`。

## S3.8 Multi-Account Collaboration

- **S3.8a 账号定位（定责标签，不进防撞键）**：账号标识仅作权限域与定责标签；任务防撞键始终是 **`项目 + 任务ID`**（`S3.5c`），不得因切换账号重复认领或无视 `memory/suspended.md`。
- **S3.8b 三段式命名与登记**：
  - 格式：`<账号主体>-<设备简标>-<OS段>`，段间用 `-`，**段内禁止出现 `-`**（例如 `zhn-x-w`、`zhn3b-x-w`）。
  - OS 字母表：`w`=Windows、`l`=Linux、`i`=iOS/iPadOS、`a`=Android、`m`=macOS、`h`=HarmonyOS、`wl`=WSL、`o`=其他。
  - 所有标识由人类指定并登记于 `env/agents.md`（设备简标先登记于 `memory/devices/_devices.md`）；未登记标识不得用于署名、认领或部署。
  - **首次接入即提示**：新设备/新账号/新 Agent 首次接入时，首条输出必须提示人类按三段式定名、给出候选串，并询问「是否为虚机」；人类确认前禁自取或从目录名推断。
  - **虚机独立设备**：虚机不沿用宿主设备简标，须在 `_devices.md` 单独登记并分配独立简标，OS 段加 `v` 前缀（如 `vw`）；**`v` 前缀仅由人类声明，Agent 不得自动探测**。虚机与宿主凭据完全隔离，禁止从宿主复制 `config/`。
- **S3.8c 历史不追溯**：署名、认领、部署留痕统一使用 `agent@device~account`；账号标识调整时仅在 `env/agents.md` 维护旧名→新名映射，不改写历史记忆或旧交接。
- **S3.8d 注入按账号配置**：平台全局指令（L1）须在每个账号下各配置并验收一次；即使平台底层配置文件为机器级共用，也不得免去另一账号的独立验收。
- **S3.8e 隔离维度**：`tmp/`、worktree 目录、自起端口按 `~<account>` 细分防撞；Python venv 遵循 `[spec/toolchain.md#S4.5b]` 按 Agent 共用不按账号拆分。
- **S3.8f 身份与记忆隔离**：平台账号私有目录（如 `user-<id>-*`）严格按账号隔离，**严禁跨账号复制**，严禁写入 Git（`R1`）。
- **S3.8g 凭据共用边界**：`~/.agent-shared/config/` 与机器级连接器授权的允许共用范围仅限 **「同一台设备 + 同一个 Agent 软件 + 同一主体」**。**跨设备、跨 Agent 软件严禁复制或分发私钥、Token、登录态（如 `~/.lark-cli/config.json`）或连接器授权**；同机同软件若出现不同法人主体账号，是否共用须人类单独裁决。
- **S3.8h 部署授权不跨账号**：人类点名授权某 Agent 部署时须同时指明具体账号标识（`~<account>`），授权不可跨账号推定（`[spec/deploy.md#S3.7a]`）。
- **S3.8i 启用与变更留痕**：新增/停用账号标识直接更新 `env/agents.md` 登记表，并同步在 `memory/org.md` 追加一行 append-only 留痕。
