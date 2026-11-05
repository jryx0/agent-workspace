# 2026-11-05 T-047 采集明细删失败清单+合成行补时分秒 · zhn-tbxg2iah-win（trae）

- 分支：`agent/trae/collect-detail-polish`（worktree `~/source/prnmgt.wt/trae`，基于 master e0807b9）
- 提交：**`b16898e`**（单提交——synthDataRows 签名与单测强耦合，拆开中间态测试必挂）
- 已推 `origin/agent/trae/collect-detail-polish`；未合 master、未部署生产。

## 改动（5 文件，+29/-35）

| 文件 | 改动 |
|---|---|
| [collect.js](file:///C:/Users/Zhn_X/source/prnmgt.wt/trae/worker/src/modules/collect.js) | runs 查询加 `ingested_at` 列；构建 `runAtMap`（与 failByDateDev 同循环 `runAtMap.set(rr.collect_date, rr.ingested_at)`）；`synthDataRows(runDates→runAtMap, ...)`；`failures` 字段保留未动 |
| [collect_fill.js](file:///C:/Users/Zhn_X/source/prnmgt.wt/trae/worker/src/lib/collect_fill.js) | synthDataRows 签名 runDates→runAtMap；`for (const [dt, at] of runAtMap)`；`collected_at: at \|\| null`；其余 4 函数未动 |
| [tabs/collect.js](file:///C:/Users/Zhn_X/source/prnmgt.wt/trae/worker/src/web/tabs/collect.js) | 删「采集失败」独立表渲染段（-16 行）；文件头注释同步（删「+ 采集失败清单」、补 T-047 留痕）；8 列结构与 error-line 样式未动；`d.failures` 全文件 0 引用残留 |
| web_assets.js | build 生成（35 资源 534138 字节） |
| collect_fill.test.mjs | 4 处调用点改 Map 入参；★红线用例 collected_at 断言改 `=== ingested_at`；新增 1 例 ingested_at 缺失回落 null；null 不落 0 逐字段断言原样 |

## 准出原始输出

### 1. 单测 `node --test tools/tests/unit/collect_fill.test.mjs`

```
1..10
# tests 10
# pass 10
# fail 0
# skipped 0
```

### 2. 全量回归

```
1..192
# tests 192
# pass 104
# fail 0
# skipped 88
```

（88 skip = 缺 legacy-all.json 镜像基线，与 T-045/T-046 基线一致）

### 3. check.mjs / build --check / web_size

```
通过：0 个问题，2 个提示   （T-034/T-040 存量拆卡提示）
web_assets.js 与 35 个源文件一致
通过：首屏 gzip 19.8 KB ≤ 40.0 KB
```

### 4. harness 冒烟（§6.4，临时脚本 %TEMP%\t047-smoke.mjs，最小内存库：2 台在用设备 + 1 条带 ingested_at 的 collect_run + failed_json）

```
PASS failures 字段保留且含 1 条
PASS failures[0].error = 设备离线
PASS 合成行存在（PRN002）
PASS 合成行 collected_at = ingested_at
PASS 合成行 error 取 failed_json 文案
PASS 合成行数值 null 不落 0
PASS 真实行 PRN001 未受影响
```

## 过程坑（新增一条）

- **CRLF 二次踩坑（比 T-046 更隐蔽）**：首次 build 直接把 CRLF 源文件内容嵌进生成物字符串（web_assets.js 内 `\r\n` 转义 6618 处，HEAD 为 0），`git diff --ignore-cr-at-eol` 消不掉（差异在字符串内容里不在行尾）。对策：先把 `worker/src/web/**` 磁盘内容归一化 LF（node 脚本，35 文件），再重跑 build → 生成物 `\r\n` 归零、真实差异只剩 tabs/collect.js 一行。**建议补进 AGENTS.md 坑表：build 前必须保证 web 源文件磁盘为 LF，否则生成物内嵌 CRLF 且 --ignore-cr-at-eol 无法识别。**
- worktree add 报分支已存在：`agent/trae/collect-detail-polish` 残留（指向 e0807b9 正确），改用 `git worktree add <path> <分支>` 挂上。
- 本机 PATH 中 node 24.14.0 目录已不存在，实际用 `~/.workbuddy/binaries/node/versions/22.22.2-6/node.exe`。
- 回收站进程本次更凶：连主仓库 `.git/config` 都被移走过一次（push 已成功，但后续在主仓库的 git 操作可能报无 remote）——**务必提醒人类排查**。

## 待办（非我做）

- workbuddy 审核 §7 清单（diff 仅 5 文件、failures 字段在、合成行行序不变、grep failures tabs/collect.js 仅注释、合并+收官+清 worktree）；
- 人类 `npx wrangler deploy` 后按 §8 截图复核：底部失败表消失、合成行显示「2026-11-04 20:10:23」样式时分秒。
