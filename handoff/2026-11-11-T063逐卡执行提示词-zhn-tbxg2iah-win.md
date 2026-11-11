# T-063 逐卡执行提示词 · 后端人工锁定内核 `manual_locked`（APPROVED · 可投喂）

> 自包含任务书，**可直接全文复制投喂执行 Agent（trae）**，无需回看历史对话。
> 编制：workbuddy@zhn-tbxg2iah-win · 2026-11-11 16:32 +08
> 卡面：`specs/0001-prnmgt-refactor/tasks.md` 的 **T-063**（`状态: todo`，认领后自行改 `doing`）
> **必读全文**：`~/.agent-shared/handoff/2026-11-11-方案A人工订正防覆盖实施卡-APPROVED-zhn-tbxg2iah-win.md`（§二设计 / §三 T-063 验收 / §四 DDL 双轨 / §五门禁 / §六禁动 / §八已知坑）
> 立项依据：`docs/adr/0012-manual-locked.md`（ACCEPTED）、`docs/decisions/OPEN-DECISIONS.md` **#19 RESOLVED**、`BOARD.md` 12:56 与 16:32 条目、四处章程豁免登记
> **并行授权**：人类 **2026-11-11 16:32 明确「允许并行」**，B3 防撞闸已解除；授权范围仅限此闸，留痕已先于派工落地。
> 分工（全局规范 v1.8.9 三-7）：workbuddy 编卡 / 复审 / 合并收官；**执行 Agent 编码，一律不得部署、不得执行 `wrangler d1 execute`**；现网 ALTER、DML 与全部部署由人类本人执行。

---

## 零、开工前必须确认（任一项不满足即停下报告）

1. 读 `~/.agent-shared/global/rules.md`（**v1.8.9**）并执行第八节自检 —— 现行为 **10 步**，平台旧指令写的「9 步」已过时；同一 agent 的不同会话同样适用。
2. 按 `AGENTS.md` 必读顺序读：`constitution.md` → `BOARD.md` → `specs/0001-prnmgt-refactor/spec.md` → `tasks.md` 的 T-063 卡面 → `docs/decisions/OPEN-DECISIONS.md` #19 → 实施卡 APPROVED **全文** → 本提示词。
3. **认领登记**：查 `~/.agent-shared/memory/projects/prnmgt.md` 任务登记节，确认 T-063 未被他人认领（doing/open），然后**追加一行** `【任务认领】T-063 ... doing`（append-only，禁止改旧行）。登记节中 trae 的 P0 只读真机调研（11-09 08:52）仍 `doing`、无 done 行 —— 人类 16:32 已明确允许并行，**不得据此停工，也不得代 P0 登记 done**。该文件有他人未提交改动（M），不触碰、不代提交、不强行 rebase。
4. **基座判据（不写死 hash）**：`git rev-parse origin/master` 与本地 HEAD 一致；`git diff --name-only 868adf7..origin/master` 的**全部**文件落在 7 个治理文档白名单（`docs/adr/0012-manual-locked.md`、`constitution.md`、`AGENTS.md`、`specs/0001-prnmgt-refactor/spec.md`、`specs/0001-prnmgt-refactor/tasks.md`、`BOARD.md`、`docs/decisions/OPEN-DECISIONS.md`），**不含任何 `worker/**` / `collector/**` / `tools/**` 代码**。出现白名单外文件即停下报告。记录实测 HEAD 号写入交付报告。
5. **worktree 隔离**：新建 `~/source/prnmgt.wt/trae-t063` + 分支 `agent/trae/T-063`（16:32 实测二者均未占用）。**不得在 P0 或其它在途卡的 worktree 内改文件**；主 worktree 的既有未跟踪项（`.login-out.txt`、`docs/paper/field-survey-*`、`docs/plan-*`、`tmp/`）不触碰、不提交。
6. **不改卡面**：`tasks.md` 的 `状态` 由 workbuddy 收官订正；执行方不自报 done、不合并 master、不改任何治理文档（§六禁动清单）。
7. 提交用一次性署名 `git -c user.name=zhn-trae -c user.email=trae@zhn-tbxg2iah-win commit -m "..." -m "Agent: trae"`；推分支到 origin 后**停下等 workbuddy 复审**。追加修正用**新提交，不 amend**。
8. **本卡纯本地编码与测试**：不连现网 D1、不执行 `wrangler d1 execute` / `wrangler deploy`、不改采集服务器 crontab 或任何生产配置。今晚 20:10 的 `--force` 重采照常运行，与本卡无关。
9. CRLF：项目仓 `core.autocrlf=false`，以**纯 LF 沙盒 `git archive` 导出**跑门禁；改动文件 CRLF 必须为 0，禁止把 CRLF 写进生成物。

