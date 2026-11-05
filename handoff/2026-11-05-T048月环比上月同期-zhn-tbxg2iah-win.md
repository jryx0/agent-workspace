# 2026-11-05 T-048 月环比基数改「上月同期」 · zhn-tbxg2iah-win（trae）

## 交接要素速览

| 项 | 内容 |
|---|---|
| 当前状态 | 代码完成、准出全绿、分支已推 origin；**待 workbuddy 审核合并**（未合 master、未部署） |
| 分支 / 提交 | `agent/trae/mom-same-period` · 单提交 **`575568b`**（基于 master `3c2fed7`） |
| worktree | `~/source/prnmgt.wt/trae`（保留待审核后清理） |
| 计划 | `docs/plan-2026-11-05-mom-same-period.md` |
| 关键文件 | `worker/src/lib/overview_period.js`、`worker/src/web/tabs/dept.js`、`tools/tests/unit/overview_period.test.mjs`、`docs/decisions/OPEN-DECISIONS.md`、`tools/compare/deviations.json` |
| 下一步 | workbuddy 按计划 §8 审核 → 合并 + T-048 收官（卡状态由审核人改）；人类 `npx wrangler deploy` 后线上复核月卡环比 |

## 一、改动（7 文件，+143/-6）

| 文件 | 改动 |
|---|---|
| [overview_period.js](file:///C:/Users/Zhn_X/source/prnmgt.wt/trae/worker/src/lib/overview_period.js) | ① 头注释 17 → 18 窗口并注明 prevMSame 用途；② `buildDeptWindows` 在 `prevM` 之后新增 `prevMSame = deptSumRange(dateDept, 上月 1 号, refs.m0)`，旧 `prevM` 保留；③ `buildCards` 的 `month.mom` 基数换 `deptSumTotal(w.prevMSame)`；④ `buildDeptRow` 新增 `wPMS`、`mMom = clampSub(wM, wPMS)`、`row.month_prev = wPMS 三项和`；字段名零变更 |
| [dept.js](file:///C:/Users/Zhn_X/source/prnmgt.wt/trae/worker/src/web/tabs/dept.js) | 仅文案：month 维度 `mom: 上月（环比基）` → `上月同期（环比基）`；quarter/year 不动 |
| [overview_chart.js](file:///C:/Users/Zhn_X/source/prnmgt.wt/trae/worker/src/web/tabs/overview_chart.js) | 仅文案：`MOM_LABEL.month` 同步为 `上月同期（环比基）`。**计划 §3 文件清单外的一行**，理由：图表与部门页展示同一指标，不能两个标签；已在「偏差说明」单列 |
| web_assets.js | build 生成（35 资源，534331 字节） |
| OPEN-DECISIONS.md | 新增表行 #14 + 文末详节（OPEN，待人类拍板转 RESOLVED） |
| deviations.json | changedValues 新增 6 条：`overview.cards.month.mom`、`by_department[].month_prev` / `month_mom_print` / `month_mom_copy` / `month_mom_scan` |
| overview_period.test.mjs（新增） | 5 例：区间语义、边界①本月 1 号当天、边界②3-31→2-28、边界③上月无数据=0、prevM 保留 + month_prev/month_mom 同基 |

## 二、准出原始输出

### 1. 单测 `node --test tools/tests/unit/overview_period.test.mjs`

```
# tests 5
# pass 5
# fail 0
# cancelled 0
# skipped 0
```

### 2. 全量回归（unit/* + golden_numbers + b4_differential + b4_overview + b5_replay + b5_ingest_write + b5_toner + b5_admin）

```
1..197
# tests 197
# pass 109
# fail 0
# cancelled 0
# skipped 88
# todo 0
```

（88 skip = 缺 `tools/mirror/out/legacy-all.json`，与 T-045/T-046/T-047 基线一致，非本卡引入）

### 3. check.mjs / build --check / web_size

```
通过：0 个问题，2 个提示   （T-034/T-040 存量拆卡提示）
web_assets.js 与 35 个源文件一致
通过：首屏 gzip 19.9 KB ≤ 40.0 KB
```

### 4. harness 冒烟（`%TEMP%\t048-smoke.mjs`，按计划 §4 示例数据：本月至今 1200、上月 10-01~10-05 = 1000、10-06 起另有 800）

```
PASS month 卡 value=1200
PASS month 卡 mom=1000（上月同期，非上月全月 1800）
PASS 环比 +20%（(1200-1000)/1000）
PASS 部门行 month_prev=1000
PASS 部门行 month_mom=200
PASS 部门行 month_last（去年同月）不受影响
PASS by_device PRN001 mom 与设备序列独立计算一致（走 device_daily）
PASS by_device PRN001 yoy 与设备序列独立计算一致
```

by_device 两条用 `devDelta(buildDevSeries(device_daily))` 做控制组独立计算后比对，证明本卡未触碰 `lib/diff.js` 口径。

## 三、偏差说明（审核重点）

1. **`overview_chart.js` 一行文案改动在计划 §3 之外**。保留理由：该文件 `MOM_LABEL.month` 渲染的正是 `month_prev` 同一组数据，若不同步会出现「部门页叫上月同期、图表叫上月」的同一指标双标签。若不接受，删这一行不会影响任何数值口径与测试。
2. **未改 `tasks.md` 卡状态**。计划 §8 明确「T-048 收官」由审核人执行；改卡会让 diff 超出 §3 范围。
3. **未新增 `prevM` 的删除**。计划 §6 红线要求旧窗口保留（供其它口径/差分对照），已保留并有单测锁定。

## 四、环境告警（请人类排查）

- 本机有进程反复把仓库 `.git` 内部文件（`config`、`config.lock`、`index`、`refs/heads/agent/trae/*`）移入回收站。本轮 push 前后各发生一次 `.git/config` 被移走；已复查 `git remote -v` 仍正常、`fsck --connectivity-only` 无输出。建议排查杀毒软件/同步盘/索引服务。
- 本机 PATH 中 node 24.14.0 目录不存在，实际使用 `~/.workbuddy/binaries/node/versions/22.22.2-6/node.exe`。

## 五、T-049 状态

**未开工**。T-049（前端视觉·基础层）的卡与计划只存在于未合并分支 `agent/workbuddy/ui-refresh-plan`，master 中不存在该卡。人类已确认「T-048 先做，T-049 待定」；如需开工，需先合并该分支再由执行 agent 建 worktree。
