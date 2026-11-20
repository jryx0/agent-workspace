# PC-17 Zig 许可与 Linux 链接阻塞

项目: pCryoxy
卡号: PC-17
状态: doing/blocked，未交付审核
执行方: copilot@zhn-tbxg2iah-win~zhn-x-w

## Linux 构建实测

- 项目基座和部分实现：`agent/copilot/pc17`，`~/source/pCryoxy.wt/copilot-pc17`，提交 `95e0efca6770f51b5f1d4e62599ccc042ac4e2f8`；构建前 worktree 无跟踪文件改动、`target/` 不存在。Rust 放行依据共享提交 `e77caef`。
- Ubuntu 24.04 WSL2，Rust 1.100.0，目标 `x86_64-unknown-linux-gnu`；单进程指定已登记 Rust 路径和 `CARGO_HOME=~/.agent-tools/cache/copilot/pcryoxy-linux/cargo`，执行既有 `./tools/build-linux`（release、`--locked --offline`）。
- 第一次退出 **20**：隔离缓存没有锁定的 `idna 1.1.0` 索引。随后从本机通用 Cargo 缓存只复制项目 `Cargo.lock` 中锁定的 430 个 crates.io 归档及对应索引到专用缓存；每个归档 SHA-256 与锁文件一致，缺失及不匹配均为 0，共 62,656,745 字节。没有复制 Cargo 凭据或用户配置，没有增加依赖或修改锁文件；注册表索引配置仅含 crates.io 官方下载/API 地址。
- 第二次退出 **20**：已开始编译，`quote`、`serde` 等构建脚本报 `linker cc not found`；没有完成两个目标库构建、没有可核验的最终库摘要。WSL 实探 `cc`、`gcc`、`clang`、`make` 缺失，`ld`、`ar`、`readelf` 存在；`crt1.o`、`crti.o`、`libc.so` 缺失，glibc 运行库 `libc.so.6` 存在。
- 同一隔离环境执行 `cargo tree --locked --offline --target x86_64-unknown-linux-gnu -p core-ir -p plugin-sdk -e normal,build --prefix none --format "{p} | {l}"` 退出 **0**。该目标依赖声明主要为 MIT、Apache-2.0 和 Unicode-3.0 等；项目自身两个包显示 `UNLICENSED` 是 Cargo 元数据输出，不推断法律状态。树不是实际链接或发布包 SBOM。
- 此处只有失败的实际编译尝试及静态依赖树；Linux 成功构建、产物、动态依赖、运行和 systemd/TUN/互通均未验证。

## Zig 官方归档初步盘点

官方资产 `https://ziglang.org/download/0.16.0/zig-x86_64-linux-0.16.0.tar.xz`，大小 55,478,392 字节，SHA-256 `70e49664a74374b48b51e6f3fdfbf437f6395d42509050588bd49abe52ba3d00`，已复核；工具归档位于本会话专用临时目录。版本/平台为 Zig 0.16.0、Linux x86_64；尚未安装，所有归档文件的安装状态为否。

Python 标准库 `tarfile` 只读遍历退出 0：19,546 个常规文件、1,286 个目录、无符号链接或硬链接；常规文件合计 357,913,169 字节。按文件名识别到 16 个 `LICENSE`/`COPYING`/`NOTICE`/`COPYRIGHT` 类路径（包含一个名为 `copyright.h` 的头文件，不必然是独立许可证）；只检查部分文本类型的前 4,096 字节共发现 46 种原始 SPDX 标记，不能据此断言未列出标记不存在。

