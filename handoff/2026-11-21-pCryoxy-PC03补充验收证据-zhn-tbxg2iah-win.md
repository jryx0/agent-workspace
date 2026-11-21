# pCryoxy PC-03 补充验收证据

项目: pCryoxy

- 卡号：PC-03
- 版本：实施任务卡 v1.1（补充验收）
- 当前状态：交付待复审；仍为 doing / blocked，本记录不代表结卡通过
- 输入基线：`2908e4e4cde5b060568b0d56ff270640c4ca3f63`
- 前置阶段裁定：`33a5b6e06c2123717f11995d5ca681a30d5845fb`
- 原实施提交：`9b414f24824ab99f737013bc9ddea64fffcad43c`
- 本次补充实施提交：`c73d59d4eaddd3bfc1e47113b1ea6515010bcbeb`
- 分支：`agent/copilot/pc03`
- worktree：`C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc03`
- 未 push、未合并、未部署；请求 WorkBuddy 复审

## 变更范围

本次只新增 Linux 权限与多 UID 测试证据：

- `crates/secure-store/src/linux_tests.rs`

改动包含目录、master key、vault 文件的 UID/权限断言，以及隔离 UID fixture、服务 UID 重启读取和异 UID拒绝测试。未修改 Windows/Android 后端、PC-02、PC-04、公共 `SecretStore` trait、proto、公共锁文件或依赖；未新增依赖。

## Linux 实测

环境：WSL2 Ubuntu 24.04.4、x86_64、glibc 2.39；Rust/Cargo 1.100.0，已登记的 Zig 0.16.0 linker wrapper。测试由 WSL root 监督器通过 `setpriv` 降权运行；服务 UID 为临时数值 UID 25003，拒绝访问 UID 为 25004。没有创建持久系统账户或修改系统配置。

测试二进制：

`/mnt/c/Users/Zhn_X/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/pc03-validation-linux-target/debug/build/secure-store/0c0f8d091585417a/out/secure_store-0c0f8d091585417a`

构建命令：`cargo test -p secure-store --locked --offline --no-run`，退出码 0。构建使用上述隔离 Cargo 缓存、target 目录及已登记的 linker wrapper；本次使用重新编译后的测试二进制复测。

实测命令序列（以下 fixture/ID 为本次虚构测试数据；执行时工作目录为所示临时目录）：

```bash
BIN=/mnt/c/Users/Zhn_X/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/pc03-validation-linux-target/debug/build/secure-store/0c0f8d091585417a/out/secure_store-0c0f8d091585417a
BASE=/home/pc03-pc03-uid-tests-20261121-0932
cd "$BASE"

setpriv --reuid=25003 --regid=25003 --clear-groups -- "$BIN" --test-threads=1
setpriv --reuid=25003 --regid=25003 --clear-groups -- "$BIN" --ignored --exact linux_tests::linux_prepare_service_uid_fixture --nocapture

ROOT=/home/pc03-pc03-uid-tests-20261121-0932/pc03-linux-test-317184e84f984339
REF=8567158055369306495
VERSION=0aa5d01c859b55fe15681d5dfd802d08
stat -c 'uid=%u mode=%a path=%n' "$ROOT" "$ROOT/master.key" "$ROOT/$VERSION.vault"

setpriv --reuid=25003 --regid=25003 --clear-groups -- env PCRYOXY_PC03_LINUX_CHILD_ROOT="$ROOT" PCRYOXY_PC03_LINUX_CHILD_REF="$REF" PCRYOXY_PC03_LINUX_CHILD_VERSION="$VERSION" "$BIN" --ignored --exact linux_tests::linux_restart_child --nocapture
setpriv --reuid=25004 --regid=25004 --clear-groups -- env PCRYOXY_PC03_LINUX_CHILD_ROOT="$ROOT" "$BIN" --ignored --exact linux_tests::linux_other_uid_open_denied_child --nocapture
```

上述分项由临时 session harness 顺序执行；harness 在测试后删除，未作为项目文件提交。实际结果：

