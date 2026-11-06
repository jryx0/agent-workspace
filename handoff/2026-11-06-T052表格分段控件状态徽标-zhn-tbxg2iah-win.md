# 交接单 · T-052 表格 + 子页签分段控件 + 消费 statusChip

| 项 | 值 |
|---|---|
| 卡号 | T-052 |
| 执行 agent | trae @ zhn-tbxg2iah-win |
| 时间 | 2026-11-06 09:12 UTC+8 |
| 基座 | origin/master **05c265e**（提示词写的 34c162c 已过时） |
| 分支 / 提交 | `agent/trae/ui-refresh-table` · **9a65e7b**（已推 origin） |
| worktree | `C:/Users/Zhn_X/source/prnmgt.wt/trae-ui-table` |
| 状态 | 待 workbuddy 审核；未合 master、未改卡状态、未部署、未连做其它卡 |

## 改动（4 文件 +129/-5）

| 文件 | 行数 | 内容 |
|---|---|---|
| `worker/src/web/styles-refresh.css` | +69/-1 | 表格覆盖（sticky 表头 top:0、`--n-th-bg`/`--n-th-ink`、斑马纹、hover、max-height 72vh）+ `.subtabs`/`.subtab` 分段控件四态 |
| `worker/src/web/tabs/overview_cards.js` | +4/-2 | import 补 `statusChip`；deviceTable 状态列走 `cellHtml` 的 `__html` 通道，kind 按 `status_error` 布尔映射 bad/ok |
| `tools/tests/unit/status_chip_integration.test.mjs` | 新增 54 行 | 6 用例：真实 chip 元素 / 无 `&lt;span` / 文案 esc / 空状态 / 布尔而非文案 / 空表 |
| `worker/src/lib/web_assets.js` | 2/2 | build 重生成（36 资源 550754 字节） |

## 准出原始输出

```
$ node scripts/build_web_assets.mjs        → 36 个资源，共 550754 字节
$ node scripts/build_web_assets.mjs --check → 与 36 个源文件一致
$ node scripts/check.mjs                   → 通过：0 个问题，2 个提示（T-034/T-040 存量）
                                           任务合计 52 · todo 1 · done 51
$ node scripts/web_size.mjs                → 67.1 KB / 25.1 KB gzip，通过 ≤40KB（余量 14.9）
$ node --test status_chip_integration      → tests 6 / pass 6 / fail 0
$ node --test 全量（root + unit）           → tests 237 / pass 146 / fail 0 / skipped 91 / todo 0
$ wc -l overview_cards.js                  → 168（≤300）
$ node --check overview_cards.js           → exit 0
$ grep -c "text-align" styles-refresh.css  → 0
$ grep -rn -- "--n-h-top" worker/src/web/  → 0 命中
$ grep -rn "statusChip" worker/src/web/tabs/ → 2 命中（import + deviceTable 调用）
```

## 自检

- **业务零改动**：未改 `r.status` / `r.status_error` 取值与字段名，未改 `fmtPct`/`deltaChip`；仅状态列渲染换 `statusChip`。
- **防二次转义**：徽标走 `{ __html: ... }`，`cellHtml` 默认分支不会 esc 到它；集成单测同时断言含真实 `<span class="chip ...">` 且不含 `&lt;span`。
- **sticky**：选择器只写 `.table-block th`，`top:0`，未引用 `--n-h-top`；未新增 `.scroll` DOM；`.pop` 弹层表格不受影响。
- **色值**：新增规则只用 `var(--n-*)` / `color-mix(... var(--n-*))`，tokens.css 未改。
- **禁动清单**：styles.css / tokens.css / index.html / app.js / icons.svg / web_size.mjs / admin_master.js / collect.js / dept.js / tasks.md 零改动；`@media print` 未扩展。
- `styles-refresh.css` `text-align` 计数 0。

## 遗留风险

