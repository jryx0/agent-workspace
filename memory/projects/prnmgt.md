# prnmgt · 项目记忆

> 规范七要求：每个登记项目在 `memory/projects/<项目名>.md` 维护独立记忆文件。
> 格式：`[@agent @设备 YYYY-MM-DD HH:mm UTC+8] 内容`（append-only）

---

[@trae @zhn-tbxg2iah-win 2026-11-04 18:30 UTC+8] 项目基础信息登记

| 项 | 值 |
|---|---|
| 仓库地址 | https://github.com/jryx0/prnmgt.git |
| 默认分支 | master |
| 本地路径 | ~/source/prnmgt |
| 技术栈 | Cloudflare Workers + D1 + 原生 ESM JS + Python 采集端 |
| 状态 | 生产运行中（2026-11-02 旧系统退役） |
| 访问地址 | https://prnmgt.parva.dpdns.org |
| 采集服务器 | Ubuntu 10.113.224.20，/opt/prnmgt-collector |
| 规模 | 22 张表、46 条路由、204 文件、~5,471→拆分后多模块 |

---

[@trae @zhn-tbxg2iah-win 2026-11-04 18:30 UTC+8] 批次进度（全部 done）

B0 骨架关卡 → B1 镜像对比 → B2 公共层路由 → B3 低风险模块 → B4 统计核心 → B5 写入链路 → B6 弱网前端 → B7 收尾 → B8 双跑期 UI 对齐（T-039~T-043）

当前无活跃开发任务。下一阶段可能涉及：B9 优化方案（demo 同源投影 / 静态页搬 Pages / 部门正式名映射）、或产品决策后的新需求。

---

[@trae @zhn-tbxg2iah-win 2026-11-04 18:30 UTC+8] 项目不可碰清单（AGENTS.md 第五节）

- `ref/legacy-worker/**` — 只读化石，契约校验依赖它
- `worker/schema.sql` — 冻结契约，改 DDL 需 ADR
- `collector/printer_monitor/**` — 0 行改动
- `collector/config.prnmgt.json` — 含凭据，gitignore
- `tools/tests/fixtures/golden/**` — 黄金用例唯一真相

---

[@trae @zhn-tbxg2iah-win 2026-11-04 18:30 UTC+8] 悬而未决（OPEN-DECISIONS.md 当前 4 条 OPEN）

#8 多选费用关联后删除报表不解锁 — 旧缺陷，等价优先保留
#9 master/item delete 缺主键 500 vs upsert 400 — 旧不一致，等价优先保留
#10 toner/lifecycle_list 含非在用墨盒时 500 — 旧缺陷，等价优先保留
#12 MCP serverInfo.name 仍为 "printer-monitor" — 待 B7 切换决策时改名

---

[@trae @zhn-tbxg2iah-win 2026-11-04 18:30 UTC+8] 核心验收命令（三条必跑）

```bash
node scripts/check.mjs                       # 结构与架构关卡
node --test tools/tests/*.test.mjs           # 单测期望 113 pass
node tools/compare/verify_all.mjs            # 契约 46/46 PASS
```

[@workbuddy @zhn-tbxg2iah-win 2026-11-05 09:03 UTC+8] 【prnmgt 工具链整改】按规范 v1.8.4 四-4 ⑦，wrangler 由全局安装改为项目本地 devDependency 4.157.0（`worker/package.json` + `package-lock.json`），调用方式 `cd ~/source/prnmgt/worker && npx wrangler <cmd>`。改动在 `agent/workbuddy/wrangler-localization` 分支（e5d01e8，worktree `~/source/prnmgt.wt/workbuddy`），待人类合并；新设备 clone 后执行 `cd worker && npm ci` 即可复现，不再依赖任何全局安装。


[@workbuddy @zhn-tbxg2iah-win 2026-11-05 09:20 UTC+8] 【v1.8.5 〇 ② 挂接】AGENTS.md「开工前必读顺序」新增第 0 项指向 `~/.agent-shared/global/rules.md`；改动在 `agent/workbuddy/agents-md-hook`（85de576，worktree `~/source/prnmgt.wt/workbuddy-agents`），未动 master，待人类合并。另：主仓库 `.git/config` 的 user.name/email 已恢复为 张皓 <hao.zhang@gmail.com>（上次 worktree 内裸 `git config` 误改），今后本项目 worktree 提交一律用 `git -c` 指定独立身份。
