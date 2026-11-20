# pCryoxy PC-01 交接

- 项目: pCryoxy
- 卡ID: PC-01
- 日期: 2026-11-19
- 交接: copilot@zhn-tbxg2iah-win~zhn-x-w
- 当前状态: **交付待审核**；实现、分支提交及测试完成，未标 done，未认领其他卡

## 1. 已完成

- 建立 `core-ir` 受限领域类型，区分 `NodeId`、`SecretRef`、`CredentialId`、`Fingerprint` 与显示名。
- `Node`、`SecretRef`、`CredentialId`、`Fingerprint` 不派生通用 `Debug` 或 `Serialize`。
- 实现八字段指纹：版本前缀 `pcryoxy-node-v1`、逐字段 u32 BE 长度、SHA-256、IDNA/域名/IP 规范化、固定大端端口。
- `validate_change` 作为入口：校验引用、唯一性、组重复、P0 组嵌套、规则兜底位置、指纹完整性与完整语义冲突。
- 相同指纹但 ALPN/REALITY/flow/FinalMask 等非显示语义不同返回 `FingerprintConflict`；仅名称或本地 `SecretRef` 变化不冲突。
- 保留 `Member::Group` 类型，但 P0 入口无条件拒绝，未实现 DAG 展开。
- `RoutingRule` 以 `Vec` 顺序为唯一顺序，不生成额外 priority。

## 2. 现场

| 项 | 取值 |
|---|---|
| worktree | `~/source/pCryoxy.wt/copilot-zhn-x-w-pc01`（会话收尾 remove） |
| 分支 | `agent/copilot/pc01` |
| 基座 | `origin/main` `152df4e` |
| PC-01 commit | `701ad88b6af9288dcd5d3f550bf7b7ac916db4c8` |
| 远端分支 | `origin/agent/copilot/pc01` |
| 项目仓 | `https://gitee.com/ParvaUltra/pCryoxy.git` |

PC-00 所有者为使测试真实运行提供两个先决提交：

- `ec39de4`：根 workspace 纳入 `core-ir`、建立零依赖 crate manifest 与 `[[test]]` target。
- `152df4e`：声明已批准的 `idna 1.1.0` 直接依赖。

## 3. 实际测试

测试环境：Windows 11 x64；Rust/Cargo 1.100.0；`rust-toolchain.toml`；MSRV 1.100.0。

| 命令 | 退出码 | 实测 |
|---|---:|---|
| `cargo fmt --all -- --check` | 0 | 通过 |
| `cargo clippy -p core-ir --all-targets --locked -- -D warnings` | 0 | 通过 |
| `cargo test -p core-ir --test ir --locked -- --nocapture` | 0 | runner 真实执行 `tests/contracts/ir.rs`，**13 passed / 0 failed** |
| `cargo test --workspace --locked -- --nocapture` | 0 | core-ir 13 tests 执行；其余现有 target 的 0 tests 也成功，不以 0 tests 冒充合同验证 |
| `cargo check --workspace --release --locked` | 0 | 通过 |
| gitleaks staged patch | 0 | 无命中 |

合同测试具体覆盖：

- 端口 0、反向端口区间、非法 host。
- 缺少节点引用。
- 组成员重复。
- 任意 `Member::Group`，含自引用与外部组引用。
- 空兜底规则位于非末位。
- 指纹已知 SHA-256 向量、长度前缀、`|` 分隔符歧义。
- 域名小写/末尾点、Unicode IDNA 与 Punycode、None/空 path。
- 名称变化不改变指纹；八字段外 ALPN 变化返回 `FingerprintConflict`。
- 合法 `ValidatedSnapshot -> Snapshot -> validate_snapshot` 往返保留协议/传输/安全非秘密参数和规则顺序。
- 规则引用合法、末尾 catch-all 合法。

## 4. §5 审核交接

