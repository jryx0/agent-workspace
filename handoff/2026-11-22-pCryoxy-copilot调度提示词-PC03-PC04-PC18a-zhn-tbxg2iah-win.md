# pCryoxy｜copilot 调度提示词（PC-04 结卡 / PC-03 真机 / PC-18a 与后继卡）

- 发布: workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-22
- 用法：人类把下面“提示词正文”整段发给 copilot。人类发送这段提示词，即视为对其中所列授权（含推送 copilot 自己分支备份）的当次明确授权。

---

## 提示词正文

你是 copilot@zhn-tbxg2iah-win~zhn-x-w，pCryoxy 项目的执行方，本轮担任**总调度**：你负责把工作拆成多条泳道，派给你自己的子 agent 并行执行，由你统一做共享仓写入和交付。审核方是 workbuddy；没有它的裁定，任何卡都不算 done。

### 0. 开工前（T2，必须先做）

1. 按 `~/.agent-shared/global/rules.md` 第八节自检，并输出自检简报。
2. 必读以下文档，读完再派工：
   - 任务卡 `handoff/2026-11-22-pCryoxy-实施任务卡-v1.2-zhn-tbxg2iah-win.md`（**以它为准，v1.1 的 PC-18、单卡 PC-21 已作废**）；
   - `handoff/2026-11-22-pCryoxy-真机验证方案-v2-zhn-tbxg2iah-win.md`；
   - `handoff/2026-11-22-pCryoxy-done卡与PC04-ABIv2独立重跑复核及集成建议-zhn-tbxg2iah-win.md`；
   - `handoff/2026-11-22-pCryoxy-main未审提交追认与集成裁定-zhn-tbxg2iah-win.md`；
   - 项目仓 `docs/04-核查报告-20261121.md`；
   - `memory/projects/pCryoxy.md` 最近 40 行。
3. 现状：项目 `main` 已集成到 `6c5e5b3`（= `2908e4e` + 文档），`pc17`、`pc03`、`pc04` 已推到 origin。你的 pc03（`c73d59d`）、pc04（`44247c8`）基座都是 `2908e4e`，**不需要变基**。
4. 先处理遗留：
   - 提交共享仓里你自己那 3 份未入库的 handoff（`PC04-GeoLifecycle`、`PC04`、`PC18阶段A只读预检…-e64ae0ad`）；
   - 删除 pc04 worktree 里未跟踪的 `tests/integration/bridge/pc04-linux-amd64.a`；
   - 为 `90aa591`（Go 绑定冻结）提交一份“交付待审核”。

### 1. 调度规则（你和所有子 agent 都要遵守）

- **一条泳道 = 一张卡（或一个矩阵子集）= 一个分支 + 一个 worktree**（`~/source/pCryoxy.wt/copilot-<卡>`）。子 agent 只能改自己 worktree 里卡面允许的文件。
- **共享仓（`~/.agent-shared`）只由你本人写**：认领行、状态行、交付 handoff、git sync 都由你串行完成，写入时持有 `~/.agent-tools/run/git.lock`。子 agent 把结果写到自己 worktree 外的临时目录，交给你汇总。
- 先认领、后开工：每条泳道开工前，你在项目记忆追加认领行（卡号、分支、基座 SHA）。
- 状态只用 `todo / doing / blocked / done`，**不得写“有条件通过”**。缺真机、缺账户就标 `blocked` 并写明原因。
- 提交信息带卡号，末尾 `by copilot@zhn-tbxg2iah-win~zhn-x-w`，加 `Agent: copilot` 尾注。**在项目仓设置仓库级身份**：`git config user.name zhn-copilot`、`git config user.email copilot@zhn-tbxg2iah-win`，不要再用全局个人邮箱。
- 不合并 main、不推 main、不部署。**授权**：每次交付后，把自己的 `agent/copilot/*` 分支推到 origin 做备份。
- 复审申请由你（执行方）提交，不让审核方代写申请。交付里要分开写“执行方实测”和“请审核方复跑的命令”。
- 依赖要新增，或文件超出卡面范围：先在 handoff 里申请，不得自行扩大范围。
- 同一验收项连续两轮失败，就标 `blocked` 并报人类，不要无限补证。

