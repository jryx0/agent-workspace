# pCryoxy PC-04c｜Control 出站接口变更申请 v2

项目: pCryoxy

- 申请者：copilot@zhn-tbxg2iah-win~zhn-x-w#pc04c；状态：doing，**v2 待契约所有者审核及人类整体批准**。
- 项目基座 `c3acc73f0b1cfc25b1770a4d0d9645cd59681738`，worktree `C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc04c`，分支 `agent/copilot/pc04c`；固定核心 `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`。
- 依据：v1 `eda2e135341c7b74aa76768c6415ccb6068adb87`；审核意见 `handoff/2026-11-23-pCryoxy-PC04c出站接口申请审核意见-eda2e13-zhn-tbxg2iah-win.md`，人类 H-6=A、H-7=A、H-8；任务卡 v1.3 增量 §3、§3.1。H-6～H-8 的单项裁定不是 v2 整体批准。
- 本文取代 v1 的接口、RSA 派生、依赖、补丁和文件范围方案；默认拒绝先行、整组提交、失败不改变 active、单 epoch、完整回滚及 ABI 边界不变。v1 JSON/`infra/conf` 方案撤回；PC-07 负责 JSON→官方 protobuf，桥不接收 JSON、不 import `infra/conf`。

## 1. 接口及准入

```proto
import "core/config.proto";

rpc ReplaceRoutingAndOutbounds(ReplaceRoutingAndOutboundsRequest) returns (CommitReceipt);
message ReplaceRoutingAndOutboundsRequest {
  OpHeader header = 1;
  repeated xray.core.OutboundHandlerConfig outbounds = 2;
  xray.common.serial.TypedMessage router_config = 3;
  repeated Override desired_overrides = 4;
}
```

`outbounds` 按顺序是整个候选出站集合，不是增量；不能为空，首项为 `sys/reject`。`router_config` 和 overrides 都是完整候选，“未传”不表示保留旧值。保留现有实例身份、expected_epoch、operation_id、确定性 protobuf 序列化摘要、结果对账和回执语义；成功一次发布，失败不产生回滚点或已应用回执。错误不泄漏配置或凭据。

- 递归拒绝 protobuf 未知字段；`TypedMessage.value` 须按白名单 type 解码后递归检查，不能仅检查外壳；拒绝未列出的 proxy、transport、security、FinalMask、字段、错误或不支持的组合。重复/空 tag、缺失必要字段、proxySettings 或 dialerProxy 指向出站的代理链、非 AsIs domainStrategy 和能绕过 RouteView 的 sockopt 均拒绝；`mux.enabled=true` 及无法识别的 mux 配置明确拒绝，不静默清零。
- 运行时及启动 prepare 使用同一出站准入/规范化函数，测试同一输入在两入口的接受、拒绝及派生结果一致。不得修改调用方持有的配置；对临时克隆校验、派生，失败不得修改 active 或旧资源。
- 协议/传输/安全范围仍按任务卡逐项取证，不得以申请代替支持声明。受控 FinalMask 复用 PC-04b 白名单；realm、xicmp、udphop 等仍拒绝。Windows TUN 入站按 PC-04b H1 仍拒绝。
- **先完成 §3.1 默认拒绝及其验收，再放行节点出站**：首出站必须为 blackhole `sys/reject`，response 为未填或 `none`，并拒绝携带 custom_response_data 等其他内容；`sys/reject` 和 `sys/direct` 常驻、不可删除或替换、不进动态池。运行时候选必须保留原实例；未命中流量不能直连。
- 出站实际 tag、路由显式目标、fallbackTag、override 指向和默认出站在同一候选中核验；引用缺失 tag 必须失败。selector 使用固定核心 `strings.HasPrefix`、去重并排序的语义；核心 `Balancer.PickOutbound` 对空候选有 fallbackTag 或报错，不能把 selector 当作完整 tag。**空候选提交是否允许走合法 fallback**：先在固定核心实测空 selector、fallback 和无 fallback，再向审核方确认；未确认不得自行改变语义或宣称验证通过。

## 2. XMC RSA：桥派生，禁止请求携带

