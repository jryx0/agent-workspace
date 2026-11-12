项目: prnmgt

# T-064 二轮复审通过并 ff-only 合并收官（未部署、DDL 归人类）

> [@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 18:20 UTC+8]
> 依据：`~/.agent-shared/global/rules.md` **v2.5**（三-4 挂起快照 / 三-7 部署权限 / 第八节 10 步）；上一份防撞权威 `handoff/2026-11-12-T064复审结论与待裁决项-zhn-tbxg2iah-win.md`（`项目: prnmgt`）。
> 本会话为**复审方＋收官方 workbuddy**（延续 T2 档位、标识沿用、不认领任务卡）。已执行 ff-only 合并与卡面收官；**未改业务代码内容、未部署、未执行任何 DDL/DML、未连现网写操作**。

## 一、结论（一句话）

首轮唯一阻断项「验收 ④ `@media print` 计算样式与基线一致」经 trae 二改 `55db7ef` 修复，并由复审方以 **8 分支 headless Chrome CDP 计算样式矩阵 + 16/16 独立断言 + 全量门禁** 双重实证复位；卡面 ①~⑥ 全部满足 → **PASS**，`agent/trae/T-064` 已 ff-only 合入 master 并订正卡面 `done`，`master = origin/master = 81df1a3`。**未部署**；DDL 与 deploy 仍归人类本人。

## 二、二改核对

| 项 | 实测 |
|---|---|
| 交付形态 | `9bd368b`（首版）→ `55db7ef`（`fix(web): 恢复 print 操作列 td class 与基线分流`），**新提交、未 amend**；基座 `1045fa1`；worktree 干净、local = origin = `55db7ef` |
| 二改范围 | 仅 `worker/src/web/tabs/dept_data_write.js` + 生成物 `worker/src/lib/web_assets.js`；整体相对基座仍 **恰 6 文件白名单**，45 insertions / 36 deletions |
| 修复手法 | `const tdCls = me.isAdmin && !(isDevOnly && !isBaseline) ? ' class="crud-actions"' : "";` —— 与基线 `opCell` 的 5 个分支一一对应，`!me` / viewer / 普通设备直计行恢复无 class，admin 三类保留 class |
| 禁动清单 | `styles.css` / `tokens.css` / `index.html` / `app.js` / `routes.js` / `schema.sql` / `ingest.js` / `history_save.js` / `diff.js` / `util.js` / `paper_calc.js` 共 11 文件与基线 **逐字节一致**；未新增 `/api/*` 路径 |
| 提交署名 | 作者仍 `张皓 <hao.zhang@gmail.com>`（trailer `Agent: trae` 已在）→ 见第五节遗留 |

## 三、独立复现（纯 LF 沙盒 `git archive 55db7ef`，不采信交付方自报）

- `scripts/check.mjs`：**0 问题 / 3 条存量提示**（T-034 / T-040 / T-055 拆卡提示）
- `build_web_assets.mjs --check`：**生成前、重生成后均与 37 源文件一致**；重生成文件与提交版 `cmp` 逐字节相同（生成器产出、非手改）
- `web_size.mjs`：首屏 gzip **25.3 KB ≤ 40 KB**（余量 14.7 KB）
- 全量 `node --test tools/tests/*.test.mjs tools/tests/unit/*.test.mjs`：**283 / pass 192 / fail 0 / skip 91**（与 T-063 收官基线一致，只增不减）
- `node --check` 6 文件 OK；`git diff --check 1045fa1..55db7ef` EXIT 0；沙盒内 6 文件 **CR = 0**
- `tools/compare/verify_all.mjs`：在基线 `1045fa1` 与交付分支**同样 exit 2**（自检失败 R-47 / R-48 无判定配置 + `mirror/out/legacy-all.json` 缺失），**非本卡引入**，不作判据；golden 契约相关用例已含在全量 283 项且 fail 0
- 自写 `wb-independent2.mjs`：**16 / 16 PASS** —— G1 history 两段 SELECT 带出标记 / G2 dept_data 账号行与设备直计行 / G2b `dedupSub` `MAX(manual_locked)` 混合双份行不吞标记 / G3a-e admin 徽标+解锁、非 admin 只有徽标、未锁无按钮、设备直计 `kind=device`、`!me` 占位 / G4 单次 `esc()` / G5a-c unlock payload 契约、device 不带 `account_id`、403 文案原样透出不刷新 / G6a-b 后端非 admin 403 零写库、admin 清零并落 `manual_unlock` 审计 / **G7（本轮改写）8 分支 td class 与基线逐项一致** / **G8（本轮新增）`web_assets` 内嵌 `tabs/dept_data_write.js` 与源文件逐字节一致且含 `tdCls`**

