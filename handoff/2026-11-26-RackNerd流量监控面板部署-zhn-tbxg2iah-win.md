# RackNerd 流量与资源监控面板部署待接手摘要

- 项目：RackNerd VPS `23.94.211.70`（与 261116 Xray 部署同机）
- 执行者：`workbuddy@zhn-tbxg2iah-win~zhn-x-w`
- 时间：2026-11-26 21:00 UTC+8
- 状态：`done`（端到端自检通过，零公网暴露）；**非任务卡，人类当次直接下达的运维请求**（B1~B5 逐条拍板「按建议办」）

## 交付

- vnStat v2.12（`active`+`enabled`），主网卡 `eth0`，时区 `Etc/UTC`，月度与面板 UTC 1 号重置天然对齐
- 面板服务 `vpspanel.service`（`active`+`enabled`，`Restart=always`），程序 `/opt/vpspanel/panel.py`（Python 3 标准库零依赖），数据 `/opt/vpspanel/data.db`（SQLite）
- 服务用户 `vpspanel`（nologin 系统用户，入 `vnstat` 组），加固 `NoNewPrivileges=yes`/`ProtectSystem=strict`/`ProtectHome=true`/`PrivateTmp=true`
- 三资源：带宽（手工基准 + vnStat 增量，3000GB/月）、磁盘、内存；80%/95% 变色
- 手工校准录入（精确到分，提交时自动抓当时 vnStat rx/tx）、规则反推（rx/tx/rx+tx/max 四口径 MAPE 拟合，样本不足返回 None）
- **零暴露**：仅 `127.0.0.1:8080`，ufw 不开 8080，公网直连实测不可达；访问走 SSH 隧道 `-L 18080:127.0.0.1:8080`（复用 51727 + Ed25519 私钥 `RackNerd-ssh-key-2026-11-24`）

## 验收证据

- 本地 API `200`、页面 `200`、SSH 隧道 `200`、公网 8080 不可达、重启后 `active`+`200`、绑定仅 `127.0.0.1`
- 算法单测：tx 口径样本→选出 `tx`（mape 0%），rx+tx 样本→选出 `rx+tx`（mape 0%）
- 修 2 个 bug：vnStat 首分钟月度数组空→回退 total；无有效样本 rule 误选→返回 None
- 3 条测试数据已清空（`records=0`），面板为干净初始态

## 文档与索引

- 运维文档：`docs://技术资料/261116｜部署｜Xray代理服务/261126｜运维｜流量监控面板部署与运维.md`
- 飞书索引已登记（rev 46，`record-get` 按 ID 回读确认落库；密级 `internal`，未上传副本）
- 未改现有 Xray 配置 / ufw 规则 / SSH 配置；当日工作区日志已留痕

## 待办 / 交接注意

- 连续录入 5~7 天面板读数后复核规则反推结论（口径/延迟），据此决定是否修正面板显示
- 阈值外部告警（邮件/Telegram）未做——需 token；目前仅页面变色
- 面板源码在服务器 `/opt/vpspanel/panel.py`，本地临时副本会话结束即清理；如需版本管理另议（禁入 Git）
- 计费最终以 RackNerd 面板为准，本地估算不替代账单
