# 全局（规范 / 环境 / 共享工具）任务登记

> 对应 handoff 文件头 `项目: 全局`。本文件只承担 三-5 ⑤ 的**任务登记节**（append-only），用于规范、`env/` 工具、共享仓结构类任务的认领防撞；不记录项目业务事实。
> 建立：[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 16:55 UTC+8]（人类 16:44 指定「校验脚本由其他 agent 写」，此前全局任务无登记处）

### 任务登记节

`任务ID | 描述 | 认领agent | 状态` — append-only，认领先追加认领行，完成／放弃追加状态行，不改旧行。

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 16:55 UTC+8] RL-001 | 编写只读规范校验脚本 `env/rules-lint.sh`（需求、验收与交付见 `handoff/2026-11-12-规范v2.6候选与RL-001任务卡-zhn-tbxg2iah-win.md` 第三节）；人类 16:44 指定由 workbuddy 以外的 agent 编写，workbuddy 审核 | （待认领，建议 trae） | todo

[@workbuddy @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 17:22 UTC+8] RL-002 | 规范 v2.7 逐节压缩（OPTIMIZATION.md C1–C5 去重与叙述移出、〇／三-5／三-4 压缩、其余 6 处摘要壳锚句化；语义零变化，只改 tmp/<agent名>/ 副本）；任务卡见 `handoff/2026-11-12-规范v2.6订正与RL-002任务卡-zhn-tbxg2iah-win.md` 第三节；**前置：RL-001 经 workbuddy 审核通过** | （待认领，建议 trae 或 codex） | todo

[@trae @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 17:15 UTC+8] RL-001 | 认领：编写只读规范校验脚本 `env/rules-lint.sh`（只读、纯 bash + POSIX 工具、不依赖 Python；验收含候选稿全 PASS、5 种变异 FAIL 退出码 1、v2.5 退出码 2） | trae | doing

[@trae @zhn-tbxg2iah-win~zhn-x-w 2026-11-12 17:34 UTC+8] RL-001 | done（待 workbuddy 审核）：交付 `env/rules-lint.sh`（只读；纯 bash + POSIX 工具；字符数按 Unicode 计并自测 locale，回退 C.UTF-8）。验收：① 候选稿 `tmp/workbuddy/2026-11-12-rules-v2.6/` 六项检查全 PASS（C3 指针 18 条、C1 锚句 30 条、C2 9 卷、C4 跨卷引用、C5 红线 5 条、C6 L1 正文 1,304 字符），exit 0；② 5 种变异 M1–M5 均 FAIL 且 exit 1（M1 锚句在 --rules 未命中 / M2 指针字符数 6,580→6,581 / M3 删原编号行 / M4 裸引用「见 三-7」/ M5 红线④改回旧文案），副本已清理；③ 现行 v2.5 默认运行报「spec 目录不存在: global/spec」并 exit 2 | trae | done（待审核）
