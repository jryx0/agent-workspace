# pCryoxy PC-03 前置缺口

- 项目: pCryoxy
- 卡号：PC-03；任务卡 v1.1；状态：doing / blocked，未交付审核。
- 执行人：`copilot@zhn-tbxg2iah-win~zhn-x-w`；2026-11-20 15:28 UTC+8。
- 输入：需求 v1.1、蓝图 v0.3、API Spec v1.2、任务卡 v1.1；PC-02 审核通过 `78cf166`、PC-17 审核通过 `1e18654`，项目代码待集成。
- 认领共享提交 `325c6ef66dc74b589c2478c6da62a861f24a6c74`，origin 与 backup 均核对一致。独立 worktree `~/source/pCryoxy.wt/copilot-pc03`，分支 `agent/copilot/pc03`，基座 `1e18654ca2a60e8f76c114c891648037d155c336`。源码尚无改动。
- 用户确认项目代码、测试和配置不得与 PC-04 重叠；共享任务登记允许按规范追加。PC-03 不改桥文件，PC-04 不改安全存储文件，公共清单/锁/契约不在两卡分支争写。

## 现场与缺口

1. 已审基座根 Cargo workspace 只有 `core-ir`、`plugin-sdk`、`tauri-app`；不存在 `crates/secure-store/Cargo.toml` 和安全存储源文件。需 PC-00 所有者经审核后串行增加 `secure-store` crate 清单、workspace 成员及必要公共锁文件变更，不能在 PC-03 分支擅改公共清单。
2. `plugin-sdk` 已有 `SecretStore::put` 和 `with_secret`；卡面还要求暂存、提交与删除的原子语义。现有 trait 没有这些方法：PC-03 可评估在自己的实现上提供而不更改冻结公共契约；若需改 trait，必须先交 PC-02 契约所有者审议，不自行改签名。
3. 需要认证加密、HMAC、密码随机数、密钥清理及平台 API；不能自己实现密码学或在缺依赖时写成功形占位。只读候选信息，均**未批准、未安装、未写入清单**：

| 候选 | 用途 | 拟用版本 | 上游声明许可 | 压缩包大小 | 状态 |
|---|---|---|---|---:|---|
| RustCrypto `aes-gcm` | Windows/Linux vault AEAD | 0.10.3 | Apache-2.0 OR MIT | 148,991 字节 | registry 元数据；正常依赖含 aead、cipher、ctr、ghash、subtle、可选 aes；闭包、安装与产物影响未核。 |
| RustCrypto `hmac` | 凭据内部标识 | 0.12.1 | MIT OR Apache-2.0 | 42,657 字节 | registry 元数据；需配 SHA-256，闭包未核。 |
| `zeroize` | 缩短密钥缓冲驻留 | 1.8.2 | Apache-2.0 OR MIT | 20,907 字节 | registry 元数据；不保证清除所有副本。 |

上述为直接候选的归档大小，不是总下载量、安装占用或发布增量；须先核验完整依赖闭包、平台特性、许可和许可义务并报 WorkBuddy 审核、用户批准。现有锁与隔离缓存已有 `sha2 0.10.9`、`windows-sys 0.61.2`、`jni 0.21.1`、`libc 0.2.191`、`getrandom 0.3.4`；缓存存在不等于 PC-03 直接依赖已获批准。Android Keystore 仍须实际验证 JNI/生命周期，不通过替换为模拟实现掩盖。
4. 已登记隔离 Windows Rust `rustc 1.100.0` / `cargo 1.100.0` 可用；`adb devices -l` 退出 0 但无设备，Android Keystore 真机持久化与重启验收当前无法执行。Windows 服务身份 / ACL、Linux 异账户拒绝和真实服务重启亦尚未验证，涉及账号或系统配置须另行明确授权。

## 请审核/授权

- 请 WorkBuddy 审核 PC-03 的平台密钥归属、无 GUI Linux 0600 与目录属主检查、Windows 用户和服务身份边界、AES-GCM nonce/密钥丢失处理、事务写入设计，以及上列候选与完整传递依赖清单；不得将本候选表当作已批准方案。
- 核准后由 PC-00 所有者在独立维护分支提交经批准的最小 Cargo 清单和锁变更，再由本卡基于该提交实施；若契约需改变，先由 PC-02 契约所有者审核。
- 真机、服务和异账户条件另行提供或授权；缺失项保持 blocked，不标 done。

## 挂起任务全量快照

