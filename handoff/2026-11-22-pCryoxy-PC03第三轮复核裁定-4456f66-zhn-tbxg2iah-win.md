# pCryoxy PC-03 第三轮复核裁定（4456f66）

- 项目：pCryoxy
- 任务：PC-03（copilot，**保持 doing**）
- 被审：项目提交 `4456f66d9536477ee6e762dab72e7494428e6adb`（分支 `agent/copilot/pc03`）；共享仓宿主与交付记录 `4b8a4d0`
- 依据：《真机验证方案 v2》§5 冻结矩阵 v1.1；《PC-03 返工复核裁定（dc3d34d）》§2～§4；《H1～H3 人类裁定落实》
- 审核：workbuddy@zhn-tbxg2iah-win~zhn-x-w，三个审核方子 agent 在隔离目录用 `git archive 4456f66` 独立构建、独立运行

## 1. 冻结矩阵逐项判定

| ID | 结果 | 关键数字 | 证据 |
|---|---|---|---|
| W1 | PASS | 3/3 | `~/.agent-tools/run/review/pc03-win-r3-20261122/out/W1/` |
| W2 | PASS | 篡改/版本替换 3/3；密钥缺失 3/3 | `out/W2a/`、`out/W2b/` |
| W3 | PASS | junction、未保护目录、祖先改名各 3/3 | `out/W3a..c/` |
| W4 | PASS | `--exact` 20/20，1168 与 ENV_BLOCKED 均 0 次，每轮后凭据 0 条；并发 provisioning 3/3 | `out/W4/`、`out/W4p/` |
| **W5** | **未执行** | 请求 20:20:59 放入，16 分钟内计划任务未处理；且 runner 设计只能单向（见 §3） | `~/.agent-tools/run/review/pc03-w5-r3-20261122/` |
| W6 | PASS | 3/3 | `out/W6/` |
| A1 | PASS（双机） | D1、D2 prepare/export 密文一致 | `~/.agent-tools/run/review/pc03-and-r3-20261122/<序列号>/` |
| A2 | PASS（双机） | adb reboot 后自动解锁，verify 通过，密文 SHA-256 不变 | 同上 |
| A3 | PASS（双机） | 卸载后包不存在、重装后 failureCode=2。D2 首次因审核脚本查包未带 `--user 0`（隐私空间次用户触发 SecurityException）判 FAIL，修正后整项重跑 PASS，两次均入证据 | 同上，`run-a3.sh`、`*-rerun.txt` |
| L1 | PASS | 同 UID 与跨 UID（WSL root 监督、`setpriv` 降到无账户 UID 25003/25004）：目录 0700、文件 0600、属主正确；异账户打开返回 PermissionDenied，系统层读/列/建均被拒 | `~/.agent-tools/run/review/pc03-l1-20261122/` |
| X1 | PASS | gitleaks（--redact）扫描 r3、w5-r3、and-r3、l1 四个证据包，均 0 命中 | 各证据目录 `x1-gitleaks.json` |

设备：D1 `9WDNW21527000189` 荣耀 TEL-AN10 / API 29；D2 `AP4XUT4711002468` 荣耀 MAG-AN00 / API 36。

## 2. 上轮必修 7 项

| # | 项 | 结果 |
|---|---|---|
| 1 | clippy | PASS：fmt 与 clippy（三种写法）均退出 0，0 warning |
| 2 | 全量测试稳定与残留 | PASS：10/10，每轮 17 passed / 0 failed / 2 ignored；0xc0000409 0 次；每轮后 pCryoxy 凭据 0、vault 目录 0；析构在 panicking 时不再断言（`tests.rs:126-141`、`:186-200`、`:239-251`） |
| 3 | 跨进程用例残留 | PASS：3/3，前后 `pCryoxy/pc03-test/` 0 条；独占锁 + 前缀回收断言（`tests.rs:430`） |
| 4 | 文档入仓 | PASS：`docs/secure-store.md` 写明配额、回滚、孤儿回收需确认、读回重试 5×25 ms、Windows 只保证进程内互斥（PC-10）、Android 写入方持锁与 rename 覆盖（PC-11） |
| 5 | W5 runner schema v2 | **FAIL**：脚本安全但功能不满足双向验证，见 §3 |
| 6 | 宿主 sendStatus / README | PASS：STATUS 与 RESULT 两行均输出 result；README 写明组件名、exit 0 陷阱、重装后 cleanup 不适用 |
| 7 | H1 pending 回收 | PASS：双机 recover-pending 通过；回收与失败清理均在持锁内（`SecretStore.kt:173-193`），rename 成功后才置 `pendingCreated=false`，不会误删已提交版本 |

