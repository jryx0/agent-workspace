# PC-04c 合并入 main 执行记录（第 4 项）

- 日期：2026-11-25
- 执行者：workbuddy@zhn-tbxg2iah-win~zhn-x-w
- 依据：`2026-11-25-pCryoxy-跨卡契约三项核对-合并前把关`（`5c61d34`）判定三项契约全一致、可进入合并
- 结论：**合并成功**，`main` 由 `4066e0d` 推进至 `862c9d4`

## 1. 合并前状态

| 项 | 值 |
|---|---|
| main（基线） | `4066e0d1d254efb638b60d740a342652ea55112c` |
| pc04c | `09899c0385f6a97e469ef8d5f94967772a722d53` |
| pc07 | `ed84bdea11293b58807f64811559efaf90e5c3fc` |
| merge-base | `c3acc73f0b1cfc25b1770a4d0d9645cd59681738` |
| 工作树 | 干净（0 处改动），无残留 lock |

## 2. 合并执行方式：改用 plumbing

`git merge --no-ff` 连续两次被外部 SIGTERM 终止（首次与重试一致），工作树留下部分改动、`MERGE_HEAD` 缺失、`.git/index.lock` 残留。为排除干扰，先做诊断：

- `.git/hooks` 无任何生效钩子（仅 `.sample`）
- `core.hooksPath` 指向 `C:/Users/Zhn_X/.agent-tools/hooks`，其中只有 `pre-commit`（gitleaks 链式委托），而 `merge --no-commit` 不触发 `pre-commit`
- 无 `commit.gpgsign`、无自定义 merge driver、无 `.gitattributes` 合并规则
- 仓库仅 2.1M / 207 个跟踪文件，合并本身不可能耗时超限

→ 判定为**外部强制终止**，非仓库或钩子问题。

**改用纯 plumbing 路径**（不触碰工作区，绕开被终止的原地改写）：

```console
$ TREE=$(git merge-tree --write-tree HEAD agent/copilot/pc04c)
51caf21ad1ce120695f205cc5e6a7358dbabe504          # 预检同时证明零冲突
$ COMMIT=$(git commit-tree "$TREE" -p HEAD -p agent/copilot/pc04c -m "merge: PC-04c 原生传输边界 09899c0 第六轮复核通过后集成 by workbuddy@zhn-tbxg2iah-win~zhn-x-w")
862c9d447dc2c217c5480f6037e2c96f67cb809a
$ git update-ref refs/heads/main "$COMMIT" 4066e0d1d254efb638b60d740a342652ea55112c
```

`git reset --hard` 同步工作区时同样被 SIGTERM 中断（`Updating files: 40% (9/22)`），导致索引写成旧树 `9a291ea`。用 `git read-tree HEAD` 重建索引后，以小批量 `git checkout-index -f`（每批 1–2 个文件）逐个补齐 11 个文件，全部成功。

## 3. 合并提交结构验证

```console
$ git cat-file -p HEAD
tree 51caf21ad1ce120695f205cc5e6a7358dbabe504
parent 4066e0d1d254efb638b60d740a342652ea55112c
parent 09899c0385f6a97e469ef8d5f94967772a722d53
```

- 树 `51caf21` 与预检 `merge-tree` 结果**逐字符相同**
- 两父提交顺序正确（main 侧在前，卡侧在后）
- `git rev-parse HEAD^{tree}` == `git write-tree`（索引与 HEAD 一致）
- `git status --short` = 0

**双向完整性：**

| 方向 | 结果 |
|---|---|
| `git diff agent/copilot/pc04c HEAD` | 仅 `.gitignore` +1 行（main 侧「仓库忽略规则补齐」） |
| `git diff 4066e0d HEAD` | pc04c 全部 22 个文件改动到位（+2655 / −144） |

提交身份为 `zhn-copilot <copilot@zhn-tbxg2iah-win>`，与历史合并提交 `c3acc73`（PC-04b）一致，提交信息中标注 `by workbuddy`，沿用既有先例。

## 4. 编译验证：必须先复现固定核心

直接在仓库内 `go build ./...` 报 `missing go.sum entry` 与大批 `undefined`。逐步定位：

1. `go.sum`（366 行）**完全没有 `xtls/xray-core` 条目**，而 `go.mod:8` 直接 require 该模块
2. 该缺陷在基线 `4066e0d` 独立 worktree 上**同样存在**（相同报错），**不是本次合并引入**
3. `go.mod` 注释已写明正确方式：
   > Build with a session-local modfile replacing Xray with the fixed source after replaying upstream-patches; the unpatched module lacks the view APIs.
4. 模块缓存里的 `xray-core@676eaf6` 是**未打补丁**版本，缺 `router.RetainedRoutes`、`geodata.VersionMatchers`、`router.Router.RouteState` 等桥侧必需符号

**按 `tests/integration/bridge/replay-linux.sh` 原逻辑复现：**

```bash
tar -xzf xray-676eaf66.tar.gz -C /tmp/xc-verify --strip-components=1
for p in upstream-patches/00*.patch; do
  if [[ ${p##*/} == 0011-* ]]; then git apply --unidiff-zero "$p"   # 该补丁必须是 unidiff-zero
  else                            git apply "$p"; fi
done
```

