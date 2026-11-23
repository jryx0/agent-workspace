# pCryoxy PC-04b 首轮审核裁定（66a1ca4）

- 审核方：workbuddy@zhn-tbxg2iah-win~zhn-x-w
- 时间：2026-11-23 16:30 UTC+8
- 被审提交：项目 `66a1ca492c12fb079421fc9639f1df80367da7bd`（分支 `agent/copilot/pc04b`，基座 `451c3cb`）；共享仓 `60613c4`（依赖申请 handoff + 待办）
- 结论：**不通过，退回返工（1 项阻断）**。PC-04b 保持 doing。功能、replay、可复现构建全部通过；阻断项仅为 Windows 构建回归，修法需人类在 H1 二选一。
- 证据目录：`~/.agent-tools/run/review/pc04b-r1/`（`logs/replay.log`、`logs/cross-*.txt`、`logs/win-base.txt`）

## 1. 独立重跑（审核方从 `git archive 66a1ca4` 导出，独立目录与缓存）

| 项目 | 结果 |
|---|---|
| 固定源码哈希校验（xray-676eaf66.tar.gz，3932cefe…） | 通过 |
| 补丁 0001～0013 应用 | 通过 |
| 上游 router/dns/dispatcher/proxy-dns/geodata 测试（普通 + `-race`） | 全部 ok，DATA RACE 0 |
| bridge 全量测试（普通 + `-race`） | 全部 ok；本卡新增 8 个测试各通过 2 次 |
| `go.sum` 与提交一致（`cmp`） | 通过 |
| ABI v1 preflight smoke（1024 并发） | 通过 |
| ABI v2 runtime smoke（8 线程并发 status） | 通过 |
| 双独立 GOCACHE/GOTMPDIR archive 构建 | first.a = second.a = 3,357,208 B，SHA-256 `ca55e2891fc3f97aced8d1ec426aeb9c16239013ebfd7855576fd47933435585`，**与 copilot r10 字节一致** |
| Android arm64 cgo archive（Windows Go 1.27.4 + NDK 29 clang，`-mod=readonly` 离线） | 通过，3,364,150 B，go.mod 无需改动 |
| **Windows amd64 cgo archive（`-mod=readonly` 离线）** | **失败**：`go: updates to go.mod needed` |
| Gitleaks（项目 `451c3cb..66a1ca4`、共享仓 `60613c4`） | 0 |
| realm 链依赖（goupnp/go-nat/pion/gopacket/ssdp/anet）在 bridge 依赖图中 | 0 |

## 2. 卡面验收对照（v1.2 §3）

| 验收 | 结论 | 依据 |
|---|---|---|
| prepare 正向取证 | 通过 | `TestValidateRestrictedProfileAllowsWhitelistedInboundsAndRouteOutbounds`、`…AllowsExplicitFinalMaskTypes` |
| 热更新单 epoch（含 -race） | 通过 | `TestPC04DNSRouteEpoch`、`TestPC04LocalDNSRouteEpoch` 及 route_view 系，`-race` 无竞争 |
| 未纳管变体 prepare 被拒且 active 不变 | 通过 | `…RejectsUnmanagedInboundAndDNSWithoutMutation`、`TestRegisterRuntimeRejectsUnmanagedFinalMasksWithoutMutation`（含 realm/xicmp/udphop） |
| 不引入 SetAdmission | 通过 | `451c3cb..66a1ca4` diff 中 0 处 |
| PC-04 replay 全量回归 | 通过 | 见 §1 |
| 审核方独立重跑 | 通过 | 见 §1，产物哈希一致 |

上一轮人类裁定的落实：go.mod 仅 +netlink v1.3.1 / netns v0.0.5；FinalMask 去除 realm/xicmp/udphop；sniffing 启用须 `route_only=true`、`destination_override` ⊆ {http,tls} 且非空、fakedns 与 exclusions 拒绝；tun 必须开 sniffing，socks/http 可关；socks/http 仅回环监听；IP 字面量目标不被改写有测试。均已核实。

## 3. 阻断项

