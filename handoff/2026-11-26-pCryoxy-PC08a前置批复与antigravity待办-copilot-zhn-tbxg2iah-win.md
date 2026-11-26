# pCryoxy PC-08a 前置批复登记 + 给 antigravity 的两项待办

- project: pCryoxy
- author: `[@copilot @zhn-tbxg2iah-win~zhn-x-w 2026-11-26 23:38 UTC+8]`
- 依据：人类在 copilot 会话内对 `handoff/2026-11-26-pCryoxy-PC08a依赖与方案前置申请-copilot-zhn-tbxg2iah-win.md` 的当次批复
- 状态：`PC-08a` 保持 `doing`；copilot 先在分支做 h2 与 supervisor 骨架，下面两项落到 `main` 后 rebase 再接上。

## 人类批复（原意转述）

1. **依赖**：批准 `h2 =0.4.21` + 手写一元 gRPC；批准一次联网 `cargo fetch`（仅限隔离 `CARGO_HOME`，完成后立即恢复 `--locked --offline`）；批准 `windows-sys` Job Object（`unsafe` 仅限 `supervisor.rs` 内最小范围）。
2. **F-1**：采用官方转换器 `xray convert pb` + stdin + 私有命名管道。附加条件：管道仅允许当前用户 / 进程访问；设置短超时；返回的 protobuf 字节用 `Zeroizing` 包装；convert 子进程同样纳入 Job Object 管控。
3. **F-2 / F-3**：由所有者更新。请 antigravity 立即在 `main` 补齐，copilot 待 `main` 推送后 rebase 再编码相关部分。

## 请 antigravity 在 `main` 完成（copilot 按卡面无权修改这两处）

### 待办 1：`contracts/core-lock.json` 增加可执行文件钉
- 需要：每个 asset 下，ZIP 内核心可执行文件的字节数与 SHA-256。
- 建议字段（最终以你落盘的为准，我按落盘结果适配）：
  `"executable": { "path": "xray.exe", "size": 34864640, "sha256": "1ca7a2cf61ba2c5d20b21a80d405b57933939751081cb289f07bd8ddf7cc3185" }`
- 上面是 **Windows x86_64** 的实测值：ZIP 先按现有钉校验通过（16,697,596 B / `12625222…a69d`），再解出 `xray.exe`，`xray version` 报 `26.11.9 … 676eaf6`。
- Linux / Android 三个 asset 我没有下载，数值需你按同样步骤取得。
- 用途：supervisor 编译期内嵌锁文件，启动前校验即将执行的那个文件；当前平台没有钉则返回 `IncompatibleVersion`。

### 待办 2：入库 `StatsService` proto
- 需要：上游 `676eaf6` 的 `app/stats/command/command.proto` 放入 `crates/plugin-xray/proto/`，重生成 `descriptor.pb` 与 `proto.lock`（方法清单增加 `/xray.app.stats.command.StatsService/*`），`tools/check-proto.mjs` 如有计数断言需同步。
- 用途：`get_traffic_stats()` 用 `QueryStats`，Rust 侧消息按入库文件手写。

## 需要你知悉的一处范围说明
人类对 F-1 的附加条件（管道限当前用户、校验对端进程）需要 `windows-sys` 多开几个 feature：`Win32_Security`、`Win32_Security_Authorization`、`Win32_Storage_FileSystem`。同一个已批准的 crate 与版本，不改变 `Cargo.lock` 的包集合。如不同意请在审核时指出。
