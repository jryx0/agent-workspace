# 交接：prnmgt T-044 凭据按设备编号

- 设备：zhn-tbxg2iah-win（主设备）
- Agent：trae@zhn-tbxg2iah-win
- 时间：2026-11-05 11:26 UTC+8
- 仓库：`~/source/prnmgt`（主仓库 master 1f0581c）
- worktree：`~/source/prnmgt.wt/trae`
- 分支：`agent/trae/credentials-by-device-no`（commit **b62a6f3**），已推 origin

## 一、已完成

T-044「采集端凭据按设备编号匹配 + 品牌随设备」完整实现，计划文档 `docs/plan-2026-11-05-cred-by-device-no.md` 6 条验收全部满足。

**改动范围（5 文件，全部 `collector/` 下）**：

| 文件 | 改动 |
|---|---|
| `collector/printer_monitor/config.py` | credentials 键从 IP 改 device_no；IPv4/IPv6 键 → ConfigError 文案「IP 会变，编码不变」；brand 从必填降级为可选（仅作一致性校验） |
| `collector/printer_monitor/collector.py` | 4 处：① :128 `cfg.credentials.get(device_no)` 替换 `get(ip)`；② brand 恒取 `vendor_brand`（不再跟 cred 走）；③ cred.brand 存在且与 vendor 不一致 → failed 阻断（删除 :152-162 旧 WARN 不阻断块）；④ 漂移检测 known_ips → all_device_nos + 日志文案改 device_no |
| `collector/config.prnmgt.example.json` | 示例键改 PRN008/PRN009；brand 示例标注可选 |
| `collector/printer_monitor/tests/__init__.py` | 新增（包标记） |
| `collector/printer_monitor/tests/test_credentials.py` | 新增，8 unittest（计划要求 7，额外加了 IPv6 拒绝用例） |

**零改动**：`worker/`、`ref/`、`worker/schema.sql`、`tools/`、`collector/printer_monitor/{fuji,kyocera,db,util,sync,...}.py` 均未触碰。

## 二、准出证据

```
# 主仓库 check.mjs
node scripts/check.mjs
→ 通过：0 个问题，2 个提示（T-034/T-040 历史拆卡提示，非本卡引入）

# worktree 内 unittest（Python 3.14.2）
python -m unittest printer_monitor.tests.test_credentials -v
→ Ran 8 tests in 0.300s — OK
```

**8 个用例覆盖**：

| # | 用例 | 覆盖准出条件 |
|---|---|---|
| 1 | device_no 键正常解析 | ① |
| 2 | IPv4 键 ConfigError | ① |
| 3 | IPv6 键 ConfigError（额外） | ① |
| 4 | brand 恒取清单 vendor | ② |
| 5 | cred.brand 不一致阻断 + error 文案 | ③ |
| 6 | cred.brand 缺省不校验 | 准出条件隐含 |
| 7 | 漂移检测 ERROR 日志 | ④ |
| 8 | 无显式凭据回退 default | ⑦ 回归现状 |

## 三、待办（下一位 agent / 人类）

1. **workbuddy 审核**：本 handoff + 分支 diff（`git diff master...agent/trae/credentials-by-device-no` 5 文件，+443/-59），按计划文档 §6 审核清单逐项核对。**禁止自行合并 master**。
2. **生产部署（人类运维，agent 不碰）**：采集服务器 config 迁移（IP 键→编号键、补 PRN013 账密、核对 PRN014 的 213 段手误）、ping 验证 PRN016、重启进程、观察当晚 20:10 collect_run。
3. **审核通过后 worktree 清理**：`git -C ~/source/prnmgt worktree remove ~/source/prnmgt.wt/trae` → `git worktree prune`。

## 四、关键文件

- **计划**：`~/source/prnmgt/docs/plan-2026-11-05-cred-by-device-no.md`（含代码行号、硬红线、审核清单、上线运维清单）
- **分支**：`https://github.com/jryx0/prnmgt/tree/agent/trae/credentials-by-device-no`
- **测试**：`~/source/prnmgt.wt/trae/collector/printer_monitor/tests/test_credentials.py`（直接用 `python -m unittest` 跑，不发真实网络请求）

## 五、注意事项

- 本机 Python 3.14.2 可用：`C:\Users\Zhn_X\AppData\Local\Programs\Python\Python314\python.exe`；系统 PATH 里的 `python.exe` 是 Microsoft Store stub（exit 9009），必须用完整路径。
- Node PATH 同样有 bug（指向不存在的 24.14.0），跑 `check.mjs` 时临时注入 `~/.workbuddy/binaries/node/versions/22.22.2-6`。
- worktree 提交已用 `git -c user.name=zhn-trae -c user.email=trae@zhn-tbxg2iah-win`，不污染主仓库署名。
- `failed_json` 的 `brand` 字段语义已变为**设备厂商**（不再是凭据 brand）。worker 侧 `lib/overview_stat.js:104` 消费失败记录时只看 device_no/ip，不读 brand → 无影响（已在测试中确认 `failed.append({"brand": brand, ...})` 的 brand 就是 vendor_brand）。
