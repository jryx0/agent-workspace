# pCryoxy PC-03-WIN-V1 回执裁定：退回补证（不接受「受外部条件阻塞」）

项目: pCryoxy
裁定人：WorkBuddy@zhn-tbxg2iah-win~zhn-x-w
裁定时间：2026-11-21 23:05（UTC+8）
回执内容：结论「受外部条件阻塞。test1 profile 已建立，但测试夹具锁路径绑定原 worktree；未运行测试。历史 8 项缺逐项日志，无法定性。」

## 一、裁定结论

**退回补证。不接受「受外部条件阻塞」。** 本卡不满足阻塞判定，理由见第二、三节。

## 二、已核实的机制（回执方判断中成立的部分）

`crates/secure-store/src/tests.rs`：

- `native_fixture_guard()` 用 `PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("target")`，锁文件为 `target/pc03-native-fixture.lock`；
- `Fixture::new()` 用 `std::env::current_dir()` 拼夹具根 `pc03-test-<hex>`。

因此「在 Zhn_X 的 worktree 构建、再把二进制复制到中立目录以 test1 运行」必然失败：`CARGO_MANIFEST_DIR` 已编译期写死，`create_dir_all`/`open().unwrap()` 会在 test1 无写权限的路径上 panic。该机制判断正确，**但它只否定了一种执行方式，不构成外部条件**。

## 三、为什么不是「外部条件」

存在不需要改产品代码、不需要提升、不需要修改真实 worktree ACL 的执行路径：

1. **在中立可写目录重建**：`C:\Users\Public\<中立目录>\`。实测 ACL 含 `NT AUTHORITY\INTERACTIVE:(OI)(CI)(IO)(M,DC)` 与 `(RX,WD,AD)`；test1 的 SID 为 `S-1-5-21-155457669-4072508151-1813346089-1002`，交互登录即 INTERACTIVE 成员，对新建子项有修改权。`CARGO_MANIFEST_DIR` 因此被烘焙到 test1 可写的路径。
2. **运行时 cwd 设为 test1 自己的 `%TEMP%`**：`Fixture::new` 的 root 随 cwd 落在 `C:\Users\test1\AppData\Local\Temp`，属主为 test1，满足 Windows 后端属主／祖先检查。

要点：**构建位置与运行 cwd 是两个独立变量**。把二者分开即消除冲突；以 `cargo test` 直接跑会强制 cwd＝crate 目录，所以须直接运行已构建的测试二进制（与 Linux 侧既有做法一致），并加 `--test-threads=1`。

若坚持使用真实 worktree 的 `target`（不推荐，会引入跨账户属主混杂），才需要一条人类执行命令，例如：
`icacls "C:\Users\Zhn_X\source\pCryoxy.wt\copilot-pc03\crates\secure-store\target" /grant "test1:(OI)(CI)M"`——这是备选，不是首选；选它须说明为何中立路径不可用。

## 四、退回后必须补齐的证据

1. 中立路径重建的完整命令与退出码（含 `--locked --offline`、`CARGO_TARGET_DIR` 取值），以及生成的测试二进制路径与 SHA-256。
2. 以 test1 实际启动的机制（`CreateProcessWithLogonW`/计划任务/其他）、启动账户确认（`whoami` 输出）、运行时 cwd 的绝对路径。
3. 全套 16 项（`--test-threads=1`）的逐项结果：名称、passed/failed/ignored、退出码；失败项贴关键错误（1168、NOT_ENOUGH_MEMORY、panic 位置等）。
4. 8 项失败的逐项定性表（可重现／不可重现／环境相关），以及 ACL／Credential Manager 隔离的实测回执（owner、DACL 原文、越界读取失败）。

若在中立路径下仍失败，须贴**首次失败的确切 panic/错误行**再判阻塞；不得以「未运行」直接给结论。

## 五、附带裁定

- **「历史 8 项缺逐项日志」不是本卡阻塞理由**。本卡目的就是以 test1 重新跑出逐项日志，历史日志缺失正是待解决对象。
- 服务身份（SeServiceLogonRight）仍按原口径记「未覆盖」，不阻塞 8 项定性；不得以计划任务/批处理登录冒充服务身份。
- 本裁定不改变 PC-03 状态：仍 `doing`／有条件通过；不合并、不部署、不标 done。
- 若人类明确否决中立目录方案且不批准任何 ACL，方可改判「受外部条件阻塞」，届时须写明已完成的构建/静态核验范围与确切阻塞项。

## 六、给实施方的可直接回复

```text
PC-03-WIN-V1 回执不接受「受外部条件阻塞」，退回补证。

夹具锁走 env!("CARGO_MANIFEST_DIR")/target、夹具根走 current_dir()，这两点你判断正确；
但这只否定「在 Zhn_X worktree 构建、复制二进制到中立目录运行」这一种方式，不构成外部条件。

请改走：① 在 C:\Users\Public\<中立目录> 重建（Public 的 INTERACTIVE 继承修改权覆盖 test1）；
② 直接运行测试二进制并把 cwd 设为 test1 的 %TEMP%，令夹具根落在 test1 私有目录；
③ 加 --test-threads=1，逐项记录名称/结果/退出码。

只有在中立路径下仍失败时，才允许判阻塞，且必须贴首次失败的确切 panic/错误行。
另：「历史 8 项缺逐项日志」不是本卡阻塞理由——本卡就是要去生成这些日志。
服务身份仍记未覆盖，不阻塞 8 项定性。
```
