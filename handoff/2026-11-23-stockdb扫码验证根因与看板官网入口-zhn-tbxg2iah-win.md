# stockdb 扫码验证根因定位 + 看板加官网验证入口

- 项目: stockdb
- 执行: workbuddy@zhn-tbxg2iah-win
- 日期: 2026-11-23 14:37–14:47 UTC+8
- 人类指令: ①确认设备 ID（官网 `/data/.node_id`）；②官网地址 `https://a.123128.xyz` 放到看板「行情查询」旁；③读网页协助扫码验证。

## 一、结论速览

- **根因不是版本**：源站 11-22 公告「黑客大哥太多，已开启扫码验证，首次使用点击完成，已扫过码无需再次验证」。今日 09:00 / 13:00 两轮同步均 `状态:授权失败 / 未初始化验证,请双击stockdb主程序或前往：https://a.123128.xyz / error: auth failed` → `result=FAIL`（updater_exit=0）。失败的是**数据更新器的设备授权**，不是引擎；v3 门禁仍把引擎拉回，7899=200，历史数据可查，仅新数据下不来。
- **升级非必需**：当前二进制 v0.3.5（md5 `99d59f4e531d2b8cd3b8d45ae823c779`，2026-09-08），`/version?v=0.3.5` 返回 `{"status":true,"expire":"2099-09-09"}`，版本有效。更-power 包不解决设备授权。已向人类说明并暂缓升级，待扫码后再决定。

## 二、设备 ID（第一问答案）

`/volume1/docker/stockdb/data/.node_id`（36 字节，root 600，11-23 09:00 更新）内容：

```
b36f0724-87a0-4942-9c4e-ec05f5ad9286
```

容器内 `/stockdb/data/.node_id`、`/stockdb/app/data/.node_id`、`/stockdb/conf/data/.node_id` 三处一致；与同步日志 `ID:` 行一致。专用验证链接：`https://a.123128.xyz/verify?id=b36f0724-87a0-4942-9c4e-ec05f5ad9286`。

## 三、验证机制（读 `/verify` 页 JS）

流程：`GET /verify?id=<设备ID>` → `POST /verify/api/state`（`{id,nick,m}`）→ stage=input 填**微信昵称（首字须完全一致）** → stage=scan 显示二维码（微信扫码） → stage=done。二维码 URL 由脚本拼 `BASE + st.qr + '?t='`。**扫码是真实人机验证，agent 无法代填昵称/代扫**；当前 `POST /verify/api/state` 仍返回 `stage=input`（未验证），等人类完成。

## 四、看板改动（第二问，已部署）

- NAS `web/sync.html` 页头「行情查询 →」旁新增 `<a href="https://a.123128.xyz" target="_blank" rel="noopener noreferrer">官网验证 ↗</a>`（沿用 `var(--run)` 同款样式）。
- 时间 14:44–14:46；基线共享仓 `abfd343`（NAS 侧静态页面变更，非共享仓代码）；部署者 workbuddy。
- 安装：线上原文件备份 `sync.html.bak.20261123`（md5 `e96cf8011ce4ab8815bebb8a2a05b81f`）→ 覆盖（新 md5 `69b61cc4d6071e9958642be7ef5e321c`）→ `/tmp` 残留清理。
- **自检**：`sync.html` 200（19813B），线上第 90 行链接就位；7899=200、`/ctl/status` 正常（引擎与控制服务未受影响）。
- 归档同步：`~/.agent-docs/绿联NAS/261111｜重建｜stockdb docker 引擎与看板重建/` 下 `脚本/sync.html` 已同步为新版；主提示词第五节修改点表与第十节 MD5 指纹表已更新。**注意此归档路径已非上轮的 `~/.agent-docs/脚本/NAS/stockdb-docker/`（该路径本会话已不存在，非本会话迁移）**。

## 五、挂起任务（跨项目全量快照 · 继承最新 handoff，无新增无解挂）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；todo | 重编卡后认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级 + 复跑 + 更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 + 新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无挂起（PC-06 doing）；stockdb 无挂起卡。

## 六、待人类 / 下一步

1. **人类扫码**（本轮唯一卡点）：打开第三节专用链接 → 填微信昵称 → 微信扫码 → 看到「验证成功」。
2. 人类完成后由 workbuddy：查 `/verify/api/state` 到 stage=done → 手动触发 `sync.sh` 补数据（不等 16:30/22:00）→ 线上自检（`日k:600519:*` 最新交易日是否推进、看板 result=OK、容器 healthy）→ 部署留痕。
3. 扫码恢复后如人类仍要升级 more-power 包，走归档 `脚本/upgrade.sh` v2（备份齐、冒烟+回滚），届时单独授权与留痕。
4. 遗留限制不变：引擎二进制启动的在线校验是闭源行为，源站故障期容器重启仍需源站恢复后拉起。
