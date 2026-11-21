# pCryoxy PC-03 专项派工：Windows 测试账户验证 + Android 真机验证（任务卡提示词）

项目: pCryoxy
发起：WorkBuddy@zhn-tbxg2iah-win~zhn-x-w，2026-11-21 22:25（UTC+8）
状态：**派工，未开工**。PC-03 卡状态不变（`doing`／有条件通过，不是 done）。

> 修订指针（2026-11-21 23:15）：卡 B 门禁条款已被 `handoff/2026-11-21-pCryoxy-PC03-AND-V1回执裁定-退回补证与卡面修正v1.1-zhn-tbxg2iah-win.md` 的 M1–M5 + D1–D5 取代——"Keystore 安全级别""设备绝对真实性"不再作为停机条件；停机只认 M2 三条。

## 0. 派工依据

- 人类 2026-11-21 22:18 指令：启动 Android 真机验证与 Windows 测试账号验证；已建 Windows 本地账户 `test1`（口令由人类掌握，本文与任何文件均不记录）。
- 前置裁定：`33a5b6e06c2123717f11995d5ca681a30d5845fb`（Windows 8 项暂缓、Android 后置）、`603f0c2148e47642814b035e5013f1da3bdb988c` + 实施提交 `c73d59d4`（PC-03 有条件通过）。
- 两张卡为 PC-03 的**补证专项**，不新增正式卡号（避免与卡面枚举冲突），不改 PC-03/PC-04/PC-18 状态。

## 1. WorkBuddy 派工前只读实测（2026-11-21 22:19，供实施方直接引用，不需重复探测）

| 项 | 实测结果 | 影响 |
|---|---|---|
| `test1` 账户 | 本地组成员仅 `Users`（标准用户）；账户启用；密码永不过期；上次登录「从未」 | 无 `C:\Users\test1` 配置目录，首次以该身份运行会创建 profile |
| 当前会话权限 | `Zhn_X` 在 Administrators 组，但会话 **IsAdmin=False**（UAC 未提升） | 建计划任务／改 ACL／授予 `SeServiceLogonRight` 均属 `[人类执行]` |
| `adb devices -l` | 退出 0，**设备列表为空** | Android 卡设备门禁不满足，现在开工只能「停并报 blocked」 |
| Android 工程 | 仓库内无 `*.gradle*`／`AndroidManifest.xml`／`gradlew`；仅有 `native/android/SecretStore.kt`、`native/android/tests/SecretStoreDeviceChecks.kt` | 真机验证缺宿主 APK，须先过宿主工程与依赖前置申请 |
| PC-03 现场 | `~/source/pCryoxy.wt/copilot-pc03`，分支 `agent/copilot/pc03`，HEAD `c73d59d`，父 `9b414f2` | 两卡默认**串行**使用该 worktree |
| Windows 全套基线 | 16 个 `#[test]`（2 个 `#[ignore]`）= 14 可执行；历史回执 6 passed／8 failed／2 ignored | 8 项失败即 14 项中未过者，需逐项定性 |

## 2. 卡 A｜PC-03-WIN-V1（可直接复制给实施方）

