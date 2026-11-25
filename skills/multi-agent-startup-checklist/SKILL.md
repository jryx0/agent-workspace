---
name: multi-agent-startup-checklist
description: "多 Agent 开工前档位判定与自检入口指针，指向 global/rules.md (v3.0) 与 env/startup-check.sh。"
agent_created: true
version: 3.0.0
---

# Multi-Agent Startup Pointer (v3.0)

权威规范：`~/.agent-shared/global/rules.md`（不在此复述正文）。

## 执行步骤
1. **首条输出先判档位**（`rules.md#S0.2`，拿不准升一档）：
   - `T0` 纯只读 / `T1` 非 `~/source/` 单会话：守 `R1-R5`，免自检。
   - `T1.5` 单项目本地代码开发：读该项目 `AGENTS.md`，查 `memory/suspended.md` 与项目记忆防撞，守 `R1-R5`。
   - `T2` 协作默认：读 `rules.md`（及 `S0.4` 所需 `spec/`），跑 `bash ~/.agent-shared/env/startup-check.sh [--project <名>]`，首条输出发 3–6 行紧凑自检简报后开工。
2. **不可豁免红线**：`R1` 密钥不入 Git；`R2` 禁全局/用户级装依赖；`R3` 不并行改人类正配资源、同步目录删除交人类 UI；`R4` 不改 `global/` 规范；`R5` 不碰他人未提交改动。
