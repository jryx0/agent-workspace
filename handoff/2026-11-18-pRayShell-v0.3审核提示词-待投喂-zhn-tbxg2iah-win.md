# pRayShell v0.3 设计文档独立审核提示词

> 状态：待投喂  
> 用途：交其他 Agent 独立审查 pRayShell v0.3 文档  
> 本提示词发起标识：`copilot@zhn-x-w`  
> 本提示词不构成实施认领、不授权改代码、不授权制卡

## 项目交接

- 项目：pRayShell
- 交接文档：`~/source` 对应共享层 handoff `2026-11-18-pRayShell-v0.3设计评审待复核-zhn-tbxg2iah-win.md`
- 文档 worktree：`~/source/pRayShell.wt/copilot-second-round`
- Branch：`agent/copilot/prayshell-second-round`
- 文档目录：`docs/`
- 基座：`master` @ `3d551c9edb009bc313c1966864584dcbe3152bfc`
- 任务类型：**只读审核**

## 需要你审核的文件

先读交接 handoff，再审核以下文件：

1. `docs/PRD.md`
2. `docs/ARCHITECTURE.md`
3. `docs/TASK_BREAKDOWN.md`
4. `docs/TEST_STRATEGY.md`
5. `docs/TEST_REPORT_TEMPLATE.md`
6. `docs/DOCUMENT_COMPARISON.md`
7. `docs/DELIVERY_SUMMARY.md`

同时读取但**不要修改**：

- 根目录 `PRD.md`
- 根目录 `ARCHITECTURE.md`
- 根目录 `TASK_BREAKDOWN.md`
- 根目录 `DELIVERY_SUMMARY.md`
- 根目录 `AGENTS.md`

## 已确认需求

审核时必须按以下决策判断，而不是重新定义产品：

1. Windows + Android 同步首发；HarmonyOS NEXT 后置，不阻塞首发。
2. xray-core 是首发必选默认核心组件。
3. 程序本身支持自动/手动更新。
4. xray-core 独立于应用更新，支持检查、兼容校验、安装与回滚。
5. Geo 文件独立版本管理，支持自动/手动更新与回滚。
6. 支持类似 v2rayN 的 GeoIP/GeoSite 类规则分流。
7. 最终程序以小体积为发布门槛；不接受未测量的固定 MB 承诺。
8. 后续可接入其他核心，但首发不实现第二核心。
9. 核心扩展只能通过插件/adapter/capability，不得让平台或核心类型渗入领域层。
10. 模块化必须支持多个 Agent 独占文件并行。

## 审核目标

你要做的是**高置信度设计审查**，不是补写方案、不是实现、不做词句润色。

查找以下可阻断后续实施的问题：

### 1. 需求闭环

- 用户需求是否全部映射到 PRD 功能、架构接口、任务草案和测试。
- Windows/Android 首发、xray-core、更新、Geo、小体积、插件、多 Agent 是否有对应验收。
- 是否出现只写在 PRD、但架构/任务/测试未承接的孤立需求。

### 2. 架构正确性

- `ICoreProvider` / `ICoreRuntime` 是否足以隔离 xray-core。
- 程序、xray-core、Geo 三类更新是否分别建模版本、manifest、校验、staging、兼容、切换和回滚。
- Windows updater 与 Android 系统安装权限是否被正确限制。
- Geo 缺失/损坏/升级/回滚时是否有安全且可解释的行为。
- SQLite、UI 框架、进程形态、FFI 或特定 ABI 是否被过早写进公共业务层。
- AI、publisher、secret 是否可能绕过端口直接触发 runtime 或系统网络变更。

### 3. 平台边界

- Windows 的系统代理/PAC/TUN、旧状态恢复、进程生命周期是否闭环。
- Android 的 `VpnService`、前台服务、授权撤销、Doze、网络变化是否闭环。
- HarmonyOS NEXT 是否只作为后置平台，且未被错误纳入首发准出。
- 是否错误地把 Linux ARM64、Go、OpenHarmony 或 Android 能力当作 HarmonyOS 支持证据。

### 4. 小体积

- 技术候选是否明确比较安装包、运行时、ABI、Geo、调试符号和可选模块的体积分解。
- 是否存在跨平台 UI/共享核心选择导致重复 runtime、重复 ABI 或大体积资源。
- release budget 是否作为实施前需实测锁定的门禁，而不是虚构已完成数字。

