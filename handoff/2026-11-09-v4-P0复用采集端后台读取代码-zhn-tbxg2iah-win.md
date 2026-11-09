# 2026-11-09 10:0x UTC+8 · v4 P0「复用采集端既有后台读取代码」核实与增量提示词

> 提交者：workbuddy @ zhn-tbxg2iah-win
> 状态：**只读研究 + 文档固化完成；未认领、未编码、未部署、未执行 DDL**。
> 防撞说明：`memory/projects/prnmgt.md` 有 trae 08:52 P0 调研认领的未提交改动，本次按规范三-5 ⑥⑦ **未触碰、未代提交、未 rebase**；本文件作为独立 handoff 单独 commit。主仓与共享仓在 09:38~10:07 期间有多个 workbuddy 会话并行推进（T-062 三项裁定、部署自检），已逐次 `git fetch` 核验基线后再提交。

## 一、人类指令

09:49「这个采集端有完整的读取打印机后台的代码，可以重复利用这个代码，开展调研」。承接 11-07 v4 纸张消耗口径方案的 P0 只读真机调研（人类 D-1 裁定）。

## 二、只读核实：判断成立

`collector/printer_monitor/` 确有成套「读取打印机后台」通用能力，且与业务落库分层；**`status_collector.py:66-75` 就是「不重写登录、import 两品牌内部函数做另一类只读采集」的现成范例**（只读状态采集）。

| 品牌 | 可直接 import 的符号 | 登录态 |
|---|---|---|
| 富士 | `util.make_session` `util.py:105`、`fuji._UA` `:85`、`_XHR_HEADERS` `:77`、`_login` `:170`、`_post_retry` `:151` | `POST /LOGIN.cmd` → `ssid` cookie |
| 京瓷 | `kyocera._make_device_session` `:216-223`（`curl_cffi impersonate="chrome"`，TLS/HTTP2 指纹门禁，requests 不可用）、`_login` `:260`、`_get_retry` `:237`、`parse_js_arrays` `:138` | `cert_id + ID1` cookie |
| 凭据/清单 | `config.load_config` `config.py:44`、`collector.select_active_devices` `:50`、`sync.pull_master` `:73` | 只列路径，不输出值 |

**最小复用 = 换 URL / 维度参数 / 解析器，无需重写登录、零改仓库代码**；一次性只读脚本放 `~/.agent-shared/tmp/<agent名>/<会话标识>/`（三-3 / 三-5 ⑦），不入 Git。

两个关键发现：

1. **京瓷最短路径**：`GLOBAL_PRN_FRAME_URL` / `GLOBAL_PRN_MODEL_URL`（`kyocera.py:66-70`）**本就在抓**，但 URL 无维度参数、`_collect_global()` `:325` 只用 `parse_js_scalars` 取默认「功能」维度。`docs/legacy-docs/PRD.md:10` 记载该页下拉 `value=1/2/3` = 功能 / 纸张尺寸 / 版面 → 同一 session 依次请求三维度 + 改用 `parse_js_arrays`，即可判定**整机级**纸型 / 版面是否可得（P0 Q6）。先框架页后 model（`:437-438`）。
2. **富士真机前端证据强于联网 KB**：`fuji.py` 全文对 `CWIS|Properties|Usage Counters|duplex|sheets|impressions` 零命中，只抓 `home/api/billing-counter`（`:70,197`）。trae 的 `tmp/trae/field-survey/fuji-home_min.js` / `fuji-config.js` 已含 `LargeSizeUsageCounter`、`UsageCounterType`、`TotalImpressions`、`this.send("/home/api/billing-counter","GET",...)`、`DVM_BILLING_LARGESIZE_IMPRESSION_METER_SUPPORT`、`COUNTER_SHEETS_PRINTING_MEDIUM_SIZE_A4SEF_SUPPORT` → 从 JS 定位真实接口 / 字段，不必猜 CWIS 路径。

**安全红线（新增）**：`tmp/trae/field-survey/fuji-wui-common.js` 含 `PMLib.AAAUser.ClearAllUsageCounter`（11 处）等**清除计数器写操作**；京瓷 `ResetCnt.htm` 在 `kyocera.py:41` 标注「采集流程绝不可请求」。只读调研绝不可触发，不得改配置 / 复位 / 打印测试页。

## 三、离线实证（无需连真机）

