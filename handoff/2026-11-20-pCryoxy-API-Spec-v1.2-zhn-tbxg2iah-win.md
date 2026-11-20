# pCryoxy 核心文件与通信接口契约 v1.2

- 项目: pCryoxy
- 版本: v1.2（完整继承 v1.1；增补 PC-02 Linux RuntimeDto 与兼容性裁定）
- 发布状态: 已发布 · 共享权威正文（后续维护正文）
- 发布: workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-20
- 发布记录与统一入口: `2026-11-19-pCryoxy任务认领入口-zhn-tbxg2iah-win.md`
- 演进关系: v1.0 首版 → v1.1（v1.0 全文 + §8）→ v1.2（v1.1 全文 + §9）；v1.2 保留原有命令、错误、DTO、事件、版本标识、文件归属和 G1～G5 约束，仅增补 Linux 平台公开字段与兼容性门禁。v1.0/v1.1 保留为历史基线。
- 权威性: 会话工作区同名源文件（`pCryoxy-API-Spec-v1.0.md`）为发布前历史快照；共享仓 v1.1 为上一版历史正文；二者均不再更新。
- 配套文件: `2026-11-20-pCryoxy-需求确认基线-v1.1-zhn-tbxg2iah-win.md`、`2026-11-20-pCryoxy-工程蓝图-v0.3-zhn-tbxg2iah-win.md`、`2026-11-20-pCryoxy-实施任务卡-v1.1-zhn-tbxg2iah-win.md`

日期：2026-11-20。适用任务：PC-00～PC-20；P1 卡仍不在本轮实施。依据用户 G1～G5 最终裁定及 v1.1 增补裁定。本文定义实施契约，不是已经存在的 SDK。所有签名、DTO 和桥扩展均是项目设计；官方 RPC 另行标明。无 SetAdmission，不引入第三方 TUN 默认依赖，不实现 P0 嵌套组。

## 1. 契约层级、进程与安全边界

```text
SolidJS(仅本地应用资源)
  → Tauri受限Commands/白名单DTO
  → 应用输入入口（语法/语义一次校验）
  → 领域期望态 + 单写者协调器
  → plugin-xray / core-updater / secure-store
  → 官方RPC受控适配 + pcryoxy.bridge.v1
  → 固定版本Xray + 完整RouteView快照
```

Windows：Tauri Rust组合根拥有调度器与vault，私有桥子进程执行核心。Android：`:proxy`服务拥有核心、Rust调度运行库及vault访问；UI进程仅是Tauri代理，使用本应用非导出的绑定服务转发请求。不能让两个进程各启动一个调度器。普通DTO可经Binder；秘密输入只在同UID、非导出、无日志的输入方法中短暂传递。JNI数据转换是边界协议解码，不在每个内部模块重新做完整业务校验。

安全目标是**敏感输入只能向受信任后端写入，后端响应/事件/日志/AI不得泄漏秘密**。用户在UI粘贴链接或密码时，秘密不可避免短暂存在WebView内存；不承诺被控制的设备、调试器、屏幕录制或任意同用户恶意进程也“绝对零泄漏”。不允许以这个边界为由在常态存储/遥测泄漏。

### 1.1 版本与线性化标识

- `apiVersion`：IPC schema版本，首版1。
- `requestId`：一次用户意图的UUID；同一会话相同ID不得执行两次。重用ID但内容不同返回RequestIdConflict；校验摘要使用本地键控摘要，不存原秘密payload。
- `configRevision`：用户期望配置版本（十进制字符串）。健康变化不增加它。
- `instanceId`：核心进程启动随机ID；进程更换必变，不能使用PID冒充。
- `epoch`：该实例已发布完整控制快照的单调版本，回滚也递增，不倒退。
- `streamId/sequence`：本次前端事件流实例和单调序号；UI重连不得把旧sequence当连续。
- `operationId`：后台操作记录ID；`Accepted`不等于成功。结果不明时查操作，不盲目重试破坏性RPC。

JS不可精确表示的u64全部编码为十进制字符串；枚举小写snake_case；时间为RFC3339 UTC；延迟毫秒可用有限非负number，缺样本为null，不能用0冒充未知。

## 2. IR、校验和秘密接口

蓝图的Node、ProxyGroup、RoutingRule字段保留；补充以下真实可实现约束：

- `ValidatedSnapshot`字段私有，只由一个入口函数构造。构造器必须在core-ir的受控入口实现或同crate验证模块中，**不能让外部parser因Rust可见性问题使用unsafe或公开unchecked构造器**。
- parser产生`ParsedChange`（尚未认证语义），`core_ir::validate_change(current, change) -> ValidatedChange`执行完整语义一次校验；ValidatedChange携带候选快照与受影响ID。crypto指纹规范化可在parser纯函数完成；引用和组校验归同一入口。
- `Member::Group`仅内部预留，P0所有输入包括JSON手工构造都返回NestedGroupNotSupported。GroupDraftDto只包含nodeIds。
- IR中的NodeState是内存状态，不把隔离计数当永久事实直接重放；持久化存储只保存配置和必要last-good引用，重启重新探测。
- HMAC凭据标识只用于内部去重。Fingerprint与SecretRef不返回前端、AI或日志。
- 八字段长度编码包括版本域，完整语义冲突返回FingerprintConflict；冲突候选保存在后端短期内存，前端只拿conflictId。P0可选择保留原节点或取消候选；替换需明确确认且提交新revision，绝不默认覆盖。保留两个相同八字段但不同语义节点的双重身份方案不在P0静默实现。

设计签名（具体生命周期及错误enum由PC-01/02落实）：

