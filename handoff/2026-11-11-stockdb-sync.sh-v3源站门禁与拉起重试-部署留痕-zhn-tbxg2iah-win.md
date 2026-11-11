# stockdb sync.sh v3 源站门禁与拉起重试 · 部署留痕（v2.0）

> 编制：workbuddy@zhn-tbxg2iah-win · 2026-11-11 19:05 UTC+8
> **项目: stockdb, prnmgt**（挂起快照跨项目全量继承，按三-4 写项目标签）
> 依据：`~/.agent-shared/global/rules.md` **v2.0**（三-7 部署权限与留痕 / 三-4 挂起快照 / 第八节 10 步）；上一份 handoff `2026-11-11-stockdb-引擎拉起与增量同步完成-部署留痕-zhn-tbxg2iah-win.md`（18:47）第四节快照。
> **本文件为最新一份 handoff**，取代 18:47 文件作为挂起快照载体；未改写任何旧 handoff。

---

## 一、指令与授权

**人类 18:51「对这个引擎进行修改，但源站不可用时，仍然可以查询历史数据」**＝对 17:36 handoff「根治方向①：源站不可达时不要停引擎」的派工授权。按三-7 ③ 复核直接执行：改动仅限 NAS 既有脚本 `scripts/sync.sh`（备份后修改），零配置/账号/编排变更，部署后自检可执行。

## 二、变更内容（sync.sh v2 → v3，NAS `/volume1/docker/stockdb/scripts/sync.sh`）

1. **源站门禁前置**（替换原「仅告警不阻断」段）：新增 `probe_src()` —— `curl -sL` 跟随 302 探测 `https://a.123128.xyz/version?v=0.3.5`，**最终非 200 或反爬挑战页（`__CBK`/`<html`）即不停引擎直接 `exit 0` 跳过本轮**，日志写「源站不可用(…), 本次跳过同步; 引擎保持运行, 历史数据可正常查询, 源站恢复后下一轮自动重试」（文案含「本次跳过」→ 看板 `classify_skip` 记 `skipped`，不算 fail）。源站恢复后下一整点 cron 自动重试，自愈。
2. **引擎拉起带重试**（替换原「无条件拉起一次」段）：最多 3 次（间隔 10s），每次失败先 `probe_src` 复探，源站已不可用即停止重试（不在风控期空转撞 IP）；成功日志「引擎已恢复服务 (第 N 次拉起成功)」保持 `startswith("引擎已恢复服务")` 兼容看板。
3. 其余段（flock 互斥、fd 200 关闭、休市清单、停引擎、删 disable、更新器、RESULT 判定、日志保留）**与 v2 逐字节一致**（diff 验证，除有意变更外仅一处转录笔误 `break` → `break ;;`，安装时 `bash -n` 当场拦截，已修复重装）。

**未改**：`engine-ctl.sh`（start 的挑战页探测与 exit 9 逻辑保留）、`crontab`、`entrypoint.sh`、compose、看板 `sync-stats.py`。

## 三、部署留痕（三-7 ⑤ / ⑥）

| 项 | 内容 |
|---|---|
| 部署时间 | 2026-11-11 18:53–19:01 UTC+8（18:59 首次安装语法错误即回查，19:00 修复版安装 + 两级验证完成） |
| 基线提交号 | 共享仓 `f2d5b81`（部署时 HEAD；改动对象为 NAS 脚本，非共享仓代码）。旧版已备份 `scripts/sync.sh.bak.20261111`（v2，md5 见日志），可随时回滚：`cat sync.sh.bak.20261111 > sync.sh` |
| 部署者 | workbuddy@zhn-tbxg2iah-win |
| 部署方式 | 本地生成（LF 行尾）→ plink 上传 `.tmp` → **MD5 双端核对一致** → `cp -p` 备份 → `cat > sync.sh` 覆盖（保留 inode 权限属主 `-rwxr-xr-x zjsj admin`）→ 宿主 + 容器内 `bash -n` 双重语法检查 |
| 自检结果 | **全部通过**：① 探测单测 real=200 / fake=000；② **负向测试**（副本 sed 替换探测 URL 为伪造域名后运行）：日志出现「源站不可用(code=000), 本次跳过同步; 引擎保持运行…」、`GATE_EXIT=0`、7899 全程 200 未被停；③ **正向端到端**（19:00 真实触发）：「源站可用(code=200), 开始同步」→ 停引擎 → 更新器增量 `3/3 files, failed=0, Success 100%` → 「引擎已恢复服务 (第 1 次拉起成功)」→ `result=OK updater_exit=0`；④ 数据完好：600519 最新交易日 **20261111** close 1402.3；⑤ 两容器 healthy、看板 `integrity.ok=true` 且正确把负向轮记为 `手动 skipped`（reason 完整显示） |
| 状态同步（⑥） | 线上生效版本 = sync.sh v3（md5 `cb155958b0a372a64155da204c9176dd`），22:00 起所有自动轮次按 v3 执行；**自 22:00 起，源站故障不再打掉引擎，历史数据始终可查** |

