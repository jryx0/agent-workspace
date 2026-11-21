项目: pCryoxy
卡号: PC-04 Runtime ABI v2
版本: WorkBuddy 设计裁定 eeac8a44813ae0a7f99a5dcc3b272777ab1a1b45
实施基线: 06acd52d1ad44f47684aa9d8f21946330b7acd81
当前状态: 实施提交已形成，等待 WorkBuddy 复审；PC-04/PC-18 仍 doing / blocked

# PC-04 Runtime ABI v2 实施交付

## 提交与现场

- implementation commit: `2206139fcb86a138b38a10ad43f20f455a99ffaf`
- branch: `agent/copilot/pc04`
- worktree: `~/source/pCryoxy.wt/copilot-pc04`
- parent: `06acd52d1ad44f47684aa9d8f21946330b7acd81`
- 本提交只包含 PC-04 Go/C bridge、IPC/生命周期代码、测试及 replay 文档；没有 push、merge、deploy。
- 未修改 PC-18 Rust daemon、PC-02 proto/descriptor/生成物/core-lock、根 Cargo 清单/锁、Go 清单/锁、CI/build matrix 或发布清单；未引入 `SetAdmission`。
- 原有未跟踪文件 `tests/integration/bridge/pc04-linux-amd64.a` 保留且未提交。

本提交不代表 PC-04 或 PC-18 结卡通过，不代表 Rust daemon 集成或完整 Xray 生产配置验收。PC-18 在 WorkBuddy 审核本 implementation SHA 前不得据此开始真实 runtime 绑定。

## ABI v2 契约与所有权

- 平台限定 Linux/amd64，头文件对其他平台/架构编译报错；ABI v1 无状态 validator 保留。
- C 符号：`PC04ABI_v2_version`、`PC04ABI_v2_runtime_create_start`、`PC04ABI_v2_runtime_status`、`PC04ABI_v2_runtime_close`。
- runtime handle 是 24-byte opaque value：单调序号加进程内随机 HMAC-SHA-256 截断认证值；不包含或暴露 Go pointer。
- ABI 可并发调用。调用者提供的 C 内存须在整次调用内有效、可读/写且不并发改写；ABI 不能安全探测任意无效地址。NULL 与长度边界有测试；任意坏地址没有在进程内解引用测试。
- 调用方持有输入缓冲区；PC-04 在调用内复制输入，不保存 C/Go 指针。调用方创建并持有权限 0700 的 socket 父目录；Go bridge 持有 runtime、Xray core、Geo leases/rollback points、gRPC server 与 Unix socket，并在 close/失败时清理。
- PC-18 提供 socket 路径、允许的 peer UID 与 ticket SHA-256 verifier；Go bridge 从 Unix peer credentials 获取实际 UID，并校验唯一、canonical、无 padding 的 43 字符 base64url ticket。测试恒真 authorize 回调不进入生产 ABI。
- 启动顺序：受限 profile prepare -> `RegisterRuntime` 内同一 validator 二次校验 -> Geo asset preflight -> `core.New` -> `x.Start` -> initial Geo publish -> Control service registration -> Unix listener bind -> gRPC `Serve` 进入首个 `Accept` -> 发布 READY 和 handle。未到 ready barrier 前不返回成功 handle。
- status 固定投影仅含 instance ID、phase、ready、epoch、revision、Geo version、安全错误码；不含配置、secret/ref、ticket、路径、错误原文或 Xray 对象地址。status 输出测试还检查 Geo 目录和 ticket digest 不出现。
- `close` 幂等；status/close 与并发 close 使用锁和关闭屏障协调。状态 handle 终止后 status 返回 `INVALID_HANDLE`，重复关闭返回 `ALREADY_CLOSED`。

固定错误码：

| 名称 | 值 |
|---|---:|
| OK | 0 |
| ABI_VERSION_MISMATCH | 1 |
| INVALID_ARGUMENT | 2 |
| PROFILE_REJECTED | 3 |
| GEO_PREFLIGHT_FAILED | 4 |
| CORE_CREATE_FAILED | 5 |
| CORE_START_FAILED | 6 |
| INITIAL_PUBLISH_FAILED | 7 |
| SERVICE_REGISTER_FAILED | 8 |
| TRANSPORT_FAILED | 9 |
| INVALID_HANDLE | 10 |
| ALREADY_CLOSED | 11 |
| BUSY | 12 |
| INTERNAL_ERROR | 13 |

