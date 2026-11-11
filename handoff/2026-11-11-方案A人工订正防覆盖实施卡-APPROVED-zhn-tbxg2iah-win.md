# 【APPROVED · 已批准 · 可投喂】方案 A「人工订正防覆盖」实施卡

> 自包含任务书。可直接复制投喂执行 Agent（trae），无需回看历史对话；**§零 B3 防撞闸已于 2026-11-11 16:32 经人类明确「允许并行」解除**；逐卡提示词见 `handoff/2026-11-11-T063逐卡执行提示词-zhn-tbxg2iah-win.md`。
> 编制：workbuddy@zhn-tbxg2iah-win · 2026-11-11 12:4x +08 · 批准落地 12:56 +08
> 人类授权范围：**2026-11-11 12:56 书面裁定「1. 新 ADR 豁免，2. B2 按建议进行」** —— 立项形式 = 新 ADR 豁免（不另立项目），B2 三项全部按建议。**仍未授权**：DDL / DML 执行与部署（归人类本人）；认领与编码由执行 Agent 按三-5 ⑤ 自行登记。**2026-11-11 16:32 追加授权**：人类明确「允许并行」→ B3 防撞闸解除，T-063 可派工。
> 卡号：**T-063**（后端锁定内核）/ **T-064**（前端可见性与解锁），已于 12:56 登记进 `specs/0001-prnmgt-refactor/tasks.md`（状态 todo；64 卡 / done 59 / todo 5）；`docs/adr/0012-manual-locked.md` 状态 **ACCEPTED**，决策 **#19 RESOLVED**。
> 基线判据（**不写死 hash**，后续治理文档提交不再使本卡失效）：立项起点 `868adf7`；本批次立项文档已合入 `origin/master`，形成纯文档提交链（如 `46093a1`、`ba58a46`，均只改治理文档）。派工前实测 `git rev-parse origin/master` 并核对：① local = origin 一致；② `git diff --name-only 868adf7..origin/master` 的**全部**文件都在白名单内（`docs/adr/0012-manual-locked.md`、`constitution.md`、`AGENTS.md`、`specs/0001-prnmgt-refactor/spec.md`、`specs/0001-prnmgt-refactor/tasks.md`、`BOARD.md`、`docs/decisions/OPEN-DECISIONS.md`），**不含任何 `worker/**` / `collector/**` / `tools/**` 代码**。满足即可作为基座；出现白名单外文件或代码改动即停下报告。
> 分工（全局规范 v1.8.9 三-7）：workbuddy 编卡 / 复审 / 合并收官；**trae 编码且一律不得部署、不得执行 `wrangler d1 execute`**；**现网 ALTER 与全部部署由人类本人执行**。
> 本卡为只读诊断结论 + 设计，不含任何业务代码改动。

> **T-064 派工（2026-11-11 17:48）**：S4 已由人类「确认T064」解挂，逐卡提示词见 `handoff/2026-11-11-T064逐卡执行提示词-zhn-tbxg2iah-win.md`（自包含，由人类复制投喂）；最新 handoff `2026-11-11-prnmgt-S4解挂与T064投喂-zhn-tbxg2iah-win.md` 承载滚动继承后的 8 字段全量快照。本节不改动 B1 / B2 / B3 的历史裁定文字。

---

## 零、最高优先：立项已过 / 三项开工前置（任一未过即不得投喂、认领、改码）

### B1 · 立项形式 —— **已通过（2026-11-11 12:56）**

人类书面裁定 **「新 ADR 豁免」**，即本卡原 (a) 方案：批准 `docs/adr/0012-manual-locked.md`（**ACCEPTED**），在 `constitution.md` / `AGENTS.md` / `spec.md` 各登记一条一次性豁免，`docs/decisions/OPEN-DECISIONS.md` 新增 **#19 RESOLVED**；**不另立项目**。

**豁免边界（不得扩大解释）**：严格仅限给 `device_daily` / `account_daily` 各加一列 `manual_locked` 及配套后端 / 前端 / 测试代码。既有 22 表其它列 / 主键 / 索引 / 语义、采集端 `collector/**` 零改动（ADR-0005）、`lib/diff.js` 统计口径、既有路由契约、第 23 表语义（#17）、**#18 前置未过 / v4 研究阶段 / v3 三卡 T-059~T-061 暂停**一律不解除；本批次**不构成 v4 开工令**。

