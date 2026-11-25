# Knowledge Base External Endpoints (`env/kb-endpoints.md`)

> 配套技能：`skills/official-doc/zhn-docs-kb/SKILL.md` (v1.0.0) 与 `references/feishu-cli.md`、`references/netdisk.md`。
> **安全红线（`rules.md#R1`）**：本文件**只登记非秘密坐标与约定路径**，严禁写入 `app_secret`、Access Token、密码、提取码或个人身份证件信息。密钥本体一律存本机 `~/.agent-shared/config/` 并登记于 `keys-checklist.md`。

## 1. Feishu (`lark-cli --profile parva`)

| Key | Value | Notes |
|---|---|---|
| CLI Profile | `parva` | 必传 `--profile parva`，缺省会落到旧租户并报 `21001` |
| CLI Binary | `~/.agent-tools/bin/lark-cli.exe` (v1.0.100) | 非全局安装；sha256 登记于 `env/toolchain.md` |
| Tenant Code | `P1499QMSJ` | 自建企业租户 |
| App ID | `cli_aa77a9fe69385c13` | 应用名 `agent-docs`；`app_secret` 仅存本机 `config/feishu-app-secret-parva.txt` |
| Index Base (`base_token`) | `KouDbtqSyamyHtsJZuKcNvNXnee` | 表名 `索引主表`，33 列，`doc_id` 主字段，`Asia/Shanghai` |
| Index Table (`table_id`) | `tblJRefSlsHuCwJn` | 枚举：`后端`=docs/feishu/pan/nas；`密级`=public/internal/confidential/secret；`status`=active/pending/pending_orphan/missing/deleted；`purpose`=delivery/preview/index；`channel`=cli/mcp/skill |
| Drive Root (`folder_token`) | `OU68fE99Tlr1SidQgMCcKmCYnog` | 镜像 `~/.agent-docs` 一级目录（`MySkill/工作/技术资料/模型使用/绿联NAS/股票研究`） |
| Base URL | `https://hcnr1wipkvsc.feishu.cn/base/KouDbtqSyamyHtsJZuKcNvNXnee` | 在线检索视图 |
| Drive Root URL | `https://hcnr1wipkvsc.feishu.cn/drive/folder/OU68fE99Tlr1SidQgMCcKmCYnog` | 在线预览根目录 |

## 2. Baidu Netdisk (External Delivery Only)

| Key | Value | Notes |
|---|---|---|
| Channel (Windows) | Official MCP (`baidu-netdisk/mcp`) | Token 仅存本机 `~/.workbuddy/mcp.json`，禁入 Git |
| Delivery Root | `/apps/bdpan/delivery/` *(suggested, confirm per batch)* | 仅 `purpose=delivery`，不做冷备 |
| Batch Packaging Threshold | `> 500` files | 默认逐文件，>500 建议打包分卷 |
| Verified Limits | Speed / quota / rate limit = `TBD` | 实测后回填本表 |

## 3. Local Active Docs Sync & Cold Backup

| Layer | Mechanism | Reference |
|---|---|---|
| `~/.agent-docs` 原件跨设备同步 | 统一第三方同步工具（本机为 WPS 企业盘，详见设备档案与 `keys-checklist.md`） | `[spec/layout.md#S2.3]` |
| NAS 异地冷备 | NAS 自带云同步工具独占 | `[spec/backup.md#S5.2]` |
