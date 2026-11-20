项目: pCryoxy
任务: PC-00 所有者的 PC-03 最小依赖维护
状态: 交付待 WorkBuddy 审核；原 PC-00 done 不重开，PC-03 仍 doing / blocked
执行者: copilot@zhn-tbxg2iah-win~zhn-x-w

# PC-03 最小依赖基线交接

1. **卡 ID**：PC-00 所有者的 PC-03 前置依赖维护；不是 PC-03 安全存储实现。
2. **代码 commit**：`2908e4e4cde5b060568b0d56ff270640c4ca3f63`，基座 `1e18654ca2a60e8f76c114c891648037d155c336`；分支 `agent/copilot/pc00-pc03-deps`，现场 `~/source/pCryoxy.wt/copilot-pc00-pc03-deps`；项目 origin 同分支已推送并核对该提交，main 未合并。
3. **文件**：根 `Cargo.toml`、`Cargo.lock`、`crates/secure-store/Cargo.toml`、`crates/secure-store/src/lib.rs`。后者为空模块，不返回伪成功；没有安全业务实现。未改 PC-02 trait、DTO 或 proto。
4. **输入版本**：需求 v1.1、蓝图 v0.3、任务卡 v1.1、API Spec v1.2；PC-02 `78cf166`、PC-17 `1e18654` 已审核。依赖申请共享提交 `16d2906`、授权 `7faad5c`、本子任务认领 `18e4660`。
5. **依赖审核**：`7faad5c` 批准本次最小候选 workspace / 依赖维护；本代码提交仍待 WorkBuddy 审核，不代表 PC-03 可以在审核前实施。
6. **实际测试**：Windows x64、Rust/Cargo 1.100.0、已登记 MSVC，隔离 `CARGO_HOME` 和 `CARGO_TARGET_DIR`；`cargo metadata --offline --format-version 1` 退出 0，`cargo metadata --locked --offline --format-version 1` 退出 0；`cargo tree -p secure-store --target <target> --edges normal,build --locked --offline` 的 Windows x86_64、Linux x86_64 GNU、Android aarch64 三目标均退出 0，仅解析依赖图；`cargo test -p secure-store -p core-ir -p plugin-sdk --locked --offline` 退出 0：core-ir 合同 15/15、plugin-sdk 9/9、空 secure-store 0 项；`cargo check -p secure-store --release --locked --offline` 退出 0；`cargo clippy -p secure-store -p core-ir -p plugin-sdk --all-targets --locked --offline -- -D warnings` 退出 0；`cargo fmt --all -- --check` 初次退出 1，针对 secure-store 格式化后退出 0；`git diff --check` 与暂存 gitleaks 均退出 0。
7. **预期与实测**：正式 workspace 在隔离缓存离线解析、锁定和 Windows 相关目标编译；未启用真正安全逻辑。Cargo 对空模块尚未使用的 `aes-gcm`、`getrandom`、`hmac`、`plugin-sdk`、`sha2`、`windows-sys` 给出 unused dependency 警告，未隐藏；Clippy 命令仍退出 0。三目标 tree 不等于三平台构建或运行通过。
8. **未覆盖**：事务协调器、安全存储代码及平台/安全测试均未实现；Android 真机、Windows 服务身份/ACL、Linux 异账户及重启未测；未运行整套 Tauri workspace 测试、Linux/Android 构建和二进制增量评估，未部署。PC-03 先等 WorkBuddy 审核本提交及 PC-02 事务边界说明。
9. **凭据脱敏**：定向暂存区 gitleaks 0 命中；未加入凭据、真实节点、完整 URL 或本地工具链。
10. **新增依赖**：依据 `7faad5c` 的直接版本/features；正式 lock 相对基座增加 15 个外部 name/version、删除 0、既有包 checksum 变化 0。新增 15 个归档合计 523,700 字节，压缩归档总量不是最终产品体积，也不是本轮联网下载量。

新增清单：`aead 0.5.2`、`aes 0.8.4`、`aes-gcm 0.10.3`、`cipher 0.4.4`、`ctr 0.9.2`、`getrandom 0.2.17`、`ghash 0.5.1`、`hmac 0.12.1`、`inout 0.1.4`、`opaque-debug 0.3.1`、`polyval 0.6.2`、`rand_core 0.6.4`、`subtle 2.6.1`、`universal-hash 0.5.1`、`zeroize 1.8.2`；版本、来源和 SHA-256 以本次 `Cargo.lock` 及 [隔离审计清单](2026-11-20-pCryoxy-PC03候选依赖审计-zhn-tbxg2iah-win.json) 为准。

离线缓存由基座已登记 Cargo 归档/索引与已获内部使用授权的 PC-03 审计归档/索引复制到本会话专用目录，不写全局缓存；构建临时产物同样留在本会话目录，不进项目。仅为内部使用，未确认对外分发许可。

## 挂起任务（当前全量快照）

| 项目 | 任务 | 挂起于/裁决 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认；2026-11-19 暂时不做 | 厂家后台升级中 | 升级完成、复跑探测、更新调研文档 | 调研文档已入库 | 续跑不重开卡 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07；2026-11-19 暂时不做 | 纸张口径未定 | S2 结论、D-5~D-10 裁定、新 ADR | 仅 DRAFT 方案 | 重编卡后认领 | 人类 |

pCryoxy 无 suspended，PC-03/PC-04 doing / blocked；prnmgt S1 已由人类解挂，T-059/T-060/T-061 已完成；pRayShell closed。本次未触碰其他项目。
