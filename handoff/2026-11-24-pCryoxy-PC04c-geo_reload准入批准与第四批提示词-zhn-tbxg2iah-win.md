# PC-04c 裁定：批准 `geo_reload.go` 最小启动准备集成（选 1）与第四批提示词

项目: pCryoxy
日期：2026-11-24 17:35 UTC+8　裁定方：workbuddy@zhn-tbxg2iah-win~zhn-x-w
状态：**人类已批准（17:29「可以」）——本文件为生效裁定**
对象：copilot `#pc04c` 会话的确认对话框（"Approve the minimal change" / "Do not modify; pause"）
依据：worktree `~/source/pCryoxy.wt/copilot-pc04c` 现状（HEAD `7afbe95` + 13 改 1 新未提交）、v2 申请 `a471dd9` §5、H-9=A 裁定、`4ffe608` 验收七条

---

## 1. 裁定：选 1，附五条条件

**结论**：批准在 `native/xray-bridge/geo_reload.go` 的 `RegisterRuntime` 中做最小启动准备集成——只允许「接住 `prepareProfileOutbounds` 返回值 → 写回 `config.Outbound` → 捕获 `systemOutboundBaseline` → 传给 `registerRuntime`」这一条链路。

**不是方便解法，是唯一可行解**：

- `core.New(config)` 在本仓只在 `geo_reload.go:96` 出现一次，启动路径无从绕过。
- `ValidateRestrictedProfile` 必须保持纯函数（`TestValidateRestrictedProfileIsPure` 锁死），prepare 的派生结果在纯校验里被丢弃，根因就在这里。
- 若不在启动点接住返回值，则「启动与运行时使用同一 prepare」这条不变量不成立：XMC RSA 启动时为派生前的空值、`systemOutbounds` 基线无从建立，`ReplaceRoutingAndOutbounds` 的 `validateSystemOutbounds` 失去比对基准。选 2（不改，停下另申请）等于让 PC-04c 停摆，把阻塞推给下一轮审批。
- 改动面 `+8/-3`：插在既有 `ValidateRestrictedProfile` 之后；`config` 已在函数上方 `proto.CloneOf` 过，不污染调用方；未触碰 `core.New`/`Start`/发布语义/错误路径。

### 条件（缺一即视为未获批）

1. **范围锁死**：只允许上述三处（prepare 返回值接管、基线捕获、传参）。不得顺带改 Geo 注册、`PublishScoped` 流程、错误码枚举、`RuntimeStartStage` 取值。
2. **同时批准 `operation.go`**：`rollbackPoint` 结构、`outboundRollbackLimit = 8`、`outboundRollbackPoints()`、`ErrOutboundSetLimit → ResourceExhausted` 映射已于 `39a5933` 落地，但 `operation.go` **同样不在** v2 §5 非契约清单（清单为 `restricted_profile*.go`／`route_control.go`／`runtime*.go`／新增桥内文件／`snapshot.go`）。两个文件一并批准，报告逐项给改动行范围与理由。
3. **补等价性测试**：现有 `TestRegisterRuntimeRepeatsPrepareBeforeAssetPreflight` 只证「先 prepare 再预检」，须新增断言「启动产物中 XMC RSA 非空，且与运行时 `ReplaceRoutingAndOutbounds` 同密码派生结果一致」。缺这条则回归全绿也发现不了启动/运行时漂移。
4. **0014 补丁改名或书面批准偏差**：§5 写定 `0014-route-view-dynamic-outbounds.patch`，实际为 `0014-route-view-outbound-sets.patch`。
5. **补 gitleaks + 立即提交**：`e129c5d`／`33b20f5`／`39a5933` 三提交无 gitleaks 日志（仅 `7afbe95` 有），须逐提交补跑留档；工作树自 15:33 起未提交近 2 小时，按 三-5 须立即落盘。

---

## 2. 已核通过项（本轮认定，不重复要求）