```rust
// core-ir/src/validated.rs
pub fn validate_change(
    current: &Snapshot, change: ParsedChange
) -> Result<ValidatedChange, InputError>;

// protocol-parser/src/canonical.rs
pub fn fingerprint(key: &CanonicalNodeKey) -> Fingerprint;
pub fn compare_semantics(a: &ParsedNode, b: &ParsedNode) -> SemanticComparison;

// plugin-sdk/src/plan.rs
pub struct VersionStamp {
    pub instance_id: InstanceId,
    pub epoch: u64,
    pub config_revision: u64,
}
pub struct ApplyReceipt { pub stamp: VersionStamp, pub effect: ApplyEffect }
pub enum ApplyEffect { Applied, Unchanged, RolledBack }
```

`SecretStore::with_secret`只供本地受信任核心生成器、协议解析器使用，不作为IPC接口。秘密类型没有Debug/Serialize泛用派生；异步使用时秘密只存在必要调用局部，不跨await长期借用vault锁，不把整个vault锁住等待网络。

## 3. Tauri Commands与SolidJS DTO

### 3.1 公共类型（TypeScript契约）

```ts
export type Id = string;
export type U64 = string;
export type Protocol = "vless" | "vmess" | "trojan" | "shadowsocks"
  | "hysteria2" | "wireguard" | "masque";
export type Health = "unknown" | "active" | "degraded" | "isolated" | "recovering";
export type Strategy = "failover" | "lowest_latency" | "round_robin";
export type OperationState = "queued" | "running" | "awaiting_user"
  | "applied" | "failed" | "rolled_back" | "cancelled" | "unknown";
export interface Stamp {
  configRevision: U64;
  instanceId: Id | null;
  epoch: U64 | null;
}
export interface Request<T> {
  apiVersion: 1;
  requestId: Id;
  expectedRevision: U64 | null; // 所有配置写操作必填；纯查询null
  payload: T;
}
export type Result<T> =
  | { ok: true; value: T; stamp: Stamp }
  | { ok: false; error: ApiError; stamp: Stamp };
export interface ApiError {
  code: ErrorCode;
  messageKey: string; // 固定i18n键，不是第三方错误原文
  field: string | null; // schema路径，如members，不含输入值
  retryable: boolean;
  operationId: Id | null;
}
export interface Accepted { operationId: Id }
export interface OperationDto {
  id: Id;
  kind: "import" | "subscription_refresh" | "config_apply" | "runtime"
    | "probe" | "geo_update" | "core_update" | "secret_replace";
  state: OperationState;
  progress: number | null; // 0..1，仅真实可测进度
  error: ApiError | null;
  stamp: Stamp;
}
export interface NodeViewDto {
  id: Id;
  label: string; // 产品生成的安全别名，不回显原始分享链接/订阅注释
  protocol: Protocol;
  endpointDisplay: string; // 脱敏host:port，不含userinfo/path/query
  hasCredentials: boolean;
  health: Health;
  latencyMs: number | null;
}
export interface GroupDto {
  id: Id; label: string; strategy: Strategy; nodeIds: Id[];
  toleranceMs: number; selectedNodeId: Id | null;
}
export interface SubscriptionDto {
  id: Id; label: string; enabled: boolean; intervalSeconds: number;
  lastRefreshAt: string | null; nodeCount: number;
} // 无URL、token、header或可反解vault句柄
export interface RuntimeDto {
  platform: "windows" | "android";
  phase: "stopped" | "starting" | "ready" | "replaying" | "failed";
  connectionMode: "system_proxy" | "local_proxy" | "vpn";
  stamp: Stamp;
  coreVersion: string | null; bridgeVersion: string | null;
  geoVersion: string | null;
  syncState: "in_sync" | "pending" | "failed" | "disk_memory_diverged";
}
```

UI需显示用户命名时，提供本地专用label编辑，经入口长度和控制字符校验；原始订阅label可能带秘密，默认不继承。后端不能保证用户主动把密码写进任意名称也神奇识别出来，所以用户自由label仅本地显示，不进入日志/AI/通用遥测。NodeViewDto的默认label由应用生成，后续label扩展不得绕过投影。

### 3.2 分流DTO与配置请求

```ts
export type DomainDto =
  | { kind: "exact" | "suffix" | "keyword"; value: string }
  | { kind: "geosite"; tag: string };
export type IpDto = { kind: "cidr"; value: string } | { kind: "geoip"; tag: string };
export type ActionDto = { kind: "direct" | "reject" }
  | { kind: "node"; nodeId: Id } | { kind: "group"; groupId: Id };
export interface RuleDto {
  id: Id; enabled: boolean;
  domains: DomainDto[]; ips: IpDto[];
  ports: { first: number; last: number }[];
  networks: ("tcp" | "udp")[];
  sniff: ("http" | "tls" | "quic" | "bittorrent")[];
  action: ActionDto;
}
export interface GroupDraftDto {
  id: Id | null; label: string; strategy: Strategy;
  nodeIds: Id[]; toleranceMs: number;
}
export interface HealthSettingsDto {
  intervalMs: number; timeoutMs: number; concurrency: number;
  failuresToIsolate: number; successesToRecover: number;
}
export interface ProbeRequest { nodeIds: Id[] } // 空数组只代表空选择，不暗指全部
export interface ReplaceRules { rules: RuleDto[] } // 完整序列；空表仍由系统生成默认拒绝
export interface RuntimeRequest { action: "start" | "stop"; mode: RuntimeDto["connectionMode"] }
```

域名/IP规则是用户本地配置，允许本地UI查看编辑，但不等于可发送给AI；AI默认只获得规则数量和动作统计。规则输入不接受原始Xray JSON或任意script，避免隐藏秘密字段进入通用回显。高级协议配置使用受限协议表单/本地导入，不开放任意JSON反射到前端。

