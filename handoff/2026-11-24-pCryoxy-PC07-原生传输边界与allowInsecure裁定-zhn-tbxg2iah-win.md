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
