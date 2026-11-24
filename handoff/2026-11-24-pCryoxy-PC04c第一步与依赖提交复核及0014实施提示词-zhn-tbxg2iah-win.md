# pCryoxy PC-04c｜第一步与依赖提交复核 + 0014 实施提示词

项目: pCryoxy

- 审核方：workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-24 13:20 UTC+8
- 被审：分支 `agent/copilot/pc04c`
  - `99c6996f4e9e5c7bb6efef1fc4800ddba2042860`「fix: enforce default reject and fragment ranges」（8 文件 +259/-24）
  - `625029c47cf93b35fa5e1f06fcc4b0009fdce947`「build: add approved outbound dependencies」（1 文件 +7）
- 依据：v2 审核意见 `a471dd9`（§2 附条件 C1～C6、§3 H-9、§4 实施顺序）；`sys/direct` 条件性与 H-9 裁定（`4ffe608`）；固定核心 `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`；基线 `c3acc73`

## 结论

| 提交 | 结论 | 说明 |
| --- | --- | --- |
| `99c6996` | **有条件通过** | 代码本身正确，可保留。但 C4、C5 两条附条件未落实，其中 C5 涉及一处**实质安全缺口**，须在 0014 前补 |
| `625029c` | **暂不接受，需补证据** | `go.mod` 七行内容与 v2 §4 表格逐行一致，无异议；但「三平台离线构建通过」这句结论现有日志不支持 |

**允许继续推进 0014，但 C5 缺口必须先修或与 0014 同批修。** 理由见 §3。

## 一、`99c6996` 逐项核实（通过部分）

| 项 | 代码位置 | 核实结果 |
| --- | --- | --- |
| 首出站强制 `sys/reject` blackhole | `restricted_profile.go:314-317` | 正确。同时校验 tag、ProxySettings 非空、type 为 `xray.proxy.blackhole.Config` 四条件，任一不满足即 `FailedPrecondition`。与 C2「没有 fallback 时落 `sys/reject`」一致 |
| blackhole 只允许空或 `none` response | `restricted_profile.go:344-348` | 正确。逐字比对固定核心 `proxy/blackhole/blackhole.go:34-46` 的 `New()` 分支：`""`/`none` 不写响应，`http` 写 403，`custom` 写自定义字节。拒绝后两者是对的——`http` 会向未匹配流量回 403（可被用作网络探针），`custom` 可回任意内容 |
| fragment 范围校验 | `restricted_profile.go:458-475` | 正确。`lower` 取值 `lengths→1`、`delays→0` 与 `fragment/conn.go:49-61` 的 `RandBetween` 语义匹配；空数组/不等长/`min<lower`/`min>max`/`max>MaxInt32` 五类检查覆盖了 `lengthForSegment` 的 `len-1 = -1` 越界 panic 路径（`conn.go:50`）|
| 测试 | `restricted_profile_test.go:165-306` | 9 个默认拒绝用例 + 14 个 fragment 用例，含 `proto.Clone` 前后比对证明 prepare 无副作用。Linux 日志 `step1-replay-linux-r7.log:619-657` 全 PASS |
| 文档 | `tests/integration/bridge/profile.md:20,28-32` | Outbounds 行与 fragment 范围说明均已更新，与代码一致 |

`TestDefaultRejectDoesNotDialUnmatchedDestination`（`:196-250`）设计得比要求更好：不只看 blackhole 是否关闭流，还用 listener 的 `SetDeadline` 反证「未匹配流量没有到达直连目的地」，这是 C2 三种情况里最需要的那条。

## 二、`625029c` 证据不足（须补）

`go.mod` 七行本身无异议，与 v2 §4 表格逐行一致，`go.sum` 未变（`git diff c3acc73..HEAD -- go.sum` 为空）。**问题是「三平台离线构建通过」这句结论不成立**，三条独立证据：

