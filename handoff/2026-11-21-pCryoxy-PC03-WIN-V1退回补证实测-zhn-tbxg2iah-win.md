项目: pCryoxy

# PC-03-WIN-V1 退回补证：test1 串行实测

- 结论：**失败**。用户随后要求终止验证；不再执行测试。PC-03 仍为 doing／有条件通过，不标 done。
- 记录：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-21 UTC+8。
- 前次“受外部条件阻塞”结论已被 `71a6ab0` 退回，不再采信；中立构建方案确实可执行，历史日志缺失也不是停止理由。
- 本次签名记忆行在并发共享仓提交 `ae7ec58` 中已被提交；本回执独立提交，不改写该提交。
- 原项目现场 `agent/copilot/pc03`，HEAD `c73d59d4eaddd3bfc1e47113b1ea6515010bcbeb`，基座 `2908e4e`；未修改产品代码、清单、锁或 ACL，不 push 项目分支、不合并、不部署。

## 环境和构建

Windows 11 企业版 LTSC 10.0.26100；rustc 1.100.0、cargo 1.100.0；MSVC 18 Community。test1 SID `S-1-5-21-155457669-4072508151-1813346089-1002`，本地 Users 成员，交互令牌含 `NT AUTHORITY\INTERACTIVE`，Medium 完整性。人类先交互登录 test1 建立 profile，再在 test1 PowerShell 中直接输入命令启动测试；未使用密码、提权、计划任务或服务。

以 `git archive --format=tar` 导出精确提交，在 `C:\Users\Public\pcryoxy-pc03-win-c73d59d-8f210aeb` 解包；设置 `CARGO_TARGET_DIR` 为该目录下 `build-target`，调用 `vcvars64.bat` 后在该目录执行 `cargo test -p secure-store --locked --offline --no-run`。首轮使用默认 Cargo 缓存失败退出 101（找不到 `aes-gcm`）；将同项目既有离线缓存和索引复制到本会话隔离目录后重跑，退出 0，无下载或新依赖。测试二进制：

`build-target\debug\build\secure-store\4abc1f1f74e69717\out\secure_store-4abc1f1f74e69717.exe`，SHA-256 `96f4727473f3ce43850ee49c6cc1a91e53875d12e2b70d8de335fb68122e1654`；`--list` 退出 0，16 项。

test1 PowerShell 以 `Start-Process`、`-WorkingDirectory C:\Users\test1\AppData\Local\Temp\pcryoxy-pc03-win-c73d59d-8f210aeb` 启动该二进制，参数 `--test-threads=1 --nocapture`，退出 **101**。进程启动前以 test1 SID 和上述 SHA-256 校验；套件结果 **1 passed／13 failed／2 ignored**。用户最初尝试 `-File` 时 PowerShell 执行策略拒绝，测试未启动；之后改为交互输入命令，未变更策略。

## 逐项结果

所有行来自上述单次套件，退出码均为**套件进程 101**；未单独启动这些项，故没有逐项独立退出码。`F` 指 `tests.rs:48:50` fixture 初始化 `Windows::initialize(...).unwrap()` 返回 `PermissionDenied`；并发项的工作线程发生同一失败，父线程随后在 `tests.rs:218:50` panic。

| 用例 | 结果 | 关键证据 |
|---|---|---|
| `redact::tests::sensitive_parse_network_jni_and_crash_errors_cannot_reach_projection` | passed | 白名单投影测试；不代表真实端到端日志或崩溃上传已验证 |
| `tests::actual_ancestor_rename_is_blocked_while_guarded` | failed | F |
| `tests::actual_cross_process_provisioning_and_commits_survive_test_cleanup` | failed | F；未进入跨进程验证 |
| `tests::actual_junction_ancestor_is_refused` | failed | F |
| `tests::actual_windows_large_secret_restart_hmac_and_staging` | failed | F；未验证大秘密或重开 |
| `tests::ambiguous_paths_and_unprotected_directories_are_refused` | failed | F |
| `tests::authenticated_tamper_and_version_substitution_are_rejected` | failed | F |
| `tests::concurrent_distinct_provisioning_preserves_all_live_keys` | failed | F；工作线程 panic，父线程 join 失败 |
| `tests::concurrent_process_child` | ignored | 父测试使用的 helper，本轮未由父测试启动 |
| `tests::independent_candidates_do_not_overwrite_old_versions` | failed | F |
| `tests::missing_master_key_preserves_old_ciphertext_and_does_not_reprovision` | failed | F；未验证密钥缺失 |
| `tests::native_create_delete_distinct_targets_keep_new_credentials` | failed | `tests.rs:197:13`，`native round=10 operation=5`，`left: Err(1168)`，`right: Ok(())` |
| `tests::panicking_consumer_does_not_poison_vault_or_hold_a_global_lock` | failed | F |
| `tests::real_immutable_destination_collision_is_unknown_without_overwrite` | failed | F |
| `tests::real_parallel_candidates_remain_independent` | failed | F |
| `tests::restart_child` | ignored | 重开父测试使用的 helper，本轮未由父测试启动 |

