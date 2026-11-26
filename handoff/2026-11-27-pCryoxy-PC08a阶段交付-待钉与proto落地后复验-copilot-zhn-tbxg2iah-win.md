# pCryoxy PC-08a 阶段交付：实现完成，待可执行文件钉与 StatsService proto 落地后复验

- project: pCryoxy
- author: `[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-27 00:40 UTC+8]`
- 分支：`agent/copilot/pc08a` @ `fde503a`（基座 `c7d1999`，已推 `origin`；8 个文件，均在卡面允许范围）
- 状态：`doing`。**尚不是“交付待审核”**，原因见下一节。

## 还差什么
`contracts/core-lock.json` 的可执行文件钉与 StatsService proto 还没到 `main`（待办见 `handoff/2026-11-26-pCryoxy-PC08a前置批复与antigravity待办-…`）。提交版本里没有钉，`VerifiedCore::verify` 对任何文件都返回 `IncompatibleVersion`，不会启动核心。

**真实核心的实测因此不是在提交版本上跑的**：我在本机用一段未提交的临时钉（值为实测的 `xray.exe` 34,864,640 B / `1ca7a2cf…3185`）跑通后，提交前把它删掉了。钉落地后必须 rebase 并在提交代码上重跑，才能改成“交付待审核”。

## 已实测（Windows，真实 `xray.exe v26.11.9`，带临时钉）
`PC07_XRAY_BIN=<缓存>\xray.exe cargo test -p plugin-xray --locked --offline -- --include-ignored`：连续 10 轮退出码 0。每轮单测 55、控制面用例 11、PC-07 互通 9，无残留进程。

| 验收项 | 用例（`tests/core_control.rs`） |
|---|---|
| ① 错误二进制 / 错误摘要拒绝启动 | `a_binary_that_does_not_match_the_pin_is_never_started` |
| ② 启动、增删出站、不重启切换赢家、`GetBalancerInfo` 核对 | `winner_switches_without_restarting_the_core` |
| ③ 不可删除 `sys/reject` / `sys/direct` | `system_outbounds_cannot_be_removed_…` |
| ④ RoundRobin 增删成员、空池拒绝 | `round_robin_follows_its_members_…` |
| ⑤ 结果未知后对账、kill 后重放、旧回执失效 | `an_unknown_outcome_is_read_back_and_a_killed_core_is_replayed` |
| ⑥ 错误路径无凭据 / 配置泄漏 | `failures_put_no_credential_or_configuration_…` |

另有：Append / Replace / 出站同步重载（含 Geo 规则）、探测出站同步与重放、宿主崩溃后核心被 Job Object 回收。

## 门禁（提交版本 `fde503a`）
- `tools/check-all.ps1 -GitRange origin/main..HEAD`：退出码 0（gitleaks 1 commit，0 泄漏）。
- 越界 diff 为空。
- `--locked --offline`：`x86_64-pc-windows-msvc`、`aarch64-linux-android`、`x86_64-linux-android` 检查通过；`x86_64-unknown-linux-gnu` 在 WSL（隔离 Rust 1.100.0 + Zig cc 包装）检查、Clippy、单测通过。

## 锁文件变更
- 新增包：`h2 0.4.21`（唯一新增）。
- `plugin-xray` 新增依赖边：bytes、getrandom 0.3.4、h2、http、sha2 0.10.9、tokio、windows-sys 0.61.2、zeroize。
- `tokio-util` 多一条指向既有 `libc` 的边（申请时没预估到）。
- windows-sys 实际启用 6 个 feature，没有用到申请时说的 `Win32_Security_Authorization`。

## 请审核时关注
1. **非 Windows 只能启动和重放**：转换器的私有回传通道只在 Windows 实现，其他平台热增出站 / 改规则返回 `UnsupportedCapability`。
2. **StatsService 消息**是按上游定义手写的，实测可用；proto 入库后需逐字段核对。
3. **明文残留**：`config.rs` 生成 JSON 时的中间字符串、h2 与内核缓冲不在本卡可擦除范围。
4. **Job Object 窗口**：子进程从启动到加入 Job 之间有极短间隙；Unix 无等价兜底。
5. `OutboundDelta` 里的 tag 字符串没有使用，核心 tag 由生成的配置推出。
6. 探测只同步出站；多节点并发探测的路由留给 PC-09。

## 实测中发现并修掉的两个问题
- API 端口被别的监听者占用时，曾把“能连上”当成核心就绪；现在以一次真实 RPC 应答为准。
- 转换管道在写端打开后、首次写入前会出现零长度读取，并发下约 1.5% 的转换丢输出；修正后 1200 次并发转换 0 失败，并留了回归用例。
