# pCryoxy PC-04c｜Control 出站接口变更申请审核意见（eda2e13）

项目: pCryoxy

- 审核方：workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-23 20:37 UTC+8
- 被审：共享仓 `eda2e13`，`handoff/2026-11-23-pCryoxy-PC04c-Control出站接口变更申请-copilot-zhn-tbxg2iah-win.md`（copilot）
- 对照基座：项目 main `c3acc73`；固定核心 `676eaf6`；桥 `native/xray-bridge`；补丁 `upstream-patches/0001～0013`
- 只读取证目录：`~/.agent-tools/run/review/pc04c-a1/`（临时副本，未动 copilot 工作树和项目仓）

## 结论

**不批准原样，需修订后重交 v2。** 申请的整体方向可以接受：整组提交出站和路由、默认拒绝先行、与 RouteView 同 epoch、拒绝代理链、mux 默认拒绝、失败时 active 不变。但请求体格式与已有的人类依赖裁定冲突，核心补丁范围也漏了两处会造成视图混代的地方。下列 H-6～H-8 需要人类裁定，v2 按裁定结果写，之后一次批准。

## 1. 可以接受的部分

| 项 | 意见 |
|---|---|
| 整组提交（ReplaceRoutingAndOutbounds），不做逐个 Add/Remove | 接受。和单 epoch 语义一致，避免中间状态 |
| `desired_overrides` 为完整期望集合，“没传”不等于保留 | 接受 |
| 默认拒绝先于节点出站（§3.1） | 接受，与人类 20:08 裁定一致 |
| 代理链、非 AsIs domainStrategy、可绕过 RouteView 的 sockopt 一律拒绝 | 接受 |
| Rollback 恢复整个 view（含出站映射），发布新 epoch | 接受 |
| QueryState 混代问题，申请扩展 `snapshot.go` | **事实属实**：`snapshot.go:23` 先读 `RouteGeoState()`，`:28` 再读实时 `ListHandlers`。建议批准扩展（见 H-8） |
| 不新增 C ABI 符号，296-byte status 不变 | 接受 |
| 凭据不进日志、回执、fixture | 接受 |

## 2. 须修订（阻断）

### R-1 请求体不能用 JSON + `infra/conf`（与 PC-04b 依赖裁定冲突）

审核方在临时副本里实测：桥只要 import `github.com/xtls/xray-core/infra/conf`，离线只读构建就报「go.mod 需要更新」。用 `-mod=mod` 解析后，go.mod 要新增 20 个模块，其中 `libp2p/go-nat`、`huin/goupnp`、`google/gopacket`、`libp2p/go-netroute`、`jackpal/go-nat-pmp`、`koron/go-ssdp` 等经 `go mod why` 确认来自 **`infra/conf → transport/internet/finalmask/realm`**。realm 正是人类在 PC-04b 裁定去掉的类型，它的依赖链也在当时不批准之列。`infra/conf` 是单个包，无法只引入一部分。

而且现有桥的启动输入本来就是 protobuf：`ValidateRestrictedProfile(config *core.Config, …)`（`restricted_profile.go:78`），`ReplaceRoutes` 也是 typed router config。桥目前不 import `infra/conf`。

建议（H-6 A）：出站以 **`repeated xray.core.OutboundHandlerConfig`**（官方 proto）提交，和启动、路由保持同一种格式；JSON→proto 的转换由 PC-07 用 prost 完成。桥对 proto 做严格纳管：
- 递归检查 unknown fields（`proto.Unmarshal` 默认会保留未知字段而不报错），有就拒绝；
- 每个 TypedMessage 的 type 必须在白名单内；
- 请求摘要用确定性序列化（`proto.MarshalOptions{Deterministic: true}`）计算。

### R-2 XMC 的 RSA 派生位置（同时更正审核方在 PC-07 前置裁定 R1 中的前提）

`xmc.Config` 的 proto 包含 `rsa_private_key = 8`、`rsa_public_key = 9`，派生函数是 `xmc.DeriveRSAKey(password)`（`infra/conf/transport_finalmask.go:981` 调用）。审核方在 PC-07 前置裁定 R1 中写「由核心 Go JSON 构建器派生」，前提是有 JSON 构建环节；但桥收的是 proto，并不经过 JSON 构建器。

