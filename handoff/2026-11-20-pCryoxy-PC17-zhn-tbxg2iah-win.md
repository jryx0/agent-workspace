# pCryoxy PC-17 阻塞交接

- 项目: pCryoxy
- 卡号：PC-17；任务卡 v1.1；状态：doing，实施受阻，未交付审核。
- 执行人：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-20 11:08 UTC+8。
- 输入：需求 v1.1、蓝图 v0.3、任务卡 v1.1、API Spec v1.2；共享审核收尾 `9676950`。
- 基座：`78cf16612b97d0026ea73da429a1b8b51adf0d4c`，已核验包含 PC-01 `3a994011832a3494e6adbceb6b5937830eb8735b` 和依赖 `2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`。
- 现场：`~/source/pCryoxy.wt/copilot-pc17`，分支 `agent/copilot/pc17`；代码未修改，无 PC-17 实现提交。

## 已完成

- 防撞检查通过，认领提交 `7bc4f85bbf8dd307adc3051f4df37a67449d9940`，origin/main 和 backup/main 均核对为该提交。
- 认领前 `tools-scan.sh --check` 和 `proxy-check.sh` 均退出 0。代理检查和双远端同步退出 0；同步回显依次为 origin main `9676950..7bc4f85`、origin tags `Everything up-to-date`、backup main `9676950..7bc4f85`、backup tags `Everything up-to-date`、`双远端推送完成`。
- 源码核验：项目现有可执行目标为依赖 Tauri 的 `pcryoxy`；`core-ir`、`plugin-sdk` 为库。`native/xray-bridge` 只有 `core_control.proto`，不存在桥实现或可构建桥资产；没有 daemon 二进制目标。
- 官方 GitHub release 元数据查询 `gh api repos/XTLS/Xray-core/releases/tags/v26.11.9` 退出 0：`Xray-linux-64.zip` 大小 16,754,078 字节，官方元数据 SHA-256 `b651f7e1d9966ee2c1b1ee1bf8b52c72771824d3065dce96bbc8bcc19ed95f82`，来源 `https://github.com/XTLS/Xray-core/releases/download/v26.11.9/Xray-linux-64.zip`。未下载、未本地验散列、未修改项目锁文件。

## 平台探测与阻塞

- Windows 主机会话只读探测既有 Ubuntu 24.04 WSL2：Linux `6.18.33.2-microsoft-standard-WSL2`、x86_64、glibc 2.39、GNU readelf 2.42、Git 2.43.0。未在 WSL 运行 agent 或建立共享工作区副本。
- Linux `rustc`、`cargo`、`go`、`node`、`cc`、`make` 均未在 PATH 或检查过的常见位置发现；实际构建目标的 Rust target 和编译器不可用。项目锁定 Rust 1.100.0、Go 1.27.4；未安装任何工具，安装须事先申请并登记。
- **blocked：构建工具链缺失。** WSL 可否作为此卡可接受的 Linux 构建证据、如何在不新增 WSL 共享工作区副本和不修改全局配置的情况下提供合规 Linux 工具链，须确认；不能将 Windows 交叉编译称为 Linux 实测。
- **blocked：桥资产及目标不存在。** 用户要求 PC-17 锁定并构建 Linux 桥和最小 daemon/core/bridge 二进制，但桥实现属于须等待 PC-17 的 PC-04，daemon 属 PC-18。本卡禁止实现它们，现有协议与 `core-lock.json` 的 `baseline-declared` 桥版本不构成已构建资产、桥提交或 SHA-256。请 WorkBuddy 明确可验收的先后顺序及允许的真实构建目标，或提供已批准可核验资产；不自行伪造桥、产物或成功结果。
- Linux 最低支持版本、目标 triple、核心资产本地校验、桥版本/commit/资产摘要、构建工具锁、产物摘要和兼容组合均未冻结；supportStatus 不得标 supported。API/桥协议声明分别为管理 API v1 和 `pcryoxy.bridge.v1`，不等于兼容性握手通过。

## 验证等级及未覆盖

仅完成源码核验、环境工具探测及官方资产元数据查询；均非 Linux 编译或产物验证。干净 checkout 无桌面 release 编译、产物大小/SHA-256、二进制动态依赖及 GTK/WebKitGTK/Tauri 排除、Linux 运行、systemd/TUN/路由/代理互通均未执行。无新增依赖、未安装工具、未写入真实凭据；认领增量 gitleaks `protect --staged` 退出 0、无命中。

## 挂起任务（全量快照）

| 项目 | 任务 | 挂起原因 | 解挂前置 | 现场／解挂后动作 | 解挂权 |
|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT；重编卡 | 人类 |

pCryoxy 无 suspended 项；PC-17 是 doing/blocked，不是自行解挂或审核通过。pRayShell 已终止 closed，非 suspended。

## 下一步

请 WorkBuddy 裁定桥及 daemon 与 PC-17 的依赖矛盾，并明确最小真实构建验收对象；请用户确认可接受的 Linux 环境和工具安装授权。PC-03、PC-04 仍须等待 PC-17 审核通过；不提前实施 PC-18、PC-19、PC-20。

## WorkBuddy 裁定（2026-11-20 11:10 UTC+8）

1. 本机 WSL 已确认可作为 PC-17 的 Linux 环境：Ubuntu 24.04.4 LTS、WSL2、x86_64、glibc 2.39；实查时为 Stopped，可按需启动。
2. PC-17 不实现桥或 daemon。当前 `native/xray-bridge/` 只有 `core_control.proto`，无桥实现；当前 workspace 无 `pcryoxy-daemon` target。桥由 PC-04 实现，daemon 由 PC-18 实现，不得伪造资产、commit、SHA-256 或构建产物。
3. PC-17 的独立验收目标改为：Linux 平台矩阵、上游 Xray Linux 核心资产元数据、无桌面依赖审计、Linux 构建入口/工具链记录和可复核的实际构建证据。缺工具时保留 `doing/blocked`，不宣称通过。
4. 工具安装不在本次裁定内；用户授权 WSL 环境，不等于批准 `apt install`、全局 PATH 或其他工具变更。工具需另列清单申请，获批后再执行。
5. 详细裁定见 `handoff/2026-11-20-pCryoxy-PC17验收目标裁定与WSL环境确认-zhn-tbxg2iah-win.md`。PC-03、PC-04 仍须等待 PC-17 最终审核通过。
