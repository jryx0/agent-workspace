# pCryoxy PC-04 Runtime ABI v2 专项正式复审申请

项目：pCryoxy
任务：PC-04 Runtime ABI v2
申请人：WorkBuddy
申请时间：2026-11-21（UTC+8）
记录性质：append-only 专项复审申请，不代表复审通过、结卡、合并或部署授权。

## 一、申请对象

请求 WorkBuddy 对以下两项进行专项正式复审：

1. PC-04 Runtime ABI v2 实施提交：
   `2206139fcb86a138b38a10ad43f20f455a99ffaf`
2. PC-04 ABI v2 status 版本规格澄清提交：
   `44247c802efe38750f19c958400cbb97086f2d41`

相关交接记录：

- 实施交付：`handoff/2026-11-21-pCryoxy-PC04-RuntimeABI-v2-implementation-copilot-zhn-tbxg2iah-win.md`
- 版本裁定与复核：`handoff/2026-11-21-pCryoxy-PC04-RuntimeABI-v2版本裁定与复核-copilot-zhn-tbxg2iah-win.md`
- ABI v2 设计审核裁定：`eeac8a44813ae0a7f99a5dcc3b272777ab1a1b45`
- 已提交复核 handoff：`ffe2eb58cc2d25f49c5e4e41b0a3a7741c14ffbf`

## 二、待复审规格

### 1. status struct 版本规格

v2 status struct 继续保持固定 296 bytes，不内嵌 ABI/version 字段。

ABI 版本通过以下方式表达：

- `PC04ABI_v2_version()` 查询当前 ABI 版本；
- create/status/close 等调用使用 `expected_abi_version`；
- 版本不匹配时优先返回固定 `ABI_VERSION_MISMATCH`；
- 不改变字段顺序、字段宽度、offset、alignment、padding 或总大小。

该规格由 `44247c802efe38750f19c958400cbb97086f2d41` 澄清并冻结，不能通过修改 296-byte 布局解决原始规格冲突。

### 2. ABI 符号与生命周期

实施提交提供以下版本化 C ABI：

- `PC04ABI_v2_version`
- `PC04ABI_v2_runtime_create_start`
- `PC04ABI_v2_runtime_status`
- `PC04ABI_v2_runtime_close`

运行时 handle 为不暴露 Go pointer 的 opaque value，支持 create/start、status、幂等 close 和固定错误码。

启动链复用唯一的：

`ValidateRestrictedProfile(config, initialGeo)`

并由 `RegisterRuntime` 进行二次校验，不引入 `SetAdmission` 或第二套准入逻辑。

## 三、实现范围核对

已核对交接材料，实施提交覆盖：

- Go/C bridge ABI v2；
- runtime handle；
- status 投影；
- Geo、RouteView、epoch/revision 和 lease 生命周期；
- Unix listener/gRPC server；
- socket 权限和 unlink；
- status/close 并发协调；
- 固定错误码和 panic 转换；
- ABI v1/v2 C smoke；
- 普通/race 测试；
- replay 和双构建比较。

实施提交未修改：

- PC-18 Rust daemon；
- PC-02 proto、descriptor 或生成物；
- 根 `Cargo.toml`、`Cargo.lock`；
- `contracts/core-lock.json`；
- `tools/build-*`；
- CI/build matrix；
- 公共发布清单；
- `native/xray-bridge/go.mod` 或 `go.sum`。

未引入 `SetAdmission`。

未跟踪的 `tests/integration/bridge/pc04-linux-amd64.a` 保持原样，未读写、未暂存、未提交。

## 四、验证证据

验证环境：Windows 主机上的 WSL Linux amd64。

固定工具和依赖：

- Xray `v26.11.9`；
- Xray source commit `676eaf66f8f05d4d558ee7a74b4736623d3feeb9`；
- Go `1.27.4`；
- Zig `0.16.0`；
- 离线 Go module cache；
- 无新增依赖、无在线下载。

replay 入口：

