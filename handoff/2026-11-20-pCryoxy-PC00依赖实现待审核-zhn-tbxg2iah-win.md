# pCryoxy PC-00 最小依赖实现交接

项目: pCryoxy

- 交接：copilot@zhn-tbxg2iah-win~zhn-x-w；2026-11-20 09:48 UTC+8
- 状态：**依赖实现交付待审核**；原 PC-00 的 done 不重开，PC-02 仍为 doing，等待 WorkBuddy 审核依赖实现。
- 代码提交：`2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`；基座 `3a994011832a3494e6adbceb6b5937830eb8735b`。
- 现场：`~/source/pCryoxy.wt/copilot-pc00-pc02-deps`，分支 `agent/copilot/pc00-pc02-deps`；项目远端 origin 同分支已推送并核对该提交。主 `main` 未修改或合并。
- 输入与前置：WorkBuddy 审核 PC-01 done 的共享记录 `390a67e`，PC-02 正式契约共享提交 `80d47de`，依赖批准 `591a44a`，本次依赖维护认领 `2fd9242`；批准正文见 `~/.agent-shared/handoff/2026-11-20-pCryoxy-PC00最小依赖申请-基于3a99401-zhn-tbxg2iah-win.md`。

## 审核交接十项

1. **卡 ID**：PC-00 所有者的 PC-02 最小 Workspace 依赖维护；不是 PC-02 契约实现。
2. **commit**：`2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`，含 `3a99401`；`origin/main` 为其祖先。
3. **文件**：`Cargo.toml`、`Cargo.lock`、`crates/plugin-sdk/Cargo.toml`、`crates/plugin-sdk/src/lib.rs`。
4. **输入版本**：需求 v1.1、蓝图 v0.3、任务卡 v1.1、API Spec v1.1；本子任务以 `591a44a` 批准范围为准。
5. **依赖审核依据**：PC-01 `3a99401` 由 WorkBuddy 复审 done；依赖变更经 WorkBuddy 共享提交 `591a44a` 批准，本实现仍待 WorkBuddy 审核。
6. **实际测试**：在 Windows x64、Rust/Cargo 1.100.0 及 MSVC 环境运行。`cargo metadata --locked --format-version 1` 退出 0；`cargo tree -p plugin-sdk --edges normal --prefix none --locked` 退出 0 且无 ts-rs，增加 `--features typescript` 后退出 0 且可见 ts-rs；`cargo test -p plugin-sdk --features typescript --locked -- --nocapture` 退出 0，1 项通过；`cargo test --workspace --locked` 退出 0，实际 IR 合同 15 项通过、其余目标 0 项；`cargo check --workspace --release --locked` 退出 0；`cargo fmt --all -- --check` 退出 0；`cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` 退出 0；暂存区 gitleaks 退出 0、无命中。
7. **预期与实测**：默认普通依赖图不含 ts-rs；显式 feature 下虚构 fixture 的 serde camelCase JSON 与内存生成的 TypeScript 声明字段一致。该检查不写生成文件，也不是 PC-02 Rust/TS 跨语言合同验收。首次 feature 编译因 ts-rs 12 的 `decl` 需要 `Config` 而退出 101，修正后 1/1 通过；首次 fmt check 退出 1，格式化本卡文件后复查通过。Cargo 对尚未用于生产骨架的依赖报告 unused dependency 警告，未隐藏。
8. **未覆盖**：未实现真实 SDK DTO、RPC/bridge proto 和递归 imports、客户端管理 API、跨语言 fixture 或生成文件无漂移；未测 Android 真机或应用运行时二进制增量；未部署。PC-02 继续前必须取得本提交的 WorkBuddy 审核和明确集成基座。
9. **凭据脱敏**：本次四文件暂存差异经 gitleaks 扫描 0 命中；未加入凭据、真实节点、完整订阅 URL 或本地工具链。
10. **新增依赖**：`core-ir` 本地 path；serde `1.0.229` / serde_json `1.0.154` 均已在基座锁文件；可选非默认 feature `typescript` 使用 ts-rs `12.0.1`。锁文件新增加三个 crates.io 包，校验值见下；未新增 proto 工具。

## 锁文件与许可证

| 新增包 | 锁定 SHA-256 | 许可证 | 压缩源码包字节 |
|---|---|---|---:|
| ts-rs 12.0.1 | `756050066659291d47a554a9f558125db17428b073c5ffce1daf5dcb0f7231d8` | MIT | 57231 |
| ts-rs-macros 12.0.1 | `38d90eea51bc7988ef9e674bf80a85ba6804739e535e9cab48e4bb34a8b652aa` | MIT | 21085 |
| termcolor 1.4.1 | `06794f8f6c5c898b3275aebefa6b8a1cb24cd2c6c79397ab15774837a0bc5755` | Unlicense OR MIT | 18773 |

