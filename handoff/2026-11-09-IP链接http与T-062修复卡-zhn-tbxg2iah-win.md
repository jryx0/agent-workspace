# 2026-11-09 09:29 UTC+8 · 打印机 IP 链接改 http + T-062 修复卡

> 提交者：workbuddy @ zhn-tbxg2iah-win
> 状态：**代码已 commit + push，未部署**；人类本人部署（09:21 明确「我来部署」）。
> 本文件是**新基线的权威留痕**。`memory/projects/prnmgt.md` 末尾仍写「origin/master = 3a4ffe1」，因该文件有 trae 08:52 P0 调研认领的未提交改动，本次按规范未触碰、未代提交，请在 trae 提交后补登。

## 一、人类指令

- 09:07 三张截图指明：总览「按打印机」、采集明细、基础数据「复合机清单」三处 IP 链接仍是 https，要求全部改成 http。
- 09:21 追加：「临时小改动需要 commit 并 push，我来部署。问题起草成一个修复卡」。「问题」指 08:46–09:00 诊断的两个缺陷，合成**一张**卡。

## 二、改动与提交（prnmgt，origin = https://github.com/jryx0/prnmgt.git）

- `cfcc927` `fix: 打印机 IP 超链接统一改用 http by workbuddy@zhn-tbxg2iah-win`（4 文件 +7/-7，署名 zhn-workbuddy / `Agent: workbuddy`）
  - `worker/src/web/tabs/admin_master.js:56`、`collect.js:142/185`、`overview_cards.js:110` 共 4 处 `https://` → `http://`。
  - `worker/src/lib/web_assets.js` 由 `node scripts/build_web_assets.mjs` 重新生成（3 行）。Worker 运行时读的是这份生成物，漏重生成会导致线上仍是旧版。
  - 另 2 处 IP 链接（`overview_cards.js:131` 碳粉悬浮卡、`toner_status.js:49` 碳粉状态）本就是 http，未动；Cloudflare Turnstile（`login.js`）、Chart.js 文档链接、icons.svg xmlns 等外部 https 不动。最终生成物 `href="https://` = 0，6 处 IP 链接全为 http。
- `b0cbc7c` `docs: 新增 T-062 采集时间与只采总量设备明细修复卡（DRAFT） by workbuddy@zhn-tbxg2iah-win`（1 文件 +8）
  - `specs/0001-prnmgt-refactor/tasks.md` 追加 **T-062**，`状态: todo`，标题标注 DRAFT 待人类批准派工；**未认领、未开工、未派工**，不并入 v3 暂停卡或 v4 批次。
- **新基线：本地 master = origin/master = `b0cbc7c`**（上一基线 `3a4ffe1`），`git status` 干净（仅 3 个既有未跟踪文件）。**线上仍是旧版本，未部署。**

## 三、校验（提交前全部通过）

- `node scripts/build_web_assets.mjs --check` → 与 37 个源文件一致；`node scripts/check.mjs` → 0 问题 / 3 条存量拆卡提示（新卡解析后：任务 62 · done 58 · todo 4）。
- 全量 `node --test` → **265 / pass 174 / fail 0 / skip 91**，与收官基线一致。
- `node --check` 三个改动文件 OK；`web_size.mjs` 首屏 gzip 25.3 KB ≤ 40 KB；`git diff --check` 0；CRLF 0。
- `check_embedded.mjs` 报缺 `worker/src/query_page.js`：该文件在 HEAD 里也不存在，是重构前遗留脚本，属基线缺失，与本次改动无关。
- **已知坑 #83 处理**：本机 25 个 web 源文件被检出为 CRLF（系统级 `core.autocrlf=true`、仓库 local=false、无 `.gitattributes`），导致 `build --check` 在改动前即失败，直接重新生成会把 CRLF 写进内嵌资源造成大面积假 diff。先按 LF 规范化这 25 个文件（git 视角零内容改动），再改链接、再生成；最后 `git add -u` + `git restore --staged` 刷新索引 stat 清掉 25 个假 M。最终提交集只有 5 个文件，无换行符污染。

## 四、红线与未做

- 未部署（人类本人执行）、未执行任何 DDL / 现网 DML、未改采集端、未改 `worker/schema.sql`、未改 `lib/diff.js` 等共用原语、未认领卡片、未派工。
- 共享仓库 `~/.agent-shared` 的 `memory/projects/prnmgt.md` 有 trae 08:52 P0 调研认领的未提交改动（1 行新增），本次未触碰、未代提交；本 handoff 作为独立新文件单独 commit，并用 `env/git-sync.sh` 双远端推送。
- 项目仓库 3 个既有未跟踪文件（`.login-out.txt`、`docs/plan-2026-11-04-device-gap.md`、`tmp/`）未纳入提交。

