# pCryoxy `native/xray-bridge/go.sum` 基线缺陷修复方案

| 项 | 内容 |
|---|---|
| 方案日期 | 2026-11-25 |
| 编制 | workbuddy@zhn-tbxg2iah-win~zhn-x-w |
| 缺陷对象 | `native/xray-bridge/go.sum`（366 行 / 167 个模块）缺 `github.com/xtls/xray-core` 全部条目 |
| 基线 | main `8954eb0`（PC-04c 与 PC-07 均已并入） |
| 结论 | **此前「补 go.sum 两行即可修好」的定性错误，本方案予以推翻并重新定位** |
| 交付边界 | 本文档仅为方案，**不改动 pCryoxy 仓库任何代码**；实施留待后续卡 |

---

## 一、结论先行

三条结论，逐条附实测依据：

1. **补 go.sum 两行不能让裸 `go build` 通过**。补后报错从 `missing go.sum entry` 变为 `WithRouteSnapshot undefined`，**仍然失败**。真正的前提是「replace 到打完 14 个补丁的固定源」，与 go.sum 无一毫关系。
2. **go.sum 缺 xray-core 条目不是疏漏，是 replace 构建方式的机制性必然**。实测：模块一旦 `replace` 到本地目录，`go mod tidy` 会**删除**该模块全部 go.sum 条目（2 行 → 0 行）。「用 replace 构建」与「go.sum 保留该模块校验和」在 Go 中不可同时成立。
3. **只要 replace 到位，go.sum 缺不缺这两行完全不影响构建**。实测原样 go.sum + `-mod=readonly` build **EXIT=0**，`go test` **ok 1.131s**。故本缺陷的严重性在于**可发现性与可操作性**，而非构建正确性。

**缺陷真实定位（这是本方案的核心产出）**：`native/xray-bridge/` 目录**自身没有任何构建入口说明**。任何人在该目录裸执行 `go build`，必然撞上 `missing go.sum entry`，而该报错**具有强误导性**——它看起来像「go.sum 漏了一行、`go get` 一下就好」，实际指向的却是「你必须先把 Xray 换成打完 14 个补丁的固定源」这个完全不同的前提。这才是缺陷本体。

---

## 二、事实核验（全部实测，可复现）

### 2.1 缺陷现象

```
$ cd native/xray-bridge && go build ./...
runtime.go:8:2: missing go.sum entry for module providing package
  github.com/xtls/xray-core/app/commander (imported by
  gitee.com/ParvaUltra/pCryoxy/native/xray-bridge); to add:
        go get gitee.com/ParvaUltra/pCryoxy/native/xray-bridge
...（共 10 处同类报错，覆盖 app/router、core、common/geodata 等）
```

### 2.2 go.sum 覆盖情况

| 检查项 | 结果 |
|---|---|
| go.sum 总行数 | 366 |
| 去重模块数 | 167 |
| `grep -c "xtls/xray-core" go.sum` | **0**（连 `/go.mod` 行都没有） |
| go.mod 的 32 项 require 中，go.sum 缺几项 | **仅 `github.com/xtls/xray-core` 一项** |
| 其余 31 项 | 全部齐备（含 `xtls/reality` 2 行，易与 xray-core 混淆） |
| 传递依赖抽样（quic-go / reality / miekg-dns / utls / wireguard） | 各 2 行，齐备 |

**结论**：go.sum 除 xray-core 外完全自洽，不是「整体未生成」，而是**精确地只缺被 replace 的那一个模块**——这正是机制性行为，不是随机疏漏。

### 2.3 补 go.sum 后的真实报错（推翻旧定性）

补入两行后（值见 §2.6），`-mod=readonly` build：

```
.\snapshot.go:27:21: s.router.WithRouteSnapshot undefined
        (type *router.Router has no field or method WithRouteSnapshot)
.\restricted_profile_test.go:282:11: r.WithRouteSnapshot undefined
FAIL ... [build failed]
```

**这是本方案最关键的一条证据**：`WithRouteSnapshot` 由 `upstream-patches/0014-route-view-dynamic-outbounds.patch:373` 引入，未打补丁的上游模块**根本没有这个 API**。故 go.sum 只是第一道门，第二道门（固定源）不解决，补 sum 毫无意义。

