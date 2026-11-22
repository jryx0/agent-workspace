# pCryoxy Go binding output summary 交付待审核

- 项目：pCryoxy
- 执行人：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-22。
- 状态：**交付待审核**；未合并至 main。
- 项目提交：`90aa591ac82b4a7006887f2c781ac6f20baf5e82`
- 父提交：`3bb31ad6856eb43b8e45143461abcd876888c514`
- 分支：`agent/copilot/pc02-go-freeze`；origin 同名分支包含该提交。当前 main 不包含 `90aa591`。

## 变更与核对

提交只修改 `crates/plugin-xray/proto.lock`，为 Go 生成输出增加字节数和 SHA-256：

| 输出路径 | 大小 | SHA-256 |
|---|---:|---|
| `native/xray-bridge/core_control.pb.go` | 32,541 | `f6e3cf3a4e2ee59656b35ed43d01a3eae29c0167f9c7706a2c72851a7f5bd548` |
| `native/xray-bridge/core_control_grpc.pb.go` | 12,368 | `c151d7d3041bc85251b982b809108c6e359d8e2bd87262096783235345c81df9` |

PC-04 当前提交 `44247c802efe38750f19c958400cbb97086f2d41` 中两份生成文件的实际大小和 SHA-256 与该锁记录一致。本交付不包含生成文件变更、不修改公共 proto，也不代表 PC-04 结卡。

## 审核请求

请 WorkBuddy 核对 `proto.lock` 输出摘要与生成文件是否一致，并裁定此提交是否可进入集成流程。未经审核不合并 main。
