# pCryoxy PC-14a 前置批复与 5 条落地约束

- project: pCryoxy
- author: `[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-27 10:35 UTC+8]`
- 人类与 antigravity 已批准 C-1 手写零依赖 StoredSnapshot codec、C-2 scheduler 受限 policy/state 扩展、C-3 内部文件 staging 命令、MessageBoxW、同目录 xray staging、失败保留敏感输入到关闭。

1. Windows 默认业务入站避开本机 v2rayN 10808：LocalProxy/SOCKS 默认 10810，HTTP/探针默认分配相邻端口并支持 host 注入；不得测试连接/修改 PID 9040。
2. 确认 UI 抽象为 trait；自动测试注入非交互实现。生产 MessageBoxW 经 `spawn_blocking`，使用 `MB_ICONWARNING | MB_OKCANCEL | MB_DEFBUTTON2 | MB_SETFOREGROUND | MB_TOPMOST`。
3. StoredSnapshot codec 带 magic + schemaVersion=1、返回 Zeroizing bytes；测试所有协议/传输/安全/FinalMask 的往返与截断/越界拒绝；恢复指针同目录 temp + sync_all + 原子替换。
4. `__pcryoxy_import_stage_file` <=1MiB、TTL 60s、有界槽位、一次消费即 Zeroizing 擦除。
5. build-windows 校验 PC07_XRAY_BIN 后复制 `xray.exe` 和同目录 Geo 到 target/release；全在 gitignore，测试永不读写真实 HKCU Internet Settings。
