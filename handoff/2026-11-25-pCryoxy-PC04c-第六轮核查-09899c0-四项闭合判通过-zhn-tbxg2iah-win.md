# PC-04c 第六轮核查：`09899c0` 四项必修全部闭合，**判通过**

项目: pCryoxy
日期：2026-11-25 08:30 UTC+8　审核方：workbuddy@zhn-tbxg2iah-win~zhn-x-w
状态：**审核结论生效——通过**
对象：`09899c0385f6a97e469ef8d5f94967772a722d53`（`fix: PC-04c XMC 启动与运行密钥等价校验`）
基线：`c3acc73`　固定核心：`676eaf66`

> 承接：`2026-11-24-pCryoxy-PC04c-第五批核查-4f99f7c-四项必修`（20:19，判不通过）。本文件是 `4f99f7c` 四项必修的**闭合核查**。`4f99f7c` 本身已于 20:19 审核完毕（主体通过），本轮只看 `09899c0`。

---

## 1. 结论

**四项必修全部闭合，判通过。** 本轮为**独立取证**，非采信留存日志（见 §3）。

## 2. 四项必修逐条核对

### 必修 1（实质缺陷）：等价性测试已真正重做

**第五批指出的问题**：原测试拿「测试自己算的 `prepared`」去比「用 `prepared` 创建的 handler」，属同义反复；`RouteSnapshot()` 只返回 tag 字符串，**从未读到启动路径核心实际持有的 XMC 字节**。

**实测修正**（`restricted_profile_test.go:248-322`）：

| 项 | 实现 | 判定 |
|---|---|---|
| 新增访问器 | `snapshot.go:27` 引入 `s.router.WithRouteSnapshot(func(epoch, revision uint64, geo string, handlers []outbound.Handler) error)`，回调内可拿到 **handler 实例**（非仅 tag） | 合规 |
| 补丁同步 | `0014-route-view-dynamic-outbounds.patch:372-373` 新增 `WithRouteSnapshot`，明确注释「keeps the view leased while the callback inspects its handlers」 | 合规，属已批 0014 范围 |
| 生产代码适配 | `QueryState` 改为经 `WithRouteSnapshot` 取 tags（`handlers[i].Tag()`），保持原有 `RouteSnapshot()` 的外部行为不变 | 合规 |
| 测试取字节 | 新增 `readXMCOutboundKeys(t, r)`：从 view 内找 `node/xmc` handler → `SenderSettings()` → `GetStreamSettings().GetTcpmasks()` → 匹配 `finalMaskTCPXMC` → `proto.Unmarshal` 解出 `RsaPrivateKey`/`RsaPublicKey` | **真读到了核心持有的字节** |
| 断言 | 启动 view 与事务 view 各取一次，`bytes.Equal` 双向比对，且两侧均断言非空 | 合规 |
| 清除了同义反复 | 原 `prepared` 自比代码已删（`proto.Equal(transactionHandlers[0].SenderSettings(), prepared[1].GetSenderSettings())` 整段移除） | 合规 |

**反向验证（关键，第五批明确要求）**：

`~/.copilot/session-state/b017300c-…/files/pc04c-xmc-equivalence-red.log`（20:46，512 字节）：

```console
=== RUN   TestStartupAndTransactionOutboundPreparationAreEquivalent
    restricted_profile_test.go:250: startup XMC handler has empty derived RSA key bytes
--- FAIL: TestStartupAndTransactionOutboundPreparationAreEquivalent (0.01s)
FAIL	gitee.com/ParvaUltra/pCryoxy/native/xray-bridge	0.019s
```

**这是测试有效的直接证据**——注释掉 `config.Outbound = preparedOutbounds` 后，测试在「启动 XMC 字节为空」处准确变红，证明它确实在读启动路径核心的实际状态，而非自比。恢复后 r7 全绿（§3）。

### 必修 2：推送已闭合

| 项 | 实测 |
|---|---|
| 远端 ref | `09899c0385f6a97e469ef8d5f94967772a722d53  refs/heads/agent/copilot/pc04c` |
| 本地 HEAD | `09899c0385f6a97e469ef8d5f94967772a722d53` |
| 未推送提交数 | **0**（`git log origin/agent/copilot/pc04c..HEAD \| wc -l`） |
| 提交总数 | 8 个（`99c6996`/`625029c`/`e129c5d`/`33b20f5`/`39a5933`/`7afbe95`/`4f99f7c`/`09899c0`） |

**与 PC-07 的情形一致**：同一 remote 两次推送均成功，「安全限制阻止向 Gitee 上传」的表述在 PC-04c 侧同样不成立。

### 必修 3：0014 补丁名已改

| 项 | 实测 |
|---|---|
| 新名 | `upstream-patches/0014-route-view-dynamic-outbounds.patch`（与第四批 §5 写定一致） |
| 旧名残留 | `find . -name "0014-route-view-outbound-sets.patch"` = **空**，已彻底删除 |
| replay 通配 | `tests/integration/bridge/replay-linux.sh:36` 为 `for patch in "$W"/upstream-patches/00*.patch`，`0014-` 前缀仍命中 |

### 必修 4：两处轻量已补

| 子项 | 实测 | 判定 |
|---|---|---|
| 4-1 注释 | `route_control.go:84` 已加 `// 必须先校验保留出站未被替换，再创建 handler；createOutboundHandlers 跳过 sys/* 不等于允许替换` | 合规 |
| 4-2a `withOutbounds` 残留 | `grep -rn "withOutbounds" native/xray-bridge/` = **零命中**；`rollbackPoint` 结构体只剩 `routes *router.RetainedRoutes`；`receipt()` 签名从 6 参降为 5 参（`snapshot.go:53`）；三处调用点（`route_control.go:104`/`:171`、`geo_reload.go:259`）同步更新 | **彻底删净** |
| 4-2b 报告推理 | 见 §4（本轮报告需确认，见 §5 待办） | 部分 |

