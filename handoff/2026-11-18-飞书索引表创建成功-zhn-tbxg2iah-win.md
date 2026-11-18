# 飞书「agent-docs 索引」多维表格创建成功（新租户落地）

- **时间**：2026-11-18 11:20 UTC+8
- **设备**：`zhn-tbxg2iah-win`
- **执行**：workbuddy@zhn-tbxg2iah-win~zhn-x-w
- **关联**：`skills/official-doc/zhn-docs-kb/SKILL.md` v0.8.0（第 4 节字段清单、第 7 节拉取式同步）
- **规范**：v2.7

## 一、为什么换了租户（根因结论）

原应用 `cli_aa7c6788007a9bb4`（`zhnn资料库`）建在**豆包账号**身份下，调用多维表格 API 恒返回 `21001 blocked by data security policy`。已逐项排除：scope 收缩至单项 `bitable:app` 仍失败、应用发版 v1.0.1 后仍失败、`bot` 与 `user` 双身份均失败。

上游证据：`larksuite/cli` GitHub issue **#2815**（豆包账号 Base OAuth 被拒，open，25 条评论、9 人复现）与 **#2902**（豆包账号无法授予多维表格权限，open）。2026-10-13 起批量出现，官方无公告。

**结论**：这是豆包账号租户的平台侧账号策略问题，与 CLI、scope、发版、代理均无关；个人侧无法绕过，唯一出路是换到「自己就是超级管理员」的企业租户。

## 二、新租户与新应用

| 项 | 值 |
|---|---|
| 企业 | 潘恩塔（Parva），企业编号 `P1499QMSJ`，成员 1 人、超级管理员 1 人＝人类本人；**企业未认证** |
| 管理后台 | `https://scnxfgxy8mjx.feishu.cn/admin/index` |
| App ID | `cli_aa77a9fe69385c13`（应用名 `agent-docs`） |
| CLI 档案 | `lark-cli --profile parva`（`~/.lark-cli/config.json` 内命名档案，旧豆包档案保留未动） |
| 版本 | 1.0.1（已发布；1.0.1 补开 `base:*` 细粒度权限） |
| 用户身份 | 张皓 `ou_b051f3bfce5d7280bb599a2853572030` |
| 凭证文件 | `~/.agent-shared/config/feishu-app-id-parva.txt`、`feishu-app-secret-parva.txt`（0600，禁 Git） |

已授权 scope（14 项）：
`bitable:app`、`drive:drive`、`docx:document`、`docs:document:import`、`base:app:create`、`base:table:read/create/update/delete`、`base:record:retrieve/create/update/delete`、`base:field:read`

## 三、索引表坐标（本条最重要）

| 项 | 值 |
|---|---|
| base_token | `KouDbtqSyamyHtsJZuKcNvNXnee` |
| table_id | `tblJRefSlsHuCwJn` |
| 表名 | `索引主表`（Base 名 `agent-docs 索引`） |
| 链接 | `https://hcnr1wipkvsc.feishu.cn/base/KouDbtqSyamyHtsJZuKcNvNXnee` |
| 时区 | `Asia/Shanghai` |
| 字段 | **33 列**（`doc_id` 为第一列主字段） |

字段分组（与 SKILL.md 第 4 节一致）：
- A 标识：`doc_id`(主) `文件名` `yymmdd` `类型段` `主题` `批次目录` `相对路径`
- B 位置：`后端`(单选 docs/feishu/pan/nas) `后端路径或 file_id` `channel`(单选 mcp/skill) `channel_version`
- C 内容：`size`(数字) `sha256` `mime` `copy_of`
- D 密级状态：`密级`(单选 public/internal/confidential/secret) `status`(单选 active/pending/pending_orphan/missing/deleted) `share_state` `purpose`(单选 delivery/preview/index)
- E 来源时间：`origin_device` `origin_agent` `updated_by` `created_at`(日期) `updated_at`(日期) `tags`(多选)
- F 版本戳：`version_sha256` `origin_updated_at`(日期) `backend_ref`
- G 墓碑：`deleted_at`(日期) `deleted_by` `deleted_origin_device` `deleted_sha256` `指令批次`

## 四、已完成的验证

1. `+base-create --as user` 建表成功，返回 base_token / table_id / url。
2. `+field-create --json @file` 一次建 32 字段，`total=32`，`+field-list` 复核 **33 列**，类型分布 text 22 / select 6 / datetime 4 / number 1。
3. 冒烟写读：`+record-batch-create` 写 1 条（`doc_id=smoke-test-0001`，含单选 `后端/密级/status/purpose` 与数字 `size`）→ `+record-list` 读回正确，且 **`doc_id` 位于返回数组第 0 列**，确认主字段正确 → `+record-delete --yes` 删除，表内记录数归零。

