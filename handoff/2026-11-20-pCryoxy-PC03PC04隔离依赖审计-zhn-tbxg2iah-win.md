项目: pCryoxy
任务: PC-03 / PC-04 候选依赖隔离审计
状态: 两卡 doing / blocked；证据待审核，不是实施或依赖批准
授权依据: 共享提交 `63acbad3afed73f363edc28697d743230c60f0e4`

# 隔离审计交接

## 基座和边界

- 两个工作树的 HEAD 均为 `1e18654ca2a60e8f76c114c891648037d155c336`，均包含 PC-02 `78cf166`；检查时工作区干净。PC-03：`~/source/pCryoxy.wt/copilot-pc03`、`agent/copilot/pc03`；PC-04：`~/source/pCryoxy.wt/copilot-pc04`、`agent/copilot/pc04`。项目主仓 main 尚未合入基座，不能误写为已集成。
- 本次仅在项目外隔离目录解析和缓存公开归档；没有将依赖安装到项目、修改项目源码或公共清单/锁/proto、安装系统工具、正式构建、执行测试、生成桥资产或部署。缓存存在不等于批准，以下均为候选证据。
- 前置核验、完整工具和测试矩阵见 [PC-03 前置缺口](2026-11-20-pCryoxy-PC03前置缺口-zhn-tbxg2iah-win.md)、[PC-04 前置缺口](2026-11-20-pCryoxy-PC04前置缺口-zhn-tbxg2iah-win.md)。

## PC-03：候选 Cargo 图

- 临时 manifest 指定 `aes-gcm =0.10.3`（默认 features 加 `zeroize`）、`hmac =0.12.1`、`sha2 =0.10.9`、`zeroize =1.8.2`、`getrandom =0.3.4`；Windows `windows-sys =0.61.2` 加 Win32_Foundation/Security/Security_Credentials/Storage_FileSystem；Linux/Android `libc =0.2.191`；Android `jni =0.21.1`。使用隔离 Cargo home 和 Rust/Cargo 1.100.0；临时空 lib 仅供解析，不构建。
- `cargo generate-lockfile` 退出 0；`cargo fetch --locked --target` 对 `x86_64-pc-windows-msvc`、`x86_64-unknown-linux-gnu`、`aarch64-linux-android` 各退出 0；首次 Android `cargo metadata --offline` 因缺跨平台 `winapi-util` 退出 101；之后 `cargo fetch --locked` 全目标补齐退出 0，三个 `cargo metadata --format-version 1 --locked --offline --filter-platform <target>` 均退出 0。
- 详见 [PC-03 全锁清单](2026-11-20-pCryoxy-PC03候选依赖审计-zhn-tbxg2iah-win.json)：59 个外部包，归档 SHA-256 与临时 lock 核对 59/59，归档总 12,299,591 字节；其中三目标解析节点去重 45 包，Windows 27、Linux 26、Android 43；另 14 包在临时锁但不在三目标解析节点。每行含原始许可声明、来源、特性、依赖边的 kind/target、归档字节/摘要及按文件名匹配的 LICENSE/COPYING/NOTICE/COPYRIGHT 路径和文件摘要。Rust 解压/缓存合计约 120,359,589 字节（含注册索引等）；产品安装和产物增量未知。
- `cesu8 1.1.0` 无 LICENSE/COPYING/NOTICE 文件，含 `COPYRIGHT-RUST.txt`；README 表示含 Rust 改编代码并引用 `LICENSE-RUST.txt`，该归档未含此文件，需核对再裁定。`jni-sys-macros 0.4.1` 归档无许可证文件，但 `.cargo_vcs_info.json` 标记上游提交 `64d77b7a5f119d7b55b4e2c169a4668067ff59e6`，该提交仓库根存在 `LICENSE-APACHE`（Git blob `8f71f43fee3f78649d238238cbde51e6d7055c82`）和 `LICENSE-MIT`（`2008402b8a1299cf118ea38e02116bfcc72e53c3`）；这不改变归档缺文件事实。锁内非三目标包 `r-efi 5.3.0` 也无上述文件名证据。原始 `Apache-2.0/MIT` 等声明不擅自规范化；文件名匹配并非法律许可判断。
- metadata 目标节点含解析图，不直接证明最终构建或运行时链接，也不含尚未存在的 secure-store 与完整项目依赖；最终 normal/build/dev 取舍、许可证义务、nonce 与事务方案均待审。

## PC-04：固定上游候选 Go 图

