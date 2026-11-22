# pCryoxy PC-03 返工复核裁定（dc3d34d）

- 项目：pCryoxy｜卡号：PC-03｜审核方：workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-22 15:30 UTC+8
- 被审：项目提交 `dc3d34d825dca715e29e174297f449c83216273a`（`agent/copilot/pc03`）、宿主脚手架为共享仓 `1e88815`
- 依据：冻结矩阵 v1.1（《真机验证方案 v2》§5；人类 08:25 冻结，14:50 将 A1～A3 改为双机）、上一轮裁定 `e625522` §4 和 `b449c00` §7
- 执行方交付：`handoff/2026-11-22-pCryoxy-PC03-Windows返工复验交付-copilot-…`、`…-PC03-Android返工复验交付-copilot-…`
- **结论：W1～W4、W6、A1～A3（双机）PASS；W5 未执行；还有 4 项结卡前必须修的问题。PC-03 保持 doing，不结卡。**

## 1. 冻结矩阵逐项判定（审核方子 agent 在隔离目录用 dc3d34d 独立构建、独立运行）

| ID | 判定 | 证据 |
|---|---|---|
| W1 | PASS | 大秘密值、真实进程重启、HMAC、staging 用例 3/3 |
| W2 | PASS | 篡改/版本替换 3/3；密钥缺失不重建、旧密文保留 3/3 |
| W3 | PASS | junction 祖先、路径歧义/目录未保护、守护期间祖先改名，各 3/3 |
| W4 | PASS | `--exact` **20/20**，ENV_BLOCKED 0 次、1168 0 次，每轮结束 pCryoxy 凭据为 0；并发 provisioning 3/3。1168 的定性：执行方诊断显示"暂时读不到"和"写入没留住"两类都存在，已由进程内串行化加读回重试处理 |
| W5 | 未执行 | 计划任务已于 10:33 修好（pcx-t2 已授批处理登录权限，LastTaskResult=0）；卡在 runner 上，见 §3-5 |
| W6 | PASS | Token 轮换 3/3 |
| A1/A2/A3 · D1 TEL-AN10 API 29 | PASS | 密文 4126 字节，三处摘要一致；重启后摘要相同；重装后 probe-old-ct 返回 failureCode=2 |
| A1/A2/A3 · D2 MAG-AN00 API 36 | PASS | 同上 |
| L1、X1 | 待结卡时执行 | 按矩阵，结卡时由审核方复跑一次 |

补充说明：
- **Android 的通过判据**：宿主从不输出 `INSTRUMENTATION_STATUS: result=PASS`，所以审核方以 exit 0、`INSTRUMENTATION_CODE: -1`、`INSTRUMENTATION_RESULT: result=PASS` 三者同时成立作为判据。矩阵只规定测什么，不规定看哪一行输出，因此本判据有效。
- **A3 取样**：`verify` 会删除 AES 密钥（`SecretStoreDeviceChecks.kt:103`），因此 A3 另取一个未跑过 verify 的新 namespace 测试；A2 的旧密文也补测了一次，同样 failureCode=2。
- **APK**：验收用审核方自建的 APK（`c7ec5cea…ee23`）。它与执行方 APK（`c7c06153…9b54`，与申报一致）的 `classes.dex` 逐字节相同，只有 ZIP 时间戳不同。签名证书是 `e6d1816a…4794`，debug.keystore 前后哈希相同，未被替换。
- **越界**：无。改动的 4 个文件都在卡面范围内。

## 2. 结卡前必须修复（冻结矩阵之外的全卡通用门禁，不算追加验收口径）

1. **clippy 门禁不过**：`windows.rs:169` 的 `|error|` 只在 `#[cfg(test)]` 下使用，产品构建报未使用变量，`cargo clippy -p secure-store -- -D warnings` 失败。
2. **全量测试不稳定，且异常中止后留下残留**：`cargo test -p secure-store` 跑了 6 次，1 次失败（孤儿回收用例和祖先改名用例 FAILED，随后进程以 0xc0000409 中止），当次留下 19 条 `pCryoxy/pc03-test/*/master` 凭据和 19 个 vault 目录。疑点是 `NativeFixture` 等析构里的 `assert!`（`tests.rs:189`）没有先判断 `std::thread::panicking()`，导致二次 panic 后 abort。要求：析构在 panic 状态下不再断言；全量测试连跑 10 次 0 失败，且 pCryoxy 凭据 0 残留。
3. **跨进程用例实测留下残留**（`tests.rs:381-393`）：跑完一轮后多出 1 条 `pCryoxy/pc03-test/…/master`，而程序报告清理成功。要求：跨进程用例与其他凭据用例互斥运行；运行前后按 `pCryoxy/pc03-test/` 前缀做残留断言和回收，与 W4 的专用前缀回收方式一致。产品层面"只保证进程内安全"的边界，审核方接受，由 §4 处理。
4. **文档没有落进仓库**（§4-2、§7-11.3 只算部分落实）：配额风险、初始化回滚、孤儿回收必须由用户确认、读回重试（5×25 ms）、以及只保证进程内互斥的边界，目前只写在交接和代码注释里。要求写入卡面允许的 PC-03 文档位置。若卡面没有可放文档的文件，在交接里提出申请。

