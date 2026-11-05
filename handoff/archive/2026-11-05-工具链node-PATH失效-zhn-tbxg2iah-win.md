# 交接：工具链基线核对发现 node PATH 失效

> 规范 三-4 交接文档 · 设备 `zhn-tbxg2iah-win` · 提出者 `trae`
> 状态：**待处置**（本 agent 未做任何环境修改）

## 一、当前状态

执行规范 v1.8.3 八-8「工具链核对」自检：

- stamp `~/.agent-tools/run/tools-scan.stamp` 存在，`scanned_at=2026-11-05T08:25:02+0800`，未满 30 天 → 按 四-4 ② 只跑 `--check`，未做全量扫描。
- 结果：**基线核对失败 1 项**

```
❌ 缺失：node（基线 >=20，用途：Node 运行时）
```

## 二、诊断结论

node 并未真正缺失，是**用户级 PATH 登记了失效路径**：

| 项 | 值 |
|---|---|
| 用户级 PATH 中 node 条目 | `C:\Users\Zhn_X\.workbuddy\binaries\node\versions\24.14.0` —— **目录不存在** |
| 磁盘上实际 node | `C:\Users\Zhn_X\.workbuddy\binaries\node\versions\22.22.2-6\node.exe`（v22.22.2，满足 >=20） |
| 设备清单记录 | `memory/devices/tools-zhn-tbxg2iah-win.md` 第 21–22 行仍写 `22.22.2-6`、PATH 可见=是（与当前 PATH 不符） |
| Git Bash 中验证 | `which node` → 无输出；`node --version` → command not found |
| 注入正确目录后复测 | `PATH=.../22.22.2-6:$PATH bash env/tools-scan.sh --check` → `✅ 基线核对通过` |

**结论：基础设施本身完整，仅 PATH 指向错误版本目录，导致 node/npm 在当前 shell 不可解析。**

> 附带发现：用户级 PATH 另有两处失效项 `C:\Users\Zhn_X\.dotnet\tools`、`C:\Users\Zhn_X\.local\bin`（优先级低于基线问题，可一并清理）。

## 三、待办（请处置 agent 按序执行）

1. **决策口径**（需人类确认后再动手，属环境变更）：
   - 方案 A：把用户级 PATH 中 `versions\24.14.0` 改为 `versions\22.22.2-6`（复用已装版本，符合 四-4 ① 探测优先）；
   - 方案 B：按原 PATH 意图补装 node 24.14.0 到该目录（属新装，须按 四-4 ③ 登记变更日志与来源类型）。
2. **执行后复测**：`bash ~/.agent-shared/env/tools-scan.sh --check` 应输出 `✅ 基线核对通过`。
3. **登记**：若涉及安装/升级/路径变更，在 `env/toolchain.md` §五 追加一行变更日志（日期 | 设备 | 操作 | 工具与版本 | 来源类型 | 操作者 | 备注），并在 §六 设备索引备注中更新扫描时间。
4. **刷新设备清单**：`bash env/tools-scan.sh --write`（PATH 修正后清单里的 node 路径与"PATH 可见"列会随之更新）。
5. 完成后在 org.md 末尾追加一条处置记录（署名 + 实际时间），并将本文件归档至 `handoff/archive/`。

## 四、关键文件

| 用途 | 路径 |
|---|---|
| 规范（v1.8.3 四-4、八-8） | `~/.agent-shared/global/rules.md` |
| 基线表与变更日志 | `~/.agent-shared/env/toolchain.md` |
| 扫描脚本 | `~/.agent-shared/env/tools-scan.sh` |
| 本机清单（脚本生成，勿手改） | `~/.agent-shared/memory/devices/tools-zhn-tbxg2iah-win.md` |
| stamp | `~/.agent-tools/run/tools-scan.stamp` |

## 五、下一步指令

处置前先确认人类选择方案 A 还是 B（本 agent 问询结果：人类要求「输出检查的问题，由其他 agent 处理」，未授权修改环境变量）。确认后按第三节 1→5 执行，全程遵守 三-5 ⑥ 人类操作优先，勿在人类正在编辑环境变量时并行修改。

---

[@trae @zhn-tbxg2iah-win 2026-11-05 08:40 UTC+8] 本交接由 trae 生成：执行 v1.8.3 自检第 8 步发现 node PATH 失效，按人类指示仅输出问题、不作环境修改。
