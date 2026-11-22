# pCryoxy PC-04 实施交接

项目: pCryoxy  
卡号: PC-04  
版本: 任务卡 v1.1  
当前状态: 交付待审核（doing / blocked；本记录不代表结卡通过）  
输入基座: `1e18654ca2a60e8f76c114c891648037d155c336`  
前置裁定: `8a3030461d6c02f0e877a5c8d8cdf640884b6c37`、`93bd249f39e785db67ad94950a9a6eef854270e1`

## 提交与现场

- Worktree: `C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc04`
- Branch: `agent/copilot/pc04`
- 实施提交：`97e04e205c6a8b302102234553cf8ec3a026b547`
- Geo 回收补充提交：`ec3af128c039170800fb046e25a20200f2ce5aca`
- 本卡最终提交 SHA: `ec3af128c039170800fb046e25a20200f2ce5aca`
- 未 push、未合并、未部署；未修改 PC-02 proto、descriptor、生成输入或 `contracts/core-lock.json`。
- 提交后仅保留原工作树中的未跟踪文件 `tests/integration/bridge/pc04-linux-amd64.a`；未覆盖、暂存或提交该归档。

## 变更文件

- `native/xray-bridge/`: `core_control.pb.go`、`core_control_grpc.pb.go`、`geo_reload.go`、`go.mod`、`go.sum`、`ipc_unix_linux.go`、`operation.go`、`route_control.go`、`runtime.go`、`snapshot.go`
- `upstream-patches/`: `0001-router-reject-unsupported-hot-config.patch`、`0002-router-versioned-route-view.patch`、`0003-normalize-route-update-entries.patch`、`0004-router-pin-lua-geo-view.patch`、`0005-router-retained-control-snapshots.patch`、`0006-dns-inject-geo-candidate.patch`、`0007-router-official-epoch-check.patch`、`0008-pin-dns-dispatch-route-view.patch`、`0009-verified-scoped-geo-publication.patch`、`0010-bind-standalone-dns-to-route-view.patch`
- `tests/integration/bridge/`: `control_ipc_test.go`、`dns_geo_candidate_test.go`、`dns_route_epoch_test.go`、`entry_normalization_test.go`、`hot_config_test.go`、`lua_geo_view_test.go`、`profile.md`、`replay-linux.sh`、`route_view_test.go`
- 未引入 `SetAdmission`；未修改公共 API/DTO/协议文件。

## 受限 profile 与拒绝证据

profile 只接受一个 router、DNS、dispatcher、outbound-manager 配置；不接受 inbound/outbound、extension、未知 protobuf 字段、sniffing、`proxy/dns`、`freedom`、finalmask、独立 Geo cron、未纳管 DNS consumer 或不支持的 DNS 后端。官方 AddRule 依既定 proto3 默认值语义规范化；ReplaceRoutes 解释为完整 desired configuration。两者先生成完整候选 RouteView，再由同一 prepare/publish 路径提交。

Linux 集成测试覆盖上述拒绝矩阵及错误码，并核验拒绝后 epoch、revision、Geo version 和活动规则不变；未支持的配置在注册 gRPC 服务或启动核心前拒绝。单次路由选择使用一个不可变 RouteView；Geo、override、DNS 视图绑定同一快照。

Geo 证据：从 `before` 连续切换到 `after`、`third`、`fourth`，释放中间 rollback point，再跨版本回滚到 `before`；错误摘要、未注册 handle、stale epoch/revision 均拒绝且不发布。新增 `RegisteredGeo.Unregister` 在 registry 锁内释放未发布候选槽位；未注册/已发布 ID 保持单次使用。最终 RouteView 释放后，GC finalizer 测试确认旧 Geo snapshot 可回收；活动/保留视图仍引用时不回收。

