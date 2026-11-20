# pCryoxy 项目记忆

> 独立新项目，与 pRayShell 的仓库、文档、任务、配置、运行数据完全隔离（REQ-01）。
> 本文件 append-only；任务登记按「项目 + 任务ID」防撞。权威文档见 `handoff/2026-11-19-pCryoxy任务认领入口-zhn-tbxg2iah-win.md`。

## 1. 项目登记

| 项 | 内容 |
|---|---|
| 项目名 | pCryoxy |
| 定位 | 现代加密代理协议的图形化前端与调度外壳（Rust＋Tokio 调度，Tauri v2 壳，SolidJS/TS/Tailwind UI）；Windows + Android 优先 |
| 代码仓 | **尚未建立**（`env/repos.md` 记为「尚未建立」，无虚构远端、无占位目录；建仓属 PC-00） |
| 约定克隆路径 | `~/source/pCryoxy`（建仓后按登记使用；目录当前不存在） |
| 正式文档 | `handoff/2026-11-19-pCryoxy-需求确认基线-v1.0-zhn-tbxg2iah-win.md`、`…-工程蓝图-v0.2-…`、`…-实施任务卡-v1.0-…`、`…-API-Spec-v1.0-…` |
| 统一入口 | `handoff/2026-11-19-pCryoxy任务认领入口-zhn-tbxg2iah-win.md` |
| 与 pRayShell 关系 | 隔离，不迁移、不覆盖、不修改旧项目成果 |

## 2. 任务登记（append-only）

[@workbuddy @zhn-tbxg2iah-win 2026-11-19 14:36 UTC+8] 【批次登记】pCryoxy v1.0 任务卡全量入册 21 张：P0 卡 PC-00～PC-16 共 17 张、P1 后续卡 PC-P1-01～PC-P1-04 共 4 张，状态一律 `todo`、**认领agent 栏为 `—`（未认领）**。本次仅为登记，不构成任何认领；PC-00 无前置依赖可被符合条件的 agent 认领，其余卡须依赖卡审核通过后才可认领，P1 卡不在本轮实施。防撞键＝项目 + 任务ID；认领须先追加认领行再开工，完成/放弃追加状态行，禁止改写旧行。

| 任务ID | 描述 | 认领agent | 状态 |
|---|---|---|---|
| PC-00 | 建立独立项目与可复现基线（建仓、工具锁定、项目接入；无前置依赖） | — | todo |
| PC-01 | core-ir、P0 入口类型与指纹规范（依赖 PC-00） | — | todo |
| PC-02 | plugin-sdk、桥协议及 IPC 契约冻结（依赖 PC-01） | — | todo |
| PC-03 | 安全存储与强制脱敏（依赖 PC-02） | — | todo |
| PC-04 | 薄 Go 桥：完整快照与无门禁发布（依赖 PC-02） | — | todo |
| PC-05 | Android 原生 TUN 最小真机门禁（依赖 PC-04） | — | todo |
| PC-06 | 订阅、分享链接、冲突与一次入口校验（依赖 PC-01/02/03） | — | todo |
| PC-07 | IR 到固定核心配置与协议矩阵（依赖 PC-02/06） | — | todo |
| PC-08 | plugin-xray 官方 gRPC、出站同步与重放（依赖 PC-04/07） | — | todo |
| PC-09 | 真实探测、健康状态机与策略（依赖 PC-06/08） | — | todo |
| PC-10 | Windows 运行时与系统代理（依赖 PC-03/08/09） | — | todo |
| PC-11 | Android 生产生命周期与服务 IPC（依赖 PC-03/05/08/09） | — | todo |
| PC-12 | Geo 基础包、手动更新与跨层回滚（依赖 PC-04/07/08/10/11） | — | todo |
| PC-13 | 双端核心升级、兼容配置与回退（依赖 PC-10/11/12） | — | todo |
| PC-14 | Tauri Commands、DTO、操作状态与事件（依赖 PC-02/06/09/10/11/12/13） | — | todo |
| PC-15 | SolidJS 页面与高频状态展示（依赖 PC-14） | — | todo |
| PC-16 | 整机安全、故障、性能与发布验收（依赖 PC-15） | — | todo |
| PC-P1-01 | AI 完整工具调用（依赖 PC-16；不在本轮实施） | — | todo |
| PC-P1-02 | 吞吐测速高级功能（依赖 PC-16；不在本轮实施） | — | todo |
| PC-P1-03 | 一致性哈希负载均衡（依赖 PC-16；不在本轮实施） | — | todo |
| PC-P1-04 | Windows TUN/进程分流（依赖 PC-16；不在本轮实施） | — | todo |

