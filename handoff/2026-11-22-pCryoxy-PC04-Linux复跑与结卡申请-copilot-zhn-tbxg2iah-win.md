# pCryoxy PC-04 Linux replay 与结卡申请

- 项目：pCryoxy
- 卡号：PC-04；按实施任务卡 v1.2 §2 六项验收。
- 执行人：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-22。
- 状态：**doing / blocked，等待 WorkBuddy 对六项清单作最终 done 裁定**；本交接不自行改卡状态，不合并、不部署。
- Worktree：`C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc04`
- 分支：`agent/copilot/pc04`；当前 `HEAD` 与 `origin/agent/copilot/pc04` 均为 `44247c802efe38750f19c958400cbb97086f2d41`，父提交 `2206139fcb86a138b38a10ad43f20f455a99ffaf`；本次未改工作树。

## 精确文件范围

以下为 PC-04 代码分支相对实际共同基线 `1e18654ca2a60e8f76c114c891648037d155c336` 的精确文件清单；合计 50 个新增文件。未修改 PC-02 proto、descriptor、公共 DTO、根 Cargo 清单/锁或 PC-03 文件。

```text
native/xray-bridge/abi/README.md
native/xray-bridge/abi/cmd/main.go
native/xray-bridge/abi/cmd/runtime_v2_linux_amd64.go
native/xray-bridge/abi/cmd/runtime_v2_linux_amd64_test.go
native/xray-bridge/abi/cmd/runtime_v2_shim_linux_amd64.c
native/xray-bridge/abi/fixture/main.go
native/xray-bridge/abi/include/pc04_preflight_v1.h
native/xray-bridge/abi/include/pc04_runtime_v2.h
native/xray-bridge/abi/runtime_v2_design.md
native/xray-bridge/checked_registrar.go
native/xray-bridge/core_control.pb.go
native/xray-bridge/core_control_grpc.pb.go
native/xray-bridge/geo_lifecycle_internal_test.go
native/xray-bridge/geo_reload.go
native/xray-bridge/go.mod
native/xray-bridge/go.sum
native/xray-bridge/ipc_unix_linux.go
native/xray-bridge/ipc_unix_linux_test.go
native/xray-bridge/operation.go
native/xray-bridge/restricted_profile.go
native/xray-bridge/restricted_profile_test.go
native/xray-bridge/route_control.go
native/xray-bridge/runtime.go
native/xray-bridge/runtime_abi_status.go
native/xray-bridge/runtime_lifecycle.go
native/xray-bridge/runtime_registration_test.go
native/xray-bridge/snapshot.go
tests/integration/bridge/control_ipc_test.go
tests/integration/bridge/dns_geo_candidate_test.go
tests/integration/bridge/dns_route_epoch_test.go
tests/integration/bridge/entry_normalization_test.go
tests/integration/bridge/hot_config_test.go
tests/integration/bridge/lua_geo_view_test.go
tests/integration/bridge/pc04_preflight_abi_smoke.c
tests/integration/bridge/pc04_runtime_abi_smoke.c
tests/integration/bridge/profile.md
tests/integration/bridge/replay-linux.sh
tests/integration/bridge/route_view_test.go
upstream-patches/0001-router-reject-unsupported-hot-config.patch
upstream-patches/0002-router-versioned-route-view.patch
upstream-patches/0003-normalize-route-update-entries.patch
upstream-patches/0004-router-pin-lua-geo-view.patch
upstream-patches/0005-router-retained-control-snapshots.patch
upstream-patches/0006-dns-inject-geo-candidate.patch
upstream-patches/0007-router-official-epoch-check.patch
upstream-patches/0008-pin-dns-dispatch-route-view.patch
upstream-patches/0009-verified-scoped-geo-publication.patch
upstream-patches/0010-bind-standalone-dns-to-route-view.patch
upstream-patches/0011-explicit-geo-snapshot-release.patch
upstream-patches/0012-geo-snapshot-reader-lifecycle-test.patch
```

## 执行方最终复跑

为满足 Unix socket UID/目录权限语义，使用 WSL2 Ubuntu 24.04 ext4 scratch；DrvFS 上不能作为该权限测试的证据环境。精确项目提交 `44247c8` 的 clean replay 退出码 0，日志无 NUL：

- 62 个 PASS、0 个 FAIL；普通与 `-race` 测试均通过。
- ABI v1 预检 C smoke：版本、纯校验及 1,024 并发调用通过。
- ABI v2 C smoke：边界校验、失败清理、真实 create/status/close 及 8 线程并发 status 通过。
- 两个独立 `GOCACHE` / `GOTMPDIR` 构建的 Go archive `cmp` 一致；`go.sum` 与锁定输入一致。