- pCryoxy：无 suspended；PC-03、PC-04 均已认领 doing，PC-03 本前置缺口 blocked；这不是 suspended。
- prnmgt：S1 T-059/T-060/T-061、S2 P0 二次真机调研、S3 v4 / #18 suspended，未触碰。
- pRayShell：closed，未触碰。

## WorkBuddy 审核记录（2026-11-20 15:33 UTC+8）

审核对象：共享提交 `1a7bdc32768243ca975ddf29690fe6eae597f340`。

结论：**前置缺口登记通过；PC-03 继续 `doing / blocked`，不标 done。**

审核确认：

1. 本提交只新增 PC-03/PC-04 前置缺口交接和项目登记，没有修改 pCryoxy 代码、Cargo workspace、Cargo.lock、公共契约、系统工具或平台凭据。
2. PC-03 阻塞依据成立：当前基座缺少 `secure-store` crate 与源文件；事务 API 是否需要改变冻结契约尚未解决；密码学依赖闭包、许可证和锁文件变更尚未审批；Android 真机、Windows 服务身份/ACL、Linux 异账户与重启场景尚未完成实测。
3. `aes-gcm`、`hmac`、`zeroize` 仅作为未批准候选，不视为依赖授权、许可证批准或已安装资产；不得在本卡分支自行写入公共清单或 Cargo.lock。
4. PC-00 所有者必须先以独立提交维护 workspace/锁文件；如需改变 `SecretStore` 公共 trait 或 DTO，先交 PC-02 契约所有者审核。
5. 缺少 Android 真机、服务身份和异账户环境的项目必须保留为未完成，不得用模拟实现或静态检查冒充平台验收。

本次允许：继续只读依赖闭包/许可证盘点、设计和测试准备；不允许安装未批准依赖、修改公共清单/锁、伪造平台证据或将 PC-03 交付。

本审核不放行 PC-04、PC-06、PC-10、PC-11，也不代表安全存储或产品 L3 通过。

## WorkBuddy 对 e458886 的审核补充（2026-11-20 15:41 UTC+8）

审核对象：共享提交 `e458886e6662ac23b89ed836ff581a2b3af88a8c`。

结论：**认领范围补充通过；PC-03 继续 `doing / blocked`。**

确认事项：

- `agent/copilot/pc03`、基座 `1e18654ca2a60e8f76c114c891648037d155c336` 和 `~/source/pCryoxy.wt/copilot-pc03` 与既有认领登记一致，不构成重复认领。
- 预计独占文件范围与 PC-04 的桥文件不重叠，作为后续实现边界记录有效。
- `crates/secure-store` 尚不存在，因此“预计独占”不等于已批准创建 crate；workspace、Cargo.lock、公共 trait/DTO 和依赖仍须分别经 PC-00/PC-02 所有者串行审核。
- 本补充没有改变此前 `33e3c8c` 的阻塞结论、依赖审批要求、平台实测门槛或安全 L3 边界。

本次不放行代码实现、密码学依赖安装、公共清单/锁修改或 PC-03 done；仍只允许在既有边界内进行只读盘点、设计和测试准备。

## 只读前置核验（2026-11-20 15:55 UTC+8）

执行人 `copilot@zhn-tbxg2iah-win~zhn-x-w`；依据用户本轮一次性只读授权和 `8fb69c3`；仍为 **doing / blocked**。截至核验，两卡 HEAD 均为 `1e18654ca2a60e8f76c114c891648037d155c336`，均包含 `78cf16612b97d0026ea73da429a1b8b51adf0d4c`，各自独立 worktree 的 `git status --porcelain=v1 --untracked-files=all` 退出 0 且输出空；主仓 main 为 `152df4eca58d5c663d5e59d6979eea55bbf288ee`，未集成上述提交。未创建 crate、改源码或合同、下载/安装依赖、构建或运行正式测试。

### 命令和现场

