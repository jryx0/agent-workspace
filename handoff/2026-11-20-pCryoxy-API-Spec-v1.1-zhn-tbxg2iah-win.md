

## 8. v1.1 新增传输与兼容性契约

### 8.1 管理面与核心版本隔离

公开管理 API 的 `apiVersion` 仍为 `1`；核心和桥另行携带 `coreVersion`、`coreCommit`、`bridgeVersion`、`bridgeProtocol`、`platform`、`arch` 与 `libc`（Linux）能力摘要。客户端不得由 `coreVersion` 推断已支持的协议；启动握手必须返回能力矩阵和不兼容原因。任何核心/桥/API 不匹配必须返回 `incompatible_version`，不得伪造就绪。

### 8.2 统一命令入口

Tauri IPC、HTTP REST 与 WebSocket 事件都进入同一命令处理器，复用 `requestId`、`expectedRevision`、`operationId`、错误码、SafeEvent 与快照重同步。HTTP/WS 路径不得直接调用官方 Xray RPC，不得读取 vault 或原始核心配置。

### 8.3 REST/WS 映射

- REST 默认只在 `127.0.0.1` 提供；非回环监听必须在启动时校验管理员 Token，缺失即拒绝启动。
- REST 使用公开 DTO；Token 不得出现在 URL、响应、日志、遥测或 `dist/`。写操作要求 `requestId` 和适用的 `expectedRevision`。
- WebSocket 只发送 SafeEvent，包含 `streamId` 与单调 `sequence`；断点或重连先请求快照，不补发秘密或原始节点链接。
- Tauri IPC 与 REST 对同一写请求使用相同幂等语义，重复 `requestId` 返回既有操作结果或 `request_id_conflict`，不得重复产生副作用。

### 8.4 服务生命周期

daemon 启停、服务注册、systemd/Windows SCM 状态和核心 ready 状态分开报告。GUI 关闭不等于 daemon 停止；服务重启后的 `instanceId` 必须变化，`epoch` 单调递增；配置错误返回可诊断状态，禁止无限重启伪装可用。

### 8.5 Linux/Windows 存储与权限

Linux 服务使用专属账户和 `0600` 密钥文件或 Secret Service；Windows Service 以实际服务身份访问 Credential Manager/ACL，不能默认读取交互用户 vault。控制面 Token 与节点凭据分离存放。权限不足、服务身份不匹配或密钥不可读都返回明确错误，不回退为直连。

### 8.6 版本适配验收

每个平台/架构/libc 组合须登记核心资产、桥产物、协议版本及 SHA-256；仅有上游核心资产不等于桥产物已验证。PC-17/04/07/19/20/13 分别提供构建、桥、配置/互通、服务/TUN、管理面和升级回退证据。无 Linux 资产或实测证据时，Linux 只能标为 planned/blocked，不能写作 supported。
