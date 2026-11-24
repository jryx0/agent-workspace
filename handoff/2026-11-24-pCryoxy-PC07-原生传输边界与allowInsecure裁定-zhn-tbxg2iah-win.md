# PC-07 裁定：Hysteria2/MASQUE 原生传输边界 与 allowInsecure 生成阶段拒绝

日期：2026-11-24　裁定方：workbuddy@zhn-tbxg2iah-win~zhn-x-w　**状态：裁定建议，待人类确认**
对象：copilot 提问（PC-07 会话两次确认对话框），依据固定核心 676eaf6 实测

---

## 1. 核实结论

### 1.1 内核不消费 TCP 传输层（两处均已实测）

| 协议 | 内核读取的 stream 字段 | 是否读 ws/xhttp/httpupgrade/grpc 等 TCP 传输设置 | 位置 |
| --- | --- | --- | --- |
| hysteria | `tlsConfig`、`ProtocolSettings.(*Config)`、`SocketSettings`、`FinalMask`（真实承载点，`:122-123` 调 `DialUDP`）、`QuicParams`；并强制 `dest.Network = net.Network_UDP` | **否** | `transport/internet/hysteria/dialer.go:327-376`（强制 UDP 在 `:334`） |
| masque | `ProtocolSettings.(*masque.Config)`、TLS、`QuicParams`、`FinalMask`（含 tcp/udp/quicParams 三部分）、`SocketSettings` | **否**（注意：FinalMask/QuicParams 是真实承载点，见 §2.4.1） | `transport/internet/masque/dialer.go:34-100`、`:150-152`（h2 判定）、`:163-166`；`hub.go:92/122/168` |

配置层也不做交叉校验：`network` 只决定 `ProtocolName`（`infra/conf/transport_internet.go:82-89`），`wsSettings`/`hysteriaSettings` 等各自独立追加进 `TransportSettings`（`:204-222`），`GetTransportSettingsFor` 按名匹配（`transport/internet/config.go:62-75`）。唯一的绑定校验只给了 masque：

- `infra/conf/xray.go:406-407`：`"the masque transport can only be used by the masque outbound"`
- hysteria **没有**对应校验（`grep "only be used by the"` 仅 2 处，均为 masque）

即 `hy2://…?type=ws` 在内核侧属**可构造成功、字段静默丢弃**，与 2026-11-24 已认定的 Hysteria2 TLS 字段缺口同类。

### 1.2 PC-07 当前实现的具体缺陷

`crates/plugin-xray/src/config.rs` 的 Hysteria2 分支 `:499-522`、Masque 分支 `:483-498` 采用「先全量构建 → 覆写 `network` → 只删 `rawSettings`」的黑名单式修补。实测后果：

- `hy2://host:443?type=ws&path=/x&security=tls` 生成 `network: "hysteria"` **加** `wsSettings: {path:"/x"}`。后者是死字段，内核仍会 `Build()` 出 websocket 的 `TransportConfig`，但 `GetTransportSettingsFor("hysteria")` 永不选中它。
- 只删 `rawSettings`，`wsSettings`/`splithttpSettings`/`httpupgradeSettings`/`grpcSettings` **四个全部漏删**。
- `type=quic` 确实被拒（`config.rs:536` `removed-quic-transport`），但属巧合，并非针对原生协议设计。

### 1.3 allowInsecure 的实际后果（与传输问题性质不同）

| 输入 | 内核行为 | 位置 |
| --- | --- | --- |
| `tlsSettings.allowInsecure = true` | **硬失败**：`The feature "allowInsecure" has been removed and migrated to "pinnedPeerCertSha256"(pcs) and "verifyPeerCertByName"(vcn)` | `infra/conf/transport_security.go:362-364` → `common/errors/feature_errors.go:25-31` |
| `tlsSettings.allowInsecure = false` | 不报错；`tls.Config` proto 已无该字段，属未知键静默忽略 | `transport/internet/tls/config.pb.go` 全仓零命中 |
| `realitySettings.allowInsecure` | 字段不存在（`REALITYConfig` 无此项） | `transport_security.go:27-52` |

`allowInsecure = true` 属**硬失败而非静默丢弃**：导入成功、核心启动即失败，比 §1.1 的静默降级更严重。

PC-07 现状 `config.rs:618` **无条件**写入 `"allowInsecure": options.allow_insecure`，两档都错：

- `true` → 产物必然让核心 `run` 失败。
- `false` → 写入内核不认的键，脏产物且会被误读为「已生效」。

---

## 2. 裁定建议

### 2.1 Hysteria2 与 MASQUE 的传输（对应提问选项 1）

- **选项 2「跟随内核有效传输」不予采纳**。其语义等价于「吞掉用户写的 ws，再在矩阵里声称 effective = hysteria」，既违反已确立的「核心无承载点 → 生成阶段拒绝、不静默丢弃」口径，也会让矩阵掩盖输入与产物不一致。
- `Protocol::Hysteria2` 与 `Protocol::Masque`：要求 `node.link.transport == Transport::Native` 且 `transport_options == TransportOptions::Native`，否则返回 `BuildError::node(node, "non-native-transport")`。
- 该检查必须发生在覆写 `network` **之前**，不得先覆写再检查。
- 这两个协议**不再复用 `build_stream_settings`**，改为白名单式单独构造最小 stream：
  - Hysteria2：`network`、`security`、`tlsSettings`、`hysteriaSettings`、`finalmask`（仅 bbr 时）
  - MASQUE：`network`、`security`、`tlsSettings`、`masqueSettings`
  - 结构上不产生死字段，优于事后 `remove`。
- 支持矩阵：hysteria2/masque 的传输列固定 `native`，注明理由（内核不消费 TCP 传输层）。

### 2.2 allowInsecure（对应提问选项 1）

- `allow_insecure == true`：生成阶段拒绝，返回 `BuildError::node(node, "allow_insecure")`，错误带节点 ID 与字段名。
- `allow_insecure == false`：**不写 `"allowInsecure"` 键**。理由同 §1.3，内核 proto 已无该字段，写 `false` 属死字段，与本轮「不生成不生效字段」口径一致。
- 现状需改两处：
  - `config.rs:618` 无条件写入 → 改为条件写入（或直接删除该行）。
  - `hysteria2_tls_security_is_preserved` 中 `assert_eq!(…["allowInsecure"], false)`（`:1618-1622`）→ 改为断言该键**不存在**。
- **不**做 `allowInsecure → pinnedPeerCertSha256 / verifyPeerCertByName` 的静默转换。核心只给了迁移方向，具体 pin 值来自实际证书，桥侧无从推导，伪造即为错。

### 2.3 跨卡与矩阵标注

- `crates/protocol-parser` 属 PC-06 已合并代码（`validate.rs` 最近提交为 `c36a26f`/`319fdaf`），本卡**不动**。
- 但支持矩阵必须如实记录以下「导入成功、启动失败/降级」组合，不得留给下一轮当漏网：
  - `hy2://…?type=ws|xhttp|httpupgrade|grpc`：导入接受，生成阶段拒绝
  - `hy2://…?insecure=1`、`vless`/`trojan` 的 `allowInsecure=1`：导入接受，生成阶段拒绝
  - `masque://` 链接：整体被拒（`validate.rs:124` `advanced-entry`），仅高级入口可配置

### 2.4 MASQUE 三题裁定（2026-11-24 16:15 人类拍板）

本节取代此前 §2.4「path 恒为 null」的待确认项。**该判断已被 PC-07 纠正，审核方承认有误**：当时只看了链接解析路径（`validate.rs:803-809` 禁止非 XHttp/Ws/HttpUpgrade 带 `path`），忽略了 IR 可由高级入口手工构造，故 `path_or_service_name` 并非恒为 `None`。

#### 2.4.1 审核方前一轮的两处事实错误（须登记，避免继续传播）

