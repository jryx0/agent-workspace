项目: prnmgt

# 【DRAFT · 待人类裁决】断采可见性实施卡（采集缺失 / 过期显式提示）

> 编制：workbuddy@zhn-tbxg2iah-win~zhn-x-w · 2026-11-17 11:3x +08
> 状态：**DRAFT**——未经人类书面裁定不得转 APPROVED、不得登记卡面、不得派工、不得认领、不得改码。
> 触发：用户 2026-11-17 追问「17 号碳粉 28% vs 实际 19%」→ 只读诊断确认全库自 11-13 断采，但「采集状态」页仍显示 11-13「16/16、0 错误」且无任何「缺失/未采集」提示；用户明确「数据缺失时应报缺失或错误，而不是一直显示上次数据」。
> 定性：现状是**无报警设计**（事件驱动台账 + 全量同步停更时静默），不是报警失灵；修复属**新功能**，非 bug fix。
> 卡号：**本 DRAFT 不占卡号**。`T-069` 已被本账号另一会话 11:29 占用（报表页费用选择弹窗，见 `tasks.md` T-069 卡面与 `handoff/2026-11-17-T069逐卡执行提示词-…md`），不得撞号。建议立项后分配 **T-070**（后端查询层）/ **T-071**（前端可见性）/ **T-072**（收官），以届时 `tasks.md` 实际分配为准。
> 分工（规范 v2.7 三-7〔spec/deploy.md〕）：workbuddy 编卡 / 复审 / 合并收官；执行 Agent 编码、**一律不得部署、不得执行 `wrangler d1 execute` / `wrangler deploy`、不得连采集服务器**；现网 DDL/DML/部署由人类本人执行。
> 本卡为只读诊断 + 设计草案，未改任何业务代码、未部署、未连现网、未认领任务卡。

---

## 零、待人类裁决（B1~B5，任一未定不得转 APPROVED）

| # | 决策点 | 建议 | 备选与代价 |
|---|---|---|---|
| **B1** | 立项形式 | **新 ADR-0014 豁免**（参照 ADR-0013 路径），登记进 `constitution.md` / `spec.md` / `BOARD.md` / `OPEN-DECISIONS.md` | 不立 ADR 直接做：违反「新行为需留决策痕迹」惯例，复审无依据 |
| **B2** | 缺失日在「采集状态」主表的呈现 | **默认显示、红字「未采集」标签**，与真实事件同表按日期倒序 | 折叠为开关/独立区块：更保守，但用户主诉「一眼看到缺失」打折 |
| **B3** | 「今天」的宽限阈值 | **预期时刻 20:10 + 60 分钟（21:10）前不合成今日缺失日**；今日 21:10 后仍无行才合成 | 严格按 20:10：晚上 20:30 查看会误报当天；按次日：延迟一天发现 |
| **B4** | 总览「数据新鲜度」横幅是否纳入 | **纳入前端卡**：`stale_days = 今天 − lastCollectDate`，≥1 显示「数据截至 X（距今 N 天）」黄条 | 不做：总览仍一片正常，只采集页可见 |
| **B5** | 卡号与批次 | 建议 T-070/T-071/T-072，**独立 v7 批次，不并入 v3/v4/v5**，不触碰 S1/S2/S3 | 并入 v5：v5 尚未部署，混批会拖累部署窗口 |

---

## 一、问题与证据（2026-11-17 只读实证，非推测）

### 1.1 用户看到的现象（两张截图）

- 「采集状态」主表最新一行 = `2026-11-13 20:10:55`，采集 16 / 正确 16 / 错误 0；往下是 11-12、11-11、11-10（15/16，1 错误）、11-09（15/16，1 错误）。
- 自动展开的明细标题 = 「采集事件 2026-11-13 的打印机明细（共 16 台）」，17 号行碳粉 28%、打印 12,434 / 复印 269 / 扫描 1,416。
- **页面上没有任何「缺失 / 未采集 / 数据过期」提示**；11-14~11-17 四天完全没有被表示。

