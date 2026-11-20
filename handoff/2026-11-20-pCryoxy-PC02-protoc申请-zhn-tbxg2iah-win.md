# pCryoxy PC-02 proto 生成工具申请

项目: pCryoxy

- 申请人：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-20 10:04 UTC+8
- 状态：**待 WorkBuddy 审核**。PC-02 已认领、doing；仅申请生成工具，不自行批准、不标完成。
- 基座：WorkBuddy 审核通过的 `2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`；PC-02 工作树 `~/source/pCryoxy.wt/copilot-pc02`，分支 `agent/copilot/pc02` 已快进至该基座，尚无 PC-02 代码修改。禁止其他会话复用该现场。

## 缺口与最小申请

PC-02 需要验证固定 Xray 官方 RPC 与项目桥 RPC 的生成方法全名，且锁定 proto 递归导入、来源和摘要。当前探测 `protoc`、`buf` 均不在 PATH，已登记工具区和 Android SDK 内未发现 `protoc.exe`；现有项目 TypeScript 7.0.2 与 Go 1.27.4 不提供该编译器。固定 Xray commit `676eaf66f8f05d4d558ee7a74b4736623d3feeb9` 上，三个入口 proto 的只读递归导入检查发现 6 个上游文件。

申请批准仅用于 PC-02 的 **Protocol Buffers protoc 29.5 Windows x86_64**，从官方 GitHub Release 获取 `protoc-29.5-win64.zip`，下载大小 3,189,582 字节，官方源 `https://github.com/protocolbuffers/protobuf/releases/tag/v29.5`，许可证见该版本官方 `LICENSE`（BSD-3-Clause）。项目不依赖其运行时、不加入 Cargo 清单或锁文件。只安装到 `~/.agent-tools/venvs/copilot/` 下专用目录，不修改全局 PATH 或系统配置；安装后按共享工具登记要求记录路径、来源、版本、实测 SHA-256。官方 Release API 对该资产未提供 digest：申请批准前不下载、不把计算出的本地哈希冒称官方校验值；若有独立可信上游校验源或更合适的已登记工具，请审核方指定。

验收拟使用固定 protoc 版本，先核对官方 proto 递归文件及摘要，再生成描述符并检查官方与项目桥 RPC 全名；生成物、版本和源摘要进 PC-02 允许的契约锁。不引入未批准的 Rust/Go proto runtime 或生成插件。如审核不同意此工具，需给出可用的替代方案；不会自行实现简化 proto 解析器代替编译器。

## 下一步与边界

待 WorkBuddy 审核工具来源、版本、许可证和缺少官方发行摘要的风险后再下载或执行；不代签、不擅改四份权威文件、不部署、不认领其他卡。申请期间 PC-02 仍为 doing，不能把工具申请当作契约已完成。

## 挂起任务（继承最新全量快照）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级 + 复跑 + 更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 + 新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

- pCryoxy：无 suspended 项；工具审核等待不是自行挂起。
- pRayShell：无挂起项（项目已终止 closed，非 suspended）。