## 四、验收 ④ 复位实证（headless Chrome/157.0.8103.51，`cdp-print2.mjs`）

同一页面同时加载基线 `1045fa1` 与二改 `55db7ef` 两版 `opCell`，8 个分支各生成一行；`Emulation.setEmulatedMedia('print')` 后逐个取 `getComputedStyle(td).display`：

| 分支 | 基线 class | 二改 class | screen 基/新 | print 基/新 |
|---|---|---|---|---|
| `!me` 占位 | (无) | (无) | table-cell / table-cell | **table-cell / table-cell** |
| viewer 普通行 | (无) | (无) | table-cell / table-cell | **table-cell / table-cell** |
| viewer 基线行 | (无) | (无) | table-cell / table-cell | **table-cell / table-cell** |
| viewer 设备直计非基线 | (无) | (无) | table-cell / table-cell | **table-cell / table-cell** |
| admin 普通行 | crud-actions | crud-actions | table-cell / table-cell | **none / none** |
| admin 基线行 | crud-actions | crud-actions | table-cell / table-cell | **none / none** |
| admin 设备直计非基线 | (无) | (无) | table-cell / table-cell | **table-cell / table-cell** |
| admin 设备直计基线 | crud-actions | crud-actions | table-cell / table-cell | **none / none** |

- 表头「操作」th：基线 `table-cell` / 二改 `table-cell`；print 媒体生效（基线 admin 行确为 `none`）
- 页面 `__errs = []`、`Runtime.exceptionThrown = []` → **无 JS 异常**；浏览器内 admin 徽标+解锁、viewer 无解锁、单次 esc 断言全 true
- 3 条 404 为沙盒静态服务未映射 `/favicon.ico` 与 `/assets/icons.svg`，与交付代码无关
- 观察项（**非回归**）：T-064 新增的「已锁定」徽标会出现在原本纯 `—` 的设备直计行 / viewer 行，打印时该列内容随之可见；这是本卡预期的新功能内容，验收 ④ 判据是「计算样式与基线一致」，不要求内容逐字相同。admin 行 print 时操作列隐藏、表头仍在，属**基线既有**错位，本卡不改。

## 五、遗留与裁定边界（如实记录，不隐瞒）

1. **准出材料仍缺**：交付方未补 AGENTS.md 第四节「卡片 / 改了 / 跑了 / 输出 / 没做 / 风险」六段报告、门禁原始输出、六组实测记录、基座实测号，共享记忆也无「二改交付待复审」行；trae 仅在 `tmp/trae/t064/` 补了 `cdp-print-check.mjs` / `print-fixture.html` / `probe-ui-t064.mjs` 三个探针。**不阻断依据**：这些不是卡面 ①~⑥ 的验收项，且复审方已用独立脚本 + 独立沙盒完整复现全部门禁与行为，不采信任何自报，证据链无缺口；继续打回不增加技术保证。
2. **署名偏差未改**：提交作者 `张皓 <hao.zhang@gmail.com>` ≠ 卡面第 9 条 `zhn-trae`；`Agent: trae` trailer 已在。首轮已明确「不建议为此 force 重推已推送分支」，本轮沿用，改写历史的收益小于风险。
3. **非本卡问题**：`verify_all.mjs` 基线同样 exit 2；`[Agent报告]` MCP 9101 offline（不阻塞）。
4. 以上 1/2 属**流程观察项**，人类可另行要求 trae 补材料；本轮判定为 PASS 并收官的依据是卡面验收项全部实测满足，不是豁免验收 ④。

## 六、合并收官（本轮唯一写操作）

- `git merge --ff-only agent/trae/T-064`：`1045fa1` → `55db7ef`，6 文件 45+/36-
- 收官提交 `81df1a3`（`docs: T-064 二轮复审通过并 ff-only 合并收官`）：仅 `BOARD.md` + `specs/0001-prnmgt-refactor/tasks.md`，+12/-2 —— T-064 卡面 `todo` → `done` 并追加结果行，BOARD 更新「最后更新」+ 新增收官条目
- **精确 index blob 提交**：`tasks.md` 中 trae 的 T-058 真机调研追加 1 行属其未提交改动，**未代提交、未触碰**；收官后工作区 `git diff` 仍恰为该 1 行
- `git push origin master` 成功，`local master = origin/master = 81df1a3`。**`git push` 不等于部署**，线上 Worker 仍旧版。

