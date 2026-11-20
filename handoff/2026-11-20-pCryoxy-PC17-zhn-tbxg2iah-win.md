# pCryoxy PC-17 阻塞交接

- 项目: pCryoxy
- 卡号：PC-17；任务卡 v1.1；状态：doing，实施受阻，未交付审核。
- 执行人：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-20 11:08 UTC+8。
- 输入：需求 v1.1、蓝图 v0.3、任务卡 v1.1、API Spec v1.2；共享审核收尾 `9676950`。
- 基座：`78cf16612b97d0026ea73da429a1b8b51adf0d4c`，已核验包含 PC-01 `3a994011832a3494e6adbceb6b5937830eb8735b` 和依赖 `2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`。
- 现场：`~/source/pCryoxy.wt/copilot-pc17`，分支 `agent/copilot/pc17`；代码未修改，无 PC-17 实现提交。

## 已完成

- 防撞检查通过，认领提交 `7bc4f85bbf8dd307adc3051f4df37a67449d9940`，origin/main 和 backup/main 均核对为该提交。
- 认领前 `tools-scan.sh --check` 和 `proxy-check.sh` 均退出 0。代理检查和双远端同步退出 0；同步回显依次为 origin main `9676950..7bc4f85`、origin tags `Everything up-to-date`、backup main `9676950..7bc4f85`、backup tags `Everything up-to-date`、`双远端推送完成`。
- 源码核验：项目现有可执行目标为依赖 Tauri 的 `pcryoxy`；`core-ir`、`plugin-sdk` 为库。`native/xray-bridge` 只有 `core_control.proto`，不存在桥实现或可构建桥资产；没有 daemon 二进制目标。
- 官方 GitHub release 元数据查询 `gh api repos/XTLS/Xray-core/releases/tags/v26.11.9` 退出 0：`Xray-linux-64.zip` 大小 16,754,078 字节，官方元数据 SHA-256 `b651f7e1d9966ee2c1b1ee1bf8b52c72771824d3065dce96bbc8bcc19ed95f82`，来源 `https://github.com/XTLS/Xray-core/releases/download/v26.11.9/Xray-linux-64.zip`。未下载、未本地验散列、未修改项目锁文件。

## 平台探测与阻塞

- Windows 主机会话只读探测既有 Ubuntu 24.04 WSL2：Linux `6.18.33.2-microsoft-standard-WSL2`、x86_64、glibc 2.39、GNU readelf 2.42、Git 2.43.0。未在 WSL 运行 agent 或建立共享工作区副本。
- Linux `rustc`、`cargo`、`go`、`node`、`cc`、`make` 均未在 PATH 或检查过的常见位置发现；实际构建目标的 Rust target 和编译器不可用。项目锁定 Rust 1.100.0、Go 1.27.4；未安装任何工具，安装须事先申请并登记。
- **blocked：构建工具链缺失。** WSL 可否作为此卡可接受的 Linux 构建证据、如何在不新增 WSL 共享工作区副本和不修改全局配置的情况下提供合规 Linux 工具链，须确认；不能将 Windows 交叉编译称为 Linux 实测。
- **blocked：桥资产及目标不存在。** 用户要求 PC-17 锁定并构建 Linux 桥和最小 daemon/core/bridge 二进制，但桥实现属于须等待 PC-17 的 PC-04，daemon 属 PC-18。本卡禁止实现它们，现有协议与 `core-lock.json` 的 `baseline-declared` 桥版本不构成已构建资产、桥提交或 SHA-256。请 WorkBuddy 明确可验收的先后顺序及允许的真实构建目标，或提供已批准可核验资产；不自行伪造桥、产物或成功结果。
- Linux 最低支持版本、目标 triple、核心资产本地校验、桥版本/commit/资产摘要、构建工具锁、产物摘要和兼容组合均未冻结；supportStatus 不得标 supported。API/桥协议声明分别为管理 API v1 和 `pcryoxy.bridge.v1`，不等于兼容性握手通过。

## 验证等级及未覆盖

仅完成源码核验、环境工具探测及官方资产元数据查询；均非 Linux 编译或产物验证。干净 checkout 无桌面 release 编译、产物大小/SHA-256、二进制动态依赖及 GTK/WebKitGTK/Tauri 排除、Linux 运行、systemd/TUN/路由/代理互通均未执行。无新增依赖、未安装工具、未写入真实凭据；认领增量 gitleaks `protect --staged` 退出 0、无命中。

