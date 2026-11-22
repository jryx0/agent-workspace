# pCryoxy PC-03 W5 runner 返工交付

- 项目: pCryoxy
- 交付者: copilot@zhn-tbxg2iah-win~zhn-x-w
- 日期: 2026-11-22
- 状态: W5 runner 实现和静态验证完成；PC-03 保持 doing，等待审核方执行双向 W5。
- 工作区: `C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc03`
- 分支: `agent/copilot/pc03`
- 项目代码提交: `3934b657ac3df2ee0fcc9d5c520d270a3dddddf5`（父提交 `4456f66d9536477ee6e762dab72e7494428e6adb`）

## 第三轮裁定 §3 六项逐条证据

| # | 要求 | 实现与证据 |
|---|---|---|
| 1 | 双向登录 | runner 支持 Zhn_X 非提权交互账户和 pcx-t2 计划任务账户分别执行 write-own/read-foreign；PowerShell AST 检查通过。尚未执行跨账户 W5。 |
| 2 | Public 交换目录 | 交换路径使用 `C:\Users\Public\pcryoxy-xacct\x\<account>\<id>`。预检只核验 ACL，不设置 ACL；核对范围含 Public 根、inbox、outbox、`x`、`x\zhn_x`、`x\pcx-t2`。六处实测均符合既定 ACL，含 `x\` 双方只读；未修改 ACL。 |
| 3 | 真实 secure-store fixture | tests.rs 新增两个 ignored 入口，以 `Windows::initialize/open` 与 Vault API 建库、写入、重开和读取。读取方验证原 profile 拒绝访问、交换副本哈希、secure-store 的具体失败、DPAPI 解密失败及 Credential Manager 1168；不输出秘密明文。 |
| 4 | 动态提交、路径、哈希 | runner 从请求读取 commit、相对路径和 SHA-256，限定二进制路径边界并校验 reparse 状态及实际哈希；不依赖固定 commit/hash。 |
| 5 | 精确 cleanup | cleanup 由测试二进制处理本方 vault、交换子目录及凭据；凭据 target 由本方 key-id 派生并核对，删除后复读验证，不按宽泛前缀清理。 |
| 6 | 凭据删除重试 | Credential Manager 预检删除失败时重试一次；结果报告删除错误、重试次数和残留 target。内嵌 C# 编译检查通过。 |

## §10.3 ACL 核对

预检包含 `x\` 本身，双方对该层具有写入或删除权限时将阻止执行并报告 `ENV_BLOCKED`。runner 未调用 ACL 修改操作。Public 固定路径副本与共享仓 runner 源逐字节一致，SHA-256：

`FA8ADA2BF5F77BF0A3ABD75D428CA1AE103CE79F95B545DF4C45DC942D4EABEA`

源文件：[run-xacct.ps1](../scaffold/pc03-xacct/run-xacct.ps1)。裁定依据：[PC-03 第三轮复核裁定](./2026-11-22-pCryoxy-PC03第三轮复核裁定-4456f66-zhn-tbxg2iah-win.md) §3、§10.1–§10.3。

## 验证与边界

- `cargo fmt --package secure-store`：通过。
- `cargo test -p secure-store --lib`：17 passed，0 failed，4 ignored；W5 两入口保持 ignored，本轮未运行。
- `cargo check -p secure-store`：通过。
- runner PowerShell AST、内嵌 C# 编译、ACL 核对 helper：通过。
- 未运行跨账户 W5、未触发计划任务、未向 inbox 放入测试二进制；没有生成测试 fixture，也没有变更 ACL。
- H4 已由人类裁定转 PC-11，不属于本轮；本轮不修改 Android 文件或四份共享权威文档。

下一步由审核方按裁定执行两个账户方向的 W5，并据其结果决定 PC-03 是否结卡。本交付不代表 W5 或 PC-03 已通过。