- `git -C <worktree> rev-parse HEAD`、`git -C <worktree> branch --show-current`、`git -C <worktree> status --porcelain=v1 --untracked-files=all`、`git -C <worktree> merge-base --is-ancestor 78cf16612b97d0026ea73da429a1b8b51adf0d4c HEAD` 均退出 0；PC-03 分支 `agent/copilot/pc03`、`~/source/pCryoxy.wt/copilot-pc03`，PC-04 分支 `agent/copilot/pc04`、`~/source/pCryoxy.wt/copilot-pc04`。
- `git -C <pc03-worktree> show HEAD:Cargo.toml` 及 `show HEAD:crates/plugin-sdk/src/lib.rs` 退出 0：workspace 只有 core-ir、plugin-sdk、tauri-app；`SecretStore` 冻结 trait 只有 `put`、`with_secret`；`git ls-tree -r --name-only HEAD crates/secure-store native/android` 退出 0 且无匹配。
- `~/.agent-tools/runtimes/rust/cargo/bin/rustc.exe --version`、`cargo.exe --version` 均退出 0，版本 1.100.0；设置进程级 `CARGO_HOME`/`RUSTUP_HOME` 指向已登记路径。`~/.agent-tools/android-sdk/platform-tools/adb.exe devices -l` 退出 0、设备列表空；`adb.exe version` 退出 0、37.0.1；JDK `java.exe -version` 退出 0、Temurin 21.0.13；SDK NDK 29.0.14206865 和 Gradle 9.6.1 启动文件存在，不代表 Android 构建或真机通过。
- `wsl.exe --list --verbose` 退出 0；Ubuntu 24.04 WSL2 可启动。`wsl.exe -d Ubuntu-24.04 -- sh -c 'uname -sm; cat /etc/os-release | grep PRETTY_NAME; getconf GNU_LIBC_VERSION'` 退出 0：Linux x86_64、Ubuntu 24.04.4 LTS、glibc 2.39。只读 `command -v go; command -v gcc; command -v cc; command -v readelf` 仅找到 `/usr/bin/readelf`；已登记隔离 Linux Rust/Zig 文件存在，**PC-17 一次性使用授权不扩展本卡**。WSL 没有验证正式服务身份、第二账户或设备权限，不能据此推断异账户拒绝或重启通过。
- `tools-scan.sh --check` 退出 0。此前用于平台检查的 `Get-Command cl,gcc` 无结果；未探测所有 VS 安装路径，不能断言系统中绝不存在编译器。Windows Credential Manager 服务账户访问、ACL、用户交互和异账户均未操作或验证。

### 候选依赖与许可证证据

使用 `https://crates.io/api/v1/crates/<name>/<version>` 和对应 `/dependencies` 只读 JSON；并以 Python `tarfile.open(..., 'r:gz')` 只读枚举**已有** Cargo 缓存归档的 LICENSE 文件，未下载或解压依赖。下列明确为拟选版本和元数据，不是已解析的最终闭包或许可批准；缓存存在不等于批准。

| 候选及考察版本 | 上游元数据 SPDX / 归档字节 | 已登记 Windows Cargo 缓存 | 主要正常/构建依赖（版本为范围，不是最终解析） |
|---|---|---|---|
| aes-gcm 0.10.3 | Apache-2.0 OR MIT / 148991 | 无 | aead ^0.5、cipher ^0.4、ctr ^0.9、ghash ^0.5、subtle ^2；默认 aes ^0.8，zeroize 可选 |
| aead 0.5.2 | MIT OR Apache-2.0 / 15509 | 无 | crypto-common ^0.1.4、generic-array ^0.14；arrayvec/bytes/heapless 等可选 |
| aes 0.8.4 | MIT OR Apache-2.0 / 124812 | 无 | cfg-if、cipher、目标条件 cpufeatures、可选 zeroize |
| cipher 0.4.4 / ctr 0.9.2 | MIT OR Apache-2.0 / 19073 / 18344 | 均无 | cipher→crypto-common、inout；ctr→cipher |
| ghash 0.5.1 / polyval 0.6.2 | Apache-2.0 OR MIT / 9482 / 18425 | 均无 | ghash→opaque-debug、polyval；polyval→cfg-if、cpufeatures、opaque-debug、universal-hash |
| subtle 2.6.1 | BSD-3-Clause / 14562 | 无 | 无正常依赖 |
| hmac 0.12.1 | MIT OR Apache-2.0 / 42657 | 无 | digest ^0.10.3；需另选 SHA-256 |
| zeroize 1.8.2 | Apache-2.0 OR MIT / 20907 | 无 | serde/zeroize_derive 可选 |
| inout 0.1.4 / opaque-debug 0.3.1 / universal-hash 0.5.1 | MIT OR Apache-2.0 / 11280 / 7066 / 9146 | 均无 | inout→generic-array；universal-hash→crypto-common、subtle |
| digest 0.10.7 / sha2 0.10.9 | MIT OR Apache-2.0 / 19557 / 29271 | 均有 | digest→crypto-common、可选 block-buffer/subtle；sha2→cfg-if、目标条件 cpufeatures、digest |
| crypto-common 0.1.7 / cfg-if 1.0.5 / cpufeatures 0.2.17 | MIT OR Apache-2.0 / 9619 / 9578 / 13466 | 均有 | 目标和 feature 条件仍须解析 |
| generic-array 0.14.7 | MIT / 15950 | 有 | typenum、构建期 version_check；serde/zeroize 可选 |
| typenum 1.20.1 / block-buffer 0.10.4 | MIT OR Apache-2.0 / 105479 / 10538 | 均有 | block-buffer→generic-array；typenum 可选 scale-info |
| version_check 0.9.5 | 原始 `MIT/Apache-2.0` / 15554 | 有 | 构建期，无正常依赖；原始许可证字符串不能未经核验改写 |
| getrandom 0.3.4 / windows-sys 0.61.2 / jni 0.21.1 / libc 0.2.191 | MIT OR Apache-2.0，jni 原始 `MIT/Apache-2.0` / 50932 / 2517186 / 105028 / 855401 | 均有 | `getrandom` 按目标有 libc 等条件依赖；windows-sys→windows-link；jni→cesu8、cfg-if、combine、jni-sys、log、thiserror、Windows 条件 windows-sys |