所有 Go 导出入口均捕获 panic 并转换为固定 `INTERNAL_ERROR`；错误返回不带原始错误文本。ABI v2 没有跨边界分配/释放 Go 内存。

## 固定源与实际测试

环境：WSL Linux x86_64；固定 Xray `v26.11.9` / 来源 commit `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`；归档 1,318,088 bytes，SHA-256 `3932cefef227439f569eb3988ca206b505467be075967a4397452a3ffe9ef033`；Go `1.27.4`；Zig `0.16.0`；Zig clang `21.1.0`；离线 Go module cache。按序重放 `0001` 至 `0012` 全部 upstream patches，`go.sum` 与 worktree 相同。

可复现入口（从 PC-04 worktree 根目录执行；路径变量指向本机已审计的固定归档、隔离 scratch、工具与离线 module cache）：

```sh
bash tests/integration/bridge/replay-linux.sh \
  "$PC04_XRAY_ARCHIVE" "$PC04_SCRATCH" "$PC04_GO" \
  "$PC04_ZIG" "$PC04_ARCHIVE_OUT" "$PC04_GOMODCACHE"
```

完整 replay 实际退出码：`0`。脚本启用 `set -euo pipefail`，包含固定归档校验、12 个补丁重放、普通/race 测试、ABI 构建与 C smoke、双构建比较。实际通过：

1. Xray 定向普通测试和 `-race`：`go test [-race] -mod=readonly -count=1 -v -run '^(TestPC04|TestRouterScriptDNSDispatcherReentry)' ./app/router ./app/dns ./common/geodata`，所有目标包通过。
2. Bridge 普通测试和 `-race`：`go test [-race] -mod=readonly -count=1 -v ./...`，bridge 与 ABI 包通过；fixture 无独立测试文件。
3. Go shared ABI 构建和两个 C smoke 退出码均为 `0`。ABI v1 smoke 验证纯校验与 1,024 并发调用；ABI v2 C smoke 实际创建、查询并关闭 runtime，检查 profile/Geo 失败无 handle/socket、BUSY、NULL/过长输入、版本不匹配优先、status 安全投影、socket 父目录 0700/socket 0600、重复 close，以及 8 个线程并发 status/close。
4. ABI shared library SHA-256：`3cc780141a99869d5b76b3dcf583ead3d1585a33da9d268e047f9809693a5bc3`。
5. 两个独立 GOCACHE/GOTMPDIR 下的 archive 构建 `cmp` 相同；产物 3,189,442 bytes，SHA-256：`8a6d31a78f47e9f16872920247df4457b0c762674a72b401373cbc714ec7abff`。
6. `git diff --check`、staged diff check、`go.sum` 比较退出码均为 `0`。Gitleaks `8.30.1` 对本次 staged 文件扫描：`no leaks found`（约 71.26 KB）。

本轮修正后的额外竞态测试 `TestRuntimeStatusCloseConcurrent` 每轮并发发起 status 与两个 close：恰好一个 close 返回 OK、另一个返回 ALREADY_CLOSED；关闭后 status 返回 INVALID_HANDLE。普通与 `-race` replay 均执行通过。

### 失败的中间尝试（不作为通过证据）

- 首次将 Windows 路径直接传给 WSL replay，脚本在“artifact output must be outside the source tree”守卫退出 `1`，没有测试执行；只产生的临时目录已检查并删除。
- 下一次 replay 的测试编译因 `_test.go` 引用了 cgo 文件局部的 `C` 标识符而失败；改为 ABI 固定码测试常量后重跑。
- 随后的 C smoke 首次退出 `11`：空 handle status 被映射为 `INVALID_ARGUMENT`，与冻结契约不符。修正为零序号 `INVALID_HANDLE`、NULL authenticator `INVALID_ARGUMENT`，并在最终 replay 再次验证通过。