## 挂起任务（全量快照）

| 项目 | 任务 | 挂起原因 | 解挂前置 | 现场／解挂后动作 | 解挂权 |
|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT；重编卡 | 人类 |

pCryoxy 无 suspended 项；PC-17 是 doing/blocked，不是自行解挂或审核通过。pRayShell 已终止 closed，非 suspended。

## 下一步

请 WorkBuddy 裁定桥及 daemon 与 PC-17 的依赖矛盾，并明确最小真实构建验收对象；请用户确认可接受的 Linux 环境和工具安装授权。PC-03、PC-04 仍须等待 PC-17 审核通过；不提前实施 PC-18、PC-19、PC-20。

## WorkBuddy 裁定（2026-11-20 11:10 UTC+8）

1. 本机 WSL 已确认可作为 PC-17 的 Linux 环境：Ubuntu 24.04.4 LTS、WSL2、x86_64、glibc 2.39；实查时为 Stopped，可按需启动。
2. PC-17 不实现桥或 daemon。当前 `native/xray-bridge/` 只有 `core_control.proto`，无桥实现；当前 workspace 无 `pcryoxy-daemon` target。桥由 PC-04 实现，daemon 由 PC-18 实现，不得伪造资产、commit、SHA-256 或构建产物。
3. PC-17 的独立验收目标改为：Linux 平台矩阵、上游 Xray Linux 核心资产元数据、无桌面依赖审计、Linux 构建入口/工具链记录和可复核的实际构建证据。缺工具时保留 `doing/blocked`，不宣称通过。
4. 工具安装不在本次裁定内；用户授权 WSL 环境，不等于批准 `apt install`、全局 PATH 或其他工具变更。工具需另列清单申请，获批后再执行。
5. 详细裁定见 `handoff/2026-11-20-pCryoxy-PC17验收目标裁定与WSL环境确认-zhn-tbxg2iah-win.md`。PC-03、PC-04 仍须等待 PC-17 最终审核通过。

## 执行方追加：部分基线与剩余阻塞（2026-11-20 11:27 UTC+8）

- 代码部分提交 `95e0efca6770f51b5f1d4e62599ccc042ac4e2f8`，基于 `78cf166`；仅在 `agent/copilot/pc17` 本地分支，未推送，非最终交付。文件为 `contracts/core-lock.json`、`docs/BUILD.md`、`tools/build-linux`。
- 代码锁定 Xray Linux x86_64 上游 zip 的官方来源、大小和 SHA-256。`gh release download v26.11.9 --repo XTLS/Xray-core --pattern Xray-linux-64.zip` 退出 0；本地 SHA-256 及 16,754,078 字节与官方元数据一致，临时包已删除。该 zip 的 Linux libc 兼容性仍未知。
- Windows 已有 Cargo 执行 `cargo tree --locked --offline -p core-ir -p plugin-sdk --edges normal` 退出 0：所选库默认正常依赖树无 Tauri、GTK 或 WebKitGTK；并非 Linux 产物依赖检查。
- WSL `sh -n tools/build-linux` 退出 0；直接执行 `./tools/build-linux` 因缺 `rustc` 按设计退出 10；上述是语法/缺工具路径验证，不是实际编译或成功产物验证。脚本以 Rust 1.100.0、`x86_64-unknown-linux-gnu`、release、`--locked --offline` 构建两个现有库并复核其 SHA-256；锁定文件执行位为 `100755`。真实 release、产物摘要、动态依赖及运行均未覆盖。
- 锁文件 JSON 核对和差异 `git diff --cached --check` 退出 0；代码增量 `gitleaks protect --staged` 退出 0、无命中。未新增项目依赖或安装工具。
- 工具申请准备：官方 Rust 1.100.0 Linux x86_64 GNU 完整包 `https://static.rust-lang.org/dist/2026-11-12/rust-1.100.0-x86_64-unknown-linux-gnu.tar.xz` 官方清单 SHA-256 `98ee6bec240e1cfe944f17e7092412dc5ef6e008484bb668c6936d35a7d15acd`，HEAD 长度 211,225,068 字节；安装占用尚未核实。Rust 用于构建、不是项目运行时依赖，Rust 项目许可证为 MIT/Apache-2.0；包内组件各自许可仍需核查。Linux 还缺 C 编译器和开发头文件；`apt-get -s install --no-install-recommends gcc libc6-dev` 仅模拟，显示 27 个候选包，未安装。非全局的编译器及 sysroot 方案、其完整来源/摘要/许可证/体积和回滚方式尚未确定，不能据此申请或执行安装。
- 当前状态仍 `doing/blocked`，须取得符合裁定的完整工具申请批准或由用户提供已安装的合规 Linux 工具链，再做真实构建；不标交付待审核或 done。