| 上一轮说法 | 实际 | 纠正依据 |
| --- | --- | --- |
| 「masque 不读 `QuicParams`/`FinalMask`/`SocketSettings`」 | **错**。只查了 `proxy/masque/`，漏掉传输层 | `transport/internet/masque/dialer.go:52-73` 读 `QuicParams`；`:84-92`（QUIC 分支）与 `:163-166`（h2 分支）读 `FinalMask`；`hub.go:92/122/168` 同理 |
| 「hysteria 不读 `FinalMask`」 | **错** | `transport/internet/hysteria/dialer.go:37` 存字段、`:122-123` 调 `c.finalMask.DialUDP` |

`FinalMask` 在 hysteria 与 masque 两侧**都是真实承载点**，不得以「内核不读」为由拒绝。下述裁剪是**产品范围决策**，不是内核能力判断。

#### 2.4.2 path：保留手工 IR 传递（人类选 1）

- MASQUE 的 `path` 是真实承载点：`infra/conf/transport_method.go:816-900` 的 `Build()` 读它，缺省回落 `DefaultPath = "/.well-known/masque/ip/*/*/"`（`transport/internet/masque/config.go:12`）；warp 模式缺省 `WarpPath = "/"`（`warp.go:17`）。
- **允许非空 path**，但须校验：以 `/` 开头、仅 ASCII 可见字符、长度 1..=2048、不含 `#`；不满足返回 `BuildError::node(node, "masque-path")`。理由：该值直接拼进 HTTP/3 请求路径，不可信输入不得透传。
- path 为**空**时，生成 JSON **不写 `path` 键**，由核心回落 `DefaultPath`；桥侧**不硬编码** `/.well-known/masque/ip/*/*/`，避免核心升级后漂移。
- 矩阵注明：masque 的 path 仅高级入口可达（链接入口整体拒绝，`validate.rs:124`），显示时标注「默认：`/.well-known/masque/ip/*/*/`」。

#### 2.4.3 FinalMask：P0 一律不输出（人类选 1，明确为裁剪）

- **P0 范围决策**：`Protocol::Masque` 节点携带**非空** `final_mask` 时，生成阶段明确拒绝，返回 `BuildError::node(node, "masque-finalmask-unsupported")`；`final_mask` 为 `None` 或空数组时正常生成，产物**不出现 `finalmask` 键**。
- **拒绝理由必须写对**：P0 不做 h2 分支判断（`transport/internet/masque/dialer.go:150-152` 的 `usesHTTP2`），tcp mask 是否被调用取决于 `tlsSettings.alpn` 是否含 `h2` 且不含 `h3`，该判断本轮**不做**。因此无法保证 tcp mask 生效，按「核心无确定承载点即生成阶段拒绝」口径整体裁剪。
- **矩阵必须如实标注为 P0 裁剪**，字面写「P0 裁剪：内核支持，本版不开放」，**不得**写成「MASQUE 不支持 finalmask」或「内核不消费」。这一条是硬要求：矩阵若读起来像内核限制，下一轮会被当事实引用。
- 未开放的子能力逐项列清（便于后续解禁）：
  - `quicParams`：MASQUE 的 QUIC 调参承载点（`dialer.go:52-73` 直接读），与 Hysteria2 的 bbr 同一机制 —— P0 不开放。
  - udp masks（`UdpNoise`/`UdpMkcpAes128Gcm`/`UdpMkcpHeader`/`UdpMkcpOriginal`/`UdpSalamander`/`UdpSalamanderGecko`/`UdpSudoku`）：对应 `dialer.go:84-92` 的 `DialUDP` 与 `hub.go:122` 的 `ListenPacket` —— P0 不开放。
  - tcp masks（`TcpFragment`/`TcpSudoku`/`TcpXmc`）：仅 h2 分支（`dialer.go:163-166`）可达，依赖 `usesHTTP2` 判断 —— P0 不做该判断，故不开放。
- **Hysteria2 不受本条影响**：其 `final_mask` 按既有 FinalMask 裁定正常生成（`dialer.go:122-123` 为真实承载点）。
- 解禁条件（写入矩阵备注）：待 h2 分支判断落地，或人类另行批准 MASQUE 的 quicParams + udp mask 子集。

#### 2.4.4 安全选项：仅 TLS（人类选 1）

- masque 仅允许 `Security::Tls`（含 `SecurityOptions::Tls`）。`None` 与 `Reality` 均拒绝。
- **拒绝理由须区分两层，不得混用文案**：
  - `None`：`proxy/masque/client.go:66-68` 返回 `MASQUE requires "security": "tls"`，属 masque 层显式失败 → 错误码 `masque-none-security`。
  - `Reality`：配置层先抛错 —— `infra/conf/transport_internet.go:117-120` 要求 reality 的 `ProtocolName` 为 `tcp`/`splithttp`/`grpc`，`masque` 不在其中，报 `REALITY only supports RAW, XHTTP and gRPC`，属传输安全段失败，**不是** masque 段 → 错误码 `masque-reality-unsupported`，不得复用 `masque requires tls` 文案（失真）。
- `tlsSettings` 有 `sni` 时必须写 `serverName`。
- MASQUE 强制 TLS，故 `allow_insecure = false` 时同样**不写** `allowInsecure` 键，与 §2.2 一致。

### 2.5 执行偏差登记：`b8018bf` 越界修改根 `.gitignore`

**事实**：PC-07 分支现有 6 个提交（此前记录为 5 个），新增第 6 个 `b8018bf`（`[PC-07] chore: ignore nested Rust build artifacts`，2026-11-24 14:58，父 `aa7e7bc`）在根 `.gitignore` 追加 `**/target/`。

**与既有裁定的冲突**：`handoff/2026-11-24-pCryoxy-PC04c与PC07-提示词与PC07缺口认定-zhn-tbxg2iah-win.md` §5.2 **A-6 明确规定「PC-07 与 PC-04c 都不动根 `.gitignore`」**，该文件由合并方以独立 chore 提交（A-5）。`b8018bf` 直接违反 A-6。

**后果评估**：

- 内容本身与 A-5 拟提交的一致（同为 `**/target/`），不产生错误规则。
- 但两卡同时改同一根文件的冲突风险因此实际发生：若合并方随后执行 A-5 的独立 chore，会遇到冲突或重复。
- 提交信息标注 `[PC-07]`，等于把仓库级忽略规则记到了单卡名下，与 A-5「提交信息注明非某卡产物」相反。

**处理建议（待人类决定，二选一）**：

- **方案甲（建议）**：保留 `b8018bf` 的改动，撤回 A-5 的独立 chore，在合并该分支时把这条提交单独 cherry-pick 到 main 并改写提交信息为「仓库忽略规则补齐，非某卡产物」，PC-07 分支内不再保留该提交。
- **方案乙**：要求 PC-07 `git revert b8018bf`（不 rebase，避免重写已审历史），恢复根 `.gitignore`，后续按 A-5 由合并方提交。

无论选哪个，**本次裁定不因此阻断**：`b8018bf` 属 chore，与本轮传输/allowInsecure 代码无关，可独立处理。

---

## 3. 验收要求

- 每例断言生成 JSON 的**键集合**，不得只断言 `run -test` 通过：
  - 正向：`network == "hysteria"`（或 `"masque"`）时，`streamSettings` 只含 §2.1 白名单键，`wsSettings`/`splithttpSettings`/`httpupgradeSettings`/`grpcSettings` 均不存在。
  - 负向：`type=ws|xhttp|httpupgrade|grpc` 四例均返回 `non-native-transport`，错误含节点 ID。
  - `allow_insecure`：`true` 被拒并带节点 ID 与字段名；`false` 时 `tlsSettings` 中无 `allowInsecure` 键（`assert!(tls.get("allowInsecure").is_none())`，不得写 `assert_eq!(…, false)`）。
