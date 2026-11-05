# 2026-11-05 前端视觉改版方案编制 · zhn-tbxg2iah-win（workbuddy）

> **规范三-4 交接要素速览**（当前状态 / 已完成 / 待办 / 关键文件 / worktree / 下一步）
>
> | 要素 | 内容 |
> |---|---|
> | **当前状态** | 方案与效果图已完成并入库，**4 项决策全部拍板，方案可开工**；生产代码**零改动**（`git diff HEAD` 为空） |
> | **已完成** | 效果图（可交互 mockup + 配色对照卡 + 定稿截图 7 张）、实施方案 v3、执行提示词（自包含任务书）、T-049~T-052 四张任务卡入库、`check.mjs` 0 问题 |
> | **待办** | 等人类指派执行 agent 按 T-049→T-049b→T-050→T-051→T-052 顺序实现；生产部署由人类执行 `npx wrangler deploy` |
> | **关键文件** | 方案 `docs/plan-2026-11-05-ui-visual-refresh.md`（生产仓库）；任务书 `docs/ui-refresh/exec-prompt.md`；效果图 `docs/ui-refresh/mockup.html`（均在 prnmgt 仓库 `agent/workbuddy/ui-refresh-plan` 分支）；效果图 PNG 在 `docs://prnmgt/ui-refresh/`（`~/.agent-docs`） |
> | **worktree / 分支** | `~/source/prnmgt.wt/workbuddy` · 分支 `agent/workbuddy/ui-refresh-plan`（已推 origin，待人类合并） |
> | **下一步** | 人类合并该分支 → 指派执行 agent 走 worktree `~/source/prnmgt.wt/<agent名>` + `agent/<agent名>/ui-refresh`，逐卡过 `check.mjs` + `web_size.mjs` + `build_web_assets --check` |

- 性质：**方案与效果图，生产代码零改动**（`git diff HEAD` 为空）；方案文档与任务卡已入 prnmgt 仓库分支，**待人类合并**
- 人类需求（14:10 口头提出）：优化打印机管理项目 web 页面显示、美化；**不动业务逻辑**；不明显增加页面体积；不用框架、原生 JS/CSS；**先出效果图待确认**
- 人类补充（15:27）：**配色再给几个方案** → 15:27 拍板 **采用石墨灰（slate）**
- 人类补充（15:40）：**表格对齐=全部居中 / 布局=A 顶栏 / 涨跌红涨绿跌=接受** → **4 个决策点全部拍板，方案可开工**
- **交付物（已入库，跨设备可达）**
  - prnmgt 仓库分支 `agent/workbuddy/ui-refresh-plan`（**待人类合并**）：
    - `docs/plan-2026-11-05-ui-visual-refresh.md`（实施方案 v3 · 决策全部落定）
    - `docs/ui-refresh/exec-prompt.md`（**执行提示词 · 自包含任务书，15:45 编制**）
    - `docs/ui-refresh/mockup.html`（68.1 KB 单文件效果图，双击即开；**默认即定稿态**）
    - `docs/ui-refresh/palette.html`（配色对照卡，已标注选定项）
    - `specs/0001-prnmgt-refactor/tasks.md` → 新增 T-049 / T-049b / T-050 / T-051 / T-052 五张卡（状态 todo）
  - `~/.agent-docs/prnmgt/ui-refresh/`（**跨设备同步区**，PNG 图表 1.3 MB，不进 Git）：`final-overview.png` / `final-collect.png` / `final-toner.png` / `final-report.png` / `final-layoutB.png` / `final-alignopt.png` / `final-legacy.png` / `palette-overview.png` —— 引用写 `docs://prnmgt/ui-refresh/<文件名>`
- 生产仓库：`~/source/prnmgt`，master HEAD `3c2fed7`（T-048 月环比计划，他人会话产物）
- **⚠️ 卡号重编（16:05 规范核查发现并修正）**：原方案用 T-048~T-051，但生产 `tasks.md` 的 **T-048 已被「月环比基数改上月同期」占用**（他人会话 15:55 登记，状态 todo）→ 撞号会导致两张卡互相覆盖。已整体重编为 **T-049 / T-049b / T-050 / T-051 / T-052**，与生产现有最大卡号 T-048 无冲突（`grep` 确认 T-049~T-052 未被占用）。

---

## 一、开工自检（规范 v1.8.5 第八节，全部 [Agent自动] 通过）

