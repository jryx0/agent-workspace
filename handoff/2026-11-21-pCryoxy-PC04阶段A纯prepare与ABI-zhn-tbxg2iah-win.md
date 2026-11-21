项目: pCryoxy
卡号: PC-04 阶段 A 配合
版本: WorkBuddy 裁定 041c2dbe8f7bbdfbb2f333998a93bd4c3baa1f6e
当前状态: 交付待 WorkBuddy 复审；PC-04 仍为 doing / blocked

# pCryoxy PC-04 阶段 A：纯 prepare 与 ABI

## 基线与范围

- 裁定基线：`041c2dbe8f7bbdfbb2f333998a93bd4c3baa1f6e`
- PC-04 实施基线：`c3a225780f02aa7920d4183f518fcaa52595b5b9`
- 实施提交：`27d942badfa26afb2d0fb0b60009071881f035b9`
- 分支：`agent/copilot/pc04`
- worktree：`~/source/pCryoxy.wt/copilot-pc04`
- 本次仅实现 PC-04 Go 侧纯 profile prepare、`RegisterRuntime` 二次校验、无状态 C ABI v1、相应契约与测试。
- 未修改 PC-18 Rust daemon、PC-02 proto/descriptor/生成物/core-lock、公共 Cargo/Go 清单；未引入 `SetAdmission`。
- 本提交不代表 PC-04 或 PC-18 结卡通过，也不代表完整 Xray 生产配置验收。

## 实现说明

`ValidateRestrictedProfile(config, initialGeo) error` 是唯一的受限 profile 校验实现。它只检查内存中的 protobuf、允许的功能集合及 Geo inventory 元数据；不读文件、不创建 Geo lease、不创建/启动 Xray core、不发布 RouteView、不改变 epoch/revision、不注册 service、不创建 listener/socket，不记录配置值、路径、ticket 或凭据。相同输入在调用方保证输入不可变期间返回确定性错误。

`RegisterRuntime` 先克隆非 nil 配置，再调用同一校验函数。校验位于 Geo 文件预检、core 创建/启动、初始 Geo publish 及控制服务注册之前；纯 prepare 拒绝时直接返回，不进入这些运行时副作用。

ABI v1 为无状态 C ABI：

- 导出 `PC04ABI_v1_version` 与 `PC04ABI_v1_validate_restricted_profile`；版本不符先于其他输入读取。
- 输入由调用方持有，Go 侧复制，不保留或返回 Go pointer；只返回固定状态码，不返回错误文本。
- Go panic 被收敛为 internal error；接口可并发重入。
- 没有 opaque handle 或持有资源，因此没有 close API；关闭生命周期不适用。
- 头文件定义配置、Geo inventory 与路径大小上限。ABI 不负责文件读取或摘要校验。

### 受限 profile 拒绝范围

校验只接受 router、DNS、dispatcher、outbound manager 四种唯一、完整的受管功能。明确拒绝：

- inbound、outbound、extension、未知 protobuf 字段、未知功能、重复或缺失功能；
- sniffing、未纳管 DNS、DNS matcher/script、非内建 localhost DNS backend；
- `proxy/dns`、`freedom`、`finalmask`、独立 Geo cron；
- 初始配置中不适用于 bootstrap 的路由/Geo 配置、歧义配置及不完整配置；
- 不完整、重复或含路径穿越的 Geo inventory 元数据。

此 allowlist 不表示受限集合之外的 Xray 配置已支持。消费者安全仍依赖当前桥与上游补丁中的同一 RouteView/epoch 绑定；未登记功能均在 prepare 阶段拒绝。

## 测试与构建证据

环境为 WSL Linux x86_64，Go `1.27.4`、Zig `0.16.0`、Zig clang `21.1.0`，使用既有离线 Go module cache。固定 Xray 归档 SHA-256 为 `3932cefef227439f569eb3988ca206b505467be075967a4397452a3ffe9ef033`；脚本按序重放 `0001` 至 `0012` 全部补丁。

实际执行入口：

```text
bash tests/integration/bridge/replay-linux.sh <固定 Xray 归档> <隔离 scratch> <Go 1.27.4> <Zig 0.16.0> <scratch/bridge.a> <离线 module cache>
```

完整脚本命令退出码：`0`。脚本启用 `set -euo pipefail`，任一子命令失败会终止。实际执行并通过：

1. 固定归档摘要校验、按序应用 12 个 upstream patches；
2. Xray router/DNS/geodata 的 PC-04 定向普通测试与 `-race` 测试；
3. 桥 `go test -mod=readonly -count=1 -v ./...` 与 `go test -race -mod=readonly -count=1 -v ./...`；
4. `go.sum` 与仓库版本比较，无依赖锁变更；
5. ABI c-shared 构建，SHA-256：`eb104eb40301c7dfdf90d5dde68447b763139f09b38c4128987cc9c945760d2e`；
6. C ABI smoke：版本、版本不匹配优先、有效/无效/拒绝输入及 8 个线程共 1024 次并发调用通过；
7. 两个独立 GOCACHE/GOTMPDIR 下的 archive 构建逐字节 `cmp` 相同；产物 `3,004,394` bytes，SHA-256：`4e20eb48f9c8213a1768d37f9837db5ab6a5cb8778c027198da75afa73130560`。

新增/扩展的重点测试：

- `TestValidateRestrictedProfileIsPure`：接受路径不存在的虚构 Geo 根，不创建目录、不注册 service；确定性拒绝不完整与重复 profile。
- `TestRegisterRuntimeRepeatsPrepareBeforeAssetPreflight`：纯校验接受 profile 元数据；`RegisterRuntime` 仍执行二次校验，并在资产预检失败时不创建目录或注册 service。
- `TestValidateRestrictedProfileRejectsAmbiguousGeoMetadata`：拒绝路径穿越。
- `TestPC04ProfileGeoRPC`：拒绝矩阵逐项比较纯 prepare 与 `RegisterRuntime` 的错误码/消息，且验证没有 service 注册；新增覆盖 unknown core field。
- ABI smoke 没有可关闭的 handle；它验证了无状态接口的版本、错误边界与并发重入，不代表 Rust wrapper 生命周期验收。

其他检查：

- `git diff --check`：退出码 `0`。
- gitleaks 8.30.1 对本次 9 个提交文件逐项扫描：均为 `no leaks found`。
- 实施提交仅包含 9 个 PC-04 文件。提交后唯一未跟踪文件仍为既有 `tests/integration/bridge/pc04-linux-amd64.a`，未暂存、未提交、未删除。

## 证据边界与未完成项

- 本次证明 PC-04 Go 纯 prepare、复用校验、ABI 编译/调用及固定源码离线测试；不是 Rust daemon 接入测试。
- 未验证生产宿主 listener/ready/重启生命周期、真实生产凭据/节点、完整 Xray 配置、生产部署或所有平台运行。
- 受限 profile 以外的功能仍拒绝；本结果不放行 PC-04 结卡，也不授权 PC-18 结卡。
- ABI v1 尚未由 PC-18 Rust wrapper 调用；不得仅凭本提交宣布 Rust 集成可用。
- PC-04 继续 `doing / blocked`，等待 WorkBuddy 对实施提交与本 handoff 复审；未合并、未部署、未推送。

## 挂起任务（当前全量快照）

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无 suspended 项；PC-04 的 `doing / blocked` 是依赖阻塞，不是挂起。pRayShell 已 closed，无 suspended 项。本轮不解挂任何项目。
