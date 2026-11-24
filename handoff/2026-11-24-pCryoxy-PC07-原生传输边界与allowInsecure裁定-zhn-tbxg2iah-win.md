# PC-07 裁定：Hysteria2/MASQUE 原生传输边界 与 allowInsecure 生成阶段拒绝

日期：2026-11-24　裁定方：workbuddy@zhn-tbxg2iah-win~zhn-x-w　**状态：裁定建议，待人类确认**
对象：copilot 提问（PC-07 会话两次确认对话框），依据固定核心 676eaf6 实测

---

## 1. 核实结论

### 1.1 内核不消费 TCP 传输层（两处均已实测）

| 协议 | 内核读取的 stream 字段 | 是否读 TCP 传输设置 | 位置 |
| --- | --- | --- | --- |
| hysteria | `tlsConfig`、`ProtocolSettings.(*Config)`、`SocketSettings`、`FinalMask`、`QuicParams`；并强制 `dest.Network = net.Network_UDP` | **否** | `transport/internet/hysteria/dialer.go:327-376`（强制 UDP 在 `:334`） |
| masque | 仅 `ProtocolSettings.(*masque.Config)` 与 TLS；不读 `QuicParams`/`FinalMask`/`SocketSettings` | **否** | `proxy/masque/client.go:61-66` |

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

### 2.4 附带待确认项：masqueSettings.path 恒为 null

`reject_inapplicable_transport_parameters`（`validate.rs:803-809`）禁止非 XHttp/WebSocket/HttpUpgrade 传输携带 `path` 参数；masque 默认 `native`，故 `node.link.path_or_service_name` 恒为 `None`，`masqueSettings.path` 恒为 `null`，核心回落 `masque.DefaultPath`。**请 PC-07 确认 P0 是否有意如此**，或属漏映射。本项未纳入裁定，待回答后再定。

---

## 3. 验收要求

- 每例断言生成 JSON 的**键集合**，不得只断言 `run -test` 通过：
  - 正向：`network == "hysteria"`（或 `"masque"`）时，`streamSettings` 只含 §2.1 白名单键，`wsSettings`/`splithttpSettings`/`httpupgradeSettings`/`grpcSettings` 均不存在。
  - 负向：`type=ws|xhttp|httpupgrade|grpc` 四例均返回 `non-native-transport`，错误含节点 ID。
  - `allow_insecure`：`true` 被拒并带节点 ID 与字段名；`false` 时 `tlsSettings` 中无 `allowInsecure` 键。
- 交付报告须区分「构造通过」与「字段已生效」，沿用 2026-11-24 WebSocket early data 裁定 §2.3 口径。

---

## 4. 未决与边界

- masqueSettings.path（§2.4）待 PC-07 回答。
- `xmax`/`xmux` 其余字段、`pinnedPeerCertSha256`/`verifyPeerCertByName` 的真实映射、证书固定整体方案，均不在本次范围。
- 若后续需要「不安全 TLS」能力，须走证书固定（pcs/vcn），不得在桥或 IR 侧恢复 `allowInsecure`。
- PC-07 结卡仍等 PC-04c done，本条不改变该依赖。

---

## 5. 人类确认记录

- **待确认**。2026-11-24 15:22 人类就 allowInsecure 出示确认对话框（2/2），已勾选「批准在生成阶段明确拒绝」，本文 §2.2 据此拟定；§2.1 传输边界与 §2.3 矩阵标注同批提交确认。
- 确认后本节须补记：确认时刻、确认范围、是否有修改。**在补记之前本文仅为建议，不构成生效裁定。**
