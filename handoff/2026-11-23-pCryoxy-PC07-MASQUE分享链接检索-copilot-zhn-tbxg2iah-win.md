# pCryoxy PC-07 MASQUE 分享链接检索记录

- 项目：pCryoxy；PC-07 doing；执行：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-23。
- 依据：PC-07 IR 契约申请 v2 审核 H-4=A。实施前核查，找到参考实现也仅报告，本次不开放 `masque://`。
- 范围：下面列明具体版本及实际检视入口；这不是对所有客户端或未来版本的穷举，也不是协议兼容性实测。

| 名称 / 版本 | 已核查入口和结论 |
|---|---|
| IETF [RFC 9298](https://www.rfc-editor.org/rfc/rfc9298.html)（2022，CONNECT-UDP） | §2 为 HTTPS URI Template，含 target_host / target_port；所查配置章节没有定义 `masque://` 节点分享格式。 |
| IETF [RFC 9484](https://www.rfc-editor.org/rfc/rfc9484.html)（2023，CONNECT-IP） | §3 使用 HTTPS URI Template；所查配置章节未定义 `masque://` 节点分享格式或其 userinfo 映射。 |
| Xray-core v26.11.9，commit `676eaf66f8f05d4d558ee7a74b4736623d3feeb9` | [`infra/conf/masque.go`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/infra/conf/masque.go) 为出站 JSON 的 address/port/remoteDNS；[`infra/conf/transport_method.go`](https://github.com/XTLS/Xray-core/blob/676eaf66f8f05d4d558ee7a74b4736623d3feeb9/infra/conf/transport_method.go) 的 transport user/pass 生成 Basic。二者是核心配置输入，不是分享链接解析规范。 |
| v2rayN `7.15.6` | [`FmtHandler.cs`](https://github.com/2dust/v2rayN/blob/7.15.6/v2rayN/ServiceLib/Handler/Fmt/FmtHandler.cs) 的分享导入与生成分派及 [`EConfigType.cs`](https://github.com/2dust/v2rayN/blob/7.15.6/v2rayN/ServiceLib/Enums/EConfigType.cs) 未列 MASQUE；仅能说明该版本所查入口未提供 MASQUE 分享格式。 |
| sing-box `v1.12.0` | [`include/registry.go`](https://github.com/SagerNet/sing-box/blob/v1.12.0/include/registry.go) 所列核心出站注册入口未列 MASQUE；它是核心 JSON 入口而非通用链接客户端，不能据此推断其他前端不支持。 |
| mihomo `v1.19.12` | [`adapter/parser.go`](https://github.com/MetaCubeX/mihomo/blob/v1.19.12/adapter/parser.go) 所查代理配置类型分派未列 MASQUE；它不是 URI 分享解析器，不能证明所有客户端均无实现。 |

结论：上述范围内未找到可核实的 `masque://` 分享链接参考实现及 user/pass 语义。当前 P0 按人类 H-4=A 在 parser 带行号明确拒绝并提示高级入口；不把 HTTPS 模板或核心 JSON 误作分享链接标准。未来若发现具体实现，先记录名称、版本与字段语义，另行审核，不能自动放开。
