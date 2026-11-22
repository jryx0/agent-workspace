# pCryoxy 审核裁定：PC-03 冻结矩阵独立验证（W4 / W5 / A1～A3）

- 审核方：workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-22 10:45
- 被审：copilot 交接《PC03-Windows-交付待审核》《PC03-Android-交付待审核》；项目提交 `f2244cf9eaae5a5e30120bfdad466b0323ba7a7f`；宿主脚手架共享提交 `35e14f8`
- 依据：《真机验证方案 v2》§5 冻结矩阵（人类 08:25 冻结），不追加口径
- 方式：人类 10:06 指示对反复失败项由审核方启动子 agent 独立验证；三个子 agent 各自在 `~/.agent-tools/run/review/` 隔离目录用 `git archive f2244cf` 构建运行，未改项目、worktree、脚手架

## 0. 总裁定：**退回（PC-03 状态 doing）**

W4 被环境阻塞；W5 和 A1～A3 分别查出 runner、宿主和**产品代码**缺陷，执行方修复后可推进，不是外部条件阻塞。所以 PC-03 由 blocked 改回 **doing**，按 §4 修复清单返工。

| 矩阵项 | 执行方 | 审核方独立验证 | 裁定 |
|---|---|---|---|
| W1 / W2 / W3 / W6 | PASS | 未重跑（不在“反复失败”范围） | 暂接受执行方证据；结卡时审核方按冻结矩阵整体复跑一次 |
| W4 | 两轮 error 8 | 三轮 `--exact` 均为 101，`index=6 error=8` | **环境阻塞**：凭据存储配额被 11-20 遗留的 940 条测试凭据占满（§1） |
| W5 | 未运行 | 计划任务已修好并能以 pcx-t2 运行；runner 绑定有误，且不支持 W5 | **退回**：runner 需修复和扩展（§2） |
| A1～A3 | 未运行（无 keystore） | 两轮 instrument 都卡住；补 `start()` 的诊断副本又暴露两个产品缺陷 | **退回**：宿主和产品均需修复（§3） |
| L1 / X1 | — | — | 结卡时执行 |

## 1. W4：error 8 是环境问题（证据目录 `pc03-w4-20261122/`，SHA256SUMS 自身 `05a645c7…d8d6`）

- `cmdkey /list` 共 954 条，其中 940 条是 `pCryoxy/v1/<hex>/master`（`windows.rs:599-607` 的产品主密钥格式）；`%LOCALAPPDATA%\Microsoft\Credentials` 下有 939 个文件，写入时间都是 11-20。
- 独立探针用自建前缀直接调 `CredWriteW` 测：1B 和 64B 的 blob 都在第 6 次写入失败，`CRED_PERSIST_SESSION` 也一样，失败点都在约 522KB；删 1 条后又能写 1 条。说明撞的是每用户 LSA 凭据总量配额，和条数、并发、句柄、`CredFree` 都无关（失败发生在串行阶段 `tests.rs:153-161`）。
- 1168 没测到，要等环境清理后重跑。
- **产品风险（必须处理）**：`windows.rs:473-477` 初始化失败后不回滚，生产代码也没有任何删除路径。每次失败或被丢弃的初始化都会永久占用约 550B，最终会把**整个用户**的凭据配额耗尽，同用户下其他应用的 `CredWriteW` 也会返回 8。

## 2. W5（证据目录 `pc03-w5-20261122/`，SHA256SUMS 自身 `01c5aed9…7d64`）

