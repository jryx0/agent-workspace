项目: prnmgt

# 【APPROVED · 可投喂】断采可见性 T-070 / T-071 逐卡执行提示词（trae 开工用）

> 编制：workbuddy@zhn-tbxg2iah-win~zhn-x-w · 2026-11-17 11:4x 定稿，2026-11-17 11:5x 转 APPROVED +08
> 状态：**APPROVED · 可投喂**——人类 2026-11-17 11:5x 逐项裁定 **B1~B5 全部按建议**（B1 新 ADR-0014 豁免；B2 缺失日默认显示红字「未采集」；B3 今日 21:10 宽限；B4 纳入总览新鲜度横幅；B5 独立 v7 批次）。立项前置已全部完成：`docs/adr/0014-collect-missing-visibility.md` ACCEPTED、`tasks.md` 已登记 T-070 / T-071 / T-072、`BOARD.md` 已加 v7 批次行与交接条目、`OPEN-DECISIONS.md` **#21 RESOLVED**、`spec.md` 第四条与 `constitution.md` 第二条人类豁免登记已写入。**可全文复制投喂 trae**。
> 设计母本：`handoff/2026-11-17-断采可见性实施卡-APPROVED-…md` 第一~六节（D1~D6、验收 1~8、禁动清单）+ `docs/adr/0014-collect-missing-visibility.md` 的 D1~D7。本文件把它拆成两张可投喂卡；T-072（收官：ADR 登记 + 卡面订正 + BOARD + 部署卡）由 workbuddy 自己做，**不投喂 trae**。
> 分工（全局规范 **v2.7** 三-7〔spec/deploy.md〕）：workbuddy 编卡 / 复审 / 合并收官；执行 Agent 编码，**一律不得部署、不得执行 `wrangler d1 execute` / `wrangler deploy`、不得连现网 D1 与采集服务器**；现网 DDL/DML/部署由人类本人执行。
> 卡号：**已登记 `tasks.md`**，T-070（后端查询层）/ T-071（前端可见性）/ T-072（收官）。T-069 已被本账号另一会话占用，不得撞号。

---

## 零、投喂前与开工前必须确认（任一项不满足即停下报告）

1. **立项前置已完成**：人类 2026-11-17 11:5x 书面裁定 B1~B5（全部按建议）→ `docs/adr/0014-collect-missing-visibility.md` 状态 ACCEPTED、T-070 / T-071 / T-072 已登记进 `tasks.md`、`BOARD.md` 已加 v7 批次行与交接条目、`docs/decisions/OPEN-DECISIONS.md` **#21 RESOLVED**、`spec.md` 第四条与 `constitution.md` 第二条人类豁免登记已写入。**本提示词状态为 APPROVED，可直接投喂**；若上述任一项与实际卡面不符，停下报告 workbuddy。
2. 读 `~/.agent-shared/global/rules.md`（现行 **v2.7**）并执行第八节自检 —— **10 步**（平台旧指令写「9 步」已过时）；同一 agent 的不同会话同样适用（三-5 ⑦）。
3. **按三-1 多项目加载**：读 `~/.agent-shared/handoff/` **最新一份** handoff 的「挂起任务（当前全量快照）」；再按项目补读 prnmgt 最近一份带 `项目:` 标签的 handoff。`org.md` 只读最近 200 行。
4. **挂起快照（防撞集合含 `suspended`）**：**S1**（T-059/T-060/T-061）、**S2**（P0 二次真机调研）、**S3**（v4 / #18）**仍 suspended，一律不得认领／开工**。T-064、T-065~T-068 已 done；T-069 由另一会话在做。本批次是 v7 独立批次，**不构成 v4 开工令**。
5. 按 `AGENTS.md` 必读顺序读：`constitution.md` → `BOARD.md` → `specs/0001-prnmgt-refactor/spec.md` → `tasks.md` 的 **本卡卡面** → `docs/decisions/OPEN-DECISIONS.md` → `docs/adr/0014-*.md` → 本提示词 → DRAFT 实施卡。
6. **认领登记（三-5 ⑤）**：查 `~/.agent-shared/memory/projects/prnmgt.md` 任务登记节，确认目标卡未被他人认领（doing/open/suspended），然后**追加一行** `【任务认领】T-07x | 断采可见性… | trae | doing`（append-only，禁止改旧行、不代提交）。
7. **基座判据（不写死 hash）**：`git fetch origin` 后实测 `git rev-parse origin/master` 与本地 HEAD 一致，把实测号写入交付报告；以**认领时刻的 `origin/master`** 为基座建 worktree。实测核验（任一不满足停下）：
   ```bash
   git show origin/master:worker/src/modules/collect.js | grep -n "runsSummary"      # 期望存在
   git show origin/master:worker/src/lib/collect_fill.js | grep -n "synthDataRows"   # 期望存在
   git show origin/master:worker/schema.sql | grep -n "report_links"                 # v5 已合并
   git cat-file -e origin/master:worker/migrations/20261117_cost_report_links.sql    # 期望存在
   ```
