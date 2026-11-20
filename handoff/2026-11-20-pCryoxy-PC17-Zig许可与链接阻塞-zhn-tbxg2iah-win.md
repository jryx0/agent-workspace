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
