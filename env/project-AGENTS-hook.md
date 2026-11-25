# Project Rules Hook Template (`env/project-AGENTS-hook.md`, v3.0)

> **单一原件原则（`global/spec/governance.md#S9.2a`）**：
> - 平台全局指令（L1）唯一原件在 `env/execution-enforcement.md#L1`，**本文件不再重复粘贴 L1 文本**。
> - 本文件只维护 `~/source/<项目>/AGENTS.md`（或 `CODEBUDDY.md`）首部挂接块与验收提示词。

## 1. Project `AGENTS.md` / `CODEBUDDY.md` Header Block

粘贴到每个 `~/source/<项目>/AGENTS.md`（及并存的 `CODEBUDDY.md`）**最顶部**：

```markdown
<!-- global-rules-hook v3.0 -->
> **全局协同规范（最高优先级）**：本文件服从 `~/.agent-shared/global/rules.md` (v3.0)。
> - 单项目纯本地代码/测试（不写 `~/.agent-shared` / `~/.agent-tools`、不装依赖、不改卡、不部署、不推远端）可走 **T1.5**：先查 `~/.agent-shared/memory/suspended.md` 与 `memory/projects/<项目名>.md` 确认未挂起且未被他人认领，遵守 `R1-R5`。
> - 涉及写共享仓/工具区、装依赖、认领/改卡、部署或 `git sync` 必须升 **T2**：读 `global/rules.md` 与所需 `global/spec/*.md`，执行 `bash ~/.agent-shared/env/startup-check.sh --project <项目名>` 并在首个输出给出紧凑自检简报。
> - **不可豁免红线 `R1-R5`**：密钥不入 Git；禁全局/用户级装依赖；不与人类并行改配置、同步区删除交人类 UI；不改 `global/` 规范正文；不碰他人未提交改动。
<!-- /global-rules-hook -->
```

## 2. Hook Verification Prompt

新开会话进入目标项目，发送：
```text
不写任何文件，先确认当前应走 T0 / T1.5 / T2 哪一档，并回报本项目是否挂接了 global/rules.md v3.0 以及 memory/suspended.md 中与本项目相关的挂起项。
```
通过标准：准确声明档位、识别 `global/rules.md` v3.0 挂接、准确列出 `memory/suspended.md` 中该项目的挂起任务。
