# pCryoxy PC-04 前置缺口

- 项目: pCryoxy
- 卡号：PC-04；任务卡 v1.1；状态：doing / blocked，未交付审核。
- 执行人：`copilot@zhn-tbxg2iah-win~zhn-x-w`；2026-11-20 15:28 UTC+8。
- 输入：需求 v1.1、蓝图 v0.3、API Spec v1.2、任务卡 v1.1；PC-02 审核通过 `78cf166`、PC-17 审核通过 `1e18654`，项目代码待集成。
- 认领共享提交 `325c6ef66dc74b589c2478c6da62a861f24a6c74`，origin 与 backup 均核对一致。独立 worktree `~/source/pCryoxy.wt/copilot-pc04`，分支 `agent/copilot/pc04`，基座 `1e18654ca2a60e8f76c114c891648037d155c336`。源码尚无改动。
- 用户确认项目代码、测试和配置不得与 PC-03 重叠；共享任务登记允许按规范追加。PC-04 不改安全存储文件，PC-03 不改桥文件，公共清单/锁/契约不在两卡分支争写。

## 固定上游只读核验

- 只读 GitHub API 核验 `XTLS/Xray-core` 提交 `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`、tree `717e944e218f098a8448f1f2f925bb7a8fa02559`；根 LICENSE 声明 MPL-2.0，不据此推断依赖闭包许可。上游 go.mod 声明 Go 1.27 和多项直接/间接依赖，版本以该提交原文件为准；没有下载或安装这些模块。
- 固定版本 `app/router/router.go` 中 rules 与 balancers 为两个独立 atomic 指针，`ReloadRules` 先存 balancers 再存 rules，替换后立即关闭旧 webhook；不能用桥外 mutex、假快照或基于此路径直接宣称跨规则/Geo/override 一致。
- 固定版本 `common/geodata/{ip_registry,domain_registry}.go` 各自拥有 registry 与可独立刷新 matcher；`app/geodata/geodata.go` 支持 cron 且依次调用两个 reload。`app/router/balancing.go` 的 override 在现有 balancer 上独立更改。
- 固定版本 `app/router/command/command.go` 的官方 AddRule/RemoveRule/Override 直接委托 router，官方与兼容服务名共用服务。实际补丁须覆盖真实读写路径及 DNS Geo 消费者，并保留旧 view/资源生命周期；不允许 SetAdmission、新流拒绝门禁或只在 gRPC 外套锁。

## 缺口和请审核

1. 上游源仓和 Go 模块尚未在本项目隔离缓存就绪；固定上游仓库本身为 MPL-2.0，其直接和传递依赖的版本、许可证、下载/安装占用及运行时/编译时关系尚未完成清单。`go.mod/go.sum` 属 PC-04，但新增模块和下载依七条铁律须先申请；请审核固定 Xray 及依赖闭包的获取/构建方案、隔离位置与许可，勿将 Xray 固定版本等同所有传递包自动获批。
2. 现有隔离 Windows Go `go1.27.4 windows/amd64` 可执行；`go env CGO_ENABLED` 返回 `0`，当前 PATH 未发现 `gcc` 或 `cl`，尚未建立可用的 Go race 环境。PC-17 的 Zig 和 Linux Rust 审核授权仅限该卡已消耗的构建，不自动授权此卡构建；所需编译器及 Linux Go 只能另行盘点、申请和登记，不安装系统包。
3. 上游最小补丁、完整候选构造与版本根、受控进程、真实 Geo/routing/override race 与线性化集成、Linux 桥二进制和资产摘要均尚未实施或实测。现有桥 proto 是 PC-02 冻结契约，不改动；`contracts/core-lock.json` 是公共锁，桥资产/patchSet 需要由所有者在审核后串行维护。
4. 请 WorkBuddy 确认上游依赖闭包审计与可用构建环境路径。若本卡发现必须改变公共契约，先提交最小变更给 PC-02 所有者；不凭构建占位模型声称真实核心集成完成。

## 挂起任务全量快照

- pCryoxy：无 suspended；PC-03、PC-04 均已认领 doing，PC-04 本前置缺口 blocked；这不是 suspended。
- prnmgt：S1 T-059/T-060/T-061、S2 P0 二次真机调研、S3 v4 / #18 suspended，未触碰。
- pRayShell：closed，未触碰。