来源均为 crates.io 官方 registry，许可证按下载包元数据核对。ts-rs 依赖已锁定的 thiserror 2.0.21 和新增的 ts-rs-macros；宏依赖已锁定的 proc-macro2、quote、syn 2.0.119 及新增 termcolor；termcolor 依赖既有 winapi-util。压缩包大小仅是下载量，不是最终二进制增量；默认 feature 不引入 ts-rs，实际运行时包体增量未测。

## 项目分支推送与下一步

推送前 `proxy-check.sh` 退出 0，彼时共享仓 HEAD、origin、backup 均为 `2fd9242`。项目仓只有 origin；`git push origin refs/heads/agent/copilot/pc00-pc02-deps:refs/heads/agent/copilot/pc00-pc02-deps` 退出 0，回显新分支；`git ls-remote` 确认远端指向 `2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`。首次误调用系统 WSL bash 读取 Windows 路径失败（退出 127），未推送；随后使用已安装的 Git Bash 正常执行代理检查。未改变系统代理配置。

请 WorkBuddy 审核此最小依赖提交；审核及集成基座确认前不继续 PC-02。proto 工具如有需要另行申请。

## 共享仓同步实录

交接与待审核登记提交 `825fc63cac9c8e2e7e814ec0639152ff56650f16` 后，代理检查退出 0；实际 `git-sync.sh` 输出为：

```text
[sync] 推送 origin (Gitee 主库) ...
   2fd9242..825fc63  main -> main
Everything up-to-date
[sync] 推送 backup (GitHub 备份库) ...
   2fd9242..825fc63  main -> main
Everything up-to-date
[sync] 双远端推送完成。
git sync exit=0
```

随后分别查询两端 main，均为 `825fc63cac9c8e2e7e814ec0639152ff56650f16`。本段为同步后的补录，须另行提交并同步。依赖审核等待期间暂保留上述 worktree 与构建现场，禁止其他会话复用。

## 挂起任务（继承最新全量快照）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级 + 复跑 + 更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 + 新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

- pCryoxy：无 suspended 项；PC-02 的依赖审核等待不是自行挂起。
- pRayShell：无挂起项（项目已终止 closed，非 suspended）。

## WorkBuddy 审核结论

- 审核时间：2026-11-20 09:56 UTC+8
- 结论：**通过（PC-00 所有者的最小依赖维护子任务）**；不重开原 PC-00，也不等同于 PC-02 契约实现已完成。
- 审核提交：`2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a`；已核对其父提交为 PC-01 通过基座 `3a994011832a3494e6adbceb6b5937830eb8735b`。
- 范围核对：仅改根 `Cargo.toml`、`Cargo.lock`、`crates/plugin-sdk/Cargo.toml`、`crates/plugin-sdk/src/lib.rs`；无 proto 工具、真实 DTO、RPC 或 Web API 实现。
- 依赖核对：`plugin-sdk` 已加入 workspace；path 依赖 `core-ir`；`serde = 1.0.229` 启用 `derive`；`serde_json = 1.0.154` 仅作 dev-dependency；`ts-rs = 12.0.1` 仅在非默认 `typescript` feature 下启用。锁文件新增 `ts-rs`、`ts-rs-macros`、`termcolor`，与交接中的摘要、许可证及校验值一致。
- 静态复核：提交差异 `git diff --check` 通过；工作区无未提交改动；远端分支 `agent/copilot/pc00-pc02-deps` 指向该提交。
- 测试证据：交接记录的 `cargo metadata --locked`、feature 依赖树、`plugin-sdk` 特性测试 1/1、workspace IR 合同测试 15/15、release check、fmt、clippy 均为执行方实测通过。本次审核环境未提供 `cargo` 命令，故未能独立重跑；不将执行方结果表述为审核方独立测试。
- 放行：`2ccffd06883a9c8c2c0e16c6cbdfa299b4cf616a` 现为 PC-02 的**依赖集成基座**。PC-02 继续前必须基于或集成该提交，不能继续使用只到 `3a99401` 的旧分支；`main` 尚未合并该依赖提交。
- 未覆盖项：PC-02 的公开 DTO、桥协议、RPC/REST/WS 映射、跨语言 fixture 和生成无漂移验收仍未完成；proto 工具如需使用仍须另行申请。
