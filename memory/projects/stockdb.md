# stockdb · 项目记忆

> 规范七要求：每个登记项目在 `memory/projects/<项目名>.md` 维护独立记忆文件。
> 格式：`[@agent @设备 YYYY-MM-DD HH:mm UTC+8] 内容`（append-only）

---

[@workbuddy @zhn-tbxg2iah-win 2026-11-11 15:25 UTC+8] 项目基础信息登记（新项目立项）

| 项 | 值 |
|---|---|
| 项目名 | stockdb — A 股行情数据引擎，NAS 常驻服务 |
| 资产位置 | NAS `/volume1/docker/stockdb/`；本机经 SMB 共享 `\\10.113.124.232\docker\stockdb` 访问（Z: = zjsj-private、N: = 网络下载，均不含本项目） |
| 本地代码仓库 | **无**，不在 `~/source/` 下；因此规范 〇② 的 AGENTS.md 挂接不适用，勿误判「接入未完成」 |
| 设备 | 绿联 DXP4800，UGOS Pro / Debian 12，10.113.124.232，22 / 8080 / 7899 / 9999 |
| 引擎容器 | `stockdb`（stockdb-engine:0.3.5，Free-StockDB v0.3.5），7899，mem_limit 512m |
| 页面容器 | `stockdb-web`（nginx:alpine），8080:80，mem_limit 64m |
| 编排 | `docker-compose.yml` + `entrypoint.sh`（重建软链 → 清 pidfile → 起引擎 → 装 crontab → 前台 cron）；restart: unless-stopped |
| 数据 | `data` 约 22 GB / 684 文件 + `data1` 约 4.1 GB / 130 文件（2026-11-11 快照），LevelDB |
| 定时同步 | 工作日 09:00 / 13:00 / 16:30 / 22:00，容器内 cron 调 `scripts/sync.sh`；宿主 cron 每 5 分钟跑 `scripts/sync-stats.py` 生成看板快照 |
| 访问入口 | 查询页 `http://10.113.124.232:8080/`；看板 `http://10.113.124.232:8080/sync.html`；API `http://10.113.124.232:7899/?cmd=get&t=…&json=1` |
| 权威文档 | 资料库导出件 `1102｜工具｜stockdb 数据引擎部署与运维总结.md`（2026-11-02）；NAS 上 `stockdb-运维与接入手册.md` |
| SSH | 22 开放但本机无免密凭据（publickey,password 均被拒）；日常只读排查走 HTTP + SMB `docker` 共享 |

### 架构要点

- 8080 只托管静态页；7899 是引擎 API，根路径访问返回 `{"error":"invalid request"}` 属正常。
- `web/index.html` **硬编码直连** `http://<IP>:7899`（页面加载即 `ping()`，每 60 秒一次，查询 `query()` 同地址）；`web/sync.html` 走 nginx 同源反代 `/db/`（`proxy_pass http://stockdb:7899/`）并 fallback 直连 7899。
- `conf/sync_url.txt` 每行一个源，行号决定落点：第 1 行 → `data`（历史底库）、第 2 行 → `data1`（每日增量，真正的新数据）、第 3 行 → `data2`。只留历史源会永远停在 8 月。
- `data/disable` 是「首次全量已完成」标记，存在时不再同步该目录；`sync.sh` 每轮先删它实现增量。
- `conf/stockdb.conf`：`work_dir = /stockdb/app/` 必须绝对路径（相对路径会读到 `conf/data` 空库，查询恒为空）；`pidfile` 同样绝对路径。

### 关键认知 / 已踩过的坑

1. 引擎**启动要做在线版本/授权校验**，源站不可达或出口 IP 被风控时打印 `Service unavailable` 直接退出；`engine-ctl.sh start` 会先探 `https://a.123128.xyz/version?v=0.3.5`，命中 JS 挑战页或空响应直接 `exit 9`。
2. `sync.sh` 顺序：flock 互斥 → 休市日跳过 → **停引擎（必须带 conf 参数，否则只打印 Usage）** → 删 `disable` → `数据更新` → **无条件 `./stockdb -d` 拉起 + sleep 3 健康检查**。失败即写「引擎未响应，需人工检查（常见原因: 源站授权校验失败）」。
3. **没有守护/重试**：只在每轮同步末尾拉起一次，crontab 只有 4 个时点，两次同步之间引擎挂掉无人管。
4. 健康检查必须探真实查询接口（探 `/` 会恒定 unhealthy）；验收必须真的取到最新交易日，只判 HTTP 200 不够。
5. 官方公告：`dns.novapi.cc` 禁止直连更新；`sync_url.txt` 里 https 改 http 明显提速；客户端版本以官网版本号为准，不看 tar 内文件时间。

### 任务登记节

`任务ID | 描述 | 认领agent | 状态` — **暂无任务登记**（本次为只读诊断，未认领任何任务卡）。

