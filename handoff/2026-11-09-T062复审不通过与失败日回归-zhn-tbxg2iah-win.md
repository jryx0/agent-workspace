# T-062 复审记录（workbuddy）— 结论：**不通过**（1 处 P1 必修，其余全部通过）

- 时间：2026-11-09 11:15 +08
- 复审者：workbuddy@zhn-tbxg2iah-win#audit
- 被审提交：**a7d50ec**（分支 `agent/trae/collect-time-total-only`，基座 `origin/master` = `1c57149`，7 文件 +328/−11）
- 复审方式：`git archive a7d50ec` 导出**独立纯 LF 沙盒** `~/.agent-shared/tmp/workbuddy/review-t062`，不采信 trae 自报；另写探针 `probe-edge.mjs` 验证未覆盖边界

## 一、通过项（实证）

| 项 | 结果 |
|---|---|
| 白名单 | 7 文件与卡面完全一致：ingest.js / collect.js / collect_fill.js / web/tabs/collect.js / lib/web_assets.js（build 生成，非手改）/ 2 个 tools/tests 用例。**未动** schema.sql、collector、lib/diff.js、OPEN-DECISIONS |
| `check.mjs` | 0 问题 · 3 条存量提示（任务 62 / done 58 / todo 4）；路由 44 路径、路由表 46 条与契约对齐 |
| `build --check` | web_assets.js 与 37 个源文件一致 |
| 全量 `node --test` | **275 / pass 184 / fail 0 / skip 91**（基线 265/174/0/91，只增不减） |
| `web_size` | 首屏 gzip **25.3 KB** ≤ 40 KB |
| `node --check` / `diff --check` / CRLF | 全 OK，CRLF 0；改动文件 264 / 293 / 116 / 255 行，均 ≤300 |
| 缺陷一时区修法 | `RUN_UPSERT` 显式写 `ingested_at`（`nowIso()`）且 DO UPDATE 同步；`nowIso()` = `YYYY-MM-DD HH:mm:ss` 与 SQLite `datetime('now')` 同格式 → 展示层无需改；仅 ingest 写 collect_run（admin_backup 只 DELETE 不 INSERT，无旁路）；历史行不被改写有测试覆盖 |
| 缺陷二口径 | total_only 行账号数值列全 null（不冒充账号口径）、带 `total_only:true`；`activeDeviceNos` 未动 → status 视图占位行仍生成；前端三态区分（账号行 / total_only 整机行 / no_data 红字）正确；failures 契约字段保留 |
| 提交纪律 | 署名 `zhn-trae <trae@zhn-tbxg2iah-win>` + `Agent: trae`；单提交未 amend；local = origin = `a7d50ec`；`git fsck` 0；worktree 干净 |
| 非阻断异常复核 | `check_embedded.mjs` 在 `1c57149` 即坏（`worker/src/query_page.js` HEAD 就不存在，基线遗留）；`api_contract --check` 默认 `--target legacy` 离线必然全 FAIL，trae 用 `--target new` 探现网得 3 条网络超时——**本次未探现网**，路由/契约对齐已由 check.mjs 覆盖，不以其为准出 |

## 二、P1 必修：只采总量设备「当天采集失败」时从明细里彻底消失（回归）

- 位置：`worker/src/lib/collect_fill.js:39` `if (devMap[no].is_total_only) continue;`（在 `realKeys` 判重**之前**）
- 探针实证（沙盒 `probe-edge.mjs`，假 D1 库级）：
  - **A 7号当天失败**（`failed_json` 有 PRN007、`device_daily` 无行）→ 修复后明细 **2 行，PRN007 完全不存在**、无 `no_data`、无 error 文案；`failures` 数组里仍有该条但**前端 `loadDetail` 不渲染 failures**（仅注释保留契约）→ 操作员在页面上看到的是「设备消失」，不再有红字原因。
  - 基线行为（改前）该场景会合成 `no_data` 行并带 `failed_json` 的错误文案 → 红字可诊断。
- 关键点：`modules/collect.js` 补 total_only 行后**已把它们写进 `realKeys`**，故这行 skip 对有数据的日期是**冗余**，只对「无数据的日期」生效——恰好把失败日一起吞掉。
- 连带：trae 新增的 2 个用例把该行为写成了断言（`collect_fill.test.mjs:135,145`，含 `device=PRN007` 也断言 `[]`），属**把缺陷固化为期望**，需同批改写。
- 验证过的修法（沙盒实测）：**删掉该 skip 行（连同 3 行注释）**，行为立即正确——
  - A → 3 行，PRN007 出现，`no_data:true` + error 取 `failed_json` 原文；
  - C（在 failed_json 但有数据）→ 仍为 `total_only` 行，不受影响；
  - 全量测试 **273/275 通过**，仅上述 2 个需改写的用例失败 → 影响面确认最小。
- 改写建议（2 个用例）：① 无数据 + 有 failed_json → 断言合成 `no_data` 行且 error 取文案；② 有数据（realKeys 命中）→ 断言不再合成，且 `device=PRN007` 走 total_only 行不重复。

## 三、P2 建议（非阻断，建议同批或登记）

1. **is_total_only 判真写法不一致**：`collect.js` 用 `Number(...) === 1`，`collect_fill.js` 用真值判断。D1 返回 INTEGER 时等价，但同库存在 NULL 行；若保留任何 skip，统一改 `Number() === 1`。若按 P1 删除 skip，本项自然消解。
2. **停用设备口径**：`totalOnlyNos` 未过滤 `use_status='在用'`，探针 B 证实「停用但仍有 device_daily 行」的 total_only 设备会进明细（`total_only:true`）。与「实采行有数据就展示」自洽，但与 synth 的「全部在用设备」口径文档（`docs/plan-2026-11-05-show-all-active-devices.md`）表述不同 → 建议注释写明，或按人类口径加在用过或明确保留现状。
3. `MAX(print_total)/MAX(copy_total)/MAX(scan_total)`：`device_daily` 主键 `(collect_date, device_no)` 唯一，当前等价；若将来允许多行应改取最新 `created_at` 行。建议留注释即可。

## 四、下一步（待人类决定）

1. 退回 trae **追加新提交**（不 amend、不重建 worktree）只改 2 文件：`worker/src/lib/collect_fill.js`（删 skip）+ `tools/tests/unit/collect_fill.test.mjs`（改写 2 用例）；准出照旧（275+/pass 184+、check 0、build --check、CRLF 0）。
2. 我方复审通过后 ff-only 合并 + 收官（tasks.md 卡面 todo→done + 结果、BOARD、共享记忆）。
3. **部署判断**：本卡为纯 worker 代码、无 DDL/migration/secret/路由/绑定变更，属「能确定」范围；但历史 UTC 存量行订正 DML 只能由人类执行，且合并收官前不部署。

## 五、防撞与仓库状态

- 主仓 `~/source/prnmgt` 仍 `1c57149`，**未合并、未改代码、未部署、未动 D1**。
- `memory/projects/prnmgt.md` 有 trae 11:07 追加的认领 + 交付两行**未提交**；本次**未触碰、未代提交**，其复审记录以本 handoff 为凭。
- 另：trae 的 P0「只读真机调研」仍登记 `doing` 未收口，投喂下一张卡前需确认。