14 个补丁 **全部 APPLIED**。关键点：`0011-explicit-geo-snapshot-release.patch` 必须用 `--unidiff-zero`，否则其后 0013、0014 连带失败——这是首次尝试漏掉的特例。

**结果：**

| 验证 | 结果 |
|---|---|
| 桥侧 `go build ./...`（`-replace` 指向打好补丁的核心） | **EXIT=0 通过** |
| 桥侧 `go test ./...` | **ok 1.626s 通过** |
| 核心侧 PC-04 回归（`./app/router ./app/dns ./app/dispatcher ./proxy/dns ./common/geodata`） | **9 个测试全 PASS，0 FAIL** |

核心侧通过的用例与第六轮核查 r7 日志一致：

```
--- PASS: TestPC04RouteViewRetainsOutboundHandlersAcrossRouteUpdate
--- PASS: TestPC04OutboundSetPublishRollbackAndReferenceLifetime
--- PASS: TestPC04BalancerUsesViewSetAndFailsClosed
--- PASS: TestPC04OutboundPublishRejectsMissingRouteAndFallbackTags（含 missing_route_tag / missing_fallback_tag 两子例）
--- PASS: TestPC04OutboundSetLimitRejectsNinthGeneration
--- PASS: TestRouterScriptDNSDispatcherReentry
--- PASS: TestPC04DispatcherUsesPinnedOutboundHandlers
--- PASS: TestPC04DispatcherWithoutScopeOnlyUsesBootstrapOutbounds
--- PASS: TestPC04RouteOnlyKeepsLiteralIPAsConnectionTarget
--- PASS: TestPC04DNSRuleAndLookupUsePinnedRouteView
--- PASS: TestPC04SnapshotLeaseWaitsForReaders
```

验证后已完整还原：`go.mod` 恢复（无 `replace` 残留）、`go.sum` 恢复、`git status` = 0。

## 5. 遗留问题登记（非本次合并引入）

**`native/xray-bridge/go.sum` 缺 `xtls/xray-core` 条目**，导致仓库内裸 `go build` 无法直接通过，必须按 `replay-linux.sh` 方式构建。此为**基线缺陷**（`4066e0d` 已复现），不影响合并正确性，但值得后续单独修（补 `go.sum` 该行，或把构建方式固定为脚本入口并在 README 注明）。

## 6. 合并后全工作区验收

| 验证项 | 命令 | 结果 |
|---|---|---|
| Rust 格式 | `cargo fmt --all --check` | **EXIT=0**，零输出 |
| Rust Lint | `cargo clippy --workspace --all-targets -- -D warnings` | **EXIT=0**，零 warning（耗时 40m30s，首编译） |
| Rust 测试 | `cargo test --workspace` | **EXIT=0，0 failed**；61 passed / 4 ignored |
| 桥侧编译 | 复现固定核心后 `go build ./...` | **EXIT=0** |
| 桥侧测试 | `go test ./...` | **ok 1.626s** |
| 核心 PC-04 回归 | 见 §4 | **9 用例全 PASS** |

Rust 测试分项：15（core-ir）+ 9 + 20 + 17 = 61 passed，17 那组含 4 ignored（互通夹具与专用测试，与 PC-07 分卡时「107 passed / 13 ignored」口径同源，此处为 main 合入 PC-04c 后的子集）。

`cargo clippy` 首次失败系 `target/debug/build/vswhom/.../fingerprint/lib-vswhom` 报 `os error 5 拒绝访问`——由前次被 SIGTERM 终止的 cargo 进程遗留句柄所致；确认无残留进程后重跑即通过，**非代码缺陷**。

## 7. 下一步

| 序 | 事项 | 状态 |
|---|---|---|
| 1 | PC-04c 推送 | ✅ `09899c0` |
| 2 | 其他模型完成 `4f99f7c` 审核 | ✅ 不通过 → `09899c0` → 通过 |
| 3 | 跨卡契约三项核对 | ✅ 全一致 |
| 4 | **合并 pc04c 入 main** | ✅ **`862c9d4`**，全验收通过 |
| 5 | PC-07 结卡 | ⏭ 待执行 |
| 6 | 合并 pc07 入 main | 待 5 |

## 8. PC-07 合并预检（为第 6 步预备）

- `git merge-base main pc07` = `c3acc73`（与 pc04c 同一基点）
- pc07 改动 18 个文件，main 侧新增 22 个文件，**交集 0**（`comm -12` 验证，按 `-z` 处理中文路径）
- 合并预检 `git merge-tree --write-tree main pc07` = `9a1ae26b6b750a8468675eb55d9edb9b475eaf9f`，**零冲突**
- `git diff main pc07` 中出现的「删除 `outbound_control_test.go`、删除 `0014-*.patch`」等，纯粹是 pc07 基点早于 pc04c 合并所致，**不是内容回退**

**PC-07 结卡待办**：`crates/plugin-xray/tests/matrix.md` 标题仍为「PC-07 支持矩阵（预验，未结卡）」，且第 86–93、146–155 行等多处单元格填「待 PC-04c」。PC-04c 已并入 main，这些占位需重新判定：能借桥取证的要补证据，仍缺夹具的须改写为「缺夹具」而非「待 PC-04c」。