8. **worktree 隔离**：T-070 用 `~/source/prnmgt.wt/trae-t070` + 分支 `agent/trae/T-070`；T-071 用 `~/source/prnmgt.wt/trae-t071` + 分支 `agent/trae/T-071`。主仓 `~/source/prnmgt` 的其它 worktree 与既有未跟踪项（`.login-out.txt`、`docs/paper/**`、`docs/plan-*`、`tmp/`）**不触碰、不提交**。
9. **一次只做一张卡**：T-070 复审通过并 ff-only 合并后，才认领 T-071。不改卡面、不自报 done、不合并 master、不改任何治理文档（第六节禁动清单）。
10. 提交用一次性署名 `git -c user.name=zhn-trae -c user.email=trae@zhn-tbxg2iah-win commit -m "..." -m "Agent: trae"`；推分支到 origin 后**停下等 workbuddy 复审**。追加修正用**新提交，不 amend**。
11. **纯本地编码与测试**：不连现网 D1、不执行 `wrangler d1 execute` / `wrangler deploy`、不登录采集服务器。现网仍停留在 09:49 部署的旧版（v5 未部署），**不得据此断定「已上线」**。
12. CRLF：项目仓 `core.autocrlf=false`，以**纯 LF 沙盒 `git archive` 导出**跑门禁；改动文件 CRLF 必须为 0，`web_assets.js` 等生成物不得手改。

---

## 一、T-070 后端：查询层合成缺失日（trae）

### 1.1 文件白名单（严格，超出即停下请示）

| # | 文件 | 改动 |
|---|---|---|
| 1 | `worker/src/modules/collect.js` | `runsSummary(data)` 合成缺失日行；`detailByData` 的 `runAtMap` 扩展；不改真实行字段 |
| 2 | `worker/src/lib/collect_fill.js` | **仅当**现有 `synthDataRows` 无法接受 `null` 锚点时才改；能复用则零改动 |
| 3 | `tools/tests/unit/collect_missing_days.test.mjs` | **新增**单测，覆盖 D5 验收 1~4、6 |

### 1.2 现状（已只读核实）

- `modules/collect.js:262-285`：`runsSummary` 直接 `SELECT c.collect_date, c.ingested_at AS collected_at, ... FROM collect_run c LEFT JOIN device_daily d ... GROUP BY c.collect_date ORDER BY c.collect_date DESC LIMIT ?`，只列真实事件；无「应有而未到」的行。
- `modules/collect.js:108-110`：`detailByData` 的 `runAtMap` 来自 `SELECT ... FROM collect_run`；`lib/collect_fill.js:35-42` 的 `synthDataRows` 以它为锚点，整天未采集 → 无锚点 → 合成 0 行。
- 现网实测：`collect_run` 末条 `2026-11-13 20:10:55 success 16/16`，11-14 起 0 行；全 16 台停在 11-13。这是**设计缺失**（无「预期采集日」概念），不是解析 bug。

### 1.3 实现要点

1. **预期日窗口（查询层合成，不落库）**：
   - 起点：`SELECT MIN(collect_date) FROM collect_run` 的**次日**；更早不合成（避免上线前大片假缺失）。
   - 终点：今天；今日仅在**当前时刻 ≥ 20:10 + 60 分钟（21:10）**且仍无 `collect_run` 行时合成（B3）。
   - 判定：窗口内每个日期 d，若 `collect_run` 无 d 行 → 合成一行。
   - 合成行字段与真实行同构：`collect_date=d, collected_at=null, total_devices=activeCount, ok_devices=0, err_devices=activeCount, sum_print=null, missing=true`。`missing` 为**新增可选字段**；前端亦可用 `collected_at === null` 识别。
   - **严禁** `sum_print=0`（污染总打印量）；真实行任何字段不得改动（含 `sum_print: r.sum_print || 0` 保持原样）。