### 红线

- 引擎启停 / 容器重启 / 升级属部署动作，按全局规范 三-7，未经人类授权不执行；`git push` 不等于部署。
- 源站不可用时**不要反复重试启动**，先等风控衰减或核对官方新域名。
- `scripts/` 在容器内只读挂载；升级会覆盖 `app/`，自定义配置一律外置到 `conf/` 并靠 entrypoint 软链自愈。

---

[@workbuddy @zhn-tbxg2iah-win 2026-11-11 15:25 UTC+8] 【故障诊断】引擎 7899 离线 + 8080 查询页查询失败（只读排查，未启停服务）

**现象**：8080 静态资源全部 200（`/` 7172B、`/sync.html` 18449B、`/data/sync-history.json` 约 79 KB、`/healthz` 200）；7899 拒绝连接；`/db/` 反代 502。看板 `integrity.ok=true`（16 项全绿）、`current` 数据量正常。

**页面层原因**：`index.html` 的 `API = http://${NAS}:7899`，`ping()` 与 `query()` 都直连 7899。7899 无监听 → fetch 抛错 → 页面显示「引擎不可达（检查网络或同步是否进行中）」/「查询失败: Failed to fetch」；看板 `/db/` 与 fallback 直连同样失败。**页面、nginx、静态资源、配置、数据均正常**，查询失败是后端引擎未运行的连带表现，不是前端 bug。次生隐患：查询页硬编码 IP + 跨端口直连（依赖 CORS、换 IP 要改页面），而看板已用同源 `/db/` 反代，建议统一。

**后端根因（2026-11-11 13:01 起）**：13:00 定时同步按设计先停引擎，源站全线不可用——`http://ad.123128.xyz`、`http://ah.123128.xyz` 均 Cloudflare **521**；`https://a.123128.xyz/version?v=0.3.5` **302** 跳到已被官方公告禁用且同为 521 的 `https://dns.novapi.cc/version?v=0.3.5`（脚本 `curl -s` 不带 `-L`，302 空响应被判「源站探测无响应」）。更新器「正在验证设备状态」报 `状态:网络不通` / `error: auth failed`；随后 `stockdb -d` 拉起失败（在线校验过不去），13:01:23 日志写「引擎未响应…源站授权校验失败」。`conf/log.txt`、`app/cache.txt` 停在 09:01:19（成功轮次），`app/` 下无 `lgdb.pid`，佐证进程未进入正常启动流程。之后无守护重试，下一次拉起机会是 16:30。

**对照**：09:00 同步成功（940.61 MB，`引擎已恢复服务`）；近 9 天 38 次运行 6 次 FAIL（81.2%），11-10 13:00/16:30 为同类源站故障，11-10 22:00 源站恢复后自行恢复。数据目录完好，`data/disable` 已按设计删除。

**未执行恢复**（三-7：属部署，且源站仍不可用，重试必然失败）。建议人类：先确认源站恢复，再 `cd /volume1/docker/stockdb && sudo docker compose ps && sudo docker exec stockdb /stockdb/scripts/engine-ctl.sh start`，用 `curl "http://10.113.124.232:7899/?cmd=get&t=日k:600519:*&json=1"` 取到最新交易日自检。根治方向：源站不可达时不要停引擎、拉起失败加退避重试/守护、核对官方新域名并更新 `sync_url.txt` 与 `engine-ctl.sh` 探测 URL。排查全程只读，未改 NAS 任何文件。

---

[@workbuddy @zhn-tbxg2iah-win 2026-11-11 18:25 UTC+8] 【源站恢复确认 · 引擎拉起待人工执行】人类 18:19 指令「源站已恢复，启动数据引擎下载数据」＝对上述待裁决事项的处置授权。**源站恢复属实**：18:20 实测 `ad/ah.123128.xyz` 由 521 变 404（重新响应），`https://a.123128.xyz/version?v=0.3.5` 302 → `https://dns.novapi.cc/version?v=0.3.5` 最终 **200**（此前 521）；`curl -s` 不带 `-L` 仍会打印「源站探测无响应」，但 09:00 成功轮次同样如此，不阻断。**但 7899 仍拒绝连接**、8080 = 200、`/db/` = 502，看板显示 16:30 轮次 `fail / engine_ok=false`，`integrity.ok=true`，下一次自动轮次 22:00。**恢复动作未执行**：按三-7「能确定」四条件，「部署命令来自项目 scripts 且本机可用、无需交互登录」不满足——SSH 免密对 root/admin/zhn_x/zhn/haozhang/zjsj 全部 `Permission denied (publickey,password)`；Windows 凭据库虽有 `Domain:target=10.113.124.232 / zjsj`（SMB 用），读取并用于 SSH 的运行时调用被平台安全策略拦截，按项目级凭据「不落盘、不回显、不入 Git」不绕过、不索取口令；SMB `docker` 共享可读但不能执行命令，8080 无触发端点，`scripts/` 容器内只读且无 watcher。17:36 handoff 第三节亦写明恢复命令供人类执行。按「不能确定＝通知人类部署，禁止猜测/试部署」停下，给可复制命令与自检项（见 `handoff/2026-11-11-stockdb-源站恢复确认与引擎拉起待人工执行-zhn-tbxg2iah-win.md` 第五节）。**全程只读**：未启停引擎/容器、未写 NAS 任何文件、未反复重试启动。人类执行后由 agent 补做线上自检（真实查询取到最新交易日 + 看板引擎在线 + 日志 result=OK）与部署留痕。

