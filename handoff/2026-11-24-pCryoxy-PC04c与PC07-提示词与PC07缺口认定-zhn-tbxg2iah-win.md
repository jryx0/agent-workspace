# pCryoxy PC-04c / PC-07 提示词与 PC-07 缺口认定

日期：2026-11-24 14:05 UTC+8　裁定方：workbuddy@zhn-tbxg2iah-win~zhn-x-w
状态：**人类已批准 C5 先于 0014 单独提交（13:59「允许在 0014 之前单独提交」）**
项目：pCryoxy　固定核心：676eaf66f8f05d4d558ee7a74b4736623d3feeb9　基线：`c3acc73`

## 0. 本次裁定

| # | 事项 | 结论 |
|---|---|---|
| A-1 | PC-04c 的 C5（sockopt 白名单） | **允许单独提交，排在 0014 之前**。人类 13:59 明确批准。理由：独立安全收紧，与引用计数无耦合，先落可缩小 0014 审查面 |
| A-2 | PC-07 支持矩阵文档 | **认定为缺口**：全仓 `grep "待 PC-04c\|待接口\|核心直跑预验\|无输入入口"` 零命中，裁定 §6 的六种标注没有任何一处落到仓库 |
| A-3 | PC-07 互通夹具 | **认定为缺口**：全仓无任何本地受控服务端（`grep TcpListener\|listen(` 在非 test 代码零命中，test 代码也无），「实际连接」栏无法取证 |
| A-4 | PC-07 分支推送 | 远端无 `agent/copilot/pc07`，`git ls-remote origin` 无匹配。5 个提交只在本地 |

## 一、PC-04c 提示词

