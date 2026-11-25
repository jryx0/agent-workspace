> **Source**: `global/rules.md` spec volume (v3.0, synced with `rules.md`)
> **Section**: `S5.2`, `S5.3`
> **Trigger**: 涉及 NAS 挂载与 `nas://` 引用、冷备脚本、备份校验与恢复演练时
> **Authority**: 与 `rules.md` 同等效力，受 `R4` 保护；修订见 `[spec/governance.md#S9]`。

## S5.2 NAS Storage Rules

- **S5.2a 挂载点**：Linux `/mnt/nas`，Windows `Z:\`（Git Bash `/z`）。
- **S5.2b 分流边界**：单文件超过 100MB、视频、扫描件、大二进制与归档存 NAS `docs/`，**禁止存入 Git**；需要跨设备频繁查看/编辑的文档原件（≤100MB）放 `~/.agent-docs`（`[spec/layout.md#S2.3]`）。冷备文件放 NAS `backup/`，禁止 Agent 在会话中实时读取。
- **S5.2c `nas://` 文本引用**：记忆与交接统一写相对 NAS 根的路径（如 `nas://docs/<项目>/<文件名>`）。`nas://` 是文本约定而非系统协议，映射登记在 `memory/devices/<device>.md`。
- **S5.2d 无挂载能力设备**：iOS 或未挂载 SMB 的 Android 遇 `nas://` **不得尝试访问**，须提示人类或改走其他合规通道。
- **S5.2e 降级禁止塞仓**：挂载不可达时立即报告人类并暂停大文件任务；**严禁**把大文件临时塞进 Git 工作区或留在 `tmp/` 超过 24 小时。

## S5.3 Baidu Netdisk Cold Backup

- **S5.3a 定位**：仅作 NAS 夜间单向冷备（由 NAS 自带同步工具或定时脚本独占），**严禁 Agent 直连 API 高频读写**；对外交付场景见 `skills/official-doc/zhn-docs-kb/SKILL.md`，禁止与冷备链路双写同一目标。
- **S5.3b 凭证与加密**：API 凭证仅放本机 `config/`（`[spec/secrets.md#S6]`）。若 `rclone` 后端因限速或接口变动不可用，降级为「本地/NAS 加密打包（7z 加密或 rclone crypt）→ 人工上传」，**严禁明文上传**。
- **S5.3c 校验、演练与告警**：
  - 每次冷备生成 `backup/manifest-YYYY-MM-DD.sha256` 同传；
  - 新链路首周每日核对 manifest，稳定后每月抽 1-2 个文件做恢复演练；
  - 备份连续失败 3 天必须触发人类可感知告警（默认邮件，可选 Server酱/Bark，凭证登记在 `keys-checklist.md`），禁止静默失败。
