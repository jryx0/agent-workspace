# PC-03-AND-V1 回执裁定：退回补证 + 卡面修正 v1.1

项目: pCryoxy

- 被审回执：`handoff/2026-11-21-pCryoxy-PC03-Android真机验证-zhn-tbxg2iah-win.md`（copilot@zhn-tbxg2iah-win~zhn-x-w）
- 回执结论原文：受外部条件阻塞；已发现一台在线设备，但 Keystore 安全级别未确认，按门禁停止；11 项用例均未执行
- 裁定：**不接受。判"退回补证"，不是阻塞。**
- 裁定人：WorkBuddy@zhn-tbxg2iah-win~zhn-x-w，2026-11-21 23:15（UTC+8）
- PC-03 状态不变：仍 `doing`／有条件通过，**不得写 done**。

## 一、裁定要点

| 项 | 回执主张 | 实测核实 | 裁定 |
|---|---|---|---|
| Keystore 安全级别 | 未取得 → 门禁不满足 → 停 | 本机可判定到"无 StrongBox"；TEE/软件不可区分属 API 29 限制 | **驳回**：处理方式应为"记录不可判定 + 残留风险"，非停机 |
| 设备真实性 / root | "不能证明绝对未 root" → 未完全确认 | 判据已充分（见二.2），卡面只要求"声明并评估影响" | **驳回**：把不可证伪命题当门禁 |
| 工程前置 | 缓存未盘点、不能判断离线构建可行 → 缺构件先申请 | 已实测：用本机现有构件离线编译产品 Kotlin 源码成功，d8 出 dex | **驳回**：不缺构件，是没试 |
| 11 项用例 | 未执行 | 未执行属实；宿主新增属卡面第三条已授权范围 | **驳回**：未做≠做不了 |
| 未修改项目文件 | — | worktree 干净，HEAD `c73d59d` 与回执一致，无 `native/android/testhost/` | **采信**：陈述诚实，但不改变结论 |

**核心判断**：回执唯一实质缺口是"没写宿主、没跑用例"，而这是卡面显式授权的份内事；它把三件可解的事（安全级别口径、设备真实性口径、离线构建能力）都转写成外部条件，属结论先行。按 2026-11-21 对 PC-03-WIN-V1 同一口径，不予采信。

## 二、逐条核实（本轮实测，2026-11-21 23:10–23:15）

### 1. Keystore 安全级别：可判定到"无 StrongBox"

回执称"未取得，不能判定 TEE / StrongBox / Software"。实测可判定的部分是明确的：

| 判据 | 命令 | 实测 |
|---|---|---|
| StrongBox 特性位 | `adb shell "pm list features" \| grep -i strongbox` | **空**（无 `android.hardware.strongbox_keystore`） |
| StrongBox HAL | `adb shell "lshal \| grep -i strongbox"` | **空** |
| Keymaster HAL | `adb shell "lshal \| grep -i keymaster"` | `android.hardware.keymaster@3.0::IKeymasterDevice/default`（FC，运行中） |
| 系统完整性 | `getprop ro.boot.verifiedbootstate` / `ro.boot.flash.locked` | `green` / `1`（BL 锁定、校验启动完好） |
| 存储加密 | `getprop ro.crypto.state` / `ro.crypto.type` | `encrypted` / `file`（FBE） |

**结论**：StrongBox **不支持**（特性位与 HAL 双缺，属可判定的否定结论）；TEE 与软件 Keymaster 在 API 29 上不可区分，因为 `KeyInfo.getSecurityLevel()` 是 API 31+。卡面要的是"报告这一项"，报告"无 StrongBox + TEE/软件不可区分（API 29 限制）+ 残余风险"即已满足。共钥级别与 11 项**行为**断言无关：用例验的是 seal/unseal/HMAC/持久化/错误码/隔离，不需要知道密钥落在 TEE 还是软件。

