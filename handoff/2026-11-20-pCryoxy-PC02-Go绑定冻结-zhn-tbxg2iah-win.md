# PC-02：PC-04 Go 绑定输入冻结

项目: pCryoxy
状态：输入已冻结；生成、无漂移和输出摘要待 PC-04 实测，未完成审核
授权：共享提交 `e327511`；认领登记 `0ca9abf`。
代码基座 `1e18654ca2a60e8f76c114c891648037d155c336`；
冻结提交 `3bb31ad6856eb43b8e45143461abcd876888c514`；
分支 `agent/copilot/pc02-go-freeze`；
工作树 `C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc02-go-freeze`。
仅变更 `crates/plugin-xray/proto.lock`，不改 proto、descriptor、PC-03 或 PC-04 文件。
该提交已推送项目 origin 分支；不是 PC-04 实现或最终审核。

## 冻结输入与工具

`proto.lock` 原有全部 8 个文件的 SHA-256 本机核对一致。Go 绑定的直接输入为：

| 路径 | 大小 | SHA-256 |
|---|---:|---|
| `native/xray-bridge/core_control.proto` | 2,125 | `219b73833e9d369e5a47f6aa0ff16648d210b20b448e7a8dc461b263b17e6a33` |
| `crates/plugin-xray/proto/common/serial/typed_message.proto` | 473 | `e0d8b7fdc4557eae7c628130d909ad648e89f2f7bab68f44bdf8ddae08e1c711` |
| `crates/plugin-xray/proto/descriptor.pb` | 9,607 | `7aa1dc216b86f9ee871ce080b84a884064e2aa7842054167bb96ccc3bf04123b` |

保留原锁定 descriptor 命令和 proto_path 顺序，重新生成的 descriptor 摘要一致，退出 0。
`protoc` 位于 `~\.agent-tools\venvs\copilot\protoc-29.5-win64\bin\protoc.exe`，
版本 `libprotoc 29.5`，可执行文件 SHA-256
`13c57dc96adf35391ad2a23b5993f514cef83e7faee7f6bcd5628da07fd68a54`。
锁中原有发行包摘要标记 `local-observed`，不声称官方签名验证。

隔离缓存离线构建的 Windows 插件位于本会话
`~\.copilot\session-state\16845d49-d5b4-494a-a1cd-caa481a4004e\files\pc04-generator-prep\`：

| 插件及实测版本 | 文件大小 | 文件 SHA-256 | Go module sum |
|---|---:|---|---|
| `protoc-gen-go.exe v1.36.12` | 8,042,496 | `809e8cdce2230b37ab158774ec589bf1b9e429252b0641dbc8eb898e29b504b9` | `h1:pJOKDDOyeXErUroCihFAd5LQuwXBSpVnKGrj5o/fwxc=` |
| `protoc-gen-go-grpc 1.6.2` | 7,715,328 | `d8345001d89b72a48eea486354447ca6c8128ebab48ffdc319612a6310468051` | `h1:rgSNvqscFZ1JgV/4wH5GOsZFSFkR2Eua9As3KIr2LlM=` |

来源分别为 `google.golang.org/protobuf@v1.36.12`、
`google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.6.2`；`go mod verify` 退出 0。
模块缓存位于上述目录的 `module-cache`。完整模块图为该目录 `module-graph.txt`
（426 边，SHA-256 `2a497b35979cd9594d654b6227f9107fe7c7d41dcff8d4a6be9da81af2eda46a`），
与既有审计图比较退出 0；该路径是本机会话证据，不是共享仓文件。
工具普通依赖仅 protobuf 和 grpc 生成器模块；测试图另含 go-cmp、
x/net、x/sys、x/text、genproto/rpc 和 grpc，详情见同目录 `tool-*-packages.txt`。
这不是 PC-04 桥最终运行时闭包的审核。

## 固定生成参数

在 PC-04 工作树根目录，显式指定以上两个已核验插件，按 `proto.lock` 的
`goBindings.command` 参数调用 Windows `protoc`，其中：

- `--proto_path=crates/plugin-xray/proto` 在前，`--proto_path=native/xray-bridge` 在后；
- 仅输入 `native/xray-bridge/core_control.proto`；
- `--go_out=native/xray-bridge`、`--go-grpc_out=native/xray-bridge`；
- 两者均用 `paths=source_relative` 及
  `Mcore_control.proto=gitee.com/ParvaUltra/pCryoxy/native/xray-bridge;bridge`；
- 不为 Xray 递归 imports 生成 Go 文件；该 import 的 `go_package` 已在冻结 proto 中。

执行时需把两个生成器分别以 `--plugin=protoc-gen-go=<已核验绝对路径>`、
`--plugin=protoc-gen-go-grpc=<已核验绝对路径>` 传给 `protoc`；绝对路径仅是本机工具位置，
不是源码或产物的可移植路径。命令参数在锁文件中逐项记录，PowerShell 中含分号的参数须作为单个字符串传入。

proto 实际 RPC 与原锁定列表一致：`/pcryoxy.bridge.v1.Control/QueryState`、
`ReplaceRoutes`、`ReloadGeo`、`Rollback`、`QueryOperation`、`ReleaseRollbackPoint`
（后五项同前缀）；检查 6 项、退出 0。

## 下一步和边界

PC-04 可按此冻结输入生成两份 Go 文件并在隔离目录再生成一次，记录完整实际命令、
退出码、大小、SHA-256 和无漂移。PC-02 所有者随后串行补记输出摘要；PC-04 单独报告
Go 依赖图和测试。生成失败、descriptor/proto 摘要变化或出现未申请模块时停止。
当前尚未生成绑定，未完成桥编译、真实核心测试或 Linux 桥资产；不标 done。

挂起快照：pCryoxy 无 suspended；PC-03、PC-04 仍 doing/blocked。
prnmgt S2、S3 suspended，S1 已由人类解挂；pRayShell closed。不得跨项目擅自解挂。

## 生成与输出锁定（2026-11-20 17:42 UTC+8）

PC-04 按上述冻结参数生成两份文件；PC-02 所有者在独立分支补充大小和摘要，
项目提交 `90aa591ac82b4a7006887f2c781ac6f20baf5e82` 已推送并核对 origin。
工作树中的绑定文件当前尚未由 PC-04 提交。

| 输出 | 大小 | SHA-256 |
|---|---:|---|
| `native/xray-bridge/core_control.pb.go` | 32,541 | `f6e3cf3a4e2ee59656b35ed43d01a3eae29c0167f9c7706a2c72851a7f5bd548` |
| `native/xray-bridge/core_control_grpc.pb.go` | 12,368 | `c151d7d3041bc85251b982b809108c6e359d8e2bd87262096783235345c81df9` |

实际首次及隔离目录第二次 `protoc` 均退出 0，两次 `fc /b` 均退出 0，
六个 RPC 全名核验退出 0；输入及 descriptor 摘要未变化。完整命令及回显位于本机会话
`files\pc04-generator-prep\control-regeneration\generation.log`；该路径不是共享仓文件。
PC-02 所有者另以文件大小与 SHA-256 核对两个实际输出及再生成输出，退出 0。

仅针对生成绑定的隔离 Go 图：`go mod tidy`、`go mod graph`、`go list -deps`
和 `go list -deps -test` 均退出 0；116 条模块图边，普通和测试各 322 条包记录，
新增校验和 0。分析使用指向已核验固定核心源码的会话内绝对 `replace`，
仅为临时核验，不得写入最终项目模块。桥实现的运行时及测试闭包仍须单独核验；
本记录不是 PC-04 桥或 Linux 资产审核通过。