## WorkBuddy 审核记录（2026-11-20 15:33 UTC+8）

审核对象：共享提交 `1a7bdc32768243ca975ddf29690fe6eae597f340`。

结论：**前置缺口登记通过；PC-04 继续 `doing / blocked`，不标 done。**

审核确认：

1. 本提交只新增 PC-03/PC-04 前置缺口交接和项目登记，没有修改 pCryoxy 代码、Go 模块、公共锁、proto 契约、系统工具或桥资产。
2. PC-04 阻塞依据成立：固定 Xray 上游的直接/传递依赖版本、许可证和缓存闭包尚未审核；当前 Windows 环境没有可用 `gcc`/`cl`，不能作为 Go race 验收环境；上游最小补丁、真实受控核心、Geo/routing/override 线性化测试、Linux 桥资产均尚未实施或实测。
3. 固定 Xray 根 LICENSE 为 MPL-2.0 不能替代整个 Go 依赖闭包的许可证盘点；不得把上游固定提交或 `core-lock.json` 声明值写成已取得的桥资产。
4. PC-17 的 Zig/Rust 授权只覆盖已经审核的 PC-17 纯 Rust库构建，不自动扩展到 PC-04 的 Go 编译、race、桥构建或 Linux 资产生成。
5. proto 契约和公共 `contracts/core-lock.json` 保持冻结；如需改变公共契约或锁文件，先交 PC-02/PC-00 所有者审核并串行维护。

本次允许：继续只读上游源码核验、依赖闭包/许可证盘点、补丁设计和测试计划；不允许安装未批准模块或系统包、扩大工具授权、使用占位模型宣称真实核心通过或生成未经审核的桥资产。

本审核不放行 PC-08、PC-12、PC-18、systemd/TUN、运行时、Web 或最终产品 L3。

## WorkBuddy 对 e458886 的审核补充（2026-11-20 15:41 UTC+8）

审核对象：共享提交 `e458886e6662ac23b89ed836ff581a2b3af88a8c`。

结论：**认领范围补充通过；PC-04 继续 `doing / blocked`。**

确认事项：

- `agent/copilot/pc04`、基座 `1e18654ca2a60e8f76c114c891648037d155c336` 和 `~/source/pCryoxy.wt/copilot-pc04` 与既有认领登记一致，不构成重复认领。
- 预计独占文件范围与 PC-03 的安全存储文件不重叠，作为后续实现边界记录有效。
- `go.mod/go.sum`、上游补丁和桥测试属于 PC-04 候选范围，但依赖闭包、许可证、缓存和工具环境仍须先完成审核；预计文件范围不等于下载、安装或构建授权。
- PC-02 的 proto 与公共 `contracts/core-lock.json` 仍不在本卡独占范围；任何公共契约或公共锁变更必须分别经 PC-02/PC-00 所有者串行审核。
- 本补充没有改变此前 `33e3c8c` 的阻塞结论、Go race 环境门槛、真实核心测试要求或 Linux 桥资产边界。

本次不放行 Go 模块安装、系统编译器安装、桥构建、Linux 资产生成或 PC-04 done；仍只允许在既有边界内进行只读盘点、补丁设计和测试准备。

## 只读前置核验（2026-11-20 15:55 UTC+8）

执行人 `copilot@zhn-tbxg2iah-win~zhn-x-w`；依据用户本轮一次性只读授权和 `8fb69c3`；仍为 **doing / blocked**。PC-04 `agent/copilot/pc04` / `~/source/pCryoxy.wt/copilot-pc04` 与 PC-03 独立分支的 HEAD 均为 `1e18654ca2a60e8f76c114c891648037d155c336`，包含 `78cf16612b97d0026ea73da429a1b8b51adf0d4c`；`git status --porcelain=v1 --untracked-files=all` 退出 0 且输出空。主仓 main `152df4eca58d5c663d5e59d6979eea55bbf288ee` 仍不含上述集成；本卡未改项目文件。

### 上游模块与许可证盘点

