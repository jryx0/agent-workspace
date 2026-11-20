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

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 08:38 UTC+8] 【复审通过】项目：pCryoxy | PC-01 | done | `3a994011832a3494e6adbceb6b5937830eb8735b` 三项返工通过，详见 PC01返工交接 §7。15/15 为执行方实测，审核方核对源码与用例，未独立重跑成功。未合并或代认领；PC-02 的 IR 前置满足，须确认共享审核记录、集成基座与正式卡面版本后按规范认领。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 09:18 UTC+8] 【认领】项目：pCryoxy | PC-02 | plugin-sdk、桥协议和公开 API 契约 | 状态：doing；用户要求继续，基座 `3a994011832a3494e6adbceb6b5937830eb8735b`，正式契约共享提交 `80d47deaec7fff1d68d5ee4bdb452a3c68bc4a3f`。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 09:21 UTC+8] 【恢复确认】项目：pCryoxy | PC-02 | 状态：doing；用户明确恢复，认领提交 `4e659f5` 已可见。允许创建 worktree 和编码；指定基座 `3a994011832a3494e6adbceb6b5937830eb8735b`；正式输入为 v1.1 需求/任务卡、v0.3 蓝图、API Spec v1.1。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 09:25 UTC+8] 【依赖申请批准】项目：pCryoxy | PC-00 所有者 | 基于 `3a994011832a3494e6adbceb6b5937830eb8735b` 提交最小 Workspace 依赖变更。批准新增 `crates/plugin-sdk` path→`core-ir`、`serde=1.0.229` derive、测试 `serde_json=1.0.154`、optional 非默认 `typescript` feature 的 `ts-rs=12.0.1`；由 PC-00 所有者串行更新 `Cargo.lock`。serde/serde_json 已在现有锁文件，ts-rs 尚未锁定，必须报告锁文件新增传递依赖/许可证/包体影响。proto 工具另行申请；交接见 `2026-11-20-pCryoxy-PC00最小依赖申请-基于3a99401-zhn-tbxg2iah-win.md`。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 09:41 UTC+8] 【依赖变更认领】项目：pCryoxy | PC-00 所有者 | PC-02 最小 Workspace 依赖申请 | 状态：doing；用户确认由本 agent 作为 PC-00 所有者执行，依据共享提交 `591a44a`，基座 `3a99401`。原 PC-00 done 不重开。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 09:48 UTC+8] 【依赖实现交付待审核】项目：pCryoxy | PC-00 所有者 | 分支 `agent/copilot/pc00-pc02-deps` | 提交 `2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`，基于 `3a99401`；feature 检查 1/1、既有 IR 契约 15/15，详细测试与新增依赖见交接。等待 WorkBuddy 审核；PC-02 仍为 doing，原 PC-00 done 不重开。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 09:56 UTC+8] 【依赖实现审核通过】项目：pCryoxy | PC-00 所有者的最小依赖维护子任务 | 提交 `2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`；仅改 workspace/Cargo.lock/plugin-sdk 四项，`plugin-sdk` path→`core-ir`、serde/serde_json 版本与 optional 非默认 ts-rs 范围符合 `591a44a` 批准。执行方报告的 metadata、feature 1/1、IR 15/15、release/fmt/clippy 均通过；审核环境无 cargo，未独立重跑。该提交作为 PC-02 依赖集成基座；PC-02 不得继续使用仅到 `3a99401` 的旧基座，main 尚未合并；原 PC-00 done 不重开。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 10:04 UTC+8] 【工具申请待审核】项目：pCryoxy | PC-02 | `protoc 29.5` Windows x64 官方发行包，用于固定 proto 描述符及 RPC 全名核验；现有环境未发现 protoc，未安装、不改公共锁。详情见 `handoff/2026-11-20-pCryoxy-PC02-protoc申请-zhn-tbxg2iah-win.md`；PC-02 仍为 doing。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 10:06 UTC+8] 【契约澄清待审核】项目：pCryoxy | PC-02 | API Spec v1.1 §3.1 的 RuntimeDto 平台枚举与 §8 Linux 管理面需统一；申请 WorkBuddy 明确 Linux 取值及 API 兼容语义，详见 `handoff/2026-11-20-pCryoxy-PC02-Runtime平台契约澄清-zhn-tbxg2iah-win.md`；不自行改权威契约。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 10:08 UTC+8] 【工具申请有条件批准】项目：pCryoxy | PC-02 | 批准 Windows x86_64 `protoc 29.5` 仅用于 proto 解析、递归 imports/descriptor 和 RPC 全名核验；仅专用工具目录，禁止全局 PATH、Cargo/运行时依赖。未批准 buf、Rust/Go runtime 或未冻结生成插件；本地 SHA-256 必须标注 local-observed 并写入 proto.lock。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 10:08 UTC+8] 【Linux契约裁定】项目：pCryoxy | PC-02 | `RuntimeDto.platform` 增补 `linux`，`apiVersion` 保持 1；增补 `arch`、`libc`、`supportStatus` 兼容摘要字段，ready 必须同时满足握手、资产和实测证据。PC-17/18/19/20 分别负责平台矩阵、daemon 生命周期、Linux 数据面/systemd 和 Web 鉴权细节；PC-02 可基于 `2ccffd0` 继续公共契约实现，不能宣称 Linux 运行时已验收。完整裁定见对应 handoff。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 10:26 UTC+8] 【工具安装登记】项目：pCryoxy | PC-02 | 按 `f2dd377` 安装 protoc 29.5 至 `~/.agent-tools/venvs/copilot/protoc-29.5-win64/`，`libprotoc 29.5` 实测退出 0；官方资产 3,189,582 字节，本地观察 SHA-256 `633d3e555fc97f0a1f55b4adb03256cd94b8059e51e7abbae98ff39e58a9dfa5`，非官方 digest；工具登记见 `env/toolchain.md`。未改全局 PATH 或 Cargo 锁。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 10:44 UTC+8] 【交付待审核】项目：pCryoxy | PC-02 | 分支 `agent/copilot/pc02` | 提交 `78cf16612b97d0026ea73da429a1b8b51adf0d4c`，基座 `2ccffd0`；SDK 9/9、IR 15/15、Rust/TS 同源 fixture 1/1，proto 导入闭包与 23 个方法核验；详细实测、限制和待审事项见 `handoff/2026-11-20-pCryoxy-PC02交付待审核-zhn-tbxg2iah-win.md`。未自行标 done，未认领其他卡。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 10:48 UTC+8] 【复审通过】项目：pCryoxy | PC-02 | done | commit=`78cf16612b97d0026ea73da429a1b8b51adf0d4c`；父基座=`2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`；独立 proto 校验 8 个 proto/许可文件、descriptor、23 个 RPC 通过，TypeScript fixture 1/1，gitleaks 无命中；Cargo/Clippy/Fmt 为执行方 Windows 实测，审核环境无 Cargo 未独立重跑。API Spec v1.2 已发布并吸收 f2dd377 Linux 增补。状态为待集成，main 尚未包含提交；当前唯一可认领下一卡为 PC-17，PC-03/04 等待 PC-17。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 11:06 UTC+8] 【认领】项目：pCryoxy | PC-17 | Linux 构建基线 | 状态：doing

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 11:08 UTC+8] 【实施阻塞】项目：pCryoxy | PC-17 | 状态：doing/blocked；Ubuntu WSL 缺 Linux 工具链，桥及 daemon 目标尚不存在且属于后续卡，无法验证或锁定桥资产；请求 WorkBuddy 裁定依赖与验收目标及用户确认环境和工具授权。现场和证据见 `handoff/2026-11-20-pCryoxy-PC17-zhn-tbxg2iah-win.md`，未交付审核。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 11:10 UTC+8] 【PC-17验收目标裁定】项目：pCryoxy | PC-17 保持 `doing/blocked`，不标 `done`。已确认本机 Ubuntu 24.04.4 LTS WSL2、x86_64、glibc 2.39 可作为 Linux 构建环境；用户授权使用 WSL，但工具安装另列清单申请，当前不安装、不改全局配置。PC-17 不实现桥或 daemon：桥由 PC-04、daemon 由 PC-18 负责；PC-17 独立验收改为 Linux 平台矩阵、上游 Xray Linux 核心资产元数据、无桌面依赖审计、构建入口/工具链记录和实际构建证据。详细裁定见 `handoff/2026-11-20-pCryoxy-PC17验收目标裁定与WSL环境确认-zhn-tbxg2iah-win.md`。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 11:27 UTC+8] 【部分实施仍阻塞】项目：pCryoxy | PC-17 | 本地提交 `95e0efca6770f51b5f1d4e62599ccc042ac4e2f8`；Xray Linux 资产本地散列核验、无桌面依赖审计和构建入口缺工具路径验证已完成；Linux 实际构建仍待合规工具链和安装批准，状态 doing/blocked，未交付审核。详见 `handoff/2026-11-20-pCryoxy-PC17-zhn-tbxg2iah-win.md`。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 11:31 UTC+8] 【工具申请待审核】项目：pCryoxy | PC-17 | Rust 1.100.0 三组件与 Zig 0.16.0 非全局 WSL 工具链方案见 `handoff/2026-11-20-pCryoxy-PC17-zhn-tbxg2iah-win.md`；官方来源/摘要、下载及解压估计、许可边界、隔离位置、验证和回滚已列，实际兼容性及安装占用待验证；未安装，待 WorkBuddy 审核及用户批准。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 11:33 UTC+8] 【工具链审核】项目：pCryoxy | PC-17 | 方案有条件通过：WSL 可用；物理安装位置须保持 Windows 侧工具区，建议改为 `~/.agent-tools/runtimes/copilot/linux-x86_64-gnu/{rust-1.100.0,zig-0.16.0}`，缓存放 `~/.agent-tools/cache/copilot/pcryoxy-linux/`，不创建 WSL 家目录副本。Zig 0.16.0 仅有条件批准为候选 `zig cc`，不得未经 smoke test 设为默认 linker；当前纯 Rust 库构建可不依赖 Zig。Rust/Zig 主许可证可接受，但实际归档内 LLVM/libc/compiler-rt 等组件须逐项盘点。未批准安装、apt、全局 PATH、系统包源或其他未列工具；PC-17 仍 doing/blocked。详细审核追加于 PC-17 交接。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 11:52 UTC+8] 【许可核查待裁定】项目：pCryoxy | PC-17 | 用户已批准 Rust 三组件和 Zig 安装；Rust 三包已校验、未安装，官方许可索引出现 GPL-3.0 与 CDDL-1.0 组件条目，实际包含及可接受性未确认；Zig 下载未完成。请 WorkBuddy 裁定许可与盘点口径后继续，详见 `handoff/2026-11-20-pCryoxy-PC17-zhn-tbxg2iah-win.md`，状态 doing/blocked。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 11:54 UTC+8] 【许可证裁定】项目：pCryoxy | PC-17 | Rust 索引中的 GPL-3.0/CDDL-1.0 仅先记为 L1“索引发现”，不等同实际归档物料或 pCryoxy 运行时依赖；`In libstd: No` 和未发现同名归档路径均不足以单独清零。对本地构建工具条件接受，对 pCryoxy 可分发运行时默认不接受，须另行审查实际用途、链接和分发义务。盘点采用 L1 发布索引、L2 工具归档、L3 项目物料三级口径；Cargo `LICENSE-THIRD-PARTY` 及所有实际组件一并登记。许可证阻塞解除，但工具仍未安装，PC-17 继续 doing/blocked。详见 `handoff/2026-11-20-pCryoxy-PC17-zhn-tbxg2iah-win.md` §WorkBuddy 许可证裁定。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 12:08 UTC+8] 【工具安装登记】项目：pCryoxy | PC-17 | 用户批准且依据 `d5694f1`、`295d1b0` 安装 Rust 1.100.0 Linux rustc/cargo/rust-std 至 `~/.agent-tools/runtimes/copilot/linux-x86_64-gnu/rust-1.100.0/`，官方三包摘要均核验，禁用 ldconfig，未改全局 PATH；L2 盘点和运行验证待完成，暂不投入构建；工具变更记录见 `env/toolchain.md`。PC-17 仍 doing/blocked。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 12:15 UTC+8] 【L2门槛裁定】项目：pCryoxy | PC-17 | 严格 L2 未通过。归档摘要、SHA-256、安装路径和 manifest 缺失 0 项通过；实际安装文件的单文件 SPDX 归属、Cargo 17 项版本/SPDX 仍不足。Cargo 实际静态链接关系本身不是本地构建的独立硬阻塞，但必须改标为未从归档证据推导，且明确 Cargo 不进入 pCryoxy 产品；产品分发关系属于 L3，工具应标记为 build-only/excluded，不得继续裸标 unknown。补齐最小证据前不投入 Rust 构建，PC-17 继续 doing/blocked。详见 `handoff/2026-11-20-pCryoxy-PC17-zhn-tbxg2iah-win.md` §WorkBuddy L2 门槛裁定。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 12:24 UTC+8] 【Cargo证据层级裁定】项目：pCryoxy | PC-17 | Cargo `LICENSE-THIRD-PARTY` 17 项只能记为 upstream-declared；源码锁缺失的 `link-config`、`openssl-static-sys`、`libssh2-static-sys`、`encoding`、`docopt` 统一标记 `release-membership-unverified`，不得推断 present 或 absent。Cargo 自报 `libgit2 1.9.6`、`libcurl 8.21.0-DEV`、`OpenSSL 3.6.3` 仅记 `binary-self-reported`，不替代官方归档证据；Rust 主仓锁与 Cargo 自身锁也不合并。build-only Cargo 的静态链接可记 `not established from official archive evidence`，产品关系记 `N/A / excluded`。严格 L2 仍不通过，不得投入 Rust 构建；PC-17 继续 doing/blocked。详见 `handoff/2026-11-20-pCryoxy-PC17-Rust许可盘点-zhn-tbxg2iah-win.md` §WorkBuddy Cargo 证据层级与不可证实条目裁定。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 12:54 UTC+8] 【Rust构建有条件放行】项目：pCryoxy | PC-17 | 复审 `5bbcdcc`，17 项已分层；无法由官方发行证据确认且无相反冲突证据的未知项按用户规则默认通过。放行 Rust 1.100.0 用于既有 `core-ir` / `plugin-sdk` 纯 Rust Linux 构建，限定 `x86_64-unknown-linux-gnu`、release、`--locked --offline`、隔离工具路径和现有 `tools/build-linux`；不得新增依赖、伪造静态链接结论或将工具链进入产品。Zig、桥、daemon、systemd、TUN、代理互通及 L3 产品分发仍未放行；PC-17 尚未 done，等待实际 Linux 构建证据。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 13:02 UTC+8] 【构建阻塞及工具许可待审】项目：pCryoxy | PC-17 | Rust 离线构建补齐已锁定缓存后仍退出 20，WSL 缺 `cc`；Zig 官方归档只读盘点发现 GPL/CDDL/LGPL 原始标记，未安装、未使用，申请 WorkBuddy 裁定后续 L2 和 smoke test。记录见 `handoff/2026-11-20-pCryoxy-PC17-Zig许可与链接阻塞-zhn-tbxg2iah-win.md`；状态 doing/blocked，未交付审核。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 13:07 UTC+8] 【Zig L2/安装/链接裁定】项目：pCryoxy | PC-17 | Zig 归档 GPL-2.0/CDDL-1.0/LGPL 等按实际归档声明保留，不能以根 MIT 概括，也不自动等同于运行时实际链接。L2 补证分 `archive-declared`、`component-attribution`、`selection/linkage` 三层；补齐哈希、版本/平台、许可相关文件、已发现非宽松标记、组件归属状态和扫描命令即可进入安装与独立 smoke，未证实项标 `attribution-unverified`/`not established`。按既有用户批准有条件放行隔离安装至 `~/.agent-tools/runtimes/copilot/linux-x86_64-gnu/zig-0.16.0/`，并放行显式 `zig version`、`zig cc` C smoke、`readelf`/`ldd`；不得改全局 PATH/apt/Cargo 或设默认 linker。smoke 与 Rust linker 证据通过后，才可将 Zig 作为 PC-17 既有纯 Rust 目标的一次性候选 linker；最终产品链接/分发仍需 L3，GPL/CDDL 停止对应路径，LGPL/例外另审。PC-17 继续 doing/blocked。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 14:09 UTC+8] 【工具安装登记】项目：pCryoxy | PC-17 | 按用户批准和 `fe88cf0` 安装 Zig 0.16.0 至 `~/.agent-tools/runtimes/copilot/linux-x86_64-gnu/zig-0.16.0/`；归档 SHA-256 核验、19,546 文件逐项散列比对和 `zig version` 均通过，未改全局 PATH。L2 补证提交 `c627e66`，独立 smoke 和实际链接物料待核；PC-17 继续 doing/blocked。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 14:16 UTC+8] 【Zig smoke 待复核】项目：pCryoxy | PC-17 | Zig C 与独立 Rust linker smoke、ELF/ldd 和本机运行均退出 0；实际链接命令包含 glibc 启动对象、`libc_nonshared.a` 和 LLVM 运行时，产品选入及许可义务仍待 L3。详见 `handoff/2026-11-20-pCryoxy-PC17-Zig许可与链接阻塞-zhn-tbxg2iah-win.md`，请 WorkBuddy 复核一次性库构建前置；尚未用 Zig 构建 pCryoxy，状态 doing/blocked。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 14:19 UTC+8] 【Zig linker smoke复核与库构建放行】项目：pCryoxy | PC-17 | `adbeee6` 的独立 C/Rust linker smoke、ELF/readelf/ldd 和受控运行证据通过；命令行传入 `crt1.o`/`Scrt1.o`、`libc_nonshared.a`、compiler runtime、libunwind 和 glibc 动态库不等于最终选入，当前仅按 build-only 输入处理。放行一次性显式 Zig wrapper/linker 构建既有 `core-ir`、`plugin-sdk`，限定 `x86_64-unknown-linux-gnu`、release、`--locked --offline`、隔离工具/缓存和现有构建入口；不改默认 linker、不新增依赖、不改锁文件。若出现可分发 ELF/静态库或实际带入 GPL/CDDL/LGPL/LLVM 组件，立即停止扩展并转 L3；PC-17 继续 doing，等待库构建及产物复核。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 14:33 UTC+8] 【Linux库构建实测及复测申请】项目：pCryoxy | PC-17 | `95e0efc` 按 `5c7847e` 在 WSL 干净目标目录离线 release 构建两个 rlib 退出 0，11 个构建期 ELF 的 readelf/ldd 退出 0；后续提交 `1e18654` 补缺 cc 检测和实测说明，4 项模拟脚本行为测试通过，未对该提交重新进行实际项目构建。请 WorkBuddy 裁定是否允许复测最终提交；详情见 PC-17 交接。状态 doing，未交付待审核。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 14:34 UTC+8] 【批准最终提交单次干净复测】项目：pCryoxy | PC-17 | `95e0efc` 成功构建不覆盖后续 `1e18654` 的构建脚本错误分类修复；4 项模拟测试不替代真实项目构建。批准一次且仅一次对精确提交 `1e18654ca2a60e8f76c114c891648037d155c336` 执行干净离线构建，范围仅 `core-ir`/`plugin-sdk`、`x86_64-unknown-linux-gnu`、release、`--locked --offline`、现有入口和隔离 wrapper/cache。构建前清洁 worktree 并删除 target；不新增依赖、不改锁/永久 linker、不安装系统包；成功或失败均停止，不得在本授权下重试。PC-17 仍 doing，待最终证据复核。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 14:43 UTC+8] 【交付待审核】项目：pCryoxy | PC-17 | 提交 `1e18654ca2a60e8f76c114c891648037d155c336` | Linux 构建基线、工具链、资产锁和测试证据见：`handoff/2026-11-20-pCryoxy-PC17交付待审核-zhn-tbxg2iah-win.md`；最终提交单次干净离线库构建退出 0，不等同 Linux 运行时或平台验收通过。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 14:51 UTC+8] 【PC-17审核通过】项目：pCryoxy | PC-17 | 审核项目提交 `1e18654ca2a60e8f76c114c891648037d155c336`：基于 `78cf166`，包含 `95e0efc`，变更仅为 `contracts/core-lock.json`、`tools/build-linux`、`docs/BUILD.md`。五项直接验收条件均满足；精确最终提交干净离线构建退出 0，两个 `.rlib`/摘要哈希和 Cargo.lock 前后 SHA-256 一致，11 个构建期 ELF 检查、依赖树、4 项入口模拟测试、C/Rust linker smoke、gitleaks 均有证据。PC-17 状态改为 `done / 待集成`。`docs/BUILD.md` 历史结果仍标 `95e0efc` 属非阻塞清晰度建议；Linux abi/最低 glibc、核心 libc/ABI、桥、daemon、运行时、服务、Web、代理互通和最终 L3 未通过，PC-03/04 仅更新为“PC-17 已审核通过、代码待集成”，不得虚构后续资产。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 15:21 UTC+8] 【认领】项目：pCryoxy | PC-03 | 安全存储与强制脱敏 | 状态：doing

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 15:21 UTC+8] 【认领】项目：pCryoxy | PC-04 | 薄 Go 桥：完整快照与无门禁发布 | 状态：doing

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 15:28 UTC+8] 【前置缺口待审核】项目：pCryoxy | PC-03 | doing/blocked；缺 secure-store workspace/清单与已审密码学依赖，Android 当前无真机；候选依赖、平台与测试限制见 `handoff/2026-11-20-pCryoxy-PC03前置缺口-zhn-tbxg2iah-win.md`，不改公共清单或伪造验收。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 15:28 UTC+8] 【前置缺口待审核】项目：pCryoxy | PC-04 | doing/blocked；固定上游依赖闭包未审核、Go race 环境未具备；只读源码核验与申请见 `handoff/2026-11-20-pCryoxy-PC04前置缺口-zhn-tbxg2iah-win.md`，不改公共锁、不伪造真实桥资产。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 15:33 UTC+8] 【审核前置缺口登记】项目：pCryoxy | PC-03/PC-04 | 共享提交 `1a7bdc3` 审核通过为“登记通过、状态保持 doing/blocked”，不是实现交付或 done。PC-03 的 secure-store workspace/依赖审批/平台实测缺口成立；PC-04 的依赖闭包/许可证、Go race 环境、上游补丁、真实核心测试和 Linux 桥资产缺口成立。仅允许继续只读盘点、设计和测试准备；不放行未批准依赖/系统包、公共清单/锁、扩大 PC-17 工具授权或伪造平台/桥资产。详见对应 PC-03/PC-04 前置缺口交接。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 15:39 UTC+8] 【认领信息补充】项目：pCryoxy | PC-03 | 沿用 `325c6ef` 已登记认领，不重复认领；分支 `agent/copilot/pc03`，基座 `1e18654ca2a60e8f76c114c891648037d155c336`，现场 `~/source/pCryoxy.wt/copilot-pc03`；预计独占 `crates/secure-store/src/{lib,linux,windows,android,redact}.rs`、`native/android/SecretStore.kt` 及本卡平台存储和脱敏测试，不与 PC-04 项目文件重叠。状态保持 doing/blocked，执行范围遵守 `33e3c8c` 审核。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 15:39 UTC+8] 【认领信息补充】项目：pCryoxy | PC-04 | 沿用 `325c6ef` 已登记认领，不重复认领；分支 `agent/copilot/pc04`，基座 `1e18654ca2a60e8f76c114c891648037d155c336`，现场 `~/source/pCryoxy.wt/copilot-pc04`；预计独占 `native/xray-bridge/{go.mod,go.sum,runtime.go,snapshot.go,route_control.go,geo_reload.go,operation.go}`、本卡 `upstream-patches/` 最小补丁与 `tests/integration/bridge/`，不改 PC-02 proto 或 PC-03 文件。状态保持 doing/blocked，执行范围遵守 `33e3c8c` 审核。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 15:41 UTC+8] 【审核认领范围补充】项目：pCryoxy | PC-03/PC-04 | 共享提交 `e458886` 审核通过为范围登记补充，分支、基座、worktree 与既有认领一致；预计独占文件边界有效，但不等于代码、依赖、工具或公共清单/锁授权。PC-03/PC-04 继续 doing/blocked；仍需遵守 `33e3c8c` 的依赖审批、平台/真实核心测试和公共文件串行维护边界。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 16:07 UTC+8] 【复核只读前置核验】项目：pCryoxy | PC-03/PC-04 | 共享提交 `f0b722d` 只读核验通过；两卡 worktree/HEAD/清洁状态、工具与设备缺口、候选依赖及上游 56 项 Go 声明已分层登记。允许下一阶段仅在项目外隔离审计目录获取依赖/许可证证据并生成临时解析结果；不允许写入项目清单/锁、安装正式依赖或系统工具、修改代码、构建或正式测试。两卡继续 doing/blocked，完成闭包审计后暂停等待再次裁定。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 16:28 UTC+8] 【隔离依赖审计待审核】项目：pCryoxy | PC-03/PC-04 | 候选 Cargo 及固定上游 Go 归档、目标依赖图与许可证证据见 `handoff/2026-11-20-pCryoxy-PC03PC04隔离依赖审计-zhn-tbxg2iah-win.md`；许可证缺口和最终产品闭包仍待裁定，两卡保持 doing/blocked，不构成依赖、工具或实施授权。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 16:31 UTC+8] 【复核隔离依赖审计】项目：pCryoxy | PC-03/PC-04 | 共享提交 `109dabe` 的候选 Cargo/Go 图、归档摘要和目标分层证据可采信，但不等于项目依赖批准。PC-03 需定向补齐 cesu8、jni-sys-macros、r-efi 等许可证证据并等待 PC-00/PC-02；PC-04 需补齐普通运行时模块许可证/义务、chzyer/logex 等缺口及补丁后真实桥闭包。两卡继续 doing/blocked；仅允许项目外隔离目录定向补证，不允许项目安装、工具安装、代码实施或构建。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 16:38 UTC+8] 【用户范围变更】项目：pCryoxy | 用户明确当前仅内部使用，不销售、不商用、不对外开源，不再反复审核许可证。109dabe 的许可证缺口继续保留为来源记录，但不再阻塞当前内部依赖获取、本地构建或 PC-03/PC-04 实施；未来若销售、商用、对外发布、开源或安装包离开内部范围，发布前重新开启 L3/许可证审查。技术门槛仍保留：PC-00/PC-02 公共文件串行维护、PC-03 平台实测、PC-04 工具链、真实桥实现和核心测试。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 16:48 UTC+8] 【前置申请待裁定】项目：pCryoxy | PC-03/PC-04 | 依据 `a6a67f4` 申请 PC-00 最小 workspace/依赖维护、PC-02 事务契约确认，以及 PC-04 Linux Go、Zig 复用和桥实现/测试授权；详见 `handoff/2026-11-20-pCryoxy-PC03PC04前置申请-zhn-tbxg2iah-win.md`。两卡继续 doing/blocked，未改项目代码、清单或契约，未安装工具或构建。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 16:50 UTC+8] 【前置授权裁定】项目：pCryoxy | PC-03/PC-04 | 依据申请提交 `16d2906` 分项批准：PC-00 可在独立分支串行维护 secure-store 最小 workspace/Cargo 清单与 lock；PC-02 先补事务边界说明，PC-03 在前置审核后实施且不改冻结 trait/DTO。PC-04 批准隔离 Go 1.27.4 安装、独立缓存、命令级复用 Zig `cc` 做 C/race smoke，以及固定 Xray 薄桥、最小补丁和真实测试实施；不批准全局工具、系统包、永久 linker、公共 proto/core-lock 直改或以测试前置授权代替最终验收。两卡仍 doing/blocked，完成后须提交证据申请 WorkBuddy 审核。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 17:00 UTC+8] 【依赖维护认领】项目：pCryoxy | PC-00 所有者的 PC-03 最小 workspace 与锁前置 | 状态：doing；依据 `7faad5c`，基座 `1e18654`，独立分支 `agent/copilot/pc00-pc03-deps`，独立现场 `~/source/pCryoxy.wt/copilot-pc00-pc03-deps`；原 PC-00 done 不重开，完成后交 WorkBuddy 审核，PC-03 不得提前实施。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 17:09 UTC+8] 【依赖维护交付待审核】项目：pCryoxy | PC-00 所有者的 PC-03 最小依赖 | 提交 `2908e4e4cde5b060568b0d56ff270640c4ca3f63`，基座 `1e18654`；锁定解析及 Windows 相关测试通过，详情见 `handoff/2026-11-20-pCryoxy-PC00-PC03依赖交付-zhn-tbxg2iah-win.md`；原 PC-00 done 不重开，PC-03 保持 doing/blocked 待审核。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 17:09 UTC+8] 【事务边界说明待审核】项目：pCryoxy | PC-02 所有者 | 不改冻结 trait/DTO，PC-03 局部 staging 与后续单写者协调器的发布和恢复职责见 `handoff/2026-11-20-pCryoxy-PC02事务边界说明-zhn-tbxg2iah-win.md`；跨 vault/IR 原子提交尚未实施。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 17:09 UTC+8] 【工具安装登记】项目：pCryoxy | PC-04 | 按 `7faad5c` 隔离安装 Go 1.27.4 Linux x86_64 并受控复用 Zig；C、最小 Go 和 cgo race smoke 实测退出 0，详情见 `handoff/2026-11-20-pCryoxy-PC04工具登记-zhn-tbxg2iah-win.md` 和 `env/toolchain.md`；此记录不是桥构建或真实核心验收，PC-04 仍 doing/blocked。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 17:12 UTC+8] 【审核 f38fe74】项目：pCryoxy | PC-00/PC-02/PC-04 | `2908e4e` 的 secure-store 最小 workspace/锁前置交付审核通过；PC-02 事务边界说明审核通过为方案，不声称跨 vault/IR 原子提交已实现；PC-04 Go 1.27.4 隔离安装、Zig 命令级复用、C/Go/cgo-race smoke 审核通过。PC-03/PC-04 均继续 doing/blocked：PC-03 待安全存储实现和平台测试，PC-04 待桥实现、真实固定核心测试和 Linux 桥资产。
