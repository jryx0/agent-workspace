# 2026-11-11 PRN014 手动全量采集闭环 + 20:10 强制重采变更

- 执行者：workbuddy@zhn-tbxg2iah-win
- 时间：2026-11-11 08:36:22 – 08:38:34 CST（采集），08:44–08:47 CST（cron 变更，见第七节）
- 触发：人类当次明确要求「连接采集服务器，让采集程序执行一次采集」，并选择「全量 data 采集」；随后又明确下达「每日 20:10 也强制重采」，授权生产 cron 配置变更。SSH 密码由人类当场一次性提供，仅作 plink `-pw` 参数，未写入任何文件/脚本/日志/记忆，未回显。
- 性质：运维动作（触发既有采集程序）+ 一项已授权的生产 cron 配置变更；未改代码、未改主数据、未改 Worker、未重启服务、未认领任务卡、未动他人未提交记忆。

## 一、执行前基线（D1 只读）

| 项 | 值 |
|---|---|
| collect_run 11-08 / 09 / 10 | 均 `partial`，16 台 ok 15，唯一失败 PRN014（连续 7 天 20:10 时段失败） |
| PRN014 device_daily / account_daily | 各 0 行（全历史无计数数据） |
| collect_run 2026-11-11 | 0 行（当日尚无批次） |
| 状态 cron | 正常，`device_status_log` 最新 `2026-11-11 08:10:47` |

## 二、动作与结果

1. `plink -batch -ssh -l jifang 10.113.224.20` 登录成功；核对 `jifang@jifang-OptiPlex-7050`、`/opt/prnmgt-collector`（属主 jifang）、依赖 `requests/openpyxl/curl_cffi` 可用、crontab 仍为唯一新实例两行（20:10 全量 / 8,11,14,17,22:10 状态）。
   - 注：首轮口令被服务器拒绝（`Access denied`，口令明文不记录），以 `-batch` 与文档原始 `echo y | plink` 两种写法各验证一次后停下报告；人类更正后一次连成。
2. 在 `/opt/prnmgt-collector` 执行 `python3 -m printer_monitor --config config.prnmgt.json`（与 20:10 cron 完全同入口），退出码 **0**，耗时约 2 分钟。
3. 采集结果：**`success` 16/16，失败 0**。主数据 24 台、在用 16 台，跳过 8 台停用。
4. **PRN014（10.113.123.248，Fuji Apeos 3560）首次采集成功**：品牌默认凭据 `4000/4000` 登录成功，打印 472 / 复印 50 / 扫描 0，账号 5 条，设备状态「休眠模式」，碳粉 TONER_K 94%、DRUM_K 99%，`recon_diff = -2`（全局终身累计差额，设计上不可判定，非错误）。与 11-10 本机只读实采（464 / 50 / 0、TONER_K 95%）交叉一致，设备真实在用。
5. 上报：第 1/3 次 `HTTPSConnectionPool(host='prnmgt.parva.dpdns.org'): Read timed out (read timeout=15)`，第 2 次重试 08:38:34 成功；`无待推送数据`。

## 三、线上自检（全部 SELECT，rows_written=0）

| 自检项 | 结果 |
|---|---|
| `collect_run` 2026-11-11 | `status=success`，`total_devices=16`，`ok_devices=16`，`failed_json=[]`，`ingested_at=2026-11-11 08:38:31` |
| `device_daily` 11-11 | 16 行（在用设备全覆盖） |
| `account_daily` 11-11 | 57 行 |
| PRN014 `device_daily` | **1 行**（全历史首次，472/50/0，状态休眠，`created_at=08:38:31`） |
| PRN014 `account_daily` | 5 行 |

结论：**自检通过**，采集与推送均已落库，11-10 诊断的「14号计数通道全历史缺失」已闭环。

## 四、根因判断（对 11-10 诊断的收敛）

- 14号在 **20:10 时段连续 7 天 ConnectTimeout**，但在 **08:37 时段完全可达且登录/计数全通** → 支持「采集服务器到 10.113.123.248 的路径/时段性间歇不通」（设备网口节能、下班断电、交换机端口/VLAN、ARP 冲突），**排除设备损坏、凭据错误、采集程序缺陷、IP 串号**。
- 「7号/14号 IP 重复」再次证伪：7号 `10.113.124.248`（京瓷 2553ci），14号 `10.113.123.248`（富士 3560），本轮两台同批成功。
- 附带观察：本轮上报也出现一次 15s 读超时（重试即成功），提示跨境/Cloudflare 链路同样存在间歇抖动，与设备侧问题无关，需另行观察。
- 补充：11-11 08:10 状态 cron 也是 16/16 成功（`cron.log` 显示 PRN014 08:10:40 登录成功），进一步佐证上午时段可达。