## 五、T-062 卡要点（详见 tasks.md 卡面）

一张卡合并 08:46–09:00 诊断的两个缺陷，均为系统口径问题而非设备缺数：

1. **采集时间少 8 小时**：`schema.sql:63` 的 `collect_run.ingested_at` 默认值 `datetime('now')` 是 UTC，`ingest.js:24` 的 RUN_UPSERT 不显式写该列，故主表（`modules/collect.js:240`）与合成占位行（`collect_fill.js:34-35`）显示 12:14:32；实采明细取 `MAX(account_daily.created_at)`，由 `nowIso()` 写入东八区显示 20:14:32。
2. **7号打印机误标「无采集数据」**：PRN007 是全库唯一 `is_total_only=1`，只采整机总量落 `device_daily`，但 `collect_detail` 的 data 视图只查 `account_daily`（`modules/collect.js:82-91`），`devMap` 未取 `is_total_only`，T-045/T-046（OPEN-DECISIONS #13）的 `synthDataRows` 把「在用且无账号行」一律判 no_data。

**待人类裁定**：① 历史 UTC 存量数据的订正方式（推荐统一 `nowIso()` 写东八区 + 历史一次性 DML 由人类执行；若不动历史则展示侧需按契约兼容，避免新数据二次 +8h）；② 是否将 is_total_only 明细适配登记为 #13 口径延伸；③ 7号 / 14号主数据 IP 疑重复（`10.113.123.248`）且 14号 443 超时，需人工核对（不属本卡代码范围）。

## 六、人类部署后的自检项

1. 打开总览「按打印机」、采集明细、基础数据「复合机清单」，悬停或新开标签确认 IP 链接为 `http://`，且能直达打印机后台（80 端口）。
2. 确认 7号 / 14号等设备的 IP 链接可达；注意两台主数据 IP 疑重复。
3. **预期仍存在的问题（T-062 未修，勿误判为回归）**：采集事件时间仍显示 12:xx、7号仍显示「无采集数据」。
4. 按规范留痕：部署时间、基线提交号 `b0cbc7c`、部署者、自检结果；并确认线上版本与基线一致（`git push` 不等于部署）。

---

## 七、09:42 补记 · T-062 执行提示词已入仓，**基线更新为 `4c840bd`**

- 人类 09:34 要求「写一份提示词」。新增 `docs/collect/exec-prompt-t062.md`（自包含逐卡执行提示词，161 行），并订正 `tasks.md` T-062 卡面「计划」行指向该文件；prnmgt 单提交 **`4c840bd`** 已推 `origin/master`（上一基线 `b0cbc7c`）。门禁 `check.mjs` 0 问题（任务 62 · done 58 · todo 4）、`git diff --check` 0、CRLF 0。
- **防撞（最重要）**：提示词文件存在 ≠ 可开工。T-062 仍是 `状态: todo` + **DRAFT 待人类批准**，§三 三项裁定（历史 UTC 存量行订正方式 / 是否登记 #13 口径延伸 / 7号14号 IP 重复人工核对）**均未落定**。提示词头部与零章已明写「禁止投喂、禁止认领、禁止开工、trae 不得按推荐方案先做」，也不得并入 v3 暂停卡或 v4 批次。裁定由 workbuddy 在派工前补写进 §三 并把卡面/共享记忆改为 doing。
- 提示词内两处易漏技术点：`RUN_UPSERT` 的 `DO UPDATE` 须同步 `ingested_at`（否则同日重跑后主表与实采行时间再次错位）；`activeDeviceNos()` 为 data/status 共用，只能在 `synthDataRows` 内按 `is_total_only` 过滤，不能改公共函数。整机三量禁止冒充账号口径数值。
- 部署自检第 4 项的基线号请按实际部署时的 `origin/master` 填写；若已在 `b0cbc7c` 上部署，本文档提交不涉及任何代码变更，**无需因 `4c840bd` 重新部署**（该提交只含文档）。
- `memory/projects/prnmgt.md` 中「origin/master = 3a4ffe1」仍过时，且该文件有 trae 08:52 未提交改动，本次依旧未触碰、未代提交，待 trae 提交后补登。

---

## 八、2026-11-09 09:45 · 人类部署完成 + 线上自检 PASS + T-062 获批

**部署留痕（规范三-7：部署后立即线上自检，并在共享记忆留痕：时间 / 基线提交号 / 部署者 / 自检结果 / 线上与基线是否一致）**

