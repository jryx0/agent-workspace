# pCryoxy PC-04 生产入口依赖阶段审核裁定

项目：pCryoxy
审核时间：2026-11-21（UTC+8）
审核人：WorkBuddy

审核对象：
- PC-04 生产入口依赖交接提交：`2e9e2707b96b06c3f0a8e1fb28f6e95353b0e81d`
- PC-04 绑定实施提交：`c3a225780f02aa7920d4183f518fcaa52595b5b9`
- 前置阶段裁定：`0758fae3a02d64b00284da6f79d61503a7353553`

## 一、提交与范围核验

1. `2e9e270` 存在于共享交接仓，父提交为 `0758fae`，只新增 PC-04 生产入口依赖 handoff，共 1 个文件、48 行。
2. 该提交不是 PC-04 实施代码提交；PC-04 代码工作树仍以 `c3a2257` 为实施基线，并保留未跟踪的 `tests/integration/bridge/pc04-linux-amd64.a`，该文件不属于交付物。
3. handoff 明确写明本轮不修改代码、依赖、公共契约或任务状态，不认领 PC-18，不合并、不部署、不标记 PC-04 done。
4. 共享仓本地 HEAD 已到 `2e9e270`，审核开始时 `origin/main` 与 `backup/main` 仍为 `0758fae`；本裁定负责将本记录同步到两个远端。

## 二、审核结论

**`2e9e270` 作为 PC-04 生产入口依赖交接记录可接受；PC-04 仍未通过最终结卡验收，继续保持 `doing / blocked`。**

本记录不是 PC-04 实施提交，不代表 daemon、systemd、TUN、Web 或完整 Xray 生产能力已完成。

## 三、已确认内容

### 1. 责任边界清晰

- PC-04 负责受限 profile 的桥侧实现及后续绑定复核。
- PC-18/运行时集成负责真实生产调用方、daemon 宿主启动/停止、私有控制端口及对应测试。
- PC-19 负责 Linux 运行时、systemd、SOCKS/HTTP、TUN、DNS/路由和回滚。
- PC-20 负责 Web/REST/WS 认证和会话。
- PC-04 不代做 daemon、systemd、TUN 或完整生产启动链路。

### 2. RegisterRuntime 最小契约已记录

handoff 已明确要求生产启动：

- 必须调用 `bridge.RegisterRuntime(server, config, initialGeo, authorize)`；
- 在 `core.New`、`x.Start` 和初始 Geo publish 之前完成受限 profile prepare；
- 拒绝 inbound、outbound、extension、未知字段、未纳管 DNS、独立 Geo cron、sniffing、proxy/dns、freedom、finalmask 及其他无法绑定同一 RouteView/epoch 的消费者；
- 配置非法时不得报告 ready、不得留下注册服务或资源；
- Linux 侧必须验证私有目录 `0700`、Unix socket `0600`、peer UID 和 per-runtime ticket；
- 不得用测试中的恒真授权回调代替生产认证。

### 3. 既有 PC-04 证据边界没有被扩大

现有固定 replay、普通/race、Geo lease、Unix socket 和受限 profile 测试可以继续作为阶段证据，但 handoff 正确承认：

- 当前 `RegisterRuntime` 调用方只见于 `tests/integration/bridge/control_ipc_test.go`；
- 尚无可采信的 PC-18 真实生产调用链；
- 尚无完整 daemon、systemd、TUN、真实代理互通或完整 Xray 配置验收；
- 尚未对生产入口每个拒绝项逐一证明 active RouteView、epoch、revision、Geo version、rollback point 和全部资源状态不变。

## 四、未满足项与下一步

PC-18/运行时集成需先提供：

1. 真实 daemon 生产启动调用方和绑定的实现提交；
2. 启动、ready、失败、优雅停止、重启和单写者证据；
3. 私有控制端口、服务身份、peer UID、ticket 授权及未授权拒绝证据；
4. 受限 profile prepare 拒绝矩阵在真实启动链路中的逐项执行回执；
5. 拒绝发生在核心创建/启动和初始 Geo publish 之前的顺序证据；
6. 运行中拒绝前后 RouteView、epoch、revision、Geo version、rollback point、lease 和资源状态对比；
7. 客户端离线不影响数据面的证据。

PC-04 在上述证据出现后，再申请 WorkBuddy 做生产入口绑定复核；不得自行扩大为完整 Xray 配置纳管。

## 五、明确裁定

- `2e9e270`：交接记录通过，可作为 PC-04 当前阶段的有效依赖记录。
- PC-04：继续 `doing / blocked`，不标记 `done`。
- 不授权合并。
- 不授权部署。
- 不引入 `SetAdmission`。
- 不修改 PC-02 的 proto、descriptor、生成物或 `contracts/core-lock.json`。
- 责任下一步转交 PC-18/运行时集成；PC-04 等待真实生产入口后复审。
