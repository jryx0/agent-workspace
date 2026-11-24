# pCryoxy PC-04c｜Control 出站接口申请 v2 审核意见（a471dd9）

项目: pCryoxy

- 审核方：workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-24 08:35 UTC+8
- 被审：`handoff/2026-11-24-pCryoxy-PC04c-Control出站接口变更申请v2-copilot-zhn-tbxg2iah-win.md`（共享仓 `a471dd900a21d0647e54a35f890c04bd5554086d`）
- 依据：v1 审核意见 `…PC04c出站接口申请审核意见-eda2e13-…md`（R-1～R-4，H-6=A、H-7=A、H-8 批准）；任务卡 v1.3 增量 §3、§3.1、§3.2；固定核心 `676eaf6`；main `c3acc73`。

## 结论

**v2 已落实 R-1～R-4 与 H-6/H-7/H-8，审核方建议人类按下列附条件 C1～C6 整体批准 v2，并裁定 H-9。** 不需要再出 v3：附条件直接作为批准范围的一部分，copilot 在实施和交付报告中逐条落实。人类明确批准之前，不改契约文件、go.mod 和核心补丁。

## 1. 已落实（审核方核实）

| 项 | 核实结果 |
|---|---|
| R-1 / H-6 格式 | `ReplaceRoutingAndOutbounds` 收 `repeated xray.core.OutboundHandlerConfig` + 完整 router_config + overrides，整组候选，不 import `infra/conf`。现有 6 个 RPC 字段编号不变。 |
| R-2 XMC RSA | proto 中 `rsa_private_key=8`、`rsa_public_key=9`（`finalmask/xmc/config.proto:22-23`）；请求自带任一非空即拒，桥在克隆上调 `xmc.DeriveRSAKey`。可接受。 |
| R-3 补丁范围 | 只新增 `0014-route-view-dynamic-outbounds.patch`，不改 0001～0013；覆盖重绑定、引用计数、balancer 走 view、动态 handler 不注册实时 ohm，每项有 publish/rollback/-race 测试设计。 |
| R-4 / H-7 依赖 | 7 个 indirect 与审核方 `pc04c-a1/logs/protoroute-gomod.diff` 逐行一致；7 个版本在基座 `native/xray-bridge/go.sum` 中均已有模块哈希行，go.sum 无需变化。 |
| H-8 | mux 默认拒绝；`snapshot.go` 改为从一次固定 view 取 epoch/revision/Geo 与 tags。 |
| §3.1 / §3.2 | 默认拒绝先行、fragment 桥侧兜底均已写入。 |

## 2. 审核方补充核实与附条件

**C1 无 scope 分发回落实时 ohm（须修）。** 0013 补丁的 `outboundForDispatch`/`defaultOutboundForDispatch` 在 context 没有 `DispatchScope` 时回落 `manager.GetHandler(tag)`/`GetDefaultHandler()`。动态出站不注册 ohm 后，任何无 scope 的分发会落到 bootstrap 出站集合，绕过当前 view。要求：0014 中无 scope 分发只允许命中 bootstrap 常驻的 `sys/reject`/`sys/direct`，其他 tag 一律失败；或证明所有生产分发路径（入站、DNS 出站、sniffing 后重分发、内部探测）都带 scope，并为每条路径写测试。二选一写进实施报告。

**C2 空候选与 fallback（回答 v2 §1 待确认项）。** 固定核心 `router.go` 中 balancer 选择出错时返回错误，`dispatcher/default.go:480-481` 随后取默认出站；在 §3.1 下默认出站是 `sys/reject`，所以没有 fallbackTag 时空候选会失败关闭。审核方意见：**允许**空候选走 fallbackTag，前提是 fallbackTag 必须指向同一候选 view 内已存在的出站，否则提交失败；没有 fallback 时落到 `sys/reject`。不允许回落到直连。三种情况（有 fallback、无 fallback、fallback 指向缺失 tag）都要实测并写测试，不另开人类裁定。

