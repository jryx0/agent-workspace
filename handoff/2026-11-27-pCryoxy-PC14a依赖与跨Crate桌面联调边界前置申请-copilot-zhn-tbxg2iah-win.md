# pCryoxy PC-14a 前置申请｜runtime-host 与桌面联调边界

- project: pCryoxy
- author: `[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-27 10:10 UTC+8]`
- 基座：`origin/main d2fba8f`；分支 `agent/copilot/pc14a`，worktree 已建且干净。
- 状态：**doing / 等待人类 + antigravity 批准**；尚未改任何 `Cargo.toml`、锁文件、公共契约、源码或 UI。

## A. 依赖结论：可做到 0 个新增 registry 包

`runtime-host` 直接复用已有锁：path 依赖 `core-ir/plugin-sdk/secure-store/protocol-parser/plugin-xray/engine-scheduler`；`tokio 1.54.1`（仅 `rt-multi-thread,sync,time`）、`serde 1.0.229`、`serde_json 1.0.154`、`zeroize 1.8.2`、`sha2 0.10.9`、`getrandom 0.4.3`。`dirs 7.0.0` 已在锁，但不建议把用户目录探测埋入核心库：runtime-host 接收宿主传入的数据/锁文件路径，tauri-app 用 Tauri `path()` API 决定目录。

Windows 生产后端只增开 `windows-sys 0.61.2` feature：
- `Win32_System_Registry`：只读/写当前用户 `HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings`。
- `Win32_UI_WindowsAndMessaging`：`MessageBoxW` 原生确认框；不引入 `tauri-plugin-dialog`。
- 现已有 `Win32_Foundation`；写恢复文件使用 std File + `sync_all`，不加 `dirs`/`tempfile`/文件锁 crate。

`pcryoxy-app` 只增加 path 依赖 `runtime-host` + `plugin-sdk`/`secure-store`/`serde_json`，并启用 Tauri 现有核心 `emit`/command/state 能力；不引入 Tauri plugin dialog。**无需联网 cargo fetch，锁中只有工作区成员引用和既有 feature 边，计划 0 个新 crate/package version。**

## B. 27 个公共命令与桌面事件

`Command::ALL` 已冻结为 27 项。tauri-app 将逐个注册 `{ request }` 命令，不改 `public_dto.rs`/`generated.ts`：

1. `app_snapshot`, `nodes_list`, `import_submit`, `import_from_file`, `conflicts_list`
2. `conflict_resolve`, `node_credentials_replace`, `nodes_remove`
3. `subscriptions_list`, `subscription_settings_set`, `subscription_refresh`
4. `groups_list`, `group_upsert`, `group_remove`, `rules_get`, `rules_replace`
5. `health_settings_set`, `probe_start`, `runtime_set`
6. `updates_check`, `update_apply`, `core_rollback`, `operation_get`, `operation_cancel`
7. `confirmation_open`, `events_open`, `events_close`

实现状态：M4 的 `updates_check/update_apply/core_rollback` 明确返回 `UnsupportedCapability`；`events_*` 产出 `pcryoxy://event`，使用现有 `AppEvent/EventPayload/EventCursor`。不为 27 命令增加 REST 路由或修改 TS 生成契约。

原生确认：Tauri command `confirmation_open` 在 Windows 调用 `MessageBoxW`，展示动作 + 安全目标摘要 + 当前 revision；同意后签发 60s、一次性、绑定 `(action digest,target digest,expected_revision,window_id)` 的 confirmationId。CLI/runtime-host 不实现 UI，也不持 Tauri 类型。

## C. 三项必须先裁定的契约/边界缺口

### C-1 `StoredSnapshot` 当前没有任何持久化编解码 API

`core_ir::StoredSnapshot` 的字段全部私有、无 `serde`，`core-ir` 也无 serde 依赖。它能 `to_stored/restore`，但 runtime-host 无法把它落盘再读取；不能从 `Snapshot` 猜测私有字段合法构造。

**推荐批准项 C-1**：只改 `crates/core-ir/{Cargo.toml,src/validated.rs}`，新增一个**私有二进制/JSON 编码 API**，由 `StoredSnapshot::encode() -> Zeroizing<Vec<u8>>` 与 `StoredSnapshot::decode()` 提供 schemaVersion=1。可走紧凑手写 codec（不新增 crate），也可给 core-ir 增已锁 serde/serde_json 后为 Stored* 添加序列化。所有公开 `Snapshot/Node/SecretRef` 不泛用 Serialize；禁止 Debug。runtime-host 只保存编码后的 `StoredSnapshot` + `VaultVersion` + config revision；崩溃对账失败返回 `DiskMemoryDiverged`。若不批准，PC-14a 无法诚实实现卡面“StoredSnapshot + Vault 单指针持久化”。

### C-2 engine-scheduler 参数不可注入

`scheduler.rs` 的 `probe_round` 固定 30s cadence/5s timeout，`health.rs` 固定 3/2/16，`LowestLatency` 运行时拒绝 tolerance !=50ms。`HealthSettingsSet` / `GroupUpsert` DTO 却包含参数。

**推荐批准项 C-2**：仅改 `crates/engine-scheduler/src/{health,scheduler}.rs`，新增 `SchedulerPolicy`/`set_policy`；M2 默认严格为 G5，但 `HealthSettingsSet` 只接受与当前固定默认完全一致的值（30000/5000/16/3/2），否则 `InvalidInput`，不伪称支持任意调参。`GroupUpsert.tolerance_ms` 只接受 50；其他值拒绝。新增 `health_states()/last_rtt/cycle_event` 只返回安全内部 DTO 数据给 runtime-host，不泄漏目标 URL/凭据。