## 非全局 Linux 工具链申请草案（2026-11-20 11:31 UTC+8）

**待 WorkBuddy 审核并由用户批准；本节不是安装授权。** 目标 Ubuntu 24.04 WSL2 / x86_64 / glibc、Rust target `x86_64-unknown-linux-gnu`；只服务本卡既有 `core-ir` 和 `plugin-sdk` release 构建，不是新增项目运行时依赖，不安装 Go、Node、桌面或 WebKitGTK。

| 工具/组件 | 官方固定资产（以下 `R` 为 `https://static.rust-lang.org/dist/2026-11-12/`） | SHA-256（官方清单） | 下载字节 | tar 解压字节估计 |
|---|---|---|---:|---:|
| Rust compiler 1.100.0 | `R` + `rustc-1.100.0-x86_64-unknown-linux-gnu.tar.xz` | `f1d0b1dec81dab6f523cd098507763487b0d4bd7fd2c87582f154128719be03b` | 84,955,936 | 422,562,304 |
| Cargo 1.100.0 | `R` + `cargo-1.100.0-x86_64-unknown-linux-gnu.tar.xz` | `7e29ce07d7c6e92d1826870575ba27d57fff6cb3e754aa57d99099cb88fab35d` | 10,946,408 | 36,781,568 |
| Rust std 1.100.0，GNU target | `R` + `rust-std-1.100.0-x86_64-unknown-linux-gnu.tar.xz` | `4591b6486594ded52ecd6135db95bf9355bbd3ca7a380888b141528bbcf9a5d4` | 31,283,108 | 168,334,848 |
| Zig 0.16.0，作 `zig cc` 编译器/链接器候选 | `https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz` | `70e49664a74374b48b51e6f3fdfbf437f6395d42509050588bd49abe52ba3d00` | 55,478,392 | 373,923,840 |

- 摘要来自 Rust 官方 `channel-rust-1.100.0.toml` 和 Zig 官方 `download/index.json`；体积来自 HTTP HEAD 及只读 XZ 索引。合计下载 182,663,844 字节，tar 流合计 1,001,602,560 字节；不是已核验的实际安装占用，安装、缓存和临时空间需另留余量，完成后实测登记。四个包均尚未下载或本地校验。
- Rust 项目主许可证 MIT/Apache-2.0，Zig 主许可证 MIT；发行包内 LLVM、libc 等组件许可需核对包内文件后完整登记，不假称全部组件只受主许可证约束。两个工具均为构建工具，不进入项目发布产物；最终二进制、链接效果和运行时影响仍待实测。
- 拟放唯一 Windows 侧 `~/.agent-tools/venvs/copilot/linux-tools/` 下，分别以 `rust-1.100.0/`、`zig-0.16.0/` 命名；WSL 只通过 `wslpath` 映射访问该唯一路径，不创建 WSL 侧共享工作区副本。拟设同目录专属 Cargo 缓存及 Zig 缓存，临时文件放本会话目录；不修改全局 PATH、系统包、包源或配置。
- 拟先验证各包 SHA-256，检查官方安装脚本及包内许可后将 Rust 三组件安装到指定 prefix、Zig 解压到指定目录；只在单次构建进程设置 PATH、CARGO_HOME、ZIG_GLOBAL_CACHE_DIR，以及指向 `zig cc` 封装的 `CC` 和 Cargo target linker。该方案的 proc-macro 链接、glibc 和 WSL 驱动器执行兼容性尚未实测，不能保证构建成功；不执行 `apt install`。
- 拟验收：`rustc --version`、`cargo --version`、`rustc --print target-libdir --target x86_64-unknown-linux-gnu`、`zig version`、C 链接试编、`tools/build-linux`、库产物大小/摘要及锁定依赖树；任何失败如实记录。先离线构建，只有明确缺少 `Cargo.lock` 中已有 crate 时，才恢复这些锁定依赖，不新增清单依赖。
- 回滚：先确认无人使用，仅移除本次安装的两个具体版本目录及本次专属缓存/临时文件；不动共享工具、工作区或系统配置。安装成功后按规范追加工具登记、实际版本与占用并提交同步。请审核候选安装位置与工具区规范的一致性、Zig 是否适合作为本卡 C linker、包内许可和空间预算；用户批准具体方案后才执行。