只读 `gh api 'repos/XTLS/Xray-core/contents/go.mod?ref=676eaf66f8f05d4d558ee7a74b4736623d3feeb9' -H 'Accept: application/vnd.github.raw+json'` 退出 0：固定 go.mod 声明 Go 1.27、35 个直接和 21 个间接模块（不代表实际使用闭包），另列 `protoc-gen-go-grpc` 和 `protoc-gen-go` 工具。用 `gh api 'repos/XTLS/Xray-core/license?ref=676eaf66f8f05d4d558ee7a74b4736623d3feeb9' --jq '[.path,.license.spdx_id,.sha] | @tsv'` 退出 0：根 `LICENSE` / MPL-2.0 / blob `a612ad9813b006ce81d1ee438dd784da99a54007`。

下表为上游 go.mod 的全部 56 个声明条目，非桥模块最终解析图、非实际链接清单。`L` 是只读 GitHub 在**对应 tag 或伪版本 commit**返回的仓库根 LICENSE 检测结果，`?` 表示未核实；根文件不证明子模块/全部文件许可，`NOASSERTION` 原样保留。查询方法：对 GitHub 依赖 `gh api 'repos/<owner>/<repo>/license?ref=<tag-or-commit>' --jq '[.path,.license.spdx_id,.sha] | @tsv'`；伪版本按末尾 commit 查询；非 GitHub 路径未推断仓库。未获取模块归档、未运行依赖解析、未执行 Go 构建。

| 直接模块@版本 | 根许可证 L |
|---|---|
| github.com/apernet/quic-go@v0.61.1-0.20260806010916-184d081eef3e | MIT |
| github.com/bufbuild/protocompile@v0.14.1 | Apache-2.0 |
| github.com/ghodss/yaml@v1.0.1-0.20220118164431-d8423dcdf344 | NOASSERTION |
| github.com/golang/mock@v1.7.0-rc.1 | Apache-2.0 |
| github.com/google/go-cmp@v0.7.0 | BSD-3-Clause |
| github.com/google/uuid@v1.6.0 | BSD-3-Clause |
| github.com/gorilla/websocket@v1.5.3 | BSD-2-Clause |
| github.com/klauspost/cpuid/v2@v2.4.2 | MIT |
| github.com/libp2p/go-nat@v1.0.1-0.20250821073202-01afc089f138 | Apache-2.0 |
| github.com/miekg/dns@v1.1.73 | NOASSERTION |
| github.com/pelletier/go-toml@v1.9.5 | NOASSERTION |
| github.com/pion/stun/v3@v3.1.7 | MIT |
| github.com/pires/go-proxyproto@v0.16.0 | Apache-2.0 |
| github.com/refraction-networking/utls@v1.8.3-0.20261108164504-a13c59ffe98b | BSD-3-Clause |
| github.com/robfig/cron/v3@v3.0.1 | MIT |
| github.com/stretchr/testify@v1.12.1 | MIT |
| github.com/vishvananda/netlink@v1.3.1 | Apache-2.0 |
| github.com/xtls/reality@v0.0.0-20261108101329-4bb46b2afd8b | NOASSERTION |
| github.com/yuin/gopher-lua@v1.1.2 | MIT |
| go4.org/netipx@v0.0.0-20231129151722-fdeea329fbba | ? |
| golang.org/x/crypto@v0.58.0 | ? |
| golang.org/x/crypto/x509roots/fallback@v0.0.0-20261020153306-9f2b28d4331a | ? |
| golang.org/x/exp@v0.0.0-20240506185415-9bf2ced13842 | ? |
| golang.org/x/net@v0.62.0 | ? |
| golang.org/x/sync@v0.24.0 | ? |
| golang.org/x/sys@v0.49.0 | ? |
| golang.zx2c4.com/wintun@v0.0.0-20230126152724-0fa3db229ce2 | ? |
| golang.zx2c4.com/wireguard@v0.0.0-20250521234502-f333402bd9cb | ? |
| golang.zx2c4.com/wireguard/windows@v1.1.1 | ? |
| google.golang.org/grpc@v1.85.0 | ? |
| google.golang.org/protobuf@v1.36.12 | ? |
| h12.io/socks@v1.0.3 | ? |
| layeh.com/gopher-luar@v1.0.11 | ? |
| lukechampine.com/blake3@v1.4.1 | ? |
| mvdan.cc/gofumpt@v0.12.0 | ? |

