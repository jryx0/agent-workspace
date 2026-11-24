# PC-07 裁定：单节点合成 balancer 命名、Failover/LowestLatency 延后

日期：2026-11-24 10:50 UTC+8　裁定方：workbuddy@zhn-tbxg2iah-win~zhn-x-w
状态：**人类已确认（10:44 页2 选1、10:48 页1 选1）**。本文取代 10:36 裁定（586b821）中关于 selector 形态的单一限制。
对象：copilot 两处提问，依据固定核心 676eaf6 与 IR 现状

## 1. 人类选择

| 问题 | 选择 | 说明 |
| --- | --- | --- |
| `Action::Node` 的规则怎么生成 | 选项 1：转成单节点合成 balancer | 规则仍全部指向 balancer，不覆盖蓝图 §3.2 |
| 单节点合成 balancer 的 tag | 选项 1：`pool/group/node-<node-id>` 等三个 tag | 用字符串 `node-` 与数字 group-id 天然隔离 |
| Failover / LowestLatency 本轮 | 选项 1：fail-closed，等 PC-04c 运行期 override | 不写 `roundrobin` 冒充 |

作废：审核方上一轮建议的 `pool/rule/<node-id>/…` 命名，不使用。

## 2. 三个 tag（最终）

```text
balancer   pool/group/node-<node-id>
selector   pool/node-<node-id>/
出站        pool/node-<node-id>/<node-id>/<revision>
```

- 出站保留第二个 `<node-id>` 段：与分组出站 `pool/<group-id>/<node-id>/<revision>` 同为四段，解析侧一套逻辑覆盖两种形态。不做三段简化。
- `node-` 后必须纯十进制、无前导零、无负号、非空。

## 3. selector 形态（收紧，替换 586b821 §4.1～§4.2）

只允许两种，其余一律拒绝：

```text
pool/<十进制数字>/
pool/node-<十进制数字>/
```

- 都必须以 `/` 结尾。
- 禁止 `pool/`、`pool/group/`、`probe/` 开头的 selector。
- 前缀隔离依据：`strings.HasPrefix`（`app/proxyman/outbound/outbound.go:164-188`）。`pool/node-3/` 不命中 `pool/node-30/30/<rev>`；`pool/5/` 不命中 `pool/node-5/…`。

## 4. 唯一性与去重

- balancer tag 全快照唯一，两个来源合并校验：分组 `pool/group/<数字>`、单节点 `pool/group/node-<数字>`。
- 出站 tag 全快照唯一。
- 同一节点既属某分组又被规则直引：允许同时存在 `pool/<group>/<node>/<rev>` 与 `pool/node-<node>/<node>/<rev>`，不合并。
- 任何 selector 不得命中 `probe/` 前缀出站。

## 5. 单节点 balancer 参数

- 按「被规则引用的不同 node-id」去重，一个节点一个合成 balancer；多条规则共用。
- 只对 `enabled = true` 且 `action = Action::Node` 的规则生效；节点不存在报 `MissingNode(node_id)`。
- `strategy` 固定 `"roundrobin"`（小写）；`fallbackTag` 空串 → 节点被隔离后 selector 命中 0 条 → 落默认出站即 `sys/reject`。
- 规则写 `balancerTag`，不写 `outboundTag`。

## 6. Failover / LowestLatency（本轮 fail-closed）

1. 缺赢家 → `BuildError::MissingSchedulingState(group_id)`，整次构建失败，不产出半成品。
2. 赢家不在成员列表 → `BuildError::InvalidSchedulingMember(group_id, node_id)`。
3. 有合法赢家 → 只生成 1 条出站；**不写 `strategy` 字段**（现有实现 `config.rs:1002` 对所有组硬编码 `roundrobin`，因候选唯一而等价，但语义错误，必须按策略分支）。
4. `fallbackTag` 仍写 `"sys/reject"`。
5. 不得暗示启动配置表达了赢家选择：启动 JSON 的 `router.Config` 无 override 字段（`app/router/config.proto`），override 只能走 RPC 路径。
6. 运行期由 PC-04c 的 `ReplaceRoutingAndOutbounds` 带 `desired_overrides` 或 `OverrideBalancerTarget` 完成，同一 epoch。PC-07 不生成 override 结构。

## 7. 必须的测试

| # | 用例 | 断言 |
| --- | --- | --- |
| 1 | 节点 1 与 10 都被规则引用 | `pool/node-1/` 候选只有 `pool/node-1/1/<rev>`，不含 `pool/node-10/10/<rev>` |
| 2 | 分组 5 与节点 5 并存 | `pool/5/` 不含 `pool/node-5/5/<rev>`；`pool/node-5/` 不含 `pool/5/…` |
| 3 | 两条规则指向同一节点 | 只生成一个合成 balancer + 一条出站 |
| 4 | 非法 selector 五例（`pool/`、`pool/group/`、`pool/node-`、`pool/node-05/`、`pool/node-5`） | 全部被拒 |
| 5 | 分组 balancer 与合成 balancer 同名 | 被拒 |
| 6 | Failover 缺赢家 | `MissingSchedulingState`，无任何 JSON 产出 |
| 7 | Failover 赢家不在成员内 | `InvalidSchedulingMember` |
| 8 | Failover 有合法赢家 | 1 条出站、balancer 无 `strategy`、`fallbackTag = "sys/reject"` |
| 9 | RoundRobin 组 | `strategy = roundrobin`、`fallbackTag = ""` |
| 10 | 遍历全部 rules | 不存在指向 `pool/` 或 `probe/` tag 的 `outboundTag`；生成 JSON 全文不出现 `override` 字样 |

## 8. 与既有裁定的关系

- 修正 586b821 §4.1～§4.2：selector 从「只允许 `pool/<group-id>/`」扩展为本节两种形态；其余条款（尾斜杠、字符集、去重排序、命中数、balancerTag 存在性、互斥、fallbackTag 限制）不变。
- 作废审核方 10:41 建议的 `pool/rule/` 命名。
