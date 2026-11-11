# 项目代码 Git 地址登记表（规范 七 / v1.8）
# 本仓库（~/.agent-shared）不同步任何项目代码；所有项目仓库在此登记。
# 克隆路径统一约定：~/source/<项目名>（v1.8 起，原 ~/work 废弃）
# 格式：项目名 | Git 地址 | 默认分支 | 本地约定克隆路径 | 简述 | 记忆文件
# v1.8.11 起：每个项目还须在下方「项目属性补充表」登记资产/挂接/部署/凭据（规范 七-1）
项目名 | Git 地址 | 默认分支 | 本地约定克隆路径 | 简述 | 记忆文件
prnmgt | https://github.com/jryx0/prnmgt.git | master | ~/source/prnmgt | Cloudflare Worker + D1 打印机管理系统重构（43 卡全 done，生产运行中） | projects/prnmgt.md
stockdb | 无（资产在 NAS /volume1/docker/stockdb，经 SMB docker 共享访问） | 无 | 无（不在 ~/source） | A 股行情数据引擎 NAS 常驻服务：7899 引擎 + 8080 查询页/同步看板 | projects/stockdb.md

## 项目属性补充表（v1.8.11，规范 七-1；v2.0 增加协作模式列，所有项目必填）

> 判定「无代码仓库 / 非 `~/source` 项目」的权威依据；不适用条款清单见 `global/rules.md` 七-1。
> 项目级凭据落在项目本地或平台凭据库，**不进 `~/.agent-shared/config/`**、也不列入 `keys-checklist.md` 的 `config/` 存在性核对；但必须写明落点与是否入 Git（六-1 gitleaks 兜底）。
> **协作模式列（v2.0）**：仅供登记参考，**不是 〇⑦ 档位判据** —— 档位按「本次操作碰不碰共享资产」判定；一旦写 `~/.agent-shared` 或 `~/.agent-tools` 即 T2，与本项目是否协作无关。

| 项目名 | 资产位置 | AGENTS 挂接 | 部署入口 | 凭据落点 | 不适用条款声明 | 协作模式（参考，非档位判据） |
|---|---|---|---|---|---|---|
| prnmgt | `~/source/prnmgt`（GitHub `jryx0/prnmgt`，master）+ Cloudflare Workers / D1 线上 | 已挂接 `~/source/prnmgt/AGENTS.md` 首部（〇②） | 项目 `worker/package.json` scripts：`npx wrangler deploy`；DDL 与部署归人类（三-7 ④ / ADR-0010 D4） | wrangler OAuth 在项目本地平台凭据库，**不入 Git**；`~/source/prnmgt/.login-out.txt` 为未跟踪登录输出，禁止误 `git add .` | 无（标准 Git 仓库项目） | 多 Agent 协作（任务卡登记 / worktree / 人类合并）；相关会话按 〇⑦ 强制 T2 |
| stockdb | NAS `/volume1/docker/stockdb/`（SMB `\\10.113.124.232\docker\stockdb`）；**无 Git 仓库、不在 `~/source/`** | **不适用**（无工作区规则文件，勿判接入未完成） | NAS 宿主 `sudo docker compose` / 容器内 `scripts/engine-ctl.sh start`；引擎启停、容器重启、升级属部署（三-7），未经人类授权不执行 | 本机**无免密 SSH 凭据**（publickey / password 均被拒）；日常只读排查走 HTTP 8080 / 7899 + SMB `docker` 共享，无凭据落盘 | 〇② 挂接 / 三-5 ③ 项目目录占用确认 / 三-6 worktree / 七节 clone 约定 | 单人只读诊断 + 人类部署；无任务卡登记，但写共享仓 / 部署时仍强制 T2 |
| 参考：共享层（非项目） | `~/.agent-shared` | — | `git sync`（双远端分步 push） | `~/.agent-shared/config/` 4 类 SSH 私钥 + WPS 客户端账号，清单见 `keys-checklist.md` | — | 全 Agent 共享仓，写入一律 T2 |
