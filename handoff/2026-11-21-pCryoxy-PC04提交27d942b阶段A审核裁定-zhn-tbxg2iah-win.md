# pCryoxy PC-04 提交 27d942b 阶段 A 审核裁定

项目：pCryoxy
审核时间：2026-11-21（UTC+8）
审核人：WorkBuddy

## 一、审核对象与提交范围

- PC-04 实施提交：`27d942badfa26afb2d0fb0b60009071881f035b9`
- 父提交：`c3a225780f02aa7920d4183f518fcaa52595b5b9`
- 阶段 A 授权基线：`041c2dbe8f7bbdfbb2f333998a93bd4c3baa1f6e`
- 分支：`agent/copilot/pc04`
- 提交标题：`feat: 提取PC-04受限profile纯预检ABI`
- 变更范围：9 个 PC-04 文件；新增纯 profile 校验、无状态 C ABI v1、定向测试和 replay 脚本更新；未修改 PC-02 proto/descriptor/生成物、公共 Cargo/Go 清单、`contracts/core-lock.json` 或 PC-18 Rust daemon。
- 工作树另有未跟踪 `tests/integration/bridge/pc04-linux-amd64.a`；已确认不属于该提交，不纳入交付。

## 二、审核结论

**`27d942badfa26afb2d0fb0b60009071881f035b9` 作为 PC-04 阶段 A 的 Go 侧最小接入实施可接受；PC-04 仍保持 `doing / blocked`，不标记 `done`。**

本结论仅放行“受限 profile 纯 prepare + `RegisterRuntime` 二次校验 + 无状态 ABI v1”这一阶段范围，不等于完整 PC-04、完整 Xray 生产配置或 PC-18 通过。

## 三、已确认的实现要求

### 1. 纯 prepare 与启动顺序

- `ValidateRestrictedProfile(config, initial GeoRoot)` 已从 `RegisterRuntime` 提取为单一校验实现。
- 校验只读取内存中的 protobuf、allowlist 功能和 Geo inventory 元数据；不读 Geo 文件、不创建/启动 core、不创建 listener/socket、不注册 service、不发布 RouteView、不创建 lease，也不修改 epoch/revision。
- `RegisterRuntime` 对非 nil 配置先做 protobuf clone，再调用同一校验函数；校验发生在 Geo 文件预检、`core.New`、`x.Start`、初始 Geo publish 和控制服务注册之前。
- 校验失败直接返回；现有测试覆盖纯校验不创建虚构 Geo 根目录、失败资产预检不注册服务，以及纯校验与运行时二次校验的错误码/错误文本一致性。

### 2. 受限 profile 边界

当前 allowlist 仅接受 router、DNS、dispatcher、outbound manager 四种唯一功能；拒绝 inbound、outbound、extension、未知 protobuf 字段、未知功能、未纳管 DNS matcher/script/backend、`proxy/dns`、`freedom`、`finalmask`、独立 Geo cron 及不符合 inventory 约束的元数据。该边界与 `041c2db` 阶段 A 裁定一致，不构成对 allowlist 以外 Xray 消费者的放行。

### 3. ABI v1

- 版本函数和校验函数已导出；版本不匹配在读取其他输入前返回。
- ABI 只复制调用方输入，不保留 Go pointer、不返回错误文本或 Go pointer；错误映射为固定状态码。
- Go panic 被收敛为 internal error；实现无可变运行时状态，C smoke 覆盖 8 线程共 1024 次并发调用。
- 无 opaque handle/close API 是因为本 ABI 明确为无状态 validator；这不替代后续 Rust wrapper、daemon 生命周期和运行时资源 close 验收。
- 头文件目前以可写指针类型表达 `config_proto`/`initial_geo`，实现实际不写入输入；Rust wrapper 接入前应补充 C 头文件的 const-correctness（`const` 指针）并复核绑定，作为契约清晰度跟进项，不据此扩大本次阶段范围。

## 四、证据与复核边界

交接材料报告固定 Xray 归档摘要、按序应用 `0001`～`0012` 补丁、桥普通/race 测试、ABI c-shared 构建、C smoke、双独立缓存 archive `cmp`、`git diff --check` 和 gitleaks 均通过；完整 replay 脚本报告退出码 `0`。该部分作为执行方绑定证据采信。

审核方本轮独立核对了提交对象、父提交、9 文件边界、源码顺序、测试断言、工作树未跟踪产物边界和 `git diff --check`；当前审核环境的 WSL 可启动但未提供 Go/Zig 或该 worktree，未将审核方现场重跑写成成功。

## 五、尚未满足的结卡条件

1. ABI 尚未由 PC-18 Rust wrapper 调用，尚无真实 daemon-server 生产入口。
2. 尚无私有控制端口、socket `0600`、目录 `0700`、peer UID/ticket、单写者、ready、优雅停止和重启恢复的生产链路回执。
3. 尚无生产入口中拒绝前后 active RouteView、epoch、revision、Geo version、rollback point、Geo lease 及其他资源均不变的逐项证据。
4. 尚无客户端断开后数据面继续运行、完整 Xray 配置、真实代理互通、systemd/TUN 或多平台最终验收证据。
5. 受限 profile 测试和 ABI smoke 不能替代 PC-18/运行时集成验收，也不能把 PC-04 标记为 done。

## 六、明确裁定

- `27d942badfa26afb2d0fb0b60009071881f035b9`：阶段 A Go 侧实施审核通过，可作为 PC-18 最小接入的桥侧基线。
- PC-04：继续 `doing / blocked`，不标记 `done`。
- 不授权合并或部署。
- 不引入 `SetAdmission`。
- 不豁免 PC-03/PC-08/PC-09/PC-17 依赖，不授权修改公共构建清单、锁文件、PC-02 proto/descriptor/生成物。
- 下一步由 PC-18/运行时集成提供真实 Rust wrapper、daemon-server 生产入口及生命周期/状态不变证据；完成后再申请 PC-04 绑定复审。
