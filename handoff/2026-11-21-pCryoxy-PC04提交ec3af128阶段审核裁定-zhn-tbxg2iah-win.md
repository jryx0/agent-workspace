# pCryoxy｜PC-04 提交 `ec3af128` 阶段审核裁定

项目：pCryoxy
任务：PC-04 Go 薄桥／受限管理路由核心
审核提交：`ec3af128c039170800fb046e25a20200f2ce5aca`
父提交：`97e04e205c6a8b302102234553cf8ec3a026b547`
审核时间：2026-11-21（UTC+8）
审核人：WorkBuddy

## 一、裁定

**该提交作为 PC-04 的增量测试／契约文档补充可接受；不通过 PC-04 结卡验收，PC-04 继续维持 `doing / blocked`。**

该提交不是 PC-03 提交，也不是完整 PC-04 实施提交；提交本身未授权合并、部署或将 PC-04 标记为 done。

## 二、提交内容核验

`ec3af128` 仅修改两个文件：

- `tests/integration/bridge/route_view_test.go`：新增 `TestPC04RetiredGeoSnapshotReclaimable`，覆盖旧 RouteView 持有 Geo 快照、发布新 Geo、删除旧资产目录、释放最后一个 RouteView 引用后等待旧 `VersionMatchers` 对象进入 GC；释放前不得被回收，释放后在 5 秒窗口内应收到 finalizer 信号。
- `tests/integration/bridge/profile.md`：补充“已发布 Geo 快照在最后一个 RouteView／保留点引用退出后可被 GC”以及操作表包含运行中操作、FIFO 淘汰、全表运行时 `ResourceExhausted` 和 `UNKNOWN` 重试边界的说明。

该提交没有修改桥运行时代码、Xray 上游补丁、Go 绑定、构建脚本或固定核心来源，因此不能单独证明这些实现语义已经落地或可复现构建。

## 三、可采信范围

1. 测试设计与 profile 文档方向符合此前 `8a30304`、`93bd249` 的受限能力子集边界：不扩大为完整 Xray 配置验收，不引入 `SetAdmission`。
2. 新测试补上了此前“释放回滚点不等于旧资源可回收”的证据缺口的一部分：至少尝试观察最后一个 RouteView 引用退出后的 Go 对象可达性。
3. profile 对运行中 operation 的容量和 FIFO 淘汰边界进行了明确化，有助于后续审查幂等窗口；这仍需与实现和运行回执绑定。

## 四、未通过结卡的原因

1. 本次审核未取得绑定 `ec3af128` 的 `go test` 或 `go test -race` 成功回执；当前 WSL 预期 Go 1.27.4 路径不存在，无法执行固定核心测试。不能把测试源码存在写成测试通过。
2. finalizer/`runtime.GC()` 是非确定性的观察手段，只能作为 Go 对象可达性辅助证据，不能单独证明 OS 文件描述符、映射、Geo 注册句柄、DNS/Lua/其他消费者资源均已释放；5 秒超时也不是生产回收 SLA。
3. 新测试只覆盖一个 Router 快照引用路径，没有覆盖 retained rollback point、连续三次以上 Geo 切换、并发读者、Lua/DNS 已纳管消费者及关闭/重启路径。
4. profile 的 operation 语义变更在本提交中只有文档变化；需要与 `operation.go` 的实现、容量边界、运行中请求和淘汰后重试的实际回执绑定。
5. PC-04 仍缺固定 Xray 源码按序重放补丁、普通测试、`-race`、双构建摘要、真实文件系统 Unix socket 身份/权限以及受限生产入口回执。既有未跟踪归档不作为本提交的构建证据。

## 五、后续要求

PC-04 可继续实施，下一次送审至少附：

- 包含 `ec3af128` 的 PC-04 实施提交完整 SHA；
- 固定源码摘要、补丁顺序、工具版本和可复现命令；
- 普通测试与 `go test -race` 的退出码和结果；建议对该回收测试执行多次，且补充显式生命周期/引用计数可观测断言，不能只依赖 finalizer；
- 连续 Geo 切换、保留点释放、并发读者退出、跨版本回滚及实际资源回收结果；
- operation 表 256 上限、运行中占位、FIFO 淘汰、`NOT_SEEN`/`UNKNOWN` 和淘汰后重试的实现—测试对应关系；
- 文件系统 Unix socket 目录/文件权限、peer UID 和 ticket 校验回执；
- 受限 profile 的生产注册入口和 prepare 拒绝后状态不变证据。

**本裁定不代表 PC-04 done，不授权合并，不授权部署；隔离测试仍不得写成完整 Xray 生产验收。**