| 间接模块@版本 | 根许可证 L |
|---|---|
| github.com/google/gopacket@v1.1.19 | NOASSERTION |
| github.com/huin/goupnp@v1.2.0 | BSD-2-Clause |
| github.com/jackpal/go-nat-pmp@v1.0.2 | NOASSERTION |
| github.com/juju/ratelimit@v1.0.2 | NOASSERTION |
| github.com/klauspost/compress@v1.20.1 | NOASSERTION |
| github.com/koron/go-ssdp@v0.0.4 | MIT |
| github.com/libp2p/go-netroute@v0.2.1 | NOASSERTION |
| github.com/molecule-man/go-brrr@v1.2.0 | MIT |
| github.com/pion/dtls/v3@v3.1.5 | MIT |
| github.com/pion/logging@v0.2.4 | MIT |
| github.com/pion/transport/v4@v4.1.0 | MIT |
| github.com/quic-go/qpack@v0.6.0 | MIT（`LICENSE.md`） |
| github.com/vishvananda/netns@v0.0.5 | Apache-2.0 |
| github.com/wlynxg/anet@v0.0.5 | BSD-3-Clause |
| go.yaml.in/yaml/v3@v3.0.5 | ? |
| golang.org/x/text@v0.43.0 | ? |
| golang.org/x/tools@v0.51.0 | ? |
| google.golang.org/genproto/googleapis/rpc@v0.0.0-20260817212433-ac3dfec99bb1 | ? |
| google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.6.2 | ? |
| gopkg.in/yaml.v2@v2.4.0 | ? |
| gvisor.dev/gvisor@v0.0.0-20260122175437-89a5d21be8f0 | ? |

GitHub 检测成功项的文件名均 `LICENSE`（qpack 除外）；NOASSERTION 和 `?` 不能简化为已批准。源码嵌入的其他许可证、模块子目录与实际最终构建图尚未证实；所列 go.mod 依赖可能包含未使用、测试或工具项，也可能遗漏桥实现会新增的模块。**完整传递闭包、每个归档 LICENSE/NOTICE、实际选入及下载/安装/产物大小尚未确定。**

### 工具、缓存与测试条件

- `~/.agent-tools/runtimes/go/bin/go.exe version` 退出 0：go1.27.4 windows/amd64；`go.exe env GOOS GOARCH CGO_ENABLED GOMODCACHE` 退出 0，输出 windows、amd64、0 和默认 `~/go/pkg/mod`。只读检测 `~/go/pkg/mod/cache/download` 不存在；不等于其他独立缓存均无资产，也不等于任何模块已批准。
- `wsl.exe --list --verbose`、Linux `uname -sm`、`getconf GNU_LIBC_VERSION` 退出 0：Ubuntu 24.04.4 LTS WSL2、Linux x86_64、glibc 2.39；只读 `command -v go; command -v gcc; command -v cc; command -v readelf` 仅返回 `/usr/bin/readelf`。Windows PATH 中 `Get-Command cl,gcc` 无结果，不代表未检查到的 VS 路径不存在。PC-17 登记隔离 Zig 文件存在，但其一次性批准已消耗，不能用于本卡；Linux Go、race 所需 C 工具链与使用权限未落实。
- `git -C <pc04-worktree> ls-tree -r --name-only HEAD native/xray-bridge tests/integration/bridge upstream-patches` 退出 0，仅有冻结的 `native/xray-bridge/core_control.proto`。未取得真实受控核心的项目构建及 Geo 测试资产，不存在可供核验的桥二进制或产物 SHA-256。
- `tools-scan.sh --check` 退出 0；Android `adb devices -l` 退出 0 且无设备；不涉及建立服务或变更账户。

### 最小方案和申请

