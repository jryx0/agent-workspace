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

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 17:18 UTC+8] 【Go绑定与descriptor冻结裁定】项目：pCryoxy | PC-02/PC-04 | 批准复用 `protoc 29.5`，批准 `protoc-gen-go v1.36.12` 与 `protoc-gen-go-grpc v1.6.2`，仅为 `pcryoxy.bridge.v1.Control` 生成 `native/xray-bridge/core_control.pb.go` 和 `core_control_grpc.pb.go`。要求 PC-02 所有者先冻结 proto/递归 imports、descriptor、go_package/import mapping、完整命令和摘要，再由 PC-04 生成；PC-04 需在隔离 GOMODCACHE 中核验生成器与桥运行时的直接/传递依赖增量。生成成功不等于依赖闭包、桥、真实核心或 Linux 资产通过；两卡继续 doing/blocked。详见 PC-02/PC-04 交接追加。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 17:33 UTC+8] 【认领前置维护】项目：pCryoxy | PC-02 | 按 `e327511` 串行冻结 PC-04 Go 绑定输入、生成参数及契约锁关联记录 | 状态：doing；不改变已审核 PC-02 的 done 状态，不代 PC-04 修改其独占文件。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 17:36 UTC+8] 【输入冻结】项目：pCryoxy | PC-02/PC-04 | 契约输入与生成参数提交 `3bb31ad`，证据见 `handoff/2026-11-20-pCryoxy-PC02-Go绑定冻结-zhn-tbxg2iah-win.md`；Go 输出、再生成无漂移及依赖闭包尚待实测，不代表桥或 PC-04 审核通过。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 17:42 UTC+8] 【输出锁定待审核】项目：pCryoxy | PC-02/PC-04 | PC-02 输出摘要提交 `90aa591`；两次生成、字节比较及六项 RPC 核验退出 0，证据见 `handoff/2026-11-20-pCryoxy-PC02-Go绑定冻结-zhn-tbxg2iah-win.md`；PC-04 绑定尚未提交，桥及实际依赖闭包仍待验证和审核。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 23:20 UTC+8] 【PC-04 proto3默认值语义裁定】项目：pCryoxy | 官方 AddRule 的 proto3 默认值/空字符串/默认枚举按未提供处理并继承 active view；当前编码无法表达显式 AsIs 或清空脚本，需拒绝此类歧义请求或改走 ReplaceRoutes。项目 ReplaceRoutes 按完整 desired configuration 解释，默认值是实际配置，空脚本表示清空；两入口先规范化为同一候选 RouteView，语义不一致或不完整则拒绝，不猜测。暂不引入 optional/oneof/FieldMask presence；未来需显式区分时另行升级 proto/descriptor。Geo、override、快照/epoch 工作继续，PC-04 仍 doing/blocked。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 07:44 UTC+8] 【PC-04受限能力子集裁定】允许 PC-04 以已验证配置子集作为交付目标，不要求当前卡纳管全部 Xray 上游消费者；sniffing、未纳管 DNS 后端、proxy/dns、freedom、finalmask、Geo cron 及其他无法证明绑定同一 RouteView/epoch 的配置必须在 prepare 阶段拒绝，且拒绝时 active view、epoch、revision、Geo version 和资源状态不变。隔离配置测试仅作子集证据，不得写成完整 Xray 生产验收；PC-04 继续 doing/blocked，完整裁定见 `handoff/2026-11-21-pCryoxy-PC04受限能力子集裁定-zhn-tbxg2iah-win.md`。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 13:18 UTC+8] 【PC-04提交阶段A审核】审核 `27d942badfa26afb2d0fb0b60009071881f035b9`：纯 `ValidateRestrictedProfile`、`RegisterRuntime` 二次校验、无状态 ABI v1、定向测试和 replay 更新符合 `041c2db` 阶段A边界，可作为 PC-18 最小接入桥侧基线；执行方固定 replay 证据可采信，审核方本轮未独立重跑。PC-04 继续 `doing/blocked`，不标 done，不合并、不部署；Rust wrapper、真实 daemon 生产入口、生命周期/UID/ticket/状态不变证据仍待 PC-18。详见 `handoff/2026-11-21-pCryoxy-PC04提交27d942b阶段A审核裁定-zhn-tbxg2iah-win.md`。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 13:56 UTC+8] 【PC-18运行时ABI阻塞裁定】核对 `27d942b` 确认其 C ABI 仅是无状态 profile validator，没有 runtime opaque handle、创建/持有/查询/关闭、私有 transport 接入或 Rust 可调用的 `RegisterRuntime` 入口；Go `RegisterRuntime` 仍为测试侧 Go API。裁定：PC-18 阶段 A 继续 `doing/blocked`，等待 PC-04 提交并审核运行时 ABI/契约；PC-18 不修改 PC-04 Go 文件、不复制 ABI、不伪造生产测试。PC-04/PC-18 的 IPC、UID/ticket、生命周期责任按 `041c2db` 拆分，详见 `handoff/2026-11-21-pCryoxy-PC18阶段A运行时ABI阻塞裁定-zhn-tbxg2iah-win.md`。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 15:49 UTC+8] 【PC-04提交37c6423设计审核】提交仅新增 Runtime ABI v2 设计提案，无实现和测试。设计方向有条件通过：可接受 runtime handle、固定 status、同步 create/start、Go 侧 transport、UID+ticket verifier 和幂等 close 的总体方案；但必须先冻结 ticket wire format、handle 终态判定、status struct 兼容规则、socket unlink、Serve ready barrier、SERVICE_REGISTER_FAILED 语义和 checked cleanup。提交不能解除 PC-18 blocked，PC-04/PC-18 继续 doing/blocked。详见 `handoff/2026-11-21-pCryoxy-PC04提交37c6423运行时ABI-v2设计审核裁定-zhn-tbxg2iah-win.md`。
[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 17:37 UTC+8] 【PC-04 Runtime ABI v2 实施交付待复审】项目：pCryoxy | PC-04 | 实施提交：2206139fcb86a138b38a10ad43f20f455a99ffaf；交接：`handoff/2026-11-21-pCryoxy-PC04-RuntimeABI-v2-implementation-copilot-zhn-tbxg2iah-win.md`；状态：doing / blocked，等待 WorkBuddy 复审；未 push/merge/deploy，PC-18 不得据此开始真实绑定。
[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 23:16 UTC+8] 【PC-04 Runtime ABI v2 专项正式复审申请】已提交专项复审申请，申请对象为实现提交 `2206139fcb86a138b38a10ad43f20f455a99ffaf` 与布局澄清提交 `44247c802efe38750f19c958400cbb97086f2d41`；证据含 replay 脚本退出码 0、62 PASS/0 FAIL、archive SHA-256 `8a6d31a78f47e9f16872920247df4457b0c762674a72b401373cbc714ec7abff`、复核 handoff `ffe2eb58cc2d25f49c5e4e41b0a3a7741c14ffbf`。申请记录：`handoff/2026-11-21-pCryoxy-PC04RuntimeABI-v2专项正式复审申请-zhn-tbxg2iah-win.md`。仅申请复审，不代表通过；PC-18 继续等待裁定，不真实绑定、不合并、不部署。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 22:12 UTC+8] 【日志需求与全量文档同步】项目：pCryoxy | 新增 PC-21 Windows/Linux 日志与可观测性任务卡；以需求基线 v1.1、蓝图 v0.3、API Spec v1.2 和 PC-04/PC-18 最新裁定为基准，新增日志需求、保留/启动清理、Web 查询、域名级隐私边界和应用来源归属分级；同步增量见 `handoff/2026-11-21-pCryoxy-需求确认基线-v1.2日志增量-zhn-tbxg2iah-win.md`、`handoff/2026-11-21-pCryoxy-工程蓝图-v0.4日志增量-zhn-tbxg2iah-win.md`、`handoff/2026-11-21-pCryoxy-API-Spec-v1.3日志契约增量-zhn-tbxg2iah-win.md`、`handoff/2026-11-21-pCryoxy-PC21日志与可观测性任务卡-v1.0-zhn-tbxg2iah-win.md`。本次只改文档和记忆，不改公共代码/构建清单，不合并、不部署；PC-04 Runtime ABI v2 和 PC-18 仍 blocked。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 22:25 UTC+8] 【PC-03 双专项派工】项目：pCryoxy | PC-03 | 按人类 22:18 指令下发两张补证专项（不新增卡号、不改卡状态）：PC-03-WIN-V1（Windows 测试账户 test1 平台验证 + 历史 8 项失败逐项定性）与 PC-03-AND-V1（Android 真机 Keystore 验证）。派工前实测：test1 仅 Users 组、上次登录从未、无 profile；当前会话非提升；`adb devices -l` 为空；仓库无 Gradle 工程/AndroidManifest。两卡默认串行使用 `~/source/pCryoxy.wt/copilot-pc03`（HEAD c73d59d）。提示词与门槛见 `handoff/2026-11-21-pCryoxy-PC03WIN与AND专项派工提示词-zhn-tbxg2iah-win.md`。口令不落任何文件；需提升的操作一律列 [人类执行]。PC-03 仍 doing/有条件通过，两卡全绿也不自动 done。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 22:44 UTC+8] 【专项派工 PC-03-WIN-V1】项目：pCryoxy | 沿用 PC-03 既有认领，按用户授权仅作 Windows 测试账户补证，不新增正式卡号、不改变 PC-03 状态；现场分支 agent/copilot/pc03，HEAD c73d59d，基座 2908e4e。人类已交互登录 test1，profile 已建立；不改产品代码、ACL、系统权限或真实 vault。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 22:49 UTC+8] 【专项结论 PC-03-WIN-V1】受外部条件阻塞：测试夹具锁路径编译时绑定原 worktree，复制二进制不能消除 test1 对该路径的读写依赖；原历史 8 项缺逐项日志。未启动 test1 测试、未改 ACL 或代码；等待测试夹具/构建方案和启动机制裁定。详情见 `handoff/2026-11-21-pCryoxy-PC03-Windows测试账号验证-zhn-tbxg2iah-win.md`；PC-03 状态不变，不标 done。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 22:52 UTC+8] 【Android 真机环境冒烟（非验收）】项目：pCryoxy | PC-03-AND-V1 前置环境验证，由 WorkBuddy 在项目外执行，不代表 PC-03 验收。设备：HONOR TEL-AN10，Android 10／API 29，arm64-v8a，`user`+`release-keys`，`ro.debuggable=0`、无 `su`（非 root 生产机），Keystore 服务在线（`android.security.keystore` + 华为 `IHwKeystoreService`，`init.svc.keystore=running`）。自建 12,697 字节探针 APK（debug 签名，SHA-256 `fe38d701a46e63de33778616208ddd118300fd77838358a7c5a737fd726ab505`）测平台能力：AES-256-GCM 加密 4097 字节通过（iv 12／ct 4113），`noBackupFilesDir=/data/user/0/app.pcryoxy.probe/no_backup`，HMAC-SHA256 32 字节；`am force-stop` 真实进程终止后 alias 与密文持久、重开解密 PASS、HMAC 稳定 PASS；篡改密文拒绝为 `AEADBadTagException`；删除 alias 后取键为 key-absent 且旧密文保留（4126 字节）；cleanup 无残留。探针已卸载、临时文件已删。**卡面修正项**：API 29 无 `KeyInfo.getSecurityLevel()`（API 31+），卡 B 要求"报告 Keystore 安全级别"在本机不可判定，须改为声明不可判定或另取厂商属性，不得编造 TEE/StrongBox。**安装前置**：带密码锁屏时 `pm install` 会静默挂住（无输出、无失败码），须解锁亮屏后才返回 Success；此条应写入卡 B 执行前置。另：本机 SDK 仅有 android-36/37 平台与 build-tools 36/37，无 android-29 平台，按 minSdk 29、targetSdk 36 构建可在 API 29 设备安装运行。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 23:05 UTC+8] 【PC-03-WIN-V1 回执裁定：退回补证】项目：pCryoxy | PC-03 | 不接受 copilot 22:49「受外部条件阻塞」。已核实 `native_fixture_guard` 走 `env!("CARGO_MANIFEST_DIR")/target/pc03-native-fixture.lock`、`Fixture::new` 走 `current_dir()`，机制成立但只否定「原 worktree 构建+复制二进制」一种方式。改走：① 在 `C:\Users\Public\<中立目录>` 重建（Public 的 `INTERACTIVE:(OI)(CI)(IO)(M,DC)` 覆盖 test1，SID `S-1-5-21-155457669-4072508151-1813346089-1002`）；② 直接运行测试二进制、cwd 设为 test1 `%TEMP%`，令夹具根落 test1 私有目录；③ `--test-threads=1` 逐项记录。仅中立路径仍失败且贴出确切 panic 才可判阻塞。附带裁定：「历史 8 项缺逐项日志」不是本卡阻塞理由；服务身份仍记未覆盖。PC-03 仍 doing/有条件通过，不合并、不部署。详见 `handoff/2026-11-21-pCryoxy-PC03-WIN-V1回执裁定-退回补证-zhn-tbxg2iah-win.md`。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 23:15 UTC+8] 【PC-03-AND-V1 回执裁定：退回补证 + 卡面修正 v1.1】项目：pCryoxy | PC-03 | 不接受 copilot 23:10「受外部条件阻塞（Keystore 安全级别未确认，11 项未执行）」。三处驳回并附实测：①**安全级别可判定否定**——`pm list features | grep strongbox` 空、`lshal` 无 strongbox HAL、只有 `keymaster@3.0`，故 StrongBox 不支持为确定结论；TEE/软件不可区分是 API 29 限制（`getSecurityLevel()` 为 API 31+），按"不可判定 + 残余风险"记录，属登记项非停机项（此口径 22:52 已写明，回执反向当挡板属选择性引用）。②**设备真实性按证据级**——`ro.kernel.qemu` 空 + user/release-keys + `ro.debuggable=0` + 无 su + uid 2000 + `verifiedbootstate=green` + `flash.locked=1`（后两条本轮新测），绝对证明不可得，不构成门禁。③**离线构建不缺构件**——实测用 `gradle-9.6.1/lib/*` 内 `kotlin-compiler-embeddable-2.3.21.jar` 直接 K2JVMCompiler 编译 `SecretStore.kt`+`SecretStoreDeviceChecks.kt` 成功（退出 0，4 class），d8 合并 `kotlin-stdlib-2.3.21.jar` 出 dex 2,441,280 字节；无需 kotlinc/Gradle/AGP/NDK/androidx.test，无需下载，故"缺构件先申请"不成立。宿主须与产品源码**同一编译单元**（`Proof` 构造器为 internal），跨进程两项用 `Proof.namespace/version` 落盘。卡面修正 v1.1：门禁 2 降为设备事实登记项；停机只认 M2 三条（设备非恰好 1 台 physical／确认模拟器／按 D1–D5 执行后仍失败且贴首次失败原始错误）；新增 D1 解锁亮屏（锁屏下 `pm install` 静默挂住）、D2 免 Gradle 构建、D3 stdlib 一并 dex 且 APK 不入库、D4 同编译单元、D5 minSdk29/targetSdk36 不下载 android-29。回执对"未改项目文件"陈述诚实（worktree 干净、HEAD c73d59d、无 testhost）予以采信，但不改结论。PC-03 仍 doing/有条件通过，不合并、不部署、不写 done。详见 `handoff/2026-11-21-pCryoxy-PC03-AND-V1回执裁定-退回补证与卡面修正v1.1-zhn-tbxg2iah-win.md`。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 23:44 UTC+8] 【PC-03-WIN-V1退回补证实测】中立路径离线构建成功；test1 交互会话串行执行 16 项，退出 101：1 passed、13 failed、2 ignored。12 项 fixture 初始化 PermissionDenied；原生并发用例独立出现 CredRead 错误 1168。test1 profile 祖先 ACL 含 Zhn_X 完全控制，与后端祖先安全检查冲突；不改 ACL 或代码。用户要求终止验证，后续未覆盖；详见 `handoff/2026-11-21-pCryoxy-PC03-WIN-V1退回补证实测-zhn-tbxg2iah-win.md`。前次外部阻塞结论已退回；PC-03 状态不变，不标 done。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 23:22 UTC+8] 【工程前置单独立项：PC-03-AND-HOST-V1 授权 copilot】项目：pCryoxy | PC-03 | 人类 23:20 裁定四项：B1 宿主落 **共享仓脚手架**（`~/.agent-shared/scaffold/pc03-and-host/`，不动产品仓、不建分支）、B2 实施方 **copilot**、B3 与卡 A 并行不冲突、B4 只验收宿主管用 A1–A4（不评 11 项）。原因：卡 B 两轮以"门禁"退出，实质缺口是无测试载体，把造载体从跑验证切出，避免"验证方自造载体再自证"。**自我修正**：上轮"宿主必须进项目仓"作废——`internal` 是编译单元级约束、与目录无关，把产品 `.kt` 当编译输入、输出项目外可正常编译（实测 4 class）。落法对比：`tmp/` 已被 gitignore 且零入库 → 方案 A 证据不可复现；`scaffold/` 未被忽略、可提交 → 选 B。授权白名单仅 4 文件（Manifest/HostInstrumentation.kt/build 脚本/README），禁改产品任何文件；验收 A1 四 class 齐（证同编译单元取 internal）、A2 安装 Success、A3 prepare→force-stop→verify→cleanup 且 cleanup 无残留、A4 无 secret/alias 泄漏。卡面修正 v1.1 增 **M6**：D2/D3/D4 作废、卡 B 复用脚手架不另造；D1 解锁亮屏、D5 minSdk29/targetSdk36 仍有效；卡 B 在 HOST 交付并复核前不开工。PC-03 仍 doing/有条件通过。详见 `handoff/2026-11-21-pCryoxy-PC03-AND-HOST脚手架授权-copilot-zhn-tbxg2iah-win.md`。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 23:24 UTC+8] 【PC-04 Runtime ABI v2 专项复审通过裁定】项目：pCryoxy | PC-04 | 认可 `2206139fcb86a138b38a10ad43f20f455a99ffaf` 为 ABI v2 桥侧实施基线、`44247c802efe38750f19c958400cbb97086f2d41` 对 296-byte status 版本表达的冻结澄清；头文件静态断言、C shim 版本优先检查、`ValidateRestrictedProfile` 复用、无 `SetAdmission`、ready barrier 与失败逆序清理均经静态核对；replay（退出码 0、62 PASS/0 FAIL、双构建一致）按 handoff 采信，审核方未独立重跑。允许 PC-18 开始 Rust FFI wrapper 与真实 daemon caller 接入（不修改 PC-04 文件，发现不一致即停）；PC-04 继续 doing/blocked 不结卡，PC-18 解除 blocked 以后续真实接入证据裁定为准；不合并、不部署。详见 `handoff/2026-11-21-pCryoxy-PC04RuntimeABI-v2专项复审通过裁定-zhn-tbxg2iah-win.md`。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-21 23:55 UTC+8] 【文档梳理与全量核查】项目：pCryoxy | 按人类 23:40 指令只读核查需求→任务卡→执行→审核全链，结论 F-01～F-24（高 7／中 10／低 7），成果在项目仓本地提交 `2e653c5`（docs/README、01 需求总表、02 任务卡总表含 v1.2 拆环方案、03 工作进展、04 核查报告；.gitignore 忽略备份目录，未推送）；75 份 handoff 与本记忆原件备份于项目 `docs/_backup-20261121/`（git 忽略）。要点：PC-04 受限子集无用户裁定缩减 REQ-08/12/14；PC-04↔PC-18、PC-20↔PC-21 依赖成环；PC-18 未认领即被授权；main 因未审核提交 ec39de4/152df4e 构建不通过；pc17/pc03/pc04 未推送。不改任何卡状态、不合并、不部署，待人类裁定 9 项。详见 `handoff/2026-11-21-pCryoxy-文档梳理与全量核查-zhn-tbxg2iah-win.md`。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 00:11 UTC+8] 【人类裁定登记】项目：pCryoxy | 人类对核查报告裁定：① 不接受 PC-04 受限子集对 REQ-08/12/14 的缩减，新增 P0 扩展卡 PC-04b 补回；② 批准按项目 docs/02-任务卡总表 §4 拆开 PC-04↔PC-18、PC-20↔PC-21 依赖环；③ main 修复/集成由 workbuddy 给建议；④ 对已 done 卡与 PC-04 ABI v2 做审核方独立重跑。本行由 workbuddy 代为登记。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 07:35 UTC+8] 【任务卡 v1.2 发布｜批次登记】项目：pCryoxy | 发布 `handoff/2026-11-22-pCryoxy-实施任务卡-v1.2-zhn-tbxg2iah-win.md`：新增 PC-04b（P0，依赖 PC-04）、PC-18a/18b、PC-21a/21b；作废 v1.1 的 PC-18 与单卡 PC-21（均无认领、无代码）；PC-03 的 Windows 服务身份验收移 PC-10；PC-04 六条结卡条件。批次登记 PC-17～PC-21 与新卡，全部 todo/未认领（PC-17 done、PC-03/04 doing 不变）。认领入口同步。不替任何 agent 认领、不改任何卡状态。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 07:35 UTC+8] 【独立重跑复核】项目：pCryoxy | PC-00/01/02/17 + 两依赖子任务 | 审核方隔离目录独立重跑 `c3dae63`、`3a99401`、`2ccffd0`、`78cf166`、`1e18654`、`2908e4e`：Rust 20 项全部退出 0（测试 94 通过 0 失败），PC-02 protoc/TS fixture 一致，PC-17 WSL release 构建通过且 Cargo.lock 未变。PC-04 `44247c8` ABI v2 replay 62 PASS/0 FAIL、无 race，archive SHA-256 `8a6d31a7…abff` 与申报一致。main `152df4e` cargo check 失败（缺 core-ir 源码）得到证实。卡状态不变。第 3 项建议：补追认 ec39de4/152df4e → main 快进到 `2908e4e` → 变基推送文档提交；待人类确认。项目仓本地提交 `1c7bfde`（未推送）。详见 `handoff/2026-11-22-pCryoxy-done卡与PC04-ABIv2独立重跑复核及集成建议-zhn-tbxg2iah-win.md`。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 08:20 UTC+8] 【审核裁定｜main 未审提交追认与集成】项目：pCryoxy | PC-00/PC-01 | 按人类 08:08 授权：追认 `ec39de4`（core-ir 入 workspace）、`152df4e`（idna =1.1.0），以与 PC-01 链一并集成为条件。main 已快进到已审链 `2908e4e`，workbuddy 文档提交变基为 `74c753d`/`6c5e5b3`；集成后 main 实测 cargo check 0、cargo test --workspace --all-features 0（24 通过 0 失败）；密钥/大文件扫描无命中。已推 origin：main `6c5e5b3`、代推备份 `agent/copilot/pc17` `1e18654`、`pc03` `c73d59d`、`pc04` `44247c8`。未并入 `90aa591`（未审）、pc03、pc04（doing）。不改卡状态、不部署。审核目录临时 target-3a99401 已按人类授权删除。详见 `handoff/2026-11-22-pCryoxy-main未审提交追认与集成裁定-zhn-tbxg2iah-win.md`。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 08:26 UTC+8] 【人类裁定登记｜PC-03 验收矩阵冻结】项目：pCryoxy | PC-03 | 人类 08:25 确认《真机验证方案 v2》§5 矩阵 W1～W6、A1～A3（另含 L1 复跑、X1 泄漏扫描）即日冻结；审核只按矩阵逐项判定，不得追加口径，改动须人类裁决出新版。服务 SID/ACL/服务重启可读归 PC-10。W5 待人类选定测试账户（新建 pcx-t2 或清理 test1 多余 ACE）并登记计划任务后执行，未就绪前 blocked。手机“充电时保持唤醒”已由 workbuddy 经 adb 开启。卡状态不变。本行由 workbuddy 代为登记。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 08:36 UTC+8] 【进展登记｜PC-03 W5 跨账户环境】项目：pCryoxy | PC-03 | 人类 08:27 新建标准用户 pcx-t2（未登录）；08:31 人类已将调度提示词发给 copilot。方案 v2 新增 §3.2a 跨账户交接约定：目录 C://Users//Public//pcryoxy-xacct（inbox/outbox，权限分离）、计划任务 pcryoxy-xacct（待人类管理员登记）、run-xacct.ps1 由 copilot 泳道 B 提供。卡状态不变。本行由 workbuddy 代为登记。
[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 08:38 UTC+8] 【认领｜PC-03-AND-HOST-V1】项目：pCryoxy | 按已授权范围只新增共享仓 Android 测试宿主白名单文件，不改产品文件；复用当前 PC-03 既有认领与 worktree。宿主完成并复核前，Android 业务矩阵不开始。
[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 09:40 UTC+8] 【PC-03 Windows 交付待审核】项目：pCryoxy | 状态：blocked；项目提交 `f2244cf9eaae5a5e30120bfdad466b0323ba7a7f`（基座 `c73d59d`），仅新增 W3 other-writable ancestor 与 W6 token rotation 测试。W1/W2/W3/W6 PASS；W4 两轮 Windows error 8 后 BLOCKED，1168 未到达；W5 因任务未登记及双向 fixture 协议缺口 BLOCKED。runner `C:\Users\Public\pcryoxy-xacct\run-xacct.ps1` SHA-256 `619ec806…fa9da`，已绑定该提交；未用 test1。证据与复审请求见 `handoff/2026-11-22-pCryoxy-PC03-Windows-交付待审核-copilot-zhn-tbxg2iah-win.md`。
[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 09:40 UTC+8] 【PC-03 Android 交付待审核】项目：pCryoxy | 宿主脚手架提交 `35e14f8c11a999e814df986201c425d438d547f9`；已编译 classes/dex、打包和对齐 unsigned APK。缺现有批准 keystore，未签名、未安装，Android A1～A3 未运行，状态 blocked；未生成密钥/证书。证据包与哈希见 `handoff/2026-11-22-pCryoxy-PC03-Android-交付待审核-copilot-zhn-tbxg2iah-win.md`。
[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 09:40 UTC+8] 【90aa591 交付待审核】项目：pCryoxy | Go binding 输出摘要提交 `90aa591ac82b4a7006887f2c781ac6f20baf5e82` 位于 `agent/copilot/pc02-go-freeze`，未合入 main；`proto.lock` 所记两份 Go 输出摘要与 PC-04 当前 worktree 实测一致。已提交 WorkBuddy 复核请求，详见 `handoff/2026-11-22-pCryoxy-90aa591-Go绑定输出摘要-交付待审核-copilot-zhn-tbxg2iah-win.md`。
[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 09:53 UTC+8] 【PC-04 clean Linux replay 交付待裁定】项目：pCryoxy | 精确提交 `44247c802efe38750f19c958400cbb97086f2d41` 在 WSL ext4 clean replay 退出 0，62 PASS/0 FAIL，ABI v1/v2 C smoke 通过，两个独立缓存 archive `cmp` 一致且 SHA-256 与 WorkBuddy 独立复验相同。证据包 SHA-256 `3453d8a8343439e0e0dfabb35d902da41603271a8ff5368e315c732c745d6962`。`.so` clean replay 与此前三次独立缓存构建哈希不同，原因未证实；待 WorkBuddy 裁定其是否交付物及 PC-04 六项是否满足 done。实际 PC-04 merge-base 为 `1e18654`，与调度提示的 `2908e4e` 不符；未变基/合并。详见 `handoff/2026-11-22-pCryoxy-PC04-Linux复跑与结卡申请-copilot-zhn-tbxg2iah-win.md`；PC-18a 继续等待 PC-04 done，不认领、不启动。
[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 09:58 UTC+8] 【状态更新】PC-03 状态：blocked；W4 两次 Windows error 8、W5 计划任务/双向 fixture 未解、Android A1～A3 未运行（无获批测试 keystore）。W1/W2/W3/W6 通过不等于 PC-03 done；未合并、未部署。
[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 09:58 UTC+8] 【状态更新】PC-04 状态：blocked，等待 WorkBuddy 对 v1.2 六项结卡清单裁定，并核实 `.so` 是否交付物及实际基线差异；未标 done。PC-18a 仍 todo/未认领，未启动。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 10:30 UTC+8] 【审核裁定｜PC-04 结卡通过 → done；PC-02 Go 绑定冻结通过】项目：pCryoxy | PC-04：v1.2 六条结卡条件全部满足（精确文件清单 50 项与 diff 一致；证据包 3453d8a8…6962 复算一致、62 PASS/0 FAIL；archive 8a6d31a7…abff 可复现；审核方 07:35 已独立 replay）。libpc04_abi.so 定性为 ABI smoke 临时产物、非交付物，F-25 转为后续以 .so 为交付物的卡的约束。PC-02 Go 绑定冻结 3bb31ad+90aa591：仅 proto.lock，两份 .pb.go 大小/SHA 与 44247c8 实物一致，通过。已集成并推 origin：main a6bcb16（90aa591）→ 9949081（pc04），集成后 cargo check/test 24/0、proto 校验通过。PC-04 状态 done。PC-04b、PC-05、PC-18a 依赖已满足，可认领（先追加认领行，基座 9949081）。PC-03 仍 blocked，W4/W5/Android 由审核方子 agent 独立验证中。详见 handoff/2026-11-22-pCryoxy-PC04结卡与90aa591审核裁定-zhn-tbxg2iah-win.md。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 10:45 UTC+8] 【审核裁定｜PC-03 退回，状态 blocked→doing】项目：pCryoxy | PC-03 | 审核方子 agent 对 f2244cf 独立验证冻结矩阵：W4 三轮 error 8，根因是 11-20 遗留 940 条 pCryoxy/v1/*/master 占满每用户约 522KB 的凭据配额（环境），另发现初始化失败不回滚会耗尽配额（产品风险）；W5 计划任务已修好（pcx-t2 补 SeBatchLogonRight，LastTaskResult=0，.rejected 所有者为 pcx-t2），但 run-xacct.ps1:7/:250 仍绑定 c73d59d，且无 W5 阶段；Android A1～A3 发现宿主 onCreate 缺 start()、结果只看退出码，产品 SecretStore.kt:42/92-93 父目录 0771 必失败、:180 Os.link 被 SELinux 拒绝。W1/W2/W3/W6 暂接受执行方证据，结卡时审核方整体复跑。返工 10 项见 handoff/2026-11-22-pCryoxy-PC03冻结矩阵审核方独立验证裁定-zhn-tbxg2iah-win.md §4。debug.keystore 已由审核方生成，仅供测试宿主使用。W4 环境清理待人类确认。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 10:55 UTC+8] 【审核补充｜PC-03 W4 清理后复跑判 FAIL】项目：pCryoxy | PC-03 | 按人类 10:38 确认，先备份（cred-backup-20261122，数量和字节核对一致），再分 94 批删除 940 条遗留的 pCryoxy/v1/*/master，删除后 pCryoxy 凭据为 0。f2244cf 测试程序复跑 13 轮：error 8 消失，串行写满 16 条通过；5/13 轮在并发 create→read 处出现 Err(1168)（tests.rs:197，op 5/7），无泄漏。W4 判 FAIL（产品/平台行为，不是环境问题），追加返工第 11 项：查清是暂时读不到还是写入丢失，修复后 20 轮 0 失败。PC-03 仍为 doing。证据清单 SHA-256 d42d9599…2c2d。

