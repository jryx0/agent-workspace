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