## WorkBuddy 工具链审核（2026-11-20 11:33 UTC+8）

### 1. 安装位置：物理隔离通过，目录分类需调整

- 方案使用 Windows 侧 `~/.agent-tools`，再由 WSL 通过 `/mnt/c/Users/Zhn_X/.agent-tools/...` 访问；不在 WSL 的 `/home/...` 创建第二份 `~/.agent-tools`，符合“工作区不进 WSL”和工具运行环境与共享仓分离的规则。
- 但 `venvs/copilot/linux-tools` 的名称容易被解释为 Python venv；Rust、Cargo 和 Zig 是工具链运行时，不是 Python 依赖。按现有工具登记惯例，建议改为：
  - `~/.agent-tools/runtimes/copilot/linux-x86_64-gnu/rust-1.100.0/`
  - `~/.agent-tools/runtimes/copilot/linux-x86_64-gnu/zig-0.16.0/`
- 专属缓存不得放入 Git 或项目目录，建议使用：
  - `~/.agent-tools/cache/copilot/pcryoxy-linux/cargo/`
  - `~/.agent-tools/cache/copilot/pcryoxy-linux/zig/`
- 构建时只在单次进程注入 `PATH`、`CARGO_HOME`、`ZIG_GLOBAL_CACHE_DIR`、`CC` 和 Cargo linker；不改用户级 PATH、WSL shell profile、系统包源或 Windows 注册表。
- **审核结论：安装位置有条件通过。** 只有按上述运行时目录和专属缓存隔离执行，才可进入安装；不得把它登记成 Python venv，也不得写入 WSL 家目录。

### 2. Zig 0.16.0 兼容性：作为候选 C linker 有条件通过

- 官方 `https://ziglang.org/download/index.json` 明确列出 Linux x86_64 资产：
  `zig-x86_64-linux-0.16.0.tar.xz`，SHA-256 为
  `70e49664a74374b48b51e6f3fdfbf437f6395d42509050588bd49abe52ba3d00`。
- 官方 0.16.0 release notes 列明 Linux 最低内核版本为 5.10；已实查 WSL2 内核为 `6.18.33.2-microsoft-standard-WSL2`，内核版本满足这一门槛。
- Zig 官方定位支持通过 `zig cc` 编译 C/C++；但这不等于已证明本项目的 Rust/C 构建、proc-macro 链接或 glibc 运行兼容。WSL 当前 glibc 为 2.39，仍需实际验证。
- 当前 PC-17 代码目标主要是 `core-ir`、`plugin-sdk` 两个纯 Rust 库；**Zig 不是当前库构建的硬依赖**。不得因为安装 Zig 就把它写入 Cargo 依赖、项目运行时或发布包。
- Zig 只能先作为 C 编译器/链接器候选，不得直接宣称为默认 linker。安装后必须依次验证：
  1. `zig version` 为 `0.16.0`；
  2. `zig cc` 编译最小 C 程序；
  3. 目标为 `x86_64-linux-gnu`，并记录实际 glibc 目标口径；
  4. `readelf -d` / `ldd` 检查动态依赖；
  5. 在单次环境中用 `CC=zig cc` 和 Cargo linker wrapper 实测一次需要 C 链接的构建路径；
  6. 运行 `tools/build-linux`，确认当前纯 Rust 目标在不依赖 Zig 的情况下可构建；
  7. 不能把 C smoke test 通过写成桥、daemon 或 Linux 运行时已通过。
- **审核结论：Zig 0.16.0 有条件批准作为本卡的构建辅助工具，不批准将其作为未经验证的默认 linker。** 若后续实际构建不需要 C 编译，允许不安装 Zig，仅安装 Rust 三组件并完成 PC-17 基线。

### 3. 许可证：主许可证可接受，包内第三方许可仍是安装门禁

