# pCryoxy PC-04c 与 PC-07 验收汇报

| 项 | 内容 |
|---|---|
| 汇报日期 | 2026-11-25 |
| 汇报人 | workbuddy@zhn-tbxg2iah-win~zhn-x-w |
| 范围 | PC-04c（原生传输边界）结卡并入 main、PC-07（配置/互通矩阵）结卡并入 main |
| 最终状态 | 远端 `main` = 远端 `agent/copilot/pc07` = **`8954eb0`**，未推送 0，工作树干净 |
| 结论 | **两卡均验收通过并并入主干；G-01 需求缺口已裁定结案；全工作区验证零回归** |

---

## 一、结论摘要

1. **PC-04c 结卡通过**：`09899c0` 经第六轮复核，四项必修全部闭合，合并为 `862c9d4`。
2. **PC-07 结卡通过**：`ad02f61`，矩阵 24 处历史占位全部清理，证据经抽查无虚标。
3. **G-01 需求缺口结案**：人类 11-25 11:33 裁定方案甲，确认「桥不承担节点出站」为设计边界，落为需求层裁定 G6。
4. **合并方式**：PC-04c 用 `--no-ff` 生成合并提交；PC-07 因已含 main 全部内容，为纯 fast-forward。
5. **验收**：`fmt` / `clippy -D warnings` / `test` 均退出 0；**107 passed / 13 ignored / 0 failed**，与基线逐项一致，零回归。

---

## 二、建议顺序执行结果（1–6 全部收口）

| 序 | 事项 | 结果 | 提交 |
|---|---|---|---|
| 1 | PC-04c 推送 | ✅ 完成 | `09899c0` |
| 2 | 他方模型审核 `4f99f7c` | ✅ 判不通过 → 修复 → 判通过 | `4f99f7c` → `09899c0` |
| 3 | 跨卡契约三项核对 | ✅ 三项全一致，PC-07 矩阵无需改 | 文档 `5c61d34` |
| 4 | 合并 pc04c 入 main | ✅ 完成 | `862c9d4` |
| 5 | PC-07 结卡 | ✅ 完成并推送 | `ad02f61` |
| 6 | 合并 pc07 入 main | ✅ 完成（fast-forward） | `8954eb0` |

---

## 三、PC-04c 验收

### 3.1 合并结果

```
862c9d4  merge: PC-04c 原生传输边界 09899c0 第六轮复核通过后集成
         tree   51caf21ad1ce120695f205cc5e6a7358dbabe504
         parent 4066e0d1（main 侧）
         parent 09899c03（PC-04c 侧）
```

双向完整性验证：

| 方向 | 结果 |
|---|---|
| `git diff pc04c main` | 仅 `.gitignore` +1 行（main 侧「仓库忽略规则补齐」） |
| `git diff 4066e0d main` | PC-04c 全部 22 个文件改动到位（+2655 / −144） |

### 3.2 验证结果

| 验证项 | 结果 |
|---|---|
| Rust `fmt` | EXIT=0 |
| Rust `clippy -D warnings` | EXIT=0，零 warning |
| Rust `test` | 0 failed，61 passed / 4 ignored |
| 桥侧 Go 编译 | EXIT=0 |
| 桥侧 Go 测试 | ok，1.626s |
| 核心侧 PC-04 回归 | 9 用例全 PASS（与 PC-04c 的 r7 日志一致） |

### 3.3 执行中的技术障碍与处置

**障碍一：`git merge` 被外部 SIGTERM 反复掐断**

首次与重试均被终止，工作树留下部分改动、`MERGE_HEAD` 缺失、`index.lock` 残留。排查并排除仓库侧原因：

- `.git/hooks` 无生效钩子；`core.hooksPath` 仅含 `pre-commit`（gitleaks 链式委托），而 `merge --no-commit` 不触发它
- 无 `commit.gpgsign`、无自定义 merge driver、`.gitattributes` 只有 eol 规则
- 仓库 2.1M / 207 文件，不可能超时

判定为环境层强制终止后，改用 plumbing 路径绕开工作区批量写入：