**B1　Windows 构建回归：引入 `proxy/tun` 后 go.mod 缺 Windows 专属模块。**
- `restricted_profile.go` 无条件 import `github.com/xtls/xray-core/proxy/tun`。其 Windows 实现依赖 `golang.zx2c4.com/wintun v0.0.0-20230126152724-0fa3db229ce2` 与 `golang.zx2c4.com/wireguard/windows v1.1.1`，二者在 go.sum 中已有、但 go.mod 未 require。
- 对照：基座 `451c3cb` 的 bridge 在 `GOOS=windows -mod=readonly` 下解析通过；`66a1ca4` 失败（Windows 原生 Go 1.27.4 与 WSL 交叉两种方式结果一致）。在副本中以 `-mod=mod` 补出的正好是这两行，补后 Windows cgo archive 可编过，go.sum 不变。
- 影响：bridge 在 Windows 上无法离线构建，Windows 是 P0 平台。
- 性质：这两个模块不在人类 15:xx 批准的「仅 netlink、netns」范围内，属于未申请的新增依赖。wintun 运行时还需随包分发签名的 `wintun.dll` 并需管理员权限。
- replay 只跑 Linux，所以 copilot 与审核方 replay 都没暴露；PC-04 结卡口径也只有 Linux，本轮补做了 Windows/Android 才发现。

## 4. 待人类裁定

**H1　Windows 上的 tun 入站怎么处理**（二选一）
1. **（建议）tun 入站只在 Android/Linux 构建放行**：用 build tag 把 `proxy/tun` 的 import 与 tun 校验分支限定在 `!windows`；Windows 构建中 tun 入站在 prepare 阶段明确拒绝（新增反向测试）。go.mod 不新增依赖。理由：P0 的 Windows 走系统代理（socks/http），tun 是 Android 经 `XRAY_TUN_FD` 的路径；Windows tun 要分发 `wintun.dll`、要管理员权限，应由后续卡另行申请。
2. 批准 wintun、wireguard/windows 两个依赖，go.mod 补两行 indirect；同时登记 `wintun.dll` 分发、签名与管理员权限的后续待办。

## 5. 非阻断建议

- A1　入站 `receiver.stream_settings` 与出站 `sender.stream_settings` 只校验了 FinalMask，传输层与 security（如入站 TLS、出站 dialer proxy）未收窄。P0 由 PC-07 从 IR 生成配置，风险低，建议后续卡补齐白名单。
- A2　`replay-linux.sh` 只覆盖 Linux。建议返工时把 Windows（zig `x86_64-windows-gnu` 或 Windows Go）与 Android（NDK 29）的 `-mod=readonly` archive 构建加入交付证据。

## 6. 返工要求

1. 按 H1 裁定修复 B1；不得自行选择。
2. 给出 Windows、Android、Linux 三平台 `-mod=readonly`、`GOPROXY=off` 的 bridge archive 构建证据，以及 go.mod 前后 require 对比。
3. 在新提交上重跑完整 replay，报 first.a/second.a 字节与 SHA-256。
4. 提交后回报提交号；PC-04b 保持 doing / 待审核，不合并、不 push。

### 6.1 人类裁定结果（2026-11-23 16:23 UTC+8）

人类在对话中裁定 **H1 采用 §4 第 1 项（审核方建议）**：tun 入站只在 Android/Linux 构建放行，Windows 构建不引入 `proxy/tun`，go.mod 不新增依赖。wintun、wireguard/windows **未获批准**。返工具体要求：

1. `proxy/tun` 的 import 与 tun 校验分支移到带 `//go:build !windows` 的文件；Windows 侧用 `//go:build windows` 的对应文件，在 prepare 阶段对 tun 入站返回明确的「不支持」错误（错误码与现有未纳管拒绝一致），active 状态不变。
2. 反向测试：Windows 下 tun 入站被拒、active 不变。该测试须能在 Windows 上实际运行（Windows 原生 Go `go test -run`），或至少以 `GOOS=windows go test -c` 编译通过并附说明；Linux 侧原有 tun 正向／必开 sniffing 测试保持不变。
3. go.mod 的 require 相对基座 `451c3cb` 只允许多 netlink v1.3.1、netns v0.0.5，go.sum 不得新增条目。注意：`go mod tidy` 会按全平台加载被引用包，可能要求补 wintun；**不得执行会写回 go.mod 的 tidy**，如遇工具要求补模块，回报审核方。
4. 文档（`tests/integration/bridge/profile.md` 或 BUILD.md）写明：P0 Windows 走系统代理（socks/http），Windows tun 入站不支持；并在共享记忆末尾登记后续待办「Windows tun（wintun.dll 分发、签名、管理员权限、依赖申请）由后续卡承接」。
5. 交付证据：Windows（Windows Go 或 zig `x86_64-windows-gnu`）、Android（NDK 29）、Linux 三平台 `-mod=readonly`、`GOPROXY=off` 的 bridge archive 构建；新提交上的完整 replay（first.a/second.a 字节与 SHA-256）；go.mod require 前后对比。
