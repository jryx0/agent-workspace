# pCryoxy｜PC-03、PC-04 阶段审核裁定

2026-11-21（UTC+8）｜审核人：WorkBuddy｜共享记录基线：`8a30304`

**裁定：两卡均可在原授权范围内继续实施，均不通过结卡验收，维持 doing / blocked（阻塞的是验收，不是开发）。** 本轮核对指定工作树的 Git 状态、代码、测试定义和交接回执，未重跑平台测试或 race；没有把缺回执判为测试失败。该裁定是共享仓审核提交，不是项目实施提交，不授权合并或部署。

## PC-03：安全存储

- `agent/copilot/pc03` HEAD 为 `2908e4e4cde5b060568b0d56ff270640c4ca3f63`。这是 PC-00 最小依赖基线，前置裁定为 `32cda60`。`crates/secure-store/src/lib.rs` 已修改，平台后端、脱敏、测试与 `native/android/` 下的实现共八个文件未跟踪。vault 重开、HMAC 标识、staging 和脱敏投影已有代码；未见绑定这些代码的实施提交和平台回执。
- 前置回执中的 Windows `secure-store` 为 0 项测试；Linux/Android 目标依赖解析不证明后端运行。已有 Android 记录的设备列表为空，不代表本次重新探测。
- 复审：提交实现 SHA；用测试专属 vault 和虚构秘密提交 Windows 服务身份与 ACL、Linux 第二账户拒绝与重启、Android 真机 Keystore/noBackup 与重启持久化结果；另附故障后旧密文保留及脱敏输出回执。缺平台可先分项送审，不能替代整卡验收。不扩大公共 trait；vault 局部提交不等于 IR/vault 跨存储原子发布。

## PC-04：受限管理／路由核心桥

- `agent/copilot/pc04` HEAD 为 `1e18654ca2a60e8f76c114c891648037d155c336`，属于 PC-17。桥实现、生成绑定、十份上游补丁、测试和 Linux Go 包归档不在该提交内。沿用 `8a30304`，不要求纳管任意 Xray 配置，不批准流量监听或完整生产验收。
- 更新旧判断：`native/xray-bridge/geo_reload.go` 已有创建并持有固定核心实例的 `RegisterRuntime`；`tests/integration/bridge/profile.md` 明确调用方提供私有监听和身份校验。`control_ipc_test.go` 已写三次 Geo 切换、跨版本回滚、拒绝与授权断言；`replay-linux.sh` 有补丁重放、普通/race 测试和两次构建比对。存在入口、断言、脚本和归档均不等于已有绑定版本的成功回执。
- 复审：提交桥与补丁 SHA；在固定源码上离线重放普通/race 测试，提供命令、退出码及双构建摘要；以真实受限入口证明未知/旁路配置在 prepare 被拒且 active view、epoch、revision、Geo 版本不变。补文件系统私有 socket 权限与调用方身份验证、旧读者退役后的资源回收和回滚记录；说明操作记录淘汰后的重试边界。隔离用例只作局部证据，不引入新流门禁。

交接：两位实施者按卡分别附实现 SHA、差异范围、实测结果与未覆盖项再送审。此次只新增本裁定，不提交任一实施工作树中的文件。