首次失败原文：`called Result::unwrap() on an Err value: PermissionDenied`，位置 `crates\secure-store\src\tests.rs:48:50`。原生并发测试在独立路径实际观察到 Credential Manager 错误 1168；该事实不能证明其是另外 12 项失败的原因，也不能认定容量错误。

## 祖先 ACL 实测与定性边界

test1 只读执行 `whoami /user`、`whoami /groups`、`Get-Acl` 和 `icacls`；目录未修改。`C:\Users\test1` owner 为 `NT AUTHORITY\SYSTEM`、继承关闭，DACL 的 `icacls` 原文：

```text
NT AUTHORITY\SYSTEM:(OI)(CI)(F)
BUILTIN\Administrators:(OI)(CI)(F)
ZHN-TBXG2IAH\test1:(OI)(CI)(F)
S-1-15-3-65536-599108337-2355189375-1353122160-3480128286-3345335107-485756383-4087318168-230526575:(S,X)
ZHN-TBXG2IAH\Zhn_X:(OI)(CI)(F)
```

`AppData`、`AppData\Local`、`Temp` 和测试 cwd owner 均为 test1、继承开启，其 ACL 均含 `ZHN-TBXG2IAH\Zhn_X:(I)(OI)(CI)(F)`。后端 `check_ancestor` 不信任其他普通用户 SID 的写入权限；该 ACL 与源码检查可解释 fixture 的 `PermissionDenied`，但本轮没有插桩直接定位具体拒绝的祖先，因此不写成已逐路径动态证明。此祖先 ACL 暴露的问题须人类裁决；本轮未修改。

历史 `6 passed／8 failed／2 ignored` 的八个名称和逐项日志未保留，无法把本轮失败一一映射到历史八项；不凭 13 个新失败反推历史名称，也不虚报逐项可重现／不可重现。新一轮独立原生测试的 1168 是实际再次观察，非历史逐项对应证明。

## 未覆盖、脱敏和清理

- 本轮没有成功生成 vault；vault 文件与目录的 owner SID、DACL、继承及异账户越界读取／互不可解、Credential target 双向隔离均未实测。test1 和 Zhn_X 的 ACL 不能等同于隔离通过。
- 同账户实际写读、真正进程重启、密钥缺失不重 provision、不覆盖 alias、4097 字节秘密的密文文件、真实日志／事件／崩溃通道无泄漏，均未完成。服务身份仍未覆盖。
- 用户明确终止验证，未做定向复测；无法给出独立定向退出码或八项历史逐项定性。
- 本次仅使用合成 fixture。`gitleaks dir --redact --no-banner` 分别扫描本次套件 stdout、stderr、结果文件及 ACL 诊断文件，均退出 0、无命中；无真实端到端日志不等于已验证其无泄漏。
- 人类在 test1 会话中确认测试临时目录为空并删除；原生并发测试使用临时随机 target，源码的析构负责删除，但本轮未独立枚举验证所有 target 已清除，不能声称已核实零残留。
- 中立构建目录及本会话独立 Cargo 缓存、源码归档已删除；不触碰其他账户的真实 vault。

## 挂起任务（当前全量快照）

继承最近有效快照；本轮不解挂任何项目。

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无 suspended 项；pRayShell 已 closed。
