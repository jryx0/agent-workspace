# PC-04c 第五批核查：4f99f7c 主体通过，四项必修

项目: pCryoxy
日期：2026-11-24 20:18 UTC+8　审核方：workbuddy@zhn-tbxg2iah-win~zhn-x-w
状态：**审核结论生效——不通过（主体正确，四项必修）**
对象：`4f99f7cd260012dc070f77d9853902abab3c2815`（`[PC-04c] feat: publish routes with managed outbounds`）
基线：`c3acc73`　固定核心：`676eaf66`

> 说明：本行是 PC-04c 的**唯一审核结论**。另一 workbuddy 会话（20:12 记忆条目）依人类 20:11「其他模型在审核」明确不复核 4f99f7c，两审核方并行不冲突。

---

## 1. 独立复核（全部属实）

| 项 | 实测 | 判定 |
|---|---|---|
| 工作树 | `git status` 全干净，HEAD = `4f99f7c` | 属实 |
| 规模 | `c3acc73..HEAD` 7 提交，22 文件 +2610/-146 | 属实 |
| r5 日志 | `~/.copilot/session-state/b017300c-…/files/pc04c-final-linux-replay-r5.log`，1341 行 / 112,551 字节 / mtime 20:04:31 | 真实非空 |
| 测试 | 14 个 `ok` 包，**0 FAIL、0 SKIP**，6 处 `-race`，`TestStartupAndTransactionOutboundPreparationAreEquivalent` 出现 4 次 | 属实 |
| 可复现构建 | 双次 `buildmode=archive` + `cmp` 通过，产物 sha256 `2c647dd7e8b61b37d818698066cdfe8c09c65130a31d2550573dc006886d4fd5` | 属实 |
| Gitleaks | **审核方独立复跑** `~/.agent-tools/bin/gitleaks git --log-opts c3acc73..HEAD`（v8.30.1）→ `7 commits scanned / 103514 bytes / no leaks found` | 属实 |
| 跨 UID 跳过 | `control_ipc_test.go:391` 仅 `t.Logf`（不 `t.Skip`），无 root/sudo 环境 | 如实降级 |

## 2. 通过项（实现质量）

- **集合上限搬迁正确**：核心侧 `publish` 中 `len(r.outboundSets) >= 8` → `ErrOutboundSetLimit` → 桥侧 `routeError` 映 `ResourceExhausted`；桥侧冗余的 `outboundRollbackLimit`/`outboundRollbackPoints()` 已删（`operation.go` 只剩 `rollbackLimit = 64` + `rollbackPoint{routes, withOutbounds}`），**消除了「按点 / 按集合」双计数的隐患**。
- **绕过用例合 4ffe608 §2.6 ③**：`TestPC04OutboundSetLimitRejectsNinthGeneration` 循环 7 次「建路由点→切出站→释放出站点」，断言 `outboundSets == 8`、第 9 个拒绝、active 与 digest 不变、候选恰好关 1 次。
- **C1**：`isBootstrapOutbound` 只放行 `sys/reject`、`sys/direct`。
- **C2**：桥侧 `validateProfileRoutes` 拒非空 `fallbackTag` + 核心 `validateRouteViewOutbounds` 拒缺失 tag，双端闭合。
- **XMC**：`deriveProfileXMCKeys` 在克隆上派生，`hasProtoField(8|9)` 拒自带 RSA。
- **契约**：`repeated xray.core.OutboundHandlerConfig`，既有字段编号未变（H-6=A）。

## 3. 四项必修

### 必修 1（实质缺陷）：等价性测试是同义反复

`restricted_profile_test.go:211-278` 的写法：

```go
prepared, _ := prepareProfileOutbounds(config.GetOutbound())   // 测试自己算一遍
startupTags := runtime.router.RouteSnapshot()                  // 只拿到 []string 标签
transactionHandlers, _ := runtime.createOutboundHandlers(prepared)
proto.Equal(transactionHandlers[0].SenderSettings(), prepared[1].GetSenderSettings())  // 拿 prepared 比自己
```

`RouteSnapshot()` 签名为 `(uint64, uint64, string, []string, bool)`，**只返回 tag 字符串**，拿不到 XMC 的 `rsa_private_key` / `rsa_public_key`。该断言只证明「`createOutboundHandlers` 忠实传递配置」，**启动路径核心实际持有的字节从未被读取**。

**判据**：删掉 `geo_reload.go` 的 `config.Outbound = preparedOutbounds` 该测试仍全绿——正是 17:33 裁定所防「回归全绿也发现不了漂移」的缺口。

### 必修 2：未推送

`git ls-remote --heads origin` 十条仍无 `pc04c`。PC-07 于 20:01 用同一 remote 推送成功，**写权限已证明正常**，不应再有安全限制类阻碍。

### 必修 3：0014 补丁名未改

仍为 `0014-route-view-outbound-sets.patch`，未改 §5 写定的 `0014-route-view-dynamic-outbounds.patch`，也未书面申请沿用。

### 必修 4：轻量两处