1. `.table-block` 加了 `max-height:72vh`，所有含长内容的块（含系统配置的表单块）会出现块内纵向滚动，表内 `h3` 会随内容滚出——按卡面「只给 .table-block 加 max-height」的约束实现，若人类不接受可下调或去掉。
2. 表头吸顶用 inset 阴影代替 border-bottom（`border-collapse:collapse` 下吸顶单元格边框不绘制）。
3. 本机无浏览器运行时，sticky/分段控件/胶囊为静态校验，需部署后人工复核。
4. 环境告警：回收站进程本轮移走 9 项 `.git` 内部文件，事后复查 local=origin=9a65e7b、工作区干净；建议人类排查杀毒/同步盘/索引服务，Agent 不得自行恢复。
## 整改（打印媒体样式渗透 · 追加提交 2be9b9b）

| 项 | 值 |
|---|---|
| 分支 / 提交 | `agent/trae/ui-refresh-table` · **2be9b9b**（保留阻断提交 9a65e7b） |
| 分支基座 | `05c265e`（落后 master `fe67b0e`，**未 rebase**） |
| 改动 | 3 文件 +88/-1：`styles-refresh.css` +5/-0、`print_media_guard.test.mjs` 新增 83 行、`web_assets.js` 1/1 |
| 未做 | 未 merge/rebase、未新建分支/worktree、未部署、未改卡状态、未连做其它卡 |

**做法（结构性隔离，非逐条打补丁）**：第 300 行起 T-052 表格段至文件末尾子页签段整体包进 `@media screen { ... }`，原有规则与选择器一字未改（没有重新缩进，diff 仅 5 行新增：2 行说明注释 + `@media screen {` + 收尾 `}` + print 段 1 行注释）；第 1–299 行（含 T-050 `@media print` 与 T-051 规则）零改动。

**新增契约单测** `tools/tests/unit/print_media_guard.test.mjs`（4 用例）：花括号配对算 `@media screen` 作用域区间，断言 `.table-block th` / `position: sticky` / `top: 0`、`.table-block` / `max-height`、`.subtabs` / `.subtab.active` 全部在作用域内且无全局裸露；并断言全文花括号配平、`@media screen` 规则唯一。

**踩坑留痕**：初版用 `css.indexOf('@media screen')` 命中 print 段注释里的文字，区间被算成 `@media print` 块，4 条断言全红；改正则 `/@media screen\s*\{/` 定位实际规则后 4/4 绿。

准出（原始）：

```
build_web_assets.mjs        → 36 个资源，共 551112 字节
build_web_assets --check    → 与 36 个源文件一致
check.mjs                   → 0 个问题，2 个提示（T-034/T-040 存量）；52 卡 done 51 / todo 1
web_size.mjs                → 67.4 KB / 25.2 KB gzip，通过 ≤40KB（余量 14.8）
node --test print_media_guard.test.mjs → tests 4 / pass 4 / fail 0
node --test 全量（root + unit）        → tests 241 / pass 150 / fail 0 / skipped 91 / todo 0
grep -n '@media screen' styles-refresh.css → 3 行（1 条规则 + 2 条说明注释）
grep -c "text-align" styles-refresh.css → 0
grep -rn -- "--n-h-top" worker/src/web/ → 0 命中
grep -rn "statusChip" worker/src/web/tabs/ → 2 命中
```

**注意（合并侧）**：本分支 `app.js` 仍是热修前版本，`web_assets.js` 因此内嵌旧 app.js（预期）；合并时 workbuddy 在合并结果上重跑 `build_web_assets.mjs` 统一解决冲突，**不要在本分支修 app.js**。

**复审待验**：headless Chrome CDP `Emulation.setEmulatedMedia(print)` 复测 7 项计算样式（max-height / box-shadow / th position+top / th background / th color / th box-shadow / 偶数行 background）须与基线完全一致；屏幕端表头吸顶、斑马纹、hover、分段控件外观应与整改前一致。