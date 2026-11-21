# pCryoxy PC-03 安全存储实施交付

项目: pCryoxy

- 卡号：PC-03
- 版本：实施任务卡 v1.1
- 当前状态：交付待审核；PC-03 仍为 doing / blocked，不代表结卡通过
- 输入基座：`2908e4e4cde5b060568b0d56ff270640c4ca3f63`
- 实施提交：`9b414f24824ab99f737013bc9ddea64fffcad43c`
- 分支：`agent/copilot/pc03`
- worktree：`C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc03`
- 权威输入：需求基线 v1.1、工程蓝图 v0.3、API Spec v1.2、实施任务卡 v1.1
- 依赖／范围审核：PC-00/PC-02 前置审核 `f38fe74`；PC-03/PC-04 阶段裁定 `93bd249f39e785db67ad94950a9a6eef854270e1`
- 未 push、未合并、未部署；请求 WorkBuddy 复审

## 变更文件

仅包含 PC-03 安全存储和测试：

- `crates/secure-store/src/lib.rs`
- `crates/secure-store/src/windows.rs`
- `crates/secure-store/src/linux.rs`
- `crates/secure-store/src/android.rs`
- `crates/secure-store/src/redact.rs`
- `crates/secure-store/src/tests.rs`
- `crates/secure-store/src/linux_tests.rs`
- `native/android/SecretStore.kt`
- `native/android/tests/SecretStoreDeviceChecks.kt`

基线相对改动：9 个文件，新增 2,565 行；未修改公共 trait、DTO、proto、公共锁文件、core-lock 或 PC-04 文件。本提交未增加依赖。

## 实现与安全边界

- 提供受控 `put` / `with_secret`、HMAC credential ID、AEAD 密文、staging/commit、vault reopen 和显式版本读取；旧版本不自动删除。
- Windows 后端将主密钥置于 Credential Manager，vault 版本为私有文件；检查当前调用身份、目录所有者与 ACL，并拒绝不安全路径。
- Linux 后端使用专属 UID、0700 目录、0600 文件、无符号链接打开与不可覆盖版本写入；root 身份不支持。
- Android Kotlin 后端使用 Android Keystore AES-GCM/HMAC 与 `noBackupFilesDir`；Rust 侧为 JNI adapter。
- 安全事件投影不包含原始第三方错误文本。脱敏边界限于本库的显式投影；不拦截其他组件自行记录的日志或 panic hook。
- `commit_staged` 只提交不可变 vault 版本，不代表 IR 与 vault 的跨存储原子提交。没有实现或声称跨存储原子性。
- 本轮测试仅使用测试 alias、测试 vault 和虚构字节/字符串；未使用真实凭据。

## 工具与静态检查

Windows 11 Enterprise LTSC 10.0.26100 x64；Rust/Cargo 1.100.0，MSVC 18 Community 环境：

| 命令 | 结果 |
|---|---|
| `cargo fmt -p secure-store -- --check` | 退出码 0 |
| `cargo clippy -p secure-store --all-targets --locked --offline -- -D warnings` | 退出码 0 |
| `git diff --check` | 退出码 0 |
| Gitleaks 8.30.1：`gitleaks dir --redact --no-banner crates/secure-store/src` | 退出码 0，无命中 |
| Gitleaks 8.30.1：`gitleaks dir --redact --no-banner native/android` | 退出码 0，无命中 |
| Gitleaks 8.30.1：`gitleaks protect --source <worktree> --staged --redact --no-banner` | 退出码 0，无命中 |

初次目录扫描把测试用合成凭据的 key-value 格式识别为 generic-api-key；已改为明确的合成字段文本，相关脱敏测试通过，之后源码、Android 目录和暂存差异扫描均无命中。

## Windows 执行回执

环境：Windows 11 Enterprise LTSC x64，Rust/Cargo 1.100.0，MSVC 环境；以下每条均为定向真实平台测试，测试用当前交互式账户及测试专属 Credential Manager target：

| 命令（Cargo 全局参数） | 结果 |
|---|---|
| `cargo test -p secure-store --locked --offline ambiguous_paths_and_unprotected_directories -- --nocapture` | 1 passed，退出码 0；拒绝不安全路径和不受保护目录 |
| `cargo test -p secure-store --locked --offline actual_windows_large_secret_restart_hmac_and_staging -- --nocapture` | 1 passed，退出码 0；4097 字节虚构秘密、HMAC、staging、子进程重开读取 |
| `cargo test -p secure-store --locked --offline independent_candidates_do_not_overwrite_old_versions -- --nocapture` | 1 passed，退出码 0；旧版本保留且候选版本独立 |
| `cargo test -p secure-store --locked --offline missing_master_key_preserves_old_ciphertext_and_does_not_reprovision -- --nocapture` | 1 passed，退出码 0；Credential Manager 返回缺失项错误（1168），旧密文保留且不重新生成密钥 |
| `cargo test -p secure-store --locked --offline sensitive_parse_network_jni_and_crash_errors_cannot_reach_projection -- --nocapture` | 1 passed，退出码 0 |

