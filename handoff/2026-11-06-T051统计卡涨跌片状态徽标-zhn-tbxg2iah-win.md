# 交接单 · T-051 统计卡 + 涨跌片 + 状态徽标

| 项 | 值 |
|---|---|
| 卡号 | T-051 |
| 执行 agent | trae @ zhn-tbxg2iah-win |
| 时间 | 2026-11-06 09:45 UTC+8 |
| 基座 | origin/master **16997f0** |
| 分支 | `agent/trae/ui-refresh-cards`（单提交 **f4f7c7a**，已推 origin） |
| worktree | `C:/Users/Zhn_X/source/prnmgt.wt/trae-ui-cards` |
| 状态 | 等审核合并；未合 master、未改卡状态、未部署、**未连做 T-052** |

## 改动（4 文件 +99/-5）

| 文件 | 行数 | 内容 |
|---|---|---|
| `worker/src/web/lib.js` | +16 | `deltaChip(pct)` / `statusChip(text, kind)`，均走 `esc()`；未动 `fmtPct`/`fmtNum` |
| `worker/src/web/tabs/overview_cards.js` | +2/-2 | import 补 `deltaChip`；`:57` 唯一 `fmtPct` 调用点包 `deltaChip(...)` |
| `worker/src/web/styles-refresh.css` | +78 | `.stat-card`（标签 12px / 数值 27px `--n-brand-strong` + tabular-nums / 左边条 `--n-brand`）、`.delta--up/down/flat`、`.chip--ok/warn/bad/muted` |
| `worker/src/lib/web_assets.js` | +3/-3 | build 重生成（36 资源 548437 字节），未手改 |

关键判定（`deltaChip`）：`fmtPct` 返回字符串，**只有「含 `%` 且首字符 `+`/`-`」才判涨跌**；`"-"`（无数据）/`"—"`（基期≤0）一律 `delta--flat`，不重算百分比。

## 准出原始输出

```
$ node scripts/build_web_assets.mjs --check
web_assets.js 与 36 个源文件一致

$ node scripts/check.mjs
任务合计 52 · todo 2 · doing 0 · blocked 0 · done 50
通过：0 个问题，2 个提示（T-034/T-040 存量）

$ node scripts/web_size.mjs
合计 65.0 KB / 24.3 KB gzip
通过：首屏 gzip 24.3 KB ≤ 40.0 KB（余量 15.7 KB）

$ node --check worker/src/web/lib.js        → exit 0，无输出
$ node --check worker/src/web/tabs/overview_cards.js → exit 0
$ lib.js 行数                                → 247（≤300）

$ node --test tools/tests/*.test.mjs tools/tests/unit/*.test.mjs
# tests 224 · pass 133 · fail 0 · cancelled 0 · skipped 91
```

过程说明：首次 check 报 `emoji 1`，原因是 `deltaChip` 注释里的 `⚠️`；已删该符号改「注意：」后复跑通过。`▲▼` 为几何字符，不触发 emoji 规则。

## 自检

- **业务零改动**：未改 `fmtPct`/`fmtNum`/取值逻辑/API/字段/口径；卡片结构仅外层多包一层 `deltaChip`。
- **色值只在 tokens.css**：新 CSS 仅 `var()` / `color-mix(in srgb, var(...), var(--n-surface))`；check 0 问题。
- **lib.js 247 行 ≤300**；未引用 `--n-h-top`；无 emoji、无框架/依赖。
- **打印稿未动**：`styles.css` 与其 `@media print` 零改动；T-050 的 `.view-body`、页头 DOM 零改动。
- 涨跌判定符合「含 % 且首字符 +/-」。

## 偏差（已在汇报说明）

1. 卡列 2 文件 → 实际 **3 个源文件** + build 生成物（`overview_cards.js` 是全站唯一 `fmtPct` 调用点，必须改）。
2. 涨跌色按 exec-prompt 用 `--n-up-ink`（红涨）/`--n-down-ink`（绿跌），未采用卡背景的 `--n-up/--n-down`。
3. 全量基线按实际 224 / pass133 / fail0 / skip91（旧文案 104/88 已过时）。

## 遗留风险

1. `statusChip` 本卡**无调用点**（预留给 T-052 状态列）；纯导出，不影响渲染，但 T-052 须消费否则属死代码。
2. 红涨绿跌：若业务习惯「跌红」，应在 tokens 层换色（`--n-up-ink`/`--n-down-ink` 互换），本卡未自定。
3. 本卡无浏览器运行时验证；部署后建议人工看总览 6 张卡的同比/环比胶囊（无数据、基期≤0、正、负四种）与 hover 明细。
4. **环境告警（未解决）**：回收站进程本轮再移 11 项 `.git` 内部文件（worktree index/lock、分支 ref、packed-refs.lock、config 等），随后复查 config 存在、remote 正常、branch/HEAD = f4f7c7a、status 干净。强烈建议人类排查杀毒/同步盘/索引服务；Agent 不得自行从回收站恢复。