### 5. 任务与并行

- B0 公共契约是否足够先冻结。
- D-xxx 草案是否存在依赖成环、独占文件重叠或公共文件并行修改。
- Windows/Android、core provider、Geo、update、UI、测试是否可独立派发。
- 是否误把 D-xxx 草案写成已认领任务、已完成实现或已执行测试。

### 6. 测试可验证性

- P0 功能是否有 Unit / Contract / Integration / Platform / Security 对应 case。
- app/core/Geo 更新的错包、完整性失败、兼容失败、中断、冒烟失败、回滚是否全覆盖。
- Geo 命中、未知分类、缺失、损坏、升级、回滚是否可验证。
- Windows/Android 体积分解是否能产出可比对的报告。
- 所有测试数字是否明确来自真实运行，而不是模板预填。

### 7. 安全与合规

- 订阅 URL、节点 UUID/密码、pbk/sid、AI key、发布 token 是否可能入库、日志、崩溃报告或 Geo/update 文档。
- 更新下载来源、哈希/签名、重定向、平台/ABI 错配是否安全。
- 共享仍保持默认关闭、DryRun、撤销和来源授权边界。
- 没有复制 v2rayN 或其他 GPL 客户端源码，也没有基于完整客户端 Fork。

## 必须忽略的非问题

- v0.3 尚未锁定 UI 语言：这是设计约束，不是遗漏。
- 尚未给出固定 MB 体积阈值：要求先由双平台最小原型实测。
- HarmonyOS 缺少完整实现方案：本轮明确后置，不阻断首发。
- 未生成正式任务卡：用户要求先评审文档。
- 未实现代码、未执行测试、未填测试报告：符合本轮只出文档的范围。
- `TEST_REPORT_TEMPLATE.md` 全部是 `__PENDING__`：符合未执行约束。

## 禁止操作

你必须遵守：

1. 只读审核，不修改任何文件。
2. 不编写工程代码、不添加测试代码。
3. 不生成正式任务卡、不认领 D-xxx、不更新任务状态。
4. 不修改根目录四份其他 Agent 文档。
5. 不修改 `AGENTS.md`、共享 rules、memory 或 handoff。
6. 不 commit、不 merge、不 push、不 deploy、不 install。
7. 不碰主 worktree 的既有未提交改动。
8. 不读取或打印任何真实节点、订阅、token、API key。
9. 不触碰 `prnmgt` 的 S1/S2/S3 挂起项。

## 挂起任务防撞

以下仍 suspended，一律不得认领或开工：

| 项目 | 任务 |
|---|---|
| prnmgt | S1 T-059/T-060/T-061 |
| prnmgt | S2 P0 二次真机调研 |
| prnmgt | S3 v4 批次 / #18 |

这些项与本次 pRayShell 审核无关。

## 输出格式

只输出以下结构；不要重写整份方案：

```markdown
# pRayShell v0.3 审核结论

## 总体结论

结论：通过 / 有条件通过 / 退回

## 阻断项

1. **[ID] 标题**
   - 文件/位置：
   - 影响：
   - 证据：
   - 必须修正：

## 高优先建议

1. ...

## 低优先建议

1. ...

## 需求覆盖确认

| 用户需求 | PRD | 架构 | 任务 | 测试 | 结论 |
|---|---|---|---|---|---|

## 需要用户裁决

1. ...

## 验证范围

- 已读文件：
- 未读/不可用文件：
- 是否发现凭据风险：
- 是否发现实现过早或平台假设泄漏：
```

## 判定标准

- 存在影响 Windows/Android 首发可行性的错误、无法验证的接口、不可回滚更新链、核心/Geo 解耦缺失、严重安全风险或多 Agent 依赖成环：**退回**。
- 核心方案成立但仍有可在用户确认前修正的缺口：**有条件通过**。
- 无阻断项，需求/架构/任务/测试均闭环：**通过**。

你在输出中必须区分：

- 阻断事实；
- 设计建议；
- 需要人类裁决的选择；
- 必须依赖后续 PoC/实测才能确认的事项。

不要把 PoC 待证事项写成已知缺陷，也不要把建议伪装成需求。

> 投喂署名：`[@copilot@zhn-x-w 2026-11-18 UTC+8] 仅请求独立只读审核；审核 Agent 请在回复中标明自身身份。`
