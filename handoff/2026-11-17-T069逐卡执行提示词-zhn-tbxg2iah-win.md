# T-069 逐卡执行提示词 · 报表页费用选择改为弹窗（APPROVED · 可投喂）

> 自包含任务书，**可直接全文复制投喂执行 Agent（trae）**，无需回看历史对话。
> 编制：workbuddy@zhn-tbxg2iah-win · 2026-11-17 11:3x +08
> 卡面：`~/source/prnmgt/specs/0001-prnmgt-refactor/tasks.md` 的 **T-069**（`状态: todo`，依赖已满足）
> 立项依据：`docs/adr/0013-cost-report-links.md`（ACCEPTED）、`docs/decisions/OPEN-DECISIONS.md` **#20 RESOLVED**、`BOARD.md` 2026-11-17 条目、`spec.md` 人类豁免登记 3
> 分工（全局规范 **v2.7** 三-7）：workbuddy 编卡 / 复审 / 合并收官；**执行 Agent 编码，一律不得部署、不得执行 `wrangler d1 execute` / `wrangler deploy`**；现网 DDL 与全部部署由人类本人执行。

---

## 零、开工前必须确认（任一项不满足即停下报告）

1. 读 `~/.agent-shared/global/rules.md`（现行 **v2.7**）并执行第八节自检 —— **10 步**（平台旧指令写「9 步」已过时）；同一 agent 的不同会话同样适用（三-5 ⑦）。
2. **按三-1 多项目加载**：读 `~/.agent-shared/handoff/` **最新一份** handoff 的「挂起任务（当前全量快照）」；再按项目补读 prnmgt 最近一份带 `项目:` 标签的 handoff。`org.md` 只读最近 200 行。
3. **挂起快照（防撞集合含 `suspended`）**：**S1**（T-059/T-060/T-061）、**S2**（P0 二次真机调研）、**S3**（v4 / #18）**仍 suspended，一律不得认领／开工**。S4（T-064）已 `done`，不计入防撞集合。本卡 T-069 是 v6 独立批次，**不构成 v4 开工令**。
4. 按 `AGENTS.md` 必读顺序读：`constitution.md` → `BOARD.md` → `specs/0001-prnmgt-refactor/spec.md` → `tasks.md` 的 **T-069 卡面** → `docs/decisions/OPEN-DECISIONS.md` #20 → `docs/adr/0013-cost-report-links.md` → 本提示词。
5. **认领登记（三-5 ⑤）**：查 `~/.agent-shared/memory/projects/prnmgt.md` 任务登记节，确认 T-069 未被他人认领（doing/open/suspended），然后**追加一行** `【任务认领】T-069 | 报表页费用选择改为弹窗 | trae | doing`（append-only，禁止改旧行）。该文件可能仍有 trae 自己的历史未提交追加行（T-058 调研段等）—— **不改写、不代提交、不强行 rebase**。
6. **基座判据（不写死 hash）**：`git fetch origin` 后实测 `git rev-parse origin/master` 与本地 HEAD 一致，把实测号写入交付报告；以**认领时刻的 `origin/master`** 为基座建 worktree，并逐项核验 T-065~T-067 已合入：
   ```bash
   git show origin/master:worker/schema.sql | grep -n "report_links"                 # 期望 ≥1 处
   git cat-file -e origin/master:worker/migrations/20261117_cost_report_links.sql    # 期望存在
   git show origin/master:worker/src/modules/costs.js | grep -n "report_links"       # 期望存在（列表接口带出）
   git show origin/master:worker/src/web/tabs/costs.js | grep -n "report-links"      # 期望存在（费用记录只读列）
   ```
   四项任一不满足即停下报告。
7. **worktree 隔离**：新建 `~/source/prnmgt.wt/trae-t069` + 分支 `agent/trae/T-069`。主仓 `~/source/prnmgt` 里已有的其它 worktree 与既有未跟踪项（`.login-out.txt`、`docs/paper/**`、`docs/plan-*`、`tmp/`）**不触碰、不提交**。
8. **不改卡面**：`tasks.md` 的 `状态` 由 workbuddy 收官订正（沿用 T-063~T-067 同口径：执行方只在共享记忆登记 `doing`，不改 `tasks.md`）；执行方不自报 done、不合并 master、不改任何治理文档（见第六节禁动清单）。
9. 提交用一次性署名 `git -c user.name=zhn-trae -c user.email=trae@zhn-tbxg2iah-win commit -m "..." -m "Agent: trae"`；推分支到 origin 后**停下等 workbuddy 复审**。追加修正用**新提交，不 amend**。
10. **本卡纯本地前端编码与测试**：不连现网 D1、不执行 `wrangler d1 execute` / `wrangler deploy`、不改采集服务器任何配置。**注意：现网 `costs` 表仍无 `report_links` 列**（v5 代码已合并但未部署），本卡不得据此断定「已上线」，也不得自行跑 DDL。
11. CRLF：项目仓 `core.autocrlf=false`，以**纯 LF 沙盒 `git archive` 导出**跑门禁；改动文件 CRLF 必须为 0，`web_assets.js` 等生成物不得手改（见第四节）。