## 五、遗留与下一步（交人类）

1. **今日 20:10 原会被幂等跳过**：`run_collect` 逻辑为「当日 `success` 且非 `--force` 直接返回既有记录」。11-11 已标 success，若不处理则今晚不会再采、当日数据定格 08:37，也失去在 20:10 时段验证 14号连通性的机会。**人类已于 08:44 拍板加 `--force`（见第七节），该问题已解决，晚间时段验证可正常进行。** 仍建议在 20:10 前后于服务器做只读探测，帮助定位网络设备侧：
   ```bash
   ping -c 4 10.113.123.248
   curl -k -m 10 -o /dev/null -w '%{http_code} %{time_total}s\n' https://10.113.123.248/
   arp -an | grep 10.113.123.248
   ```
2. 观察后几日 `collect_run` 是否稳定 `success 16/16`；若 20:10 仍复现失败，按上述探测结果定位网络设备侧。
3. 上报链路 15s 读超时为单点偶发，暂不处置；若连续出现再查 Worker/网络。
4. 共享记忆 `memory/projects/prnmgt.md` 存在他人未提交改动（M），按三-5 ⑥ 本条不触碰、不代提交；本交接为独立文件单独提交。

## 六、状态

- 生产代码未部署：线上 Worker 版本与采集端 Python 代码均未变化，基线提交号未变；**08:46 起采集端 crontab 有已授权的配置变更（20:10 行加 `--force`）**，详见第七节。本节的 `git push` 仅指共享记忆仓库的文档同步，与生产部署无关。
- 未改 `~/.agent-shared` 内既有的他人文件；本 handoff 为本次新增并按事件追加。
- 工作区当日日志：`.workbuddy/memory/2026-11-11.md`。

## 七、08:44–08:47 后续变更：每日 20:10 强制重采（人类拍板）

- 触发：人类在看完第五节第 1 条后明确下达「每日 20:10 也强制重采」，即授权生产 cron 配置变更。
- 变更前只读核对：
  - 完整 crontab 仅 1 行注释 + 2 行任务（无其他用户任务）；已有历史备份 `~/crontab.backup.20261102`。
  - 采集端 `db.py`（`save_device_snapshot` / `save_account_snapshots` / `upsert_run`）与 Worker `src/modules/ingest.js`（`DEV_UPSERT` / `RUN_UPSERT` / `ACCT_UPSERT`）均为 `INSERT ... ON CONFLICT DO UPDATE` 按行覆盖；`ingest.js` 中 `DELETE FROM device_daily` 命中数为 **0** → 同日重跑/重推不会产生重复行，也不会删掉上午已入库的 14号行；`upsert_run` 会把 `pushed` 复位 0 后重新推送。
- 动作（08:46 CST，单次 plink 会话内先备份、再改、再校验，校验不通过即 ABORT）：
  1. `crontab -l > ~/crontab.backup.20261111`（354 B，`jifang:jifang`）；
  2. 仅对 `^10 20 * * *` 且含 `python3 -m printer_monitor --config` 的行，把 ` --config ` 替换为 ` --force --config `（`sed` 地址精确匹配，不会命中 `status` 行）；
  3. 自动校验 `--force` 计数 = 1、diff 恰为 1 行替换、新行含 `--force --config` 后才执行 `crontab` 安装；
  4. 安装后 `crontab -l` 与备份 diff 复核：仅第 3 行变化；`status --config` 状态行**原样未动**。
- 最终生效行：
  ```cron
  10 20 * * *  cd /opt/prnmgt-collector && python3 -m printer_monitor --force --config config.prnmgt.json >> logs/cron.log 2>&1
  ```
- 线上自检：① `crontab -l` 共 4 行、与备份 diff 仅 1 行替换、备份文件存在；② 服务器端 `python3 -m printer_monitor --force --help` 正常打印帮助并列出 `--force`；③ 服务器源码 `__main__.py:50` 定义 `--force`、`collector.py:98` 的 `status == "success" and not force` 幂等判断在位 → 参数与逻辑均可用。
- **待今晚验证**（本会话无法即刻完成）：20:10 后查 `collect_run WHERE collect_date='2026-11-11'` 的 `ingested_at` 应变为 `20:1x`；14号若晚间仍不通，批次会变 `partial 15/16` 并把失败写入 `failed_json`，但上午已入库的 14号 `device_daily`/`account_daily` 行按 upsert 语义保留、不丢。
- 边界：未改代码、未改主数据、未改 Worker、未重启服务、未动状态 cron；口令仍为一次性 `-pw` 参数、未落盘；`memory/projects/prnmgt.md` 他人 M 改动仍不触碰。
- 回滚（如需恢复原幂等行为）：`crontab ~/crontab.backup.20261111 && crontab -l`。
