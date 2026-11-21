# pCryoxy PC-04 Runtime ABI v2 设计提案交接

项目：pCryoxy
时间：2026-11-21 14:19 UTC+8
Agent：copilot
设备：zhn-tbxg2iah-win
状态：仅设计说明，待 WorkBuddy 裁定

## 1. 基线与现场

- PC-04 当前实施基线：`27d942badfa26afb2d0fb0b60009071881f035b9`
- PC-04 阶段 A 审核：`6e2e21566f48c0ddb60a377882eff39c8decd6f9`
- PC-18 runtime ABI 阻塞裁定：`39461cae236a3779c6417794bf77c4cac7f3fc9f`
- 所有权裁定：`041c2dbe8f7bbdfbb2f333998a93bd4c3baa1f6e`
- PC-04 worktree：`C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc04`
- 分支：`agent/copilot/pc04`
- 设计说明提交：`37c6423c23f1242f03ec5bd6c846aa6c29e39799`
- 本提交仅增加 `native/xray-bridge/abi/runtime_v2_design.md`，不含 ABI 实现。
- 既有未跟踪文件 `tests/integration/bridge/pc04-linux-amd64.a` 保留且未纳入提交。

只读核验确认：`RegisterRuntime` 仍接收 Go `grpc.ServiceRegistrar`、`context.Context` callback、Go `core.Config`/`GeoRoot`，当前调用方只有 bridge 集成测试；ABI v1 只有版本查询与纯 profile validator。现有 `ListenPrivateUnix` 校验服务 UID 所有的 0700 目录并创建/核验 0600 socket，peer UID 可由 Go 内部 `UnixPeerUID` 获取。当前 Geo/runtime close 路径不返回全部清理错误，设计已将 checked cleanup 列为实现前置要求，未把源码现状写成“资源无遗留”证据。

## 2. 设计提案摘要

草案采用一次同步的 Go ABI `runtime_create_start`：输入为 `proto.Marshal(*core.Config)` bytes、Geo root/inventory、PC-18 选择的私有 socket path、允许 UID 和 ticket SHA-256 verifier。ABI 先调用 `ValidateRestrictedProfile`，再进入 `RegisterRuntime`（其仍二次调用同一 validator），完成 Geo preflight、core.New/Start、初始 Geo publish、service 注册后，才创建私有 socket 并启动 gRPC Serve；全部成功后才返回 opaque handle 和 READY。

拟议责任边界：

- PC-18 负责私有目录与 socket path 选择、allowed UID、ticket 生成/分发、父目录创建与清理、Rust wrapper/daemon lifecycle。
- PC-04 Go ABI 按传入 path 创建 Unix socket/listener，持有 grpc.Server、Runtime、Xray core、Geo leases 与 rollback points；close 负责释放这些资源。
- PC-18 传入 ticket 的 SHA-256 verifier；Go 内部 closure 对每个 RPC 同时验证 Unix peer UID 和 authorization metadata ticket，使用 constant-time compare；不跨 ABI 传 Go callback 或 interface。
- v2 使用固定宽度字段、caller-owned buffer、opaque sequence+authenticator handle、固定错误码及不含秘密的状态投影。ABI v1 保持不变。

这是供审核的责任拆分提案，不视为已冻结接口；尤其 Go ABI 创建实际 listener 与 PC-18 “私有控制端口”所有权的解释需要 WorkBuddy 明确裁定。

## 3. 拟议错误/生命周期边界

- create 失败不返回有效 handle；version mismatch 优先返回且不解引用其他参数。
- profile/Geo/core/start/publish/service 失败发生在 listener 创建前；transport 失败时关闭 listener/server/runtime/core/Geo，ready 不成立。
- 首次 close 执行资源清理并返回 `OK`；并发/重复 close 等待完成后返回 `ALREADY_CLOSED`；close 后 status 返回 `INVALID_HANDLE`。
- Serve 在 runtime ready 后异常退出时，释放资源并仅保留无资源的安全失败状态供 status/close 使用。
- Go panic 不跨 C ABI；错误仅返回固定 enum，不返回原始错误文本、路径、配置或 ticket。
- 任意未映射 C 地址无法由 Go ABI 安全探测；草案将其作为 caller contract violation，以隔离子进程测试，不承诺普通错误码。
- PC-18 在 ABI create 失败或 close 后负责移除其拥有的父目录。

## 4. 建议测试矩阵（尚未执行）

拟议普通/race/C smoke 覆盖：版本不匹配优先级、profile 与 Geo/core/publish/service/transport 分阶段失败清理、真实 runtime create/status/close、状态脱敏、invalid handle、重复及并发 close、close/status 并发、至少 8 线程、真实 0700/0600 Unix socket、UID/ticket 拒绝、异常 Serve 后状态清理和 C caller memory 边界。PC-18 获准接入后另由 PC-18 增加 Rust FFI smoke；不得将本阶段的 C smoke 计划冒充 Rust 或生产 daemon 验收。

当前只验证了设计文档提交本身：

- `git diff HEAD^ HEAD --check`：退出码 0
- `gitleaks dir --redact --no-banner <设计文件>`：退出码 0，无泄漏
- 设计文档为纯文档变更，未运行实现构建、Go 普通/race 测试或 C/Rust smoke；没有新增依赖。

## 5. 文件边界

本次 PC-04 提交只新增设计说明。获批准后预计修改 PC-04 自有 ABI/Go bridge/测试/replay 文件；不修改 PC-18 Rust daemon、PC-02 proto/descriptor/生成物/DTO、根 Cargo 清单/锁文件、`contracts/core-lock.json`、公共发布清单或 `native/xray-bridge/go.mod`/`go.sum`。不引入 `SetAdmission`。

## 6. 请求裁定

请 WorkBuddy 对 [PC-04 Runtime ABI v2 设计说明](C:/Users/Zhn_X/source/pCryoxy.wt/copilot-pc04/native/xray-bridge/abi/runtime_v2_design.md) 作设计阶段裁定，重点确认：

1. 是否批准“PC-18 管理目录/path 与 UID/ticket policy；Go ABI 创建并拥有 socket/listener”的 transport 边界。
2. 是否批准 Go 内部验证 UID + ticket verifier，Rust/C 不传 callback。
3. 是否批准同步 create/start 到 READY、单 runtime slot、固定错误码与重复 close 语义。
4. 是否接受无效 C 地址按 caller contract 处理及固定 status struct。
5. 是否批准增加 Go 内部 checked cleanup 与最小安全 status projection。

在设计裁定通过前不实施 ABI 代码、不开展 ABI 构建/生命周期测试、不修改 PC-18 文件，也不通知 PC-18 开始真实 runtime 绑定。

**本交接和提交仅为 ABI 设计提案，不代表 PC-04 runtime ABI 已实施，不代表 PC-04 或 PC-18 结卡通过，也不授权合并或部署。**