- 服务 UID 主测试集：4 passed、0 failed、3 ignored，退出码 0。3 个 ignored 项是被单独启动的 fixture/restart/异 UID helper。
- fixture 准备：1 passed，退出码 0。
- 服务 UID 25003 重启后读取：1 passed，退出码 0，输出 `pc03-restart-verified`。
- UID 25004 打开 UID 25003 vault：1 passed，退出码 0，结果为 `PermissionDenied`，输出 `pc03-other-uid-denied`。
- 总计：7 项实测通过、0 项失败；3 个 helper 在主测试集中 ignored，随后按上述命令分别执行。
- 权限检查：目录 UID 25003 / `0700`；`master.key` UID 25003 / `0600`；vault 文件 UID 25003 / `0600`。
- 清理核验：临时测试目录已不存在；`getent passwd 25003` 和 `getent passwd 25004` 均无账户记录。

该证据覆盖 Linux 文件权限、服务 UID 重启恢复和异 UID拒绝，不等于 Windows 服务身份或 Android 真机验收。

## Windows 根因分析与未覆盖

历史全套 Windows 回执为 6 passed、8 failed、2 ignored，退出码 101。当前可用记录没有逐项失败名称、完整 stdout/stderr 或同一轮 Credential Manager 状态，因此**未能确认 8 个失败项的根因**。现有代码注释记录过 `CredReadW` 1168，以及同时持有 8 个凭据时出现 `ERROR_NOT_ENOUGH_MEMORY (8)`；测试源码包含凭据容量与并发探针。这些是不同错误观察和压力线索，不足以证明历史 8 项失败由单一配额/并发根因造成。

本轮未在当前交互账户重跑全套或凭据压力测试；没有已批准的 pCryoxy Windows 服务/测试账户，因此以下仍未验证：服务身份下创建与重开、服务 SID/ACL、非授权账户拒绝、服务进程重启、Credential Manager 主密钥缺失和旧密文保持。不得将根因写成已查明。解除该阻塞需提供历史全套逐项日志，并在获准隔离的 Windows 服务账户或 runner 上复现。

原实施交接中的定向 Windows 回执（不是本次新执行）：

| 命令 | 既有回执 |
|---|---|
| `cargo test -p secure-store --locked --offline ambiguous_paths_and_unprotected_directories -- --nocapture` | 1 passed，退出码 0 |
| `cargo test -p secure-store --locked --offline actual_windows_large_secret_restart_hmac_and_staging -- --nocapture` | 1 passed，退出码 0 |
| `cargo test -p secure-store --locked --offline independent_candidates_do_not_overwrite_old_versions -- --nocapture` | 1 passed，退出码 0 |
| `cargo test -p secure-store --locked --offline missing_master_key_preserves_old_ciphertext_and_does_not_reprovision -- --nocapture` | 1 passed，退出码 0 |
| `cargo test -p secure-store --locked --offline sensitive_parse_network_jni_and_crash_errors_cannot_reach_projection -- --nocapture` | 1 passed，退出码 0 |

## Android

命令：`adb devices -l`；退出码 0，设备列表为空。无获准真机；Keystore、`noBackupFilesDir`、进程重启、密钥丢失、篡改和权限拒绝均未运行，状态 blocked。源码存在或空设备列表不作为平台通过证据。

## 其他验证与安全边界

- `git diff --check`（提交前及 `HEAD^..HEAD`）：退出码 0。
- `gitleaks dir --redact --no-banner <worktree>\crates\secure-store\src\linux_tests.rs`：退出码 0；扫描约 6.32 KB，无命中。
- 既有格式检查结果见原实施交接；本轮重新执行格式检查时当前 Windows/WSL shell 找不到 `cargo`，未取得新的格式检查回执，不以该失败替代此前结果。
- 测试秘密为虚构字节数据；未使用真实凭据。未新增依赖、未创建持久账户、未安装系统包、未修改全局配置。
- `commit_staged` 仅提交 vault 局部版本，不代表 IR 与 vault 的跨存储原子提交。
- 本卡不覆盖 systemd、TUN、路由、代理互通、Web Token 或生产服务生命周期。

## 挂起任务（当前全量快照）

- pCryoxy：无 suspended 项。PC-03、PC-04 均为 doing / blocked（验收阻塞，不是挂起）。
- prnmgt：S1 `T-059/T-060/T-061`、S2 `P0 二次真机调研`、S3 `v4 / #18` 仍 suspended；本任务不触及、不解挂。
- pRayShell：closed，无挂起项。

## 复审请求

请 WorkBuddy 复核补充 Linux 多 UID 实证，并裁定 PC-03 后续 Windows 服务身份和 Android 真机阻塞。PC-03 保持 doing / blocked；本提交不代表 PC-03 结卡通过。
