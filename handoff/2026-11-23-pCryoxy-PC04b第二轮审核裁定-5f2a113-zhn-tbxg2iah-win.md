# pCryoxy PC-04b 第二轮审核裁定（5f2a113）

- 审核方：workbuddy@zhn-tbxg2iah-win~zhn-x-w
- 时间：2026-11-23 17:05 UTC+8
- 被审提交：项目 `5f2a113e54d64b8ee45ac4593cd4d3bd38ca721d`（分支 `agent/copilot/pc04b`，基座 `451c3cb`）；共享记忆 `10fca45`、`32c04ec`
- 依据：首轮裁定 `handoff/2026-11-23-pCryoxy-PC04b首轮审核裁定-66a1ca4-zhn-tbxg2iah-win.md`（含 §6.1 人类裁定 H1）
- 证据目录：`~/.agent-tools/run/review/pc04b-r2/`

## 1. 结论

**代码通过，有条件通过。** 首轮阻断 B1（Windows 构建回归）已修复，H1 裁定全部落实。结卡前只差一项**仅改测试**的小提交（§4 C1）。PC-04b 保持 doing，暂不合并。

## 2. 审核方独立重跑（`git archive 5f2a113`，独立目录与缓存）

| 项目 | 结果 |
|---|---|
| 固定源码完整 replay（补丁 0001～0013，上游与 bridge 测试普通 + `-race`） | 退出 0；78 个 PASS、0 FAIL、0 数据竞争 |
| 本卡 profile 测试（含 Linux TUN 正向、TUN 必开 sniffing） | 每个普通、`-race` 各通过 1 次 |
| ABI v1 / v2 smoke | 通过 |
| Linux 双缓存 archive | first.a / second.a / 输出均 3,370,584 B，SHA-256 `cbc918f408fa37d11a2ac1644b03fd10ccb73903fc892561606c7e9b6724ba6b`，**与 copilot r11 产物逐字节一致** |
| Windows amd64 archive（Windows 原生 Go 1.27.4，`-mod=readonly`、`GOPROXY=off`） | 通过，3,212,980 B，与 copilot 报告一致；依赖图不含 `proxy/tun`、wintun、wireguard/windows |
| Android arm64 archive（NDK 29，同上离线只读） | 通过，3,377,526 B，与 copilot 报告一致；依赖图含 `proxy/tun` |
| go.mod / go.sum | require 相对 `451c3cb` 仅多 netlink v1.3.1、netns v0.0.5；go.sum 不变；各次构建未改写 |
| Windows 原生 TUN 拒绝测试 | `TestRegisterRuntimeRejectsTUNInboundWithoutMutation` 通过（`FailedPrecondition / unsupported inbound proxy type`，active 哨兵服务保留） |
| Gitleaks | 项目 `66a1ca4..5f2a113`、共享 `da43e82..32c04ec` 均无发现 |

## 3. H1 落实情况（逐条）

1. `proxy/tun` import 与 TUN 校验移入 `restricted_profile_platform_unix.go`（`//go:build !windows`）；`restricted_profile_platform_windows.go` 在 prepare 第一步拒绝 TUN，错误码与既有未纳管拒绝一致。✅
2. Windows 反向测试存在且在 Windows 原生 Go 下实测通过。✅
3. go.mod 只多 netlink/netns，go.sum 不变，未执行改写 go.mod 的 tidy。✅
4. `tests/integration/bridge/profile.md` 写明 P0 Windows 走系统代理、不支持 TUN；共享记忆已登记 Windows TUN 后续卡待办。✅
5. 三平台离线 archive 与新提交完整 replay 证据齐全。✅

## 4. 结卡条件

- **C1（须补，仅改测试）**：Windows 原生跑整个 bridge 包测试时，本卡在 `66a1ca4` 新增的 5 个 profile 测试失败：
  `AllowsLoopbackInboundsAndRouteOutbounds`、`LoopbackSniffingRequirements`、`AllowsExplicitFinalMaskTypes`、`RejectsUnmanagedInboundAndDNSWithoutMutation`、`RegisterRuntimeRejectsUnmanagedFinalMasksWithoutMutation`。
  - 原因：`restricted_profile_test.go:118` 与 `:496` 用 `filepath.Join(string(filepath.Separator), "tmp", …)` 作 Geo 目录，Windows 上得到不带盘符的 `\tmp\…`，被 `valid Geo ID and clean absolute directory required` 先行拒绝，后续断言全部落空。也就是说，Windows 上 socks/http 回环、sniffing、FinalMask 白名单的正反向断言实际没有被验证。
  - 审核方在副本中把两处改为 `filepath.Join(os.TempDir(), …)` 后，Windows 原生 13 个测试全部通过（`logs/wintest-fixturefix.txt`），说明是夹具可移植性问题，不是校验逻辑缺陷。
  - 要求：按上述方式（或 `t.TempDir()`）修夹具，单独提交；Linux 普通与 `-race` 跑一次 bridge 测试，Windows 原生跑一次整包测试（`control_ipc_test.go` 由 replay 脚本注入且仅限 Linux，可排除，须写明）。只改测试文件，archive 产物不受影响，不需要重跑完整 replay。
  - copilot 交付称「Windows 原生 TUN 拒绝测试通过」属实，但未说明只跑了 TUN 一条、整包在 Windows 下有 5 个失败。以后的平台测试证据须写明运行范围。

## 5. 非阻断

- **A1** 共享记忆 16:49 交付条目插在了文件中部（审核方 16:30/16:23 条目之前），copilot 已在 `32c04ec` 追加更正，不改旧记录，处理方式可接受。
- **A2** 审核方自身更正：首轮裁定的记忆条目时间写为 16:30，实际写入早于 16:23 的 H1 人类裁定条目；以 H1 条目 16:23 为准，两条的先后顺序即实际发生顺序。
- **A3** 首轮 §5 的建议仍有效：入站/出站传输层与安全设置白名单后续收窄；交付证据固定包含 Windows 与 Android 构建。

## 6. 下一步

copilot 补 C1 提交并回报提交号 → 审核方核对 diff（仅测试文件）、在 Windows 原生与 Linux 各跑一次 bridge 测试 → 结卡、合并 main、推送 origin。
