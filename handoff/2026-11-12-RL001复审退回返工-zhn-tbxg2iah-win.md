# RL-001 复审结论：退回返工

> 项目: 全局（`memory/projects/global.md`）
> 审核方: workbuddy@zhn-tbxg2iah-win~zhn-x-w　时间: 2026-11-12 18:46 UTC+8
> 被审交付: `env/rules-lint.sh`（提交 `6c5d178`，trae，17:36）
> 结论: **不通过，退回 trae 返工**。任务卡验收的 3 项全部达标，但另有 3 处必改，其中 F1 会阻断 v2.6 落地。

## 一、已核实达标

| 项 | 结果 |
|---|---|
| 候选稿全量运行 | 60 项 PASS，exit 0；与 `_build/check.py` 结论一致 |
| 任务卡 5 种变异 M1–M5 | 全部被**对应**检查项捕获：M1→C1、M2→C3、M3→C2、M4→C4、M5→C5，exit 1 |
| v2.5 默认运行 | 报「spec 目录不存在」，exit 2，未误报 PASS |
| 只读约束 | 读源码确认：无写文件、无 git、无网络；locale 自测并回退 C.UTF-8 |
| 越界检查 | `global/`、`tmp/workbuddy/` 未被改动；`tmp/trae/` 已清理变异副本 |

## 二、必改（返工范围）

| # | 严重度 | 位置 | 问题（附复现） | 修法 |
|---|---|---|---|---|
| F1 | **阻断落地** | `rules-lint.sh:138-144` `paste_body` | 只认「粘贴正文」标题。正式 `env/execution-enforcement.md` 的 L1 在 `### L1 · 软注入强化` 下的第一个 ```` ```text ```` 块（第 27–40 行），没有该标题。复现：`--l1 env/execution-enforcement.md` 跑候选稿 → `FAIL C6 未找到…代码块`。任务卡 C6 已写明「落地后为 env/execution-enforcement.md 二-L1 代码块」。 | 先找含「粘贴正文」的标题，找不到再找以 `### L1` 开头的标题，取其后第一个代码块（容许 ```` ```text ````） |
| F2 | 重要 | `rules-lint.sh:244-266` | L1 正文取不到时只报 1 条 C6，**C5 整段跳过、无任何输出**，5 条红线等于没查。 | 取不到正文时 C5 同样报 FAIL（如「C5 无法检查：未取到 L1 正文」） |
| F3 | 重要 | `rules-lint.sh:254-259` | C5 只拿 5 个写死短语查 L1，**不查 `--rules` 一侧**；也没按任务卡在注释写来源行。复现：把候选稿常驻层红线④改回「不改 `global/rules.md` 正文」、L1 不动 → exit 0。任务卡 C5 的本意是两侧一致。 | 每条红线维护「常驻层写法（含反引号）＋ L1 写法」一对短语，两侧都须命中；注释写明来源（候选稿 `rules.draft.md` 第 45–49 行，〇⑦ ③ 1–5 条） |

## 三、建议一并改（不改不阻断）

| # | 位置 | 问题（附复现） | 修法 |
|---|---|---|---|
| F4 | `:167-170` C3 | 任务卡要求「所有 `spec/X.md`／`global/spec/X.md` 指向的文件都存在」，脚本只查带字数的指针。复现：常驻层加 `` `global/spec/nope.md` `` → exit 0。另外不带 `global/` 前缀的内联 `` `spec/X.md`（N 字符 `` 不解析。 | 单独扫一遍所有 `spec/*.md` 指针查存在性；内联正则改成 `(global/)?spec/` |
| F5 | `:147-149` C4 | 有效引用只看「后面跟了任意 `〔spec/…〕`」，不核对目标。复现：`三-7〔spec/accounts.md〕`、`三-7〔spec/nope.md〕` 都被判有效。报错文案却写的是「未紧跟 〔spec/$tgt〕」。 | `valid_ref_pat` 传入 `$tgt`，只认 `〔spec/$tgt〕` |
| F6 | `:223` C4 | `二-[0-9]` 不容 `二-0.5`。复现：合法的 `二-0.5〔spec/layout.md〕` 被报未标注。候选稿当前没有这种写法，所以没暴露，v2.7 压缩时可能出现。 | 键改为 `二-[0-9](\.[0-9])?`，有效式同步 |
| F7 | `:163` | 内联指针字数错时也报「分流表写 N」，同一卷会报两条一样的文案 | 区分「分流表」「内联指针」 |
| F8 | 可选 | anchors 清单整行被删时查不出来，因为没有基准 | 可选：比对常驻层锚句壳 `- 〔tag〕` 的标签集合与 anchors 清单的标签集合 |

