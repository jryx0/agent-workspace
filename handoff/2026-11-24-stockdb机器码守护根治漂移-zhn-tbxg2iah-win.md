# 2026-11-24 stockdb 机器码覆盖验证 + 守护根治漂移 · 部署留痕

- **执行者**：workbuddy@zhn-tbxg2iah-win
- **档位**：T2（覆盖 NAS 机器码 + 触发同步 + 装守护脚本/cron + 写共享仓 + 拟推远端）
- **时间**：2026-11-24 12:35–12:55（GMT+8）
- **来源**：人类转述官方确认——某 ID 已验证后，若 ID 变化可用已验证设备号覆盖。

## 人类裁定
1. 两个已验证 ID 都覆盖试一遍，看哪个可用；覆盖后立即同步验证。
2. 持久化方案：**加 cron 同步前写回**（不改 sync.sh 本体、不动引擎/控制服务）。
3. 固定用第 1 个 `11084fcf-527e-4ee4-8205-b524bbd85284`；第 2 个 `b36f0724-87a0-4942-9c4e-ec05f5ad9286` 保存备查、不启用。

## 核查事实
- 官网验证态：`11084fcf`、`b36f0724` 均 `stage=done`；现行 `d267b7c8`、残留 `979a0816` 均 `stage=input`。
- `.node_id` 真实文件仅两处：`/volume1/docker/stockdb/data/.node_id`（root:600，更新器实际读取，日志 ID 与之一致）与 `/volume1/docker/stockdb/conf/data/.node_id`（旧残留，更新器不读）。容器内 `/stockdb/app/data` 是软链指向 `/stockdb/data`，非独立副本。
- 现有定时：容器内 cron（scripts/crontab）跑 sync.sh（09:00/13:00/16:30/22:00 工作日）；宿主机 `/etc/cron.d/stockdb-ctl`（控制服务保活）、`stockdb-stats`（看板快照）。sync.sh 由 UGOS 计划任务管理，标准 cron 里查不到——故守护采用高频检测，不依赖触发时点。

## 覆盖实测
- 覆盖 `11084fcf` → 12:40:49 同步 `[log] ID: 11084fcf`、`状态:有效`、`result=OK`、引擎第 1 次拉起。
- 覆盖 `b36f0724` → 12:41:52 同步 `状态:有效`、`result=OK`。
- 结论：官方方法有效，两个已验证 ID 均可用。

## 决定性机制（新发现，已根治）
- 更新器每轮同步**读 `data/.node_id` 后即删除该文件**；下一轮若缺失，则按机器码生成未验证新 ID → auth failed（第三次测试生成 `080ef5e7…` 并 `result=FAIL`）。这就是"一天漂移 4 次"的根因——**手动覆盖只管一轮**。

## 部署内容
- 新增 `/volume1/docker/stockdb/scripts/nodeid-guard.sh`（755，MD5 `d41af4a2d72d35e917495d58916a5879`）：每 60s 检查 `data/.node_id`，缺失或≠`GOOD`（11084fcf）即写回、chmod 600、记 `logs/nodeid-guard.log`；备查 ID 写在注释。
- 新增 `/etc/cron.d/stockdb-nodeid-guard`（644 root:root）：`* * * * * root /bin/sh .../nodeid-guard.sh >/dev/null 2>&1`。
- 同步前备份：`data/.node_id.bak.20261124-preoverride`、`conf/data/.node_id.bak.20261124-preoverride`。
- 未改：sync.sh 本体、engine 二进制、控制服务、token、nginx、看板 HTML。

## 端到端验证（闭环成立）
- 模拟删除 `data/.node_id` → 12:53:01 守护自动写回 `11084fcf`（日志 `MISSING -> 11084fcf`）。
- 12:53:26 触发同步 → `[log] ID: 11084fcf`、`状态:有效`、`result=OK`、引擎第 1 次拉起成功。
- 12:54:01 更新器读后删文件 → 守护再次写回（日志 `MISSING -> 11084fcf`），当前 `data/.node_id`＝`11084fcf`。
- 证明：守护写入 → 同步读到已验证 ID → 成功 → 文件被删 → 守护补回，循环稳定。

## 线上自检（全通过）
- 最新交易日 `20261123`（600519/000001/300750 一致，数据本就完整，本次同步只增量 3 文件）。
- 看板 12:54:27 刷新，最新轮 `手动 ok / engine true / 3 文件`、`integrity.ok=true`、授权失败横幅判定隐藏。
- 两容器 healthy；`/ctl/status`=200；NAS `/tmp` 临时脚本已清理。
- 口令未落盘、未回显、未入 Git。

## 归档
- `~/.agent-docs/绿联NAS/261111｜重建｜stockdb docker 引擎与看板重建/`：新增 `脚本/nodeid-guard.sh`；`脚本/crontab` 末尾追加守护 cron 说明；主提示词架构图、文件清单、权限表、第 6 步重建命令、修改点表、文件数（19→20）、MD5 表均已同步。

## 需人类处理（阻塞推送）
- **`proxy-check` 连续两次报 backup 远端不可达**：origin 可达且＝本地 `bee960e`，无全局代理漂移，10808 可连。已按规范 `[Agent报告]` 提醒，**未找临时代理、未单独推 origin**。请检查 backup 远端/代理配置；恢复后由本 agent 重跑 proxy-check 并把本轮留痕 commit + git sync 推双远端（本轮留痕文件已写、将在人类确认后提交推送）。
- **后续观察**：下次自动轮次（16:30/22:00）确认 `result=OK`、看板无授权横幅；若守护日志出现写回但同步仍失败，再排查 ID 生成时机竞态。
- 机器码仍可能触发官方服务端策略；如官方后续更新校验逻辑，需复核守护固定 ID 是否仍有效。