现有锁已包含 digest、sha2、crypto-common、cfg-if、cpufeatures、generic-array、typenum、block-buffer、version_check、getrandom、windows-sys、jni、libc，但未包含 aes-gcm、aead、aes、cipher、ctr、ghash、hmac、zeroize、inout、opaque-debug、polyval、subtle、universal-hash。版本和 feature 仍须正式解决；尤其 aes-gcm 默认 getrandom/`rand_core`、平台条件和构建依赖可能扩展闭包，上表不保证完整。未指定最终 crate 特性、目标和构建方式，因此**完整解析闭包、全部许可证文件、下载/安装总量、各平台二进制增量均未核实**，不能用表中大小相加宣称总成本。

已有归档中实际读到：sha2、digest、getrandom、jni、libc 各含 `LICENSE-APACHE` 与 `LICENSE-MIT`；generic-array 含 `LICENSE`；windows-sys 含 `license-apache-2.0`、`license-mit`。候选缺缓存的包未取得归档内许可证文件；registry SPDX 是发布者声明，不替代实际文件归属及最终产品 L3。

### 最小后续裁定与测试矩阵

1. 请 WorkBuddy 先审核上列候选及其按 Windows/Linux/Android target、features、dev/build 分层的**完整解析闭包**、各归档许可文件、来源摘要、总下载/安装占用和产物影响；必要时单独授权隔离获取元数据/归档以补证。之后再申请具体依赖下载和 PC-00 所有者串行 workspace/清单/锁提交；不得把本盘点当成任何批准。
2. 请 PC-02 契约所有者判定 staging/commit/delete 能否保持现有 trait 不变；设计须保证 IR 和 vault 不半提交、密钥不可用不覆盖现有密文、nonce 唯一、密钥和 Token 分离、路径和目录属主受检。三平台各自密钥实现、别名生命周期和服务身份需要明确审核。
3. 后续分别以受控临时 vault/alias 测试：写/读、独立进程重启、不可用密钥保留旧密文、alias 不覆盖、大于 2560 字节、AEAD 篡改拒绝；Linux 目录属主/0600 与异账户，Windows 用户/服务账户和 ACL，Android 真机 Keystore/noBackup；向解析、网络、JNI 错误注入虚构秘密并检查日志/事件/崩溃与网络输出。测试只清理自身资产；异账户、服务和真机需要单独明确环境及授权。
4. 未执行任何 PC-03 安装、代码编写、正式构建、平台/安全测试、部署或系统配置变更；等待依赖、工具和实现各自裁定。

### 挂起快照更正

pCryoxy 无 suspended；两卡 doing/blocked。prnmgt 的 S1 已由人类解挂，T-059 已认领（见 `memory/projects/prnmgt.md` 的最新记录）；S2 真机调研与 S3 v4/#18 仍以原快照为准，未触碰。pRayShell closed。旧交接中 S1 suspended 为历史快照，不得作为当前禁令。

## WorkBuddy 对 f0b722d 的复核与下一阶段授权（2026-11-20 16:07 UTC+8）

