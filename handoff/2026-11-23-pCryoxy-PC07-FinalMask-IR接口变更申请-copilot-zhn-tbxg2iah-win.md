# pCryoxy PC-07 FinalMask IR 接口变更申请

- 申请者：copilot@zhn-tbxg2iah-win~zhn-x-w
- 基座：`main c3acc73f0b1cfc25b1770a4d0d9645cd59681738`
- 关联任务：PC-07；当前只申请接口评审，不实施 core-ir/parser 变更。
- 依据核心：Xray `v26.11.9`，commit `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`（`crates/plugin-xray/proto.lock`）。
- 状态：等待契约所有者审核及人类批准。批准前，PC-07 矩阵中的 FinalMask 标为“待接口”。

## 变更目标与边界

在 `core-ir::FinalMaskOption` 中以封闭、类型化的变体表达 profile.md 允许的十种消息形态；不增加通用 `raw`/`settings` 逃逸。FinalMask 只可附着到出站 `LinkOptions`，配置生成时必须作为出站 `stream` 的官方 TypedMessage。不得将被拒绝类型或任意 JSON 放入 IR。

申请审核扩展以下范围：`crates/core-ir/src/node.rs`、`crates/core-ir/src/validated.rs`、`crates/core-ir/src/lib.rs`、`tests/contracts/ir.rs`。parser 当前没有可依据的 FinalMask 分享链接格式；本申请不新增输入语法，必要的 `crates/protocol-parser/src/validate.rs` 变更仅用于显式保持/测试拒绝行为。

## 十种允许类型、字段与范围依据

以下字段名和 protobuf 标量类型来自固定核心同一 commit 下各 `config.proto`。表中“可证实约束”仅列固定核心源代码已有依据的规则；没有依据的长度/数量上限标为待裁定，不自行填值。建议 IR 中的密码、噪声 packet/bytes 使用 `SecretRef`，不保存明文或任意二进制；XMC 派生私钥不得进入 IR/StoredSnapshot。

建议新增的十个封闭变体名为 `TcpFragment`、`TcpSudoku`、`TcpXmc`、`UdpMkcpAes128Gcm`、`UdpMkcpHeader`、`UdpMkcpOriginal`、`UdpNoise`、`UdpSalamander`、`UdpSalamanderGecko`、`UdpSudoku`；现有 `None` 和 `Header` 保持原义。名字显式带 transport，避免 UDP FinalMask 被误放到 TCP outbound 或其他 stream 位置。

