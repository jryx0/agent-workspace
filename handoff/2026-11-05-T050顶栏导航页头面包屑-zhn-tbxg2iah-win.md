# 交接单 · T-050 顶栏 + 导航 + 页头 + 面包屑

| 项 | 值 |
|---|---|
| 卡号 | T-050 |
| 标题 | 顶栏 + 导航 + 页头 + 面包屑 |
| 执行 agent | trae @ zhn-tbxg2iah-win |
| 时间 | 2026-11-05 18:52 UTC+8 |
| 基座 | origin/master **ff19318**（T-049b 已合并收官） |
| 分支 | `agent/trae/ui-refresh-topbar` |
| worktree | `C:/Users/Zhn_X/source/prnmgt.wt/trae-ui-topbar` |
| 提交 | **cace75a**（单提交，5 文件 +207/-14，`Agent: trae` trailer） |
| 推送 | 已推 origin；复查 local = origin = cace75a，status 干净，remote -v 正常 |
| 状态 | 等 workbuddy 审核合并；**未合 master、未部署、未连做 T-051** |
| 卡状态 | 未改（收官由审核人做） |

## 一、改动清单

| 文件 | 行数 | 内容 |
|---|---|---|
| `worker/src/web/styles-refresh.css` | +172/-7 | 顶栏 / 导航 / 右侧身份区 / 页头 + 面包屑 / 自写 @media print |
| `worker/src/web/index.html` | +1/-1 | `.brand__dot` 内加「印」（品牌块由纯圆点改为圆角方块字标） |
| `worker/src/web/app.js` | +14/-2（净 16 行） | `HEAD` + `headOf()`；route 内插入页头并改用 `.view-body` 渲染根 |
| `worker/src/web/icons.svg` | +16 | 新增 i-up / i-down / i-crumb / i-refresh 四个 symbol |
| `worker/src/lib/web_assets.js` | +4/-4 | build 重生成（36 资源 545453 字节），未手改 |

说明：卡列 3 文件，exec-prompt 另要求 icons.svg，按 4 个源文件做（4 < 5 红线）。

### 关键实现

- **顶栏**：`linear-gradient(135deg, var(--n-topbar-a), var(--n-topbar-b))`，内层 `min-height:56px`（**字面量，未引用 `--n-h-top`**）。不做侧边栏。
- **导航**：`.tab` 胶囊（8px 圆角）+ 选中 `color-mix(in srgb, var(--n-topbar-ink) 16%, transparent)` 半透明底 + `::after` 20×2 亮线（`var(--c-primary-light)`）+ hover 10% 底。`.tabs` 的 `overflow-x:auto` 保留、未改 flex-wrap；「系统配置▾」仍在 `.tabs` 外的 `.tab-master-wrap`（负边距归 0）。
- **角色徽标**：未改 `paintIdentity` 输出，CSS 把 `#whoami b` 渲染成 10.5px chip（warning 30% 底 + 顶栏白字）。
- **页头 + 面包屑**：app.js 生成 `<div class="page-head">`（左：面包屑 + h2 + 副标题；右：`.page-head__ops` 刷新按钮），插入 `#view` 内、tab 内容之前；tab 内容放进新建的 `.view-body` 容器后交给 `mod.render(body, …)`。
- **打印**：`styles-refresh.css` 末尾自写 `@media print { .crumb, .page-head { display:none !important } }`；`styles.css` 及其 A4 横向 26 行基线零改动。

## 二、准出原始输出

```
$ node scripts/check.mjs
任务合计 52 · todo 3 · doing 0 · blocked 0 · done 49
通过：0 个问题，2 个提示
（2 提示为 T-034 / T-040 存量）

$ node scripts/build_web_assets.mjs --check
web_assets.js 与 36 个源文件一致

$ node scripts/web_size.mjs
合计 63.1 KB / 23.9 KB gzip
通过：首屏 gzip 23.9 KB ≤ 40.0 KB（余量 16.1）
（styles-refresh.css 5.9 KB / 2.3 KB gzip；icons.svg 2.9 KB / 1.0 KB gzip；app.js 13.3 KB / 6.1 KB gzip）

$ wc -l worker/src/web/app.js
294 worker/src/web/app.js          （≤ 300；diff 净 16 行 ≤ 18）

$ node --check worker/src/web/app.js
（无输出，exit 0）

$ node --test tools/tests/*.test.mjs tools/tests/unit/*.test.mjs
# tests 224 · pass 133 · fail 0 · skipped 91
```

补充 grep（红线）：

```
--n-h-top 引用（web/*.css,*.html,*.js）        → 0
sidebar / .rail / aside（index.html + 新 CSS） → 0
```

## 三、自检

- **业务零改动**：仅 `web/` 的 CSS / HTML / 展示层 JS；`tabs/**`、`lib/**`、API、字段名、统计口径、取值逻辑全未动；无 `worker/src/modules/**` 改动。
- **色值只在 tokens.css**：新 CSS 仅 `var(--…)` 与 `color-mix(in srgb, var(--…), transparent)`，无 `#hex / rgb() / hsl()`；check.mjs 0 问题。
- **app.js 未超 300**：294 行；diff +14/-2（合计 16 行 ≤ 18）。
- **打印稿基线未动**：`styles.css` 零改动（含其 `@media print` 段）；仅新文件自写隐藏规则。
- **无侧边栏 DOM**：index.html 结构不变，仅 brand dot 文本；无 sidebar/rail/aside。
- **无 emoji / 无框架 / 无新依赖**；生成物由 build 产出。

## 四、遗留风险

1. **渲染根变了**：`mod.render` 的 root 从 `#view` 变为内层 `.view-body`。已 grep 12 个 tab 模块，确认只用 `root.innerHTML` / `root.querySelector*`，无 `root.id` / `parentElement` / `className` 依赖；但**未做浏览器运行时验证**（本机无 dev server，卡验收未要求）。合并后建议人类部署一次逐个 tab 点一遍。
2. **页头刷新按钮**：绑 `route(true)`，复用既有 retry 导入路径（不新增 API、不改口径）。若审核认为这算「改数据流」，删掉绑定那 1 行即可（按钮变纯展示）。
3. **admin 子页标题不随 sub 变**：面包屑/大标题按 tab 粒度写死（系统配置），子页切换不更新；如需按子页细分要再改 app.js（会超 18 行预算）。
4. **i-up / i-down 本卡未使用**：为 T-051 涨跌片预置，不影响当前渲染。
5. **环境告警**：回收站进程本轮再移 10 项 `.git` 内部文件（`config`、分支 ref、worktree `index`/`HEAD.lock`/`AUTO_MERGE.lock`、`packed-refs.lock`、`maintenance.lock`）。push 已完成且复查 local = origin = cace75a、remote -v 正常、工作区干净；**建议人类排查杀毒 / 同步盘 / 索引服务**。Agent 不得自行从回收站恢复。
6. **下一步（T-051）**：基于合并后的 master 开工；涨跌色用 `--n-up-ink` / `--n-down-ink`，图标现在已有 i-up / i-down；顶栏高度仍不要引用 `--n-h-top`（未定义）。
