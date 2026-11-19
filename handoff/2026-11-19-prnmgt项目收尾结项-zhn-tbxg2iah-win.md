---
项目: prnmgt
日期: 2026-11-19
设备: zhn-tbxg2iah-win
代理: workbuddy@zhn-tbxg2iah-win~zhn-x-w
类型: 收尾结项
---

# prnmgt · 项目收尾结项（T-077 done）

> 人类 2026-11-19 指令：**「本项目基本功能已经完成，挂起的任务暂时不做，做项目收尾了和运维文档」**
> 本份为**收尾交接件**，不是开工令。prnmgt 进入「可正常运维」状态。

---

## 1. 结论（先看这一段）

| 项 | 结论 |
|---|---|
| 功能状态 | **基本功能全部完成并已上线**；增强项（纸张口径等）按人类指令挂起，**不影响日常使用** |
| 线上版本 | `7de9be32-f33a-42b2-8071-2a6deecde362` |
| 主干 | `master = origin/master = 2f02cea`（本轮收尾提交） |
| **线上版本与基线是否一致** | **是** —— `git diff d0e7162..2f02cea -- worker/ collector/` **输出为空**，业务代码自 T-074 起零改动 |
| 门禁 | `check.mjs` 0 问题 3 存量提示 · `node --test` 313 / pass 222 / fail 0 / skip 91 · `build --check` 37 源文件一致 · `web_size` 26.7 KB · `xls_golden` 2 PASS |
| 本轮改动 | 纯文档 + 仓库卫生，**零业务代码改动**，**未部署** |
| 挂起项 | S1 / S2 / S3 三项**全部挂起**，卡面保持 `todo`，**禁止认领开工** |

---

## 2. 交付物清单

### 2.1 新增：`docs/operations/04-closeout-and-maintenance.md`（240 行）

运维手册第四篇，构成完整交接层：

1. **终态快照** —— 线上版本 / 主干 / 现网数据（`collect_run` 28 行，2026-10-16~11-18）/ 在用设备 16 台 / 20 模块 + 24 lib + 29 tab / 46 路径 · 48 契约 · 56 请求；
2. **已交付能力清单** —— 采集端三态 + 三种部署 + 展示端 13 个业务域 + **5 条刻意保留的「非缺陷」行为**；
3. **遗留项台账 L1~L7** —— 每项含状态 / 根因 / 处置口径；
4. **挂起任务快照** S1/S2/S3；
5. **巡检周期表**（日 / 周 / 月 / 变更时）+ **变更纪律 9 条** + 出问题去哪查；
6. **后续可做事项**与解挂前置；
7. **交接检查单 4 组 18 项**。

### 2.2 文档失真订正（3 处 + README 重写）

| 文件 | 订正内容 |
|---|---|
| `README.md`（重写） | 版本 `1dd15dd7`→`7de9be32`；模块 16→**20**；卡 37→**76**；单测「113 pass」→**313 / pass 222 / fail 0 / skip 91**；体积 19.7→**26.7 KB**；设备「12 台在用」→**16 台**；红线「46 路由等价 PASS 率 100%」→改为「46 路径 / 48 契约 / 56 请求只增不改不改语义」；**三条必跑命令剔除 `verify_all.mjs`、换成 `xls_golden`**；入口从 `docs/handoff/README.md` 改为 `docs/operations/README.md` |
| `docs/operations/02-worker-deploy.md` | 第 3 道门改为「已退出日常门禁」并展开**两层根因**；**原「补判定配置（推荐）」是无效建议，已废**；发布检查单第 3 项改 `xls_golden` |
| `docs/operations/03-troubleshooting.md` | B7 同源订正（两层根因 + 唯一正确处置） |

### 2.3 仓库卫生

| 项 | 动作 |
|---|---|
| `.gitignore` | 补 `.login-out.txt`（**全局规范七-1** 明文要求「项目根下的登录输出类文件须加入项目 `.gitignore`」）、`tmp/`、`.trae/`、`.wrangler/` |
| `docs/paper/field-survey-2026-11-07.md` | 由未跟踪**转入库**（P0 真机调研结论，2026-11-09 实机只读探测完成；S2 挂起项的解挂前置之一） |
| `docs/plan-2026-11-04-device-gap.md` | 由未跟踪**转入库**（设备缺口核查计划） |
| 凭据扫描 | 两份入库文档**逐条扫描无任何凭据**（password / passwd / token / secret / cookie 值 / Authorization），仅含方法论描述与内网 IP |

---

## 3. 本轮最有价值的产出：`verify_all.mjs` 根因订正

**表层现象**（实跑复现）：

```
$ node tools/compare/verify_all.mjs
verify_all 自检失败（路由条目缺判定配置，禁止静默跳过）：
  - R-47 无配置
  - R-48 无配置
```

**表面根因**：纸张模块新增 `R-47 /api/paper/summary`、`R-48 /api/paper/purchases`，判定表未收录 → 脚本在生成对比产物**之前** `exit 2`。

**但补配置救不回来 —— 这才是真正的阻断点**：

