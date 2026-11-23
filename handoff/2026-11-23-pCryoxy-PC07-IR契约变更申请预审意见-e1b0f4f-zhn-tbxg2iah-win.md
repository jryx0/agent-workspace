# pCryoxy PC-07 IR 契约变更合并申请｜审核方预审意见（e1b0f4f）

- 被审：共享仓 `e1b0f4f63c62027178a9565c65b4cc26e9ac545e`（copilot 19:38），追加在 `handoff/2026-11-23-pCryoxy-PC07-FinalMask-IR接口变更申请-copilot-…md` 末尾的「合并补充申请」A～D 节。
- 审核：workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-23 19:47 UTC+8
- 依据：需求基线 v1.3 REQ-08；PC-06 首轮审核裁定 §H1（人类裁定：完整 WireGuard 分享链接转 P1，P0 只支持 JSON/手工构造）；PC-07 前置事项裁定 §3/§3.1；固定核心 `676eaf6` 源码。
- **结论：需修订后重交（v2），本次不批准。** 方向正确：合并成一次迁移；不发明输入格式；SecretRef 不复制明文；不推测旧 `peers` 的含义。但有一处事实错误（MASQUE），FinalMask 部分还没按 R1～R7 修订，另有 2 个点要先请人类裁定。

## 1. 逐项意见

| # | 节 | 意见 | 级别 |
|---|---|---|---|
| E1 | A 快照版本号 | 接受。无版本格式视为 v0，首个显式版本为 v1，只迁移一次（v0→v1）；revision 不变；未知版本明确失败。补一条：v1 的序列化格式若需要新依赖，另走申请（申请里已写明） | 通过 |
| E2 | B WireGuard 输入来源 | **口径要改。** 申请认为「没有标准 URI 就不支持」。但人类在 PC-06 H1 已裁定：P0 的 WireGuard 只通过 **JSON/手工构造** 录入，完整分享链接转 P1；REQ-08 也规定「其余已支持的能力提供高级入口」。所以 Interface/Peer 字段的 P0 输入来源是**高级入口（PC-14/15）**，可以建模；矩阵「解析」栏标「高级入口（待 PC-14/15）」。`wireguard://` 分享链接继续按 H1 明确拒绝，不重开 H1 | 须修 |
| E3 | B 旧 `peers` | 接受「不推测语义」。v1 中旧 `peers` 保留为只读的 `legacy_peer_ips`，不参与配置生成；有这个字段的节点在配置生成阶段报「需重新录入」，不能悄悄忽略。同时说明 parser 的 `peer`/`peers` query 以后是否继续接受（建议按 H1 一起拒绝） | 须补 |
| E4 | B 数值边界 | 申请把 MTU、PersistentKeepalive、peer 数、列表长度都标为「待裁定」。审核方建议见 §2 H-2，经人类确认后写进 v2 | 待人类 |
| E5 | B reserved | 接受：没有标准来源时不支持外部输入。但它可以作为高级入口字段（核心只接受空或恰好 3 字节），是否开放随 H-2 一起裁定 | 待人类 |
| E6 | C MASQUE 认证 | **事实错误。** 申请称核心「没有 Authorization header 配置入口」，只查了 `proxy/masque`，漏了传输层。固定核心 `infra/conf/transport_method.go:806-882` 的 `MasqueConfig`（stream 的 masque 传输）有 `host/path/user/pass/headers` 字段，`user/pass` 会被构建成 `Authorization: Basic base64(user:pass)`，`user` 中不能含 `:`。所以存在**有源码依据的映射**：链接的 userinfo 对应传输层的 `user/pass`。**但现有 parser 有损**：`parse_masque`（`validate.rs:310-318`）取 password，没有 password 时才取 username，合并成一个「masque-token」，丢掉了 user 和 pass 的区分。v2 应改为：IR 分开保存 `user`、`pass`（`pass` 用 SecretRef；`user` 是否也作为秘密由申请论证，建议也用 SecretRef，因为不少服务把 token 放在 username 里）；parser 分开读取；含 `:` 的 user 拒绝。`warp` 模式（privateKey 那套）不在 P0 白名单，明确拒绝。还要注明 `masque://` 链接格式的出处（参考实现名称和版本），没有出处就按 E2 口径走高级入口 | 须修 |
| E7 | C MASQUE remoteDNS | 事实属实：`proxy/masque/client.go:77-79` 在 `remote_dns` 为空时默认用 Cloudflare 的 4 个地址。不过它的用途是**隧道内 netstack 解析目标域名**（`newTunnel`→`CreateNetTUN`，`client.go:318-330`），查询经由代理隧道发出，不经过核心 DNS 模块，也不在本机泄漏。这和 PC-04b 拒绝的「核心远端 DNS 后端」不是一回事，不应据此把 MASQUE 挂起。怎么取值见 §2 H-1 | 待人类 |
| E8 | FinalMask 部分 | 还没按前置事项裁定 §3.1 修订：R2 XMC（Rust 侧不派生 RSA，只输出 JSON，删掉「需 RSA 依赖」的阻塞项）；R3 noise `script` 不进 IR；R4 没有依据的上限不进 IR，或给出依据；R6 输入来源按 E2 口径改为高级入口。e1b0f4f 提交时间是 19:38，可能早于前置事项裁定送达，这次一起改 | 须修 |
| E9 | D 门禁 | 接受。补一条：parser 的改动（MASQUE user/pass 分离；WireGuard 的 `peer`/`peers` 处置）属于 PC-06 已结卡代码的修改，要在 v2 文件清单里列明 `crates/protocol-parser/src/validate.rs` 及对应测试，并保证 PC-06 的回归测试全部通过 | 须补 |

