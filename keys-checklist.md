# 密钥核对清单（规范 六）
# 只列密钥名称与用途，严禁写入密钥值。密钥本体由人类手动分发到本机 ~/.agent-shared/config/。
# 维护规则：新增密钥先更新本清单再分发；废弃密钥标注废弃日期；泄漏事故按规范 六-1 处置。

| 密钥项 | 用途 | 状态 | 备注 |
|---|---|---|---|
| Oracle-ssh-key-2026-10-06.key / .key.ppk | PuTTY/SSH 私钥：oraclevps 服务器登录 | 已分发 2026-11-04 | 原件在 `~/.ssh/`，副本在 `config/`；.pub 公钥未复制 |
| printer_ubuntu | PuTTY/SSH 私钥：printer-Monitor 服务器登录 | 已分发 2026-11-04 | 原件在 `~/.ssh/`，副本在 `config/`；.pub 公钥未复制 |
| id_ed25519 / id_ed25519.ppk | 通用 Ed25519 SSH 密钥（Git/服务器认证） | 已分发 2026-11-04 | 原件在 `~/.ssh/`，副本在 `config/`；.pub 公钥未复制 |
| wps-enterprise-account | WPS 企业账号（承载 ~/.agent-docs 同步，凭证在 WPS 客户端） | 已登录本机 2026-11-04 | 密码不入库；账号变动会影响 agent-docs 同步 |
