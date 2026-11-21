# pCryoxy PC-04 生产入口依赖交接

项目: pCryoxy

- 记录人：copilot@zhn-tbxg2iah-win~zhn-x-w；本记录为新增 handoff，不改写历史记录。
- PC-04 实施提交：`c3a225780f02aa7920d4183f518fcaa52595b5b9`；最新裁定：`0758fae3a02d64b00284da6f79d61503a7353553`。
- 现场：`~/source/pCryoxy.wt/copilot-pc04`，分支 `agent/copilot/pc04`，HEAD 为上述实施提交；跟踪文件无未提交修改。未跟踪的 `tests/integration/bridge/pc04-linux-amd64.a` 保留，不属于本轮交付。
- 状态：PC-04 继续 `doing / blocked`；受限能力子集既有测试回执可按上述裁定采信，但没有真实生产调用方及生产绑定证据。本轮仅交接，不修改代码、依赖、公共契约或任务状态。

## 责任与依赖

PC-18/运行时集成负责提供真实生产调用方、宿主启动/停止、私有控制端口及相应测试；PC-04 负责受限 profile 的桥侧实现及后续绑定复核。PC-04 不代做 daemon、systemd、TUN 或完整生产启动链。PC-19 的平台运行/服务职责和 PC-20 的 Web/REST/WS 认证职责仍各自独立。

在指定 PC-04 提交中，`RegisterRuntime` 的调用只见 `tests/integration/bridge/control_ipc_test.go`；本次指定基线中也未发现 `crates/daemon-server` 文件。这是该基线的只读核对，不断言其他未检查分支不存在代码。当前没有可采信的 PC-18 生产绑定及运行证据，故本轮不新增代码、不认领 PC-18，直接记录依赖阻塞。

任务卡 v1.1 中 PC-08 依赖 PC-04，PC-18 又依赖 PC-08/PC-09；而当前 PC-04 结卡需要 PC-18/运行时生产绑定。该先后关系可能形成验收循环：需由任务所有者协调分阶段集成及放行顺序；本记录不豁免原依赖，也不授权提前认领或实施其他卡。

## RegisterRuntime 最小调用契约

1. 真实生产启动必须调用 `bridge.RegisterRuntime(server, config, initialGeo, authorize)`，不得以单独创建核心或其他旁路替代。server、config、authorize 均须非空；入口创建并持有新核心，不接管外部既有核心。成功后宿主负责持有返回的 runtime 与关闭函数，并在宿主停止/失败清理时正确释放。
2. 生产配置必须满足现有受限 profile：router、DNS、dispatcher、outbound manager 各一份；拒绝 inbound、outbound、extension、未知字段以及未纳管 DNS、独立 Geo cron、脚本或其他无法证明绑定同一 RouteView/epoch 的消费者。sniffing、proxy/dns、freedom、finalmask 等不可绕过此限制。该 profile 是管理/路由核心，不提供可拨号出站，不承诺完整 Xray 配置。
3. 入口必须在 `core.New`、`x.Start` 和初始 Geo publish 之前完成 profile prepare 校验；非法输入应失败并保持未就绪，不允许先启动或先发布后再校验。初始 Geo 根须提供稳定 ID、绝对不可变目录及完整相对路径 SHA-256 清单，至少包含 `geoip.dat` 与 `geosite.dat`。
4. Linux 生产侧须实际创建受服务 UID 拥有的 `0700` 私有目录，使用 `ListenPrivateUnix` 创建 `0600` socket，以 `NewUnixPeerCredentials` 配置 gRPC 服务；`authorize(ctx)` 必须同时验证 `UnixPeerUID(ctx)` 与显式允许的管理客户端 UID，以及有效的 per-runtime ticket。缺失 peer 凭据、UID 不符或 ticket 缺失/错误均须拒绝；不能使用测试里的恒真回调，也不能把 socket 权限单独当成认证。
5. 当前 Linux helper 要求目录由服务有效 UID 拥有且为 `0700`，socket 为 `0600`；因此不同 UID 的客户端通常无法直接遍历目录及连接。若生产要求跨 UID 管理，PC-18 须先明确经授权的访问/中介方案并取得相应契约审核，不能假定配置不同 UID 即可连通，也不能擅自放宽目录权限。其他平台需提供各自经过批准的等价私有传输与身份验证，不得将 Linux UID 证据外推。

## PC-18 需提供的生产证据

- 真实宿主版本/提交、启动路径、构建与启动命令、环境、退出码；证明每条生产入口必经上述注册校验，失败不报告核心 ready，且无绕过实例或独立 commander 管理旁路。
- 实际服务身份、私有目录/socket 属主及权限、listener 和 gRPC peer credential 配置；在获准环境中验证授权客户端正确 UID 与有效 ticket 可访问，错误/缺失 UID、错误/缺失/失效 ticket 与未授权账户被拒绝。禁止记录真实 ticket 或其他秘密；同 UID/跨 UID 场景分别说明。
- 对真实生产入口逐项注入受限 profile 拒绝矩阵，记录可复现命令、测试数、结果及启动前事件顺序；验证拒绝先于核心创建/启动及首次 Geo publish，未注册服务、未报告 ready、未遗留资源。
- 对已有运行时的 prepare 拒绝，逐项比较拒绝前后 active RouteView、epoch、revision、Geo version、rollback point 及资源/lease 状态，证明无 publish、替换或意外释放；同时证明受管消费者共享同一 RouteView/epoch。无既存 active view 的首次启动失败应单列，不能伪造前后快照。
- 提供真实宿主重启、单写者和优雅退出等 PC-18 卡面证据；缺环境、未执行项和失败项逐项标 blocked。测试定义、隔离测试、实际执行和生产验收分别记录，不能将现有桥测试或 package archive 当作生产启动证明。

## 既有证据与缺口

桥源码显示启动 profile 校验在 `core.New`、`x.Start` 和首次 Geo publish 之前；现有隔离测试证明部分失败时服务未注册、部分运行中拒绝后 epoch/revision/Geo version 不变，及特定路由失败后规则与 rollback 可用。尚无生产调用链证据，也没有对每个拒绝项逐一证明 active RouteView 身份、rollback point 和所有资源状态不变；不能扩大为全部通过。

不引入 `SetAdmission`；不修改 PC-02 proto、descriptor 或 `contracts/core-lock.json`；不合并、不部署、不标记 PC-04 done。本轮不请求结卡复审；待 PC-18/获授权运行时集成提供真实调用方和实测证据后，再由 PC-04 按裁定申请 WorkBuddy 绑定复核。

## 挂起任务（当前全量快照）

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定、新 ADR、重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级、复跑、更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论、D-5～D-10、新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

pCryoxy 无 suspended 项；PC-04 的 `doing / blocked` 是依赖阻塞，不是挂起。pRayShell 已 closed，无 suspended 项。本轮不解挂任何项目。
