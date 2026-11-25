# New Agent Bootstrap Prompt (`env/new-agent-bootstrap.md`, v3.0)

> 用于新设备、新账号或新 Agent 首次接入时的一次性开场提示词。只做指针引导，不重复规范正文。

```text
请作为新接入 Agent 执行首次接入核对（先只读，不要擅自写文件或提交）：
1. 读取 `~/.agent-shared/global/rules.md` (v3.0) 与 `global/spec/accounts.md` (`S3.8`)；
2. 在本次首个输出中，向我确认：
   - 拟使用的已登记 agent 名（查 `env/agents.md`）与设备名（查 `memory/devices/_devices.md`）；
   - 按三段式 `<账号主体>-<设备简标>-<OS段>` 给出候选账号标识，并询问我「是否为虚机（是否加 v 前缀）」；
3. 运行 `bash ~/.agent-shared/env/startup-check.sh` 汇报当前环境状态、挂起任务与异常项；
4. 在我确认账号标识与登记前，不自取名字、不署名、不认领任务、不执行部署，严格遵守 `R1-R5`。
```
