# 交接单 · T-054 总览「按部门统计」增加合计行

| 项 | 值 |
|---|---|
| 卡号 | T-054（v2 批次首张，ADR-0010 ACCEPTED 后解锁） |
| 执行 agent | trae @ zhn-tbxg2iah-win |
| 时间 | 2026-11-06 11:51 UTC+8 |
| 基座 | origin/master **e01955d**（只比 0ce10d4 多 1 个文档提交，前端与线上一致） |
| 分支 / 提交 | `agent/trae/dept-total` · **054b71c**（已推 origin） |
| worktree | `C:/Users/Zhn_X/source/prnmgt.wt/trae-dept-total` |
| 状态 | 待 workbuddy 复审（实测 import deptTable + CDP）；未合并、未部署、未改卡面、未连做其它卡 |

## 改动（3 文件 +66/-2）

| 文件 | 行数 | 内容 |
|---|---|---|
| `worker/src/web/tabs/overview_dept.js` | +16/-1（145→160） | deptTable 首部口径说明 `<p class="muted ov-dept-note">`；tbody 末尾追加普通 `<tr>` 合计行（序号空 / 部门「合计」/ 6 个数值列求和 / 4 个百分比列「—」），空数组不加 |
| `tools/tests/unit/dept_total.test.mjs` | 新增 49 行 | 4 用例：合计行唯一 + 求和 + 列序、无 `<b>`/`<tfoot>`、口径说明、空数组 |
| `worker/src/lib/web_assets.js` | 1/1 | build 重生成（36 资源 552204 字节） |

合计行样式为纯 `<tr class="num">`，未加任何 CSS；`@media print` 与 `.table-block` 规则零改动（T-052 的 `@media screen` 隔离不受影响）。

## 准出原始输出

```
$ node scripts/build_web_assets.mjs        → 36 个资源，共 552204 字节
$ node scripts/build_web_assets.mjs --check → 与 36 个源文件一致
$ node scripts/check.mjs                   → 通过：0 个问题，2 个提示（T-034/T-040 存量）
                                             任务合计 58 · todo 5 · done 53
                                            check EXIT=0
$ node scripts/web_size.mjs                → 67.4 KB / 25.2 KB gzip，通过 ≤40KB（余量 14.8）
$ node --test dept_total.test.mjs          → # tests 4 / # pass 4 / # fail 0
$ node --test 全量（root + unit）           → # tests 249 / # pass 158 / # fail 0 / # skipped 91 / # todo 0
                                            EXIT=0
$ node --check overview_dept.js            → EXIT=0 ；wc -l → 160（≤300）
```

## 实现口径

- 合计覆盖 `by_department` **全部行，含「未分配」**，未按部门过滤。
- 数值列：账号数 / 累计合计 / 本年至今 / 本月 / 本季度 / 年增长 = 各列 Σ（`Number(...) || 0` 兜底 null）。
- **列序锁定**：第 6 列是「本月」、第 7 列是「本季度」，与表头 `<thead>` 一致，单测用整行精确字符串锁死。
- 四个百分比列写「—」：部门表由前端 `pct()` 从 `*_total` 与 `*_last/*_prev` 重算，合计行没有对应基期，不做「平均同比」。
- 合计行不加 `dept-trend-pop` / `dept-acc-pop` 悬浮包装（避免无 `data-dept` 的占位触发空弹层），仅纯文本数字。

## 自检 / 风险

- 未改 CSS（含 `styles-refresh.css`、`@media print`）、后端 / SQL / 字段名、`overview_cards.js`、`app.js`、`index.html`、`tokens.css`、`collector/`；合计值未取 `cards.*`。
- 新增 `<p class="muted">` 会出现在打印稿（表格上方多一行说明）；本卡按任务要求添加，若人类要求打印时隐藏，需另开卡改 `@media print`（本卡禁改）。
- 未在浏览器验证（本机无浏览器运行时），需 workbuddy CDP 复核屏幕端与打印端。
- 环境：回收站进程本轮移走 8 项 `.git` 内部文件（含分支 ref、worktree index/HEAD.lock、packed-refs.lock），事后复查 local=origin=054b71c、工作区干净；建议人类排查杀毒/同步盘/索引服务。