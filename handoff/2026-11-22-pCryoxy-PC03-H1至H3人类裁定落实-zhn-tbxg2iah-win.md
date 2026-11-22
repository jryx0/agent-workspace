# pCryoxy PC-03 H1～H3 人类裁定落实

- 项目：pCryoxy
- 任务：PC-03（doing，copilot）；连带 PC-10、PC-11 范围追加
- 出处：《PC-03 返工复核裁定（dc3d34d）》§4；人类 2026-11-22 15:23 裁定"H1～H3 按审核方建议做"
- 登记：workbuddy@zhn-tbxg2iah-win~zhn-x-w

## 1. 裁定结果

| # | 问题 | 裁定 | 落到哪里 |
|---|---|---|---|
| H1 | Android 残留 pending 让该版本永久返回 Failure(6)（`SecretStore.kt:177`、`:180-188`、`:220`） | **PC-03 结卡前必修**，作为返工裁定 §2/§3 之后的第 7 项 | PC-03 |
| H2 | Android rename 会覆盖目标（`SecretStore.kt:196`），"不覆盖"只靠锁加先查后改 | **转 PC-11**；PC-03 只在文档写明"所有写入方必须持锁" | PC-11（实现），PC-03（文档） |
| H3 | Windows 跨进程并发 CredWrite/CredDelete 不保证一致 | **转 PC-10**，由 PC-10 保证单一服务进程（单实例）写凭据；PC-03 文档写明"只保证进程内互斥" | PC-10（实现），PC-03（文档） |

## 2. PC-03 第 7 项（H1）验收要求

1. 写入、fsync、读回校验任一步失败时，本次创建的 pending 必须删除（finally 或等价路径）。
2. 进程崩溃留下的陈旧 pending，须在持锁状态下回收后再创建，不能直接按"已存在"返回 Failure(6)。回收只针对 pending，不得动已提交的版本文件。
3. 新增宿主用例：人为制造残留 pending（写入后不改名即退出，或直接放一个 pending 文件），重新写同一版本应成功；输出带 `sendStatus` 的 PASS/FAIL。
4. 因为改了 `SecretStore.kt`，审核方会在 D1（TEL-AN10，API 29）和 D2（MAG-AN00，API 36）双机重跑 A1～A3 与新用例。

## 3. PC-03 文档追加（并入返工裁定 §2 第 4 项）

- Android：所有写入方必须持锁；rename 本身会覆盖目标，不覆盖靠锁保证，`RENAME_NOREPLACE` 的评估在 PC-11。
- Windows：只保证进程内互斥；跨进程一致性由 PC-10 的单实例服务保证。

## 4. 下游卡范围追加（实施任务卡 v1.2 已同步追记 §9）

- **PC-10**：增"凭据写入单实例"——产品只允许一个服务进程写 Windows 凭据，须有单实例保护和对应测试（第二实例启动被拒或只读）；并接手"孤儿诊断依赖调用方传全 vault 根目录"，用 vault 根目录注册表解决。
- **PC-11**：增"Android 不覆盖提交"——评估 `renameat2(RENAME_NOREPLACE)` 在目标 API 范围（29～36）与 SELinux 下的可用性；可用则改用，不可用则在文档写明依赖锁并补并发测试。`Os.link`+`remove` 已证实被 SELinux 拒绝，不再考虑。

## 5. 给 copilot 的补充提示词（可直接转发）

```
pCryoxy PC-03 返工补充（人类 2026-11-22 15:23 裁定）：
读 ~/.agent-shared/handoff/2026-11-22-pCryoxy-PC03-H1至H3人类裁定落实-zhn-tbxg2iah-win.md。
1. H1 定为结卡前必修（第 7 项）：SecretStore.kt 写入失败或校验失败时删除本次 pending；陈旧 pending 在持锁状态下回收后再创建；新增残留 pending 宿主用例并输出 sendStatus。
2. H2、H3 不在 PC-03 实现，只在 PC-03 文档写明：Android 所有写入方必须持锁；Windows 只保证进程内互斥。
3. 与返工裁定 §2 的 1～4、§3 的 5～6 一起交一个新提交，交付记录逐项对照 7 项写明证据。改了 SecretStore.kt，审核方会双机重跑 A1～A3。
```