- **MASQUE 专项四例**（§2.4）：
  - path 合法：`"/pc07/x"` → `masqueSettings.path == "/pc07/x"`，且 `masqueSettings` 不含其他键。
  - path 非法：`"pc07"`（不以 `/` 开头）、`"/a#b"`（含 `#`）、超 2048 → 均返回 `masque-path` 且带节点 ID。
  - path 为空：`masqueSettings` 中**无 `path` 键**（不是 `path: null`）。
  - final_mask 非空（任一 `FinalMaskOption`，例 `TcpFragment`、`UdpNoise`）→ 返回 `masque-finalmask-unsupported` 且带节点 ID；`final_mask == None` 或空 vec → 产物中**无 `finalmask` 键**。
  - security：`None` → `masque-none-security`；`Reality` → `masque-reality-unsupported`。**两例断言错误码不同**，不得混用文案。
- **Hysteria2 `final_mask` 回归**：非空 `final_mask` 仍正常生成（`dialer.go:122-123` 是真实承载点），产物含 `finalmask` 键。此例用于证明 §2.4.3 的裁剪**只作用于 masque**，未误伤 hysteria。
- 交付报告须区分「构造通过」与「字段已生效」，沿用 2026-11-24 WebSocket early data 裁定 §2.3 口径。
- 矩阵交付时须能被逐格核对：每格必须给出六种标注之一（支持／拒绝／P0 裁剪／待 PC-04c／不适用／未验证），**MASQUE 的 finalmask 格必须是「P0 裁剪：内核支持，本版不开放」**，不得写「不支持」。

---

## 4. 未决与边界

- `b8018bf` 越界修改根 `.gitignore`（§2.5）待人类选甲/乙 —— **本轮未决，不阻断**。
- MASQUE `finalmask` 的解禁（§2.4.3）：待 h2 分支判断（`dialer.go:150-152` `usesHTTP2`）落地，或人类单独批准 quicParams + udp mask 子集。**P0 不开放不等于永不开**。
- `xmax`/`xmux` 其余字段、`pinnedPeerCertSha256`/`verifyPeerCertByName` 的真实映射、证书固定整体方案，均不在本次范围。
- 若后续需要「不安全 TLS」能力，须走证书固定（pcs/vcn），不得在桥或 IR 侧恢复 `allowInsecure`。
- PC-07 结卡仍等 PC-04c done，本条不改变该依赖。

---

## 5. 人类确认记录

- **2026-11-24 15:22**：人类就 `allowInsecure` 出示确认对话框，勾选「批准在生成阶段明确拒绝」。本文 §2.2 据此拟定并生效。
- **2026-11-24 16:15**：人类就 MASQUE 三题拍板，答复原文「选 1，h2 分支判断先别做，P0 裁剪写进矩阵」。据此确定：
  - §2.4.2 path：保留手工 IR 传递，允许非空 + 格式校验。
  - §2.4.3 FinalMask：P0 一律不输出，矩阵标注为「P0 裁剪：内核支持，本版不开放」。
  - §2.4.4 security：仅 TLS，None/Reality 拒绝且两码区分。
  - **明确不做** h2 分支判断（`usesHTTP2`），故 tcp mask 可达性不判，整体裁剪。
- **2026-11-24 16:15 同时确认**：§2.1 传输白名单构造、§2.2 allowInsecure 双档处置、§2.3 矩阵标注（含 `b8018bf` 登记）按原文生效。
- 本文件自此刻起为**生效裁定**，不再是建议稿。审核方保留对 §2.5 `b8018bf` 两项处置方案的待定态度，但不影响其余条款生效。

---

## 6. 审核方纠错登记（自我披露）

本节独立成章，便于后续引用时不被漏读。

| 序号 | 我此前的错误 | 正确事实 | 影响 |
| --- | --- | --- | --- |
| E-1 | 称「masque 不读 `QuicParams`/`FinalMask`/`SocketSettings`」 | 只查了 `proxy/masque/`，漏了 `transport/internet/masque/`。`dialer.go:52-73` 读 `QuicParams`；`:84-92`、`:163-166` 读 `FinalMask`；`hub.go:92/122/168` 同理 | 若按错误结论裁「内核不读故可拒」，会把「P0 产品裁剪」误标成「内核限制」，矩阵失真 |
| E-2 | 称「hysteria 不读 `FinalMask`」 | `transport/internet/hysteria/dialer.go:37` 存字段、`:122-123` 调 `c.finalMask.DialUDP` | 同上 |
| E-3 | §2.4 曾判「`masqueSettings.path` 恒为 null」 | 只看了链接解析路径（`validate.rs:803-809`），忽略 IR 可经高级入口手工构造 | PC-07 已纠正；本文 §2.4.2 已改为「保留，允许非空 + 校验」 |

纠错方法沉淀：查「内核是否消费某字段」时，必须同时看 `proxy/<proto>/`（业务层）与 `transport/internet/<proto>/`（传输层），只查一侧即会误判。E-1/E-2 均为只查业务层所致。


---

## 7. 第二轮核查：2ec1611 与 d4e4f03（2026-11-24 17:10）

### 7.1 结论

**结论：主体合规，四处偏差需修正提交。** 两个提交时间 2026-11-24 16:29，早于裁定生效后 9 分钟，属 PC-07 主动跟进，非裁定传达后执行。

### 7.2 合规项（已核对，无需改动）

| 裁定条款 | 实现位置 | 判定 |
|---|---|---|
| §2.1 native 强制，且在覆写 `network` 之前 | `config.rs:329-336`，位于 `let settings = match`（`:338`）之前 | 通过 |
| §2.1 白名单构造，不复用 `build_stream_settings` | masque `:522-535`、hysteria `:537-557` 均改为 `json!({ "network": ... })` + `build_security_settings` | 通过 |
| §2.2 `allow_insecure == true` 生成阶段拒绝 | `validate_tls_security` `:692-698`，码 `allow_insecure` | 通过 |
| §2.2 `allow_insecure == false` 不写键 | `:662` 改为 `let mut settings = json!({});` | 通过 |
| §2.2 测试改断言键不存在 | `:1679-1687` 用 `.get("allowInsecure").is_none()` | 通过 |
| §2.4.4 None/Reality 分两码 | `masque-none-security` / `masque-reality-unsupported`，`:454-459` | 通过 |
| §2.4.2 path 格式校验 | `:469-479`：`/` 开头、`0x21..=0x7e`、`!= b'#'`、`len > 2048` | 通过 |
| §2.4.2 path 为空省略键 | `:528-532` 仅非空时写 `path` | 通过 |
| §2.4.3 masque 非空 final_mask 拒绝 | `:461-470`，`is_some_and(|m| !m.is_empty())` | 通过（码名见偏差 3） |
| §3 键集合断言 | `native_protocol_streams_have_only_allowed_keys` `:1690-1717`，hysteria/masque 各一组期望集合 | 通过 |
| §3 非 native 四例拒绝 | `native_protocols_reject_non_native_transport_options` `:1719-1757`，含 `Native + Raw` 组合 | 通过 |

### 7.3 四处偏差（须修正提交）

#### 偏差 1（必改）：矩阵写入裁定明令禁止的错误理由

`crates/plugin-xray/tests/matrix.md:18-19`：

> 两种 native 协议必须为 `Native`（含 transport options），其他传输在生成时拒绝，
> **因核心实际使用原生传输而不读取其他传输设置。**

问题：「不读取其他传输设置」在语义上等于「内核不消费传输设置」，正是 `2026-11-24-pCryoxy-PC07-原生传输边界与allowInsecure裁定` §2.4.3 明确禁止的表述（原文：「**不得**写成『MASQUE 不支持 finalmask』或『内核不消费』」）。且与本裁定 §2.4.1 自相矛盾——已认定 `FinalMask`/`QuicParams` 是真实承载点。

