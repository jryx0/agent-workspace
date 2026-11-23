# pCryoxy PC-07 前置事项裁定（依赖、crate 根、IR 契约变更流程、桥出站缺口、probe 配置边界）

- 项目：pCryoxy｜卡：PC-07「IR 到固定核心配置与协议矩阵」（P0，doing，copilot）
- 基座：main `c3acc73f0b1cfc25b1770a4d0d9645cd59681738`
- 裁定登记：workbuddy@zhn-tbxg2iah-win~zhn-x-w｜2026-11-23 19:40 UTC+8
- 人类裁定依据：copilot 在会话中提出的 6 道选择题，人类 19:30 确认「都是按你的建议选择的」，也就是采用审核方在 19:0x～19:29 会话中给出的选项和第 4 项附加条件全文。本文把这些选项逐项写成条文。
- 权威正文：需求基线 v1.3、实施任务卡 v1.2 + **v1.3 增量**（同日发布）、API Spec v1.2 + v1.3 日志增量。
- 被审申请：`d852dcc` 认领、`4d1f31d` 依赖申请、`e8d4100` FinalMask IR 接口变更申请、`31bc7e1` plugin-sdk 依赖追加申请。

**本文没有批准任何 core-ir/parser 的具体字段设计。** IR 契约变更走 §3 的合并申请流程，要等审核方审完、人类批准后才能实施。

## 1. 依赖授权（人类已批准，附条件）

| 包 | 版本/来源 | 结论 |
|---|---|---|
| `core-ir` | 工作区 path | 批准 |
| `plugin-sdk` | 工作区 path | 批准；**不启用 `typescript` 特性**（不引入 ts-rs） |
| `serde`（derive） | `=1.0.229` | 批准，锁文件已有 |
| `serde_json` | `=1.0.154` | 批准，锁文件已有 |
| `prost` | `=0.14.6` | 批准，只用默认的 `derive`、`std` |
| `prost-derive` / `itertools` / `either` | `0.14.6` / `0.15.0` / `1.19.0` | 批准，属于 prost 的传递依赖 |

附加条件：
1. 直接依赖一律用 `=` 精确固定版本。不加 `prost-build`、`protoc`，也不写 `build.rs`。
2. 批准后实际生成的 `Cargo.lock` 中，新增的 registry 包只能是 `prost`、`prost-derive`、`itertools`、`either` 这 4 个，版本和申请一致；已有包的版本不能变。工作区内部只新增 `plugin-xray → core-ir`、`plugin-xray → plugin-sdk` 两条依赖边。
3. 解析结果和以上任一条不符（多出包、版本不同、已有包变版本），先停下来报告，不得自行调整。交付时附 `git diff c3acc73 -- Cargo.lock` 全文。
4. 不改 go.mod/go.sum。本机代理 `127.0.0.1:10808` 只是下载通道，不能替代审批。

## 2. crate 根与文件范围（人类已批准）

- 批准新增 `crates/plugin-xray/src/lib.rs`，只放 `mod` 声明和 `pub use` 导出，不写业务逻辑。
- 批准修改根 `Cargo.toml`（members 只增加 `"crates/plugin-xray"` 一行），以及 `Cargo.lock`（变化限于 §1）。
- 其余文件范围仍按卡面：`crates/plugin-xray/src/{config,protocols,capabilities}.rs`、`crates/plugin-xray/Cargo.toml`、`contracts/core-capabilities.json`、`crates/plugin-xray/tests/fixtures/config/`。core-ir/parser 的文件要等 §3 获批后，才按批准清单扩展。

## 3. IR 契约变更：FinalMask + WireGuard + MASQUE + 快照版本号合并为一份申请

**人类裁定**：不缩减 P0，也不让整卡暂停。

1. **合并申请**：copilot 在原 `e8d4100` 申请文件上追加章节（或另出 v2），合并成一份「PC-07 IR 契约变更申请」，覆盖以下四项。一次审批、一次升快照版本号、一次迁移。
   - **A. FinalMask**：按 PC-04b 白名单的 10 种类型逐一建模（已提交，审核意见见 §3.1）。
   - **B. WireGuard**：逐项列出核心客户端 peer 必需的字段，包括对端公钥、endpoint、allowedIPs、本地接口地址、MTU、reserved 等，写明类型、取值范围和输入来源。说明现有 `peers: Vec<IpAddr>`（`core-ir/src/node.rs:150`）的真实含义，以及改名或迁移方案。私钥和可选的 preshared key 只能用 `SecretRef`。
   - **C. MASQUE**：说明 token 的协议语义和出处，可以是标准文档、分享链接格式或核心源码。固定核心 `infra/conf/masque.go` 只认 `user`/`pass`/`headers` 三项。有依据能证明 token 可以无损映射到这三项的，写明映射规则和依据；没有依据的，带 token 的链接在**解析阶段明确拒绝**，不发明映射。token 只能用 `SecretRef`。
   - **D. G-09 快照版本号**：给 `ValidatedSnapshot` 的存储格式加版本字段，写明旧格式（无版本）的读取规则和迁移测试。
2. **通用要求**：每个新字段都要注明输入来源；没有标准来源的输入，写明「不支持」。parser 只能从有依据的链接或订阅格式中读取，不发明 query 参数、URI scheme 或订阅字段。「protobuf 里有这个字段」不等于有输入来源。
3. **审批前**：PC-07 的其余部分照常推进。FinalMask、WireGuard、MASQUE 在矩阵里标「待接口」，不修改 core-ir/parser。
4. **审批后**：在 PC-07 分支实施，允许的文件按批准清单扩展。
5. **结卡门槛**：以上三项没有全部完成三栏取证之前，PC-07 不能结卡。

