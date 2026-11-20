# pCryoxy PC-17 交付待审核

- 项目: pCryoxy
- 卡号：PC-17；版本：实施任务卡 v1.1；当前状态：交付待审核。
- 执行人：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-20 14:43 UTC+8。
- 输入：需求 v1.1、工程蓝图 v0.3、API Spec v1.2；WorkBuddy 对验收目标裁定 `7bc4f85` 后的正式交接、Rust 放行 `e77caef`、Zig 工具及链接裁定 `fe88cf0` / `5c7847e`，最终提交单次复测授权 `123193a`。
- 基座：`78cf16612b97d0026ea73da429a1b8b51adf0d4c`；包含 PC-01 `3a99401`、依赖 `2ccffd0` 和 PC-02 `78cf166`。PC-00、PC-01、PC-02 审核通过；PC-17 验收目标调整见历史交接 `handoff/2026-11-20-pCryoxy-PC17-zhn-tbxg2iah-win.md`。
- 项目提交：`1e18654ca2a60e8f76c114c891648037d155c336`（包含前序 `95e0efca6770f51b5f1d4e62599ccc042ac4e2f8`）；分支 `agent/copilot/pc17`，worktree `~/source/pCryoxy.wt/copilot-pc17`；跟踪文件无未提交改动。
- 文件：`contracts/core-lock.json`、`tools/build-linux`、`docs/BUILD.md`。未改共享权威正文、Cargo 根清单或 Cargo.lock。

## Linux 矩阵与资产

| 字段 | 实测/状态 |
|---|---|
| 环境 | Ubuntu 24.04.4 LTS WSL2，x86_64，glibc 2.39；目标 `x86_64-unknown-linux-gnu`。这是一次 WSL 环境，不是最低发行版或最低 glibc 版本证明。 |
| 工具 | Rust/rustc/cargo 1.100.0；Zig 0.16.0 仅本次显式 linker；GNU readelf 2.42。Go、Node 未用于本次构建；未安装系统 `cc`。 |
| 桌面 | 构建两个纯 Rust 库不需要桌面、Tauri、GTK 或 WebKitGTK；目标正常及 build 依赖树和 11 个构建期 ELF 的实际动态依赖均未发现它们。Tauri 可执行目标不在本卡。 |
| 核心 | Xray `v26.11.9` / `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`；Linux x86_64 `Xray-linux-64.zip`，官方 `https://github.com/XTLS/Xray-core/releases/download/v26.11.9/Xray-linux-64.zip`，16,754,078 字节，SHA-256 `b651f7e1d9966ee2c1b1ee1bf8b52c72771824d3065dce96bbc8bcc19ed95f82`，本地核验一致；其 libc/ABI 未实测。 |
| 桥 | 声明协议 `pcryoxy.bridge.v1`、版本 `0.0.1`；当前无桥实现或发行资产，桥 commit、Linux 资产来源和 SHA-256 不存在可核实值，由 PC-04 提供，不能伪造。 |
| 管理 API / 兼容 | API 版本 1；平台 `linux`、架构 `x86_64`、libc `glibc`。这只是已知输入，未执行运行时握手；桥和运行时未实现，`supportStatus` 不标 `Supported`，可按契约作为 `Blocked` 处理，不代表已实际返回该字段。 |

## 最终提交单次干净构建

遵照 `123193a`：构建前 HEAD 精确为 `1e18654ca2a60e8f76c114c891648037d155c336`，worktree 干净；删除本 worktree 先前构建的 `target/` 并核对不存在，保留已校验隔离缓存。构建后跟踪文件仍干净、`target/` 已生成；没有新增 Cargo 依赖、未修改公共锁文件。

单进程的 `PATH` 指向临时 `cc` wrapper、隔离 Rust bin 与系统 `/usr/bin:/bin`；`CC` 和 `CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER` 指向该 wrapper，wrapper 调用已登记的 Zig `cc -target x86_64-linux-gnu`；`CARGO_HOME`、`ZIG_GLOBAL_CACHE_DIR` 和链接日志限定在 `~/.agent-tools/cache/copilot/pcryoxy-linux/` 或本会话临时目录。未更改永久 PATH、Cargo 配置或系统工具。

实际执行 `./tools/build-linux`，其调用：

```sh
cargo build --locked --offline --release --target x86_64-unknown-linux-gnu \
  --target-dir "$root/target" -p core-ir -p plugin-sdk
```

实际退出 **0**；脚本内 `sha256sum -c` 两项均 OK。仅执行了获准的一次最终提交复测。

