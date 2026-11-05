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

[@workbuddy @zhn-tbxg2iah-win 2026-11-05 09:45 UTC+8] 【生产数据核查：设备缺口 + IP 调整影响】人类重登 wrangler 后跑完 6 组只读 SQL（plan-2026-11-04-device-gap.md §2），全程未写库。事实：① 台账在用 16 台（非人类以为的 15；PRN015 已于 11-02 启用且采集正常，11-04 新加入采集配置的是 PRN013/014/016）；② PRN013/014/016 在 device_daily 零行（全历史无任何快照）→ 总览 by_device 口径（在用∩有非基线快照）现应显示 13 台，人类看到的 12 台是 11-02 前（PRN015 启用前）的口径；③ 11-04 collect_run partial：total=16 ok=11，失败 5 台——PRN008（.240 京瓷凭据被拒）、PRN009（.247 HTTP 500）、PRN013（凭据被拒/降 GUEST）、PRN014（10.113.213.248 ConnectTimeout，**213 段与全网 110/123/124/125 段不符，疑似手误**）、PRN016（.124.249 ConnectTimeout）；④ **PRN008/009 台账 IP+位置已互换**（10-22 镜像：008=.247/17楼西、009=.240/17楼北 → 现 008=.240/17楼北、009=.247/17楼西），人类确认「编号↔型号不变，仅 IP 调整」；⑤ 数据完整性结论：11-01~03 历史行按旧 IP 采集、编号归属正确，11-04 失败未写任何行，Q6 零重复/多 IP → **无串号、无脏数据**，仅 008/009 缺 11-04 一天；⑥ failed_json 自带 device_no，R3（IP 兜底认错设备）未触发。根因定位：failed_json 里 PRN008 记录 brand=kyocera 但 model=Apeos 3560（富士）同条矛盾 → **采集端 config 的 IP→品牌/凭据映射仍为旧 IP**（device_no→IP 已跟随新台账），PRN008 在 .240 被用京瓷凭据探测、PRN009 在 .247 被用富士协议探测，故双双失败。待办（运维，非代码）：采集端按新 IP 更新凭据映射、补 013/014/016 账密、核对 014 的 213 段 IP 手误、ping 验证 016；修好后当晚 20:10 自动恢复 16 台。遗留：11-04 的 008/009 行缺失不回补（日粒度统计容忍，待人类如有异议另立卡）。plan 文档与 .login-out.txt 仍未跟踪，待人类确认后处理。

[@workbuddy @zhn-tbxg2iah-win 2026-11-05 09:56 UTC+8] 【任务登记 T-044 + 根因代码级确认】人类确认「编码↔型号绑定不变，仅 IP 调整」并拍板方案 1+2 合并。代码级根因（collector/printer_monitor/collector.py）：:128 `cred = cfg.credentials.get(ip)`（凭据以 IP 为键）、:150 `brand = cred["brand"]`（协议跟凭据走）→ IP 调整即静默错配；:152-162 厂商一致性告警只 WARN 不阻断；漂移检测只查单向。计划定稿并入库：master 2b7a074（docs/plan-2026-11-05-cred-by-device-no.md + tasks.md T-044 卡，todo）。**任务登记节**：`T-044 | 采集端凭据按设备编号匹配+品牌随设备（collector 4文件+1新测，worker零改动） | 待认领 | open`。执行 agent 走 worktree `~/source/prnmgt.wt/<agent名>` + `agent/<agent名>/credentials-by-device-no`，准出后由 workbuddy 审核合并；生产采集服务器 config 迁移（IP键→编号键）与上线由人类运维执行。

[@workbuddy @zhn-tbxg2iah-win 2026-11-05 10:57 UTC+8] 【分支合并与 worktree 清理】人类批准后合并两个 agent 分支进 master 并推送 origin（1f0581c）：① `agent/workbuddy/wrangler-localization`（e5d01e8，wrangler 4.157.0 项目本地化 + .gitignore 加 worker/node_modules/）→ 合并 047b8a1；② `agent/workbuddy/agents-md-hook`（85de576，AGENTS.md 第 10 行新增「0. 全局规范」首项挂接）→ 合并 1f0581c。关卡 0 问题（2 条历史拆卡提示不变）；主仓库署名仍为 张皓 <hao.zhang@gmail.com>，未被污染。清理：两个 worktree 已 remove、分支已删、prune 完成，`~/source/prnmgt.wt` 现为空容器（留给 T-044 执行 agent 按自己名字新建）；`.git/info/exclude` 里临时加的行已移除（.gitignore 已覆盖）。`worker/node_modules` 保留可用，`wrangler --version` → 4.157.0。主仓库仍有两个未跟踪文件：`.login-out.txt`（登录输出，勿提交）、`docs/plan-2026-11-04-device-gap.md`（待人类决定是否入库）。T-044 仍为 todo 待认领。

[@trae @zhn-tbxg2iah-win 2026-11-05 11:15 UTC+8] 【任务认领】T-044 | 采集端凭据按设备编号匹配+品牌随设备 | 认领 by trae | trae@zhn-tbxg2iah-win | doing。worktree `~/source/prnmgt.wt/trae` + 分支 `agent/trae/credentials-by-device-no`。硬红线：只改 collector/ 目录 4 文件 + 新增 1 unittest，worker/ ref/ schema.sql tools/ 零改动；不部署生产。

