# zhn-docs-std 升 v1.1.0 与 agent-docs 年份前缀补加

- **项目**: 全局（技能规范 + 文档同步区，无项目任务卡）
- **执行者**: workbuddy @ zhn-tbxg2iah-win
- **时间**: 2026-11-11 18:51–19:0x UTC+8
- **档位**: T2（写共享仓 + Git 推双远端），开工简报已出（规范 v2.0，10 步自检通过）

## 一、任务与结果

人类指令「更新 zhn-docs-std 加两位年份 + 现有 agent-docs 合规文件名加上今年」，清单经人类逐项确认后执行。

1. **技能升版 v1.1.0**：`skills/official-doc/zhn-docs-std/SKILL.md`
   - §2 命名格式 `MMDD｜类型｜主题.扩展名` → `YYMMDD｜类型｜主题.扩展名`（两位年份居前，2026-11-02 → `261102`）；「修改已有文件保持原 YYMMDD」
   - frontmatter version/description/关键词、§5 输出约定、§8 三处示例同步；§7 追加变更记录行
   - 单向复制到平台副本 `~/.workbuddy/skills/zhn-docs-std/SKILL.md`，**SHA256 双方一致** `feac9a87…c82b`；无裸 MMDD 残留
2. **agent-docs 存量改名 19/19**：全部合规文件日期段前补 `26`（`0921｜…`→`260921｜…`、`1102｜…`→`261102｜…`、根目录 html → `261111｜账号｜账号信息整理.html`）。改名前 grep 共享仓 memory/handoff/env **无任何引用旧名的 `docs://` 链接**，无断链；全目录备份 `/tmp/agent-docs-backup-20261111/`；终检 YYMMDD 格式 19 个、旧格式残留 0。
3. **未动**（人类明确）：文件夹名（含 `技术资料/0924｜文档｜多agent协同提示词/`）、8 张 prnmgt UI 截图 png、3 张内嵌 assets jpg。
4. **引用迁移规则**：旧文件名前 4 位日期前补 `26` 即得新名；其他设备/记忆中引用旧名时按此换算。

## 二、合规记录

- 本会话未安装任何依赖（tools-scan --check 通过，stamp 11-08 未满 30 天）；未部署；未认领任务卡。
- `memory/projects/prnmgt.md` 仍有 trae 活跃未提交改动，全程未触碰、未代提交、未强 rebase；`git pull --rebase` 因此中止，但 proxy-check 确认 local=origin=backup=f2d5b81 三方一致，无需拉取。
- 提交为精确 `git add`（技能文件 + org.md + 本 handoff），未带入他人改动。

## 三、挂起任务（跨项目全量快照 · 8 字段 · 滚动继承自 18:45 stockdb handoff，本轮无新增无解挂）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | **S1** T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停，合并为一次 ALTER + 一次部署 | S3 人类裁定 + 新 ADR 批准 + 重编卡面 | 无 worktree；卡面 todo | 重编卡面后重新认领 | 人类 |
| prnmgt | **S2** P0 二次真机调研 | 2026-11-11 人类确认 | 富士 CWIS 无单双面统计，厂家后台升级中 | 厂家升级完成 + 复跑三台探测 + 更新调研文档 | tmp 快照保留；worktree 已 remove | 续跑不重开卡 | 人类 |
| prnmgt | **S3** v4 批次 / #18 | 2026-11-07 15:11 | 纸张消耗口径重编，数据可行性未定 | S2 结论 + D-5~D-10 逐条人类裁定 + 新 ADR | 仅 DRAFT，未写卡面 | 裁定后重编拆卡再认领 | 人类 |

**已解挂/不计入防撞**：prnmgt S4 T-064 已解挂回 todo，trae 18:12 已认领 doing。防撞集合含 doing/open/suspended。

## 四、待人类裁决／处置（滚动继承，不计入挂起快照）

- stockdb 根治四项 + 22:00 轮次复核（待派工）；prnmgt T-063 已合并未部署（ALTER/DML/部署归人类）；11-08 requests 用户级违规副本 + `/tmp/pwtest` 待裁决；MCP 9101 offline（需人类运行 `env/start-mcp.bat`）；L3 钩子未启用。

## 五、关键文件与下一步

- 关键文件：`skills/official-doc/zhn-docs-std/SKILL.md`（v1.1.0）、`~/.workbuddy/skills/zhn-docs-std/SKILL.md`（同源副本）、`memory/org.md` 18:59 条目、备份 `/tmp/agent-docs-backup-20261111/`
- 下一步：① 若其他设备 agent-docs 同步出现旧名/新名并存冲突，由人类在同步客户端处理（本技能 §6 红线）；② 后续新建 agent-docs 文件一律按 YYMMDD 出建议名；③ 备份目录确认无异常后可清理。
