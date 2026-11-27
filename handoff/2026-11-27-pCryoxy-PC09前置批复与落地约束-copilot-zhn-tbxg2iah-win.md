# pCryoxy PC-09 前置批复与落地约束

- project: pCryoxy
- author: `[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-27 08:26 UTC+8]`
- 基于：`handoff/2026-11-27-pCryoxy-PC09依赖与跨Crate接口前置申请-copilot-zhn-tbxg2iah-win.md`
- 人类与 antigravity 已批准 A/B/C/D。实现按下面 5 条收紧，不再按原申请中“用户名绑定 node/rev”。

1. probe-only SOCKS5 inbound 在启动后固定 16 个账户 `probe-slot/0..15`；`set_probe_nodes`、revision 升高时只用 RoutingService 更新 `user=probe-slot/i` 到 `probe/<node>/<rev>` 的规则，不做 AlterInbound。未绑定 slot 必落到首出站 `sys/reject`；最多 16 个探测任务。
2. 一次隔离 CARGO_HOME `cargo fetch` 后，先只落依赖骨架并跑 Windows + Linux GNU + Android ARM64/x86_64 四目标 `--locked --offline cargo check`；确认 Graviola/ureq 无 Android 编译门禁后才写全量业务。TLS 同时支持 1.3/1.2。
3. 构造 rustls/ureq 时显式传 provider/TlsConfig；若调用 `install_default` 必须幂等处理重复返回值，禁止 unwrap。跨测试/同进程多实例均不得 panic。
4. 订阅正文：`take(max_bytes + 1)` 边读边判，超过立即中止并先零化；不信 Content-Length；总耗时受 `timeout_global`。
5. C 项允许边界补为 `crates/protocol-parser/{Cargo.toml,src/subscription.rs,tests/**}`；`SubscriptionFetcher` 返回 `Zeroizing<Vec<u8>>`，错误只保固定枚举，不持 URL/正文/底层错误文本。

获批依赖：`ureq 3.5.2`（features `rustls-no-provider,rustls-webpki-roots,socks-proxy`）、`rustls 0.23.46`（只 `std,tls12`）、`rustls-graviola 0.4.0`、`webpki-roots 1.0.12`。允许一次隔离 fetch；之后全部恢复 `--locked --offline`。若实际 lock 增量超出预估活跃包/交叉平台辅助包，立即暂停重提差异。
