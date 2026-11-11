# T-064 逐卡执行提示词 · 前端人工锁定可见性与解锁按钮（APPROVED · 可投喂）

> 自包含任务书，**可直接全文复制投喂执行 Agent（trae）**，无需回看历史对话。
> 编制：workbuddy@zhn-tbxg2iah-win · 2026-11-11 17:48 +08
> 卡面：`~/source/prnmgt/specs/0001-prnmgt-refactor/tasks.md` 的 **T-064**（`状态: todo`，依赖已满足）
> **必读全文**：`~/.agent-shared/handoff/2026-11-11-方案A人工订正防覆盖实施卡-APPROVED-zhn-tbxg2iah-win.md`（§二设计 D5 / §三 T-064 / §五门禁 / §六禁动 / §八已知坑）
> 立项依据：`~/source/prnmgt/docs/adr/0012-manual-locked.md`（ACCEPTED，含批准检查单）、`docs/decisions/OPEN-DECISIONS.md` **#19 RESOLVED**、`BOARD.md` 12:56 / 16:32 / 17:2x / **17:48** 条目、四处章程豁免登记
> **派工授权**：人类 **2026-11-11 17:40 明确「确认T064」** → S4 解挂、确认可投喂下一张卡。解挂留痕已按规范 v1.8.11 三-4「先留痕后出提示词」先行落地（事件行 + 最新 handoff 全量快照 + 治理文档订正）。**解挂不等于自动派工**：本提示词仍由人类复制投喂，执行方须自行认领登记。
> 分工（全局规范 **v1.8.11** 三-7）：workbuddy 编卡 / 复审 / 合并收官；**执行 Agent 编码，一律不得部署、不得执行 `wrangler d1 execute` / `wrangler deploy`**；现网 ALTER、D-1 补锁 DML 与全部部署由人类本人执行。

---

## 零、开工前必须确认（任一项不满足即停下报告）

1. 读 `~/.agent-shared/global/rules.md`（现行 **v1.8.11**）并执行第八节自检 —— **10 步**（平台旧指令写「9 步」已过时）；同一 agent 的不同会话同样适用（三-5 ⑦）。
2. **按三-1 多项目加载**：读 `~/.agent-shared/handoff/` **最新一份** handoff（`2026-11-11-prnmgt-S4解挂与T064投喂-zhn-tbxg2iah-win.md`，`项目: prnmgt, stockdb`）的「挂起任务（当前全量快照）」；再按项目补读 prnmgt 最近一份带 `项目:` 标签的 handoff。`org.md` 只读最近 200 行。
3. **挂起快照（防撞集合含 `suspended`）**：**S1**（T-059/T-060/T-061）、**S2**（P0 二次真机调研）、**S3**（v4 / #18）**仍 suspended，一律不得认领／开工**；**S4（本卡 T-064）已解挂 → 回 `todo` 重新认领**。16:32「允许并行」是只针对 T-063 的一次性豁免；17:40「确认T064」只解挂 S4，两者都**不构成 v4 开工令**，也不解除 S1/S2/S3。
4. 按 `AGENTS.md` 必读顺序读：`constitution.md` → `BOARD.md` → `specs/0001-prnmgt-refactor/spec.md` → `tasks.md` 的 **T-064 卡面** → `docs/decisions/OPEN-DECISIONS.md` #19 → ADR-0012 → 实施卡 APPROVED **全文** → 本提示词。
5. **认领登记（三-5 ⑤）**：查 `~/.agent-shared/memory/projects/prnmgt.md` 任务登记节，确认 T-064 未被他人认领（doing/open/suspended），然后**追加一行** `【任务认领】T-064 | 前端人工锁定可见性与解锁按钮 | trae | doing`（append-only，禁止改旧行）。该文件可能仍有 trae 自己的历史未提交追加行（T-058 调研段、17:08 认领 / 17:16 交付行）—— **不改写、不代提交、不强行 rebase**；17:48 的 `【解挂】` 事件行已由 workbuddy 单独入库。**不得代 P0 登记 done、不得改 S2 挂起条**。
6. **基座判据（不写死 hash，避免立项文档提交后自指失效）**：`git fetch origin` 后实测 `git rev-parse origin/master` 与本地 HEAD 一致，把实测号写入交付报告；以**认领时刻的 `origin/master`** 为基座建 worktree，并逐项核验 T-063 已合入：
   ```bash
   git show origin/master:worker/schema.sql | grep -n "manual_locked"          # 期望 2 处（两表各一列）
   git cat-file -e origin/master:worker/migrations/20261111_manual_locked.sql  # 期望存在
   git show origin/master:worker/src/modules/ingest.js | grep -n "manual_locked = 0"  # 期望 2 处 WHERE
   ```
   三项任一不满足即停下报告。**不要**再套用 T-063 卡面的「`git diff --name-only 868adf7..origin/master` 仅 7 个治理文档」判据 —— 代码合入后该判据已自然失效，T-064 不复用。