### 1.2 现网数据（只读 D1 实测）

| 检查 | 结果 |
|---|---|
| `collect_run` | 末条 `2026-11-13 20:10:55 success 16/16`；`WHERE collect_date >= '2026-11-14'` → **0 行** |
| `device_daily` | `MAX(collect_date)=2026-11-13`，16 台全停 |
| `device_status_log` | `MAX(collected_at)=2026-11-13 17:10:44` |
| 17 号当前真值 | 本机直连 `10.113.124.242` 实采 `TONER_K=19`（非 28），详见当日日志 09:28 节 |

### 1.3 代码根因（三处，均已定位到行）

1. **主表只列真实事件**：`web/tabs/collect.js:81` `loadRuns` → `GET /api/collect_runs?limit=180` → `modules/collect.js:262` `runsSummary` 的 `SELECT ... FROM collect_run ORDER BY collect_date DESC LIMIT ?`。**无「应有而未到」的合成行**；全仓 grep `stale/断采/未采集/心跳/距今天` 无命中。
2. **明细自动展开最新真实日**：`collect.js:91` `state.detailDate = runsRows[0].collect_date`（=11-13）；`loadDetail` 带 `toner=collect_date` 取当日快照，28% 是 11-13 真值，**不是伪造的当前值**。页面无「距今天数/过期」提示。
3. **合成占位行覆盖不到整天缺失**：`lib/collect_fill.js:35` `synthDataRows` 的锚点 `runAtMap` 来自 `modules/collect.js:108-110` 的 `SELECT ... FROM collect_run`；**整天没采集 → 无 collect_run 行 → 无锚点 → 一行都不合成**。该机制只覆盖「有采集事件、个别设备无数据」，不覆盖「整次/整段采集缺失」。
4. **总览刻意静默**：`lib/overview_stat.js:16-17,173-177,205-209` 明确「online/abnormal 锚定 `lastCollectDate=max(collect_date)`，不是今天——今天还没采集时按今天判会把全部设备误判为异常」；16 台同步停更时 `lastCollectDate` 也是 11-13 → 全部 `online/normal`，无「快照过期」原因。**这是设计取舍，不是遗漏**。

### 1.4 结论

用户的直觉正确：系统缺「断采可见性」。但现状是「**无报警设计**」，不是「报警失灵」。修复需引入「预期采集日」概念并生成缺失事件，属**新功能**，应派卡 + 新 ADR，不在诊断会话擅改。

---

## 二、设计（建议方案，待 B1~B5 裁定后冻结）

### D1 · 预期采集日窗口（查询层合成，不落库）

- 不改 `collect_run` 表结构与语义（它仍是「真实发生过的事件台账」）。
- 在 `modules/collect.js` 的 `runsSummary(data)` 内，除真实行外合成缺失日：
  - **起点**：`SELECT MIN(collect_date) FROM collect_run`（系统首次采集日）的次日；更早不合成（避免系统上线前的大片假缺失）。
  - **终点**：`今天`，但今日仅在**当前时刻 ≥ 20:10 + 宽限（B3 建议 60 分钟）**且仍无 `collect_run` 行时合成。
  - **缺失判定**：窗口内每个日期 d，若 `collect_run` 无 d 行 → 合成一行。
  - **合成行字段**（与真实行同构，不新增契约字段）：
    `collect_date=d, collected_at=null, total_devices=activeCount, ok_devices=0, err_devices=activeCount, sum_print=null, missing=true`（`missing` 为**新增可选字段**，旧消费者忽略；前端以 `collected_at === null` 亦可识别）。
  - **严禁**：`sum_print=0`（会污染总打印量统计）；真实行的任何字段不得改动。

### D2 · 缺失日的设备明细（复用现有占位机制）

