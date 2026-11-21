# PC-03-AND-HOST-V1 授权单：Android 测试宿主脚手架（工程前置）

项目: pCryoxy

- 性质：**工程前置授权项，不是验收卡**。产出"可复跑的测试载体"，不产出 PC-03 任何验收结论。
- 授权人：WorkBuddy@zhn-tbxg2iah-win~zhn-x-w，2026-11-21 23:22（UTC+8）
- 人类裁定（2026-11-21 23:20）：B1 落法 = **B 共享仓脚手架**；B2 实施方 = **copilot**；B3 与卡 A 并行、不冲突；B4 验收只验宿主管用（A1–A4），11 项归卡 B；B5 保留 C 方案作为后续正式项，等 PC-11/CI 阶段或人类明确要 CI 化时立卡。
- 为什么单独立项：卡 B（PC-03-AND-V1）两轮以"门禁"退出，实质缺口是"没有可运行的测试载体"。把造载体从跑验证里切出来，各自可验收、可追责，避免"验证方自造载体再自证"。

## 一、授权项定义

```text
【授权项】PC-03-AND-HOST-V1｜Android 测试宿主脚手架（工程前置，非验收卡）

性质：为 PC-03-AND-V1 提供可复跑的测试载体。改的是脚手架，不是产品代码；本项不产出 PC-03 验收结论。
认领：copilot@zhn-tbxg2iah-win~zhn-x-w；开工前在 memory/projects/pCryoxy.md 追加【授权项 PC-03-AND-HOST-V1】
现场：不改产品仓、不建分支、不建 worktree。脚手架新增于
  ~/.agent-shared/scaffold/pc03-and-host/
编译输入（只读）：~/source/pCryoxy.wt/copilot-pc03/native/android/SecretStore.kt
                  ~/source/pCryoxy.wt/copilot-pc03/native/android/tests/SecretStoreDeviceChecks.kt
产物（不入库）：~/.agent-shared/tmp/workbuddy/pc03-and-host/{out,dex,apk}

一、只准新增以下 4 个文件（改产品任何文件即违约；发现产品缺陷只记录不改，另开修复卡）
1. scaffold/pc03-and-host/AndroidManifest.xml      包名 app.pcryoxy.andhost，minSdk 29 / targetSdk 36
2. scaffold/pc03-and-host/HostInstrumentation.kt   仅调 prepare/verify/cleanup；
   Proof 的 namespace/version 由宿主自行落盘以支持 force-stop 跨进程；不得打印 secret 或 alias
3. scaffold/pc03-and-host/build.sh + build.cmd     封装下列两条已验证命令
4. scaffold/pc03-and-host/README.md                命令、参数、已知坑

二、构建命令（已实测可用；禁止改用 Gradle/AGP/NDK，禁止下载任何组件）
J=C:/Users/Zhn_X/.agent-tools/runtimes/jdk-21/bin/java.exe
GL=C:/Users/Zhn_X/.agent-tools/runtimes/gradle-9.6.1/lib
SL=~/.gradle/caches/modules-2/files-2.1/org.jetbrains.kotlin/kotlin-stdlib/2.3.21/*/kotlin-stdlib-2.3.21.jar
AJ=C:/Users/Zhn_X/.agent-tools/android-sdk/platforms/android-36/android.jar
BT=C:/Users/Zhn_X/.agent-tools/android-sdk/build-tools/36.0.0

# 编译：宿主与产品源码必须在同一次调用（SecretStoreDeviceChecks.Proof 构造器是 internal）
"$J" -cp "$GL/*" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler -classpath "$AJ;$SL" -jvm-target 11 \
  -d out <宿主 .kt> <SecretStore.kt> <SecretStoreDeviceChecks.kt>
# dex：必须把 stdlib 一起 dex（Android 不含 Kotlin stdlib），否则运行期 NoClassDefFoundError
"$J" -cp "$BT/lib/d8.jar" com.android.tools.r8.D8 --min-api 29 --lib "$AJ" --output dex <out 下全部 class> "$SL"
# 打包/签名/安装：aapt2 link → zipalign -f 4 → apksigner sign → pm install -r -t -g
# 运行：am instrument -w [-e phase prepare|verify|cleanup] app.pcryoxy.andhost/.HostInstrumentation

执行前置：设备必须已解锁亮屏（锁屏下 pm install 会无输出静默挂住、无失败码，已实测）；
开工前查 dumpsys power | grep mWakefulness 与 dumpsys window | grep isStatusBarKeyguard，不满足请人类解锁。
d8 会刷大量 kotlin metadata 版本告警（d8 8.10 不认 Kotlin 2.3 元数据），无害；嫌吵可换 kotlin-stdlib 2.2.10（缓存已有）。

三、验收（只验宿主管用，任一不满足即驳回；不评 11 项业务用例）
A1 编译退出 0，产物含 SecretStore、SecretStore$Failure、SecretStoreDeviceChecks、
   SecretStoreDeviceChecks$Proof 四个 class（证明同编译单元可取 internal）
A2 APK 安装返回 Success（给命令与原始输出）
A3 prepare → am force-stop（pidof 为空）→ verify → cleanup 全通；cleanup 后 containsAlias=false 且目录不存在
A4 源码与运行输出不含 secret 字节、不含 alias 明文（给 logcat 过滤命令与结论）

四、交付
- 文件提交到共享仓，commit：scaffold: PC-03 Android测试宿主脚手架 by copilot@zhn-tbxg2iah-win~zhn-x-w
- handoff/2026-11-21-pCryoxy-PC03-AND-HOST脚手架-copilot-zhn-tbxg2iah-win.md：
  含 4 个文件清单、构建/安装/运行命令与退出码、A1–A4 逐条证据、已知坑、挂起快照节
- memory/projects/pCryoxy.md 追加带署名结论行
- 结论三选一：通过 / 失败 / 受外部条件阻塞
  （仅当 A1–A4 中某项在已按上列命令执行后仍失败，且贴出首次失败的确切命令、退出码与错误行）

五、边界
- 不 push 产品分支、不 merge、不部署、不改产品仓、不写 PC-03 done
- 不改 SecretStore.kt / SecretStoreDeviceChecks.kt / Cargo.* / contracts/ / 其它 crate
- APK/dex/大日志不入库（>1MB 走 tmp/ 或删除）
- 本项通过不构成 PC-03 任何验收结论；11 项业务用例仍归 PC-03-AND-V1
```

