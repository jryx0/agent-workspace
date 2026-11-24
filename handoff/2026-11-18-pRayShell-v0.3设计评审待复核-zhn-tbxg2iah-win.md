# pRayShell v0.3 设计评审待复核

- 项目: pRayShell
- 日期: 2026-11-18
- 执行设备: `zhn-tbxg2iah-win`
- 当前执行者: `copilot@zhn-x-w`（Copilot SDK in VS Code，本轮仅做设计文档）
- 其它 Agent 交互标识: `copilot@zhn-x-w`
- 任务性质: 文档修订、跨 Agent 评审交接；未认领实施卡、未写工程代码
- Worktree: `~/source/pRayShell.wt/copilot-second-round`
- Branch: `agent/copilot/prayshell-second-round`
- 基座: `master` @ `3d551c9edb009bc313c1966864584dcbe3152bfc`

## 当前状态

v0.3 设计文档已完成修订并通过静态复核，当前等待：

1. 人类确认本轮需求与产品边界；
2. 其他 Agent 进行架构/需求/任务拆解复核；
3. 用户确认后，由主 Agent 制作正式任务卡并分派实施；
4. 实施 Agent 产出工程/测试后，由本会话对应的主审角色负责审核。

本轮没有实现、没有运行测试、没有安装依赖、没有部署、没有 push、没有 `git sync`。

## 挂起任务（当前全量快照 · 未解挂项一律禁止认领／开工）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停，合并为一次 ALTER + 一次部署 | S3 人类裁定 + 新 ADR 批准 + 重编卡面 | 无 worktree；卡面 todo | 重编后重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级中 | 升级完成 + 复跑探测 + 更新调研文档 | tmp 快照保留；worktree 已 remove | 续跑不重开卡 | 人类 |
| prnmgt | S3 v4 批次 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 裁定 + 新 ADR | 仅 DRAFT | 裁定后重编拆卡 | 人类 |

**防撞口径**：按“项目 + 任务ID”匹配；pRayShell 当前无挂起任务，本轮未认领任何实施任务。共享仓 `pRayShell.md` 未写认领事件。

## 已完成

### 1. 已确认的新需求

以下需求已写入 v0.3：

- Windows + Android 同步首发；HarmonyOS NEXT 后置，不阻塞首发。
- xray-core 是首发必选默认核心组件，不是可选插件。
- 程序本身支持自动检查/手动检查与安装更新。
- xray-core 独立于应用更新，支持版本检查、兼容校验、原子切换和回滚。
- Geo 数据独立于应用与核心版本管理，支持更新/回滚。
- 支持类似 v2rayN 的 GeoIP/GeoSite 类规则分流。
- 最终产物以“小体积”为发布门槛；要求安装包分项报告与 release budget。
- 保留后续其他核心接入能力，通过 `ICoreProvider` / capability / config schema 隔离。
- 继续坚持插件化、模块化、端口隔离，便于多 Agent 并行开发。

### 2. 文档产物

只在隔离 worktree 的 `docs/` 下新增：

| 文件 | 内容 |
|---|---|
| `docs/PRD.md` | v0.3 产品需求、用户故事、功能优先级、首发平台、更新/Geo/体积约束 |
| `docs/ARCHITECTURE.md` | v0.3 平台无关架构、核心/Geo/更新 DTO、API、状态机、时序与技术路线 |
| `docs/TASK_BREAKDOWN.md` | B0–B6 任务草案、文件职责、API Spec、Agent 并行边界 |
| `docs/TEST_STRATEGY.md` | Windows/Android/共享层测试、更新回滚、Geo、体积预算矩阵 |
| `docs/TEST_REPORT_TEMPLATE.md` | 未执行测试报告模板；全部结果为 `__PENDING__` |
| `docs/DOCUMENT_COMPARISON.md` | 与根目录其他 Agent 四份文档的优缺点和冲突比较 |
| `docs/DELIVERY_SUMMARY.md` | 交付说明、平台结论、待裁决项、后续流程 |

### 3. 关键架构决策

- 平台无关层冻结：DTO / JSON Schema / 错误码 / 纯领域算法 / capability。
- 首发平台层：
  - Windows：系统代理/PAC/TUN、进程/库 runtime、Windows updater。
  - Android：`VpnService`、前台服务、Keystore、系统安装器、移动 xray runtime。
- xray-core：
  - 首发必选默认核心；
  - 通过 `ICoreProvider` 和 `ICoreRuntime` 隔离；
  - 其他核心未来可插入，不修改订阅、健康、策略、Geo 和 UI 用例。
- 更新：
  - 组件分为 `app / core / geo / extension`；
  - manifest 必须匹配 platform / ABI / channel；
  - 强制大小、哈希、签名、兼容性、staging、smoke、原子切换与回滚。
- Geo：
  - GeoIP/GeoSite 类资产有独立版本；
  - 缺失或损坏不得伪造为确定分流结果；
  - 规则经 `RoutingIntent` 映射到当前核心 provider。