### 3.3 写入秘密：唯一例外方向

```ts
// 这些结构只允许Request输入，绝不能用于Response/Event。
export type SecretInput =
  | { kind: "share_links"; text: string }
  | { kind: "subscription_create"; url: string }
  | { kind: "subscription_url_replace"; subscriptionId: Id; url: string }
  | { kind: "node_credentials"; nodeId: Id; value: string };
export interface ImportRequest { input: SecretInput }
export interface SecretReplaceRequest {
  nodeId: Id;
  value: string; // 协议相应凭据编码，在后端解释；不返回旧值
}
export interface ConflictDto {
  id: Id; existingNodeId: Id;
  differingFields: string[]; // 白名单字段名，不含值
}
export interface ResolveConflict {
  conflictId: Id;
  resolution: "keep_existing" | "replace_confirmed" | "cancel";
  confirmationId: Id | null;
}
export type ConfirmationRequest =
  | { action: "remove_nodes"; nodeIds: Id[] }
  | { action: "remove_group"; groupId: Id }
  | { action: "replace_conflict"; conflictId: Id }
  | { action: "apply_update"; offerId: Id }
  | { action: "rollback_core"; versionId: Id };
```

前端敏感输入保持组件局部、禁止store持久化/console/error telemetry/URL query/localStorage/sessionStorage；提交完成或取消清空引用。清空JS引用不等于内存即时擦除，不作虚假安全承诺。原始body进入Rust后不打印Tauri参数，不把它混在operation记录里。共享链接/订阅URL不能出现在返回message、错误details、Crash report或AI上下文。不存在get_secret、export_raw_config、get_subscription_url等命令。

凭据编辑采用“替换但不回读”；如用户不想让WebView暂存秘密，可通过原生文件选择器导入，前端仅传importTicket，由后端读取。文件票据绑定窗口、用途和单次使用，不允许前端传任意绝对路径访问磁盘。含秘密导出不纳入本轮P0命令；未来须单独确认加密导出格式和原生授权，不能为了补接口开放明文下载。

### 3.4 完整命令注册表（P0）

统一调用：`invoke<Result<T>>(command, { request })`，Rust接收一个`request`参数；命令名称snake_case，JSON字段camelCase。只有下列命令在capabilities授权给本地主窗口，远程内容窗口不授权。

| 命令 | payload | 响应value | 权限/副作用 |
|---|---|---|---|
| app_snapshot | `{}` | AppSnapshotDto | 只读安全投影 |
| nodes_list | `{cursor: string|null, limit:number}` | `{items:NodeViewDto[], nextCursor:string|null}` | 不回全IR |
| import_submit | ImportRequest | Accepted | 一次敏感写入，期望revision必填 |
| import_from_file | `{importTicket:Id}` | Accepted | 原生选文件生成票据，只读导入 |
| conflicts_list | `{operationId:Id}` | `{items:ConflictDto[]}` | 不回冲突秘密值 |
| conflict_resolve | ResolveConflict | Accepted | replace需后端原生确认令牌 |
| node_credentials_replace | SecretReplaceRequest | Accepted | 不回旧凭据 |
| nodes_remove | `{nodeIds:Id[], confirmationId:Id}` | Accepted | 有引用时返回Referenced，不偷偷改组 |
| subscriptions_list | `{}` | `{items:SubscriptionDto[]}` | 无URL |
| subscription_settings_set | `{id:Id, enabled:boolean, intervalSeconds:number}` | Accepted | 不含URL；URL替换用import_submit的subscription_url_replace分支，明确subscriptionId，不重复造接口 |
| subscription_refresh | `{id:Id}` | Accepted | 用户触发；定时任务走同领域服务 |
| groups_list | `{}` | `{items:GroupDto[]}` | P0无嵌套 |
| group_upsert | GroupDraftDto | Accepted | 完整候选一次验证 |
| group_remove | `{id:Id, confirmationId:Id}` | Accepted | 路由仍引用时拒绝 |
| rules_get | `{}` | `{rules:RuleDto[]}` | 本地配置专用，不进AI |
| rules_replace | ReplaceRules | Accepted | 完整序列、预检、桥原子发布 |
| health_settings_set | HealthSettingsDto | Accepted | 不允许无效周期/并发；G5为默认 |
| probe_start | ProbeRequest | Accepted | 轻量探测，无自动吞吐测速 |
| runtime_set | RuntimeRequest | Accepted | Android启动需系统授权；停止是用户意图，不是热更门禁 |
| updates_check | `{component:"core"|"geo"}` | `{offers:UpdateOfferDto[]}` | 用户查询元数据；不自动下载Geo |
| update_apply | `{offerId:Id, confirmationId:Id}` | Accepted | core需原生确认；Geo用户点按触发，可使用同确认流程 |
| core_rollback | `{versionId:Id, confirmationId:Id}` | Accepted | Windows最近兼容旧产物；Android返回repair_required/安装修复APK流程，非偷偷降级 |
| operation_get | `{operationId:Id}` | OperationDto | 超时后的真实状态查询 |
| operation_cancel | `{operationId:Id}` | OperationDto | 下载/解析未提交可取消；提交中返回CannotCancel，不假装撤销 |
| confirmation_open | ConfirmationRequest | `{confirmationId:Id|null}` | 必须后端原生对话框同意后才返回一次性令牌；取消null |
| events_open | `{}` | EventSubscriptionDto | 建流且返回一致快照基线 |
| events_close | `{streamId:Id}` | `{closed:boolean}` | 清理订阅，不停止代理 |