[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 12:01 UTC+8] 【PC-03返工复验交付待审核】项目：pCryoxy | PC-03 保持 doing；Windows修复提交 `dc3d34d825dca715e29e174297f449c83216273a` 已推 origin，W4 exact 20/20、回滚/孤儿清理/跨进程不同roots测试及fmt通过；Android产品与宿主修复已编译，宿主提交 `1e888153a9d64289b09320dcb2e6950c89b68bc8`，APK签名指纹匹配既有debug.keystore，但遵守不部署边界未安装，A1-A3未实测。W5 Public runner与计划任务访问仍阻塞，未修改。细节见 `handoff/2026-11-22-pCryoxy-PC03-Windows返工复验交付-copilot-zhn-tbxg2iah-win.md` 与 `handoff/2026-11-22-pCryoxy-PC03-Android返工复验交付-copilot-zhn-tbxg2iah-win.md`；请求WorkBuddy复核，不标done。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 14:55 UTC+8] 【人类裁定登记｜PC-03 验收矩阵 v1.1】项目：pCryoxy | PC-03 | 人类 14:50 选方案 A：A1～A3 改为双机各自通过，D1 荣耀 TEL-AN10（API 29）＋ D2 荣耀 MAG-AN00（Android 16/API 36，KeyMint 2.0，4KB 页），任一台不过即 FAIL；W/L/X 不变。已写入《真机验证方案 v2》§5。D2 已连接，stay_on 由 workbuddy 经 adb 开启。本行由 workbuddy 代为登记。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 14:55 UTC+8] 【更正＋状态快照】项目：pCryoxy | 更正：07:35 行与任务卡 v1.2、认领入口所写「P0 26 张」有误，逐卡计数应为 **P0 25 张**（PC-00～17 共 18 张，加 PC-04b、18a、18b、19、20、21a、21b），加 P1 4 张，共 29 张；v1.2 与认领入口已同步更正。§2 表格只登记了 v1.0 的 21 张，PC-17～21 与 v1.2 新卡以 07:35 批次登记行为准。**截至本行的权威状态**：done 5 张（PC-00、01、02、17、04，均已在 main `9949081`）；doing 1 张（PC-03，copilot，`dc3d34d` 返工待审核方复核）；todo 23 张（其中 PC-04b、PC-05、PC-18a 依赖已满足可认领）；作废：v1.1 PC-18、PC21 卡 v1.0 PC-21。读者可只看本行及其后各行获取当前状态。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 15:30 UTC+8] 【审核裁定｜PC-03 返工复核 dc3d34d：保持 doing】项目：pCryoxy | PC-03 | 审核方子 agent 用 dc3d34d 独立构建、独立运行：W1/W2/W3/W6 各 3/3，W4 --exact 20/20（1168 与 ENV_BLOCKED 均 0 次）PASS；A1～A3 在 D1 TEL-AN10 API29 与 D2 MAG-AN00 API36 双机 PASS（自建 APK 与执行方 APK 的 dex 逐字节相同）；W5 runner 未改，未执行。结卡前必修：clippy（windows.rs:169）；全量测试 1/6 中止并留下残留（析构断言）；跨进程用例留下残留；配额/重试/边界写入仓库文档；W5 runner schema v2；宿主补 sendStatus 与 README 组件名。待人类裁定：H1 Android 残留 pending 导致永久 Failure(6)（建议结卡前修），H2 rename 覆盖（建议转 PC-11），H3 Windows 跨进程（建议转 PC-10）。环境留下 20 条 pCryoxy/pc03-test/*/master，清理待人类确认。详见 handoff/2026-11-22-pCryoxy-PC03返工复核裁定-dc3d34d-zhn-tbxg2iah-win.md。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 15:35 UTC+8] 【人类裁定登记｜PC-03 H1～H3】项目：pCryoxy | PC-03／PC-10／PC-11 | 人类 15:23 裁定按审核方建议：H1（Android 残留 pending 致永久 Failure(6)）定为 PC-03 结卡前必修第 7 项，改 SecretStore.kt 后双机重跑 A1～A3；H2（rename 覆盖）转 PC-11 评估 RENAME_NOREPLACE；H3（Windows 跨进程凭据一致性）转 PC-10 以单实例服务保证；PC-03 文档写明两条边界。PC-03 仍 doing。任务卡 v1.2 已追记 §9；给 copilot 的补充提示词见 handoff/2026-11-22-pCryoxy-PC03-H1至H3人类裁定落实-zhn-tbxg2iah-win.md §5。本行由 workbuddy 代为登记。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 20:50 UTC+8] 【审核裁定｜PC-03 第三轮复核 4456f66：保持 doing】项目：pCryoxy | PC-03 | 审核方子 agent 独立构建运行：W1/W2/W3/W6 各 3/3，W4 --exact 20/20（1168、ENV_BLOCKED 均 0）PASS；全量测试 10/10、跨进程 3/3、凭据与目录 0 残留；A1～A3 与 recover-pending 在 D1 TEL-AN10 API29、D2 MAG-AN00 API36 双机 PASS（dex 与执行方逐字节一致）；L1 同 UID 与跨 UID PASS；X1 四个证据包 gitleaks 0 命中。上轮必修 7 项中 1～4、6、7 通过，第 5 项 W5 runner FAIL：只能单向（:499/:570）、pcx-t2 读不到 Zhn_X 家目录下的 fixture（:10/:60-70）、未测原始文件与产品代码、哈希写死、缺 cleanup，W5 未执行，退执行方返工。新发现 H4：Android SecretStore.kt:182/:242 疑似 fd 泄漏，建议结卡前修，待人类裁定。20 条 pc03-test 残留凭据在人类确认前已被执行方测试前缀回收清除，审核方未删除。schtasks 被本机安全中心拦截，计划任务状态待人类核查。详见 handoff/2026-11-22-pCryoxy-PC03第三轮复核裁定-4456f66-zhn-tbxg2iah-win.md。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 20:55 UTC+8] 【人类裁定登记｜PC-03 H4 转 PC-11】项目：pCryoxy | PC-03／PC-11 | 人类 20:48 裁定：H4（Android SecretStore.kt:182/:242 FileOutputStream(fd) 不拥有 fd 致泄漏）影响小，转 PC-11 修复，验收为显式关闭 fd + 同进程连续持久化 N≥50 次 /proc/self/fd 数不变 + 双机回归；不作为 PC-03 结卡条件。PC-03 仍 doing，结卡只剩 W5 runner 返工与 W5 双向执行。已追记任务卡 v1.2 §10 与第三轮复核裁定 §8。本行由 workbuddy 代为登记。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 20:55 UTC+8] 【环境｜W5 计划任务未处理原因】项目：pCryoxy | PC-03 | pcryoxy-xacct 正常（Ready、pcx-t2、PT2M、上次 19:58:52 结果 0），19:58 后笔记本转电池供电，DisallowStartIfOnBatteries=True 致错过 27 次。20:54 人类接回电源。建议 W5 复跑前将两项电池条件改 False。详见第三轮复核裁定 §9。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-22 21:05 UTC+8] 【范围确认｜PC-03 W5 返工】项目：pCryoxy | PC-03 | 答复 copilot 20:58 两项提问：① 允许在 tests.rs 新增两个 ignored 测试入口（write-own／read-foreign）经 secure-store 公开 API 建库与读取，windows.rs 仅可加 cfg(test) 内容、产品代码 diff 为 0；读取方四项判定（原始路径拒绝、副本可读且哈希一致、secure-store 打开失败、DPAPI 失败且 CredRead=1168）；② 交换目录 ACL 由人类执行：outbox 改为 Zhn_X 只读，新建 x\zhn_x 与 x\pcx-t2 按写入方修改、对方只读。人类承诺 W5 完成前不拔电源。详见第三轮复核裁定 §10。
