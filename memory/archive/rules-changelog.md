> **来源**：`global/rules.md` v2.5 「变更记录」全量。
> **状态**：v2.6（2026-11-13）落地时自 `global/rules.md` 迁入，只读归档；`rules.md` 只留近期版本要点 + 指针。

## 变更记录

> **精简口径（v2.3，人类 2026-11-12 12:02 指令）**：本区只保留当前版与近期版本的一行要点；v1.1–v2.2 的详细条目、触发事件、被否方案已从正文删除，可从 Git 历史查证（`git log -- global/rules.md`、`git show <提交号>:global/rules.md`）；v1.1–v1.7 另有只读归档 `memory/archive/2026-11-rules-changelog.md`。

- **v2.5 (2026-11-12)**：① **接入即提示**——新设备／新账号／新 agent 首次接入，agent 第一个输出须提示人类按三段式生成账号标识并询问是否虚机，未确认前不得自取／署名／认领／部署；② **虚机规则**——OS 段＝可选 `v` 前缀 + OS 字母（1–3 位），`v` 仅由人类声明、agent 不得自行探测，虚机作为独立设备在 `_devices.md` 单独登记并分配独立第二段简标（宿主 `zhn-x-w`／虚机 `zhn-y-vw`），与宿主凭据边界分开、`config/` 单独分发；③ 按人类批准 **改注入端二-L1／A 段全文**（新增接入提示行，最小红线集 5 条字面未改），**需人类在 UI 第四次粘贴并新开任务验收**，磁盘 `app-config.json` 不擅自改写；④ 联动 `env/agents.md`、`env/new-agent-bootstrap.md`、`memory/devices/_devices.md`、`keys-checklist.md`、两处注入端状态注释。被否方案：虚机沿用宿主简标（会让凭据边界模糊）、agent 自动探测虚机（易把容器/WSL 误判）、不改 L1（人类要求平台层也提示）。
- **v2.4 (2026-11-12)**：账号标识改为三段式 `<账号主体>-<设备简称>-<OS段>`（人类 12:24 定义）。① 第一段＝人＋账号类型（`zhn`／`zhn3b`），**不编码 agent 软件**，不同 agent 靠定责键 `agent名@设备名` 前缀区分；② 第二段设备简称由人类指定并登记进 `memory/devices/_devices.md`；③ 第三段 OS 字母表 `w`=Windows／`l`=Linux／`i`=iOS／`a`=Android／`m`=macOS／`h`=鸿蒙／`wl`=WSL／`o`=其他，按实际运行 OS 取值，段内禁 `-`、可 1–2 位小写字母；④ 标识 `zhn-x`→`zhn-x-w`、`zhn-3b-x`→`zhn3b-x-w`，旧名加映射、历史不追溯；⑤ 联动 `env/agents.md`、`keys-checklist.md`、`env/new-agent-bootstrap.md`、`memory/devices/_devices.md`、`env/execution-enforcement.md` 状态注释。**〇⑦ ③ 最小红线集 5 条字面未改，注入端无需重新粘贴**。被否方案：第一段复合编码 agent 软件（可读性差）、改四段式（违背三段约束）。
- **v2.3 (2026-11-12)**：规范压缩 + 企业账号标识带设备简标。① 变更记录瘦身，删除 v1.8.x–v2.2 长条目与版本沿革标注；② 删除过时的 `inbox/` 迁移说明，保留全部现行条款与章节号；③ 企业账号标识 `zhn-3b` → **`zhn-3b-x`**（`-x` ＝ 本机 `zhn-tbxg2iah-win` 设备简标，与 `zhn-x` 对齐）；④ 联动 `env/agents.md`、`keys-checklist.md`、`env/new-agent-bootstrap.md`、`env/execution-enforcement.md` 状态注释。**〇⑦ ③ 最小红线集 5 条字面未改**，注入端无需重新粘贴。被否方案：为压缩而删现行条款（会破坏规则完整性）。
- **v2.2 (2026-11-12)**：凭据共用边界订正——同一台设备 + 同一个 agent 软件可共用一份 `config/` 与机器级连接器授权，跨设备／跨 agent 软件禁止；身份／记忆目录仍按账号隔离。账号标识 `personal`→`zhn-x`、`corp`→`zhn-3b`；关闭「人类已裁决、正文未订正」窗口。
- **v2.1 (2026-11-12)**：新增 三-8 多账号协同（账号＝定责标签，防撞键仍「项目 + 任务ID」，注入按账号各配一次）。
- **v2.0 (2026-11-11)**：新增 〇⑦ T0/T1/T2 分级加载与任何档位不可豁免的最小红线集 5 条。

---
