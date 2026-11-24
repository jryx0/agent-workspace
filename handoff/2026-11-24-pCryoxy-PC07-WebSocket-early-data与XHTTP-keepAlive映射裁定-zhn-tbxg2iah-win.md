# PC-07 裁定：WebSocket early data 与 XHTTP keepAlivePeriod 的映射口径

日期：2026-11-24　裁定方：workbuddy@zhn-tbxg2iah-win~zhn-x-w　**人类已于 2026-11-24 10:20 确认，本节全部生效**
对象：copilot 提问（PC-07 会话），依据固定核心 676eaf6 实测

## 1. 核实结论

copilot 的判断成立，两处都会静默丢弃，实测如下（日志 `~/.agent-tools/run/review/pc07-core-verify/logs/build-probe.log`，探针临时文件已删除，核心源码未改动）：

| 输入 | 核心构建结果 | 说明 |
| --- | --- | --- |
| `wsSettings.ed = 2048` | `Config.Ed = 0`，`Path = "/x"` | `WebSocketConfig`（`infra/conf/transport_method.go:620-626`）没有 `ed` 字段，JSON 解码静默丢弃 |
| `wsSettings.path = "/x?ed=2048"` | `Config.Ed = 2048`，`Path = "/x"` | `Build()`（`:629-639`）从 path 的 `ed` 查询参数取值并把它从 path 里删掉 |
| `wsSettings.earlyDataHeaderName = "X-Custom"` | 无对应字段 | `WebSocketConfig` 没有该字段；核心固定用 `Sec-WebSocket-Protocol`（`transport/internet/websocket/dialer.go:145`、`hub.go:55-58`） |
| `splithttpSettings.keepAlivePeriod = 1500` | 顶层无该字段，静默丢弃 | `SplitHTTPConfig` 没有顶层 `keepAlivePeriod` |
| `splithttpSettings.xmux.hKeepAlivePeriod = 2` | `Xmux.HKeepAlivePeriod = 2` | 唯一承载点，单位为**秒**（`transport/internet/splithttp/dialer.go:148-150`） |

`run -test` 对这些字段一律返回 `Configuration OK.`，即核心不报错、只是不生效，属于静默降级。

## 2. 裁定（人类已批准）

### 2.1 WebSocket early data

- `max_early_data == 0`：不写任何 early data 字段。
- `max_early_data > 0`：写进 `wsSettings.path` 的 `?ed=<值>` 查询参数；path 缺省时用 `/`；若调用方给的 path 已含 `ed` 参数，以 IR 字段为准替换，不保留两份。
- `early_data_header` **非空即拒绝**（报节点 ID 与字段名 `early_data_header`）。核心没有可配置的 header 名，实际固定 `Sec-WebSocket-Protocol`，写入该字段必然是静默丢弃；不得改写、不得忽略后继续。
- 非 WebSocket 传输携带非零 `max_early_data` 或非空 `early_data_header`：拒绝（沿用 PC-06 已确立的 `unsupported_capability` 口径）。

### 2.2 XHTTP keepAlivePeriod

- `keep_alive_period_ms` 为 `Some(v)`：映射到 `splithttpSettings.xmux.hKeepAlivePeriod`，**单位换算为秒**（毫秒 / 1000，向下取整）。
  - `v == 0`：不写该字段（核心 0 表示未设）。
  - `0 < v < 1000`：向下取整为 0 会丢失调用方意图，改为拒绝并报节点 ID 与字段名。理由是核心只能表达整秒，写 0 等于静默丢弃。
  - 同时写 `xmux` 其他字段不影响本项；本卡不生成其他 xmux 字段。
- 不得在 `splithttpSettings` 顶层写 `keepAlivePeriod`。
- 字段名沿用 IR 的 `keep_alive_period_ms`，语义按毫秒解释；单位差异由生成侧换算，不改 IR。

### 2.3 通用

- 拒绝一律在生成阶段完成，带节点 ID 与字段名，不改写、不静默丢弃、不降级为其他字段。
- 验收：ed 0/2048/带 path 三种生成正确；`early_data_header` 非空被拒；keep_alive 1500ms→1、2000ms→2、0 不写、500ms 被拒；每例断言生成 JSON 的键与值，不得只断言 `run -test` 通过。
- 核心 `run -test` 只证明构造通过，不证明字段生效；交付报告须区分「构造通过」与「字段已生效」。

## 3. 未决与边界

- `xmax`/`xmux` 其余字段、`sessionID*`、`seq*`、`downloadSettings`、`h2Params`、`extra` 均不在本次范围。
- 若后续需要 `early_data_header` 的真实自定义能力，须另行向核心提出能力请求，不在桥或 IR 侧伪造。

## 4. 人类确认记录

- 2026-11-24 10:20，人类在 PC-07 会话中确认：三项提问（early data 映射、keepAlivePeriod 映射、核心字段与单位换算及不可精确映射的处理）均按本文口径执行，未作修改。登记方：workbuddy@zhn-tbxg2iah-win~zhn-x-w。
- 生效范围仅限本文 §2 列出的字段；§3 列出的未决字段仍未批准。
