# Handoff — stockdb 机器码查看功能上线 + 22:00 第 4 次 ID 漂移登记

- **时间**：2026-11-24 08:10–08:26 UTC+8
- **署名**：workbuddy@zhn-tbxg2iah-win
- **档位**：T2（NAS 部署 + 共享仓留痕 + 推双远端）

## 人类需求与决策
1. 标题"stockdb 同步看板"旁放当前机器码，悬停弹浮窗显示"时间+历史机器码"；页面刷新时采集机器码并记录。
2. 历史去重：与上一次一致就不记录（变化才记）。
3. 08:22 追加：**时间精确到秒**。
- 决策（AskUserQuestion）：历史范围＝**服务端共享历史**（非前端本地）；22:00 新漂移＝**只记录不改数据**（不触发同步）。

## 实现
- 后端 `scripts/engine-ctl-server.py` 新增 `GET /nodeid`（在 token 校验内）：以 root 读 `data/.node_id`（root:600；`zjsj` 与容器外读不到，控制服务进程是 root，故可行）；维护 `data/node-history.json`：`{entries:[{ts,id}]}`，与最后一次相同则不记，`HIST_MAX=200`，`os.replace` 原子写；返回 `{ok,current,entries,recorded}`；时间戳 `time.strftime("%Y-%m-%d %H:%M:%S")` 到秒。
- 前端 `web/sync.html`：标题旁 `.nid` 芯片显示当前机器码前 8 位；`loadNodeId()` 在每次 `load()`（含 60s 自动刷新）`fetch('ctl/nodeid')`；悬停/`:focus-within` 显示 `.tip`，内容＝"时间(到秒)＋完整机器码"历史（最新在上、当前项标"← 当前"、`esc()` 转义）；并入 `Promise.all`。
- 复用现有 nginx `/ctl/` 反代与 token，未新增 nginx 配置、未动 token。

## 部署与线上自检（全通过）
- 08:24 部署；备份 `engine-ctl-server.py.bak.20261124-nodeid`、`sync.html.bak.20261124-nodeid`。
- 旧控制服务 08:23 kill；cron `stockdb-ctl` 08:24:01 保活自动拉起新版（手动补拉实例因端口占用退出，无影响）；日志确认监听 `172.18.0.1:7910`。
- MD5：控制 `52ff86b6…`→`e39ea9bcc672515a72f186003573e8cc`；看板 `4fae00f6…`→`0af381523e99cd9b38f8c954640b66d5`。
- 自检：① Python AST ✅、`node --check` ✅；② 去重逻辑实测（A/A/A→1 条、B→2 条、B 不增、A→3 条）；③ `/ctl/nodeid` 首次 `recorded=true` 写入 `2026-11-24 08:24:13 d267b7c8…`，二次 `recorded=false`；④ `/ctl/status` 回归 `引擎 HTTP = 200`；⑤ 页面 200/26885B、特征命中 10；⑥ 时间戳到秒复核 `2026-11-24 08:24:13` 长度 19、正则通过；⑦ `loadNodeId` 函数单元验证（fetch/esc/最新在上/当前标记均命中）。
- **局限**：本机无浏览器二进制，Playwright 无可用内核，未做真实 hover 截图；以 DOM+接口链路模拟与函数单元验证替代（已如实告知人类）。
- 临时文件 `/tmp/ctl-new-20261124.py`、`/tmp/sync-new-20261124.html` 已清理。

## 归档
`~/.agent-docs/绿联NAS/261111｜重建｜stockdb docker 引擎与看板重建/`：两文件已同步；主提示词架构图（加 GET /nodeid）、第五节修改点表（控制服务+sync.html）、目录树版本 ★v5、第十节 MD5 均更新；注明 `node-history.json` 为运行时生成、不入归档。

## 新漂移登记（未处置）
11-23 22:00 自动轮次 `result=fail`，`.node_id` `11084fcf…`→**`d267b7c8-76e9-45c7-9e4a-cb87a7de71e7`**（当日第 4 次），授权失败。人类裁定只记录。待本人验证：`https://a.123128.xyz/verify?id=d267b7c8-76e9-45c7-9e4a-cb87a7de71e7`。

## 挂起任务快照（继承，未认领未开工）
- prnmgt S1（T-059/T-060/T-061）、S2（P0 二次真机调研）、S3（v4/#18）：均 suspended，解挂权归人类。
- stockdb：无挂起项；ID 反复漂移根因（机器码为何变化）仍待人类决定是否深入排查 / 向官方反馈。

## 边界
未改数据、未触发同步、未动 token/nginx 配置；口令未落盘/未回显/未入 Git；他人未提交改动未触碰。