1. 先审核固定上游 56 个声明模块及补丁后的实际可达闭包（包含平台、工具和测试分层）、`NOASSERTION` / 未知模块原始许可文件、MPL 源码分发义务、摘要及下载/占用预算；只读索引不等于授权下载。取得逐项裁定后，再单独授权隔离源码/模块获取、构建工具与 race 环境；禁止全局安装。
2. 经实现许可后才设计并实施实际核心读路径：候选在锁外构造，将 routes、双 Geo 和 override 绑定同一不可变 view；发布锁只核对版本并切换指针；管理 RPC 与兼容服务共用提交器；DNS Geo 纳管、独立 cron 停用、旧 view 生命周期受控；script/domainStrategy 热变更明确拒绝。不得加入 SetAdmission 或新流拒绝门禁。
3. 隔离真实核心的验收矩阵须独立验证路由与两类 Geo 和 override 并发、每次 route 单 epoch、prepare/publish 失败不变、旧 view 无旧磁盘依赖、慢 DNS/webhook 不持锁、管理旁路拒绝、无递归锁死；另给 `go test`、`go test -race`、线性化结果、Linux 桥运行及产物摘要。缺任一真实条件标未覆盖，不把模型或 mock 当实证。
4. proto/公共核心锁由 PC-02/PC-00 所有者审核串行维护；本阶段未安装模块/工具、未改任何源码、未构建桥、未运行正式测试或生成资产，等待依赖、工具和实现分别裁定。

### 挂起快照更正

pCryoxy 无 suspended；两卡 doing/blocked。prnmgt S1 已由人类解挂，T-059 已认领（见 `memory/projects/prnmgt.md` 最新记录）；S2 真机调研与 S3 v4/#18 仍以原快照为准，未触碰。pRayShell closed；旧交接中 S1 suspended 为历史快照。

## WorkBuddy 对 f0b722d 的复核与下一阶段授权（2026-11-20 16:07 UTC+8）

审核对象：共享提交 `f0b722d31d47d63b0aa98c30e7e5e666facb8c3d`。

结论：**只读前置核验通过；PC-04 仍为 `doing / blocked`。允许进入“隔离依赖/许可证证据获取”阶段，不放行代码实施、Go 模块安装或系统工具安装。**

复核确认：

1. PC-04 worktree 的 HEAD、分支、祖先关系和清洁状态已记录；主仓 `main` 尚未集成 `1e18654`，没有把分支现场误写成项目已集成。
2. 固定 Xray 的 56 个 go.mod 声明条目已被逐项登记为上游声明，不等同最终解析图或实际链接清单；`NOASSERTION` 与 `?` 均被保留，未误标为已批准。
3. 根 LICENSE 的 MPL-2.0、GitHub license API 结果和 go.mod 声明不足以替代实际模块归档、子目录许可证和补丁后可达闭包；该缺口仍是有效阻塞。
4. 当前无 Linux Go/race/C 工具链，Windows `gcc`/`cl` 未在已检查 PATH 中发现；PC-17 一次性 Rust/Zig 授权不应扩展到 PC-04。
5. 本次只读核验未下载模块、未安装工具、未修改代码/公共锁、未构建桥、未运行正式测试，证据边界记录正确。

### 现在允许的最小范围

仅允许在项目外的隔离审计目录中：

- 获取固定 Xray 提交对应的 Go module metadata、源码归档或模块归档，用于核对实际版本、SHA-256、`LICENSE*`/`COPYING*`/`NOTICE*` 和许可证原文；
- 按目标平台、build tags、正常/测试/工具依赖分层，生成临时 module graph 和候选闭包清单；
- 标记 `NOASSERTION`、未知仓库、缺失归档、补丁新增依赖和无法确认的实际链接关系；
- 输出“候选闭包审计”交接，供 WorkBuddy 和 PC-00/PC-02 所有者再次审批。

### 仍禁止

- 不得把临时 `go.mod`/`go.sum` 或 module cache 写入 pCryoxy 项目；
- 不得修改公共 proto、`contracts/core-lock.json` 或其他公共锁；
- 不得下载或安装正式 Go 模块到项目缓存；
- 不得安装 gcc、cl、Linux Go、系统包、Android 工具或服务；
- 不得实施上游补丁、构建桥、生成 Linux 桥资产或执行真实核心验收；
- 不得以本阶段证据标记 PC-04 done。

完成闭包审计后必须暂停，另行申请：隔离模块获取/缓存、Go/race 工具链、上游补丁实施和桥代码实施授权。

## WorkBuddy 对 109dabe 的复核与下一阶段裁定（2026-11-20 16:31 UTC+8）

审核对象：共享提交 `109dabea100cfc1758d83978e778874943cbce8f`。

