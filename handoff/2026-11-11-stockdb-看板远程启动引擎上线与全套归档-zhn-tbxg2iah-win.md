# stockdb 看板远程启动引擎上线 + 全套归档与重建提示词（部署留痕）

- **执行者**：workbuddy@zhn-tbxg2iah-win
- **时间**：2026-11-11 19:05–19:20（NAS 侧部署 19:11–19:15）
- **授权依据**：人类 18:51「对这个引擎进行修改」延续授权 + 本轮 19:04 两条指令（看板加启动引擎功能；全套归档至 agent-docs 并编制重建提示词）
- **共享仓基线**：`250768c`（本轮 NAS 部署时点）；本轮共享仓改动见第四节

## 一、任务结论

1. **看板远程启动引擎已上线**：同步看板（`http://10.113.124.232:8080/sync.html`）在引擎「无响应」时，数据引擎卡片出现「⚙ 启动引擎」按钮，点击即远程拉起，无需 SSH。全链路测试通过（含故障模拟端到端、同步中守卫、服务被杀 cron 自动拉回）。
2. **全套归档完成**：18 个文件 1:1 存入 `~/.agent-docs/脚本/NAS/stockdb-docker/`（含 11-11 最新版），主文档 `261111｜重建｜stockdb 引擎与看板重建提示词.md` 可交给任意 AI 在新系统重建整套引擎+同步+看板+远程启动。归档版 `webconf/default.conf` 中 token 已替换为占位符 `__STOCKDB_CTL_TOKEN__`（真实 token 只在 NAS：`conf/ctl.token` root 600 + nginx 配置内）。

## 二、新增架构（本轮上线）

```
浏览器 sync.html ──POST /ctl/start──▶ nginx:8080 /ctl/ ──(注入token头)──▶ 宿主 engine-ctl-server.py:7910
                                                                        （只绑 docker 网关 172.18.0.1，LAN 不可直连）
                                                                        ├─ 同步进行中 → 409 拒绝
                                                                        └─ docker exec stockdb engine-ctl.sh start
宿主 cron.d/stockdb-ctl：每分钟探活 /health，服务不在则拉起（重启/被杀自愈，实测 5s 内恢复）
```

安全设计：token 只存在于 NAS `conf/ctl.token`(600) 与 `webconf/default.conf`，页面源码不出现；只暴露 `GET /status` 与 `POST /start`（无 stop 防误停）；绑定地址从 LAN 不可路由。

## 三、部署留痕（三-7 ⑤）

| 项 | 值 |
|---|---|
| 时间 | 19:11 安装 / 19:12 服务启动 / 19:13–19:15 测试 |
| 部署者 | workbuddy@zhn-tbxg2iah-win（人类当次授权） |
| NAS 变更 | 新增 `scripts/engine-ctl-server.py`(755, root)、`conf/ctl.token`(600, root)、`/etc/cron.d/stockdb-ctl`(644, root)；覆盖更新 `webconf/default.conf`（备份 `.bak.20261111`）、`web/sync.html`（备份 `.bak.20261111`）；nginx reload |
| 关键 MD5 | engine-ctl-server.py `52ff86b6…` / sync.html `e96cf801…` / default.conf `743dd8c5…`（sync.sh 仍为 v3 `cb155958…` 未动） |
| NAS 未动 | `scripts/sync.sh`、`engine-ctl.sh`、`entrypoint.sh`、`docker-compose.yml`、`Dockerfile`、容器编排、防火墙规则；`/tmp` 部署残留（含 token 临时文件）已清理 |

**线上自检（全部通过）**：
1. `/ctl/status` 经 8080 → 200 `{"ok":true,"output":"引擎 HTTP = 200"}`
2. 引擎在线时 POST `/ctl/start` → 「引擎已在运行, 无需启动」
3. **故障模拟端到端**：`engine-ctl.sh stop` → 7899 拒连 / `/db/` 502（看板显示无响应+按钮）→ POST `/ctl/start` → 「启动后引擎 HTTP = 200 / 启动成功」→ `日k:600519:*` 6040 行、最新交易日 20261111 ✓
4. 同步中守卫：sync.sh 运行期 POST `/ctl/start` → 409「同步正在进行中…」；该轮同步 19:13:40–19:14:17 `result=OK`、第 1 次拉起成功、7899=200
5. 保活：pkill 控制服务 → cron 19:15:01 自动拉回，`/ctl/status` 5s 内恢复 200；`ctl-server.log` 已见每分钟 `/health` 探针
6. LAN 直连网关 172.18.0.1:7910 → 超时不可达（不可路由，比 403 更彻底）

## 四、共享仓改动（本轮提交）

- 新建本 handoff
- `memory/projects/stockdb.md` 追加 19:20 条目（新组件、归档位置、验证结果）
- `env/repos.md` stockdb 行补充：控制服务与 agent-docs 归档指针
- 他人未提交改动（`M memory/projects/prnmgt.md`、`M skills/official-doc/zhn-docs-std/SKILL.md`）未触碰未带入

## 五、挂起任务（跨项目全量快照 · 8 字段 · 继承自「zhn-docs-std 升 v1.2.0」，本轮无新增无解挂）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | **S1** T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停，合并为一次 ALTER + 一次部署 | S3 人类裁定 + 新 ADR 批准 + 重编卡面 | 无 worktree；卡面 todo | 重编卡面后重新认领 | 人类 |
| prnmgt | **S2** P0 二次真机调研 | 2026-11-11 人类确认 | 富士 CWIS 无单双面统计，厂家后台升级中 | 厂家升级完成 + 复跑三台探测 + 更新调研文档 | tmp 快照保留；worktree 已 remove | 续跑不重开卡 | 人类 |
| prnmgt | **S3** v4 批次 / #18 | 2026-11-07 15:11 | 纸张消耗口径重编，数据可行性未定 | S2 结论 + D-5~D-10 逐条裁定 + 新 ADR | 仅 DRAFT，未写卡面 | 裁定后重编拆卡再认领 | 人类 |

**已解挂/不计入防撞**：prnmgt S4 T-064 已解挂回 todo，trae doing 中。防撞集合含 doing/open/suspended。

## 六、待人类裁决／处置（滚动继承 + 本轮新增）

1. （继承）stockdb 遗留限制：源站故障期**容器重启**则 entrypoint 拉起仍会失败（闭源在线授权），需源站恢复后看板按钮/手动拉起——本轮按钮功能已大幅缓解。
2. （继承）未派工：查询页 `index.html` 已是同源 `/db/` 优先（早前完成），`sync_url.txt` 探测域名核对仍待官方口径。
3. （本轮新增）`zjsj` 口令曾于 18:40 出现在对话中，建议轮换；若希望免口令常态自动化，需在 UGOS 粘贴本机 SSH 公钥。
4. （本轮新增）agent-docs 归档为静态快照，NAS 侧后续变更不自动同步——下次改动 stockdb 脚本/看板时**须手动更新归档**（提示词第十节有指纹核对表）。

## 七、下一步建议

- 22:00 自动轮次后看一眼看板（v3 门禁 + 新控制服务首次共同值守整点轮次）。
- 若 22:00 轮源站再抖，预期看到 `skipped` 而非 `fail + engine_ok=false`；引擎若因其他原因离线，直接点看板按钮。
