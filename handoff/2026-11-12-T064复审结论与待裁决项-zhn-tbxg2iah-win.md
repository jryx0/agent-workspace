项目: prnmgt

# T-064 复审结论：功能与门禁 PASS，验收项 ④ 未满足 → **不予合并，待人类裁决**

> [@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 17:24 UTC+8]
> 依据：`~/.agent-shared/global/rules.md` **v2.5**（三-4 挂起快照 / 三-7 部署权限 / 第八节 10 步）；上一份防撞权威 `handoff/2026-11-12-规范v2.6订正与RL-002任务卡-zhn-tbxg2iah-win.md`（`项目: 全局`）。
> 本会话为**复审方 workbuddy**，T2 自检简报已出；未认领任务卡、未改业务代码、未改卡面、未合并 master、未部署、未执行任何 DDL/DML、未连现网写操作。

## 一、结论（一句话）

`agent/trae/T-064 @ 9bd368b` 的**功能实现、白名单、门禁、独立实测全部 PASS**，但卡面验收 ④ 的「`@media print` 计算样式与基线一致」经 headless Chrome CDP **实证不满足**，且交付方准出材料与提交署名不符卡面；按「不采信自报、逐项验收」的复审口径 **不予 ff-only 合并**，卡面保持 `todo`、共享记忆 T-064 仍 `doing`。是否豁免该项／打回二改，**裁决权归人类**（第十节）。

## 二、交付核对

| 项 | 实测 |
|---|---|
| 分支 / 基座 | `agent/trae/T-064 @ 9bd368b`，基座 `1045fa1`（= 认领时刻 origin/master）；worktree `~/source/prnmgt.wt/trae-t064` 干净；local = origin = `9bd368b` |
| 白名单 | `git diff --name-status 1045fa1..9bd368b` **恰 6 文件**（history.js / dept_query.js / dept_data.js / web/tabs/dept_data.js / web/tabs/dept_data_write.js / lib/web_assets.js），45 insertions / 36 deletions；禁动清单零改动；未新增 `/api/*` 路径（check.mjs 路由 44 / 契约 46 一致） |
| 提交署名 | **作者 `张皓 <hao.zhang@gmail.com>`**，与卡面第 9 条要求的 `zhn-trae <trae@zhn-tbxg2iah-win>` 不符；trailer `Agent: trae` 已在 |
| 交付报告 | **缺失**：共享记忆 `memory/projects/prnmgt.md` 只有 18:12 认领行，无「交付待复审」行；未见门禁原始输出、卡面 ①~⑥ 六组实测记录、基座实测号、headless CDP 记录 |
| 现网状态 | 线上 Worker 仍旧版、D1 两表无 `manual_locked` 列（T-063 合并后未部署）；本卡不得据此断定已上线 |

## 三、独立复现（纯 LF 沙盒 `git archive 9bd368b`，不采信交付方自报）

- `scripts/check.mjs`：**0 问题 / 3 条存量提示**（任务 64 · done 60 / todo 4）
- `build_web_assets.mjs --check`：生成前、重生成后**均与 37 源文件一致**；重生成文件与提交版 `cmp` 逐字节相同
- `web_size.mjs`：首屏 gzip **25.3 KB ≤ 40 KB**（余量 14.7 KB）
- 全量 `node --test tools/tests/*.test.mjs tools/tests/unit/*.test.mjs`：**283 / pass 192 / fail 0 / skip 91**（与 T-063 收官基线一致，只增不减）
- `node --check` 6 文件 OK；`git diff --check 1045fa1..9bd368b` EXIT 0；沙盒内 6 文件 **CR = 0**
- **自写独立脚本 `wb-independent.mjs` 15/15 PASS**：G1 history 两段 SELECT 带出标记且值正确 / G2 dept_data 账号行与设备直计行带出标记 / G2b dedupSub `MAX(manual_locked)` 混合双份行不吞标记 / G3a-e admin 徽标+解锁、非 admin 只有徽标、未锁无按钮、设备直计 kind=device、身份未就绪占位 / G4 单次 `esc()` 无二次转义 / G5a-c unlock payload 契约、device 不带 account_id、403 文案原样透出不刷新 / G6a-b 后端非 admin 403 零写库、admin 清零并落 `manual_unlock` 审计 / G7 打印 class 偏离实证
  - 两次脚本断言失败均属**复审方构造问题**（误判 `&lt;` 应恰好 2 次，实际 common 被多个按钮复用；误判所有分支都带 `crud-actions`，实际 `!me` 分支仍无 class），已订正后全绿，与交付代码无关。
- **headless Chrome CDP（`cdp-check.mjs`，Chrome/157.0.8103.51）**：页面 `__errs = []`、`Runtime.exceptionThrown = []` → **无 JS 异常**；浏览器内 opCell 断言全 true（admin 徽标+解锁、viewer 无解锁、device kind、单次 esc、DOM 中 2 个解锁按钮 / 3 个徽标）。3 条 404 为沙盒静态服务未映射 `/favicon.ico` 与 `/assets/icons.svg`，与交付代码无关。
- `tools/compare/verify_all.mjs` **在 master 基线 `1045fa1` 与交付分支同样 exit 2**（自检失败：R-47 / R-48 无判定配置），且 `tools/mirror/out/legacy-all.json` 缺失本就 SKIP → **非本卡引入**，不作判据；golden 契约相关用例已含在全量 283 项中且 fail 0。

