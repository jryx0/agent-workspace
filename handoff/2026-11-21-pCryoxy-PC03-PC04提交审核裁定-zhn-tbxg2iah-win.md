# pCryoxy PC-03 / PC-04 提交审核裁定

项目: pCryoxy
审核时间: 2026-11-21（UTC+8）
审核人: WorkBuddy
审核对象:
- PC-04 implementation commit: `c3a225780f02aa7920d4183f518fcaa52595b5b9`
- PC-03 supplemental implementation commit: `c73d59d4eaddd3bfc1e47113b1ea6515010bcbeb`

前置裁定:
- PC-04 受限能力子集: `8a3030461d6c02f0e877a5c8d8cdf640884b6c37`
- PC-04 ec3af128 阶段审核: `bc0d5a9ce02e0485701b98647fc7cc5ce6f7ba9e`
- PC-03 阶段审核: `33a5b6e06c2123717f11995d5ca681a30d5845fb`
- PC-03 Windows 失败暂缓、Android 后置: `3d082b6f66c468d6a6f39b87a1b2ae50935994de`

## 一、PC-04 审核结论

结论: **受限能力子集阶段实施可接受，Geo 生命周期、固定构建、race 和 IPC 证据基本齐全；但 PC-04 仍未通过结卡验收，继续保持 `doing / blocked`。**

### 已采信证据

1. `c3a2257` 在 `ec3af128` 基础上新增显式 Geo snapshot lease / reader 生命周期管理，并新增 `Unregister`、关闭和发布后的资源释放路径。
2. 测试覆盖：
   - 旧 RouteView 仍有读者时不释放 Geo snapshot；
   - 最后读者退出后释放；
   - retained rollback point 持有和释放；
   - 候选注销、关闭、发布后的 lease 转移；
   - 连续 Geo 切换、中间 rollback point 释放和跨版本回滚。
3. 交接回执提供固定 Xray 源码 commit `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`、源码归档 SHA-256、0001 至 0012 补丁顺序、Go 1.27.4、Zig 0.16.0、离线模块缓存和 replay 命令。
4. 交接回执报告普通测试、`go test -race`、真实文件系统 Unix socket、跨 UID、peer UID、ticket、prepare 拒绝和 operation 淘汰测试均退出码 0。
5. 交接回执报告独立 GOCACHE/GOTMPDIR 双构建及 `cmp` 一致，产物为 Linux amd64 Go package archive。
6. profile 明确拒绝 sniffing、未纳管 DNS、proxy/dns、freedom、finalmask、独立 Geo cron、未知字段和未绑定同一 RouteView/epoch 的消费者；不引入 `SetAdmission`。

### 仍保留的范围边界

- 不宣称完整 Xray 配置验收。
- 不宣称独立 daemon、systemd、TUN、真实代理接管、SOCKS/HTTP 互通或生产部署通过。
- Go package archive 不等于最终 Xray/daemon 可执行文件。
- 工作树中的未跟踪 `tests/integration/bridge/pc04-linux-amd64.a` 不属于本提交，不影响本次审核，但不得作为交付物引用。
- 本次审核采信绑定 handoff 的实际回执并完成代码范围核对；未在当前审核环境重新执行完整 replay，因此若后续要求独立复跑，应以该 implementation commit 和固定源码摘要复跑。

### 状态裁定

PC-04 可按“受限能力子集阶段实施可接受、待补齐结卡证据”处理，继续保持 `doing / blocked`。不得扩大为完整 Xray 产品完成，不授权因本裁定自动合并或部署。

## 二、PC-03 审核结论

结论: **Linux 补充证据可接受；PC-03 当前有条件通过并解除本阶段 Linux 证据阻塞，但不标记最终 done。**

### 已采信证据

1. `c73d59d` 只修改 `crates/secure-store/src/linux_tests.rs`，范围集中，没有修改 PC-02、PC-04、公共 `SecretStore` trait、proto、公共锁文件或依赖。
2. Linux WSL2 Ubuntu 24.04.4 / x86_64 实测使用临时服务 UID 25003 和拒绝 UID 25004，未创建持久账户或修改系统配置。
3. 回执报告：服务 UID 主测试集 4 passed、0 failed；fixture、服务 UID 重启读取和异 UID拒绝分别通过；总计 7 项实测通过、0 项失败。
4. 回执报告目录为 `0700`、master key 和 vault 文件为 `0600`，属主为服务 UID；服务 UID 重启后可读取，异 UID 打开返回 `PermissionDenied`；测试目录和临时 UID 已清理。
5. 本次提交未伪造 Windows 或 Android 结果，并明确 Android 真机仍未执行。

### 仍保留的条件

- Windows 历史 `6 passed、8 failed、2 ignored` 缺少逐项日志，当前不能确认可重现；依据用户裁定，按“暂缓核查／条件接受”处理，不写成 8 项已通过。
- Android 真机按 `3d082b6` 后置，源码存在或 `adb` 空设备不算平台通过；待用户准备设备后另开专项测试和复审。
- Windows Service 身份、服务 SID/ACL、服务重启和异账户拒绝尚未形成新的实测回执；若后续取得获准 runner，再单独补测。
- `c73d59d` 是 Linux 补充实施提交，不是三平台完整验收提交。

### 状态裁定

PC-03 当前按“有条件通过、继续实施”处理，仍不标记最终 `done`，不授权因本裁定自动合并或部署。Android 真机专项任务由用户准备好后另行发起。

## 三、联合裁定

- PC-04：受限能力子集阶段验收通过；完整 Xray 生产、daemon、systemd、TUN 和真实代理互通不在本裁定范围内。
- PC-03：Linux 补充证据通过；Windows 历史失败暂缓核查，Android 后置；不代表三平台完整验收。
- 两个实施提交均未因本裁定自动合并或部署。
- 本记录为审核裁定记录，不是实施代码提交。
