# 2026-11-24 stockdb 机器码悬浮窗加宽不换行 · 部署留痕

- **执行者**：workbuddy@zhn-tbxg2iah-win
- **档位**：T2（NAS 部署 + 共享仓留痕 + 推双远端）
- **时间**：2026-11-24 08:27–08:29（GMT+8）
- **人类要求**：机器码悬浮窗口宽度加大，不要换行（承接 08:24 上线的机器码查看功能）

## 自检
- 规范 v2.8；几分钟前刚完成全量 10 步自检，本轮复用：记忆目录正常、`config/` 仅 `feishu-app-id-parva.txt` 已知缺项；MCP 9101 本任务不需；无 `.compact-lock`；tools-scan --check ✅；stockdb 无仓库项目挂接不适用。
- 本轮推送前重跑 `proxy-check`：代理 10808 可连、会话代理 55592（平台分配，未写全局）、本地 HEAD `bffdaf4` = origin = backup；工作区有他人未提交改动，精确 add 两个自身文件、不 pull、不触碰。
- **挂起项**（继承最新快照，不认领）：prnmgt S1（T-059/T-060/T-061）、S2（P0 二次真机调研）、S3（v4/#18）均 suspended，解挂权归人类；stockdb 无挂起项。

## 改动（仅 `web/sync.html`）
- 悬浮窗 `.tip`：宽度 `max(360px,100%)/max-width:min(92vw,520px)` → `max(520px,100%)/max-width:min(96vw,760px)`。
- 换行修复：去掉 `white-space:pre-wrap;word-break:break-all`（原会换行），改 `.tip .row{display:block;white-space:nowrap}`（每条历史独占一行、行内不换行），标题 `.tt` 加 `white-space:nowrap`，容器加 `overflow-x:auto` 供窄屏横向滚动。
- 渲染 `loadNodeId()`：历史行 `join('\n')` → `join('')`，改由 `.row` 块级分行；`class="row"` 保留当前项 `cur` 高亮。
- **未改**：控制服务、后端 `/ctl/nodeid`、token、nginx、数据、同步逻辑——均未动。

## 部署与自检
- 08:28 部署：先上传 `/tmp/sync-new-20261124b.html` 核对 MD5 一致（26929B），再备份线上 `sync.html.bak.20261124-widertip`（旧 26885B）并覆盖。
- MD5：`0af381523e99cd9b38f8c954640b66d5` → `7ef644a856ad9084d466d46a0938fcc0`。
- 自检全部通过：① `node --check` JS 语法 ✅；② 关键 CSS/渲染特征命中（520px/760px/`.row` nowrap/标题 nowrap）；③ 线上 `sync.html` HTTP 200 / 26929B；④ `/ctl/nodeid` 联动正常（current `d267b7c8-76e9-45c7-9e4a-cb87a7de71e7`，1 条历史 `2026-11-24 08:24:13`）；⑤ `/tmp` 残留清理。
- **局限**：本机无浏览器二进制（playwright 无内核），未做真实 hover 截图；以 JS 语法 + CSS/渲染特征 + 接口联动 + DOM 结构验证替代。
- 口令未落盘、未回显、未入 Git。

## 归档
- `~/.agent-docs/绿联NAS/261111｜重建｜stockdb docker 引擎与看板重建/脚本/sync.html` 已同步（MD5 一致）。
- 主提示词：第 70 行版本标记 ★v5 → ★v6（注明悬浮窗加宽不换行）；第 164 行修改点表补述 `.tip` 新宽度/`.row` nowrap/容器 overflow-x；第 232 行 MD5 更新。

## 待人类
- 昨晚 22:00 起机器码为 `d267b7c8-76e9-45c7-9e4a-cb87a7de71e7`（当日第 4 次漂移），仍未扫码验证。如需恢复下载，用该 ID 本人完成 `https://a.123128.xyz/verify?id=d267b7c8-76e9-45c7-9e4a-cb87a7de71e7`，完成后由 agent 触发同步并自检最新交易日（当前 20261123）。
- 一天漂移 4 次已非偶发，建议向官方反馈或排查机器码变化源头。
