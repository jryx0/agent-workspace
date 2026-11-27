---
project: pCryoxy
author: copilot@zhn-tbxg2iah-win~zhn-x-w
date: 2026-11-27
---

# PC-14c 文件边界、契约与依赖前置申请

## 状态与基线

- 申请人：copilot；审核：antigravity；需人类与审核方批准后实施受限变更。本申请不是批准、交付或结卡。
- 任务：PC-14c，doing；计划分支 `agent/copilot/pc14c`、独立 worktree `~/source/pCryoxy.wt/copilot-pc14c`；项目基座 `origin/main 3b4cb2cfef8a6a2ebc1b747741e0218d917fdc69`。
- 依据：项目 `docs/06-M2.5桌面体验与Xray配置规范.md` §1、§3.1–3.5 与任务卡 PC-14c；需求基线 v1.3、蓝图 v0.3/v0.4、API Spec v1.2/v1.3 及 G6。
- 共享仓存在 3 个其他会话未提交文件；人类对本次 S3.1e 拉取明确豁免，已只读核对共享仓本地 HEAD 与两个远端 main 均为 `aa1f15275b9a3e15ed9dc97962b157d5b81163d4`。不碰、不暂存其改动。

## A. 文件边界申请

申请在本卡内修改以下目录的必要源码与本卡对应测试，具体 diff 仍须遵守最小化原则：

1. `crates/core-ir/src/`：节点、路由和持久化编解码；尤其 `RealityOptions.mldsa65_verify` 的向后兼容迁移与指纹/引用校验。
2. `crates/plugin-sdk/src/public_dto.rs`、`crates/plugin-sdk/examples/generate_types.rs` 与相关契约测试：公开命令、DTO、事件、错误与确认动作；由源定义重新生成 `ui/src/api/generated.ts`。
3. `crates/runtime-host/src/` 与测试：配置持久化迁移、命令、日志环、节点编辑、订阅分组、备份、目录打开与协调；使用已有单指针和 revision/确认机制。
4. `crates/plugin-xray/src/` 与测试：Xray 入站/路由/DNS 模型和热下发、按节点出站计数；延续 G6，不把节点出站移入 Go 桥。
5. `crates/engine-scheduler/src/` 与测试：有界健康策略及受控订阅 fetch；`crates/protocol-parser/src/` 与测试：容错订阅与兼容解析。
6. `crates/tauri-app/src/` 和 `ui/src/`：新增命令的桌面接线与既有 UI/Mock 编译所需的最小契约适配；不做 PC-15a-v2 布局重构。
7. 直接相关 `docs/` 和契约测试：说明迁移、安全限制、配置边界及验证；如需其他文件，先补申请。

`Cargo.toml`、`Cargo.lock`、`public_dto.rs`、生成的 `generated.ts`、Proto 和 `proto.lock` 属受限项，必须先获批准。拟优先不改 Proto；仅在现有官方 StatsService 不足时，另提精确变更与生成计划，禁止手改生成物。

## B. 契约与兼容申请

