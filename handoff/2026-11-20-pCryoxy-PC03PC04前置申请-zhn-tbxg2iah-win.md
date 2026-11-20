项目: pCryoxy
任务: PC-03 / PC-04 最小前置申请
状态: 待 WorkBuddy 分别裁定；两卡 doing / blocked
申请人: copilot@zhn-tbxg2iah-win~zhn-x-w
依据: 共享提交 `a6a67f4c90ef640e8383a03e152d045f4f5f3072`

# 公共清单、事务契约与桥工具申请

## 共同输入与边界

- PC-02 `78cf166`、PC-17 `1e18654` 已审核；两卡独立 worktree 的 HEAD 均为 `1e18654ca2a60e8f76c114c891648037d155c336`，2026-11-20 16:44 检查均干净。PC-03 分支 `agent/copilot/pc03`；PC-04 分支 `agent/copilot/pc04`。两卡代码、测试及配置不得重叠；公共文件由所有者单独串行维护。
- `a6a67f4` 将现有许可证缺口保留为来源记录，不再作为当前内部使用的阻塞项；不声称许可已经确认或对外发布已批准。若范围变为销售、商用、对外发布、开源或安装包离开当前内部范围，发布前重新审查。
- 本文仅申请，不是批准，不认领新卡，不修改项目实现、公共清单/锁或权威契约。申请的每项需独立裁定；需要的后续项目提交由相应所有者在新分支完成并交审核，不在 PC-03/PC-04 两条分支争写。

## 一、PC-03：请批准 PC-00 最小 workspace/依赖维护

**申请对象**：PC-00 所有者的独立前置提交；原 PC-00 done 不重开。基于 `1e18654`，建议仅修改根 `Cargo.toml`（workspace 添加 `crates/secure-store`）、根 `Cargo.lock`、`crates/secure-store/Cargo.toml` 与为可解析 workspace 所需的最小空 `crates/secure-store/src/lib.rs`。空模块不得返回伪成功，不实现安全功能；此文件随后由 PC-03 基于已审依赖提交继续维护，不能与 PC-04 文件重叠。无批准不创建这些文件。

候选普通/目标依赖沿用 [隔离审计](2026-11-20-pCryoxy-PC03PC04隔离依赖审计-zhn-tbxg2iah-win.md)，仅供批准、最终按实际实现核对：

| 依赖及精确版本 | 功能与范围 | 当前事实 |
|---|---|---|
| 本地 `plugin-sdk`、`core-ir` path | SecretStore/SecretRef 契约；非网络包 | 既有 workspace 成员 |
| `aes-gcm =0.10.3`，默认特性加 `zeroize` | Windows/Linux 密文文件候选 AEAD；审计配置也会解析 Android 目标 | 审计图新包；默认 features 含 `getrandom`/`rand_core`，是否缩减待批准后验证 |
| `hmac =0.12.1`、`sha2 =0.10.9` | HMAC-SHA-256 派生 credential_id | sha2 已在基座锁；hmac 不在基座锁 |
| `zeroize =1.8.2`、`getrandom =0.3.4` | 敏感缓冲清理和安全随机数 | 前者不在基座锁；后者已存在；仍须审查平台错误处理 |
| Windows `windows-sys =0.61.2`，Foundation/Security/Security_Credentials/Storage_FileSystem | Credential Manager 和文件操作候选 | 基座已有，具体 ACL 所需额外 features 不在本次假定范围 |
| Linux/Android `libc =0.2.191`；Android `jni =0.21.1` | 目录/权限及 Android 受控 JNI 交互候选 | 基座已有；是否实际需要由实现与平台验证决定 |

对比基座 lock 与隔离候选 lock：候选图中有 **15 个 name/version 对**尚不在基座锁，分别为 `aead@0.5.2`、`aes@0.8.4`、`aes-gcm@0.10.3`、`cipher@0.4.4`、`ctr@0.9.2`、`getrandom@0.2.17`、`ghash@0.5.1`、`hmac@0.12.1`、`inout@0.1.4`、`opaque-debug@0.3.1`、`polyval@0.6.2`、`rand_core@0.6.4`、`subtle@2.6.1`、`universal-hash@0.5.1`、`zeroize@1.8.2`。这是**两个独立解析结果的集合差，不是实际 workspace lock diff**；与基座共同解析后的升级、features、下载量和二进制增量须实际验证，不得承诺固定 15 包或静默升级。

请裁定：① 本候选依赖、目标/feature 与最小文件范围；② PC-00 所有者单独提交并验证 lock 的授权；③ 允许 PC-03 在该前置提交经审核后基于它实施。新增依赖/特性如超出批准范围重新申请；不改公共 DTO/proto，不使用全局缓存或系统配置。

## 二、PC-03：请 PC-02 契约所有者确认事务边界

