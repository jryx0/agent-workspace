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

## 共享交付提交首次同步实际回显

代理检查：2026-11-20 10:45:51 UTC+8，全局 http.proxy 未设置、GitHub 专用代理端口可连；本地 `920c424` 领先 origin/backup 的 `f650022`，结论可执行同步。

```text
[sync] 推送 origin (Gitee 主库) ...
remote: Powered by GITEE.COM [1.1.23]
remote: Set trace flag 43467990
To https://gitee.com/ParvaUltra/agent-workspace.git
   f650022..920c424  main -> main
Everything up-to-date
[sync] 推送 backup (GitHub 备份库) ...
To https://github.com/jryx0/agent-workspace.git
   f650022..920c424  main -> main
Everything up-to-date
[sync] 双远端推送完成。
git sync exit=0
920c4246debdb8debb8a2a8d2ee2b5bc5e7986d6 refs/heads/main  (origin)
920c4246debdb8debb8a2a8d2ee2b5bc5e7986d6 refs/heads/main  (backup)
```

本段是该次实际输出整理，分支核验行的括注标明调用对象；本段自身由后续提交同步，不递归记录自身提交号。

## WorkBuddy 审核结论（追加）

- 审核时间：2026-11-20 10:48 UTC+8
- 卡 ID：PC-02；审核对象：`78cf16612b97d0026ea73da429a1b8b51adf0d4c`；父提交/依赖集成基座：`2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`；分支：`agent/copilot/pc02`。
- 结论：**通过**。PC-02 公共 DTO、错误/事件/命令合同、计划层、TypeScript 生成物、项目桥 proto、递归导入锁和 RPC 全名核验均达到本卡范围；不等同于 daemon、REST/WS 服务、真实 Xray、TUN、systemd、Web 鉴权或 Linux 运行时已完成。
- 独立核验：使用已批准 `protoc 29.5` 复跑 `tools/check-proto.mjs`，确认 8 个 proto/许可文件摘要、descriptor 和 23 个 RPC 方法通过；TypeScript 7.0.2 fixture 独立编译并与 `tests/contracts/fixtures/api.json` 比对 1/1 通过；新增差异秘密扫描无命中；源文件摘要与 `proto.lock` 一致。
- 执行方证据：Windows 本机报告 SDK 9/9、IR 15/15、workspace/all-features、release、clippy、fmt 和 Rust→TS 生成无漂移均退出 0。本审核环境无 Cargo，未独立重跑 Cargo/Clippy/Fmt，不将其表述为审核方独立测试。
- 已知例外：上游锁定的 `app/router/command/command.proto:126` 原始尾随空格导致完整差异 `diff --check` 非零；该文件按上游字节保留，摘要已锁定，非本次新增格式问题。
- 正式契约收尾：已发布 API Spec v1.2，内容为 v1.1 全文 + §9 Linux `RuntimeDto`/兼容性增补；统一入口和收尾清单已切换到 v1.2。`protoc` 本地 SHA 仍明确标记为 `local-observed`，不冒称官方 digest。
- 集成状态：**待集成**。项目 `main` 尚未包含 `78cf166`；`agent/copilot/pc02` 为后续集成基座，由代码仓所有者按仓规范合并/快进。PC-02 不得自行宣称 main 已集成。
- 下一卡放行：PC-02 依赖已闭环；当前仅 **PC-17 Linux 构建基线**满足认领前置。PC-03/PC-04 仍等待 PC-17 审核通过；不放行其他未满足依赖的卡。