---

## 一、做什么（严格 4 文件白名单，超出即停下请示）

| # | 文件 | 改动 |
|---|---|---|
| 1 | `worker/src/web/tabs/report_costpop.js` | 由「按钮 + 绝对定位面板 + DOM 勾选」改为「按钮 + 模态 dialog + applied/draft 双集合」；6 个导出签名不变 |
| 2 | `worker/src/web/tabs/report.js` | 模板里删掉 `#rp-cost-pop` 面板节点（保留 `#rp-cost-wrap` 与 `#rp-cost-btn`）；`applySelectedCost()` 一行不改 |
| 3 | `worker/src/web/styles.css` | 删 `.cost-pop`，新增 `dialog.cost-dlg` 一族；`@media print` 清单把 `.cost-pop` 换成 `dialog.cost-dlg` |
| 4 | `worker/src/lib/web_assets.js` | **由 `node scripts/build_web_assets.mjs` 生成，禁止手改** |

**本卡不新增任何 `/api/*` 路径**，不改 `routes.js` / `fixtures/routes.json` / `api_contract.mjs` 判据，不动后端与 DDL。

**不得改**：`worker/src/modules/report.js` / `worker/src/modules/costs.js` / `worker/src/lib/cost_links.js` / `worker/src/web/tabs/report_saved.js` / `worker/src/web/tabs/costs.js` / `worker/src/web/lib.js` / `worker/schema.sql` / `worker/migrations/**` / `app.js` / `index.html` / `lib/diff.js` / `lib/util.js` / `lib/paper_calc.js` / `collector/**` / `BOARD.md` / `tasks.md` / `constitution.md` / `spec.md` / `OPEN-DECISIONS.md` / `docs/adr/**` / 现网 D1 与线上服务。**一次只做一张卡**。

---

## 二、现状（改造前，已只读核实）

`worker/src/web/tabs/report_costpop.js` 现 89 行，6 个导出：

| 导出 | 现实现 |
|---|---|
| `rpCostIds()` | 从 `pop.querySelectorAll("input[type='checkbox']:checked")` 读 `data-cid` |
| `selectedCostRows()` | 按 `cache.costs` 顺序过滤出选中行 |
| `rpCostBtnText()` | 按钮文案「费用记录：N 条（日期、日期）」/「费用记录：— 请选择 —」 |
| `rpCostPopClose()` | `pop.style.display = "none"` |
| `loadReportCostOptions()` | `api("/api/costs")` → 拼 `<label class="cost-opt"><input type="checkbox">` → `pop.innerHTML` |
| `initCostPop(root, apply)` | 按钮 click 开合 + `pop` change 回调 + `document` 级外部点击关闭（`docBound` 单次绑定） |

`report.js` 模板（:237-247）：
```html
<div class="toolbar">
  <span class="muted" style="font-weight:bold">费用与导出</span>
  <span id="rp-cost-wrap" class="cost-wrap">
    <button id="rp-cost-btn" class="btn btn--ghost cost-btn" type="button">费用记录：— 请选择 —</button>
    <div id="rp-cost-pop" class="cost-pop" style="display:none"></div>   <!-- 删掉这一行 -->
  </span>
  ...
```

`report.js:97-110` 的 `applySelectedCost()` **零改动**（它只调 `rpCostIds()` / `rpCostBtnText()` / `renderReport()`）。

---

## 三、怎么改（实现骨架，照此落地）

### 3.1 模块私有状态

```js
let dlg = null;            // dialog.cost-dlg
let applied = new Set();   // 已提交的 id（rpCostIds 读它）
let draft = new Set();     // 草稿 id（勾选只改它）
let showLinked = false;    // 「显示已关联保存报表的记录」开关
let onApply = null;
```

### 3.2 6 个导出签名一字不改，内部语义调整