PC-07 输出 XMC proto 的 password/hostname/profiles，`rsa_private_key` 和 `rsa_public_key` 均为空；Rust 不派生或持久化 RSA。桥统一校验函数对输入的任一 RSA 字段非空一律拒绝，然后在私有克隆调用 `xmc.DeriveRSAKey(password)`。参照固定核心 `infra/conf/transport_finalmask.go:981-1006` 的编码：PKCS#1 DER 填私钥、PKIX DER 填派生公钥；这里仅调用 xmc 和 Go 标准库，**不 import infra/conf**。派生或编码失败明确失败，禁止回显密码、密钥或原始 proto。

测试：启动和运行时相同密码产生等价派生结果；任一自带私钥/公钥均拒绝且 active 不变；非法输入和派生失败不留半成品；调用者输入未变、旧回滚点未变；同时覆盖真实 XMC 可互通，不用包含明文或派生密钥的静态 fixture。

## 3. 新增核心补丁方案与逐项测试

只新增 `upstream-patches/0014-route-view-dynamic-outbounds.patch`，不改 0001～0013；候选补丁目标文件如下，确需新增或修改其他既有文件时先补充清单审批：

| 修改的固定核心文件 | 方案 |
|---|---|
| `app/router/route_view.go`、`app/router/router.go` | 保留启动绑定；新增受 expected epoch 约束的候选接口，绑定有序出站集合、default 和完整路由/override 后一次发布，不能再次调用一次性 `BindOutboundHandlers` 冒充运行时更新；Geo/仅路由更新与 rollback 保留正确的映射。新增固定核心测试 `app/router/pc04c_outbound_view_test.go`。 |
| `app/router/route_view.go`、`app/proxyman/outbound/handler.go`（仅在需要安全延迟 stats/资源初始化时） | 给 handler 及共享出站集合明确所有权、引用计数，bootstrap 管理器与 view 不得双重关闭；成功 publish 的旧 handler 由旧 view、在途连接、retained point 共持，最后引用释放后恰好关闭一次。候选失败只关闭新资源；不复用已经释放的 handler。构造/Start/Close 及外部副作用须在锁外完成，失败可追踪。必要生命周期测试列入新测试文件。 |
| `app/router/balancing.go`、`app/router/config.go`、`app/router/router.go`、`app/router/lua.go` | 路由决策、`GetPrincipleTarget`、Lua 的 selector 均使用调用时固定的 view，而非实时 ohm；匹配结果保持前缀、去重、排序语义，避免复用跨 view 的实时缓存。候选与回滚的 override、fallback 均只引用同一 view 的 handler。 |
| `app/dispatcher/default.go`、`app/router/route_view.go`、`app/proxyman/outbound/handler.go`（必要时） | 新动态 handler **不注册实时 ohm**；dispatch、balancer、状态查询均经 pinned view；保留 bootstrap 静态 handler 的管理器兼容，但拒绝独立 HandlerService 绕过提交。请求审核此选择及可能需要的 handler 构造/生命周期补丁。 |

动态出站不注册 ohm 的影响：`ListHandlers`/实时 selector 不反映动态出站，不能用于 `QueryState`、路由或管理清单；`snapshot.go` 改从一次固定 view 取 epoch/revision/Geo 与 tags 同算摘要。官方 HandlerService 未注册，不能把它的列表当本契约。固定核心 `NewHandler` 在构造时可能通过 stats manager 按 tag `GetOrRegisterCounter`，即使不加入 ohm 也可能有副作用和同 tag 跨 epoch 合并；本受限 profile 当前未纳管 stats，**不宣称新旧 epoch 分离计数**。须实测候选失败是否留下 stats 或其他外部副作用，并验证生产 profile 仍拒绝未纳管 stats；若需要启用 stats 或无法在失败时清理副作用，停下另申请设计，不返回成功。