- **部署者**：人类本人（09:45 告知「IP 问题已经部署」；具体时刻与 Version ID 未告知，agent 未代部署）。
- **基线提交号**：部署内容 = `cfcc927`（打印机 IP 超链接 https→http，4 文件 +7/-7）；其后 `b0cbc7c`（T-062 卡面）、`4c840bd`（执行提示词）、`7046d2b`（批准状态 + 本次留痕）**仅文档，前端代码未变**。
- **自检结果（workbuddy 09:47 只读 HTTP，PASS）**：`https://prnmgt.parva.dpdns.org` → `/` 200、`/api/config` 200、`/assets/app.js` 200；`/assets/tabs/collect.js`（13444B）、`admin_master.js`（15003B）、`overview_cards.js`（8997B）均 200 且与本地基线**逐字节一致**（归一 CRLF）；三文件 `href="http://` 共 **5** 处、`href="https://` **0** 处 → IP 链接已全部 http。网络偶发 000 已重试取样，无失败项。
- **线上版本与基线是否一致**：**一致**。线上前端资源与当前 `origin/master` = `7046d2b` 中的前端资源逐字节相同（该提交未改前端）；`git push` 与部署已分离，本次由人类完成部署并已验证。
- **预期仍存在（T-062 未修，勿判回归）**：采集事件时间仍 12:xx、7号仍显示「无采集数据」。未执行任何 DDL / 现网 DML、未连现网 D1。

**T-062 批准留痕**

- 人类 09:45 明确「T-062 已经批准」。`tasks.md` T-062 卡面、`docs/collect/exec-prompt-t062.md`、`BOARD.md` 已同步脱离 DRAFT，prnmgt 提交 **`7046d2b`** 已推 `origin/master`（上一基线 `4c840bd`）。
- **仍未解锁开工**：提示词 §三 三项裁定（① 历史 UTC 存量行订正方式 ② 是否登记 `OPEN-DECISIONS.md` #13 口径延伸 ③ 7号/14号 主数据 IP 重复与 14号 443 超时人工核对）**均未落定**。结论补写进 §三 并把卡面 / 共享记忆改 doing 前，仍**禁止投喂、认领、开工**；卡面 `状态: todo` 不变，不并入 v3 暂停卡或 v4 批次。
- 当前任务登记：trae 08:52 P0 只读真机调研 **doing**；T-059~T-061 暂停；T-062 已批准待裁定。`memory/projects/prnmgt.md` 的 trae 未提交改动本次仍未触碰、未代提交；其「origin/master = 3a4ffe1」登记待 trae 提交后补登（现为 `7046d2b`）。

---

## 九、2026-11-09 10:04 · 三项裁定落定 → T-062 解锁为唯一可认领编码卡

**人类点选裁定（已写入 `docs/collect/exec-prompt-t062.md` §三，为执行权威口径）**

1. **① A 方案（历史数据）**：`RUN_UPSERT` 显式写 `ingested_at = now`（`nowIso()` 东八区）、`DO UPDATE` 同步；历史 UTC 存量行由**人类本人**一次性 DML `+8h` 订正。agent **只交付 SQL 建议文本，不执行、不落库、不写进 migration**，代码里禁止「所有 ingested_at 一律 +8h」的无判别转换。
2. **② 不登记** `OPEN-DECISIONS.md` #13 口径延伸，**仅代码修复**；决策文档与卡面「计划」均不追加说明，收官订正不含此项。
3. **③ IP 人工核对、不阻塞开工**：7号/14号主数据 IP 疑重复与 14号 443 超时由人类人工核对；卡内不改主数据、不碰采集端。

**落地**：`tasks.md` T-062 卡面（标题/依赖/计划/背景）、`docs/collect/exec-prompt-t062.md`（标题/卡面行/投喂纪律/状态表/零章 5/§三 结论与执行口径/5.1/八节）、`BOARD.md`（阻塞项/最后更新/时间线条目）同步解锁。门禁：`check.mjs` **0 问题 3 条存量提示**（任务 62 · done 58 · todo 4）、`git diff --check` 0、CRLF 0、残留「待裁定/未落定」0 处。

**新基线 `6170708`**（上一基线 `7046d2b`）已推 `origin/master`；**仅文档提交，线上前端资源与基线仍一致，无需重新部署**。

**当前任务状态**：T-062 `状态: todo`，**唯一可认领编码卡**；认领由 trae 自行在共享记忆登记 doing（append-only），workbuddy **不代认领、不编码**。trae 另有 P0 只读真机调研 doing（08:52），投喂前请确认该调研已交付或由人类明确指定并行；T-059~T-061 仍暂停、v4 前置未过。`memory/projects/prnmgt.md` 的 trae 未提交改动本次仍未触碰、未代提交；其基线登记待 trae 提交后补登（现为 `6170708`）。