1. **构建日志为空。** `step2-windows-build.log` 与 `step2-android-build.log` 均为 **0 字节**（sha256 都是 `e3b0c442…b855`，即空文件哈希）。Linux 那份只有 85 字节，内容是 `Linux build and dependency enumeration succeeded` 一行脚本标记，没有任何 `go build` 输出。Go 构建成功时确实静默，但另外两平台连这行标记都没有，三份日志形式不一致。
2. **依赖枚举早于提交。** `step2-*-deps.log` 的 mtime 是 11:19:24～11:21:04，`625029c` 的提交时间是 **11:21:24**。即枚举跑在 `go.mod` 落盘之前，证明不了「加完七项之后仍能解析」。
3. **七项依赖一个都没出现。** 三份 deps 日志里 `google/uuid`、`gorilla/websocket`、`quic-go/qpack`、`x/exp`、`wintun`、`zx2c4.com/wireguard` 出现次数**全部为 0**。而 `pc04c-why-*.log` 里这七项都在，说明 `go mod why` 能追到、`go list -deps` 却没列——两份产物不自洽。

**另注**：三份 `pc04c-why-*.log` 的 sha256 完全相同（`c0ea8336…e8a2`），是同一份输出复制三次，不是三平台各自运行。C6 只要求落盘与 sha256，这条形式上做到了；但报告里不能写成「三平台各自枚举」。

**补充要求**：重跑三平台 `-mod=readonly` 构建，每平台单独留存日志并给 sha256；日志里要有可核对的成功标记（如 `go build` 后的产物 sha256 或 `go list -m` 输出）。或改口径为「Linux 离线构建通过，Windows/Android 未取证」，不得写「三平台通过」。

## 三、C5 未落实 —— 实质安全缺口（最高优先）

`validateSenderSettings`（`restricted_profile.go:390-420`）只校验 `stream.GetTcpmasks()` / `GetUdpmasks()`，**完全不看 `stream.GetSocketSettings()`**。而固定核心 `transport/internet/dialer.go:270-279`：

```go
if len(sockopt.DialerProxy) > 0 {
    if obm == nil { return nil, errors.New("there is no outbound manager for dialerProxy") }
    h := obm.GetHandler(sockopt.DialerProxy)
    if h == nil { return nil, errors.New("there is no outbound handler for dialerProxy") }
    return redirect(ctx, dest, sockopt.DialerProxy, h), nil
}
```

`obm` 是**实时 ohm**，不是 RouteView。即：出站只要在 `senderSettings.socket_settings.dialer_proxy` 写一个 tag，这条连接就会被重定向到该 tag 的实时 handler，**完全绕过 RouteView 的路由决策与出站快照**。这比 C1 说的 dispatcher 层回落更隐蔽——它在 dialer 层，不经过 `outboundForDispatch`。

同一 `SocketConfig`（`transport/internet/config.proto:104-153`）里还有一批同等风险的字段：

| 字段 | 风险 |
| --- | --- |
| `dialer_proxy` | 见上，直接取实时 ohm handler |
| `domain_strategy` | 触发 `LookupForIP`（`dialer.go:254`），走 `dnsClient` 而不是 view 内 DNS |
| `address_port_strategy` | `checkAddressPortStrategy` 替换目标地址（`dialer.go:246-249`） |
| `customSockopt` | 可设任意 socket 选项，含 `SO_MARK`、`SO_BINDTODEVICE` |
| `interface` / `mark` / `tproxy` | 绑网卡、打标记、TProxy 模式 |
| `happy_eyeballs` | 并发拨号，多目标探测 |

C5 原文要求「`stream_settings.socket_settings` 只放行明确列出的字段（默认全拒，逐项论证后放行）」。**当前实现是全放行**——`knownGeoFields` 只查 protobuf unknown 字段（高位编号），这些已知字段当然通过。

**处理要求**：在 `validateSenderSettings` 里加 `stream.GetSocketSettings()` 校验，默认全拒，只放行明确论证过的字段（建议 P0 直接拒绝整块 `socket_settings` 非 nil，即 `stream.GetSocketSettings() != nil` 即拒；若确有场景需要，逐项列出并附理由）。测试至少覆盖 `dialer_proxy` 非空被拒、`customSockopt` 非空被拒、`domain_strategy` 非 `AS_IS` 被拒、`socket_settings` 为 nil 时通过。