每项测试均包含成功 publish、rollback 和 Linux `-race`：
1. **重绑定**：两个带相同/不同 tag 的集合随路由一次切换；旧连接仍走旧 handler，新的仅走新 handler；rollback 递增 epoch 并恢复旧集合；竞态下读到的 `(epoch, route, handler)` 只能来自一个完整 view。
2. **生命周期**：可计数的 handler 模拟长连接、多个 retained points、失败候选、释放顺序和回滚；旧连接及回滚点任存时不关闭，最后释放后恰好一次关闭；没有 use-after-close、泄漏、重复关闭或 race。
3. **balancer**：两 view 的前缀集合互斥、重叠、重复 selector 与有序结果；固定旧 view 跨 publish 和 rollback 继续选旧集合，fresh view 选新集合，覆盖 random/roundrobin、override、fallback、GetPrincipleTarget 与可达 Lua 路径；匹配结果与固定核心原始 selector 对照，不从实时 ohm 取值。
4. **不注册及状态/stats**：人为让 ohm 列表与 view 不同，dispatch 和 balancer 仍绑定 view，`QueryState` 的 tag digest 与同一 epoch 始终一致；反复 publish、rollback、查询、释放并跑 race；失败候选不留下可观察 stats/handler 副作用，或在确有副作用时停报。

## 4. go.mod 增量申请（go.sum 不变）

审核副本 `~/.agent-tools/run/review/pc04c-a1/` 的 proto 出站 import 闭包 `protoroute-gomod.diff` 有以下 **7 个 indirect**，各模块对应版本在基座 go.sum 中已有完整模块校验行；本次申请仅加这 7 行，go.sum 不变，不 tidy，不新增 realm、xicmp、udphop、go-nat、goupnp、gopacket。

| 模块及版本 | 平台 | 用途和 `go mod why -m` 引入链 |
|---|---|---|
| `github.com/google/uuid v1.6.0` | 三平台 | Hysteria 账户标识：bridge → `proxy/hysteria` → `proxy/hysteria/account` → uuid |
| `github.com/gorilla/websocket v1.5.3` | 三平台 | WebSocket 传输：bridge → `transport/internet/websocket` → websocket |
| `github.com/quic-go/qpack v0.6.0` | 三平台 | Hysteria HTTP/3 QPACK：bridge → `transport/internet/hysteria` → `github.com/apernet/quic-go/http3` → qpack |
| `golang.org/x/exp v0.0.0-20240506185415-9bf2ced13842` | 三平台 | Hysteria BBR 类型约束：bridge → `transport/internet/hysteria` → `transport/internet/hysteria/congestion/bbr` → `x/exp/constraints` |
| `golang.zx2c4.com/wireguard v0.0.0-20250521234502-f333402bd9cb` | 三平台 | WireGuard 用户态协议/网络栈：bridge → `proxy/wireguard` → `wireguard/conn` |
| `golang.zx2c4.com/wintun v0.0.0-20230126152724-0fa3db229ce2` | Windows 编译闭包 | bridge → `proxy/tun` → wintun；经 WireGuard/MASQUE 的核心包间依赖进入，不在桥直接 import |
| `golang.zx2c4.com/wireguard/windows v1.1.1` | Windows 编译闭包 | bridge → `proxy/tun` → `wireguard/windows/tunnel/winipcfg`；不在桥直接 import |

取证：对审核临时 probe 使用 Go 1.27.4、`GOPROXY=off GOSUMDB=off GOFLAGS=-mod=readonly` 分别设置 Windows/amd64、Linux/amd64、Android/arm64 运行 `go mod why -m`；日志在本会话 `files/pc04c-why-{windows,linux,android}.log`。`go mod why` 会考虑其他构建标签，因此三份输出都列出 Windows 包，**不能单凭它判定平台闭包**；平台归属采用审核方独立三平台构建结论，交付时重新用目标平台依赖图复核。日志有 `downloading` 提示（离线缓存缺部分测试依赖，实际 GOPROXY=off），命令退出 0；不据此声称这些额外包已下载或安装。

H-7=A 的 wintun 和 wireguard/windows 仅作编译依赖；不分发 wintun.dll、不启用 Windows TUN 入站。Windows WireGuard、MASQUE 受控互通时逐项记录进程模块列表证明未加载 wintun.dll，并以运行前后网卡清单及相关事件证明未创建网卡；证据缺失则不结卡。审核方日志中 `build-windows.txt`、`build-linux.txt`、`build-android.txt` 为空，成功结论引用审核意见，不冒称日志本身包含退出码；`android-list.txt` 为修改前只读缺依赖结果。

