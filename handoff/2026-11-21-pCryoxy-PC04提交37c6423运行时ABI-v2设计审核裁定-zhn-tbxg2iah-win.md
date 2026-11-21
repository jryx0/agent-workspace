# pCryoxy PC-04 提交 37c6423 Runtime ABI v2 设计审核裁定

项目：pCryoxy
审核时间：2026-11-21（UTC+8）
审核人：WorkBuddy

## 一、审核对象

- 审核提交：`37c6423c23f1242f03ec5bd6c846aa6c29e39799`
- 父提交：`27d942badfa26afb2d0fb0b60009071881f035b9`
- 阶段 A ABI 阻塞裁定：`39461cae236a3779c6417794bf77c4cac7f3fc9f`
- 阶段 A 所有权裁定：`041c2dbe8f7bbdfbb2f333998a93bd4c3baa1f6e`
- 分支：`agent/copilot/pc04`
- 变更：仅新增 `native/xray-bridge/abi/runtime_v2_design.md`，194 行；无 Go/C/Rust ABI 实现、无公共清单修改、无新增依赖。
- 工作树另有未跟踪 `tests/integration/bridge/pc04-linux-amd64.a`，未纳入本提交。

## 二、审核结论

**设计方向有条件通过，可作为 PC-04 下一阶段实现输入；但本提交不是运行时 ABI 实施提交，不能解除 PC-18 阻塞，不能授权 PC-18 开始真实 runtime 绑定。**

PC-04 仍为 `doing / blocked`；PC-18 仍为 `doing / blocked`。本提交不授权合并或部署。

## 三、已确认的设计优点

1. 正确区分 ABI v1 无状态 profile validator 与拟议 ABI v2 runtime 接口，没有把纯 prepare 冒充运行时句柄。
2. 保留 `RegisterRuntime` 的二次 `ValidateRestrictedProfile`，并将顺序放在 Geo preflight、`core.New`、`x.Start`、初始 Geo publish、service registration 和 ready 之前。
3. 采用 Go 内部创建 gRPC server/listener、Rust 只传 C-safe 输入的方向，避免跨 ABI 传 Go interface、Go callback、Go pointer 或 Go-owned listener。
4. 明确提出 runtime opaque handle、固定 status 投影、固定错误码、panic 收敛、输入复制、同步 create/start、单 runtime slot 和幂等 close。
5. 正确划分 PC-18 的目录/path、ticket 生成分发和 daemon 生命周期责任，以及 PC-04 的 Go runtime/core/Geo/listener 资源责任。
6. 明确承认当前 `Runtime.Close`、`RegisteredGeo.Close` 和 `RegisterRuntime` failure path 尚未具备完整 checked cleanup，未把设计计划写成现有实现证据。
7. 测试计划覆盖 profile/Geo/core/start/publish/service/transport 分阶段失败、状态脱敏、并发 close、status/close 并发、socket 权限、UID/ticket 和 C smoke；并明确 Rust smoke 尚待 PC-18。

## 四、必须在实现前修订/冻结的契约问题

### 1. transport 所有权可接受，但必须冻结边界

原则上接受“PC-18 拥有父目录、socket path 和 policy；PC-04 Go ABI 创建/持有 listener、gRPC server 和 socket”的方案，但实现前必须在头文件和 handoff 中固定：

- path 是绝对、clean、不得已有文件、不得为 symlink 的路径；
- PC-18 创建父目录并保持 `0700`/服务 UID；PC-04 只验证并绑定，不创建、递归删除或接管父目录；
- PC-04 close 必须明确 unlink socket，不能假设 `listener.Close()` 自动删除 Unix socket 文件；
- create 失败和 close 返回后的父目录清理由 PC-18 执行，并有成功/失败证据；
- intentional close 与 Serve 异常退出必须区分，避免正常关闭被记为 FAILED。

### 2. ticket wire format 仍需冻结

设计已规定 Go 接收 ticket SHA-256 verifier，并在每个 RPC 上核验 Unix peer UID 与 metadata ticket；方向可接受。但实现前还要冻结：

- metadata key 的固定名称和大小写规则；
- ticket 的传输编码、长度和是否允许重复 metadata；
- 缺失、重复、错误、过期 ticket 的固定错误行为；
- verifier 的输入是否只允许 32 bytes；
- constant-time 比较的确切位置；
- ticket 不进入日志、status、错误文本或 handle。

### 3. handle 终态语义需补充可验证定义