**与 C1 的关系**：C1 要在 0014 里处理 dispatcher 层 `outboundForDispatch` 无 scope 回落；C5 处理 dialer 层 `dialer_proxy`。两条是不同入口，都要做，不能只做一条。

## 四、C4 未落实（低优先，不阻断）

C4 明确要求「加一条测试，证明 policy/stats app 仍被拒」。`restricted_profile_test.go` 全文无任何 `policy` / `stats` 相关用例，11 个测试函数里没有覆盖这条。

不过 `ValidateRestrictedProfile:91-95` 的 app 白名单只放行四个类型，其余一律 `FailedPrecondition`，逻辑上已拒绝。**需要补的是测试，不是代码**。加一条把 `xray.app.policy.Config` 或 `xray.app.stats.Config` 塞进 `config.App` 断言被拒即可，同时把 C4 那段「`policy.DefaultManager.ForSystem()` 返回零值所以不注册计数器」的推理写进交付报告。

## 五、C1～C6 落实状态

| 条件 | 状态 | 说明 |
| --- | --- | --- |
| C1 无 scope 分发回落 | **待 0014** | 属补丁范围，未开始 |
| C2 空候选与 fallback | 已覆盖 | 由 `99c6996` 首出站强制 + `bee960e` 裁定共同落实；三种情况中「无 fallback」已实测（`TestDefaultRejectDoesNotDialUnmatchedDestination`），「有 fallback」「fallback 指向缺失 tag」需 0014 补 |
| C3 Lua 路径不打补丁 | **待 0014** | 0014 目标文件清单里不得含 `app/router/lua.go` |
| C4 stats 结论 | **未落实** | 见 §四，补测试 |
| C5 sockopt 白名单 | **未落实** | 见 §三，**须先修** |
| C6 证据落盘 | 部分落实 | 已落 `~/.agent-tools/run/pc04c/logs/`；三份 why 日志同源、时间点未记录，需重取 |

## 六、下一步实施提示词（可直接发 copilot）