## 七、挂起任务（当前全量快照 · 8 字段 · 继承自上一份 handoff 第五节）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | **S1** T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停，合并为一次 ALTER + 一次部署 | S3 人类裁定 + 新 ADR 批准 + 重编卡面 | 无 worktree；卡面 todo | 重编卡面后重新认领 | 人类 |
| prnmgt | **S2** P0 二次真机调研 | 2026-11-11 人类确认 | 富士 CWIS 无单双面统计，厂家后台升级中 | 厂家升级完成 + 复跑三台探测 + 更新调研文档 | tmp 快照保留；worktree 已 remove | 续跑不重开卡 | 人类 |
| prnmgt | **S3** v4 批次 / #18 | 2026-11-07 15:11 | 纸张消耗口径重编，数据可行性未定 | S2 结论 + D-5~D-10 逐条裁定 + 新 ADR | 仅 DRAFT，未写卡面 | 裁定后重编拆卡再认领 | 人类 |

**已完成／不计入防撞**：prnmgt **S4 / T-064** 本轮 `done`（`81df1a3`），分支 `agent/trae/T-064` 与 worktree `~/source/prnmgt.wt/trae-t064` 保留原状，未删除、未触碰；首轮 17:24 交接中「S4 仍 doing／不得合并」的表述**已过时，以本份为准**。全局 **RL-001 / RL-002 均为 `todo`**（RL-002 有前置），不是挂起项；本会话未认领。S1/S2/S3 未被解挂，本份不构成 v4 开工令。

## 八、部署卡（归人类本人，workbuddy 不自行部署）

命中 **D1 migration／表结构变更**（三-7 ④ / #19 / ADR-0012 D6 / 用户级长期授权 2026-11-06）→ **不确定，不自行部署**。现网两表仍无 `manual_locked` 列；单独上线新 `ingest.js` 会报 `no such column: device_daily.manual_locked`（T-063 17:2x 实证），**DDL 与 deploy 必须同一窗口**：

```bash
cd ~/source/prnmgt/worker
npx wrangler d1 execute prnmgt --remote --file migrations/20261111_manual_locked.sql
npx wrangler d1 execute prnmgt --remote --json --command "SELECT (SELECT COUNT(*) FROM device_daily WHERE is_baseline=1) AS dev_n, (SELECT COUNT(*) FROM account_daily WHERE is_baseline=1) AS acc_n"
npx wrangler d1 execute prnmgt --remote --command "UPDATE device_daily SET manual_locked=1 WHERE is_baseline=1"
npx wrangler d1 execute prnmgt --remote --command "UPDATE account_daily SET manual_locked=1 WHERE is_baseline=1"
npx wrangler deploy
```

**线上自检**：① 两表 `manual_locked` 列存在且 `NOT NULL DEFAULT 0`；② 锁定计数与上面 `dev_n` / `acc_n` 一致；③ 20:10 `--force` 重采后 `collect_run` 当日 `success 16/16` 且无 `no such column`；④ `/` 与 `/api/config` 200；⑤ admin 行可见「已锁定」+「解锁」，viewer 只见徽标。**失败即报告人类并给回滚建议（实施卡 §七），禁止反复重试**。合并后、部署前，当天人工订正仍须放在 20:10 重采之后，否则照样被冲掉。

## 九、关键文件

- 复审脚本（本机 `tmp/`，不入 Git）：`~/.agent-shared/tmp/workbuddy/t064-review2-20261112/{wb-independent2.mjs, cdp-print2.mjs, finalize.mjs, sync-wt.mjs, 01-check.log … 07-verify-all-new.log}`
- 首轮材料：`~/.agent-shared/tmp/workbuddy/t064-review-20261112/{wb-independent.mjs, cdp-check.mjs, repo-master/（基线 1045fa1 归档）}`
- 任务卡 / 提示词：`~/source/prnmgt/specs/0001-prnmgt-refactor/tasks.md` T-064（done）、`~/source/prnmgt/BOARD.md` 18:20 条目、`~/.agent-shared/handoff/2026-11-11-T064逐卡执行提示词-zhn-tbxg2iah-win.md`
- 首轮结论：`~/.agent-shared/handoff/2026-11-12-T064复审结论与待裁决项-zhn-tbxg2iah-win.md`（本份为其后继）