| 归档内目录或文件 | 常规文件数 | 许可线索和边界 |
|---|---:|---|
| `LICENSE`、`README.md`、`zig`、`doc/langref.html` | 4 | 根 `LICENSE` 为 MIT；`zig` 二进制内实际 LLVM/其他静态物料、版本和链接关系尚未证实，不能将根许可套用于整个归档。 |
| `lib/build-web`、`lib/c`、`lib/c.zig`、`lib/compiler`、`lib/compiler_rt`、`lib/compiler_rt.zig`、`lib/docs`、`lib/fuzzer.zig`、`lib/init`、`lib/std`、`lib/ubsan_rt.zig`、`lib/zig.h` | 991 | Zig 源码及编译器运行时；归档根 `LICENSE`、逐文件头及组件来源须结合核验，目录级根许可不证明每个文件的第三方组成。 |
| `lib/include` | 241 | 存在原始 `Apache-2.0 WITH LLVM-exception` 标记；LLVM 相关许可另见 `lib/libcxx/LICENSE.TXT` 等。 |
| `lib/libc/darwin`、`freebsd`、`glibc`、`include`、`mingw`、`musl`、`netbsd`、`openbsd`、`wasi` | 16,659 | 平台 libc、头文件及其许可分别看归档内 `lib/libc/freebsd/COPYRIGHT`、`glibc/LICENSES`、`mingw/COPYING`、`musl/COPYRIGHT`、`wasi/LICENSE*` 和各文件标记；不能以单一 MIT 概括。 |
| `lib/libcxx`、`lib/libcxxabi`、`lib/libunwind` | 1,373 | 各自 `LICENSE.TXT` 含 LLVM/Apache 许可与其他声明，原始逐文件标记须保留。 |
| `lib/libtsan` | 278 | LLVM 相关运行时，归档中未发现单独同名 LICENSE 文件；具体组件归属和许可闭包待查。 |

上表合计 19,546 个常规文件；目录计数覆盖归档文件，不代表逐文件许可证归属已完成。

重要原始标记示例（相对归档根路径；仅表示这些文件声明，并非 pCryoxy 产物成分）：

| 原始 SPDX 标记 | 已发现数量 | 示例路径 |
|---|---:|---|
| `Apache-2.0 WITH LLVM-exception` | 1,708 | `lib/include/__clang_spirv_builtins.h` |
| `GPL-2.0 WITH Linux-syscall-note` | 913 | `lib/libc/include/aarch64-linux-any/asm/auxvec.h` |
| `GPL-2.0+ WITH Linux-syscall-note` | 154 | `lib/libc/include/any-linux-any/drm/exynos_drm.h` |
| `CDDL-1.0` | 1 | `lib/libc/include/generic-freebsd/sys/nvpair.h` |
| `((GPL-2.0 WITH Linux-syscall-note) OR CDDL-1.0)` | 2 | `lib/libc/include/any-linux-any/linux/vbox_vmmdev_types.h` |
| `LGPL-2.0+ WITH Linux-syscall-note` | 5 | `lib/libc/include/any-linux-any/linux/comedi.h` |
| `LGPL-2.1 WITH Linux-syscall-note` | 4 | `lib/libc/include/any-linux-any/linux/cgroupstats.h` |
| `LGPL-2.1+ WITH Linux-syscall-note` | 16 | `lib/libc/include/any-linux-any/linux/cifs/cifs_mount.h` |

另见 BSD、ISC、MIT 等原始标记，以及其他 GPL 例外和混合表达式；不得简化 `OR`、`AND` 或例外。以上扫描不是完整 SBOM，也不能排除缺失标记的许可证。Linux 构建调用 Zig 时实际选入的 libc、启动文件、静态库及其分发关系尚未建立，须独立进行 L3 审查。

## 待 WorkBuddy 裁定

1. Rust 已放行但构建缺 `cc`：本机未经安装的 Zig 是否可在补齐何种 L2 证据后，按既有用户工具批准用于独立的 `zig version`、C smoke test、`readelf`/`ldd` 和 glibc 检查？现阶段不使用、不设默认 linker。
2. 请确认上述实际发现的 Zig 归档 GPL/CDDL/LGPL 头文件与现有 build-only 放行规则的关系，以及 Zig C smoke test 和后续库构建的 L3 边界；不将已发现的许可当成未知或自动认定进入 pCryoxy。
3. Zig 完整逐文件许可归属、工具安装登记、smoke test、Linux 实际构建和产物证据未完成。PC-17 保持 `doing/blocked`，PC-03/PC-04 不放行；不代审、不部署。

## WorkBuddy Zig L2、安装与链接范围裁定（2026-11-20 13:07 UTC+8）

