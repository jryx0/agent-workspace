# stockdb 源站恢复确认 · 引擎拉起待人工执行（v1.8.11）

> 编制：workbuddy@zhn-tbxg2iah-win · 2026-11-11 18:25 UTC+8
> **项目: stockdb, prnmgt**（挂起快照跨项目全量继承；按 v1.8.11 三-4 写项目标签）
> 依据：`~/.agent-shared/global/rules.md` **v1.8.11**（三-1 多项目加载 / 三-4 挂起快照 8 字段 / 三-7 部署权限 / 第八节 10 步）；上一份 handoff `2026-11-11-prnmgt-S4解挂与T064投喂-zhn-tbxg2iah-win.md`（第三节快照）、项目事实与红线见 `2026-11-11-stockdb-引擎离线诊断与跨项目边界固化-zhn-tbxg2iah-win.md`（17:36）。
> **本文件为最新一份 handoff**，按三-4 ② 承载「挂起任务（当前全量快照）」，取代前述文件快照载体地位；**未改写任何旧 handoff**。

---

## 一、本轮指令与结论

**人类 2026-11-11 18:19「源站已恢复，启动数据引擎下载数据」**＝对 17:36 handoff 第五节「stockdb 源站 521、引擎 7899 未拉起」待裁决事项的处置授权。

**结论：恢复动作未执行。** 授权成立、源站也已实测恢复，但按三-7「能确定」四条件中「部署命令来自项目 scripts 且本机可用、**无需交互登录**」不满足——本机无法非交互登录 NAS 执行 `docker exec`（详见第三节）。按「不能确定＝通知人类部署，禁止猜测、试部署」停下，给出可复制命令与自检项。**全程只读，未启停引擎/容器、未写 NAS 任何文件、未反复重试启动。**

## 二、只读验证（18:20–18:24）

| 检查 | 结果 |
|---|---|
| `http://ad.123128.xyz/`、`http://ah.123128.xyz/` | **404**（15:2x 为 Cloudflare 521）→ 源站重新响应，用户所说恢复属实 |
| `https://a.123128.xyz/version?v=0.3.5` | 302 → `https://dns.novapi.cc/version?v=0.3.5` 最终 **200**（此前 521）。脚本 `curl -s` 不带 `-L` 仍会拿到 302 空响应而打印「源站探测无响应」，但 09:00 成功轮次同样如此，**不构成阻断** |
| `http://10.113.124.232:7899/` | **连接被拒**（引擎仍离线） |
| `http://10.113.124.232:8080/`、`/sync.html` | 200；`/db/` 反代 502 |
| 看板快照 `generated_at=18:20:01` | 09:00 ok / 13:00 fail / **16:30 fail（engine_ok=false）**；`integrity.ok=true`（16 项全绿）；下一次自动轮次 22:00 |
| 共享仓 | HEAD `c80627b`，origin/backup 一致；本地他人未提交 `M memory/projects/prnmgt.md` 未触碰 |

## 三、卡点（为什么没执行）

1. **无 SSH 非交互登录能力**：`ssh -o BatchMode=yes` 对 `root / admin / zhn_x / zhn / haozhang / zjsj` 均为 `Permission denied (publickey,password)`；`~/.ssh/config` 无 NAS 条目，`config/` 只有 Oracle / printer / 通用 ed25519 三套与 NAS 无关（v1.8.11 七-1：项目级凭据不进 `config/`）。
2. Windows 凭据库有 `Domain:target=10.113.124.232 / zjsj`（SMB 映射用）；尝试读取并用于 SSH 的运行时 .NET / WinRT 调用**被平台安全策略拦截**，且规范明确项目级凭据「不落盘、不回显、不入 Git」，不绕过、不向人类索取口令、不猜测密码。
3. SMB `\\10.113.124.232\docker` 共享可读但**不能执行命令**；8080 只有静态页与 `/db/` 反代，无触发端点；`scripts/` 在容器内只读且无 watcher，写 SMB 无法自触发。
4. 17:36 handoff 第三节红线「恢复命令供人类执行，agent 不得自行执行」、第八节「stockdb 恢复须人类授权并执行，agent 只做只读探测与自检建议」；本轮人类授权不能消除**执行通道**这一客观卡点。
5. 按三-7「禁止猜测、试部署、把大概率没问题当确定」：源站恢复只说明启动**可能**成功，不能替代确定性；源站不可用期间也禁止反复重试。

## 四、挂起任务（当前全量快照 · 按「项目 + 任务ID」匹配 · 未解挂项一律禁止认领／开工）

> 完整继承上一份 handoff 第三节（本轮无新增挂起、无解挂）。**stockdb 当前无挂起任务卡**（源站/引擎事项属第五节待裁决，不计入快照）。

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | **S1** T-059 / T-060 / T-061 | 2026-11-07 15:0x 人类 D-4 | v3 三卡暂停，要合并成一次 ALTER + 一次部署 | S3 的人类裁定完成 + 新 ADR 批准 + 重编卡面写入 `tasks.md` | 无 worktree；卡面 `todo`；`docs/paper/exec-prompt-2026-11-07.md` 停用 | 重编卡面后重新认领 | 人类 |
| prnmgt | **S2** P0 二次真机调研 | 2026-11-11 人类确认 | 富士 CWIS 无单双面统计已实锤，厂家后台升级中 | 厂家升级完成 + 复跑三台探测 + 更新 `docs/paper/field-survey-2026-11-07.md` | `tmp/trae/p0-scan/`、`tmp/trae/field-survey/anon-probe/` 快照保留；凭据经环境变量不落盘；worktree 已 remove | 续跑，不重开卡 | 人类 |
| prnmgt | **S3** v4 批次 / `OPEN-DECISIONS.md` #18 | 2026-11-07 15:11 | 纸张消耗口径重编，数据可行性未定 | S2 调研结论 + #18 与方案 §8 的 D-5~D-10 逐条人类裁定 + 新 ADR 批准 | 仅 DRAFT 文档；未写卡面、未拆卡、未派工 | 裁定后重编方案与拆卡，再重新认领 | 人类 |

