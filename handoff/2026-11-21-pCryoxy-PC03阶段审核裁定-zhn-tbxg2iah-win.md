# pCryoxy｜PC-03 安全存储阶段审核裁定

项目：pCryoxy
任务：PC-03 安全存储
审核时间：2026-11-21（UTC+8）
审核人：WorkBuddy
交接提交：`bc3b0efb2f89e138591d5d9da24875533ed4205f`
实施提交：`9b414f24824ab99f737013bc9ddea64fffcad43c`
前置基线：`2908e4e4cde5b060568b0d56ff270640c4ca3f63`

## 一、裁定

**阶段实施可接受；PC-03 未通过结卡验收，维持 `doing / blocked`。**

本次不退回 PC-03 的实现范围：实施提交与交接记录可追溯，改动集中在 secure-store、平台后端、脱敏和测试，未修改公共 trait、DTO、proto、公共锁文件、core-lock 或 PC-04 文件；交接记录也明确声明 `commit_staged` 不是 IR 与 vault 的跨存储原子提交。

本次不批准 `done`、合并或部署。`bc3b0ef` 是本地交接提交，`9b414f2` 是实施提交；两者都不是本裁定提交号。

## 二、已采信证据

1. 实施提交 `9b414f24824ab99f737013bc9ddea64fffcad43c` 相对 `2908e4e` 变更 9 个 PC-03 文件，共新增 2,565 行；提交工作树干净，范围未越界。
2. 交接记录提供了 Windows 定向回执：不安全路径、4097 字节虚构秘密、HMAC、staging、子进程重开、旧版本保留、缺失主密钥和脱敏投影等定向测试各 1 passed；同时如实说明这些不是 Windows Service 身份验收。
3. 交接记录提供了 Linux 验证二进制回执：4 passed、0 failed、1 ignored，覆盖同 UID 重开、0700/0600、缺失密钥、篡改、符号链接、不可变版本和旧密文保留；同时如实说明第二账户拒绝尚未验证。
4. 交接记录提供了 Gitleaks、`git diff --check`、Clippy 和格式检查回执；本次独立执行 `git diff 2908e4e..9b414f2 --check` 退出码 0。
5. 源码静态核对确认：公共 `SecretStore` 仍只暴露 `put` 与 `with_secret`；错误投影使用固定 `ErrorCode`，不格式化第三方原始错误；Linux 后端拒绝 root、符号链接和不安全权限；Android 适配明确不宣称设备验收。

## 三、未满足的结卡条件

以下事项仍是结卡阻塞项：

1. Windows Service 身份、服务 SID/ACL、服务进程重启和异账户访问尚未实测；既有 Windows 全套测试曾有 6 passed、8 failed、2 ignored，交接记录未查明失败根因，不能以定向通过替代全套验收。
2. Linux 第二账户拒绝尚未验证；`setpriv` 在当前 WSL 环境退出 127，且返回 `setresuid failed: Operation not permitted`，不能据此宣称跨账户隔离通过。
3. Android 没有获准真机；Keystore、`noBackupFilesDir`、进程重启持久化和异账户测试均未运行，设备验收保持 blocked。
4. 本地复核环境无法独立重跑完整 Cargo 测试：锁定 Rust 工具链的离线缓存缺少 `idna`，Cargo 退出 101；该结果属于复核环境依赖缺口，不判定为实施代码测试失败。当前环境的 Cargo 也未安装 `cargo-fmt` 子命令；不覆盖交接中已提供的格式回执，但不能由本地复核再次确认。

## 四、继续实施与复审要求

PC-03 可继续在现有范围内补证，不得扩大公共契约：

- 补 Windows Service 身份/ACL、服务重启和异账户回执，并解释或修复全套测试失败根因；
- 在具备权限的 Linux 环境补第二账户拒绝；
- 在获准 Android 真机补 Keystore、noBackup、重启持久化和权限回执；
- 所有测试使用测试专属 vault、alias 和虚构秘密，不使用真实凭据；
- 新增交接记录必须 append-only，附实施 SHA、完整命令、退出码、环境和未覆盖项；
- 完成上述补证后再申请 PC-03 结卡复审。

**本裁定不等于 PC-03 done，不授权合并，不授权部署。**