### 1. 许可证与 L2 补证口径

1. 本归档中的 GPL/CDDL/LGPL 等不是“未知项”，而是归档文件中已发现的原始许可标记；必须保留原始 SPDX 表达式、例外、`OR`/`AND` 关系和相对路径，不能用根目录 MIT 概括整个 Zig 归档。
2. 当前 19,546 个常规文件、1,286 个目录、16 个许可证相关路径和 46 种扫描到的原始 SPDX 标记，属于**初步 L2 盘点**。扫描只检查部分文本文件前 4,096 字节，不能写成完整逐文件 SBOM；未扫描到不等于不存在。
3. Zig L2 补证采用三层字段，不要求在安装前完成每个文件逐符号归因，但不得裸留或擅自清零未知：
   - `archive-declared`：归档内文件实际声明的许可表达式、路径和计数；GPL-2.0、CDDL-1.0、LGPL 及 LLVM 例外均原样保留。
   - `component-attribution`：按 `libc`、`libcxx/libcxxabi/libunwind`、LLVM/编译器运行时、Zig 自身源文件等组件或目录关联许可证文本、COPYING/NOTICE 路径；无法归属时记 `attribution-unverified`。
   - `selection/linkage`：在 smoke/build 后才判断哪些头文件、启动文件、库或运行时实际被选入；未实测统一记 `not established`，不得从归档存在反推实际链接。
4. L2 补证最小闭环为：完整归档 SHA-256、版本/平台、归档根许可证、许可证相关文件清单、已发现非宽松标记清单、组件归属状态和扫描命令/退出码。完成该闭环即可进入工具安装和独立 smoke 阶段；不要求把全部 19,546 个文件先改写成逐文件 SPDX SBOM。
5. 但若后续实际选入 GPL/CDDL/LGPL 文件、静态库、启动文件或运行时，必须从 L2 转入 L3 单独审查；不得用“build-only 工具可安装”替代产品物料许可结论。

### 2. Zig 安装放行

- **有条件放行隔离安装**：用户先前已批准 Zig 0.16.0，本次归档 SHA-256 与官方值一致，允许按既定路径安装到 `~/.agent-tools/runtimes/copilot/linux-x86_64-gnu/zig-0.16.0/`，缓存使用 `~/.agent-tools/cache/copilot/pcryoxy-linux/`。
- 安装不得改全局 PATH、WSL profile、apt 源、系统包或 Cargo 文件；不得复制到 WSL 家目录作为第二份工具；不得把 Zig 归档或其许可证文件放入 pCryoxy 发布包。
- 安装登记必须补：归档哈希、安装路径、实测版本、文件数/占用、安装命令退出码、`zig version` 退出码和回滚路径。
- 本放行只针对 build-only 工具，不是对 Zig 归档内 GPL/CDDL/LGPL 组件进入 pCryoxy 的许可批准。

### 3. 独立 smoke test 放行

安装完成后，允许执行**独立、显式调用 Zig 的 smoke test**，不把它设为默认 linker：

1. `zig version`：验证版本与目标平台。
2. `zig cc -target x86_64-linux-gnu -c` 最小 C 源：先验证编译器、头文件和对象生成。
3. 在同一隔离目录尝试显式链接最小 C 程序；使用 `readelf -h/-d`、`ldd` 和受控运行验证 ELF、解释器和动态依赖。每条命令记录退出码；失败必须记录真实缺口，不能改写为成功。
4. 若因当前 WSL 缺少 `crt1.o`、`crti.o`、`libc.so` 开发链接输入而链接失败，结论应为“Zig 已安装、C 编译 smoke 通过/链接 smoke 被环境缺口阻塞”，不是 Zig 许可失败，也不得借机安装 apt 或系统工具。
5. 需要验证 Rust linker 适配时，另建最小临时 Rust crate，显式设置本次命令的 `CC`/linker 环境；该测试与 C smoke 分开记录。不得把 `zig cc` 写入全局配置或项目永久配置。

### 4. 后续链接放行边界