已冻结 `plugin-sdk::SecretStore` 仅有 `put` 和 `with_secret`；任务卡与 API Spec 要求安全存储支持 `delete_staged`、`commit_staged`，且不得提交半份 vault 与悬空 IR 引用。当前实现尚不存在跨 vault/IR 的提交协调器；单独添加两个方法不能证明跨持久化资源的崩溃原子性。

建议优先保持已冻结公共 trait 和 DTO 不变，由 PC-03 在自身实现内提供受限 staging API，具体签名及谁拥有提交令牌、IR 发布次序、持久化日志/恢复和失败清理需契约所有者确定。若下游必须经 `SecretStore` 泛型调用 staged 操作，再另提公共 trait 的最小变更；不得自行扩接口。

请明确：① staging/commit/delete 的调用者和接口归属；② 验证失败、vault 写失败、IR 提交失败及进程中断后的可恢复状态；③ 引用尚未持久化或删除回滚如何避免丢失秘密和悬空引用；④ PC-03 与后续单写者/导入卡之间的责任。缺可实现的协调契约时不得声称实现了跨文件原子事务。

## 三、PC-04：请单独裁定桥实现和工具链

**桥/依赖申请**：固定 Xray `v26.11.9` / `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`，以已有 [167 模块审计清单](2026-11-20-pCryoxy-PC04候选依赖审计-zhn-tbxg2iah-win.tsv) 为上游候选，不把 `./...` 全图宣称为桥最终依赖。申请批准基于独立隔离模块缓存解析并锁定实际桥所需 Go 依赖、在 PC-04 独占范围内编写最小桥和上游补丁、使用真实固定核心测试；最终模块差、补丁摘要和资产来源/哈希交审核。公共 proto、`contracts/core-lock.json` 不在本申请的直接写入范围，若需要变更先由 PC-02/PC-00 所有者审核串行维护。不引入 SetAdmission 或新流拒绝门禁。

**Linux Go 工具申请**：官方发行索引 `https://go.dev/dl/?mode=json&include=all` 于本次查询 `curl` 退出 0，列出 `go1.27.4.linux-amd64.tar.gz`，大小 **70,680,823 字节**，SHA-256 `7226736c2339719cda28fbf3a54d71aa63bcefe376e98cef00034268dab24840`；拟从 `https://go.dev/dl/go1.27.4.linux-amd64.tar.gz` 获取，仅解压至 `~/.agent-tools/runtimes/copilot/linux-x86_64-gnu/go-1.27.4/`，下载后核验摘要并记录实测占用，解压占用尚未知。Go 为构建工具，不是项目运行时依赖；不改系统 PATH/profile/apt，不装全局工具。已登记 Windows Go 1.27.4 仅为 Windows 工具，并非 Linux 编译实证。

**race/C 工具申请**：本机 WSL Ubuntu 24.04.4 x86_64、glibc 2.39；本次 `wsl --exec sh -lc` 探测退出 0，PATH 中未发现 go/gcc/cc，发现 readelf。PC-17 已登记隔离 Zig 0.16.0，原归档官方 SHA-256 `70e49664a74374b48b51e6f3fdfbf437f6395d42509050588bd49abe52ba3d00`；其 PC-17 一次性使用授权已消耗。申请允许 PC-04 **复用现有 Zig**，仅作为命令级 `zig cc` 的 C 编译器候选，配合隔离 Linux Go 实测 `CGO_ENABLED=1` 的 C 链接及 `go test -race`；不新装 Zig、不改系统配置。Zig/Go race 兼容性及系统链接输入尚未证明，失败须如实报告并再申请替代，不保证可以通过；实际 release 与真实桥测试必须分别获准。模块、Go 构建和 Zig 缓存按卡独立设置，绝不落入全局模块缓存。

请 WorkBuddy 分别批准：① Linux Go 官方归档获取/隔离安装；② 本卡复用已登记 Zig 的受控 smoke/race；③ 桥实现、固定源码补丁和对应真实测试；④ 失败时再次申请替代工具链。安装和工具使用需按全局规范登记并验摘要，未批准前不执行。Android 真机、Windows 服务身份、Linux 异账户、Go race 与 Linux 桥资产均尚无验收证据。

## 挂起任务（当前全量快照）

| 项目 | 任务 | 挂起于/裁决 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认；2026-11-19 暂时不做 | 厂家后台升级中 | 升级完成、复跑探测、更新调研文档 | 调研文档已入库 | 续跑不重开卡 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07；2026-11-19 暂时不做 | 纸张口径未定 | S2 结论、D-5~D-10 裁定、新 ADR | 仅 DRAFT 方案 | 重编卡后认领 | 人类 |

pCryoxy 无 suspended；两卡 doing / blocked。prnmgt S1 已由人类解挂，T-059/T-060/T-061 已完成；pRayShell closed。本次未触碰其他项目。