派工前已由 workbuddy 落地：ADR-0012、四处豁免登记、#19、T-063 / T-064 卡面、BOARD 12:56 交接条目；项目仓 `check.mjs` 实测 **0 问题 / 3 条存量提示**、`git diff --check` EXIT 0。**执行 Agent 不得自行修改上述任何文档**（§六 禁动清单）。现网 ALTER / DML / 部署归人类本人（B4 不变）。

### B2 · 三项待裁定 —— **已全部裁定（按建议，2026-11-11 12:56）**

| # | 裁定 | 执行要求 |
|---|---|---|
| **D-1** 存量 `is_baseline=1` 基线行 | **R1：现网一次性 DML 补锁** | `UPDATE device_daily / account_daily SET manual_locked = 1 WHERE is_baseline = 1;`（§四已给全文）。执行前先 `SELECT` 计数并留痕；回滚时须区分「本来就锁定的新写入」与「批量补锁的基线行」。**只交 SQL 文本，由人类本人执行** |
| **D-2** 存量「已被改过但无标记」的 inline 订正行 | **不追溯，全部保持 0** | 历史 `/api/history` 订正无来源标记与审计，加列后无法自动识别；上线前由人类确认是否有需人工补标的日期，若需则另交一次性 DML |
| **D-3** 与在途任务的隔离 | **独立批次**：不并入 v3 / v4、不与 P0 只读真机调研连做 | **2026-11-11 16:32 人类明确「允许并行」→ 防撞闸解除，T-063 可派工**（B3 留痕已先行落地）；独立批次边界不变：不并入 v3 / v4、不与 P0 连做、T-064 仍须等 T-063 复审合并 |

### B3 · 认领与同步纪律

按三-5 ⑤/⑦：开工前查 `~/.agent-shared/memory/projects/prnmgt.md` 任务登记节，确认 T-063 未被他人认领（doing/open）；**认领与完成各追加一行**（append-only，禁止改旧行）。

**B3 防撞闸已解除（2026-11-11 16:32，人类明确授权）**：人类答复「**允许并行**」，对应 12:56 裁定 D-3 留下的「是否允许并行须人类明确」。授权范围**仅限解除**「P0（trae 11-09 08:52 `doing`、无 done 行）未 done 时不得认领 T-063」这一条闸；按 AGENTS.md「二、一次只做一张卡」本次为**一次性豁免**，留痕已先写入本卡 / #19 / ADR-0012 / BOARD 16:32 条目后再派工（符合本条原文要求）。**不解除**：T-064 对 T-063 复审合并的依赖、v4 前置未过与 v3 三卡暂停、#18 未决、T-063 与 T-064 不得连做；本批次仍不构成 v4 开工令。执行 Agent 仍须自行查登记节并追加 doing 行；若由 trae 执行且 P0 仍在途，必须用**独立 worktree / 分支**（`~/source/prnmgt.wt/trae-t063`、`agent/trae/T-063`），不得在 P0 的 worktree 内改文件。共享记忆该文件有**他人未提交改动（M）**，本卡全程未触碰、未代提交；执行 Agent 也不得代为提交或强行 rebase。

### B4 · 部署与 DDL 归人类本人

三-7 ④ 明确「涉及 migration / 表结构变更」必须通知人类，且 #16 / #17 结论「现网一次性 ALTER 与全部部署由人类本人执行」不变。**trae 不得执行 `wrangler d1 execute`、不得 `wrangler deploy`**；workbuddy 复审合并后按三-7 判断，命中 migration 亦须通知人类并标「待人类部署」。

---

## 一、问题与证据（2026-11-11 只读诊断，非推测）

### 1.1 现状

`device_daily (collect_date, device_no)` 与 `account_daily (collect_date, device_no, account_id)` 是**日快照表**，主键按业务日期。计数器是终身累计值，同一天只应有一行有效读数。`/api/ingest` 用 `ON CONFLICT DO UPDATE` 按行覆盖，所以同日重跑 = 取更晚时点的读数，这是设计意图（20:10 加 `--force` 后每天多一次重推）。

### 1.2 四类人工订正，全部会被 20:10 重推静默冲掉