根因：`FinalMask`/`QuicParams` 走 `finalmask` 对象，不走 `TransportSettings`，两者是不同的消费路径。表述必须区分：

- hysteria/masque **不消费** `TransportSettings` 里的 tcp 传输块（ws/xhttp/httpupgrade/grpc）→ 这是强制 `Native` 的依据。
- hysteria/masque **消费** `finalmask`（含 `FinalMask` 与 `quicParams`）→ 这是 §2.4.3 只能作 P0 裁剪、不能声称内核不支持的原因。

#### 偏差 2（必改）：矩阵缺失 P0 裁剪标注

`grep -c "P0 裁剪"` = **0**。§2.4.3 要求字面写「P0 裁剪：内核支持，本版不开放」。现矩阵仅 `:118` 写「MASQUE 非空 FinalMask 明确拒绝」，读起来像内核限制，与本裁定要防的误读完全一致。

#### 偏差 3（必改）：错误码与裁定不一致

裁定 §2.4.3 写死 `masque-finalmask-unsupported`，实现为 `masque-finalmask`（`config.rs:467` 与测试 `:1837`）。虽语义无误，但码名是对外契约，须一致。

#### 偏差 4（必改）：缺 §3 要求的 Hysteria2 final_mask 回归测试

裁定 §3 原文要求：「Hysteria2 `final_mask` 回归：非空 `final_mask` 仍正常生成（`dialer.go:122-123` 是真实承载点），产物含 `finalmask` 键。此例用于证明 §2.4.3 的裁剪**只作用于 masque**，未误伤 hysteria。」

现状：`build_final_masks` 只有隔离单测（`:1618`、`:1624` 直接调用，不经 `build_node_outbound`），**无任何测试断言 hysteria 的 `final_mask` 进入生成 JSON**。`grep "final_mask"` 全文件 `:544`/`:647` 两处调用点均无测试覆盖。

为何必补：`final_mask` 处理在改动后出现**两处重复逻辑**（`:544` hysteria 分支内联、`:647` `build_stream_settings` 内），删错或漏改一处即静默丢失 hysteria 的 mask，现有测试全绿也发现不了。

### 7.4 可接受差异（不要求改，但须在矩阵注明）

`config.rs:544` 对 `Some(vec![])`（空数组）会写 `{"tcp":[],"udp":[]}`，裁定原文是「`None` 或空数组时产物不出现 `finalmask` 键」。空数组不产生死字段（核心 `transport/internet/memory_settings.go:57` 判断 `len(s.Tcpmasks) != 0 || len(s.Udpmasks) != 0`，空数组等价未设），故**接受**。矩阵须补一句说明，避免下轮误判为与裁定不符。

### 7.5 证据核实

- `native-win-workspace-tests.log`：plugin-xray lib `33 passed`、`9 ignored`（interop）；workspace 各包全绿。
- `local-interop-final.log`：9 项全 `ok`，含 `hysteria2_tls_with_fixture_trust_override`。
- 日志非空、含编译与逐测试输出，非伪造。
- 实地复跑受阻：本机 `~/.cargo/registry/cache` 无 `prost`，`--offline` 解析失败，无法独立复验。**本项作为已知限制登记**，不代表信任日志，而是本轮无法二次取证。

- `local_interop.rs:324` 显式写 `useSystemCA=true` 并注释为夹具覆盖，`matrix.md` 亦声明「这不是原始生成配置，不能填成 H 格通过」。**做法正确**，符合「不得用夹具掩盖缺口」口径。

---

### 7.6 给 PC-07 的修正提示词（可直接粘贴）

> PC-07：`2ec1611` 与 `d4e4f03` 已审，主体合规（native 强制与时机、白名单构造、allowInsecure 双档、path 校验、两码区分、键集合断言均通过）。需一个修正提交，四项，均在 `crates/plugin-xray/` 内：
>
> **1. 矩阵理由句改错（必修，优先级最高）**
> `tests/matrix.md:18-19` 现写「因核心实际使用原生传输而不读取其他传输设置」，这句是裁定明令禁止的表述。改为：
>
> ```
> hysteria2 与 MASQUE 强制传输为 native（含 transport options），依据是核心不消费
> TransportSettings 中的 tcp 传输块（ws/xhttp/httpupgrade/grpc）：
> transport/internet/hysteria/dialer.go:327-376 强制 dest.Network=UDP，
> transport/internet/masque/dialer.go:43 同样强制 UDP。
> 注意区分：finalmask 对象（FinalMask 与 quicParams）是两者的真实承载点
> （hysteria dialer.go:122-123；masque dialer.go:52-73、:84-92、:163-166 与
> hub.go:92/122/168），走 finalmask 而非 TransportSettings，见下条 P0 裁剪说明。
> 不得表述为「核心不读传输设置」。
> ```
>
> **2. 矩阵补 P0 裁剪标注（必修）**
> 在「输入与限制」段 MASQUE 条目前增补，并给矩阵表加图例：
>
> ```
> - MASQUE FinalMask：**P0 裁剪 —— 内核支持，本版不开放**。
>   内核在 transport/internet/masque/dialer.go:52-73 读 quicParams、:84-92 读
>   FinalMask.DialUDP、:163-166（h2 分支）读 DialTCP，hub.go:92/122/168 服务端同理，
>   均为真实承载点。P0 不做 usesHTTP2（:150-152）分支判断，无法确定 tcp mask 是否
>   可达，故整体裁剪。未开放子项：quicParams、udp masks（UdpNoise /
>   UdpMkcpAes128Gcm / UdpMkcpHeader / UdpMkcpOriginal / UdpSalamander /
>   UdpSalamanderGecko / UdpSudoku）、tcp masks（TcpFragment / TcpSudoku / TcpXmc）。
>   解禁条件：h2 分支判断落地，或人类单独批准 quicParams + udp mask 子集。
> ```
> 表内 MASQUE 的 finalmask 相关格用「P0 裁剪」，**不得**用「不支持」或「内核不消费」。
>
> **3. 错误码统一（必修）**
> `masque-finalmask` → `masque-finalmask-unsupported`，改 `src/config.rs:467` 与测试 `:1837` 两处。裁定 §2.4.3 写死了该码名，对外契约须一致。
>
> **4. 补 Hysteria2 final_mask 回归测试（必修）**
> 新增：
>
> ```rust
> #[test]
> fn hysteria2_final_mask_is_preserved() {
>     // 证明 §2.4.3 的 masque 裁剪未误伤 hysteria
>     let mut node = hysteria_node(CongestionControl::Bbr, None);
>     node.link.final_mask = Some(vec![FinalMaskOption::TcpFragment {
>         packets: FragmentPackets::TlsHello,
>         length: MaskRange { from: 1, to: 3 },
>         delay: MaskRange { from: 0, to: 1 },
>         max_split: MaskRange { from: 1, to: 2 },
>     }]);
>     let outbound = build_node_outbound(&node, &DummySecrets).unwrap();
>     let tcp = outbound["streamSettings"]["finalmask"]["tcp"]
>         .as_array()
>         .expect("hysteria must emit finalmask.tcp");
>     assert_eq!(tcp.len(), 1);
> }
> ```
> 参数按 `FinalMaskOption::TcpFragment` 实际字段与既有 `build_final_masks` 校验规则填，若范围被拒则改用能通过的合法值。理由：改动后 `final_mask` 处理在 `config.rs:544`（hysteria 分支内联）与 `:647`（`build_stream_settings` 内）出现两处重复逻辑，删错一处即静默丢失 hysteria 的 mask，现有测试全绿也发现不了。`build_final_masks` 现只有隔离单测（`:1618`/`:1624`），不经 `build_node_outbound`。
>
> **5. 空 final_mask 说明（必写，不必改代码）**
> `config.rs:544` 对 `Some(vec![])` 会写 `{"tcp":[],"udp":[]}`，与裁定「空数组时不出现 `finalmask` 键」不同。空数组不产生死字段（核心 `transport/internet/memory_settings.go:57` 按 `len != 0` 判断），故接受。在矩阵注明该差异即可，不要求改代码。
>
> **约束**：只碰 `crates/plugin-xray/src|tests`；不动根 `.gitignore`；`b8018bf` 由人类另行决定处置，本提交不得基于它做任何调整；每提交跑 `cargo fmt --all --check`、`cargo clippy --workspace --all-targets --locked --offline -- -D warnings`、`cargo test --workspace --locked --offline` 并留日志；分支仍须推送。
>
> **不需重做的**：native 强制时机、白名单构造、allowInsecure 双档、path 校验、两码区分、键集合断言均已通过，勿改动。