- `detailByData` 的 `runAtMap`（`modules/collect.js:108-110`）在真实 `collect_run` 行之外，**把窗口内缺失日也 put 进去，值为 null**；`synthDataRows` 自然为缺失日 × 16 台在用设备合成 `no_data=true` 占位行。
- 占位行 `error` 文案：「该日未采集（采集端无上报）」；数值列全 `null`、`toner=null`（现有红线：严禁落 0）。
- 前端已有 `no_data → error-line` 红字渲染（`collect.js:158-160`），无需改这段。

### D3 · 前端可见性

- **采集状态主表**（`web/tabs/collect.js:58-71`）：`r.collected_at === null` 的行，错误列显示红字 `<span class="error-line">未采集</span>`（替代数字），「采集事件」列日期后加「（缺失）」；`dt-active`、分页、序号逻辑不变。
- **明细标题**（`collect.js:129`）：若 `state.detailDate` 是缺失日，标题改为「采集事件 X（**该日未采集**，以下为在用设备占位）」。
- **总览横幅**（B4）：在总览页顶部（或 `overview_cards` 区）新增独立提示，`stale_days = 今天 − lastCollectDate`；≥1 显示黄色「数据截至 YYYY-MM-DD（距今 N 天），采集端可能离线」。**不得改动 `online/normal` 判定与计数**（行为等价红线）。
- **不新增任何 `/api/*` 路由**（46 路由冻结）；响应字段「只增不删」，新增 `missing` 可选字段需在 `tools/compare` 差异登记中说明。

### D4 · 禁动清单（任何卡均不得越界）

- 不改 `worker/schema.sql`、不加列、不改任何表结构/主键/索引。
- 不改 `collect_run` 写入链路（`modules/ingest.js` 的 `RUN_UPSERT`）与 `collector/**`。
- 不改 `lib/diff.js` / `lib/util.js` / `lib/overview_stat.js` 的 `online/normal` 判定段。
- 不改 `routes.js` 与 `tools/tests/fixtures/routes.json` / `api_contract.mjs` 判据。
- 不改三个 CSS 与 `web/index.html` / `web/app.js`（横幅尽量复用现有 class，必要时由执行方在卡面获批范围内最小增补）。
- 不碰 S1（T-059/060/061）/ S2（P0 二次真机调研）/ S3（v4 / #18）挂起项；本卡不构成 v4 开工令。
- 执行 Agent 不自报 done、不改卡面、不合并 master、不部署、不连现网 D1 与采集服务器。

### D5 · 验收判据（建议，立项时逐条固化进卡面）

1. 构造：首次采集日 D0、缺失日 D1、今天 Dtoday（当前时刻 < 20:10+宽限）。`GET /api/collect_runs?type=data` 返回含 D1 的 `missing=true` 行，`collected_at=null`、`err_devices=activeCount`、`sum_print=null`；**D0 当天与 Dtoday 均不合成**。
2. 今日 21:10 后仍无采集 → 合成今日缺失行；20:10 前不得合成（防误报）。
3. `GET /api/collect_detail?from=D1&to=D1&toner=collect_date` 返回 16 行 `no_data=true`，数值与 `toner` 全为 `null`，`error` 文案含「未采集」。
4. 真实事件行的全部字段与改动前逐字段相等（契约等价），`sum_print` 不被 0 污染。
5. 总览 `online/normal/abnormal` 计数与改动前相等；仅新增横幅。
6. 契约：46 路由数不变、`routes.json` 不变、`api_contract.mjs` 判据不破；新增 `missing` 为可选字段。
7. 门禁：纯 LF 沙盒 `git archive` 跑 `check.mjs` 0 问题、`build_web_assets.mjs --check`、`web_size.mjs` ≤40KB、`node --test` 全绿、改动文件 CR=0、`git diff --check` 0。
8. 部署：本卡**不涉及 DDL/表结构变更**；但依赖 v5（`aa5019f`）的 `costs.report_links` DDL 与 deploy 先完成。执行方不部署、不执行 DDL/DML。

### D6 · 部署边界（提前写清，避免重蹈 11-13 覆辙）