---

## 一、做什么（严格 9 文件白名单，超出即停下请示）

| # | 文件 | 改动 |
|---|---|---|
| 1 | `worker/schema.sql` | `device_daily` / `account_daily` 各加 `manual_locked INTEGER NOT NULL DEFAULT 0`；主键与其它列逐字不变（测试 `freshDb()` 直接读此文件建库） |
| 2 | `worker/migrations/20261111_manual_locked.sql` | **新增**，两条 `ALTER TABLE ... ADD COLUMN`；头注必须含「仅现网一次性执行、新库不执行、禁止整目录重跑 migrations/、由人类本人执行」 |
| 3 | `worker/src/modules/ingest.js` | `DEV_UPSERT` / `ACC_UPSERT` 的 `DO UPDATE SET` 全部列**保持不动**，仅在末尾各加 `WHERE device_daily.manual_locked = 0` / `WHERE account_daily.manual_locked = 0` |
| 4 | `worker/src/lib/history_save.js` | `action=update` / `action=insert` 写 `manual_locked=1`；新增 `action:'unlock'` 分支（仅 admin，非 admin 403 且零写库，`UPDATE ... SET manual_locked=0`）；人工写入与解锁各写一条 `user_log` 审计；`action=delete` 不变 |
| 5 | `worker/src/lib/admin_baseline.js` | account / device 两个 upsert 的 INSERT 列清单与 `DO UPDATE SET` 均置 1；DELETE 不变 |
| 6 | `worker/src/lib/admin_account.js` | 全 0 锚点的 INSERT 与 `DO UPDATE SET` 置 1 |
| 7 | `worker/src/lib/admin_import.js` | **易漏**：两条 `INSERT OR REPLACE` 必须**显式**把 `manual_locked` 写进列清单与 VALUES(=1)，否则 REPLACE 会把标记复位 0 |
| 8 | `tools/tests/unit/manual_locked.test.mjs` | **新增**单测 |
| 9 | `tools/tests/b5_admin.test.mjs` | 补断言（可选；零改动可不列） |

**核心语义**：`ON CONFLICT DO UPDATE ... WHERE` 在锁定行上 **整行静默跳过、不报错**（SQLite 3.24+ / D1 / 本地 `node:sqlite` 假 D1 均支持），因此数值、`collect_type`、`created_at`、`counter_json`、`device_status`、`is_baseline` 全部原样保留。必须是**整行**锁定 —— 采集端载荷不含 `collect_type`，`COALESCE(excluded.collect_type, 原值)` 恒写 `'cumulative'`，只护数值列会漏掉类型回退。

**不得改**：`lib/diff.js` / `lib/util.js` / `lib/paper_calc.js` / `collector/**`（ADR-0005 采集端零改动）/ `worker/src/routes.js` 与 `tools/tests/fixtures/routes.json`（**不新增 `/api/*` 路径**，避免动契约冻结）/ `api_contract.mjs` 判据 / 三个 CSS 与 `index.html` / `app.js` / 既有 22 表其它列与主键 / `BOARD.md` / `tasks.md` / `constitution.md` / `spec.md` / `OPEN-DECISIONS.md` / `docs/adr/**` / 现网 D1 与线上服务。新增响应字段若触发契约检查报错，**停下报告，不得改判据哈希或夹具基线**。

---

## 二、验收（执行方自测 + workbuddy 独立复现，不采信自报）

六组行为实测，**每组都要有可复现记录**（脚本放共享仓 `tmp/<agent名>/<会话标识>/`，不入 Git、不在仓库内建脚本）：

