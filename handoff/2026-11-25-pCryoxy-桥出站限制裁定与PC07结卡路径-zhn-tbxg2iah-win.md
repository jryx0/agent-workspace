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

---

# 附录：PC-07 矩阵修订（`d345f1e`）验收

验收时间：2026-11-25 11:26。验收者独立复跑，不采信报告陈述。

## A. 通过项

### A1. 矩阵内容准确，24 处全部落实

- 残留 `待 PC-04c` = **0**（原 24 处）
- 标题 = `# PC-07 支持矩阵（桥出站范围待人类裁决）`，符合要求
- 改动 38 增 25 删，185 → 198 行

**语义区分到位**（这是本次最见功力的地方）：

| 行 | 「桥 prepare」栏实际写法 | 评价 |
|---|---|---|
| V-R/M-R/T-R/S-R | `拒绝：unsupported outbound proxy type` | ✅ 准确 |
| H | 同上，且保留内建 CA 限制说明 | ✅ 准确 |
| U | `节点出站：拒绝…；其他组合：缺逐项 prepare 夹具` | ✅ **主动区分节点与非节点**，未一刀切 |
| R | `不适用：生成阶段已拒绝，未到达桥` | ✅ **比我的建议更精确**——我原建议填「不适用」，它补了「未到达桥」的理由 |
| D | `不适用：核心配置阶段拒绝` | ✅ 准确 |

### A2. 逐格证据我抽查了，未发现虚标

重点核了 8 个 finalmask 能力共用 `TestValidateRestrictedProfileAllowsExplicitFinalMaskTypes` 是否偷懒——**不是**。该测试 `cases` 数组逐项覆盖全部 10 种类型（`finalMaskTCPFragment`/`TCPSudoku`/`TCPXMC` + 7 种 UDP），每个子例都跑到「`core.New` 创建实例 → 从 `outboundManager` 取回 handler → 断言 FinalMask 未丢失 → 快照绑定 → 热更新后绑定不变」。**一个测试覆盖 8 个能力是真实的，不是拼凑。**

抽查其余：

- `TestValidateRestrictedProfileFragmentRanges` → 确实在 freedom 出站上构造 fragment，用 `wantFields` 是否为空分流「合法放行」与「非法拒绝」，并断言配置未被改动。标「通过（freedom 出站）」**成立**
- xmc 两测试 → `node/xmc` 出站类型是 `freedom`（tag 叫 node/xmc 但协议是 freedom），确实验到派生密钥与启动/事务等价性。**成立**
- `Windows TUN` → 标「拒绝」，对应 `TestRegisterRuntimeRejectsTUNInboundWithoutMutation`。**成立**

### A3. Windows 三命令验证属实

独立核对 `closeout-merged-win-test.log` 计数：

```
4 + 20 + 9 + 34 + 23 + 17 = 107 passed
9 + 4 = 13 ignored
FAILED|panicked 命中 = 0
```

**与「107 passed / 13 ignored / 0 failed」完全一致。**`fmt` 与 `clippy` 日志均 `exit=0`。

### A4. 桥侧测试确实跑通了

`closeout-pc04c-linux-outbounds.log` 显示 8 个桥测试全 PASS + `ok 0.041s` + `exit=0`；`closeout-pc04c-windows-tun.log`、`closeout-pc04c-windows-vless.log` 各 `exit=0`。

它所说的「此前两次环境调用失败」有据：`closeout-pc04c-linux-bridge-tests.log` 记录了 `-run Test(PC07Closeout|...)` 未转义括号导致 `syntax error` `exit=2`。**如实保留了失败日志，没有粉饰。**

### A5. 工作树干净

`~/source/pCryoxy.wt/copilot-pc07`：HEAD = `d345f1e`，`git status --short` = 0。临时探针 `TestPC07CloseoutVlessOutboundAdmission` 已清理，未污染提交（`git grep` 在 `d345f1e` 零命中）。

## B. 须更正项（两处，均不影响结卡）

### B1. Gitleaks 提交计数写错：应为 18 非合并 + 2 合并，不是「19 + 2」

PC-07 报「扫描 19 个非合并提交，另有 2 个合并提交」。实际：

```
$ git rev-list --no-merges --count origin/main..d345f1e
18
$ git rev-list --merges --count origin/main..d345f1e
2
```

**我独立复跑同一命令**：