此前 Windows 全套测试的一次回执为 6 passed、8 failed、2 ignored，退出码 101；包含 Credential Manager 1168／资源错误，根因未定。本轮为避免在容量受限账户重复压力探针，未重跑全套。当前定向测试在交互式账户下通过，不是 Windows Service 身份验收；服务 SID/ACL、服务进程重启和异账户访问仍未实测。

## Linux 执行回执

环境：Ubuntu 24.04.4 LTS WSL2，内核 `6.18.33.2-microsoft-standard-WSL2`，x86_64、glibc 2.39、UID 1000；Rust/Cargo 1.100.0。主机没有 `cc`，编译命令使用已存在的 Zig 0.16.0 linker wrapper；未安装系统包或全局依赖。

编译／执行过程：

1. 在 `/mnt/c/.../copilot-pc03` 执行 Cargo 测试时，Cargo 将测试当前目录设为 NTFS worktree，Linux 后端拒绝该不安全祖先路径；3 个平台用例在 fixture 初始化处失败，退出码 101。这是执行目录安全检查失败，不是通过结果。
2. 使用 `--manifest-path` 从 `/home/zhn_x` 调用 Cargo，Cargo 仍将测试进程当前目录设为 crate 目录；同样 3 个用例失败，退出码 101。
3. 从 `/home/zhn_x` 直接运行已构建测试二进制：`/mnt/c/Users/Zhn_X/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/pc03-validation-linux-target/debug/build/secure-store/0c0f8d091585417a/out/secure_store-0c0f8d091585417a --test-threads=1`。结果：4 passed、0 failed、1 ignored（子进程用例由重开父测试启动），退出码 0。

该实测覆盖同 UID 下 vault 重开/子进程读取、0700/0600 权限拒绝、缺失密钥、篡改拒绝、符号链接拒绝、不可变版本冲突及旧密文保留。测试二进制为验证用，不是产品产物；大小 16,897,032 bytes，SHA-256 `7f6a31760275f1c02e0a6895179e01d003271279bfa42a5f1e52a99bbab790e2`。`ldd` 仅显示 `libc.so.6` 与动态加载器。

第二账户拒绝尚未验证：`setpriv --reuid=65534 --regid=65534 --clear-groups -- id -u` 退出码 127，环境返回 `setresuid failed: Operation not permitted`。不得据此宣称跨账户隔离通过。

## Android 执行回执

`adb devices -l` 退出码 0，但设备列表为空。无获准 Android 真机，本轮没有运行 Keystore、`noBackupFilesDir`、进程重启持久化或异账户测试；Kotlin/JNI 源码存在不等于编译或设备运行通过。Android 设备验收 blocked。

## 已覆盖等级与未覆盖项

- 源码核验：完成。
- Windows 工具链／格式／Clippy：完成。
- Linux 工具链构建与测试二进制：完成；动态依赖检查完成。
- Windows/Linux 定向平台运行：按以上回执部分通过。
- Windows 服务身份和异账户、Linux 第二账户、Android 真机：未覆盖。
- Windows 全套既有失败根因：未查明；未以定向通过替代全套验收。
- systemd、TUN、路由、代理互通、Web Token、生产服务生命周期，以及 IR/vault 跨存储原子提交：本卡不覆盖。

## 挂起任务（当前全量快照）

来源为最新已读的 `2026-11-19-pCryoxy任务认领入口-zhn-tbxg2iah-win.md`；2026-11-21 PC-03/PC-04 阶段裁定没有变更该快照。

- pCryoxy：无挂起项。PC-03 仍 doing / blocked，等待本次实施证据复审；这不是 suspended。
- prnmgt：S1 `T-059/T-060/T-061`、S2 `P0 二次真机调研`、S3 `v4 / #18` 仍 suspended，解挂权属于人类；本交付不触及、不解挂。
- pRayShell：无挂起项；项目 closed。

## 后续与审核请求

请 WorkBuddy 按 PC-03 卡面复审本提交和分项证据，裁定为“通过、退回、受外部条件阻塞”之一。在审核前不标记 done，不合并、不 push、不部署。优先补齐 Windows 服务身份/ACL、Linux 第二账户与 Android 获准真机证据；另需裁定此前 Windows 全套测试失败根因。

**本提交不代表 PC-03 结卡通过。**
