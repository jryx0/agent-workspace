# RackNerd 新机 Xray 部署交接（23.94.211.70）

项目: 全局

- 执行：workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-24 09:50 UTC+8
- 状态：**已上线并端到端自检通过**
- 依据：`~/.agent-docs/技术资料/261116｜部署｜Xray代理服务/`（VLESS+REALITY 同构）+ Xray 官网 level-0 第 4 章（SSH 加固）/ 第 7 章（服务端安装）

## 一、最终状态（一分钟）

| 项 | 值 |
|---|---|
| 服务器 | RackNerd `23.94.211.70`（Ubuntu 24.04 LTS，x86_64，hostname `racknerd-7794342`） |
| SSH | 端口 **51727**，用户 `opstzih2`，**仅 Ed25519 私钥登录**；禁 root、禁密码；ufw 放行 51727 + 443 |
| 私钥 | `~/.ssh/RackNerd-ssh-key-2026-11-24`（副本 `~/.agent-shared/config/`，已登记 keys-checklist） |
| 协议 | VLESS + `xtls-rprx-vision` / tcp / **REALITY** / 443 |
| 伪装 target | `dl.google.com:443`，serverNames `["dl.google.com"]` |
| Xray | v26.11.9（官方脚本安装），服务 active、enabled |
| 配置路径 | `/usr/local/etc/xray/config.json`，权限 **640 root:xray** |
| 日志 | `/var/log/xray/{access,error}.log`，属主 **xray:xray**（曾因 root:root 600 导致启动失败，已修） |
| 优化 | BBR 已开（`net.ipv4.tcp_congestion_control=bbr`） |
| 自检 | 外部 443 可达、`xray -test` = Configuration OK.、出口 IP = `23.94.211.70`、`Configuration OK.` |

## 二、客户端参数（可分发，非私钥）

> **2026-11-24 更正（密钥轮换）**：导出参数时私钥曾误回显到工具输出，按「私钥不进对话/文档」红线已现场轮换密钥对。**下列公钥为轮换后的最新值**；旧值 `svxlUusYqUxJesP13i30sC5AnHEvyW0TrB9YfuH9rBI` 已作废，勿再使用。轮换后重验：`Configuration OK.` + active + 443 监听 + 握手返回 Google 证书。

- 地址：`23.94.211.70`
- 端口：`443`
- 协议：VLESS，flow `xtls-rprx-vision`
- UUID：`ee857907-9635-4b7b-83be-e9698dadb522`
- 安全：REALITY，serverName `dl.google.com`，publicKey `ZrVpHWezFAZNldxpF0o3yVay7g8s3q93CgU5UNvsFhQ`（新），shortId `448ab44ea1af21c9`
- 传输：tcp，加密 none
- VLESS 链接：`vless://ee857907-9635-4b7b-83be-e9698dadb522@23.94.211.70:443?encryption=none&security=reality&sni=dl.google.com&fp=chrome&pbk=ZrVpHWezFAZNldxpF0o3yVay7g8s3q93CgU5UNvsFhQ&sid=448ab44ea1af21c9&type=tcp&flow=xtls-rprx-vision#RackNerd`
- ⚠️ REALITY 私钥只在服务器 config.json 内，不在本文档/对话中留存。
- 完整可分发参数已导出到 `docs://技术资料/261116｜部署｜Xray代理服务/261124｜客户端｜RackNerd新机配置参数导出.md`；运维要点见同目录 `261124｜运维｜RackNerd新机运维手册.md`（两份已登记飞书索引、密级 internal、未上传副本）。

## 三、关键坑与处置（供日后维护）

1. **Ubuntu 24.04 是 systemd socket 激活**：改 `sshd_config` 的 `Port` 无效，必须在 `/etc/systemd/system/ssh.socket.d/override.conf` 写 `ListenStream=51727`（先写空 `ListenStream=` 清除默认 22 再叠加）。本次因只改 sshd_config 且 ufw 提前启用，两次把自己锁在外面，靠人类 VNC 恢复。
2. **ufw 顺序**：新 SSH 端口必须在禁用 22 **之前**放行并验证可登录；443 必须显式 `ufw allow 443/tcp`，否则 xray 监听了但外部连不上。
3. **config.json 权限**：必须 `640 root:xray`（资料红线）；设 600 或因 umask 077 导致 xray 读不到 → 启动 failed。
4. **日志目录权限**：`/var/log/xray` 与其中 *.log 必须归 `xray:xray`，否则 access logger 报 permission denied、服务 status=23。
5. **xray 无 `--loglevel` 命令行参数**：日志级别在 config.json 的 `log.loglevel` 改。
6. `xray -test -c <file>` 要求文件名能识别格式；用 `.json` 结尾，别用 `.new`（会报 Failed to get format）。
7. 部署中曾两次锁死 SSH，均由人类通过 RackNerd VNC 执行恢复命令解围；已记录以免重犯。

## 四、旧机清理

- 旧 RackNerd `107.175.219.173:21376` 已失效，经人类授权清理：`~/.ssh/known_hosts` 与 `known_hosts.old` 中该 IP 的 6 行已删（备份 `*.bak-20261124-092808` 保留）；`~/.agent-docs/261111｜账号｜账号信息整理.html` 中两行由人类在 WPS UI 删除；旧机本无私钥在册。

## 五、下一步

- 客户端（Windows/Android/Linux）按 §二 参数导入，按《三平台客户端配置指南》验证出口 IP。
- 定期检验备份：新机暂无备份包，建议按《备份说明》对 config.json 做离线加密备份（含 REALITY 私钥，禁入网盘明文）。
- 合规：用途由人类自行评估（资料总览已记该结论）。
