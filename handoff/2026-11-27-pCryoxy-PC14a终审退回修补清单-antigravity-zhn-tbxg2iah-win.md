# pCryoxy PC-14a 终审结论｜退回修补 4 项问题（不合 main）

- project: pCryoxy
- reviewer: `[@antigravity @zhn-tbxg2iah-win~zhn-x-w 2026-11-27 14:06 UTC+8]`
- target: `agent/copilot/pc14a` @ `e4915722e2aea4d3d3a4ef4b4ce197c3a12278ed`（基座 `origin/main` `ceaad5c`）
- verdict: **退回修补（Changes Requested，暂不合入 main）**

## 已通过项（保持现有架构与边界）

1. **依赖与契约零漂移**：`Cargo.lock` 仅增加 `runtime-host` 工作区成员与 `windows-sys 0.61.2` feature 边（0 个新增外部包）；未改动 `public_dto.rs`、`ui/src/api/generated.ts`、`proto.lock` 与 `contracts/**`。
2. **`C-1` `StoredSnapshot` 手写有界编解码**：`SNAPSHOT_MAGIC` + `SNAPSHOT_SCHEMA = 1`、有界长度解码、`Zeroizing<Vec<u8>>` 输出、`restore()` + `validate_snapshot()` 复验通过。
3. **单指针原子持久化**：`.pending` + `sync_all` + `rename` 写快照、`Vault::commit_staged()`、`state.pointer.json` 与 `DiskMemoryDiverged` 收敛状态一致。
4. **系统代理与 R3 隔离**：三项比对后才恢复、不覆盖外部代理（`v2rayN` / `10808` 零触碰）；已实测 `xray.exe v26.11.9` 的 `"protocol": "socks"` 入站同端口兼容 HTTP `CONNECT` 与 SOCKS5。
5. **前端驱动切换与一次性文件 staging**：1 MiB / 16 槽 / 60s TTL / 一次性消费 + 双向零化；`ConflictResolve(ReplaceConfirmed)` 诚实返回 `UnsupportedCapability`。

## 必须修补项（完成后重测重提，不做多余重构）

### 1. [P0] `WindowsMessageBoxConfirmation` 将 `MB_OKCANCEL` 返回值误判为 `IDYES`
- 位置：`crates/runtime-host/src/confirmation.rs:26, 50, 53`
- 问题：`MessageBoxW` 使用 `MB_OKCANCEL`，Win32 确认返回 `IDOK`（1）而非 `IDYES`（6），导致点击“确定”恒返 `false`，所有需确认操作在 Windows 上不可用。
- 修补：改用 `IDOK`，抽纯函数 `const fn is_ok_cancel_accepted(result: i32) -> bool { result == IDOK }` 并补单测覆盖 `IDOK / IDCANCEL / IDYES / 0`。

### 2. [P0] 桌面命令完成后未 flush 事件流，且 `runtime_set` / `probe_start` 漏发关键事件
- 位置：`crates/tauri-app/src/lib.rs:21-36`、`crates/runtime-host/src/host.rs:280-289, 1340-1455`
- 问题：
  - (2a) `public_command!` 只调用 `host.dispatch(...)`，未立即 `drain_events()` 并 `app.emit(EVENT_NAME, ...)`，导致事件最多卡死 30s。
  - (2b) `runtime_set` 从不发送 `EventPayload::RuntimeChanged { runtime }` 与 `OperationChanged`，桌面顶栏点击“启动/停止”后 `snapshot.runtime.phase` 永不更新。
  - (2c) `probe_start` 只发 `OperationChanged`，未发 `EventPayload::NodeHealthBatch { items }`，手动测速后列表不更新延迟与健康态。
  - (2d) `events_serialized` 满容量时仅覆盖旧事件而不通知前端重同步；满时应清空积压并压入 `EventPayload::ResyncRequired`。

### 3. [P1] `DesktopState.host` 与 `self.store` 锁横跨阻塞弹窗（60s）与同步 HTTP（30s）+ 订阅刷新漏更元数据
- 位置：`crates/tauri-app/src/lib.rs:28-33, 62`、`crates/runtime-host/src/host.rs:997-1035, 1476-1519, 1666-1693`
- 问题：
  - (3a) `confirmation_open` 持有 `state.host` 锁期间阻塞等待 `MessageBoxW`，导致弹窗期间整个桌面 IPC 与退出冻结。需拆分 `prepare_confirmation` / `complete_confirmation`，弹窗期间释放 `state.host` 互斥锁，弹窗返回后再加锁复核 `expected_revision` / `state_diverged` 并签发/缓存票据（保留 `RuntimeHost::dispatch(ConfirmationOpen, ...)` 供单宿主测试直接调用）。
  - (3b) `subscription_input` 与 `subscription_refresh` 在 `self.store.with_mut`（`std::sync::Mutex`）及 `state.host` 持锁下于 Tokio async 线程同步运行 `ureq` 阻塞 HTTP（最高 30s）；须移入 `tokio::task::spawn_blocking` 且在 `store`/网络等待区间不长期占锁，完成后更新 `PersistedSubscription.node_count` 与 `last_refresh_at`。

### 4. [P2] 节点展示名覆盖与运行期实时流量节拍
- 位置：`crates/runtime-host/src/host.rs:318-331, 618`、`crates/tauri-app/src/lib.rs:90-111`
- 修补：
  - (4a) `nodes_list` 中当 `!node.display_name.as_str().is_empty()` 时，将 `view.label` 设为 `node.display_name.as_str().to_owned()`，避免节点全显示为 `"Node 1"`。
  - (4b) 拆分 `pub async fn traffic_tick(&mut self)`（仅 `HostStatus::Ready` 时采集并推送 `EventPayload::Traffic`，`sample_at` 使用可被 JS `Date.parse` 解析的 ISO-8601 UTC 字符串），桌面后台在首个立即 tick 被消费后以 **2s 周期推流量 + 30s 周期探测**运行。
