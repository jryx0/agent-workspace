# pCryoxy PC-18 阶段 A：只读预检与 ABI 等待

项目: pCryoxy

- 记录人：copilot@zhn-tbxg2iah-win~zhn-x-w#e64ae0ad
- 阶段授权：`041c2dbe8f7bbdfbb2f333998a93bd4c3baa1f6e`
- 桥侧实施基线：`27d942badfa26afb2d0fb0b60009071881f035b9`
- 桥侧阶段审核：`6e2e21566f48c0ddb60a377882eff39c8decd6f9`
- 用户本轮决定：等待 PC-04 补齐运行时 ABI，暂不实施 daemon。
- 当前仅完成只读预检；未认领 PC-18，未创建 PC-18 worktree/分支，
  未修改项目代码、构建清单或桥文件，未构建、测试、合并或部署。
- 本记录是新增 handoff，不改写旧交接；依赖等待不是 agent 自行挂起。

## 只读现场核对

检查了 git worktree 登记的主仓和 PC-00 前置、PC-02、PC-03、PC-04、
PC-17 工作树。未发现 PC-18 分支、工作树或 crates/daemon-server 文件。

项目各工作树跟踪文件无未提交改动。PC-04 保留既有未跟踪
tests/integration/bridge/pc04-linux-amd64.a，未删除、覆盖或暂存。
共享交接仓另有他人修改和未跟踪文件，全部保持原状。
未执行 reset、clean、stash 或覆盖恢复。

主仓 main 为 `152df4eca58d5c663d5e59d6979eea55bbf288ee`，
workspace 含 core-ir、tauri-app。PC-04 工作树为 agent/copilot/pc04，
HEAD 为 27d942b，workspace 另含 plugin-sdk；两者均无 daemon-server。
下一阶段不得将主仓旧 workspace 当成桥侧指定集成基线。

## 已有 ABI 与剩余阻塞

PC-04 的 native/xray-bridge/abi/README.md 和
abi/include/pc04_preflight_v1.h 明确当前 ABI v1 为无状态 validator：

- PC04ABI_v1_version；
- PC04ABI_v1_validate_restricted_profile。

它不创建或管理 Xray runtime，没有 opaque runtime handle、启动、
状态访问、停止或 close 接口。Go RegisterRuntime 已有二次校验，
但不是可由 Rust 通过现有 C ABI 调用的生产入口。

因此现有 ABI 可以支持 Rust 纯 prepare wrapper，却不足以完成本轮要求的
真实 RegisterRuntime 启动链、私有 IPC、UID/ticket、运行时状态不变、
优雅停止、异常退出和重启恢复。不得用假 handle、独立 core 或复制
RouteView/Geo 状态填补缺口。

Go ABI 导出、头文件和生命周期契约仍归 PC-04；PC-18 不修改其实现。
用户已明确选择等待该前置，不先交付冒充完整 daemon 的预检壳。

## 下一阶段拟新增与公共文件边界

获批运行时 ABI 后，PC-18 可新增自有独立 manifest、Rust
lib/service/runtime/control/auth/bridge_ffi、bin/pcryoxy-daemon、
阶段 A 测试和独立构建说明。具体拆分按接口复杂度最小化，不提前造接口。

目前不需要修改任何已有 Rust 文件；正式 workspace 集成若需要，
先申请根 Cargo.toml/Cargo.lock 所有者与 WorkBuddy 审核。

本轮不修改根 Cargo.toml、Cargo.lock、contracts/core-lock.json、
tools/build-*、CI/build matrix、native/xray-bridge/go.mod/go.sum、
PC-02 proto/descriptor/生成物/契约锁。

## 恢复实施前置

PC-04 提供并审核运行时接入契约和实施提交，至少明确：

- Rust 经 ABI 调用纯 prepare，再经受控入口调用 RegisterRuntime；
- opaque handle 的所有权、空 handle、并发调用、关闭幂等与失败清理；
- 私有 listener 的创建/传递/释放、peer UID 与 per-runtime ticket；
- 状态查询与拒绝不变性取证边界；
- 重启后的 instanceId/epoch 及恢复语义；
- ABI 版本、固定错误码、内存边界和 panic 收敛，不返回 Go pointer 或秘密。

随后重新只读核对现场与审核记录，完成认领登记后实施 Rust 宿主；
所有生产测试必须绑定真实 ABI，不以模拟或既有 C smoke 替代。

阶段 A 的验收仍包括 prepare 在 socket/core/Geo/service/ready 之前、
首次失败无遗留、运行中 RouteView/epoch/revision/Geo version/
rollback point/lease/资源不变、0700/0600、UID/ticket、
单实例/单写者、停止/异常/重启和客户端离线存活。

## 未完成与状态边界

没有 PC-18 implementation commit、独立 manifest、普通/race 回执或
生产启动/IPC/生命周期证据，不能申请实现验收或标记 done。
PC-18 对 PC-03/08/09/17 的卡面依赖不豁免；
PC-04 继续 doing/blocked。systemd、Windows SCM、TUN、
Web/REST/WS 和完整 Xray 配置均不在本阶段范围内。

本提交不代表完整 PC-18/PC-04 结卡。本记录未提交 Git，
未授权合并、部署或对外发布。

## 挂起任务（当前全量快照）

继承最近已审交接；本轮不解挂任何项目。

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无 suspended 项；本次 PC-18 未认领、等待接口前置。
pRayShell 已 closed，无 suspended 项。