**追溯**：这一口径我在 2026-11-21 22:5x 的冒烟回报中已明确写出（"API 29 拿不到 Keystore 安全级别……得改成'声明不可判定'或另取厂商属性，不能编造"），并已记入 `memory/projects/pCryoxy.md`。回执把该项反向当停机挡板，属选择性引用。

### 2. 设备真实性与 root：卡面要求"声明并评估"，不是"绝对证明"

已有判据（全部退出码 0，本轮及 22:5x 两次复现）：

- `ro.kernel.qemu` 为空；`ro.build.type=user`、`ro.build.tags=release-keys`、`ro.debuggable=0`
- `command -v su` 退出 1；`adb shell id` = `uid=2000(shell)`
- `ro.boot.verifiedbootstate=green`、`ro.boot.flash.locked=1`（BL 锁定，未刷机）
- fingerprint `HONOR/TEL-AN10/HWTEL-H:10/HONORTEL-AN10/103.0.0.165C00:user/release-keys`
- 序列号 `9WDNW21527000189`，`adb devices -l` 稳定 `device`

"不能绝对证明未 root"对任何设备都成立（用户态无法排除内核级后门）。若以此为门禁，任何真机验收都不可能启动。正确写法是：**按上述判据声明为"非 root 生产机（证据级，非绝对证明）"，并评估影响**——已 root 才会影响本卡隔离结论。

### 3. 工程前置：离线构建能力已实测存在，不需要申请新构件

回执称"未盘点具体构件，不能判断离线构建是否可行"。本轮已实际编译成功，命令与结果如下（输出到项目外 tmp，未触碰仓库）：

**编译产品 Kotlin 源码**（退出码 0，产物 4 个 class）

```text
J=C:/Users/Zhn_X/.agent-tools/runtimes/jdk-21/bin/java.exe
GL=C:/Users/Zhn_X/.agent-tools/runtimes/gradle-9.6.1/lib
SL=C:/Users/Zhn_X/.gradle/caches/modules-2/files-2.1/org.jetbrains.kotlin/kotlin-stdlib/2.3.21/a2ee2c4e220fee522f0451b723bab2a43f3481a7/kotlin-stdlib-2.3.21.jar
AJ=C:/Users/Zhn_X/.agent-tools/android-sdk/platforms/android-36/android.jar
"$J" -cp "$GL/*" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler \
  -classpath "$AJ;$SL" -jvm-target 11 -d out \
  <worktree>/native/android/SecretStore.kt \
  <worktree>/native/android/tests/SecretStoreDeviceChecks.kt
```

产物：`app/pcryoxy/secure/SecretStore.class`、`SecretStore$Failure.class`、`SecretStoreDeviceChecks.class`、`SecretStoreDeviceChecks$Proof.class`
（注：`-no-stdlib`/`-no-reflect` 的 warning 可忽略；编译器取自 Gradle 9.6.1 自带 `kotlin-compiler-embeddable-2.3.21.jar`，**无需 kotlinc、无需下载**。）

**dex 化**（退出码 0，`classes.dex` 2,441,280 字节）

```text
BT=C:/Users/Zhn_X/.agent-tools/android-sdk/build-tools/36.0.0
"$J" -cp "$BT/lib/d8.jar" com.android.tools.r8.D8 --min-api 29 --lib "$AJ" \
  --output dexout out/app/pcryoxy/secure/*.class "$SL"
```

注意两点：① **必须把 kotlin-stdlib jar 一起 dex**（Android 不含 stdlib）；② d8 会刷大量 `kotlin metadata` 版本告警（d8 8.10 不认 Kotlin 2.3 元数据），无害——只影响元数据重写，不影响运行；嫌吵可改用 `kotlin-stdlib 2.2.10`（缓存中同样存在）。

**打包、签名、安装、运行**四步在 22:5x 已用同一台机器、同一台设备跑通（aapt2 link → zipalign → apksigner → `pm install` → `am instrument -w`），产物 12,697 字节、debug 签名。故"缺构件先申请"不成立：**不缺，已验**。

### 4. 11 项未执行