审核对象：共享提交 `f0b722d31d47d63b0aa98c30e7e5e666facb8c3d`。

结论：**只读前置核验通过；PC-03 仍为 `doing / blocked`。允许进入“隔离依赖/许可证证据获取”阶段，不放行代码实施或项目依赖安装。**

复核确认：

1. PC-03/PC-04 worktree 的 HEAD、分支、祖先关系和清洁状态已记录；主仓 `main` 尚未集成 `1e18654`，没有把分支现场误写成项目已集成。
2. `secure-store` 缺失、SecretStore 事务语义待契约裁定、Android 无真机以及 Windows 服务身份/Linux 异账户条件缺失，均仍是有效阻塞。
3. `aes-gcm`、`hmac`、`zeroize` 及传递候选的版本范围、features、最终解析闭包、全部归档许可证文件和产品影响仍未核实。现有缓存中的部分包不能替代完整闭包，也不能作为许可证批准。
4. 本次只读核验未安装、未构建、未测试、未改项目代码，证据边界记录正确。

### 现在允许的最小范围

仅允许在项目外的隔离审计目录中：

- 获取候选 crate 的 registry 元数据和归档，用于完整依赖闭包、features、版本、SHA-256、大小及 `LICENSE*`/`COPYING*`/`NOTICE*` 盘点；
- 为 Windows/Linux/Android 目标和明确 features 生成临时审计 manifest/lock 或等价解析结果；
- 记录正常依赖、构建依赖、目标条件依赖、可选依赖和许可证原文；
- 输出“候选闭包审计”交接，供 WorkBuddy 和 PC-00 所有者再次审批。

### 仍禁止

- 不得把临时 manifest/lock 写入 pCryoxy 项目；
- 不得修改 workspace、Cargo.toml、Cargo.lock、SecretStore trait、DTO 或公共契约；
- 不得将候选依赖加入项目或执行正式构建/测试；
- 不得安装系统包、编译器、Android 工具或平台服务；
- 不得以本阶段证据标记 PC-03 done。

完成闭包审计后必须暂停，另行申请：PC-00 的最小清单/锁文件维护、PC-02 的公共契约裁定、依赖安装及代码实施授权。

## WorkBuddy 对 109dabe 的复核与下一阶段裁定（2026-11-20 16:31 UTC+8）

审核对象：共享提交 `109dabea100cfc1758d83978e778874943cbce8f`。

结论：**PC-03 候选 Cargo 图审计材料通过采信；不等于项目依赖批准。PC-03 继续 `doing / blocked`。**

已采信证据：

- 临时 manifest/lock 在 Windows、Linux、Android 三个目标上完成解析和 fetch；59 个外部包的归档 SHA-256 与临时锁核对为 59/59。
- 目标解析节点和正常/构建/目标条件依赖已分层记录；证据明确未构建、未接入尚不存在的 `secure-store`、未证明最终运行时链接。
- 归档许可证文件和原始声明已保留，没有把 registry SPDX 直接升级为产品许可结论。

尚未满足项目依赖批准的缺口：

- `cesu8 1.1.0`、`jni-sys-macros 0.4.1` 和锁内非目标节点 `r-efi 5.3.0` 的归档许可证文件证据不完整或缺失；其中上游线索不能替代归档/来源核验。
- 正常依赖、构建依赖和 Android/Windows/Linux 目标的最终取舍尚未绑定到实际 secure-store 实现。
- 产品安装增量、最终产物选入和 L3 义务仍未知。

### 下一阶段授权

允许 PC-03 在项目外隔离审计目录中做**定向许可证证据补齐**：

- 核验上述缺口包的精确归档、上游 tag/commit、许可证原文和摘要；
- 对未进入三目标解析节点的包明确标记 `not-selected`，不得把它们混入产品闭包；
- 产出逐包 `license-evidence-status` 和目标/feature 取舍表。

仍不允许：

- 修改项目 workspace、Cargo.toml、Cargo.lock、公共 trait/DTO 或契约；
- 将审计缓存变成项目依赖缓存；
- 安装依赖、编写 secure-store、构建或运行正式测试；
- 以“59/59 哈希通过”替代许可证批准或平台验收。

定向缺口补齐后暂停，等待 PC-00 的最小清单/锁文件申请和 PC-02 的事务契约裁定。

## 用户范围变更与 WorkBuddy 授权调整（2026-11-20 16:38 UTC+8）

用户明确裁定：pCryoxy 当前仅内部使用，不对外销售、不商用、不对外开源；不再反复进行许可证核查。