## 二、与卡 B 的衔接（对卡面修正 v1.1 的补充 M6）

本授权项交付后，`PC-03-AND-V1回执裁定-退回补证与卡面修正v1.1` 中 **D2／D3／D4 三条前置作废**，改为一条：

> **M6**：卡 B 直接复用 `~/.agent-shared/scaffold/pc03-and-host/` 的宿主与 `build.sh`/`build.cmd`，不得另造第二套宿主；宿主的构建参数、dex 合并 stdlib、`internal` 同编译单元约束由该脚手架负责。卡 B 只负责：填 11 项用例、逐项记命令与退出码、给设备事实登记表。

**D1（解锁亮屏）与 D5（minSdk 29 / targetSdk 36，不下载组件）继续有效。**

## 三、并行与互斥

- 与卡 A（PC-03-WIN-V1 补证）**可并行**：卡 A 只跑测试、不改树；本项只写共享仓 `scaffold/` 与 `tmp/`。两者不共享文件。
- 与本项冲突的只有一种情况：他人写 `~/.agent-shared/scaffold/`。当前该目录不存在，无冲突。
- 卡 B 在本项交付前**不得开工**（否则又会回到"没有载体"的老路）；本项交付并经复核后，卡 B 立即续跑。

## 四、记录

- 共享仓 `.gitignore` 已核实：`tmp/` 在忽略区且零入库、`config/` 忽略、`scaffold/` 未被忽略 → 脚手架可提交、产物不可提交。这正是不选 A（项目外 tmp）的原因：tmp 里的东西清一次就没了，证据不可复现。
- 上一轮"宿主必须进产品仓"的表述已作废：`internal` 是编译单元级约束，与目录无关；把产品 `.kt` 当编译输入、输出到项目外可正常编译（已实测，4 个 class）。

## 挂起任务（当前全量快照）

继承 2026-11-21 最新已审交接，本轮不解挂任何项目。

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无 suspended 项；pRayShell 已 closed，无 suspended 项。