```text
【任务卡】PC-03-WIN-V1｜Windows 测试账户 test1 平台验证与历史 8 项失败定性

项目：pCryoxy｜性质：PC-03 专项补证（不新增卡号，不改 PC-03 状态，不得写 done）
现场：worktree C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc03；分支 agent/copilot/pc03；HEAD c73d59d；基座 2908e4e
认领：沿用 PC-03 既有认领；开工前在 memory/projects/pCryoxy.md 追加一行【专项派工 PC-03-WIN-V1】

一、目标（只做平台验证，不写产品代码）
1. 在 test1 身份下执行 secure-store 全套 16 项（--test-threads=1 --nocapture），逐项记录命令、退出码、结果；对照历史 6 passed / 8 failed / 2 ignored，对 8 项失败逐项定性：可重现／不可重现／环境相关，并归类根因（Credential Manager 1168 或资源错误／容量限制／ACL-owner／路径安全／子进程／并发）。
2. 复验 PC-03 卡面 Windows 证据：同账户实际写读、进程重开后仍可用、密钥缺失时保留旧密文且不重新 provision、不覆盖 alias、>2560 字节秘密走密文文件、注入解析/网络/JNI/崩溃错误后日志与事件无泄漏。
3. 异账户隔离：test1 与 Zhn_X 的 vault 目录与 Credential target 互不可读、互不可解；越界访问必须失败并返回安全错误，不得只验证"能读自己的"。
4. 文件 ACL 实测：vault 目录与文件的 owner SID、实际 DACL 条目、继承是否关闭。**只记录不改**；如与卡面"当前用户 ACL"要求冲突，先报告再等批准。
5. 服务身份（受门槛，非必达）：仅当 test1 具备 SeServiceLogonRight 时，才可做服务上下文读取；否则记"未覆盖"，并给出人类执行步骤。**不得用计划任务、批处理登录或 Start-Process 冒充服务身份。**

二、执行约束
1. 凭据：test1 口令不得出现在任何文件、commit、脚本明文、命令行参数或持久化环境变量中；建议人类用 DPAPI 写入本机（可复用 config/pcryoxy-test-inputs.dpapi 的做法），执行时内存解密、结束即弃。回执与日志一律写 <redacted>。
2. 非提升：当前会话非管理员。凡需提升的操作（建/删计划任务、改目录 ACL、授予服务登录权、首次创建 test1 profile）一律列成 [人类执行] 可复制命令，禁止 UAC 绕过、禁止借管理员令牌提权。
3. 可读性：test1 默认读不到 C:\Users\Zhn_X\... 下的 worktree。先把已构建测试二进制及运行所需文件复制到中立只读目录（如 C:\ProgramData\pcryoxy-pc03-test\<短哈希>\），vault 落在 test1 自己的 %LOCALAPPDATA%/%TEMP%；复制件不得进仓库，结束后删除。
4. 只用合成 fixture；结束后清理 test1 下的测试 target/vault/临时目录，保留 test1 账户，不触碰任何真实 vault。不改 crates/、native/、Cargo.*、contracts/；发现真实缺陷先出报告，改代码需另行批准。

三、必须交付的证据（缺一项即不构成通过）
1. 环境：OS build、rustc/cargo 版本、test1 的 SID 与组成员、profile 状态、SeServiceLogonRight 是否具备、以 test1 启动的实际机制（含是否需要人类提升）。
2. 全套与定向测试逐项表：命令、退出码、passed/failed/ignored 计数、失败项名称与关键错误码。
3. 8 项失败逐项定性表 + 每项证据行（日志片段脱敏）。
4. ACL 与 Credential Manager 隔离实测：owner/DACL 原文、越界读取的失败回执、target 命名空间隔离。
5. 脱敏核验：gitleaks 对新增/变更文件及回执的扫描结果；日志无 secret 明文。
6. 未覆盖项清单（尤其服务身份）。

四、回执与边界
- handoff：handoff/2026-11-21-pCryoxy-PC03-Windows测试账号验证-zhn-tbxg2iah-win.md（首行 `项目: pCryoxy`，含「挂起任务（当前全量快照）」节）。
- commit（仅共享仓文档）：`handoff: PC-03 Windows测试账户验证 by copilot@zhn-tbxg2iah-win~zhn-x-w`；不提交二进制、日志原文、口令。
- memory/projects/pCryoxy.md 追加带署名结论行。
- 结论三选一：通过 / 失败 / 受外部条件阻塞。不 push 项目分支、不 merge、不部署、不标 done。
```

## 3. 卡 B｜PC-03-AND-V1（可直接复制给实施方）

