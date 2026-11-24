# PC-04c 裁定：`sys/direct` 条件性存在 + H-9 回滚点出站集合上限

日期：2026-11-24 12:46 UTC+8　裁定方：workbuddy@zhn-tbxg2iah-win~zhn-x-w
状态：**人类已确认（12:44 选 3；H-9 于 12:41 确认「按建议」）**
对象：copilot 提问「启动时缺少 `sys/direct` 的处理」；H-9「回滚点持有旧出站的资源上限」
项目：pCryoxy　固定核心：676eaf66f8f05d4d558ee7a74b4736623d3feeb9

## 一、`sys/direct` 条件性存在（选 3）

### 1.1 结论

`sys/reject` 与 `sys/direct` 的强制性**不同**：

| 出站 | 强制性 | 理由 |
| --- | --- | --- |
| `sys/reject` | **强制**。首出站必须是 blackhole 且 tag 为 `sys/reject`，response 只允许空或 `none` | 未匹配流量靠它 fail-closed，缺失即漏向直连 |
| `sys/direct` | **条件性**。仅当路由规则中存在 `Action::Direct`（对应 `outboundTag = "sys/direct"`）时才需要；无直连规则时不必存在 | 蓝图 v0.3 §326「**显式**直连为 `sys/direct`」——显式即按需 |

桥侧**不因缺少 `sys/direct` 而拒绝**。这是对卡面的收窄澄清，不是新增准入口径。

### 1.2 为什么否掉选项 1（启动必须包含 `sys/direct`，缺失即拒绝）

1. **依据不成立**：任务卡 v1.3 §3.1 与 v2 申请 §1 的「不可删除、不可替换」是**按 tag 比对的运行时约束**，不是存在性约束。启动时没有 `sys/direct`，就没有实例需要保留，规则天然满足。copilot 所说「没有可供比较和保留的原始 handler」把两种约束混为一谈。
2. **与蓝图冲突**：蓝图 v0.3 §326 写「显式直连为 `sys/direct`」。强制存在会为纯代理场景凭空造一个直连出站，违反「默认拒绝」。
3. **安全方向相反**：多一个 freedom 出站就多一条潜在直连通路。选 1 是在没有直连需求的配置里**引入**直连能力，是放宽而非收紧。

### 1.3 为什么否掉选项 2（启动可缺省，首次运行时提交必须显式创建）

1. **违反核心不变量**：v2 申请 §1 明文要求「运行时及启动 prepare 使用同一出站准入/规范化函数，测试同一输入在两入口的接受、拒绝及派生结果一致」。让运行时的能力大于启动时，直接违反该条。
2. **开后门**：运行期凭空创建 `sys/direct` 等于给应用一条「运行时可新增直连出站」的通路，与「`sys/direct` 不可删除、不进动态池」的意图相反。

### 1.4 落地口径（桥侧）

1. `validateProfileOutbounds`（`restricted_profile.go:313-370`）**维持现状**：只强制 `configs[0]` 为 `sys/reject` blackhole（`:314-316`），**不要求** `sys/direct` 存在。补一条注释说明 `sys/direct` 是条件性出站。
2. 桥不因缺少 `sys/direct` 报错。路由规则若引用 `sys/direct` 而出站集合中不存在，由既有的「实际引用缺失 tag 即失败」路径拒绝（v2 §1 已定），**不需要新逻辑**。
3. 运行时整组提交的保留逻辑保持：提交中出现的 `sys/reject`、`sys/direct` 必须与启动实例同 tag 同实例；提交中**不出现** `sys/direct` 时不视为删除——因为启动时也不存在。
4. 补测试五项：

| # | 用例 | 断言 |
| --- | --- | --- |
| a | 只有 `sys/reject`、无 `sys/direct` | prepare 通过 |
| b | 上述配置启动后发未匹配流量 | 落 `sys/reject`、**不直连**（复用 `TestDefaultRejectDoesNotDialUnmatchedDestination` 的 listener 断言方式，但去掉 `sys/direct`） |
| c | 有 `sys/direct` 且被 `Action::Direct` 规则引用 | 正常通过，流量走直连 |
| d | 有 `sys/direct` 但无规则引用 | 允许，不报「多余出站」 |
| e | 规则引用 `sys/direct` 但出站集合无该 tag | 提交失败、active 不变 |

### 1.5 PC-07 侧

PC-07 的 `system_outbounds()`（`config.rs:27-41`）**无条件**返回 `sys/reject` + `sys/direct`，属「总是提供」的保守实现，与本节不冲突。**本裁定不要求 PC-07 改动**；是否改为按需生成交由后续卡评估。

## 二、H-9：回滚点出站集合上限（选 A，含计数对象精确化）

### 2.1 人类选择

**选项 A**：回滚点继续持有旧 handler（保证精确回滚），另设资源上限；超出返回 `ResourceExhausted`，须先释放。仅路由/Geo 的回滚点仍按 64 计。

### 2.2 计数对象（关键精确化，人类 12:41 确认）

**上限 8 的对象是「同时存活的、不同的出站集合数」（含 active 集合），不是回滚点数量。**

