# 2026-11-05 前端视觉改版方案编制 · zhn-tbxg2iah-win（workbuddy）

- 性质：**仅方案与效果图，生产仓库零改动**（`git diff HEAD` 为空）
- 人类需求（14:10 口头提出）：优化打印机管理项目 web 页面显示、美化；**不动业务逻辑**；不明显增加页面体积；不用框架、原生 JS/CSS；**先出效果图待确认**
- 人类补充（15:27）：**配色再给几个方案** → 15:27 拍板 **采用石墨灰（slate）**
- 交付物目录：`C:/Users/Zhn_X/WorkBuddy/2026-11-04-21-23-46/`
  - `prnmgt-ui-mockup.html`（68.1 KB 单文件效果图，双击即开；**默认即石墨灰**）
  - `prnmgt-ui-refresh-plan.md`（实施方案 v2 · 已按石墨灰收敛）
  - `prnmgt-ui-palette.html` + `palette-overview.png`（配色对照卡，已标注选定项）
  - `final-*.png`（石墨灰最终效果图 7 张）/ `pal-*.png`（6 套备查截图）/ `shot-*.png`（历史核对截图）
  - 辅助脚本：`gen-palette.mjs`（对照卡生成）/ `verify.mjs`（15 项自检）/ `probe-legacy.cjs`（legacy 保真运行时探测）
- 生产仓库：`C:/Users/Zhn_X/source/prnmgt`，master HEAD `f4ddfbf`（系他人合并 T-047，与本会话无关）

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
| T-048 | Token 扩展 + 基础层 | `tokens.css`、新 `styles-refresh.css` | +110 行 |
| **T-048b** | **落地石墨灰配色 + ink token**：改 8 个既有 token 值 + 新增 14 个 | `tokens.css` | +32 行 |
| T-049 | 顶栏 + 导航 + 页头 + 面包屑 | `styles-refresh.css`、`index.html`、`app.js` | +95 行 |
| T-050 | 卡片 + 涨跌片 + 状态徽标 | `styles-refresh.css`、`lib.js` | +120 行 |
| T-051 | 表格 + 子页签分段控件 | `styles-refresh.css` | +100 行 |

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

> 注：6 套方案只存在于**评审件 mockup**（不进生产）。落地时按 T-048b **只落地石墨灰这一套**，其余 5 套不写进 `tokens.css`（全落地会 +156 行 / +1.4KB gzip，且徒增选择成本）。

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

## 六、待人类拍板（**剩 3 点**，卡住开工）

1. **表格对齐**：标准全居中（= 现版口径，`AGENTS.md` 记录「表头与表体一律居中」是旧系统基线）vs 增强（数字右对齐 + 文本左对齐）——**影响长表格可读性最大**，建议选增强
2. **布局**：A 顶栏导航（改动最小，与现版结构一致）vs B 侧边导航（信息架构更清晰，但顶栏/侧栏需重排）
3. **涨跌配色**：红涨绿跌（市场惯例）是否接受？现版是无色纯文本

**✅ 已定（15:27）：配色 = 石墨灰（slate）**，主色 `#425466`，顶栏 `#303b48 → #425466`。落地策略见 §3.3.0。

另需确认：是否保留「现版对照」模式作长期回归手段（建议只留 `docs/ui-refresh/legacy-look.md` 记录视觉基线，不进生产）。

> 对照卡：`prnmgt-ui-palette.html`（双击即开）或 `palette-overview.png`（一眼对比，已标注选定项）。

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

人类拍板**剩余 3 点**后：
1. 建 worktree `~/source/prnmgt.wt/workbuddy-ui` + 分支 `agent/workbuddy/ui-refresh`
2. 按 T-048 → **T-048b（落地石墨灰：改 8 个既有 token 值 + 新增 14 个）** → T-049 → T-050 → T-051 顺序执行，每卡过 `check.mjs` + `web_size.mjs`
3. T-048b 落地时**必须同步改 `tokens.css` 头注释**（记录「2026-11-05 人类决策变更主色系与交互态共 8 项」）并把决策来源写进卡内
4. 全部完成后交 workbuddy 审核，**部署生产 Worker 由人类执行**（worker/ 目录 `npx wrangler deploy`）

**未做**（等拍板）：未建 worktree、未建分支、未改 prnmgt 任何文件、未跑 build、未部署。

**未跟踪文件说明**：主仓库 `.login-out.txt`（wrangler 登录输出，勿提交）与 `docs/plan-2026-11-04-device-gap.md`（11-04 他人会话产物）**均与本方案无关**，本会话全部改动都在 WorkBuddy 工作区。

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
