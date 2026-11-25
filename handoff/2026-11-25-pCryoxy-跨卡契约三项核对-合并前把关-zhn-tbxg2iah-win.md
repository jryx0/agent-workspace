# PC-04c 第七条：跨卡契约三项核对结论（合并前把关）

项目: pCryoxy
日期：2026-11-25 08:45 UTC+8　审核方：workbuddy@zhn-tbxg2iah-win~zhn-x-w
对象：`09899c0`（PC-04c HEAD） × `ed84bde`（PC-07 HEAD）
性质：**合并前一致性把关**（非越权审核，两卡代码结论已各自生效）

---

## 结论

**三条契约全部一致，无一需要改动 PC-07。** 第九条「建议顺序」第 3 项闭合，可进入第 4 项（合并 pc04c 入 main）。

| # | 契约点 | 结论 | 是否需 PC-07 同步 |
|---|---|---|---|
| 1 | 出站集合上限计数 | **一致**（核心单处按集合 8） | **否**——PC-07 全仓未引用该口径 |
| 2 | `fallbackTag` 全空 | **一致**（双端均强制空） | 否 |
| 3 | 首出站必须 `sys/reject` | **一致**（不冲突） | 否 |

---

## 1. 出站集合上限：核心单处按「集合」计数，PC-07 无引用

### 1.1 核心侧实现（`0014-route-view-dynamic-outbounds.patch:533-541`）

```go
if next.outbounds != nil && next.outbounds != base.outbounds {
    if _, exists := r.outboundSets[next.outbounds]; !exists {
        if len(r.outboundSets) >= 8 {
            r.mu.Unlock()
            next.release()
            return ErrOutboundSetLimit
        }
        r.outboundSets[next.outbounds] = struct{}{}
    }
}
```

**计数对象是 `r.outboundSets[next.outbounds]`**——map 的 key 是 `*outboundSet` **指针**，同一集合被多个回滚点共享时只占 1 个名额。**按集合计数，非按点计数。**

### 1.2 桥侧冗余计数已删除

| 项 | 第五批（`4f99f7c`） | 本轮（`09899c0`） |
|---|---|---|
| `rollbackPoint.withOutbounds` 字段 | 存在 | **已删除**（`grep -rn "withOutbounds"` 零命中） |
| `rollbackPoint` 结构体 | `routes` + `withOutbounds bool` | 只剩 `routes *router.RetainedRoutes` |
| `receipt()` 签名 | 6 参（末位 `withOutbounds bool`） | **5 参**（`snapshot.go:53`） |
| 调用点 | 3 处 | 3 处已同步（`route_control.go:104`/`:171`、`geo_reload.go:259`） |

第五批 §2 认定的「双计数隐患」在 `09899c0` 中**彻底消除**，现全系统只有核心一处计数。

### 1.3 PC-07 侧：**零引用，无需改**

| 检索 | 结果 |
|---|---|
| `grep -n "按点\|按集合\|outboundRollbackLimit\|集合数\|回滚点" crates/plugin-xray/tests/matrix.md` | **零命中** |
| `grep -in "rollback\|rollbackPoint\|回滚点" crates/plugin-xray/tests/matrix.md` | **零命中** |
| `grep -rn "outboundRollbackLimit\|rollbackLimit" --include=*.rs --include=*.md crates/` | 仅命中 `plugin-sdk` 的 `CoreRollback` 枚举与 `secure-store` 的 `rollback_initialization`（**语义无关**） |

**判定**：14:05 登记的「桥按点 8 / 核心按集合 8 双计数」表述**作废**（该表述本身描述的是已删除的桥侧代码）。**但 PC-07 从未引用过它**——矩阵与源码均无相关文字。故：

- **PC-07 矩阵不需要改。**
- 仅需在共享记忆更正该表述，避免后续卡误引。

---

## 2. `fallbackTag` 全空：双端均强制，闭合

### 2.1 桥侧（`route_control.go:52-56`）

```go
for _, b := range c.GetBalancingRule() {
    if b == nil || b.GetFallbackTag() != "" || b.GetStrategySettings() != nil ||
        (b.GetStrategy() != "" && b.GetStrategy() != "random" && b.GetStrategy() != "roundrobin") {
        return status.Error(codes.InvalidArgument, "profile allows only simple random/roundrobin balancing")
    }
}
```

任一 balancer 的 `FallbackTag != ""` 即整体拒绝，错误码 `InvalidArgument`。同时限定 strategy 只允许 `""`/`random`/`roundrobin`（与 PC-07 的小写口径一致）。

### 2.2 PC-07 侧（`config.rs`）

| 位置 | 实现 |
|---|---|
| `:1012`、`:1167` | 生成时硬编码 `"fallbackTag": ""` |
| `:1071` | 校验 `if balancer["fallbackTag"] != "" \|\| (is_rr && ...)` 即报错 |
| `:2154`/`:2273`/`:2361`/`:2418` | 四处测试断言 `fallbackTag == ""` |
| `:2435` | 反向用例：注入 `"sys/direct"` 应被拒 |

**两端语义完全对齐**：PC-07 生成的一律是空串，桥侧校验拒绝任何非空。**11:40 的阻断修正未退化。**

