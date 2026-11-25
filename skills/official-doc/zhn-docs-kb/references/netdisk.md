# Baidu Netdisk External Delivery (`zhn-docs-kb/references/netdisk.md`)

> 按需加载：仅在执行百度网盘对外交付（`purpose=delivery`）或批量文件夹上传时读取。
> **定位**：本期百度网盘**只服务对外交付**；异地冷备由 NAS 链路独占（`[spec/backup.md#S5.3]`），禁止双写；本期不启用 WSL 通道与 `bdpan` Skill。

## 1. Platform Channel & Constraints

- **Windows 原生通道**：官方 MCP（`baidu-netdisk/mcp`：SSE 管理检索 + stdio `uv run netdisk.py` 上传）。
- **能力边界**：MCP 支持上传、列表、元信息、搜索、创建分享链接，**不支持下载/转存/读正文**（不得伪造；确需取回由人类在客户端完成）。
- **禁止项**：Windows 原生不得安装 `bdpan` Skill；本期不启用 WSL 通道；不自动轮询官方升级。
- **安装与凭证**：
  - 安装前先跑 `env/tools-scan.sh --check`；`uv` 放 `~/.agent-tools/bin/`；MCP 源码放 **`~/.agent-tools/mcp/`**（遵守 `rules.md#R2` 与 `[spec/layout.md#S2.2]`）。
  - Token 仅写本机 `~/.workbuddy/mcp.json`（SSE URL query / stdio 环境变量），禁入 Git、日志、记忆、handoff 或索引；新增/修改 MCP 后须人类在客户端点「信任」。
  - `file_upload_stdio` 的 `remote_path` 必须以 `/` 开头并显式指定目标根（见 `env/kb-endpoints.md`），首次使用前先 `file_list` 只读探测授权范围并记录实测速度/限流至 `env/kb-endpoints.md`。

## 2. Batch Folder Upload (`purpose=delivery`)

### 2.1 Pre-Upload Confirmation (Mandatory)
开始上传前必须输出清单并**等待人类明确确认**：
- 源路径、文件数、总大小、预计请求数、目标根路径（如 `/apps/bdpan/delivery/...`）、模式（逐文件 / 打包分卷）、排除清单（基于 `secret-exclude.txt`，排除 `secret`、隐藏/临时文件、符号链接不跟随、`~/.agent-shared/**`）、是否生成分享链接、`purpose=delivery`。

### 2.2 Upload Modes
- **逐文件模式（默认）**：保留目录结构，串行或并发 1；每 20 个文件暂停汇报进度；失败记入失败清单，继续或中止由人类决定。
- **打包分卷模式（建议阈值 `> 500` 文件）**：无需网盘逐文件预览时，本地打包分卷后仅上传压缩包与 manifest，降低请求数与限流风险。

### 2.3 Manifest & Batch Record
- **manifest（必填）**：每条记录 `相对路径`、`size`、`sha256`、`状态`（`pending|success|failed|skipped`）、`网盘路径`、`错误信息`；重入时 `success` 且本地 `sha256` 未变自动 `skipped`。
- **批次记录**：`batch_id`、`purpose=delivery`、源路径、模式、文件数、总大小、目标根路径、manifest 路径、状态、失败清单、起止时间、执行者；认领锁写进 `memory/projects/<项目名>.md` 任务登记节。

## 3. Rate Limit & Backoff

- 网络/限流失败采用指数退避（1s → 2s → 4s → 8s → 16s，最多 5 次），记录错误码与阈值；连续失败即停并报告人类，禁止切换未授权通道绕过。
- 首次每平台使用须完成小文件冒烟（上传 → 列表 → 元信息 → 搜索；分享仅经人类批准后测）并回填 `env/kb-endpoints.md`。
