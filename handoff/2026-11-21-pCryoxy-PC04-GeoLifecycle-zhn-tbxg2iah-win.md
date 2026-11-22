# pCryoxy PC-04 Geo 生命周期实施交接

项目: pCryoxy  
卡号: PC-04  
版本: 任务卡 v1.1  
当前状态: 交付待审核（doing / blocked；本记录不代表结卡通过）  
输入代码基线: `ec3af128c039170800fb046e25a20200f2ce5aca`  
前置裁定: `8a3030461d6c02f0e877a5c8d8cdf640884b6c37`、`bc0d5a9ce02e0485701b98647fc7cc5ce6f7ba9e`

## 提交与现场

- Worktree: `C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc04`
- Branch: `agent/copilot/pc04`
- Implementation commit: `c3a225780f02aa7920d4183f518fcaa52595b5b9`
- 未 push、未合并、未部署；PC-04 保持 doing / blocked。
- 实施提交相对输入基线只改 PC-04 文件；未修改 PC-02 proto、descriptor、生成物或 `contracts/core-lock.json`，未引入 `SetAdmission`。
- 原有未跟踪文件 `tests/integration/bridge/pc04-linux-amd64.a` 未修改、未暂存、未提交。

## 变更文件

- `native/xray-bridge/geo_reload.go`
- `native/xray-bridge/geo_lifecycle_internal_test.go`
- `tests/integration/bridge/profile.md`
- `tests/integration/bridge/replay-linux.sh`
- `tests/integration/bridge/route_view_test.go`
- `upstream-patches/0011-explicit-geo-snapshot-release.patch`
- `upstream-patches/0012-geo-snapshot-reader-lifecycle-test.patch`

## Geo 生命周期与 prepare 证据

- frozen Geo snapshot 现在显式跟踪 owner/RouteView lease 和打开的 asset reader。最后一个 lease 与 reader 退出后会清空 snapshot asset map 并关闭 release signal；关闭的 reader 清除其底层 byte slice。该回收不依赖 `runtime.GC`、finalizer 或对象不可达。
- RouteView 继承、替换、关闭时分别 acquire/release Geo lease；DNS/script view 与 RouteView 生命周期一致。注册候选的 Unregister、Close 和成功发布后的所有权转移均有释放处理。
- 普通与 `-race` 测试覆盖 reader 延迟释放、并发旧 RouteView 读者退出、rollback point 持有与释放、候选注销/关闭、发布后 lease 转移及资产目录删除后的旧视图读取。
- 固定核心 RPC 集成测试覆盖连续 Geo 切换（before → after → third → fourth）、中间 rollback point 释放、跨版本 rollback、stale epoch/revision 和失败发布。受限 profile 对 sniffing、未纳管 DNS、`proxy/dns`、`freedom`、finalmask、Geo cron、未知字段/扩展等拒绝。拒绝后检查 epoch、revision、Geo version 和规则不变；随后可成功使用此前保留的 rollback point。
- 测试证据是受限配置与隔离固定核心测试，不是完整 Xray 配置或完整生产实例验收。

## IPC 与操作边界证据

- 环境：WSL2 Ubuntu-24.04，Linux x86_64，`/tmp`；测试以 UID 0 启动服务，用现有 `setpriv` 以 UID 65534（nobody）执行未授权访问，不安装工具、不改系统配置。
- 使用真实文件系统 Unix socket：私有目录权限 `0700`、socket 权限 `0600`；不同 UID 的 socket 连接被文件权限拒绝。服务端通过 `SO_PEERCRED` 读取 peer UID。
- RPC 测试分别验证 peer UID 不匹配、无 ticket、错误 ticket 被拒，以及匹配 UID + 随机测试 ticket 成功。生产调用方仍须显式验证管理客户端 UID 与 ticket。
- Operation 测试覆盖 payload 冲突、stale epoch、revision 冲突、提交后响应丢失重试，以及 300 条操作填充后的 256 条 FIFO 淘汰窗口；淘汰后旧请求为 `UNKNOWN`，重试按 expected epoch 语义失败。幂等不承诺无限期。

