# 规范注入端模板（配套 global/rules.md 〇 章，v1.8.5）

> 用途：把「去哪里读规范」的**短指针**放进两类注入端。按 〇 ⑤「单一原件」，**禁止把规范条款正文复制到这里或全局指令里**；规范正文只在 `global/rules.md` 维护。
> 本文件是模板，不是配置本身。实际生效内容以 WorkBuddy 设置界面 / 各项目 AGENTS.md 为准。

## A 段 · 平台全局指令模板（设置 → 个性化 →「给 WorkBuddy 的指令」，≤1500 字符）

人类已于 2026-11-05 09:15 完成粘贴。以下为基准模板，如 UI 中内容有调整，以 UI 为准。

```
【开工前必做】
1. 涉及文件/环境/代码/工具的操作前，先读 ~/.agent-shared/global/rules.md，执行其中「八、启动自检」标 [Agent自动] 的步骤；文件不存在就报告人类，不要自行猜规则。
2. 再读 ~/.agent-shared/handoff/ 最新一份 + memory/org.md 最近 200 行。
3. 装任何工具/依赖前先跑 bash ~/.agent-shared/env/tools-scan.sh --check；已装且达标就复用，禁止重复下载。禁止 npm install -g / pip install 全局安装；项目级 CLI 用 devDependency + npx。装完必须 --write 刷新清单并在 env/toolchain.md 追加变更日志。
4. 改过 ~/.agent-shared 内文件，10 分钟内 commit（type: 简述 by <agent>@zhn-tbxg2iah-win）并 git sync 推双远端；写完 handoff 立即提交。
5. 人类正在配置的目录/工具/服务不并行修改；云同步目录里的删除交给人类 UI 操作。
```

注意：全局指令**只在会话开始时注入**，改完必须新开任务才生效；当前会话不会重新加载。

## B 段 · 项目 AGENTS.md / CODEBUDDY.md 挂接块（放在「开工前必读顺序」首项）

```
0. **全局规范**：`~/.agent-shared/global/rules.md`（多设备多 Agent 协同总规范）——先读并执行「八、Agent 启动自检」，再读本项目下列文件；上下文中已含该规范全文或全局指令指针时视为已注入，无需重复加载。见规范 〇 ②③。
```

挂接规则（〇 ②）：
- `~/source/` 下每个项目都要挂；未挂接视为「接入未完成」，登记进 `memory/projects/<项目名>.md` 并提醒人类。
- agent 不得擅自改写项目规则文件；改动走 三-6 worktree + `agent/*` 分支，待人类合并。
- 项目自身规则与全局规范冲突时，以全局规范为准（协作纪律、Git 推送、密钥、工具链）。

## C 段 · 首次注入验证（〇 ④）

1. 新开一个任务，只发一句：`开工前按规范自检`
2. 预期：agent 主动读 `~/.agent-shared/global/rules.md` → 跑 `bash ~/.agent-shared/env/tools-scan.sh --check` → 读最新 handoff 与 org.md 最近 200 行
3. 未做到即注入失败：检查指令是否保存、是否为**新任务**、路径是否写对
4. 验证通过后，把结果按署名规范追加一条到 `memory/org.md`