ConfirmationRequest的判别联合明确携带实际操作对象，批量nodeIds由后端去重规范化后计算列表摘要，并在原生弹窗显示对应安全别名与数量。确认令牌绑定动作、资源ID/列表摘要、configRevision、窗口身份；请求不能用确认删除A的令牌删除B。纯UI弹窗回传`confirmed:true`不算可信确认。硬件或OS授权弹窗依平台正常流程，不能自动点击。

AppSnapshotDto包含`apiVersion, stamp, runtime, healthSettings, nodeCount, groups, geoVersion, operations`的安全投影，不包含整份nodes/rules/secret；大列表分页调用。节点删除采用整批事务；成员被订阅删除/更新时必须先按预设保留引用节点或报冲突，不能造成悬空引用，具体订阅差异策略由PC-06实现报告明确。

UpdateOfferDto：`id, component, version, bridgeVersion|null, platform, abi, downloadBytes:U64, compatible:boolean, reasonCode|null`。不包含带token的下载URL或任意shell参数；offer由后端检查得到，apply只接受已知offerId。GeoCheck可取网络元数据但不安装数据；自动下载不存在。核心自动检查只查元数据，仍用户确认安装。

### 3.5 错误合同

ErrorCode固定集合：`invalid_input`、`unsupported_capability`、`nested_group_not_supported`、`fingerprint_conflict`、`referenced`、`revision_conflict`、`request_id_conflict`、`permission_denied`、`confirmation_required`、`cancelled`、`cannot_cancel`、`secret_unavailable`、`core_unavailable`、`deadline_unknown`、`preflight_failed`、`geo_tag_missing`、`integrity_failed`、`incompatible_version`、`protect_failed`、`repair_required`、`disk_memory_diverged`、`operation_not_found`、`internal_error`。

Rust→Tauri始终返回Result枚举，不把任意anyhow/String错误交给JS。网络原始URL、protobuf配置、secret bytes、JNI原文不进入error.field。业务错误保留messageKey可定位原因，但可诊断性不依赖输出秘密。DeadlineUnknown是待对账，不是自动失败重试标志。

### 3.6 事件与SolidJS刷新

```ts
export type EventPayload =
  | { type: "runtime_changed"; runtime: RuntimeDto }
  | { type: "node_health_batch"; items: { nodeId:Id; health:Health; latencyMs:number|null }[] }
  | { type: "traffic"; uplinkBytes:U64; downlinkBytes:U64; sampleAt:string }
  | { type: "operation_changed"; operation:OperationDto }
  | { type: "configuration_changed"; stamp:Stamp }
  | { type: "resync_required" };
export interface AppEvent {
  apiVersion: 1; streamId:Id; sequence:U64; stamp:Stamp;
  payload: EventPayload;
}
export interface EventSubscriptionDto {
  streamId:Id; sequence:U64; snapshot:AppSnapshotDto;
}
```

固定事件名 `pcryoxy://event`，只向获授权的本地窗口发送。先建立前端listener再调用events_open；后端串行建立stream并返回该时刻一致snapshot/sequence，前端暂存早到事件，丢弃小于等于snapshot序号的事件，再依次应用。队列有界；遥测合并但序号针对实际发送帧增长。非遥测事件不能静默丢失，溢出发resync_required或明确关闭stream，前端重开获得快照。

遥测初始合并间隔250ms为实现提案，不作为已批准性能指标；配置/操作完成及时发送。SolidJS用batch提交一帧，不为每个节点多次invoke。事件到达早于Accepted响应时按operationId关联，不能“响应覆盖更新后的事件”。流量为同instance累计计数，不以采样差值作为永久总账；instance变化重置基线。

## 4. 逐文件API Spec与所有权

本节与任务卡共同定义独占写入。表中函数为实施契约，避免给每个文件再造Trait。子函数只在逻辑复杂或复用时提取。

