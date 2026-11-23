# stockdb 看板失败卡片悬停报错提示

- 项目: stockdb
- 执行: workbuddy@zhn-tbxg2iah-win
- 日期: 2026-11-23 15:10–15:15 UTC+8
- 人类指令: 附截图（今日四时点中 09:00/13:00 显示失败），再次新增——鼠标移到失败卡片上时显示报错信息。

## 一、改动（仅 NAS `web/sync.html`）

1. `renderToday()`：对 `status` 为 `fail`/`incomplete` 且带 `excerpt` 的时点卡片加 `.err` 类与 `tabindex="0"`，内嵌 `<div class="tip">`。
2. CSS：`.slot.err:hover .tip, .slot.err:focus-within .tip { display:block }`；浮层为等宽字体、`--fail` 边框、`z-index:20`、宽 `max(320px,100%)`（最大 `min(92vw,520px)`），深色主题随 CSS 变量自适应；鼠标悬停即显示，键盘 Tab 聚焦亦可。
3. tip 内容：该轮 `excerpt` 中按关键词（error/失败/授权/未初始化/auth/unavailable/timeout/警告/refused/exception）过滤出的错误行；无匹配则取末 5 行；最多 8 行；经新增的 `esc()` 做 HTML 实体转义；超出 8 行提示"完整日志见下方'日志'列"。失败行用 `--fail` 红色高亮。
4. 与今日已上线的授权失败横幅（`renderAuthBanner`）并存，互不干扰；非失败卡片不受影响。

## 二、部署与留痕

- 时间 15:12–15:14；备份 `sync.html.bak.20261123-tooltip`（22513B，旧 md5 `40e231b7388bba1ef5ea0ddc95532537`）；新 md5 `4fae00f68158cc6988223f21a9145014`（24345B）。
- 基线提交 `0169958`（本地 HEAD，含前次横幅留痕）；本次零后端/配置变更；部署者 workbuddy。
- 口令仅用于 plink `-pw` 与 sudo stdin，未落盘、未回显、未入 Git；`/tmp` 上传残留已清理。
- 归档 `~/.agent-docs/绿联NAS/261111｜重建｜stockdb docker 引擎与看板重建/`：`脚本/sync.html` 已同步；主提示词第五节修改点表、第 69 行版本标记（★v4）、第十节 MD5 指纹表已更新。

## 三、线上自检（通过）

1. `http://10.113.124.232:8080/sync.html` = 200，24345B。
2. 页面源码关键特征（`.slot.err` / `.tip` / `renderAuthBanner` / `esc =`）命中 9 处。
3. 抽取 `<script>` 走 `node --check` 通过。
4. 用线上 2026-11-23 的 09:00 / 13:00 真实失败数据模拟 tip 内容——精确提取出截图同款三条错误：`[log] 状态:授权失败`、`[log] 未初始化验证,请双击stockdb主程序或前往：https://a.123128.xyz`、`[log] error: auth failed, 状态:授权失败`。
5. 无本地浏览器 CLI / browser-use skill，未做可视化截图实测；以 JS 语法 + 数据模拟 + HTTP 特征三重验证替代，足以确认功能逻辑。

## 四、下一步 / 挂起项

- 16:30 自动轮次后复核最新交易日是否推进到 20261123（扫码验证后数据通道应恢复）。
- 若未来再出现授权失败：页头横幅 + 失败卡片悬停 + 明细红字三重提示，用户无需登录 NAS 查日志。
- 升级 more-power 包仍暂缓（v0.3.5 版本有效，扫码已解决授权）；如升级走归档 `脚本/upgrade.sh` v2，单独授权留痕。
- 跨项目挂起快照无变化：prnmgt S1/S2/S3 仍 suspended，解挂权在人类。