| 入口 | 实现 | 现状后果 |
|---|---|---|
| 部门数据页 inline 编辑 | `lib/history_save.js` `UPDATE` 数值列 / `collect_type`，**无来源标记、无 `auditLog`** | 数值、类型全被覆盖，事后无法追溯 |
| 基线 | `lib/admin_baseline.js` 写 `is_baseline=1`，有「已有真实行 → 409」守卫 | `ingest.js` 以 `is_baseline = 表.is_baseline` 自赋值**保留标记**、却覆盖数值 → 畸形行；`lib/diff.js` 把基线行当锚点（只更新 prev 不求和），口径错乱 |
| 账号重置锚点 | `lib/admin_account.js` 写全 0 行，有「非 0 行拒绝」守卫 | 被真实读数覆盖，锚点消失 |
| 历史 CSV 导入 | `lib/admin_import.js` `INSERT OR REPLACE` | 当天数据被覆盖且丢标记 |

根因：两表**没有来源 / 锁定字段**（全项目 `is_manual|data_source|manual_edit|is_locked` 零命中），采集行与人工行无法区分。

### 1.3 两处必须写入卡面的更正 / 细节

1. **`collect_type` 也会被冲掉**（11-11 前一轮答复曾误判为「保留」）：采集端 `collector/**` 全目录不含 `collect_type`，载荷不带该字段，`ingest.js` 绑定 `a.collect_type || 'cumulative'`，故 `COALESCE(excluded.collect_type, account_daily.collect_type)` 恒取 `'cumulative'` → 人工改的 `periodic` 每次重推回退。真正不被覆盖的只有 `is_baseline` 标记与 `master_devices.location/model`。
2. **历史日期通常安全**（采集只推当天），例外是 `sync.py::push_pending` 按日期升序补推 `pushed=0` 的历史日。

### 1.4 为什么不采用「主键加时分秒」

人类 11-11 提出过该方案，评估结论：**不解决主诉且会打散统计口径**。① 一天多行后报表面临「取哪一行」——取最新则订正被逻辑遮蔽，取人工行则仍需来源标记，绕回本方案；② `diff.js` 差分按 `(d,t)` 序列做相邻相减，同日两个读数会产生虚假增量，其头部注释已记录「不排序会静默算错 60 倍且不抛异常」；`dept_query.js::dedupSub` 的 `MAX(...) GROUP BY collect_date,...` 会跨行拼接数值；`overview_stat.js` 的 `devLatest[no] = r`、`history_save.js` 的按日期 UPDATE、各 admin 守卫的 `.first()` 全部失准；③ Worker 内 `device_daily` 62 处 / `account_daily` 46 处引用、采集端三张 SQLite 表主键、`build_payload`、前端、黄金测试、历史数据回填都要改，双端同一窗口发布、回滚困难。若日后需要「每轮采集留痕」，另立**追加型流水表**（参照现成的 `device_status_log`），本卡不做。

---

## 二、方案 A 设计（**已冻结** · 12:56 三项裁定落定，不得自行调整）

### D1 · 列定义（两表各一列）

```sql
manual_locked INTEGER NOT NULL DEFAULT 0   -- 0=自动采集可覆盖（默认） 1=人工作过，采集整行跳过
```

沿用 `is_baseline` 的整型标记风格；默认值 0 保证**存量行行为完全不变**。`worker/schema.sql` 两处 `CREATE TABLE` 必须同步（测试 `tools/tests/unit/_fake_d1.mjs::freshDb()` 直接读该文件建内存库）。

### D2 · ingest 拦截点（核心，最小改动）

`worker/src/modules/ingest.js` 的 `DEV_UPSERT` / `ACC_UPSERT` 保持现有 `DO UPDATE SET` 全部列不动，**仅在末尾各加一个 WHERE**：

```sql
-- DEV_UPSERT 末尾
... device_status = excluded.device_status, created_at = excluded.created_at,
    is_baseline = device_daily.is_baseline
  WHERE device_daily.manual_locked = 0;

-- ACC_UPSERT 末尾
... collect_type = COALESCE(excluded.collect_type, account_daily.collect_type),
    created_at = excluded.created_at, is_baseline = account_daily.is_baseline
  WHERE account_daily.manual_locked = 0;
```

SQLite 3.24+ 支持 `ON CONFLICT DO UPDATE SET ... WHERE`；Cloudflare D1 与本地 `node:sqlite` 假 D1 均支持。WHERE 不成立时**整个 DO UPDATE 静默跳过、不报错**，因此锁定行的数值、`collect_type`、`created_at`、`counter_json`、`device_status` 全部原样保留。