## 固定源码、命令与测试结果

- Xray: `v26.11.9`，commit `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`
- 源码归档: `pc04-dependency-audit/xray-676eaf66.tar.gz`，1,318,088 bytes，SHA-256 `3932cefef227439f569eb3988ca206b505467be075967a4397452a3ffe9ef033`。
- 工具：Go `1.27.4 linux/amd64`、Zig `0.16.0`；使用已有 session-local 离线 module cache。`GOPROXY=off`、`GOSUMDB=off`、`GOTOOLCHAIN=local`；`go.sum` 与提交清单比较一致，未新增依赖。
- 完整 replay 命令（全部成功，最终退出码 0）：

```powershell
wsl.exe -u root bash -lc "set -o pipefail; mkdir -m 700 /tmp/pc04-explicit-geo-r5; cd /mnt/c/Users/Zhn_X/source/pCryoxy.wt/copilot-pc04; bash tests/integration/bridge/replay-linux.sh /mnt/c/Users/Zhn_X/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/pc04-dependency-audit/xray-676eaf66.tar.gz /tmp/pc04-explicit-geo-r5 /mnt/c/Users/Zhn_X/.agent-tools/runtimes/copilot/linux-x86_64-gnu/go-1.27.4/bin/go /mnt/c/Users/Zhn_X/.agent-tools/runtimes/copilot/linux-x86_64-gnu/zig-0.16.0/zig /tmp/pc04-explicit-geo-r5.a /mnt/c/Users/Zhn_X/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/pc04-dependency-audit/module-cache 2>&1 | tee /mnt/c/Users/Zhn_X/.copilot/session-state/d67ae345-7a2d-4360-8c1f-7f2865e75e9d/files/pc04-final-replay-r5.log"
```

- Replay 顺序为 `upstream-patches/0001` 至 `0012`；固定源码先验大小与 SHA-256。`0011` 是针对该固定源码和前置补丁序列生成的零上下文差异，脚本只对该补丁使用 `git apply --unidiff-zero --check` 后应用。
- 普通测试命令退出码均为 0：
  - `go test -mod=readonly -count=1 -v -run '^(TestPC04|TestRouterScriptDNSDispatcherReentry)' ./app/router ./app/dns ./common/geodata`
  - `go test -mod=readonly -count=1 -v .`（bridge）
- Race 测试命令退出码均为 0：
  - `go test -race -mod=readonly -count=1 -v -run '^(TestPC04|TestRouterScriptDNSDispatcherReentry)' ./app/router ./app/dns ./common/geodata`
  - `go test -race -mod=readonly -count=1 -v .`（bridge）
- 真实文件 socket、跨 UID、ticket、Geo lifecycle、prepare 拒绝和 operation 测试均在上述实际测试运行中通过；这些不是生产部署或真实代理互通证据。
- 双构建命令均退出码 0，独立 `GOCACHE` / `GOTMPDIR`，`cmp first.a second.a` 退出码 0。产物 `/tmp/pc04-explicit-geo-r5.a`：2,987,510 bytes，SHA-256 `abfd08b1bcbec199f24e6c77ad3356ee03e985c79794586469742b879649f9c7`，`file` 类型为 `current ar archive`。
- 本次构建是 Linux amd64 Go package archive，不是独立 Xray/daemon 可执行文件；未声称 systemd、TUN、代理接管或完整运行时通过。
- `git diff --cached --check` 退出码 0；Gitleaks 8.30.1 对整个 PC-04 worktree 扫描约 1.23 MB，退出码 0，未发现 secret。

## 未覆盖与复审

- 未完成完整 Xray 生产配置验收、独立 daemon 运行、生产 service 身份/部署、systemd、TUN/路由、真实网络代理互通，以及 Windows/Android 运行测试。
- 本提交不代表 PC-04 结卡通过，也不代表完整 Xray 生产验收。
- 请求 WorkBuddy 复审 implementation commit `c3a225780f02aa7920d4183f518fcaa52595b5b9` 与上述绑定证据。审核前不改状态为 done，不推进其他卡片。