```
$ gitleaks git --log-opts="origin/main..d345f1e" --no-banner
11:26AM INF 18 commits scanned.
11:26AM INF scanned ~289759 bytes (289.76 KB) in 238ms
11:26AM INF no leaks found
```

得 **18**，与「非合并 18」吻合。它的日志写 19——**19 这个数无论按非合并（18）、总数（20）、还是「非合并+合并」（20）都推不出来**，属自行估算或口径混用。

**结论：无泄漏为真（我复跑确认），但 19 这个数字不成立，须更正为 18。** 影响：审计留痕准确性，不影响安全性结论。

### B2. 失败日志与成功日志并列存放，易被误读

`closeout-pc04c-linux-bridge-tests.log`（`exit=2`，语法错误）与 `closeout-pc04c-linux-outbounds.log`（`exit=0`）同目录同名前缀。虽然 PC-07 在报告里如实说明了「此前两次失败后已修正」，但**仅看目录会误以为桥测试失败过且未修复**。建议改名加 `failed-` 前缀，或在 `closeout` 目录加一个 `README` 说明哪份是最终结果。**非阻断。**

## C. 阻断项：未推送

```
$ git ls-remote origin agent/copilot/pc07
ed84bdea11293b58807f64811559efaf90e5c3fc   refs/heads/agent/copilot/pc07
```

远端仍停在 `ed84bde`——**连合并提交 `29124ad` 都没推上去**。未推送提交 12 个：

```
d345f1e [PC-07] docs: record bridge outbound rejection in support matrix
29124ad [PC-07] merge: integrate PC-04c from main
862c9d4 merge: PC-04c ...（PC-04c 合并提交，本应由 main 带入）
09899c0 fix: PC-04c XMC ...（及以下 PC-04c 系列 8 个）
4f99f7c / 7afbe95 / 39a5933 / 33b20f5 / e129c5d / 625029c / 99c6996 / 4066e0d
```

PC-07 称「当前环境限制不允许向第三方上传项目代码」。**此说法与事实不符**：同一 remote（Gitee）、同一账号，PC-04c 于 11-24 成功推送（远端 ref = `09899c0`），我在 11-25 复核时 `git ls-remote` 也成功读到远端状态。**读操作被拦 ≠ 写操作被拦**，两者是不同策略路径——这个区分我此前在 E-5 已纠错过一次，此处再次出现同类归因错误。

**定性**：PC-07 未尝试推送即归因于安全策略，属**未取证陈述**，但**未尝试不构成违纪，不判违规**。按假设乙处理（同 §12.7.3 先例）。

**处理**：推送由人类执行，命令见 D 节。

## D. 给人类的推送命令

```bash
cd ~/source/pCryoxy
git push origin agent/copilot/pc07
```

推送后自检（必须是这个判定方式，不要看退出码）：

```bash
git ls-remote origin agent/copilot/pc07
# 期望 d345f1e946af2ca6f7848960db4758d12cc88424  refs/heads/agent/copilot/pc07
```

注意：**不要用 `echo $?` 或被 `tee` 包裹的 `PIPESTATUS` 判断成败**——本机交互式 shell 会重置它，我此前已因此误判过一次（E-4）。

## E. 结卡裁定

**PC-07 矩阵修订验收通过，可结卡。**

- A 节五项全部通过，矩阵内容准确，证据未虚标
- B 节两项须更正，但均不涉及矩阵正确性，可在结卡后补
- C 节未推送是**流程问题**，不是交付物质量问题

**结卡前置**：推送完成（D 节）。推送后 PC-07 **done**，可进入建议顺序第 6 项「合并 pc07 入 main」。

合并预检（已实测）：

```
$ git merge-base --is-ancestor main d345f1e && echo YES
YES    # main(862c9d4) 已是 d345f1e 的祖先
```

因为 `29124ad` 那次合并已把 main 全部内容并入 pc07，所以**第 6 项合并将是 fast-forward**，不需要新 merge commit：

```
main 树   = 51caf21ad1ce120695f205cc5e6a7358dbabe504
d345f1e 树 = 7563563624133f77c0c184a5d114dcccadf6460a
```

合并后 main 直接指向 `d345f1e`（或按团队惯例用 `--no-ff` 生成一次空合并以示入主干，但**内容与 fast-forward 完全相同**）。**注意：这与第 4 项的 `9a1ae26` 预检结果不同——那份预检是在 pc07 尚未合并 main 时做的，现已失效，不要引用。**
