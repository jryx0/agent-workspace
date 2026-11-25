---
name: zhn-docs-kb
description: "多 Agent 文档知识库的分层存储、分流判断、飞书单向预览+多维表格索引、百度网盘对外交付与墓碑删除规范。跨设备原件同步由统一同步工具负责，命名委派 zhn-docs-std。按需加载 references/ 细则。"
agent_created: true
version: 1.0.0
metadata:
  source: "~/.agent-shared/skills/official-doc/zhn-docs-kb/SKILL.md"
  install: "bash ~/.agent-shared/env/install-skill.sh zhn-docs-kb"
---

# zhn-docs-kb — 多 Agent 文档知识库操作规范 (v1.0.0)

> 上位规范：`~/.agent-shared/global/rules.md` (v3.0, `[spec/layout.md#S2.3]`, `[spec/backup.md#S5.2]`, `R1-R5`)。
> 命名强制委派：`zhn-docs-std` (v2.0.0)；外部端点/索引表坐标见 `env/kb-endpoints.md`（本文件不含实例坐标或秘密）。
> **按需扩展文档**（仅涉及对应场景时再读）：
> - 飞书 `lark-cli` 安装、命令映射、全量同步与踩坑 → `references/feishu-cli.md`
> - 百度网盘对外交付、批量文件夹上传与 manifest → `references/netdisk.md`
> - 技能分发、多账号边界与新 Agent 接入提示 → `references/install.md`

---

## K1. 存储分层与唯一原件（方案 A，已与 `spec/layout.md#S2.3` 对齐）

| 层 | 位置 | URI | 角色与通道 | 原件归属 |
|---|---|---|---|---|
| 共享仓层 | `~/.agent-shared` | Git 路径 | 规范/技能/记忆/配置，Git 双远端，**绝不上云盘/飞书** | 原件 |
| 活跃文档层 | `~/.agent-docs` | `docs://<相对路径>` | 重要文档原件（≤100MB）；**跨设备原件同步由统一第三方同步工具负责**（如 WPS 企业盘，详见 `env/kb-endpoints.md`） | **唯一原件** |
| 在线预览层 | 飞书云空间 | `feishu://<token>` | **单向只读预览副本**（经 `lark-cli --profile parva`）；`.md` 导入为 `docx` 在线可读，其他可预览格式原格式上传 | 仅派生副本 |
| 索引层 | 飞书多维表格 | `kb://` | 统一元数据检索索引 + 版本戳 + 墓碑（`~/.agent-docs/kb/` 仅离线回退，禁双写） | 索引 |
| 对外交付层 | 百度网盘（MCP） | `pan://<相对路径>` | **仅对外交付副本**（`purpose=delivery`），默认不生成分享链接 | 仅副本 |
| 异地冷备层 | NAS `Z:\` / `/mnt/nas` | `nas://<相对路径>` | 超大文件(>100MB)/归档 + **异地冷备（NAS 链路独占，本技能不写冷备）** | 冷备/大文件原件 |

**核心架构红线**：
- `~/.agent-docs` 是唯一原件；跨设备同步靠统一同步工具，**不再把飞书当作 `.md` 原件双向/回覆盖通道**（彻底避免 `.md` → `docx` 格式变换导致 sha256 不一致与覆盖原件风险）。
- 禁止在飞书在线编辑预览副本，禁止用云端副本反向覆盖 `~/.agent-docs` 原件。
- 知识库外的人类指定文件夹：原件留原位置，网盘交付仅登记批次记录，不迁入 `~/.agent-docs`。

---

## K2. 文件分流顺序（按序命中第一条）

1. **密级 `secret`**（或命中同目录 `secret-exclude.txt`）→ 仅留本机安全位置，**禁上飞书/网盘、禁分享**，终止并提示人类。
2. 属于 `~/.agent-shared` → 仅 Git 双远端，不上云。
3. 超大视频 / 大型二进制（>100MB）→ 走 NAS（`[spec/backup.md#S5.2]`），不入知识库。
4. Agent 产出文档 / 人类指定文档 → 落盘 `~/.agent-docs`（命名调用 `zhn-docs-std`），同步工具自动完成跨设备原件同步。
5. **需在线阅读 / 纳入统一检索** → 单向推送到飞书只读预览副本 + 登记多维表格索引（见 `K4` 与 `references/feishu-cli.md`）。不可在线阅读的脚本/配置类文件（`.sh/.py/.ps1/.yml/Dockerfile` 等）默认不上飞书，除非人类明确指令。
6. **需对外交付** → 上传百度网盘交付副本（`purpose=delivery`，单文件或批量均见 `references/netdisk.md`），默认不建分享链接。