### 2.4 上游未打补丁版本确缺补丁 API

对从 proxy.golang.org 下载的 `v0.0.0-20261109052709-676eaf66f8f0` 模块 zip 逐项核验：

| 补丁引入的 API | 上游未打补丁版本 |
|---|---|
| `WithRouteSnapshot`（0014） | 不存在 |
| `RetainedRoutes`（0005） | 不存在 |
| `ReplaceRoutesRetaining`（0005） | 不存在 |
| `PublishScopedGeo`（0009） | 不存在 |
| `RouteGeoState`（0013） | 不存在 |
| `FreezeVerifiedVersionMatchers`（0009） | 不存在 |

### 2.5 replace 使 go.sum 免校验（机制验证）

最小复现（本地 dummy 模块 + replace + 手工 go.sum 假哈希）：

| 场景 | 结果 |
|---|---|
| 有 replace + 本地目录，go.sum 用**假哈希** `h1:AAAA` | **build EXIT=0**（假哈希未被校验） |
| 去掉 replace | `missing go.sum entry` |
| 有 replace 跑 `go mod tidy` | **go.sum 被清空**（2 行 → 0 行） |
| 无 replace 跑 `go mod tidy` | go.sum **保留** 2 行 |

**三条机制结论**：
1. `replace` 到本地目录时，Go **不校验**该模块的 go.sum 条目（连假哈希都放过）；
2. `go mod tidy` 在 replace 存在时会**主动删除**该模块的 sum 条目；
3. 因此「go.sum 有 xray-core 条目」与「go.mod 有 replace」是**互斥状态**，当前仓库处于后者，属正确状态。

### 2.6 完整固定源复现与验证

从上游模块 zip 出发，依序 `git apply` 全部 14 个补丁（`0011` 用 `--unidiff-zero`）：

| 项 | 结果 |
|---|---|
| 补丁应用 | 14/14 全部 APPLIED，**零 `.rej` 残留** |
| 被修改文件数 | 34 |
| 关键 API 核验（6 项） | 全部命中 |
| `go build -mod=readonly ./...`（**原样 go.sum**） | **EXIT=0** |
| `go test -mod=readonly -count=1 ./...` | **ok 1.131s**，EXIT=0 |
| `go mod verify` | `all modules verified` |
| `go mod graph`（`replay-linux.sh:61` 依赖） | 252 行，EXIT=0 |
| 补 sum 两行后 build | EXIT=0，且 `cmp` 确认 go 未改写 go.sum |
| 补 sum 后 `replay-linux.sh:65` 的 `cmp go.sum` 断言 | **仍通过**（补 sum 不破坏该断言） |

**go.sum 两行的实测值**（由 proxy.golang.org + sum.golang.org 内容寻址取得，可信）：

```
github.com/xtls/xray-core v0.0.0-20261109052709-676eaf66f8f0 h1:onzYnVgcK25ljaND6bHGW7SXoaR/MF+Zo2C0Lliq/IM=
github.com/xtls/xray-core v0.0.0-20261109052709-676eaf66f8f0/go.mod h1:qOpfp0I7DlfhmEHyiv0OV+6jbalzb41EFGegv0UfzBE=
```

### 2.7 说明入口为何找不到

| 位置 | 内容 | 可发现性 |
|---|---|---|
| `native/xray-bridge/go.mod:5-6` | `// Build with a session-local modfile replacing Xray with the fixed source after replaying upstream-patches; the unpatched module lacks the view APIs.` | **差**——注释在 go.mod 内，`go build` 报错时不显示 |
| `tests/integration/bridge/profile.md:37-45` | 完整调用约定 + 参数说明 | **差**——跨目录，需先知道去 tests 找 |
| `native/xray-bridge/` 本目录 | **无任何 .md 文件** | **无** |

`go.mod` 的注释其实**写对了**，问题在位置——它躺在最不会被 `go build` 失败者看到的地方。

---

## 三、方案对比

### 方案 A：补 go.sum 两行

