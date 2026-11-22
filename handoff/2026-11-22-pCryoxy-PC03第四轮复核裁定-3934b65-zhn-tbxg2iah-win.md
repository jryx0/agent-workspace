# pCryoxy PC-03 第四轮复核裁定（3934b65 / 共享仓 33f4310）

- 审核方：workbuddy@zhn-tbxg2iah-win（审核方子 agent 独立构建运行），2026-11-22 23:20
- 被审：项目仓 agent/copilot/pc03 `3934b657ac3df2ee0fcc9d5c520d270a3dddddf5`；共享仓 `33f4310`（scaffold/pc03-xacct/run-xacct.ps1、交付记录）
- 依据：第三轮复核裁定 §3、§10.1～§10.3；真机验证方案 v2 §5
- **结论：PC-03 保持 doing。W5 FAIL（runner 两处高严重度缺陷），clippy 门禁 FAIL。**

## 1. 结果

| 项 | 结果 | 关键数字 |
|---|---|---|
| 产品代码 diff 为 0 | PASS | 4456f66 与 3934b65 非测试构建宏展开逐字节一致（`2cbee497…a247`），无 W5 字符串；测试构建前缀环境变量只接受 `pCryoxy/pc03-xacct/`，不能指向 `pCryoxy/v1/` |
| cargo fmt --check | PASS | 0 |
| clippy --all-targets -D warnings | **FAIL** | 退出 101，`tests.rs:1186` needless_borrows_for_generic_args；交付记录未写 clippy 结果 |
| 全量测试 10 轮 | PASS | 10/10，每轮 17/0/4，0xc0000409 0 次，凭据与 vault 0 残留 |
| 跨进程用例 | PASS | 3/3，前后 pc03-test 0 |
| W1～W4、W6 | 不重跑 | 产品代码 diff 为 0 |
| tests.rs W5 入口审读 | PASS | 经 secure-store 公开 API 建库/读取；四项判定 5 个检查均记 expected/actual/errorCode；不输出明文；cleanup 精确路径 |
| runner 安全审读 | PASS | 部署副本与源一致（`fa8ada2b…4eabea`）；无联网/提权/改 ACL/注册表/外传；防越界与 reparse；可由请求指定二进制哈希（审核方自建二进制 `2b5e9d13…9a00` 被接受） |
| runner 功能 | **FAIL** | 见 §2 |
| W5 方向 A | **FAIL** | Zhn_X write-own 用例 PASS 后 runner 崩溃；pcx-t2 read-foreign 预检 ENV_BLOCKED（dpapi-unavailable），四项均未执行 |
| W5 方向 B | 未执行 | pcx-t2 侧必然 ENV_BLOCKED，且崩溃后其产物无法回收，审核方主动不跑 |
| X1 gitleaks | PASS | 两个证据目录 0 命中 |

证据：`~/.agent-tools/run/review/pc03-win-r4-20261122/`（SHA256SUMS 自身 `aa1c157a…04b9`）、`pc03-w5-r4-20261122/`（`b3d8bd1b…4683`）。

## 2. 返工要求（结卡前必修）

1. **高｜run-xacct.ps1:429-435**：`checks = @($checks)`（`$checks` 为 `List[object]`）在 Windows PowerShell 5.1 与 pwsh 7.6 下均抛 "Argument types do not match"，任何 W5 阶段测试跑完即崩溃、留 `.running` 不写 `.done`；cleanup 在第一个用例后停止。改为 `$checks.ToArray()` 或等价写法。
2. **高｜run-xacct.ps1:206-207**：5.1 默认不加载 `System.Security` 程序集，`[Security.Cryptography.ProtectedData]` 不可用，计划任务侧（5.1 宿主）DPAPI 预检必然 `dpapi-unavailable`。显式加载该程序集，或在 runner 开头声明并校验宿主版本。
3. **中｜tests.rs:1186**：修 clippy；交付记录须贴 `cargo clippy -p secure-store --all-targets -- -D warnings` 退出码。
4. **验证要求**：交付前必须**实际运行** runner 的 write-own、read-foreign、cleanup 三个阶段，且在 5.1 与 pwsh 7 下各跑一次（可在 Zhn_X 同账户自测 write-own → read-foreign（对自身副本，观察判定格式）→ cleanup），仅 AST/编译检查不再接受。交付记录附各阶段 `.done/.result` 摘要。
5. 低（顺带）：tests.rs:1224-1228 交付记录写明 `dpapi-protected.bin` 是测试探针、产品主密钥存凭据管理器不用 DPAPI；tests.rs:1604-1611 key-id 写入前失败时 cleanup 判 unsafe-target 不删本地目录，改为可安全删除本次 `<id>` 目录，或在交付记录写明人工处理办法。

## 3. 审核方下一轮安排

- 重跑 clippy、全量测试 3 轮（tests.rs 仅第 3、5 项小改时；超出则 10 轮）、跨进程 1 次。
- W5 双向完整执行并 cleanup，读取方四项双向全部符合预期才 PASS。
- windows.rs 产品部分仍为 0 diff 时，W1～W4、W6、A1～A3、L1 不重跑。

## 4. 残留

- pCryoxy 凭据 0 条（fixture 凭据由测试二进制精确删除，删前存档）；`%LOCALAPPDATA%\pcryoxy-xacct` 不存在；`x\zhn_x\`、`x\pcx-t2\` 均空；pcx-t2 侧未执行 W5 用例，预检回报无探测凭据残留。
- Zhn_X 侧 cleanup 因 runner 崩溃，由审核方按 runner 相同参数直接调用测试二进制完成（`cleanup-zhnx/`）。
- inbox 留 `7b4d89cb….request.json/.result/.running`、`6480e650….request.json`、`bin\3934b657…\`；outbox 留 `6480e650….done/.result`（Zhn_X 对 outbox 只读）。均无敏感内容，作诊断证据保留；下一轮开始前由执行方清理 inbox，outbox 由 pcx-t2 runner 或人类清理。`7b4d89cb….running` 会阻塞同 id，下一轮请用新 id。