> 依赖列以 `pCryoxy-实施任务卡-v1.0` 卡面「依赖」字段为准；上表为登记摘要，冲突时以卡面为准。

## 3. 挂起与阻塞

- 本项目无挂起项。
- 待人类提供/裁决事项记录在此节，不并入挂起快照。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-19 15:24 UTC+8] 【认领】项目：pCryoxy | PC-00 | 建立独立项目与可复现基线 | 状态：doing

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-19 17:50 UTC+8] 【完成提交】项目：pCryoxy | PC-00 | 远端 `https://gitee.com/ParvaUltra/pCryoxy.git`，默认分支 `main`，最终提交 `3288de7b501265e47443db30cc7d86094bfcbd45`；Windows x64 与 Android arm64-v8a/x86_64 release 空壳构建已在干净 checkout 实测。`adb devices -l` 无设备，因此按卡面状态：**blocked（待真实 Android 设备）**，未标 done，交 WorkBuddy 审核。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-19 17:54 UTC+8] 【状态补充】PC-00 构建实测提交为 `3288de7b501265e47443db30cc7d86094bfcbd45`；随后仅补录 Gradle/AGP 实际解析值，远端最终提交为 `c3dae630d64669d619c24a00cfab22c01928d28a`。状态仍为 **blocked（待真实 Android 设备）**，不改前一行结论。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-19 18:08 UTC+8] 【复审通过】项目：pCryoxy | PC-00 | 状态：done。依据：用户于 18:04 裁定将 PC-00 的 Android 真机验收门槛移交 PC-05。按调整后的空壳构建基线验收：执行方在 3288de7 记录 Windows x64 与 Android 双 ABI 干净构建，审核核对至 c3dae63 仅变更构建说明；未独立重编，不计真机通过。此前 blocked 为原门槛下的历史结论。PC-05 须补真实设备证据，缺设备仍阻塞；本条不放行 PC-05。PC-01 的 PC-00 前置审核已满足，须独立查撞、追加认领并同步后开工，本条不是认领记录。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-19 18:20 UTC+8] 【认领】项目：pCryoxy | PC-01 | core-ir、P0 入口类型与指纹规范 | 状态：doing

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-19 18:43 UTC+8] 【交付待审核】项目：pCryoxy | PC-01 | 分支：`agent/copilot/pc01` | 提交：`701ad88b6af9288dcd5d3f550bf7b7ac916db4c8`；实际合同测试 13/13，workspace 测试与 release check 退出码 0。未认领其他卡，未自行标 done，待 WorkBuddy 审核。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-19 18:50 UTC+8] 【审核结论】项目：pCryoxy | PC-01 | 状态：doing（退回返工）；原提交 `701ad88` 保留，具体返工项待 WorkBuddy 退回单/用户粘贴。PC-02 暂不放行；未认领、未开工。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-19 19:05 UTC+8] 【返工交付待复审】项目：pCryoxy | PC-01 | 原分支 `agent/copilot/pc01` | 返工提交：`3a994011832a3494e6adbceb6b5937830eb8735b`。对应 WorkBuddy 三项退回：SNI 等价语义、规则重排 affected、独立内部存储往返均已修复；合同测试 15/15，workspace test/release/clippy 均通过。状态仍为 doing，PC-02 未放行。