| 项 | 位置 | 结论 |
|---|---|---|
| C5 出站 socket_settings 默认全拒 | `restricted_profile.go:521-524`，`stream.GetSocketSettings() != nil` 即 `FailedPrecondition` | 通过，`e129c5d` |
| C5 入站侧 | `restricted_profile.go:286-289`，同口径拒非 nil | 通过，`7afbe95`；方向正确，入站 `Mark`/`Tproxy` 同样越出受限面 |
| C4 policy/stats 测试 | `restricted_profile_test.go` 新增 `policy-app`／`stats-app` 两例 | 通过，`33b20f5` |
| C1 无 scope 分发 | 0014 的 `app/dispatcher/default.go` 加 `isBootstrapOutbound`，非 `sys/reject`／`sys/direct` 一律返回 nil | 通过（二选一里的「限定只命中 bootstrap」） |
| C3 script 拒绝 | `validateProfileRoutes` 拒 `Script`，`TestValidateProfileRoutesRejectsScriptsAndFallbackTags` 覆盖；0014 未含 `app/router/lua.go` | 通过 |
| C2 fallbackTag | 桥侧 `validateProfileRoutes` 拒非空 `FallbackTag`；核心 `validateRouteViewOutbounds` 拒缺失 tag | 通过（提前闭合「桥通过、核心起不来」） |
| H-9 集合上限 | 补丁 `ErrOutboundSetLimit`，`publish` 中按「不同集合数、active 不计」判 8；`TestPC04OutboundSetLimitAllowsEightRetainedSets` 断言 `len(outboundSets) == 9` 且第 9 次拒绝时 active 不变、候选恰好关闭 1 次 | 方向正确，见 §3 疑点 |
| 引用计数 | `outboundSet.refs` + `retain`/`release`，`routeView.release()` 补 `v.outbounds.release()`，最后引用时关闭 `owned` | 通过结构审查 |
| 契约 | `ReplaceRoutingAndOutbounds` 用 `repeated xray.core.OutboundHandlerConfig`，既有字段编号未变 | 符合 H-6=A |
| XMC | `deriveProfileXMCKeys` 在克隆上派生，`hasProtoField(8|9)` 拒绝自带 RSA | 符合 v2 §2 |
| 启动 prepare 顺序 | prepare 在 `ValidateRestrictedProfile` 之后、`core.New` 之前 | 通过 |

---

## 3. 待 copilot 答复的疑点（不阻断提交，但须在报告里回应）

1. **`systemOutbounds` 基线取自 prepare 后**：`systemOutboundBaseline(preparedOutbounds)` 在派生 XMC 之后取值。当前 `sys/reject`／`sys/direct` 均不含 XMC，等价；但若将来基线含派生字段，`validateSystemOutbounds` 的 `proto.Equal` 会因运行期提交的是「未派生」还是「派生后」而分叉。请在报告写明「基线为派生后快照，运行期提交的 system 出站同样经 prepare，故两侧同形态」。
2. **`createOutboundHandlers` 跳过 `sys/reject`／`sys/direct`**：当前靠 `validateSystemOutbounds` 保证它们未被改动。请确认顺序——先 `validateSystemOutbounds` 再 `createOutboundHandlers` 已经成立（`route_control.go` 中是先校验后创建），并在报告中点明「跳过不等于允许替换」。
3. **`session` 级 `s.points` 与核心 `outboundSets` 两处计数**：桥侧 `outboundRollbackPoints()` 按 `withOutbounds` 计数、核心按不同集合计数。两者在「同一集合被多个点共享」时不等值（桥侧 2、核心 1）。请说明为何不需要让两处对齐，以及第 9 个集合被核心拒绝时桥侧是否会先误判——桥侧 8 是「点」的上限，比核心的「集合」上限更严，方向安全，但报告须显式写出这条推理。

---

## 4. 第四批提示词（可直接粘贴给 copilot `#pc04c`）

