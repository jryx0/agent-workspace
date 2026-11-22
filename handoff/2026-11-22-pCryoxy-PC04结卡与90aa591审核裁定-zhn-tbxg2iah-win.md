# pCryoxy 审核裁定：PC-04 结卡 / PC-02 Go 绑定冻结（3bb31ad+90aa591）

- 审核方：workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-22 10:30
- 依据：任务卡 v1.2 §2 PC-04 六条结卡条件；copilot 交接《PC04-Linux复跑与结卡申请》《90aa591-Go绑定输出摘要-交付待审核》
- 集成授权：人类 2026-11-22 08:08（修 main 并合并、推送；未审提交审后再合）

## 1. PC-02 Go 绑定冻结：**通过**

| 核对项 | 方式 | 结果 |
|---|---|---|
| 改动范围 | `git show --stat 3bb31ad 90aa591` | 仅 `crates/plugin-xray/proto.lock`（+40、+10/-2） |
| 输出摘要与实物 | 审核方对 `44247c8` 中两份文件 `wc -c` + `sha256sum` | `core_control.pb.go` 32,541 B `f6e3cf3a…d548`；`core_control_grpc.pb.go` 12,368 B `c151d7d3…1df9`，与锁记录逐字一致 |
| 集成后 proto 校验 | main `9949081` 上 `node tools/check-proto.mjs`（protoc 29.5） | 退出 0 |

## 2. PC-04 固定 Go 桥：**通过 → done**

| v1.2 结卡条件 | 审核方核对 | 结论 |
|---|---|---|
| 前置：类别授权改写为精确文件清单 | `git diff --name-status 1e18654 44247c8` 50 个新增文件，与交接清单逐行 diff 一致；无修改/删除既有文件 | 满足 |
| ① 受限 profile prepare 校验与拒绝清单 | replay 中 `restricted_profile_test.go` 通过 | 通过 |
| ② Runtime ABI v2 与固定错误码 | Go ABI 测试 + C ABI v2 smoke 通过（执行方 clean replay 与审核方 07:35 独立 replay 一致） | 通过 |
| ③ 普通 + `-race` 全通过、双构建一致 | 证据包 SHA-256 `3453d8a8…6962` 审核方复算一致，包内 `hashes.sha256` 5 项全部 OK；`replay-clean.log` 62 PASS / 0 FAIL；Go archive `8a6d31a7…abff` 与审核方独立重跑一致 | 通过 |
| ④ 单一 epoch / 线性化 / 无 SetAdmission | route epoch 测试通过；清单内无 SetAdmission | 通过 |
| ⑤ Linux 固定资产与桥运行检查 | 固定 Xray 输入 `3932cefe…f033`、Go 1.27.4、Zig 0.16.0；archive 可复现；ABI v1/v2 smoke 通过 | 通过（`.so` 见下） |
| ⑥ 审核方独立重跑 | 已于 07:35 完成（`handoff/2026-11-22-pCryoxy-done卡与PC04-ABIv2独立重跑复核及集成建议-…` §1） | 通过 |

**`.so` 裁定**：`libpc04_abi.so` 不在 PC-04 卡面交付物内，定性为 **ABI smoke 测试临时产物，不是交付物**。PC-04 的 Linux 交付资产是 Go archive（已证可复现）。差异原因判断：`.so` 未 strip、带 `debug_info`，C shim 经 zig cc 编译会把构建目录绝对路径写入 DWARF，所以不同 scratch 路径下摘要不同，同一路径（shared-a/b）下摘要一致（`9c5b…ec70` ×3）。**F-25 降为后续卡约束**：PC-18a 或任何把 `.so` 作为交付物的卡，须加 `-trimpath`、`-ffile-prefix-map`/`-fdebug-prefix-map` 或 strip，并证明双路径一致。

**低风险记录**：交接文档写 `.so` 大小 45,550,112 B，实物 45,550,176 B（哈希一致，仅大小笔误）。

**基线差异**：PC-04 实际基于 `1e18654`（非调度提示词写的 `2908e4e`）。`1e18654` 是 main 的祖先，`git merge-tree` 无冲突，按合并方式集成，无需变基。

## 3. 集成

| 提交 | 内容 |
|---|---|
| `a6bcb16` | merge 90aa591（含 3bb31ad）进 main |
| `9949081` | merge `agent/copilot/pc04` `44247c8` 进 main |

集成后 main `9949081`：`cargo check --workspace --locked` 0；`cargo test --workspace --all-features --locked` 24 通过 0 失败；proto 校验 0；`git diff 44247c8 main -- native tests/integration upstream-patches` 为空（Go 侧与已 replay 的提交逐字相同）。已推 origin。未部署（pCryoxy 无部署目标）。

## 4. 下游放行

- 按任务卡 v1.2：**PC-04b、PC-05**（依赖 PC-04 done）与 **PC-18a**（依赖 PC-04、PC-17 done；对 PC-03 只依赖已审 Linux 后端与 `SecretStore` trait）**现均可认领**。copilot 须先在项目记忆追加认领行再开工，基座取 main `9949081`。PC-18b 仍须 PC-03 整体 done。
- PC-03 仍 blocked（W4/W5/Android 由审核方子 agent 独立验证中，结论另发）。
