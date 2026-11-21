# pCryoxy｜PC-03 补充裁定：Windows 历史失败暂缓、Android 后置

项目：pCryoxy
任务：PC-03 安全存储
前置裁定：`33a5b6e06c2123717f11995d5ca681a30d5845fb`
最近交接：`aa60737`（PC-03 Linux 补充验收证据）
审核时间：2026-11-21（UTC+8）
审核人：WorkBuddy

## 一、用户补充裁定

### Windows 原 8 项失败

原始逐项日志当前不可用；现有记录只有历史汇总 `6 passed、8 failed、2 ignored`，没有可供脱敏核对的完整 stdout/stderr、失败名称、对应测试轮次和 Credential Manager 状态。

在当前可用环境中也没有获准的 Windows Service 测试账户或 runner 可重新执行完整验证。因此，Windows 原 8 项失败**当前不能确认可重现**。

按本次用户裁定：

- 该历史 8 项失败暂时从当前阶段的阻塞清单中移除；
- 标记为“暂缓核查／条件接受”，不是“8 项测试已通过”；
- 不要求当前继续追索不可用的原始日志；
- 若后续获得脱敏日志或获准 Windows Service runner，再单独建立补测任务，不追溯修改本裁定。

### Android 真机测试

Android 真机测试后置。当前没有获准 Android 真机，故：

- 不执行 Android 真机测试；
- 不把 Android 源码存在或 `adb` 空设备写成通过；
- Android Keystore、`noBackupFilesDir`、进程重启、密钥丢失、篡改和权限测试移出本阶段验收范围；
- 待用户准备好设备后，由用户另行发起 Android 专项任务和复审。

## 二、当前阶段结论

**PC-03 当前阶段可作“有条件通过／继续实施”，不再因 Windows 历史 8 项和 Android 真机缺失阻塞当前阶段；但不等于最终 PC-03 done，也不代表三平台完整验收通过。**

仍需保留的边界：

- 不授权合并或部署；
- 不把 Windows 8 项写成测试通过；
- 不把 Android 写成测试通过；
- 不改变 `SecretStore` 公共 trait、PC-02 proto/descriptor、公共锁文件或 PC-04 范围；
- `commit_staged` 仍不代表 IR 与 vault 的跨存储原子提交；
- 后续 Android 真机任务必须附设备信息、命令、退出码和未覆盖项，再单独复审。

## 三、给实施方的脱敏回复

可直接回复 PC-03 实施方：

```text
原始逐项 Windows 日志路径：不可用；当前没有可供脱敏核对的完整日志文件。
获准 Windows Service 测试账户/runner：当前不可用。
Android 真机：当前不可用，按 WorkBuddy 裁定后置，待用户准备好后另行发起任务。

Windows 原 8 项失败目前无法重现。按用户裁定，本项暂时按“条件接受/暂不阻塞当前阶段”处理，但不得写成 8 项测试已通过。
Android 真机验收暂不执行，也不得把源码或空设备列表写成平台通过。
PC-03 当前为有条件通过/继续实施，不代表最终 done；不得合并或部署。
```