| 步 | 结果 |
|---|---|
| 1 记忆目录 / keys-checklist / config 权限 | 5 项密钥齐全；无 compact-lock |
| 2 MCP 127.0.0.1:9101 | 在线 |
| 3 `git pull --rebase` + 最新 handoff + org.md 近 200 行 | Already up to date；已读 T-047 handoff |
| 4 `.compact-lock` | 不存在 |
| 5 `VIRTUAL_ENV` | 未激活（无需） |
| 6 `env/mcp-registry.md` | 本会话不装 MCP |
| 7 `~/.agent-docs` | 可达 |
| 8 `tools-scan.sh --check` | 基线核对通过（stamp 2026-11-05T09:03，未满 30 天，未重复全量扫描） |
| 9 规范注入确认 | 已读 `global/rules.md` 全文；prnmgt `AGENTS.md` 首部已挂接全局规范 |

> 人类指令里写的 `C:\Users\Zhn_X.agent-shared\global\rules.md` 少了个 `\`，实际路径是 `C:\Users\Zhn_X\.agent-shared\global\rules.md`（已确认存在后照常执行）。

---

## 二、现状诊断（读全 35 个 web 源文件后得出，非猜测）

| 项 | 实测 |
|---|---|
| 首屏体积 | **gzip 19.8 KB / 预算 40 KB**（`node scripts/web_size.mjs --no-check`） |
| 样式 | `styles.css` **784 行**（已超 `MAX_LINES=300` 上限）· `tokens.css` 68 行 / 25 个 token（注释明写「逐字抄自旧页，一个没改」） |
| 架构 | `index.html` 骨架 → `app.js` hash 路由 + `import()` 懒加载 29 个 tabs → `lib.js` 共享助手 |
| 门禁 | `check.mjs`：单文件 ≤300 行（**只扫 .js**）、色值只允许 `tokens.css` 定义、禁 emoji、禁紫粉渐变 |
| 跑腿 | `scripts/build_web_assets.mjs`（生成 `web_assets.js`）+ `scripts/web_size.mjs`（体积硬门禁） |
| 授权 | `BOARD.md` 候选区原列「前端 UI 视觉改版（禁止顺手做）」——本轮由人类新需求正式授权 |

**关键约束推导**：① `styles.css` 已超行数上限 → 新增样式**只能另起文件**；② `check.mjs` 只允许 `tokens.css` 存色值 → 所有新色必须先进 token；③ `tokens.css` 25 个 token 冻结 → 新增只增不改。

---

## 三、方案要点

### 3.1 不动业务逻辑怎么保证

只改 **CSS** + **纯展示 DOM 包装**。`modules/*`、`lib/*` 业务模块、`routes.js`、46 条 API、字段名、统计口径、PRD 行为基准 **一律不碰**。
需新增的只有 `lib.js` 两个纯函数：`deltaChip(v)` / `statusChip(text, kind)`——只做 HTML 包装，不含任何取值逻辑与条件判断。

### 3.2 4 张卡（每卡 <5 文件 / <300 行）

| 卡 | 内容 | 文件 | 预估 |
|---|---|---|---|
| T-049 | Token 扩展 + 基础层 | `tokens.css`、新 `styles-refresh.css` | +110 行 |
| **T-049b** | **落地石墨灰配色 + ink token**：改 8 个既有 token 值 + 新增 14 个 | `tokens.css` | +32 行 |
| T-050 | 顶栏 + 导航 + 页头 + 面包屑 | `styles-refresh.css`、`index.html`、`app.js` | +95 行 |
| T-051 | 卡片 + 涨跌片 + 状态徽标 | `styles-refresh.css`、`lib.js` | +120 行 |
| T-052 | 表格 + 子页签分段控件 | `styles-refresh.css` | +100 行 |

**新建 `styles-refresh.css` 而非改 `styles.css`**：不触旧代码 + 出问题删一个 `<link>` 即回滚 + 可独立长缓存。

### 3.3 配色：6 套备查 → **已定石墨灰（slate）**

在 mockup 内以 `body[data-t="xxx"]:not(.v-legacy)` 选择器实现 **6 套配色**，每套只覆盖 token、不改任何结构规则：

| 方案 | key | 主色 | 顶栏渐变 | 定位 | 状态 |
|---|---|---|---|---|---|
| 经典蓝 | `classic` | `#2c5aa0` | `#24466f → #2c5aa0` | 与现版主色一致 | 备查 |
| 墨绿 | `forest` | `#1f6f54` | `#17543f → #1f6f54` | 沉稳内敛，运维/资产类常见 | 备查 |
| **石墨灰** | `slate` | `#425466` | `#303b48 → #425466` | 近乎无彩，注意力全让给数据 | ✅ **人类 15:27 拍板** |
| 青碧 | `teal` | `#0e6b78` | `#0a4d56 → #0e6b78` | 现代科技感，弱化传统后台观感 | 备查 |
| 暖砂 | `sand` | `#9a6428` | `#7f5222 → #9a6428` | 低饱和暖色，贴合纸张/文印语义 | 备查 |
| 深空 | `dark` | `#2f6fae` | `#141b24 → #1c2b3a` | 深色模式，夜间值守/大屏 | 备查（不落地） |

**关键设计：`:not(.v-legacy)`** —— 「现版对照」模式永远保持生产原色，是可信的改版前参照，不被任何新方案污染。

**新增品牌语义 token**（使主题可驱动原本硬编码处）：`--n-brand`、`--n-brand-strong`、`--n-on-primary`、`--n-topbar-a/b`、`--n-topbar-ink`、`--n-chart-prev`、`--n-ring`。

#### 3.3.0 落地策略：改哪 8 个、不改哪 17 个（**本次最关键的决策**）

生产 `tokens.css` 头注释写「25 个变量的值逐字抄自旧页，一个都没有改：现网用户对这些颜色已有认知，重写前端不以『顺手调色』为理由动它们」。换主色必然与这条冲突，**处理原则 = 把冲突面收到最小**：

| 类别 | 数量 | 处理 |
|---|---|---|
| 主色系（primary/-dark/-light/-soft、header、th） | 6 | 🔧 **改值** → 石墨灰系 |
| 交互态底色（select、hover） | 2 | 🔧 **改值** → `#d9e0e8` / `#eef1f5`（属品牌交互态，留淡蓝会露怯） |
| 中性色（bg/card/zebra/input-bg/border/text/text-2/text-muted） | 8 | ✅ 不动（石墨灰版差异 <3/255，肉眼不可辨） |
| 语义功能色（danger/warning/success） | 3 | ✅ 不动（红=异常须跨方案一致） |
| 圆角/阴影/焦点环（r-ctl/-card/-dialog、shadow-card/-dialog、ring） | 6 | ✅ 不动；`--ring` 是蓝色焦点环 → 改版样式改用新增 `--n-ring` |

> **备案不采用的替代方案**：新增 `--n-brand` 全量承载石墨灰、`--c-primary` 保持蓝色不动。**不采用** —— 既有 `styles.css` 大量元素直接引用 `--c-primary`（表头、图表柱、按钮、链接），不改其值就需在 `styles-refresh.css` 逐条重定向，等于长期维护两套品牌色，漏一处即蓝灰混搭。改 8 个值 = 一处改、全站统一、回滚只需 `git revert`。
>
> **落地时的义务动作**：① 改 `tokens.css` 头注释，把「一个都没有改」改为「2026-11-05 经人类决策变更主色系与交互态共 8 项，其余 17 项未动」；② 卡内记录决策来源（原话与日期），防后人误判为「顺手调色」而回滚。

#### 3.3.1 必须新增 ink token 的原因（生产遗留 WCAG AA 缺陷）

生产既有 token 用作「淡底小字前景」时对比度不足：

| 冻结 token | 值 | 实际用途 | 对比度 | AA(4.5:1) |
|---|---|---|---|---|
| `--c-danger` | `#d64541` | 淡底小字（异常态） | 2.69:1 | ✗ |
| `--c-warning` | `#d97a00` | 淡底小字（短缺态） | 3.67:1 | ✗ |
| `--c-success` | `#2e8b57` | 淡底小字（正常态） | 3.79:1 | ✗ |
| `--c-primary` | `#2c5aa0` | 浅灰底上的链接/数值 | 4.39:1 | ✗ |
| `--c-text-2` | `#5a6675` | 次要文字 | 4.39:1 | ✗ |

修法：另立 `--n-*-ink` 语义 token 承载「淡底小字前景」，用 **HSL 空间保持色相与饱和度、只调明度**解出合规值，**原 `--c-danger/-warning/-success` 值一律不动**（语义色跨方案必须一致）。

石墨灰套的具体值：`--n-danger-ink:#c23a34`、`--n-warn-ink:#945d00`、`--n-ok-ink:#2b794f`、`--n-up-ink:#c23a34`、`--n-down-ink:#2b7a4f`、`--n-danger-solid:#c23a34`。

**审计结果：石墨灰单套 19 项 + 6 套合计 114 项前景/背景组合实测，全部 ≥4.5:1 通过。** 深色方案下危险按钮改「亮红底 + 深字」（白字在亮红上仅 2.79:1）。

**legacy 保真验证方法（比像素比对更精确，值得复用）**：用 Chrome 无头 + `--dump-dom`，把 mockup 塞进 iframe，load 后读 `getComputedStyle(documentElement).getPropertyValue('--c-*')` 与实际元素的 `color`/`backgroundColor`，与生产 `tokens.css` 权威值逐一比对。本轮实测：**4 个页面 × 3 套配色组合下，25 个 token 全部等于生产原值**；`.tone-bad` = `rgb(214,69,65)` = `#d64541`，顶栏渐变 = `rgb(36,70,111)→rgb(44,90,160)` = `#24466f→#2c5aa0`，body 背景 = `rgb(238,241,245)` = `#eef1f5`。

### 3.4 体积（核心约束的量化）

| 项 | gzip 变化 |
|---|---|
| `tokens.css` | +1.0 KB（37 个新 token + 8 个既有值改写） |
| `styles-refresh.css`（新） | +2.4 KB |
| `app.js` | +0.3 KB |
| `icons.svg` | +0.3 KB（补 4 个 symbol） |
| **首屏合计** | **19.8 → ~24.0 KB（预算 40 KB，余量 16.0 KB）** |

砍到 ~22 KB（+11%）也可行：去侧边栏 −0.8、箭头改字符 −0.2、复用现有图标 −0.3。

> 注：6 套方案只存在于**评审件 mockup**（不进生产）。落地时按 T-049b **只落地石墨灰这一套**，其余 5 套不写进 `tokens.css`（全落地会 +156 行 / +1.4KB gzip，且徒增选择成本）。

---

## 四、本轮踩坑（3 个真实渲染 bug，均已修 + 建议入 AGENTS.md 坑表）

### 坑 1（最隐蔽）：`position:sticky` 的包含块不是视口

`th { position:sticky; top:56px }` 放在 `overflow-x:auto` 的 `.scroll` 容器内时，**sticky 相对该容器定位而非视口**——表头被下移 56px，**盖住第 1 行**。截图实测：`采集明细` 页 PRN001 整行（含其账号明细子行）被完全遮住。

修法：`th { top:0 }` + 给容器 `max-height: min(62vh,560px)` 做纵向有界滚动。

> 这条对生产同样成立：`styles.css` 现有 `.table-block{overflow-x:auto}`，若后续给 `th` 加 sticky 会踩同一个坑。

### 坑 2：grid 隐式排布错位

`.shell` 有 3 个子元素（topbar / rail / main），`grid-template-columns` 给 2 列 → 浏览器隐式排成三行，侧栏跑到最上面把内容顶掉。
修法：显式 `grid-template-areas:"rail top" "rail main"`。

### 坑 3：换底色后「白底白字」

布局 B 把顶栏从深蓝渐变改成白底后，顶栏里那套横排导航（白字）不可见，但**仍占据布局空间**。
修法：`body.layout-b .topbar .nav{display:none}`（导航已移到侧栏）。

### 附带坑 4：评审条换行 → 整页位移 44px

加入 6 个配色按钮后 `.review` 工具条换行，而 `.shell` / `.rail` 里硬编码了 `calc(100vh - 33px)`，导致整页下移 44px。

修法两步：① 改为 `calc(100vh - var(--rev-h,33px))`，由 JS 实测 `.review` 高度写回 `--rev-h`；② 工具条改 `flex-wrap:nowrap` + `overflow-x:auto` + `white-space:nowrap`，并精简按钮文案（「现版对照」→「现版」、「标准（居中）」→「居中」）。

**验证方法**：自写 PNG 解码（zlib inflate + PNG filter 反算）做垂直平移搜索，逐像素比对「现版对照」在改版前后是否零回归。结果：**0px 位移 + 0.00 通道差**。

### 附带坑：Chrome 无头截图在本机的坑

- `--screenshot=shot.png` 相对路径报「拒绝访问」，须给**绝对 Windows 路径**（`C:\\...\\shot.png`）
- 页面切换靠 URL hash 需在脚本里显式读 `location.hash`，否则四页渲染出同一张图（本次已加深链支持）

---

## 五、核对方式

```bash
# 用本机 Chrome（无需下载浏览器）逐页截图核对
"/c/Program Files/Google/Chrome/Application/chrome.exe" --headless --disable-gpu --no-sandbox \
  --hide-scrollbars --window-size=1680,1180 \
  --screenshot="C:\\...\\shot-overview.png" --virtual-time-budget=2500 \
  "file:///C:/.../prnmgt-ui-mockup.html#overview"

# 计算样式探测（比截图更精确，定位「白底白字」这类问题）
# 在页面注入 script 把 getComputedStyle 结果写进 document.title，再用 --dump-dom 读
```

已逐页人工核对：总览 / 采集明细 / 碳粉分析 / 报表生成 / 布局B / 现版对照 / 增强对齐，共 7 张。

**合规自检**（对齐 `check.mjs` 规则）：JS 语法有效 ✓ · 无外部资源引用（离线可用）✓ · 无 emoji ✓ · 无硬编码色值（token 定义与评审工具条除外，二者不进生产）✓

---

## 六、决策点已全部拍板（2026-11-05 15:40），**可开工**

| # | 决策 | 结论 | 人类原话 |
|---|---|---|---|
| 1 | 配色 | **石墨灰 slate**，主色 `#425466` | 「采用石墨灰」 |
| 2 | 表格对齐 | **全部居中**（= 现版口径） | 「表格对齐 全部居中。」 |
| 3 | 布局 | **A 顶栏**（不做侧边栏） | 「部门A顶栏」 |
| 4 | 涨跌配色 | **接受红涨绿跌** | 「接受」 |

**决策带来的删减（执行时不要做多余的事）**：
- 布局 A → **不落地**侧边栏 DOM/CSS（效果图的布局 B 仅留备查）
- 全居中 → **不落地**「数字右对齐」档位，且 **T-052 不得触碰 `styles.css:197-201` 的 `text-align`**（其注释已说明源自旧系统 `query_page.js:191/193`）
- 涨跌色 → **需要** `deltaChip`（T-051）

另需确认（不阻塞开工）：
- **是否保留「现版对照」模式作为长期回归手段**——建议不保留进生产（纯属评审件），但可留一份 `docs/ui-refresh/legacy-look.md` 记录视觉基线。
- **ink token 修复是否随本次改版一起上线**——它修的是生产遗留的可访问性缺陷（徽标文字 2.69:1），建议一起上；若要求「徽标颜色一个字都不能变」，则推迟到后续独立卡。

---

## 七、准出原始输出

### `node scripts/check.mjs`（生产仓库，方案阶段应为 0 问题）

```
OK  项目章程
OK  Agent 规则（单源）
OK  specs/0001-prnmgt-refactor 任务 47 · done 47
OK  路由 42 个 /api 路径，与契约一致
OK  路由表 44 条，与契约逐条对齐（路径/方法/鉴权）
最大文件 worker/src/mcp.js · 299 行
OK  web 资源 33 个 · emoji 0
通过：0 个问题，2 个提示
```

### `node scripts/web_size.mjs --no-check`（体积基线）

```
首屏资产                  原始         gzip
index.html            2.8 KB     1.4 KB
tokens.css            2.6 KB     1.6 KB
styles.css           33.6 KB    10.4 KB
icons.svg             2.0 KB     0.8 KB
app.js               12.3 KB     5.6 KB
合计                    53.2 KB    19.8 KB
预算：gzip 40.0 KB，余量 20.2 KB
通过：首屏 gzip 19.8 KB ≤ 40.0 KB
```

### 共享记忆登记

`memory/projects/prnmgt.md` 追加方案登记条目 → commit `f67e266` → 已推双远端（origin Gitee + backup GitHub），gitleaks 0 leaks。

---

## 八、下一步

**决策已全部拍板，方案与任务卡已入库，可直接开工。** 执行入口是生产仓库分支 `agent/workbuddy/ui-refresh-plan` 内的 **`docs/ui-refresh/exec-prompt.md`**（自包含任务书，含逐卡指令、准出命令、禁止事项、token 全表、已知坑表）。

1. **人类先合并** `agent/workbuddy/ui-refresh-plan`（含方案 v3 + 执行提示词 + 效果图 + T-049~T-052 五张卡）进 master
2. 执行 agent 建 worktree `~/source/prnmgt.wt/<agent名>` + 分支 `agent/<agent名>/ui-refresh`
3. 按 T-049 → T-049b → T-050 → T-051 → T-052 顺序执行，每卡过 `check.mjs` + `web_size.mjs` + `build_web_assets --check` + 单测
4. T-049b 落地时**必须同步改 `tokens.css` 头注释**（记录「2026-11-05 人类决策变更主色系与交互态共 8 项」）并把决策来源写进卡内
5. 全部完成后交 workbuddy 审核，**部署生产 Worker 由人类执行**（worker/ 目录 `npx wrangler deploy`）

**未做**（等人类指派执行 agent）：未跑 build、未改任何生产代码、未部署。

**未跟踪文件说明**：主仓库 `.login-out.txt`（wrangler 登录输出，勿提交）与 `docs/plan-2026-11-04-device-gap.md`（11-04 他人会话产物）**均与本方案无关**。

---

## 八之二、16:00-16:10 规范合规自查与修正（规范 v1.8.5）

按人类要求「检查是否遵守 rule 规范，各种产出、handoff」，逐条比对 `~/.agent-shared/global/rules.md` v1.8.5 + 项目 `AGENTS.md` + `constitution.md`，**发现 4 项违规并已全部修正**：

| # | 级别 | 违规内容 | 依据条款 | 修正动作 |
|---|---|---|---|---|
| **V1** | **P0** | **任务卡撞号**：原方案用 T-048~T-051，但生产 `tasks.md` 的 **T-048 已被「月环比基数改上月同期」占用**（他人会话 15:55 登记，状态 todo）→ 执行 agent 建卡会与该卡互相覆盖 | 项目 `AGENTS.md` §二「一次只做一张卡」+ 规范三-5 ⑤「任务认领机制」 | 整体重编为 **T-049 / T-049b / T-050 / T-051 / T-052**；用脚本做占位符替换防连环覆盖；`grep` 确认 T-048 归零且 T-049~T-052 在生产未被占用 |
| **V2** | P1 | **任务卡未登记**：五张卡只在方案文档里，生产 `tasks.md` 无卡片，执行 agent 无处认领 | 规范三-5 ⑤ + 章程原则3「一条命令能验证」 | 五张卡写入 `specs/0001-prnmgt-refactor/tasks.md`，每卡含 `依赖/改动范围/验收/状态` 四字段 + 计划 + 背景；验收全部写成「命令 → 期望输出」；`check.mjs` 复跑 **0 问题**（任务 47→52） |
| **V3** | P1 | **交付物未入库，跨设备不可达**：全部产出只在本机 WorkBuddy 工作区，其他设备（含移动端）无法获取，handoff 里引用的还是绝对路径 | 规范三-3「跨设备文件分类」+ 三-4「关键文件链接」+ 五-2 引用规范 | 文本类（≤1MB）入 prnmgt 仓库 `docs/`：方案 → `docs/plan-2026-11-05-ui-visual-refresh.md`、任务书 → `docs/ui-refresh/exec-prompt.md`、效果图 → `docs/ui-refresh/mockup.html` 与 `palette.html`；PNG（1.3MB 图表）入 `~/.agent-docs/prnmgt/ui-refresh/`，引用写 `docs://prnmgt/ui-refresh/<文件名>`；handoff 内绝对路径**已清零** |
| **V4** | P1 | **handoff 缺规范三-4 要求的五要素**（当前状态/已完成/待办/关键文件/worktree/下一步）：原文档章节标题用的是自定义措辞，且缺「当前状态」独立表述 | 规范三-4「交接文档需包含」 | 首部新增「规范三-4 交接要素速览」表，六要素齐备；worktree 路径与分支填实（`~/source/prnmgt.wt/workbuddy` · `agent/workbuddy/ui-refresh-plan`） |

### 未修正但需登记的一项

**commit message type 未用枚举值**：`c0f79d8` 与 `2d5f511` 的 type 写成中文「前端视觉改版」，规范五-1 要求 type 取 `docs/feat/fix/refactor/memory/handoff/infra/scripts`。**不修正**——同条规范明确「历史提交不追溯改写」，且两条均已推双远端，改写会破坏他人已拉取的历史。后续提交一律用枚举 type（本次入库提交已用 `docs:`）。

### 本轮顺带确认的无违规项

- **第八节启动自检**：9 步全过（记忆目录正常、5 项密钥齐全、无 compact-lock、MCP 9101 在线、工具链 stamp 存在且未满 30 天、项目 `AGENTS.md` 第 10 行已挂接全局规范）
- **记忆 append-only**：`git diff f67e266..HEAD -- memory/projects/prnmgt.md` = **8 insertions / 0 deletions**，无改写无重排；署名格式 `[@workbuddy @zhn-tbxg2iah-win YYYY-MM-DD HH:mm UTC+8]` 合规
- **agent 署名**：`workbuddy` 已在 `env/agents.md` 登记（设备 `zhn-tbxg2iah-win`），非无效署名
- **gitleaks**：全局 hook 已配（`core.hooksPath` → `~/.agent-tools/hooks`），链式委托项目自身 pre-commit；本次提交 0 leaks
- **双远端**：origin 与 backup 均为 `5fe8f33`，一致；仓库无 tag 故 `--tags` 无对象
- **worktree 规范**：按三-6 建 `~/source/prnmgt.wt/workbuddy` + `agent/workbuddy/ui-refresh-plan`；提交身份用 `git -c user.name=zhn-workbuddy` 一次性指定，**未用裸 `git config`** 污染主 worktree 署名
- **生产代码零改动**：主仓库 `git diff HEAD` 为空；`worker/src/lib/web_assets.js` 两仓库 md5 相同（`3f1cb7e9...`），未跑 build 故未污染生成物
- **既有基线问题（非本轮引入）**：`build_web_assets --check` 在**主仓库同样报不一致**，属 `AGENTS.md` 坑表第 83 条记录的 CRLF 坑，本轮改动未触及 `worker/src/web/` 任何文件

---

## 九、15:27-15:35 配色收敛轮（人类拍板石墨灰）补充

### 做了什么

1. **mockup 默认主题切为 `slate`**，配色按钮加「已定」徽标；评审条由深蓝改为**中性石墨**（避免评审工具的蓝与页面主色混淆）。
2. **新增 `prnmgt-ui-palette.html` + `palette-overview.png` 对照卡**：石墨灰卡片加「已选定」角标与高亮描边；卡片内容由 `gen-palette.mjs` **从 mockup 直接抽 token 生成**（避免手工转录出错），脚本会同时校验 14 个色位齐全。
3. **`prnmgt-ui-refresh-plan.md` 重写为 v2**：新增 §〇 已定/待定一览、§3.1.1 落地策略（改 8 不改 17 + 备案替代方案 + 义务动作）、§3.1.2 新增 37 个 token 全表（石墨灰值，逐字可抄）、§3.1.4 其余 5 套备查不落地、§六 额外验收命令（配色回归 one-liner）、§七 新增两条风险。
4. **出石墨灰最终效果图 7 张**：`final-overview / collect / toner / report / layoutB / alignopt / legacy`。

### 验证结果

```
OK  JS 语法有效
OK  CSS 括号平衡 (255/255)
OK  无外部依赖（离线可开）      OK  无 emoji      OK  无紫粉渐变
OK  6 套方案 CSS 块 + 按钮齐全   OK  深链 &t= 支持  OK  THEMES 常量正确
OK  legacy 保真: .tone-bad 还原  OK  legacy 保真: .btn--danger 还原
OK  语义 ink token 齐全          OK  品牌语义 token 齐全
OK  评审条高度动态 var(--rev-h)  OK  syncRevH 存在
体积: 68.1 KB (评审件，不进生产)  → 全部通过
```

**legacy 保真（运行时 `getComputedStyle` 探测，比像素比对精确）**：4 个页面 × 3 套配色切换组合下，25 个 token 全部等于生产原值。
**生产仓库**：`git diff HEAD --stat` 为空，零改动。

### 本轮沉淀的方法论（可复用）

> **验证「某模式是否保持了生产原色」时，用运行时 `getComputedStyle` 读 CSS 变量，比截图逐像素比对更快更精确**：
> Chrome 无头 `--dump-dom` + iframe 载入被测页 + `load` 后读 `getComputedStyle(documentElement).getPropertyValue('--c-*')`，
> 拿到的是**最终生效值**（含所有覆盖与优先级），可直接与生产权威值表逐一比对，还能顺带取实际元素的 `color`/`backgroundColor`。
> 配套脚本：`probe-legacy.cjs`（本工作区）。

---

## 十、15:40-15:50 决策全定 + 执行提示词编制

### 10.1 人类拍板（4 点全部落地）

人类 15:40 一条消息给全：**表格对齐=全部居中 / 布局=A 顶栏 / 涨跌红涨绿跌=接受**（加上 15:27 的石墨灰）。**决策全部齐了，方案可开工。**

决策带来的**删减**（写进提示词，防止执行 agent 做多余的事）：
- 布局 A → **不落地**侧边栏 DOM/CSS（效果图的布局 B 仅留备查）
- 全居中 → **不落地**「数字右对齐」档位，且 T-052 **不得触碰** `styles.css:197-201` 的 `text-align`（其注释已说明源自旧系统 `query_page.js:191/193`，是旧系统基线）
- 涨跌色 → **需要** `deltaChip`（T-051）

### 10.2 执行提示词（新增交付物）

`prnmgt-ui-refresh-exec-prompt.md` —— **自包含任务书**，执行 agent 无需看历史对话即可完整执行。含 9 个部分：任务定义 / 业务背景（Cloudflare Workers+D1、无框架、29 个 tab）/ 已定决策（不可再讨论）/ 11 条硬约束红线 + 绝对不可碰清单 + 行数红线 / worktree 与提交规范 / **逐卡指令（T-049/T-049b/T-050/T-051/T-052，每卡含文件、具体改法、准出命令）** / 全局准出 + 人工验收清单 / 15 条禁止事项 / 汇报格式模板 / 附录 A token 全表 + 附录 B 视觉基准深链 + 附录 C 10 条已知坑。

### 10.3 ⚠️ 本轮纠正两处**事实性错误**（此前方案与 handoff 均写错）

| # | 错误说法 | 事实 | 影响 |
|---|---|---|---|
| **E1** | 「`styles.css` 784 行**已超 `MAX_LINES=300` 上限**，新增只能另起文件」 | **错**。`scripts/check.mjs:199` 是 `walk(src, ['.js'])` —— **`MAX_LINES` 只扫 `.js`，CSS 完全不受此门禁约束**（`styles.css` 784 行并不违规） | 结论虽仍指向「另起新文件」，但**理由错了**。真正理由是：784 行旧样式耦合深、另起文件便于回滚与长缓存。已在 plan/handoff/提示词全部改正 |
| **E2** | 未提及 `web_size.mjs` 的首屏白名单 | **漏了关键一步**。`scripts/web_size.mjs:23` 的 `FIRST_SCREEN` 是**硬编码 5 项白名单**（`['index.html','tokens.css','styles.css','icons.svg','app.js']`），新增 `styles-refresh.css` **不手动加进去就不会计入首屏体积** —— 门禁形同虚设，改版后真实首屏体积会超出报告值 | 已在 T-049 卡与提示词里列为**必做项**，并给出改完的自检方法（`web_size.mjs` 输出应出现 `styles-refresh.css` 一行） |

> `build_web_assets.mjs` 的 `collect()` 递归遍历 `web/` 全部文件，新文件会自动进字节表，这一步无需配置。

### 10.4 ⚠️ 行数红线（此前方案未量化，执行会直接撞门禁）

`MAX_LINES` 只扫 `.js`，而 `.js` 里已有多文件贴顶：

| 文件 | 现状 | 距 300 | 处置 |
|---|---|---|---|
| `worker/src/web/app.js` | 282 | **仅 18 行** | T-050 的页头挂载**必须 ≤ 18 行**，多的挪 `lib.js` |
| `worker/src/web/lib.js` | 231 | 69 行 | T-051 的 `deltaChip`/`statusChip` 放这里（→ 约 256，安全） |
| `worker/src/web/tabs/admin_master.js` | 298 | 2 行 | **本方案不得改** |
| `worker/src/mcp.js` | 298 | 2 行 | **本方案不得改** |

### 10.5 涨跌方向的实际坑（`fmtPct` 返回的是字符串）

`lib.js:58` `fmtPct(value, delta)` 返回的是**字符串**：`"+12.4%"` / `"-9.8%"` / `"-"`（无数据，**半角减号**）/ `"—"`（基期≤0，em dash）。

→ `deltaChip` 判断涨跌**必须**「含 `%` 且首字符为 `+`/`-`」，**不能只看首字符是否为 `-`**（无数据时也是减号开头）；**绝不能重算百分比**（会与 `fmtPct` 结果不一致）。
→ 全站 `fmtPct` 调用点**只有一个**：`tabs/overview_cards.js:57`，改动面因此极小。

**运行时实测**（`probe-delta.cjs`，读 DOM 而非看图）：`delta--up | +12.4%`、`delta--down | -12.5%`、`delta--up | +3.2%`、`delta--down | -52.3%` 等，方向判定正确。
> 教训：看截图时小字号 `+` 与 `−` 极易误读（本轮我就误读过一次），**验证数值/方向一律走 DOM 读取，不靠肉眼**。

### 10.6 方案文档更新

`prnmgt-ui-refresh-plan.md` 升到 v3：§〇 已定/待定表改为「全部已拍板」+ 人类原话；§一 硬约束表修正 `MAX_LINES` 适用范围并加行数红线；§二 现状诊断修正 CSS 行数表述；§3.3 表格对齐改为「已定=全部居中」并写明不得触碰 `text-align`；§四 关键设计决策扩到 7 条（新增「JS 改动额度极紧」「表格对齐不动 text-align」）；§五 加 `FIRST_SCREEN` 必做项；§八 改为「决策点已全部拍板」+ 决策带来的删减。
