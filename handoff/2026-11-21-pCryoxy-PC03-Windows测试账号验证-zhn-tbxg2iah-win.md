项目: pCryoxy

# PC-03-WIN-V1 Windows 测试账户补证

- 结论：**受外部条件阻塞**；本专项没有通过，不改变 PC-03 的既有状态，不标 done。
- 记录：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-21 UTC+8。
- 现场：`C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc03`，`agent/copilot/pc03`，HEAD `c73d59d`，基座 `2908e4e`；未改项目文件、未 push、未 merge、未部署。
- 沿用 PC-03 既有认领；专项派工已追加项目记忆。

## 环境和门槛

| 项 | 本轮事实 |
|---|---|
| OS | Windows 11 企业版 LTSC，10.0.26100，build 26100 |
| 工具链 | rustc 1.100.0、cargo 1.100.0，各 `--version` 退出 0 |
| 当前令牌 | `WindowsPrincipal.IsInRole(Administrator)` 为 False，非提升 |
| test1 | 启用；SID `S-1-5-21-155457669-4072508151-1813346089-1002`；本机组成员查询结果为 Users |
| profile | 人类交互登录后，Win32_UserProfile 已登记 `C:\Users\test1`，查询时 Loaded=True；LastLogon 为 2026-11-21 22:33:05 |
| 服务登录权 | LSA `LsaOpenPolicy(POLICY_LOOKUP_NAMES)` 成功，直接枚举 test1 account rights 返回 Win32 错误 2；不能排除通过组授予，**有效权限未确认**，没有启动服务 |
| test1 启动机制 | 人类交互登录仅用于建 profile；本轮未以 test1 启动任何测试进程 |
| 凭据 | 未读取或记录口令；回执为 `<redacted>` |

## 执行障碍

`crates/secure-store/src/tests.rs` 的 `native_fixture_guard` 使用 `env!("CARGO_MANIFEST_DIR")` 生成固定的 `<构建时 crate 目录>\target\pc03-native-fixture.lock`，并尝试创建目录和读写锁文件。按卡面从当前 worktree 构建、再只复制二进制到中立只读目录，不会改变该编译期绝对路径；测试仍须写入 `C:\Users\Zhn_X\...`。test1 默认无此访问权，且卡面禁止修改 ACL。尚未以 test1 实测该访问失败，因此这是源码证实的移植阻碍，而不是伪造的运行回执。

按任务要求先报告，未改测试或产品代码，未更改 ACL，未运行 Credential Manager 压力测试。需人类或契约所有者批准安全的测试夹具修订/构建方案，以及可用的 test1 进程启动机制后重试；不得用计划任务冒充服务。

## 测试和历史失败

| 项 | 命令 | 退出码 / 计数 | 结果 |
|---|---|---|---|
| test1 全套 | `secure_store-<hash>.exe --test-threads=1 --nocapture` | 未执行 / 未取得 | 阻塞；没有二进制转移及实际测试回执 |
| test1 定向测试 | 各测试名配 `--exact --nocapture` | 未执行 / 未取得 | 阻塞 |
| 历史 Windows 全套 | 历史回执，具体命令及逐项日志不可用 | 101；6 passed、8 failed、2 ignored | 原始名称、错误及轮次无法核对；不得将任一历史失败判成已复现、不可复现或已定位根因 |

历史交接另记录过 `CredReadW` 1168 及独立容量探针 `ERROR_NOT_ENOUGH_MEMORY` 8；二者不是历史 8 项的逐项对应证据。历史失败名称均未知，无法可靠列出八行逐项定性表；如取得脱敏原始日志再做对应。

源码列出的 16 项（不是执行结果）：`native_create_delete_distinct_targets_keep_new_credentials`、`concurrent_distinct_provisioning_preserves_all_live_keys`、`actual_cross_process_provisioning_and_commits_survive_test_cleanup`、`concurrent_process_child`（ignored）、`actual_windows_large_secret_restart_hmac_and_staging`、`restart_child`（ignored）、`missing_master_key_preserves_old_ciphertext_and_does_not_reprovision`、`authenticated_tamper_and_version_substitution_are_rejected`、`independent_candidates_do_not_overwrite_old_versions`、`ambiguous_paths_and_unprotected_directories_are_refused`、`panicking_consumer_does_not_poison_vault_or_hold_a_global_lock`、`real_parallel_candidates_remain_independent`、`actual_junction_ancestor_is_refused`、`actual_ancestor_rename_is_blocked_while_guarded`、`real_immutable_destination_collision_is_unknown_without_overwrite`、`sensitive_parse_network_jni_and_crash_errors_cannot_reach_projection`。

## 未覆盖与清理

- 同账户写读、真正重启、密钥缺失、不覆盖 alias、大秘密、错误注入及日志/事件无泄漏：本轮均未实测。既有交互账户的定向结果见原 PC-03 交接，不能替代 test1 证据。
- test1 与 Zhn_X 的 vault 和 Credential target 双向越界、互不可解：未实测；没有拒绝回执。
- vault 目录及文件 owner SID、DACL 原文、继承状态：无测试 vault，未实测；未改 ACL。
- 服务身份：有效 SeServiceLogonRight 未确认，未覆盖；计划任务/批处理身份不能代替。**[人类执行]** 使用本地安全策略 `secpol.msc` → 本地策略 → 用户权限分配 → “作为服务登录”，检查直接和所属组的授权及“拒绝作为服务登录”的覆盖；如需授权，须先另行批准，由人类操作。之后由人类通过真实 SCM 服务上下文进行测试，记录服务 SID、进程身份、重启及清理；本卡不自动授权或创建服务。
- 未创建中立测试副本、测试 target 或 vault；未触碰真实 vault；test1 账户保留。
- `gitleaks dir --redact --no-banner <本回执>` 和同命令扫描 `memory/projects/pCryoxy.md`：各退出 0，无命中；没有运行测试、没有测试日志，因此不能宣称日志无秘密。

## 挂起任务（当前全量快照）

继承最新交接，本轮不解挂任何项目。

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无 suspended 项；pRayShell 已 closed，无 suspended 项。
