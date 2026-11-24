# PC-07 审核记录：Hysteria2 quicParams 映射的核心实测与 TLS 缺口

日期：2026-11-24 09:5x UTC+8　审核方：workbuddy@zhn-tbxg2iah-win~zhn-x-w
对象：copilot 未提交的工作树改动（HEAD c36a26f，`crates/plugin-xray/src/config.rs`、`protocols.rs` 有改动）

## 1. 实测环境

- 固定核心源码：`XTLS-Xray-core-676eaf6`（与 `native/xray-bridge/go.mod` 一致）。
- 构建：Go 1.27.4（隔离工具链）、`CGO_ENABLED=0 GOOS=linux GOARCH=amd64`、`GOPROXY=off`、模块缓存 `~/.agent-tools/cache/pCryoxy/pc04b-gomodcache`。
- 产物：`~/.agent-tools/run/review/pc07-core-verify/xray`，sha256 `5517dabd65eb2ef3ae829584813b0bad26c88b3ec31a15efc12896d69b455e7d`。
- 版本自报：`Xray 26.11.9 (go1.27.4 linux/amd64)`。

## 2. `run -test` 结果（日志 `pc07-core-verify/logs/core-test.log`）

| 用例 | 配置要点 | 结果 |
| --- | --- | --- |
| bbr | `finalmask.quicParams={congestion:"bbr",bbrProfile:"standard"}` | `Configuration OK.` |
| cubic | 同上改 `congestion:"cubic"` | 拒绝：`unknown congestion control: cubic, valid values: reno, bbr, brutal, force-brutal` |
| brutal | 同上改 `congestion:"brutal"`，无 `brutalUp` | `Configuration OK.`（构建期不报错；`dialer.go:207-209` 在 `BrutalUp==0` 时静默改用 BBR） |
| hopInterval | `hysteriaSettings.hopInterval=30` | `Configuration OK.`（未知字段被 JSON 解码静默忽略） |

结论：copilot 的「Cubic/Brutal/hop 拒绝」判断与核心行为一致；`brutal` 与 `hopInterval` 属于**静默降级**而非报错，桥侧必须自行拒绝，不能指望核心拦截。

## 3. 新发现缺口：Hysteria2 缺 TLS 时配置能过、运行必失败

- 核心 `transport/internet/hysteria/dialer.go:327-331`：`tls.ConfigFromStreamSettings` 为 nil 直接返回 `tls config is nil`。
- 实测：`security` 缺省（IR 的 `Security::None`）的 hysteria 出站 `run -test` 仍输出 `Configuration OK.`（`cfg/hy.json`，sha256 `c7a88bb1…`）；补 `security:"tls"` 后同样 OK（`cfg/hy-tls.json`，sha256 `40d2107b…`）。
- IR 侧 `validate_node`（`crates/core-ir/src/validated.rs:764-812`）不校验协议与安全类型组合，`protocol-parser` 只在链接解析时给 hysteria2 默认 `tls`；手工快照或后续入口可构造出 `Security::None` 的 Hysteria2 节点。
- 影响：PC-07 若照现状生成，会产出「`run -test` 通过、实际连接报 `tls config is nil`」的配置，属于假通过。

## 4. 审核结论

- 映射字段与位置正确：`streamSettings.finalmask.quicParams`，`congestion`+`bbrProfile` 与 `infra/conf/transport_finalmask.go:1198-1290` 一致；写入方不涉及 `hysteriaSettings` 的拥塞字段。
- 待补：Hysteria2 必须在生成阶段要求 `Security::Tls`（`Security::Reality`/`None` 拒绝并报节点 ID 与字段），否则不得声称「Hysteria2 配置生成完成」。
- 工作树改动未提交，本轮不构成交付。
