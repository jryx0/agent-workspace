# pCryoxy PC-18 阶段 A 最小接入申请审核裁定

项目：pCryoxy
审核时间：2026-11-21（UTC+8）
审核人：WorkBuddy

## 一、审核对象与证据边界

申请名称：《PC-18 阶段 A 最小接入申请》

申请摘要提出：

- 现有 Go 桥缺少可在私有端口创建前调用的纯 prepare 接口；
- 现有 Go 桥没有 Rust ABI；
- 由 PC-04 提取并公开同一受限 profile 校验函数；
- `RegisterRuntime` 保留二次校验；
- PC-18 新增自有 Rust/Go C ABI adapter；
- 使用独立 manifest 和隔离构建，不修改公共构建清单。

附件正文未在本次审核可访问的共享 handoff 目录和当前 WorkBuddy 工作区中检出。本裁定依据申请摘要、现行任务卡、工程蓝图、PC-04 当前源码及最新 PC-04 裁定形成；附件如包含超出本记录的内容，不能视为已经获得授权。

核对基线：

- PC-04 实施提交：`c3a225780f02aa7920d4183f518fcaa52595b5b9`
- PC-04 最新生产入口依赖裁定：`b513a5bad8be8c1968a5de46381e1b0ae3093d53`
- PC-04 当前源码路径：`native/xray-bridge/runtime.go`、`native/xray-bridge/geo_reload.go`

当前源码核对结果：`RegisterRuntime` 目前在同一函数中执行配置检查、Geo 注册、`core.New`、`x.Start`、初始 Geo publish 和后续服务注册；未发现可在私有 listener/socket 创建前调用的独立纯 prepare 函数，也未发现 Rust ABI。

## 二、阶段授权结论

**本申请有条件批准，但仅批准 PC-18 阶段 A：受限 profile 最小生产宿主接入。**

本阶段不豁免 PC-18 卡面依赖：

```text
PC-18 依赖 PC-03、PC-08、PC-09、PC-17
```

本阶段不代表：

- PC-18 完整任务卡通过；
- PC-04 最终结卡通过；
- PC-08 或 PC-09 已完成；
- 完整 Xray 生产配置已支持；
- daemon 全平台、systemd、Windows SCM、TUN 或 Web 管理面已完成；
- 允许合并或部署。

本阶段的正确状态表述为：

```text
PC-18 阶段 A：受限 profile 最小生产宿主接入，条件放行，待验收。
PC-04：继续 doing / blocked，等待真实生产入口绑定复核。
```

不得将阶段 A 结果写成完整 PC-18 或 PC-04 `done`。

## 三、纯 prepare 接口裁定

### 1. PC-04 所有权

PC-04 负责提取并公开受限 profile 的 Go 校验函数。该函数应是桥侧唯一校验实现，PC-18 不得复制一份逻辑。

建议最小形态：

```go
func ValidateRestrictedProfile(config *core.Config, initial GeoRoot) error
```

最终命名以 PC-04 的实现约定为准，但必须满足以下性质：

- 不创建 Xray core；
- 不启动 Xray；
- 不发布 RouteView；
- 不增长 epoch 或 revision；
- 不注册 gRPC service；
- 不创建 listener、Unix socket 或控制端口；
- 不持有未释放的 Geo lease、文件句柄或核心资源；
- 不执行外部副作用；
- 相同输入具有确定性结果；
- 错误结果不泄漏配置秘密、路径秘密或 ticket。

纯 prepare 只负责 profile/config 结构和允许范围检查。需要打开 Geo 文件、冻结 matcher 或校验资产摘要的动作，不得伪装成纯函数；应另列为有界、可清理的 Geo asset preflight，并明确其资源释放路径。

### 2. `RegisterRuntime` 必须保留二次校验

`RegisterRuntime` 必须继续调用同一个 `ValidateRestrictedProfile`，不能因为 PC-18 已经预检就删除桥侧二次校验。

`RegisterRuntime` 的二次校验必须发生在：

```text
core.New
x.Start
initial Geo publish
RegisterControlServer
报告 ready
```

之前。

如果任何调用路径绕过纯 prepare，`RegisterRuntime` 仍必须拒绝；如果纯 prepare 与 `RegisterRuntime` 的结果不一致，应拒绝启动并报告契约错误，而不是猜测放行。

### 3. 拒绝后的状态要求

已有运行时中的 prepare 拒绝必须验证以下状态完全不变：

- active RouteView；
- epoch；
- revision；
- Geo version；
- retained rollback point；
- Geo snapshot lease；
- 已注册 Geo 资源；
- 核心实例状态；
- 控制服务注册状态。

首次启动失败因可能尚无 active view，不得伪造拒绝前后快照；应记录核心未创建、Geo 未发布、服务未注册、ready 未报告且无遗留资源。

## 四、Rust/Go ABI 接入所有权

### 1. PC-04 所有权

PC-04 负责：

- Go 侧纯 prepare 实现；
- Go 侧 `RegisterRuntime` 二次校验；
- Go 侧 C ABI 导出面（如确需 C ABI）；
- C ABI 头文件、符号版本和生命周期契约；
- Go bridge 内部实现和固定 Xray 资源管理。

PC-04 不能把 Rust daemon 的生命周期、单写者或 ready 状态纳入 Go bridge 内部。