- **允许**：在 Zig smoke 通过后，用显式命令和隔离缓存进行临时 linker 试验、对象/测试程序链接，以及为定位 WSL `cc` 缺口而做的最小 Rust linker 试验。
- **有条件允许**：若 Rust linker smoke、`readelf`/`ldd` 和实际输入清单均通过，可将 Zig 作为 PC-17 `x86_64-unknown-linux-gnu` 的一次性候选 linker，用于既有 `core-ir` / `plugin-sdk` 构建验证；仍须 `--locked --offline`，不新增依赖，不修改 Cargo.lock，不宣称 PC-17 完整通过。
- **暂不允许**：将 Zig 设为默认 linker、写入全局或项目永久配置；把 Zig 的 `libc`/启动文件/运行时复制进 pCryoxy 安装包；将任何 GPL-2.0/CDDL-1.0/LGPL 物料静态或动态带入最终产品；或把一次成功链接写成桥、daemon、systemd、TUN、代理互通和发布物料已通过。
- **L3 前置**：任何实际 pCryoxy 运行时链接必须列出实际输入（对象、启动文件、静态库/动态库、解释器、头文件/运行时来源）及许可证关系。出现 GPL/CDDL 时停止对应发布路径；LGPL 或带例外表达式需按实际链接和分发方式另审，不能按宽松许可证自动放行。

### 5. 当前状态

- `25cf629` 的 Zig 归档哈希和初步盘点有效；Zig 尚未安装，未执行 smoke，未作为 linker 使用。
- WSL 缺 `cc`、`gcc`、`clang`、`make` 及开发版启动/链接文件，Rust Linux 构建仍 blocked；本裁定不等于 Linux 构建成功。
- PC-17 保持 `doing/blocked`；PC-03/PC-04 不因本裁定放行。后续执行方可按上述范围先安装 Zig，再提交独立 smoke 证据供复核。

## 挂起快照

- pCryoxy：无 suspended；PC-17 doing/blocked（不是 suspended）。
- prnmgt：S1、S2、S3 保持 suspended，未触碰。
- pRayShell：closed；未触碰。

## 执行方追加：Zig L2 补证（2026-11-20）

依据 `fe88cf0`，补充扫描结果，仍不宣称完整逐文件 SBOM：

1. **archive-declared：** Zig 0.16.0 Linux x86_64 的官方归档、大小、SHA-256、根 MIT 许可与目录计数见上文。完整扫描到的 4,416 条 SPDX 原文标记及其各自相对路径，包括所有本次扫描发现的 GPL/CDDL/LGPL、例外和复合表达式，保存在 `handoff/2026-11-20-pCryoxy-PC17-Zig-SPDX路径-zhn-tbxg2iah-win.tsv`；共 46 种原始标记，不改写其括号或表达式。
2. **许可证相关文件清单：** `LICENSE`；`lib/libc/freebsd/COPYRIGHT`；`lib/libc/glibc/LICENSES`；`lib/libc/include/generic-freebsd/sys/copyright.h`；`lib/libc/mingw/COPYING`；`lib/libc/musl/COPYRIGHT`；`lib/libc/wasi/LICENSE`、`LICENSE-APACHE`、`LICENSE-APACHE-LLVM`、`LICENSE-MIT`；`lib/libc/wasi/fts/musl-fts/COPYING`；`lib/libc/wasi/libc-bottom-half/cloudlibc/LICENSE`；`lib/libc/wasi/libc-top-half/musl/COPYRIGHT`；`lib/libcxx/LICENSE.TXT`；`lib/libcxxabi/LICENSE.TXT`；`lib/libunwind/LICENSE.TXT`。其中 `copyright.h` 是按文件名匹配的头文件，不能仅凭名字当作许可证。
3. **component-attribution：** Zig 自身根许可参见 `LICENSE`；libc 各平台参见各自上述许可和源码标记；libcxx、libcxxabi、libunwind 分别参见各自 `LICENSE.TXT`；LLVM 相关头文件参见源码标记及上述 LLVM 许可文本。`zig` 可执行文件内部组件、`lib/compiler_rt`、`lib/libtsan` 和无法与许可文件直接对应的文件仍为 `attribution-unverified`，不把根 MIT 分配给它们。
4. **selection/linkage：** 尚未安装、未运行 Zig，所有头文件、启动文件、库和运行时的实际选择与链接均为 `not established`；工具归档及安装目录不复制到项目发布物。后续 smoke 或项目产物涉及的实际物料必须另按 L3 判断。
5. **复现：** 执行 `python ~/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/pc17-zig-audit.py`，退出 0；该脚本校验归档 SHA-256、类型/数量、许可证路径和原始标记。加 `--manifest` 生成上述 TSV，退出 0。扫描范围仅为 `.c/.h/.zig/.s/.cpp/.hpp/.txt/.rs`、小于 5,000,000 字节文件的前 4,096 字节；未扫描或无显式标记并不等于无许可。

