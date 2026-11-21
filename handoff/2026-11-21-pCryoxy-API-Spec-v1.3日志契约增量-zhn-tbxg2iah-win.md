# pCryoxy API Spec v1.3｜日志契约增量

- API 父版本：`2026-11-20-pCryoxy-API-Spec-v1.2-zhn-tbxg2iah-win.md`
- 本文性质：增量契约，不重复复制 v1.2 全文。
- 生效方式：v1.3 = v1.2 全文 + 本文；日志 DTO、命令和错误语义以本文为准。
- 编制时间：2026-11-21（UTC+8）
- 状态：设计契约，须由 PC-02 所有者冻结并生成 Rust/TypeScript，尚未实现。

## 1. 日志投影与隐私边界

`AccessLogDto` 是本地受鉴权管理面的日志投影，不是 `SafeEvent`、`SafeContext` 或 AI 输入。所有字段必须由后端白名单构造。

```ts
export type LogKind =
  | "access"
  | "node_health"
  | "route_switch"
  | "runtime"
  | "storage";

export type LogStatus = "success" | "failed" | "cancelled" | "unknown";

export type SourceAppKind =
  | "windows_process"
  | "linux_process"
  | "linux_uid"
  | "unknown";

export interface SourceAppDto {
  kind: SourceAppKind;
  value: string;
  label: string | null;
  pid: string | null;
}

export interface AccessLogDto {
  id: Id;
  kind: "access";
  time: string;
  instanceId: Id;
  platform: "windows" | "linux";
  sourceApp: SourceAppDto | null;
  domain: string | null;
  sni: string | null;
  destinationIp: string | null;
  port: number | null;
  protocol: string | null;
  policyGroupId: Id | null;
  policyGroupLabel: string | null;
  selectedNodeId: Id | null;
  selectedNodeLabel: string | null;
  routeReason: string | null;
  attempts: { nodeId: Id | null; result: LogStatus; errorCode: string | null }[];
  dnsMs: number | null;
  connectMs: number | null;
  handshakeMs: number | null;
  ttfbMs: number | null;
  durationMs: number | null;
  uploadBytes: U64 | null;
  downloadBytes: U64 | null;
  averageUpKbps: number | null;
  averageDownKbps: number | null;
  status: LogStatus;
  errorCode: string | null;
}
```

本 DTO 不允许增加：

```text
fullUrl
urlPath
query
requestHeaders
responseHeaders
body
cookie
authorization
subscriptionUrl
credential
secretRef
ticket
rawConfig
rawError
processPath（默认不返回）
```

域名和 SNI 也只允许出现在本地日志查询响应中，不得复用到 AI、第三方遥测或通用错误响应。

## 2. 日志设置和查询 DTO

```ts
export type StartupCleanupMode = "none" | "expired" | "all_previous";
export type LogDetailLevel = "metadata" | "diagnostic";

export interface LoggingSettingsDto {
  enabled: boolean;
  retentionDays: number | null;
  maxTotalBytes: U64 | null;
  rotatePolicy: "daily" | "size" | "daily_and_size";
  startupCleanupMode: StartupCleanupMode;
  detailLevel: LogDetailLevel;
  redactQuery: true;
}

export interface LogsQueryRequest {
  from: string | null;
  to: string | null;
  cursor: string | null;
  limit: number;
  kind: LogKind | null;
  sourceApp: string | null;
  domain: string | null;
  policyGroupId: Id | null;
  nodeId: Id | null;
  status: LogStatus | null;
}

export interface LogsQueryResult {
  items: AccessLogDto[];
  nextCursor: string | null;
  scannedRecords: U64;
  droppedRecords: U64;
}

export interface LogsStatsRequest {
  from: string | null;
  to: string | null;
  groupBy: "app" | "domain" | "policy_group" | "node" | "status";
}

export interface LogsStatsResult {
  totalRecords: U64;
  totalUploadBytes: U64;
  totalDownloadBytes: U64;
  averageLatencyMs: number | null;
  averageDownKbps: number | null;
  groups: { key: string; records: U64; bytes: U64; latencyMs: number | null; averageKbps: number | null }[];
}
```

`retentionDays = null` 和 `maxTotalBytes = null` 的精确定义由实现契约冻结；不能在前端把未知、无限和关闭混为一谈。设置变更必须带既有 `Request<T>`、`requestId` 和适用的 `expectedRevision`。

## 3. P0 命令增量

新增到 P0 命令注册表：

| 命令 | 输入 | 输出 | 语义 |
|---|---|---|---|
| `logging_settings_get` | `{}` | `LoggingSettingsDto` | 只读安全投影 |
| `logging_settings_set` | `LoggingSettingsDto` | `Accepted` | 变更保留/清理策略，不回显路径或 Token |
| `logs_query` | `LogsQueryRequest` | `LogsQueryResult` | 本地分页查询，限制最大 limit |
| `logs_stats` | `LogsStatsRequest` | `LogsStatsResult` | 本地聚合统计 |
| `logs_cleanup` | `{mode, confirmationId}` | `Accepted` | 受控清理，不能清理当前打开文件 |
| `logs_export` | `{query, confirmationId}` | `Accepted` | 生成受控本地导出，不包含秘密 |

P0 不新增实时日志 tail 命令；若后续增加，必须沿用 streamId/sequence、bounded queue、resync_required 和非遥测事件不静默丢失规则。

HTTP REST 与 Tauri 调用同一命令处理器；WebSocket 只负责既有安全状态事件和后续经批准的日志增量，不直接读取文件。

## 4. 错误增量

如实现需要独立错误码，由 PC-02 统一冻结以下候选，不得由 PC-21 私自新增字符串错误：

```text
log_storage_unavailable
log_storage_full
log_query_invalid
log_cleanup_denied
log_export_failed
```

错误响应只返回固定 `messageKey`、字段路径和 `operationId`，不返回文件绝对路径、原始 IO 错误、域名查询内容或 Token。

## 5. 存储和能力声明

API 不暴露日志文件路径、SQLite/JSONL 等内部格式，不把文件扫描结果当作生产能力证明。日志格式版本、滚动、损坏行处理、保留和启动清理行为由 PC-21 的实现契约另行冻结。

`sourceApp` 为可选字段：平台无法提供可靠连接归属时返回 `null` 或 `unknown`，不得从域名、端口、策略组反推。

本 API 增量不改变既有 `RuntimeDto`、Linux `supportStatus` 或 PC-04/PC-18 ABI 规则；日志查询只能在 daemon 已就绪且权限通过时提供，不能伪造 runtime ready。