干净证据包：`C:\Users\Zhn_X\.copilot\session-state\9c3b77d9-71d5-42cb-8b89-694c4ab7ac59\files\pc04-linux-ext4-final-evidence.zip`，大小 16,693,675 bytes，SHA-256 `3453d8a8343439e0e0dfabb35d902da41603271a8ff5368e315c732c745d6962`。包内 5 项均已按 `hashes.sha256` 逐项核验；重叠运行产生的旧 `replay.log` 未纳入。

| 资产/日志 | 大小 | SHA-256 |
|---|---:|---|
| clean replay `replay-clean.log` | 78,363 | `9352d72e49f671fb62143278746b6f6ffd1606a3540c463322a654aa788074e5` |
| Linux amd64 Go archive `pc04-linux-amd64-clean.a` | 3,189,442 | `8a6d31a78f47e9f16872920247df4457b0c762674a72b401373cbc714ec7abff` |
| clean replay `libpc04_abi.so` | 45,550,112 | `fb459ee38e598acbbe916c4b077e8dd607e3eac09df2e5834d8caa6dfd24e03f` |

固定 Xray 输入归档 SHA-256 为 `3932cefef227439f569eb3988ca206b505467be075967a4397452a3ffe9ef033`；Go `1.27.4`、Zig `0.16.0`；未联网下载、未安装依赖。

### 六项结卡清单

| v1.2 §2 项 | 执行方结果 | 依据/边界 |
|---|---|---|
| ① 受限 profile prepare 校验与拒绝清单 | PASS | `restricted_profile_test.go`、`profile.md` 与 clean replay；拒绝后状态不变 |
| ② Runtime ABI v2 与固定错误码 | PASS | Go ABI 测试及 C ABI v2 runtime smoke |
| ③ 固定核心普通/race replay、双构建一致 | PASS | clean replay 62 PASS/0 FAIL；Go archive 两个独立缓存构建 `cmp` 一致，SHA 与 WorkBuddy 独立复验一致 |
| ④ 单一 epoch / 线性化 / 无 `SetAdmission` | PASS | route epoch 测试通过；桥实现未引入 `SetAdmission` |
| ⑤ Linux 固定资产与桥运行检查 | **部分待裁定** | 固定 Go archive 哈希已复现，ABI v1/v2 smoke 通过；`libpc04_abi.so` clean replay 哈希为 `fb459…e03f`，而另一轮三次独立缓存构建均为 `9c5b…ec70`。差异原因未证实，不作 `.so` 可复现声明。 |
| ⑥ 审核方独立重跑一次 replay | PASS（已完成） | WorkBuddy 对精确 `44247c8` 独立 replay 报 62 PASS/0 FAIL，archive SHA 与本次一致；见 `2026-11-22-pCryoxy-done卡与PC04-ABIv2独立重跑复核及集成建议-zhn-tbxg2iah-win.md` §1。 |

`.so` 是否属于交付物尚未明确。请 WorkBuddy 裁定：若为交付物，F-25 仍未关闭，需先解释/修复可复现性；若仅为 ABI smoke 临时产物，请明确按非交付物处理。未覆盖独立 daemon/生产调用方、systemd、TUN、真实代理互通或部署。

## 审核复跑命令

在 ext4 checkout 的精确提交 `44247c802efe38750f19c958400cbb97086f2d41` 下，以 WSL root 运行；先创建全新的 mode 0700 scratch，并为 artifact output 指定空目录：

```bash
bash tests/integration/bridge/replay-linux.sh \
  /mnt/c/Users/Zhn_X/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/pc04-dependency-audit/xray-676eaf66.tar.gz \
  <fresh-ext4-scratch-root> \
  /mnt/c/Users/Zhn_X/.agent-tools/runtimes/copilot/linux-x86_64-gnu/go-1.27.4/bin/go \
  /mnt/c/Users/Zhn_X/.agent-tools/runtimes/copilot/linux-x86_64-gnu/zig-0.16.0/zig \
  <fresh-artifact-output-directory> \
  /mnt/c/Users/Zhn_X/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/pc04-dependency-audit/module-cache
```

## 基线差异待确认

实际 `git merge-base HEAD origin/main` 为 `1e18654ca2a60e8f76c114c891648037d155c336`；本轮调度提示词写 PC-04 基座为 `2908e4e`。实际分支未基于 `2908e4e`，本轮按提示未变基、未合并。请 WorkBuddy/代码所有者在集成前核对这一差异。
