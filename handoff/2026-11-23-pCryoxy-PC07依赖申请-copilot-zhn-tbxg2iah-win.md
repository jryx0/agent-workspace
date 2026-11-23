# pCryoxy PC-07 依赖申请

- 申请者：copilot@zhn-tbxg2iah-win~zhn-x-w
- 基座：`main c3acc73f0b1cfc25b1770a4d0d9645cd59681738`
- 状态：等待人类逐项批准；批准前不修改任何 `Cargo.toml` 或 `Cargo.lock`。
- 范围：PC-07 `plugin-xray` 的 IR 映射、配置 JSON 序列化和官方 TypedMessage protobuf 编码。

## 直接依赖申请

| crate | 固定版本 / 来源 | 用途 | 基座 `Cargo.lock` |
|---|---|---|---|
| `core-ir` | `0.1.0`，工作区 path | 读取 `ValidatedSnapshot`、Node、协议与路由 IR；不得绕过已验证 IR 构造配置 | 已有，本地 workspace package |
| `serde` | `=1.0.229`，启用 `derive` | 以强类型配置结构序列化，避免通用 raw JSON 逃逸 | 已有 |
| `serde_json` | `=1.0.154` | 生成固定核心 JSON 配置及验证序列化结果 | 已有 |
| `prost` | `=0.14.6` | 按 `crates/plugin-xray/proto/common/serial/typed_message.proto` 的官方字段编码 TypedMessage；不把 JSON 放入 `value`，不引入 build.rs/protoc | 不存在，新增 |

## 预期锁文件传递项

| crate | 版本 | 用途/来源 | 基座 `Cargo.lock` |
|---|---|---|---|
| `prost-derive` | `0.14.6` | `prost` 的默认 `derive` feature | 不存在，新增 |
| `itertools` | `0.15.0` | `prost-derive` 的传递依赖 | 不存在，新增 |
| `either` | `1.19.0` | `itertools` 的传递依赖 | 不存在，新增 |
| `bytes` | `1.12.2` | `prost` 的传递依赖 | 已有 |
| `anyhow` | `1.0.104` | `prost-derive` 的传递依赖 | 已有 |
| `proc-macro2` | `1.0.107` | derive 宏传递依赖 | 已有 |
| `quote` | `1.0.47` | derive 宏传递依赖 | 已有 |
| `syn` | `2.0.119` | derive 宏传递依赖 | 已有 |

上述传递版本按当前公开 crate 元数据与基座锁文件核对；实际解析结果须在批准后验证。预期新增 registry package 为 `prost`、`prost-derive`、`itertools`、`either` 四项。未申请 `prost-build`、网络客户端、运行时、TLS 或其他协议 crate。

## 尚待裁定的接口/文件范围阻塞

1. PC-07 要求覆盖出站 FinalMask 白名单，但基座 `core-ir/src/node.rs:316` 的 `FinalMaskOption` 只有 `None` 和 `Header`，`protocol-parser/src/validate.rs:810` 当前恒返回 `None`；`tests/integration/bridge/profile.md:21` 也明确记载白名单 FinalMask 对 P0 IR 不可达、需后续卡承接。要从 IR 表达并生成这些变体，可能需要修改 PC-07 文件清单之外的共享接口。此申请不包含该接口变更；须先由契约所有者审核并获准后才能实施。
2. PC-07 允许文件列出 `src/{config,protocols,capabilities}.rs`，但未列 Cargo crate root `src/lib.rs`。此申请不包含 `lib.rs`；须先确认新增该文件是否获准，或指定卡面允许的 crate-root 方案。

本文件只提交依赖与范围问题供审核，不代表任何依赖或文件范围已获批准。