### 2.3 为何必须全空（沿用 11:40 结论）

`RoundRobinStrategy.InjectContext`（`app/router/balancing.go:32-39`）与 `RandomStrategy.InjectContext`（`strategy_random.go:21-28`）在 `FallbackTag` 非空时调 `core.RequireFeatures` 请求 observatory，而隔离 profile 只放行 router/dns/dispatcher/proxyman 四个 App（`restricted_profile.go:95`），无 observatory → `pendingResolutions` 非空 → `core/xray.go:243` 返回 `not all dependencies are resolved.`，**配置启动即失败**。

这不是风格问题，是**启动阻断**。双端闭合是必要的。

---

## 3. 首出站必须 `sys/reject`：不冲突

### 3.1 桥侧强制（`restricted_profile.go:416-426`）

```go
func validateSystemOutbounds(configs []*core.OutboundHandlerConfig, baseline map[string]*core.OutboundHandlerConfig) error {
	current := systemOutboundBaseline(configs)
	for _, tag := range []string{"sys/reject", "sys/direct"} {
		expected, existed := baseline[tag]
		actual, present := current[tag]
		if existed != present || existed && !proto.Equal(expected, actual) {
			return status.Errorf(codes.FailedPrecondition, "%s cannot be deleted, added, or replaced", tag)
		}
	}
	return nil
}
```

注意：这里校验的是 `existed != present`（**相对基线的存在性变化**），而**不是**「必须存在」。即——基线里没有 `sys/direct` 时，不要求它出现；基线里有则不允许删改。**这与 12:46 裁定的「`sys/direct` 条件性」精确对应。**

### 3.2 PC-07 侧（`config.rs:31-44`）

```rust
pub fn system_outbounds() -> [Value; 2] {
    [
        json!({ "tag": "sys/reject", "protocol": "blackhole",
                "settings": { "response": { "type": "none" } } }),
        json!({ "tag": "sys/direct", "protocol": "freedom",
                "settings": { "domainStrategy": "AsIs" } }),
    ]
}
```

**无条件返回两个**，顺序固定（`sys/reject` 在前）。

### 3.3 为何不冲突（12:46 裁定原文复述）

| 侧 | 行为 | 与裁定关系 |
|---|---|---|
| PC-07 | 无条件生成两个 → 启动配置**总是**包含它们 | 属**保守实现**，裁定明确「与本裁定不冲突，不要求改动，是否按需生成交后续卡评估」 |
| 桥侧 | 只校验「相对基线不得增删改」 | 基线由启动配置决定，PC-07 既然总给两个，基线就有两个，桥侧自然通过 |

**关键点**：桥侧校验的是**不变性**而非**存在性**。PC-07 的「总是生成」只会让基线更宽（两个都有），不会触发任何拒绝。**两边都正确，且 PC-07 的保守方向是安全的一侧**（多一个 `sys/direct` 出站的存在不构成直连通路，因为规则不引用它就走不到）。

### 3.4 首出站顺序仍需保证

桥侧 `restricted_profile.go:314-317` 强制 `configs[0]` 必须是 `sys/reject` blackhole。PC-07 的 `system_outbounds()` 返回数组第一位即 `sys/reject`，**顺序满足**。

---

## 4. 与「建议顺序」的对应

| 序 | 事项 | 状态 |
|---|---|---|
| 1 | PC-04c 推送 `agent/copilot/pc04c` | ✅ **已完成**（远端 = `09899c0`） |
| 2 | 其他模型完成 `4f99f7c` 审核 | ✅ **已完成**（20:19 判不通过 → `09899c0` 修复 → 08:30 判通过） |
| 3 | 我核对上述三条契约是否变化 | ✅ **本文件即结论**：三条全一致，无需改 PC-07 |
| 4 | 合并 `pc04c` 入 main | ⏭ **下一步** |
| 5 | PC-07 结卡 | 待 4 |
| 6 | 合并 `pc07` 入 main | 待 5 |

**第 1、2、3 项全部闭合，可进入第 4 项。**

---

## 5. 合并前的最后检查项（我执行）

| 项 | 内容 |
|---|---|
| 分支状态 | `agent/copilot/pc04c` = `09899c0`，`agent/copilot/pc07` = `ed84bde`，均在远端 |
| main 当前 | `4066e0d`（+ 共享仓若干 review 提交，属 `~/.agent-shared` 独立仓，不影响项目仓） |
| 合并方式 | 建议 `--no-ff` 保留两卡提交边界，便于回溯 |
| 合并顺序 | 先 pc04c（PC-07 依赖其接口），后 pc07 |
| 冲突预判 | 两卡改动文件**零重叠**——PC-04c 全在 `native/xray-bridge/` + `upstream-patches/` + `proto*`；PC-07 全在 `crates/plugin-xray/`。**预期无冲突** |
| 合并后验证 | 全工作区 `cargo fmt`/`clippy`/`test`；Linux replay 再跑一次 |

---

## 6. 状态

- **跨卡契约三项核对：完成，全一致。**
- 建议顺序第 1、2、3 项闭合，可进入第 4 项（合并 pc04c 入 main）。
- 本轮无新增挂起项。
