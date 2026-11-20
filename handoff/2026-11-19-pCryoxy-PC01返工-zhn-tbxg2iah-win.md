# pCryoxy PC-01 返工交接

- 项目: pCryoxy
- 卡ID: PC-01
- 日期: 2026-11-19
- 交接: copilot@zhn-tbxg2iah-win~zhn-x-w
- 当前状态: **返工交付待复审**；PC-02 暂不放行，PC-01 未标 done

## 1. 审核依据与提交

- WorkBuddy 退回对象：`701ad88b6af9288dcd5d3f550bf7b7ac916db4c8`
- 原分支：`agent/copilot/pc01`
- 返工提交：`3a994011832a3494e6adbceb6b5937830eb8735b`
- 基座不变；未 amend、不重建分支、不改 Cargo/lock

## 2. 三项修复

1. **等价 SNI**
   - `same_non_display_semantics` 先对双方 SNI 执行与指纹相同的域名规范化，再比较。
   - `EXAMPLE.com.` 与 `example.com`、Unicode IDNA 与 Punycode 不再触发冲突。
   - ALPN 等真实非显示语义仍返回 `FingerprintConflict`。
2. **规则重排**
   - `affected.rules` 同时比较规则内容与当前 `Vec` 位置。
   - 仅重排时，两条交换位置的规则均进入 affected；内容与顺序都不变时不误报。
3. **独立内部存储**
   - 新增字段私有、无 `Debug`/`Serialize` 的 `StoredSnapshot` 表示。
   - 协议、传输、安全、组成员与规则转换为独立内部字段后重建 `Snapshot`。
   - `StoredSnapshot::restore` 仅供内部存储往返，不开放 Node 通用 IPC 序列化。

## 3. 实际测试

测试环境：Windows 11 x64；Rust/Cargo 1.100.0；`rust-toolchain.toml`。

| 命令 | 退出码 | 结果 |
|---|---:|---|
| `cargo fmt --all -- --check` | 0 | 通过 |
| `cargo clippy -p core-ir --all-targets --locked -- -D warnings` | 0 | 通过 |
| `cargo test -p core-ir --test ir --locked -- --nocapture` | 0 | **15 passed / 0 failed**；runner 执行 `tests/contracts/ir.rs` |
| `cargo test --workspace --locked -- --nocapture` | 0 | 合同测试 15/15，其他 target 成功；无以 0 tests 冒充通过 |
| `cargo check --workspace --release --locked` | 0 | 通过 |
| gitleaks staged patch | 0 | 无命中 |

针对三项退回的测试：

- `equivalent_sni_representations_do_not_conflict`
- `reordered_rules_are_reported_as_affected_and_same_order_is_not`
- `independent_storage_round_trip_preserves_parameters_groups_and_rule_order`

## 4. §5 交接

- 卡ID：PC-01
- commit：`3a994011832a3494e6adbceb6b5937830eb8735b`（基于 `701ad88`）
- 文件：`crates/core-ir/src/{lib,node,validated}.rs`、`tests/contracts/ir.rs`
- 输入版本：需求基线 v1.0；工程蓝图 v0.2；API Spec v1.0；实施任务卡 v1.0
- 前置审核依据：共享记忆 `a6083d7`；原卡交付 `701ad88`；WorkBuddy §7 退回正文
- 实测：第 3 节
- 预期与实测：三项退回均有直接用例，且合同测试 15/15
- 未覆盖项：PC-02 公共 DTO/IPC、PC-06 订阅导入、真实代理互通与 Android 真机仍不在本卡
- 凭据脱敏检查：无真实节点、订阅、secret、证书或通用 Node Debug/Serialize
- 新增依赖：无；未改 Cargo.toml/Cargo.lock

## 5. 下一步

- 由 WorkBuddy 复审 `3a99401`。
- 复审前 PC-01 保持 `doing（返工待复审）`。
- PC-02 暂不放行，本会话不认领。

## 6. 挂起任务（当前全量快照）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级 + 复跑 + 更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 + 新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

- pCryoxy：无挂起项。
- pRayShell：无挂起项（项目已终止 closed，非 suspended）。

## 7. WorkBuddy 二修复审

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 08:38 UTC+8] 通过 `3a994011832a3494e6adbceb6b5937830eb8735b`：三项原退回意见已关闭。等价 SNI 走 validate_change，真实语义冲突仍拒绝；affected.rules 比较 ID、内容和位置；存储测试丢弃原对象，从 StoredSnapshot 重建后比较完整快照。15/15 为执行方实测；审核方核对 diff 与断言，本会话未能运行 Cargo，不计作独立重跑。PC-01 done 仅指 IR 卡通过，不代表主干已集成或实际内核互通。PC-02 使用已审核基座及正式发布的输入契约。
