# pCryoxy PC-15a 交付待审核摘要

- project: pCryoxy
- 执行者: `[@antigravity @zhn-tbxg2iah-win~zhn-x-w 2026-11-26 16:03 UTC+8]`
- 状态: `doing`（**待审核**；需由独立会话或人类指定审核方复审，禁自审标 `done`）
- 分支与提交: `agent/antigravity/pc15a` @ `9e55d42`（基座 `3425538`，已推 `origin`）

## 核心交付（31 文件，`index.html` + `ui/src/**`，零新增依赖）
1. **双通道传输底座（`ui/src/api/`）**：
   - `client.ts` / `contract.ts` / `events.ts` / `errors.ts`：36 位 UUID v4 `requestId`、写命令自动带十进制 `expectedRevision`、查询传 `null`、`EventCursor` 断序重拉与错误字段映射。
   - `mock/driver.ts` + `mock/scenarios.ts`：全量 27 命令、异步操作流、1s `traffic` 与 4.5s `node_health_batch` 推送，内置 6 套验收场景切换器。
   - `tauri.ts`（`__TAURI_INTERNALS__` 零依赖桥接）+ `http.ts`（REST/WS 骨架）。
2. **ADR-02 选项 A 二次确认**：`ConfirmModal.tsx` 覆盖 5 类高危操作（安全摘要/去重数/`configRevision`/Esc/防连点）。
3. **5 大视图与安全输入**：`NodesView`（单向 `ImportDrawer`/`CredentialsModal`/`ConflictModal`，提交/关闭即清空）、`SubscriptionsView`（无 URL 回显）、`GroupsView`（G4 禁嵌套+3 策略+HTTP 204 探测）、`RoutingView`（拖拽/按钮排序+草稿/执行中/核心已生效三态）、`UpdatesSettingsView`（Core/Geo 独立版本、更新与回退）。
4. **原生 CSS 系统**：`tokens.css`/`base.css`/`layout.css`/`components.css`（深浅主题 + `batch()` 合并更新）。

## 门禁实测
- `tools/check-all.ps1`：退出码 `0`（Rust/TS/`generated.ts`/Proto/Gitleaks 全绿）。
- `tools/build-windows.ps1`：退出码 `0`（`target/release/pcryoxy.exe` `4179456` B；`ui/dist` JS `142876` B / CSS `15029` B）。
- 越界 diff 为空；`gitleaks`（`origin/main..HEAD`）扫描 1 commit，`no leaks found`。
