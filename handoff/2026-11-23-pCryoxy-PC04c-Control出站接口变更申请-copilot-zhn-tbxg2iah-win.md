# pCryoxy PC-04c｜Control 服务出站接口变更申请

项目: pCryoxy

- 申请者：copilot@zhn-tbxg2iah-win~zhn-x-w#pc04c；状态：doing，**待契约所有者审核及人类批准**。
- 基座：项目 main `c3acc73f0b1cfc25b1770a4d0d9645cd59681738`；worktree `C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc04c`；分支 `agent/copilot/pc04c`。
- 依据：需求 v1.3 REQ-08、实施任务卡 v1.3 增量 §3 和 §3.1、PC-07 前置事项裁定 §4、PC-04b H1 和结卡裁定。固定核心 `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`。
- 本文仅为申请，不代表实现、测试、互通或契约变更已经获批；批准前不修改契约文件、不写业务实现。人类已单独允许本认领和申请在共享仓 main 提交；项目 main 不提交、不推送。

## 1. 请求审核的新 RPC

建议一次提交完整出站集合和完整路由，而非逐个 Add/Remove：

```proto
rpc ReplaceRoutingAndOutbounds(ReplaceRoutingAndOutboundsRequest) returns (CommitReceipt);

message ReplaceRoutingAndOutboundsRequest {
  OpHeader header = 1;
  bytes outbounds_json = 2;
  xray.common.serial.TypedMessage router_config = 3;
  repeated Override desired_overrides = 4;
}
```

- `outbounds_json` 是 UTF-8 JSON 数组，元素为固定核心 JSON 出站对象，按数组顺序提交整个期望集合，而非增量操作；不能为空。首个对象必须是 `sys/reject`，因此不另设默认出站字段。
- 桥使用固定核心 `infra/conf` 的出站 JSON 配置及构建器构造核心出站配置；不得把 JSON 字节直接塞入 protobuf `TypedMessage.value`，也不在 Rust 侧派生 XMC RSA。JSON 结构、协议及 stream 字段先严格纳管，构建后再校验核心配置；未知字段、构建失败、重复或空 tag、未知协议或无法证明受控的组合均明确拒绝，不静默丢字段。若固定构建器不能满足严格拒绝，先报审核，不以成功形状回退。
- `router_config` 使用现有 typed router config，`desired_overrides` 为完整期望集合；不能将“没传”当作保留当前集合。桥在同一候选中验证规则显式出站、balancer selector 和 override 最终目标；任何实际引用缺失 tag，或默认出站缺失，提交失败且 active 不变。selector 的匹配语义及空匹配必须按固定核心和业务约束实测，不能把前缀当作 tag 直接比较或擅自改变合法语义。
- 既有 `ReplaceRoutes`、兼容 RoutingService 写入及 Geo 热更新继续保留，不绕过同一实例串行提交器；路由变更路径引用出站时也须以所绑定的候选/当前同一 view 校验。请求是否为同一操作按现有 `operation_id`、实例与请求摘要机制判断；冲突、超时结果未知时沿用 `QueryOperation`/`QueryState` 对账，不盲目重试。
- 凭据可能包含在 JSON 中：仅经现有受保护管理通道传输，不写日志、错误详情、fixture 或持久化记录；不在回执中回显配置。现有确定性请求摘要只保存摘要而非请求体；临时解析和构建过程同样不得记录明文。

## 2. 默认拒绝和准入边界

- 按人类 20:08 裁定与任务卡 §3.1：**先完成默认拒绝出站纳管及验收，再放行节点出站**。启动 prepare 首个出站必须为 tag `sys/reject` 的 blackhole，response 只允许空或 `none`；`sys/direct` 是常驻直连。二者不可删除、替换或纳入动态池；运行时整组提交保留原有受控实例，任何删除或替换都必须失败且 active 不变。未命中路由的流量走 `sys/reject`，不得直连。
- 出站协议逐项验证 vless（Vision、VLESS Encryption）、vmess、trojan、shadowsocks（含 2022）、hysteria2、wireguard、masque；传输 raw、xhttp、ws、httpupgrade、grpc；安全 tls、reality。FinalMask 复用 PC-04b 的 TCP/UDP 位置与类型白名单；realm、xicmp、udphop 等仍拒绝。固定核心不支持的组合明确拒绝。
- 始终拒绝 `proxySettings`/`dialerProxy` 指向其他出站的代理链；可能绕过 RouteView 的 sockopt 和非 AsIs `domainStrategy` 按固定核心及平台实测拒绝。Windows tun 入站维持 PC-04b H1 的明确拒绝，不新增 wintun 或 wireguard/windows。
- **mux 单独申请：建议本卡默认拒绝启用 mux。** mux 复用连接的生命周期可能跨视图发布与回滚，现有 PC-04b 只证明出站 handler 的视图绑定，未证明复用子流始终遵守选定视图和健康策略；REQ-08 的本卡必验协议、传输、安全清单没有要求 mux。不是声称已验证安全，也不是默认静默关闭：出现启用或无法识别的 mux 配置时显式拒绝，active 不变。请求审核方及人类明确是否接受此边界；如要求放行，先裁定范围并补独立单 epoch、复用、回滚及互通证据，不能仅凭普通 TCP 成功放行。
- 启动和运行时调用同一套出站校验逻辑；为两条入口各设正反例，证明同配置结果一致及失败不改变 active。所有尚未取得证据的能力不能标为已支持；发现无法纳管或需要缩小 P0 时停下报人类裁决。