## 3. 测试宿主与 W5（结卡前必须）

5. **W5 runner**：`run-xacct.ps1` 第 7 行、第 250 行改为绑定 dc3d34d（或最终提交）的二进制哈希和目录，并实现 schema v2 的 `write-own` / `read-foreign`。方案沿用上一轮裁定 §4。W5 的环境阻塞已解除，不得再以"任务访问/注册阻塞"为由标 blocked。
6. **宿主输出**：`HostInstrumentation.kt:62-63` 在 `finish()` 前补一条 `sendStatus`（输出 result=PASS/FAIL）；README 第 56 行补上组件名 `app.pcryoxy.andhost/.HostInstrumentation`；写明重装后 cleanup 不适用；说明 `am instrument` 失败时也返回 exit 0，判定不能只看退出码。

## 4. 交人类裁定：两项 Android 稳健性问题和一项跨进程问题（不在冻结矩阵内）

| # | 问题 | 审核方建议 |
|---|---|---|
| H1 | **残留 pending 会让该版本永久返回 Failure(6)**：pending 用 O_EXCL 创建（`SecretStore.kt:177`），写入、fsync、校验失败或进程崩溃后不会删除（`:180-188`、`:220`），之后该版本一直误报"已存在" | **结卡前修**：改动小，而且直接影响数据可用性。在 finally 中清理 pending，或在锁内回收陈旧 pending |
| H2 | **rename 会覆盖目标**（`:196`），"不覆盖"只靠锁加先查后改 | 转给 PC-11（Android 生产生命周期）：改用 `Os.link`+`remove` 不可行（SELinux 已证实拒绝 link），可评估 `renameat2(RENAME_NOREPLACE)` 的可用性。PC-03 先在文档里写明"所有写入方必须持锁" |
| H3 | **跨进程并发 CredWrite/CredDelete 不保证一致**（Windows，同用户的其他进程也会参与竞争） | 转给 PC-10（Windows 运行时）：产品只有单一服务进程写凭据，由 PC-10 保证单实例；PC-03 文档写明这一边界 |

其余低风险项（毒锁可改用 `into_inner`、回滚未删 guard 目录、回滚用例没有注入真实故障、诊断分类 `recovered` 条件过宽、孤儿诊断依赖调用方传全 vault 根目录）由执行方在本轮返工中**顺带处理或在文档登记**，不作为结卡条件。其中"孤儿诊断依赖调用方传全根目录"（中）建议在 PC-10 引入 vault 根目录注册表时一并解决。

## 5. 环境

- 本轮复核留下 20 条 `pCryoxy/pc03-test/<hex>/master` 测试凭据（全量测试中止 19 条、跨进程用例 1 条）。这个前缀不在子 agent 获准删除的范围内，**清理待人类确认**。
- 证据：
  - Windows：`~/.agent-tools/run/review/pc03-win-r2-20261122/`，`SHA256SUMS.txt` 自身哈希 `0d2734cccaebafa589f6343803bbd609235550897a8886d4a8e35e5baee87e12`；测试二进制 `f30f6199…fa1dfa5b`。
  - Android：`~/.agent-tools/run/review/pc03-and-r2-20261122/`，`SHA256SUMS.txt` 自身哈希 `74d76fccd797a85636e0c648f7aea000ed9d7ccd28774e456739ad4cd17a5584`。

## 6. 结卡路径

执行方完成 §2 的 1～4、§3 的 5～6，以及人类定为必修的 §4 各项，然后交新提交。审核方随后执行：W5 跨账户双向测试；对返工涉及的 W 项做回归；A1～A3 只在 SecretStore.kt 有改动时双机重跑；L1 复跑一次；X1 用 gitleaks 扫描证据包。全部通过后判 PC-03 done 并合并进 main。
