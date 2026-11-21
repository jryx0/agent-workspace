# pCryoxy PC-04 Runtime ABI v2 专项正式复审申请审核裁定

项目：pCryoxy
任务：PC-04 Runtime ABI v2
裁定人：WorkBuddy
裁定时间：2026-11-21（UTC+8）
申请记录：`handoff/2026-11-21-pCryoxy-PC04RuntimeABI-v2专项正式复审申请-zhn-tbxg2iah-win.md`
本裁定为 append-only 记录，不改写既有裁定。

## 一、裁定结论

```text
PC-04 Runtime ABI v2 桥侧实施：专项复审通过
PC-04 卡状态：继续 doing / blocked（等待 PC-18 真实接入证据，不结卡）
PC-18：允许开始 Rust FFI wrapper 与真实 daemon caller 实现（受条件约束）
合并：未授权
部署：未授权
生产验收：未完成
```

## 二、审核对象

1. 实施提交：`2206139fcb86a138b38a10ad43f20f455a99ffaf`（父 `06acd52d1ad44f47684aa9d8f21946330b7acd81`）
2. 布局澄清提交：`44247c802efe38750f19c958400cbb97086f2d41`（父为 `2206139`，仅改 `native/xray-bridge/abi/runtime_v2_design.md`）
3. 复核 handoff：`ffe2eb58cc2d25f49c5e4e41b0a3a7741c14ffbf`

## 三、静态核对结果（审核方本轮实际执行）

### 1. 提交与边界

- `44247c8` 仅修改 `runtime_v2_design.md`，未触碰 ABI 头文件、status 布局或实现。
- 实施提交相对 `27d942b` 共 19 个文件，全部位于 `native/xray-bridge` 与 `tests/integration/bridge` PC-04 自有边界内。
- 未修改 PC-18 Rust daemon、PC-02 proto/descriptor/生成物、根 Cargo 清单/锁、`contracts/core-lock.json`、`tools/build-*`、CI/build matrix、公共发布清单、`go.mod`/`go.sum`。
- 工作树仅有既有未跟踪 `tests/integration/bridge/pc04-linux-amd64.a`，未纳入提交。

### 2. ABI 契约（头文件逐项核对）

- `struct pc04_runtime_status_v2` 固定 296 bytes，`PC04_RUNTIME_STATUS_SIZE 296u`；`sizeof`/`_Alignof`/全部字段 `_Static_assert` 齐备（struct_size/phase/safe_error/ready/epoch/revision/instance_id/geo_version/reserved 均有偏移断言）。
- 无内嵌 ABI/version 字段；版本通过 `PC04ABI_v2_version()` 与每次调用的 `expected_abi_version` 表达，与 `44247c8` 冻结规格一致。
- 平台限定 Linux/amd64，头文件对其他平台编译报错。
- 固定错误码 0–13 与 handoff 错误码表一致。
- handle 为 24-byte opaque（sequence + 16-byte authenticator），不暴露 Go pointer。

### 3. 版本与准入逻辑（代码核对）

- C shim 三个入口（create_start/status/close）均在读取其他参数前先比较 `expected_abi_version`，不匹配返回 `ABI_VERSION_MISMATCH`；smoke 用不可解引用哨兵参数验证版本优先。
- `abi/cmd/runtime_v2_linux_amd64.go` create 路径：`ValidateRestrictedProfile(config, geo)` 先于 `grpc.NewServer` 和 `RegisterRuntime`；`RegisterRuntime` 内部再次调用同一 validator（`geo_reload.go`），全程未引入 `SetAdmission`（全仓代码零命中，仅设计文档声明不引入）。
- 失败路径：未 publish 时执行 `cleanupResources` 逆序清理并等待 serve 退出，panic 收敛为 `INTERNAL_ERROR`。
- ready barrier：`RegisterRuntime` 完成 core/publish/service 注册后 bind listener，`entry.serve` 进入 accept loop 后才 `m.publish` 发放 handle；任一失败不返回成功 handle。
- start 失败码按阶段（profile/geo/core create/core start/publish/service register）精确映射。
- ticket verifier 为调用方传入的 SHA-256 digest（32 字节），handle 认证使用 HMAC-SHA-256 截断，常量时间比较用于校验路径。

### 4. 测试证据采信

replay 脚本退出码 `0`、`62 PASS/0 FAIL`、ABI v1/v2 C smoke（真实 create/status/close、BUSY、NULL/超长、socket 0700/0600、重复 close、8 线程并发）、双构建 archive 一致（SHA-256 `8a6d31a78f47e9f16872920247df4457b0c762674a72b401373cbc714ec7abff`）、`git diff --check`、gitleaks 通过。交接对失败中间尝试（路径守卫、cgo 标识符、空 handle 语义修正）如实记录，中间失败未冒充通过，予以采信。

PowerShell/WSL 外层包装尾部 CR 解析失败发生在 replay 退出码 `0` 已记录之后，不影响 replay 结果判定。

### 5. 审核边界

审核方本轮环境无 WSL Go/Zig 与固定 replay 依赖，未独立重跑 replay；本裁定基于提交源码静态核对与绑定 handoff 证据采信，与既往 `6e2e215` 审核边界一致。

## 四、裁定事项（对应申请第七节逐项）

1. **认可** `2206139fcb86a138b38a10ad43f20f455a99ffaf` 为 PC-04 Runtime ABI v2 桥侧实施基线。
2. **认可** `44247c802efe38750f19c958400cbb97086f2d41` 对 296-byte status struct 版本表达的澄清与冻结。
3. **允许** PC-18 基于该冻结 ABI 开始 Rust FFI wrapper 与真实 daemon caller 实现，条件：
   - 仅调用本裁定冻结的符号与 296-byte 布局，不得假设新增字段；
   - 不得修改 PC-04 Go 文件、ABI 头文件或任何公共文件；
   - 发现 ABI 不一致时停止并报告，不得自行迁就。
4. **允许** PC-18 开始 UID/ticket、private IPC、ready/stop/restart/client disconnect 集成测试计划与实现；ticket 编排仍由 PC-18 侧负责，PC-04 ABI 侧按已冻结 verifier 边界对接。
5. **PC-04 继续 `doing / blocked`**：待 PC-18 真实接入证据（Rust FFI smoke、真实 daemon caller、生命周期与失败路径证据）提交并通过绑定复审后，另行评估结卡；不得因本裁定标 done。
6. **继续禁止**合并、部署、完整生产验收声明；`core.New`/`x.Start`/publish/service 各阶段 ABI 故障注入与跨 OS UID 实测仍未覆盖，不得写成通过。

## 五、后续责任

- PC-18：按 `39461cae` 与本裁定条件推进阶段 A 真实接入，完成后提交实施 handoff 申请绑定复审。
- PC-04：响应 PC-18 接入中发现的 ABI 缺陷或契约模糊点；修补必须保持 296-byte v2 布局与版本协商语义，破坏性变更须另行申请。

PC-18 在本裁定允许范围内开始的实现，不代表 PC-18 解除 blocked 状态本身；解除以 WorkBuddy 对 PC-18 真实接入证据的后续裁定为准。