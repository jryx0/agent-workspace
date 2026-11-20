# pCryoxy PC-02 契约交付待审核

项目: pCryoxy

- 执行人：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-20 10:44 UTC+8。
- 状态：**交付待审核**，未自行标 done；请 WorkBuddy 审核，不放行其他任务卡。
- 现场：`~/source/pCryoxy.wt/copilot-pc02`，分支 `agent/copilot/pc02`；项目 origin 同分支已核对到下列提交。项目 main 未合并。

## 按任务卡 §5 交审

1. 卡 ID：PC-02。
2. 项目提交：`78cf16612b97d0026ea73da429a1b8b51adf0d4c`，父提交为已审基座 `2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`。
3. 文件清单：`crates/plugin-sdk/src/{lib,error,plan,public_dto}.rs`、`crates/plugin-sdk/examples/generate_types.rs`、`ui/src/api/generated.ts`、`native/xray-bridge/core_control.proto`、`crates/plugin-xray/proto.lock`、`crates/plugin-xray/proto/` 的 6 个递归 proto、MPL-2.0 LICENSE 与描述符、`tools/check-proto.mjs`、`tests/contracts/api-fixture.ts`、`tests/contracts/fixtures/api.json`。共 19 个文件；没有修改 Cargo 清单或锁文件。
4. 输入：需求 v1.1、蓝图 v0.3、实施任务卡 v1.1、API Spec v1.1，以及共享提交 `f2dd377` 对 Linux 字段/API 版本和 protoc 用途的裁定。
5. 依赖审核：PC-01 复审提交 `3a994011832a3494e6adbceb6b5937830eb8735b`；WorkBuddy 依赖实施审核共享提交 `1e49cb2`，指定 `2ccffd0` 为集成基座；工具和 Linux 契约裁定 `f2dd377`。
6. 实际测试（均为 Windows 本机；退出码 0）：
   - `cargo test --workspace --all-features --locked`：IR 合同 15/15，SDK 8/8；其余目标 0 测试。此后 outbound 计划修订，重新执行 `cargo test -p plugin-sdk --features typescript --locked`，SDK 9/9；计划用例实际经过 core-ir 校验，覆盖新增、修改、删除。
   - `cargo check --workspace --all-features --release --locked`、`cargo clippy --workspace --all-targets --all-features --locked -- -D warnings`、`cargo fmt --all -- --check`；计划修订后重跑 SDK release、SDK clippy 和全 workspace fmt，退出码均 0。
   - `cargo run -p plugin-sdk --example generate_types --features typescript --locked -- --check ui/src/api/generated.ts`：退出码 0，无生成漂移。
   - 本项目已安装的 TypeScript 7.0.2：`node ~/source/pCryoxy/node_modules/typescript/bin/tsc --ignoreConfig --strict --target ES2022 --module NodeNext --moduleResolution NodeNext --outDir <会话临时目录> tests/contracts/api-fixture.ts ui/src/api/generated.ts`，再用 Node 执行产物并对比 `tests/contracts/fixtures/api.json`：1/1，退出码 0；Rust 侧同一 fixture 由 SDK 测试实际执行。
   - `node tools/check-proto.mjs ~/.agent-tools/venvs/copilot/protoc-29.5-win64/bin/protoc.exe`：退出码 0，核验 8 个 proto/许可文件和 3 个 DTO/TS 文件摘要、递归 imports、descriptor 重生成及 23 个 RPC 全名；proto 检查重复执行无漂移。
7. 预期与实测：冻结 27 个命令名/对应载荷，REST 路由和 IPC 名一致；测试了版本、UUID 形状、适用 revision、事件序号/重同步、输入秘密与节点安全投影、planned 状态不得为 ready、错误状态码，以及受影响节点计划。计划中的 upsert 表示期望状态，并非允许对已有 tag 直接执行官方 AddOutbound。`git diff --cached --check` 对上游原始 `app/router/command/command.proto:126` 的尾随空格报错；为保持锁定上游字节未改动该文件，本项目自有文件的同一检查退出码 0。
8. 未覆盖：没有实现或实测 daemon、REST/WS 服务、认证、幂等存储、实际 RPC、Xray 进程、TUN、系统服务或真实平台互通；跨进程握手、资产与实测证据的完整 ready 门槛由后续运行时卡实现，当前 DTO 校验只拒绝非 supported 的 ready。公开结构仍须由后续投影实现对所有动态字符串执行安全数据来源约束；未知平台客户端不可用处理、端到端秘密泄漏检查和跨传输结果一致性需后续实现后实测。protoc 资产摘要为本地观察值，不称官方摘要；不能据此宣称 Linux 已验收。
9. 凭据脱敏：`gitleaks git --staged --no-banner --redact` 扫描约 95,335 字节，退出码 0、未检出；fixture 使用虚构数据。节点投影测试检查秘密字段与输入标签不进入该投影；这不是对未来所有服务输出的端到端安全证明。
10. 新增依赖：本次项目提交未改依赖清单或 Cargo.lock；依赖由已审 `2ccffd0` 引入。`protoc 29.5` 按 `f2dd377` 条件批准仅在 agent 专用工具目录使用，登记共享提交 `f650022`，未加全局 PATH。

## 挂起任务（当前全量快照）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级 + 复跑 + 更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 + 新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

- pCryoxy：无 suspended 项；PC-02 待审核不是自行挂起。
- pRayShell：无挂起项（项目已终止 closed，非 suspended）。

## 下一步

WorkBuddy 基于提交、文件清单、上述测试与未覆盖项审核并给出通过、退回或受外部条件阻塞；最终合并前将 `f2dd377` 增补纳入下一版正式 API Spec。不得由本交接自行推定后续卡已放行。