**必须写进单测的边界**：
- `RUN_UPSERT`（collect_run）、`DEV_MASTER_UPSERT`（master_devices 只更 ip）、`toner_consumption_log`、`user_log` 不在拦截范围，**仍正常写入**；尤其验证锁定行的设备 IP 仍能同步。
- `pushToner` 的 `tbPrevReads` 与 `detectAccountResets` 都按 `collect_date < date` 读 `device_daily` / `account_daily`，会读到人工锁定值作为上一期基准 —— **这是期望行为**（订正应参与统计），不得改成读 payload。
- 新插入（无冲突）的行不受 WHERE 影响，按 INSERT 列清单吃默认值 0。
- `env.DB.batch()` 语句顺序与「全成或全滚」不变（ingest.js 头注第 1 条红线）。

### D3 · 四个写入入口置位（`manual_locked = 1`）

| 文件 | 改动 |
|---|---|
| `lib/history_save.js` | `action=update`（device/account）与 `action=insert`（account 补录）写 `manual_locked=1`；`action=delete` 不变（删行后下次采集会重新插入，属预期，需在交付报告说明） |
| `lib/admin_baseline.js` | POST 的 account / device 两个 upsert 的 INSERT 列清单与 `DO UPDATE SET` 均置 1（顺带修掉 1.2 的畸形基线行）；DELETE 不变 |
| `lib/admin_account.js` | 全 0 锚点的 INSERT 与 `DO UPDATE SET` 置 1 |
| `lib/admin_import.js` | **易漏**：两条 `INSERT OR REPLACE` 必须显式把 `manual_locked` 写进列清单与 VALUES(=1)。REPLACE 是 delete+insert，不显式带列会把标记复位 0；存量「REPLACE 丢其它列」行为本卡不修（等价优先） |

`DEV_MASTER_UPSERT` 与任何 `collector/**` 文件不改（ADR-0005 采集端零改动红线不解除）。

### D4 · 解锁动作（不新增路由，契约零改动）

`lib/history_save.js` 的 `POST /api/history` 增加 `action: 'unlock'` 分支：仅 admin（非 admin 403 且零写库）、按既有主键 `UPDATE ... SET manual_locked = 0`、写一条 `auditLog`（`util.js` 已有）。**不加新 `/api/*` 路径**，避免改动 `routes.json` / `routes.js` / `index.js` 白名单与 `api_contract.mjs` 计数。`fields` 白名单不含 `manual_locked`，普通 update 无法绕过锁定。

同时补齐现有缺口：四个入口的人工写入 + unlock 各写一条 `user_log` 审计（解决「被冲掉是静默的、无留痕」的另一半）。

### D5 · 前端可见性（T-064）

- 后端三处 SELECT 带出 `manual_locked`：`modules/history.js` 的 device/account 两段、`lib/dept_query.js::dedupSub`（加 `MAX(manual_locked) AS manual_locked`）、`modules/dept_data.js` 的外层 SELECT。
- `web/tabs/dept_data.js` / `dept_data_write.js`：admin 行显示「已锁定」标记与「解锁」按钮，调 `POST /api/history {action:'unlock', ...}`；沿用 `costs.js` 的锁定交互与单次 `esc()` 纪律。
- 改前端**必须**重跑 `node scripts/build_web_assets.mjs` 生成 `lib/web_assets.js`，禁止手改。
- 新增响应字段若触发 `check.mjs` / golden 契约检查报错，**停下报告，不得擅自改判据哈希或夹具基线**。

---

## 三、拆卡（一次一张卡，严格文件白名单）

### T-063 · 后端锁定内核（P0，可独立闭环）

- **依赖**：B1 已通过（ADR-0012 ACCEPTED / #19 RESOLVED / 章程豁免已登记）；B2 三项已裁定并写入本卡；**B3 防撞闸已过**（2026-11-11 16:32 人类明确「允许并行」）且认领已登记 doing；B4 执行时遵守；`origin/master` 基线复核按头部判据通过（相对立项起点 `868adf7` 仅治理文档、代码零改动）。
- **文件白名单**（严格 9 个，超出即停下请示）：
  1. `worker/schema.sql`
  2. `worker/migrations/20261111_manual_locked.sql`（新增，DDL 双轨）
  3. `worker/src/modules/ingest.js`
  4. `worker/src/lib/history_save.js`
  5. `worker/src/lib/admin_baseline.js`
  6. `worker/src/lib/admin_account.js`
  7. `worker/src/lib/admin_import.js`
  8. `tools/tests/unit/manual_locked.test.mjs`（新增）
  9. `tools/tests/b5_admin.test.mjs`（补断言，可选；若零改动可不列）
