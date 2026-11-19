# 项目代码 Git 地址登记表（规范 七 / v1.8）
# 本仓库（~/.agent-shared）不同步任何项目代码；所有项目仓库在此登记。
# 克隆路径统一约定：~/source/<项目名>（v1.8 起，原 ~/work 废弃）
# 格式：项目名 | Git 地址 | 默认分支 | 本地约定克隆路径 | 简述 | 记忆文件
# v1.8.11 起：每个项目还须在下方「项目属性补充表」登记资产/挂接/部署/凭据（规范 七-1）
项目名 | Git 地址 | 默认分支 | 本地约定克隆路径 | 简述 | 记忆文件
prnmgt | https://github.com/jryx0/prnmgt.git | master | ~/source/prnmgt | Cloudflare Worker + D1 打印机管理系统重构（43 卡全 done，生产运行中） | projects/prnmgt.md
stockdb | 无（资产在 NAS /volume1/docker/stockdb，经 SMB docker 共享访问） | 无 | 无（不在 ~/source） | A 股行情数据引擎 NAS 常驻服务：7899 引擎 + 8080 查询页/同步看板 | projects/stockdb.md
pRayShell | 本地仓，无 remote（不推远端） | master | ~/source/pRayShell | 类 v2rayN 的 xray-core 客户端；第一轮仅交付 4 份设计文档（工程代码/测试延后第二轮），技术选型开放 ADR 未锁定 | projects/pRayShell.md
pCryoxy | https://gitee.com/ParvaUltra/pCryoxy.git | main | ~/source/pCryoxy | 现代加密代理协议图形化前端与调度外壳（Rust＋Tokio 调度、Tauri v2、SolidJS；Windows＋Android 优先）；PC-00 空壳构建基线已建立，真机验收待后续卡 | projects/pCryoxy.md

## 项目属性补充表（v1.8.11，规范 七-1；v2.0 增加协作模式列，所有项目必填）

> 判定「无代码仓库 / 非 `~/source` 项目」的权威依据；不适用条款清单见 `global/rules.md` 七-1。
> 项目级凭据落在项目本地或平台凭据库，**不进 `~/.agent-shared/config/`**、也不列入 `keys-checklist.md` 的 `config/` 存在性核对；但必须写明落点与是否入 Git（六-1 gitleaks 兜底）。
> **协作模式列（v2.0）**：仅供登记参考，**不是 〇⑦ 档位判据** —— 档位按「本次操作碰不碰共享资产」判定；一旦写 `~/.agent-shared` 或 `~/.agent-tools` 即 T2，与本项目是否协作无关。

| 项目名 | 资产位置 | AGENTS 挂接 | 部署入口 | 凭据落点 | 不适用条款声明 | 协作模式（参考，非档位判据） |
|---|---|---|---|---|---|---|
| prnmgt | `~/source/prnmgt`（GitHub `jryx0/prnmgt`，master）+ Cloudflare Workers / D1 线上 | 已挂接 `~/source/prnmgt/AGENTS.md` 首部（〇②） | 项目 `worker/package.json` scripts：`npx wrangler deploy`；DDL 与部署归人类（三-7 ④ / ADR-0010 D4） | wrangler OAuth 在项目本地平台凭据库，**不入 Git**；`~/source/prnmgt/.login-out.txt` 为未跟踪登录输出，禁止误 `git add .` | 无（标准 Git 仓库项目） | 多 Agent 协作（任务卡登记 / worktree / 人类合并）；相关会话按 〇⑦ 强制 T2 |
| stockdb | NAS `/volume1/docker/stockdb/`（SMB `\\10.113.124.232\docker\stockdb`）；**无 Git 仓库、不在 `~/source/`**；**权威备份**：`~/.agent-docs/脚本/NAS/stockdb-docker/重建/`（v1.3.0 批量结构：主文件 + `脚本/` 18 原名文件，NAS 变更须手动同步归档） | **不适用**（无工作区规则文件，勿判接入未完成） | NAS 宿主 `sudo docker compose` / 容器内 `docker exec stockdb /stockdb/scripts/engine-ctl.sh start / status / stop`、`sync.sh`；**看板远程启动**：`POST http://10.113.124.232:8080/ctl/start`（引擎离线时看板按钮，宿主 `engine-ctl-server.py` + `/etc/cron.d/stockdb-ctl` 保活）；引擎启停、容器重启、升级属部署（三-7），需人类当次授权且 ③ 四条件全满足 | 本机**常态无免密 SSH 凭据**；18:40 人类当次提供 `zjsj` 口令，经 `plink -batch -pw` + `sudo -S`(stdin) 非交互登录成功，**口令不落盘/不回显/不入 Git**；日常只读走 HTTP 8080 / 7899 + SMB `docker` 共享 | 〇② 挂接 / 三-5 ③ 项目目录占用确认 / 三-6 worktree / 七节 clone 约定 | 单人诊断；部署由 workbuddy 在三-7 满足时执行（18:45 / 19:01 / 19:15 三次留痕）；无任务卡登记，但写共享仓 / 部署时仍强制 T2 |
| pRayShell | `~/source/pRayShell`（本地 git 仓，`master`，**无 remote**；项目代码不进共享仓）；4 份设计文档 + `AGENTS.md` + `.gitignore` | 已挂接 `~/source/pRayShell/AGENTS.md` 首部「开工前必读顺序」第 0 项（〇②） | **不适用·本轮不部署**（纯设计交付，无服务/引擎/容器；用户拍板不部署、不推远端、不 git sync） | 项目本地 gitignored `config/*.local` + 环境变量 / OS 凭据库，`ISecretProvider` 单点读取，**不入 Git**；不列入 `keys-checklist.md` 的 `config/` 存在性核对（规范七-1） | 无（标准 Git 仓库项目；但无 remote，不推双远端、不 git sync、不部署；先 `git init` 再放文档，不构成七-1 占位目录） | 多 Agent 并行（文档阶段 Wave 0 契约冻结 / Wave 1 并行 4 份 / Wave 2 核对）；写共享仓登记按 〇⑦ 强制 T2 |
| pCryoxy | 现阶段**仅文档资产**：`~/.agent-shared/handoff/` 下 4 份正式文档 + 统一入口；**代码仓尚未建立**（建仓属 PC-00），`~/source/pCryoxy` 当前不存在 | **不适用（建仓前）**：无工作区规则文件；建仓后由 PC-00 补挂接并回填本表，不视为接入未完成 | **不适用·本轮不部署**（仅文档发布，无服务/引擎/容器；本轮不建仓、不装依赖、不认领实施卡） | 规划为项目本地平台凭据库 + 环境变量（Windows Credential Manager / Android Keystore 为运行时设计），**不入 Git**；不列入 `keys-checklist.md` 的 `config/` 存在性核对（规范七-1） | 〇② 挂接（建仓前）/ 三-5 ③ 项目目录占用 / 三-6 worktree / 七节 clone 约定 —— 建仓前均不适用；**不得据此创建占位目录** | 多 Agent 协作（任务卡登记 + 认领 + WorkBuddy 审核）；写共享仓按 〇⑦ 强制 T2 |
| 参考：共享层（非项目） | `~/.agent-shared` | — | `git sync`（双远端分步 push） | `~/.agent-shared/config/` 4 类 SSH 私钥 + WPS 客户端账号，清单见 `keys-checklist.md` | — | 全 Agent 共享仓，写入一律 T2 |
