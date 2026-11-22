# pCryoxy PC-03 返工交付

项目：pCryoxy
状态：**doing，等待审核方执行 W5 双向验证及 Android 双机复跑**
项目提交：`4456f66d9536477ee6e762dab72e7494428e6adb`
分支：`agent/copilot/pc03`

## 七项逐项证据

1. **Clippy**：`cargo clippy --manifest-path crates/secure-store/Cargo.toml --all-targets -- -D warnings` 通过。`windows.rs` 测试专用错误变量改为 `_error`；Rust 测试中的 Clippy 告警一并消除。
2. **全量测试稳定性与凭据清理**：`cargo test --quiet --manifest-path crates/secure-store/Cargo.toml -- --test-threads=8` 连续 10 次通过；每轮均为 17 passed、0 failed、2 ignored。跨进程用例在独占测试锁内回收并验证 `pCryoxy/pc03-test/` 前缀为空；其他 fixture 持共享锁并在析构时清理，panic 展开期间清理失败不再触发二次 panic。测试未触碰 `pCryoxy/v1/`。
3. **跨进程测试隔离**：`Fixture` 将测试锁持有至资源清理完成。跨进程父用例持有独占锁，父/子测试 fixture 使用协调后的无嵌套锁路径，避免死锁并防止其他测试进程在前后清理间插入凭据。
4. **PC-03 文档**：新增项目 `docs/secure-store.md`，记录 Windows 凭据配额与初始化回滚、孤儿密钥的确认式诊断/回收、5 次 × 25 ms 读取重试、Android 所有写入方持锁，以及 `Os.rename` 覆盖风险。明确 H2 由 PC-11 评估、Windows 互斥仅保证进程内并由 PC-10 处理；测试和 W5 凭据前缀与产品前缀隔离。
5. **W5 runner schema v2**：`C:\Users\Public\pcryoxy-xacct\run-xacct.ps1` 已绑定本项目提交、二进制相对路径和 SHA-256。`write-own` 由 `pcx-t2` 批处理登录生成 DPAPI 密文文件及 `pCryoxy/pc03-xacct/<id>` 凭据，向 `outbox\<id>\fixture.json` 写入路径、散列和密文编码，不输出明文；`read-foreign` 将 `foreignPath` 限制在 `C:\Users\Zhn_X\.agent-tools\run\xacct-fixture\<request-id>\fixture.json`，逐项记录文件读取（预期成功）、DPAPI Unprotect（预期失败）和 CredRead（预期 not-found，Win32 1168）的 expected/actual/errorCode。Zhn_X 阶段要求交互登录、非提权令牌，并将 `whoami /groups` 原文与 Mandatory Label 写入 manifest。脚本 PowerShell AST 解析通过；**未触发计划任务或执行 W5**。
   - 提交：`4456f66d9536477ee6e762dab72e7494428e6adb`
   - 构建：`cargo test --manifest-path crates/secure-store/Cargo.toml --no-run`
   - 二进制：`C:\Users\Public\pcryoxy-xacct\inbox\bin\4456f66d9536477ee6e762dab72e7494428e6adb\secure_store_tests.exe`
   - SHA-256：`1c17b51ac129c8914d8cdb65c01e334e6191d49d1b8df02c050e8fd4adaee56d`
6. **Android 宿主**：补充 `recover-pending` phase，成功和失败均调用 `sendStatus`；README 固定组件名、要求同时检查 instrumentation code/status/result，并说明 exit 0 陷阱及卸载重装后旧 proof 不可 cleanup。共享脚手架本地构建成功，未安装或运行设备测试。
7. **H1 pending 恢复**：`SecretStore.persistVersion` 在持锁状态下先验证并回收陈旧 pending；写入、fsync、读回逐字节校验后再确认 final 不存在并 rename。写入或校验失败时清理本次 pending。新增宿主残留 pending 用例并验证新版本可重新打开。由于改动了 `SecretStore.kt`，仍需审核方依裁定双机重跑 A1～A3 与新用例。

## 验证边界与后续

- Android 宿主构建 SHA-256：`9cc3c1c8884a06b3738c05300b813138ee7753fa3355e05bccb0dbd233e89fef`；D8 输出 Kotlin metadata 版本提示，构建与 APK 验签均成功。
- W5 仅更新 runner 和固定提交的测试二进制；没有执行跨账户读写，`pc03-xacct` fixture/target 待审核方完成双向测试后由所属账户按 fixture 中的精确路径清理。
- 不在 PC-03 实现 H2/H3；PC-03 状态保持 doing，待审核方完成 W5、Android 双机复核及其余裁定复跑后再判定结卡。

[@copilot @zhn-tbxg2iah-win 2026-11-22 19:43 UTC+8] 已按七项逐项提交证据；没有运行真机安装或跨账户任务。
