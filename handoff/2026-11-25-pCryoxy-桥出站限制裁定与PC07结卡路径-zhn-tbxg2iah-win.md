# 裁定：桥出站限制的定性与 PC-07 结卡路径

- 日期：2026-11-25
- 裁定者：workbuddy@zhn-tbxg2iah-win~zhn-x-w
- 触发：PC-07 于合并 main 后（`29124ad`）报告「前提不成立：桥的 `validateProfileOutboundsInPlace` 仅放行 freedom、DNS、blackhole，VLESS 等节点出站会返回 `unsupported outbound proxy type`，不能填写 prepare 通过」，并给出三选项请求裁定
- 结论：**PC-07 的观察为真，但结论定性偏了**。这不是 PC-04c 的缺陷，也不是 PC-07 的举证失败，而是 **G-01 历史遗留的需求范围缺口**。**裁定走选项 1（矩阵如实记录桥拒绝）并同时立案**，不走选项 2（暂停等待）。

## 1. 事实核验（全部实测/源码核对，不采信任何一方陈述）

### 1.1 合并已落地

```
$ git rev-parse agent/copilot/pc07
29124adf56cc5dec176835208475089775060e0f
$ git log --oneline -2 29124ad
29124ad [PC-07] merge: integrate PC-04c from main
862c9d4 merge: PC-04c 原生传输边界 09899c0 第六轮复核通过后集成 by workbuddy@...
```

### 1.2 桥出站放行范围：PC-07 所述属实

`native/xray-bridge/restricted_profile.go:340-404`：

```go
const (
	profileOutboundFree   = "xray.proxy.freedom.Config"
	profileOutboundDNS    = "xray.proxy.dns.Config"
	profileOutboundReject = "xray.proxy.blackhole.Config"
)

func validateProfileOutboundsInPlace(configs []*core.OutboundHandlerConfig) error {
	// ...首出站必须 sys/reject blackhole（:341-344）
	proxyType := cfg.GetProxySettings().GetType()
	switch proxyType {
	case profileOutboundFree, profileOutboundDNS, profileOutboundReject:
	default:
		return status.Error(codes.FailedPrecondition, "unsupported outbound proxy type")   // :361
	}
```

**我在 PC-07 的 worktree 上写了探针实测**（用完已删，工作树 `status` 归零）：

```
vless          -> REJECTED: unsupported outbound proxy type
vmess          -> REJECTED: unsupported outbound proxy type
trojan         -> REJECTED: unsupported outbound proxy type
shadowsocks    -> REJECTED: unsupported outbound proxy type
freedom        -> ACCEPTED
```

**并且这个限制不只在热更新路径**：`geo_reload.go:44` 的启动路径同样调用 `prepareProfileOutbounds(config.Outbound)`，所以**整个桥（启动 + 全部 7 个 RPC）只接受这三种出站**。

### 1.3 这不是 PC-04c 引入的

```
$ git show c3acc73:native/xray-bridge/restricted_profile.go | grep -A3 "case profileOutboundFree"
		case profileOutboundFree, profileOutboundDNS:
		default:
			return status.Error(codes.FailedPrecondition, "unsupported outbound proxy type")
```

PC-04b 时期放行 **2 种**（freedom、dns）；PC-04c 增加了 blackhole 变成 **3 种**。**方向是放宽，不是收紧**。PC-07 把它归因为「PC-04c 前提不成立」在因果上不成立。

### 1.4 根因：G-01，早在 PC-04 就记录在案

`docs/01-需求总表.md:70`（**这是仓库里早就存在的条目，不是我事后补的**）：

> **G-01 | 高** | PC-04 受限子集裁定（11-21 07:44）在 prepare 阶段拒绝 `sniffing`、`freedom`、`finalmask`、`proxy/dns`，事实上缩减了 REQ-08/12/14 的 P0 范围。基线 §10 要求「确需缩减已确认范围时另请用户裁决」，裁定文件中无用户确认，也没有后续卡承接被拒能力 | 由用户在下面两条里选一条：A. 确认 P0 暂不支持这些能力，在基线追加 REQ 修订并标注后续卡；B. 新增「PC-04b 受限 profile 扩展」卡，把 freedom（直连）和 sniffing 纳入统一 RouteView。**freedom 关系到直连规则能否生效，建议至少把它列为 P0 必须补齐项**

关键点：**G-01 提的两条路都只谈 freedom / sniffing / finalmask / proxy/dns，从未把「节点出站（VLESS/VMess/Trojan/Shadowsocks）纳入桥」列为要补的能力**。桥的定位始终是「受限 profile」——管路由、管系统出站、管内核边界，**不承担节点出站的生命周期**。

## 2. 定性

**桥拒绝 VLESS 等节点出站，是设计边界，不是缺陷。**

理由三点：

1. **职责边界**：桥的 7 个 RPC 全是运行期控制面（`QueryState` / `ReplaceRoutes` / `ReplaceRoutingAndOutbounds` / `ReloadGeo` / `Rollback` / `QueryOperation` / `ReleaseRollbackPoint`），没有「创建节点出站」这一职责位。
2. **隔离意图**：`replaceConnections` 跳过 `sys/*`、`validateSystemOutbounds` 只认 `sys/reject`/`sys/direct`、`restricted_profile.go` 通篇围绕「受限」二字——放行任意节点出站会破坏这个隔离假设。
3. **G-01 的范围从未包含它**：需求层面没有要求过。

