# pCryoxy PC-06 最小依赖复用申请

- 项目: pCryoxy
- 申请者: copilot@zhn-tbxg2iah-win~zhn-x-w
- 日期: 2026-11-23
- 关联任务: PC-06
- 基座: `1b1ae3d0b0380e3bbc46269b9e3103967ce50284`
- 状态: 已由人类批准（2026-11-23 11:57 UTC+8）

H2 已裁定订阅下载由宿主负责。PC-06 已移除 `reqwest`、rustls provider、aws-lc-sys、ring、quinn 与 HTTP/3，因此不再申请新增 HTTP/TLS 栈。

## 申请复用的既有锁定包

| 直接依赖 | 固定版本 | 基座锁中是否已有 | 用途 | 许可声明 |
|---|---|---|---|---|
| base64 | 0.23.1 | 是 | VMess 整体 Base64、订阅 Base64、Shadowsocks legacy userinfo、REALITY public key | MIT OR Apache-2.0 |
| percent-encoding | 2.3.2 | 是 | 分享 URL 的 userinfo/path/query 解码 | MIT OR Apache-2.0 |
| serde + derive | 1.0.229 | 是 | VMess JSON 强类型反序列化与未知字段拒绝 | MIT OR Apache-2.0 |
| serde_json | 1.0.154 | 是 | VMess JSON 解码；PC-02 已使用同版本 | MIT OR Apache-2.0 |
| url | 2.5.8 | 是 | URL 主机、端口、userinfo、查询结构解析与 IPv6 处理 | MIT OR Apache-2.0 |
| zeroize | 1.8.2 | 是 | parser 候选 credential 的临时内存零化；PC-03 已使用 | MIT OR Apache-2.0 |
| sha2（仅 dev/test） | 0.10.9 | 是 | 测试 Vault mock 的 credential_id；PC-03 同版本 | MIT OR Apache-2.0 |

以上均已是 main 基座锁中现存 package；PC-06 仅为新 crate 声明直接依赖，`Cargo.lock` 对基座的新增外部 package delta 为 0，物理新增仅 16 行 `protocol-parser` workspace member 引用。

## 替代方案

1. 手写 URL/percent/base64/JSON：会把编码边界错误重新实现到 PC-06，且缺少 URL 对 IPv6/userinfo 的既有验证，不采纳。
2. `reqwest` 内置订阅下载：已由 H2 否决；会新增 TLS/C provider、HTTP3 传递依赖和三平台 C 编译要求。
3. 仅 std + 共享依赖：Cargo 不允许直接使用未声明传递依赖；若删除声明，编译失败或需要修改既有共享 crate，超出卡面。

## 三平台与安全影响

- Windows x86_64：无新增系统工具或 C 编译链。
- Android aarch64：所用 package 均为 Rust，走既有 NDK/Rust target；不新增 aws-lc/CMake/clang 要求。
- Linux x86_64：不新增 host C build dependency；URL/JSON/编码均为 Rust。现有 `secure-store` 的 Linux libc 行为保持不变。
- 未改变 PC-06 既有 1 MiB 输入上限、SecretStore staging 与 Zeroizing 边界。
- `--locked --offline` 三平台实际 check 已通过。

人类已批准本申请。PC-06 可将 `ad37056` 与 `319fdaf` 交付复核；仍不合并、不推送。
