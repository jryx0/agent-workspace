# pCryoxy PC-18 阶段 A 运行时 ABI 阻塞裁定

项目：pCryoxy
审核时间：2026-11-21（UTC+8）
审核人：WorkBuddy

## 一、用户提出的阻塞问题

PC-18 当前说明：要完成真实 daemon，需要 PC-04 提供并经审核的运行时 ABI，包括经 `RegisterRuntime` 创建的 opaque handle、私有 IPC/UID/ticket 接入、状态查询及幂等关闭；当前 `27d942b` 只有纯 prepare；PC-18 不修改 PC-04 Go 文件、不伪造生产测试。

问题：当前是否已有可供 PC-18 接入的已审核运行时 ABI，还是等待 PC-04 补齐？

## 二、核对基线

- PC-04 阶段 A 实施提交：`27d942badfa26afb2d0fb0b60009071881f035b9`
- PC-04 阶段 A 审核裁定：`6e2e21566f48c0ddb60a377882eff39c8decd6f9`
- PC-18 阶段 A 最小接入裁定：`041c2dbe8f7bbdfbb2f333998a93bd4c3baa1f6e`
- PC-04 生产入口依赖裁定：`b513a5bad8be8c1968a5de46381e1b0ae3093d53`

## 三、核对结果

### 1. `27d942b` 的 ABI 不是运行时 ABI

该提交的 C ABI 只导出：

- ABI 版本查询；
- `PC04ABI_v1_validate_restricted_profile`。

它接收序列化 profile 配置和 Geo inventory 元数据，复制输入后返回固定状态码。它没有：

- runtime opaque handle；
- runtime create/start 或对应的 `RegisterRuntime` 跨语言入口；
- 状态查询；
- 私有 IPC/server/transport 接入；
- peer UID/ticket 接入；
- stop/close 或幂等关闭；
- Rust 可调用的资源所有权和错误路径契约。

`RegisterRuntime` 仍是 Go 函数，参数包含 Go `grpc.ServiceRegistrar`、Go `context.Context` 回调和 Go 侧类型，不能直接作为 PC-18 Rust/C ABI 入口。现有 `RegisterRuntime` 调用方仍只有集成测试，没有真实 daemon 生产调用方。

因此，不能把 `27d942b` 或其已审核裁定解释为“运行时 ABI 已提供”。

### 2. 私有 IPC/UID/ticket 的责任边界

既有 `041c2db` 裁定将责任拆分为：

- PC-04：Go 纯 prepare、`RegisterRuntime` 二次校验、Go C ABI 导出面、ABI 符号/内存/错误/线程/生命周期契约，以及 Go bridge 内部 Xray 资源管理；
- PC-18：Rust wrapper、daemon-server、daemon 生命周期和单写者、私有控制端口、peer UID/ticket 认证编排、ready/停止/重启/客户端离线测试。

所以本次不是要求 PC-04 独自实现整个 daemon 或替代 PC-18 的认证编排；但 PC-04 必须先提供可被 PC-18 安全封装的运行时创建/持有/查询/关闭 ABI，以及明确 Go 资源与私有 transport 的所有权边界。PC-18 不能凭现有纯 validator 自行猜测该边界。

## 四、明确裁定

**当前没有已审核、可供 PC-18 直接接入的运行时 ABI。PC-18 阶段 A 运行时接入应保持 blocked，先等待 PC-04 补齐并提交运行时 ABI/契约，再由 WorkBuddy 审核后继续。**

PC-18 当前说明“不会修改 PC-04 Go 文件或伪造生产测试”是正确做法，予以确认。PC-18 可以继续做不依赖未冻结 ABI 的只读设计、隔离 manifest 和测试计划，但不得：

- 自行定义或复制一套 Go runtime ABI；
- 直接把 `RegisterRuntime` 当作 Rust FFI；
- 用纯 prepare validator 冒充 runtime handle；
- 伪造私有 IPC、UID/ticket、ready、状态查询或关闭测试；
- 修改 PC-04 Go bridge 内部文件。

## 五、PC-04 下一次提交必须提供的最小契约

PC-04 应提交新的实施提交和 handoff，至少冻结：

1. 版本化 ABI 符号及 ABI version mismatch 行为；
2. runtime opaque handle 的创建/持有/销毁所有权；
3. `RegisterRuntime` 所需输入如何由 Rust/C 边界表达，不能跨边界传 Go pointer、Go interface 或 Go callback；
4. 私有 transport/server 的所有权：由 Go bridge 创建、由 Rust daemon 提供抽象，或由其他明确的单写者组件拥有；不得含糊；
5. 状态查询最小投影，至少包括 instance ID、phase/ready、epoch、revision、Geo version 和安全错误状态；不得返回配置秘密、ticket、完整路径或 Go pointer；
6. `close`/stop 的幂等行为、并发调用、失败路径、未启动句柄和重复关闭行为；
7. 线程安全、调用线程约束、panic/错误码转换和内存释放规则；
8. `RegisterRuntime` 二次校验仍在 core 创建/启动、初始 Geo publish、服务注册和 ready 前执行；
9. runtime 创建失败时 core、Geo、service、socket、lease 和临时目录无遗留；
10. 真实 ABI lifecycle/race 测试及与 PC-18 wrapper 的最小绑定测试。

其中私有 IPC、peer UID/ticket 的最终 daemon 编排和生产验收仍由 PC-18 负责；PC-04 不能以 ABI 设计替代这些生产证据。

## 六、状态与下一步

- PC-18：阶段 A 继续 `doing / blocked`，阻塞原因成立；等待 PC-04 运行时 ABI/契约更新。
- PC-04：继续 `doing / blocked`；`27d942b` 阶段 A Go 侧实施可接受，但尚未完成 runtime ABI 交付。
- 不授权 PC-18 修改 PC-04 Go 文件。
- 不授权以隔离 validator、mock、测试恒真授权回调或独立伪造 ABI 代替运行时集成。
- 不授权合并或部署。
