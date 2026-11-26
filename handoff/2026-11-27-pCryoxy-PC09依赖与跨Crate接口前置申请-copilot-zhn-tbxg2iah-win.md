# pCryoxy PC-09 前置申请｜HTTP/TLS 依赖与探针路由接口

- project: pCryoxy
- author: `[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-27 07:12 UTC+8]`
- 基座：`origin/main 4a1439e`；分支 `agent/copilot/pc09`，worktree 已建立；工作区干净。
- 状态：**doing / 等待人类批准 + antigravity 审核**。未改任何 `Cargo.toml`、`Cargo.lock`、跨卡源码或工具脚本；申请获批前保持纯只读/文档登记。

## A. 推荐依赖：同步 ureq + 全 Rust rustls provider

| 用途 | 精确依赖 / feature | 说明 |
|---|---|---|
| HTTP/HTTPS、SOCKS5、redirect、流式 body | `ureq =3.5.2`，`default-features=false`，启用 `rustls-no-provider`,`rustls-webpki-roots`,`socks-proxy` | **原文为 `3.5.2`，不能降成 0.3**；阻塞 API 正好匹配 `SubscriptionFetcher` 的同步 trait；探测放入最多 16 个 `spawn_blocking`，每任务 5s global timeout |
| TLS | `rustls =0.23.46`，关闭默认 feature，仅 `std,tls12`；`rustls-graviola =0.4.0`；`webpki-roots =1.0.12` | `rustls_graviola::default_provider().install_default()`；TLS 协议与密码学 provider 均为 Rust，无 OpenSSL、系统 TLS、C/CMake/Nasm/Android NDK 原生库 |
| 调度/零化 | 复用锁内 `tokio 1.54.1`（`rt,sync,time`）、`zeroize 1.8.2` | 不启 tokio macros/process；ureq 请求在受界的 blocking 池中执行 |

`ureq 3.5.2` / `rustls 0.23.46` / `rustls-graviola 0.4.0` / `webpki-roots 1.0.12` 的当前 crates.io 元数据 MSRV 均 ≤1.89，低于仓库 1.100.0。

**预计新增活跃包（10）**：`ureq 3.5.2`、`ureq-proto 0.7.1`、`utf8-zero 0.8.1`、`graviola 0.4.5`、`rustls-graviola 0.4.0`、`rustls 0.23.46`、`rustls-pki-types 1.16.0`、`rustls-webpki 0.103.17`、`untrusted 0.9.0`、`webpki-roots 1.0.12`。`h2/http/hyper/bytes/tokio/zeroize` 已在锁中，不新增同类栈。Ureq+rustls resolution 还会为跨平台元数据锁入 `ring 0.17.14` 与 `windows-* 0.52.6` 辅助包，但不会启用 ring provider；获批后以**真实 worktree resolver 为准**列入锁变更表。

只读 HEAD 估算：活跃包归档约 **2.12 MiB**；若 `cargo fetch` 按 lock 下载全部 Windows 辅助包，隔离缓存上限约 **11.4 MiB**。预计一次冷编译：Windows/Linux 30–90s；纯 Rust Graviola 编译主导。获批后需一次 `cargo fetch`（仅隔离 CARGO_HOME），随后所有验证恢复 `--locked --offline`。

**为什么不复用 reqwest**：`reqwest 0.13.5` 本身已锁，但开启 `rustls-no-provider` 会额外引入 `rustls-platform-verifier`、Linux/Android 原生证书/JNI、Windows/macOS verifier 与 `hyper-rustls`（只读 resolver 约新增 39 包/版本）。PC-09 的流式上限、5s 总超时、 SOCKS5 与有限 redirect 均可由 ureq 完成，依赖面更小、没有系统证书边界。

## B. 探针并发：单 SOCKS 入站 + 16 个认证用户路由

只读核对：当前 `build_startup_config` 确实只允许一个 `ProbeSpec.node_id`，`probe_only` 入站直指一个 `probe/<node>/<rev>`；`set_probe_nodes` 目前只追加出站，不重写多节点探针规则。

**推荐方案**：保留一个仅回环监听、必须密码认证的 `probe_only` SOCKS5 inbound；每个选中节点一个 account，用户名固定 `probe/<node-id>/<config-rev>`，密码共用一个取自现有 `probe_credentials` 的 `Zeroizing` 密钥；为每个 account 生成路由 rule：`inboundTag=probe-socks && user=<that-user> -> outboundTag=probe/<node>/<rev>`。Ureq 每节点构造独立 Agent/Proxy，只保留当前 5s 请求期，日志/错误不输出凭据。

真实 `xray.exe v26.11.9` 只读夹具已证实：① 16 accounts + 16 user rule 的配置 `run -test` 退出 0；② 实际 SOCKS 登录 `node/7` 收到 A、`node/8` 收到 B，证明 `user` 确实选择不同 `probe/*`，不是仅配置通过。相较 16 个独立监听端口，这一方案端口和凭据生命周期更小，也天然将并发上限作为 16 个 account 上限。

核心 epoch/instance 变化时，`engine-scheduler` 先把各组置 `Reject`/空 RR，再重读 `ProbeRoute`、清空旧健康状态并重探；禁止用旧 epoch 的探针回执更新新实例。

## C. 必须批准的跨 Crate / 公共文件边界

1. **新增** `crates/engine-scheduler/**`：状态机、actor、ureq 探测器、`SubscriptionFetcher`、测试。
2. **公共依赖**：根 `Cargo.toml` 增 member；`Cargo.lock` 增上述锁项；`tools/build-linux` 的 `-p` 与产物清单增加 `engine-scheduler`。
3. **plugin-xray 最小扩展**：`config.rs` 将单 `ProbeSpec` 扩为有限 account 映射；`lib.rs` 暴露不实现 `Debug` 的 `ProbeRoute { node_id, endpoint, Zeroizing username/password }`，扩展 `set_probe_nodes` 生成 rules；`tests/core_control.rs` 覆盖双用户并发/epoch 重放。**不改 plugin-sdk/core-ir/proto。**
4. **协议接口修订申请**：现 `protocol-parser::SubscriptionFetcher` 返回裸 `Vec<u8>`，无法让下载缓冲全生命周期受 `Zeroizing`。请求把返回改为 `Result<Zeroizing<Vec<u8>>, Error>`；`prepare_subscription_with_limits` 直接消费，`subscription.rs` 与既有 fake fetcher 测试只做最小适配。若不批准此契约改动，则 PC-09 无法同时满足“用 Zeroizing 包装下载缓冲”和现 trait。
5. URL/正文/凭据不进入错误 `Debug/Display`；内部 ureq error 只映射固定错误码，明文缓冲与 16KiB 读块均 Zeroizing。

## D. 请批准

- A：ureq 3.5.2 + rustls/Graviola + webpki roots 方案；一次隔离 CARGO_HOME 的 `cargo fetch`；验收真实四目标 `--locked --offline`，不允许 OpenSSL。
- B：单入站多用户探针隔离、以及只改 `plugin-xray/{config,lib}.rs` 和对应测试。
- C：`SubscriptionFetcher` 返回 `Zeroizing<Vec<u8>>` 的跨 crate 契约改动。
- D：允许根 `Cargo.toml`、`Cargo.lock`、`tools/build-linux` 的最小变更；锁实际变化若超出上述 10 个活跃包 + 交叉平台辅助包，先停并重提差异。