建议：Rust 侧仍不派生 RSA，也不引入 RSA 依赖（R1 结论不变）；PC-07 生成的 XMC proto 只填 password/hostname/profiles，两个 RSA 字段留空；**由桥在 prepare 和运行时提交时调用 `xmc.DeriveRSAKey` 填入**（桥已 import `finalmask/xmc`，不新增依赖）。请求里自带 RSA 字段的一律拒绝。启动和运行时用同一个函数，写测试证明结果一致。PC-07 侧同步按此执行。

### R-3 核心补丁范围要写明，现有两处会造成混代

申请 §4 只笼统写了「仅新增序号的 upstream-patches/」。核对 0002/0013 后，至少要新增补丁处理下面几点，v2 须逐项列出：

1. **出站映射是一次性绑定的。** `Router.BindOutboundHandlers()`（0013）在启动时快照 `ohm.ListHandlers`；已经绑定过再调用直接报 `outbound handlers already bound`。运行时替换需要新的「候选 view 携带新出站映射发布」接口。
2. **出站 handler 没有生命周期计数。** `routeView.outbounds` 是裸 `map[string]outbound.Handler`，`newRouteView` 直接继承 base 的 map，没有像 `dnsLife`/`viewResource` 那样的引用计数。替换后旧 handler 什么时候 Close，必须挂在 view 的引用计数上：最后一个读者和 retained 点都释放后才关闭；候选失败时关闭新建的 handler。
3. **Balancer 走实时出站管理器。** `Balancer.SelectOutbounds()` 用 `b.ohm.(outbound.HandlerSelector).Select(selectors)`（`app/router/balancing.go:129-133`），即按前缀匹配**实时** ohm 中的 tag，而不是钉住的 view。运行时换出站后，旧 view 里的 balancer 可能选中一个只存在于新集合的 tag，`OutboundHandler(tag)` 返回 nil 后流量落到默认出站。必须改成在 view 自己的出站映射里做 selector 匹配，并保持固定核心原有的前缀语义。
4. **动态 handler 是否注册到实时 ohm** 要明确选择并论证。建议不注册（view 独占），这样 QueryState 和 balancer 都只能读 view；如果注册，要证明 dispatch、balancer、QueryState 都不读实时 ohm。

### R-4 依赖申请要逐项提交（不论 H-6 如何裁定都需要）

即使走 proto 路线，协议和传输包本身也要引入新模块。审核方在临时副本实测（import `proxy/{blackhole,vless/outbound,vmess/outbound,trojan,shadowsocks,shadowsocks_2022,hysteria,wireguard,masque}` 和 `transport/internet/{splithttp,websocket,httpupgrade,grpc,tls,reality,hysteria,masque}`）：

| 平台 | go.mod 新增（均为 indirect） |
|---|---|
| 三平台共有 | `github.com/google/uuid v1.6.0`、`github.com/gorilla/websocket v1.5.3`、`github.com/quic-go/qpack v0.6.0`、`golang.org/x/exp v0.0.0-20240506185415-9bf2ced13842`、`golang.zx2c4.com/wireguard v0.0.0-20250521234502-f333402bd9cb` |
| 仅 Windows 闭包需要 | `golang.zx2c4.com/wintun v0.0.0-20230126152724-0fa3db229ce2`、`golang.zx2c4.com/wireguard/windows v1.1.1` |

- go.sum 不变（哈希已在）；补全 go.mod 后 Windows amd64、Linux amd64、Android arm64 三平台 `CGO_ENABLED=0 -mod=readonly` 构建都通过；三平台依赖闭包里都没有 realm、xicmp、udphop、go-nat。
- 这是审核方的取证，不代替申请。v2 须按惯例逐项写包名、版本、用途、引入链、平台、是否已在 go.sum，人类批准后才能写入 go.mod，禁止 tidy 改写其他行。

### R-5 次要

- §6 的挂起快照表是 prnmgt 项目的历史条目，和本申请无关，v2 可以删掉。
- `router_config` 与出站同一请求时，路由里引用的 balancer selector 必须在**同一候选**的出站集合里至少匹配一个；空匹配视为失败还是允许（落 fallbackTag），按固定核心语义实测后写明，不要自定。

## 3. 需要人类裁定

### H-6 运行时出站提交用什么格式