---

---

## 8. `b8018bf` 处置：人类选甲（2026-11-24 17:21）

### 8.1 裁定

人类 17:21 答复「b8018bf 甲」，即：**保留该提交的改动内容，撤回 A-5 的独立 chore，由合并方（workbuddy）在 main 上以正确提交信息承载该改动，PC-07 分支内不再保留该提交。**

选择理由（登记人类口径）：内容本身正确（同为 `**/target/`），甲方案不重写已审历史，只需在合并时多一次 cherry-pick 等价操作。

### 8.2 执行结果

| 项 | 结果 |
|---|---|
| main 提交 | `4066e0d1d254efb638b60d740a342652ea55112c`，`chore: 仓库忽略规则补齐，非某卡产物` |
| 提交作者 | `workbuddy <workbuddy@zhn-tbxg2iah-win>`，**不归属任何单卡**（符合 A-5） |
| 改动 | 根 `.gitignore` 第 2 行追加 `**/target/`，`+1 -0`，无行尾空格（`cat -A` 复核为 `**/target/$`） |
| 推送 | 已推 origin/main，本地与远程均为 `4066e0d`（`git ls-remote` 实测一致） |
| 忽略生效验证 | `git check-ignore -v crates/secure-store/target/pc03-native-fixture.lock` → `.gitignore:2:**/target/` 命中；`crates/foo/target/x` 同样命中 |
| 已跟踪文件安全 | `git ls-files \| grep "/target/"` = 0，加规则不漏已跟踪文件 |

### 8.3 对 PC-07 的后续影响（须写入其修正提示词）

- **PC-07 不再需要、也不得再保留 `b8018bf`**。合并 `agent/copilot/pc07` 时，**必须跳过（drop）该提交**，否则与 main 的 `4066e0d` 冲突并重复。
- 若 PC-07 使用的合并方式会产生冲突，按以下顺序处理：先 `git rebase --onto aa7e7bc b8018bf agent/copilot/pc07`（把 `2ec1611`、`d4e4f03` 及后续重接到 `aa7e7bc` 之后），再由合并方合入 main。**不得用 revert**（甲方案不采用乙）。
- PC-07 的工作树中 `crates/secure-store/target/` 目录保持原样，不提交不删除（A-6 不变）。
- 因 main 已有 `4066e0d`，PC-07 后续 rebase 到最新 main 时该行会自然存在，**不需要也不得再次添加**。

---

## 9. 登记项

- 第二轮核查结论见 §7；§7.6 附「给 PC-07 的修正提示词」，可直接粘贴。
- `b8018bf` 处置见 §8，人类选甲，已于 `4066e0d` 落 main 并推送。
- 已知限制：审核方本机无 cargo 离线缓存（`~/.cargo/registry/cache` 无 `prost`，`--offline` 解析失败），§7.5 无法独立复跑测试，仅核对 PC-07 留存日志（`~/.agent-tools/run/pc07/logs/native-*`、`local-interop-final.log`）。**这是本轮取证的唯一缺口，不代表采信日志内容。**

---

## 10. 第三轮核查：`75ac242` / `dfe6e0e`（2026-11-24 18:20）

### 10.1 结论

**四项必改全部修正到位，本轮判通过。** 另查出一处新偏差（矩阵测试数未随新增测试更新，`106` 应为 `107`），属文档笔误，不阻断通过，但须在下一提交修正，否则矩阵与实测不符。

### 10.2 提交同一性

| 项 | 值 |
|---|---|
| PC-07 报告提交 | `75ac2428bc63d3523bbeb2ad7424dcbc51c4c37d` |
| 当前 HEAD | `dfe6e0ea799a126bf494f698fc56a2fd89edcd73` |
| 关系 | `reflog` 实测 `rebase (start): checkout aa7e7bc` → `75ac242` 为 rebase 前提交，`dfe6e0e` 为 rebase 后重放 |
| 差异 | `git diff 75ac242 dfe6e0e --stat` 仅 `.gitignore \| 1 -`，即 `b8018bf` 的 `**/target/` 行被 drop，**其余内容逐字节相同** |
| `b8018bf` 状态 | 已 drop（`git merge-base --is-ancestor b8018bf HEAD` 返回非零） |

**判定**：PC-07 严格执行了 §8.3 的 `git rebase --onto aa7e7bc b8018bf`，未用 revert。甲方案落地正确。

### 10.3 四项偏差修正核对

| 偏差 | 要求 | 实测 | 结论 |
|---|---|---|---|
| 1 矩阵理由句 | 区分 `TransportSettings` 与 `finalmask` 两条消费路径，禁写「内核不消费」 | `matrix.md:18-23` 已改为「不消费 `TransportSettings` 中的 tcp 传输块……`finalmask` 对象是真实承载点」，并列出 hysteria `dialer.go:327-376`/`masque dialer.go:43`（不消费传输块）与 `dialer.go:122-123`/`52-73,84-92,163-166`/`hub.go:92,122,168`（消费 finalmask） | **通过**，两路径表述清晰，未再出现禁止语 |
| 2 P0 裁剪标注 | 字面写「P0 裁剪：内核支持，本版不开放」 | `grep -c "P0 裁剪"` = **4**（`:24`、`:116`、`:135`、`:149`），`:116` 含完整未开放子能力清单与解禁条件 | **通过** |
| 3 错误码一致 | `masque-finalmask-unsupported` | `config.rs:467` 与测试 `:1854` 已统一；另新增 `:1857-1860` 断言 `error.to_string() == "node 9: unsupported field masque-finalmask-unsupported"`，把码名纳入对外契约回归 | **通过**（强于要求） |
| 4 Hysteria2 回归测试 | 断言 `final_mask` 进入生成 JSON | `config.rs:1656-1673` 新增 `hysteria2_final_mask_is_preserved`，经 `build_node_outbound` 断言 `finalmask.tcp[0]["type"] == "fragment"` | **通过** |

### 10.4 新增偏差（第五处，非阻断）

`matrix.md:168`：

> 测试为 **106** passed、0 failed、13 ignored

实测 `correction-win-test.log` 汇总 16 个 target，`passed` 合计 **107**、`failed=0`、`ignored=13`。上一轮 `native-win-workspace-tests.log` 为 106，本轮 `dfe6e0e` 新增 `hysteria2_final_mask_is_preserved` 后应为 107。**矩阵未同步更新，与自身「本轮验证」段落声称的实测冲突。**

为何必须改：矩阵是结卡与合并方复核的唯一口径来源，测试计数错误会让后续核查失去基准（例如新增测试被静默跳过时无法察觉）。要求下一提交把 `106` 改为 `107`，并说明新增的是 `hysteria2_final_mask_is_preserved`。

### 10.5 独立取证