## 五、命令备忘（后续写读索引直接照用）

```bash
# 读表（列式返回：data.data 为行数组，配合 field_id_list 定位列）
lark-cli --profile parva base +record-list --base-token KouDbtqSyamyHtsJZuKcNvNXnee --table-id tblJRefSlsHuCwJn --as user

# 写记录（单选/多选用数组，如 "后端":["feishu"]）
lark-cli --profile parva base +record-batch-create --base-token ... --table-id ... --json '{"create_records":[...]}' --as user

# 建字段（数组，支持 @file，避免命令行转义）
lark-cli --profile parva base +field-create --base-token ... --table-id ... --json @fields.json --as user
```

注意：`+record-create` 不存在，写入用 `+record-batch-create` 或 `+record-upsert`；删除记录属 high-risk-write，须 `--yes`。

## 六、遗留与待人类

1. **App Secret 轮换**：`Ql4…` 曾在对话中明文出现，建议建表后到开发者后台重置，并只更新本机 `config/feishu-app-secret-parva.txt`；改后 `lark-cli config init --name parva --app-id ... --app-secret-stdin` 重新绑定。
2. **企业未认证**：自建应用与多维表格 API 目前可用；若后续遇到能力限制，再考虑实名认证。
3. **应用可用范围**：当前授权成功，说明账号在可用范围内；若新增设备/账号需授权，先确认「版本管理与发布 → 可用范围」含全体成员。
4. **索引表尚未接入技能逻辑**：`SKILL.md` v0.8.0 第 4 节的坐标仍是占位，需升 **v0.9.0** 写入 `base_token` / `table_id` / `profile=parva`，并把「读前查表 → 按需下载 → sha256 校验」跑通（Step 3/4/5 冒烟仍未做）。
   - **已于 2026-11-18 11:30 完成前一半**：`SKILL.md` 升 **v0.9.0**，坐标与命令写入 4.4 与新增 8A 节；Step 3/4/5 冒烟仍未做（见第八节）。
5. **删除语义**：v0.8.0 定为「本地标记 tombstone + 云端不物理删」，本次未建墓碑实测数据；`status=deleted` 枚举已就位。

## 七、T2 自检与边界

- 规范 v2.7；`tools-scan.sh --check` ✅（stamp 11-08）；`proxy-check.sh` 写前 ✅，写前 local=origin=backup=`19df53d`。
- 未装依赖、未改 `global/` 正文、未写 `mcp.json`（飞书走 CLI 不走 MCP）、未部署。
- 他人未提交改动（任务卡 handoff、`memory/projects/prnmgt.md`、`zhn-work-summary/SKILL.md`、两份 11-17 handoff）全程未触碰、未代提交、未强 rebase。

## 八、v0.9.0 升版（11:30 完成）

- **App Secret 已由人类重置**（11:27 写入 `config/feishu-app-secret-parva.txt`，32 字节）；`lark-cli config init --name parva` 重新绑定后 **用户登录态未丢失**（`tokenStatus=valid`），并以 `base +base-get --as bot` 实测新 secret 可正常换发 token。
- **`SKILL.md` v0.8.0 → v0.9.0**（532 行，原 432）：新增 **8A 节「飞书通道：官方 CLI」**（8A.1 非全局安装与校验、8A.2 绑定与 device flow 授权、8A.3 能力映射表、8A.4 红线与已知坑）；新增 **4.4 节「索引表坐标与访问方式」**（坐标表 + 三条命令 + 三处坑位）；0 节加裁决 9（豆包租户 21001 → 新租户 + CLI 定案）；1 节补坐标与「飞书一律走 CLI」；4.2 取回改 `drive +download`／`+pull`；7.7 改为「B3 已闭合」；12 节新增租户/坐标/CLI 三行并把 B3 行改为已闭合；13 节增三条禁止（禁全局安装、禁自动 `drive +delete`、禁复制 `config.json`、禁改回 MCP）；16 节加 v0.9.0 条目；description 与 metadata.scope 同步。
- `INSTALL-PROMPT.md` 验收第 6 条口径更新（CLI 已补齐能力、新设备须自行授权）。
- 平台副本已重装：`install-skill.sh zhn-docs-kb` → `[OK] zhn-docs-kb → .workbuddy/skills/`（树哈希 `985fac63b7c5…`），`--check` 三个技能全部「最新」。
- **仍未做**：Step 3（真实文档登记索引）、Step 4（分流与真实上传预览副本）、Step 5（端到端 + 5 个负向用例）冒烟。