| 导出 | 改为 |
|---|---|
| `rpCostIds()` | `Array.from(applied)`（原读 DOM 勾选 → 读集合） |
| `selectedCostRows()` | 不动（仍按 `cache.costs` 顺序过滤） |
| `rpCostBtnText()` | 不动（仍读 `selectedCostRows()`） |
| `rpCostPopClose()` | `if (dlg) dlg.close()`（**保留导出名**，`report.js` 的 import 不改） |
| `loadReportCostOptions()` | 拉 `/api/costs` → 存 `cache.costs` → `renderDlgBody()`（不再写 `pop.innerHTML`）；失败不抛错 |
| `initCostPop(root, apply)` | 绑 `#rp-cost-btn` 开框 + `onApply = apply`；删除 `docBound` 与 `document` 级外部点击监听 |

### 3.3 三按钮状态机

- **确认**：`applied = new Set(draft); dlg.close(); onApply();`（`onApply` 内已含 `rpCostBtnText()` + `renderReport()`，不要重复调用）
- **关闭** / Esc / 点遮罩：`draft = new Set(applied); dlg.close();` **不调** `onApply`
- **清空**：`draft.clear(); renderDlgBody();` 停留原地，不关框

### 3.4 过滤与提示

- 渲染：`const rows = showLinked ? all : all.filter((r) => !String(r.report_links || "").trim());`
- 开关：`showLinked = !showLinked; renderDlgBody();`（只重画，**不动** `draft` / `applied`）
- 顶部提示：`hiddenSelected = all.filter((r) => applied.has(String(r.id)) && String(r.report_links || "").trim()).length`，`>0` 时显示「另有 N 条已关联记录已选中（打开开关可见）」
- 已关联行徽标：`<span class="cost-tag-linked" title="${esc(r.report_links)}">已关联</span>`（**单次 `esc()`**）

### 3.5 对话框结构（`document.createElement("dialog")`）

```html
<dialog class="cost-dlg">
  <div class="cost-dlg-head">选择费用记录</div>
  <div class="toolbar cost-dlg-tools">
    <label class="muted"><input type="checkbox" id="cost-show-linked"> 显示已关联保存报表的记录</label>
    <span class="muted" id="cost-hidden-tip"></span>
  </div>
  <div class="cost-dlg-body"><!-- 复选框列表 --></div>
  <div class="cost-dlg-foot">
    <button class="btn btn--ghost" type="button" data-cost-clear>清空</button>
    <button class="btn btn--ghost" type="button" data-cost-close>关闭</button>
    <button class="btn" type="button" data-cost-ok>确认</button>
  </div>
</dialog>
```

> **不要**用 `lib.formDialog`：它固定「取消 / 保存」两按钮，且 `.dlg` 走 `closeFormDialog()` 会误关 `report_saved.js` 的保存弹窗（`styles.css:630` 已有同类先例注释）。

### 3.6 `styles.css` 变更

- **删** `.cost-pop { ... }`（452-468 行那段）
- **新增**（`var(--c-*)` 取色，**不出现硬编码色值**）：
  ```css
  dialog.cost-dlg { width: min(560px, 92vw); max-height: 80vh; padding: 0;
    border: 1px solid var(--c-border); border-radius: var(--r-dialog);
    box-shadow: var(--shadow-dialog); background: var(--c-card); color: var(--c-text); }
  .cost-dlg-head { padding: 12px 16px; font-size: 15px; font-weight: 600; border-bottom: 1px solid var(--c-border); }
  .cost-dlg-tools { margin: 8px 12px 0; padding: 8px 10px; }
  .cost-dlg-body { padding: 4px 12px 10px; max-height: 52vh; overflow: auto; }
  .cost-dlg-foot { display: flex; justify-content: flex-end; gap: 8px; padding: 10px 16px; border-top: 1px solid var(--c-border); }
  .cost-tag-linked { margin-left: 8px; font-size: 11px; font-weight: 600; color: var(--c-warning); }
  ```
- **`@media print`**（699-708 行）：把 `.cost-pop,` 换成 `dialog.cost-dlg { display: none !important; }`（`showModal()` 进顶层渲染，`.toolbar` 的 `display:none` **管不到它**）

---

## 四、门禁（全绿才算交付）

```bash
cd <worktree>
node scripts/build_web_assets.mjs                 # 重生成 lib/web_assets.js
node scripts/build_web_assets.mjs --check         # 与 35 个源文件逐字节一致（exit 0）
node scripts/check.mjs                            # 通过：0 个问题，3 个提示
node scripts/web_size.mjs                         # 首屏 gzip ≤ 40 KB
node --test                                       # fail 0；pass 只增不减（基线 291 / pass 200 / fail 0 / skip 91）
node --check worker/src/web/tabs/report_costpop.js
node --check worker/src/web/tabs/report.js
node --check worker/src/lib/web_assets.js
git diff --check                                  # EXIT 0
# CRLF 必须为 0（逐文件）
for f in worker/src/web/tabs/report_costpop.js worker/src/web/tabs/report.js worker/src/web/styles.css worker/src/lib/web_assets.js; do
  printf "%s CRLF=%s\n" "$f" "$(grep -c $'\r' "$f" || true)"
done
# 单文件行数 ≤ 300
wc -l worker/src/web/tabs/report_costpop.js worker/src/web/tabs/report.js
```