## 执行方追加：Zig 安装登记（2026-11-20 14:09 UTC+8）

- 用户已批准，`fe88cf0` 有条件放行；L2 补证 `c627e66` 已双远端同步。官方包大小与 SHA-256 见上文，解压前逐项检查无绝对路径、`..`、链接或特殊文件。
- 在 WSL 中将归档 `tar -xJf ... --strip-components=1 -C ...` 解压到 Windows 工具区 `~/.agent-tools/runtimes/copilot/linux-x86_64-gnu/zig-0.16.0/`；解压退出 0。安装目录事前不存在；未写 WSL 家目录副本、全局 PATH 或系统配置。
- 安装后 19,546 个文件共 357,913,169 字节（表观大小）、1,285 个子目录；逐一核对归档与安装文件的 SHA-256，19,546 项、差异 0，退出 0。WSL 显式运行 `<安装目录>/zig version` 输出 `0.16.0`，退出 0。
- 回滚目标仅为上述 Zig 安装目录；未执行回滚。工具登记见 `env/toolchain.md` §五和设备清单；独立 C/Rust linker smoke 与实际链接物料还未验证，未设默认 linker。

## 执行方追加：独立 Zig C / Rust linker smoke 待复核（2026-11-20 14:16 UTC+8）

### 测试环境与命令

- Ubuntu 24.04 WSL2 x86_64、glibc 2.39；Zig 0.16.0 安装登记共享提交 `61c8c0c`，Rust 1.100.0。仅在单进程设置 `ZIG_GLOBAL_CACHE_DIR=~/.agent-tools/cache/copilot/pcryoxy-linux/zig`、`CARGO_HOME=~/.agent-tools/cache/copilot/pcryoxy-linux/cargo`；临时目录为 `~/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/pc17-zig-smoke/`。未改系统或项目 linker 配置。
- C 测试源仅调用 `puts`。`zig cc -target x86_64-linux-gnu -MD -MF smoke.d -c smoke.c -o smoke.o` 退出 0。尝试链接时 `-Wl,--trace`、`-Wl,-Map,smoke.map` 均被 Zig 拒绝，分别退出 1；改用 `zig cc -target x86_64-linux-gnu -v smoke.o -o smoke` 退出 0，详细链接命令见临时目录 `link.stderr`。
- 无依赖的独立 Rust 临时 crate：`cargo generate-lockfile --offline` 退出 0；以临时 `zig-cc` 包装脚本显式调用 `zig cc -target x86_64-linux-gnu -v`，仅本进程设置 `CC` 和 `CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER`，执行 `cargo build --locked --offline --release --target x86_64-unknown-linux-gnu`。第一次因 Windows CRLF 导致包装脚本 shebang 找不到，退出 101；换成 LF 后第二次退出 0，有 Zig 忽略 deprecated linker optimization 的警告。完整链接命令保留在临时目录 `rust-link.log`。

### 产物与运行证据

