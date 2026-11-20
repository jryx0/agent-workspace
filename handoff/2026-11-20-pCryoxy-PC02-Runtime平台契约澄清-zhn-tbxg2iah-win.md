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