| 文件/所有者卡 | 入口→输出 | 不变量/失败语义 |
|---|---|---|
| core-ir/node.rs · PC-01 | Node、ProtocolOptions、CanonicalNodeKey | SecretRef与Fingerprint不对外序列化；不含Xray字段名泄漏到通用IR |
| core-ir/group.rs · PC-01 | ProxyGroup、Member、Strategy | P0不允许Group成员，类型保留不等于允许构造有效快照 |
| core-ir/routing.rs · PC-01 | RoutingRule、Match、Action | 字段内OR/字段间AND，Vec顺序唯一，类型化CIDR/端口 |
| core-ir/validated.rs · PC-01 | validate_change → ValidatedChange | 唯一语义校验入口；私有有效类型构造；失败不发布任何新revision |
| plugin-sdk/error.rs · PC-02 | 内部错误→公开ErrorCode映射 | 区分Rejected、结果未知、部分持久化，不带外部原文 |
| plugin-sdk/plan.rs · PC-02 | ValidatedChange→RoutePlan/OutboundDelta | 生成受控tag，明确Replace/Append，实例与epoch不可混用 |
| plugin-sdk/lib.rs · PC-02 | ProxyCorePlugin/SecretStore/VersionStamp | 静态泛型，默认不引入async-trait/运行时插件loader |
| protocol-parser/canonical.rs · PC-06 | normalize、fingerprint、compare_semantics | 版本化长度编码、无DNS反查、保持path大小写；相同8字段差异必冲突 |
| protocol-parser/lib.rs · PC-06 | parse(bytes)→ParsedChange/Conflict | 链接和内容为敏感输入，只返回安全错误与行索引 |
| protocol-parser/validate.rs · PC-06 | 输入形状解码→调用core_ir校验 | 不重复业务规则，不另造第二套验证 |
| protocol-parser/subscription.rs · PC-06 | refresh(SubscriptionId)→ImportOperation | 后端取URL；内容在私有缓冲；失败保留旧节点/引用 |
| secure-store/lib.rs · PC-03 | put/with_secret/delete_staged/commit_staged | 不提供通用IPC getter；失败不把半份vault与IR引用提交 |
| secure-store/windows.rs · PC-03 | 当前用户Credential Manager密钥→AEAD vault | 不用Enterprise漫游；大秘密不塞单条Blob |
| secure-store/android.rs、SecretStore.kt · PC-03 | SecretRef→Keystore加解密 | alias稳定、不默认认证弹窗；无密钥不覆盖旧数据 |
| secure-store/redact.rs · PC-03 | 领域事件→SafeEvent/SafeContext | 白名单投影，不是对完整JSON做正则替换 |
| plugin-xray/config.rs · PC-07 | ValidatedSnapshot+SecretStore→CoreConfig/OutboundSpec | 明文仅局部；固定版本字段；输入条件不扩大匹配 |
| plugin-xray/protocols.rs · PC-07 | Typed protocol→JSON/protobuf | 每协议必须有可验证映射，无通用raw JSON透传逃逸 |
| plugin-xray/capabilities.rs · PC-07 | 锁定版本/平台→CapabilitySet | 不支持返回显式错误，不能默丢字段 |
| plugin-xray/rpc.rs · PC-08 | official requests + bridge requests→ApplyReceipt | 单写者；metadata鉴权；超时查询operation，不盲重试 |
| plugin-xray/replay.rs · PC-08 | desired + last-good→新instance重放 | 旧applied不可复用；完整规则发布前填override；RR空override |
| engine-scheduler/health.rs · PC-09 | (State,ProbeOutcome)→StateTransition | 纯函数，无网络无IPC；取消不增加失败计数 |
| engine-scheduler/select.rs · PC-09 | 健康快照+组→DesiredTarget | RR返回NativeRoundRobin，不在Rust轮询；最低延迟才50ms |
| engine-scheduler/probe.rs · PC-09 | 节点ID/受控probe句柄→ProbeOutcome | 真204指定出口；不直连测速偷换链路；并发16 |
| engine-scheduler/reconcile.rs · PC-09 | DesiredState+AppliedState→串行计划 | 先add赢家再override后remove；不重启作常规切换 |
| core-updater/manifest.rs · PC-12 | 外部manifest→ValidatedOffer | ABI/hash/源版本一次验证，可信来源不等于摘要本身 |
| core-updater/geo.rs · PC-12 | offer→staging/preflight/ReloadGeo/commit | 用户手动；version目录不变；磁盘内存分歧可观测 |
| core-updater/windows.rs · PC-13 | upgrade/rollback→Operation | 保留桥能力；不覆盖运行中exe；失败恢复旧配置核心 |
| core-updater/android.rs、PackageUpdate.kt · PC-13 | offer→系统安装器/repair | 不静默安装，不低versionCode降级，不下载执行so |
| core-updater/compatibility.rs · PC-13 | (app,bridge,core,geo,IR)→CompatibleProjection | 不破坏性删除不兼容字段；不兼容时阻止更新 |
| plugin-sdk/src/public_dto.rs · PC-02 | Rust公开DTO源→ui/src/api/generated.ts | 只公开类型，无完整Node/vault/敏感Response；Tauri仅作路由适配 |
| tauri-app/commands.rs · PC-14 | Request<T>→Result<T>/Accepted | 白名单路由到领域入口，不直接组装核心JSON |
| tauri-app/state.rs · PC-14 | 组合根/服务连接→状态句柄 | Windows一个actor；Android代理到:proxy，禁止重复调度 |
| tauri-app/operations.rs · PC-14 | requestId→状态/去重/确认令牌 | 只记安全元数据；确认绑定资源及revision；未知不假失败 |
| tauri-app/projection.rs · PC-14 | 私有状态→本地UI DTO | 枚举/结构白名单，秘密不能通过错误旁路 |
| tauri-app/events.rs · PC-14 | 安全状态变化→有序事件流 | bounded队列、遥测合并、非遥测不静默丢失 |
| tauri-app/platform/windows.rs · PC-10 | 用户代理选择→系统代理变更/恢复 | 仅恢复仍属本应用的值；不覆盖用户后改 |
| ui/api/client.ts · PC-15 | typed invoke封装→Result | 不console参数，不通用retry写操作，不暴露任意command字符串 |
| ui/stores/telemetry.ts · PC-15 | AppEvent→Signals batch | stream/seq检查、重同步；不收SecretInput |
| ui/routes/Nodes.tsx · PC-15 | 安全列表/敏感输入组件 | 输入只局部，完成清空；编辑不回读凭据 |
| ui/routes/Groups.tsx · PC-15 | GroupDraftDto→upsert | 无嵌套UI，无Rust轮询实现 |
| ui/routes/Routing.tsx · PC-15 | RuleDto序列→rules_replace | 拖拽只改序列，等待实际applied回执 |
| ui/routes/Updates.tsx · PC-15 | offer/operation→用户动作 | 不接受任意URL；Geo只手动；回退区分平台 |
| ui/routes/Settings.tsx · PC-15 | HealthSettings/runtime设置 | 默认G5，修改走后端；OS授权真实呈现 |
| plugin-ai-agent/{lib,safe_context,tools}.rs · P1 | SafeContext→ToolProposal→用户确认 | P0不执行；无SecretStore权限、无全量Node序列化 |

## 8. v1.1 新增传输与兼容性契约

本节是对本文 v1.0 全部 §1～§4 的增量，不替代、不删减原命令、错误、DTO、事件、版本标识、逐文件所有权或 G1～G5 约束。v1.1 的完整输入是：**v1.0 全文 + 本节**。

### 8.1 管理面与核心版本隔离