## 3. 单 epoch、资源和回滚

1. 在发布前解析并完整校验候选、构造出站 handler、路由、override，绑定当前 Geo/DNS；候选失败须清理新资源，不能改变 active、epoch、revision、Geo、既有回滚点或旧资源。构造与启动阶段是否存在网络或其他副作用须实测；若不能确保失败安全，先报告而非宣称原子。
2. 在同一发布点核对 `expected_epoch`，一次发布含路由、override、Geo/DNS 与出站映射的完整 RouteView，epoch 只递增一次；成功回执返回既有 `CommitReceipt` 和紧邻前驱的 retained handle。旧连接持有旧 view 及其 handler 资源，释放时机须与读者/回滚点生命周期一致；不承诺连接零损或不复制活动网络连接。
3. 现有 `Rollback` 恢复回滚点中的整个 view，包括出站映射、默认出站和路由，发布新 epoch 而非倒退；同时返回新的前驱回滚点。`ReleaseRollbackPoint` 只释放管理引用，不提前关闭仍被在途读者或其他 retained view 使用的资源。Geo 与路由单独提交也不得丢失绑定的出站集合。
4. `QueryState` 的 epoch、revision、Geo 与出站 tag 摘要须来自同一个已固定的 view。当前 `snapshot.go` 先读取 `RouteGeoState`，再从实时 `outbounds.ListHandlers` 取 tag；运行时出站变更后可能混代，因此**请求扩展文件归属，允许修改 `native/xray-bridge/snapshot.go` 及必要的直接测试**。该文件不在现有卡面明确清单内，未经批准不修改。桥外围 mutex 不能代替固定核心真实读取路径的视图绑定。
5. 不引入 SetAdmission、新流门禁或新的 C ABI 符号；ABI v2 status 保持 296 字节。出站管理器与 view 的同步、handler 的引用计数/清理及错误码均须以固定源码取证，申请不是实现承诺。

## 4. 请求变更文件及依赖

契约变更须先由契约所有者审核、人类批准，且只改以下生成链：

1. `native/xray-bridge/core_control.proto`：新增上述 RPC 和消息，不改变现有 RPC 的字段编号。
2. `native/xray-bridge/core_control.pb.go`、`native/xray-bridge/core_control_grpc.pb.go`：按现有 proto.lock 记录的工具及参数生成。
3. `crates/plugin-xray/proto/descriptor.pb`：含 imports 的 descriptor 重新生成。
4. `crates/plugin-xray/proto.lock`：更新 proto、生成物、descriptor 的哈希、大小及方法清单；固定工具版本不自行升级。PC-07 不修改这些 proto 文件。

非契约实现按卡面限于 `native/xray-bridge/restricted_profile*.go`、`route_control.go`、`runtime*.go`、必要新增桥内文件、`tests/integration/bridge/` 和仅新增序号的 `upstream-patches/`；额外申请上节的 `snapshot.go` 及其直接测试，确切新增测试文件须在批准时确认。若发现其他必需现有文件不在批准范围，先补申请，不擅自修改。

`go.mod`/`go.sum` **默认不增加依赖**；目前尚未证明引入 `infra/conf` 的完整三平台依赖闭包可在基座离线通过。若只读构建发现缺少模块，停止并逐项另报包名、版本、用途、平台、直接/传递关系和锁文件影响，获批前不执行写回 modfile 的 tidy、不自行添加、不隐式下载。现有 PC-04b H1 对 Windows tun 的限制保持不变。

## 5. 验收计划与待批准事项

- 每项协议、传输、安全：启动 prepare 允许、本地受控服务端互通、未纳管变体拒绝且 active 不变，分别记录平台和组合；测试凭据仅用临时生成值，不使用真实节点/凭据。
- 同一校验函数覆盖启动与运行时；缺失 tag、保留出站删除/替换、首出站错误及未命中路由均有正反证据。运行时 publish、rollback、并发及资源生命周期证明单 epoch，含 Linux `-race`。
- PC-04/04b 全量回归；因 §3.1 更新 freedom 首出站旧夹具的范围逐项列明。Windows 原生 `CGO_ENABLED=0`、Linux WSL（含 `-race`）及 Android NDK 交叉构建均记录命令、包、用例、排除项与原因；临时路径用 `t.TempDir()`。对 `c3acc73..HEAD` 跑 Gitleaks；测试日志只存会话文件，不进仓库。
- 申请审核决策：① 上述合并 RPC 与 JSON 请求/完整快照语义；② mux 默认拒绝边界；③ `snapshot.go` 及必要直接测试的文件归属扩展；④ 契约文件生成链。依赖如有缺项，另行逐项申请。所有项获所需批准后才实施；不以本申请冒充批准记录。

## 6. 交接与挂起快照

- 当前已完成：认领事件已提交共享仓；任务 worktree 已从指定基座创建。本申请待审核；无项目代码或契约改动、无部署。
- 下一步：等待契约所有者和人类对 §5 作明确裁定；获批后复核卡面、文件归属与并发状态再动手。PC-07 可并行，但其桥 prepare/经桥互通证据仍待 PC-04c。
- 人类在本会话确认 PC-04c 当前未挂起。最新交接未提供规范要求的全量挂起快照；以下是认领入口留存的历史快照，**未验证仍为当前全量**，请交接维护方核实并补齐，不擅自挂起或解挂：

| 项目 | 任务 ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级 + 复跑 + 更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5～D-10 + 新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |
