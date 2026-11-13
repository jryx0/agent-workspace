# 2026-11-13 zhn-docs-kb 裁决落地 v0.8.0 交接

- **设备**：zhn-tbxg2iah-win（简标 `x`／OS 段 `w`）
- **执行者**：workbuddy（`~zhn-x-w`，已登记已启用）
- **时间**：2026-11-13 16:5x UTC+8
- **依据**：人类 16:05／16:15／16:25 三批裁决 + 16:51「按建议落地」指令；`docs://技术资料/261112｜文档｜飞书百度网盘混合存储方案审核.md` 第十二节
- **档位**：T2 协作档（写共享仓 + git sync），写前已出第八节 10 步自检简报

## 一、本轮做了什么

把 `zhn-docs-kb` 从 v0.7.0 升到 **v0.8.0**，一次性落地三批裁决与 16:25 的全部建议。

| 文件 | 动作 |
|---|---|
| `skills/official-doc/zhn-docs-kb/SKILL.md` | 升 v0.8.0；0/1/2/4/4.2/5/6/7/8.7/9/12/13/14/16 节改写或重写 |
| `skills/official-doc/zhn-docs-kb/INSTALL-PROMPT.md` | 同步 v0.8.0 口径（拉取式、墓碑、不主动同步、WSL 本期不启用）；验收清单加第 6 条并注明未实测 |
| `skills/official-doc/zhn-docs-kb/secret-exclude.txt` | **新建**：secret / 批量上传排除清单（只列模式，不含密钥值） |
| `~/.agent-docs/技术资料/261112｜文档｜飞书百度网盘混合存储方案审核.md` | 追加第十二节「2026-11-13 人类裁决落地」，不改上文历史内容 |
| `memory/org.md` | append-only 追加本轮留痕 |
| `memory/devices/_devices.md` | append-only **追加更正注释行**（不改表格第 10 行原文） |
| `~/.workbuddy/skills/zhn-docs-kb/` | 用 `env/install-skill.sh zhn-docs-kb` 重装平台副本（原 `--check` 报「过期」），重装后 `--check` 应为「最新」 |

**核心口径**：飞书＝只读预览副本 + 飞书多维表格（唯一权威索引）；变更均由人类指令触发、均有效；同步＝**写后登记元数据 + 读前查表按需拉取**，不主动同步、不广播、不建常驻机制；删除＝本地标记（tombstone + `.trash/`，云侧删除交人类 UI）；原件＝本地 `~/.agent-docs`，云端永不作原件；网盘＝仅对外交付，冷备由 NAS 独占；WSL 通道选 ③ 暂不启用；密级四级沿用、未标注按 internal、分享默认关闭。

## 二、规范边界（重要）

- **未改** `global/` 下任何规范正文（`rules.md`、`global/spec/*.md`），未升规范版本，最小红线④未触碰。
- **受控例外登记**：`global/spec/layout.md` 二-3 仍写 `~/.agent-docs`「由第三方同步工具处理、确保多设备实时一致」「全部接入设备必须使用同一个同步工具」，与本期「原件本地 + 拉取式不主动同步」有字面差异。本期按人类裁决执行，**飞书为唯一同步载体**（多维表格查表 + 云空间按需下载），`~/.agent-docs` 不启用实时同步工具，冷备走 NAS 自带云同步工具。**分卷措辞修订须人类单独批准**，本交接与 `org.md` 留痕即为受控例外登记。
- `rules.md` 二-1 目录树补登 `env/install-skill.sh` 与 `skills/` 安装约定**同样须人类单独批准**，本轮以技能第 15 节、`INSTALL-PROMPT.md`、本交接与 `org.md` 留痕替代，未改目录树。
- **WSL 冲突已消解（核对新发现）**：`rules.md` v2.6 变更记录 B2 已把条文改为「工作区不进 WSL；WSL 内运行 agent 须人类登记、OS 段 `wl`」，现行 `spec/toolchain.md` 四-1 §1 只禁止在 WSL 内建立第二份 `~/.agent-shared`/`~/.agent-tools`/`~/.agent-docs`/`~/source`——与技能 8.7 边界一致，v0.5.0/v0.6.0 记录的「规范明令不使用 WSL」是历史状态。本轮选 ③ 暂不启用，因此不登记 `wl` 账号、不安装 bdpan Skill、不扫码、不做 WSL 冒烟；`wsl.exe` 沙箱黑名单仍生效。

## 三、挂起任务（当前全量快照 · 8 字段 · 继承自最新 handoff，本轮无新增无解挂）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停，合并为一次 ALTER + 一次部署 | S3 人类裁定 + 新 ADR 批准 + 重编卡面 | 无 worktree；卡面 todo | 重编卡面后重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 富士 CWIS 无单双面统计，厂家后台升级中 | 厂家升级完成 + 复跑三台探测 + 更新调研文档 | tmp 快照保留；worktree 已 remove | 续跑不重开卡 | 人类 |
| prnmgt | S3 v4 批次 / #18 | 2026-11-07 15:11 | 纸张消耗口径重编，数据可行性未定 | S2 结论 + D-5~D-10 逐条裁定 + 新 ADR | 仅 DRAFT，未写卡面 | 裁定后重编拆卡再认领 | 人类 |

**全局项目无挂起项。** 本轮为人类当次直接指令落地，**不认领任务卡、不新建 RL 卡**；上述 suspended 项一律未认领未开工。RL-004～RL-007 已完成并通过审核，RL-007 集合一试运行与 B 档批准仍未完成，不属挂起项。

## 四、自检与并发保护

- 规范 v2.7；`tools-scan.sh --check` ✅（stamp 11-08 20:26，未满 30 天）；`proxy-check.sh` ✅（无全局 http.proxy、10808 可连、写前 local=origin=backup=`d89b95b`）；推送前重跑。
- `memory/.compact-lock` 不存在；`config/` 5 项齐、ACL 仅当前用户 + SYSTEM + Administrators；`~/.agent-docs` 可达、无冲突/同步残留文件；本会话不需要共享 MCP 9101（offline 沿用已知，不阻塞）；不使用 Python venv、不装依赖、不涉及 `~/source/` 项目。
- **并发保护**：他人未提交的两处改动 `handoff/2026-11-13-多设备多Agent协同评估后续任务卡-zhn-tbxg2iah-win.md`、`memory/projects/prnmgt.md` 全程未触碰、未代提交、未强 rebase；`git pull --rebase` 因该未提交改动跳过（本地与双远端 HEAD 一致，无需同步）；commit 只显式 `git add` 本轮自己产出的路径，禁止 `git add -A`。

## 五、遗留与下一步（归人类）

1. **凭证与授权**：飞书自建应用 `app_id/app_secret` + 最小 scope + 发布版本；百度网盘 Access Token 与授权目录范围；`~/.workbuddy/mcp.json` 写入后由人类点「信任」；每台设备 + 每个 agent 软件单独分发，禁止跨设备复制同一 token（三-8⑥⑦）。
2. **能力前置 B3**：只读取证飞书 MCP 是否暴露「读多维表格 + 下载文件」；缺则走官方 API/CLI，不引入 WSL。
3. **待人类指定**：对外交付根路径（建议 `/apps/bdpan/delivery/`）；`secret-exclude.txt` 逐条确认；`.trash/` 保留天数（建议 30 天）；飞书副本清理策略。
4. **实测**：审核报告第六节 9 项仍全部「待测」；Step 0b 环境与 Step 1～5 仍暂缓；`INSTALL-PROMPT.md` 验收 6 条尚未在其他设备/账号实测；对外分享链接是否免登录可读待冒烟。
5. **规范类**：`spec/layout.md` 二-3 措辞修订、`rules.md` 二-1 目录树补登，均须人类单独批准；`_devices.md` 总表旧行的物理改写按三-2 禁止，已用追加更正行处理。
6. **部署**：本轮无部署动作；`git push` 不等于部署（用户级规则 2026-11-06）。
