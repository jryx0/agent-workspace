# PC-14a 交付待审核

- 分支：`agent/copilot/pc14a`
- 提交：`e4915722e2aea4d3d3a4ef4b4ce197c3a12278ed`
- 基座：`origin/main ceaad5c`；仅获批文件范围，未改 `public_dto.rs/generated.ts/proto/contracts`
- `check-all.ps1 -GitRange origin/main..HEAD`：退出 0
- `runtime-host`：9 个单测 + 1 个真实 Windows Xray 持久化/启动/重启测试，退出 0；测试进程残留 0
- PC-09 真实核心回归：scheduler 14+1、plugin-xray 55+11+9，退出 0
- 四目标 `--locked --offline` Clippy：Windows、Android arm64/x64、Linux 全通过；`tools/build-linux` 通过并生成校验清单
- `build-windows.ps1`：退出 0；`pcryoxy.exe 8,812,032 B`、`ui/dist 158,668 B`；同目录锁定 `xray.exe 34,864,640 B`（SHA-256 `1ca7…185`）
- 首轮桌面冷启动：374 ms；静态主进程 RSS 18,685,952 B、Private 3,346,432 B。转发中 IPC P95/P99 尚未采集。
- gitleaks：1 commit / 186.10 KB / 0 leaks
- R3：自动测试仅注入代理后端；未写真实 HKCU；现存 Xray PID 39164 的父进程是 v2rayN，未触碰
- 待审核项：协议解析层不暴露替换冲突候选，因此 `replace_confirmed` 仍明确返回 `UnsupportedCapability`；异步任务为即时完成，`operation_cancel` 对已完成任务返回 `CannotCancel`

状态保持 `doing`，等待 antigravity 终审，不合 main。
