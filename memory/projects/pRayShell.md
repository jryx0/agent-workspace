# pRayShell · 项目记忆

> 规范七要求：每个登记项目在 `memory/projects/<项目名>.md` 维护独立记忆文件。
> 格式：`[@agent @设备 YYYY-MM-DD HH:mm UTC+8] 内容`（append-only）

---

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-15 11:23 UTC+8] 项目基础信息登记与第一轮设计交付

| 项 | 值 |
|---|---|
| 项目名 | `pRayShell` |
| 本地路径 | `~/source/pRayShell`（本地 git 仓，默认分支 `master`，**无 remote**） |
| 定位 | 面向互联网公开免费代理节点的 xray-core 客户端：订阅/手输获取节点、自动探测延迟与可用性组成策略组、按策略语义剔除失效与不稳定节点、定时更新订阅、用户明确同意后共享节点；插件化模块化 + AI 对话接口对接层 |
| 本轮交付 | **仅设计**：`PRD.md` / `ARCHITECTURE.md` / `TASK_BREAKDOWN.md` / `DELIVERY_SUMMARY.md` 共 4 份；支撑文件 `AGENTS.md` / `.gitignore` |
| 未交付（第二轮） | 原 5 项之 ④⑤，细分 3 类产物：工程代码与 AI 对接层 / 测试用例文件 / 测试报告（`TEST_REPORT.md` 模板内嵌 `TASK_BREAKDOWN.md` §5.5，全 `__PENDING__`） |
| 技术选型 | **未锁定**（用户拍板延后）；`ARCHITECTURE.md` §2 为候选评估 + 7 条开放 ADR（全 OPEN）。本机运行时：Python 3.13.14 / Node 22.22.2 / dotnet 10.0.401 可用，Go 未安装，Rust 未确认 |
| 权威资料源 | Xray 字段以 `https://xtls.github.io/config/`（中文默认）+ `https://xtls.github.io/llms-full.txt` 为准；用户给的 `/document/` 是使用指南/教程区，官方自承「相当久没更新」，不作字段依据 |
| 资产隔离 | `~/source/repos/XrayShell`（118 行需求大纲、非 git、未实现，其「Tauri 2 已确认」结论**不继承**）与 `~/source/repos/v2rayN`（GPL-3.0 C#/.NET，仅行为参考、**不复制源码**、不触碰其未提交改动）均为独立资产，不迁移不覆盖 |
| 凭据边界 | 节点分享链接与订阅 URL 等同凭据，**永不入 Git / 不入库 / 不进日志 / 不写进任何交付文档**；唯一落点为项目本地 gitignored `config/*.local`，经环境变量或 OS 凭据库由 `ISecretProvider` 单点读取；不列入 `keys-checklist.md` 的 `config/` 存在性核对（规范七-1） |
| 真机夹具 | 用户已提供 1 个稳定节点 + 2 个不稳定订阅源（**凭据未写入任何文件**），本轮不消费、不验证，留第二轮；预期按 strategy 分支写、不保证剔除 |
| 边界状态 | 项目仓不推任何远端、不 git sync、不部署；共享仓登记按 T2 append-only |
| 会话档位 | T2（新建 `~/source` 项目 + 写共享仓登记）；规范 v2.7，已出开工前自检简报 |

---

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-19 14:13 UTC+8] 【项目终止】pRayShell | 用户明确要求终止项目、关闭相关任务并清理临时文件。正式任务卡从未生成/认领；`TASK_BREAKDOWN.md` 中 D-001~D-076 仅为设计草案，不视为开放卡。会话任务 8/8 已完成并关闭。隔离 worktree `~/source/pRayShell.wt/copilot-second-round` 已清理，提交 `b07c2c7b90beb868d5c1eefac1d1dafa4e928e51` 保留在分支 `agent/copilot/prayshell-second-round` 供审计。主仓 `~/source/pRayShell` 及其既有 dirty 文件不删除、不代提交。状态：terminated（closed）；解散开发活动，不再制卡、不再实施，除非人类另行重启并重新认领。
