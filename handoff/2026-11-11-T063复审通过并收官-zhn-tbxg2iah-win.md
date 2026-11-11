# T-063 复审通过并 ff-only 合并收官（**未部署 · 待人类部署**）

> 编制：workbuddy@zhn-tbxg2iah-win · 2026-11-11 17:2x UTC+8
> 依据：`~/.agent-shared/global/rules.md` **v1.8.10**（三-4 挂起快照 / 三-6 分支准出 / 三-7 部署权限）；实施卡 `handoff/2026-11-11-方案A人工订正防覆盖实施卡-APPROVED-zhn-tbxg2iah-win.md` §五；逐卡提示词 `handoff/2026-11-11-T063逐卡执行提示词-zhn-tbxg2iah-win.md`。
> 本文件为**最新一份 handoff**，按 v1.8.10 三-4 ② 承载「挂起任务（当前全量快照）」（见第五节，滚动继承）。

---

## 一、结论

**复审 PASS**。trae 单提交 `7736fa6` 已由 workbuddy **ff-only 合入 `master`**，收官订正提交 `d5fad5d`。**零部署、零 DDL、零 DML、零现网写操作**。

| 项 | 结果 |
|---|---|
| 交付 | `agent/trae/T-063` @ `7736fa6`，8 文件 +367/-19；基座 `c6cb364`；署名 `zhn-trae` + trailer `Agent: trae`；worktree 干净、local=origin |
| 白名单 | 严格 9 文件中 8 个改动，未改的 `b5_admin.test.mjs` 属卡面标注的可选项；**禁动清单零改动** |
| 收官 | `master` = `d5fad5d`（`7736fa6` 快进 + 卡面/BOARD 订正）；卡面 T-063 `todo → done` + 结果行；`check.mjs` 0 问题 / 3 条存量提示 |
| 线上 | **待人类部署**：线上 Worker 仍为旧版，与新 `master` **不一致**；现网两表无 `manual_locked` 列 |

## 二、交付准出核对

- `git merge-base c6cb364 7736fa6 = c6cb364` → 可 ff-only，无分叉；单提交、无 amend。
- `git diff --name-only c6cb364..7736fa6` 恰为 8 个白名单文件；`git diff --check` EXIT 0；8 文件 CRLF=0。
- 禁动清单逐项零改动：`lib/diff.js` / `lib/util.js` / `lib/paper_calc.js` / `collector/**` / `routes.js` / `fixtures/routes.json` / `api_contract.mjs` / 三个 CSS / `index.html` / `app.js` / 既有 22 表其它列与主键 / 治理文档与卡面（收官由 workbuddy 订正）。

## 三、独立复现（**不采信交付方自报单测**）

**沙盒**：`git archive 7736fa6` 导出至 `~/.agent-shared/tmp/workbuddy/t063-review-20261111/`（纯 LF，非 Git 仓库）。

门禁全绿：`check.mjs` **0 问题 / 3 条存量提示** · `build_web_assets.mjs --check` 与 37 源文件一致 · `web_size` **25.3 KB gzip ≤ 40 KB** · 全量 `node --test` **283 / pass 192 / fail 0 / skip 91**（T-062 基线 275/184/0/91 → 只增不减）· 6 文件 `node --check` OK · `git diff --check` EXIT 0 · CRLF 0。

复审方自写脚本 `wb-independent.mjs`（不 import 交付方单测，自行构造 payload 与断言）**8/8 PASS**：

| 组 | 实测内容 |
|---|---|
| G0 | `PRAGMA table_info` 两表各多 1 列 `INTEGER NOT NULL DEFAULT 0`，主键逐字未变；migration 头注四要素齐 |
| G1 | 未锁定行同日重推仍覆盖数值 / `collect_type` / `created_at` |
| G2 | 人工入口置锁后同键重推**整行逐字段不变**，同批普通行正常更新，`batch` 不抛、`ingested` 不变；`master_devices.ip` / `collect_run` / `toner_consumption_log` / `user_log` 旁路仍写 |
| G3 | `fields` 白名单不含 `manual_locked`，普通 update 带 `manual_locked:0` 无法绕过锁定 |
| G4 | history(update/insert) / baseline(device/account) / account reset / history import 四入口均置 1；`INSERT OR REPLACE` 显式带列，不复位 0 |
| G5 | 基线行同日重推后数值与 `is_baseline=1` 同时保持，「标记是基线、值是采集值」的畸形行消失 |
| G6 | 非 admin `unlock` 403 且全库快照逐字节零写库；admin 解锁落 `manual_unlock` 审计、下次 ingest 恢复覆盖 |
| G7 | `detectAccountResets` / `pushToner` 仍按 `collect_date < date` 读日表上一行（未被改成读 payload） |