操作幂等范围：表上限 256 个 ID（含运行中的请求）；完成项在需要腾槽时 FIFO 淘汰；全为运行中时返回 `ResourceExhausted`。淘汰前缺失 ID 为 `NOT_SEEN`，发生淘汰后缺失 ID 为 `UNKNOWN`。窗口内重试返回缓存回执。测试注入“服务端提交后抑制响应”，随后 QueryOperation 与同 ID 重试得到已提交回执；窗口淘汰后旧 ReplaceRoutes 重试因 expected epoch 过期而 `Aborted`。不宣称无限期幂等；官方兼容入口没有 expected-epoch 字段，UNKNOWN 后客户端必须先 reconcile，不能盲目复用旧 ID。

## IPC 证据

- 环境：WSL2 Ubuntu-24.04，Linux x86_64，`/tmp` 类型 `ext2/ext3`，glibc 2.39；测试以 UID 0 启动服务，并用 `setpriv` 以 UID 65534（nobody）运行异 UID 客户端。
- 真实文件系统 Unix socket：私有目录由服务 UID 持有且为 `0700`，socket 为 `0600`；非授权 UID 对 socket 的实际连接因文件权限拒绝。
- 服务端 gRPC 使用 `SO_PEERCRED` 提取 UID。测试分别验证 UID 不匹配、无 ticket、错误 ticket 被拒，以及匹配 UID + 随机测试 ticket 成功。
- `profile.md` 明确生产调用方必须验证 management UID 与 ticket；socket mode 单独不构成授权。
- WSL 普通用户的 `sudo -n -u nobody` 不可用（要求密码）；未改系统配置，改为使用现有 WSL root 执行器和 `setpriv`，最终跨 UID 测试通过。

## 固定源码、工具链与构建

- Xray: `v26.11.9`，commit `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`
- 固定源码归档 SHA-256: `3932cefef227439f569eb3988ca206b505467be075967a4397452a3ffe9ef033`（1,318,088 bytes）
- Linux 工具：Go `1.27.4 linux/amd64`；Zig `0.16.0`；使用已存在的 session-local 离线 module cache。
- 执行脚本：`bash tests/integration/bridge/replay-linux.sh <fixed-source-tar> <session-scratch> <go-bin> <zig-bin> <artifact-output> <offline-module-cache>`；最终运行时 UID 0，脚本退出码 0，完整 `set -x` 日志保存在 `C:\Users\Zhn_X\.copilot\session-state\16845d49-d5b4-494a-a1cd-caa481a4004e\files\pc04-delivery-replay-7.log`。
- 脚本校验源码包大小/摘要，按 `0001` 至 `0010` 顺序逐个 `git apply --check` 并应用补丁；`GOPROXY=off`、`GOSUMDB=off`、`GOTOOLCHAIN=local`。`cmp go.sum` 成功，未增加模块或版本；`golang.org/x/sys v0.49.0` 原已在依赖闭包中，仅由 indirect 调整为直接依赖。
- 普通测试及 race 测试均退出 0：
  - `go test -mod=readonly -count=1 -v -run '^(TestPC04|TestRouterScriptDNSDispatcherReentry)' ./app/router ./app/dns`
  - 同上加 `-race`
  - `go test -mod=readonly -count=1 -v .`（bridge）
  - 同上加 `-race`（bridge）
  - 共 15 个顶层测试，在普通/race 两种模式各运行一次；另含 profile 拒绝子测试。最终四条 go test 命令均返回 0。
- 双构建使用独立 GOCACHE/GOTMPDIR：
  - `go build -mod=readonly -trimpath -buildvcs=false -buildmode=archive -o first.a .`
  - 同命令输出 `second.a`；`cmp first.a second.a` 返回 0。
  - Linux amd64 bridge archive: `/tmp/pc04-delivery.E1QHiv/pc04-linux-amd64.a`，2,980,680 bytes，SHA-256 `864773578ce68295a0db7a5e7bd1c8ce126078c2a6af380016850490b73e2e93`；`file` 报告 `current ar archive`。
