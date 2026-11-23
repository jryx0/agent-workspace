# pCryoxy PC-07 IR 契约变更合并申请 v2

- 项目：pCryoxy；PC-07 doing；申请者：copilot@zhn-tbxg2iah-win~zhn-x-w；基座 `c3acc73f0b1cfc25b1770a4d0d9645cd59681738`。
- 状态：**待契约所有者审核及人类整体批准**；H-1、H-2 是单项裁定，不是 v2 接口整体批准。批准前不修改 core-ir、protocol-parser；FinalMask、WireGuard、MASQUE 矩阵标「待接口」。
- 本文取代 v1（共享仓 `e1b0f4f`）中 FinalMask 的字段/来源/阻塞说明及 A～D 补充章节的相应方案；旧文保留为历史记录。依据预审 `handoff/2026-11-23-pCryoxy-PC07-IR契约变更申请预审意见-e1b0f4f-zhn-tbxg2iah-win.md`、前置事项裁定 §3.1 R1～R7、PC-06 首轮 H1。四项一次审核、一次 schema 升版及迁移；不缩减 P0。
- 固定核心 Xray `v26.11.9` / `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`。无标准输入来源不能发明分享链接、订阅字段或 query；JSON/手工高级入口由 PC-14/15 承接，不代表入口已实现。

## 1. G-09 快照版本与迁移

存储 schema version 与内容 `revision` 分开：无版本表示作为 legacy v0，首个显式版本为 v1；只做 v0→v1 一次迁移，revision 原样保持。新 FinalMask、WireGuard、MASQUE 字段及旧值处置合并进 v1。未知版本、格式损坏及不能无损迁移的值明确失败，禁止默认成功或丢失字段；只保留 SecretRef 引用，不读取或复制密文/明文。现有 `StoredSnapshot` 未发现真实持久化或序列化实现，不声称已有磁盘格式；若发现实际消费者/编码，先核实并取得契约审核。新增序列化依赖须另行申请。

迁移测试清单：
1. 无版本 v0 读入后迁到 v1，revision、节点/组/路由及旧 `None`/`Header` 语义不变；再次保存/加载 v1 不重复迁移。
2. v1 新变体及全部 SecretRef 往返；旧 WireGuard IP 列表原样保留但生成报需重新录入；旧 MASQUE 合并 token 无法无损拆分时明确要求重新录入，不伪造 user/pass。
3. 未知版本、损坏数据、无效新字段与不可迁移数据逐项明确失败；不出现部分成功或明文泄漏。
4. 数据一致性、指纹冲突、staging/回滚回归；存在外部持久化消费者时先用真实旧格式增补迁移测试。

## 2. WireGuard（修正 v1 来源及数值边界）

P0 的来源是高级入口的 JSON 或手工构造（PC-06 H1、REQ-08；PC-14/15 待实现），不是 `wireguard://`；分享链接转 P1。本次申请 parser 对 `wireguard://` 统一返回带行号的明确不支持，包含旧 `peer`/`peers`、`reserved`、`private-key` query，不再接受任何这类链接；不从旧 query 猜语义。矩阵解析列为「高级入口（待 PC-14/15）」，批准前同时标「待接口」。

| 字段 | 申请类型与限制 | 来源 |
|---|---|---|
| 本地私钥 | `SecretRef`；读取后校验 WireGuard key 为 32 字节 | 高级入口 JSON/手工 |
| 本地地址 | `Vec<IpCidr>`，显式 1～64 条，IPv4 prefix 0～32、IPv6 prefix 0～128 | 同上 |
| peers | `Vec<Peer>`，1～16 | 同上 |
| 每个 peer 公钥 | 32 字节公钥类型，合法编码无损解码 | 同上 |
| 每个 peer 预共享密钥 | `Option<SecretRef>`；存在时解码为 32 字节 | 同上 |
| 每个 peer endpoint | `Endpoint`，host + 非零 u16 端口 | 同上 |
| 每个 peer allowedIPs | `Vec<IpCidr>`，显式 1～64 条，地址族与 prefix 有效；不默认全路由 | 同上 |
| MTU | 可选 `u16`，1280～1500；缺省时生成器显式输出 1420 | 同上；范围/默认依人类 H-2 |
| PersistentKeepalive | `u16` 秒：0 关闭，否则 1～65535 | 同上；wg(8) 与人类 H-2 |
| reserved | `Option<[u8; 3]>`，空或恰好三字节 | 同上；人类 H-2 |
| legacy_peer_ips | 旧 `peers: Vec<IpAddr>` 原样保留的只读 legacy 字段，仅迁移读取 | v0 存储，绝不从其推导 interface/endpoint/allowedIPs |