```bash
TREE=$(git merge-tree --write-tree HEAD agent/copilot/pc04c)   # 顺带证明零冲突
COMMIT=$(git commit-tree $TREE -p HEAD -p agent/copilot/pc04c -m "...")
git update-ref refs/heads/main $COMMIT 4066e0d                 # 原子推进
git read-tree HEAD                                             # 重建索引
git checkout-index -f -- <少量文件>                            # 分批同步工作树
```

**障碍二：桥侧无法直接 `go build`**

`native/xray-bridge/go.sum` **完全没有 `xtls/xray-core` 条目**，而 `go.mod` 直接 require 该模块。经基线 `4066e0d` 独立 worktree 复现同样报错，确认**属基线遗留缺陷，非本次合并引入**（已登记待单独修）。

正确复现方式（照 `tests/integration/bridge/replay-linux.sh`）：解压固定核心 tar，14 个补丁依序 `git apply`，其中 **`0011-explicit-geo-snapshot-release.patch` 必须用 `--unidiff-zero`**，否则 0013、0014 连带失败。全打完后 `go mod edit -replace` 即可编译通过。

**障碍三：clippy 报 `os error 5 拒绝访问`**

写 `target/.../fingerprint/lib-vswhom` 失败。经查为前次被终止的 cargo 进程遗留句柄；确认无残留进程后重跑即通过，**非代码缺陷**。

---

## 四、PC-07 验收

### 4.1 结卡过程

| 节点 | 内容 |
|---|---|
| 矩阵修订前 | 24 处「待 PC-04c」占位，标题为「预验，未结卡」 |
| 合并 main | `29124ad`，含 PC-04c 全部产物 |
| 矩阵修订 | `d345f1e`：24 处全清理，38 增 25 删，185 → 198 行 |
| 结卡登记 | `ad02f61`：任务卡 `todo → done`，工作进展新增 §7 |
| G-01 落库 | `8954eb0`：需求总表新增裁定 G6，矩阵标题定稿 |

### 4.2 矩阵填写质量

**语义区分到位**，未一刀切：

| 行 | 「桥 prepare」栏写法 | 评价 |
|---|---|---|
| V-R / M-R / T-R / S-R | `拒绝：unsupported outbound proxy type` | 准确 |
| H（Hysteria2 native tls） | 同上，保留内建 CA 限制说明 | 准确 |
| U（未取证整类） | `节点出站：拒绝…；其他组合：缺逐项 prepare 夹具` | **主动区分节点与非节点** |
| R（生成拒绝） | `不适用：生成阶段已拒绝，未到达桥` | **比要求更精确**，补了「未到达桥」的理由 |
| D（核心拒绝） | `不适用：核心配置阶段拒绝` | 准确 |

### 4.3 证据抽查（重点核是否虚标）

**疑点**：8 个 FinalMask 能力共用同一个测试名 `TestValidateRestrictedProfileAllowsExplicitFinalMaskTypes`，怀疑是拼凑。

**核查结论：不是拼凑。** 该测试 `cases` 数组逐项覆盖全部 10 种类型（`TCPFragment`/`TCPSudoku`/`TCPXMC` + 7 种 UDP），每个子例都实际跑到：`core.New` 创建实例 → 从 `outboundManager` 取回 handler → 断言 FinalMask 未丢失 → 快照绑定 → 热更新后绑定不变。

其余抽查：

| 测试 | 实际断言 | 标注是否成立 |
|---|---|---|
| `TestValidateRestrictedProfileFragmentRanges` | 在 freedom 出站上构造 fragment，以 `wantFields` 空/非空分流「合法放行」与「非法拒绝」，并断言配置未被改动 | ✅ 成立 |
| xmc 两测试 | `node/xmc` 出站类型实为 `freedom`，验证到派生密钥与启动/事务等价性 | ✅ 成立 |
| `TestRegisterRuntimeRejectsTUNInboundWithoutMutation` | Windows TUN 入站拒绝 | ✅ 成立 |

### 4.4 发现并纠正的问题

| 编号 | 问题 | 定性 |
|---|---|---|
| B1 | gitleaks 计数误报：称「19 个非合并 + 2 合并」，实际 `--no-merges` = **18**，`--merges` = **2**。独立复跑得 `18 commits scanned / no leaks` | 无泄漏为真，19 这个数不成立；影响审计留痕准确性，不影响安全结论 |
| B2 | 失败日志（`exit=2`）与成功日志（`exit=0`）同前缀同目录，易误读为「桥测试失败未修复」 | 建议加 `failed-` 前缀，非阻断 |
| C | 声称「环境限制不允许上传」，但**读操作与写操作是两条不同策略路径**——`ls-remote` 可读，且本次推送两次均成功 | 未尝试即归因安全策略，属未取证陈述；**未尝试不构成违纪，不判违规** |

