# T-062 二改复审通过并合并收官（2026-11-09 12:2x +08）

> 设备：zhn-tbxg2iah-win · 角色：workbuddy（复审 / 合并收官） · 前序交接：`2026-11-09-T062复审不通过与失败日回归-zhn-tbxg2iah-win.md`

## 一、结论

**复审通过，已 ff-only 合入 `master` 并推远端。`origin/master` = `d8ef6a5`（local = remote）。卡面 `状态: done`。未部署。**

## 二、提交链（`1c57149` → `d8ef6a5`）

| 提交 | 内容 | 署名 |
|---|---|---|
| `a7d50ec` | T-062 首版：7 文件 +328/−11（ingest/collect/collect_fill/tabs.collect/web_assets/两测试） | zhn-trae / `Agent: trae` |
| `0a161ee` | 二改：2 文件 +28/−15（撤销 `collect_fill.js` 的 `is_total_only` skip；改写 2 个用例） | zhn-trae / `Agent: trae` |
| `0af1060` | 复审方补：1 文件 +2/−1，仅订正 `collect.js` 合成行注释（原注释「synthDataRows 内部会跳过」在二改后失准） | zhn-workbuddy / `Agent: workbuddy` |
| `d8ef6a5` | 卡面 T-062 → done + 结果行；BOARD 收官条目与计数 | zhn-workbuddy / `Agent: workbuddy` |

## 三、复审证据（不采信自报，独立复现）

方式：`git archive 0a161ee` 导出独立纯 LF 沙盒 `~/.agent-shared/tmp/workbuddy/review-t062b`，在沙盒内重跑。

- `node scripts/check.mjs` → **0 问题**（3 条存量拆卡提示：T-034/T-040/T-055）
- `node scripts/build_web_assets.mjs --check` → 与 37 个源文件一致
- `node --test` → **275 / pass 184 / fail 0 / skip 91**（基线 265/174/0/91，只增不减）
- `web_size` 首屏 gzip **25.3 KB** ≤ 40 KB；`node --check` 4 文件 OK；`git diff --check` 0；沙盒 CRLF **0**
- 改动文件行数 264/294/182/255 均 ≤ 300；白名单未越界（未动 `worker/schema.sql`、`collector/`、`lib/diff.js`、`OPEN-DECISIONS`）
- 二改范围严格 2 文件，与「限 2 文件」指令一致（`git diff --name-status a7d50ec 0a161ee`）

## 四、P1 回归已修复（假 D1 探针实证）

`probe-edge.mjs` / `probe-dup.mjs`（沙盒内，未入仓）：

- **A 失败日**（`failed_json` 有 PRN007、`device_daily` 无行）：修复前明细仅 2 行、PRN007 完全不出现、无 error（前端又不渲染 `failures`）→ 修复后 **3 行**，PRN007 出现且 `no_data: true`、`error` 取 `failed_json` 原文（ConnectTimeout 整串）
- **B 停用但有 `device_daily` 行**：仍出现（`total_only: true`），与「有数据就展示」自洽（P2 提示未变）
- **C 在 `failed_json` 但有数据**：仍为 `total_only` 行、`no_data` 未设，形态不变（非回归）
- **有数据日去重**：PRN007 只出 **1 行**（`realKeys` 命中即跳过，不重复）；PRN001 行为不变
- status 视图：`activeDeviceNos()` 未动，占位行保留（有用例覆盖）

## 五、时间口径（缺陷一）

`RUN_UPSERT` 显式写 `ingested_at = now`（`nowIso()`，`YYYY-MM-DD HH:mm:ss`，与 SQLite `datetime('now')` 同格式 → 展示层无需改），且 `DO UPDATE` 同步，避免同日重跑后主表停在首次入库时刻。历史 UTC 存量行按裁定① A 方案由**人类本人**一次性 DML 订正；代码不做无判别 +8h（有测试覆盖「历史行不被改写」）。

## 六、未做 / 需人类

1. **未部署**。`cd ~/source/prnmgt/worker && npx wrangler whoami` → `Not logged in. Your auth token has expired and could not be refreshed because the Cloudflare auth server could not be reached`（网络/代理问题，凭据未被清除）。属「不能确定」情形，**部署归人类**；若需重新登录：`npx wrangler login` 后再 `npm run deploy`（或 `npx wrangler deploy`）。
2. **历史 UTC 存量行 DML 已由人类执行**（2026-11-09 14:07，结果见第八节）；**订正脚本**（项目仓库 `2059413` / `f4fa8bf` / 说明 `868adf7`）：

   | 文件 | 用途 |
   |---|---|
   | `docs/collect/sql-2026-11-09-t062-01-precheck.sql` | 只读预检：逐日 `delta_min`（480=仍 UTC / 0=已东八区 / NULL=无证据）+ 三桶汇总 |
   | `docs/collect/sql-2026-11-09-t062-02-fix.sql` | DDL 建备份表 `collect_run_bak_t062_20261109` + 幂等日志 `dml_log`，DML 只改「备份值未变 且 与当日东八区证据差≈8h」的行 |
   | `docs/collect/sql-2026-11-09-t062-03-verify.sql` | 复核 `delta_min` 全 0、`residual_8h`=0、无未来时间 |
   | `docs/collect/sql-2026-11-09-t062-99-rollback.sql` | 从备份逐行还原 + 清审计标记 |

   已在本地 SQLite 3.53 造 5 类场景实测：真 UTC 行 +8h、已东八区行跳过、无证据日不自动改、第二次重跑无变化、回滚差异 0、行数不变。**只动 `collect_run.ingested_at`**；`device_daily`/`account_daily.created_at` 由代码显式写 `nowIso()` 无需订正；`device_status_log.created_at` 虽走 UTC 默认值但不参与页面判读（页面用 `collected_at`），脚本仅作只读体检。建议顺序：**先部署 T-062 → 再跑 01→02→03**（02 幂等，可重跑补漏网行）。

   **⚠️ 现网执行踩坑（2026-11-09 12:35，人类实跑 01）**：`npx wrangler d1 execute prnmgt --remote --file=...01-precheck.sql` 报
   `X [ERROR] LIKE or GLOB pattern too complex: SQLITE_ERROR`。
   原因：P1 用 `ingested_at GLOB '[0-9][0-9][0-9][0-9]-...'`（20 组 `[0-9]`，75 字节模式）校验格式，**D1 运行时的 `LIKE`/`GLOB` 模式长度限制比本地 SQLite 严**（本地同一语句可通过，故上一轮本地实测未暴露）。02 的末行格式闸门有同样隐患。
   处理（已修，项目仓库 **`f4fa8bf`**）：两处均改为 `strftime` 回环判据 ——
   `strftime('%Y-%m-%d %H:%M:%S', ingested_at) = ingested_at`（合法值回环相等；非法/空值返回 NULL 或不等 → 不计入/不进 UPDATE）。语义与 GLOB 等价（本地复测：T 分隔、带毫秒、空串三种非法格式均未被 +8h，合法 UTC 行正常 +8h，`bad_format=3/4` 计数正确；5 类主场景与幂等/回滚结果不变）。
   **结论：重跑仍是同一命令**，无需改文件名或顺序；若 01 的多条结果只打印最后一段，可单独用 `--command` 跑 P2 逐日明细。