1. `route_control.go:81`（`validateSystemOutbounds`）后缺注释：`// 必须先校验保留出站未被替换，再创建 handler；createOutboundHandlers 跳过 sys/* 不等于允许替换`。
2. 报告三点回应仍缺：`systemOutboundBaseline` 取 prepare 后快照、运行期同经 prepare 故 `proto.Equal` 两侧同形态的推理；桥/核心两处计数关系（现已合并为单处，须更新表述）；`rollbackPoint.withOutbounds` 现只用于 receipt 传递是否属残留。

## 4. 裁定

**不通过**（主体正确、证据可采信、四项必修）。

实现质量高，非返工级；但必修 1 是「测试存在却证明不了目标命题」，按 17:33 裁定「第二步未做 = 不通过」口径计未完成。

## 5. 第五批提示词（可直接粘贴）

> **PC-04c 第五批：等价性测试重做 + 三项收尾**
>
> `4f99f7c` 已核：工作树干净、r5 日志真实（1341 行 / 14 包 ok / 0 FAIL / 6 处 race / 双次构建 cmp 通过）、gitleaks 审核方独立复跑 7 提交 103.51KB 无泄漏、集合上限 8 与绕过用例符合 4ffe608 §2.6 ③。**一处实质缺陷 + 三项收尾**，补齐即通过。
>
> ### 一、等价性测试重做（必修，当前是同义反复）
>
> `TestStartupAndTransactionOutboundPreparationAreEquivalent` 现在拿「测试自己算的 `prepared`」去比「用 `prepared` 创建的 handler」，属同义反复；`RouteSnapshot()` 只返回 tag 字符串，**根本没读到启动路径核心持有的 XMC 字节**。删掉 `geo_reload.go` 那行 `config.Outbound = preparedOutbounds` 测试仍全绿，就是这个原因。
>
> 要求：
>
> 1. 给 `Router` 加一个能取到 **view 内 handler 实例**的访问器（建议把 `RouteSnapshot()` 改为返回 `[]outbound.Handler`，`snapshot.go` 里再 `handler.Tag()` 取标签；或新增 `RouteOutboundHandlers() map[string]outbound.Handler`，二选一，理由写进报告）。改 `0014` 补丁属已批范围。
> 2. 测试改为：启动后**从该访问器取出 `node/xmc` 的 handler**，读其 `SenderSettings()` 解出 XMC 的 `rsa_private_key` / `rsa_public_key`；再走 `ReplaceRoutingAndOutbounds` 提交同密码 XMC，从新 view 取同两字段；断言**两组字节 `bytes.Equal` 且均非空**。
> 3. 加一条**反向验证**：临时把 `config.Outbound = preparedOutbounds` 注释掉跑一次，确认该测试**变红**，把这次「红」的记录写进报告（证明测试有效）。跑完恢复。
>
> ### 二、推送（必修）
>
> `agent/copilot/pc04c` 推到 `origin` 同名分支，给 `git ls-remote --heads origin | grep pc04c` 输出。PC-07 的 `agent/copilot/pc07` 同样待推，一并处理或明确交代由谁推。
>
> ### 三、0014 补丁名（必修）
>
> 改名 `0014-route-view-dynamic-outbounds.patch` 并确认 `replay-linux.sh` 的 `00*.patch` 通配仍命中；或书面申请沿用现名并写清理由。二选一，不得沉默。
>
> ### 四、补两处（轻量）
>
> 1. `route_control.go:81` 后加一行注释：`// 必须先校验保留出站未被替换，再创建 handler；createOutboundHandlers 跳过 sys/* 不等于允许替换`。
> 2. 报告回答：`systemOutboundBaseline` 取 prepare 后快照，运行期提交同经 prepare，故 `proto.Equal` 两侧形态一致——请复述这条推理；另说明 `rollbackPoint.withOutbounds` 现在只用于 receipt 传递，是否属残留。
>
> ### 约束
>
> `go.sum` 不变；不改 `0001`～`0013`；每提交跑 Gitleaks；清单外文件先申请；不部署、不合并、不推项目 `main`。

## 6. 状态

- PC-04c：`doing`，未推送、未合并。本轮**不新增**挂起项。
- 合并顺序（沿用 20:12 记忆条目 ⑨）：推送 → 4f99f7c 审核（本文件即结论）→ 跨卡契约三项核对 → 合并 pc04c 入 main → PC-07 结卡 → 合并 pc07 入 main。
- 跨卡契约三项待核（不属越权审核，属合并前一致性把关）：
  1. 出站集合上限：**本轮已合并为单处（核心按不同集合计数 8）**，桥侧冗余计数删除，14:05 登记的「桥按点 8 / 核心按集合 8 双计数」表述作废，PC-07 矩阵若引用该口径需同步。
  2. `fallbackTag` 全空：11:40 已闭合。
  3. 首出站必须 `sys/reject`：PC-07 的 `system_outbounds()` 无条件返回两个出站，与 `sys/direct` 条件性不冲突。
