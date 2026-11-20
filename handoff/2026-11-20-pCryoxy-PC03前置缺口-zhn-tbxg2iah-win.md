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
