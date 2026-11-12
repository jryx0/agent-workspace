# 接入提示词：安装并使用 zhn-docs-kb

> **用途**：给**另一个 agent**（另一台设备、另一个平台、另一个账号）用的可复制提示词。
> **用法**：把下面「一」的代码块整段发给目标 agent；把 `<AGENT_NAME>`、`<DEVICE_NAME>` 换成实际值。
> **不要**把本文件内容抄进目标 agent 的全局规则——全局规则只放一行指针（见「二」）。

---

## 一、标准提示词（有技能机制的 agent）

```text
【任务】在本机安装共享技能 zhn-docs-kb 并回报结果。只做这件事，不要顺手改其他文件、不要提交共享仓。

【这是什么】多 Agent 协同共享文档知识库的规范：文档放哪（~/.agent-docs 原件 + 百度网盘副本）、
怎么命名（委派 zhn-docs-std）、怎么建索引、怎么批量上传、多设备怎么感知变更。
权威原件在 ~/.agent-shared/skills/official-doc/zhn-docs-kb/SKILL.md，随共享仓 Git 同步。
你在本机装的是「单向副本」，永远不要编辑副本。

【步骤】
1. 更新共享仓（Windows 用 Git Bash：/c/Users/<user>/.agent-shared；Linux/macOS：$HOME/.agent-shared）
   cd ~/.agent-shared && git pull --rebase
2. 一键安装（装到本机已探测到的 agent 技能目录）
   bash ~/.agent-shared/env/install-skill.sh --all
3. 校验，必须全部 [OK]
   bash ~/.agent-shared/env/install-skill.sh --check
4. 若第 2 步报「未探测到任何 agent 技能目录」，改成指定目录安装：
   bash ~/.agent-shared/env/install-skill.sh --all --dest <你实际加载技能的目录>
   不确定装哪，就先跑 bash ~/.agent-shared/env/install-skill.sh --list 看现状再问我。
5. 若你的 agent 没有技能目录机制，停止安装，改为执行「二」的一行指针方案，不要复制正文。

【回报格式】（照抄这四行，缺一项算没做完）
- 安装位置：<绝对路径>
- 技能版本：<SKILL.md 里 version 的值>
- 校验结果：全部 [OK] / 有 [STALE] / 有 [DRIFT] / 有 [MISS]
- 能否复述：用一句话说出「文档该放哪、要不要同时写索引」（证明技能已生效）

【红线】
- 不修改、不手抄技能正文到任何规则文件（单一原件原则）；只改权威原件，改完我来提交。
- [STALE] 表示原件已升级、副本落后 → 重装即可；[DRIFT] 表示副本被本地改过或来源不明 → 报告我，不要手改副本"修好"。
- 不覆盖无安装标记的同名目录（脚本会拒绝）；确需覆盖加 --force，备份会被放到 ~/.agent-tools/backups/skills/。
- 不把任何 Token、密钥、账号信息写进技能、索引、Git。
- 不在你所在环境里新建第二套工作区（例如为了装工具而开 WSL 的第二个 ~）。

【多账号提醒】你如果有多个账号/多个版本（个人版、企业版、团队版），技能目录通常是机器级共享的，
不需要每个账号各装一份；但记忆、登录态、连接器凭证往往按账号隔离，不要跨账号复制凭证文件。
装完请确认「切换账号后技能是否还在」，并把结论告诉我。
```

---

## 二、没有技能机制的 agent：一行指针

不要复制正文，在该项目规则文件（如 `AGENTS.md`、`.trae/rules`、项目 `README` 的规则段）加一行：

```text
涉及文档存放/命名/索引/备份/同步时，读 ~/.agent-shared/skills/official-doc/zhn-docs-kb/SKILL.md 并按其约束执行。
```

长文本按需加载，指针常驻、正文不进规则文件。

---

## 三、人类侧验收清单

1. `bash ~/.agent-shared/env/install-skill.sh --list` 显示目标目录为「最新」。
2. 目标 agent 能报出版本号，且能复述「文档放 `~/.agent-docs`、要同时登记索引」。
3. 让它新建一份文档，检查：文件名符合 `YYMMDD｜类型｜主题`、索引有对应记录、没有双活副本。
4. 多账号场景：退出登录换另一个账号，确认技能仍在（技能目录是机器级的，理应不受影响）。
5. 升级链路：改权威原件 → commit + git sync → 各设备 `git pull --rebase` → 重装 → `--check` 全 `[OK]`。

---

## 四、常见报错对照

| 现象 | 含义 | 处理 |
|---|---|---|
| `[MISS] ... 未安装` | 该目录下没有副本 | 正常，跑安装 |
| `[STALE] ... 落后于原件` | 原件已升级 | 重装该技能 |
| `[DRIFT] ... 被本地修改` | 副本被手改，或来源不明 | 报告人类，不盲目覆盖 |
| `[SKIP] 已存在且无安装标记` | 可能是人工维护的同名技能 | 确认后再 `--force` |
| `未探测到任何 agent 技能目录` | 目录不在探测表内 | 用 `--dest` 指定 |
| 技能装了但 agent 不认 | 平台未重扫技能目录 | 重启会话；仍不认则改指针方案 |