- **验收**：
  1. `freshDb()` 后 `PRAGMA table_info(device_daily)` / `(account_daily)` 实测各多 1 列、`NOT NULL DEFAULT 0`、既有行全为 0；两表主键与其它列定义逐字未变。
  2. migration 文件头注含「仅现网一次性执行、新库不执行、禁止整目录重跑 migrations/、由人类本人执行」，两条 `ALTER TABLE ... ADD COLUMN` 与 `schema.sql` 定义逐项对齐。
  3. **行为回归**：`manual_locked=0` 的行同日重推仍覆盖数值 / `collect_type` / `created_at`，与改动前逐字段一致。
  4. **锁定生效**：先造一行置 1，再推同键 payload，SELECT 全字段逐项相等（含 `print_total/copy_total/scan_total`、`print_bw/.../total`、`collect_type`、`created_at`、`counter_json`、`device_status`、`is_baseline`）；同批混合普通行时普通行正常更新；`env.DB.batch` 不抛错、`ingested` 计数不变。
  5. **旁路仍写**：同一次 ingest 中 `collect_run`、`master_devices.ip`、`toner_consumption_log`、`user_log` 均正常落库。
  6. 四个入口各自写入后 `manual_locked=1`；**专设断言**验证 `admin_import` 的 REPLACE 未把标记复位 0。
  7. 基线行写入后同日重推，数值与 `is_baseline=1` 同时保持（1.2 的畸形行不再出现）。
  8. `action:'unlock'`：admin 解锁后下一次 ingest 恢复覆盖；非 admin 403 且 dump 逐字节零写库；写入与解锁各落一条 `user_log`。
  9. 门禁全绿（见 §五）；未执行任何 `wrangler d1 execute` / `wrangler deploy`、未连现网。

### T-064 · 前端可见性与解锁按钮（P1）

- **依赖**：T-063 复审通过并合并（未合并不得认领）—— **已满足**：T-063 17:2x 收官 `d5fad5d`；**S4 已于 2026-11-11 17:48 经人类「确认T064」解挂**，可投喂。逐卡执行以共享仓 `handoff/2026-11-11-T064逐卡执行提示词-zhn-tbxg2iah-win.md` 为准（自包含）；挂起快照以最新 handoff 为准；卡面状态保持 `todo`、执行方只登记 `doing`。
- **文件白名单**（严格 6 个）：`worker/src/modules/history.js`、`worker/src/lib/dept_query.js`、`worker/src/modules/dept_data.js`、`worker/src/web/tabs/dept_data.js`、`worker/src/web/tabs/dept_data_write.js`、`worker/src/lib/web_assets.js`（build 生成，禁止手改）；如需追加单测则第 7 个，须先请示。
- **验收**：列表正确显示锁定标记、admin 解锁按钮触发 `POST /api/history {action:'unlock'}` 成功后刷新且标记消失、非 admin 不显示按钮、后端 403 时前端有错误态；`build_web_assets.mjs && --check` 一致、`web_size` 首屏 gzip ≤ 40KB、`check.mjs` 0 问题、全量 `node --test` fail 0、单次转义无实体字面（T-051/T-058 教训）、`@media print` 计算样式与基线一致、headless Chrome CDP 实测无 JS 异常；未部署。

---

## 四、DDL 双轨（文本建议 · **由人类本人执行，agent 不得执行**）

`worker/migrations/20261111_manual_locked.sql` 建议内容（新库只认 `schema.sql`，不执行本文件）：

```sql
-- 2026-11-11：日快照表新增人工锁定标记（方案 A / T-063）
-- 仅现网一次性执行；新库不执行（新库只认 schema.sql + bootstrap.sql）。
-- 不得整目录重跑 migrations/（其它文件对新库不幂等，见 docs/runbook.md 建库陷阱）。
-- 由人类本人执行，agent 不得执行 wrangler d1 execute / deploy。

ALTER TABLE device_daily  ADD COLUMN manual_locked INTEGER NOT NULL DEFAULT 0;
ALTER TABLE account_daily ADD COLUMN manual_locked INTEGER NOT NULL DEFAULT 0;

-- 执行后自检（期望两表 n = 0，即存量行均为默认值）：
--   SELECT COUNT(*) AS n FROM device_daily  WHERE manual_locked <> 0;
--   SELECT COUNT(*) AS n FROM account_daily WHERE manual_locked <> 0;
```