只读解析 `tools/tests/fixtures/golden/db.json`（未写文件）：`account_daily` 498 行、**100 行**含 `paperSizeCounter`；`duplexCounter[0]+[1]==[2]` **100/100**、`combineCounter` 三项和 == 合计 **100/100**；但纸型六项和 / 合计覆盖率 min **0.448** / 中位 **0.560** / max 1.000，仅 **4/100** 行达 100% → **量化证明账号级纸型计数不能代表整机**，Q3 必须给「仅账号级、不可用」的二值结论。设备侧 `counter_json` 与账号级 `raw_json` 是两套数据，方案 §1.1 原表述与本节不矛盾，已在 §1.5 说明。

## 四、落地（主仓 `1c57149`，4 文件 +145/-7，已推 origin/master）

- `docs/plan-2026-11-07-paper-sizing-duplex.md`：新增 §1.5（复用清单 / 最短路径 / 离线实证 / 安全红线 / 边界），修订 §1.1 counter_json 表述、§2.2 执行方式、§3 分支 A 规模修正、§6 P3、§9 来源（补 3 条）。
- `docs/paper/field-survey-prompt-2026-11-07.md`：头部补修订说明；边界加 A1（可 import + 临时脚本路径）/ A2（写操作禁令）/ A3（复用≠解冻）；已知事实补复用清单、京瓷最短路径、富士快照证据、离线实证；Q5 / Q6 改为指向具体复用动作；交付物加「复用路径与证据」节。
- **新增** `docs/paper/field-survey-reuse-addendum-2026-11-09.md`：给已认领 doing 的执行者**一键复制投喂**的增量提示词（可照抄的复用代码、京瓷三维度路径、离线证据、写操作禁令、验收命令）。
- `BOARD.md`：更新「最后更新」，新增 09:5x 交接条目（未改并行会话写入的 T-062 裁定内容，diff 已核验无回退）。

**门禁**：`check.mjs` **0 问题 / 3 条存量提示**（任务 62 · done 58 · todo 4）、全量 `node --test` **265 / pass 174 / fail 0 / skip 91**、`git diff --check` 0、4 份文档 CRLF 0、两份提示词代码块边界（四反引号外层 + 三反引号内层）正确。

## 五、认领与防撞

- P0 只读真机调研由 **trae 08:52 认领 `doing`**；交付文档 `docs/paper/field-survey-2026-11-07.md` **尚未产出**，`tmp/trae/field-survey/` 已有 7 份真机页面 / JS 快照。本会话**不认领、不触碰其交付文件、不移动 / 删除其快照、不改 tasks.md 卡面**。
- 当前**唯一可认领编码卡 = T-062**（10:04 三项裁定落定后解锁，与本次 v4 无关）；v3 三卡 T-059~T-061 仍暂停。`origin/master` 本轮从 `6170708` → **`1c57149`**；线上前端资源仍与 `4c840bd` 一致，仅文档提交，**无需部署**。

## 六、红线与未做

- **复用 ≠ 解冻**：把新页面写进 `fuji.py` / `kyocera.py`、加上报字段、改 D1 仍触犯 `constitution.md:61,95`、`AGENTS.md:48`、`spec.md:35`、ADR-0005；分支 A 仍需人类书面新 ADR + 修订章程冻结条款。复用只把规模从「另起采集器」降为「新增抓取目标 + 解析 + 上报字段」。
- `OPEN-DECISIONS.md` #18 与方案 §8 的 D-5~D-10 仍待 P0 结论后由人类裁定；现网一次性 DDL 与全部部署仍由人类本人执行（v1.8.8 三-7 / #16 / #17）；现网 `paper_purchases` 已有存量，**不得重复执行建表 DDL**。
- 本轮**零业务代码改动、未改采集端、未改卡面、未认领、未派工、未部署、未执行 DDL / DML、未连真机、未输出任何凭据值**。未安装任何工具/依赖（`tools-scan.sh --check` 通过）；推送前 `proxy-check.sh` 通过。

## 七、下一步

1. 把 `docs/paper/field-survey-reuse-addendum-2026-11-09.md` 的一键复制提示词**转给正在做 P0 的 trae**（或人类本人），让它按复用路径补齐 Q1~Q7；不要另起会话重复认领。
2. P0 交付文档回来后，由 workbuddy 依据主方案 §3 判定分支 A / B，把 #18 与 D-5~D-10 一并提交人类裁定，**之后才落 tasks.md 卡面与逐卡编码提示词**。
3. T-062 若已被 trae 认领，按 `docs/collect/exec-prompt-t062.md` 走复审收官，勿与 v4 合并处理。
