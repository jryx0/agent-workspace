# 2026-11-05 前端视觉改版方案编制 · zhn-tbxg2iah-win（workbuddy）

- 性质：**仅方案与效果图，生产仓库零改动**（`git diff HEAD` 为空）
- 人类需求（14:10 口头提出）：优化打印机管理项目 web 页面显示、美化；**不动业务逻辑**；不明显增加页面体积；不用框架、原生 JS/CSS；**先出效果图待确认**
- 交付物目录：`C:/Users/Zhn_X/WorkBuddy/2026-11-04-21-23-46/`
  - `prnmgt-ui-mockup.html`（55.7 KB 单文件效果图，双击即开）
  - `prnmgt-ui-refresh-plan.md`（实施方案）
  - `shot-*.png`（6 张核对截图，非交付主体）
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
| T-049 | 顶栏 + 导航 + 页头 + 面包屑 | `styles-refresh.css`、`index.html`、`app.js` | +95 行 |
| T-050 | 卡片 + 涨跌片 + 状态徽标 | `styles-refresh.css`、`lib.js` | +120 行 |
| T-051 | 表格 + 子页签分段控件 | `styles-refresh.css` | +100 行 |

**新建 `styles-refresh.css` 而非改 `styles.css`**：不触旧代码 + 出问题删一个 `<link>` 即回滚 + 可独立长缓存。

### 3.3 体积（核心约束的量化）

| 项 | gzip 变化 |
|---|---|
| `tokens.css` | +0.6 KB（21 个新 token） |
| `styles-refresh.css`（新） | +2.4 KB |
| `app.js` | +0.3 KB |
| `icons.svg` | +0.3 KB（补 4 个 symbol） |
| **首屏合计** | **19.8 → ~22.8 KB（预算 40 KB，余量 17.2 KB）** |

砍到 ~21 KB（+6%）也可行：去侧边栏 −0.8、箭头改字符 −0.2、复用现有图标 −0.3。

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

## 六、待人类拍板（3 点，卡住开工）

1. **表格对齐**：标准全居中（= 现版口径，`AGENTS.md` 记录「表头与表体一律居中」是旧系统基线）vs 增强（数字右对齐 + 文本左对齐）——**影响长表格可读性最大**，建议选增强
2. **布局**：A 顶栏导航（改动最小，与现版结构一致）vs B 侧边导航（信息架构更清晰，但顶栏/侧栏需重排）
3. **涨跌配色**：红涨绿跌（市场惯例）是否接受？现版是无色纯文本

另需确认：是否保留「现版对照」模式作长期回归手段（建议只留 `docs/ui-refresh/legacy-look.md` 记录视觉基线，不进生产）。

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

人类拍板 3 点后：
1. 建 worktree `~/source/prnmgt.wt/workbuddy-ui` + 分支 `agent/workbuddy/ui-refresh`
2. 按 T-048 → T-051 顺序执行，每卡过 `check.mjs` + `web_size.mjs`
3. 全部完成后交 workbuddy 审核，**部署生产 Worker 由人类执行**（worker/ 目录 `npx wrangler deploy`）

**未做**（等拍板）：未建 worktree、未建分支、未改 prnmgt 任何文件、未跑 build、未部署。
