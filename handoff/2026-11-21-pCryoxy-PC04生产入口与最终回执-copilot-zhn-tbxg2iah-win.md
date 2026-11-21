# pCryoxy PC-04 生产入口与最终回执

项目: pCryoxy

- 记录人：copilot@zhn-tbxg2iah-win~zhn-x-w；本记录追加，不改写历史裁定。
- implementation commit：`c3a225780f02aa7920d4183f518fcaa52595b5b9`；其父提交：`ec3af128c039170800fb046e25a20200f2ce5aca`。
- 联合裁定：`603f0c2148e47642814b035e5013f1da3bdb988c`；前置裁定：`8a3030461d6c02f0e877a5c8d8cdf640884b6c37`、`bc0d5a9ce02e0485701b98647fc7cc5ce6f7ba9e`。
- 分支 `agent/copilot/pc04`；worktree `C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc04`。复跑前后 HEAD 均为上述 implementation commit，已跟踪工作树无差异；复跑前暂存区无差异。未跟踪的 `tests/integration/bridge/pc04-linux-amd64.a` 保留，未暂存、未提交，也不是本轮产物。
- 本轮未修改项目代码，未创建新的实施提交；该提交的文件为 `native/xray-bridge/geo_lifecycle_internal_test.go`、`native/xray-bridge/geo_reload.go`、`tests/integration/bridge/profile.md`、`tests/integration/bridge/replay-linux.sh`、`tests/integration/bridge/route_view_test.go`、`upstream-patches/0011-explicit-geo-snapshot-release.patch`、`upstream-patches/0012-geo-snapshot-reader-lifecycle-test.patch`。

## 生产入口和受限 profile

当前 PC-04 代码树内 `RegisterRuntime` 的调用均在 `tests/integration/bridge/control_ipc_test.go`；没有实际生产调用方。不能证明生产启动必经此校验，需 PC-18/运行时集成绑定并验证；本轮不实现 daemon，也不将测试中的恒真授权回调当成生产认证。

入口自身在 `core.New`、`x.Start` 和初始 Geo publish 之前校验启动 profile。允许 router、DNS、dispatcher、outbound manager 各一份，不允许 inbound、outbound、extension、未知字段和未纳管功能；DNS 仅允许空列表或默认端口/网络的 localhost，Geo 使用经过校验的受管快照，不允许独立 cron。它是 management/routing core，不是提供可拨号出站的代理启动 profile。生产调用者仍须配置私有 listener、peer UID 和 per-runtime ticket 授权，不能仅依靠 socket 权限。

## prepare 拒绝及状态证据边界

- `TestPC04ProfileGeoRPC` 覆盖 inbound/outbound 容器中的 sniffing、finalmask、proxy/dns、freedom 样例、独立 cron、router/DNS 脚本、未知字段、extension 及多种未纳管 DNS 地址；拒绝时断言 `FailedPrecondition` 或 `InvalidArgument` 且 gRPC 服务未注册。上述名称对应测试输入，不能误写为所有底层组合都已独立实测。
- 源码顺序表明启动 profile 校验发生在 core 创建、启动和 publish 之前；这是源码证据，不是生产入口绑定证据。对未绑定同一 RouteView/epoch 的消费者，现有受限 profile/实例级 Geo 证明有拒绝逻辑，未证明任何未来生产调用方不可绕过。
- 运行中 Geo 未注册和 stale revision 失败测试断言无 receipt，epoch、revision、Geo version 不变；受限路由拒绝测试还核对活跃规则不变并成功使用既有 rollback point。不能扩大为每项拒绝均独立证明 RouteView 对象、rollback point 及全部资源状态不变；该矩阵仍有证据缺口。
- 不引入 `SetAdmission`，未新增完整 Xray 配置旁路。

## 固定源码 replay 和构建

环境：Windows 主机上的 WSL2 Ubuntu 24.04.4 LTS、Linux x86_64、glibc 2.39；WSL root 执行测试监督与跨 UID socket 测试。Go 1.27.4、Zig 0.16.0；`GOPROXY=off`、`GOSUMDB=off`、`GOTOOLCHAIN=local`，使用既有离线模块缓存，未安装或下载依赖。