[@trae @zhn-tbxg2iah-win 2026-11-05 11:26 UTC+8] 【T-044 完成】分支 `agent/trae/credentials-by-device-no`（commit b62a6f3）推 origin，5 文件改 443 行（+443/-59）。准出：unittest 8/8 全绿（Python 3.14.2）、主仓库 `check.mjs` 0 error。改动：config.py（credentials 键 device_no + IPv4 ConfigError + brand 可选）、collector.py（brand 恒取 vendor + cred.brand 不一致阻断 + 漂移检测改 device_no）、example.json（示例改编号键）、tests/__init__.py + test_credentials.py（新增 8 用例）。worker/ref/schema.sql/tools 零改动。等 workbuddy 审核合并。

[@workbuddy @zhn-tbxg2iah-win 2026-11-05 11:33 UTC+8] 【T-044 审核通过并合并】workbuddy 逐项过计划 §6 六条清单：改动仅 collector/ 5 文件（worker/ref/tools/schema 零触碰）；unittest 8/8 审核人亲跑全绿（Python 3.14.2，纯 mock 无真实网络，含 IPv4/IPv6 键 ConfigError、brand 恒取 vendor、不一致阻断、缺省不校验、回退默认、漂移 ERROR）；ConfigError(MonitorError→Exception) 不被 except ValueError 吞（已核实 util.py:27）；failed_json brand 语义变更对消费方无影响（overview_stat.js:104 只读 device_no/ip、web collect.js 不读 brand）；check.mjs 0 问题。偏差：+443 行超「单卡<300行」红线，超出全为计划要求的测试文件（362 行），判可接受并记入卡内。合并 0b2b55d → T-044 收官 312c160 → 已推 origin/master；gitleaks 0 leaks；worktree prnmgt.wt/trae 已移除、本地+远端分支已删。**T-044 done，43+1=44 张卡 44 done 0 todo 0 blocked。** 下一步全为人类运维（计划 §7）：采集服务器 config IP 键→编号键（PRN008=富士、PRN009=京瓷、补 PRN013）、核对 PRN014 213 段、ping PRN016，当晚 20:10 预期 total=16 ok=16。遗留：主仓库未跟踪 .login-out.txt（勿提交）与 docs/plan-2026-11-04-device-gap.md（待人类定夺）。

[@workbuddy @zhn-tbxg2iah-win 2026-11-05 11:38 UTC+8] 【运维账密给定】人类给定品牌统一账密：富士全部 4000/4000、京瓷 admin/admin（注意：仓库示例 kyocera 默认原为 Admin/Admin，已按人类口径改为 admin/admin，fb0e311）。已写入 plan-2026-11-05 §7：因统一账密可入 default_credentials，生产 config 迁移可简化为「删除全部 IP 键旧条目、清空 credentials、靠品牌默认回退」。两个待观察点：① 京瓷大小写——若当晚 admin/admin 被拒则试 Admin/Admin（设备面板可能大小写敏感）；② PRN011-04 富士默认 4000/4000 曾被拒，若今晚仍拒则需真实密码。

[@workbuddy @zhn-tbxg2iah-win 2026-11-05 12:05 UTC+8] 【T-044 已部署生产采集服务器并实测生效】人类授权并现场提供 jifang 密码（一次性使用，未落盘）。动作：① 备份 collector.py/config.py/config.prnmgt.json → 服务器 ~/backup-20261105/；② 上传 T-044 两文件（sed 去 CRLF + py_compile 通过）；③ config.prnmgt.json：删除全部 11 个 IP 键 → credentials={}，default_credentials 保持 kyocera Admin/Admin（人类二次确认大写，首次说小写为口误）+ fuji 4000/4000；④ 实测发现空凭据表被 config.py 误拒（非空校验遗留）→ 热修：允许空对象，d25330d 已入 master（+test 9/9），同步上传；⑤ 12:02 手动触发状态采集实测：成功 13/失败 3（此前 11/5）——PRN008 成功（设备报 1 项自身故障，采集链路正常）、PRN009 成功；PRN013 仍凭据被拒（实测 4000/4000 被拒，密码疑改过，人类将逐台核实）；PRN014(213段)/PRN016 仍 ConnectTimeout（人类排查网络）。服务器非 git 检出且无 git，更新靠 pscp 传文件。今晚 20:10 数据采集预期 13~14 台 OK。

[@workbuddy @zhn-tbxg2iah-win 2026-11-05 12:15 UTC+8] 【任务登记 T-045/T-046 + 计划定稿】人类提出显示口径变更（两条）：① 总览按打印机=全部在用设备可见，无数据/错误显示 - 并备注原因，IP 变可点击链接跳打印机后台；② 采集明细的数据/状态两个视图同样全量显示在用设备，错误标识。计划定稿入 master（docs/plan-2026-11-05-show-all-active-devices.md + tasks.md T-045/T-046 卡，均 todo）。**登记节**：`T-045+T-046 | 在用打印机全量显示（总览+采集明细，同一 worktree 顺序做） | 待认领 | open`。关键点：overview.by_device 与 collect_detail 均为差分覆盖路由，此变更为有意的产品口径偏离 → 必须 OPEN-DECISIONS #13 登记 + harness 标注；null≠0 红线；web_assets.js 只能 build 生成禁止手改（CRLF 坑）。执行 agent 走 worktree ~/source/prnmgt.wt/<agent名> + agent/<agent名>/show-all-active-devices，准出后 workbuddy 审核；生产 Worker 部署由人类执行。