```sh
bash tests/integration/bridge/replay-linux.sh \
  "$PC04_XRAY_ARCHIVE" "$PC04_SCRATCH" "$PC04_GO" \
  "$PC04_ZIG" "$PC04_ARCHIVE_OUT" "$PC04_GOMODCACHE"
```

最终 replay 证据：

- replay 脚本退出码：`0`；
- replay 日志记录：`62` 个顶层 PASS；
- replay 日志记录：`0` 个 FAIL；
- replay 日志：`files/pc04-runtime-abi-v2-2206139-verify.log`；
- replay 日志 SHA-256：`afddebd51a5183d96baf0f65a3cef3f053e90686e733eb0c5863e0b497033aac`；
- archive 双构建比较一致；
- archive SHA-256：`8a6d31a78f47e9f16872920247df4457b0c762674a72b401373cbc714ec7abff`；
- `git diff --check` 通过；
- gitleaks 检查通过。

已通过的验证类别：

1. Xray 定向普通测试；
2. Xray race 测试；
3. bridge 普通 Go 测试；
4. bridge race Go 测试；
5. ABI v1 C smoke；
6. ABI v2 C smoke；
7. profile/Geo 失败时无 handle/socket；
8. NULL、超长输入和版本不匹配优先级；
9. status 安全投影；
10. socket 父目录 `0700` 和 socket `0600`；
11. 重复 close；
12. 8 线程 status/close 并发；
13. 双构建 archive 一致性。

PowerShell/WSL 外层包装曾因尾部 CR 解析问题返回非零；该问题发生在 replay 已完成并记录脚本退出码 `0` 之后，不改变 replay 本身的退出结果。该问题已记录在复核 handoff，不能把外层包装结果冒充 replay 失败或成功。

## 五、明确未覆盖项

以下内容不在本次 PC-04 ABI v2 专项复审的已通过范围内：

- Rust FFI smoke；
- PC-18 daemon-server 真实 caller；
- PC-18 真实 UID/ticket identity provisioning；
- 跨 OS UID 的独立账户拒绝实测；
- daemon 宿主重启/恢复；
- core.New、x.Start、initial publish、service registration 各阶段的完整 ABI 故障注入和资源清零实测；
- 完整 Xray 生产配置；
- PC-18 生产生命周期验收；
- 合并和部署。

这些未覆盖项不得因 ABI v2 C smoke 通过而写成 PC-18 或生产验收通过。

## 六、请求 WorkBuddy 作出裁定

请对以下事项逐项裁定：

1. 是否认可 `2206139fcb86a138b38a10ad43f20f455a99ffaf` 作为 PC-04 Runtime ABI v2 的桥侧实施基线；
2. 是否认可 `44247c802efe38750f19c958400cbb97086f2d41` 对 296-byte status struct 版本表达的澄清；
3. 是否允许 PC-18 基于该 ABI 开始 Rust FFI wrapper 和真实 daemon caller 实现；
4. 是否允许 PC-18 开始 UID/ticket、private IPC、ready、stop、restart 和 client disconnect 集成测试；
5. PC-04 是否继续保持 `doing / blocked`，等待 PC-18 真实接入证据；
6. 是否仍禁止合并、部署和完整生产验收声明。

建议裁定边界：

- PC-04 ABI v2 实施可作为 PC-18 接入基线；
- PC-18 可在不修改 PC-04 ABI 的前提下开始真实 Rust/daemon 接入；
- PC-04 不标记为完整 done；
- PC-18 不因本次复审自动解除 blocked；
- Rust FFI smoke、真实 daemon caller、UID/ticket、生命周期和生产验收仍需单独复审；
- 不授权合并或部署。

## 七、当前状态

在 WorkBuddy 正式裁定产生前：

- PC-04：`doing / blocked`；
- PC-18：`doing / blocked`；
- PC-18 不开始真实 runtime 绑定；
- 不合并；
- 不部署；
- 不宣称 PC-04 或 PC-18 完整结卡。

本文件仅为 PC-04 ABI v2 专项正式复审申请，不是复审通过裁定。