**C3 Lua 路径不打补丁。** 桥对 router 的 `script` 非空一律拒绝（`route_control.go:28`），Lua selector 不可达。从 0014 目标文件中去掉 `app/router/lua.go`，改为加一条测试证明带 script 的候选仍被拒；以后开放 Lua 另行申请。

**C4 stats 副作用的结论。** `outbound/handler.go:30-50` 只在 `policy.ForSystem().Stats.OutboundUplink/Downlink` 为真时注册计数器。受限 profile 的 app 白名单只有 router/dns/dispatcher/proxyman.OutboundConfig（`restricted_profile.go:91`），核心退回 `policy.DefaultManager`，其 `ForSystem()` 返回零值（`features/policy/default.go:25-27`），所以当前不会注册计数器。要求：把这条推理写进实施报告并加一条测试，证明 policy/stats app 仍被拒；不需要为 stats 做额外补丁。若以后要启用统计，另行申请。

**C5 sockopt 用白名单表述。** 「能绕过 RouteView 的 sockopt 拒绝」不可验证。改为：`stream_settings.socket_settings` 只放行明确列出的字段（默认全拒，逐项论证后放行），列表写进交付报告。

**C6 证据落盘。** `go mod why` 日志写在「本会话 files/」，不是持久路径。实施前复制到 `~/.agent-tools/run/pc04c/logs/`（或 handoff 附件），报告引用该路径与 sha256。

**附带说明（不阻断）**：`handler.go` 标为「仅在需要时」修改，可以接受；真的需要时在交付报告里说明原因，超出 v2 §3 表格的文件仍须先报。

## 3. 待人类裁定

### H-9 回滚点持有旧出站的资源上限

运行时提交整组出站后，回滚点要能精确恢复旧集合，所以每个保留的回滚点都持有一整组旧 handler。WireGuard、MASQUE 等出站在构造时会创建用户态网络栈和后台 goroutine。现有 `rollbackLimit = 64`（`operation.go:15`），最坏情况下 64 组完整出站同时存活。

| 选项 | 做法 | 评价 |
|---|---|---|
| **A（建议）** | 回滚点继续持有旧 handler（保证精确回滚）；另设「携带出站集合的回滚点」上限 **8**，超出返回 ResourceExhausted，须先释放。仅路由/Geo 的回滚点仍按 64 计 | 回滚语义不变，资源有上界；8 是审核方按资源控制给的数，没有协议依据 |
| B | 不设单独上限，共用 64 | 最坏资源占用没有上界 |
| C | 回滚时按旧配置重建 handler | 重建可能失败，回滚不再「恰好恢复」，违反单 epoch 回滚语义，不建议 |

选 A 时附：交付证据包含 8 个携带出站的回滚点同时存在时的 goroutine 数与内存，以及第 9 个被拒、active 不变。

## 4. 批准后的实施顺序（建议）

1. 先单独提交 §3.1 默认拒绝与 §3.2 fragment 兜底（不涉及契约）；
2. go.mod 只加 7 行，三平台 `-mod=readonly` 离线构建复核；
3. 0014 补丁与核心内测试；
4. proto 契约与 RPC 实现；
5. 逐协议准入与互通取证、Windows 未加载 wintun.dll 证据。

## 附：人类批准与裁定（2026-11-24 09:10）

- 人类明确批准 PC-04c Control 出站接口变更申请 v2（共享仓 a471dd9），附条件 C1～C6 一并生效（见 §2），批准范围以 v2 申请与本文为准。
- H-9：A。携带出站集合的回滚点单独上限 8，超过即拒绝（需先释放旧回滚点），active 不变；仅路由/Geo 的回滚点仍按 64。依据写「人类裁定（资源控制）」。验收含 8 个携带出站的回滚点同时存在时的 goroutine 数与内存，以及第 9 个被拒。
- 批准后可按 §4 顺序实施：改 core_control.proto 及生成文件、proto.lock、descriptor.pb、go.mod（只加 v2 列出的 7 个 indirect，go.sum 不得变化）、新增 upstream-patches/0014（不含 lua.go）、snapshot.go。清单外文件先补申请。

（本节由 workbuddy 代为登记人类批准。）