代码逐行核对：两条 `DEV_UPSERT` / `ACC_UPSERT` 仅在 `DO UPDATE SET` 末尾加 `WHERE <表>.manual_locked = 0`（整行跳过，非只护数值）；`history_save.js` 的 `unlock` 分支仅 admin、带 404 存在性检查与 `auditLog`，人工 `update` / `insert` 各写 `manual_edit` / `manual_insert` 审计；`admin_baseline` / `admin_account` / `admin_import` 原有 `baseline_upsert` / `account_reset` / `history_import` 审计仍在。

**唯一一次脚本失败属复审方构造问题**：G5 初版用了未来日期 `2026-11-12`，基线接口按既有设计返回 400；改用历史空日 `2026-11-08` 后通过，与交付代码无关。

**现网只读核对**：`SELECT name FROM pragma_table_info('device_daily') WHERE name='manual_locked'` → `results: []`（DDL 未执行）；11-11 `collect_run` 仍为 `08:38:31 success 16/16`（生产采集未受影响，20:10 强制重采尚未到点）。

## 四、部署判断（三-7）：**不能部署，通知人类**

按用户授权「审核通过后由 workbuddy 自行判断是否直接部署」，本次判定为**不能确定且命中禁止项**，故不部署、标「待人类部署」：

1. 三-7 ④ 明文「涉及 migration / 表结构变更必须通知人类」；#19 / ADR-0012 / 实施卡 §四 均写死「现网一次性 ALTER、D-1 DML 与全部 `wrangler deploy` 由人类本人执行」。
2. **实证硬阻断**：`wb-deploy-risk.mjs` 把新 `ingest.js` 跑在旧 schema（`c6cb364` 的 `schema.sql`，等价于现网）上，`/api/ingest` 直接抛 `no such column: device_daily.manual_locked`。**代码与 DDL 必须同一窗口上线**，单独部署会让当晚 20:10 的采集推送全量失败。
3. T-064（前端解锁入口）仍挂起（S4），此时上线会出现「能锁但界面无解锁按钮」的半成品。
4. #19 与 ADR-0011 教训要求：**T-063 + T-064 都复审合并后，人类一次 ALTER + 一次 deploy + 线上自检**。

**给人类的一次性命令文本**（agent 不执行；`--file` 只出汇总，取结果用 `--json --command`）：

```bash
cd ~/source/prnmgt/worker
# ① 前置：T-064 已复审合并；两卡代码都在 master
npx wrangler d1 execute prnmgt --remote --file migrations/20261111_manual_locked.sql
npx wrangler d1 execute prnmgt --remote --json --command "SELECT name FROM pragma_table_info('device_daily') WHERE name='manual_locked'"
# ② D-1（R1）：执行前先 SELECT 计数并留痕
npx wrangler d1 execute prnmgt --remote --json --command "SELECT COUNT(*) AS n FROM device_daily WHERE is_baseline=1"
npx wrangler d1 execute prnmgt --remote --command "UPDATE device_daily SET manual_locked=1 WHERE is_baseline=1"
npx wrangler d1 execute prnmgt --remote --command "UPDATE account_daily SET manual_locked=1 WHERE is_baseline=1"
# ③ 一次部署
npx wrangler deploy
```

**部署后自检项**：两表 `manual_locked` 列存在且 `NOT NULL DEFAULT 0`；`COUNT(*) WHERE manual_locked<>0` 与 ② 的计数一致；20:10 采集后 `collect_run` 当日 `success 16/16` 且日志无 `no such column`；`/` 与 `/api/config` 200；T-064 上线后 admin 行可见「已锁定」与解锁按钮。**失败即报告并回滚**（回滚语句见实施卡 §七），不重试。

## 五、挂起任务（当前全量快照 · 未解挂项一律禁止认领／开工）

> 继承 `handoff/2026-11-11-挂起任务登记机制与全量快照-zhn-tbxg2iah-win.md` 第四节。本轮**无新增挂起、无解挂**；S4 的一个解挂前置已满足，但另一项未满足，故仍 suspended。挂起与解挂权归人类。