2. **明细占位**：`detailByData` 的 `runAtMap` 在真实行之外，把窗口内缺失日也 put 进去、值为 `null`；`synthDataRows` 自然为「缺失日 × 16 台在用设备」合成 `no_data=true` 行。数值列与 `toner` 全 `null`（**严禁落 0**），`error` 文案「该日未采集（采集端无上报）」。前端已有红字渲染，不需要改前端。
3. **时间基准**：服务端按东八区计算「今天」与 21:10 阈值；单测用可注入的 now（或等价手段），不得依赖机器本地时区漂移。
4. **契约**：不新增 `/api/*` 路由（46 路由冻结）；响应字段只增不删；`missing` 在差异登记中说明为可选字段。

### 1.4 T-070 验收（逐条跑通才算完成）

1. 首次采集日 D0、缺失日 D1、今天 Dtoday（时刻 < 21:10）：`GET /api/collect_runs?type=data` 含 D1 的 `missing=true` 行，`collected_at=null`、`err_devices=activeCount`、`sum_print=null`；D0 与 Dtoday 均不合成。
2. 今日 21:10 后仍无采集 → 合成今日；20:10 前不得合成。
3. `GET /api/collect_detail?from=D1&to=D1&toner=collect_date` 返回 16 行 `no_data=true`，数值与 `toner` 全 `null`，`error` 含「未采集」。
4. 真实事件行全部字段与改动前逐字段相等，`sum_print` 不被 0 污染。
5. 46 路由数不变、`routes.json` 不变、`api_contract.mjs` 判据不破。
6. 纯 LF 沙盒 `git archive` 跑 `check.mjs` 0 问题、`node --test` 全绿、改动文件 CR=0、`git diff --check` 0。

---

## 二、T-071 前端：缺失可见性与新鲜度横幅（trae，依赖 T-070 已合并）

### 2.1 文件白名单（严格，超出即停下请示）

| # | 文件 | 改动 |
|---|---|---|
| 1 | `worker/src/web/tabs/collect.js` | 主表缺失标识、明细标题 |
| 2 | `worker/src/web/tabs/overview.js` | 新鲜度横幅容器 + 渲染调用；**不改 `online/normal` 判定** |
| 3 | `worker/src/lib/web_assets.js` | **由 `node scripts/build_web_assets.mjs` 生成，禁止手改** |
| 4 | `tools/tests/unit/collect_missing_days_ui.test.mjs` | 新增（若测试框架支持；否则并入现有 collect 单测） |

### 2.2 现状（已只读核实）

- `web/tabs/collect.js:58-71` 主表：错误列 `r.err_devices > 0 ? '<span class="error-line">…</span>' : "0"`，采集事件列 `esc(r.collected_at || r.collect_date)`。
- `collect.js:81-100` `loadRuns` 首次进入自动展开 `state.runsRows[0].collect_date` → 断采时会展开最新真实旧日（11-13），页面无过期提示。
- `collect.js:129-130` 明细标题固定「采集事件 X 的打印机明细（共 N 台…）」。
- `collect.js:157-164` 已有 `no_data → error-line` 红字渲染，**保持不动**。
- `web/tabs/overview.js:63-73` 模板：toolbar 之后依次 `#ov-cards`、`#ov-devcards`；`paint()` 在 `:54-61` 填这些容器。横幅插在 toolbar 与 `#ov-cards` 之间，不动其余结构。

### 2.3 实现要点

1. 主表：`r.collected_at === null`（或 `r.missing === true`）的行，错误列显示红字 `<span class="error-line">未采集</span>`，采集事件列日期后加「（缺失）」；`dt-active`、分页、序号逻辑不变。
2. 明细标题：若 `state.detailDate` 是缺失日，标题改为「采集事件 X（**该日未采集**，以下为在用设备占位）」。
3. 总览横幅（B4）：`stale_days = 今天 − 最新真实 collect_date`（从 `/api/collect_runs?type=data&limit=1` 取，若 overview 响应已含等价字段则优先用之，不新增路由）；`stale_days ≥ 1` 显示黄色提示「数据截至 YYYY-MM-DD（距今 N 天），采集端可能离线」。**不得改动 `lib/overview_stat.js` 的 `online/normal/abnormal` 判定与计数**；横幅只增不改。
4. 样式尽量复用现有 class（`muted` / `error-line` / `toolbar` 等）；必要时最小增补，但**不新增 CSS 文件**，且三个 CSS 与 `web/index.html` / `web/app.js` 仍按禁动清单处理（如确需改 CSS，停下来请示 workbuddy）。
5. 生成物 `web_assets.js` 必须由 `node scripts/build_web_assets.mjs` 生成，`build_web_assets.mjs --check` 必须逐字节一致。