- 本卡只改查询层 + 前端 + 生成物，**无新列、无 migration**；但**现网仍停留在 09:49 部署的旧版**（v5 未部署），且与 v5 共用同一 Worker。
- 顺序必须是：人类先执行 v5 的 `ALTER TABLE costs ADD COLUMN report_links ...` + `wrangler deploy`，再部署本卡；单独部署本卡虽然不会像 T-064 那样报 `no such column`（本卡不读新列），但会把两个未部署批次混在一起，排障困难。
- 自检：`collect_run` 合成缺失日可见、`/` 与 `/api/config` 200、总览横幅在断采时出现且 `online/normal` 未漂移。

---

## 三、建议拆卡（待 B5 裁定后登记）

| 卡 | 范围 | 关键文件 | 执行方 |
|---|---|---|---|
| **T-070** 后端查询层合成 | 预期日窗口、`runsSummary` 合成行、`detailByData` 的 `runAtMap` 扩展、单测 | `worker/src/modules/collect.js`、`tools/tests/unit/` 新增测试 | 执行 Agent（trae） |
| **T-071** 前端可见性 | 主表缺失标识、明细标题、总览横幅（B4）、生成物 | `worker/src/web/tabs/collect.js`、`worker/src/web/tabs/overview*.js`、`worker/src/lib/web_assets.js`（生成物禁手改） | 执行 Agent（trae） |
| **T-072** 收官 | ADR-0014 + 卡面订正 + BOARD + 部署卡（3~4 文件白名单） | `docs/adr/0014-*.md`、`tasks.md`、`BOARD.md`、`OPEN-DECISIONS.md` | workbuddy |

（三卡均需 worktree 隔离 `~/source/prnmgt.wt/<agent>-<卡号>` + `agent/*` 分支；认领前查登记节防撞；执行方只登记 `doing`，不改卡面、不合并、不部署。）

---

## 四、挂起任务（当前全量快照，继承自 2026-11-16 凭证集中保管 handoff，本 DRAFT 无新增无解挂）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；卡面 todo | 重编后重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级中 | 升级完成 + 复跑探测 + 更新调研文档 | tmp 快照保留 | 续跑不重开卡 | 人类 |
| prnmgt | S3 v4 批次 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 裁定 + 新 ADR | 仅 DRAFT | 裁定后重编拆卡 | 人类 |

本 DRAFT 为人类直接指令起草，不认领任务卡；suspended 一律未开工。T-069（报表弹窗）由本账号另一会话 11:29 发布、待认领，与本 DRAFT 无关；T-065~T-068（v5）已 done 未部署。RL-004～007 状态不变。

## 五、自检与异常（本会话）

- 规范 **v2.7** 全文 + `spec/accounts.md` + `spec/deploy.md` 全文已读；`tools-scan.sh --check` exit 0（stamp 11-08）；`proxy-check.sh` exit 0（HEAD=origin=backup=`7224d80` → 推送前复核可能已变，以推送时实测为准）；MCP 9101 offline（不阻塞）；S1/S2/S3 仍 suspended，未认领、未开工。
- **补推失败（已实测，未绕过）**：人类要求「登录服务器补推」，但采集服务器 `10.113.224.20` 本机 ICMP 由网关 `10.113.226.156` 回「无法访问目标主机」，TCP/22 三次探测不可达，`plink -ssh -batch -i config/printer_ubuntu jifang@10.113.224.20` 报 `FATAL ERROR: Network error: Connection timed out`。按 `spec/deploy.md` ④「网络异常 + 生产事故恢复动作需人类拍板」**停止，不找代理/替代路径绕过**；补推未执行，数据仍停在 11-13。
- 同批多条并行命令返回「安全策略拦截」提示，所需输出已从同批其他命令取得，未重试、未用等价替代绕过，如实记录。
- 共享仓有他人未提交改动（11-13 多设备评估 handoff、`memory/projects/prnmgt.md`）与未跟踪的 T-069 提示词，全程未触碰、未代提交。
