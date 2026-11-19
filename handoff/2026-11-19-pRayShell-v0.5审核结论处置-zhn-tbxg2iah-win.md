# pRayShell v0.5 审核结论处置

- 项目: pRayShell
- 交互标识: `copilot@zhn-x-w`
- 回复对象: `workbuddy@zhn-tbxg2iah-win~zhn-x-w`
- 日期: 2026-11-19
- Worktree: `~/source/pRayShell.wt/copilot-second-round`
- Branch: `agent/copilot/prayshell-second-round`
- 项目文档提交: `b07c2c7b90beb868d5c1eefac1d1dafa4e928e51`
- 共享仓 v0.4 前置提交: `bc503b8ec3b558362998c16472a3ac811b3b3daa`
- 共享仓 v0.5 交接提交: `999b86d6befee4d68c0716e964152e5252abfd3f`

## 结论

v0.4 复审的 B-01/B-02、H-1~H-7、L-1~L-7 和 S-03/S-06/S-07/S-08 已全部处置。v0.5 文档已提交到独立项目分支；本轮没有实现代码、没有制卡、没有认领任务。

## 逐项处置

| 项 | 状态 | 修改位置 | 自查方式 |
|---|---|---|---|
| B-01 Geo 降级 | 已修 | ARCH §6.0；COMPARISON C12 | `Geo.*P1` 0 命中；Geo updater 在 P0 |
| B-02 Fake/降级 | 已修 | TASK §1 原则 5、§9；DELIVERY §4.1 | `Fake adapter` / “FakeRuntime 全链” 0 命中 |
| H-1 重复校验 | 已修 | ARCH §6.0/6.3/6.7；TASK 4.3/D-020 | `validate_and_apply`、`IConfigRenderer`、`IConfigValidator` 0 命中 |
| H-2 配置生命周期 | 已修 | ARCH §6.7/§11；TEST SEC-006；REPORT SEC-001~006 | SEC-006、运行时核心配置表均存在 |
| H-3 iOS 后置 | 已修 | PRD；ARCH；TASK D-075/D-076/能力矩阵；TEST IOS-001~004；REPORT；COMPARISON | iOS 与 HarmonyOS 均明确后置；D-052 不再依赖鸿蒙卡 |
| H-4 追溯矩阵 | 已修 | TASK §5→§6；矩阵增加结论列和两类需求 | 全部测试写具体 ID，无 `size-budget/HOS未来` 描述 |
| H-5 接口分级 | 已修 | ARCH §6.0 逐接口表 | 每行含接口/P级/理由/首个使用方；单使用方保留理由 |
| H-6 K-01~K-05 | 已修 | TASK §1 和 §9 K 检查清单 | 每项可判定是/否 |
| H-7 真实 xray smoke | 已修 | TEST RUN-008；UPD-008/WIN-003/AND-006 引用；REPORT RUN-001~008 | RUN-008 与真实 xray apply→connect→stop 存在 |
| L-1 编号 | 已处置 | TASK B6 中 D-067 置于 D-072 前 | 按层/依赖阅读；新增 D-075/D-076 按 iOS 平台卡分段 |
| L-2 P0 跳号 | 已处置 | PRD F-ID 保持跨优先级冻结 | 不重排编号；F-17/F-19/P1 属既定 ID 语义 |
| L-3 主观评分 | 已修 | COMPARISON §7 | 改为“缺口/处置状态”，删除无口径分数 |
| L-4 RequestPermission | 已修 | ARCH §9.1 note | 注明仅 Android/HOS/iOS 授权平台，Windows 直通 |
| L-5 全候选隔离 | 已处置 | ARCH §7.3；TEST POL-005 | 统一为保底候选并标 degraded；测试不再给“双选一” |
| L-6 报告编号 | 已修 | TEST_REPORT §5/§6/§7/§8 | 章节连续 |
| L-7 rollback 终态 | 已修 | ARCH §9.1 | 增 `Switching → Idle: rollback_failed` |
| S-03 文档提交 | 已修 | 项目提交 `b07c2c7`；共享前置提交 `bc503b8` | 两个仓不包含他人 dirty 文件；共享已双远端同步 |
| S-06 文件名 | 已修 | v0.4 两文件已改为 `...-zhn-tbxg2iah-win.md`；v0.5 同规则 | `Get-ChildItem handoff/*pRayShell-v0.4*` 只见设备后缀 |
| S-07 项目标签 | 已修 | v0.4 prompt 与本文件 | `项目: pRayShell` 存在 |
| S-08 实际复跑 | 已修 | 下方验证记录 | URL/token/UUID/路径/相对链接与 git diff 检查通过 |

## 未采纳项

无静默跳过项。

- `AGENTS.md` 未按 K-06 增生成物规则，因为用户澄清 K-06 只适用于共享仓生成文档；项目 `docs/` 可直接维护。
- iOS 不进入首发，但已与 HarmonyOS NEXT 同级后置。
- 未在当前轮固定 MB 体积阈值；必须由双平台最小原型实测。
- 未自登记 `copilot` agent；该项属于人类/主 Agent，未自行修改 `env/agents.md`。

## 仍需用户裁决

唯一裁决清单以 `PRD.md §9.1` 为准：

1. UI 与共享核心路线：原生双端 vs Flutter/KMP PoC。
2. xray 接入：Windows 进程、Android library/FFI 的最终选择。
3. 运行时配置：私有临时文件策略，或要求 FFI 绝不落盘。
4. 更新源、channel、签名和自动安装权限。
5. Geo 基础数据内置或按需下载。
6. AI/共享是否保持 P1。
7. release size budget 的低端设备基线。

## 实际验证命令与结果

### 1. 文档安全与链接

```text
PowerShell: 遍历 docs/*.md
检查: http(s) URL / token 前缀 / UUID / 盘符绝对路径 / 本地相对链接
结果: DOC_COUNT=7
结果: DOC_SAFETY_AND_LINKS=PASS
```

### 2. 复审自查

```text
rg: validate_and_apply / IConfigRenderer / IConfigValidator / IC oreProvider.validate / Geo P1 / Fake adapter
结果: 仅 updater 描述中无违规命中；关键阻断模式均为 0 命中
```

### 3. Git scope

```text
git diff --check
git status --short
结果: 项目 worktree 仅 ?? docs/（提交前）
```

提交后：

```text
git status --short --branch
## agent/copilot/prayshell-second-round
```

### 4. 共享仓前置提交与同步

```text
proxy-check.sh
git push origin --all
git push origin --tags
git push backup --all
git push backup --tags
结果: origin 917c129..bc503b8
结果: backup 917c129..bc503b8
```

## 提交说明

- 项目仓：`b07c2c7b90beb868d5c1eefac1d1dafa4e928e51`，包含 7 份 v0.5 docs。
- 共享仓前置：`bc503b8ec3b558362998c16472a3ac811b3b3daa`，完成 v0.4 handoff 设备后缀更名与提示词项目标签。
- 共享仓 v0.5：`999b86d6befee4d68c0716e964152e5252abfd3f`，包含本处置文档与 v0.5 提示词。
- 本补录采用后续提交，不 amend、不改写历史。

## 下一步

1. 其他 Agent 对 v0.5 做只读复核。
2. 人类裁决 PRD §9.1。
3. 裁决后才生成正式任务卡。

> 署名：`copilot@zhn-x-w`
