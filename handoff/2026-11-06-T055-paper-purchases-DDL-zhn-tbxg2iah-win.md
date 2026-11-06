# 交接单 · T-055 ADR-0010 落地与 paper_purchases DDL 双轨

| 项 | 值 |
|---|---|
| 卡号 | T-055（ADR-0010 ACCEPTED 后解锁；workbuddy 12:14 裁定白名单 4 → 8 文件） |
| 执行 agent | trae @ zhn-tbxg2iah-win |
| 时间 | 2026-11-06 12:23 UTC+8 |
| 基座 | origin/master **fddcb84**（线上生产仍 0ce10d4，T-054 未部署） |
| 分支 / 提交 | `agent/trae/paper-ddl` · **85ce646**（已推 origin） |
| worktree | `C:/Users/Zhn_X/source/prnmgt.wt/trae-paper-ddl` |
| 状态 | 待 workbuddy 复审；未合并、未部署、未执行任何 DDL、未改卡面 |

## 改动（8 文件 +77/-10）

| 文件 | 行 | 内容 |
|---|---|---|
| `worker/schema.sql` | +14 | 末尾追加第 23 表 `paper_purchases` + 索引；22 表零改动 |
| `worker/migrations/20261106_paper_purchases.sql` | 新增 20 | 头注「仅现网一次性；新库不执行；不得整目录重跑」+ 执行/自检命令 + 同份 DDL |
| `docs/adr/0010-paper-purchases-table.md` | +15 | 批准人/时间；实施记录（T-052/T-054 前置、本卡落地、现网尚未建表、部署待人类）；状态保持 ACCEPTED |
| `docs/runbook.md` | +10 | 建库陷阱表补「仅现网一次性」行；登记 `wrangler d1 execute --file` 与 `SELECT COUNT(*)` |
| `worker/src/lib/admin_backup.js` | +7/-3 | 新增独立组 `paper: ['paper_purchases']`；`FULL_GROUPS` 加 `paper`；注释 22→23。`LEGACY_ALL_GROUPS` 17 表旧契约未动 |
| `tools/tests/c1_backup_full.test.mjs` | +11/-4 | 22→23（注释/两个测试名/两处断言）+ 防假绿三断言；「scope=all 17 表」「旧备份恢复不受影响」一字未动 |
| `tools/tests/c1_drill.test.mjs` | 2 | 前置断言 22→23（含文案） |
| `tools/backup/drill.mjs` | 2 | 注释「全量（22 表）」→「（23 表）」 |

## 准出原始输出

```
$ node scripts/check.mjs            → 通过：0 个问题，2 个提示（T-034/T-040 存量）
                                      任务合计 58 · done 54 · todo 4  ；check EXIT=0
$ node --check admin_backup.js      → EXIT=0
$ node --test c1_backup_full.test.mjs → # tests 7 / # pass 7 / # fail 0
$ node --test c1_drill.test.mjs       → # tests 2 / # pass 2 / # fail 0
$ node --test 全量（root + unit）     → # tests 249 / # pass 158 / # fail 0 / # skipped 91 / # todo 0
$ node scripts/build_web_assets.mjs --check → 与 36 个源文件一致
$ node scripts/web_size.mjs          → 67.4 KB / 25.2 KB gzip，通过 ≤40KB（余量 14.8）
$ git diff --check                   → EXIT=0
$ 两份 DDL 逐字比对                  → ddl_identical=True len_a=446 len_b=446
$ freshDb() 查询                     → {"n":0}
```

## 现网 DDL 状态（重要）

人类 **2026-11-06 12:05 已确认现网尚未建表**：11:41 的 `--file` 失败是文件当时尚不存在（顺序提前，不是故障），之后未改用内联 `--command`。现网首次执行直接用本卡 `migrations/20261106_paper_purchases.sql`：

```bash
cd C:/Users/Zhn_X/source/prnmgt/worker
node_modules/.bin/wrangler d1 execute prnmgt --remote --file=migrations/20261106_paper_purchases.sql
# 自检，期望 n = 0
node_modules/.bin/wrangler d1 execute prnmgt --remote --command "SELECT COUNT(*) AS n FROM paper_purchases"
```

## 自检 / 风险

- 双轨齐全：新库走 `schema.sql`，现网走 `migrations/`；`freshDb()` 已证明新库能建出表（ADR-0006）。
- 备份契约同步：`scope=full` 23 表（含 paper），`scope=all` 仍 17 表逐字节一致；恢复预览含 `paper_purchases`，避免 full 备份/恢复静默丢采购记录。
- 未改：`b5_admin` 的 scope=all 契约、legacy 22 表基线（`_admin_kit`/`_toner_kit`/`verify_all`/`_harness`）、`schema_diff.mjs`/`routes.json`（T-057）、`bootstrap.sql`、前端、采集端。
- 本卡未在浏览器/现网验证；DDL 未执行、未部署，需人类执行后自检。
- 环境：回收站进程本轮移走 9 项 `.git` 内部文件（含分支 ref、worktree index/HEAD.lock/AUTO_MERGE.lock/packed-refs.lock），`ls-remote` 已复核远端 = 85ce646；建议人类排查杀毒/同步盘/索引服务。