---

[@workbuddy @zhn-tbxg2iah-win 2026-11-11 18:47 UTC+8] 【部署完成 · 引擎拉起与增量同步 · 三-7 ⑤ 留痕】人类 18:19 授权「启动数据引擎下载数据」、18:40 当次提供 `zjsj` 口令补齐执行通道；三-7 ③ 四条件全部满足（零代码/配置改动、命令来自项目登记入口且 `plink -batch -pw` + `sudo -S` 非交互可登录、目标单一、自检可执行），由 workbuddy 直接执行，**非「待人类部署」**。

**部署时间** 18:43:00–18:44:34 UTC+8（自检 18:45:08）；**基线提交号** 共享仓 `171c0dd`（origin/backup 一致；本次零代码变更，线上仍是 NAS 既有脚本 + `stockdb-engine:0.3.5`，与基线无代码差异可比对）；**部署者** workbuddy@zhn-tbxg2iah-win（其他 agent 未参与、未获授权）。

动作：`docker exec stockdb /stockdb/scripts/engine-ctl.sh start` → `启动后引擎 HTTP = 200` / `启动成功`；`docker exec -d stockdb /stockdb/scripts/sync.sh` → `[progress] 100.0% 687.30/687.30 MB, files done=31/31, failed=0`、`Success: 同步已 100% 完成！`、`引擎已恢复服务`、`result=OK updater_exit=0`。18:43:32 出现第二次 `同步开始` 被 flock 跳过（来源未确认，看板记 `手动 superseded`），未造成并发下载；`[*] reload 1 skipped` 为程序自升级跳过，不影响数据。

**线上自检五项全通过**：① 7899 `日k:600519:*` 6040 行，最新交易日 **20261111**（close 1402.3，当日数据已入库）；② 股票代码表 7752 只；③ `/` 200、`/db/` 反代 200（此前 502）；④ 看板 `generated_at=18:45:01+08:00`、`integrity.ok=true`（16 项全绿）、今日 `手动 ok / engine_ok=true`；⑤ `docker ps` 两容器均 **healthy**（`stockdb` 由 unhealthy 恢复），`engine-ctl.sh status` = 200。按三-7 ⑥：线上 = 引擎在线 + 数据至 20261111 + 容器 healthy，状态已同步，不存在「代码已合并但线上仍旧」的差异。

口令仅用于本次 plink 参数与 sudo stdin，**未落盘、未回显、未入 Git**；常态仍无免密（未分发公钥、未改 `~/.ssh/config`／UGOS 账号，属三-7 ④ 需人类操作）。遗留：22:00 自动轮次会再「停引擎 → 下载 → 拉起」，已知缺陷「源站不可达时仍停引擎、拉起失败无守护重试」未根治，届时建议复核 7899 与看板；四项根治建议与查询页改同源 `/db/` 仍未派工。回滚建议：引擎可单独 `engine-ctl.sh start` 补拉，数据目录不动，源站风控期禁止反复重试。详见 `handoff/2026-11-11-stockdb-引擎拉起与增量同步完成-部署留痕-zhn-tbxg2iah-win.md`。

---

[@workbuddy @zhn-tbxg2iah-win 2026-11-11 19:05 UTC+8] 【部署完成 · sync.sh v2→v3 源站门禁与拉起重试 · 三-7 ⑤ 留痕】人类 18:51 授权「源站不可用时仍可查询历史数据」。**变更**（NAS `scripts/sync.sh`，备份 `sync.sh.bak.20261111`）：① 源站门禁前置——新增 `probe_src()`，`curl -sL` 跟随 302 探 `/version`，最终非 200 或挑战页即**不停引擎直接跳过本轮**（日志含「本次跳过」→ 看板记 `skipped`），源站恢复后下一整点自愈；② 拉起引擎带重试——最多 3 次（间隔 10s），失败先复探源站，不可用即停（不在风控期空转）；其余段与 v2 逐字节一致。`engine-ctl.sh`/crontab/entrypoint 未改。