| 产物（相对 worktree） | 类型 | 大小（字节） | SHA-256 |
|---|---|---:|---|
| `target/x86_64-unknown-linux-gnu/release/libcore_ir.rlib` | ar 格式 Rust 库 | 809,112 | `8389d5fc5fc77435643eef2012eb216e3349a1cbee41491ec5be1d0141d4be52` |
| `target/x86_64-unknown-linux-gnu/release/libplugin_sdk.rlib` | ar 格式 Rust 库 | 3,443,972 | `46bb3920f2263e62cdca35088c438b926401bb69d31b1f16dea9e3c44d7a9109` |
| `target/x86_64-unknown-linux-gnu/release/SHA256SUMS-pcryoxy-libraries` | 两库摘要文件 | 247 | `b0a91e7c37740af9181c491dafd9dd590e5c0cebefe6db7facd26c0f6bf364de` |

`file` 检查退出 0；独立 `sha256sum -c` 退出 0。`Cargo.lock` 前后 SHA-256 均为 `3e698bce0b5a664426302483b12ffa09ec911bb52287d1b575dbb5ceba52c119`。两个库的摘要与同环境前一干净构建一致；这不是跨机器可复现性或发布物 L3 证明。

## 验证等级及结果

1. **源码核验：** 无桥/daemon 实现，`core-lock.json` 的桥字段为基线声明；Xray 官方资产 URL、版本、大小和摘要已锁定。
2. **工具链探测：** 隔离 Rust 1.100.0 与 Zig 0.16.0 实测；Zig 安装和许可证据见 `env/toolchain.md`、`handoff/2026-11-20-pCryoxy-PC17-Zig许可与链接阻塞-zhn-tbxg2iah-win.md`。
3. **静态依赖：** `cargo tree --locked --offline --target x86_64-unknown-linux-gnu -p core-ir -p plugin-sdk -e normal,build --prefix none --format "{p} | {l}"` 退出 0；未发现 Tauri/GTK/WebKitGTK。Cargo `UNLICENSED` 项目包标签是清单元数据输出，不作法律结论。
4. **实际编译及产物：** 上述最终提交离线 release 构建、产物存在性与摘要核对退出 0；两个交付库为 `.rlib`，不是运行时 ELF。
5. **构建期动态依赖：** 发现 11 个 ELF（6 个 build script、5 个 proc-macro）；逐个 `readelf -h/-d/-l` 与 `ldd` 共 44 项均退出 0、无未找到依赖。`DT_NEEDED` 并集：`ld-linux-x86-64.so.2`、`libc.so.6`、`libdl.so.2`、`libpthread.so.0`；未见 GUI 依赖。这些是本机构建过程物料，不是项目发布运行时。
6. **入口分支测试：** `sh -n tools/build-linux` 退出 0；4 个独立模拟用例：缺 `cc`→10、编译失败→20、产物缺失→30、模拟成功→0，测试退出 0。模拟测试不是实际项目编译证据。
7. **独立 Linux 运行：** Zig C 和独立 Rust linker smoke 均可在该 WSL 运行，记录见 Zig 交接；不是 pCryoxy 运行测试。
8. **未覆盖：** Linux 最低版本、核心 libc/ABI、真实桥与 daemon、实际兼容性握手、systemd、TUN、路由、DNS、Web、代理互通、独立设备与最终产品 L3；均不得称为通过。

最终构建日志、11 个 ELF 详细检查、依赖树和链接输入保留于 `~/.copilot/session-state/16845d49-d5b4-494a-a1cd-caa481a4004e/files/pc17-zig-smoke/` 的 `project-final-build.log`、`project-final-elf.log`、`project-final-dependency-tree.txt`、`project-final-link-logs/`。日志包含本地路径，不复制到发布物。

## 依赖、脱敏与后续

- **项目新增依赖：0。** Build-only 工具新增 Zig 0.16.0，官方包 55,478,392 字节、安装文件表观合计 357,913,169 字节；根 MIT，归档另含 LLVM、libc 及 GPL/CDDL/LGPL 等原始声明，见 `handoff/2026-11-20-pCryoxy-PC17-Zig-SPDX路径-zhn-tbxg2iah-win.tsv`。本地构建用途获条件放行，最终分发、实际静态成员及 LGPL 等义务仍须独立 L3 审查。
- 对基座到项目提交执行 `gitleaks git --log-opts='78cf16612b97d0026ea73da429a1b8b51adf0d4c..1e18654ca2a60e8f76c114c891648037d155c336' --no-banner`：2 个提交、退出 0、无命中；未记录真实节点、订阅或凭据。
- PC-18 需要已审核桥资产、daemon 实现、目标平台和 L3 输入；PC-19 需要后续系统服务、TUN 和路由实测。PC-03/PC-04 必须等待 WorkBuddy 审核 PC-17，不因本交付自动放行。
- 审核方为 WorkBuddy；本交付不自行标记 done 或通过。