| FinalMask 形态 | 字段与 wire 类型 | 可证实约束 / 尚待裁定 |
|---|---|---|
| TCP `fragment.Config` | `packets_from/to: int64`；`max_split_min/max: int64`；`lengths_min/max[]: int64`；`delays_min/max[]: int64` | 固定核心配置转换将空 packets 映射为 `(0,0)`、`tlshello` 映射为 `(0,1)`，显式范围不得从 0 开始；其余输入范围经 `Int32Range`（signed 32-bit），最后一个 length 的 min 不得为 0。建议 IR 用 `All` / `TlsHello` / 正整数范围而非任意 sentinel，并要求长度/延迟数组非空、成对、`min <= max`；超出已验证规则的最大值需契约所有者决定。 |
| TCP `sudoku.Config` | `password: string`；`ascii: string`；`custom_table: string`；`custom_tables[]: string`；`padding_min/max: uint32` | ASCII 模式仅 `""`、`entropy`、`prefer_entropy`、`ascii`、`prefer_ascii`；custom table 固定 8 字符，恰为 2 个 `x`、2 个 `p`、4 个 `v`。核心把 padding 截到 100、并把反序范围改写为相等；为避免静默改写，建议 IR 直接拒绝 `>100` 或 `min > max`。自定义表数量和密码长度没有已查到的上限，待裁定。 |
| TCP `xmc.Config` | `password: string`；`hostname: string`；`profiles[]`（`username: string`、`uuid: bytes`、`textures_value/signature: string`）；wire 另含 `rsa_private_key/public_key: bytes` | 固定核心 JSON builder 要求密码非空、profile 至少一个、username 为 `[A-Za-z0-9_]{3,16}`、UUID 可解析为 16 bytes、textures 两字段非空；RSA-1024 key 由密码确定性派生。IR 不应存派生私钥；Rust 侧派生需要另行依赖申请。现有 parser 没有 profile 输入来源，不得请求 Mojang 或自行设计 URL 字段。hostname 范围和 profiles 数量上限待裁定。 |
| UDP `mkcp.aes128gcm.Config` | `password: string` | 固定核心转换仅在 legacy `value` 非空时选择该类型；没有查到长度上限。建议使用 `SecretRef`，不在 IR 保存明文。 |
| UDP `mkcp.header.Config` | `ID: int32`；`domain: string` | 固定核心枚举 ID 为 `0..5`：DNS、DTLS、SRTP、UTP、WECHAT、WIREGUARD；仅 DNS 使用 domain。DNS 编码器逐 label 检查长度但没有清晰的完整域名上限，完整域名规则待裁定。该项只是 MKCP header mask，不是 WireGuard 隧道。 |
| UDP `mkcp.original.Config` | 无字段 | 空 protobuf message；无值域。 |
| UDP `noise.Config` | `reset_min/max: int64`；`items[]`（`rand_min/max: int64`、`rand_range_min/max: int32`、`packet: bytes`、`delay_min/max: int64`、`segments[]` 含 `kind/bytes/min_size/max_size`）；`script: string` | 配置转换输入使用 signed 32-bit range；`rand_range` 为 `0..255`；noise expression 的随机段 size 为 `0..65535`。segment kind 的固定枚举是 `BYTES`、`RANDOM`、`RANDOM_ASCII`、`RANDOM_DIGIT`、`TIMESTAMP`、`COUNTER`、`NONCE`。`script` 会编译/执行 Lua，建议 IR 不提供该字段。reset/rand/delay 的安全上下限、item/segment 数量和 packet 总长度没有已查到的固定上限，待裁定；不得靠截断或默认值改写。 |
| UDP `salamander.Config` | `password: string` | 固定核心要求 PSK 至少 4 bytes；未发现上限。建议使用 `SecretRef`。 |
| UDP `salamander.GeckoConfig` | `password: string`；`MinPacketSize/MaxPacketSize: int32` | 固定核心 builder 要求 min `>0`、max `<=2048`；IR 另应拒绝 `min > max`，不做重排。建议密码使用 `SecretRef`。 |
| UDP `sudoku.Config` | 与 TCP `sudoku.Config` 相同 | 同一 protobuf 类型及上述相同字段/约束；IR 仍需区分/验证其 UDP 出站使用位置。 |

上表按白名单计十种（`sudoku.Config` 在 TCP、UDP 各计一种）。凡字段虽在 protobuf 中存在、但无固定核心边界的，必须由契约所有者明确接受的标量边界或继续拒绝；不能据此扩展支持未列出的消息。

## 输入来源与拒绝规则

- 现有 `crates/protocol-parser/src/validate.rs:810` 的 `parse_final_mask` 恒返回 `None`；`reject_query_keys` 对未列入协议 schema 的 query key 返回 `UnsupportedCapability("query-field")`（同文件约 820–830 行）。
- `crates/protocol-parser/src/subscription.rs` 只把宿主提供的 bounded subscription body 交给同一 `prepare_import`/分享链接 parser；未定义独立 FinalMask 语法。API Spec v1.2 和现有 parser 中未发现上述十种 FinalMask 的分享链接或订阅字段。
- 因而本申请不发明 query 参数、URI scheme、订阅字段或下载行为。批准接口扩展本身不等于批准 parser 接受任何新输入；在另有标准输入依据前，分享链接/订阅中试图提供 FinalMask 的字段继续明确拒绝。
- 不在 IR 中定义 `realm`、`xicmp`、`udphop`、`filter`、`xdns`、`header-custom`、未知/自定义类型或通用 raw 设置字段。即使伪造/反序列化输入声称这些类型，也必须在 `validate_snapshot` 拒绝。
- 输入来源仍是本接口申请的未决问题：若产品要求用户可配置这些值，须先由契约所有者确定一个有依据的上游/产品输入契约；不得把“protobuf 有字段”误当成分享链接格式。

## 存储与旧数据兼容

基座 `StoredFinalMaskOption` 目前是 `core-ir/src/validated.rs` 内部的 `None` / `Header` 类型，和 `From`/`restore` 对称转换；工作区内只在 `tests/contracts/ir.rs` 通过 `ValidatedSnapshot::to_stored()` 覆盖 round-trip，未发现外部序列化或生产持久化格式。建议：

