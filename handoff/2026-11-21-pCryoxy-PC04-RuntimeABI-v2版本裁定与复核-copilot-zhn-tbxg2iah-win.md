# pCryoxy PC-04 Runtime ABI v2 版本裁定与复核

项目: pCryoxy

- 记录人：copilot@zhn-tbxg2iah-win~zhn-x-w；本记录为 append-only 补充，不改写此前交付或裁定。
- ABI v2 implementation commit：`2206139fcb86a138b38a10ad43f20f455a99ffaf`，父提交 `06acd52d1ad44f47684aa9d8f21946330b7acd81`。
- ABI v2 设计审核：`eeac8a44813ae0a7f99a5dcc3b272777ab1a1b45`；纯 prepare 前置提交：`27d942badfa26afb2d0fb0b60009071881f035b9`；本轮用户冻结规格决定：2026-11-21（UTC+8）。
- ABI 设计文档澄清提交：`44247c802efe38750f19c958400cbb97086f2d41`，仅修改 `native/xray-bridge/abi/runtime_v2_design.md` 的版本表达说明，不改变 ABI 头文件、状态布局或实现。

## Status 版本规格裁定

**v2 status struct 不内嵌 ABI/version 字段，版本由版本查询函数和 `expected_abi_version` 参数表达；这是为保持 296-byte v2 布局兼容而作出的冻结规格选择。**

继续使用原有固定 296-byte 布局，不改变字段顺序、宽度、alignment、padding、offset 或总大小。ABI 版本通过 `PC04ABI_v2_version()` 查询；create/status/close 在访问其他参数前检查 `expected_abi_version`，不匹配返回固定 `ABI_VERSION_MISMATCH`。版本查询函数本身无 expected-version 参数，仅用于发现当前 ABI 版本。未来需扩展时须使用新 ABI 版本或显式扩展结构，不得破坏 v2。

## 只读核对与范围

- 分支 `agent/copilot/pc04`；实现复核时 HEAD 为 `2206139fcb86a138b38a10ad43f20f455a99ffaf`。工作树仅有既存未跟踪文件 `tests/integration/bridge/pc04-linux-amd64.a`；该文件始终保留，未读写、未暂存、未提交。
- ABI header 的 status size/alignment/offset static assertions 与上述冻结决定一致。C shim 导出版本查询及 create/status/close；三个操作入口均先检查 expected version。C smoke 用不可解引用哨兵参数验证版本不匹配优先。
- 实现启动链继续复用唯一 `ValidateRestrictedProfile(config, initialGeo)`，并由 `RegisterRuntime` 内再次校验；没有引入 `SetAdmission`。
- 相对 `27d942b` 未修改根 `Cargo.toml`、`Cargo.lock`、`contracts/core-lock.json`、`tools/build-*`、CI/build matrix、PC-02 proto/descriptor/生成物、PC-18 daemon、发布清单、`native/xray-bridge/go.mod` 或 `go.sum`。
- 本轮没有新增 Go/C runtime 实现代码；ABI v2 实施内容与范围见原 implementation handoff `2026-11-21-pCryoxy-PC04-RuntimeABI-v2-implementation-copilot-zhn-tbxg2iah-win.md`。

## 本轮复核证据

环境为 Windows 主机上的 WSL Linux amd64；使用固定 Xray `v26.11.9` / 来源 commit `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`、Go 1.27.4、Zig 0.16.0 和既有离线 module cache，无新依赖或在线下载。

执行入口：

```sh
bash tests/integration/bridge/replay-linux.sh \
  "$PC04_XRAY_ARCHIVE" "$PC04_SCRATCH" "$PC04_GO" \
  "$PC04_ZIG" "$PC04_ARCHIVE_OUT" "$PC04_GOMODCACHE"
```

本轮参数使用唯一 scratch `pc04-abi-v2-2206139-verify-nov21`，实现提交及 tracked worktree/index 在 replay 前检查为 clean。完整日志：`files/pc04-runtime-abi-v2-2206139-verify.log`，SHA-256 `afddebd51a5183d96baf0f65a3cef3f053e90686e733eb0c5863e0b497033aac`；日志记录的 replay 脚本退出码为 `0`。PowerShell/WSL 外层包装最后因 CR 字符把 `exit 0` 解析失败并返回非零；这发生在 replay 已完成且脚本结果已记为 0 之后，不把包装器结果冒充 replay 退出码。

实际命令及结果：

- `go test -mod=readonly -count=1 -v -run '^(TestPC04|TestRouterScriptDNSDispatcherReentry)' ./app/router ./app/dns ./common/geodata`：退出码 0。
- `go test -race -mod=readonly -count=1 -v -run '^(TestPC04|TestRouterScriptDNSDispatcherReentry)' ./app/router ./app/dns ./common/geodata`：退出码 0。
- `go test -mod=readonly -count=1 -v ./...`：退出码 0。
- `go test -race -mod=readonly -count=1 -v ./...`：退出码 0。
- `go build -mod=readonly -trimpath -buildvcs=false -buildmode=c-shared -o ... ./abi/cmd`：成功；ABI v1 C smoke 验证纯校验与 1,024 并发调用，ABI v2 C smoke 执行真实 create/status/close、输入边界、失败 handle、socket 权限、重复 close 和 8 线程 status/close；两 smoke 均通过。
- ABI shared library 本轮 SHA-256：`1cb313fc0ec5b50c50fb8ad205fee8ecf7810b9b94a6661ef61579ac88c998c3`（单次 smoke 构建摘要，不声明 shared library 双构建可复现）。
- 两次独立 GOCACHE/GOTMPDIR 的 `go build -mod=readonly -trimpath -buildvcs=false -buildmode=archive` 比较一致；archive 为 3,189,442 bytes，SHA-256 `8a6d31a78f47e9f16872920247df4457b0c762674a72b401373cbc714ec7abff`。结果保留在当前会话 files，不是项目仓库产物。
- replay 日志记录 62 个顶层 PASS 行、0 个 FAIL；`git diff --check` 对实现和本轮文档差异通过。

## 未覆盖、状态与后续责任

- 没有 Rust FFI smoke、PC-18 daemon/真实生产身份 provisioning、生产运行时重启，或跨 OS UID 的独立账户拒绝实测；设计中的 core start、initial publish、service registration 分阶段故障注入/完整资源清零也未全部执行。不能将 ABI C smoke 写成 PC-18 生产接入验收。
- PC-04 与 PC-18 均不因此标记 done。implementation ABI 可供后续 Rust wrapper 集成，但 PC-18 是否解除阻塞仍取决于 WorkBuddy 对实施复核及后续真实 daemon 接入证据；本轮不修改 PC-18 文件、不合并、不部署。
- 请求 WorkBuddy 复核 `2206139` implementation 与本轮 status 版本规格补记；不请求结卡通过。

## 挂起任务（当前全量快照）

继承最新 2026-11-21 PC-03 专项派工快照；本轮不解挂任何项目。

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无 suspended 项；PC-03/PC-04/PC-18 的 `doing / blocked` 不是挂起。pRayShell 已 closed，无 suspended 项。
