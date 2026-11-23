# pCryoxy PC-07 IR 契约变更申请 v2 审核意见（7498339）

- 项目：pCryoxy｜PC-07 doing
- 被审：共享仓 `749833922b99d5b0db16629e943da2e20a953dd4`，`handoff/2026-11-23-pCryoxy-PC07-IR契约变更申请v2-copilot-zhn-tbxg2iah-win.md`
- 审核：workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-23 20:16 UTC+8
- 依据：e1b0f4f 预审意见（含 H-1/H-2 附节）、PC-07 前置事项裁定 §3 R1～R7、PC-06 首轮裁定 §6.1 H1、固定核心 676eaf6 源码
- **结论：v2 已逐项落实预审 ①～⑤，内容可接受；剩余三个待裁决点（H-3/H-4/H-5）须人类裁定。三项裁定后，审核方建议整体批准 v2，批准后 copilot 方可修改 core-ir / protocol-parser。** 本文不是批准。

## 1. 逐项核对

| 项 | v2 内容 | 结论 |
|---|---|---|
| G-09 快照版本 | v0→v1 一次迁移，revision 不变，未知版本/损坏明确失败；如实说明 `StoredSnapshot` 尚无真实持久化 | 接受 |
| WireGuard | 字段表与 H-2 一致；私钥/PSK 用 SecretRef；legacy `peers` 只读保留、生成时报「需重新录入」；`wireguard://` 一律带行号拒绝 | 接受。现有 `parse_wireguard`（validate.rs:261）仍接受不带 peer/reserved query 的链接，生成出的节点无法使用；改为全部拒绝符合 PC-06 H1「完整分享链接转 P1」，并消除「解析成功但不可用」 |
| MASQUE 认证 | 更正 transport_method.go:806-882 user/pass→Basic；user/pass 分开存 SecretRef；warp 拒绝；旧合并 token 不推测、要求重新录入 | 接受；链接入口见 H-4，指纹见 H-5 |
| MASQUE remoteDNS | 按 H-1=A，含 IP-only、≤8、常量注明出处 | 接受。「地址族不匹配提示」需要运行时分配地址，生成阶段拿不到：要求 PC-07 在 plugin-xray 提供纯函数（输入分配地址与 DNS 列表，输出是否匹配），由 PC-14/15 调用展示；登记为 PC-14/15 的对接义务 |
| FinalMask | XMC 只出 JSON、Rust 不做 RSA；noise script 拒绝；密码 SecretRef；入口为高级入口，未实现前标「无输入入口」 | 接受；无上限字段见 H-3 |
| 文件清单 | core-ir 4 处、parser 4 处、plugin-xray；明确 PC-06 全回归 | 接受；实施中需加文件须先补申请 |

## 2. 待人类裁定

### H-3 可变长字段的资源上限

R4 要求「没有依据上限的字段不进 IR」，而 XMC profiles、各类密码等又是核心必需字段，核心本身不设上限。与 H-2（peer 1～16）同理，上限可以由人类作为**产品资源限制**裁定，依据写「人类裁定（资源控制）」即可，不需要协议依据。审核方建议：

| 字段 | 建议上限 | 依据 |
|---|---|---|
| 各类密码（sudoku、xmc、mkcp aes128gcm、salamander/Gecko） | 1～256 字节；salamander 下限仍为 4 | 资源控制 |
| 域名类（xmc hostname、mkcp header DNS domain） | 总长 ≤253，单个 label ≤63，须为合法主机名 | RFC 1035，有标准依据，不必等裁定 |
| XMC profiles | 1～8 个 | 资源控制 |
| XMC texturesValue / texturesSignature | 各 1～8192 字节 | 资源控制（核心只要求非空，transport_finalmask.go:960） |
| noise items | 1～32 项；单项 packet / segments 长度 ≤2048 字节 | 资源控制；2048 与 Gecko 包长上限一致 |

超出上限在生成/校验阶段明确拒绝，不截断。

### H-4 MASQUE 分享链接入口

现状：PC-06 的 `parse_masque`（validate.rs:298）接受 `masque://`，把密码（否则用户名）合成一个 token。v2 称找不到可核实的 `masque://` 链接规范，提议在依据找到之前解析入口拒绝。

- **A（建议）**：与 WireGuard（H1）同一做法。P0 的 MASQUE 由高级入口（JSON/手工，PC-14/15）录入；`masque://` 带行号明确拒绝，提示走高级入口。copilot 在 v2 实施前补一节检索记录（查过哪些客户端/规范、名称和版本）；若找到可核实的参考实现，再按其语义开放链接映射，另行审核。
- B：保留链接入口，把 userinfo 的 user/pass 直接映射到核心 user/pass，作为本项目约定写进文档。问题是这等于自定链接语法，违反「不发明链接语法」。
- C：维持现状（合并 token）。有损，不可接受。

A 不缩减 P0：MASQUE 协议本身仍在 P0，只是输入方式和 WireGuard 一样走高级入口。

### H-5 MASQUE 双凭据与 G2 指纹

G2 指纹 `CanonicalNodeKey`（core-ir node.rs:413）只有一个 `credential_id`，由宿主 `credential_id(value: &[u8])`（protocol-parser lib.rs:78）从凭据字节计算。审核方建议：

- 不加第九字段。把 user、pass 编成**带域分隔、带长度前缀**的字节串，例如 `"pcryoxy/masque-basic/v1" ‖ u32(len user) ‖ user ‖ u32(len pass) ‖ pass`，交给现有 `credential_id()` 计算，得到唯一的 credential_id。长度前缀保证 (`ab`,`c`) 与 (`a`,`bc`) 不会碰撞。
- 旧 MASQUE 节点的指纹会变化；由于旧合并 token 本来就要求重新录入，不做旧指纹兼容，迁移时标记需重新录入即可。
- staging 与回滚：两个 SecretRef 同进同退，任一写入失败整体回滚，测试覆盖。

## 3. 下一步

人类裁定 H-3、H-4、H-5 后，审核方登记并给出整体批准建议；人类批准 v2 后，copilot 按 v2 §5 清单实施，批准前不改 core-ir / protocol-parser。
