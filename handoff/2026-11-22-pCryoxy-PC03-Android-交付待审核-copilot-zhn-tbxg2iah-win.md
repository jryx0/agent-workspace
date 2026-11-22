# pCryoxy PC-03 Android test host 交付待审核

- 项目：pCryoxy
- 卡号：PC-03；泳道 C：Android A1～A3；前置宿主子任务 `PC-03-AND-HOST-V1`。
- 执行人：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-22。
- 状态：**blocked / 交付待审核**；未标 done、未安装或部署应用。
- 宿主脚手架共享提交：`35e14f8c11a999e814df986201c425d438d547f9`。

## 范围与变更

仅共享仓 `scaffold/pc03-and-host/` 的宿主文件：

- `AndroidManifest.xml`
- `HostInstrumentation.kt`
- `build.cmd`
- `build.sh`
- `README.md`

未改项目产品文件。宿主仅为测试载体，不是产品 APK，也不构成 PC-03 Android 验收结果。

## 构建证据

输出包：`C:\Users\Zhn_X\.copilot\session-state\9c3b77d9-71d5-42cb-8b89-694c4ab7ac59\files\pc03-and-host-evidence.zip`
SHA-256：`a005586c5cf4908400dd7e0de4e7410b553cb277d6adcc51d1a9c7fa8fcaf005`。ZIP 内部 `hashes.sha256` 的 11 个条目已逐项核验。

JDK 21、Kotlin 2.3.21、Android API 36、build-tools 36.0.0 下已编译必需 classes 与 `classes.dex`，APK 打包及对齐成功：

| 输出 | 大小 | SHA-256 |
|---|---:|---|
| `apk/host-unsigned.apk` | 748,817 | `55b259f72a2dad7601281800fb1da3b05fae71868fcf8b48f20592827af3369b` |
| `apk/host-aligned.apk` | 748,817 | `f353e28c0eef5709e561cdd9a0454bcdeafb45e2557cd15fde0066c600be6073` |
| `dex/classes.dex` | 2,444,772 | `3bdf02c2f0ed35cf9fe28ed53b61a79e91fc3517170dc006a6ac877e18af2ef9` |

没有可用的已批准本地测试 keystore，故未签名；未生成或替换密钥/证书。未安装 APK，A1～A3 设备流程均未运行；不能据此声称 Android 真机持久化或重启验证通过。

## 阻塞与请求

请 WorkBuddy 复核宿主脚手架的授权范围及离线构建证据。解阻需人类提供/批准现有测试 keystore 路径后，才能签名并执行设备安装、prepare → reboot → verify → cleanup。当前 PC-03 仍为 blocked，不放行下游卡。
