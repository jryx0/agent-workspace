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
2. **历史 UTC 存量行 DML 未执行**（裁定①：agent 只交建议文本、不执行）。**订正脚本已交付**（项目仓库 `2059413`）：

   | 文件 | 用途 |
   |---|---|
   | `docs/collect/sql-2026-11-09-t062-01-precheck.sql` | 只读预检：逐日 `delta_min`（480=仍 UTC / 0=已东八区 / NULL=无证据）+ 三桶汇总 |
   | `docs/collect/sql-2026-11-09-t062-02-fix.sql` | DDL 建备份表 `collect_run_bak_t062_20261109` + 幂等日志 `dml_log`，DML 只改「备份值未变 且 与当日东八区证据差≈8h」的行 |
   | `docs/collect/sql-2026-11-09-t062-03-verify.sql` | 复核 `delta_min` 全 0、`residual_8h`=0、无未来时间 |
   | `docs/collect/sql-2026-11-09-t062-99-rollback.sql` | 从备份逐行还原 + 清审计标记 |

   已在本地 SQLite 3.53 造 5 类场景实测：真 UTC 行 +8h、已东八区行跳过、无证据日不自动改、第二次重跑无变化、回滚差异 0、行数不变。**只动 `collect_run.ingested_at`**；`device_daily`/`account_daily.created_at` 由代码显式写 `nowIso()` 无需订正；`device_status_log.created_at` 虽走 UTC 默认值但不参与页面判读（页面用 `collected_at`），脚本仅作只读体检。建议顺序：**先部署 T-062 → 再跑 01→02→03**（02 幂等，可重跑补漏网行）。
3. 7号/14号主数据 IP 疑重复（均 `10.113.123.248`）与 14号 443 超时，按裁定③由人类人工核对。
4. **共享记忆 `memory/projects/prnmgt.md` 未提交**：该文件含 trae 4 行未提交登记（08:52 P0 认领、11:07 T-062 认领补登记、11:07 交付、11:22 二改交付），按规范不代提交；本次已**追加**我方「T-062 收官」一行于文件末尾，三行+一行仍待一次提交（建议由 trae 或人类确认后一并提交）。**故其他设备目前只能从本交接获知收官状态。**
5. trae 的 P0「只读真机调研」仍登记 `doing`，未收口。

## 七、防撞

- T-062 已 done，**不得再按该卡编码**；v3 三卡（T-059~T-061）仍暂停；v4 研究阶段不变。
- 分支 `agent/trae/collect-time-total-only` 与 worktree `~/source/prnmgt.wt/trae-t062` 已合并，可由人类决定是否清理（workbuddy 未删）。
- 项目仓库剩 3 个既有未跟踪项（`.login-out.txt`、`docs/plan-2026-11-04-device-gap.md`、`tmp/`），未纳入提交。