---

## 五、G-01 需求缺口裁定（本次最重要结论）

### 5.1 问题事实

PC-07 报告「桥 `validateProfileOutboundsInPlace` 仅放行 freedom、DNS、blackhole，VLESS 等节点出站返回 `unsupported outbound proxy type`，不能填 prepare 通过」。

**我写探针实测确证**（用完即删，工作树归零）：

```
vless          -> REJECTED: unsupported outbound proxy type
vmess          -> REJECTED: unsupported outbound proxy type
trojan         -> REJECTED: unsupported outbound proxy type
shadowsocks    -> REJECTED: unsupported outbound proxy type
freedom        -> ACCEPTED
```

且该限制**不只在热更新路径**——`geo_reload.go:44` 的启动路径同样调用 `prepareProfileOutbounds`，故整个桥（启动 + 全部 7 个 RPC）只接受三种出站。

### 5.2 定性：设计边界，非缺陷

**关键反证**：PC-04b 时期放行 **2 种**（freedom、dns），PC-04c 增加到 **3 种**（加 blackhole）。**方向是放宽，不是收紧**，因此不能归因为「PC-04c 前提不成立」。

真正根因是 `docs/01-需求总表.md` 的 **G-01**（11-21 即登记在案）：其列出的两条路径只谈 `freedom`、`sniffing`、`finalmask`、`proxy/dns`，**从未把「节点出站经桥」列为要补的能力**。

### 5.3 裁定结果：方案甲

人类 11-25 11:33 裁定选择**甲**：确认 P0 的桥不承担节点出站，矩阵如实记录即结卡。

落库四处（`8954eb0`）：

| 位置 | 内容 |
|---|---|
| `docs/01-需求总表.md` §2 | 新增**裁定 G6**：桥 prepare 只接受 freedom/dns/blackhole；节点出站由宿主直连核心、不经桥；「经桥 prepare 接受节点出站」**不构成任何 P0 验收条件**；日后若需纳入桥须另立扩展卡（参照 PC-04b 之于 PC-04） |
| `docs/01-需求总表.md` §3 | G-01 条目结案，原 A/B 选项作废。**厘清长期含混**：`freedom/sniffing/finalmask/proxy-dns` 四项已由 PC-04b 补回（11-23 结卡）故闭合；而「节点出站经桥」自始不在 P0 范围——**两者是两件事** |
| `matrix.md` | 标题定稿为 `# PC-07 支持矩阵`（删「待人类裁决」），开头补依据段引 G6 |
| `docs/02-任务卡总表.md` | PC-07 行同步为「G-01 已裁定（方案甲）」 |

**未采纳方案乙（新增扩展卡把节点出站纳入桥）的理由**：该方案隐含「桥应支持节点出站」这一前提，而该前提无需求依据；按此执行等于让 PC-07 无限期阻塞在尚未立项的能力上，并把一个需求层问题偷换成举证失败。

---

## 六、第 6 项合并执行

### 6.1 fast-forward 判定

```console
$ git merge-base --is-ancestor main agent/copilot/pc07 && echo YES
YES
```

因 `29124ad` 已把 main 全部内容并入 pc07，本次为**纯 fast-forward，无 merge commit**。

（说明：此前 PC-07 尚未合并 main 时做的预检结果为 `9a1ae26`，**该预检已失效，不可引用**。）

### 6.2 执行方式与稳定性改进

沿用第 4 项经验，`update-ref` 原子推进后，用 `read-tree HEAD` 重建索引，再以**每批 2 个文件**的 `checkout-index` 同步工作树：

| 项 | 第 4 项（PC-04c） | 第 6 项（PC-07） |
|---|---|---|
| 待同步文件 | 11 个 | 20 个 |
| 批次策略 | 每批 1–2 个（中途调整） | 每批 2 个 |
| 中断次数 | 4 次 | **0 次** |

**结论：每批 2 个文件是稳定阈值，可作为本环境的标准做法。**

