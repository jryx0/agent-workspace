# Execution Enforcement Plan (L1 / L2 / L3 — v3.0)

> 配套规范：`global/rules.md` (v3.0, `S0.1`, `S0.2`, `S0.3`, `S0.5`)。
> 目标：通过平台全局指令（L1）、一键只读脚本与校验（L2）、项目挂接与验收（L3），确保每次会话开工前执行正确的档位自检与最小红线。

---

## L1. Platform Global Instruction (Single Source of Truth)

> **使用方式**：将下方代码块整段粘贴到各 Agent 平台的全局指令/Custom Instructions（每个账号各自配置并验收一次，见 `[spec/accounts.md#S3.8d]`）。
> **长度红线**：≤ 1,500 Unicode 字符（由 `env/rules-lint.sh` `L6` 强校验）。禁止在其他文件复制本段全文，其他文件只指向本节。

```text
【开工前·档位判定（首个输出声明档位与依据，拿不准升一档）】规则权威：~/.agent-shared/global/rules.md (v3.0)。
- T0 纯对话/只读：不写文件、不装依赖、不碰共享仓/远端 → 免读规范、免自检简报。
- T1 本机单会话：仅写非 ~/source/ 临时本地文件，不碰共享仓/工具区、不装依赖/认领/部署/推送 → 仅守 R1-R5。
- T1.5 项目本地开发：仅读写单个 ~/source/<项目> 本地代码与测试，不写共享仓/工具区、不装依赖/改卡/部署/推送 → 读该项目 AGENTS.md，查 ~/.agent-shared/memory/suspended.md 与项目记忆防撞，守 R1-R5。
- T2 协作（默认）：写 ~/.agent-shared 或 ~/.agent-tools、装依赖、认领/改卡、部署、git sync、跨项目、首次接入或要求「开工前按规范自检」→ 读 rules.md + 按 S0.4 读所需 spec 分卷；跑 bash ~/.agent-shared/env/startup-check.sh [--project <名>]；动手前首个输出发 3-6 行紧凑自检简报（档位/版本/身份/同步锁/工具/挂起/认领/异常），简报后可直接继续。
【首次接入】新设备/新账号/新 Agent 首条输出须提示我按三段式 <主体>-<设备简标>-<OS段> 定名并询问是否虚机（S3.8）；未确认禁自取/署名/认领/部署。
【最小红线 R1-R5（永不豁免）】R1 密钥永不入 Git；R2 禁把依赖装进全局或用户级位置（按最终落盘位置判定，非命令写法：pip 落 %APPDATA%\Python\...\site-packages、pip --user、npm -g 全违规，装依赖转 T2）；R3 不并行改我正在配置的目录/工具/服务，云同步目录删除交我 UI；R4 不改 global/ 下规范正文（rules.md 与 spec/）；R5 不碰他人未提交改动、不代提交、不强 rebase。
【同步与收尾】装依赖先跑 tools-scan.sh --check；改共享仓 10 分钟内仅 add 自己改动并跑 env/git-sync.sh（已内置代理核对，异常即停报告，禁临时代理绕过）。
```

---

## L2. Automated Guards (Scripts)

1. **`env/startup-check.sh`**：T2 开工一键只读自检（版本、锁、git status、config 存在性、tools-scan、挂起表、最新 handoff、项目挂接）。
2. **`env/git-sync.sh`**：共享仓推送唯一入口，自动内置 `env/proxy-check.sh --quiet` 核对，异常即非零退出，禁止会话临时代理绕过。
3. **`env/rules-lint.sh`**：修改 `global/` 或 L1 模板后的硬校验门禁（`L1-L7`）。
4. **`env/tools-scan.sh --check`**：安装依赖前只读核对工具链基线与 30 天 stamp。
5. **全局链式 `gitleaks` hook**：`~/.agent-tools/hooks/pre-commit` 防密钥入库（`[spec/secrets.md#S6.1b]`）。

---

## L3. Verification Checklist (After Updating L1)

每次更新 L1 粘贴文本后，在每个账号下新开会话验收：
1. 发送纯只读问题 → 首个输出声明 `T0`，不跑脚本、不输出冗长自检表；
2. 发送单项目本地读/改小测试请求 → 声明 `T1.5`，读项目 `AGENTS.md` 并核对 `memory/suspended.md`；
3. 发送「开工前按规范自检」→ 声明 `T2`，执行 `bash ~/.agent-shared/env/startup-check.sh`，输出 3-6 行紧凑简报并准确报出 `v3.0` 与当前挂起项。