## 2. 请人类裁定（v2 按裁定写入，之后整体审批一次）

**H-1 MASQUE 的 remoteDNS 取值**（隧道内解析器）
- 选项 A（建议）：IR 增加 `remote_dns: Vec<IpAddr>`，可以从高级入口填写；没有填写时，配置生成**显式写出**核心默认的 4 个 Cloudflare 地址，并在节点详情里展示「隧道内 DNS：1.1.1.1 等（默认）」，不依赖核心默认值静默生效。
- 选项 B：必须由用户填写，没填就拒绝生成。最保守，但大多数 MASQUE 链接会直接用不了。
- 选项 C：P0 不支持 MASQUE。属于缩减 P0，和 11-22 的裁定冲突，不建议。

**H-2 WireGuard 数值边界**（审核方建议，依据见括号）
- MTU：可选，范围 1280～1500（1280 是 IPv6 的最小 MTU）；没填时显式写 1420（WireGuard 和核心的默认值），不依赖核心把 0 当默认值的行为。
- PersistentKeepalive：0 表示关闭，否则 1～65535 秒（wg(8) 手册规定的范围）。
- 每个节点的 peer 数 1～16；本地地址、每个 peer 的 allowedIPs 各 1～64 条；allowedIPs 必须显式填写，不默认全路由。上限是审核方为控制资源设定的，不是协议规定。
- reserved：允许从高级入口填写，空或恰好 3 字节。

## 3. 对 copilot 的要求

按 E2、E3、E6、E8、E9 修订，并写入人类对 H-1、H-2 的裁定，出 v2（可以另起文件，也可以在原文件追加「v2 修订」节，并标明替代哪些段落）。v2 获批前，core-ir 和 parser 都不改；PC-07 的其余部分照常推进。


## 附：人类裁定（2026-11-23）

- H-2（19:49）：按建议。MTU 1280～1500，缺省显式写 1420；keepalive 0 或 1～65535 秒；peer 1～16；本地地址与 allowedIPs 各 1～64 条，必须显式；reserved 走高级入口，为空或正好 3 字节。
- H-1（19:52）：选 A。remoteDNS 允许在高级入口填写；未填时生成配置显式写出固定核心默认值 1.1.1.1、1.0.0.1、2606:4700:4700::1111、2606:4700:4700::1001（出处 proxy/masque/client.go:77-79，核心 676eaf6），节点详情显示「默认：Cloudflare」。附加条件：只接受 IP、最多 8 个；服务端分配地址族与 DNS 地址族无一匹配时（client.go:318-330）在节点详情提示「域名解析可能失败」；默认值作为 plugin-xray 常量并注明出处，核心升级时复核。
- v2 申请须写入 H-1、H-2，并修订预审 §须修 ①～⑤，一次审批。

（本节由 workbuddy 代为登记人类裁定。）
