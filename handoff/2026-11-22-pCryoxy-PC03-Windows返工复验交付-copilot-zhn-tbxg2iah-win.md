# pCryoxy PC-03 Windows 返工复验交付待审核

- 项目：pCryoxy
- 卡号：PC-03；状态：**doing / 返工交付待审核**，未标 done。
- 执行人：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-22。
- 分支：`agent/copilot/pc03`；提交 `dc3d34d825dca715e29e174297f449c83216273a`，已推送 origin。
- 基座：`f2244cf9eaae5a5e30120bfdad466b0323ba7a7f`。

## 修复

- 在同进程内用一个互斥锁覆盖 `CredReadW`、`CredWriteW`、`CredDeleteW`，避免产品线程间 create/delete 交错。
- 写凭据后立即读回校验；读取遇 `ERROR_NOT_FOUND` 时最多 5 次、间隔 25 ms 重试（最多约 100 ms）。
- 初始化失败回滚可能写入的 master credential 和 `key-id`；部分 `key-id` 文件写入失败时也清理。
- 增加孤儿 master-key 诊断与回收 API。诊断调用者必须提供全部活动 vault roots；回收必须显式确认，并在删除前重做诊断。接口不读取或返回密钥内容。
- W4 使用专用 target 前缀 `pCryoxy/pc03-w4-native/`，运行前仅按此前缀回收测试残留；首次写入遇 error 8 输出 `ENV_BLOCKED: credential quota`，不继续做容量断言。

## W4 诊断与最终验收

清理后基线曾同时复现两类 1168：即时读取缺失后延迟恢复，以及 join 后延迟重读仍缺失。前两轮诊断日志为 16/20、17/20；由此保留了有界读回重试，并针对持久缺失采用同进程凭据操作串行化。

首轮修复后 20 次运行**未计入验收**：测试夹具锁也串行化了 create/delete。随后将该锁移到整个测试用例边界，仅阻止其他测试进程同时清理/使用测试凭据；`NativeFixture` 的 create/delete 操作不再获取夹具锁，仍会在产品互斥锁上竞争。重新执行 exact 用例 20 次，**20/20 通过、0 失败、0 次 ENV_BLOCKED**。每次用例内部仍运行 24 轮并发 create/delete。

- 命令：`cargo test -p secure-store --locked --offline tests::native_create_delete_distinct_targets_keep_new_credentials -- --exact --test-threads=1 --nocapture`，重复 20 次。
- 复验日志：`~/.copilot/session-state/9c3b77d9-71d5-42cb-8b89-694c4ab7ac59/files/pc03-w4-final-20-verified.log`
- 日志 SHA-256：`9e4b6654069503dcf30a1e977d9e23aa424f629c7bc64e28e5ba2476212e9d43`
- `failed_initialization_rolls_back_written_master_and_marker`、`orphan_master_key_cleanup_requires_confirmation_and_exact_diagnosis`、`actual_cross_process_provisioning_and_commits_survive_test_cleanup` 均通过；`cargo fmt --all -- --check` 通过。

## 跨进程边界与凭据配额风险

上述互斥锁是**进程内**锁，不提供跨进程锁。正常打开 vault 只读凭据；同一 vault 的初始化由独占目录创建限制为单个成功初始化者；维护性孤儿回收要求同一用户的客户端进程静止。已有跨进程测试覆盖不同 roots 的 provision/read，并由测试夹具串行化清理；它**不证明**任意跨进程并发 CredWrite/CredDelete 安全，也不应如此表述。若未来支持多进程并发删除/写入，需另行设计跨进程同步。

审核裁定记录的旧测试曾留下 940 条 `pCryoxy/v1/*/master`，占用每用户凭据配额并使 `CredWriteW` 返回 error 8；初始化失败若不回滚也会永久消耗配额。本轮没有删除或修改任何既有用户凭据；产品前缀仍为 `pCryoxy/v1/`，测试只用专用前缀。孤儿回收不会自动执行，必须由调用方取得用户确认。

## 尚未结卡

- W5 计划任务查询仍受访问拒绝阻塞，Public runner 的 schema v2/W5 阶段未修改；不得用 `test1`，需先解决 `pcx-t2` 任务访问/注册与待处理 inbox 请求。
- Android 源码和宿主已返工，但未在设备安装/运行 A1～A3。
- PC-03 仍为 doing，待 WorkBuddy 按冻结矩阵复核；不请求或宣称整卡 done。
