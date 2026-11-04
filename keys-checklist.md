# 密钥核对清单（规范 六）
# 只列密钥名称与用途，严禁写入密钥值。密钥本体由人类手动分发到本机 ~/.agent-shared/config/。
# 维护规则：新增密钥先更新本清单再分发；废弃密钥标注废弃日期；泄漏事故按规范 六-1 处置。

| 密钥项 | 用途 | 状态 | 备注 |
|---|---|---|---|
| putty-oraclevps.ppk | PuTTY SSH 私钥：oraclevps 服务器登录 | 待分发 | 目标位置 `~/.agent-shared/config/`；如需 OpenSSH 格式可由 ppk 转换 |
| putty-printer-monitor.ppk | PuTTY SSH 私钥：printer-Monitor 服务器登录 | 待分发 | 同上 |