## 四、遗留限制与后续

1. **引擎二进制启动仍需在线授权校验**（闭源行为，脚本层无法根治）：若 **NAS/容器在源站故障期间重启**（`restart: unless-stopped` + entrypoint 拉起），引擎依旧起不来，需源站恢复后由 entrypoint 下次重启、`engine-ctl.sh start` 或下一轮 sync 拉起。v3 已覆盖的常态场景＝「运行中的引擎不会被同步误停」。
2. 查询页 `index.html` 硬编码 7899 直连、`sync_url.txt`/`engine-ctl.sh` 探测 URL 域名核对——**仍未派工**，待人类决定。
3. 凭据处理同 18:47 handoff：口令仅本次会话 plink 参数/sudo stdin，未落盘/未回显/未入 Git；常态仍无免密。
4. 18:43:32 重复触发来源仍未确认（flock 已挡，无复发）。

## 五、挂起任务（当前全量快照 · 按「项目 + 任务ID」匹配 · 未解挂项一律禁止认领／开工）

> 完整继承 18:47 handoff 第四节；本轮无新增挂起、无解挂。stockdb 无挂起任务卡。

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | **S1** T-059 / T-060 / T-061 | 2026-11-07 15:0x 人类 D-4 | v3 三卡暂停，要合并成一次 ALTER + 一次部署 | S3 的人类裁定完成 + 新 ADR 批准 + 重编卡面写入 `tasks.md` | 无 worktree；卡面 `todo`；`docs/paper/exec-prompt-2026-11-07.md` 停用 | 重编卡面后重新认领 | 人类 |
| prnmgt | **S2** P0 二次真机调研 | 2026-11-11 人类确认 | 富士 CWIS 无单双面统计已实锤，厂家后台升级中 | 厂家升级完成 + 复跑三台探测 + 更新 `docs/paper/field-survey-2026-11-07.md` | `tmp/trae/p0-scan/`、`tmp/trae/field-survey/anon-probe/` 快照保留；凭据经环境变量不落盘；worktree 已 remove | 续跑，不重开卡 | 人类 |
| prnmgt | **S3** v4 批次 / `OPEN-DECISIONS.md` #18 | 2026-11-07 15:11 | 纸张消耗口径重编，数据可行性未定 | S2 调研结论 + #18 与方案 §8 的 D-5~D-10 逐条人类裁定 + 新 ADR 批准 | 仅 DRAFT 文档；未写卡面、未拆卡、未派工 | 裁定后重编方案与拆卡，再重新认领 | 人类 |

**已解挂／不计入防撞**：`prnmgt / S4 T-064` 17:48 解挂回 `todo`，trae 18:12 已认领 doing。防撞集合含 `doing/open/suspended`；`memory/projects/prnmgt.md` 仍有他人活跃未提交改动，本快照是开工防撞权威。

## 六、待人类裁决／处置（滚动继承，不计入挂起快照）

| 项目 | 事项 | 状态 | 依据 |
|---|---|---|---|
| stockdb | 源站故障打掉引擎缺陷 | **本轮已根治**（v3 门禁 + 重试，两级验证通过） | 本文件第二/三节 |
| stockdb | 查询页改同源 `/db/`；探测 URL 域名核对 | 待人类决定是否派工 | 本文件第四节 |
| prnmgt | T-063 已合并但**未部署**；T-064 doing | 现网 ALTER / DML / 部署归人类 | 18:25 handoff 第六节 |
| 全局 | 11-08 requests 用户级违规副本 + `/tmp/pwtest` | 待人类裁决 | 四-5 ⑥ |
| 全局 | MCP 9101 offline / L3 钩子未启用 | 需人类运行 `env/start-mcp.bat`；钩子须先探针 | 八-2、〇⑥ |

## 七、关键文件与下一步

- NAS：`scripts/sync.sh`（v3 生效，md5 `cb155958…`）、`scripts/sync.sh.bak.20261111`（v2 回滚点）
- 共享仓：`memory/projects/stockdb.md`（19:05 部署留痕条目）、本 handoff
- 后续会话：按三-1 各读最近一份带 `项目:` 标签 handoff（stockdb 读本文件）；领卡前查 `memory/projects/<项目名>.md` 的 `doing/open` ＋ 本文件第五节 `suspended`
- 建议 22:00 轮次后顺手复核看板（应见 v3 风格日志；若源站届时恰好故障，应见 `skipped` 而非 `fail + engine_ok=false`）
