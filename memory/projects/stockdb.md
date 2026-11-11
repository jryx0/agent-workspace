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
