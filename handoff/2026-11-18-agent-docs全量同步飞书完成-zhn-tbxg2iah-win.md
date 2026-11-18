# 2026-11-18 agent-docs 全量同步飞书完成（zhn-docs-kb v0.10.0）

- 执行设备：`zhn-tbxg2iah-win`
- 执行 agent：workbuddy（committer `workbuddy@zhn-tbxg2iah-win~zhn-x-w`）
- 人类指令：「agent-docs 中的文件都要同步到飞书，可以拿部分文件做测试」
- 依据：`skills/official-doc/zhn-docs-kb/SKILL.md` v0.10.0（4.5 节为本次新增的可复现流程）

## 1. 结果

| 项 | 数 | 说明 |
|---|---|---|
| 本地 `~/.agent-docs` 文件总数 | 60 | 1.7MB，无 >5MB 文件 |
| 已同步到飞书 | **40** | 33 个 `.md` → docx 在线文档；7 个 html/jpg/txt → 原格式文件 |
| 失败 | **0** | 串行执行，无限流触发 |
| 索引表记录 | **40** | 全 `active`；33 `internal` / 7 `confidential` |
| 云端目录 | 14 | 与本地逐级一致，0 缺失 |
| 未上传 | 20 | 1 个 secret + 19 个脚本/配置/二进制（待人类裁决，见 §4） |

校验三件套全部通过：
1. 逐级 `drive files list` 与本地目录对比：14/14 目录齐全；
2. 抽检 `+download` 回文件：`sync.html`、`AiDo9*.jpg` 的 sha256 与原件**逐字节一致**；
3. 抽检 docx：`docs +fetch --scope outline|full` 标题层级与正文完整，非空壳。

## 2. 坐标（已写入 SKILL 4.4）

- 索引表：`base_token=KouDbtqSyamyHtsJZuKcNvNXnee`、`table_id=tblJRefSlsHuCwJn`
- 云空间根文件夹：`OU68fE99Tlr1SidQgMCcKmCYnog`（`https://hcnr1wipkvsc.feishu.cn/drive/folder/OU68fE99Tlr1SidQgMCcKmCYnog`）
- 租户「潘恩塔 P1499QMSJ」，应用 `cli_aa77a9fe69385c13`，CLI 档案 `parva`，用户身份 张皓

## 3. 本次踩到并已入册的硬坑

1. **路径白名单**：`--file` 传绝对路径必被拒（`unsafe file path ... outside the built-in allowlist`）。必须 `cwd=~/.agent-docs` + 相对路径正斜杠。
2. **`+push` 不能替代 md 导入**：`+push/+pull/+status` 只处理 `type=file`，md 经 `+import` 后是 docx 在线文档，这三条命令会跳过 → md 只能逐文件 `+import`。
3. **docx 回取不保证 sha256**：`docs +fetch --doc-format markdown` 能取回正文，但飞书会规范化空行/列表/标题，故 `.md` 副本只作预览、只做语义校验，**禁止用它覆盖本地原件**。
4. **`+record-delete` 只收 `--record-id`**（单条），无 `--record-ids`；批量需逐条循环 + `--yes`。
5. **datetime 写入用 13 位毫秒戳**，读回自动 ISO8601+08:00；`--jq` 不支持 ndjson，需解析 CLI 落盘文件。
6. **同名目录会被重复创建**：建目录前必须 `files list` 判重并复用 token。

## 4. 待人类裁决

| # | 事项 | 建议 | 现状 |
|---|---|---|---|
| A1 | 19 个脚本/配置/二进制是否入飞书（`.sh/.py/.ps1/.conf/.yml/Dockerfile/crontab/.sha256/.tar.gz`） | 按裁决 1「仅同步可在线阅读文件」**维持不上传**；如担心其他设备缺批次附件，改用网盘 `purpose=delivery` | 未上传 |
| A2 | `.tar.gz` 服务器备份包（2.3K，含 Xray/NAS 配置） | 视为 confidential 以上，**不上飞书、不上网盘**，只留本地 | 未上传 |
| A3 | Xray 相关 7 篇文档含真实 UUID/私钥 | 已标 `confidential`、只进飞书私有租户、**不生成分享链接**；如需更严可降为 secret 并下云 | 已上传（confidential） |
| A4 | `261111｜账号｜账号信息整理.html` | secret 永久排除，不提供例外 | 已排除 |

## 5. 未做（留给下一轮）

- Step 5 负向用例 5 项：撞名、并发写、索引缺失、分享过期、secret 拦截。
- 网盘侧前置 P1~P6 仍待人类执行。
- `global/spec/layout.md` 二-3 与 `rules.md` 二-1 补登仍待人类单独批准（受控例外）。

## 6. 其他设备如何接手

```bash
cd ~/.agent-shared && git pull --rebase
bash env/install-skill.sh zhn-docs-kb && bash env/install-skill.sh zhn-docs-kb --check
# 本机 lark-cli 需各自完成 config init + device flow 授权（禁止复制 config.json）
lark-cli --profile parva base +record-list --base-token KouDbtqSyamyHtsJZuKcNvNXnee --table-id tblJRefSlsHuCwJn --as user
```
