# 2026-11-05 T-049 基础层 token 与基础样式 · zhn-tbxg2iah-win（trae）

## 交接要素速览

| 项 | 内容 |
|---|---|
| 当前状态 | 代码完成、四条准出全绿、分支已推 origin；**待 workbuddy 审核**（未合 master、未部署、未连做 T-049b） |
| 分支 / 提交 | `agent/trae/ui-refresh-base` · 单提交 **`5c10e31`**（基于 origin/master `d42d647`） |
| worktree | `~/source/prnmgt.wt/trae-ui-base`（保留待审核后清理） |
| 关键文件 | `worker/src/web/tokens.css`、`worker/src/web/styles-refresh.css`（新增）、`scripts/web_size.mjs`、`worker/src/web/index.html`、`worker/src/lib/web_assets.js`（生成物） |
| 下一步 | workbuddy 审核 5 文件 diff + 亲跑四条准出 → 合并 → T-049 收官；随后指派 T-049b（品牌色落地，改 8 个 `--c-*` 值 + 新增 14 token） |

## 一、改动文件清单（5 文件，+109/-5）

| 文件 | 改动 | 一句话 |
|---|---|---|
| `worker/src/web/tokens.css` | +47/-0 | 追加 24 个 `--n-*` 基础 token（中性 16 / 圆角 3 / 阴影 3 / 涨跌 2）；既有 25 个 `--c-*` 零增删零改值 |
| `worker/src/web/styles-refresh.css`（新增） | +52 | 仅基础层：`.page-head` / `.page-head__title` / `.page-head__sub` 骨架、`.app-footer`、`.u-row`/`.u-push`/`.u-nowrap`/`.u-tnum`；无组件样式、无 @media print、无硬编码色值 |
| `scripts/web_size.mjs` | +1/-1 | `FIRST_SCREEN` 白名单插入 `styles-refresh.css`（体积门禁真正计入） |
| `worker/src/web/index.html` | +3/-2 | `<head>` 在 `styles.css` 后挂 `styles-refresh.css`；注释「两个样式表」→「三个样式表」 |
| `worker/src/lib/web_assets.js` | +6/-3 | 由 `node scripts/build_web_assets.mjs` 生成（36 资源 537082 字节），未手改 |

## 二、准出原始输出（四条）

### 1. `node scripts/check.mjs`

```
任务合计 52 · todo 4 · doing 0 · blocked 0 · done 48
OK  路由 42 个 /api 路径，与契约一致
OK  路由表 44 条，与契约逐条对齐（路径/方法/鉴权）
最大文件 worker/src/mcp.js · 299 行
OK  web 资源 34 个 · emoji 0
--------------------------------------------------------
! specs/0001-prnmgt-refactor/tasks.md: T-034 改动范围含 9 个文件，超过 5 个建议拆卡
! specs/0001-prnmgt-refactor/tasks.md: T-040 改动范围含 7 个文件，超过 5 个建议拆卡
通过：0 个问题，2 个提示
```

### 2. `node scripts/web_size.mjs`

```
首屏资产                  原始         gzip
--------------------------------------------
index.html            2.8 KB     1.4 KB
tokens.css            3.8 KB     2.1 KB
styles-refresh.css    1.5 KB     0.9 KB
styles.css           32.8 KB    10.3 KB
icons.svg             2.0 KB     0.8 KB
app.js               12.0 KB     5.6 KB
--------------------------------------------
合计                   54.9 KB    21.2 KB
预算：gzip 40.0 KB，余量 18.8 KB

通过：首屏 gzip 21.2 KB ≤ 40.0 KB
```

（`styles-refresh.css` 已单列一行 → FIRST_SCREEN 白名单生效；较 T-048 基线 19.7KB 增 1.5KB）

### 3. `node scripts/build_web_assets.mjs --check`

```
web_assets.js 与 36 个源文件一致
```

（生成命令原始输出：`已生成 worker/src/lib/web_assets.js：36 个资源，共 537082 字节`；worktree 检出为 LF，`index.html` CR 数 = 0，无 CRLF 假差异）

### 4. `node --check worker/src/lib/web_assets.js`

```
（无语法输出，exit 0；仅 Node 自带 MODULE_TYPELESS_PACKAGE_JSON 性能提示，与本卡无关）
```

> 注：提示词写的是 `worker/src/web/lib/web_assets.js`，该路径不存在；实际生成物为 `worker/src/lib/web_assets.js`（build 脚本写入位置）。

## 三、自检（四条红线）

| 项 | 结论 | 证据 |
|---|---|---|
| 业务逻辑零改动 | ✅ | `git diff --stat` 仅 5 文件；无 `worker/src/modules/**`、`worker/src/lib/**`（生成物除外）、`collector/`、`schema.sql` 改动；无任何 .js **源**文件改动 |
| 色值只在 tokens.css | ✅ | `styles-refresh.css` grep `#hex\|rgb(\|hsl(` 只命中文件头注释里的「禁止」说明文字，无实际色值；全部用 `var(--n-*)` |
| 行数红线 | ✅ | 未触碰 `app.js`(282)/`lib.js`(231)/`tabs/**`；`styles-refresh.css` 52 行；`worker/src/lib/web_assets.js` 为生成物 |
| 打印稿未动 | ✅ | `styles.css` 零改动；`styles-refresh.css` 无 `@media print`（grep `print` 仅命中注释第 3 条说明） |

补充：既有 25 个 `--c-*` token —— `tokens.css` diff 为 **+47/-0**（纯追加），无一行删除或修改。

## 四、遗留风险

1. **本卡零可见变化**：`.page-head*` / `.app-footer` / `.u-*` 目前没有任何 DOM 引用者，链接新样式表后线上外观与现版一致——符合「基础层」定位，视觉变化从 T-049b（品牌色）与 T-050（顶栏/导航/页头）开始。审核时不要以「截图看不出变化」判失败。
2. **T-049b 落地前不要删 `--n-*`**：24 个 token 里涨跌两色（`--n-up #c33a34` / `--n-down #2c7d51`）与 ink 系列将在 T-051 的 `deltaChip` 消费，提前删除会连带改组件卡。
3. **`check.mjs` 的「web 资源 34 个」与 build 的「36 个源文件」口径不同**（前者只统计特定扩展名），非本卡引入的不一致，无需处理。
4. **环境告警（持续）**：本机回收站进程本轮一次移走 10 个 `.git` 文件（含 `config`、`refs/heads/agent/trae/ui-refresh-base`、worktree 的 `index`/`HEAD.lock`/`AUTO_MERGE.lock`、`packed-refs.lock`、`objects/maintenance.lock`）。push 已完成，事后复查 local/remote ref 均为 `5c10e31`、`git remote -v` 正常、工作区干净。强烈建议排查杀毒软件 / 同步盘 / 索引服务。

## 五、后续（非本会话）

- workbuddy 审核 → 合并 `agent/trae/ui-refresh-base` → T-049 收官（卡状态由审核人改，本会话未动 `tasks.md`）
- 人类部署后浏览器复核：`<head>` 三条 stylesheet、Network 面板可见 `/assets/styles-refresh.css` 200
- 下一卡 **T-049b**（品牌色落地：改 8 个 `--c-*` 值 + 新增 14 token）——**本会话不连做**