1. 保持现有 `None` 与 `Header { name, value }` 的含义和转换不变。
2. 为新增的每个强类型 FinalMask 变体增加对应的私有 Stored 变体及对称转换；`SecretRef` 只保存引用，不复制明文。
3. 为旧 `None`/`Header` 和每个新变体增加 restore/validate round-trip 合同测试；拒绝不合法范围、错位的 transport、未知变体和不支持的 FinalMask。
4. 若实施前发现 `StoredSnapshot` 已进入外部持久化，暂停并另提格式迁移/版本化申请；当前证据不支持声称存在磁盘格式。

## 额外阻塞与请求审核项

- XMC 的固定核心会从密码派生 RSA-1024 并把派生密钥放进 XMC protobuf。当前 PC-07 依赖批准不含 Rust RSA/大整数实现；不得手写密码学或把派生私钥存入 IR。需另行申请实现依赖/审查密钥流，或由契约所有者决定该分支如何满足 P0。
- `noise` 有可执行 Lua 字段，且多个整数/列表没有固定核心上限。请审核是否接受上表的严格子集；对没有证据的 cap 请给出裁定，不由实现者自行补值。
- FinalMask 的所有输入来源仍无标准定义；在来源和密钥输入契约确认前，不能把“可表示”报告为“可解析”或“已互通”。

## 固定核心依据

- [profile.md](../../source/pCryoxy/tests/integration/bridge/profile.md)：出站 FinalMask 十种白名单、拒绝范围，以及当前 P0 IR 不可达的说明。
- [core-ir `node.rs`](../../source/pCryoxy/crates/core-ir/src/node.rs) 与 [validated.rs](../../source/pCryoxy/crates/core-ir/src/validated.rs)：当前公开/存储 IR 形状。
- [parser `validate.rs`](../../source/pCryoxy/crates/protocol-parser/src/validate.rs) 与 [subscription.rs](../../source/pCryoxy/crates/protocol-parser/src/subscription.rs)：现有输入来源与拒绝行为。
- 固定核心 schemas：[`fragment`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/transport/internet/finalmask/fragment/config.proto)、[`sudoku`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/transport/internet/finalmask/sudoku/config.proto)、[`xmc`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/transport/internet/finalmask/xmc/config.proto)、[`mkcp aes128gcm`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/transport/internet/finalmask/mkcp/aes128gcm/config.proto)、[`mkcp header`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/transport/internet/finalmask/mkcp/header/config.proto)、[`mkcp original`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/transport/internet/finalmask/mkcp/original/config.proto)、[`noise`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/transport/internet/finalmask/noise/config.proto)、[`salamander`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/transport/internet/finalmask/salamander/config.proto)。
- 固定核心范围/转换依据：[`infra/conf/transport_finalmask.go`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/infra/conf/transport_finalmask.go)、[`infra/conf/common.go`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/infra/conf/common.go)、[`fragment/conn.go`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/transport/internet/finalmask/fragment/conn.go)、[`sudoku/table.go`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/transport/internet/finalmask/sudoku/table.go)、[`salamander.go`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/transport/internet/finalmask/salamander/salamander.go)、[`xmc/derivation.go`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/transport/internet/finalmask/xmc/derivation.go)。

本申请不构成审核通过或人类批准。PC-07 在接口审核/批准前可继续实现非 FinalMask 能力，但 FinalMask 不得进入候选实现，也不得结卡。

## 合并补充申请：IR 版本、WireGuard 与 MASQUE

- 申请者：copilot@zhn-tbxg2iah-win~zhn-x-w
- 关联：本节与上文 FinalMask 申请、需求基线 v1.3 的 G-09 合为**一份 PC-07 IR 契约变更申请**，一次契约所有者审核、一次人类批准、一次 schema 版本升级和一次迁移；不另立平行的 IR 版本申请。
- 状态：仅申请评审，尚未获契约所有者审核或人类批准。以下内容在获批前均不得实施。
- 固定核心：Xray v26.11.9，`676eaf66f8f05d4d558ee7a74b4736623d3feeb9`。

### A. G-09：IR snapshot schema 版本和单次迁移

当前 `Snapshot.revision` 是快照内容修订号，不是 schema 版本。`StoredSnapshot`（`crates/core-ir/src/validated.rs:43`）目前保存 revision、nodes、groups、rules，没有 schema version；仓内只有 `to_stored()`/`restore()` 内存往返测试，没有序列化实现或持久化调用方。因此不能把 revision 误当格式版本，也没有证据声称已有磁盘格式。