据此调整：

1. `109dabe` 中 `cesu8`、`jni-sys-macros`、`r-efi` 等许可证文件缺口，以及原始 SPDX/许可证义务的未核实状态，继续作为来源和审计记录保留，但**不再阻塞当前内部开发、依赖获取、本地构建或 PC-03 实施**。
2. 不把这些条目改写成“许可证已确认”或“对外分发已批准”；当前范围下不再重复逐包追审，也不要求为内部构建反复补齐发行 SBOM。
3. 如果未来改为销售、商用、对外发布、开源或安装包离开当前内部范围，必须在发布前重新开启 L3/许可证审查。

### 当前可执行授权

- PC-00 所有者可基于现有候选图提出最小 `secure-store` workspace、Cargo.toml 和 Cargo.lock 变更，并按公共文件串行维护；无需再次重复许可证审计。
- PC-03 可在 PC-00/PC-02 前置完成后进入 secure-store 实现；如需改变冻结的 SecretStore trait/DTO，仍须先经 PC-02 审核。
- 允许使用已登记的隔离依赖和本地缓存进行当前内部开发；不得将工具链、缓存或审计产物复制为对外发布物。

### 未解除的技术门槛

- `secure-store` workspace 尚需 PC-00 串行维护；事务 API 仍需 PC-02 确认；Android 真机、Windows 服务身份/ACL、Linux 异账户与重启测试仍未通过。
- PC-03 继续 `doing / blocked`，阻塞原因从许可证审计转为 workspace/契约/平台实测条件，不得标 done。

## WorkBuddy 前置授权裁定（2026-11-20 16:50 UTC+8；依据申请提交 `16d2906`）

### 已批准：PC-00 最小 workspace/依赖维护

批准 PC-00 所有者在独立分支、基于 `1e18654` 串行维护以下最小范围：

- 根 `Cargo.toml`：仅加入 `crates/secure-store` workspace 成员；
- 根 `Cargo.lock`：由实际解析结果生成和校验，不手工承诺固定包数；
- `crates/secure-store/Cargo.toml`；
- 为使 workspace 可解析所需的最小空 `crates/secure-store/src/lib.rs`。

空模块不得返回伪成功，也不得提前实现安全功能。候选直接依赖和版本/feature 以申请表为本次候选范围：`aes-gcm = 0.10.3`（含申请的 `zeroize` feature）、`hmac = 0.12.1`、既有 `sha2 = 0.10.9`、`zeroize = 1.8.2`、既有 `getrandom = 0.3.4`，以及按平台实际需要使用的 `windows-sys = 0.61.2`、`libc = 0.2.191`、`jni = 0.21.1`。实际 lock 解析、feature 展开和下载增量必须以提交证据为准；超出上述版本、feature 或直接依赖范围，需重新申请。

PC-00 提交前须记录 `cargo metadata --locked`/等价解析结果、lock 前后差异、工作树状态和离线缓存边界，并申请 WorkBuddy 审核。PC-03 不得在自己的分支改根清单或 lock。

### 已批准：PC-03 在前置提交审核后实施

PC-00 前置提交审核通过后，PC-03 可在已登记独占文件内实施 secure-store、平台适配、脱敏和单元/可复现测试；允许使用已登记隔离依赖和本地缓存。不得新增未申请依赖，不得修改公共 DTO/proto 或冻结的 `SecretStore` trait。

### PC-02 事务契约裁定

先保持公共 `SecretStore` trait/DTO 不变。PC-03 可在自身实现内提供受限 staging API，但必须把它限定为安全存储内部的暂存、校验、提交和清理能力；不得宣称仅靠两个方法实现跨 vault/IR 的崩溃原子性。PC-02 所有者须补一份可执行的事务边界说明，明确调用者、发布顺序、失败恢复、进程中断后的清理和与单写者/导入卡的责任；若确需改公共 trait，再单独提交最小契约变更申请。

### 仍未批准/仍需实测

- Android Keystore 真机、Windows 服务身份/ACL、Linux 异账户/重启等平台证据；
- 任何公共 trait/DTO、proto、公共 lock 之外的扩大变更；
- 将内部构建状态写成对外分发或许可证已确认结论。

本裁定不将 PC-03 标记为 `done`；状态保持 `doing / blocked`，待 PC-00 前置提交审核、PC-02 事务说明及平台实测证据完成后再交付审核。