7. **worktree 隔离**：新建 `~/source/prnmgt.wt/trae-t064` + 分支 `agent/trae/T-064`（**17:48 实测目录、本地分支、远端分支均未占用**）。主仓 `~/source/prnmgt` 里已有的其它 worktree（`trae-t063` 等）与既有未跟踪项（`.login-out.txt`、`docs/paper/field-survey-*`、`docs/plan-*`、`tmp/`）**不触碰、不提交**。
8. **不改卡面**：`tasks.md` 的 `状态` 由 workbuddy 收官订正（沿用 T-063 同口径：执行方只在共享记忆登记 `doing`，不改 `tasks.md`）；执行方不自报 done、不合并 master、不改任何治理文档（§六禁动清单）。
9. 提交用一次性署名 `git -c user.name=zhn-trae -c user.email=trae@zhn-tbxg2iah-win commit -m "..." -m "Agent: trae"`；推分支到 origin 后**停下等 workbuddy 复审**。追加修正用**新提交，不 amend**。
10. **本卡纯本地编码与测试**：不连现网 D1、不执行 `wrangler d1 execute` / `wrangler deploy`、不改采集服务器 crontab 或任何生产配置。T-063 代码虽已合并进 `master`，但**线上 Worker 仍是旧版、现网两表无 `manual_locked` 列**（17:2x 只读实证），本卡不得据此断定「已上线」。今晚 20:10 的 `--force` 重采照常运行，与本卡无关。
11. CRLF：项目仓 `core.autocrlf=false`，以**纯 LF 沙盒 `git archive` 导出**跑门禁；改动文件 CRLF 必须为 0，`web_assets.js` 等生成物不得手改（见下）。

---

## 一、做什么（严格 6 文件白名单，超出即停下请示）

| # | 文件 | 改动 |
|---|---|---|
| 1 | `worker/src/modules/history.js` | device / account 两段 SELECT 带出 `manual_locked` |
| 2 | `worker/src/lib/dept_query.js` | `dedupSub` 用 `MAX(manual_locked)` 聚合，避免一天多行时标记被吞 |
| 3 | `worker/src/modules/dept_data.js` | 外层 SELECT 带出 `manual_locked` |
| 4 | `worker/src/web/tabs/dept_data.js` | admin 行显示「已锁定」标记 +「解锁」按钮；非 admin 不显示按钮 |
| 5 | `worker/src/web/tabs/dept_data_write.js` | 点击调 `POST /api/history` 带 `action:'unlock'`；成功后刷新且标记消失；后端 403 时前端有错误态 |
| 6 | `worker/src/lib/web_assets.js` | **由 `node scripts/build_web_assets.mjs` 生成，禁止手改** |

**解锁接口已由 T-063 提供**：`POST /api/history` 的 `action:'unlock'` 分支（仅 admin、非 admin 403 且零写库、`UPDATE ... SET manual_locked=0`、写 `user_log` 审计）。**本卡不新增任何 `/api/*` 路径**，不改 `routes.js` / `fixtures/routes.json` / `api_contract.mjs` 判据。

**前端纪律**：沿用 `costs.js` 的锁定交互与**单次 `esc()`** 转义，无实体字面、无二次转义（T-051 / T-058 教训）；新增响应字段若触发 `check.mjs` / 黄金契约检查报错，**停下报告，不得擅自改判据哈希或夹具基线**（ADR-0012 后果 4）。改前端**必须重跑** `node scripts/build_web_assets.mjs`，再 `--check` 校验与源文件逐字节一致，否则线上资源仍是旧版（T-055 / T-058 两次验证）。

**不得改**：`lib/diff.js`（统计口径）/ `lib/util.js` / `lib/paper_calc.js` / `lib/history_save.js` 与其余 `admin_*.js`（T-063 产物）/ `worker/src/modules/ingest.js` / `worker/schema.sql` / `worker/migrations/**` / `collector/**`（ADR-0005 采集端零改动）/ 三个 CSS 与 `index.html` / `app.js` / 既有 22 表其它列与主键 / `BOARD.md` / `tasks.md` / `constitution.md` / `spec.md` / `OPEN-DECISIONS.md` / `docs/adr/**` / 现网 D1 与线上服务。**一次只做一张卡**，不得顺手改 T-063 或其它卡。