## 四、发现项

**A. 【阻断 · 验收 ④】打印计算样式偏离（CDP 实证）**
`opCell` 重构后，除 `!me` 占位分支外**所有**操作列 `<td>` 都带 `class="crud-actions"`，而 `styles.css` 的 `@media print` 有 `.crud-actions { display:none !important }`。CDP 切 print 媒体后实测：基线版 td `display: table-cell`、**交付版 td `display: none`**、表头「操作」`th` 仍 `table-cell` → viewer 打印时表头有列、数据行操作列整体消失，**列结构偏离**（admin 打印的同类错位是基线既有行为，不属本卡新增）。卡面 ④ 要求「`@media print` 计算样式与基线一致」，逐字不满足。
> 说明（复审方不强加方案）：把徽标/解锁按钮放进 `crud-actions` 也有合理意图——确保新增 UI 在打印时被隐藏；若改为无 class，徽标（span，非 `.btn`）会漏进打印件。最小修复可由 trae 在**已白名单的** `web/tabs/dept_data.js` 给表头「操作」`th` 同步加 `crud-actions`（或按分支保留原 class 语义），**新提交、不 amend**；是否接受该偏离则属人类豁免权。

**B. 【准出材料】** 见第二节交付报告缺失；卡面第四节 5 项交付物未提供，复审方已全部自行复现但无法核对交付方原始输出与基座实测号。

**C. 【流程偏差】** 提交作者署名不符卡面第 9 条（trailer 已在，定责不受影响）；改写已推送分支历史需 force push，不建议为此重推，按留痕记录即可。

**D. 【非本卡 / 环境】** MCP 9101 offline；`verify_all.mjs` 基线即 exit 2；CDP 沙盒 404；`memory/projects/prnmgt.md` 长期有他人未提交行，本轮用精确 index blob 只提交本方复审行。

## 五、挂起任务（当前全量快照 · 8 字段 · 继承自上一份 handoff 第五节，本轮无新增、无解挂）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | **S1** T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停，合并为一次 ALTER + 一次部署 | S3 人类裁定 + 新 ADR 批准 + 重编卡面 | 无 worktree；卡面 todo | 重编卡面后重新认领 | 人类 |
| prnmgt | **S2** P0 二次真机调研 | 2026-11-11 人类确认 | 富士 CWIS 无单双面统计，厂家后台升级中 | 厂家升级完成 + 复跑三台探测 + 更新调研文档 | tmp 快照保留；worktree 已 remove | 续跑不重开卡 | 人类 |
| prnmgt | **S3** v4 批次 / #18 | 2026-11-07 15:11 | 纸张消耗口径重编，数据可行性未定 | S2 结论 + D-5~D-10 逐条裁定 + 新 ADR | 仅 DRAFT，未写卡面 | 裁定后重编拆卡再认领 | 人类 |

**已解挂／不计入防撞**：prnmgt **S4 / T-064** 17:48 已解挂回 `todo`，trae 11-11 18:12 认领 `doing`；本轮复审**不合并**，仍 `doing`（防撞集合含 `doing/open/suspended`，其他会话不得重复开工）。全局 **RL-001 / RL-002 均为 `todo`**（RL-002 有前置），不是挂起项；本会话未认领。

## 六、下一步与部署边界

1. **人类裁决（二选一）**：① 打回二改 —— 把第四节 A 发给 trae，修 `dept_data.js` 表头 class 后**新提交**、补交付报告与规范署名，再由 workbuddy 复审；② 明确豁免卡面验收 ④ 与 B/C 准出材料 —— workbuddy 立即 ff-only 合并 `9bd368b` 并收官订正 `tasks.md` / `BOARD.md`。
2. **任何人不得自行合并或部署**：裁决前 `origin/master` 保持 `1045fa1`；`tasks.md` T-064 保持 `todo`。
3. **部署仍归人类本人**（三-7 ④ / #19 / ADR-0012 D6）：即便两卡都合并，现网仍需**一次 ALTER → D-1 补锁 DML（执行前 SELECT 计数）→ 一次 `wrangler deploy` → 线上自检**；旧 schema 上跑新 `ingest.js` 会报 `no such column: device_daily.manual_locked`（T-063 17:2x 实证），DDL 与 deploy 必须同一窗口。自检项：两表 `manual_locked` 列存在且 `NOT NULL DEFAULT 0`、锁定计数一致、20:10 `collect_run` 当日 success 16/16 且无 `no such column`、`/` 与 `/api/config` 200、admin 行可见「已锁定」与解锁按钮。失败即报告并回滚，禁止重试。
4. 合并前，当天人工订正仍须放在 20:10 `--force` 重采之后，否则照样被冲掉。

## 七、关键文件

- 复审脚本（本机 `tmp/`，不入 Git）：`~/.agent-shared/tmp/workbuddy/t064-review-20261112/{wb-independent.mjs, cdp-check.mjs, 01-check.log … 06-node-test.log}`
- 任务卡与提示词：`~/source/prnmgt/specs/0001-prnmgt-refactor/tasks.md` T-064、`~/.agent-shared/handoff/2026-11-11-T064逐卡执行提示词-zhn-tbxg2iah-win.md`、实施卡 APPROVED §三 T-064
- 交付分支：`~/source/prnmgt.wt/trae-t064`（保持原状，未触碰）
