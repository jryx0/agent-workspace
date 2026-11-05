# 交接单 · T-049b 石墨灰配色落地

| 项 | 值 |
|---|---|
| 卡号 | T-049b |
| 标题 | 石墨灰配色落地 |
| 执行 agent | trae @ zhn-tbxg2iah-win |
| 时间 | 2026-11-05 17:58 UTC+8 |
| 基座 | origin/master **f6a12ec**（T-049 已合并收官） |
| 分支 | `agent/trae/ui-refresh-color` |
| worktree | `C:/Users/Zhn_X/source/prnmgt.wt/trae-ui-color` |
| 提交 | **e992398**（单提交，2 文件 +41/-15，`Agent: trae` trailer） |
| 推送 | 已推 origin；复查 local = origin = e992398，工作区干净 |
| 状态 | 等 workbuddy 审核合并；**未合并 master、未部署、未连做 T-050** |
| 卡状态 | 未改（收官由审核人做） |

## 一、改动清单

| 文件 | 行数 | 说明 |
|---|---|---|
| `worker/src/web/tokens.css` | +41/-15 | 唯一源文件改动：改 8 个 `--c-*` 值、新增 14 个变量、头注释改写、订正计数 |
| `worker/src/lib/web_assets.js` | +1/-1 | 由 `node scripts/build_web_assets.mjs` 生成（36 资源 538620 字节），未手改 |

### 1. 改 8 个既有值（diff 内 `--c-*` 恰好 8 组 -/+）

| 变量 | 旧值 | 新值 |
|---|---|---|
| `--c-primary` | `#2c5aa0` | `#425466` |
| `--c-primary-dark` | `#22497f` | `#333f4d` |
| `--c-primary-light` | `#6fb3e8` | `#9dabbc` |
| `--c-primary-soft` | `#3a6cb4` | `#55677a` |
| `--c-header` | `#24466f` | `#303b48` |
| `--c-th` | `#2f5a94` | `#425466` |
| `--c-select` | `#d5e5f8` | `#d9e0e8` |
| `--c-hover` | `#e9f1fb` | `#eef1f5` |

### 2. 未改 17 个（逐项核对，均未出现在 diff）

`--c-bg`、`--c-card`、`--c-zebra`、`--c-input-bg`、`--c-border`、`--c-text`、`--c-text-2`、`--c-text-muted`、`--c-danger`、`--c-warning`、`--c-success`、`--c-r-ctl`、`--c-r-card`、`--c-r-dialog`、`--c-shadow-card`、`--c-shadow-dialog`、`--c-ring`（含 danger/warning/success 语义色跨方案一致）。

### 3. 新增 14 个（逐字抄 `docs/ui-refresh/exec-prompt.md` 附录 A2）

品牌语义 8：`--n-brand #425466`、`--n-brand-strong #333f4d`、`--n-on-primary #ffffff`、`--n-topbar-a #303b48`、`--n-topbar-b #425466`、`--n-topbar-ink #ffffff`、`--n-chart-prev #cdd3da`、`--n-ring 0 0 0 3px rgba(66,84,102,.16)`。

语义 ink 6：`--n-danger-ink #c23a34`、`--n-warn-ink #945d00`、`--n-ok-ink #2b794f`、`--n-up-ink #c23a34`、`--n-down-ink #2b7a4f`、`--n-danger-solid #c23a34`。

### 4. 头注释改写（旧原话已删除）

```
25 个变量中 17 个逐字抄自 ref/legacy-worker/query_page.js 的 :root 段，未改动。
主色系 6 项 + 交互态底色 2 项于 2026-11-05 经人类决策变更（配色改为石墨灰），
其余 17 项（含语义功能色 danger/warning/success）保持原值不变。
```

### 5. 顺带订正 T-049 遗留计数

A1 实为 **23 个**（中性 15 + 圆角 3 + 阴影 3 + 涨跌 2），原注释写 24/16，已在段尾与段首同步订正（T-049 审核记录已登记该偏差）。

## 二、准出原始输出

### 1. `node scripts/check.mjs`

```
通过：0 个问题，2 个提示
（2 提示为 T-034 / T-040 存量；任务 52 / doing 0 / done 48 / todo 4）
```

### 2. `node scripts/web_size.mjs`

```
tokens.css   5.3 KB / 2.7 KB gzip
合计 gzip 21.8 KB ≤ 40 KB（余量 18.2 KB）
```

### 3. `node scripts/build_web_assets.mjs --check`

```
web_assets.js 与 36 个源文件一致
```

### 4. 卡验收两条 grep

```
grep -c "var(--ring)" worker/src/web/styles-refresh.css   → 0
grep 旧头注释原话 "25 个变量的值逐字抄自旧页"            → 无匹配
```

（说明：`styles.css` 内 2 处旧 `var(--ring)` 与 `tokens.css` 的 `:focus-visible` 属既有基线，按卡要求不动。）

### 5. 16 个关键 token 校验

```
OK 16 个关键 token 全部符合
exit 0
```

（8 个改了 + 8 个没改，两头锁死；另校验 `--n-ring` 存在。脚本原为 `node -e`，因双引号 shell 吞反斜杠，改写为临时 `.mjs` 后执行。）

### 6. 全量回归

```
224 项  pass 133 / fail 0 / skip 91
```

（skip 91 = 缺 `tools/mirror/out/legacy-all.json` 基线，与合并前一致；fail 0。）

## 三、自检

- **17 个未改 token**：逐项核对，diff 中零出现（含 danger/warning/success）。
- **头注释**：含决策日期 `2026-11-05` 与授权来源「经人类决策变更」，旧原话无残留。
- **生成物**：`web_assets.js` 仅由 `build_web_assets.mjs` 产出，`--check` 一致。
- **打印稿与业务零改动**：`@media print` 未动；未改任何 `.js` 业务源码 / API / 字段名 / 统计口径 / 取值逻辑；`styles.css`、`styles-refresh.css` 未动。
- **规范动作**：4 列认领行（doing → 已追加 done 完成行在 memory）、`Agent: trae` trailer、`git -c` 一次性署名、带任务名 worktree、未合 master、未部署。

## 四、遗留风险

1. **`--n-h-top` 仍未定义** —— 仅出现在效果图 `docs/ui-refresh/mockup.html` 的自定义值里，不在 A1/A2 清单。**T-050 落地顶栏若引用它，必须先补定义**，否则 `var(--n-h-top)` 静默失效（无报错）。
2. **本卡会改变线上外观** —— 顶栏/表头/链接/选中/hover 变石墨灰。T-049 是零可见变化，T-049b 是第一次真变色。建议本卡合并后由人类**部署一次**再进 T-050，避免多卡累积后一次性排障。
3. **环境告警（未解决）** —— 本轮回收站进程再次连移 10+ 项 `.git` 文件（`config`、分支 ref、worktree 的 `index`/`HEAD.lock`/`AUTO_MERGE.lock`、`packed-refs.lock` 等）。push 已完成且事后复查 local = origin = `e992398`、`remote -v` 正常、`status` 干净，但**强烈建议人类排查杀毒 / 同步盘 / 索引服务**。Agent 不得自行从回收站恢复。
4. **方案文档计数与死链** —— `docs/ui-refresh/exec-prompt.md` 附录 A1 标题仍写「24 个 token」（实为 23 个），会话工作区路径仍有死链，待编制会话订正（非本卡范围）。

## 五、下一卡

T-050（顶栏/侧栏组件层）基于 `origin/master` 合并后的新 HEAD 开工；开工前先补 `--n-h-top` 定义（或改用它名），并确认本卡已部署过一次。
