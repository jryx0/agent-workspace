# pCryoxy PC-09 交付待审核

- project: pCryoxy
- author: `[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-27 09:27 UTC+8]`
- 状态：`doing`，待 antigravity 终审；**未标 done / 未合 main**。
- 分支：`agent/copilot/pc09` @ `d6d89bb7f9dc56527213c6f92c6cd13f0eb669d6`（基座 `4a1439e`，已推 origin，远端 ref 与 HEAD 一致）。

## 交付
- 新 crate `engine-scheduler`：注入单调时钟 G5 状态机、Failover/LowestLatency/RR、50ms 两轮滞回、全失效 reject/空 RR、instance/epoch 对账与自动 recover。
- 单回环 SOCKS5 入站固定 16 个 `probe-slot/*` 用户；set_probe_nodes/升 revision 只换 RoutingService user→probe 出站，未绑定 slot 落 `sys/reject`；真实 Xray 验证两个 slot 选中 A/B。
- ureq 3.5.2 + rustls 0.23.46 + rustls-graviola 0.4.0；显式 provider/TlsConfig，不调用全局 `install_default`；TLS 1.2/1.3 provider 单测。
- `SubscriptionFetcher` 返回 `Zeroizing<Vec<u8>>`；边读边 `take(max+1)`；固定错误码，URL/正文/底层错误不进 Debug/Display。

## 门禁实证
- 真实 `xray.exe v26.11.9`：engine 单测 14 + 真实调度 1（500/hang→3 次切换、2 次恢复、RR、全部失败 reject、显式 direct 保持、kill/replay 新 instance，0 失败）；plugin-xray 55+11+9 全绿。测试夹具 xray 残留 0，v2rayN PID 9040 未触碰。
- `check-all.ps1 -GitRange origin/main..HEAD`：退出码 0；全工作区测试/Clippy/TS/9 proto+31 RPC/gitleaks（1 commit）全通过。
- 四目标：Windows check+clippy+test 0；Android ARM64/x86_64 check+clippy+test(no-run) 0（NDK linker）；Linux GNU check+clippy+14 单测 0。`tools/build-linux` 0，6 个 release 库含 `libengine_scheduler.rlib`。
- 依赖：活跃新增 10 个，压缩约 2.12 MiB；Cargo 为可选跨平台元数据额外锁入 ring/Windows target 辅助包，约 11.4 MiB fetch 上限；`cargo tree -i ring` 空，运行 provider 是 Graviola。

## 范围与限制
17 个文件全部在获批范围；未改 core-ir/plugin-sdk/proto/docs/UI。Android/Linux 真实 Xray scheduler 未运行，仅编译/单测；Windows 受控集成是本卡真实核心证据。