- **环境已修复**：根因是 `0x80070569`，pcx-t2 缺 `SeBatchLogonRight`。人类 10:33 已授予，并关掉了电池限制。手动触发后 `LastTaskResult=0`，`C:\Users\pcx-t2` 已生成，探针 `.rejected` 文件所有者是 `ZHN-TBXG2IAH\pcx-t2`。Zhn_X 以非提权令牌访问 `C:\Users\pcx-t2` 被拒，配置文件 ACL 干净。
- **runner 缺陷**：`run-xacct.ps1:7` 期望哈希 `e08e6ecb…` 是 c73d59d 构建的；`:250` 仍检查 `bin\c73d59d…\`。f2244cf 的真实二进制必然被拒。
- **runner 缺 W5**：白名单只有 W1～W4 的 12 个用例，没有 write-own / read-foreign 阶段。

## 3. Android（证据目录 `pc03-and-20261122/`，SHA256SUMS 自身 `832de12a…fa46`）

| # | 缺陷 | 位置 | 性质 |
|---|---|---|---|
| D1 | `onCreate` 没调 `start()`，`onStart` 永不执行，`am instrument -w` 一直挂起 | `scaffold/pc03-and-host/HostInstrumentation.kt:15-18` | 宿主 |
| D2 | 结果判定只看 `$LASTEXITCODE`，FAIL 时 `am instrument` 仍退出 0 | 脚手架 README / 构建脚本 | 宿主 |
| D3 | `checkDirectory(parent)` 要求 `noBackupFilesDir` 的组和其他用户位全为 0，但框架固定创建 `0771`，所以必定 `Failure(1)` | `SecretStore.kt:42`、`:92-93` | **产品** |
| D4 | 用 `Os.link` 实现写入不覆盖，在 API 29 上被 SELinux 拒绝（`avc: denied { link } tclass=file`），导致 `Failure(5)` | `SecretStore.kt:180` | **产品** |
| D5 | 宿主没有 A3 所需的 phase，也不输出密文摘要 | 宿主 | 宿主 |

手工把目录改成 0700 后，密钥生成和 seal 在 keymaster 中都成功，说明 Keystore 本身在这台设备上可用。

## 4. 返工清单（copilot，必须全部完成后再提交审核）

**Windows 产品 / 测试（项目仓，PC-03 允许文件）**
1. W4 测试用专用前缀（不能再用产品前缀 `pCryoxy/v1/`），用例开始前按前缀回收上次残留；首次写入就报 error 8 时输出 `ENV_BLOCKED: credential quota`，不再断言容量。
2. 初始化失败要回滚已写入的凭据；补一个由用户确认后执行的孤儿主密钥诊断和回收入口（可以只做 API + 测试，UI 归后续卡）。在 PC-03 文档里写明配额风险。
3. 环境清理完成后，W4 跑 3 轮 `--exact`，并对 1168 给出定性。

**W5 runner（`C:\Users\Public\pcryoxy-xacct\run-xacct.ps1`，泳道 B）**
4. 修正 `:7`、`:250`，绑定 f2244cf 之后的新提交及其二进制哈希；交接里写明构建命令和哈希。
5. 请求 schema 升到 v2，新增两个阶段：`write-own`（pcx-t2 生成自己的存储、DPAPI 哨兵和凭据 target，路径写入 `outbox\<id>\fixture.json`，不含明文）和 `read-foreign`（读取 `foreignPath`，只允许 `C:\Users\Zhn_X\.agent-tools\run\xacct-fixture\<id>\` 前缀；对文件读、DPAPI Unprotect、CredRead 三项逐一记录期望值、实际值和错误码）。manifest 加 `whoami /groups`。方向 B 由 Zhn_X 以非提权令牌执行，证据中附 Mandatory Label。

**Android（脚手架 `35e14f8` 授权范围 + 产品 `SecretStore.kt`）**
6. D1、D2：补 `start()`；判定改为解析 `INSTRUMENTATION_CODE=-1` 加 `result=PASS`；安装默认加 `--no-incremental`，超时 90 秒。
7. D3：只对自建的 namespace 目录严格校验 0700，父目录 `noBackupFilesDir` 只校验属主和不可被其他用户写。
8. D4：改为 pending → fsync → 确认 final 不存在 → `Os.rename` → 同步目录；交接里论证并发下不覆盖的语义，必要时用应用内文件锁。
9. D5：prepare / verify 输出密文 SHA-256；新增 `export-ct` / `probe-old-ct` 两个阶段，A3 预期 `Failure(2)`。
10. 签名直接用 `%USERPROFILE%\.android\debug.keystore`（审核方 10:10 已生成，标准调试库，alias `androiddebugkey`，证书 SHA-256 `e6d1816a…01df4794`），只用于测试宿主，不得入库。

## 5. 需要人类确认

- **W4 环境清理（破坏性操作）**：删除当前用户凭据管理器中 `pCryoxy/v1/*/master`（约 940 条）和 `pCryoxy/pc03-test-native/*`。删前把 `cmdkey /list` 清单和 `%LOCALAPPDATA%\Microsoft\Credentials` 目录整体备份。确认前不做。
- pCryoxy 目前没有正式安装或在用的保险库，这些主密钥都是 11-20 测试遗留，删除不影响任何在用数据。是否属实，请人类最终确认。

## 7. 补充（10:55）：W4 环境清理与清理后复跑

**清理**：人类 10:38 确认。删除前已把 `cmdkey /list` 清单和 Local/Roaming 两个 Credentials 目录备份到 `~/.agent-tools/run/review/pc03-w4-20261122/cred-backup-20261122/`，文件数和字节数都核对一致（Local 949/519818，Roaming 3/1894）。删除范围只有 940 条 `pCryoxy/v1/<hex>/master`，没有 `pc03-test-native/*`，也没有其他 pCryoxy 凭据。分 94 批，每批 10 条、每批核对一次，全部成功。删除后凭据共 14 条，pCryoxy 为 0；Local 目录剩 9 个文件 / 21618 字节。

**复跑**：同一测试程序（SHA-256 `f15d5249…`，`f2244cf` 构建）跑 `--exact --test-threads=1` 共 13 轮：
- 8 轮通过，5 轮失败（第 1、4、5、7、9 轮），失败率约 38%；
- error 8 不再出现，串行写满 16 条全部通过，证实 error 8 是配额问题；
- 失败全部是 `Err(1168)`，位置在 `tests.rs:197`，都是并发阶段中“新建后立即读取”的线程（operation 5 或 7）：另外 4 条凭据被并发删除时，新建的凭据 `create()` 返回成功，紧接着 `read()` 却找不到；
- 每轮结束后 pCryoxy 凭据都是 0，没有新的泄漏。

**定性**：**W4 判 FAIL**。原因是产品在 Windows 凭据管理器上的行为问题，不是环境问题。这是 1168 第一次在干净环境里复现；执行方之前两轮报的是 error 8（环境），不计入“连续两轮失败”。

**追加返工（第 11 项）**：
1. 查清 1168 是暂时读不到，还是写入真的丢了：失败时延迟重读一次，并在 join 之后再读一次，把两次结果都记录下来。用例先打印诊断，再断言。
2. 如果是**写入丢失**（并发 CredDelete 覆盖掉了并发 CredWrite），这是产品缺陷。`windows.rs` 必须对同一用户的凭据写入和删除做进程内串行化，跨进程的情况要给出论证；修好后用 `--exact` 跑满 20 轮且 0 失败。
3. 如果只是**暂时读不到**，产品代码要在写入后校验，并给出有上限的重试策略，同时写进 PC-03 文档；20 轮且 0 失败的要求不变。
4. 测试用的 target 改用专用前缀，不再用产品前缀 `pCryoxy/v1/`（见 §4 第 2 项）。

证据：`pc03-w4-20261122/results.tsv`（post-clean 行）、`out/post-clean/`，清单 SHA-256 `d42d959962f2912dc75134a5198a4e91c00cd72c7d6dd96ca000669adcf02c2d`。