1. `freshDb()` 后 `PRAGMA table_info` 实测两表各多 1 列、属性为 `NOT NULL DEFAULT 0`、存量行全为 0；两表主键与其它列定义逐字未变。
2. **未锁定回归**：`manual_locked=0` 的行同日重推，数值 / `collect_type` / `created_at` 与改动前逐字段一致。
3. **锁定生效**：置 1 后推同键 payload，全字段逐项相等；同批混合普通行时普通行正常更新；`env.DB.batch()` 不抛错、`ingested` 计数不变。
4. **旁路仍写**：同一次 ingest 中 `collect_run`、`master_devices.ip`、`toner_consumption_log`、`user_log` 正常落库，**尤其验证锁定行的设备 IP 仍能同步**。
5. **四入口置位**：history / baseline / account reset / history import 各自写入后 `manual_locked=1`；专设断言验证 `admin_import` 的 REPLACE 未复位 0；基线行同日重推后数值与 `is_baseline=1` 同时保持（消除「标记是基线、值是采集值」的畸形行）。
6. **unlock**：admin 解锁后下一次 ingest 恢复覆盖；非 admin 403 且 dump 逐字节零写库；写入与解锁各落一条 `user_log`。

`pushToner` 的 `tbPrevReads` 与 `detectAccountResets` 按 `collect_date < date` 读到人工锁定值作为上一期基准 —— **这是期望行为，不得改成读 payload**；新插入（无冲突）的行不受 WHERE 影响；`env.DB.batch()` 语句顺序与「全成或全滚」不变。

**门禁全绿**：`node scripts/check.mjs` 0 问题（3 条存量提示只增不减）· `node scripts/build_web_assets.mjs --check` 一致 · `node scripts/web_size.mjs` ≤ 40KB · `node --test tools/tests/*.test.mjs tools/tests/unit/*.test.mjs` fail 0（T-062 收官基线 **275 / pass 184 / fail 0 / skip 91**，以派工前实测为准、只增不减）· 目标文件 `node --check` · `git diff --check` EXIT 0 · 改动文件 CRLF 0。

**DDL / DML 只交文本**（§四已给全文，含 D-1 = R1 的 `UPDATE ... SET manual_locked=1 WHERE is_baseline=1`）：migration 头注、执行前 `SELECT` 计数、执行后自检与回滚语句一并给出，**由人类本人执行**。

---

## 三、边界与红线

- **T-064 不得连做**（依赖 T-063 复审通过并 ff-only 合并）；v4 前置未过、v3 三卡 T-059~T-061 暂停、#18 未决一律不因本卡解除；**本批次不构成 v4 开工令**。
- 「允许并行」是**一次性豁免** AGENTS.md「二、一次只做一张卡」中「P0 未 done 不得认领」这一条闸，不扩大到其它卡、其它批次或其它会话；执行方仍须自行认领登记。
- 方案上线**之前**，当天的人工订正仍请放在 20:10 之后，否则照样会被重推冲掉 —— 本卡不改变现行生产行为。
- T-063 + T-064 都复审合并后，由人类**一次 ALTER + 一次 `wrangler deploy` + 线上自检**；不要 T-063 合并就单独上线（那时界面还没有解锁入口，ADR-0011 教训）。

---

## 四、交付物清单

1. T-063 分支与提交号（基座、署名、trailer、worktree 干净、local = origin）。
2. 门禁原始输出（check / build --check / web_size / 全量 node --test / node --check / diff --check / CRLF）。
3. 六组独立实测记录（可复现脚本路径）。
4. 现网 DDL 与 D-1 DML 的**建议文本**（只交文本，不执行）。
5. 交付报告注明：未部署、未执行 DDL/DML、未连现网、禁动清单零改动、未连做其它卡、未改治理文档与卡面、P0 状态未代改。
6. 已知坑需在报告说明：`history_save.js` 的 `delete` 只删行，删后下次采集会重新插入（不是 bug）。

> 复审：workbuddy 在独立纯 LF 沙盒复现门禁与六组行为，通过后 ff-only 合并收官并留痕；**不采信执行方自报单测**。