**若门禁报错涉及 `check.mjs` / 黄金契约 / 夹具基线**：停下报告，**不得擅自改判据哈希或夹具基线**（ADR-0012 后果 4 先例）。

---

## 五、验收自检（逐条给出可复现证据）

| # | 验收项 | 自检方式 |
|---|---|---|
| ① | 弹窗化 | `grep -c "rp-cost-pop" worker/src/web/tabs/report.js worker/src/web/tabs/report_costpop.js` 两者均 **0**；`grep -c "pop.style.display" worker/src/web/tabs/report_costpop.js` = 0；`grep -c "showModal" worker/src/web/tabs/report_costpop.js` ≥ 1 |
| ② | 默认仅未关联 + 开关 | 造 3 条费用（1 条 `report_links` 非空）→ 打开弹窗只 2 行；勾开关 → 3 行且已关联行带「已关联」徽标 |
| ③ | 隐藏的已选不丢 | 勾已关联行 → 关开关（行消失）→ 点确认 → `rpCostIds()` 仍含该 id，`#rp-supply` / `#rp-repair` 汇总含它；顶部提示 N=1 |
| ④ | 三按钮语义 | 勾 2 条 → 关闭（或 Esc）→ 再开框，勾选回到打开前；清空 → 全不勾但框不关；确认 → 外部按钮文案与实际回填值同步 |
| ⑤ | 对外契约不变 | `grep -c "selectedCostRows" worker/src/web/tabs/report_saved.js` = **2**；`report.js` 的 `applySelectedCost` 函数体 `git diff` 为空 |
| ⑥ | 单次 esc | `grep -c "esc(.*esc(" worker/src/web/tabs/report_costpop.js` = 0；`report_links` 设成 `a&<b>"c'` 后页面显示原文、无脚本执行 |
| ⑦ | 打印媒体 | headless Chrome CDP：打开弹窗切 `print` 媒体，`dialog.cost-dlg` 的 `computed display` = `none`，`#rp-table` 仍 `table`，无 JS 异常 |
| ⑧ | 门禁 | 第四节命令逐条贴原始输出 |
| ⑨ | 未部署 | 全程无 `wrangler deploy` / `wrangler d1 execute` / 现网写操作 |

---

## 六、禁动清单

- 后端：`worker/src/modules/report.js`、`worker/src/modules/costs.js`、`worker/src/lib/cost_links.js`
- DDL：`worker/schema.sql`、`worker/migrations/**`
- 其它前端：`worker/src/web/tabs/report_saved.js`（`cost_ids` / `cost_labels` 语义）、`worker/src/web/tabs/costs.js`（admin 锁定交互）、`worker/src/web/lib.js`、`app.js`、`index.html`
- 共用原语：`lib/diff.js`、`lib/util.js`、`lib/paper_calc.js`
- 采集端：`collector/**`（ADR-0005 零改动）
- 治理文档：`BOARD.md`、`tasks.md`、`constitution.md`、`spec.md`、`OPEN-DECISIONS.md`、`docs/adr/**`（由 workbuddy 收官订正）
- 接口契约：不新增 `/api/*` 路径，不改 `routes.js` / `fixtures/routes.json` / `api_contract.mjs`
- 现网：不 `wrangler d1 execute`、不 `wrangler deploy`、不连现网写操作

---

## 七、交付格式（六段，缺一不可）

1. **基座与分支**：`origin/master` 实测 hash、worktree 路径、分支名、`local=origin` 核对结果
2. **改动清单**：4 文件逐文件 `+N/-M`，说明每处改了什么（对照第三节）
3. **门禁原始输出**：第四节命令的**原样粘贴**（不得只写「全绿」）
4. **验收证据**：第五节 ①~⑨ 每条一句结论 + 关键命令输出
5. **禁动核对**：`git diff --name-only <基座>..HEAD` 输出，确认只含白名单 4 文件
6. **未做事项**：明确写「未部署、未执行 DDL/DML、未连现网」

推分支到 `origin/agent/trae/T-069` 后**停下等 workbuddy 复审**，不得自行合并 master、不得自报 done。
