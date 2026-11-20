项目: pCryoxy
任务: PC-04 受限能力子集与统一 RouteView 生产边界裁定
状态: doing / blocked；本裁定允许受限能力子集作为交付目标，不代表 PC-04 done 或完整 Xray 生产验收
裁定人: workbuddy@zhn-tbxg2iah-win~zhn-x-w
时间: 2026-11-21 07:44 UTC+8

# WorkBuddy 裁定

## 一、裁定结论

**允许 PC-04 发布/交付“已验证配置子集”能力；不要求本卡在当前阶段纳管所有上游 Xray 消费者。**

PC-04 可以把统一 RouteView、epoch、prepare/publish/rollback 和桥 API 的能力范围明确限定为经过验证的 profile。对无法证明所有相关消费者均绑定同一 RouteView 的配置，必须在 prepare 阶段拒绝；不得接受后再以“运行时未覆盖”或“测试未覆盖”解释为成功。

本裁定不把隔离 profile 测试写成生产实例验收，也不把当前实现标记为 done。当前状态继续为 **doing / blocked**，待受限 profile 的实现、可复现构建、真实实例接入和对应验收证据完成后，再另行审核。

## 二、必须拒绝的配置类别

在生产 prepare 阶段，至少拒绝以下配置；拒绝必须发生在任何发布、epoch 增长、旧视图回收或外部副作用之前：

1. `sniffing` 或其他会在 RouteView 外改变目标/路由输入的 inbound 能力；
2. 未纳管到同一 RouteView 的 DNS 后端、DNS consumer 或 DNS matcher；
3. `proxy/dns`、`freedom` 等可能绕过统一 RouteView、独立读取 Geo/DNS 或改变出站行为的配置；
4. `finalmask` 及其他未证明与候选 RouteView 原子绑定的出站/最终处理能力；
5. Geo cron、独立定时刷新器或任何不经过同一候选 view 的 Geo 更新路径；
6. 其他未在受限 profile 清单中逐项证明 route、双 Geo、override、DNS、Lua/脚本和出站消费者共同使用同一不可变 view/epoch 的配置。

允许的 profile 必须显式列出：配置类型、允许的消费者、Geo 资产来源与摘要、DNS 形态、脚本/override 限制、prepare 校验条件和拒绝错误。未知字段、未登记扩展、无法证明一致性的配置一律拒绝，不猜测补全。

## 三、prepare 拒绝的不可变性要求

对上述不支持配置或其他候选构造失败：

- active RouteView 不变；
- epoch、revision、Geo version 不变；
- 不产生可用的 rollback point、operation receipt 或“已应用”状态；
- 不启动/替换不受控的 DNS、Geo cron、Lua、outbound 或其他旁路消费者；
- 不因失败关闭仍被旧 view 使用的资源；
- 通过 bridge 与兼容官方管理入口的错误语义保持一致。

不得引入 `SetAdmission` 或新流拒绝门禁来掩盖未纳管消费者；拒绝必须是配置 prepare/validation 的明确结果。

## 四、生产验收边界

隔离 `RegisterIsolatedGeoRuntime` 或类似最小配置测试，只能证明受限 profile 的局部构造、拒绝清单和 RouteView 机制；不能证明完整 Xray 实例的生产验收。

当前审核特别确认：普通 `RegisterRuntime` 的 Geo 后端仍不是生产级实例 Geo 热更新证据，隔离 profile 明确拒绝 inbound/outbound/extension 也不能替代生产接入证据。因此后续交付必须补齐：

1. 真实受限 profile 的生产注册/启动入口，而非只在测试辅助入口注册；
2. 对每个允许消费者的 route/DNS/Geo/Lua/override 单 epoch 证据；
3. 对上述不支持配置的 prepare 拒绝及 active 状态不变证据；
4. 至少连续三次 Geo 版本切换、旧资源回收和跨版本回滚证据；
5. 私有 IPC 监听、身份/权限和未授权访问证据；
6. 固定 Xray 源码按序重放补丁、桥构建、`go test`/`go test -race` 和 Linux 资产摘要；
7. 受限 profile 的可复现配置清单与最终构建命令。

在这些证据完成前，交接和审核结论只能使用“受限能力子集设计/实现/测试证据”，不得写“完整 Xray 配置已支持”“生产实例已验收”或“PC-04 done”。

## 五、对当前 PC-04 的直接放行

允许继续：

- 在 PC-04 独占文件范围内完善受限 profile 的 prepare 校验和明确拒绝错误；
- 保持 route、双 Geo、override、DNS/Lua 等已纳管消费者绑定同一不可变 RouteView；
- 继续真实固定核心测试、并发/epoch/回滚/资源生命周期测试和桥构建证据；
- 以受限能力子集为本卡交付目标，不为纳管全部上游消费者扩大本卡范围。

仍不允许：

- 以隔离配置测试替代生产实例验收；
- 把未提交工作树、未重放补丁的 `go.mod` 或模型测试写成可复现桥构建；
- 宣称完整 Xray 配置、所有上游消费者或任意生产 profile 已由统一 RouteView 纳管；
- 修改 PC-02 冻结 proto、descriptor 或 `contracts/core-lock.json`；
- 把本裁定解释为 daemon、systemd、TUN、Web/REST/WS、最终运行时或产品发布放行。

## 六、审核状态

本文件是 WorkBuddy 对“受限能力子集是否可作为 PC-04 交付边界”的正式裁定记录。裁定提交后须核对 `local HEAD == origin/main == backup/main`；PC-04 代码工作树中的未提交文件不属于本裁定提交，也未因本裁定自动获得验收通过。
