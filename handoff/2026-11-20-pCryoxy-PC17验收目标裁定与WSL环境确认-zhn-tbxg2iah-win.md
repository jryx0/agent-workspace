# pCryoxy PC-17 验收目标裁定与 WSL 环境确认

- 项目: pCryoxy
- 卡号: PC-17 Linux 构建基线
- 裁定状态: WorkBuddy 已裁定；PC-17 保持 `doing/blocked`，不得标记 `done`
- 裁定人: workbuddy@zhn-tbxg2iah-win~zhn-x-w
- 裁定时间: 2026-11-20 11:10 UTC+8
- 输入版本: 需求基线 v1.1、工程蓝图 v0.3、实施任务卡 v1.1、API Spec v1.2
- 代码基座: `78cf16612b97d0026ea73da429a1b8b51adf0d4c`
- PC-17 认领提交: `7bc4f85bbf8dd307adc3051f4df37a67449d9940`
- 原阻塞交接: `2026-11-20-pCryoxy-PC17-zhn-tbxg2iah-win.md`

## 一、WorkBuddy 裁定结论

### 1. PC-17 不负责提前实现桥和 daemon

已核实当前代码树：

- `native/xray-bridge/` 当前只有 `core_control.proto`；
- 不存在可构建的桥实现或桥产物；
- 不存在 `pcryoxy-daemon` 二进制目标；
- 当前 workspace 的可执行目标仍为依赖 Tauri 的 `pcryoxy`，`core-ir` 和 `plugin-sdk` 为库。

因此：

- PC-17 **不得**为了满足自身卡面而实现 PC-04 的 Go/Xray 桥；
- PC-17 **不得**提前实现 PC-18 的 daemon-server/daemon 二进制；
- 不得伪造桥版本、桥 commit、桥资产 SHA-256 或 daemon 构建产物；
- 原任务卡中“桥资产”和“最小二进制”的表述，按本裁定解释为：PC-17 只冻结可独立获得的 Linux 平台与上游核心基线，并验证当前实际存在的无桌面构建目标；后续桥资产由 PC-04 产生，daemon 产物由 PC-18 产生。

这不是降低后续验收标准，而是消除 PC-17 对 PC-04/PC-18 的循环依赖。

### 2. PC-17 的可独立验收目标

PC-17 通过条件改为以下五项全部具备：

1. **Linux 环境矩阵**：记录发行版、WSL/内核、架构、libc、Rust target、工具链版本和最低支持口径；缺少实际工具时标记 `blocked`，不填猜测值。
2. **上游核心资产锁定**：记录已批准 Xray 版本/commit、Linux 资产名称、来源和官方 SHA-256；只有下载并本地复算后才能填写本地校验结果。桥资产不在 PC-17 伪造或代产范围内。
3. **无桌面依赖审计**：对现有项目树确认是否存在 Tauri/WebKitGTK/GTK 依赖，并明确当前无 daemon/bridge target；不得把 Tauri 可执行目标当作无桌面 daemon。
4. **Linux 构建入口与工具链记录**：在不安装全局依赖的前提下准备 `tools/build-linux` 或等价构建说明；记录完整命令、target、产物和 SHA-256。工具缺失时可以提交基线锁定和阻塞证据，但不能宣称构建通过。
5. **证据分级与状态**：将“环境探测、工具链安装、源码审计、实际编译、产物检查、Linux 运行”分开记录；`supportStatus` 在桥/daemon/运行时互通未完成前不得标为 `supported`/`ready`。

### 3. 下游任务边界

- **PC-04**：实现并锁定 Linux 桥，完成桥资产、快照/race 和桥运行检查；PC-17 通过后才可按依赖认领。
- **PC-18**：实现无界面 daemon-server、daemon 生命周期和最小 daemon 二进制；不得把 PC-17 的基线记录当作 daemon 已存在。
- **PC-19**：负责 systemd、SOCKS/HTTP、TUN、路由、DNS 和回滚。
- **PC-20**：负责 Web/REST/WS、Token、Origin、会话和断点恢复。

PC-17 通过后，只表示其直接基线门槛已满足；不表示 Linux daemon、systemd、TUN、Web 管理端或代理互通通过。

## 二、本机 WSL 环境确认

用户已授权使用本机 WSL 作为 PC-17 的 Linux 构建环境。WorkBuddy 实查结果：

| 项目 | 实测结果 |
|---|---|
| 发行版 | Ubuntu 24.04.4 LTS |
| WSL | WSL2 |
| 内核 | `6.18.33.2-microsoft-standard-WSL2` |
| 架构 | `x86_64` |
| libc | glibc `2.39`（Ubuntu `2.39-0ubuntu8.8`） |
| 当前状态 | 实查时为 `Stopped`；可按需由 WSL 启动，不构成环境不存在 |
| 已见工具 | `readelf 2.42`、Git 2.43.0（见执行方交接） |
| 缺失工具 | Rust/cargo、Go、Node、C 编译器、make（见执行方交接） |

WSL 被接受为 Linux 环境，但“环境可用”不等于“工具链已安装”，更不等于“Linux 构建通过”。

## 三、工具安装边界

本裁定**不批准安装工具**，也不批准修改 WSL 全局配置。工具安装另列申请，至少应逐项说明：

- 工具名称和固定版本；
- 官方来源与资产 SHA-256；
- 安装位置；
- 是否写入 PATH；
- 是否为项目运行时依赖；
- 许可证、下载体积和安装占用；
- 目标 Linux 架构/libc；
- 回滚方式和验证命令。

在工具申请获批并完成登记前，PC-17 保持 `doing/blocked`。执行方不得自行 `apt install`、修改系统包源、写入全局 PATH 或安装到共享项目目录。

## 四、当前放行与后续动作

1. PC-17 可继续在独立 worktree 中完成环境矩阵、上游核心资产元数据、无桌面依赖审计和构建入口设计。
2. PC-17 不等待桥/daemon 源码出现后才开始这些基线工作，也不自行创建桥/daemon。
3. 工具链申请获批后，再在 WSL 中完成实际构建与产物校验；若缺少可构建的无桌面目标，应如实追加 `blocked` 证据，不移交为“通过”。
4. PC-03、PC-04 仍须等待 PC-17 最终审核通过；本裁定本身不代替代码、构建或产物验收。
5. PC-17 完成后追加“交付待审核”记录，由 WorkBuddy 按本裁定复核；执行方不得自行标记 `done`。

## 五、证据与安全边界

- 本裁定未安装依赖、未修改项目代码、未下载 Xray 资产、未修改系统配置。
- 本裁定只记录 WSL 环境事实和任务边界；不把官方 release 元数据查询写成本地资产校验通过。
- 测试节点、订阅源和真实凭据不得写入源码、共享文档、日志或构建产物。
- pCryoxy 当前无 suspended 项；prnmgt 的三项 suspended 保持原状，未解挂。
