项目: pCryoxy

# PC-03-AND-V1 Android 真机 Keystore 补证

- 结论：**受外部条件阻塞**。Keystore 安全级别未取得，卡面门禁不满足，未执行本专项用例；不改变 PC-03 状态。
- 记录：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-21 UTC+8。沿用既有 PC-03 认领，不新增卡号。
- 指定现场：`C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc03`，`agent/copilot/pc03`，HEAD `c73d59d`；仅只读查看状态，未修改项目文件、未建工作树或分支。

## 设备门禁

| 项 | 命令与实测 |
|---|---|
| 连接 | `C:\Users\Zhn_X\.agent-tools\android-sdk\platform-tools\adb.exe devices -l`，退出 0；恰好一台 `device`，型号 `TEL_AN10`，非 offline / unauthorized。项目记忆中 WorkBuddy 将其登记为 HONOR 真实设备；本轮未独立证明硬件真实性。 |
| 型号 | `adb shell getprop ro.product.model`，退出 0：`TEL-AN10`。 |
| fingerprint | `adb shell getprop ro.build.fingerprint`，退出 0：`HONOR/TEL-AN10/HWTEL-H:10/HONORTEL-AN10/103.0.0.165C00:user/release-keys`。 |
| API、ABI | `adb shell getprop ro.build.version.sdk`、`adb shell getprop ro.product.cpu.abilist`，均退出 0：API 29；`arm64-v8a,armeabi-v7a,armeabi`。 |
| 模拟器指标 | `adb shell getprop ro.kernel.qemu`，退出 0、结果为空；此项不能单独证明是物理设备。 |
| root 指标 | `adb shell id` 退出 0，UID 2000 shell；`adb shell getprop ro.build.type`、`ro.debuggable`、`ro.build.tags` 均退出 0，分别为 `user`、`0`、`release-keys`；`adb shell 'command -v su'` 退出 1。未使用 root；这些指标不能证明设备绝对未 root，故 root 状态仍为未完全确认。若设备受控或已 root，应用隔离和秘密保护结论可能不适用。 |
| Keystore 安全级别 | **未取得**，不能判定 TEE / StrongBox / Software。设备为 API 29；项目记忆的独立环境冒烟记录指出 API 31 的 `KeyInfo.getSecurityLevel()` 在此设备不可用，其探针已卸载，不能代替本专项密钥级别证据。本轮未安装探针或创建密钥，也不根据设备型号推断级别。 |

卡面要求安全级别信息，当前不满足；按“任一不满足即停”停止。需由人类或契约所有者裁定 API 29 可接受的安全级别证据与门禁处理，并确认物理设备及 root 状态后再重试；不得将历史冒烟结果当成本专项通过。

## 工程与执行

- 已登记工具：JDK 21.0.13+9、Android SDK Platform 36/37、Build-Tools 36/37、NDK 29.0.14206865、Gradle 9.6.1；登记依据为共享 `env/toolchain.md`。本机只读目录检查发现相应 SDK 平台、build-tools 和 NDK 目录；`java`、`javac`、`gradle`、`kotlinc` 均不在当前 PATH。
- `Test-Path` 只读检查：用户目录下 `.gradle\caches`、`.gradle\wrapper\dists` 存在，`.m2\repository` 不存在；未盘点具体构件，不能判断离线构建是否可行。JDK、Gradle 可执行文件与 Kotlin 编译器未实测版本。
- 构建命令、安装命令、instrumentation 运行命令：**未执行，退出码不适用**。没有创建宿主、APK、so、密钥或 vault，也没有安装、下载依赖或更改全局配置。重新开工应先只读盘点完整缓存，缺构件先申请。
- `logcat` 采集和过滤命令：**未执行，退出码不适用**；无脱敏片段，不能宣称无秘密泄漏。

## 逐项结果

门禁未通过，以下各项均未运行；对应测试命令未确定，退出码均不适用，不能视为通过。

| # | 用例 | 结果 |
|---|---|---|
| 1 | 4097 字节合成秘密 seal/unseal 往返 | 未执行 |
| 2 | HMAC credential_id 跨进程重开稳定 | 未执行 |
| 3 | force-stop 后重启 verify 旧版本 | 未执行 |
| 4 | 删除 alias 后 unseal/seal/persist 返回 code 2、旧密文保留 | 未执行 |
| 5 | 篡改末字节返回 code 3 | 未执行 |
| 6 | 已存在 alias 再次 initialize 返回 code 6、不覆盖 | 未执行 |
| 7 | 目录重命名后 initialize 返回 code 6、held 目录不变 | 未执行 |
| 8 | noBackupFilesDir 实际路径及备份排除 | 未执行；无本专项实际路径或备份检查结果 |
| 9 | 其他 UID / 应用不可读目录 | 未执行；无实测拒绝回执 |
| 10 | logcat 无秘密明文 | 未执行；无过滤结果 |
| 11 | cleanup 后 alias 不存在、目录不存在 | 未执行；本轮未创建测试 alias 或目录 |

## 后续与未覆盖

明确安全级别门禁和真实设备/root 证据后，重新检查设备连接；完整盘点已登记工具与离线缓存，构件不足先申请。设备安装须人类确认且设备解锁；最小宿主只供测试，遵守卡面隔离与脱敏约束。所有 11 项仍需独立执行、记录命令和退出码；服务、IPC、TUN 和生命周期不在本卡。

## 挂起任务（当前全量快照）

继承最近交接，本轮不解挂任何项目。

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无 suspended 项；pRayShell 已 closed，无 suspended 项。