APK：审核方自建 `95829f81…8aadce` 与执行方 `9cc3c1c8…ef` 的 `classes.dex` 逐字节一致（`287b7222…40e0`），整包差异仅为 ZIP 时间戳。

## 3. W5 runner 返工（结卡前必修，执行方）

审读文件 SHA-256 `4e3e6e30…fea509`（存档 `pc03-w5-r3-20261122/run-xacct.reviewed.ps1`）。安全面：无联网、提权、改 ACL/注册表、外传；删除仅限本请求产物；有 reparse 检查与哈希双校验；不输出明文。功能面问题：

1. **高｜`:499`、`:570`**：write-own 只允许 pcx-t2 批处理登录，"Zhn_X 写、pcx-t2 读"方向无法执行。要求：Zhn_X 交互登录（非提权）下也能 write-own。
2. **高｜`:10`、`:60-70`**：read-foreign 路径写死在 `C:\Users\Zhn_X\.agent-tools\…`，pcx-t2 无权访问（§3.1 也禁止给它加 ACE），该方向必然失败。要求：交换目录放在 `C:\Users\Public\pcryoxy-xacct\` 下按账户分开，写入方可写、对方只读。
3. **中｜`:350`、`:379-399`**：read-foreign 读的是内嵌 base64 的 fixture.json，没有读对方账户的原始 `protected.bin`；write-own/read-foreign 不运行测试二进制，验证的是 PowerShell 层的 DPAPI/CredRead，不是 secure-store。要求：至少由 secure-store 测试二进制（或明确声明的等价调用）产生对方数据，并读取对方原始文件路径；"文件可读、DPAPI 解不开、CredRead=1168"三项都对真实对象判定。
4. **中｜`:7`、`:9`、`:506-508`**：二进制哈希与路径写死在 runner，审核方不能换自建二进制。要求：由请求文件指定提交、相对路径和 SHA-256，runner 只校验。
5. **中**：缺 cleanup 阶段，pcx-t2 侧凭据 `pCryoxy/pc03-xacct/<id>` 和 `%LOCALAPPDATA%\pcryoxy-xacct\<id>` 只能人类登录清理。要求：加 cleanup 阶段，按 fixture 精确路径清理并回报。
6. **低｜`:195`、`:206`**：预检探测凭据删除失败时不再回收。要求：失败后重试一次或在 outbox 报残留清单。

## 4. 新发现：待人类裁定

| # | 问题 | 审核方建议 |
|---|---|---|
| H4 | **Android fd 泄漏（审读得出，未实测）**：`SecretStore.kt:182`（pending 写入，本轮新改）与 `:242`（持久化锁文件，上轮已有）用 `FileOutputStream(fd).use{}` 包住 `Os.open` 得到的 fd。Android 上以 FileDescriptor 构造的 FileOutputStream 不拥有该 fd，close 不会关闭它，两处也都没有 `Os.close(fd)`；估计每次持久化泄漏 2 个 fd。旧版 pending 写入在 finally 中显式关闭，本轮属回退 | **结卡前修**：两处在 `use` 外加 `finally { Os.close(fd) }`（或回到 `Os.write`+`Os.fsync`+`Os.close`）；加宿主用例：同一进程连续持久化 N 次，前后 `/proc/self/fd` 数量不变。因改动 SecretStore.kt，审核方双机重跑 A1～A3 与新用例 |

其余低风险项由执行方顺带处理或在文档登记，不作为结卡条件：
- 回收前检查 fd、之后按路径删除，中间有时间窗（`:206-208`），同 UID 恶意代码不在防护范围内；
- finally 中清理失败会覆盖原失败码（`:193`）；
- 权限不对的陈旧 pending、写入失败清理路径没有用例覆盖；
- 审核方自建 Windows 测试二进制（`b4ada858…`）与执行方（`1c17b51a…`）不一致，推测为构建路径写入调试信息，未做比对。

## 5. 环境与人类事项

- **20 条 `pCryoxy/pc03-test/*/master` 残留凭据**：人类 19:58 确认删除时已不存在，执行方第 2、3 项的前缀回收在其 10 轮全量测试中已清除；本轮全程 pCryoxy 凭据始终 0 条，审核方未删除任何凭据。
- **计划任务**：`schtasks.exe` 被本机安全中心程序黑名单拦截，审核方按约束未绕行。请人类在任务计划程序中查看 `pcryoxy-xacct` 的状态和上次运行结果（是否被停用、pcx-t2 密码是否变更）。
- inbox 里旧 v1 请求 `dcb7a39b….request.json` 可由人类删除（outbox 已有其 `.rejected`）。
- L1 跨 UID 使用了 `wsl -u root`（免密 root），做法与执行方一致，没有留下持久改动。

## 6. 结卡路径

执行方完成 §3 第 1～6 项（以及人类若定 H4 为必修则一并），交新提交。审核方随后：W5 双向跑一次；若改了 SecretStore.kt，则双机重跑 A1～A3、recover-pending 与 fd 用例；X1 扫新证据。已通过的 W1～W4、W6、L1 不再重跑，除非 Rust 产品代码有改动。全部通过后判 PC-03 done 并合并进 main。

## 7. 证据哈希（各目录 SHA256SUMS.txt 自身）

- `pc03-win-r3-20261122`：`7c4278a9b353098b740b8f1171b731a48f8880c98d43fdbfccd016d11093049d`
- `pc03-w5-r3-20261122`：`e3efe7485d5afecdb7ae931b61a8ba8a2ae02848f1d3d9d0d8d951fa51a75d87`
- `pc03-and-r3-20261122`：`3e705da7f9d59be871565c5a541d814bb41b4be11e295f02237db6b9b0cdb917`
- `pc03-l1-20261122`：`063268b34a0d9f3ee7100cbfa0f900ee9d2b6f67e4b50f54977d455ac5516e38`
- X1 报告 `x1-gitleaks.json` 在 SHA256SUMS 生成之后写入，未纳入上述清单。

## 8. 人类裁定（2026-11-22 20:48）

H4 影响小，**转 PC-11 修复**，不作为 PC-03 结卡条件；已记入任务卡 v1.2 §10。PC-03 结卡只剩 §3 第 1～6 项（W5 runner）返工与审核方 W5 双向执行；SecretStore.kt 若无改动，A1～A3 不重跑。

## 9. 补记：W5 请求未被处理的原因（2026-11-22 20:55）

人类在管理员窗口查得：`pcryoxy-xacct` 状态 Ready、运行账户 pcx-t2（Password）、触发器每 2 分钟有效；上次运行 19:58:52 结果 0，之后错过 27 次（约 54 分钟）。设置 `DisallowStartIfOnBatteries=True`、`StopIfGoingOnBatteries=True`，审核方查得当时 `Win32_Battery.BatteryStatus=1`（电池供电，47%）。结论：19:58 后笔记本改用电池，任务被条件拦下，与 runner 无关。20:54 人类已接回交流电源（BatteryStatus=2）。建议在 W5 复跑前把两项电池条件改为 False（需重新录入 pcx-t2 密码），避免长时间测试中途被打断。runner 的功能缺陷（§3）仍须返工。

## 10. 范围确认（答复 copilot 2026-11-22 20:58 的两项提问，审核方 21:05）

人类 20:58 承诺 W5 测试完成前不拔电源。

### 10.1 允许新增 W5 测试入口（§3 第 3 项的落实方式）

- **允许**在 `crates/secure-store/src/tests.rs` 新增两个 `#[ignore]` 测试入口（名称自定，如 `w5_write_own`、`w5_read_foreign`），参数经环境变量传入；必须调用 secure-store 的公开 API（`Windows::initialize`、写入、打开、读取），不得在测试里另写一套 DPAPI/CredRead 来代替产品路径（第 4 项的直调对照除外）。
- `windows.rs` 只允许新增 `#[cfg(test)]` 内容（例如 W5 专用凭据前缀 `pCryoxy/pc03-xacct/`）；`#[cfg(not(test))]` 产品代码 diff 必须为 0。不得使用 `pCryoxy/v1/`。不改 Android 文件。
- **写入方**（write-own）：在本账户 `%LOCALAPPDATA%\pcryoxy-xacct\<id>\vault` 用 secure-store 建库并写入随机值（只输出哈希，不输出明文）；再把库内全部文件逐字节复制到交换目录（见 10.2）本账户子目录，附 SHA-256 清单和原始路径。
- **读取方**（read-foreign）对同一 `<id>` 逐项记录 expected / actual / errorCode：
  1. 直接读对方 profile 里的原始库路径 → 预期**拒绝访问**；
  2. 读交换目录里的副本、核对 SHA-256 → 预期**成功**；
  3. 把副本复制到本账户临时目录，用 secure-store 打开并读取 → 预期**失败**（返回具体 StoreError，不得返回任何明文）；
  4. 对副本中的 DPAPI 密文直接调用 CryptUnprotectData → 预期**失败**；对写入方的凭据目标名 CredRead → 预期 **1168**。
  四项全部符合预期，该方向才算 PASS；双向都 PASS，W5 才 PASS。
- runner 只负责调度：按请求文件里的提交、相对路径、SHA-256 校验二进制后，用 `--ignored --exact` 调用上述入口；脚本里现有的 DPAPI/CredRead 直调可保留为预检，但不作为 W5 判定依据。
- cleanup 阶段：用同一测试二进制按 fixture 精确路径删除本账户的库目录、交换目录子目录、`pCryoxy/pc03-xacct/<id>` 凭据，回报删除清单与残留数。
- 审核影响：tests.rs 有改动，审核方将重跑全量测试 10 次与跨进程用例 3 次；若 `windows.rs` 的非测试部分 diff 为 0，W1～W4、W6 不重跑。

### 10.2 交换目录 ACL（由人类在管理员窗口执行，copilot 与 runner 不得改 ACL）

现状：根目录 Zhn_X 修改、pcx-t2 只读执行；outbox 两个账户都可修改；所有者均为 Administrators。目标：

| 目录 | Zhn_X | pcx-t2 |
|---|---|---|
| `inbox\` | 修改 | 只读执行（不变） |
| `outbox\` | **只读执行**（改） | 修改 |
| `x\zhn_x\`（新建） | 修改 | 只读执行 |
| `x\pcx-t2\`（新建） | 只读执行 | 修改 |

三个目录都断开继承，保留 SYSTEM 与 Administrators 完全控制，所有者保持 Administrators（Zhn_X 以非提权令牌运行时，Administrators 组只作拒绝使用，不构成写权限）。runner 预检须核对上述 ACL，对方账户在本账户子目录有写权限时写 `ENV_BLOCKED` 并停止。

### 10.3 ACL 落实核对（审核方 21:07）

人类 21:03～21:06 在管理员窗口执行完毕。另把中间层 `x\` 断开继承并改为两账户均只读执行（原继承根目录的 Zhn_X 修改，可被改名后伪造 `x\pcx-t2\`）。现状：`outbox\` Zhn_X RX／pcx-t2 M；`x\` 双方 RX；`x\zhn_x\` Zhn_X M／pcx-t2 RX；`x\pcx-t2\` pcx-t2 M／Zhn_X RX；四者均断开继承，所有者 Administrators，保留 SYSTEM、Administrators F。审核方以 Zhn_X 非提权令牌（Medium）实测：在 `x\`、`x\pcx-t2\`、`outbox\` 新建文件均被拒，改名 `x\` 被拒，在 `x\zhn_x\` 新建与删除成功（探测文件已删）。pcx-t2 一侧待 W5 runner 预检核对。runner 预检须同时核对 `x\` 本身：任一账户对 `x\` 有写入／删除权限即写 `ENV_BLOCKED`。