### 3.1 审核方对 `e8d4100`（FinalMask 部分）的预审意见（不是批准，供合并申请修订）

| # | 事项 | 意见 |
|---|---|---|
| R1 | 10 个封闭变体，不设通用 raw/settings 字段，被拒类型在 `validate_snapshot` 拒绝 | 方向正确，保留 |
| R2 | **XMC 需要 RSA**：申请认为 Rust 侧需要 RSA 实现 | **不需要。** 固定核心 JSON 构建器 `infra/conf/transport_finalmask.go:972-991` 会在 Go 里用 `xmc.DeriveRSAKey(password)` 派生密钥。Rust 侧只输出 JSON 的 `password/hostname/profiles`，由核心完成构建。**禁止**在 Rust 侧派生、保存或传递 RSA 密钥，不申请 RSA 依赖。运行时增删出站也走 JSON，由桥侧构建（见 §4 PC-04c） |
| R3 | **noise 的 `script`（Lua）字段** | **不进 IR，一律拒绝。** 这是从订阅输入可执行代码，风险超出 P0 安全边界；核心本身也规定 `script` 和 `noise` 不能同时用（同文件 :340）。noise 只建模声明式的 items/reset |
| R4 | 一些整数和列表在核心里没有上限 | 合并申请里给出建议上限，并写明依据（例如对应的协议特性、或核心使用 int32 的边界）。没有依据的字段**不进 IR**，取最小可用子集，不要实现时临时补值 |
| R5 | 密码类字段（sudoku、mkcp aes128gcm、salamander、xmc） | 一律用 `SecretRef`，明文不进 IR、fixture 和日志 |
| R6 | 输入来源 | 申请已如实写明「没有标准的 FinalMask 分享链接格式」。合并申请里要补一条：IR 可以表达之后，**由哪个入口写入**。如果只能由 Web/GUI 表单录入，就要写明属于 PC-14/15 的范围；在入口存在之前，矩阵的「解析」栏标「无输入入口」 |
| R7 | 存储兼容 | 方案可以接受，并按 §3-D 改成带版本号 |

## 4. 桥出站缺口：新开 PC-04c（人类已批准）

- **事实**（审核方 18:50 已核实）：
  - 启动阶段：桥的 `validateProfileOutbounds` 只放行 `freedom` 和 `proxy/dns` 两种出站（`restricted_profile.go:322-326`）。
  - 运行阶段：桥没有注册 HandlerService，也就没有 `AddOutbound`/`RemoveOutbound`（`runtime.go:47` 禁用了独立的命令接口）。
  - 结果是：现在的桥连不上任何节点。这是审核方编制 PC-04 受限子集裁定和 PC-04b 卡面时的遗漏。
- **裁定**：新开 P0 卡 **PC-04c「节点出站纳管」**。卡面见任务卡 v1.3 增量 §3。
- **对 PC-07 的影响**：
  - 配置生成和核心 `run -test` 照做；「桥 prepare」和「实际连接」两栏标「待 PC-04c」。
  - 可以用核心直接运行做互通预验，但证据要标明「核心直跑，非桥」，不能算作验收证据。
  - PC-04c done、两栏补齐之前，PC-07 不能结卡。

## 5. probe / 入站配置边界（人类已批准选项 1，附条件）

- IR 里没有监听地址、入站和 probe 入口这类字段，API Spec 也只规定了 `ProbeRequest { nodeIds }`。监听地址、端口、tag 属于宿主运行时的参数，不进 IR。
- PC-07 在 `plugin-xray` 内部定义一个生成上下文（下称 context），由调用方显式传入：
  1. context 只在 `plugin-xray` 内部使用（`pub(crate)`，或者不在 lib.rs 导出），不进 core-ir、ABI、proto，不新增 IPC/API 字段。
  2. 监听地址、端口、入站 tag、probe 凭据的 `SecretRef` 全部由调用方传入，不设默认值，也不写死。缺任一项时，生成阶段明确报错。
  3. 监听地址只能是 `127.0.0.1` 或 `::1`，其他地址在生成阶段拒绝。probe 入口的 SOCKS 必须带凭据，配置里只放引用，日志和 fixture 中不能出现明文。
  4. probe 和业务池的 tag 隔离：probe 入站只能命中 probe 路由，业务入站不能命中 probe 出站。两个方向都要有反向测试。
  5. context 的字段清单（名称、类型、校验规则）写进交付报告，作为 PC-09 对接的输入。PC-09 如需把它提升为正式契约，再走契约变更，PC-07 不预先扩展。

## 6. PC-07 矩阵状态标注规则（汇总）

| 标注 | 含义 |
|---|---|
| 通过 | 这一栏有本卡取证 |
| 待接口 | 等 §3 的 IR 契约变更获批并实施（FinalMask、WireGuard、MASQUE） |
| 待 PC-04c | 桥 prepare、经桥的实际连接 |
| 核心直跑预验 | 只作参考，不算验收证据 |
| 未通过／缺夹具 | 没有本地受控服务端夹具 |
| 无输入入口 | IR 能表达，但没有有依据的解析或录入入口 |

## 7. 审核方自查

PC-07 提示词中有三项要求是在没有核对实现条件时写下的：一是要求覆盖每种 FinalMask，而 IR 表达不了；二是要求生成 probe 入口，而契约里没有对应字段；三是没有发现桥拒绝节点出站。这三项都由 copilot 在实施前发现并上报，没有造成返工。此后审核方出卡面前，会先核对 IR、契约和桥的白名单能否支撑卡面要求。