### 2.4 T-071 验收

1. 缺失日主表行显示红字「未采集」+ 日期「（缺失）」；真实行渲染与改动前逐字段一致。
2. 展开缺失日：标题含「该日未采集」，明细 16 行红字占位，数值/碳粉全 `-`，无 0 污染。
3. 断采时总览出现黄色横幅，`online/normal/abnormal` 计数与改动前**完全相等**。
4. `web_size.mjs` ≤ 40KB；`build_web_assets.mjs --check` 通过；`node --test` 全绿；CR=0；`git diff --check` 0；CSS/HTML/app.js 零改动。

---

## 三、共同禁动清单（任何卡均不得越界）

- 不改 `worker/schema.sql`、不加列、不改任何表结构/主键/索引；不做 DDL/DML。
- 不改 `collect_run` 写入链路（`modules/ingest.js` 的 `RUN_UPSERT`）与 `collector/**`。
- 不改 `lib/diff.js` / `lib/util.js` / `lib/overview_stat.js` 的 `online/normal` 判定段。
- 不改 `routes.js` 与 `tools/tests/fixtures/routes.json` / `api_contract.mjs` 判据；不新增 `/api/*`。
- 不改三个 CSS 与 `web/index.html` / `web/app.js`（横幅复用 class；确需新增停下请示）。
- 不碰 S1（T-059/060/061）/ S2（P0 二次真机调研）/ S3（v4 / #18）挂起项；不碰 T-069。
- 执行 Agent 不自报 done、不改卡面、不合并 master、不部署、不连现网 D1 与采集服务器。

## 四、部署边界（提前写清）

- 本批次**无新列、无 migration**；但现网仍停留在 09:49 旧版，**v5（`aa5019f`）的 `costs.report_links` DDL + deploy 必须先完成**，再部署本批次。单独部署虽不会报 `no such column`（本批次不读新列），但会混批，排障困难。
- 部署由人类本人执行；执行 Agent 只交付分支与门禁报告。
- 部署自检：`collect_run` 缺失日可见、`/` 与 `/api/config` 200、总览横幅出现且 `online/normal` 未漂移。

## 五、挂起任务（全量快照，继承 2026-11-16 凭证集中保管 handoff，本文件无新增无解挂）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；卡面 todo | 重编后重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级中 | 升级完成 + 复跑探测 + 更新调研文档 | tmp 快照保留 | 续跑不重开卡 | 人类 |
| prnmgt | S3 v4 批次 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 裁定 + 新 ADR | 仅 DRAFT | 裁定后重编拆卡 | 人类 |

本文件为按人类指令预置的执行提示词草案，不认领任务卡；suspended 一律未开工。T-069（报表弹窗）由本账号另一会话发布、待认领，与本批次无关；T-065~T-068（v5）已 done 未部署。RL-004～007 状态不变。

## 六、自检与边界（本会话）

- 已只读核实：`tasks.md` 已登记 **T-070 / T-071 / T-072**（当前最大卡号 T-072，三张均 `todo`）；`modules/collect.js:262-285`、`web/tabs/collect.js:58-71/81-100/129-164`、`web/tabs/overview.js:63-73` 与本提示词描述一致；单测目录含 `collect_fill.test.mjs` / `collect_t062.test.mjs` 等可参照。
- 采集服务器 `10.113.224.20` 网络已恢复（ping 0% 丢包）；OpenSSH 通用/专用私钥均被服务端拒绝（`Permission denied (publickey,password)`），人类明确**登录一律用用户名/密码**（口令值不落盘）。补推已于 11:48 完成：本地 SQLite 全部 `pushed=1`、11-14~16 无快照 → `--push-only` 无可补数据；按口径执行 `--force` 补当日（不 `--date` 回溯），16/16 成功上报；线上自检 `collect_run` 11-17 success 16/16、`device_daily` 16 行、PRN017 `toner.pct=19`。此状态不影响本提示词的编制。
- 2026-11-17 11:5x 人类逐项裁定 B1~B5 **全部按建议** → 本文件转 **APPROVED · 可投喂**；项目仓已落地 `docs/adr/0014-collect-missing-visibility.md`（ACCEPTED）、T-070~T-072 卡面、`OPEN-DECISIONS.md` #21、`spec.md` 第四条与 `constitution.md` 第二条人类豁免登记、`BOARD.md` v7 批次行与交接条目。**未改任何业务代码、未部署、未 DDL/DML、未认领卡。**