- Core 配置：新增 CoreSettings、DNS/TUN 与命名规则集模型，持久化且能在重启后恢复；明确入站业务与永久回环的 API/probe 隔离。需要校验端口冲突、认证与日志落盘边界。Windows VPN 继续返回 `UnsupportedCapability`。
- 路由与主出口：`activeProxyTarget` 按 node/group 判别；规则集有序、可启用及热切换，包含四套标准预置。目标缺失、空组与热下发失败必须 fail-closed，明确 revision、回滚及重放语义。
- 健康：允许设置五项探测参数与容差并持久化；现探针固定 16 槽，故并发上限不得突破实际槽位，先校验数值再转换窄整数；调整后状态机、调度及运行节拍均须真正使用配置。具体上下界及跨字段约束请审核方确认。
- 统计：现有 `get_traffic_stats` 聚合入站；申请启用并查询出站 stats，以 pool tag 归并 node ID，按采样间隔计算速率，明确不同池重复节点、实例重启/计数回退及清零竞态的处理，保留现有汇总兼容。
- 凭据：新增节点详情、按需 reveal、结构化更新；列表仍不含凭据。明文只经明确 reveal 命令返回，后端临时缓冲零化，不进入持久化、日志、事件或幂等回复缓存；更新重算八字段指纹并进行冲突、事务及热下发验证。
- 订阅：DTO 明文回显 URL，空 URL 为本地分组；保存不触发网络。现存 `PersistedSubscription.url_ref` 需要定义从 Vault 引用到明文配置的可恢复迁移，旧数据不丢失；日志、错误、版本库禁止真实 URL。加入 fetch mode、过滤器、UA、headers、排序、备注；订阅刷新使用 `ValidOnly` 并返回有界脱敏跳过原因，单独导入的既有 Atomic 行为不随之改变。
- 运行日志与运维：有界日志环仅接受白名单字段；内容不包含 URL、凭据、分享链接、原始错误或未经验证的用户文本。导出含凭据需绑定目标和 revision 的一次性确认；导入导出需明确备份格式、权限、凭据处理与失败回滚；新增目录打开和安全重启。
- 保持现有 API 版本、u64 字符串、revision/requestId、事件重同步与错误码约定；若必须改变兼容语义或引入错误码，先列明并请求批准。

## C. 依赖申请

目标零新增外部 registry 包；优先复用锁内 crate。若必须更改成员依赖边、Cargo feature、manifest 或 lock，逐项提交版本、feature、目标平台和锁增量，再等待人类及 antigravity 批准；不安装或联网拉取未批准依赖。正则须有明确大小与计算复杂度上限，不能仅凭长度声称防 ReDoS。

## D. 需裁定的问题

1. 需求基线 v1.3 REQ-12 将远端 DNS 列为 P0 拒绝，而 M2.5 §3.2 要求远端代理 DNS 模型与防环。请确认本卡是仅受控官方核心直连路径开放，还是仅保存而拒绝启用，以及该变化如何与 G6 和旧安全边界衔接。
2. 请冻结健康参数各项安全上下界、timeout 与 interval 的关系；设置规则集中默认代理、目标为空或被删除时的明确 fail-closed 行为。
3. 请确定 `auto` 的直连/代理选择与失败回退规则、无可用代理时错误；过滤器匹配语义及限制、header 可接受范围及敏感值保护。
4. 请明确备份的凭据封装、保护方式和恢复/跨设备能力；不要将明文凭据备份视为默认已获批。确定用户取消、覆盖和失败回滚行为。
5. 请确认节点 reveal 的权限/确认边界、泄漏面及结果不缓存；确定请求字段兼容、旧 URL 引用迁移后是否保留和何时清理，以及运行日志显示用户可控标签的安全方式。
6. 请审核本申请文件范围及仅复用锁内 crate 的策略；涉及 Proto、公共清单/锁的具体改动另逐项批准。

## E. 验证与红线

- Mock 与私有临时目录；绝不读写真实 HKCU Internet Settings，不触碰 v2rayN 或 10808 做产品测试，测试结束核实 0 个夹具 `xray.exe` 残留；`RUSTUP_AUTO_INSTALL=0`。
- 定向覆盖旧数据迁移与回滚、路由切换和 fail-closed、监听隔离、统计清零和实例变化、节点 reveal/编辑冲突、订阅代理与部分失败、确认令牌与敏感信息不泄漏。
- 交付前执行 `tools/check-all.ps1`（含区间 gitleaks）、Windows 固定版本真实核心全量集成、四目标离线 Clippy 与 `tools/build-linux`；生成 TS 与 Proto 锁零漂移，UI `tsc` 通过。
- 未获人类及 antigravity 前置批复不改受限项；未经 antigravity 终审不标 done、不合 main。