未执行属实，但宿主新增在卡面第三条明确授权：`允许新增仅测试用途的最小宿主工程 native/android/testhost/`。故不构成外部条件。宿主可写性的关键技术点已澄清：

- `SecretStoreDeviceChecks.Proof` 构造器是 `internal` → **宿主必须与产品 Kotlin 源码同一编译单元**（一起交给上面那条 K2JVMCompiler 命令）；这不需要 Gradle module，也不需要 `androidx.test`。
- 跨进程用例（第 2、3 项）需 `Proof.namespace` 与 `Proof.version` 跨进程保留：两者都是 `public val`，宿主自行落盘（不进 logcat）即可，`am force-stop` 后重建 Proof 再 `verify` 即为真跨进程。
- 返回码定义已确认可用：`SecretStore.Failure(code)`，`code=2` 密钥缺失、`code=3` 解密/AEAD 失败、`code=6` alias 冲突（`native/android/SecretStore.kt:36,45,71-73,88`），与卡面 4/5/6/7 项一致。

## 三、卡面修正 v1.1（自本裁定生效，覆盖派工文档中的原条款）

**M1｜门禁 2 重新定性**：原"门禁 2 设备信息"改为**设备事实登记（记录项，非停机条件）**。写法要求：型号、fingerprint、API、ABI、root 判据（上列 6 条）、Keystore 级别（本机：无 StrongBox，TEE 与软件不可区分，API 29 限制）、残余风险声明。此项**任何取值都不得用于停机**。

**M2｜真正的停机条件**（仅这三条）：
1. `adb devices -l` 非"恰好 1 台 physical 且状态 device"（空列表、多设备未指定 `-s`、offline/unauthorized）；
2. 确认为模拟器（`ro.kernel.qemu=1` 或 `ro.hardware` 为 goldfish/ranchu）；
3. 宿主编译/安装/运行在**已按 D1–D5 执行后**仍失败，且贴出首次失败的确切命令、退出码与错误行。

**M3｜新增执行前置 D1–D5**（22:5x 实测所得，必须遵守）：
- **D1 解锁亮屏**：设备带锁屏时 `pm install` 会**无任何输出地挂住**、无失败码；解锁亮屏后立即 `Success`。开工前先 `dumpsys power | grep mWakefulness` 与 `dumpsys window | grep isStatusBarKeyguard`，非 Awake/仍 keyguard 即请人类解锁，不得反复重试。
- **D2 不用 Gradle/AGP/NDK**：按二.3 的两条命令，用 JDK21 + build-tools 36 + `android-36/android.jar` + Gradle 自带 `kotlin-compiler-embeddable`。
- **D3 stdlib 一并 dex**，APK 约 2.5MB → 不入库（>1MB 走 tmp/ 或删除）。
- **D4 宿主与产品源码同编译单元**（`internal` 约束），Proof 的 namespace/version 由宿主落盘以支持 force-stop 跨进程。
- **D5 构建参数**：`minSdk 29`、`targetSdk 36`；本机无 `android-29` 平台，此组合已在 API 29 设备安装运行通过，**不得为此下载组件**。

**M4｜用例 9 的可执行写法**（避免"沙箱理应如此"）：以 `adb shell`（uid 2000）`ls` 宿主私有目录须 `Permission denied`；另用第二个不同 UID 应用尝试读取同路径，双证据。**M5｜用例 8**：给 `context.noBackupFilesDir` 实际绝对路径（形如 `/data/user/0/<pkg>/no_backup`）+ `dumpsys backup` 排除项，两者都要。

## 四、可直接转发给实施方的回复（PC-03-AND-V1 补证要求）

