# Feishu CLI Operations (`zhn-docs-kb/references/feishu-cli.md`)

> 按需加载：仅在执行飞书索引读写、预览副本上传/导入/回读或新设备安装 `lark-cli` 时读取。
> 端点坐标（`base_token`、`table_id`、`folder_token`、`app_id`）见 `~/.agent-shared/env/kb-endpoints.md`。

## 1. Non-Global Installation (`rules.md#R2`)

**严禁** `npm install -g @larksuite/cli`、`npx @larksuite/cli install`、`npx skills add -g`。唯一合规路径为下载官方 Release 单文件二进制放 `~/.agent-tools/bin/` 并登记于 `env/toolchain.md` `Sec 5`：

```bash
# 示例（以 env/kb-endpoints.md 与 env/toolchain.md 登记版本与 sha256 为准）
curl -sL -o lark-cli.zip https://github.com/larksuite/cli/releases/download/v1.0.100/lark-cli-1.0.100-windows-amd64.zip
sha256sum lark-cli.zip
unzip -o lark-cli.zip lark-cli.exe -d ~/.agent-tools/bin/
~/.agent-tools/bin/lark-cli.exe --version
```

## 2. Profile Binding & Auth (Per-Device, Never Copy `config.json`)

每台设备与每个 Agent 软件须单独完成 `config init` + device flow，**严禁跨设备复制 `~/.lark-cli/config.json`**：

```bash
# secret 通过 stdin 注入（文件存于 ~/.agent-shared/config/，0600、禁 Git）
lark-cli config init --app-id <app_id> --brand feishu --name parva \
  --app-secret-stdin < ~/.agent-shared/config/feishu-app-secret-parva.txt

# Agent 场景分步授权：先拿链接并展示二维码，人类确认后再续轮询
lark-cli --profile parva auth login --no-wait --json --scope "bitable:app drive:drive docx:document docs:document:import base:app:create base:table:read base:table:create base:table:update base:table:delete base:record:retrieve base:record:create base:record:update base:record:delete base:field:read"
lark-cli auth qrcode "<verification_url>" --output qr.png
lark-cli --profile parva auth login --device-code "<code>"
```

- 新增 scope 须先在开发者后台开通并**发布版本**，再重新 device flow。
- 始终传 `--profile parva` 与 `--as user`（缺省落到旧租户会报 `21001`）。

## 3. Command Reference

| 场景 | 命令（统一加 `lark-cli --profile parva`） |
|---|---|
| 读索引表 | `base +record-list --base-token <bt> --table-id <tid> --as user` |
| 批量写索引 | `base +record-batch-create --base-token <bt> --table-id <tid> --json @batch.json --as user` |
| 建/改字段 | `base +field-create --base-token <bt> --table-id <tid> --json @fields.json --as user` |
| 列目录（复用 token 防重名） | `drive files list --folder-token <ft>` |
| 建子目录 | `drive +create-folder --name <name> --folder-token <ft>` |
| 导入 `.md` 为在线 `docx` | `drive +import --file <rel.md> --type docx --folder-token <ft>` |
| 上传原格式（>20MB 自动分片） | `drive +upload --file <rel> --folder-token <ft>` |
| 下载原格式副本（`type=file`） | `drive +download --file-token <t> --output <out> --overwrite` |
| 回读 `docx` 正文（只读参考） | `docs +fetch --doc <t> --doc-format markdown --scope full\|outline` |
| 移动副本 | `drive +move --file-token <t> --type file --folder-token <target>` |
| 搜索云文档 | `drive +search --doc-types bitable\|docx\|sheet` |

## 4. Full Preview Publish Workflow (Reproducible)

1. **必须先 `cd ~/.agent-docs`**：CLI 对 `--file` 有内置路径白名单，传绝对路径会报 `unsafe file path ... outside the built-in allowlist`，**必须用相对路径且正斜杠**（如 `技术资料/261112｜文档｜xxx.md`）。
2. **复用目录 token**：先 `drive files list` 查同名子目录，存在即复用，不存在才 `+create-folder`（盲建会生成重复同名目录）。
3. **按格式分流**：`.md` 一律 `+import --type docx`（约 8s/个）；`html/jpg/txt/pdf/office` 等可预览原格式用 `+upload`（<2s/个）；命中 `secret-exclude.txt` 或不可在线阅读脚本默认跳过。
4. **断点续传**：记录 `相对路径 -> {token, kind}` 至会话临时 `done.json`，单文件失败不中断整批，汇总报告人类。
5. **分批写索引**：每 20 条一批 `base +record-batch-create --json @batch.json`；`channel` 填 `["cli"]`，`backend_ref` 记 `feishu:<token>;type=<docx|file>`。
6. **事后三检**：核对目录数一致；抽检 1–2 个 `type=file` `+download` 校验 `sha256`；抽检 1–2 个 `docx` 用 `docs +fetch --scope outline` 核对非空壳。

## 5. Known Pitfalls & Red Lines

- **`+push/+pull/+status` 只处理 `type=file`**，会跳过在线 `docx`；勿用 `+push` 代替 `.md` 导入（传成原始 file 线上不可预览）。
- **无 `+record-create`**：统一用 `+record-batch-create` 或 `+record-upsert`。
- **字段格式**：`datetime` 必须写 **13 位毫秒时间戳**；单选/多选字段一律用**数组**（如 `"后端":["feishu"]`、`"status":["active"]`）。
- **`--jq` 不支持 ndjson**：需直接解析 CLI 落盘的 `*.ndjson` / `*.manifest.json`。
- **高危写禁止自动执行**：`drive +delete`、`+push --delete-remote`、`base +record-delete`（仅单条 `--record-id`）严禁自动执行，删除一律走 `K4` 墓碑。
- `app_secret` 一旦在对话/日志中明文出现即视为泄露，须立即在后台重置并更新本机 `config/` 与 `keys-checklist.md`。
