# pCryoxy 真机验证方案 v2（Windows 跨账户 / Android Keystore）

- 发布: workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-22
- 适用: PC-03（Windows 用户态 + Android Keystore），后续 PC-10（Windows 服务身份）、PC-05/PC-11（Android）
- 替代: 11-21 起 PC-03-WIN-V1 / AND-V1 的逐次人工派工方式；已发布的裁定与证据不作废

## 1. 为什么反复结不了（根因）

| # | 现象 | 根因 |
|---|---|---|
| R1 | Windows 13 项失败都在 fixture 初始化 `PermissionDenied`（`tests.rs:48`） | **环境问题，不是产品缺陷**：`C:\Users\test1` 的 DACL 里有一条显式 `ZHN-TBXG2IAH\Zhn_X:(OI)(CI)(F)`，被继承到 `AppData\Local\Temp`。后端 `check_ancestor` 会拒绝“其他普通用户可写”的祖先目录，判断是对的。也就是说，测试账户的配置本身让被测的安全检查必然拒绝 |
| R2 | 只有一次整套运行、只有套件级退出码 101，单项无法定性 | 没有逐项独立运行；证据靠人工转写 |
| R3 | 每轮都要人类交互登录 test1、手动启动，然后人类叫停 | 跨账户步骤完全靠人工，成本高，容易中断 |
| R4 | 历史“6 通过 / 8 失败”的名单丢失，裁定又反复改口径 | 每轮没有冻结的验收矩阵和证据包，审核方逐轮追加要求 |
| R5 | Android 锁屏时 `pm install` 静默挂住；华为/荣耀机型弹出 USB 安装确认 | 设备前置状态没有自动检查 |
| R6 | 唯一独立的问题：`native_create_delete_distinct_targets_keep_new_credentials` 报 `Err(1168)`（ERROR_NOT_FOUND） | 可能是真实的并发缺陷，与 R1 无关，需同账户单独复现 |

## 2. 新方案的五条规则

1. **先跑环境预检，再跑测试**：预检不通过就输出 `ENV_BLOCKED` 和原因，不运行测试、不算失败。
2. **逐项独立运行**：先 `--list`，再对每项用 `--exact` 单独运行，逐项记录退出码。
3. **证据包自动生成**：每轮输出一个目录，包含 `manifest.json`（精确提交、二进制 SHA-256、账户 SID、设备型号/API、时间）、`results.tsv`（用例 / 退出码 / 耗时）、原始 stdout/stderr、预检结果，以及以上全部文件的 SHA-256。不允许人工转写结论。
4. **冻结验收矩阵**：§5 的矩阵一经人类确认即冻结，审核只能逐项对照，不得追加新口径；需要改矩阵时报人类裁决。
5. **限时两轮**：同一矩阵项连续两轮失败，就标 `blocked` 并报人类，不再无限补证。

## 3. Windows 方案

### 3.1 账户与目录（人类一次性操作，需管理员）

- **建议新建干净测试账户 `pcx-t2`**（标准用户），**不要给它的配置文件加任何其他用户的 ACE**。test1 保留，不再用于 PC-03。
  - 若坚持用 test1，可以删除那条多余的 ACE：`icacls C:\Users\test1 /remove:g Zhn_X /t /c`（管理员执行）。Zhn_X 作为管理员，仍可通过提权访问该目录。
- 交接目录：`C:\Users\Public\pcryoxy-xacct\{inbox,outbox}`。执行方往 inbox 放测试二进制和请求文件，跨账户运行结果写入 outbox。

### 3.2 跨账户执行：去掉交互登录

- 由人类以管理员身份**登记一次计划任务** `pcryoxy-xacct`：以 `pcx-t2` 身份运行，选“不管用户是否登录都要运行”，每 2 分钟检查一次 inbox，存在请求文件就执行 `run-xacct.ps1`。密码只在登记时由人类输入一次，不写入任何文件。
- 之后 agent 只需把精确提交的测试二进制和请求放进 inbox，等 outbox 出结果，不需要人类再登录。
- **预检要包含批处理登录下的 DPAPI 和凭据管理器可用性**。如果批处理登录写凭据失败（比如 1312 错误），就退回由人类执行 `runas /user:pcx-t2` 一次，并在证据包里写明登录类型。

### 3.2a 跨账户交接约定（2026-11-22 08:35 补，供泳道 B 实现）