| 依赖 | 实测状态（2026-11-19） |
|---|---|
| `tools/mirror/out/legacy-all.json` | **不存在**（被 `.gitignore` 排除，本就不入库） |
| 其来源旧库 `dd87b46c-1c16-473c-a0f7-70e2909b182c` | **已删除** —— `wrangler d1 list` 下**只剩 `prnmgt` 一个库**（ADR-0008：旧系统 2026-11-02 退役） |
| `buildEnv()` 实跑结果 | `ENOENT: no such file or directory, open 'tools/mirror/out/legacy-all.json'` |

**结论**：该脚本是**双轨期专用的一次性工具**，旧系统退役后已无等价物 → **正式退出日常门禁**。原 02 / 03 两章给的「补 R-47/R-48 判定配置（推荐）」属**无效建议**，会把运维引向无效劳动，已在 **04 章 L1 + 02 章 3.1 + 03 章 B7 三处**统一订正。

**替代门禁（三道，全部可复跑、当前全绿）**：

```bash
node scripts/check.mjs                                            # 通过：0 个问题，3 个提示
node --test tools/tests/*.test.mjs tools/tests/unit/*.test.mjs     # 313 / pass 222 / fail 0 / skip 91
node tools/tests/xls_golden.mjs                                    # 共 2 个用例 PASS
```

`tools/compare/diff.mjs` 的定向差分同因（旧侧快照来自已下线旧站）→ 一并归为**历史留档**。
需要「与旧系统逐字段等价」时，查 `tools/tests/fixtures/golden/**`（黄金用例唯一真相，**禁止改期望值让测试通过**）与 `tools/compare/deviations.json`。

---

## 4. 验证与边界

**门禁（独立实测，不采信自报）**：`check.mjs` **0 问题 3 存量提示**（T-034/T-040/T-055）· 全量 `node --test` **313 / pass 222 / fail 0 / skip 91** · `build_web_assets --check` **与 37 个源文件一致** · `web_size` **26.7 KB ≤ 40.0 KB** · `xls_golden` **2 PASS** · 10 个改动文件 **CRLF=0 纯 LF** · `git diff --check` **EXIT 0**（README 与 `.gitignore` 首次写入被写成 CRLF，已用二进制方式修正）。

**线上只读自检 4 项全 PASS**：`/`=**200** · `/api/config`=**200** · 未登录 `/api/collect_runs`=**401** · 线上 `styles-refresh.css` 与仓库源文件**逐字节一致**（`cmp` 通过）。

**边界**：**未部署、未改线上、未执行任何 DDL/DML、未改任何业务代码**（采集端 Python **0 行改动**，ADR-0005）。

---

## 5. 挂起任务（当前全量快照 · 未解挂项一律禁止认领／开工）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 + **2026-11-19 人类「暂时不做」** | v3 三卡暂停，并入 v4 统一拆卡 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；卡面 todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 + **2026-11-19 人类「暂时不做」** | 厂家后台升级中 | 升级完成 + 复跑探测 + 更新调研文档 | `docs/paper/field-survey-2026-11-07.md` 已入库 | 续跑不重开卡 | 人类 |
| prnmgt | S3 v4 批次 / #18 | 2026-11-07 15:11 + **2026-11-19 人类「暂时不做」** | 纸张口径未定 | S2 结论 + D-5~D-10 裁定 + 新 ADR | 仅 DRAFT（`docs/plan-2026-11-07-paper-sizing-duplex.md`） | 重编卡后认领 | 人类 |
| pCryoxy | — | — | 无挂起项 | — | — | — | — |
| pRayShell | — | — | 无挂起项（项目已终止 closed，非 suspended；旧 D-xxx 草案不得当作开放任务） | — | — | — | — |

- 快照来源：`handoff/2026-11-19-pCryoxy任务认领入口-zhn-tbxg2iah-win.md`，全量继承，**本轮未解挂任何一项**，也不得由 agent 解挂。
- **口径**：项目 `tasks.md` 卡面状态**保持 `todo` 不变**（`check.mjs` 锁死 `todo / doing / blocked / done` 四值），**挂起约束由共享仓层提供**。T-059/T-060/T-061 三张卡面状态未被本轮改动。
- **「基本功能完成」与「挂起」不冲突**：三项全部是增强项（纸张口径细化、真机调研），不涉及采集 / 展示 / 统计 / 排障任何主链路。

---

## 6. 后续接手人须知（5 条）

1. **运维手册在 `docs/operations/`**（四篇：部署 / 发布 / 排障 / **收尾交接**），`README.md` 已改为指向该目录。
2. **不要去补 `verify_all.mjs` 的判定配置** —— 见 §3，补了无效。
3. **采集服务器一律用户名 + 密码登录**（`jifang`），**SSH 密钥认证已被服务端拒绝**。
4. **严禁 `--date` 回溯补历史** —— 计数器终身累计、碳粉当前余量，回溯污染历史曲线。
5. **DDL 变更先写 ADR；发现代码与 PRD 不一致 → 停手、登记 `docs/decisions/OPEN-DECISIONS.md`、上报人类**。

---

## 7. 关键提交号

| 项 | 值 |
|---|---|
| 项目仓收尾提交 | `2f02cea`（`master = origin/master`） |
| 上一主干 | `c2e5219`（v8 批次收官） |
| 线上版本 | `7de9be32-f33a-42b2-8071-2a6deecde362` |
| 业务代码零改动起点 | `d0e7162`（T-074） |
| 共享记忆提交 | 见 `memory/projects/prnmgt.md` 同日条目 |