- 体积：
  - 暂不伪造 MB 阈值；
  - 先用最小原型实测 Windows/Android，再冻结 release budget；
  - Android 按 ABI 分包；release 排除 symbol/debug/test fixture/冗余 locale。

## 验证结果

- 7 份 Markdown 存在。
- 本地 Markdown 链接检查通过。
- 未发现真实 URL、API key/token、UUID、Windows 盘符绝对路径或不可见控制字符。
- `docs/` 之外无新增项目产物。
- 主 worktree 原有改动未触碰：
  - `M AGENTS.md`
  - `?? .agents/`
  - `?? .github/`
- 隔离 worktree 当前仅有 `?? docs/`，尚未提交。
- pRayShell 本仓无 remote；本轮未 push、未 sync、未部署。
- T2 工具自检通过：
  - `tools-scan.sh --check` 通过；
  - `proxy-check.sh` 通过；
  - compact lock 不存在；
  - MCP 9101 离线，本任务使用内置文件工具，判不适用；
  - 未安装任何依赖。

## 给其他 Agent 的审核重点

其他 Agent 只审核，不改本次文档，建议输出：

1. 需求遗漏：用户提出的任何需求是否缺少 PRD 映射。
2. 架构缺陷：Windows/Android 是否都能由当前端口实现，是否存在平台 API 泄漏到领域层。
3. 更新安全：app/core/Geo 更新能否防错包、校验失败、兼容失败、启动失败与断电。
4. Geo 完整性：Geo 数据、规则、xray provider 映射和缺失降级是否闭环。
5. 体积风险：候选 UI/共享核心是否会破坏“小体积”目标。
6. 核心扩展：`ICoreProvider` 是否足以接入其他核心而不改业务层。
7. 多 Agent 并行：是否有任务独占文件冲突、公共契约过晚冻结、依赖成环。
8. 测试覆盖：Windows/Android 的 P0、安全、更新、Geo、体积是否有可执行证据入口。
9. 事实准确性：不得把 xray-core 在 HarmonyOS NEXT 的可行性写成已确认。
10. 合规：不复制 GPL 客户端源码；不泄露节点、订阅或更新凭据。

审核结论格式建议：

```text
结论: 通过 / 有条件通过 / 退回
阻断项:
高优先建议:
低优先建议:
证据/文件位置:
```

## 待用户确认／裁决

| 项目 | 待确认事项 |
|---|---|
| pRayShell | 是否确认 v0.3 的“平台无关基线先行、Windows + Android 首发、HarmonyOS 后置” |
| pRayShell | Windows/Android 先做原生双端还是 Flutter/KMP 体积 PoC |
| pRayShell | 应用、xray-core、Geo 的 release channel、签名体系与自动安装权限 |
| pRayShell | Geo 基础数据内置还是按需下载 |
| pRayShell | 首发安装包体积基线与测试设备 |
| pRayShell | AI、节点共享是否纳入首发或保留 P1 |
| pRayShell | HarmonyOS NEXT 在哪个首发里程碑后启动 |

## 不应做的事

- 不要把 `docs/TASK_BREAKDOWN.md` 中 D-xxx 草案当作已正式认领或已派工。
- 不要先实现业务功能而跳过 B0 契约冻结与审核。
- 不要修改根目录四份其他 Agent 文档。
- 不要触碰主 worktree 的既有未提交改动。
- 不要在共享仓 `memory/projects/pRayShell.md` 追加“doing”认领；本轮未获用户的正式制卡/派工确认。
- 不要把 HarmonyOS 作为首发依赖或宣称 xray-core 已支持。
- 不要把未知体积阈值写成已确认数字。
- 不要安装全局/用户级依赖。

## 下一步指令

1. 其他 Agent 对 v0.3 七份文档执行独立复核。
2. 主 Agent 汇总分歧，形成最终确认版或按意见更新。
3. 人类确认技术路线、更新源、体积基线与首发范围。
4. 主 Agent 将通过的任务草案拆成正式任务卡。
5. 其他 Agent 按独占 worktree + `agent/*` 分支实施。
6. 主 Agent 审核实现、测试报告和体积分解；未通过项退回执行 Agent。

## 开工自检摘要

- 档位：T2。
- 项目：pRayShell。
- 任务认领：无，本轮仅文档；不与 suspended 冲突。
- 挂起：prnmgt S1/S2/S3 未解挂，本轮未触碰。
- Worktree：隔离分支 `agent/copilot/prayshell-second-round`。
- 依赖：未安装。
- 工具：基线通过。
- Git/代理：共享仓双远端与代理核对通过；pRayShell 无 remote。
- 共享写入：仅本 handoff 新文件；未修改既有 handoff、memory 或 shared rules。

> 交接署名：`[@copilot@zhn-x-w 2026-11-18 UTC+8] pRayShell v0.3 设计评审待复核；本文档未认领实施任务。`