请求审核以下一次性方案：

1. 在实际持久化边界增加独立的 `schemaVersion`，建议把当前无版本表示作为 legacy v0，把首次显式 schema 定为 v1；快照内容 `revision` 原样保留，不因迁移递增。
2. 只定义一个 `v0 → v1` 迁移；FinalMask、WireGuard 新字段、SecretRef 引用和 legacy 字段处置在同一个 v1 中定版，不先建中间版本再二次迁移。未知版本、损坏字段或无法无损迁移的值必须明确失败，不回退成默认值。
3. 迁移不得解引用或复制任何秘密。旧 FinalMask `None`/`Header` 保持原值；旧 WireGuard `peers: Vec<IpAddr>` 原样保留为 legacy 数据，不能猜测为本地地址、peer endpoint 或 AllowedIPs。
4. 现有代码未找到外部持久化消费者。若契约所有者发现仓外消费者，需先确认实际 legacy 编码；不得据此宣称已完成用户数据迁移。若需要序列化依赖，须另按依赖申请流程批准，本文不授权新增依赖。

### B. WireGuard：明确字段、边界及来源

当前 `WireGuardOptions`（`crates/core-ir/src/node.rs:149`）只有 `peers: Vec<IpAddr>` 与 `reserved: Option<[u8; 3]>`。PC-06 的 `parse_wireguard`（`crates/protocol-parser/src/validate.rs:261`）将 `peer`/`peers` 查询值按逗号拆分并解析为 IP 地址，将私钥放入 Node 的 `SecretRef`；没有证据说明该 IP 列表是本地 interface address、peer endpoint 还是 allowed IP，更不是公钥。固定核心客户端配置需要的字段见下表。

| 字段 | 建议 IR 类型 / 可证实范围 | 有依据的输入来源 | 当前状态 |
|---|---|---|---|
| 本地 private key | `SecretRef`，继续使用节点凭据引用；解码后为 32-byte WireGuard key | 官方 WireGuard Interface `PrivateKey`；当前 `wireguard://` 输入虽有私钥但 URI 格式未有标准依据 | 没有获批输入格式前不解析；明文不得进 IR/StoredSnapshot |
| 本地地址 | `Vec<IpCidr>`；每项 IPv4 prefix `0..=32` 或 IPv6 prefix `0..=128` | 官方 Interface `Address` 配置字段；当前 parser 不读取 | 待接口；不从 `peers` 推导 |
| peer 公钥 | `[u8; 32]` 的封闭 key 类型；编码必须无损解码为 32 bytes | 官方 Peer `PublicKey`；当前 parser 不读取 | 待接口；无来源时不支持 |
| peer preshared key | `Option<SecretRef>`；解码后为 32-byte key | 官方 Peer `PresharedKey`；当前 parser 不读取 | 待接口；只能存 SecretRef |
| peer endpoint | `Endpoint`（host + `NonZeroU16` port，即 `1..=65535`） | 官方 Peer `Endpoint`；当前 parser 不读取 | 待接口；无来源时不支持 |
| peer allowed IPs | 非空 `Vec<IpCidr>`；prefix 按 IPv4/IPv6 地址族分别为 `0..=32` / `0..=128` | 官方 Peer `AllowedIPs`；当前 parser 不读取 | 待接口；生成时必须显式提供，不能触发核心默认全路由 `0.0.0.0/0`、`::/0` |
| PersistentKeepalive | wire 字段为 `uint32` 秒；核心配置构造器未给出更窄上限；`0` 表示不设置 | 官方 Peer `PersistentKeepalive`；当前 parser 不读取 | 可证实语义范围不足，等待契约所有者确定可接受上限；不得自行截断或设默认 |
| MTU | wire 字段为 `int32`；核心构造器未给出有效范围，且 `0` 会静默采用 1420 | 官方 Interface `MTU`；当前 parser 不读取 | 可证实边界不足；等待裁定明确范围与缺省语义，当前不得依赖 0/1420 默认值 |
| reserved | 核心构造器接受空或恰好 3 bytes | Xray 扩展字段；不是已确认的 WireGuard 标准配置字段，当前仅来自未标准化 query | 无标准输入来源时不支持；不得仅凭核心有字段就开放 |