## 四、返工验收

1. 候选稿默认三参数运行：exit 0。
2. **新增**：`--rules <候选稿> --spec <候选稿 spec> --l1 env/execution-enforcement.md` 运行时，C6 必须能取到正文（字符数 1,464）。C5 中常驻层④为新写法、L1 为旧写法，**应报 C5 FAIL**，这是 F3 修好后的正确行为；落地时 L1 换成新文本后即通过。
3. M1–M5 重测，并加测 F2、F3 两项的复现，以及已改的 F4–F6 复现，每项都须报对应 FAIL（F6 为应 PASS）。
4. 仍须满足：只读、纯 bash、v2.5 运行 exit 2。
5. 变异副本放 `tmp/trae/`，测完清理。**不得用 `eval`、反引号拼接或把 Markdown 当命令执行**（见第六节）。

## 五、给 trae 的返工提示词（可直接复制）

```
【RL-001 返工】按 ~/.agent-shared/global/rules.md 判定档位（写 env/，属 T2，先出自检简报）。
读 ~/.agent-shared/handoff/2026-11-12-RL001复审退回返工-zhn-tbxg2iah-win.md 第二至四节，修改 env/rules-lint.sh：
必改 F1（L1 正文提取兼容 env/execution-enforcement.md 的「### L1」代码块）、F2（取不到 L1 正文时 C5 也报 FAIL）、F3（C5 两侧比对 + 注释写来源行）；建议一并改 F4–F7，F8 可选。
约束：只读、纯 bash + POSIX 工具、不依赖 Python；不得改 global/、tmp/workbuddy/ 下任何文件；不得自行落地 v2.6。
变异测试副本放 tmp/trae/，用 sed/printf 改文件时不得 eval、不得把含反引号的 Markdown 放进命令替换；测完清理。
验收按第四节逐条执行，结果附在 memory/projects/global.md 的 RL-001 状态行（done（返工，待 workbuddy 复审））。
提交：scripts: rules-lint.sh 复审返工 F1-F3 by trae@zhn-tbxg2iah-win~zhn-x-w；提交前 fetch 比对远端，有他人未提交改动时不得 pull/stash；推送前跑 proxy-check.sh 再 git sync。
```

## 六、审核过程事故说明（workbuddy 自报）

做变异测试时，我把一条含反引号的 Python 变异命令放进 `eval`，反引号里的 `spec/deploy.md` 被 bash 当作命令替换，测试副本 `tmp/workbuddy/rl001-review/spec/deploy.md` 被当成脚本执行。其中第 9 行的 `` `git push` `` 实际执行了一次，推向上游 `backup/main`，返回 `Everything up-to-date`：本地、origin、backup 均仍为 `6c5d178`，reflog 无新条目，**没有推送任何内容**。同一行的 `` `wrangler deploy` `` 因本机未安装，报 command not found，**没有发生部署**。以 `> ` 开头的引用行被解析为重定向，全部失败，未产生文件；候选稿与仓库状态均未变。之后改用纯 Python 修改副本重测。

**教训**：变异或批量修改 Markdown 规范时，禁止 `eval`，禁止把文本放进双引号或命令替换；规范正文里含 `git push`、`wrangler deploy` 这类可执行片段，被误执行时有真实后果。是否把这条写进规范，交人类在 v2.7 时裁决。

## 七、挂起任务（当前全量快照 · 8 字段 · 继承自 `2026-11-12-T064二轮复审通过并收官` 第七节，本轮无新增、无解挂）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | **S1** T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停，合并为一次 ALTER + 一次部署 | S3 人类裁定 + 新 ADR 批准 + 重编卡面 | 无 worktree；卡面 todo | 重编卡面后重新认领 | 人类 |
| prnmgt | **S2** P0 二次真机调研 | 2026-11-11 人类确认 | 富士 CWIS 无单双面统计，厂家后台升级中 | 厂家升级完成 + 复跑三台探测 + 更新调研文档 | tmp 快照保留；worktree 已 remove | 续跑不重开卡 | 人类 |
| prnmgt | **S3** v4 批次 / #18 | 2026-11-07 15:11 | 纸张消耗口径重编，数据可行性未定 | S2 结论 + D-5~D-10 逐条裁定 + 新 ADR | 仅 DRAFT，未写卡面 | 裁定后重编拆卡再认领 | 人类 |

**不计入挂起**：prnmgt **S4 / T-064** 已 `done`（`81df1a3`，见上一份 handoff；分支与 worktree 保留原状，本会话未触碰）。全局 **RL-001 退回返工**（`doing`，trae）；**RL-002 前置未满足**，继续 `todo`，不得开工。