公开管理 API 的 `apiVersion` 仍为 `1`；核心和桥另行携带 `coreVersion`、`coreCommit`、`bridgeVersion`、`bridgeProtocol`、`platform`、`arch` 与 `libc`（Linux）能力摘要。客户端不得由 `coreVersion` 推断已支持的协议；启动握手必须返回能力矩阵和不兼容原因。任何核心/桥/API 不匹配必须返回既有错误集合中的 `incompatible_version`，不得伪造就绪。

### 8.2 公共 DTO 新归属与统一命令入口

v1.1 起，公开 DTO 的唯一 Rust 源文件从 `crates/tauri-app/src/dto.rs` 移至：

- `crates/plugin-sdk/src/public_dto.rs`：跨平台公开请求、响应、错误投影、操作票据、事件 payload 和 `AppSnapshotDto` 的 Rust 源；不含密钥、SecretRef、完整 Node、原始核心 JSON。
- `ui/src/api/generated.ts`：由 `public_dto.rs` 白名单生成的 TypeScript 类型，只读生成物，禁止手改。
- `crates/tauri-app/src/commands.rs`：仅保留 Tauri IPC 路由适配，不再定义公共 DTO。
- `crates/daemon-server/src/http.rs`：REST 路由适配，不重新定义 DTO。
- `crates/daemon-server/src/ws.rs`：WebSocket 事件与快照适配，不重新定义事件 payload。
- `ui/src/api/client.ts`、`tauri.ts`、`http.ts`、`websocket.ts`：同一套前端业务接口的两种传输适配，不复制业务模型。

Tauri IPC、HTTP REST 与 WebSocket 事件都进入同一命令处理器，复用原 v1.0 的 `requestId`、`expectedRevision`、`operationId`、错误码、SafeEvent 与快照重同步。HTTP/WS 路径不得直接调用官方 Xray RPC，不得读取 vault 或原始核心配置。

### 8.3 REST/WS 映射

- REST 默认只在 `127.0.0.1` 提供；非回环监听必须在启动时校验管理员 Token，缺失即拒绝启动。
- REST 使用 v1.0 同源公开 DTO；Token 不得出现在 URL、响应、日志、遥测或 `dist/`。写操作要求 `requestId` 和适用的 `expectedRevision`。
- WebSocket 只发送原 v1.0 `AppEvent`/`SafeEvent`，包含 `streamId` 与单调 `sequence`；断点或重连先请求 `AppSnapshotDto`，不补发秘密或原始节点链接。
- Tauri IPC 与 REST 对同一写请求使用相同幂等语义，重复 `requestId` 返回既有操作结果或既有 `request_id_conflict`，不得重复产生副作用。

### 8.4 服务生命周期

daemon 启停、服务注册、systemd/Windows SCM 状态和核心 ready 状态分开报告。GUI 关闭不等于 daemon 停止；服务重启后的 `instanceId` 必须变化，`epoch` 单调递增；配置错误返回可诊断状态，禁止无限重启伪装可用。

### 8.5 Linux/Windows 存储与权限

Linux 服务使用专属账户和 `0600` 密钥文件或 Secret Service；Windows Service 以实际服务身份访问 Credential Manager/ACL，不能默认读取交互用户 vault。控制面 Token 与节点凭据分离存放。权限不足、服务身份不匹配或密钥不可读都返回明确错误，不回退为直连。

### 8.6 版本适配验收

每个平台/架构/libc 组合须登记核心资产、桥产物、协议版本及 SHA-256；仅有上游核心资产不等于桥产物已验证。PC-17/04/07/19/20/13 分别提供构建、桥、配置/互通、服务/TUN、管理面和升级回退证据。无 Linux 资产或实测证据时，Linux 只能标为 `planned`/`blocked`，不能写作 `supported`。

`lib.rs`仅导出已审边界，`main.rs`只做启动和错误码顶层处理；generated文件全部禁止手补。平台manifest/权限改生成源，不直接修改Tauri gen产物。

## 5. 薄Go桥与官方RPC内部合同

### 5.1 数据面发布不是“桥外加锁”

固定上游源码需要最小可审补丁：

| 接入点 | 改动责任 |
|---|---|
| app/router/router.go PickRoute / ReloadRules | PickRoute开始固定完整RouteView；重载分prepare/publish；不对整段DNS持读锁 |
| app/router/config.go Rule条件 / balancing.go override | 绑定view内Geo与override；禁止在旧rules中读live新状态；不复制含mutex的Balancer |
| common/geodata/{ip_registry,domain_registry}.go | 两类候选共同准备；发布完整view，不顺序Reload部分生效 |
| app/router/command/command.go | 官方和兼容服务名都进入统一提交器，不允许旁路写入 |
| app/dns相关Geo消费者 | 固定相应GeoView；未纳管消费者不得宣称全实例一致 |
| proxy/tun/tun_android.go | 只在已证明的FD所有权问题处最小修补，不重写TUN栈 |
| transport/internet/system_dialer.go及实际绕行点 | protect失败关闭本次拨号；仅补经过测试证实的漏路径 |

核心结构（项目新增设计，不是官方API）：

```go
type RouteView struct {
    Epoch uint64
    Revision uint64
    GeoVersion string
    // 规则、Geo状态、override按版本不可变；RR内部游标独立并发安全。
    Routes PreparedRoutes
    Geo PreparedGeo
    Overrides ImmutableOverrides
}
// 使用受保护引用或atomic.Pointer固定view；Go GC保证内存存活，
// webhook等需Close的资源另有最小引用寿命管理，不能发布后立即关闭。
func (c *Controller) AcquireView() *RouteView
func (c *Controller) PrepareRoutes(req ReplaceRoutesRequest) (*RouteView, error)
func (c *Controller) PrepareGeo(req ReloadGeoRequest) (*RouteView, error)
func (c *Controller) Publish(expected uint64, next *RouteView) (CommitReceipt, error)
```

