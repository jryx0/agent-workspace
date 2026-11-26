# pCryoxy PC-08a 前置申请：gRPC 依赖 + 三项方案裁定

- project: pCryoxy
- author: `[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-26 23:20 UTC+8]`
- 基座：`origin/main c7d1999`；分支 `agent/copilot/pc08a`（worktree `~/source/pCryoxy.wt/copilot-pc08a`，尚无提交）
- 状态：**等待人类批准 + antigravity 审核**。获批前不改 `Cargo.toml`/`Cargo.lock`，尚未写任何实现代码。

## A. 依赖申请（建议甲：`h2` + 手写一元 gRPC，不用 tonic）

| 方案 | 新增锁包 | 说明 |
|---|---|---|
| **甲（建议）`h2 =0.4.21`** | **1 个**：`h2 0.4.21`（MSRV 1.63） | 它的 11 个依赖全部已在锁内。回环 h2c 先验连接、5 字节 gRPC 帧、`grpc-status` trailer 手写，只做一元调用 |
| 乙 `tonic =0.14.9` + `tonic-prost =0.14.9` | 至少 8 个：tonic、tonic-prost、h2、hyper-timeout、tokio-stream、pin-project、pin-project-internal、base64 0.22.x（锁内已有 0.21.7 / 0.23.1，会出现第三个版本） | 禁用 build.rs / codegen 后，tonic 只剩通道封装，收益小 |

甲方案下 `plugin-xray` 的其余直接依赖均为锁内既有版本，不新增包：
`tokio =1.54.1`（`default-features = false`，features `net, rt, time, sync, io-util`）、`http =1.5.0`、`bytes =1.12.2`、`sha2 =0.10.9`、`zeroize =1.8.2`、`getrandom =0.3.4`（`instance_id` 随机源）。

- **不开 tokio 的 `process` / `macros`**：会引入锁外的 `signal-hook-registry` / `tokio-macros`。子进程监管改用 `std::process` 加监控线程。
- 锁文件预期变化：新增 `h2` 一个 `[[package]]`；`plugin-xray` 条目增加上述依赖边；`tokio` 条目不变（已含 mio / socket2 / libc / windows-sys）。
- 离线影响：`h2-0.4.21.crate` 不在本机 `CARGO_HOME` 缓存，获批后需**一次联网 `cargo fetch`**，之后 `--locked --offline` 恢复可用。
- 版本取自 crates.io 索引元数据，实际解析结果获批后复核。

**A-2（可选，建议批准）** `windows-sys =0.61.2`（锁内既有，`cfg(windows)`，features `Win32_Foundation, Win32_System_JobObjects, Win32_System_Threading, Win32_System_Pipes`）。
理由：release 配置是 `panic = "abort"`，宿主崩溃或被杀时 `Drop` 不执行，`xray.exe` 会成为孤儿继续代理；Job Object `KILL_ON_JOB_CLOSE` 由内核兜底。代价是 `supervisor.rs` 出现少量 `unsafe` FFI。不批则只有 `stop()` + `Drop`。

## B. 需裁定的三项方案缺口

### F-1 业务节点出站与路由的 protobuf 从哪来（最大项）
卡面要求把 `core_ir::Node` 手写编码为官方 `OutboundHandlerConfig`。现状：

- `crates/plugin-xray/proto/` 只入库 6 个 proto（两个 command、core/config、typed_message、user、network）。各协议、传输、TLS / REALITY、FinalMask 的消息以及 `xray.app.router.Config` 都没有入库。
- `protocols.rs` 只有两个系统出站；PC-07 的映射（`config.rs`，约 97 KB）全部产出 JSON。
- 实测一个 VLESS + WS + TLS 出站就嵌套 5 种 TypedMessage。

选项：

1. **官方转换器（建议）**：沿用已审的 `config::build_startup_config` 生成 JSON，经 stdin 交给**同一份已校验的 `xray convert pb`**，经私有命名管道取回 `core.Config` protobuf（不落盘），Rust 用 prost 解出 `outbound[]` 与 `app[]`，再由自有 gRPC 客户端发 `AddOutbound` / `AddRule`。`TypedMessage.value` 是官方构建器产出的 protobuf 二进制，不是 JSON；启动路径与热路径共用一份映射，不会分叉。代价是每批转换起一个短命子进程。
2. **纯 Rust 手写**：需先由契约所有者入库数十个上游消息的 proto（数量是我的估计，未逐一清点）并更新 `proto.lock`，再用 Rust 重写 `infra/conf` 的构建语义并做差分测试。工作量与分叉风险远超本卡，建议拆子卡。

### F-2 `core-lock.json` 钉的是发行 ZIP，不是可执行文件
按现有锁文件无法做到卡面要求的“核验 `xray` 可执行文件的大小与 SHA-256”。

1. **所有者补可执行文件钉（建议）**：在各 asset 下增加可执行文件的 size / sha256。Windows 实测 `xray.exe` 为 34,864,640 B，SHA-256 `1ca7a2cf61ba2c5d20b21a80d405b57933939751081cb289f07bd8ddf7cc3185`。supervisor 编译期内嵌锁文件，启动前校验即将执行的那个文件。
2. **supervisor 收 ZIP 自行解压**：校验 ZIP 后解压（手写 ZIP 目录解析 + 锁内 `miniz_oxide`），每次启动重验。解压更适合归更新卡。

### F-3 `StatsService` 的 proto 未入库
`proto.lock` 的 24 个方法里没有它。

1. **所有者入库（建议）**：加入 `app/stats/command/command.proto` 并重生成 `descriptor.pb` / `proto.lock`。
2. **批准手写**：我按上游 `676eaf6` 手写 `QueryStats` 相关的小消息并注明出处。

### 非阻塞备注
`plugin_sdk::OutboundDelta` 生成的 tag 是 `pool/node/<id>`，与 `config.rs` 的 `pool/<group>/<node>/<rev>` 不一致。我会在 `plugin-xray` 内按节点 ID 对账到规范 tag，不改 `plugin-sdk`；请 SDK 所有者知悉。

## C. 已完成与实测

- 认领已登记并同步（共享仓 `4f427f2`）。
- `Xray-windows-64.zip` 已下载到 `~/.agent-tools/cache/pCryoxy/`，大小与 SHA-256 与 `core-lock.json` 一致；解出的 `xray.exe` 自报 `Xray 26.11.9 … 676eaf6`。
- `xray convert pb stdin:` 不带 `-outpbfile`：退出码 1，不支持输出到 stdout。
- `-outpbfile \\.\pipe\<名>` 配双向命名管道：退出码 0，管道收到 492 字节，含预期的 5 个类型名。只开入站方向的管道则报 `Access is denied`。
- **未实测**：Linux / Android 的转换通道（拟用 `/dev/stderr`）。本卡只在 Windows 真机验证，Unix 侧只做编译检查。

## D. 请批复

1. A：选甲还是乙；A-2 是否批准；是否允许一次联网 `cargo fetch`。
2. F-1、F-2、F-3 各选哪一项。F-2 / F-3 的选项 1 需要所有者修改 `contracts/core-lock.json` 与 `crates/plugin-xray/proto/**`，这两处我无权修改。