| 项 | 我的实测 | 与 PC-07 报告 |
|---|---|---|
| `cargo fmt --all --check` | 日志 `exit=0` | 一致 |
| `cargo clippy --workspace --all-targets --locked --offline -- -D warnings` | `correction-win-clippy-verified.log` 尾部 `Finished dev profile ... in 2.03s`，无 warning | 一致 |
| `cargo test --workspace --locked --offline` | 107 passed / 0 failed / 13 ignored（逐 target 累加，16 行 `test result` 全 ok） | 一致（矩阵文本 106 有误） |
| Gitleaks | **我独立跑 `gitleaks git --log-opts="c3acc73..HEAD"` → 8 commits scanned、174.56 KB、no leaks found** | 一致（但见 10.6） |

### 10.6 两处方法问题（须纠正，不影响结论正确性）

**（1）Gitleaks 范围口径不足。** PC-07 日志 `correction-gitleaks.log` 内容为 `0 commits scanned`、`scanned ~2753 bytes`——只扫了工作区未扫提交历史，覆盖不到任何提交。结论「no leaks」虽与我的独立复跑一致，但**其自身证据不成立**。要求：Gitleaks 必须带 `--log-opts` 指定提交区间，日志首行须显示 `N commits scanned` 且 `N` 等于待审提交数；`0 commits scanned` 视为未取证。

**（2）Clippy 首次触发的 Rustup 自动安装未清理。** `correction-win-clippy.log` 首行：

```
info: syncing channel updates for 1.100.0-x86_64-pc-windows-msvc
warn: the missing active toolchain `1.100.0-x86_64-pc-windows-msvc` has been auto-installed
```

即工具链路径误写触发 `~/.agent-tools/rust/` 下约 **926M** 自动安装。PC-07 已如实披露「误安装目录未删除」，**披露正确**。该目录属个人目录非项目产物，按安全规则我只登记不代为删除，待人类决定。

### 10.7 本机复跑限制（沿用 §7.5）

审核方本机 `target/` 目录出现 `os error 5`（文件 `zerovec`/`zerofrom` 指纹写入被拒），已尝试：PC-07 的 `CARGO_HOME`、`RUSTUP_AUTO_INSTALL=0`、独立 `CARGO_TARGET_DIR`（被安全策略拦截），**均失败**。故 §10.5 的 fmt/clippy/test 三项为核对 PC-07 留存日志，非我独立执行；**Gitleaks 一项为我的独立复跑**。这是本轮取证的唯一缺口。

### 10.8 给 PC-07 的收尾提示词（可直接粘贴）

> PC-07：`dfe6e0e`（原 `75ac242`）四项偏差已全部核对通过，`b8018bf` 已按甲方案正确 drop，本轮判通过。
>
> 剩两件事，一个提交即可：
>
> **1. 矩阵测试数改 107（必改）**
> `crates/plugin-xray/tests/matrix.md:168` 的 `106 passed` 改为 `107 passed`，并在同段补一句「本轮新增 `hysteria2_final_mask_is_preserved`」。实测 `correction-win-test.log` 16 个 target 累加为 107 passed / 0 failed / 13 ignored，上一轮为 106，差值即该新增测试。矩阵与自身验证段冲突会被后续核查当作基准错误。
>
> **2. Gitleaks 范围补正（必改，重跑即可）**
> `correction-gitleaks.log` 为 `0 commits scanned`、`2753 bytes`，只扫工作区未扫提交历史，该证据本身不成立。请带 `--log-opts` 重跑：`gitleaks git --log-opts="c3acc73..HEAD"`，日志首行须为 `8 commits scanned`（我已独立复跑，结果为 8 commits / 174.56 KB / no leaks，你的结论应与我一致）。此后所有 Gitleaks 日志若显示 `0 commits scanned` 一律视为未取证。
>
> **3. 推送（必做）**
> `origin/agent/copilot/pc07` 仍不存在，8 个提交只在本地。安全策略若拦截，如实报告并说明卡点，不要反复重试；不要用 `--no-verify`。
>
> **不需改的**：native 强制时机、白名单构造、allowInsecure 双档、path 校验、两码区分、键集合断言、P0 裁剪标注（4 处）、错误码与 `to_string` 断言、`hysteria2_final_mask_is_preserved` 本身——全部通过，勿动。
>
> **约束**：只碰 `crates/plugin-xray/src|tests`；不动根 `.gitignore`（`**/target/` 已由 main `4066e0d` 承载，不得再加）；提交信息保持 `[PC-07]` 前缀；`~/.agent-tools/rust/` 926M 误安装保持原样，不删除不提交，由人类另行决定。

### 10.9 状态

- PC-07：**代码层面可判通过**，剩矩阵计数、Gitleaks 重跑、分支推送三项收尾；结卡仍等 PC-04c done。
- 审核方：本轮核查完成，无新增未决项。

---

## 11. 第四轮核查：`ed84bde` + Rustup 误安装定性（2026-11-24 19:40）

### 11.1 结论

**矩阵修正到位，本轮判通过。** 同时完成 §10.6(2) 遗留的 Rustup 误安装定性：**不是重复下载，是三份独立物理副本，其中 17:22 那份是纯属误写的第三份**。**可安全删除 926M**，但有前置条件（见 §11.3.3）。

### 11.2 `ed84bde` 核对

| 项 | 要求 | 实测 | 结论 |
|---|---|---|---|
| 改动范围 | 只改 `matrix.md` | `git show --stat` = `matrix.md \| 7 +++++--`，单文件 +5/-2 | 合规 |
| 测试计数 | `106` → `107` | `matrix.md:168` 已为 `测试为 107 passed、0 failed、13 ignored` | **通过** |
| 新增测试说明 | 说明新增的是哪一项 | 同段接 `；本轮新增 hysteria2_final_mask_is_preserved` | **通过**（超要求） |
| 日志路径 | 指向本轮验证日志 | `:184` 改为 `correction-win-{fmt,clippy-verified,test}.log`，并保留原 `native-*` 作历史 | **通过** |
| fmt | 退出 0 | `closeout-win-fmt.log` = `exit=0` | 一致 |
| Clippy | 退出 0 无 warning | `closeout-win-clippy.log` 尾部 `Finished dev profile ... in 4.27s`、`exit=0` | 一致 |
| 测试 | 107 passed / 13 ignored | `closeout-win-test.log` 14 个 target 累加 = **107 passed / 0 failed / 13 ignored** | 一致 |
| Gitleaks 提交前 | 8 commits | `closeout-gitleaks-precommit.log` = `8 commits scanned`、`174.56 KB`、`no leaks` | **口径已修正**，见 11.2.1 |
| Gitleaks 提交后 | 9 commits | `closeout-gitleaks-final.log` = `9 commits scanned`、`174.91 KB`、`no leaks` | 一致 |

#### 11.2.1 Gitleaks 口径已按 §10.6(1) 修正

上一轮是 `0 commits scanned`（只扫工作区），本轮两份日志均为 `N commits scanned` 且 `N` 与提交数吻合。**我独立复跑 `gitleaks git --log-opts="c3acc73..HEAD"` → 9 commits / 174.91 KB / no leaks found**，与 `closeout-gitleaks-final.log` 逐字节同源。§10.6(1) 的整改完成。

### 11.3 Rustup 926M 定性：**不是重复下载，是第三个独立副本**

#### 11.3.1 三份副本的物理证据

全机存在三份 `1.100.0-x86_64-pc-windows-msvc` toolchain：

| 路径 | 大小 | 文件数 | 创建时间 | 性质 |
|---|---|---|---|---|
| `~/.rustup` | 925 MB | 279 | 2026-11-19 17:56:39 | 用户全局 rustup home（**亦是残留，见 11.3.4**） |
| `~/.agent-tools/runtimes/rust/rustup` | 926 MB | 278 | 2026-11-19 15:36:58 | **项目脚本指定的正确隔离 home** |
| `~/.agent-tools/rust/rustup` | 926 MB | 278 | **2026-11-24 17:22:22** | **误写路径产生的第三份** |