- 固定 Xray 版本 `v26.11.9`、来源记录的 commit `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`；归档 1,318,088 bytes，SHA-256 `3932cefef227439f569eb3988ca206b505467be075967a4397452a3ffe9ef033`。归档没有 Git 元数据，commit 与归档的对应关系依赖既有来源记录；本轮复核的是归档长度和摘要。
- replay 日志：`C:\Users\Zhn_X\.copilot\session-state\16845d49-d5b4-494a-a1cd-caa481a4004e\files\pc04-c3-committed-replay-r2.log`；SHA-256 `38086a6f6985d09119673848b3117e24db8e082a8615bbbdc8e3794f8e7b201c`。日志记录 Windows Git 预检 HEAD、父提交、跟踪文件和 index 干净；Windows Git 复跑后再次确认 HEAD 未变和跟踪工作树无差异。
- 日志按顺序记录 `0001` 至 `0012` 全部补丁检查与应用，其中 `0011` 使用 `--unidiff-zero`，包含 `0011`、`0012`；不以旧版 `0001`～`0010` 日志代替。
- 实际调用（外层 PowerShell 包装使用 Windows Git 预检并将日志写至上述文件；以下为 WSL 内执行的 replay 命令）：

```bash
cd /mnt/c/Users/Zhn_X/source/pCryoxy.wt/copilot-pc04
bash tests/integration/bridge/replay-linux.sh \
  /mnt/c/Users/Zhn_X/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/pc04-dependency-audit/xray-676eaf66.tar.gz \
  /tmp/pc04-final-c3-16845d49-20261121-r2 \
  /mnt/c/Users/Zhn_X/.agent-tools/runtimes/copilot/linux-x86_64-gnu/go-1.27.4/bin/go \
  /mnt/c/Users/Zhn_X/.agent-tools/runtimes/copilot/linux-x86_64-gnu/zig-0.16.0/zig \
  /tmp/pc04-final-c3-16845d49-20261121-r2/bridge.a \
  /mnt/c/Users/Zhn_X/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/pc04-dependency-audit/module-cache
```

replay 脚本及修正后的外层命令退出码均为 0。脚本中实际运行的普通和 race 命令为：

```bash
go test -mod=readonly -count=1 -v -run '^(TestPC04|TestRouterScriptDNSDispatcherReentry)' ./app/router ./app/dns ./common/geodata
go test -race -mod=readonly -count=1 -v -run '^(TestPC04|TestRouterScriptDNSDispatcherReentry)' ./app/router ./app/dns ./common/geodata
go test -mod=readonly -count=1 -v .
go test -race -mod=readonly -count=1 -v .
```

前两条在 replay 源码目录运行，后两条在隔离 bridge 目录运行；四条均成功，脚本启用 `set -e`，日志中四组 package 均为 `ok`。普通和 race 合计记录 38 个顶层 PASS、60 个缩进子测试 PASS，0 个 FAIL；这不是对未筛选的完整 Xray `./...` 全套测试的声明。

两次使用独立 GOCACHE/GOTMPDIR 执行 `go build -mod=readonly -trimpath -buildvcs=false -buildmode=archive`，`cmp` 成功，产物 2,987,510 bytes，SHA-256 `abfd08b1bcbec199f24e6c77ad3356ee03e985c79794586469742b879649f9c7`，与日志逐字一致；类型为 Go package archive，不是 daemon 或 Xray 可执行文件。WSL 临时目录随后不再存在；尝试将 `/tmp/pc04-final-c3-16845d49-20261121-r2/bridge.a` 复制到会话目录失败，不能声称产物仍可取得。复核日志和摘要仍保留。

失败记录：首次 PowerShell/WSL 包装因引号传递失败，退出 1；第二次因 WSL Git 无法解析 Windows worktree gitdir 退出 1，均未开始 replay。第三次 replay 脚本本体返回 0，但外层 bash 因末尾 CR 返回 2、PowerShell 命令总体退出 1，日志为同目录 `pc04-c3-committed-replay.log`。以上不能当作完整命令成功；第四次修正包装后得到上述退出 0 回执。

## 未覆盖和状态

没有真实生产调用方、生产启动绑定和逐项完整状态不变证明；未覆盖独立 daemon、systemd、TUN、真实代理互通、完整 Xray 配置与生产部署。隔离测试、race、IPC 和 archive 构建不等同完整产品验收。本提交不代表完整 Xray 生产验收；PC-04 维持 doing / blocked，请 WorkBuddy 复审并裁定后续集成责任。