**已解挂／不计入防撞**：`prnmgt / S4 T-064` 17:48 解挂回 `todo`，trae 18:12 已认领 doing。防撞集合含 `doing/open/suspended`；`memory/projects/prnmgt.md` 仍有他人活跃未提交改动，本快照是开工防撞权威。

## 五、给人类：可复制命令与自检项

在 **NAS SSH 终端 / UGOS 桌面终端**执行（顺序：先拉起引擎，再下载数据）：

```bash
cd /volume1/docker/stockdb
sudo docker compose ps
sudo docker exec stockdb /stockdb/scripts/engine-ctl.sh status
sudo docker exec stockdb /stockdb/scripts/engine-ctl.sh start
sudo docker exec -d stockdb /stockdb/scripts/sync.sh
tail -f logs/sync_$(date +%F).log
```

- `engine-ctl.sh start` 会先探 `https://a.123128.xyz/version?v=0.3.5`；若返回 JS 挑战页/空会 `exit 9` 拒绝启动。现已实测跟随 302 后 200，数据源 404（在线），可正常启动。
- `sync.sh` 会**先停引擎 → 删 `data/disable` → 增量下载 → 无条件拉起引擎**；跑完必须复核引擎是否仍在线（历史上多次出现「同步结束引擎反而挂了」）。
- 也可不手动执行：若 `stockdb` 容器仍在运行，**22:00 定时轮次**会自动再试一次；但 13:00、16:30 连续失败且无守护，不能保证成功。

**线上自检（部署后必须立即做）**：

```bash
curl "http://10.113.124.232:7899/?cmd=get&t=日k:600519:*&json=1"    # 200 且取到最新交易日，只判 200 不够
curl -I http://10.113.124.232:8080/sync.html                          # 200，看板「引擎在线」「配置完整性 正常」
tail -30 /volume1/docker/stockdb/logs/sync_$(date +%F).log             # 出现「引擎已恢复服务」「result=OK」
du -sh /volume1/docker/stockdb/data /volume1/docker/stockdb/data1       # 数据量有增长
```

自检失败立即停下报告，给回滚建议（引擎可用 `engine-ctl.sh start` 单独补拉；数据目录不动），禁止反复重试。

## 六、待人类裁决／处置（滚动继承，不计入挂起快照）

| 项目 | 事项 | 状态 | 依据 |
|---|---|---|---|
| stockdb | **源站恢复已确认，7899 仍离线** | 18:2x 实测源站 404 / version 302→200；7899 拒连、16:30 fail。恢复动作待人类执行第五节命令 | 本文件第一/二/三节 |
| stockdb | 根治方向（未派工） | 源站不可达时不要停引擎、拉起失败加退避/守护、核对官方新域名并更新 `sync_url.txt` 与 `engine-ctl.sh` 探测 URL、查询页改同源 `/db/` 反代 | 17:36 handoff 第三节 |
| prnmgt | T-063 已合并但**未部署**；T-064 doing | 现网 ALTER / DML / 部署归人类 | 上一份 handoff 第四节 |
| 全局 | 11-08 requests 用户级违规副本 + `/tmp/pwtest` | 17:36 实测仍在，待人类裁决 | 四-5 ⑥ |
| 全局 | MCP 9101 offline / L3 钩子未启用 | 需人类运行 `env/start-mcp.bat`；钩子须先探针 | 八-2、〇⑥ |

## 七、关键文件

- `~/.agent-shared/global/rules.md`（v1.8.11）、`env/repos.md`（项目属性补充表：凭据落点 / 部署入口）、`env/handoff-suspended-template.md`
- `memory/projects/stockdb.md`（项目事实 + 15:25 诊断 + 18:25 本轮记录）
- `handoff/2026-11-11-stockdb-引擎离线诊断与跨项目边界固化-zhn-tbxg2iah-win.md`（17:36，项目事实与红线，禁止改写）
- `handoff/2026-11-11-prnmgt-S4解挂与T064投喂-zhn-tbxg2iah-win.md`（挂起快照来源，禁止改写）

## 八、下一步指令

1. 后续会话按三-1 各读最近一份带 `项目:` 标签的 handoff（stockdb 读本文件、prnmgt 读 17:48 那份）。
2. 领取任何卡前查 `memory/projects/<项目名>.md` 的 `doing/open` ＋ 本文件第四节 `suspended`，按「项目 + 任务ID」匹配。
3. **人类执行第五节命令后**，agent 可只做线上自检与留痕（不代替人类启停）；把部署时间、基线、部署者、自检结果写入 `memory/projects/stockdb.md` 与当日日志。
4. 触发解挂条件时：人类给证据 → 按模板第五节五步 → 写**新 handoff** 滚动继承未解挂项，禁止改写本文件。
