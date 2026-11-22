# pCryoxy PC-03 Android 返工复验交付待审核

- 项目：pCryoxy
- 卡号：PC-03；泳道 C：Android A1～A3；状态：**doing / 返工交付待审核**，未标 done。
- 执行人：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-22。
- 产品代码提交：`dc3d34d825dca715e29e174297f449c83216273a`，已推送至 `agent/copilot/pc03`。
- 宿主脚手架提交：`1e888153a9d64289b09320dcb2e6950c89b68bc8`（本地共享仓提交，随本轮共享仓同步）。

## 产品与宿主变更

- `SecretStore.kt` 只对自建 namespace 目录严格要求 0700；`noBackupFilesDir` 父目录验证属主且拒绝 other-writable，兼容 Android 框架创建的 0771。
- 持久化顺序改为 pending 文件 → 写入并 fsync → 确认 final 不存在 → 锁内 `Os.rename` → 同步目录。进程内锁避免同进程 `FileChannel` 重叠锁；namespace 下的 0600 锁文件提供协作进程间文件锁。若 final 已存在，删除 pending 并返回 Failure(6)，不覆盖既有版本。
- Device checks 覆盖同版本重复写入拒绝、并发竞争时只允许一个 final 提交、读回内容完整，以及 pending/锁文件清理。
- `prepare`、`verify` 输出 ciphertext SHA-256；新增 `export-ct` 与 `probe-old-ct` 阶段。A3 probe 校验输入密文摘要并实测要求 `Failure(2)`，成功后输出 `failureCode=2`。
- Host `onCreate()` 调用 `start()`；PowerShell 流程必须同时解析 `INSTRUMENTATION_CODE: -1` 与 `INSTRUMENTATION_STATUS: result=PASS`，安装参数加入 `--no-incremental`，安装超时为 90 秒。
- `build.cmd` 在自身子进程中设置 `JAVA_HOME` 到已批准的本地 JDK 21，使 `apksigner` 可运行；未修改用户/系统环境变量。

## 构建证据

最终构建目录：`~/.copilot/session-state/9c3b77d9-71d5-42cb-8b89-694c4ab7ac59/files/pc03-and-host-r7/`

| 产物 | 大小 | SHA-256 |
|---|---:|---|
| `apk/pc03-host.apk` | 762,265 | `c7c0615351e3bc54b3bd5132bf87a4ed006430c051c2f641eb5eca1ab02d9b54` |
| `dex/classes.dex` | 2,456,540 | `25a9665a662603a962643b8f3747196f5f1af00a98345c9d7c20e7e287ac3748` |

APK 签名证书 SHA-256：`e6d1816a916ae378f1fde5163ff518b7bd439226c71a52948750593401df4794`，与既有批准的 debug.keystore 指纹一致；复用了已有密钥，未生成证书或密钥。构建脚本在未继承 `JAVA_HOME` 的 PowerShell 进程中退出 0，`apksigner verify --print-certs` 通过。D8 输出 Kotlin metadata 兼容性警告，但构建成功。

## 设备门禁

遵守项目边界，本轮**未安装或部署 APK**，因此 A1～A3 仍未实测通过。APK 与 dex 均保留在 session 私有目录、未入 Git。真实设备验证仍需人类在允许安装后执行；A3 先运行 `prepare`、`export-ct` 并保存 namespace/hash/Base64 密文，再重装宿主调用 `probe-old-ct`，期望 `failureCode=2`。

PC-03 整卡仍为 doing，需 WorkBuddy 复核；W5 计划任务/runner 阻塞也尚未解除，不请求或宣称整卡 done。