## IPC 与失败路径边界

- 同 UID 的真实文件系统 Unix socket、0700/0600 权限、peer UID 上下文、缺失/重复/格式错误/错误 ticket 拒绝及 socket close/unlink 已执行。
- 跨 OS UID 子进程拒绝未实测：环境无 root/免密 sudo，`sudo -n` 退出 `1`；集成测试明确记录 blocked 并继续同 UID 检查。不得把策略配置的错误 UID 拒绝等同于第二 OS 用户实测。
- Profile 拒绝与 Geo preflight 失败实际验证没有 handle/socket；RegisterRuntime 的纯 prepare/二次校验、asset preflight 与 checked registrar panic 单测通过。
- 未做 `core.New`、`x.Start`、initial publish、service registration 各阶段的 ABI 故障注入/全量资源清零实测；相关固定错误码已定义，不能把代码存在写成这些故障路径的验收通过。
- 未对任意坏 C 地址做进程内测试；调用者必须遵守有效内存契约。NULL、超长长度和结构尺寸边界已实际测试。
- 未做 Rust FFI smoke、PC-18 daemon-server、真实生产身份/ticket provisioning、宿主重启/恢复或生产配置验收；没有修改 PC-18 文件。

## 文件与审核交接

implementation commit 共 18 个文件：

- `native/xray-bridge/abi/README.md`
- `native/xray-bridge/abi/cmd/runtime_v2_linux_amd64.go`
- `native/xray-bridge/abi/cmd/runtime_v2_linux_amd64_test.go`
- `native/xray-bridge/abi/cmd/runtime_v2_shim_linux_amd64.c`
- `native/xray-bridge/abi/fixture/main.go`
- `native/xray-bridge/abi/include/pc04_runtime_v2.h`
- `native/xray-bridge/checked_registrar.go`
- `native/xray-bridge/geo_lifecycle_internal_test.go`
- `native/xray-bridge/geo_reload.go`
- `native/xray-bridge/ipc_unix_linux.go`
- `native/xray-bridge/ipc_unix_linux_test.go`
- `native/xray-bridge/runtime.go`
- `native/xray-bridge/runtime_abi_status.go`
- `native/xray-bridge/runtime_lifecycle.go`
- `native/xray-bridge/runtime_registration_test.go`
- `tests/integration/bridge/control_ipc_test.go`
- `tests/integration/bridge/pc04_runtime_abi_smoke.c`
- `tests/integration/bridge/replay-linux.sh`

审核交接：

1. 卡 ID：PC-04 Runtime ABI v2。
2. implementation commit：`2206139fcb86a138b38a10ad43f20f455a99ffaf`。
3. 文件清单：见上。
4. 输入版本/裁定：WorkBuddy `eeac8a44813ae0a7f99a5dcc3b272777ab1a1b45`；实现基线 `06acd52d1ad44f47684aa9d8f21946330b7acd81`；Xray `v26.11.9` / `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`。
5. 依赖审核号：ABI v2 设计审核 `eeac8a44813ae0a7f99a5dcc3b272777ab1a1b45`；无新增 Go/Cargo 依赖。
6. 实际测试：固定源码 replay、普通/race、ABI v1/v2 C smoke、双构建，均退出 `0`；跨 UID OS 用户检查 blocked。
7. 预期与实测：Linux/amd64 C ABI runtime 可创建、查询、幂等关闭；启动前拒绝样例无 handle/socket；status/close 并发测试通过。不是 Rust/生产 profile 验收。
8. 未覆盖：跨 UID OS 用户、任意坏地址、各 core/start/publish/service 阶段 ABI 故障注入、Rust FFI/PC-18 daemon、生产宿主生命周期与完整配置。
9. 凭据脱敏检查：Gitleaks 8.30.1 staged scan 无泄漏；测试仅用虚构 Geo 和全零测试 ticket 派生值。
10. 新增依赖：否；`go.sum` 未变，公共清单/锁未修改。

请求 WorkBuddy 复审 implementation SHA 与本 handoff。未 push、未 merge、未 deploy；PC-04、PC-18 状态保持 doing / blocked。