---

## 二、验收（执行方自测 + workbuddy 独立复现，不采信自报）

按卡面 ①~⑥ 与实施卡 §三 T-064 逐项给出可复现记录（脚本放共享仓 `tmp/<agent名>/<会话标识>/`，不入 Git、不在仓库内建脚本）：

1. **后端三处 SELECT** 带出 `manual_locked`：`history.js` 的 device / account 两段、`dept_query.js::dedupSub` 用 `MAX(manual_locked)`、`dept_data.js` 外层 SELECT；用 `freshDb()` 造「同行 `manual_locked=1`」与「混合批」验证标记不丢、不被聚合吞掉。
2. **可见性与解锁**：admin 行显示「已锁定」+「解锁」按钮，点击调 `POST /api/history {action:'unlock'}` 成功后刷新且标记消失；**非 admin 不显示按钮**；后端 403 时前端有明确错误态（不静默吞错）。
3. **转义纪律**：单次 `esc()`、无实体字面、无二次转义；`@media print` 计算样式与基线一致；**headless Chrome CDP 实测无 JS 异常**（给出实测记录）。
4. **生成物一致**：`node scripts/build_web_assets.mjs && node scripts/build_web_assets.mjs --check` 与源文件一致；`web_size.mjs` 首屏 gzip ≤ 40KB。
5. **门禁全绿**：`node scripts/check.mjs` **0 问题 / 3 条存量提示**（只增不减）· 全量 `node --test tools/tests/*.test.mjs tools/tests/unit/*.test.mjs` **fail 0**（T-063 收官基线 **283 / pass 192 / fail 0 / skip 91**，以认领前实测为准、只增不减）· 目标文件 `node --check` · `git diff --check` EXIT 0 · 改动文件 CRLF 0。
6. **未越界**：`git diff --name-only <基座>..HEAD` 恰为 6 文件白名单（或 7 个含已请示的单测）；禁动清单零改动；未执行任何 `wrangler d1 execute` / `wrangler deploy`、未连现网。

---

## 三、边界与红线

- **只做 T-064，不连做**：S1（v3 三卡 T-059~T-061）、S2（P0 二次真机调研）、S3（v4 / #18）仍 suspended；16:32「允许并行」与 17:40「确认T064」都是**范围有限的一次性授权**，不扩大到其它卡 / 批次 / 会话；**本批次不构成 v4 开工令**。
- **部署仍归人类本人**：T-063 虽已合并，但现网 DDL 未执行、线上 Worker 仍旧版；**不要单独上线**（旧 schema 上跑新 `ingest.js` 报 `no such column: device_daily.manual_locked`，17:2x 实证）。**T-064 复审合并后，由人类一次性执行现网 ALTER + D-1 补锁 DML + 一次 `wrangler deploy` + 线上自检**（ADR-0011 教训 / #19 / ADR-0012 D6）。
- 方案上线**之前**，当天的人工订正仍请放在 20:10 之后，否则照样会被重推冲掉；本卡不改变现行生产行为。
- 已知坑（交付报告须说明）：`history_save.js` 的 `delete` 只删行，删后下次采集会重新插入（默认 0）＝隐式解锁；`admin_import` 的 `INSERT OR REPLACE` 未显式带 `is_baseline` 等列（既有行为，T-063 未修）；重复 `unlock` 会多一条 `manual_unlock` 审计（无去重）。**均属 T-063 观察项，不在本卡范围，不得顺手修**。

---

## 四、交付物清单

1. T-064 分支与提交号（基座实测号、署名、trailer、worktree 干净、local = origin）。
2. 门禁原始输出（check / build 生成 + `--check` / web_size / 全量 node --test / node --check / diff --check / CRLF）。
3. 卡面 ①~⑥ 六组可复现实测记录（含 headless Chrome CDP 无 JS 异常、生成物逐字节一致）。
4. 交付报告注明：未部署、未执行 DDL/DML、未连现网、禁动清单零改动、未连做其它卡、未改治理文档与卡面、未代改 P0 / S2 状态。
5. 若自查发现 6 文件白名单不足以完成验收，**先停下请示**，不得自行扩文件。

> 复审：workbuddy 在独立纯 LF 沙盒复现门禁与六组行为，通过后 ff-only 合并收官并留痕；**不采信执行方自报单测**。两卡都合并后，部署窗口仍由人类本人开启。