**但 PC-07 的核心判断是对的**：「桥 prepare」这一栏**不能填「通过」**。这一栏的真实语义就是「桥是否接受该配置」，答案是「拒绝」，那就必须如实写「拒绝」。

## 3. 裁定

### 3.1 采纳选项 1，但补一条：不是「保持未结卡」，而是「按真实语义填完后结卡」

- **矩阵「桥 prepare」栏**：节点协议行（V-R/V-W、M-R/M-W、T-R/T-W、S-R/S-W 等）一律填 **「拒绝：`unsupported outbound proxy type`（桥只接受 freedom/DNS/blackhole）」**，并注明依据 `restricted_profile.go:358-362` 与我这次的实测。
- **这样填是「如实记录」，不是「未通过」**。桥拒绝节点出站不代表该协议不可用——它代表**这条取证路径不存在**。
- **「实际连接」栏维持「缺夹具」**，不因本裁定改动。
- 改完后**可以结卡**，标题去掉「预验，未结卡」。

### 3.2 不采纳选项 2，理由

「暂停 PC-07，等桥侧补齐协议支持后再结卡」这个方案的前提是「桥应该支持节点出站」。**这个前提本身没有需求依据**（见 §1.4）。按此执行等于：

- 让 PC-07 无限期阻塞在一个**尚未立项**的能力上
- 把一个 G-01 级别的**需求范围问题**，偷换成 PC-07 的**举证失败**
- 若日后人类真的决定扩展桥的范围，那是新卡的事（类似 PC-04b 之于 PC-04），不该压在 PC-07 头上

### 3.3 真正要动的是需求，不是卡

G-01 从 11-21 挂到今天 11-25 还没裁决，现在它有了具体后果（PC-07 无法证明节点协议经桥可用）。**这必须由人类裁决**，三个选项：

| 选项 | 内容 | 后果 |
|---|---|---|
| **甲** | 确认 P0 的桥**不承担节点出站**，PC-07 矩阵按 §3.1 如实记录即可结卡，并新建一条需求说明「节点出站由宿主直连核心，不经桥」 | 最小成本，PC-07 今天就能结卡；但「P0 的节点协议到底走不走桥」这个架构问题被显式记录为**不在桥的范围** |
| **乙** | 新增扩展卡（如 PC-04d）把节点出站纳入桥的受管范围，PC-07 等该卡 done 后再结卡 | 工作量最大，但架构最一致；PC-07 再度阻塞 |
| **丙** | 确认 P0 阶段节点出站走宿主直连核心（现状），桥仅管路由与系统出站；PC-07 矩阵增加一列「直连核心」记录该路径的取证 | 折中：承认双路径现状并分别取证，PC-07 需扩矩阵结构 |

**我建议甲**：现状就是节点出站由宿主直连核心（`local_interop.rs` 用 `Command::new(binary)` 直接起核心，完全绕过桥），矩阵如实描述即可。乙的工作量不该在收尾阶段引入；丙会让矩阵变复杂但收益有限。

## 4. 立即执行（不等人类裁决的部分）

PC-07 现在就该做的（已发包，与本裁定不冲突）：

1. **矩阵如实填「桥 prepare」栏**为拒绝 + 依据，**不要填通过，也不要填「待 PC-04c」**。
2. 标题去掉「预验，未结卡」的前提是 §3.1 改完 —— 但因 G-01 未裁决，**标题暂改为「PC-07 支持矩阵（桥出站范围待人类裁决）」**，比「未结卡」更准确。
3. 补跑 `cargo fmt` / `clippy` / `test`（合并 main 后必须重跑），日志带 `closeout` 字样。
4. **桥侧的 Go 测试不要硬跑**：`native/xray-bridge/go.sum` 缺 `xtls/xray-core` 条目（基线遗留），必须按 `tests/integration/bridge/replay-linux.sh:34-43` 复现固定核心，其中 `0011-*.patch` 必须 `--unidiff-zero`。若 PC-07 报「桥侧测试尚未完成」，多半是卡在这里——**这不是它的问题，可以直接引用本裁定说明口径**。

## 5. 给 PC-07 的回复要点

- 你的观察**经我实测确证，为真**，不是误报。
- 但定性要改：**不是「PC-04c 前提不成立」，是「G-01 需求范围从未包含节点出站经桥」**。桥在 PC-04b 时只放行 2 种，PC-04c 加到 3 种，方向是放宽。
- 你要选的**不是暂停**，是**如实填 + 结卡**。矩阵里写「桥拒绝，依据 `restricted_profile.go:358-362`」是正确且完整的取证，不是缺口。
- 「桥侧测试尚未完成」若因 go.sum / 固定核心而复现，按 §4.4 处理，不必自我归责。
- G-01 的裁决我会提交人类，**不占用你的结卡**。
