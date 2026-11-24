# PC-07 裁定：balancer fallbackTag 阻断修正 + 单节点合成池候选来源

日期：2026-11-24 11:40 UTC+8　裁定方：workbuddy@zhn-tbxg2iah-win~zhn-x-w
状态：**人类已确认（11:38 回复「按建议」）**
对象：copilot 排队问题 1/7「单节点合成池的候选来源」；同时修正 320c3cb §6.4 的阻断缺陷
项目：pCryoxy　固定核心：676eaf66f8f05d4d558ee7a74b4736623d3feeb9

## 1. 阻断缺陷（实测在先，本裁定第一条即因此产生）

### 1.1 结论

**balancer 的 `fallbackTag` 非空会导致配置启动失败。**

隔离 profile 下必须一律写 `fallbackTag = ""`，包括 RoundRobin、Failover、LowestLatency 与单节点合成 balancer。**320c3cb §6.4「`fallbackTag` 仍写 `"sys/reject"`」作废。**

### 1.2 根因

```go
// app/router/balancing.go:32-39
func (s *RoundRobinStrategy) InjectContext(ctx context.Context) {
	s.ctx = ctx
	if len(s.FallbackTag) > 0 {
		common.Must(core.RequireFeatures(s.ctx, func(observatory extension.Observatory) error {
			s.observatory = observatory
			return nil
		}))
	}
}
```

`RandomStrategy.InjectContext`（`app/router/strategy_random.go:21-28`）同样在 `FallbackTag` 非空时要求 observatory。调用链：

1. `Balancer.InjectContext`（`app/router/balancing.go:121-124`）转发到策略；
2. 策略调 `core.RequireFeatures` 请求 observatory；
3. 隔离 profile 只放行四个 App（`native/xray-bridge/restricted_profile.go:95`：`xray.app.router.Config`、`xray.app.dns.Config`、`xray.app.dispatcher.Config`、`xray.app.proxyman.OutboundConfig`），**没有 observatory**；
4. `pendingResolutions` 非空，`core/xray.go:243` 返回 `not all dependencies are resolved.`；
5. 启动直接失败。

### 1.3 实测（固定核心 676eaf6，Xray 26.11.9 Custom go1.27.4 linux/amd64，WSL）

| 配置 | strategy | fallbackTag | 候选 | 结果 |
| --- | --- | --- | --- | --- |
| `empty-rr.json` | roundrobin | `""` | 0 | 启动 OK；请求落 `sys/reject` |
| `empty-rr-fallback.json` | roundrobin | `sys/reject` | 0 | **启动失败** |
| `failover-nostrat.json` | 无（=random） | `sys/reject` | 1 | **启动失败** |
| `failover-obs.json` | 无 | `sys/reject` | 1 | 启动 OK（**必须额外加 observatory**） |
| `ctrl-nofb.json` | 无 | `""` | 1 | 启动 OK；请求走 `pool/3/9/1` |
| `node-empty.json` | roundrobin | `""` | 0 | 启动 OK；请求落 `sys/reject` |

`xray run -test` 同样失败，不是只漏检运行期。

### 1.4 fail-closed 不依赖 fallbackTag

空候选时 `PickOutbound` 返回空 tag → `PickRoute` 报错 → `dispatcher` 落默认出站（`app/dispatcher/default.go:456-481`）。默认出站是**第一个注册的出站**（`app/proxyman/outbound/outbound.go:105-111`：`if m.defaultHandler == nil { m.defaultHandler = handler }`，实际赋值在 `:110`）。PC-04c 已强制首出站为 blackhole `sys/reject`（`restricted_profile.go:314`）。实测 `empty-rr.json`、`node-empty.json` 的请求均落 `sys/reject`，语义完整保留且无附加依赖。

**首出站顺序因此升为安全前提，不得调整**：`sys/reject` 必须始终是 `outbounds[0]`。PC-04c 的运行时候选集合同样受此约束（v2 申请书 §1 已写「`outbounds` 按顺序是整个候选出站集合……首项为 `sys/reject`」）。

### 1.5 对西侧校验的连带要求（PC-04c）

PC-04c v2 申请书 §1 末尾的待确认项「空候选提交是否允许走合法 fallback」按此裁定结项：**桥侧 `validateProfileRoutes` 应要求所有 `balancingRule` 的 `fallbackTag` 为空**。否则带 fallbackTag 的候选能过桥校验、到核心即启动失败，形成「桥通过、核心起不来」的假通过。此条写入 PC-04c 审核意见，不属本裁定强制 copilot 立即实施的范围。

## 2. 问题 1/7：单节点合成池的候选来源

### 2.1 人类选择

**选项 1：启动期总是包含被引用节点，隔离由 PC-09 / PC-04c 在运行期调整。**