legacy 字段存在的节点配置生成必须报「需重新录入」，不能悄悄忽略，即使列表为空也要保留“来自 legacy”的可判定标记。字段变更不重开 H1，也不新增链接语法。

## 3. MASQUE（修正 v1 认证及 DNS 事实）

- 先前声称没有 Authorization 入口是错误的：固定核心 [`infra/conf/transport_method.go:806-882`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/infra/conf/transport_method.go) 的 MASQUE transport `user`/`pass` 生成 `Authorization: Basic base64(user:pass)`，`user` 含冒号被拒；warp 与 user/pass 不能并用。P0 明确拒绝 warp，不发明 bearer/token 映射。
- `parse_masque` 当前取 password，否则 username，合成单个 token，丢失两者区别。申请将 user、pass **分开**用 `SecretRef` 存储、分别解析/暂存、生成时映射到上述 transport `user`/`pass`；user 也用 SecretRef，因为它可能承载秘密。非法冒号、空值/缺值等按已核实的核心语义和输入格式明确处理，不得合并、丢弃或把明文写入日志/fixture。
- 链接 userinfo 到两字段的映射只有在分享链接规范或具体参考实现名称、版本可核实后才开放；目前未找到可验证的 `masque://` 链接规范，不把核心 JSON 的字段存在当作分享链接标准。无此依据时解析入口明确拒绝；高级入口 JSON/手工可分别填写，PC-14/15 负责。旧合并 token 不得推测为 user 或 pass，迁移保留引用并要求重新录入。
- 认证拆分要同时审查 staging 事务、两项秘密回滚、去重与现有 G2 八字段指纹：请求契约所有者明确双凭据身份编码与旧指纹兼容；不得新增第九字段、暗中合并有歧义的字节或静默去重。实现前对此决议须明确。
- **remoteDNS：人类 H-1=A。** `remote_dns` 允许高级入口填写 IP 地址，最多 8 个；不接受域名。未填写时生成配置显式写 `1.1.1.1`、`1.0.0.1`、`2606:4700:4700::1111`、`2606:4700:4700::1001`，节点详情显示「默认：Cloudflare」。值集中为 plugin-xray 常量，注明 [`proxy/masque/client.go:77-79`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/proxy/masque/client.go) 与固定核心版本；核心升级复核。服务端分配地址族与所有 DNS 地址族不匹配时，节点详情提示「域名解析可能失败」（同文件 :318-330）；运行期如何将实际地址族传给 PC-14/15 属后续宿主/UI 对接，须审核，不能凭配置猜测。
- remoteDNS 是 MASQUE 隧道内 netstack 的域名解析，不是 PC-04b 禁止的核心远端 DNS 后端；不据此挂起 MASQUE。其他核心远端 DNS/FakeDNS 禁令不变。

## 4. FinalMask（修正 v1，R1～R7）

只申请出站 stream 的 10 个封闭变体；无通用 raw/settings、未知类型或入站 FinalMask。`validate_snapshot` 拒绝 transport 错配以及 realm、xicmp、udphop 和其他未纳管类型。表内每项的拟定写入方均为 PC-14/15 高级 JSON/手工入口；该入口未实现前解析栏标「无输入入口」，获批前同时标「待接口」。分享链接和订阅没有已核实字段，均不新增语法。下表列的是**候选字段，不是批准**；任何缺少合理上限依据的可变长字段不得先进入 IR，必要字段发生冲突的情况列于表后供裁决，不自行降低 P0。