| 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|
| **S1** T-059 / T-060 / T-061 | 2026-11-07 15:0x 人类 D-4（v4 重编方案） | v3 三卡暂停，要合并成一次 ALTER + 一次部署 | S3 的人类裁定完成 + 新 ADR 批准 + 重编后的卡面写入 `tasks.md` | 无 worktree；卡面 `todo`；`docs/paper/exec-prompt-2026-11-07.md` **停用** | 重编卡面后重新认领 | 人类 |
| **S2** P0 二次真机调研 | 2026-11-11 人类确认（trae 共享记忆「T-058 真机调研挂起」条，**尚未提交**） | 富士 CWIS 无单双面统计已实锤，联系厂家后台升级中 | 厂家升级完成 + 复跑富士 / 京瓷三台探测 + 更新 `docs/paper/field-survey-2026-11-07.md` 结论 | `tmp/trae/p0-scan/` 与 `tmp/trae/field-survey/anon-probe/` 快照保留；凭据经环境变量、不落盘；worktree 已 remove | **续跑**，不重开卡 | 人类 |
| **S3** v4 批次 / `OPEN-DECISIONS.md` #18 | 2026-11-07 15:11（#18 OPEN PENDING、方案 DRAFT） | 纸张消耗口径重编，数据可行性未定 | S2 调研结论 + #18 与方案 §8 的 D-5~D-10 逐条人类裁定 + 新 ADR 批准（若走分支 A） | 仅 DRAFT 文档；未写卡面、未拆卡、未派工 | 裁定后重编方案与拆卡，再重新认领 | 人类 |
| **S4** T-064（前端解锁入口） | 2026-11-11 16:32 派工卡 §三 | 依赖 T-063 复审通过并 ff-only 合并；禁止连做 | ✅ **T-063 复审合并收官已于 17:2x 完成（`d5fad5d`）**；❌ **人类确认可投喂下一张卡（未满足）** | 无 worktree；卡面 `todo` | **重新认领** | 人类 |

口径说明：S2 挂起的是厂家升级后的**复跑**，P0 首轮调研已于 11-09 13:1x 交付；「允许并行」（16:32）仍是一次性豁免，仅解除「P0 未 done 不得认领 T-063」这一闸，**不解除 S1/S3/S4，本批次不构成 v4 开工令**。`memory/projects/prnmgt.md` 有 trae 活跃未提交改动（含 17:08 认领行、17:16 交付行、S2 挂起条），本轮按三-5 ⑥⑦ **未触碰、未代提交、未强行 rebase**；项目级 `【挂起】` 事件行与 T-063 收官事件行待其提交后由后续会话补登。**在此期间，本快照是开工防撞的权威依据。**

## 六、边界与未做事项

- 本轮只做：复审、ff-only 合并、卡面/BOARD 收官订正、留痕与同步。**未部署、未执行 DDL/DML、未连现网写操作、未认领新卡、未解挂 S4、未派 T-064**。
- `specs/.../tasks.md` 工作区仍有 trae 的 T-058 真机调研追加行（未提交）。收官提交用 `git hash-object -w` + `git update-index --cacheinfo` 构造**仅含卡面订正**的 index blob，实测提交后 `git diff` 只剩他人那一行 → **未代提交**。
- 未清理 `~/source/prnmgt.wt/trae-t063` worktree（按三-6 生命周期由交付方会话结束自行 remove，避免并行打扰）；合并后分支 `agent/trae/T-063` 保留在 origin。
- 观察项（不阻断，供 T-064 / 后续批次参考）：① 对 `manual_locked` 已为 0 的行重复 `unlock` 仍会写一条 `manual_unlock` 审计（无去重）；② `admin_import` 的 `INSERT OR REPLACE` 未显式带 `is_baseline` 等列，REPLACE 会丢这些列 —— 属既有行为，实施卡 §八 已知坑 1 明确本卡不修；③ `history_save` 的 `delete` 删行后下次采集会重新插入（默认 0），等于隐式解锁，已知坑 7 要求交付报告说明，trae 17:16 交付行已注明未改该文件。
- **判据时效提醒**：T-063 卡面「`git diff --name-only 868adf7..origin/master` 仅治理文档」是**派工前**的基座判据；本轮代码合入后该 diff 自然包含 `worker/**`，属预期失效，**不是异常、也不代表有人违规改码**。T-064 的依赖只看「T-063 复审通过并 ff-only 合并」，不复用该判据；后续会话勿以此判据误停。

## 七、引用

- 交付分支 `agent/trae/T-063` @ `7736fa6`；收官提交 `d5fad5d`；`BOARD.md` 17:2x 条目；`tasks.md` T-063 结果行。
- 复审沙盒与脚本：`~/.agent-shared/tmp/workbuddy/t063-review-20261111/`（`wb-independent.mjs` 8 组、`wb-deploy-risk.mjs` 部署实证、`finalize_t063.py` 收官订正）——按规范留在 `tmp/<agent名>/<会话标识>/`，不入 Git。
- 立项：`docs/adr/0012-manual-locked.md`（ACCEPTED）、`docs/decisions/OPEN-DECISIONS.md` #19；当日工作日志 `C:/Users/Zhn_X/WorkBuddy/2026-11-04-21-23-46/.workbuddy/memory/2026-11-11.md`。
