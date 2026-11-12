# 全局（规范 / 环境 / 共享工具）任务登记

> 对应 handoff 文件头 `项目: 全局`。本文件只承担 三-5 ⑤ 的**任务登记节**（append-only），用于规范、`env/` 工具、共享仓结构类任务的认领防撞；不记录项目业务事实。
> 建立：[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 16:55 UTC+8]（人类 16:44 指定「校验脚本由其他 agent 写」，此前全局任务无登记处）

### 任务登记节

`任务ID | 描述 | 认领agent | 状态` — append-only，认领先追加认领行，完成／放弃追加状态行，不改旧行。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 16:55 UTC+8] RL-001 | 编写只读规范校验脚本 `env/rules-lint.sh`（需求、验收与交付见 `handoff/2026-11-12-规范v2.6候选与RL-001任务卡-zhn-tbxg2iah-win.md` 第三节）；人类 16:44 指定由 workbuddy 以外的 agent 编写，workbuddy 审核 | （待认领，建议 trae） | todo

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 17:22 UTC+8] RL-002 | 规范 v2.7 逐节压缩（OPTIMIZATION.md C1–C5 去重与叙述移出、〇／三-5／三-4 压缩、其余 6 处摘要壳锚句化；语义零变化，只改 tmp/<agent名>/ 副本）；任务卡见 `handoff/2026-11-12-规范v2.6订正与RL-002任务卡-zhn-tbxg2iah-win.md` 第三节；**前置：RL-001 经 workbuddy 审核通过** | （待认领，建议 trae 或 codex） | todo

[@trae @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 17:15 UTC+8] RL-001 | 认领：编写只读规范校验脚本 `env/rules-lint.sh`（只读、纯 bash + POSIX 工具、不依赖 Python；验收含候选稿全 PASS、5 种变异 FAIL 退出码 1、v2.5 退出码 2） | trae | doing

[@trae @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 17:34 UTC+8] RL-001 | done（待 workbuddy 审核）：交付 `env/rules-lint.sh`（只读；纯 bash + POSIX 工具；字符数按 Unicode 计并自测 locale，回退 C.UTF-8）。验收：① 候选稿 `tmp/workbuddy/2026-11-12-rules-v2.6/` 六项检查全 PASS（C3 指针 18 条、C1 锚句 30 条、C2 9 卷、C4 跨卷引用、C5 红线 5 条、C6 L1 正文 1,304 字符），exit 0；② 5 种变异 M1–M5 均 FAIL 且 exit 1（M1 锚句在 --rules 未命中 / M2 指针字符数 6,580→6,581 / M3 删原编号行 / M4 裸引用「见 三-7」/ M5 红线④改回旧文案），副本已清理；③ 现行 v2.5 默认运行报「spec 目录不存在: global/spec」并 exit 2 | trae | done（待审核）

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 18:52 UTC+8] RL-001 | 复审**不通过，退回返工**：任务卡验收 3 项全部达标（候选稿 60 PASS／M1–M5 均由对应检查项捕获／v2.5 exit 2／只读）；必改 F1 L1 正文提取不兼容正式 `env/execution-enforcement.md` 的「### L1」代码块（落地后默认运行 C6 FAIL，阻断落地）、F2 取不到 L1 时 C5 静默跳过、F3 C5 只查 L1 不查常驻层（常驻层红线④回退仍 exit 0）；建议改 F4–F7。详情与返工提示词见 `handoff/2026-11-12-RL001复审退回返工-zhn-tbxg2iah-win.md` | trae | doing（返工）

[@trae @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 19:21 UTC+8] RL-001 | done（返工，待 workbuddy 复审）：已改 F1–F3 必改项与 F4–F7 建议项、F8 可选（锚句壳标签集合比对）。F1 `paste_body` 先找「粘贴正文」标题，找不到回退 `### L1` 标题下第一个代码块；F2 取不到 L1 正文时 C5 与 C6 均报 FAIL；F3 C5 改为每条红线「常驻层写法|L1 写法」两侧都查，注释标注来源候选稿 `rules.draft.md` 45–49 行（〇⑦ ③ 1–5 条）；F4 C3 单独扫全部 `(global/)?spec/X.md` 指针查存在性、内联正则兼容无 `global/` 前缀；F5 `valid_ref_pat` 传入目标卷，只认 `〔spec/$tgt〕`；F6 C4 键改 `二-[0-9](\.[0-9])?`；F7 C3 区分「分流表」「内联指针」文案。验收：① 候选稿默认三参数（`--l1` 用候选稿 `execution-enforcement.draft.md`）67 项 PASS，exit 0；② `--l1 env/execution-enforcement.md`（现行 L1）→ C6 取到 1,464 字符 PASS、C5 红线④ L1 缺 FAIL，exit 1（预期，落地换新文本后通过）；③ M1→C1 / M2→C3 / M3→C2 / M4→C4 / M5→C5 全 FAIL exit 1；F2→C6+C5 双 FAIL、F3→C5 常驻层 FAIL、F4→C3 指针不存在 FAIL、F5→C4 目标错 FAIL，F6（`二-0.5〔spec/layout.md〕`）应 PASS 实际 PASS；④ 现行 v2.5 默认运行报「spec 目录不存在: global/spec」exit 2；⑤ 变异副本在 `tmp/trae/`，已清理；`global/`、`tmp/workbuddy/` 零改动 | trae | done（返工，待复审）

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 20:22 UTC+8] RL-001 | 二审**不通过，退回小返工**：F1（落地后默认运行 exit 0 已验证）、F2、F4–F8 达标；必改 G1 C5 常驻层一侧在全文查短语，只回退〇⑦③第 4 条红线时被第 75 行 v2.6 变更记录的同句命中而误报通过（F3 未真正修好）；G2 第 4 条 L1 短语缩短丢了「（rules.md 与 spec/）」范围限定。详情与提示词见 `handoff/2026-11-12-RL001二审与RL002未交付-zhn-tbxg2iah-win.md` | trae | doing（二次返工）
[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 20:22 UTC+8] RL-002 | 核查：无认领、无交付（人类称已完成，实为 RL-001 返工）；前置未满足，继续 todo | （待认领） | todo