| 独立产物 | 大小 | SHA-256 | 检查结果 |
|---|---:|---|---|
| C 对象 `smoke.o` | 2,544 | `977e4a49879b358953ed2b0f5973c1febbcff848b8e8882be3ba532ed657a862` | 编译退出 0；`smoke.d` 记录所用 Zig glibc 和 Clang 头文件。 |
| C 程序 `smoke` | 7,904 | `b4d4902a3d4a90633d60fec1f6d3d5c74f8df226ae05fa286a5c840169e7ba31` | `readelf -h/-d/-l/--version-info` 各退出 0，`ldd` 退出 0，运行退出 0；ELF64 x86_64，解释器 `/lib64/ld-linux-x86-64.so.2`，NEEDED `libc.so.6`，版本需求 `GLIBC_2.2.5`。 |
| Rust 程序 `rust/target/x86_64-unknown-linux-gnu/release/pc17-linker-smoke` | 359,856 | `0b5df24999bccf46577fe6baeea7fc1c64326f5bbe380ef69277c14f194232d3` | `readelf -h/-d/-l/--version-info` 各退出 0，`ldd` 退出 0，运行退出 0；ELF64 x86_64 PIE，NEEDED `libc.so.6`、`ld-linux-x86-64.so.2`、`libpthread.so.0`、`libdl.so.2`，最高已观察符号版本 `GLIBC_2.30`。 |

`ldd` 实际解析到本机 glibc 和解释器，两测试输出分别为 `pc17 zig smoke`、`pc17 rust linker smoke`；依赖检查未发现 GTK/WebKitGTK。此仅为 WSL 上的两个独立测试，`GLIBC_2.30` 是该 Rust 测试的符号版本证据，不是已验证的 Linux 最低支持版本。

### 实际命令输入与许可边界

- C 编译 `smoke.d` 记录 29 个头文件路径，来自 Zig 的 `lib/libc/include/generic-glibc/`、`x86-linux-gnu/` 和 `lib/include/`。C 链接命令显式传入测试 `smoke.o`、Zig 缓存生成的 `crt1.o`、`libubsan_rt.a`、glibc 相关 `.so`、`libc_nonshared.a`、`libcompiler_rt.a`；`--as-needed` 使传入并不等于最终选入。
- Rust 链接命令显式传入 `Scrt1.o`、测试对象、Rust 1.100.0 的 `libstd`、`panic_unwind`、`object`、`memchr`、`addr2line`、`gimli`、`cfg_if`、`rustc_demangle`、`std_detect`、`hashbrown`、`rustc_std_workspace_alloc/core`、`miniz_oxide`、`adler2`、`unwind`、`libc`、`alloc`、`core`、`compiler_builtins` 的 `.rlib`，以及 Zig 缓存生成的 `libubsan_rt.a`、`libunwind.a`、`libc_nonshared.a`、`libcompiler_rt.a` 和 glibc 相关 `.so`。完整参数及哈希目录见 `rust-link.log`；静态归档命令行传入不证明每个成员被选入。
- `-v` 日志显示 `Scrt1.o`/`crt1.o` 由 `start-2.33.o`、`abi-note.o`、`init.o` 构成；`libc_nonshared.a` 的构造命令列有 `atexit.o`、`at_quick_exit.o`、`pthread_atfork.o`、`stack_chk_fail_local.o`、`stat` 系列等。Zig 归档中对应 glibc 源路径线索包括 `lib/libc/glibc/sysdeps/x86_64/start-2.33.S`、`csu/abi-note.S`、`csu/init.c`、`csu/elf-init-2.33.c`、`stdlib/atexit.c`、`stdlib/at_quick_exit.c`、`sysdeps/pthread/pthread_atfork.c`、`debug/stack_chk_fail_local.c`；仅按名称关联是候选来源，不是逐对象来源证明。
- 上述 glibc 源文件头包含 LGPL 2.1 及部分特殊例外的线索，须逐项验证实际来源、表达式、选入和分发义务；LLVM 相关组件参见 Zig `lib/libunwind/LICENSE.TXT`、Rust 许可索引。两次测试仅为本地 build-only smoke，未复制到产品；不放行这些输入进入最终产品。

### 待复核

请 WorkBuddy 核对 smoke 及实际输入清单是否满足 `fe88cf0` 的一次性 PC-17 库构建前置，尤其审查 Zig 提供的 glibc 启动文件、`libc_nonshared.a`、LLVM 运行时及其 L3 边界。当前尚未用 Zig 执行 pCryoxy 构建，PC-17 保持 doing/blocked；不宣称桥、daemon、服务、TUN 或运行时通过。
