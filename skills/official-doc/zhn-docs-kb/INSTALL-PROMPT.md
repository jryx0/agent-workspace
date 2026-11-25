# Agent Onboarding Prompt: `zhn-docs-kb` & `zhn-docs-std`

> 适用版本：`zhn-docs-kb` v1.0.0 / `zhn-docs-std` v2.0.0（对齐 `global/rules.md` v3.0）。
> 完整安装与多账号细则见同目录 `references/install.md`。

## 1. Copy-Paste Prompt (Agents With Skill Support)

```text
【任务】在本机安装共享技能 zhn-docs-kb 与 zhn-docs-std 并回报结果。只做这件事，不顺手改其他文件、不提交共享仓。

【步骤】
1. 更新共享仓：cd ~/.agent-shared && git pull --rebase origin main
2. 一键安装：bash ~/.agent-shared/env/install-skill.sh --all
3. 漂移校验：bash ~/.agent-shared/env/install-skill.sh --check（须全部 [OK]）
   - 若未探测到技能目录，用 --dest <实际目录> 指定；无技能机制则停止安装，仅在规则文件加一行指向 ~/.agent-shared/skills/official-doc/zhn-docs-kb/SKILL.md。

【回报四行】
- 安装位置：<路径>
- 技能版本：zhn-docs-kb=<version> / zhn-docs-std=<version>
- 校验结果：全部 [OK] / [STALE] / [DRIFT] / [MISS]
- 一句话复述：原件放哪、谁负责跨设备同步、飞书与网盘分别做什么、删除怎么处理

【红线】
- 禁止编辑技能副本、禁止抄正文进全局规则、禁止复制任何密钥/Token/~/.lark-cli/config.json、禁止全局安装 npm/pip、禁止改 global/ 规范正文。
```

## 2. Quick Troubleshooting

| Output | Meaning | Action |
|---|---|---|
| `[MISS]` | 未安装 | 运行 `install-skill.sh --all` |
| `[STALE]` | 原件已升级，副本落后 | 重新运行安装覆盖 |
| `[DRIFT]` | 副本被手改或来源不明 | 报告人类，勿盲目覆盖 |
| `[SKIP]` | 存在无标记同名目录 | 人类确认后加 `--force`（自动备份至 `~/.agent-tools/backups/skills/`） |
