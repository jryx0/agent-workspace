项目: pCryoxy
任务: PC-04 Linux Go / Zig 受控工具 smoke
状态: 工具登记和 smoke 证据待审核；PC-04 仍 doing / blocked
依据: 共享授权 `7faad5c`，独立工具准备会话

# PC-04 工具实测

- 官方来源 `https://go.dev/dl/go1.27.4.linux-amd64.tar.gz`，本地归档 70,680,823 字节，SHA-256 `7226736c2339719cda28fbf3a54d71aa63bcefe376e98cef00034268dab24840`，与批准目标一致。隔离安装于 `~/.agent-tools/runtimes/copilot/linux-x86_64-gnu/go-1.27.4/`，实测 244,338,457 字节；`go version` 输出 `go1.27.4 linux/amd64`、退出 0。该目录是仅针对本次安装的回滚目标，删除前须确认无人使用；不得删除其他工具。
- WSL Ubuntu 24.04.4 LTS x86_64 / glibc 2.39；项目专用 Go 缓存 `~/.agent-tools/cache/copilot/pcryoxy-go/` 当前 96,146,936 字节。未改全局 PATH、WSL profile、系统包或项目配置。临时 smoke 源码、构建输出和 Zig 缓存位于本会话独立目录。
- `zig version`：`0.16.0`，退出 0；单命令 `zig cc` 编译并链接最小 C 程序、受控运行均退出 0；`readelf -h/-l` 与 `ldd` 均退出 0，ELF64 x86-64，解释器 `/lib64/ld-linux-x86-64.so.2`，依赖 libc.so.6、动态加载器和 linux-vdso。
- 隔离 `GOENV=off GOWORK=off GOTOOLCHAIN=local GO111MODULE=off GOPROXY=off`，`CGO_ENABLED=0 go build` 最小程序及其运行退出 0；`CGO_ENABLED=1 CC="<隔离 zig> cc" go test -race -v .` 执行独立 cgo smoke，`TestAnswer` 1/1，退出 0。每条具体命令在本会话 `files/pc04-toolchain/smoke.sh`；原始输出保留在会话工具记录，未另存日志文件。
- 首次归档安全检查因脚本引号错误导致 Python 试图打开 `/validate.py`，退出 2；修正命令后检查退出 0，随后安装、版本和 smoke 均按上列记录。该错误未表述为成功。
- 本次仅验证工具链 smoke，不是 PC-04 桥构建、固定核心真实测试、最终链接闭包或 Linux 桥资产。未修改 proto、公共锁、项目代码或系统配置。工具使用仍限定 `7faad5c`；后续 PC-04 须使用隔离缓存、逐项记录真实桥验收，失败依授权停止并上报。

## 挂起任务（当前全量快照）

| 项目 | 任务 | 挂起于/裁决 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认；2026-11-19 暂时不做 | 厂家后台升级中 | 升级完成、复跑探测、更新调研文档 | 调研文档已入库 | 续跑不重开卡 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07；2026-11-19 暂时不做 | 纸张口径未定 | S2 结论、D-5~D-10 裁定、新 ADR | 仅 DRAFT 方案 | 重编卡后认领 | 人类 |

pCryoxy 无 suspended，PC-03/PC-04 doing / blocked；prnmgt S1 已由人类解挂，T-059/T-060/T-061 已完成；pRayShell closed。本次未触碰其他项目。
