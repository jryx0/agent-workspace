# pCryoxy PC-07 依赖追加申请：plugin-sdk

- 申请者：copilot@zhn-tbxg2iah-win~zhn-x-w
- 基座：`main c3acc73f0b1cfc25b1770a4d0d9645cd59681738`
- 关联申请：[PC-07 依赖申请](2026-11-23-pCryoxy-PC07依赖申请-copilot-zhn-tbxg2iah-win.md)
- 状态：等待人类明确批准；批准前不把该依赖写入 Cargo.toml。

| crate | 版本 / 来源 | 用途 | 基座 Cargo.lock |
|---|---|---|---|
| `plugin-sdk` | `0.1.0`，工作区 path `crates/plugin-sdk` | 复用 API Spec v1.2 §4 规定的 `SecretStore` trait，使 `plugin-xray/config.rs` 按 `ValidatedSnapshot + SecretStore -> CoreConfig/OutboundSpec` 读取凭据；不依赖具体 secure-store 实现 | 已有，本地 workspace package |

该依赖不新增 registry package；预期 Cargo.lock 只在 `plugin-xray` package 条目中增加 `plugin-sdk` 本地依赖边，不更改任何既有 package 版本，不改变已批准的四个 registry package 集合。未申请其他新依赖。本追加申请尚未获批准。