- 卡ID：PC-01
- commit：`701ad88b6af9288dcd5d3f550bf7b7ac916db4c8`；分支 `agent/copilot/pc01`
- 文件清单：
  - `crates/core-ir/src/lib.rs`
  - `crates/core-ir/src/node.rs`
  - `crates/core-ir/src/group.rs`
  - `crates/core-ir/src/routing.rs`
  - `crates/core-ir/src/validated.rs`
  - `tests/contracts/ir.rs`
- 输入版本：需求确认基线 v1.0；工程蓝图 v0.2；API Spec v1.0；实施任务卡 v1.0
- 前置审核依据：共享记忆提交 `a6083d7`，WorkBuddy 于 18:08 将 PC-00 标为 done，并将 Android 真机门槛移交 PC-05
- 实际测试：见第 3 节
- 预期与实测：预期 6 个卡内文件实现受限 IR/唯一校验；实测 13/13 合同用例、workspace test 与 release check 通过
- 未覆盖项：订阅/链接导入属 PC-06；公开 IPC DTO 属 PC-02；运行时调度/DAG 展开未实现且 P0 明确禁止；未做真实代理互通、Tauri UI 或 Android 真机
- 凭据脱敏检查：gitleaks staged patch 0 命中；fixture 只使用虚构域名与固定 credential_id；无真实节点、订阅、secret、证书、pRayShell 文件或全量 Node 日志输出
- 是否新增依赖：是。`idna 1.1.0`（MIT OR Apache-2.0，IDNA/UTS-46 规范化）；已由用户批准，PC-00 提交 `152df4e` 声明；它原已位于 Cargo.lock，未新增传递包。无其他依赖。

## 5. 未覆盖与下一步

- 不实现 PC-06 的订阅/分享链接解析。
- 不实现 PC-02 的公开 DTO、IPC、插件 trait 契约。
- 不运行代理内核、部署、签名或上传应用。
- 由 WorkBuddy 审核本卡；审核意见只能追加，不回写或改写本文。
- 审核通过后才可由下一任务认领 PC-02；本会话不认领 PC-02/PC-05。

## 6. 挂起任务（当前全量快照）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级 + 复跑 + 更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 + 新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

- pCryoxy：无挂起项。
- pRayShell：无挂起项（项目已终止 closed，非 suspended）。

## 7. WorkBuddy 审核结论：退回返工

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-20 08:26 UTC+8] 补录对 `agent/copilot/pc01` 提交 `701ad88b6af9288dcd5d3f550bf7b7ac916db4c8` 的审核意见，非对新提交的复审。第 3 节的 13/13 为执行方实测，审核方未独立重跑。PC-01 保持 `doing`，PC-02 暂不放行。

1. **等价 SNI 被误报为指纹冲突。** `Fingerprint::compute` 已规范化 SNI，但 `same_non_display_semantics` 比较原始 `LinkOptions`。复审须通过 `validate_change` 验证大小写、末尾点、等价 IDNA 表示均不触发冲突；同指纹但 ALPN 等实际语义不同时仍返回 `FingerprintConflict`。不改八字段公式。
2. **规则仅重排时，`affected.rules` 漏报。** `affected_ids` 按 ID 比较内容，未计入位置变化。交换两条匹配范围重叠、动作不同的非兜底规则，断言新快照保留新顺序且结果标出顺序受影响的规则；顺序与内容都不变时不得误报。
3. **现有往返测试未跨过存储边界。** `validate_snapshot → into_snapshot → validate_snapshot` 只取回原内存对象。请写出独立的内部存储表示，再从该表示重建快照；断言协议、传输与安全非秘密参数、组成员顺序和规则顺序全部保留。不要求接数据库，不给 `Node` 开放通用 IPC 序列化。

请原认领者在原分支返工，无需重新认领。再次交付时追加新提交号、针对上述三项的测试名称、实际运行命令与结果，交 WorkBuddy 复审；未复审通过不标 `done`。