```text
【裁定】PC-03-AND-V1 回执不接受，判"退回补证"，非外部条件阻塞。PC-03 状态不变。

一、三处驳回（附实测，命令与退出码见裁定文档第二节）
1) Keystore 安全级别不是门禁：`pm list features | grep -i strongbox` 与 `lshal | grep -i strongbox`
   均为空、`lshal` 只有 keymaster@3.0 → 可判定"无 StrongBox"。TEE/软件不可区分是 API 29 限制
   （KeyInfo.getSecurityLevel() 为 API 31+），按"不可判定 + 残余风险"记录即可，不得停机。
2) 设备真实性按证据级声明，不要求绝对证明：ro.kernel.qemu 空、user/release-keys、ro.debuggable=0、
   无 su、uid=2000、verifiedbootstate=green、flash.locked=1。据此声明"非 root 生产机（证据级）"并评估影响。
3) 离线构建能力已实测存在，不缺构件：
   java -cp "<gradle-9.6.1>/lib/*" org.jetbrains.kotlin.cli.jvm.K2JVMCompiler \
     -classpath "<android-36>/android.jar;<kotlin-stdlib-2.3.21.jar>" -jvm-target 11 -d out \
     native/android/SecretStore.kt native/android/tests/SecretStoreDeviceChecks.kt    # 退出 0，4 个 class
   d8 --min-api 29 --lib android.jar --output dexout out/app/pcryoxy/secure/*.class <kotlin-stdlib.jar>
                                                                                    # 退出 0，dex 2.44MB
   打包/签名/安装/am instrument 四步已于本机本设备跑通，无需 Gradle/AGP/androidx.test/NDK，不得下载组件。

二、执行前置（硬性，已实测）
D1 设备必须解锁亮屏：锁屏下 pm install 无输出静默挂住且无失败码。开工前查
   dumpsys power | grep mWakefulness 与 dumpsys window | grep isStatusBarKeyguard；不满足请人类解锁。
D2 先写 native/android/testhost/（卡面已授权，包名与产品隔离，不改产品 manifest/包名/依赖）。
D3 宿主必须与 SecretStore.kt + tests/SecretStoreDeviceChecks.kt 同一编译单元（Proof 构造器为 internal）。
D4 跨进程两项（2、3）用 Proof.namespace/version 落盘（不进 logcat），am force-stop 后重建 Proof 再 verify。
D5 构建用 minSdk 29 / targetSdk 36；本机无 android-29 平台，不得为此下载。

三、必须交付
1) 设备事实登记表（含 StrongBox 否定判据、root 六条判据、Keystore 不可判定声明与残余风险）。
2) 宿主源码位置、两条构建命令、安装命令、每项用例的 am instrument 参数。
3) 11 项逐项：命令 + 退出码 + 结果（不得合并为"全部通过"）；用例 8 给 noBackupFilesDir 绝对路径 +
   dumpsys backup 排除项；用例 9 给 adb shell(uid 2000) 与第二应用两个 UID 的拒绝回执；
   用例 10 给 logcat 过滤命令与脱敏结论；用例 11 给 containsAlias=false 与目录不存在的证据。
4) 未覆盖项清单（服务/IPC/TUN/生命周期属 PC-11，不在本卡）。
5) 结论三选一：通过 / 失败 / 受外部条件阻塞。仅当命中 M2 三条真停机条件才可写阻塞，且必须贴首次失败
   的确切命令、退出码与错误行。

四、约束不变：不 push 项目分支、不 merge、不部署、不得写 PC-03 done；APK/dex/大日志不入库。
```

## 五、复审口径（本轮不打折）

- 只认逐项命令 + 退出码 + 原始输出；"全部通过"、"理应如此"、无退出码的结论一律退回。
- 用例 3 必须 `am force-stop` 后 `pidof` 为空再启，对象重建不算跨进程。
- 用例 4 除 code 2 外必须证明旧密文字节未变（长度 + 哈希）。
- 用例 7 必须证明 held 目录未被改动（mtime/条目对比）。
- 安全级别、设备真实性两项按 M1 记录，**不再作为任何退回理由**。

## 挂起任务（当前全量快照）

继承 2026-11-21 最新已审交接，本轮不解挂任何项目。

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无 suspended 项；pRayShell 已 closed，无 suspended 项。
