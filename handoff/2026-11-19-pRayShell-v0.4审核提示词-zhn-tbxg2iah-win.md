# pRayShell v0.4 独立复核提示词

> 发起标识：`copilot@zhn-x-w`  
> 状态：待投喂  
> 任务：只读审核，不修改、不实现、不制卡

- 项目: pRayShell

## 读取

1. 交接：`2026-11-19-pRayShell-v0.4审核结论处置-copilot-zhn-x-w.md`
2. Worktree：`~/source/pRayShell.wt/copilot-second-round`
3. Branch：`agent/copilot/prayshell-second-round`
4. 审核 `docs/` 下 7 份 v0.4 文档及根目录既有四份设计文档。

## 已裁决事项

- Windows + Android 同步首发。
- HarmonyOS NEXT 与 iOS 同级后置。
- xray-core 首发必选，其他核心只保留插件边界。
- app/core/Geo 自动/手动更新、校验和回滚。
- Geo 分流进入 P0；小体积是 release gate。
- `copilot@zhn-x-w` 是跨 Agent 交互唯一标识。
- K-06 只约束共享仓 handoff/提示词等生成物，不限制项目 `docs/`。

## 审核重点

1. v0.4 是否已修正 H-01/H-02/H-04/H-05/H-06。
2. K-01/K-02/K-03/K-04/K-05 是否真正可制卡，而非只写口号。
3. K-07 是否做到真实逻辑优先、替身原因明确、真实 xray smoke 不被替代。
4. iOS 是否真正只作为后置平台。
5. app/core/Geo 更新是否可兼容、校验、原子切换、回滚。
6. 运行时配置凭据文件生命周期是否可执行。
7. 接口 P0/P1/P2 与校验边界是否过度或不足。
8. 需求追溯矩阵和测试报告模板是否完整。
9. 推荐项是否误写成已确认决策。
10. 小体积、插件化和多 Agent 独占边界是否一致。

## 禁止

- 不修改文件、不实现、不制卡、不认领。
- 不 commit/push/deploy/install。
- 不碰根目录其他 Agent 产物、主 worktree dirty、S1/S2/S3。
- 不读取真实节点、订阅、token。

## 输出格式

```markdown
# pRayShell v0.4 审核结论

结论: 通过 / 有条件通过 / 退回

## 阻断项

## 高优先建议

## 低优先建议

## 推荐项是否误写成决策

## 验证范围
```

审核回复请标明自身 Agent 身份，并对 `copilot@zhn-x-w` 回复。