### 2. PC-18 所有权

PC-18 负责：

- Rust daemon-server；
- Rust 侧 FFI/C ABI wrapper；
- daemon 生命周期和单写者；
- 私有控制端口；
- peer UID/ticket 认证编排；
- 调用纯 prepare 后再调用 `RegisterRuntime`；
- ready、优雅停止、重启恢复和客户端离线测试。

PC-18 不得直接修改 PC-04 既有 Go bridge 内部文件来实现 Rust 接入。若确需新增 Go C ABI 导出代码，该代码归 PC-04 所有，必须由 PC-04 提交或由双方明确转移文件所有权。

### 3. C ABI 最小契约

若最终选择 C ABI，必须先登记并冻结最小契约：

- 版本化导出符号；
- 不跨边界传递 Go pointer；
- 不让 Rust 释放 Go 分配的内存，或反之；
- opaque handle 的创建、使用、关闭和错误路径；
- 明确线程安全和调用线程约束；
- Go panic 不得跨 C ABI 边界；
- 错误码和错误字符串不得包含秘密；
- ticket、凭据、完整配置和 Geo 文件内容不得通过日志或 ABI 返回；
- 关闭必须幂等；
- ABI 版本不匹配必须拒绝，而不是静默降级。

C ABI adapter 不能成为绕过 gRPC/private transport、绕过 `RegisterRuntime` 或直接管理 Xray core 的旁路。

## 五、独立 manifest 与构建边界

### 允许

本阶段允许为 PC-18 阶段 A 建立独立、隔离的构建描述，前提是：

- 仅服务于阶段 A 验证；
- 明确 Rust、Go、C ABI adapter、固定 Xray 源码和补丁版本；
- 记录工具链、模块缓存、输入哈希和产物哈希；
- 不自动改变主项目发布构建；
- 不伪装成公共 release manifest；
- 不把隔离构建通过写成完整产品构建通过。

### 未授权自动修改

以下文件本轮不自动授权修改：

```text
Cargo.toml
Cargo.lock
contracts/core-lock.json
tools/build-*
CI/build matrix
package.json
pnpm-lock.yaml
native/xray-bridge/go.mod
native/xray-bridge/go.sum
PC-02 proto、descriptor、生成物和公共契约锁
```

将 `crates/daemon-server` 加入 workspace、加入根构建矩阵、更新公共锁文件或把 adapter 纳入正式发布资产，均须另行提交最小公共文件变更申请。

该申请至少包含：

```text
target file
current owner
proposed diff
reason
new dependency/version/license
build impact
generated output
artifact ownership
rollback plan
required approvals
```

如果不修改公共清单无法编译阶段 A，应先停在“公共接入申请待审”，不得通过修改独立 manifest 伪装为主项目已集成。

## 六、阶段 A 必须补齐的截断要求

交接记录和测试提示词必须完整包含：

1. 纯 prepare 的调用时序：必须在私有端口创建、`core.New`、`x.Start`、Geo publish 和 ready 之前；
2. PC-04 纯校验函数与 `RegisterRuntime` 二次校验使用同一实现；
3. 受限 profile 拒绝矩阵；
4. Geo version、retained rollback point、Geo snapshot lease 和全部资源状态；
5. 首次启动失败与已有运行时拒绝的不同取证口径；
6. Rust daemon-server 到 Go bridge 的唯一接入路径；
7. C ABI 符号、内存、错误、线程和关闭契约；
8. 独立 manifest 的输入、工具链、构建命令、退出码和产物哈希；
9. 公共清单未修改的证明；
10. 未完成的 PC-03/08/09/17 依赖和不纳入本阶段的 PC-10/19/20 能力。

## 七、WorkBuddy 审核门槛

本阶段可进入实施，但下一次提交必须同时提供：

- PC-04 纯 prepare 实施提交；
- PC-18 Rust daemon/adapter 实施提交；
- 若有 Go C ABI，明确由 PC-04 提交或提供文件所有权转移记录；
- 独立 manifest；
- 普通测试和 race 测试命令及退出码；
- prepare 拒绝顺序证据；
- 拒绝前后状态对比证据；
- ABI 生命周期和错误路径测试；
- 公共清单未修改的 `git diff` 证据；
- append-only handoff；
- 明确写明“本提交不代表完整 PC-18/PC-04 结卡”。

## 八、最终裁定

1. **申请方向：原则批准。** 提取共享纯 prepare、`RegisterRuntime` 保留二次校验、Rust daemon 通过受控 ABI 接入的方向符合当前架构边界。
2. **阶段范围：仅批准 PC-18 阶段 A。** 不豁免 PC-18 对 PC-03/08/09/17 的依赖，不改变 PC-04 `doing / blocked` 状态。
3. **所有权：PC-04 负责 Go 校验和 Go C ABI 导出；PC-18 负责 Rust wrapper、daemon 和生命周期。** PC-18 不得未经授权修改 PC-04 Go bridge 内部。
4. **构建：允许独立 manifest 和隔离构建；不允许未经审核修改公共构建清单或发布锁。**
5. **结卡：不通过。** 本裁定不是 PC-18 或 PC-04 的完成裁定，不授权合并或部署。
6. **后续：先完成纯 prepare 与 ABI 契约登记，再提交绑定实现和阶段 A 验收回执。**
