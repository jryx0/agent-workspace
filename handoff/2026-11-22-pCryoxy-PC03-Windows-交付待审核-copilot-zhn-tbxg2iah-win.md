# pCryoxy PC-03 Windows 验收子集交付待审核

- 项目：pCryoxy
- 卡号：PC-03；范围：真机验证方案 v2 §3、§5 的 Windows W1～W6。
- 执行人：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-22。
- 状态：**blocked / 交付待审核**；未标 done、未合并。
- Worktree：`C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc03`
- 分支：`agent/copilot/pc03`；项目提交：`f2244cf9eaae5a5e30120bfdad466b0323ba7a7f`，基座 `c73d59d4eaddd3bfc1e47113b1ea6515010bcbeb`；origin 分支已推到该提交。

## 变更

仅 `crates/secure-store/src/tests.rs`，新增 W6 token rotation 测试及 W3 other-writable ancestor 断言；未改产品实现、依赖清单或 lockfile。提交文件 SHA-256 为 `737409f5970b35465d7058c5d0dd0971b12179aff376964353b179bd3fbff8b3`。

测试证据包的 manifest 记录基座 `c73d59d` 和当时的授权工作树测试改动；manifest `sourceTestsSha256` 与当前提交中的 `tests.rs` 完全相同，证明被测源文件内容与交付提交一致，但不是在该提交 SHA 上生成的二进制。

## Windows 矩阵结果

| 项 | 状态 | 执行方结果 |
|---|---|---|
| W1 | PASS | 同账户写读与重启后读取 |
| W2 | PASS | 篡改/版本替换拒绝及密钥缺失行为 |
| W3 | PASS | junction 等既有 3 项通过；新增 other-writable ancestor exact 用例最终退出 0 |
| W4 | BLOCKED | 两轮 exact 均退出 101，Windows error 8（索引 7、后索引 6）；依矩阵两轮上限停止。1168 阶段在同一用例内，未到达 |
| W5 | BLOCKED | 计划任务 `pcryoxy-xacct` 尚未由管理员登记/核验，查询权限拒绝；未运行，未使用 test1 |
| W6 | PASS | token rotation 用例通过 |

W5 还有双向 fixture 协议缺口：现有请求/runner 尚不能证明 `pcx-t2` 与 `Zhn_X` 双向读/解对方数据均被拒。未扩展请求 schema 或矩阵，需另行裁定。

## 证据与跨账户 runner

- 初轮证据：`C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc03\target\pc03-evidence\round-20261122T085611.zip`，SHA-256 `38fae770acb1c2f3f898bc6a9fc5b4569d479c52534aeeacf40dc4c07c943046`。
- 补充证据：`C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc03\target\pc03-evidence\supplement-20261122T090346.zip`，SHA-256 `df2a5069573e225522ef7a45d0cfe82ed2b6b86d17674998f7b1580bfbe9fb94`。
- W3 最终 exact 证据：`C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc03\target\pc03-evidence\w3-final-20261122T090753.zip`，SHA-256 `303623d00cca2c3d05adacf5d75a9c55d911ba80c9e69aab54aacc29c26448e7`。
- 固定 runner：`C:\Users\Public\pcryoxy-xacct\run-xacct.ps1`；本次已绑定精确提交 `f2244cf9eaae5a5e30120bfdad466b0323ba7a7f` 与 `bin\f2244cf9eaae5a5e30120bfdad466b0323ba7a7f\secure_store_tests.exe`。私有源与 Public 文件 SHA-256 均为 `619ec806e23c4624eb8f85b749f5cb09b01e4b9a7390ec0f7071e58d800fa9da`；纯 ASCII、PowerShell parse 与两段内嵌 C# 编译通过。目录 ACL 与 §3.2a 相符；未注册或修改计划任务。

## 审核请求与边界

请 WorkBuddy 按冻结矩阵复核提交、证据和 W4/W5 阻塞。W4 连续两轮失败，停止补证；W5 须先由人类完成计划任务登记/核验，并裁定双向 fixture 方案。当前结果不代表 PC-03 done，也不放行下游卡。
