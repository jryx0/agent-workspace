> **Source**: `global/rules.md` spec volume (v3.0, synced with `rules.md`)
> **Section**: `S9` (`S9.1`, `S9.2`, `S9.3`, `S9.4`)
> **Trigger**: 修订 `global/` 规范正文、执行 `env/rules-lint.sh`、查阅 v2.x 与 v3.0 编号映射时
> **Authority**: 与 `rules.md` 同等效力，受 `R4` 保护。

## S9. Governance

### S9.1 Amendment Authority & Process
- **S9.1a 审批权**：本规范（`global/rules.md` 与 `global/spec/*.md`）为活文档，修改权仅归仓库所有者（人类）。任何 Agent 不得擅自修改（`R4`）。
- **S9.1b 修订流程**：
  1. 在 `memory/org.md` 提出变更提案或缺陷事实，经人类明确批准后修改 `global/`；
  2. 同步更新受影响的 `env/` 模板、脚本与技能引用；
  3. 修改规范标题版本号与日期，并将精简变更记录追加至 `memory/archive/` 对应变更归档文件（禁止写长篇变更记录进常驻层 `rules.md`）；
  4. 提交前必须运行 `bash ~/.agent-shared/env/rules-lint.sh` 全部通过（exit 0），再执行 `env/git-sync.sh`。
- **S9.1c 副裁决人（Bus Factor）**：仓库所有者可在 `memory/devices/_devices.md` 指定一名可信人类协作者（拥有 Gitee/GitHub 写权限与独立备份私钥）作为副裁决人，仅在主所有者长期不可达时接管压缩与规范修订。

### S9.2 Authoring & Single-Source Conventions
- **S9.2a 单一原件**：条款正文只在 `global/rules.md` 或对应 `global/spec/*.md` 维护一次；`env/` 模板、项目 `AGENTS.md`、技能文件只放短指针与 `R1-R5`，不得复制大段正文。
- **S9.2b 抽象与实例分离**：规范正文不写本机具体设备名、账号取值、租户 ID、token 或文件路径实例；实例取值统一放在 `env/agents.md`、`env/repos.md`、`env/kb-endpoints.md`、`memory/devices/` 等登记表。
- **S9.2c 纯 ASCII 编号纪律**：
  - 章：`S0`~`S9`；节：`S3.5`、`S2.0b`；条：`S3.5a`；最小红线：`R1`~`R5`；档位：`T0` / `T1` / `T1.5` / `T2`。
  - 跨卷引用统一写法：`[spec/<file>.md#S<id>]`。
  - `global/` 正文及现行 `env/` 模板、脚本注释中禁止新增中文数字章节号（含中文数字与顿号/节号组合）与圆圈数字。历史归档与 append-only 记忆旧行不追溯改写。

### S9.3 Automated Lint (`env/rules-lint.sh`)
每次修改 `global/` 或 L1 注入模板后必须运行 `bash ~/.agent-shared/env/rules-lint.sh`，校验项：
- **L1** 路由完整性：`rules.md` 所有 `[spec/<file>.md#S<id>]` 指针均指向真实存在的分卷与真实存在的节号；`global/spec/` 下每份分卷均在 `rules.md` 被引用。
- **L2** 分卷头规范：每份 `global/spec/*.md` 前 6 行含 `> **Section**:`。
- **L3** 跨卷引用有效：分卷内所有 `[spec/<target>.md#S<id>]` 均指向真实存在的分卷与节号。
- **L4** 纯 ASCII 编号检查：`global/rules.md`、`global/spec/*.md`（除本文件 `S9.4` 历史映射表外）与 L1 模板正文不含旧中文编号或圆圈数字。
- **L5** 最小红线 `R1-R5` 对齐：`rules.md` `S0.3` 与 `env/execution-enforcement.md` L1 模板中 `R1-R5` 逐条命中。
- **L6** 体积上限：`env/execution-enforcement.md` L1 粘贴正文 ≤ 1,500 Unicode 字符；`global/rules.md` 常驻层 ≤ 12,000 Unicode 字符。

### S9.4 Legacy Numbering Map (v2.x -> v3.0, Read-Only Reference)
供查阅历史 `memory/` 与旧 `handoff/` 使用（历史文件不回改）：

| v2.x Old Ref | v3.0 New Ref | Location |
|---|---|---|
| `〇①` / `〇②` / `〇③` | `S0.1` (`S0.1a`-`S0.1c`) | `global/rules.md` |
| `〇④` / `〇⑥` | `S0.5` + `env/execution-enforcement.md` | `global/rules.md` / `env/` |
| `〇⑤` | `S9.2a` | `global/spec/governance.md` |
| `〇⑦` (T0/T1/T2 & 红线1-5) | `S0.2` (T0/T1/T1.5/T2) & `S0.3` (`R1-R5`) | `global/rules.md` |
| `一` | `S1` (`S1.1`-`S1.5`) | `global/rules.md` |
| `二` (`二-0/0.5/1/2/3`) | `S2` (`S2.0/S2.0b/S2.1/S2.2/S2.3`) | `global/spec/layout.md` |
| `三-1` | `S3.1` (`S3.1a`-`S3.1e`) | `global/rules.md` |
| `三-2` | `S3.2` (`S3.2a`-`S3.2f`) | `global/spec/memory-compaction.md` |
| `三-3` | `S3.3` (`S3.3a`-`S3.3b`) | `global/rules.md` |
| `三-4` | `S3.4` (`S3.4a`-`S3.4b`) | `global/rules.md` |
| `三-5` | `S3.5` (`S3.5a`-`S3.5e`) | `global/rules.md` |
| `三-6` | `S3.6` (`S3.6a`-`S3.6f`) | `global/spec/worktree.md` |
| `三-7` | `S3.7` (`S3.7a`-`S3.7f`) | `global/spec/deploy.md` |
| `三-8` | `S3.8` (`S3.8a`-`S3.8i`) | `global/spec/accounts.md` |
| `四` (`四-1`~`四-5`) | `S4` (`S4.1`-`S4.5`) | `global/spec/toolchain.md` |
| `五-1` | `S5.1` (`S5.1a`-`S5.1c`) | `global/rules.md` |
| `五-2` / `五-3` | `S5.2` / `S5.3` | `global/spec/backup.md` |
| `六` / `六-1` | `S6` / `S6.1` | `global/spec/secrets.md` |
| `七` / `七-1` | `S7` / `S7.1` | `global/spec/projects.md` |
| `八` (10步自检) | `S8` (`S8.1`-`S8.5` + `env/startup-check.sh`) | `global/rules.md` |
| `九` | `env/human-setup-checklist.md` | `env/` |
| `十` | `S9` (`S9.1`-`S9.4`) | `global/spec/governance.md` |