写管理队列串行；构建不持发布锁，读取过程中已固定的view不变；发布短锁内核对instance/epoch并切一个指针。SetOverride同样由提交器发布带新override的view；全量规则替换从权威集合重放override到未发布的balancer，不出现新流看到默认策略的窗口。删除仍有override的组必须显式删除其override或拒绝，不丢弃配置。

RR健康池使用官方出站增删及selector动态缓存，不把outbound所有网络连接纳入大快照复制；在途先选tag后被移除的窗口按已批准边界允许连接失败，不把RouteView一致性扩大成整个数据面的事务零损。

### 5.2 桥方法与官方方法共存

官方方法全名不变：

- `/xray.app.router.command.RoutingService/OverrideBalancerTarget`：`balancerTag,target`；空target启用原生RR。受控构建内部统一提交并保留权威override。
- `.../AddRule`：`config:TypedMessage,shouldAppend`；全量替换在候选中恢复override。
- `.../RemoveRule`：`ruleTag`；只删除规则，不顺手删组。
- `/xray.app.proxyman.command.HandlerService/AddOutbound`：`outbound`；对应sender/proxy TypedMessage。
- `.../RemoveOutbound`：`tag`；sys/reject与sys/direct禁止由应用动态池路径删除。

TypedMessage.type为protobuf FullName，value为编码bytes。固定proto生成，不用任意JSON/Any URL替代。官方请求没有expectedEpoch字段时，通过同一受信任客户端写队列和服务端提交器串行，RPC metadata携带operationId和预期instance；不能假装更改官方proto字段。

项目桥服务：`pcryoxy.bridge.v1.Control`，仅后端可调用：

| 方法 | 输入 | 输出与成功语义 |
|---|---|---|
| QueryState | instanceId可空 | instanceId、epoch、revision、geoVersion、bridge/core版本、能力位、受控outbound tag清单摘要 |
| ReplaceRoutes | OpHeader、typed router config、完整desiredOverrides | CommitReceipt；完整候选已一次发布 |
| ReloadGeo | OpHeader、assetVersionId、snapshotRevision | CommitReceipt；两类Geo及绑定引用已生效 |
| Rollback | OpHeader、retainedVersionId | 新epoch的CommitReceipt，引用保留内存view，不从磁盘重建 |
| QueryOperation | operationId | not_seen/running/applied/failed/rolled_back/unknown及receipt |
| ReleaseRollbackPoint | retainedVersionId | 仅持久化成功且不再需回滚时释放管理持有引用，在途读者仍保留 |

`OpHeader={operationId,instanceId,expectedEpoch}`。RetainedVersionId/assetVersionId是后端注册的版本句柄，不是前端可传的任意路径。ReloadGeo版本对应固定资产根，桥同进程禁止临时全局setenv切到staging。预检另进程；运行时构建使用显式版本根factory。

`CommitReceipt={instanceId,epoch,revision,geoVersion,retainedVersionId,effect}`；prepare失败返回NotCommitted且active不变，expectedEpoch不符返回Conflict而非覆盖。epoch回滚不倒退。操作表只需本实例有界记录，进程丢失后用desired和last-good重建，不声称无限期exactly-once。

Windows使用仅当前用户可访问的命名管道（gRPC over自定义transport）连接受控桥；Android同进程库/同UID私有Unix socket，不把控制token暴露WebView。若选TCP回环作为过渡测试，只能测试环境，记录同用户访问风险，不宣称达到生产隔离；正式实现传输选择在PC-04/10验证，不安装新代理服务。

无SetAdmission/暂停新流RPC。管理调用鉴权失败拒绝的是管理写入，不影响业务新流。正常发布短锁等待不等于零等待；不持锁下载/解析/DNS/webhook关闭。

### 5.3 Geo磁盘与内存提交

更新器单写队列持有Geo事务期间的配置版本；源码prepare后若configRevision变化则拒绝/重建候选，不用旧规则验证结果给新规则包担保。

1. 手动下载候选不可变目录、压缩与解压摘要、完整标签预检。
2. 写小型恢复记录：旧/新资产版本、对应IR revision、operationId，不含配置秘密。
3. ReloadGeo构建并发布，返回保留旧view句柄。
4. 原子替换active manifest、fsync按平台实现、标记last-good；成功后释放旧回滚持有引用，仍保留上个磁盘版本。
5. 持久化失败时Rollback旧view并恢复旧manifest；若磁盘仍失败，明示disk_memory_diverged、当前实际版本，不停止listener、不无限持锁。后续操作受管理状态约束，用户仍可使用代理。
6. 崩溃重启读取完成提交的manifest；未完成记录选最后完整last-good并重新预检/重放，不能相信半写指针。恢复不了就报告核心未就绪，不能伪造Geo已生效。

保留旧matcher/factory/规则/override引用才叫内存回滚，保留DAT文件不等价。正常prepare失败根本不需要“先破坏再恢复”。

## 6. Android核心文件、FD与protect合同

| 文件 | 方法/职责 | 边界 |
|---|---|---|
| ProxyVpnService.kt | startVpn(options)、stopVpn、onRevoke | :proxy进程建立TUN，持有PFD；前台通知；停止按明确顺序关闭 |
| CoreBridge.kt | start(configHandle,tunFd)、stop、preflight(assetVersion)、protect回调 | 句柄均内部，不把core JSON交WebView |
| ProxyServiceClient.kt | bind、request、observe、unbind | 同UID非导出服务，UI消失不自动停核心 |
| ProxyServiceContract.kt | DTO转发/operation事件 | 仅安全DTO回UI；秘密请求单向不回显 |
| android_tun.go | 校验FD、设置本进程环境、调用原生tun | xray.tun.fd优先于XRAY_TUN_FD，冲突清理；无效FD在调用前拒绝 |
| android_protect.go | registerOnce、RawConn.Control同步回调 | 不能关借用FD；false返回拨号失败，回调不等待UI线程 |
| upstream FD补丁 | 先dup再设置/管理自有副本 | 错误只能close自有副本，PFD仍归Kotlin；不得出现close复用FD |