- Rust 工具链项目主许可证记录为 MIT/Apache-2.0；Zig 项目主许可证记录为 MIT。两者均为构建期工具，不进入 pCryoxy 发布产物。
- 官方 Zig 下载 JSON 未提供 license 字段；不能仅凭下载 JSON 证明发行归档内所有组件均为 MIT。Rust 和 Zig 发行包可能包含 LLVM、libc、compiler-rt、标准库或其他第三方组件，必须以实际归档内的 `LICENSE*`、`COPYING*`、`NOTICE*` 文件为准。
- 安装后必须生成一份包内许可证清单，至少包含：文件名、组件名、版本（可识别时）、许可证标识和归档相对路径；清单只入工具登记/交接，不把工具二进制或大段许可证源码提交到项目仓。
- **审核结论：许可证条件通过。** 允许按主许可证作为初步方案，但在下载校验后、工具投入构建前完成包内许可证盘点；发现不可接受或无法识别的组件时停止并报告，不得把“主项目 MIT/Apache-2.0”扩写成“整个发行包单一许可证”。

### 4. 预算与安装授权边界

- 方案列出的下载总量约 182,663,844 字节、解压估计约 1,001,602,560 字节；这只是候选包预算，不是实际磁盘占用。安装前需确认临时空间、缓存和最终目录空间；安装后记录实测占用。
- 本审核**不等于安装授权**。仍需用户明确批准具体工具安装；批准范围只能是 Rust 1.100.0 三组件和/或 Zig 0.16.0，按本节路径、哈希、许可盘点和单进程环境执行。
- 不批准 `apt install`、修改系统包源、全局 PATH、WSL 家目录工具副本、Go/Node/桌面/WebKitGTK 或任何未列工具。

### 5. 当前状态

PC-17 继续保持 `doing/blocked`。本审核不产生 PC-17 实现提交、不改变 PC-04/PC-18 的所有权，也不将工具方案视为 Linux 构建通过。详细安装动作须在用户批准后另行执行，并在 `env/toolchain.md`、设备工具清单和项目交接中追加实测记录。

## 执行方追加：安装前许可核查待裁定（2026-11-20 11:52 UTC+8）

- 用户批准 Rust 1.100.0 三组件及 Zig 0.16.0；安装位置、缓存和使用边界以 WorkBuddy 11:33 审核为准。
- Rust 三组件已下载到本会话 `~/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/`，字节数和 SHA-256 均与申请表对应的官方值一致，均尚未安装或运行。Zig 下载较慢，在等待许可裁定时停止并删除了 12,893,953 字节的未完成下载，未取得完整归档。
- 以 `tar -tJf` 和归档内 `rustc/share/doc/rust/COPYRIGHT.html` 只读盘点：该索引列出 1,437 个带许可表达式的外部组件，0 个缺失许可字段；其覆盖整个 Rust 工具链发布所使用的源码/依赖，不可直接推断每个条目均被此卡链接或实际打包。
- 需 WorkBuddy 明确可接受性及适用范围的示例：`gccjit-6.1.0` 与 `gccjit_sys-3.2.0` 标为 `GPL-3.0`，`inferno-0.12.6` 标为 `CDDL-1.0`；该索引均标 `In libstd: No`，归档路径未发现含上述组件名的文件，但这不证明它们未被静态链接。另有 `r-efi` 和 `r-efi-alloc` 的 `MIT OR Apache-2.0 OR LGPL-2.1-or-later` 可选许可表达式。
- Rust 编译器归档顶层 `LICENSE-APACHE`、`LICENSE-MIT`、`COPYRIGHT`；`rustc/share/doc/rust/COPYRIGHT.html` 和 `COPYRIGHT-library.html` 为组件/版本/许可索引，`rustc/share/doc/rust/licenses/` 含 Apache-2.0、MIT、LLVM-exception、GPL、ISC、BSD 等许可证文本。Cargo 归档的 `LICENSE-THIRD-PARTY` 列出 OpenSSL、libgit2、libssh2、libcurl 等第三方及各自许可文本；完整逐项许可盘点尚未完成。Rust std 归档顶层有 `LICENSE-APACHE`、`LICENSE-MIT`。
- 未判断上述特殊许可证能否接受，也未把源索引等同实际二进制物料清单。按安装前许可门禁，请 WorkBuddy 审核这些条目及 Cargo 许可，明确许可盘点的可接受口径；Zig 完整归档、包内许可和 smoke test 尚未核验。完成裁定前不安装、不执行工具，PC-17 保持 `doing/blocked`。
