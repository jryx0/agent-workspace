项目: pCryoxy
卡号: PC-04 阶段 A 配合
关联实施提交: `27d942badfa26afb2d0fb0b60009071881f035b9`
关联主 handoff: `2026-11-21-pCryoxy-PC04阶段A纯prepare与ABI-zhn-tbxg2iah-win.md`
当前状态: 交付待 WorkBuddy 复审；PC-04 仍为 doing / blocked

# PC-04 阶段 A 验证命令补记

## 执行过程中的失败记录

本补记区分工具启动失败与测试失败；以下前置尝试均未执行 Go 测试：

1. 一次定向复跑命令因 WSL 命令中的源路径变量未正确传入，`cp` 报 `cannot stat '/tests/integration/bridge/control_ipc_test.go'`。
2. 随后的定向复跑命令指向已不存在的 scratch `delivery-bridge` 目录，`cp` 报 `No such file or directory`。
3. 完整重放结束后，另一个 WSL 调用无法再次读取前一调用的 `/tmp/.../replay.log`；该日志临时目录不跨调用保留。完整脚本自身已退出 `0`，且结束输出已记录 ABI smoke、双构建比较及摘要。
4. handoff 暂存检查第一次因 Git 对中文路径的 quoting 与 PowerShell 字符串比较方式不一致而中止；随后以 `core.quotepath=false` 核对，确认仅新 handoff 一项已暂存，再单独提交。没有其他路径进入该提交。

随后从新建的隔离 scratch 目录运行固定 Xray 完整重放脚本，脚本退出码 `0`。普通测试、race 测试、ABI C smoke、双构建 `cmp` 均由带 `set -euo pipefail` 的脚本执行；没有 Go 测试失败被略过或改写。

## 边界与状态

- 以上工具路径/临时目录错误不代表代码测试失败，也不改变成功完整重放的证据。
- 完整执行命令、测试范围、摘要、未覆盖项见关联主 handoff。
- 实施分支：`agent/copilot/pc04`；worktree：`~/source/pCryoxy.wt/copilot-pc04`。
- 本补记只记录执行过程，不修改实现，不代表 PC-04 或 PC-18 结卡通过；未推送、未合并、未部署。

## 挂起任务（当前全量快照）

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无 suspended 项；PC-04 `doing / blocked` 是依赖阻塞，不是挂起。pRayShell 已 closed，无 suspended 项。本补记不解挂任何项目。