生产约束：Builder配置地址/路由/DNS，由系统创建真实fd。默认TUN数据面使用Xray原生实现，不经额外SOCKS协议层；业务SOCKS可以用于桌面和隔离探测，不等于Android必须TUN-to-SOCKS。

所有启用组合必须审计物理socket创建路径：默认TCP/UDP dialer、DNS客户端、bootstrap、DoH/DoQ、SRV/TXT、FinalMask/QUIC等。源码存在controller不等于所有路径都调用它。必要控制点补丁须给复现测试，不能以“改用tun-adapter”解决核心自身绕过protect的问题。无法满足的必要组合标明不支持和阻断验收，需用户决定是否降级，不能主动删需求。

## 7. 生成物、测试和接口变更门禁

- proto源：固定上游文件＋项目core_control.proto；TS源：`crates/plugin-sdk/src/public_dto.rs`白名单。生成器版本及源摘要写锁文件，带GENERATED说明，禁手改生成输出。
- DTO schema变更由PC-02所有者维护；破坏性修改升apiVersion并更新Rust/TS/fixture，不让前后端分别猜字段。
- 快照提交/重放/超时查询用真实核心集成测试；安全用真实Tauri invoke和捕获日志/事件/网络请求验明秘密不外流。通用单元测试不替代Android真机protect和签名APK升级。
- PC-04先通过慢DNS、并发路由/override/Geo、内存旧view恢复和管理旁路测试；go race之外明确断言一次route单epoch。再让其他卡依赖桥能力。
- G5已批准默认不重复问；最近3成功样本/连续两轮改善等附加算法参数在本稿显式呈现为实现默认，改动记录在测试报告，不冒充用户裁定。
- P0不加通用插件loader、schema反射表单框架、分布式事务、通用RPC重试器或第三方TUN兜底；有真实需求再新增。

## 8. 官方固定证据与未执行声明

源码基准： https://github.com/XTLS/Xray-core/tree/676eaf66f8f05d4d558ee7a74b4736623d3feeb9

- 原生TUN：`infra/conf/tun.go`、`proxy/tun/tun_android.go`、`proxy/tun/README.md`；环境变量：`common/platform/platform.go`。
- protect入口：`transport/internet/system_dialer.go`；DNS绕行核验：`app/dns/nameserver_quic.go`、`features/dns/localdns/client.go`、`transport/internet/dialer.go`。
- 真实路由读取及发布：`app/router/router.go`、`config.go`、`condition.go`、`balancing.go`、`balancing_override.go`。
- Geo状态：`common/geodata/ip_registry.go`、`domain_registry.go`；默认热加载：`app/geodata/geodata.go`。

本轮只核验文档/源码并编制契约；所有RPC扩展、锁补丁、DTO、UI与真机测试尚未实施。任务卡未认领，不以本契约存在冒充代码存在或验收通过。

## 9. PC-02 Linux RuntimeDto 与兼容性增补

本节为 v1.1 §3.1 与 §8 的正式增量，供 PC-02 及后续运行时卡共同使用；不替代 v1.1 其他章节。

### 9.1 RuntimeDto 公共字段

- `platform` 为 `"windows" | "android" | "linux"`。
- `apiVersion` 继续为 `1`。本次是同一 API 版本内的新增平台值和响应字段；客户端必须忽略未知响应字段，未知平台值不得按其他平台处理，必须呈现不可用状态。
- `RuntimeDto` 包含 `arch: string`、`libc: "glibc" | "musl" | null`、`supportStatus: "supported" | "planned" | "blocked" | "incompatible_version"`。Windows/Android 的 `libc` 为 `null`。
- `supportStatus` 描述平台/架构/libc/核心/桥组合状态；`phase` 继续只描述 `stopped | starting | ready | replaying | failed` 生命周期。
- 只有兼容性握手通过、资产已登记且有对应实测证据时，才允许 `supportStatus = supported` 且 `phase = ready`。其他状态不得伪装为 ready，原因通过既有兼容性错误/能力摘要返回。

### 9.2 兼容性与责任边界

- PC-02 冻结并生成 `apiVersion`、`coreVersion`、`coreCommit`、`bridgeVersion`、`bridgeProtocol`、`platform`、`arch`、`libc`、`supportStatus` 字段及其 REST/WS/Tauri 统一投影。
- PC-17 冻结 Linux 发行版、架构、libc 最低版本、Rust/Go target、核心/桥资产和实测矩阵；未列入矩阵或无实测证据的组合只能是 `planned` 或 `blocked`。
- PC-18 负责 daemon/service 生命周期与核心 ready 实现；PC-19 负责 systemd、SOCKS/HTTP/TUN、路由/DNS/权限与回滚；PC-20 负责 Web Token、REST/WS 鉴权与会话。
- `connectionMode` 在本版保持 `system_proxy | local_proxy | vpn`；Linux 数据面具体请求 DTO及其端口、协议、路由和权限语义由 PC-19/PC-20 另行提出并经契约所有者纳入正式版本，不得静默降级。

### 9.3 实施边界

v1.2 的字段和门禁可用于 PC-02 公共 DTO、TypeScript 生成、proto 锁定及双通道契约实现；不表示 Linux daemon、systemd、TUN、Web Token 或真实平台互通已完成。