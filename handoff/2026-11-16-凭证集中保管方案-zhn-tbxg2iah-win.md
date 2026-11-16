项目: 全局

# 交接：凭证集中保管落地方案（密码管理器选型与 zhn-docs-kb 接入）

- 日期：2026-11-16（会话 08:42 起）
- 设备/账号：zhn-tbxg2iah-win / workbuddy@zhn-tbxg2iah-win~zhn-x-w
- 状态：**方案已产出，待人类批准后实施**；本轮未改技能、未改规范、未动任何凭证内容。

## 一、任务与产出

- 人类指令：密码/凭证/密钥太多且分散，担心丢失；研究在 doc 中怎么保存、怎样加入 zhn-docs-kb。
- 产出：`docs://技术资料/261116｜文档｜凭证集中保管落地方案（密码管理器选型与zhn-docs-kb接入）.md`，含：
  - 现状盘点：5 类资产分散、零第二份、零加密容器；SSH 私钥母本+副本同机为最高风险（盘坏=VPS 失联）；`261111｜账号｜账号信息整理.html` 明文单点。
  - 选型对比（2026-11-16 六源检索）：KeePassXC / Bitwarden云 / Bitwarden自托管 / Vaultwarden / Passbolt / Proton Pass；**推荐 KeePassXC**（零服务器、文件即 vault、SSH Agent 内建、ANSSI 认证、与「原件 agent-docs + 副本冷备」分层零冲突）；Vaultwarden（NAS docker）留作日后升级路径。
  - 目标架构：`docs://密钥/credentials-vault.kdbx`（值唯一权威，secret-encrypted）+ `docs://密钥/密码台账.md`（不含值，internal，Agent 可检索）+ keys-checklist.md 加「权威母本」列 + 主密码纸质应急卡。
  - zhn-docs-kb v0.9.0 接入草案：分流表首位新增凭证类模式（kdbx/key/ppk/pem/密码/账号/凭证/credential/secret 默认 secret；kdbx 例外可进冷备）、secret-exclude.txt 增补、索引补 `credential_type`/`vault_only`、新增 9.5 凭证类文件保管小节。
  - 实施步骤 0–9（◆ 人类亲手项：建库、录入、私钥附件入 vault、跨设备验收）。

## 二、人类决策记录（2026-11-16 08:42）

① 管理器选开源并要求先对比优缺点；② kdbx 密文允许进网盘冷备；③ 旧明文账号文件需「方便管理和查询」方式（方案：人查 vault、Agent 查台账）；④ 本轮只出落地方案，不实施。

## 三、挂起任务（全量快照，继承自 2026-11-13 v0.8.0 handoff，本轮无新增无解挂）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；卡面 todo | 重编后重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级中 | 升级完成 + 复跑探测 + 更新调研文档 | tmp 快照保留 | 续跑不重开卡 | 人类 |
| prnmgt | S3 v4 批次 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 裁定 + 新 ADR | 仅 DRAFT | 裁定后重编拆卡 | 人类 |

本轮为人类直接指令研究，不认领任务卡；suspended 一律未开工。RL-004～007 状态不变。

## 四、自检与异常

- 规范 **v2.7**（章节分流已读：`spec/secrets.md`、`spec/accounts.md`、`spec/layout.md`、`spec/backup.md` 全文）；`tools-scan.sh --check` ✅（stamp 11-08）。
- **`proxy-check.sh` 异常**：GitHub 代理端口 127.0.0.1:10808 不可达（v2rayN 疑未启动），backup 远端不可达；本地 HEAD `d29b6cd` 领先 origin 1 个提交。**本轮共享仓改动只本地 commit，不推送**；待人类启动代理后执行 `git sync` 补推。
- 他人未提交改动 2 处（`handoff/2026-11-13-多设备多Agent协同评估后续任务卡-….md`、`memory/projects/prnmgt.md`）全程未触碰。
- `config/` 6 项仅核对存在性（3 对 SSH 密钥 + feishu-app-secret.txt + printer_ubuntu）；未读任何内容。无 `.compact-lock`。不装依赖、不需要 MCP 9101。

## 五、下一步（待人类）

1. **审批方案**：确认 KeePassXC 选型与第六节 v0.9.0 接入草案（或改选 Vaultwarden/其他）。
2. 批准后按方案第七节阶段 0–9 实施（◆ 项需你亲手）。
3. 启动 v2rayN 后跑 `bash ~/.agent-shared/env/git-sync.sh`（或通知 agent 代跑），把 d29b6cd 与本轮提交一起推双远端。
4. 遗留旧项不变：飞书 app_id/app_secret、网盘 Access Token（见 11-13 handoff 第五节）——建库时一并录入 vault 即可闭环。