3. 7号/14号主数据 IP 疑重复（均 `10.113.123.248`）与 14号 443 超时，按裁定③由人类人工核对。
4. **共享记忆 `memory/projects/prnmgt.md` 未提交**：该文件含 trae 4 行未提交登记（08:52 P0 认领、11:07 T-062 认领补登记、11:07 交付、11:22 二改交付），按规范不代提交；本次已**追加**我方「T-062 收官」一行于文件末尾，三行+一行仍待一次提交（建议由 trae 或人类确认后一并提交）。**故其他设备目前只能从本交接获知收官状态。**
5. trae 的 P0「只读真机调研」仍登记 `doing`，未收口。

## 七、防撞

- T-062 已 done，**不得再按该卡编码**；v3 三卡（T-059~T-061）仍暂停；v4 研究阶段不变。
- 分支 `agent/trae/collect-time-total-only` 与 worktree `~/source/prnmgt.wt/trae-t062` 已合并，可由人类决定是否清理（workbuddy 未删）。
- 项目仓库剩 3 个既有未跟踪项（`.login-out.txt`、`docs/plan-2026-11-04-device-gap.md`、`tmp/`），未纳入提交。

## 八、现网执行结果（2026-11-09 14:07，人类执行 · workbuddy 只读复核）

**部署状态**：T-062 代码**已上线**。workbuddy 以只读 HTTP 复核 `https://prnmgt.parva.dpdns.org/assets/tabs/{collect,overview_cards,admin_master}.js`，三者与本地基线（`868adf7`）**逐字节一致**（13919 / 8997 / 15003 B），`collect.js` 含 T-062 三态逻辑（`total_only`/`no_data` 9 处命中），IP 链接仍全 `http`。

**DML 执行**：`02-fix.sql` 5 条语句、写入 48 行（含备份 21 + 审计 + UPDATE 20，D1 的 `rows_written` 是合并计数）；`dml_log.applied_at = 2026-11-09 06:07:11`（UTC，即本地 14:07）。

**只读复核结果**（`--command` 实测）：

| 指标 | 值 |
|---|---|
| `collect_run` 总行数 / 备份表行数 | 21 / 21（一致，只改值未增删） |
| `changed_rows`（已 +8h） | **20** |
| `unchanged_rows` | **1** |
| `future_rows`（CAST 后判定） | **0** |
| `min_v` / `max_v` | `2026-10-16 17:27:01` / `2026-11-08 20:14:32` |

**唯一例外：`2026-10-19` 未被订正**（`ingested_at` 仍 `04:12:00`，备份值相同）。原因：当日 `device_daily`/`account_daily` 的 `MAX(created_at)=20:00:20`，与 `ingested_at` 相差 **15h48m**，既不≈8h 也不≈0，被 02 的证据闸门判为 `CHECK 偏差异常` 而跳过。合理解释：旧代码 UPSERT 不更新 `ingested_at`，保留**首次入库**时刻（本地 12:12 → UTC 04:12），而当天 **20:00 又重采过一次**，把 `created_at` 覆盖成 20:00 → 12:12+8h 与 20:00 差 7h48m，叠上时区差即 15h48m。

**待人类决定**（1 行，可回滚，备份值 `2026-10-19 04:12:00` 已在备份表）：

```sql
UPDATE collect_run
   SET ingested_at = strftime('%Y-%m-%d %H:%M:%S', ingested_at, '+8 hours')
 WHERE collect_date = '2026-10-19'
   AND ingested_at = '2026-10-19 04:12:00';   -- 幂等：已改过则不重复 +8h
```

**类型陷阱经验（写给后续 agent）**：`strftime('%s', x)` 返回 **TEXT**，与整数比较时 SQLite 按存储类排序（INTEGER < TEXT），`strftime('%s',x) > strftime('%s','now')` 会**恒为真**，必须 `CAST(... AS INTEGER)`。02/03 的判据均走 `ABS(减法)` 或同格式字符串比较，不受影响（已复核 03:45 行是 TEXT vs TEXT 同格式比较，正确）。