## 5. 文件范围、契约与门禁

- 契约：`native/xray-bridge/core_control.proto`、`core_control.pb.go`、`core_control_grpc.pb.go`、`crates/plugin-xray/proto.lock`、`crates/plugin-xray/proto/descriptor.pb`；按锁定工具生成，更新方法及所有相关哈希、大小，不改已有字段编号。PC-07 不修改这些文件。
- 依赖：`native/xray-bridge/go.mod` 仅上表七项，`go.sum` 不能变化。增补后按 Windows、Linux、Android 各自 `-mod=readonly` 离线验证；新增任何其他模块或禁用链立即停报。
- 非契约：卡面允许的 `native/xray-bridge/restricted_profile*.go`、`route_control.go`、`runtime*.go`、新增桥内文件、`tests/integration/bridge/`，以及 H-8 已批准的 `native/xray-bridge/snapshot.go` 和直接测试。计划新增 `native/xray-bridge/pc04c_outbound_test.go`、`native/xray-bridge/snapshot_test.go`，按需要修改已有 `restricted_profile_test.go`、`restricted_profile_tun_unix_test.go`、`restricted_profile_windows_test.go` 中首出站为 freedom 的夹具，并报告具体范围。
- 核心补丁只新增 `upstream-patches/0014-route-view-dynamic-outbounds.patch`，内容及核心内测试文件详见 §3；绝不改已审核补丁，若须扩展补丁目标文件先报。
- 验收：逐协议/传输/安全分别记录 prepare、受控服务互通、未纳管变体拒绝及 active 不变；默认拒绝、缺失 tag、保留出站变更、XMC、mux、单 epoch/race、生命周期和状态摘要均有独立反例。PC-04/04b 全量回归、Windows 原生 CGO_ENABLED=0、Linux WSL（含 race）、Android NDK 交叉构建，以及 `c3acc73..HEAD` Gitleaks；记录具体包、用例、排除项和原因，临时测试路径用 `t.TempDir()`。不改 ABI v2 C 符号或 296-byte status，不引入 SetAdmission/新流门禁。
- 人类整体批准前，不改契约、go.mod 或核心补丁。人类另允许的 §3.1 默认拒绝启动校验及测试可单独分支提交，不能视为完整功能或 v2 获批。若需要缩小范围或无法证明安全，先停报人类。

## 6. 交接状态

共享仓本地与 origin/backup 在自检时均为 `00ad020`，故依共享仓规范跳过 pull（共享仓含他人未提交内容）；之后共享仓已由其他会话推进。PC-04c 原认领不变，未部署、不合并、不推项目 main；本申请待审核。PC-07 IR v2 已另获批准，不等于本申请获批。挂起快照不在此伪称完整；请交接维护方继续核实全量快照。

## 7. 人类裁定：fragment 长度桥侧兜底

- 人类针对 PC-07 的 fragment 安全问题批准收窄：每一项 `lengths_min/max` 均须满足 `min >= 1` 且 `min <= max`；零、负数、跨零及逆序区间明确拒绝，不对调、不改写输入。报告项序号和原值。依据固定核心 `676eaf6` 的 `transport/internet/finalmask/fragment/conn.go:139-143`（负长度切片越界）和 `common/crypto/crypto.go:13-15`（核心会静默对调逆序）。
- PC-04c 须在启动 prepare 与运行时出站提交中使用同一校验函数，逐项检查 fragment 的 `lengths_min/max`，作为桥侧兜底；拒绝时 active 不变。验收包含 1 通过、0、-1、[-1,5]、[5,3] 拒绝，以及多段中任一项非法时整体拒绝。PC-07 不修改桥。
- 本附节只记录人类对 fragment 校验的裁定，不构成 PC-04c v2 的整体批准。记录：copilot@zhn-tbxg2iah-win~zhn-x-w（PC-07 会话）。
