---
project: global
date: 2026-11-25
author: antigravity@zhn-tbxg2iah-win~zhn-x-w
status: completed
---

# 规范 v3.0 正式落地与 Antigravity 接入登记

## 1. 结论与改动摘要
- **规范体系升级至 v3.0**：`global/rules.md`（10,735 字符，-54.9%）+ 10 份 `global/spec/*.md`（含新增 `spec/governance.md` 与 `spec/projects.md#S7.2` 跨项目编码底线），全量采用纯 ASCII 编号（`S0-S9`、`R1-R5`、`[spec/<file>.md#S<id>]`），旧编号映射留存于 `spec/governance.md#S9.4`。
- **分级与运行时减税**：新增 `T1.5` 项目本地开发档位；新增唯一挂起状态表 `memory/suspended.md`（含 `prnmgt` S1/S2/S3）；新增一键自检 `env/startup-check.sh`；`env/git-sync.sh` 内置 `proxy-check.sh`；删冗余 `global/AGENTS-startup.prompt.md`，瘦身 L1（991 字符）及全部启动模板。
- **文档技能对齐**：`zhn-docs-std` 升 v2.0.0，`zhn-docs-kb` 升 v1.0.0（方案 A：原件同步归统一同步工具，飞书仅单向预览+索引，拆分 `references/` 与 `env/kb-endpoints.md`）。
- **Agent 接入**：`antigravity` 已登记进 `env/agents.md`（设备 `zhn-tbxg2iah-win`、账号 `zhn-x-w`、端口段 `9400-9499`）。

## 2. 验证结果
- `env/rules-lint.sh`：`L1-L7` 全部 PASS（exit 0）。
- `env/startup-check.sh --project prnmgt`：实测通过，正确识别 v3.0、3 条挂起项与项目 hook。
- 并发安全（`R5`）：既有未提交的 `memory/projects/stockdb.md`、`skills/official-doc/zhn-work-summary/SKILL.md` 全程未触碰、未纳入本次提交。

## 3. 人类待办
1. 在各平台 UI（WorkBuddy 个人/企业版、Antigravity、Trae、Copilot）粘贴 `env/execution-enforcement.md#L1` 新版 991 字符指令并按 L3 验收；
2. 按需将各活跃项目 `AGENTS.md` 首部更新为 `env/project-AGENTS-hook.md` v3.0 挂接块；
3. 推送完成后可在需要时执行 `bash ~/.agent-shared/env/install-skill.sh --all && bash ~/.agent-shared/env/install-skill.sh --check` 同步本机技能副本。