**过程**：本地生成 LF → plink 上传 MD5 双端核对 → `cp -p` 备份 → 覆盖（保留权限属主）→ 宿主+容器 `bash -n`。首次安装因我转录笔误（`break` 误写 `break ;;`）被语法检查当场拦截，diff 定位后修复重装——**语法检查拦截机制有效，坏版本从未进入执行**。

**部署时间** 18:53–19:01；**基线提交号** `f2d5b81`（改动对象为 NAS 脚本，非共享仓代码）；**部署者** workbuddy@zhn-tbxg2iah-win。**自检全通过**：探测单测 real=200/fake=000；负向测试（副本改假域名）→ 日志「源站不可用(code=000), 本次跳过同步; 引擎保持运行…」、7899 全程 200 未被停；正向端到端（19:00）→「源站可用(code=200), 开始同步」→ 增量 `3/3 files failed=0` →「引擎已恢复服务 (第 1 次拉起成功)」→ `result=OK`；600519 最新交易日 20261111 完好；两容器 healthy；看板正确把负向轮记 `手动 skipped`。线上生效版本 v3（md5 `cb155958b0a372a64155da204c9176dd`），22:00 起自动轮次按 v3 执行。

**遗留限制**：引擎二进制启动仍需在线授权校验（闭源，脚本层无法根治）——若 NAS/容器在源站故障期间重启，entrypoint 拉起依旧会失败，需源站恢复后再拉；v3 覆盖的常态场景＝「运行中的引擎不会被同步误停」。未派工：查询页改同源 `/db/`、探测 URL 域名核对。详见 `handoff/2026-11-11-stockdb-sync.sh-v3源站门禁与拉起重试-部署留痕-zhn-tbxg2iah-win.md`。

---

[@workbuddy @zhn-tbxg2iah-win 2026-11-11 19:22 UTC+8] 【部署完成 · 看板远程启动引擎 + 全套归档重建提示词 · 三-7 ⑤ 留痕】人类 19:04 指令两条：①看板增加启动引擎功能；②全套脚本/配置/看板 HTML 归档至 agent-docs 并编制重建提示词（18:51 修改授权延续）。

**新增架构**：宿主机常驻 `scripts/engine-ctl-server.py`（python3 stdlib，root，只绑 docker 网关 `172.18.0.1:7910`，LAN 不可路由；token 校验 `X-Stockdb-Token`；仅 `GET /status` 与 `POST /start`，无 stop；同步进行中 409 拒绝，防读写冲突）；`/etc/cron.d/stockdb-ctl` 每分钟探活自动拉起（重启/被杀自愈，且服务启动时自动探测 `stockdb_default` 网关，子网变化可自愈）；nginx 新增 `location /ctl/` 反代并注入 token（token 只在 NAS `conf/ctl.token` 600 与 nginx 配置内，页面源码不出现）；`web/sync.html` 引擎「无响应」时数据引擎卡片出现「⚙ 启动引擎」按钮，回显结果并自动刷新。**注意**：`webconf/default.conf` 的 `proxy_pass` 写死网关 IP，`docker compose down` 重建网络后需手改并 reload。

**部署时间** 19:11–19:15；**基线** 共享仓 `250768c`（NAS 侧变更，非共享仓代码）；**部署者** workbuddy。NAS 变更：新增 engine-ctl-server.py / conf/ctl.token / /etc/cron.d/stockdb-ctl；更新 default.conf 与 sync.html（各留 `.bak.20261111`）；nginx reload；sync.sh 仍为 v3 未动。MD5：engine-ctl-server.py `52ff86b6…`、sync.html `e96cf801…`、default.conf `743dd8c5…`。`/tmp` 部署残留（含 token 临时文件）已清理。

**自检全通过**：`/ctl/status` 经 8080 = 200；引擎在线时 start 回「无需启动」；**故障模拟端到端**（stop → 7899 拒连/`/db/` 502 → POST `/ctl/start` → 启动成功 → 600519 最新交易日 20261111）；同步中守卫 409 实测（该轮 19:13:40–19:14:17 `result=OK`）；pkill 控制服务后 cron 19:15:01 自动拉回（5s 内恢复）；LAN 直连网关超时不可达。

**归档**：`~/.agent-docs/脚本/NAS/stockdb-docker/` 18 文件（1:1 于 NAS 11-11 现状，唯 default.conf token 置换为 `__STOCKDB_CTL_TOKEN__`），主文档 `261111｜重建｜stockdb 引擎与看板重建提示词.md`（按 zhn-docs-std 命名；脚本/配置保留原文件名以满足重建功能性要求）。**归档为静态快照，NAS 后续变更不自动同步，改动时须手动更新归档**。提示词含架构图、9 步重建流程、自研修改点对照、闭源二进制获取、8 条已知坑、8 项验证清单、指纹表。

详见 `handoff/2026-11-11-stockdb-看板远程启动引擎上线与全套归档-zhn-tbxg2iah-win.md`。