> **PC-04c 第三批：C5 sockopt 白名单 + C4 测试 + 0014 补丁**
>
> 已核：`99c6996` 的默认拒绝与 fragment 范围校验通过，保留。`625029c` 的 `go.mod` 七行内容无异议。
>
> **一、先修 C5（安全缺口，最高优先，单独一个提交）**
>
> `validateSenderSettings` 当前完全不校验 `stream.GetSocketSettings()`。固定核心 `transport/internet/dialer.go:270-279` 里，`sockopt.DialerProxy` 非空会走 `obm.GetHandler()` 取**实时 ohm** handler 并 `redirect`，绕过 RouteView 快照与路由决策。同块还有 `domain_strategy`、`address_port_strategy`、`customSockopt`、`interface`、`mark`、`tproxy`、`happy_eyeballs` 等字段同等风险。
>
> 要求：在 `validateSenderSettings` 中加 `socket_settings` 校验，**默认全拒**。P0 建议直接拒绝 `stream.GetSocketSettings() != nil`；若确需放行某字段，逐项列出并说明为什么不能绕过 view。测试至少：`dialer_proxy` 非空被拒、`customSockopt` 非空被拒、`domain_strategy` 非 `AS_IS` 被拒、`socket_settings` 为 nil 通过。同步更新 `profile.md`。
>
> **二、补 C4 测试（可与上一条同批）**
>
> 加一条用例：把 `xray.app.policy.Config` 或 `xray.app.stats.Config` 塞进 `config.App`，断言 `FailedPrecondition`。交付报告里写清：`ValidateRestrictedProfile:91-95` 的 app 白名单只放行四个类型，核心退回 `policy.DefaultManager`，其 `ForSystem()` 返回零值（`features/policy/default.go:25-27`），所以不会注册 `OutboundUplink`/`OutboundDownlink` 计数器，不需要为 stats 打补丁。
>
> **三、重取 `625029c` 构建证据**
>
> 现有 `step2-windows-build.log`、`step2-android-build.log` 都是 0 字节，`step2-*-deps.log` 的 mtime（11:19-11:21）早于提交时间（11:21:24），且七项依赖在三份 deps 日志里出现次数全为 0。重跑三平台 `-mod=readonly` 离线构建，逐平台单独留存日志并给 sha256，日志需含可核对标记。做不到就改口径为「仅 Linux 取证」，不得写「三平台通过」。
>
> **四、0014 补丁（新增 `upstream-patches/0014-route-view-dynamic-outbounds.patch`，不改 0001～0013）**
>
> 按 v2 §3 与 H-9 裁定（`4ffe608` §二）：
>
> 1. 出站集合加引用计数：`routeView.release()`（`0002` 补丁 `route_view.go:267-277`，现状只释放 hooks/script/dnsLife）在最后一个引用释放时恰好关闭一次集合。现有 0013 的 `release()` 完全不处理 `outbounds`，必须补齐。
> 2. 核心持有存活集合计数：**计数对象是「同时存活的不同出站集合数」（含 active），上限 8**，不是回滚点数量。出现第 9 个不同集合时返回 `ResourceExhausted`，`active` 与旧集合不变，不产生回滚点、不产生已应用回执（与 `route_control.go:61-63` 现有 `rollbackLimit` 拒绝同型）。`rollbackLimit = 64`（`operation.go:15`）不变，路由/Geo 点仍按 64 计。
> 3. 释放路径按集合粒度递减：`ReleaseRollbackPoint`（`route_control.go:113-131`）与 `Runtime.Close`（`runtime.go:185-193`）递减引用，最后引用释放才关闭；禁止 use-after-close、重复关闭、泄漏。
> 4. **C1**：无 scope 分发只允许命中 bootstrap 常驻的 `sys/reject`/`sys/direct`，其他 tag 一律失败；或证明所有生产分发路径都带 scope 并为每条写测试。二选一写进报告。
> 5. **C3**：目标文件**不含** `app/router/lua.go`。改为加一条测试，证明带 `script` 的候选仍被拒（`route_control.go:28`）。
> 6. **C2 剩余两项**：`fallbackTag` 非空时必须指向同一候选 view 内已存在的出站，否则提交失败；无 fallback 时落 `sys/reject`，不允许回落直连。三种情况（有 fallback、无 fallback、fallback 指向缺失 tag）全部实测。
>
> 验收按 `4ffe608` §2.6 七条：①8 个集合同时存活允许；②第 9 个 `ResourceExhausted` 且 active 不变；③绕过用例（建路由点→切出站→释放出站点→重复）第 9 个仍被拒；④同一集合被 64 个回滚点共享允许、集合数仍为 1；⑤8 个集合同时存在时记录 goroutine 数与内存，全部释放后回基线；⑥publish/rollback/release/Close 各路径 `-race` 无竞态无泄漏无 use-after-close；⑦失败候选不留可观察副作用，active 与旧回滚点不变。
>
> **五、约束**
>
> - `geo_reload.go` 仍不修改；确需改按 v2 §5 另行申请。
> - 清单外文件先补申请。
> - `go.sum` 不得变化。
> - 每个提交单独跑 Gitleaks 并留日志。

## 七、待人类确认

仅一项：**C5 是否允许在 0014 之前单独提交**。审核方建议允许——它是独立的安全收紧，与 0014 的引用计数无耦合，先落可以缩小 0014 的审查面。若人类希望一次提交，也可合并，但报告里要能单独指认 C5 的改动。

## 依据

- v2 审核意见 `a471dd9` §2 C1～C6、§3 H-9、§4
- `sys/direct` 条件性与 H-9 裁定（`4ffe608`）§一 §二
- 固定核心 `676eaf6`：`proxy/blackhole/blackhole.go:34-46`、`transport/internet/finalmask/fragment/conn.go:49-66`、`common/crypto/crypto.go:12-21`、`transport/internet/dialer.go:233-280`、`transport/internet/config.proto:104-153`、`app/proxyman/outbound/outbound.go:102-122`
- 桥侧：`restricted_profile.go:314-317,344-348,390-420,458-475`
- 证据：`~/.agent-tools/run/pc04c/logs/`（19 份日志，sha256 见 `step1-replay-linux-r7.log` = `a64cf476…d3ae`、`step1-windows-regression-r2.log` = `50cb7277…4a72`）
