# PC-07 裁定：调度输入（SchedulingInput）与 balancer 生成口径

日期：2026-11-24 10:35 UTC+8　裁定方：workbuddy@zhn-tbxg2iah-win~zhn-x-w
状态：**人类已于 2026-11-24 10:30 前后确认两页问答内容，本文为登记稿**
对象：copilot 提问「分组排程无来源，是否改用简单启动输入」，依据固定核心 676eaf6 与 PC-04c 桥白名单实测

## 1. 人类选择

选项 1「先用简单启动输入」，附四条前置（下文 §3）。不采用选项 2（整体拒绝分组），理由是 RoundRobin 不依赖健康数据，只要 Active 池由 Rust 维护，核心侧轮询即可正确工作。

## 2. 核实事実

| 项 | 事实 | 出处 |
| --- | --- | --- |
| leastPing | 桥白名单只接受 `""`/`random`/`roundrobin`，`leastPing` 启动即被拒 | `native/xray-bridge/route_control.go:50-53` |
| leastPing 运行期 | 无 observatory 时 `PickOutbound` 返回空 tag，全池落 `fallbackTag` | `app/router/strategy_leastping.go:30-52` |
| 蓝图约束 | 明令不配置原生 leastPing/leastLoad，不启用 burstObservatory | 蓝图 v0.3 §3.2 |
| 大小写 | 桥按大小写敏感比较，只认小写 `roundrobin`；核心 `Build` 走 `strings.ToLower` | `route_control.go:51`、`app/router/config.go:126` |
| selector | 前缀匹配（`strings.HasPrefix`），非精确匹配 | `app/proxyman/outbound/outbound.go:164-188` |
| 默认出站 | 第一个加入的出站成为默认出站 | `app/proxyman/outbound/outbound.go:109-111` |
| override | 启动 JSON 的 `router.Config` 无 override 字段，只能在 AddRule/RPC 路径传入 | `app/router/config.proto` |

## 3. 四条前置（不满足不得提交）

1. **删除 leastPing 映射**：Failover 与 LowestLatency 均不得写 `leastPing`。
2. **策略字符串一律小写**：`roundrobin`/`random`；草稿的 `roundRobin` 会被桥拒绝。
3. **tag 与 selector 按蓝图 §3.2**：`pool/<group-id>/<node-id>/<config-rev>`、`probe/<node-id>/<config-rev>`，`config-rev` 取快照 revision；selector 必须带尾斜杠 `pool/<group-id>/`。扁平 tag + 精确 selector 会因前缀匹配出现 `pool/node/3` 命中 `pool/node/31`。
4. **启动输入只由 BuildContext 显式传入**：

```rust
pub struct SchedulingInput {
    rr_active: BTreeMap<GroupId, Vec<NodeId>>,
    failover_winner: BTreeMap<GroupId, NodeId>,
}
```

- RoundRobin：selector 只含 `rr_active` 中列为 Active 的成员；`fallbackTag` 留空；该组未提供时按空池处理，不猜。
- Failover / LowestLatency：必须有该组已确认赢家才生成 balancer；缺失返回 `BuildError::MissingSchedulingState(group_id)`，整次构建失败。
- 禁止「第一个成员即赢家」的自行推导。

## 4. 目标校验（生成阶段，fail-closed，报 group_id/node_id/tag 原值）

1. selector 每条以 `/` 结尾，仅由 `[a-z0-9-]` 与 `/` 组成；无空段、`..`、`*`、正则字符；同一快照内去重排序。
2. selector 必须严格等于 `pool/<group-id>/`，禁止用节点 tag 或更短前缀。
3. 每个 selector 在本次生成的出站中至少命中 1 条；RR 空池例外见 §5.1。
4. `balancerTag` 引用的 balancer 必须存在；rule 的 `balancerTag` 与 `outboundTag` 互斥。
5. `fallbackTag`：RR 必须空串；Failover/LowestLatency 只允许 `sys/reject`，指向其它 tag 一律拒绝（含 `sys/direct` 与其它池）。
6. 同一快照内 balancer tag 唯一；业务 selector 不得命中 `probe/` 前缀，需有测试断言。

## 5. 空池行为

1. **RR**：允许命中 0 条；`fallbackTag` 空 → 核心返回空 tag → dispatcher 落默认出站，默认出站即首项 `sys/reject`（`outbound.go:109-111`）。须测试断言：Active 为空的组最终命中 `sys/reject`，不落 `sys/direct`。
2. **Failover / LowestLatency**：空池或缺失赢家一律生成阶段拒绝，不产出「空池运行期再补」的半成品。
3. 组不存在 / 组内成员为空 / 成员含嵌套组 分别报不同错误码，不合并。

## 6. 运行时对接

1. PC-07 只做「给定 SchedulingInput 生成完整启动配置」；不读时钟、不探测、不推断健康。
2. 启动期一次生成完整 inbounds/outbounds/routing，不依赖增量 RPC。
3. 运行期变更不走 PC-07 重新生成 JSON，走 PC-04c 的 `ReplaceRoutingAndOutbounds`（整组出站 + router_config + desired_overrides，同一 epoch）。
4. 切换赢家由控制器调 `OverrideBalancerTarget` 或随整组提交带 `desired_overrides`；RR 切换后清空该组 override（首次为 `""`）。
5. 启动 JSON 仅用于启动；运行期正确性以 PC-04c 回执与 `GetBalancerInfo` 对账为准，「启动配置能跑」不是运行期证据。

## 7. 本轮可交付范围

- 无分组快照；
- 仅 RoundRobin 路径（含 Active 空 → `sys/reject` 的测试）；
- 组缺失、嵌套组、空成员的明确报错路径。
- 报告须写明：PC-09 未开工，含 Failover/LowestLatency 组的快照必然构建失败，这是设计上的 fail-closed，不是缺陷。