---

## K3. 命名与引用

- 进入 `~/.agent-docs` 的主文件、批次目录、整理操作一律委派 `zhn-docs-std` v2.0.0；调用时若已查多维表格/同目录，向其提供既用类型标签以便复用。
- 上传飞书/网盘的副本沿用原件文件名与相对路径；跨文档引用一律用 `docs://`、`feishu://`、`pan://`、`nas://`、`kb://`，禁写本机绝对路径。

---

## K4. 索引、写入与墓碑删除

坐标（`base_token`、`table_id`、`folder_token`）与枚举定义统一见 `env/kb-endpoints.md`。

- **核心字段**：`doc_id`（`sha256[:12]@<backend>:<ref>`）、`文件名`、`相对路径`、`后端`、`后端路径或 file_id`、`size`、`sha256`、`mime`、`密级`、`copy_of`、`status`（`active|pending|pending_orphan|missing|deleted`）、`purpose`（`preview|delivery|index`）、`channel`（`cli|mcp|skill`）、`version_sha256`、`origin_updated_at`、`updated_by`、`backend_ref`，及 append-only 墓碑字段（`deleted_at`、`deleted_by`、`deleted_origin_device`、`deleted_sha256`、`指令批次`）。
- **两阶段写入**：
  1. 命名 → 计算流式 `sha256` → 索引查重（同 sha256 复用；同名异 sha256 走撞名确认）→ 写 `status=pending`；
  2. 执行上传/导入（飞书 `.md` 用 `drive +import --type docx`，其他可预览格式用 `drive +upload`）→ 回读核对 → 置 `active` 并写版本戳与 `backend_ref`；失败置 `pending_orphan` 并报告人类，禁自动重删重传。
- **取回边界**：本地已有同步原件优先直接读 `~/.agent-docs`；确需从飞书临时取回只读参考时，`type=file` 用 `drive +download` 并校验 `sha256`，`.md` 对应 `type=docx` 用 `docs +fetch` 做只读语义核对，**严禁覆盖本地 `.md` 原件**。
- **删除与墓碑（严守 `rules.md#R3`）**：
  - 禁止自动执行 `drive +delete`、`+push --delete-remote` 或物理删除同步目录文件；
  - 收到人类删除指令时：多维表格将记录置 `status=deleted` 并 append-only 写墓碑字段；本地同步目录与飞书云空间物理删除一律交人类在客户端 UI 完成（非同步临时区可移入 `.trash/` 保留 30 天）；同名新文件不得自动“复活”覆盖墓碑。

---

## K5. 密级与安全红线

- **四级密级**：`public` / `internal` / `confidential` / `secret`；**未标注一律按 `internal` 保守处理**。
  - `secret`：禁上云、禁分享；
  - `confidential`：仅可进飞书只读预览，**禁生成分享链接、禁上网盘**；
  - `internal` / `public`：可按人类指令上传网盘对外交付。
- **分享**：默认关闭；仅人类当次明确指令生成，优先 7 天短有效期；**提取码永不写入索引、Git、记忆或 handoff**。
- **凭证隔离**：`app_secret` 放本机 `config/`（`0600`、禁 Git），飞书登录态留本机 `~/.lark-cli/config.json`，网盘 Token 仅写本机 `~/.workbuddy/mcp.json`；**跨设备/跨 Agent 软件严禁复制或分发凭证与登录态**（`[spec/accounts.md#S3.8g]`）。

---

## K6. 多 Agent 协同

- 批量同步/交付任务认领统一追加至 **`memory/projects/<项目名>.md` 任务登记节**（遵循 `rules.md#S3.5c`，防撞键 `项目 + 任务ID` / `batch_id`），不得双人并发写同一批次；共享仓提交只 `git add` 自己改动。
- 禁止主动后台同步、禁止建轮询/事件订阅自动化、禁止在 Windows 原生安装 `bdpan` Skill、本期不启用 WSL 通道。

---

## K7. 禁止事项速查

- 禁伪造未实测能力（网盘限流/配额等未测项标 `TBD`）；
- 禁把飞书当原件或用 docx 覆盖本地 `.md`；
- 禁全局安装 `@larksuite/cli`（`npm install -g` / `npx @larksuite/cli install` / `npx skills add -g` 均违 `R2`）；
- 禁自动执行云端物理删除或改回飞书 MCP；
- 禁改 `global/` 规范正文（`R4`）或手改已安装的技能副本（须改权威原件再跑 `install-skill.sh`）。