| 维度 | 评价 |
|---|---|
| 效果 | 报错从 `missing go.sum entry`（误导性）变为 `WithRouteSnapshot undefined`（指向真因） |
| 机制风险 | **不稳定**——任何一次 `go mod tidy` 会静默删除（§2.5 已复现） |
| 对既有断言影响 | 无。`replay-linux.sh:65` 的 `cmp` 实测仍通过（§2.6） |
| 语义正确性 | 存疑——replace 场景下该条目本就不参与校验，属「善意污染」 |
| 工作量 | 极小（2 行） |

### 方案 B：纯文档化

| 维度 | 评价 |
|---|---|
| 效果 | 把「唯一入口是 `replay-linux.sh`」写清楚，消除认知盲区 |
| 机制风险 | **零**——不碰 go.sum/go.mod |
| 覆盖面 | 依赖人工记住 14 步补丁序列（其中 `0011` 的 `--unidiff-zero` 是真实陷阱，本次核查中我本人踩过一次） |
| 工作量 | 小（新增 README） |

### 方案 C：固化一键构建脚本

| 维度 | 评价 |
|---|---|
| 效果 | 把「解压 → 14 补丁 → modfile replace → build/test」封装为 `native/xray-bridge/build.sh`，彻底消除 14 步手工记忆 |
| 机制风险 | 低——只新增脚本，不改 go.sum/go.mod |
| 覆盖面 | 需处理 tar 输入的哈希断言（`replay-linux.sh:26-27` 要求 1318088 字节 + sha256 `3932cefe…`） |
| 工作量 | 中（脚本 + 参数校验 + 失败提示） |

### 交叉对比

| 判据 | A | B | C |
|---|---|---|---|
| 消除误导性报错 | ✅ | ⬜ | ⬜ |
| 消除 14 步记忆负担 | ❌ | ❌ | ✅ |
| 机制稳定（不被 tidy 破坏） | ❌ | ✅ | ✅ |
| 零语义污染 | ❌ | ✅ | ✅ |
| 可独立实施 | ✅ | ✅ | ❌（依赖 B 的文档） |

**推荐组合：C 为主 + B 为辅，A 列为可选且必须标注副作用。**

理由：本缺陷的本质是「入口不可发现 + 步骤不可记忆」，B 解决前者、C 解决后者；A 只是把报错文案改好一点，却引入一个会被 tidy 静默回退的状态，**单独使用价值低**。若实施 A，**必须在同一处注明「本条目会被 `go mod tidy` 删除，勿据此判断构建可期」**，否则会制造新的困惑。

---

## 四、推荐方案实施步骤（留待后续卡）

> 本节只给可执行内容，**本次任务不改动仓库**。

### 4.1 步骤一：新增 `native/xray-bridge/README.md`

必含以下四段，缺一不可：

1. **构建入口唯一性声明**：本目录**不可**裸执行 `go build`；唯一受支持入口是 `tests/integration/bridge/replay-linux.sh`（WSL）。
2. **为什么会失败**：`go.mod` 以 `require` 引用上游 `xtls/xray-core`，但桥所需 6 个视图 API（`WithRouteSnapshot`、`RetainedRoutes`、`ReplaceRoutesRetaining`、`PublishScopedGeo`、`RouteGeoState`、`FreezeVerifiedVersionMatchers`）**仅存在于打完 14 个补丁的固定源中**，上游 tag 不含。
3. **go.sum 说明**（关键，防止下一个人重复误判）：go.sum 不含 `xtls/xray-core` 条目是 **replace 构建的正确产物**，非疏漏；补上后 `go mod tidy` 会删除；补与不补**都不影响 replace 到位时的构建**。
4. **14 步补丁序列**：逐条列出，并**显式标注 `0011-explicit-geo-snapshot-release.patch` 必须用 `git apply --unidiff-zero`**（漏掉会导致 0013、0014 连带失败）。

### 4.2 步骤二：新增 `native/xray-bridge/build.sh`

建议接口与校验（与 `replay-linux.sh` 的既有断言保持一致，不重复造轮子）：

```
build.sh <fixed-source-tar> <work-dir>
```

