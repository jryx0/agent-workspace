# 交接单 · T-053 热修 · 页头刷新属性笔误致全 tab 白屏

| 项 | 值 |
|---|---|
| 卡号 | T-053（生产热修，优先级高于阻断中的 T-052） |
| 执行 agent | trae @ zhn-tbxg2iah-win |
| 时间 | 2026-11-06 10:04 UTC+8 |
| 基座 | origin/master **4081a7e** |
| 分支 / 提交 | `agent/trae/hotfix-page-head` · **95cd461**（已推 origin） |
| worktree | `C:/Users/Zhn_X/source/prnmgt.wt/trae-hotfix-head` |
| 状态 | 待 workbuddy 复审（headless Chrome CDP 实测）；未合 master、未部署、未改卡状态、未连做其它卡 |

## 改动（3 文件 +39/-3）

| 文件 | 行数 | 内容 |
|---|---|---|
| `worker/src/web/app.js` | 2/2 | :56 `data-head-refresh">` → `data-head-refresh>`；:136 绑定加可选链 `?.`（行数仍 294） |
| `tools/tests/unit/page_head_refresh.test.mjs` | 新增 36 行 | 4 条纯文本契约：属性名合法、模板内唯一、绑定判空、回调仍 `location.reload()` |
| `worker/src/lib/web_assets.js` | 1/1 | build 重生成（36 资源 548483 字节） |

根因：`data-head-refresh"` 属性名末尾多一个双引号 → 浏览器解析出的属性名带引号 → `[data-head-refresh]` 恒 null → :136 对 null 调 addEventListener 抛 TypeError → 该行在 try/catch 之外且在 `mod.render` 之前 → route 中断、内容区全空（全站白屏）。

## 准出原始输出

```
$ node scripts/build_web_assets.mjs        → 36 个资源，共 548483 字节
$ node scripts/build_web_assets.mjs --check → 与 36 个源文件一致
$ node scripts/check.mjs                   → 通过：0 个问题，2 个提示（T-034/T-040 存量）
$ node scripts/web_size.mjs                → 65.0 KB / 24.3 KB gzip，通过 ≤40KB（余量 15.7）
$ node --test page_head_refresh.test.mjs   → tests 4 / pass 4 / fail 0
$ node --test 全量（root + unit）           → tests 235 / pass 144 / fail 0 / skipped 91 / todo 0
$ node --check app.js                      → exit 0
$ wc -l app.js                             → 294（≤300）
$ grep -n data-head-refresh app.js         → :56 data-head-refresh>  /  :136 [data-head-refresh]'）?.addEventListener
```

## 自检

- 只改允许的 3 个文件；未动 `tasks.md` / `styles.css` / `tokens.css` / `styles-refresh.css` / `index.html` / `lib.js` / `tabs/*.js` / `scripts/*` / `@media print`。
- 未动 T-052 分支（`agent/trae/ui-refresh-table`），未 rebase/合并它。
- 未合 master、未部署、未改卡状态、未连做其它卡。
- `web_assets.js` 由 build 生成，无手改。

## 遗留风险

1. 静态契约测试只能证明文本层正确，DOM 属性解析与 `.view-body` 业务骨架须由 workbuddy 用 headless Chrome CDP 实测。
2. `master 05c265e`（即当前 4081a7e 的前代）与 `agent/trae/ui-refresh-table` 仍带该缺陷，本卡合并部署前任何一版上线都会白屏，须先合本卡。
3. 环境告警：回收站进程本轮移走 14 项 `.git` 内部文件（worktree index/index.lock、分支 ref、packed-refs.lock 等），事后复查 local=origin=95cd461、工作区干净；建议人类排查杀毒/同步盘/索引服务，Agent 不得自行恢复。