**D-1 已裁定 = R1**，另交一份独立 DML 文本（同样由人类本人执行，agent 只交文本不执行；执行前先 `SELECT` 计数并留痕）：

```sql
-- 建议先备份 / 先 SELECT 计数，执行后核对行数
UPDATE device_daily  SET manual_locked = 1 WHERE is_baseline = 1;
UPDATE account_daily SET manual_locked = 1 WHERE is_baseline = 1;
```

部署节奏建议（沿用 ADR-0011「一次 ALTER、一次部署」教训）：**T-063 与 T-064 都复审合并后，由人类一次性执行 DDL + 一次 `wrangler deploy` + 线上自检**；不要 T-063 合并就单独上线（那时界面还没有解锁入口）。

---

## 五、门禁、提交与复审纪律

- 门禁（**以纯 LF 沙盒 `git archive` 导出为准**；主仓 Windows 工作区曾出现 CRLF 漂移 —— 12:56 实测项目仓 `core.autocrlf=false`、index 存 LF 而磁盘为 CRLF，会让 `build_web_assets --check` 假失败，已在立项提交时把两份章程文档归一化为 LF）：
  `node scripts/check.mjs` 0 问题 · `node scripts/build_web_assets.mjs --check` 一致 · `node scripts/web_size.mjs` ≤ 40KB · `node --test tools/tests/*.test.mjs tools/tests/unit/*.test.mjs` fail 0（T-062 收官基线 **275 / pass 184 / fail 0 / skip 91**，以派工前实测为准，只增不减）· `node --check` 目标文件 · `git diff --check` EXIT 0 · 改动文件 CRLF 0。
- **规模红线说明**：T-063 白名单 9 文件 / T-064 6 文件，字面上越过 `constitution.md` 五/六的「单卡 < 5 文件」；但属「新增一列 + 两条 upsert 加 WHERE」的原子集（2 个新增文件、1 个可选，缺任一写入入口会出现「能锁但入口不置位」的半成品），历史 T-055（白名单 4→8 文件临时授权）与 T-062（7 文件）有同口径先例，`check.mjs` 对 >5 文件只 warn 不 error。**12:56 实测 0 问题 / 3 条存量提示**，新增两卡未引入新提示。若人类要求严格按 5 文件拆卡，须重新裁定拆分方式，不得由执行 Agent 自行合并或拆分。
- 提交：worktree 模式（`~/source/prnmgt.wt/trae-t063`、分支 `agent/trae/T-063`）；一次性署名
  `git -c user.name=zhn-trae -c user.email=trae@zhn-tbxg2iah-win commit -m "..." -m "Agent: trae"`；
  推分支到 origin，**不合并 master、不改 `tasks.md` 卡面、不自报 done、停下等 workbuddy 复审**。追加修正用**新提交，不 amend**。
- 复审：workbuddy 在独立纯 LF 沙盒复现门禁，独立实测「锁定 / 未锁定 / 混合批 / 四入口 / unlock / 旁路写入」六组，不采信执行方自报单测；通过后 ff-only 合并收官并留痕。

---

## 六、禁动清单（越界即打回）

`lib/diff.js` · `lib/util.js` · `lib/paper_calc.js` · `collector/**`（ADR-0005）· `worker/src/routes.js` 与 `tools/tests/fixtures/routes.json`（不新增路由）· `routes` 门禁白名单 · `tools/tests/api_contract.mjs` 判据 · 三个 CSS 与 `index.html` / `app.js` · 既有 22 表的其它列与主键 · `BOARD.md` / `tasks.md` / `constitution.md` / `spec.md` / `OPEN-DECISIONS.md` / `docs/adr/**`（立项文档已由 workbuddy 于 12:56 订正完毕，执行方一律不得改）· 现网 D1 与线上服务。

---

## 七、回滚