- 固定 Xray `676eaf66f8f05d4d558ee7a74b4736623d3feeb9` 的 GitHub 源码 tar.gz 1,318,088 字节，SHA-256 `3932cefeF227439f569eb3988ca206b505467be075967a4397452a3ffe9ef033`；仓库根声明 MPL-2.0。隔离 Go 1.27.4、`GOENV=off`、`GOWORK=off`、`GOTOOLCHAIN=local`；全程未使用项目模块缓存。
- 首次 `go mod graph` 直连公开 Go proxy 超时退出 1；进程级代理下重试 `go mod graph` 退出 0（426 条边），`go mod download -json all` 退出 0（167 个模块归档，均有 Go `h1` 和 `go.mod` sum，无模块 Error）。归档总 174,422,512 字节；隔离模块缓存含解压和索引等约 915,448,398 字节，不能当作产品增量。
- 分 `GOOS/GOARCH=windows/amd64,linux/amd64,android/arm64`、`CGO_ENABLED=0`，离线 `go list -e -deps -json -mod=readonly ./...`、`go list -e -deps -test -json -mod=readonly ./...`、`go list -e -deps -json -mod=readonly tool` 各目标均退出 0；逐包检查无 Error/DepsErrors。各目标为普通图 48 模块、相对普通图新增测试模块 4、工具图 2；三目标普通图并集 50、含测试并集 54。工具模块可与其他集合重叠。这里只列包元数据，未运行测试或编译。
- [PC-04 模块归档清单](2026-11-20-pCryoxy-PC04候选依赖审计-zhn-tbxg2iah-win.tsv) 逐项记录版本、Go h1、go.mod h1、zip SHA-256 和大小、平台普通/测试相对分类、工具图目标及归档 LICENSE/COPYING/NOTICE 文件路径与摘要；[模块图](2026-11-20-pCryoxy-PC04模块依赖图-zhn-tbxg2iah-win.txt) 保存原始 426 条模块边。`github.com/chzyer/logex@v1.1.10` 归档没有匹配许可文件，该模块不在以上三个目标的普通/测试图；其精确 tag 的 GitHub 根目录也未发现许可证文件，仍需核查。根目录 License API 的 `NOASSERTION` 与 `?` 见之前 PC-04 交接。
- Go 模块并不普遍提供可机器读取的 SPDX 字段；本次归档文件盘点**不是**逐模块 SPDX 法律核准：对于未能可靠辨认或未核对具体文件内容者，SPDX 与义务仍未定，尤其 NOASSERTION、子目录、多许可证、工具和仅模块图选入项。Go 下载成功和 h1 是 Go 校验/元数据证据，另列的 zip SHA-256 是复核摘要，不代替许可审查。
- `./...` 是固定上游源码默认 build tags 的宽口径包图，不是尚未实现的桥实际导入、真实链接、补丁后或其它 build tags 的闭包；`CGO_ENABLED=0` Android 只证明元数据可解析，不证明可编译或运行。两条上游 `tool` 声明为 protobuf 和 gRPC 代码生成工具。最终桥依赖、补丁和核心资产仍未知。

## 缺口和下一步

1. WorkBuddy 分别裁定候选版本/features、三平台许可证文件缺口与 obligations，补足 Go 逐模块 SPDX/子目录证据，再分别审批依赖、工具和代码实施；本交接不请求或假定已获批准。PC-00 所有者先单独审核和串行维护必要的公共清单/锁；PC-02 所有者先裁定事务/公开契约。
2. PC-03 需 Android 真机、Windows 服务身份与 ACL、Linux 异账户/重启测试条件；候选密码学与密钥不可用、原子提交、篡改拒绝及脱敏测试仍未实施。
3. PC-04 缺 Linux Go/C/race 的可用工具及许可；真实核心 route/Geo/override 同一视图、并发线性化、Linux 桥二进制和资产核验均未实施。不得加入 SetAdmission 或新流拒绝门禁。
4. 两卡保持 doing / blocked；完成本阶段后暂停，等待 WorkBuddy。不得以隔离包图或缓存代替产品构建、平台运行、真实核心验收。

## 挂起任务（当前全量快照）

| 项目 | 任务 | 挂起于/裁决 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认；2026-11-19 暂时不做 | 厂家后台升级中 | 升级完成、复跑探测、更新调研文档 | 调研文档已入库 | 续跑不重开卡 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07；2026-11-19 暂时不做 | 纸张口径未定 | S2 结论、D-5~D-10 裁定、新 ADR | 仅 DRAFT 方案 | 重编卡后认领 | 人类 |

pCryoxy 无 suspended；两卡做前置审计但均 blocked。prnmgt S1 已由人类解挂，T-059/T-060 已完成，T-061 状态以最新项目登记为准；pRayShell closed。上述与本任务无关，未触碰。