- **A（建议）**：官方 proto `repeated xray.core.OutboundHandlerConfig`，和启动、路由一致；JSON→proto 由 PC-07 完成；桥严格检查 unknown fields 和 TypedMessage 白名单；XMC RSA 由桥派生（R-2）。
- B：JSON + `infra/conf`。会引入 realm 及其 NAT/UPnP/抓包依赖链，等于推翻 PC-04b 依赖裁定。不建议。
- C：JSON，但桥自己写一套 JSON 解析。等于重写核心构建器，出错面大。不建议。

### H-7 Windows 上 WireGuard/MASQUE 出站的依赖

`proxy/wireguard`（netstack.go/server.go）和 `proxy/masque`（server.go）都 import `proxy/tun`，`proxy/tun` 在 Windows 上 import `wintun` 和 `wireguard/windows/tunnel/winipcfg`。所以**只要 Windows 要 WireGuard 或 MASQUE 出站，这两个模块就会进入编译闭包**，而 PC-04b 当时不批准它们（针对 TUN 入站）。

核实：WireGuard 客户端走用户态 netstack（`xtun.Stack`），不建网卡；`wintun` 包对 `wintun.dll` 是延迟加载（`dll.go:19`、`wintun.go:34`），只有真正创建 TUN 时才会加载。

- **A（建议）**：只把这两个模块作为 **Windows 的编译依赖**批准，附条件：
  - 不随包分发 `wintun.dll`；
  - Windows TUN 入站继续按 PC-04b H1 在 prepare 阶段拒绝；
  - 提交 Windows 运行证据：WireGuard/MASQUE 出站互通测试期间，进程没有加载 `wintun.dll`，也没有创建网卡；
  - 只作为 indirect 依赖，不在桥代码里直接 import。
- B：Windows 的 P0 不支持 WireGuard/MASQUE 出站。属于 P0 缩减，和 11-22 裁定冲突。
- C：加核心补丁拆开 import。要长期维护补丁，收益只是不出现在 go.mod 里。不建议。

### H-8 mux 边界与文件归属（建议一并按建议批准）

- **mux**：本卡默认拒绝，出现启用或无法识别的 mux 配置时明确拒绝，active 不变。REQ-08 没有要求 mux，工程蓝图 §331 本来就写「默认关闭 Mux」，不算 P0 缩减。以后要开放，另立卡补单 epoch、复用、回滚证据。
- **文件归属**：批准 `native/xray-bridge/snapshot.go` 及其直接测试；`upstream-patches/` 新增补丁按 R-3 列出的范围。

## 4. v2 交付要求

1. 按 H-6～H-8 的裁定结果改写 §1、§4；
2. 写入 R-1～R-5；
3. 依赖逐项申请（R-4）；
4. 列明新增核心补丁的编号、改动文件和要解决的问题（R-3 的 1～4）；
5. 批准前不改契约文件、不写实现、不改 go.mod。

PC-04c 状态维持 doing。PC-07 的「桥 prepare」「实际连接」两栏继续标「待 PC-04c」。


## 附：人类裁定（2026-11-23 20:40）

- H-6：A。运行时出站提交用官方 protobuf（repeated core.OutboundHandlerConfig），与启动配置、RouteView 同格式；JSON→protobuf 由 PC-07 负责；桥拒绝未知字段、只放行白名单类型；不引入 infra/conf。
- H-7：A。golang.zx2c4.com/wintun、golang.zx2c4.com/wireguard/windows 仅作为 Windows 编译依赖批准（经 proxy/wireguard、proxy/masque→proxy/tun 引入）。附条件：不分发 wintun.dll；Windows 仍在 prepare 阶段拒绝 TUN 入站；补交 WireGuard/MASQUE 出站运行时未加载 wintun.dll 的证据。版本以 v2 依赖申请逐项列明为准，go.sum 不得变化。
- H-8：批准。mux 默认拒绝；PC-04c 文件范围扩大到 snapshot.go，修复先读路由状态、再读实时出站列表造成的不一致。
- 仍须修订：R-1～R-4（含 XMC RSA 由桥调 xmc.DeriveRSAKey 派生、请求自带即拒；补丁覆盖出站重绑定、handler 引用计数、Balancer 走 view 内出站集合；三平台新增模块逐项申请）。v2 批准须人类另行明确表示，本节不构成批准。

（本节由 workbuddy 代为登记人类裁定。）