### C-3 浏览器无法产生真正的 `ImportFromFile` ticket

`ImportDrawer` 当前用前端 UUID `file-ticket-*`，没有命令把本地文件内容先送入后端；`import_from_file` 的唯一 payload 又只有 `import_ticket`。真实 Tauri 的前端不能用这个随机票据读取磁盘。

**推荐批准项 C-3**：在 `tauri-app` 增一个不进入公共 27 命令契约的内部命令 `__pcryoxy_import_stage_file`（webview 选择 File 后读取 `Uint8Array`，IPC 送字节、返回 backend ticket）。随后 UI 仍调用冻结的公共 `import_from_file`；ticket TTL/一次性消费/上限由 runtime-host 维护。该内部命令不进入 `public_dto/generated.ts`。替代选择是一次性改前端把文本文件当 `ImportSubmit(ShareLinks)`；这会让 `import_from_file` 在 M2 仍是不可用的成功形状或 fake，不建议。

## D. 文件边界申请

获批后拟动：
- 新 `crates/runtime-host/**`；根 `Cargo.toml`；根 `Cargo.lock`；`tools/build-linux` 与 `tools/build-windows.ps1`（加入 runtime-host 和可验证 xray.exe 的 staging/copy，不把 xray 入仓库）。
- C-1 仅 `crates/core-ir/Cargo.toml` + `src/validated.rs`。
- C-2 仅 `crates/engine-scheduler/src/health.rs` + `scheduler.rs` + 对应测试。
- `crates/tauri-app/Cargo.toml/tauri.conf.json/src/**`、必要 `build.rs` 不改生成语义。
- UI 若批准 C-3：`ui/src/state/store.ts`（Tauri 默认驱动、去掉 startup conflicts_list 空 operationId、内部文件 staging）、`ui/src/components/ImportDrawer.tsx`（真实 File bytes staging），`ui/src/components/HeaderBar.tsx`（移除冗余表达式），以及失败口径。

不得改 `public_dto.rs`、`generated.ts`、`proto.lock`、`contracts/**`、secure-store、plugin-sdk 公共 trait、xray proto、PC-09 外的 public APIs。

## E. 系统代理与 R3

`SystemProxyBackend` 纯 trait；生产实现仅 Windows `HKEY_CURRENT_USER` 三项。写前恢复文件由 runtime-host 持久化 `(expected ProxyEnable/Server/Override)` 与 `owner token`。恢复时先读当前值；仅三项都与本次写入完全一致才恢复旧值。否则只清掉 recovery claim 并返回明确 `DiskMemoryDiverged/RevisionConflict` 类状态，不覆盖 v2rayN 或其他软件。PID 9040 / 10808 只做“存在性识别”检查，生产与自动测试均不连接、不终止、不改写。

所有自动测试注入 MockBackend 或临时导入键名称的隔离 backend；**不会调用真实 HKCU Internet Settings**。运行真实 pCryoxy 的手工桌面签收由人类明确窗口批准后另做，非本次自动门禁。

## F. 对照 27 命令的实现责任

| 命令组 | handler 责任 |
|---|---|
| 查询/事件 | Snapshot/Nodes/List/Groups/Rules/Operations + bounded event ring/resync |
| 导入 | parser + vault staging；conflict operation；文件 ticket staging |
| 凭据/组/规则 | 原子 snapshot + vault version + expected revision；单写者 commit pointer |
| 健康/调度 | G5 policy 校验、probe start、scheduler event mapping |
| runtime | Start/Stop、LocalProxy/SystemProxy/Vpn；Vpn 固定 UnsupportedCapability |
| update/M4 | 3 个 M4 命令固定 UnsupportedCapability |
| confirmation | 原生框、一次性绑定 token、消费校验 |

## G. M2 可运行产物与 xray.exe

`runtime-host` 只接受“已验证的固定 xray.exe 路径”，生产默认优先同目录 `xray.exe`，测试经显式 `XRAY_BIN`/fixture 注入。`tools/build-windows.ps1` 申请增加：若 `PC07_XRAY_BIN` 已设置且 `core-lock` hash/size 通过，复制到 bundle resource/staging；否则只构建 `pCryoxy.exe` 但打印“缺固定核心，运行时 IncompatibleVersion/Unavailable”，不得自动下载。是否要求本次 build-windows 默认产出含 xray 的安装包/NSIS 需人类拍板：目标是“可运行 exe”，最低可按 `target/release/xray.exe + pcryoxy.exe` 同目录交付。

## H. 批复项

1. C-1 批准 core-ir 增 `StoredSnapshot` encode/decode（选：手写零依赖 codec 或复用锁内 serde/serde_json）。
2. C-2 批准 engine-scheduler 的只读接口 + 受限 policy setter/事件读取。
3. C-3 批准内部 `__pcryoxy_import_stage_file`，或选替代 A（文件文本走 import_submit，`import_from_file` 保持 UnsupportedCapability）。
4. 批准文件边界与 UI 4 项适配；其中失败时建议**保留单向输入并不清空**，只显示错误，关闭后才清除，避免重输敏感数据但仍不落盘。
5. 批准 build-windows 的固定 xray staging 方案（A 同目录，B Tauri bundle.resources；不得下载/入 Git）。