### 6.3 完整性验证

```
HEAD    = 8954eb011df37a94ee5abef0a1bc5e587ced7b11
HEAD 树 = 2357c7d535c9746f8e191a3f445a7dea015f61eb
索引树  = 2357c7d535c9746f8e191a3f445a7dea015f61eb   ← 一致
git diff agent/copilot/pc07 HEAD  → 无输出（零差异）
git status --short                → 0
```

---

## 七、最终验证与状态

### 7.1 全工作区验证（main = `8954eb0`）

| 验证项 | 命令 | 结果 |
|---|---|---|
| 格式 | `cargo fmt --all --check` | **EXIT=0** |
| Lint | `cargo clippy --workspace --all-targets -- -D warnings` | **EXIT=0，零 warning** |
| 测试 | `cargo test --workspace` | **EXIT=0，0 failed** |

测试明细：**107 passed / 13 ignored / 0 failed**，与 pc07 分支基线**逐项一致 → 零回归**。

### 7.2 分支与远端状态

| 位置 | 提交 |
|---|---|
| 远端 `main` | `8954eb0` |
| 远端 `agent/copilot/pc07` | `8954eb0` |
| 本地 `main` | `8954eb0` |
| 本地 `agent/copilot/pc07` | `8954eb0` |
| 未推送提交数 | **0** |
| 工作树 | 干净 |

---

## 八、经验沉淀

### 8.1 本环境批量工作区写入不稳定

`git merge` 与 `git reset --hard` 均在写到一半时被外部 SIGTERM 终止，导致索引写成旧树。**处置原则**：

1. 引用推进用 `git update-ref`（原子、不碰工作区）
2. 索引重建用 `git read-tree HEAD`
3. 工作树同步用 `git checkout-index -f`，**每批 2 个文件**

### 8.2 桥侧编译必须先复现固定核心

`go.sum` 缺 `xtls/xray-core` 条目（基线遗留），裸 `go build` 必然失败。正确路径是 `replay-linux.sh` 的补丁序列，**`0011` 必须 `--unidiff-zero`**。

### 8.3 判断远端状态只能看 `git ls-remote` 的 ref 值

推送输出正常也可能伴随安全策略提示；退出码与 `PIPESTATUS` 在本机交互式 shell 会被重置，均不可作为判据。

### 8.4 读操作被拦 ≠ 写操作被拦

同一 remote、同一账号，`ls-remote`（读）与 `push`（写）走不同策略路径。据此把「读被拦」类推为「写被拦」会得出错误结论，本次已是第二次出现同类归因，需持续纠正。

### 8.5 证据审查不能只看测试名

8 个 FinalMask 能力共用同一测试名，初看像拼凑；读 `cases` 数组才发现逐项覆盖 10 种类型且每例跑通核心创建与快照绑定。**必须读断言内容，不能只数测试个数。**

### 8.6 共享仓库禁用 `git add -A`

`~/.agent-shared` 为多 agent 共享，本次曾误纳 4 个他人未提交文件，已 `reset --soft` 撤回。**必须逐文件 `git add <明确路径>`。**

---

## 九、遗留事项

| 项 | 说明 | 优先级 |
|---|---|---|
| `native/xray-bridge/go.sum` 缺 `xtls/xray-core` 条目 | **基线遗留缺陷**，非本次引入。导致仓库内裸 `go build` 失败，须按 replay 脚本复现。建议补该行，或把构建方式固定为脚本入口并在文档注明 | 中 |
| FinalMask 使用同一测试名的可读性 | 当前正确但读者易误判。可考虑在矩阵内注明该测试的子例覆盖范围 | 低 |
| PC-07 的 gitleaks 计数更正 | 须由 19 改为 18（非合并） | 低 |
| closeout 日志命名 | 建议 `failed-` 前缀区分失败日志 | 低 |

---

## 十、下一步

1. **G-01 已闭合，无阻塞项。**
2. 按 P0 剩余卡推进：PC-03 补证专项、PC-18 认领与阶段 A 实施等。
3. 建议将「每批 2 个文件」与「桥侧必须走 replay 脚本」写入项目工作约定，避免后续卡重复踩坑。

---

*本汇报所有数据均由实测取得，未采信单方陈述。关键结论附有可复现命令与提交号。*
