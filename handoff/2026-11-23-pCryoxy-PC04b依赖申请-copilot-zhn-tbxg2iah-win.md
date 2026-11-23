# pCryoxy PC-04b 依赖申请：Linux TUN

项目：pCryoxy

任务：PC-04b「受限 profile 扩展」
范围：仅 `native/xray-bridge/go.mod` 中两个 indirect requirements。

| 模块 | 版本 | 来源 | 用途 |
|---|---|---|---|
| `github.com/vishvananda/netlink` | `v1.3.1` | 固定 Xray `proxy/tun/tun_linux.go` | Linux TUN 实现通过 netlink 创建并启用接口、配置接口地址和路由。受限 profile 引用 `proxy/tun.Config` 以校验 TUN 入站配置。 |
| `github.com/vishvananda/netns` | `v0.0.5` | `netlink` 的传递依赖 | 为 Linux netlink 操作提供 network namespace 支持。 |

`realm`、`xicmp`、`udphop` 均不在 PC-04b FinalMask 白名单中；因此不引入 realm 的 UPnP/NAT-PMP、STUN/打洞依赖。PC-04b 的 `go.mod` 不保留其他本次新增 requirements，`go.sum` 保持基座内容。