设计提出 sequence + HMAC authenticator，不保留无界 tombstone，同时规定：已关闭 handle 重复 close 返回 `ALREADY_CLOSED`，但 status 返回 `INVALID_HANDLE`。实现前必须明确：

- 如何区分“曾经由本进程签发后已关闭”与“从未签发但格式合法”的 handle；
- sequence 是否严格单调且永不复用；
- 关闭中的 handle、失败后保留的 handle 和进程重启后的旧 handle 分别返回什么；
- `ALREADY_CLOSED` 是否允许被攻击者用任何 HMAC-valid 但未签发 sequence 触发。

如果实现决定把 HMAC-valid 的非活动 handle 一律解释为已关闭，必须写明该安全假设和测试边界；否则需要有限 tombstone/issued-sequence 状态。

### 4. status 结构需冻结 ABI 兼容规则

固定 status struct 方向可接受，但头文件必须定义：

- `struct_size` 小于/等于/大于当前版本时的处理；
- 所有 padding、alignment、整数宽度和字节序；
- `instance_id`/`geo_version` 截断、终止和字符集规则；
- phase、ready、safe error 的固定枚举值；
- status 在 STARTING、READY、FAILED、CLOSING、CLOSED 各阶段的返回值；
- status 与 close 的并发线性化点。

不得把现有 gRPC `QueryState` 原样暴露为 ABI status；设计中避免 outbound digest/capabilities/原始错误泄漏的方向正确。

### 5. SERVICE_REGISTER_FAILED 需要与 Go API 对齐

当前 `grpc.ServiceRegistrar.RegisterService` 不返回 error；设计错误码中列出 `SERVICE_REGISTER_FAILED`，但现有注册路径主要通过注册或 panic 表达失败。实现前必须明确：

- 是否将 service registration panic 收敛为 `SERVICE_REGISTER_FAILED`；
- panic 后专用 grpc server、Runtime、Geo、core 是否逆序清理；
- 是否移除无法由当前 API 产生的独立“注册返回错误”语义。

不得仅在错误码表中声明该阶段，而没有可执行的失败和清理证据。

### 6. checked cleanup 是实现前置，不是 ABI 外层 recover 的替代

现有源码中的 `Runtime.Close`、`RegisteredGeo.Close` 和部分 `RegisterRuntime` failure path 不能完整报告清理错误，部分路径会 panic 或忽略 close error。下一实施提交必须：

- 建立单一资源 owner 和逆序 cleanup；
- 即使某项释放失败也继续释放其他资源；
- 最终映射固定 `INTERNAL_ERROR`，不泄漏原始错误；
- 证明 core、Geo lease、rollback point、service、listener、socket 和临时资源均已处理；
- 不以 GC、对象不可达或“理论上会关闭”替代证据。

### 7. Serve ready 需要可观测的启动确认

“Serve goroutine 已进入且未立即退出”不能只靠启动 goroutine 的时间猜测。实现必须定义可测试的 ready barrier，并区分：

- listener 已成功绑定；
- gRPC Serve 已进入 accept loop；
- ready 已对 ABI caller 可见；
- Serve 异常退出；
- intentional close。

## 五、实施阶段边界

下一次 PC-04 实施提交才可新增/修改：

- `native/xray-bridge/abi/include/pc04_runtime_v2.h`
- Go runtime ABI/export/handle registry 文件
- C shim
- PC-04 自有 runtime status/cleanup 文件
- ABI 普通/race/C smoke 测试
- 必要的 PC-04 replay/build 更新
- 对应 append-only handoff

未经单独批准不得修改：

- PC-18 Rust daemon/worktree；
- 根 `Cargo.toml`、`Cargo.lock`；
- `contracts/core-lock.json`；
- `tools/build-*`、CI/build matrix；
- PC-02 proto、descriptor、生成物、DTO；
- `native/xray-bridge/go.mod`、`go.sum`。

不引入 `SetAdmission`，不直接把 `RegisterRuntime` 暴露为 C 函数。

## 六、最终裁定

- `37c6423c23f1242f03ec5bd6c846aa6c29e39799`：设计提案审核为**有条件通过**。
- 该提交不是 runtime ABI 实现，不解除 PC-18 blocked。
- PC-04 可按本裁定修订并实施 ABI v2；修订后的头文件、实现、测试和资源清理证据需再次提交审核。
- PC-18 暂不开始真实 runtime 绑定；只能继续不依赖 ABI 的只读设计和隔离准备。
- 不授权合并或部署。