**判定为独立物理副本而非硬链接的三项证据**：

1. `fsutil file queryfileid` 三份 `rustc.exe` 的 FileID 全不同：
   - `~/.rustup` → `0x...0400000016a0cf`
   - `~/.agent-tools/rust` → `0x...030000001e39e1`
   - `~/.agent-tools/runtimes/rust` → `0x...1d0000000c4f2e`
2. `fsutil hardlink list` 三份各只列出自己一条路径，链接数均为 1。
3. `Get-Item.LinkType` 三方均为空（非符号链接）。

**故磁盘上确实有 3 × 926M ≈ 2.7G 的同一 toolchain。**

#### 11.3.2 误写根因：`Join-Path` 少写一层

项目脚本 `tools/build-windows.ps1:4-5` 与 `tools/build-android.ps1:5`：

```powershell
$env:CARGO_HOME  = Join-Path $agentTools "runtimes\rust\cargo"
$env:RUSTUP_HOME = Join-Path $agentTools "runtimes\rust\rustup"   # 正确
```

**正确路径**：`$HOME/.agent-tools/runtimes/rust/rustup`
**实际路径**：`$HOME/.agent-tools/rust/rustup`

差一层 `runtimes\`。`~/.agent-tools/rust/` 顶层只有 `rustup` 一个子目录，**没有 `cargo`**——若为正常安装，两者应同级出现。这直接证明是 `RUSTUP_HOME` 被单独赋了错值（只设了 rustup 未设 cargo，故 cargo 仍走 `runtimes\rust\cargo`），而不是脚本整体指向别处。

**时间线铁证**（`correction-win-clippy.log` 首三行）：

```
info: syncing channel updates for 1.100.0-x86_64-pc-windows-msvc
info: latest update on 2026-11-12 for version 1.100.0 (0ef1bc386 2026-11-09)
info: downloading 7 components
```

| 时刻 | 事件 |
|---|---|
| 17:22:22 | `~/.agent-tools/rust/rustup` 目录创建 |
| 17:22:30 | `toolchains/1.100.0-...` 目录创建（下载开始） |
| 17:23:38 | toolchain 目录完成（**耗时 68 秒，是真实下载**） |
| 17:23:43 | 日志写入 `the missing active toolchain has been auto-installed` |

`update-hashes/1.100.0-x86_64-pc-windows-msvc` 内容 `3051e859570f64a8c5ac` 与另两份**完全一致**，即同一 manifest 版本。**68 秒的下载时长排除了本地复制或缓存命中的可能**——`downloads/` 与 `tmp/` 均为空目录，说明下载产物已被 rustup 移至 toolchains 后清空，是标准首次安装流程。

#### 11.3.3 能否删除：可删，但有一个前置条件

**结论：`~/.agent-tools/rust/` 可安全删除，回收 926M。**

理由：

- 该目录无 `settings.toml`（另两份中 `runtimes` 版有、`~/.rustup` 也无——后者的缺失本身是异常，见 11.3.4）。rustup 的 home 在正常使用后必然生成 `settings.toml`；**缺失说明它从未被当作有效 home 使用**，只在 auto-install 时被写入 toolchain 就再未触碰（`stat` 显示目录 mtime 停在 17:22-17:23，此后无变更）。
- 全仓库、`~/.agent-tools/bin/`、`~/.agent-tools/hooks/`、`~/.workbuddy/` 中**无任何引用**指向 `~/.agent-tools/rust`（`grep -rn` 排除 `runtimes` 后零命中）。
- 项目脚本指向的是 `runtimes\rust\rustup`，删除不影响 fmt/clippy/test 三项验证能力。

**前置条件（必须先做，否则重跑会再生成一份）**：确认触发 auto-install 的那次调用为何没读到 `RUSTUP_HOME`。三种可能，须 PC-07 说明实际是哪一种：

1. 直接调 `cargo` 时未先 `source` 脚本，`RUSTUP_HOME` 为空 → rustup 回落默认 `~/.rustup`，但实际写到了 `~/.agent-tools/rust`，**与假设矛盾**；
2. 某处手动写成了 `RUSTUP_HOME=$HOME/.agent-tools/rust/rustup`（少 `runtimes` 层）；
3. `PATH` 里的 `rustup` shim 自身记录了一个过期 home。

**无论哪一种，删除前必须由 PC-07 书面确认「下次运行不会再次触发」**。否则删了 926M，下轮验证又下 926M，属无效劳动。

#### 11.3.4 顺带发现：`~/.rustup` 也是 925M 残留

`~/.rustup`（2026-11-19 17:56 创建）同样**无 `settings.toml`**，且 `~/.cargo/bin/` 不存在（`which rustup` 返回 not found）。即该目录同样是一个「装了 toolchain 但从未作为有效 rustup home 使用」的残留。它与 `runtimes` 版同版本同哈希。

**但此项我不建议现在删**：`~/.rustup` 是 rustup 的编译期默认 home，删除它需要比 `~/.agent-tools/rust` 更强的确信。且它属个人目录非项目产物，按安全规则我只登记不代为删除。**建议人类在确认 `runtimes` 版可独立工作后，一并清理这两份，合计回收 1.85G。**

#### 11.3.5 我的处置边界

按 `<personal_files_safety>` 规则，`~/.agent-tools/` 与 `~/.rustup` 属个人目录非项目产物：**我只报告路径、大小、时间与判据，不代为删除**。需要清理时由人类执行，或由人类明确授权我执行。

### 11.4 分支推送：仍未完成

`git ls-remote --heads origin` 实测 `origin` 上**没有** `agent/copilot/pc07`，9 个提交（`837d620`/`a969729`/`c36a26f`/`c845bb0`/`aa7e7bc`/`af6ddcb`/`f8ac674`/`dfe6e0e`/`ed84bde`）全在本地。`main` = `4066e0d`。

PC-07 报告「安全限制阻止向 Gitee 上传项目代码」，与我的实测一致（我自己的 `git ls-remote` 也被安全策略拦截过）。**此项不判 PC-07 违规，但须作为结卡的阻断项登记**——分支不在远端，合并方无法合入，PC-07 结卡与后续验收都无从进行。

### 11.5 给 PC-07 的答复（可直接粘贴）

> PC-07：`ed84bde` 核对通过。矩阵已改 107 并说明新增项，Gitleaks 口径也已按 §10.6(1) 修正（提交前 8 commits、提交后 9 commits，均为 N commits scanned 而非 0）。我独立复跑 `gitleaks git --log-opts="c3acc73..HEAD"` 得 9 commits / 174.91 KB / no leaks，与你一致。**代码与文档层面判通过。**
>
> 关于 Rustup 926M 的定性，答复如下：
>
> **1. 不是重复下载，是第三个独立副本。** 全机有三份同版本 toolchain：`~/.rustup`（925M，11-19 17:56）、`~/.agent-tools/runtimes/rust/rustup`（926M，11-19 15:36，**项目脚本指定的正确 home**）、`~/.agent-tools/rust/rustup`（926M，**11-24 17:22 你这次误写产生**）。`fsutil file queryfileid` 三份 FileID 全不同、`fsutil hardlink list` 各只列自己一条、`LinkType` 均为空——**物理上确实是 3 份，不是硬链接**。
>
> **2. 根因是 `Join-Path` 少写了一层。** 脚本写 `Join-Path $agentTools "runtimes\rust\rustup"` 是对的，实际却落到 `$HOME/.agent-tools/rust/rustup`，差一层 `runtimes\`。旁证：`~/.agent-tools/rust/` 下**只有 `rustup` 没有 `cargo`**——正常安装两者应同级，说明只有 `RUSTUP_HOME` 被赋了错值。日志时间线也吻合：17:22:22 建目录 → 17:22:30 开始下载 → 17:23:38 完成（**68 秒**，`downloads/`、`tmp/` 已空，是真实网络下载而非本地复制）。
>
> **3. 可以删，但先回答我一个问题。** 该目录**无 `settings.toml`**（`runtimes` 版有），说明它从未被当作有效 home 使用，全仓库也无任何引用指向它，**删除安全，回收 926M**。但请先书面说明：那次调用为什么没读到 `RUSTUP_HOME`？是直接调 `cargo` 未 source 脚本、还是某处手写了 `RUSTUP_HOME=$HOME/.agent-tools/rust/rustup`、还是 `PATH` 里的 shim 记录了过期 home？**不确认就删，下轮验证会再下一份。**
>
> **4. 另外 `~/.rustup` 也是 925M 残留**，同样无 `settings.toml`、`~/.cargo/bin/` 也不存在。这份我不建议现在动（rustup 编译期默认 home），但登记在此，待你确认 `runtimes` 版可独立工作后由人类一并清理，合计可回收 1.85G。
>
> **处置边界**：`~/.agent-tools/` 与 `~/.rustup` 属个人目录，我只报告不代删，需人类授权。请不要自行 `rm -rf` 这两个目录。
>
> **剩一件事：推送。** `origin` 上仍无 `agent/copilot/pc07`，9 个提交全在本地。安全策略拦截不判你违规，但分支不在远端则合并方无法合入，**结卡与验收都无从进行**，须作为阻断项。若确实无法推送，请如实说明卡点（哪个命令、什么报错），由人类处理，不要反复重试、不要用 `--no-verify`。

### 11.6 状态

- PC-07：**代码与文档层面判通过**。阻断项仅剩分支推送（安全策略拦截，须人类处理）；Rustup 926M 待 PC-07 说明根因后清理。
- 审核方：§10 三项收尾中，矩阵计数与 Gitleaks 两项已闭合，推送项仍在。
- 结卡：仍等 PC-04c done，不变。

---

## 12. 根因确认与推送可达性（2026-11-24 19:58）

### 12.1 Rustup 误安装根因：**已确认，PC-07 说明与证据一致**

PC-07 19:50 答复：

> 确认误安装根因是我在 Clippy 命令中手写 `RUSTUP_HOME` 时漏了 `runtimes`，不是脚本或 shim 问题。后续已使用正确路径并设置 `RUSTUP_AUTO_INSTALL=0`；该条件下不会自动安装。两个目录均未删除。

**三项独立证据支持该说明，无矛盾**：

| 证据 | 实测 | 指向 |
|---|---|---|
| 旁证「只有 `rustup` 没有 `cargo`」 | `~/.agent-tools/rust/` 下仅 `rustup` 一个子目录 | 排除了「脚本整体指向别处」（那样 `cargo` 也会同级出现），**只能**是 `RUSTUP_HOME` 被单独赋了错值 |
| `~/.agent-tools/rust` 此后未被触碰 | `find ~/.agent-tools/rust -newermt "2026-11-24 17:24"` = **空**；`stat` mtime 停在 `17:22:22.728` | 该目录自误安装后再未被使用，**与「后续已用正确路径」一致** |
| `closeout-*` 三项日志无自动安装 | 三份日志中 `syncing channel\|auto-installed\|downloading` 命中 **0 次**；`closeout-win-clippy.log` 直接从 `Compiling quote` 开始 | `RUSTUP_AUTO_INSTALL=0` + 正确路径**确已生效**，未再触发下载 |

**判定**：根因定性为「手写命令时 `RUSTUP_HOME` 漏一层 `runtimes\`，单次操作失误」，**非脚本缺陷、非 shim 记录过期**。项目脚本 `tools/build-windows.ps1:4-5`、`tools/build-android.ps1:5` 的路径**本来就是正确的**，不需要修改。

**口径提醒（写入规程）**：`RUSTUP_AUTO_INSTALL=0` 的作用是「缺工具链时直接失败而非静默下载」，它不校正 `RUSTUP_HOME` 的值。因此**正确路径与禁止自动安装必须成对使用**——只设前者仍可能因路径笔误再下载一份，只设后者则命令会失败。PC-07 现在两者都设了，是本轮的正确做法。

### 12.2 两个残留目录：处置待人类授权

| 路径 | 大小 | 状态 | 建议 |
|---|---|---|---|
| `~/.agent-tools/rust/` | 926 MB | 已确认无引用、无 `settings.toml`、17:22 后未触碰 | **可删**，回收 926M |
| `~/.rustup/` | 925 MB | 同样无 `settings.toml`、`~/.cargo/bin/` 不存在 | 暂缓，先确认 `runtimes` 版可独立工作，再一并清理（合计 1.85G） |

两份均**未删除**（PC-07 已确认，我也未动）。按 `<personal_files_safety>`，个人目录我只报告不代删。**等人类明确授权。**

### 12.3 推送：`--dry-run` 实测通过，与「安全限制」的说明存在张力

PC-07 19:50 答复：

> 推送方面：我未执行 `git push`，因此没有命令报错；安全限制不允许我向 Gitee 上传项目代码。分支仍未推送，需人类处理。

**我做了 dry-run 探测（只协商 ref、不上传对象、不改远端）**：

```console
$ git push --dry-run origin agent/copilot/pc07:agent/copilot/pc07
To https://gitee.com/ParvaUltra/pCryoxy.git
 * [new branch]      agent/copilot/pc07 -> agent/copilot/pc07