- **数据层**（人类执行）：`UPDATE device_daily SET manual_locked = 0; UPDATE account_daily SET manual_locked = 0;` → 全部行恢复自动覆盖，无需删列；加列本身可保留。
- **代码层**：`git revert` 相应提交后重新部署（部署仍归人类）。
- 若 D-1 采用 R1，回滚时须区分「本来就锁定的新写入」与「批量补锁的基线行」，故 R1 执行前必须先 `SELECT` 计数并留痕。

---

## 八、已知坑（本项目反复踩过）

1. `INSERT OR REPLACE` 丢列（`lib/admin_import.js`）—— 必须显式带 `manual_locked`。
2. `DO UPDATE ... WHERE` 不满足时**静默跳过**，别误判成写入失败；单测要断言「无异常且行未变」。
3. `collect_type` 恒被采集端缺省写成 `'cumulative'`；`created_at` 每次重推都更新 —— 锁定必须是**整行**跳过，不能只护数值列。
4. 基线行「标记保留、数值被覆盖」比数值丢失更隐蔽（`lib/diff.js` 把基线当锚点），D-1 裁定前不要自行决定存量处置。
5. CRLF 假差异（AGENTS.md 第七节）：LF 沙盒为准，禁止把 CRLF 写进生成物。
6. 新增响应字段可能影响契约冻结检查；报错停下报告，禁止改判据哈希。
7. `history_save.js` 的 `delete` 只删行，删后下次采集会重新插入 —— 不是 bug，交付报告需说明。

---

## 九、交付物清单（执行方）

1. T-063 / T-064 分支与提交号（含基座、署名、trailer、worktree 干净、local=origin）。
2. 门禁原始输出（check / build --check / web_size / 全量 node --test / node --check / diff --check / CRLF）。
3. 六组独立实测的记录（可复现脚本放共享仓 `tmp/<agent名>/<会话标识>/`，**不入 Git、不在仓库内建脚本**）。
4. 现网 DDL 与 D-1 DML 的**建议文本**（只交文本，不执行）。
5. 交付报告注明：未部署、未执行 DDL/DML、未连现网、禁动清单零改动、未连做其它卡。

---

## 十、状态与引用

- **当前状态**：**APPROVED（2026-11-11 12:56 人类批准）** —— 立项形式新 ADR 豁免、B2 三项按建议；ADR-0012 ACCEPTED、#19 RESOLVED、四处章程豁免登记、T-063 / T-064 卡面与 BOARD 交接条目均已落地。**16:32 人类明确「允许并行」→ B3 防撞闸解除、可派工**；逐卡提示词 `handoff/2026-11-11-T063逐卡执行提示词-zhn-tbxg2iah-win.md` 已出。**仍未认领、未改代码、未执行 DDL/DML、未部署、未连现网**。 **补注（2026-11-11 17:48）**：T-063 已复审合并收官 `d5fad5d`（PASS、未部署）；**S4 解挂、T-064 可投喂**，提示词 `2026-11-11-T064逐卡执行提示词-zhn-tbxg2iah-win.md` 已备。S1/S2/S3 仍 suspended，部署仍归人类本人。
- 共享记忆 `memory/projects/prnmgt.md` 有他人未提交改动（M），本卡未触碰、未代提交；本文件单独提交并推双远端。
- 工作区日志：`C:/Users/Zhn_X/WorkBuddy/2026-11-04-21-23-46/.workbuddy/memory/2026-11-11.md`。
- 同日相关留痕：`handoff/2026-11-11-PRN014手动采集闭环-zhn-tbxg2iah-win.md`（第七节：20:10 强制重采 cron 变更）。
- 立项依据：`~/source/prnmgt/docs/adr/0012-manual-locked.md`（ACCEPTED，含批准检查单与豁免边界）、`docs/decisions/OPEN-DECISIONS.md` #19 RESOLVED、`BOARD.md` 12:56 交接条目、`specs/0001-prnmgt-refactor/tasks.md` 的 T-063 / T-064 卡面。
- 依据文件：`worker/src/modules/ingest.js`、`worker/src/lib/{history_save,admin_baseline,admin_account,admin_import,dept_query,diff}.js`、`worker/src/modules/{history,dept_data}.js`、`worker/schema.sql`、`collector/printer_monitor/{db,sync}.py`、`constitution.md`、`AGENTS.md`、`specs/0001-prnmgt-refactor/spec.md`、`docs/decisions/OPEN-DECISIONS.md`。