peer 数量及 interface/allowed-IP 列表数量在固定核心 schema 中没有经本申请核实的安全上限；没有经审核的上限前不接受外部输入。WireGuard 官方 Quick Start 说明通过 `wg`/Interface/Peer 配置设置私钥、peer 公钥、endpoint 和 allowed IP，并未定义 `wireguard://` 分享 URI（<https://www.wireguard.com/quickstart/>）。因此：

- 当前 `peers: Vec<IpAddr>` 的已实现语义仅是“来自自定义 `peer`/`peers` query 的 IP 列表”，其业务含义未定义；不能重命名后自动映射到上述任何字段。
- 建议 schema 迁移时将旧列表原样保留为 deprecated `legacy_peer_ips`；新本地地址、peer 公钥、endpoint、AllowedIPs 等字段只能由契约审核明确批准的标准 Interface/Peer 输入提供。若后续批准标准配置文件输入，PC-06 必须另行确认该输入格式和解析验收。
- 所有无标准来源的字段输入均明确拒绝；不发明 query 参数、分享链接或订阅字段。

### C. MASQUE：token 语义及无损映射审查

IETF [RFC 9298](https://www.rfc-editor.org/rfc/rfc9298.html) 定义 HTTP CONNECT-UDP 与客户端 URI Template；[RFC 9484](https://www.rfc-editor.org/rfc/rfc9484.html) 定义 HTTP CONNECT-IP 与 URI Template。两份标准均未定义 `masque://` 分享链接 scheme，也未定义把 URL userinfo 当作 MASQUE token、bearer token 或核心客户端密码的映射。RFC 9484 的 URI Template 示例中出现 `user` 变量，不构成通用认证语义。

固定 Xray 源码进一步表明目前没有可证实的无损映射（均固定到 commit `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`）：

- [`proxy/masque/config.proto`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/proxy/masque/config.proto) 的 `ClientConfig` 只有 `server` 和 `remote_dns`；`Account.password` 属于 server-side account，并非 client config 字段。
- 固定版本 [`infra/conf/masque.go`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/infra/conf/masque.go) 的客户端 builder 只生成 server 与 remoteDNS；[`proxy/masque/client.go`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/proxy/masque/client.go) 只从客户端配置读取 Server/RemoteDns 与 TLS transport，没有读取 client account/token，也没有 Authorization/Proxy-Authorization header 配置入口。
- `MasqueOptions` 目前只有 congestion control，而 parser 将 `masque://` 的 username/password 当成 token 放入 SecretStore。将其映射成核心 `Account.password`、HTTP Basic/Bearer 或任意 header 都会改变语义，没有源码或标准依据。

因此请求审核：

1. token 若在 IR 中保留，只能表示为 `SecretRef`，不允许明文进入 IR、日志或 fixture；但它在固定核心 client path 未有可用消费点。
2. 未能提供经审核的标准链接/订阅来源及固定核心消费映射前，带 token 的 `masque://` 输入必须在解析阶段明确拒绝；不发明认证映射。没有其他标准输入格式的 MASQUE 链接同样不支持。
3. PC-04b 明确拒绝远端 DNS 与 FakeDNS；固定核心 MASQUE client 在 `remote_dns` 为空时会默认使用公共 DNS IP。配置生成不得接受这一默认，也不得把远端 DNS 静默替换成另一种模式。除非审核出一个符合 P0 DNS 边界的明确配置来源，否则 MASQUE 配置保持待接口。

### D. 合并范围、拒绝规则及结卡门禁

- 本申请合并上文十种 FinalMask IR 变体、G-09 schema version/migration、WireGuard 字段和 MASQUE token/输入边界；一次审核后再实现，一次迁移，不拆成多轮 schema 版本。
- 每个新增字段必须在契约中同时列明类型、范围、标准输入来源和迁移规则；无标准来源的值保持显式不支持。没有范围依据的字段不得由实现者自行设上限、截断、重排或默认。
- 获批前，FinalMask、WireGuard、MASQUE 矩阵行均为“待接口”；`core-ir`、parser 与 `StoredSnapshot` 不改。获批后也须逐项完成解析、配置、候选核心 `run -test`、PC-04c bridge prepare 与受控互通取证；核心直跑仅为预验，不能冒充桥或实际连接的验收证据。
- PC-07 在 FinalMask、WireGuard、MASQUE 的要求和证据全部完成前不得结卡；P0 范围不缩减。PC-04c 由审核方另出任务卡，PC-07 不修改 bridge/ABI/proto。
