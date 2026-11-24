# 2026-11-24 stockdb 机器码悬浮窗可悬停复制 · 部署留痕

- **执行者**：workbuddy@zhn-tbxg2iah-win
- **档位**：T2（NAS 部署 + 共享仓留痕 + 推双远端）
- **时间**：2026-11-24 08:29–08:31（GMT+8）
- **人类要求**：上一条加宽后，鼠标离开顶部机器码标签浮窗即消失，要求鼠标能停在浮窗上复制文字。

## 背景 / 根因
- 上一版（08:28）机器码悬浮窗 `.nid .tip` 定位 `top:calc(100% + 6px)`，芯片与浮窗之间有 6px 空隙。鼠标从芯片移向浮窗经过空隙时离开 `.nid:hover` 命中区，浮窗 `display:none`，无法选中文字。

## 改动（仅 `web/sync.html`）
- `.nid .tip`：`top:calc(100% + 6px)` → `top:100%` 紧贴芯片底部；6px 外间隙移作内部 `padding:16px 12px 10px`（视觉间距不变，但 hover 路径连续无空隙）。
- 加 `cursor:auto;user-select:text`，使浮窗文字可选中复制（覆盖芯片的 `cursor:help`）。
- 原理：浮窗是 `.nid` 的 DOM 后代，鼠标停在浮窗上时 `.nid:hover` 仍成立 → `:hover .tip{display:block}` 持续显示；配合无间隙定位，鼠标可平滑移入并选中文字。
- **未动**：失败卡片 `.slot .tip`（仍 `top:calc(100% + 6px)`，与本次无关）、控制服务、后端、token、nginx、数据、同步逻辑。

## 部署与自检
- 08:29 部署：上传 `/tmp/sync-new-20261124c.html` 核对 MD5 一致（26954B），备份线上 `sync.html.bak.20261124-selectable`（旧 26929B）并覆盖。
- MD5：`7ef644a856ad9084d466d46a0938fcc0` → `53874d922b06a73d5cd13add986b3511`。
- 自检通过：① `node --check` ✅；② 关键特征命中 4（top:100% / padding:16px / cursor:auto;user-select:text / .row nowrap）；③ 线上 200 / 26954B；④ 后台结构校验：tip 嵌套在 nid 内=True、`.nid:hover .tip` 规则存在=True、间隙已消除=True（`calc(100% + 6px)` 仅剩失败卡片 `.slot .tip` 一处）、可选中=True；⑤ `/tmp` 清理。
- **局限**：本机无浏览器二进制（playwright 无内核），未做真实 hover/选中截图，用 JS 语法 + 特征 + DOM 结构校验替代。
- 口令未落盘、未回显、未入 Git。

## 归档
- `~/.agent-docs/绿联NAS/261111｜重建｜stockdb docker 引擎与看板重建/脚本/sync.html` 已同步（MD5 一致）。
- 主提示词：第 70 行 ★v6 → ★v7（注明可悬停复制）；第 164 行修改点表补述 `top:100%`/`padding-top:16px`/`cursor:auto;user-select:text` 及断链根因；第 232 行 MD5 更新。

## 待人类（沿用上一 handoff）
- 机器码 `d267b7c8-76e9-45c7-9e4a-cb87a7de71e7`（11-23 22:00 第 4 次漂移）仍未扫码验证。如需恢复下载，本人完成 `https://a.123128.xyz/verify?id=d267b7c8-76e9-45c7-9e4a-cb87a7de71e7` 后由 agent 触发同步并自检最新交易日（当前 20261123）。
- 一天漂移 4 次非偶发，建议向官方反馈或排查机器码变化源头。