即回滚点最多持有 7 个旧集合。回滚点总数仍为 `rollbackLimit = 64`（`operation.go:15`），本裁定不调整。

### 2.3 为什么不能按「点」计数

**按「出站提交产生的点」计 8 可被绕过**：

```text
建路由点 P1（共享 S1）→ 切换出站 S2 → 释放出站点 → 再建路由点 P2（共享 S2）→ …
```

每次只占 1 个出站点，但每个路由点各持一个不同旧集合；64 个点即可让 64 个集合存活，8 的上限失效。

**按「所有含出站的点」计 8 则会把路由/Geo 点一并压到 8**，与「只改路由或 Geo 仍为 64」冲突。

两者都不成立。根因是拿「点」当资源单位；实际消耗 netstack、后台 goroutine 与内存的是**集合**。

### 2.4 两个上限各自约束什么（不冲突）

| 上限 | 约束对象 | 值 |
| --- | --- | --- |
| 不同出站集合数 | 出站 handler 的 netstack、后台 goroutine、内存 | **8**（含 active） |
| 回滚点总数 | 路由/Geo 快照的保留数量 | 64（不变） |

路由/Geo 更新**不创建新集合**，只给当前集合加引用，因此不计入 8。但若该点是在某次出站切换**之前**创建的，它持有的旧集合会计入 8——那个集合确实仍存活，属正确核算，不是例外。

### 2.5 0014 必须落实的前置（R-3）

1. **出站集合加引用计数**：`routeView.release()`（0002 补丁 `route_view.go:267-277`，现状只释放 hooks / script / dnsLife）在最后一个引用释放时**恰好关闭一次**集合。现有 0013 的 `release()` 完全不处理 `outbounds`，必须补齐，否则 2.2 的计数无意义。
2. **核心持有存活集合计数**：出站提交在「将出现第 9 个不同集合」时返回 `ResourceExhausted`，`active` 与旧集合不变，**不产生回滚点、不产生已应用回执**（与 `route_control.go:61-63` 现有 `rollbackLimit` 拒绝同型）。
3. **释放路径按集合粒度递减**：`ReleaseRollbackPoint`（`route_control.go:113-131`）与 `Runtime.Close`（`runtime.go:185-193`）释放引用时递减，最后引用释放才关闭；禁止 use-after-close、重复关闭、泄漏。
4. **计数放核心即可，桥侧不需要改 `geo_reload.go`**：出站提交路径在 `route_control.go`（清单内），回滚点登记与释放经 `snapshot.go`（H-8 已批准）、`route_control.go`，均在 v2 §5 范围内。若最终确需改 `geo_reload.go`，按 v2 §5 另行申请。

### 2.6 验收

| # | 用例 | 断言 |
| --- | --- | --- |
| 1 | 8 个不同出站集合同时存活 | 允许 |
| 2 | 第 9 个不同集合 | `ResourceExhausted`，`active` 不变 |
| 3 | 绕过用例：建路由点 → 切出站 → 释放出站点 → 重复 | 第 9 个不同集合仍被拒（证明按集合计数，不按点计数） |
| 4 | 同一集合被 64 个回滚点共享 | 允许，集合数仍为 1 |
| 5 | 8 个集合同时存在 | 记录 goroutine 数与内存；全部释放后回到基线 |
| 6 | publish / rollback / release / Close 各路径 | `-race` 下无竞态、无泄漏、无 use-after-close |
| 7 | 失败候选 | 不留可观察副作用（stats、handler、goroutine），`active` 与旧回滚点不变 |

### 2.7 8 这个数的说明

原 H-9 提案想的是「8 个回滚点」，现在变成「8 个集合」。若单个集合的出站数很多（如 100 节点），8 个集合仍然偏重。验收第 5 条要求实测内存，**若超预算再下调，先不预设更小的值**。

## 三、与既有裁定的关系

- 本裁定 §一 是对任务卡 v1.3 §3.1「`sys/reject`、`sys/direct` 不可删除、不进动态池」的**收窄澄清**：该条是运行时按 tag 比对的约束，不构成启动时的存在性要求。
- 本裁定 §二 落实 v2 审核意见（a471dd9）§3 H-9 选项 A，并精确化计数对象。
- 不修改 v2 申请的任何其他条款；不修改已审补丁 0001～0013。

## 四、依据

- 蓝图 v0.3 §326（`handoff/2026-11-20-pCryoxy-工程蓝图-v0.3-zhn-tbxg2iah-win.md:326`）：「显式直连为 `sys/direct`」
- 任务卡 v1.3 §3.1（`:78-79`）
- PC-04c v2 申请 §1、§5（`handoff/2026-11-24-pCryoxy-PC04c-Control出站接口变更申请v2-copilot-zhn-tbxg2iah-win.md`）
- v2 审核意见（a471dd9）§3 H-9、C1
- 桥侧代码：`restricted_profile.go:313-370`、`route_control.go:61-63,113-131`、`operation.go:15`、`runtime.go:185-193`
- 核心补丁：`0002-router-versioned-route-view.patch:267-277`、`0013-route-view-outbound-dns.patch:283,304,318,439-443`
