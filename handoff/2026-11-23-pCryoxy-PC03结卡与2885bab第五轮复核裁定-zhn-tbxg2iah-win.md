# pCryoxy 审核裁定：PC-03 结卡（2885bab / 共享仓 1755d73）

- 审核方：workbuddy@zhn-tbxg2iah-win（审核方子 agent 独立构建运行），2026-11-23 08:50
- 被审：项目仓 agent/copilot/pc03 `2885babf1e8bb0da318ee3a28ce5bf1da5d0342e`（含 `dc987a2`）；共享仓 `1755d73`（run-xacct.ps1、第四轮返工交付）
- 依据：任务卡 v1.2 PC-03 及 §9、§10 追记；第三轮复核裁定 §3、§10；第四轮复核裁定 §2、§3；真机验证方案 v2 §5（矩阵 v1.1）
- **结论：PC-03 通过 → done。已合并进 main `1b1ae3d` 并推 origin。**

## 1. 第五轮复核结果

| 项 | 结果 | 关键数字 |
|---|---|---|
| diff 范围 | PASS | `3934b65..2885bab` 仅 tests.rs +11/-4，windows.rs 0 改动；对应第四轮 §2 第 3、5 项 |
| cleanup 兜底审读 | PASS | tests.rs:1605-1616 仅在无 reparse、两根不存在或均为普通目录、且两处 key-id 均确不存在时兜底；只删 `<id>`（32 位 hex）精确路径，删除范围未扩大 |
| fmt / clippy --all-targets -D warnings | PASS | 均退出 0 |
| 全量测试 3 轮 | PASS | 每轮 17/0/4，0xc0000409 0 次，凭据与 vault 0 残留 |
| 跨进程用例 | PASS | 1/1，前后 pc03-test 0 |
| runner 一致性与审读 | PASS | 部署副本 `d223dfb3…baffd29`，去 CR 后与 git blob 一致；diff 仅 System.Security 显式加载与 `.ToArray()`，无越界 |
| W5 方向 A（Zhn_X 写 → pcx-t2 读） | PASS | 写入 2/2；读取 5/5 |
| W5 方向 B（pcx-t2 写 → Zhn_X 读） | PASS | 写入 2/2；读取 5/5 |
| cleanup 两侧 | PASS | 4 个请求各 5/5 |
| X1 gitleaks | PASS | 两目录 0 命中 |

读取方五项（双向相同）：① 直读对方原始库 denied/5；② 交换副本 SHA-256 match；③ secure-store 打开副本 KeyUnavailable；④ CryptUnprotectData failure/0x8009000B；④ CredRead not-found/1168。pcx-t2 阶段为计划任务 Batch(4)、非提权 S-1-16-8192、dpapi=ok；Zhn_X 阶段为 pwsh 7.6.10 交互、非提权。审核方自建测试二进制 `76e783d3…af0c4`，8 个结果包 binarySha256 均为此值。

证据：`~/.agent-tools/run/review/pc03-win-r5-20261123/`（SHA256SUMS 自身 `d87b65c6…7c67`）、`pc03-w5-r5-20261123/`（`0dfff818…d233`）。

## 2. PC-03 结卡条件汇总

| 条件 | 证据轮次 | 结论 |
|---|---|---|
| W1、W2、W3、W6 | 第三轮 4456f66 各 3/3；其后产品代码 diff 为 0 | 通过 |
| W4 | 第三轮 `--exact` 20/20（1168、ENV_BLOCKED 0） | 通过 |
| W5 跨账户双向 | 本轮 | 通过 |
| A1～A3 + recover-pending（D1 API29、D2 API36） | 第三轮；其后 Android 文件 0 改动 | 通过 |
| L1 Linux 同 UID / 跨 UID | 第三轮 | 通过 |
| X1 | 第三、四、五轮证据包均 0 命中 | 通过 |
| 返工必修 1～7（dc3d34d 裁定 + H1） | 第三轮 1～4、6、7；第 5 项（W5 runner）经第四、五轮关闭 | 通过 |
| 文档边界（配额、回滚、孤儿回收、重试、H2/H3 边界） | 第三轮审读 docs/secure-store.md | 通过 |

转出事项不在本卡：H2（rename 覆盖）、H4（Android fd 泄漏）→ PC-11；H3（Windows 跨进程一致性）及服务 SID/ACL/服务重启 → PC-10。

## 3. 集成

- `git merge-tree` 无冲突；main `ea90841` 合并 `2885bab` 得 `1b1ae3d`（--no-ff）。
- 集成后 main：`cargo check --workspace --locked --offline` 0；`cargo test --workspace --all-features --locked --offline` 0，41 通过 / 0 失败 / 4 忽略（原 24 + secure-store 17）；测试后 pCryoxy 凭据 0 条。日志 `~/.agent-tools/run/review/pc03-merge-20261123/`。
- 已推 origin（`ea90841..1b1ae3d`）。pCryoxy 无部署目标，未部署。

## 4. 解锁与后续

- **PC-06**（依赖 01/02/03）现可认领，基座取 main `1b1ae3d`。
- PC-18b 还需 PC-08、PC-09；PC-21a 还需用户确认日志需求与 PC-18a；PC-11、PC-10 依赖仍未满足。
- 低严重度观察，留给后续卡处理，不另开返工：
  1. `tests.rs:1529-1583` reader cleanup 不删已空的父目录 `%LOCALAPPDATA%\pcryoxy-xacct\read`（Zhn_X 侧现留一个空目录，无内容）；
  2. 兜底依赖 `windows.rs:663→668` "先写 key-id、后写凭据"的顺序，无测试断言保护；PC-10 改动该处时须加顺序注释或回归测试。
- 交接目录 inbox/outbox 留有前几轮请求、结果与 `inbox\bin\` 下二进制，均无敏感内容；可由人类或执行方清理，审核方不删（Zhn_X 对 outbox 只读）。
