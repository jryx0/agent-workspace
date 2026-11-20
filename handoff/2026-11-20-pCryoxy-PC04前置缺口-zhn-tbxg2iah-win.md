# pCryoxy PC-04 前置缺口

- 项目: pCryoxy
- 卡号：PC-04；任务卡 v1.1；状态：doing / blocked，未交付审核。
- 执行人：`copilot@zhn-tbxg2iah-win~zhn-x-w`；2026-11-20 15:28 UTC+8。
- 输入：需求 v1.1、蓝图 v0.3、API Spec v1.2、任务卡 v1.1；PC-02 审核通过 `78cf166`、PC-17 审核通过 `1e18654`，项目代码待集成。
- 认领共享提交 `325c6ef66dc74b589c2478c6da62a861f24a6c74`，origin 与 backup 均核对一致。独立 worktree `~/source/pCryoxy.wt/copilot-pc04`，分支 `agent/copilot/pc04`，基座 `1e18654ca2a60e8f76c114c891648037d155c336`。源码尚无改动。
- 用户确认项目代码、测试和配置不得与 PC-03 重叠；共享任务登记允许按规范追加。PC-04 不改安全存储文件，PC-03 不改桥文件，公共清单/锁/契约不在两卡分支争写。

## 固定上游只读核验

- 只读 GitHub API 核验 `XTLS/Xray-core` 提交 `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`、tree `717e944e218f098a8448f1f2f925bb7a8fa02559`；根 LICENSE 声明 MPL-2.0，不据此推断依赖闭包许可。上游 go.mod 声明 Go 1.27 和多项直接/间接依赖，版本以该提交原文件为准；没有下载或安装这些模块。
- 固定版本 `app/router/router.go` 中 rules 与 balancers 为两个独立 atomic 指针，`ReloadRules` 先存 balancers 再存 rules，替换后立即关闭旧 webhook；不能用桥外 mutex、假快照或基于此路径直接宣称跨规则/Geo/override 一致。
- 固定版本 `common/geodata/{ip_registry,domain_registry}.go` 各自拥有 registry 与可独立刷新 matcher；`app/geodata/geodata.go` 支持 cron 且依次调用两个 reload。`app/router/balancing.go` 的 override 在现有 balancer 上独立更改。
- 固定版本 `app/router/command/command.go` 的官方 AddRule/RemoveRule/Override 直接委托 router，官方与兼容服务名共用服务。实际补丁须覆盖真实读写路径及 DNS Geo 消费者，并保留旧 view/资源生命周期；不允许 SetAdmission、新流拒绝门禁或只在 gRPC 外套锁。

## 缺口和请审核

1. 上游源仓和 Go 模块尚未在本项目隔离缓存就绪；固定上游仓库本身为 MPL-2.0，其直接和传递依赖的版本、许可证、下载/安装占用及运行时/编译时关系尚未完成清单。`go.mod/go.sum` 属 PC-04，但新增模块和下载依七条铁律须先申请；请审核固定 Xray 及依赖闭包的获取/构建方案、隔离位置与许可，勿将 Xray 固定版本等同所有传递包自动获批。
2. 现有隔离 Windows Go `go1.27.4 windows/amd64` 可执行；`go env CGO_ENABLED` 返回 `0`，当前 PATH 未发现 `gcc` 或 `cl`，尚未建立可用的 Go race 环境。PC-17 的 Zig 和 Linux Rust 审核授权仅限该卡已消耗的构建，不自动授权此卡构建；所需编译器及 Linux Go 只能另行盘点、申请和登记，不安装系统包。
3. 上游最小补丁、完整候选构造与版本根、受控进程、真实 Geo/routing/override race 与线性化集成、Linux 桥二进制和资产摘要均尚未实施或实测。现有桥 proto 是 PC-02 冻结契约，不改动；`contracts/core-lock.json` 是公共锁，桥资产/patchSet 需要由所有者在审核后串行维护。
4. 请 WorkBuddy 确认上游依赖闭包审计与可用构建环境路径。若本卡发现必须改变公共契约，先提交最小变更给 PC-02 所有者；不凭构建占位模型声称真实核心集成完成。

## 挂起任务全量快照

- pCryoxy：无 suspended；PC-03、PC-04 均已认领 doing，PC-04 本前置缺口 blocked；这不是 suspended。
- prnmgt：S1 T-059/T-060/T-061、S2 P0 二次真机调研、S3 v4 / #18 suspended，未触碰。
- pRayShell：closed，未触碰。

## WorkBuddy 审核记录（2026-11-20 15:33 UTC+8）

审核对象：共享提交 `1a7bdc32768243ca975ddf29690fe6eae597f340`。

结论：**前置缺口登记通过；PC-04 继续 `doing / blocked`，不标 done。**

审核确认：

1. 本提交只新增 PC-03/PC-04 前置缺口交接和项目登记，没有修改 pCryoxy 代码、Go 模块、公共锁、proto 契约、系统工具或桥资产。
2. PC-04 阻塞依据成立：固定 Xray 上游的直接/传递依赖版本、许可证和缓存闭包尚未审核；当前 Windows 环境没有可用 `gcc`/`cl`，不能作为 Go race 验收环境；上游最小补丁、真实受控核心、Geo/routing/override 线性化测试、Linux 桥资产均尚未实施或实测。
3. 固定 Xray 根 LICENSE 为 MPL-2.0 不能替代整个 Go 依赖闭包的许可证盘点；不得把上游固定提交或 `core-lock.json` 声明值写成已取得的桥资产。
4. PC-17 的 Zig/Rust 授权只覆盖已经审核的 PC-17 纯 Rust库构建，不自动扩展到 PC-04 的 Go 编译、race、桥构建或 Linux 资产生成。
5. proto 契约和公共 `contracts/core-lock.json` 保持冻结；如需改变公共契约或锁文件，先交 PC-02/PC-00 所有者审核并串行维护。

本次允许：继续只读上游源码核验、依赖闭包/许可证盘点、补丁设计和测试计划；不允许安装未批准模块或系统包、扩大工具授权、使用占位模型宣称真实核心通过或生成未经审核的桥资产。

本审核不放行 PC-08、PC-12、PC-18、systemd/TUN、运行时、Web 或最终产品 L3。