| 变体 | 拟定字段、范围及来源 |
|---|---|
| TCP fragment | packets 取 All/TlsHello 或正整数区间；length、delay、maxSplit 使用固定核心 `Int32Range` 可表示范围、起止有序，最后 length 下界非 0。高级入口；不建无上限 `lengths`/`delays` 列表字段。 |
| TCP sudoku | password 为 `SecretRef`；ascii 枚举为空、entropy、prefer_entropy、ascii、prefer_ascii；单个 custom table 固定 8 字符，2 x/2 p/4 v；padding 0～100 且 min≤max。高级入口；不建无上限 custom_tables。 |
| TCP xmc | password `SecretRef`，hostname 和 profiles 来源为高级入口；核心要求密码非空、profiles 非空、username `[A-Za-z0-9_]{3,16}`、UUID 16 字节、textures 的 value/signature 非空。只生成 JSON 的 password/hostname/profiles，RSA 由固定核心 Go JSON builder 派生，Rust 不派生、不存储或传输 RSA，也不申请 RSA 依赖。hostname、profiles 数量及 textures 长度的可接受边界待裁决，未裁决不进入 IR、不伪称支持。 |
| UDP mkcp aes128gcm | password `SecretRef`，高级入口；非空；密码长度上限缺依据待裁决。 |
| UDP mkcp header | ID `0..=5`；DNS domain 高级入口，完整域名上限待核实；未确认前 domain 不进入 IR，不能假装 DNS 变体已取证。此为 mask，非 WireGuard 隧道。 |
| UDP mkcp original | 无字段；由高级入口选择变体。 |
| UDP noise | 声明式 reset、items（rand、randRange、delay）来自高级入口；数值以核心 `Int32Range` 为边界，randRange 0～255，禁止脚本；items 数量、packet/segments 长度未有上限依据，不先纳入 IR，若无界限导致无法表达有效 noise，须先裁决而非静默给空值。 |
| UDP salamander | password `SecretRef`，高级入口，至少 4 字节；上限缺依据待裁决。 |
| UDP salamander Gecko | password `SecretRef`；min/max packet size 1～2048 且 min≤max；高级入口，密码上限同上。 |
| UDP sudoku | 字段与 TCP sudoku 相同，独立校验 UDP 位置；高级入口。 |

所有密码类字段均仅用 SecretRef；不得把明文写入 IR、持久化快照、日志或 fixture。noise `script`/Lua 不进 IR，出现即拒绝；不执行 Lua。没有依据上限的字段不建模、不凭实现者自行设 cap、不以默认值冒充原意。**待裁决冲突**：XMC profiles 与密码等是核心必需可变长输入，但核心未规定安全上限；R4 要求无依据上限的字段不进 IR，PC-07 又必须覆盖十种。请求契约所有者与人类在整体审批中明确这些字段的资源上限及依据；其他无界的必需字段同理。在裁定前对应变体保持「待接口」，不宣称缩减或完成 P0。

## 5. 请求扩展的文件清单及验证

以下均为申请范围，v2 批准前不得修改；实施以最终批准清单为准：

- `crates/core-ir/src/node.rs`：FinalMask、WireGuard、MASQUE 强类型和 SecretRef；`crates/core-ir/src/validated.rs`：校验、版本化存储及一次迁移；`crates/core-ir/src/lib.rs`：必要类型导出；`tests/contracts/ir.rs`：契约与迁移回归。
- `crates/protocol-parser/src/validate.rs`：`parse_masque` 无损拆分/warp 拒绝、旧 WireGuard 全链接与 `peer`/`peers` query 明确拒绝；`crates/protocol-parser/src/canonical.rs`：双 SecretRef staging、原子回滚及批准的 G2 指纹/去重方案；`crates/protocol-parser/src/lib.rs`：仅按批准方案调整候选/事务接口；`crates/protocol-parser/tests/parser.rs`：正反例、带行号错误、回滚/无泄漏及 PC-06 回归。若实现发现需额外文件，先补申请，不擅自扩大。
- `crates/plugin-xray/src/{config,protocols,capabilities}.rs`、`crates/plugin-xray/tests/fixtures/config/`、`contracts/core-capabilities.json`：批准后生成和证据；PC-14/15 节点详情与高级入口为后续卡，不在本次修改文件中。
- 上述 parser 文件属于**已结卡 PC-06 代码变更**：实施后必须完整重跑 PC-06 全部回归测试并通过，报告命令、范围、排除项与结果；另跑 workspace fmt、clippy、test 及要求的平台构建，不能用单例冒充全量。
- 每种协议/能力分别记录解析、配置、实际连接及平台；核心 `run -test` 与桥 prepare 分列；桥 prepare 与经桥实际连接标「待 PC-04c」，不能把核心直跑预验冒充验收。没有受控夹具标「未通过／缺夹具」。所有取证完成前 PC-07 不结卡；不改桥、ABI、proto 或 go.mod/go.sum。