### 2. 泳道与顺序

**泳道 A｜PC-04 结卡（最高优先级，整条关键路径都等它）**
- 按 v1.2 §2 的六条结卡条件，逐条写**结卡清单**：已证 / 未证 / 证据提交号。条件 ⑥（审核方独立重跑）已由 workbuddy 在 `44247c8` 上完成，62 PASS / 0 FAIL、archive `8a6d31a7…abff`。
- 把 `041c2db` / `eeac8a4` 的类别授权**改写成精确文件清单**。
- 补齐 ⑤ Linux 固定资产与桥运行检查。如果 `libpc04_abi.so` 会成为交付物，补可复现构建（F-25）。
- 提交“PC-04 结卡申请”。只有收到 workbuddy 的 done 裁定，才能开泳道 D、E。

**泳道 B｜PC-03 Windows（按真机验证方案 v2 §3、§5 的 W1～W6）**
- 先写预检和证据包脚本：逐项 `--exact` 运行，生成 `manifest.json` / `results.tsv`。
- W1～W4、W6 在当前账户下自动跑；先单独复现 1168（W4），定性是不是真实缺陷。
- W5 等人类建好 `pcx-t2` 账户和计划任务后再跑；人类没准备好之前，W5 标 `blocked`，不要再用 test1。
- 服务 SID / ACL 不在本卡，已移到 PC-10。

**泳道 C｜PC-03 Android（方案 v2 §4，A1～A3）**
- 复用共享仓 `scaffold/pc03-and-host/` 宿主（M6），不另造第二套。
- 设备：荣耀 TEL-AN10，API 29。先跑预检（屏幕亮着、无锁屏、安装设超时），再走 prepare → `adb reboot` → verify → cleanup 全自动流程。
- 预检不通过就输出 `ENV_BLOCKED` 和原因，请人类处理手机设置，不算测试失败。

**泳道 D｜PC-18a 宿主骨架（PC-04 done 后开）**
- 新卡号 PC-18a，分支 `agent/copilot/pc18a`，先认领。11-21 的“PC-18 阶段 A”预检材料只作为设计输入，不构成认领。
- 依赖：PC-04 done、PC-17 done、PC-03 的 Linux 后端与 `SecretStore` 接口（已审可用）。
- 验收按 v1.2 §4.1，其中“生产调用方必须经过 `ValidateRestrictedProfile` 和 `RegisterRuntime` 二次校验”由本卡承担。

**泳道 E｜PC-04b 受限 profile 扩展、PC-05（PC-04 done 后与 D 并行）**
- PC-04b 按 v1.2 §3：freedom、sniffing、finalmask、proxy/dns 逐项从拒绝清单移到允许清单，每项单独取证。某项实测做不到时**不得自行降级**，报人类裁决。
- PC-05 卡面同 v1.1。

**泳道 B 与 C 可以和 A 同时开始**；D、E 必须等 PC-04 done。同一时间最多 3 个子 agent。

### 3. 每轮收尾

1. 每条泳道交付一份 `handoff/2026-11-2x-pCryoxy-<卡>-交付待审核-copilot-zhn-tbxg2iah-win.md`，内容包括：精确提交 SHA、改动文件清单（核对卡面）、执行方实测、请审核方复跑的命令、证据包路径与 SHA-256、未覆盖项。
2. 项目记忆每个事件单独一行，时间用真实时间，不倒填。
3. 由你串行 commit + git sync 共享仓；推送自己的分支备份。
4. 向人类汇报：各泳道状态（四值）、阻塞项、需要人类做的一次性操作。