```

**三项事实**：

1. **远端可达** —— 完成了与 `gitee.com` 的完整 HTTP 协商；
2. **认证有效** —— 凭据被接受，否则在 dry-run 阶段就会返回 401/403；
3. **ref 可创建** —— 输出明确为 `[new branch]`，即远端不存在同名分支、无冲突。

**这与「安全限制不允许上传」的表述存在张力**：dry-run 已走通除「写对象」以外的全部环节。可能有两种情况：

- **甲**：安全策略**只拦截实际写入**（上传 pack 文件），不拦截 dry-run 的 ref 协商。此时 PC-07 的说明成立，真实推送会被拒。
- **乙**：安全策略**已放行**，PC-07 未尝试就下了结论（他说「我未执行 `git push`」，即**没有实测过**）。

**我不断言是乙，但必须指出：PC-07 的结论没有命令输出支撑**（他自己也说「没有命令报错」）。按本项目一贯口径——**「未取证」不等于「不通」**，与矩阵里 `U` 格的判定标准一致。

**不做的事**：我不替他推。理由有三：① 分工上代码操作属其他 agent（`~/.agent-shared/global/rules.md` 三-7）；② 该分支 9 个提交的验收责任在 PC-07，越权推送会让「谁验的、谁推的」失去追溯；③ 若安全策略确实只拦写对象，我推也会被拦，属无效动作。

### 12.4 请人类裁定（三选一）

| 选项 | 动作 | 后果 |
|---|---|---|
| **甲（建议）** | 人类直接执行一次 `git push origin agent/copilot/pc07`，把真实输出（成功或拒绝原文）贴回 | 一次性定性安全策略到底拦不拦，后续所有卡都不必再猜 |
| 乙 | 人类授权我代推 | 我执行并留完整日志，但需接受「审核方同时是推送方」的追溯瑕疵 |
| 丙 | 维持现状，PC-07 结卡挂起 | 合并方无法合入，PC-07 无法结卡，PC-04c 联动阻塞 |

**建议选甲**。成本极低（一条命令），且能一次性消除「安全策略边界在哪里」这个反复消耗审查资源的不确定性——本轮已因此多花两轮沟通。

### 12.5 状态

- PC-07：**代码与文档层面判通过**；根因已闭合（§12.1）。阻断项仅剩推送，且该阻断**不在 PC-07 能力范围内**，属人类处置。
- Rustup 残留：926M + 925M 待人类授权清理。
- 结卡：仍等 PC-04c done，不变。
- 本轮无新增审核方未决项。