结论：**PC-04 候选 Go 图审计材料通过采信；不等于项目模块、工具或桥实现批准。PC-04 继续 `doing / blocked`。**

已采信证据：

- 固定 Xray 源码归档、摘要、Go 校验和、426 条模块边以及 167 个模块归档均有隔离审计记录。
- Windows/Linux/Android 目标的普通、测试和工具图已分层；普通图、测试图和工具图没有被混写成最终产品闭包。
- `NOASSERTION`、未知许可证和归档缺文件项均被保留；未将 Go 下载成功或 h1 校验和解释为许可证批准。

尚未满足项目模块/桥实施批准的缺口：

- `./...` 宽口径图不是尚不存在的桥实际 import graph；补丁后的可达闭包、真实桥代码依赖和最终选入仍未知。
- `github.com/chzyer/logex@v1.1.10` 未发现匹配许可证文件；其余模块仍有 `NOASSERTION`、未知仓库、子目录许可证和多许可证义务待核。
- Linux Go/race/C 工具链未具备；没有真实桥构建、真实核心读路径、Geo/routing/override 线性化或资产 SHA-256 证据。

### 下一阶段授权

允许 PC-04 在项目外隔离审计目录中做**定向许可证和候选闭包补证**：

- 对普通目标图中的模块优先补齐精确归档许可证原文、子目录许可证、摘要和分发义务；测试/工具图必须单独标记，不得混入运行时闭包；
- 对 `chzyer/logex`、`NOASSERTION`、未知仓库和补丁可能新增依赖逐项给出 `license-evidence-status`；
- 在不写入项目的前提下，形成“上游候选依赖闭包”与“桥实现新增依赖待定项”两张清单。

仍不允许：

- 修改项目 `go.mod`/`go.sum`、公共 proto 或 `contracts/core-lock.json`；
- 将隔离 module cache 写入项目或安装正式 Go 模块；
- 安装 gcc、cl、Linux Go、race 工具或系统包；
- 实施上游补丁、编写桥、构建桥、生成 Linux 资产或执行真实核心测试；
- 以 426 条模块边、167 个归档或 `go mod download` 成功替代实际桥闭包和许可证批准。

定向缺口补齐后暂停，等待 PC-00/PC-02 对公共锁和契约的裁定，再申请工具、依赖和代码实施授权。

## 用户范围变更与 WorkBuddy 授权调整（2026-11-20 16:38 UTC+8）

用户明确裁定：pCryoxy 当前仅内部使用，不对外销售、不商用、不对外开源；不再反复进行许可证核查。

据此调整：

1. `109dabe` 中 Go 模块的 `NOASSERTION`、未知许可证、`chzyer/logex` 缺少许可证文件等状态，继续作为来源和审计记录保留，但**不再阻塞当前内部开发、依赖获取、本地构建或 PC-04 实施**。
2. 不把这些条目改写成“许可证已确认”或“对外分发已批准”；当前范围下不再重复逐模块追审，也不要求为内部构建反复补齐发行 SBOM。
3. 如果未来改为销售、商用、对外发布、开源或安装包离开当前内部范围，必须在发布前重新开启 L3/许可证审查。

### 当前可执行授权

- PC-04 可基于现有固定 Xray 候选图进入桥实现准备，不必再次重复许可证审计。
- 允许在明确的隔离缓存和已登记工具范围内获取当前内部开发所需 Go 模块；不得写入其他项目、全局模块缓存或对外发布物。
- 如需修改公共 proto 或 `contracts/core-lock.json`，仍须由 PC-02/PC-00 所有者串行审核；不得以内部使用范围绕过公共文件所有权。

### 未解除的技术门槛

- Linux Go/race/C 工具链仍未具备，工具安装或新增工具链必须另行申请；PC-17 的一次性 Rust/Zig 授权不自动扩展到 PC-04。
- 真实桥代码、上游最小补丁、真实核心 route/Geo/override 线性化测试、Linux 桥资产和 SHA-256 仍未完成。
- 不得加入 SetAdmission 或新流拒绝门禁；不得用 mock/模型替代真实核心验收。
- PC-04 继续 `doing / blocked`，阻塞原因从许可证审计转为工具链、实现和真实测试条件，不得标 done。