- 人类已于 08:27 新建标准用户 `pcx-t2`（尚未登录，配置文件将在计划任务首次批处理登录时自动生成；**不得给其配置文件添加任何其他用户的 ACE**）。
- 目录与权限（人类管理员执行）：`C:\Users\Public\pcryoxy-xacct\` 断开继承；Administrators/SYSTEM 完全控制，`Zhn_X` 修改，`pcx-t2` 只读执行；仅 `outbox\` 给 `pcx-t2` 修改。
- 计划任务 `pcryoxy-xacct`：以 `pcx-t2` 运行、不管是否登录、每 2 分钟、`IgnoreNew`、单次限时 30 分钟，执行固定路径 `C:\Users\Public\pcryoxy-xacct\run-xacct.ps1`。
- **`run-xacct.ps1` 由 copilot 泳道 B 提供**（纯 ASCII，放上述固定路径），约定：
  1. 只处理 `inbox\<id>.request.json`（含精确提交、测试二进制相对路径、SHA-256、用例清单）；先校验二进制 SHA-256，不符则写 `outbox\<id>.rejected`。
  2. pcx-t2 对 inbox 无写权限，以 `outbox\<id>.done` 存在作为“已处理”标记，不重复执行。
  3. 结果按 §2 第 3 条写 `outbox\<id>\`（manifest 含 `whoami /user` SID 与登录类型、results.tsv、原始输出、预检、SHA-256 清单）。
  4. 预检含批处理登录下 DPAPI / 凭据管理器可用性；失败写 `ENV_BLOCKED`。
- 计划任务登记后，人类或 workbuddy 用 `schtasks /query /tn pcryoxy-xacct /v /fo list` 核对“上次运行结果”。

### 3.3 同账户部分

- 同账户写读、真实进程重启、密钥缺失不重新生成、4097 字节大秘密、Token 轮换、1168 并发问题复现：这些全部在 Zhn_X 下由 agent 自动执行，不需要人类参与。

### 3.4 服务身份（PC-10，建议提前准备）

- 建议启用 **Windows 沙盒**：这台机器的系统是企业版 LTSC，虚拟化已就绪，但沙盒功能还没开。由人类以管理员身份执行 `Enable-WindowsOptionalFeature -Online -FeatureName Containers-DisposableClientVM -All`，然后重启。
- 沙盒里是一次性的管理员环境：可以随便建账户、用 `sc.exe` 装服务、验证服务 SID 和 ACL、重启服务，测完即丢，不污染本机。用 `.wsb` 配置文件把证据目录映射出来。PC-10 的服务身份验收全部在沙盒里完成。

## 4. Android 方案

- 当前设备：**荣耀 TEL-AN10（API 29）**，已通过 adb 连接（`~/.agent-tools/android-sdk/platform-tools/adb.exe`），符合 minSdk 29 的裁定（D5）。
- **人类一次性设置手机**：
  - 开发者选项里打开“USB 调试”“仅充电模式下允许 ADB 调试”“充电时保持唤醒”，关闭“监控 ADB 安装应用”；
  - 测试期间临时取消锁屏密码（这样重启后能自动进入桌面）。
- **自动化脚本**（复用 AND-HOST 宿主，不另造第二套）：
  1. 预检：`adb get-state`，屏幕亮着（`dumpsys power` 显示 `mWakefulness=Awake`），没有锁屏（`dumpsys window` 显示 keyguard 未显示），可用存储空间足够；
  2. `pm install` 设 60 秒超时，超时判为 `ENV_BLOCKED`；
  3. `am instrument -e phase prepare`；
  4. `adb reboot` → `wait-for-device` → 等 `sys.boot_completed=1` → 再预检一次；
  5. `am instrument -e phase verify`：验证重启后可读、密文没变；
  6. `am instrument -e phase cleanup`，然后卸载。
- 模拟器的 Keystore 是软件实现，**只能做冒烟，不能作为验收**。
- **可选技能**：「腾锐Ai安卓」（`android-phone-agent`），可以截屏识别并自动点击华为/荣耀的安装确认弹窗，解决 R5 中仍需人手点的部分。它会截取手机屏幕，人类同意后才安装。

## 5. PC-03 冻结验收矩阵（v1.2 口径，**人类 2026-11-22 08:25 确认，已冻结**）

> 冻结后审核只能逐项对照本表判定通过/不通过，不得追加口径；任何增删改须报人类裁决并发新版本。

| ID | 平台 | 项 | 执行方式 |
|---|---|---|---|
| W1 | Win | 同账户写读、真实进程重启后可读 | 自动 |
| W2 | Win | 篡改与版本替换被拒；密钥缺失时不重新生成、旧密文保留 | 自动 |
| W3 | Win | 祖先目录不安全（junction、他人可写）时拒绝 | 自动（用故意构造的目录） |
| W4 | Win | 并发 provisioning 互不覆盖；1168 问题定性 | 自动 |
| W5 | Win | 异账户 `pcx-t2` 读不到、解不开 Zhn_X 的数据，反之亦然 | 计划任务跨账户 |
| W6 | Win | Token 轮换 | 自动 |
| A1 | Android | Keystore 生成、写读 | adb 自动 |
| A2 | Android | 重启后可读、密文不变 | adb reboot 自动 |
| A3 | Android | 卸载重装后旧数据不可解 | adb 自动 |
| L1 | Linux | 0600 权限 + 目录属主、异账户拒绝 | 已采信，审核方复跑一次 |
| X1 | 全平台 | 日志、事件、崩溃通道无明文泄漏（gitleaks 扫描证据包） | 自动 |

服务 SID / ACL / 服务重启可读移到 PC-10（沙盒）。

## 6. 需要人类做的事（一次性）

1. ~~确认 §5 矩阵后冻结。~~ 已完成（2026-11-22 08:25 人类确认）。
   - 手机“充电时保持唤醒”已由 workbuddy 于 08:24 经 adb 开启（`stay_on_while_plugged_in=3`）。
2. 新建 `pcx-t2` 账户（或删除 test1 上多余的 ACE），并登记计划任务 `pcryoxy-xacct`。
3. 手机做 §4 的设置；测试期间保持 USB 连接、充电。
4. （可选）启用 Windows 沙盒；（可选）同意安装「腾锐Ai安卓」技能。
