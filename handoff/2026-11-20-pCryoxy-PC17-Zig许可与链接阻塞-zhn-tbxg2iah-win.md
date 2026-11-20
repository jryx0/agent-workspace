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

## 挂起快照

- pCryoxy：无 suspended；PC-17 doing/blocked（不是 suspended）。
- prnmgt：S1、S2、S3 保持 suspended，未触碰。
- pRayShell：closed；未触碰。
