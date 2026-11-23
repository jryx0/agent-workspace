# stockdb 看板授权失败提示横幅

- 项目: stockdb
- 执行: workbuddy@zhn-tbxg2iah-win
- 日期: 2026-11-23 14:58–15:05 UTC+8
- 人类指令: 截图为 Windows 弹窗「未初始化验证…error: auth failed, 状态:授权失败」；问 Linux 是否有同样报错，若有则 sync.html 需提示用户。

## 一、结论：Linux 有同样报错

Linux/NAS 上的数据更新器使用同一套授权逻辑，报错文案与 Windows 客户端**逐字相同**：
`状态:授权失败` / `未初始化验证,请双击stockdb主程序或前往：https://a.123128.xyz` / `error: auth failed, 状态:授权失败`。
区别仅在呈现方式：Windows 弹窗提示，Linux 无 GUI 因而只写进 `logs/sync_2026-11-23.log` 和看板 `data/sync-history.json` 的 `runs[].excerpt`。今日 09:00 / 13:00 两轮即为此报错（14:48 扫码验证后已恢复为「状态:有效」）。

## 二、改动（仅 NAS `web/sync.html`）

1. 新增 `renderAuthBanner()`：扫描 `data.runs`（新→旧）；遇到 `status=ok` 且日志含「状态:有效」的成功轮即判定已恢复、不显示。若在此之前命中 `auth failed|授权失败|未初始化验证`，显示醒目横幅（黄色 `--skip` 主题），含：
   - 失败时间与三条错误原文；
   - 从日志 `ID:` 行提取的设备 ID；
   - `/verify?id=<ID>` 专属验证链接按钮（`https://a.123128.xyz/verify?id=…`）；
   - 说明「引擎在线、历史可查，仅新数据下不来，需本人微信扫码」。
2. 运行明细表：授权失败行的「说明」列显示红字「设备授权失败 · 需官网扫码验证」。
3. `load()` 中调用 `renderAuthBanner(data)`。

零后端、零配置、零 CRON 变更；手机/深色主题沿用现有 CSS 变量。

## 三、部署与留痕

- 时间 15:00–15:03；备份 `sync.html.bak.20261123-authbanner`（19813B，旧 md5 `69b61cc4d6071e9958642be7ef5e321c`）；新 md5 `40e231b7388bba1ef5ea0ddc95532537`（22513B）。
- 基线提交 `58bd91e`（含他 agent 的 PC-04b 提交；本次零代码变更，线上为 NAS 静态页）；部署者 workbuddy。
- 口令仅用于 plink `-pw` 与 sudo stdin，未落盘、未回显、未入 Git；`/tmp` 上传残留已清理。
- 归档 `~/.agent-docs/绿联NAS/261111｜重建｜stockdb docker 引擎与看板重建/`：`脚本/sync.html` 已同步；主提示词第五节修改点表、第十节 MD5 指纹表已更新。

## 四、线上自检（通过）

1. `http://10.113.124.232:8080/sync.html` = 200，22513B。
2. 页面源码中关键特征（auth-banner / detectAuthFailure / renderAuthBanner / 设备授权失败）命中 9 处。
3. 抽取 `<script>` 走 `node --check` 通过。
4. 检测逻辑用线上真实数据验证：当前最新轮 14:48 `ok` 且含「状态:有效」→ 横幅应隐藏；仅取失败轮子集 → 命中并正确提取设备 ID `b36f0724-87a0-4942-9c4e-ec05f5ad9286`。
5. 页面无授权失败时不影响原有横幅（配置完整性）、引擎卡片、四时点、日历、趋势等渲染。

## 五、下一步 / 挂起项

- 16:30 自动轮次后复核最新交易日是否推进到 20261123；若推进说明扫码后数据通道完全恢复。
- 若未来再出现授权失败，看板顶部会自动出现黄色横幅并给出专属验证链接，无需登录 NAS 查日志。
- 升级 more-power 包仍暂缓（v0.3.5 版本有效，扫码已解决授权）；如需升级走归档 `脚本/upgrade.sh` v2，单独授权与留痕。
- 跨项目挂起快照无变化：prnmgt S1/S2/S3 仍 suspended，解挂权在人类。