> **PC-04c 第四批：geo_reload 最小集成获批 + operation.go 补批 + 等价性测试 + 证据补齐**
>
> 人类 17:29 已批准选项 1「Approve the minimal change」。范围从严，只批下列两项文件，其余改动仍须先申请。
>
> ### 一、`geo_reload.go` 批准（设计已核，勿扩大）
>
> 允许的改动**只有**三处：
>
> 1. `ValidateRestrictedProfile` 之后接住 `prepareProfileOutbounds(config.Outbound)`，失败按 `RuntimeStartStageProfile` 返回；
> 2. `config.Outbound = preparedOutbounds`（`config` 已在函数上方 `proto.CloneOf`，不得再克隆第二次）；
> 3. `systemOutbounds := systemOutboundBaseline(preparedOutbounds)` 并作为第 6 参传给 `registerRuntime`。
>
> **禁止**：改 Geo 注册／`PublishScoped`／`fail` 与 `cleanup` 语义、新增 `RuntimeStartStage`、改 `core.New`/`Start` 调用位置、把 prepare 移进 `ValidateRestrictedProfile`（那会破坏 `TestValidateRestrictedProfileIsPure`）。
>
> ### 二、`operation.go` 补批
>
> `39a5933` 已落地的 `rollbackPoint`、`outboundRollbackLimit = 8`、`outboundRollbackPoints()`、`routeError` 中 `ErrOutboundSetLimit → ResourceExhausted` 一并获批。此文件此前在 v2 §5 清单外，属补批，不是新增授权：**不得借补批新增其他字段或改 `rollbackLimit = 64`**。
>
> ### 三、等价性测试（必做，缺则不打通过）
>
> 新增一个测试（可并入 `outbound_control_test.go`）：同一份含 XMC `final_mask` 的 profile，分别走
>
> - 启动：`RegisterRuntime` 后从核心实际持有的出站配置取 XMC 的 `rsa_private_key`/`rsa_public_key`；
> - 运行时：`ReplaceRoutingAndOutbounds` 提交同密码的 XMC 出站；
>
> 断言两者**字节相等**，且均非空。这条用来锁死「启动与运行时同一 prepare」不变量——现有 `TestRegisterRuntimeRepeatsPrepareBeforeAssetPreflight` 只证顺序，证不了结果一致。
>
> ### 四、补证据
>
> 1. `e129c5d`、`33b20f5`、`39a5933` 三个提交**缺 gitleaks 日志**（现只有 `gitleaks-7afbe95.log`）。逐提交补跑，日志落 `~/.agent-tools/run/pc04c/logs/gitleaks-<sha>.log`，报告给 sha256。
> 2. 0014 补丁文件名：§5 写定 `0014-route-view-dynamic-outbounds.patch`，实际为 `0014-route-view-outbound-sets.patch`。**改名为 §5 的名字**（`git mv`，内容不变），并确认 `replay-linux.sh` 的 `00*.patch` 通配仍能命中；若你判断改名会破坏已留存的回放日志可比性，则改为在报告里书面申请沿用现名，二选一，不得沉默。
> 3. 工作树自 15:33 起未提交，已超 10 分钟纪律。**立即按逻辑分组提交**，建议拆四个：契约生成物、桥侧运行时（route_control/runtime/snapshot/restricted_profile）、0014 补丁、测试。每提交跑一次 gitleaks。
>
> ### 五、报告须回应三点
>
> 1. `systemOutboundBaseline` 取的是 prepare 后快照，请说明运行期提交的 system 出站同样经 prepare，故 `proto.Equal` 两侧同形态；
> 2. `createOutboundHandlers` 跳过 `sys/reject`／`sys/direct` 时，靠**先** `validateSystemOutbounds` **后** `createOutboundHandlers` 保证「跳过不等于允许替换」，请在代码注释与报告中同时写明这条顺序依赖；
> 3. 桥侧 `outboundRollbackPoints()` 按「点」计数、核心按「集合」计数，共享集合时两者不等值（桥 2／核心 1）。请说明桥侧上限更严、方向安全，不要求对齐。
>
> ### 约束（不变）
>
> - `go.sum` 不得变化；不改 0001～0013 补丁。
> - 每个提交单独跑 Gitleaks 留日志。
> - 清单外文件先申请，含 `native/xray-bridge/*_test.go` 之外的一切。
> - 不部署、不合并、不推项目 main；`agent/copilot/pc04c` 与 `agent/copilot/pc07` 仍未推送远端，本轮结束前推到 `origin` 同名分支并给 `git ls-remote` 核对输出。

---

## 5. 与 PC-07 的关系

- PC-07 结卡仍等 PC-04c done，本条不改变依赖。
- PC-07 上一轮四项偏差（矩阵表述、`P0 裁剪` 缺失、错误码 `masque-finalmask` vs `masque-finalmask-unsupported`、Hysteria2 `final_mask` 回归）见 `2026-11-24-pCryoxy-PC07-原生传输边界与allowInsecure裁定-…md` §7.6，与本文件无关，不合并处理。

## 6. 登记项

- 本轮**不新增**挂起项；PC-04c 保持 `doing`。
- 主仓 `~/source/pCryoxy` 的 `**/target/` 已由 `4066e0d` 以独立 chore 承载，A-6 越界已按甲方案收敛，本文件不再重提。