> **PC-04c 第三批：C5 sockopt 白名单（单独提交）→ C4 测试 → 重取构建证据 → 0014 补丁**
>
> 已核：`99c6996` 的默认拒绝与 fragment 范围校验通过，保留。`625029c` 的 `go.mod` 七行内容与 v2 §4 逐行一致，无异议。人类已批准 C5 先于 0014 单独提交。
>
> ### 第一步（独立提交，不得与 0014 混合）
>
> **C5：`socket_settings` 默认全拒**
>
> 现状：`validateSenderSettings`（`restricted_profile.go:390-420`）只遍历 `stream.GetTcpmasks()` 与 `GetUdpmasks()`，**完全不读取 `stream.GetSocketSettings()`**。`knownGeoFields` 只检查 protobuf unknown 字段（高位编号），已知字段自然全部通过。
>
> 这是实质安全缺口。固定核心 `transport/internet/dialer.go:270-279`：
>
> ```go
> if len(sockopt.DialerProxy) > 0 {
>     h := obm.GetHandler(sockopt.DialerProxy)   // obm 是实时 ohm，不是 RouteView 快照
>     return redirect(ctx, dest, sockopt.DialerProxy, h), nil
> }
> ```
>
> 出站只要在 `senderSettings.socket_settings.dialer_proxy` 写一个 tag，该连接就被 `redirect` 到实时 handler，**绕过 RouteView 的路由决策与出站快照**。发生在 **dialer 层**，不经过 `dispatcher` 的 `outboundForDispatch`（即 C1 覆盖的位置），C1 修了也管不到这里。
>
> 同块 `SocketConfig`（固定核心 `transport/internet/config.proto:104-153`）同等风险字段：
>
> | 字段 | 风险 |
> |---|---|
> | `dialer_proxy` | 取实时 ohm handler 并 redirect，绕过 view |
> | `domain_strategy` | 触发 `LookupForIP`（`dialer.go:254`），走全局 `dnsClient` 而非 view 内 DNS |
> | `address_port_strategy` | `checkAddressPortStrategy` 替换目标地址（`dialer.go:246-249`） |
> | `customSockopt` | 任意 socket 选项，含 `SO_MARK`、`SO_BINDTODEVICE` |
> | `interface` / `mark` / `tproxy` / `penetrate` | 绑网卡、打标记、TProxy 模式 |
> | `happy_eyeballs` | 并发拨号，多目标探测 |
>
> **要求**：在 `validateSenderSettings` 中读取 `stream.GetSocketSettings()`，**默认全拒**。P0 建议直接拒绝 `stream.GetSocketSettings() != nil`（即任何非 nil 的 socketSettings 一律 `FailedPrecondition`）。若确需放行某字段，逐项列出并论证为什么不能绕过 view，列表写进交付报告。按 C5 原文要求「默认全拒，逐项论证后放行」，不接受「黑名单列举危险字段」的做法。
>
> **测试至少覆盖**：①`dialer_proxy` 非空被拒；②`customSockopt` 非空被拒；③`domain_strategy` 非 `AS_IS` 被拒；④`mark` 非 0 被拒；⑤`socket_settings` 为 nil 时通过（回归，确保没误伤现有配置）；⑥`SenderSettings` 为 nil 时通过。用 `proto.Clone` 前后比对证明 prepare 无副作用（与既有测试同型）。
>
> 同步更新 `tests/integration/bridge/profile.md` 的 Outbounds / Outbound FinalMask 附近，写明 socketSettings 默认拒绝。
>
> **交付**：单独一个提交，只含 C5 相关文件与测试；报告里单独指认 C5 的改动行范围。
>
> ### 第二步（可与 C5 同批或紧随）
>
> **C4：补 policy/stats 拒绝测试**
>
> `restricted_profile_test.go` 现有 11 个测试函数无一涉及 policy/stats。逻辑上 `ValidateRestrictedProfile:91-95` 的 app 白名单只放行 router/dns/dispatcher/proxyman.OutboundConfig，其余一律 `FailedPrecondition`，**已拒绝，不需改代码**。
>
> 要求：加用例把 `xray.app.policy.Config` 或 `xray.app.stats.Config` 塞进 `config.App`，断言 `FailedPrecondition`。交付报告写明推理链：白名单只放行四类 → 核心退回 `policy.DefaultManager` → 其 `ForSystem()` 返回零值（固定核心 `features/policy/default.go:25-27`）→ `outbound/handler.go:30-50` 的 `Stats.OutboundUplink/Downlink` 为假 → 不注册计数器 → 不需要为 stats 打补丁。
>
> ### 第三步
>
> **重取 `625029c` 的构建证据**
>
> 现有证据不支持「三平台离线构建通过」：
>
> 1. `step2-windows-build.log`、`step2-android-build.log` 均 **0 字节**（sha256 同为 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`，即空文件）；`step2-linux-build.log` 仅 85 字节脚本标记，无 `go build` 输出。
> 2. `step2-*-deps.log` 的 mtime 为 11:19:24～11:21:04，`625029c` 提交时间是 **11:21:24**，枚举跑在 `go.mod` 落盘之前。
> 3. 七项依赖在三份 deps 日志出现次数**全部为 0**（`google/uuid`、`gorilla/websocket`、`quic-go/qpack`、`x/exp`、`wintun`、`zx2c4.com/wireguard` 逐项核对）；而 `pc04c-why-*.log` 里七项都在，两份产物不自洽。
> 4. 三份 `pc04c-why-*.log` 的 sha256 全同（`c0ea8336cbbd5f53628bd14500b836a0e56ad3ee88f7855ef2d9c015bdd8e8a2`），是同一份输出复制三次，报告里不得写成「三平台各自枚举」。
>
> 要求：重跑三平台 `-mod=readonly` 离线构建，**逐平台单独**留存日志并给 sha256；日志含可核对标记（产物 sha256 或 `go list -m all` 相关行）。做不到就改口径为「仅 Linux 取证，Windows/Android 未取证」，不得写「三平台通过」。
>
> 注意：直接 `go build -mod=readonly ./...` 会因 `go.sum` 无 `xray-core` 条目失败，但 `git show c3acc73:native/xray-bridge/go.sum | grep -c "xtls/xray-core"` 为 0——**基线就没有该条目，属既有状态**，须走 `tests/integration/bridge/replay-linux.sh`（它用 `go mod edit -replace` 指向打完补丁的源码）。报告里要说清用了哪条路径验证。
>
> ### 第四步
>
> **0014 补丁**：新增 `upstream-patches/0014-route-view-dynamic-outbounds.patch`，不改 0001～0013。
>
> 1. **出站集合引用计数**：`routeView.release()`（`0002` 补丁 `route_view.go:267-277`，现状只释放 hooks/script/dnsLife）在最后一个引用释放时**恰好关闭一次**集合。现有 0013 的 `release()` 完全不处理 `outbounds`（`newRouteView` 用 `v.outbounds, v.defaultOutbound = base.outbounds, base.defaultOutbound` 直接赋 map 引用），必须补齐。
> 2. **核心持有存活集合计数**：计数对象是「**同时存活的不同出站集合数**（含 active）」，上限 **8**。出现第 9 个不同集合时返回 `ResourceExhausted`，`active` 与旧集合不变，**不产生回滚点、不产生已应用回执**（与 `route_control.go:61-63` 现有 `rollbackLimit` 拒绝同型）。`rollbackLimit = 64`（`operation.go:15`）不变。
> 3. **释放按集合粒度递减**：`ReleaseRollbackPoint`（`route_control.go:113-131`）与 `Runtime.Close`（`runtime.go:185-193`）递减引用，最后引用释放才关闭；禁止 use-after-close、重复关闭、泄漏。
> 4. **C1**：无 scope 分发只允许命中 bootstrap 常驻的 `sys/reject`/`sys/direct`，其他 tag 一律失败；或证明所有生产分发路径（入站、DNS 出站、sniffing 后重分发、内部探测）都带 scope 并为每条写测试。二选一写进报告。
> 5. **C3**：目标文件**不含** `app/router/lua.go`。改为加一条测试，证明带 `script` 的候选仍被拒（`route_control.go:28`）。
> 6. **C2 剩余两项**：`fallbackTag` 非空时必须指向同一候选 view 内已存在的出站，否则提交失败；无 fallback 时落 `sys/reject`，不允许回落直连。三种情况（有 fallback、无 fallback、fallback 指向缺失 tag）全部实测。**注意**：PC-07 裁定（`bee960e` §1.5）要求桥侧 `validateProfileRoutes` 要求所有 `balancingRule` 的 `fallbackTag` 为空——带 fallbackTag 的候选能过桥校验、到核心即启动失败，会形成「桥通过、核心起不来」的假通过。这条要一并落实。
>
> **验收按 `4ffe608` §2.6 七条**：①8 个集合同时存活允许；②第 9 个 `ResourceExhausted` 且 active 不变；③绕过用例（建路由点→切出站→释放出站点→重复）第 9 个仍被拒；④同一集合被 64 个回滚点共享允许、集合数仍为 1；⑤8 个集合同时存在时记录 goroutine 数与内存，全部释放后回基线；⑥publish/rollback/release/Close 各路径 `-race` 无竞态无泄漏无 use-after-close；⑦失败候选不留可观察副作用（stats/handler/goroutine），active 与旧回滚点不变。
>
> ### 第五步（可与第四步并行）
>
> **RPC 与 proto 契约**：按 v2 §5 改 `core_control.proto` 与生成文件、`proto.lock`、`descriptor.pb`，实现 `ReplaceRoutingAndOutbounds`。现有 6 个 RPC 字段编号不变。
>
> ### 约束
>
> - `geo_reload.go` 仍不修改；确需改按 v2 §5 另行申请。
> - 清单外文件先补申请。
> - `go.sum` 不得变化。
> - 每个提交单独跑 Gitleaks 留日志。
> - `crates/secure-store/target/` 未跟踪目录：建议在根 `.gitignore` 加 `**/target/`，单独一个 chore 提交，不混进功能提交。

## 二、PC-07 提示词

> **PC-07 第二批：支持矩阵落库 + 互通夹具 + 分支推送**
>
> 已核：`aa7e7bc` 的 fallbackTag 修正通过（7 项测试已落实：空池落 `sys/reject`、Failover/LowestLatency 单候选、单节点合成、全 balancer 断言 `fallbackTag == ""`、`state = Isolated` 仍保留直引出站）。`hysteria2_none_security_is_rejected`、`hysteria2_reality_security_is_rejected` 已补，Hysteria2 TLS 缺口已闭合。
>
> **PC-07 结卡仍依赖 PC-04c done**，本轮不结卡。以下三项都不依赖 PC-04c，先做。
>
> ### 一、支持矩阵落库（缺口，优先）
>
> 现状：全仓 `grep "待 PC-04c\|待接口\|核心直跑预验\|无输入入口"` 零命中，裁定 §6 定义的六种标注**没有任何一处落进仓库**。任务卡 v1.3 §2 明确要求「矩阵按裁定 §6 标注」。
>
> 要求：在 `crates/plugin-xray/` 或 `docs/` 下建一份矩阵文档（建议 `docs/pc07-支持矩阵.md` 或 `crates/plugin-xray/MATRIX.md`），按**协议 × 传输 × 安全选项**三维逐格填，每格用 §6 六种标注之一：
>
> | 标注 | 含义 |
> |---|---|
> | 通过 | 这一栏有本卡取证 |
> | 待接口 | 等 IR 契约变更获批并实施 |
> | 待 PC-04c | 桥 prepare、经桥的实际连接 |
> | 核心直跑预验 | 只作参考，不算验收证据 |
> | 未通过／缺夹具 | 没有本地受控服务端夹具 |
> | 无输入入口 | IR 能表达，但没有有依据的解析或录入入口 |
>
> 必须覆盖的协议：vless（含 Vision、VLESS Encryption）、vmess、trojan、shadowsocks（含 2022）、hysteria2、wireguard、masque。
> 必须覆盖的传输：raw、xhttp、ws、httpupgrade、grpc。
> 必须覆盖的安全：none、tls、reality（按协议实际支持情况）。
>
> 每格写清：该组合当前落在哪个标注、依据是什么（哪些测试/日志）、缺什么。**不允许空格，不允许全部标「待 PC-04c」蒙混**——`config.rs` 已有实现的组合应标「核心直跑预验」并给出对应测试名。
>
> 另外把已经作废的口径一并清理：`fallbackTag = "sys/reject"` 的旧写法不得出现在矩阵或注释里。
>
> ### 二、互通夹具（缺口，最大工作量）
>
> 现状：全仓**没有任何本地受控服务端**。`grep -rn "TcpListener\|listen(" --include="*.rs" crates/` 在业务代码零命中，测试代码也没有。任务卡要求「每个协议、传输、安全选项都要有：prepare 允许、**与本地受控服务端互通**、未纳管的变体在 prepare 被拒」，其中「互通」这一栏完全无能力取证。
>
> 要求：建一套本地受控服务端夹具，供 PC-07 现在与 PC-04c 完成后共用：
>
> 1. **夹具形态**：可用固定核心 `676eaf6` 自身起服务端（`native/xray-bridge` 那份源码已能构建），或用最小协议实现。**建议用固定核心起服务端**——同版本、同协议实现，取证可比性最高。
> 2. **覆盖范围**：先把 P0 七协议的**最小可用组合**跑通，即每协议一个「客户端配置 → 服务端配置 → 建连 → 收发 1 字节 → 断言成功」的闭环。传输先覆盖 raw + ws，其余后续补。
> 3. **落盘**：夹具脚本放 `tests/integration/`（与桥的 `tests/integration/bridge/` 平级或并入），生成的服务端/客户端配置与运行日志落 `~/.agent-tools/run/pc07/interop/`，给 sha256。
> 4. **标注**：**这一轮跑出来的结果只能标「核心直跑预验」，不算验收证据**。经桥的实际连接要等 PC-04c 的 RPC 就绪，届时同一套夹具复用。
> 5. **不得声称互通通过**：只用 Rust 侧生成配置、固定核心客户端连自建服务端，属「核心直跑」，不能写成「PC-07 互通验收通过」。
>
> 若某协议本轮做不出闭环（例如需要真实服务端证书、需要外部网络），**如实标「未通过／缺夹具」并写清卡在哪**，不要用「待 PC-04c」掩盖。
>
> ### 三、分支推送与产物清理
>
> 1. `agent/copilot/pc07` 的 5 个提交（`837d620`、`a969729`、`c36a26f`、`c845bb0`、`aa7e7bc`）**只在本地**，远端 `git ls-remote origin | grep pc07` 无匹配。推到 `origin` 同名分支。
> 2. `crates/secure-store/target/` 未跟踪。在根 `.gitignore` 加 `**/target/`，单独一个 chore 提交。
> 3. 推送后给出 `git ls-remote` 的核对输出。
>
> ### 约束
>
> - **不改 `crates/plugin-xray/proto*`**：proto 相关文件（`core_control.proto`、`proto.lock`、`proto/descriptor.pb`、`core_control*.pb.go`）归 PC-04c 所有，PC-07 不碰（任务卡 v1.3 §2 明文）。
> - 不改 `native/xray-bridge/**`。
> - XMC 的 RSA 字段继续留空，Rust 侧不派生、不保存（v2 批准附节）。
> - `masque://` 继续拒绝并提示高级入口（H-4=A 已落实，`validate.rs:124`）。
> - 每个提交单独跑 Gitleaks 留日志。

## 三、两份提示词的关系

- **PC-04c 第五步（RPC）完成前，PC-07 的「桥 prepare」「经桥的实际连接」两栏无法取证**，PC-07 结卡继续等。
- 但 PC-07 的矩阵、夹具、推送三项现在就能做，且夹具做好后 PC-04c 完成即可直接复用，不必返工。
- 两边都碰 `crates/plugin-xray/`：PC-07 只碰 `src/`、`tests/`，PC-04c 只碰 `proto*`。分界已由任务卡 v1.3 §2 划定，不得越界。

## 四、依据

- v2 审核意见 `a471dd9` §2 C1～C6、§3 H-9
- `sys/direct` 与 H-9 裁定（`4ffe608`）§一 §二
- PC-07 fallbackTag 裁定（`bee960e`）§1.2～§1.5、§2.3、§3
- PC-07 IR v2 审核意见（`7498339`）+ 人类批准附节
- 任务卡 v1.3 §2 PC-07 行、§3 PC-04c 文件归属
- 固定核心 `676eaf6`：`transport/internet/dialer.go:225-280`、`transport/internet/config.proto:104-153`、`proxy/blackhole/blackhole.go:34-46`、`features/policy/default.go:25-27`、`app/proxyman/outbound/outbound.go:102-122`
- 复核记录 `fd6e9d3`（第一步与依赖提交复核 + C5 缺口）
- 证据：`~/.agent-tools/run/pc04c/logs/`、`~/.agent-tools/run/pc07/logs/`、`~/.agent-tools/run/review/pc07-core-verify/`