- 本次构建产物是 Go package archive，不是独立 Xray/daemon 可执行文件；因此 `ldd`/`readelf` 动态依赖核验不适用，也未声称 systemd、TUN、路由接管、SOCKS/HTTP 或真实代理互通通过。

  ## 兼容性握手记录

  - `platform=linux`；`arch=amd64`；`libc=glibc 2.39`
  - `coreVersion=v26.11.9`；`coreCommit=676eaf66f8f05d4d558ee7a74b4736623d3feeb9`
  - `bridgeVersion=0.0.1`；`bridgeCommit=ec3af128c039170800fb046e25a20200f2ce5aca`
  - `artifactSHA256=864773578ce68295a0db7a5e7bd1c8ce126078c2a6af380016850490b73e2e93`
  - `apiProtocol=PC-02 API Spec v1.2`；当前 QueryState schema 没有独立的协议版本协商字段，不宣称运行时已完成版本握手。
  - `supportStatus=restricted-profile-tested; platform-not-fully-supported`。只记录本轮受限管理/路由 profile 测试，不表示 Linux 产品运行、服务、TUN 或代理能力整体受支持。

补丁 SHA-256（顺序与 replay 一致）：

```text
0001-router-reject-unsupported-hot-config.patch af22e253a378615a662eed85b0c6e3ade8345af8aed77d558272d54dfa426efc
0002-router-versioned-route-view.patch          650344a635d55b254f6dae212ce1ec466f71678b49b7ac2e4ee3970199e3c2c0
0003-normalize-route-update-entries.patch       9adf0ea0243bce0cdd9090455fe97b72fe33d82bfb8b5e7d469b26bf2c2eee25
0004-router-pin-lua-geo-view.patch              2ee5f2524c4b530a44a89b035dd9340343ea1c963026c1ef2bd86041c233ad72
0005-router-retained-control-snapshots.patch    c58771dc4170bfe60772a84e27446ff36c446804becb37af426d958818b9dd4e
0006-dns-inject-geo-candidate.patch             b31440fbbd3c9598fb729c7222eeacdbcab2dfa6fd470dafd23683ba3b5c9d52
0007-router-official-epoch-check.patch          98a3d2f538d650fc338f1ed6addf7632ad147d44d13db131142ac02937347afd
0008-pin-dns-dispatch-route-view.patch          891d70932206418d25da7e5e0ccc8818eed06c05485c252e52779b644f9920ee
0009-verified-scoped-geo-publication.patch      948d872ffc420f366f487b67fb0f621f7a7c6d190809453c98133b7f80d11baa
0010-bind-standalone-dns-to-route-view.patch    a6cea0862de664f20646e26a904fa6d4e303ee9699c0b3642ce0512482bf08cb
```

## 检查、失败迭代与未覆盖

- Gitleaks 8.30.1：扫描约 1.22 MB，exit 0，`no leaks found`。
- 源码、测试和说明文件的 staged `git diff --check` 通过。完整默认 `git diff --check` 对 `upstream-patches/*.patch` 的 unified-diff 空白上下文标记报告 trailing-space / space-before-tab；这些是补丁容器格式，不是重放后源码。所有补丁均逐项 `git apply --check` 成功；忽略 patch 容器上下文空白后检查 exit 0。
- 迭代失败如实记录：最初 replay 缺少 scratch 子目录；随后未提权测试因 sudo 密码要求在跨 UID 断言失败；另一次构建因未预建 `scratch-first/second` 失败；加入响应丢失测试后发现一个断言仍使用旧 epoch。均修复后以最终源码重跑，最终 replay 退出码 0。
- 未覆盖：独立 Xray daemon 可执行文件与运行时动态依赖；生产 service 身份/部署、systemd、TUN、真实网络代理互通及完整 Xray 配置验收。
- 本提交不代表 PC-04 结卡通过，也不代表完整 Xray 生产验收。请求 WorkBuddy 对上述实施提交和证据复审；审核前保持 doing / blocked，不推进 PC-03/PC-04 之外卡片。
