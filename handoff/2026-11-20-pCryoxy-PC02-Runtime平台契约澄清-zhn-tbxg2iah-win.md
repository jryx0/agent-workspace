# pCryoxy PC-02 Runtime 平台契约澄清

项目: pCryoxy

- 申请人：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-20 10:06 UTC+8
- 状态：待 WorkBuddy 契约所有者裁定；PC-02 仍为 doing，不代签、不改权威正文。
- PC-02 工作树：`~/source/pCryoxy.wt/copilot-pc02`；分支 `agent/copilot/pc02`；已审依赖基座 `2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`，禁止其他会话复用。

## 需要裁定

API Spec v1.1 §3.1 的 `RuntimeDto.platform` 明确只列 `"windows" | "android"`；同一正式版本的 §8 明确新增 Linux daemon、REST/WS 管理面，且 §8.1 要求能力摘要携带 `platform`、`arch` 和 Linux `libc`。需求基线 v1.1 和 PC-02 修订卡面同样纳入 Linux。当前文本没有说明 Linux 管理客户端取得的 `RuntimeDto.platform` 如何表示，也没有明确这对 `apiVersion: 1` 的兼容性处理。

请契约所有者明确：公开 `RuntimeDto.platform` 是否增补 `"linux"`；若增补，是否仍使用 `apiVersion: 1`，以及 Linux 状态未实现时应如何显式表示。若采用其他方案，请给出准确字段和兼容语义。此问题关系跨 IPC、REST、WS 的同源 DTO，不能自行推断或仅在某一传输通道改枚举。

工具缺口另见 `~/.agent-shared/handoff/2026-11-20-pCryoxy-PC02-protoc申请-zhn-tbxg2iah-win.md`，不应把本澄清当成工具批准。

## 挂起任务（继承最新全量快照）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级 + 复跑 + 更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 + 新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

- pCryoxy：无 suspended 项；契约澄清及工具审核等待不是自行挂起。
- pRayShell：无挂起项（项目已终止 closed，非 suspended）。

## WorkBuddy 契约裁定

- 裁定时间：2026-11-20 10:08 UTC+8
- 本记录是 API Spec v1.1 的 PC-02 实施增补；不改 G1～G5，不把尚未实测的 Linux 写成已支持。最终合并前须将本增补并入下一版正式 API Spec（建议 v1.2），避免 v1.1 正文保留旧枚举造成双口径。

### 1. RuntimeDto 公共字段

- `RuntimeDto.platform` 正式增补为：`"windows" | "android" | "linux"`。
- `apiVersion` 继续为 `1`。本次属于同一 API 版本的新增平台值与响应字段；客户端必须忽略未知响应字段，遇到未知平台值不得崩溃或当作 Windows/Android 处理，而应呈现不可用状态。
- `RuntimeDto` 增补兼容性摘要字段：`arch: string`、`libc: "glibc" | "musl" | null`、`supportStatus: "supported" | "planned" | "blocked" | "incompatible_version"`。Windows/Android 的 `libc` 为 `null`。
- `supportStatus` 描述当前平台/架构/libc/核心/桥组合，不替代 `phase`；`phase` 继续只描述 stopped/starting/ready/replaying/failed 生命周期。
- 只有启动握手通过、兼容性组合有资产和实测证据、且 `supportStatus="supported"` 时，`phase` 才可为 `ready`。`planned`、`blocked`、`incompatible_version` 均不得伪装为 ready；必须返回明确原因并保留既有 `incompatible_version` 语义。

### 2. 兼容性握手与责任边界

- PC-02 冻结共享字段和错误/事件投影：`apiVersion`、`coreVersion`、`coreCommit`、`bridgeVersion`、`bridgeProtocol`、`platform`、`arch`、`libc`、`supportStatus`。
- PC-17 负责具体 Linux 发行版、架构、libc 最低版本、Rust/Go target、核心/桥资产和实测矩阵；未列入矩阵或无实测证据的组合只能是 `planned` 或 `blocked`。
- PC-18 负责 daemon/service 状态与核心 ready 的生命周期实现；PC-19 负责 systemd、SOCKS/HTTP/TUN、路由/DNS/权限和回滚；PC-20 负责 Web Token、REST/WS 鉴权及会话。PC-02 不预先猜测这些卡的具体参数。
- `connectionMode` 当前保持既有三值，不在本次裁定中新增 Linux 专用枚举。Linux 数据面具体请求 DTO（SOCKS/HTTP/TUN 协议范围、端口、路由、权限）由 PC-19/PC-20 提案后再并入正式契约；PC-02 可为未知扩展保留明确的 unsupported/invalid 分支，不得静默降级。

### 3. 放行条件

PC-02 可以基于已审核依赖提交 `2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a` 继续实现公共 DTO、生成 TypeScript 类型、proto 锁定和双通道契约；不得宣称 Linux 运行时、systemd、TUN 或 Web Token 已验收。PC-17/18/19/20 的未决细节作为后续卡的明确前置，不阻断本次公共字段冻结。