必做校验：
- tar 存在且 **1318088 字节**、sha256 = `3932cefef227439f569eb3988ca206b505467be075967a4397452a3ffe9ef033`（与 `replay-linux.sh:26-27` 同值，保持单一事实来源）；
- `work-dir` 必须在源码树外（与 `replay-linux.sh:23-25` 同约束）；
- 补丁循环中 `0011` 分支走 `--unidiff-zero`；
- 结束时打印 `go version`、14 个补丁的 APPLIED 计数、build 退出码。

失败提示须包含**可操作的下一步**，例如：
```
若报 missing go.sum entry：说明 replace 未生效，不是 go.sum 缺陷。
请确认 go mod edit -replace 已执行且目标目录存在。
```

### 4.3 步骤三（可选）：补 go.sum 两行

若决定实施，**必须与步骤一第 3 点同批提交**，且 commit message 注明「善意污染，tidy 会清除」。值见 §2.6。

### 4.4 步骤四：同步既有文档

`tests/integration/bridge/profile.md:37` 保持现状即可，但建议在段首加一句指向新 README：`See native/xray-bridge/README.md for why bare go build fails.`

---

## 五、验收标准

| 编号 | 判据 | 验证方式 |
|---|---|---|
| V1 | 新人在 `native/xray-bridge/` 裸跑 `go build` 后，能在 1 分钟内知道「需先复现固定源」 | 阅读 README 即可，无需询问 |
| V2 | README 明确写出「go.sum 缺 xray-core 是正确状态」 | 文本检索命中 |
| V3 | `build.sh` 从零到 build 成功一条命令完成 | 空 work-dir 实跑 |
| V4 | `0011` 的 `--unidiff-zero` 已固化进脚本，不依赖人工记忆 | 代码审阅 + 实跑 |
| V5 | 若补了 go.sum 两行，`replay-linux.sh:65` 的 `cmp` 断言仍通过 | 实跑该脚本 |
| V6 | 本次改动**不触碰** `go.mod` 的 require 块与 replace 语义 | `git diff` 审阅 |

---

## 六、风险与回滚

| 风险 | 影响 | 处置 |
|---|---|---|
| 补 go.sum 后被人 `go mod tidy` 清掉，误判为「又被改坏了」 | 低（构建本不受影响） | README 第 3 点预先说明；或干脆不补（推荐） |
| `build.sh` 硬编码 tar 哈希，上游重新打包导致失配 | 中 | 哈希值来源统一指向 `replay-linux.sh:26-27`，改一处即可 |
| `build.sh` 在 Windows 原生 bash 下被误用 | 中 | 脚本首行检测 `uname`，非 Linux/WSL 直接报错退出 |
| 新增脚本被 CI 误纳为门禁 | 低 | 脚本不注册进任何 CI；仅作本地辅助 |

回滚：本方案只新增文件（`README.md`、`build.sh`），**删除即回滚**，无状态残留。若实施 A，`git checkout -- go.sum` 即回滚。

---

## 七、遗留与后续

| 项 | 状态 | 说明 |
|---|---|---|
| 本文档 §4 的实施 | **待认领** | 建议并入 PC-03 补证专项或独立开卡；本次任务按人类裁定只出方案 |
| go.sum 两行是否补 | **人类未定论** | 人类 11-25 12:xx 裁定「只在方案文档里列为可选，不做定论」，故 §4.3 保持可选 |
| PC-07 的 gitleaks 计数（19 → 18） | 遗留 | 与本缺陷无关，见验收汇报 §九 |
| closeout 失败日志加 `failed-` 前缀 | 遗留 | 与本缺陷无关，非阻断 |

---

## 八、给后续认领人的三句话

1. **不要试图靠补 go.sum 修好裸 build**——补了也失败，报错会变成 `WithRouteSnapshot undefined`，那才是真因。
2. **go.sum 缺 xray-core 是对的**——replace 构建的必然产物；`go mod tidy` 会主动删掉你补的行。
3. **真正要修的是「入口不可发现」**——`go.mod:5-6` 的注释写对了，但它躺在最不会被看到的地方。

---

*本方案所有结论均附实测证据，关键失败路径（补 sum 后仍失败、tidy 删除 sum、假哈希通过）均已独立复现。未采信任何单方陈述。*