```text
【任务卡】PC-03-AND-V1｜Android 真机 Keystore 验证

项目：pCryoxy｜性质：PC-03 专项补证（不新增卡号，不改 PC-03 状态，不得写 done）
现场：默认复用 ~/source/pCryoxy.wt/copilot-pc03（与 PC-03-WIN-V1 串行）；若需并行，另建 ~/source/pCryoxy.wt/copilot-pc03-and + 分支 agent/copilot/pc03-android，禁止两卡同目录并发。

一、门禁（先做；任一不满足即停，结论写"受外部条件阻塞"，禁止写通过）
1. adb devices -l 必须恰好 1 台 physical、非 offline/unauthorized、非 emulator。派工时实测为空 → 无设备即停，不得用模拟器顶替，不得把"源码存在"或"空设备列表"写成平台通过。
2. 设备信息：型号、build fingerprint、API level、ABI、Keystore 安全级别（TEE/StrongBox/Software）、是否 root/已解锁（root 须声明并评估是否影响结论）。
3. 工程前置：仓库内无 Gradle 工程与 AndroidManifest，只有 native/android/SecretStore.kt 与 tests/SecretStoreDeviceChecks.kt。先只读盘点 JDK/SDK/NDK/Gradle 已登记版本与本机 Maven/Gradle 缓存是否够构建最小 instrumentation 宿主；**缺构件先申请，不得自行下载、安装或改全局配置**。优先自定义 Instrumentation 承载，避免引入 androidx.test 等新增依赖；确需新增依赖，先出申请单。

二、范围与用例矩阵（逐项给结果，不得合并成"全部通过"）
1. 4097 字节合成秘密 seal/unseal 往返一致；
2. HMAC credential_id 同值跨进程重开稳定；
3. 真实进程终止后 verify 仍能读出旧版本（force-stop + 重启，不是对象重建）；
4. 删除 Keystore alias 后 unseal/seal/persist 全部返回 code 2，旧密文保留；
5. 篡改密文末字节返回 code 3；
6. 已存在 alias 再次 initialize 返回 code 6（不覆盖 alias）；
7. 目录被重命名后 initialize 返回 code 6，held 目录不被改动；
8. 密文位于 noBackupFilesDir（给实际路径），并只读检查备份排除（dumpsys backup / bmgr）；
9. 其他 UID/其他应用不可读该目录（给命令与结果，不以"沙箱理应如此"代替实测）；
10. 全程 logcat 无 secret 明文（给过滤命令与结论）；
11. cleanup 后 alias 与目录均无残留（containsAlias=false、目录不存在）。

三、约束
- 允许新增仅测试用途的最小宿主工程 native/android/testhost/（包名与产品隔离，不改产品 manifest/包名/依赖）；宿主只调用 prepare/verify/cleanup，不得把 secret 字节或 alias 打到日志。
- 不用模拟器、不用 root 提权绕过；不安装系统包或全局依赖；不把 APK/so/大日志提交仓库（>1MB 走 tmp/ 或删除）。
- 不 push 项目分支、不 merge、不部署；服务/IPC/TUN/生命周期属 PC-11，不在本卡。

四、交付
- handoff：handoff/2026-11-21-pCryoxy-PC03-Android真机验证-zhn-tbxg2iah-win.md（首行 `项目: pCryoxy`，含设备信息、构建/安装/运行命令、每项用例命令+退出码+结果、logcat 脱敏片段、未覆盖项、挂起快照节）。
- commit：`handoff: PC-03 Android真机验证 by copilot@zhn-tbxg2iah-win~zhn-x-w`。
- 结论三选一：通过 / 失败 / 受外部条件阻塞；不得写 PC-03 done。
```

## 4. 排队与互斥

- 两卡**默认串行**：先 PC-03-WIN-V1（只跑测试、不改树），再 PC-03-AND-V1（可能新增宿主文件）。并行须另建 worktree 与 `agent/*` 分支。
- 均不得占用 PC-04 现场 `~/source/pCryoxy.wt/copilot-pc04`。

## 5. 人类需先配合的两件事

1. 连接一台已授权 USB 调试的 Android 真机（`adb devices -l` 显示 1 台 physical），并确认允许在设备上安装测试 APK。
2. 为 test1 的验证路径二选一定档：① 人类交互登录 test1 一次（创建 profile，最省事）；② 由人类在提升的 PowerShell 中按卡 A 的 [人类执行] 清单建一次性计划任务。口令仅由人类输入或经 DPAPI 存放，不落明文。

## 挂起任务（当前全量快照）

继承 2026-11-21 最新已审交接；本轮不解挂任何项目。

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无 suspended 项（PC-03/PC-04 为 doing/blocked，不是 suspended）；pRayShell 已 closed。

## 6. 审核口径（给 WorkBuddy 后续复审用）

- 两卡只补平台证据，不改变 PC-03「有条件通过／继续实施」的性质；即使 Windows 与 Android 全绿，PC-03 仍不因本专项自动 done（PC-11 生命周期、PC-10 服务身份等未覆盖项需另卡）。
- 反伪证口径：设备为空、服务身份未达、ACL 未实测、日志无脱敏证据，任一项出现即判"证据不足"，不得判通过。
- 若 Windows 8 项失败定位到产品缺陷，另开修复卡走代码审核，不在本专项内改代码。