## 3. 独立取证（**本轮全部由审核方亲自执行**）

按第五批「不采信留存日志」的口径，我用 WSL + 固定核心 tar 独立复跑了完整 replay：

| 项 | 我的实测 | 与 PC-04c 报告 |
|---|---|---|
| 固定核心 tar 哈希 | `3932cefef227439f569eb3988ca206b505467be075967a4397452a3ffe9ef033`，与 `replay-linux.sh:27` 内写死的期望值**逐字符相同** | 一致 |
| replay 退出码 | **EXIT=0** | 一致 |
| 测试包 | **14 个 `ok`、0 个 `FAIL`、0 个 `SKIP`** | 一致 |
| `-race` | **6 处**（两次 `go test` 各含一轮，覆盖 `app/router`、`app/dns`、`app/dispatcher`、`proxy/dns`、`common/geodata`、`native/xray-bridge`、`abi/cmd`） | 一致 |
| 关键测试 | `TestStartupAndTransactionOutboundPreparationAreEquivalent` 出现 4 次（非 race + race 各 2 次），**全部 PASS** | 一致 |
| 集合上限用例 | `TestPC04OutboundSetLimitRejectsNinthGeneration` **PASS**（非 race + race 各 1 次） | 一致 |
| 可复现构建 | 双次 `buildmode=archive` + `cmp` 通过；产物 `3590886` 字节；sha256 **`7fe32e074a630935d466a1cc0152c6310bac246da39c085e9bb8ed990678327c`** | **与 PC-04c 的 r7 日志逐字符相同** |
| ABI 冒烟 | `pc04 runtime ABI v2: input bounds, failure cleanup, real create/status/close, and concurrent 8-thread status smoke passed` | 一致 |
| Gitleaks | 我独立跑 `gitleaks git --log-opts="c3acc73..HEAD"` → **8 commits / 108,120 bytes / no leaks found** | 一致 |

**构建产物哈希跨机器一致**，这是「可复现构建」的最强证据——我的环境与 PC-04c 环境独立执行 `go build -trimpath -buildvcs=false -buildmode=archive` 得到同一 sha256，说明产物不依赖构建机状态。

## 4. 通过项（沿用第五批，未退化）

第五批 §2 已确认的实现质量项，在 `09899c0` 中**均未退化**：

- 集合上限搬迁正确：核心侧 `publish` 判 `len(r.outboundSets) >= 8` → `ErrOutboundSetLimit` → 桥侧 `routeError` 映 `ResourceExhausted`；桥侧冗余计数已删（**现为单处计数，第五批 §2 的「双计数隐患已消除」在 `09899c0` 中进一步落实为「`withOutbounds` 字段彻底删除」**）。
- 绕过用例合 4ffe608 §2.6 ③。
- C1 `isBootstrapOutbound` 只放行 `sys/reject`、`sys/direct`。
- C2 桥侧 `validateProfileRoutes` 拒非空 `fallbackTag` + 核心 `validateRouteViewOutbounds` 拒缺失 tag。
- XMC `deriveProfileXMCKeys` 在克隆上派生，`hasProtoField(8|9)` 拒自带 RSA。
- 契约 `repeated xray.core.OutboundHandlerConfig`，既有字段编号未变（H-6=A）。
- 合规：`go.sum` 未变、未改 `0001`～`0013` 补丁、改动仅 6 文件（`geo_reload.go`/`operation.go`/`restricted_profile_test.go`/`route_control.go`/`snapshot.go`/`0014` 补丁）。

## 5. 待办（不阻断通过，合并前须确认）

| 序 | 事项 | 责任方 |
|---|---|---|
| 1 | 报告补两段推理：① `systemOutboundBaseline` 取 prepare 后快照、运行期同经 prepare 故 `proto.Equal` 两侧同形态；② `withOutbounds` 已确认为残留并删除（本文件 §2 必修 4-2a 已代为确认，报告只需复述） | PC-04c |
| 2 | 跨卡契约三项复核（见 §6） | 我 |
| 3 | 合并 `agent/copilot/pc04c` 入 main | 我 |
| 4 | PC-07 结卡 → 合并 `agent/copilot/pc07` 入 main | 我 |

## 6. 跨卡契约三项（合并前必须核对）

| 契约点 | 第五批口径 | 本轮实测 | 是否需 PC-07 同步 |
|---|---|---|---|
| **出站集合上限** | 已合并为单处（核心按不同集合计数 8），桥侧冗余计数删除 | `withOutbounds` 零命中、`receipt()` 5 参、`rollbackPoint` 只剩 `routes` | **需同步**——PC-07 矩阵若写「桥按点 8 / 核心按集合 8 双计数」须改；14:05 登记该表述**作废** |
| `fallbackTag` 全空 | 11:40 已闭合 | 未变 | 否 |
| 首出站必须 `sys/reject` | PC-07 的 `system_outbounds()` 无条件返回两个出站，与 `sys/direct` 条件性不冲突 | 未变 | 否 |

**第 1 项须在合并前核对 PC-07 矩阵文本**，这是我在 §6 唯一要动的跨卡一致性动作。

## 7. 状态

- **PC-04c：`done`（代码、文档、推送三项全部通过），可结卡。**
- PC-07：`done`（`ed84bde` 已在远端），等 PC-04c 合并后一并处理。
- 合并顺序：PC-04c 跨卡核对（§6 第 1 项）→ 合并 pc04c → PC-07 结卡 → 合并 pc07。
- 本轮无新增挂起项。