## WorkBuddy 审核结论（2026-11-20 14:51 UTC+8）

### 结论

**PC-17 审核通过，状态改为 `done / 待集成`。** 审核对象为项目提交 `1e18654ca2a60e8f76c114c891648037d155c336`，不是共享交接提交。代码仓已核对：该提交位于 `agent/copilot/pc17`，基于 `78cf166`，包含前序 `95e0efc`；相对基座的变更范围为 `contracts/core-lock.json`、`tools/build-linux`、`docs/BUILD.md`，未改 Cargo 根清单或 Cargo.lock。

### 通过项

1. **Linux 环境矩阵**：Ubuntu 24.04.4 LTS / WSL2 / x86_64 / glibc 2.39、Rust target `x86_64-unknown-linux-gnu`、Rust 1.100.0 和 Zig 0.16.0 均有记录；明确未宣称最低发行版或最低 glibc 支持。
2. **上游核心资产锁定**：Xray v26.11.9、commit、Linux x86_64 资产 URL、大小和 SHA-256 已锁定并本地核验；核心 libc/ABI 仍标未实测，符合边界。
3. **无桌面依赖审计**：`core-ir`/`plugin-sdk` 正常及构建依赖树、11 个构建期 ELF 的动态依赖均未发现 Tauri、GTK、WebKitGTK；未把 Tauri 可执行目标冒充无桌面目标。
4. **构建入口与工具链**：`tools/build-linux` 使用固定 target、release、`--locked --offline`，并显式检查 host `cc`；精确最终提交已在干净 worktree 完成一次构建，退出 0，两个 `.rlib` 和摘要文件存在且哈希校验通过，`Cargo.lock` 前后 SHA-256 一致。
5. **证据分级与状态**：实际构建、产物、构建期 ELF、依赖树、模拟入口测试、C/Rust linker smoke 和未覆盖项分开记录；桥/daemon/运行时握手/systemd/TUN/路由/Web/代理互通/最低 Linux 版本/L3 均未被写成通过。
6. **安全与边界**：相对基座到 `1e18654` 的 gitleaks 审查退出 0、无命中；未新增项目依赖、未修改公共锁文件，未将 Zig wrapper、工具缓存或 smoke 产物放入仓库/产品。

### 非阻塞说明

- `docs/BUILD.md` 保留了“实际结果来自 `95e0efc`”的历史说明；最终提交 `1e18654` 的复测结果已在本交付文档及构建日志中单独记录，故不构成审核阻塞。后续如维护构建文档，建议补一句最终复测提交号以避免读者将历史首测与最终复测混淆。
- `core-lock.json` 的 Linux `abi` 仍为 `unknown`，Xray 核心 libc/ABI 未实测；这正是当前平台基线的限制，不影响本卡直接验收，但禁止将 Linux supportStatus 标为 `supported`/`ready`。

### 放行与后续边界

- PC-17 直接交付已通过；可进入代码仓集成/合并流程，具体合并由代码仓所有者按协作规则执行。
- 本审核不批准 PC-17 代做 PC-04 桥、PC-18 daemon、PC-19 systemd/TUN/路由或 PC-20 Web/Token；不批准最终运行时或安装包 L3 分发。
- PC-03/PC-04 的前置状态应在项目登记中按“PC-17 已审核通过、代码待集成”更新，不因本审核虚构桥或 daemon 资产。

## 挂起任务全量快照

- pCryoxy：无 suspended；PC-17 为交付待审核。
- prnmgt：S1 T-059/T-060/T-061、S2 P0 二次真机调研、S3 v4 / #18 保持 suspended，未触碰。
- pRayShell：closed，未触碰。

## 交付记录双远端同步实测

共享交付提交 `81e750586629d6cbc0cf7bf68e24fd7ecc19e5c8` 定向暂存三份本卡文件，`gitleaks protect --staged --no-banner` 退出 0、无命中。推送前 `proxy-check.sh` 退出 0，两个远端均为 `123193a`，本地领先。随后执行 `./env/git-sync.sh` 退出 0，实际回显如下：

```text
[sync] 推送 origin (Gitee 主库) ...
remote: Powered by GITEE.COM [1.1.23]
remote: Set trace flag ab423f89
To https://gitee.com/ParvaUltra/agent-workspace.git
   123193a..81e7505  main -> main
Everything up-to-date
[sync] 推送 backup (GitHub 备份库) ...
To https://github.com/jryx0/agent-workspace.git
   123193a..81e7505  main -> main
Everything up-to-date
[sync] 双远端推送完成。
```
