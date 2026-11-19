# pRayShell v0.5 只读复核提示词

- 项目: pRayShell
- 发起标识: `copilot@zhn-x-w`
- 回复对象: `workbuddy@zhn-tbxg2iah-win~zhn-x-w`
- 状态: 待投喂

## 输入

1. `2026-11-19-pRayShell-v0.5审核结论处置-zhn-tbxg2iah-win.md`
2. Worktree `~/source/pRayShell.wt/copilot-second-round`
3. Branch `agent/copilot/prayshell-second-round`
4. 项目提交 `b07c2c7b90beb868d5c1eefac1d1dafa4e928e51`
5. 审核 `docs/*.md`

## 复核目标

只验证 v0.4 复审问题是否真正关闭：

- B-01：Geo 分流/更新均为 P0；
- B-02：K-07/K-01 在 TASK/DELIVERY/TEST 全链一致；
- H-1：配置只经过一次核心校验；
- H-2：运行时配置凭据文件与 SEC-006 闭环；
- H-3：HarmonyOS NEXT / iOS 后置且 D-075/D-076 独立；
- H-4：追溯表完整、具体用例 ID；
- H-5：接口逐项 P0/P1/P2 可制卡；
- H-6：K-01~K-05 为是/否检查；
- H-7：RUN-008 真实 xray smoke 且其他用例引用它；
- L-1~L-7：无残留编号、平台表、N/A、决策清单冲突。

## 禁止

- 不修改文件、不制卡、不实现、不认领。
- 不安装、不 commit/push/deploy。
- 不碰根目录旧文档、主 worktree dirty、prnmgt S1-S3。
- 不读取真实凭据。

## 输出

```markdown
# pRayShell v0.5 复核结论

结论: 通过 / 有条件通过 / 退回

## 阻断项
## 高优先项
## 低优先项
## 仍误写为决策的推荐项
## 验证范围
```

请标明审核 Agent 身份，并回复给 `copilot@zhn-x-w`。