即在生成阶段，只要规则 `enabled = true` 且 `action = Action::Node`，无论目标节点 `state` 为何，都照常生成单节点出站与合成 balancer。

### 2.2 理由

1. `Action::Node` 是用户显式指定「这条流量固定走这个节点」，selector `pool/node-<id>/` 只命中 1 条出站，没有候选选择空间，不构成「池」，不存在隔离后要不要排除的调度问题。
2. 生成期排除会使隔离恢复后必须重新生成配置才能恢复；隔离期间规则指向空池落 `sys/reject`，用户只看到「不通」，无法区分是节点隔离还是配置错误。
3. 隔离的执行点在运行期：PC-09 判定后经 PC-04c 的 `ReplaceRoutingAndOutbounds` 撤除该出站，或用 `desired_overrides` 把 `pool/group/node-<id>` 改指 `sys/reject`，同一 epoch 生效（320c3cb §6.6 已定）。
4. `SchedulingInput` 表达的是调度决策（RR 排班成员、Failover 赢家），单节点无调度决策；增设 `single_node_active` 等于让 PC-07 变相承担健康判断，与 586b821 ④「不读时钟、不探测、不推断健康」冲突。
5. 佐证：全仓库无任何代码把 `NodeState` 置为 `Active`（`validated.rs:1322`、`plan.rs:145`、`public_dto.rs:970`、`canonical.rs:64`、`config.rs:1415`、`tests/contracts/ir.rs:65` 全为 `Unknown`）。按 `state == Active` 过滤会把全部节点滤掉，属不可能成立的实现。

### 2.3 硬约束

1. **所有 balancer 的 `fallbackTag` 一律写 `""`**（§1）。
2. 删除 `config.rs:1026` 自校验中「非 RR 必须 `fallbackTag == "sys/reject"`」的断言，改为所有 balancer 断言 `fallbackTag == ""`。
3. `config.rs:1120-1127` 按策略分支写 `fallbackTag` 的逻辑改为统一写 `""`。
4. PC-07 不读 `node.state` 做任何过滤或报错；`node.state` 仅可用于 UI/导出侧展示透传。
5. PC-07 不生成任何 override 结构。

## 3. 必须的测试

| # | 用例 | 断言 |
| --- | --- | --- |
| 1 | RoundRobin 空池 | `strategy = roundrobin`、`fallbackTag = ""`、无 `pool/<group>/…` 出站 |
| 2 | Failover 有合法赢家 | 只 1 条出站、balancer 无 `strategy`、`fallbackTag = ""` |
| 3 | LowestLatency 有合法赢家 | 同 #2 |
| 4 | 单节点合成 balancer | `strategy = roundrobin`、`fallbackTag = ""`、selector `pool/node-<id>/` |
| 5 | 节点 `state = NodeState::Isolated` 且被 enabled 的 `Action::Node` 规则引用 | 照常生成出站 `pool/node-<id>/<id>/<rev>` 与 balancer；证明不做隐式过滤 |
| 6 | 遍历全部 balancers | 无一 `fallbackTag` 非空 |
| 7 | 启动实测（固定核心 `run`，非只 `run -test`） | RR 空池、Failover 单候选、单节点三类配置均能启动成功；空候选请求实测落 `sys/reject` |

测试 #5 需允许覆盖 `hysteria_node` 辅助函数的 `state` 字段（现固定 `Unknown`，`config.rs:1415`），属测试脚手架改动。

## 4. 与既有裁定的关系

- **作废 320c3cb §6.4**（`fallbackTag` 仍写 `"sys/reject"`）。
- **部分修正 320c3cb §7 测试 #8**：原断言 `fallbackTag = "sys/reject"` 改为 `""`。
- **部分修正 586b821 ⑤**：「RR 空池落首项 `sys/reject`」的结论不变，但机制说明更正为「核心默认出站」，不是 fallbackTag。
- §1.5 的桥侧校验要求属 PC-04c 范围，由 PC-04c 审核意见另行提出。
- 其余条款不变。

## 5. 证据

目录：`~/.agent-tools/run/review/pc07-emptypool/`

```text
empty-rr.json                  RR + "" + 0 候选
empty-rr-fallback.json         RR + sys/reject + 0 候选
failover-nostrat.json          无 strategy + sys/reject + 1 候选
failover-fb.json               无 strategy + sys/reject + 1 候选（与 nostrat 同型，保留）
failover-obs.json              无 strategy + sys/reject + 1 候选 + observatory
ctrl-nofb.json                 无 strategy + "" + 1 候选（对照）
node-empty.json                单节点合成 + "" + 0 候选
rr.log  node.log  ctrl.log     运行日志
test-failover-nostrat.log      run -test 也失败的日志
README.md                      结论与复现步骤
```
