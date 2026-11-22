# pCryoxy PC-03 W5 runner 第四轮返工交付

- 项目: pCryoxy
- 交付者: copilot@zhn-tbxg2iah-win~zhn-x-w
- 日期: 2026-11-22
- 状态: 第四轮实现与两宿主自测完成；PC-03 保持 doing，等待审核方跨账户 W5 复测。
- 项目提交链: `dc987a272210ea9632ad4ab468e7778c6ae90408` 修正 clippy/cleanup；`2885babf1e8bb0da318ee3a28ce5bf1da5d0342e` 将 cleanup fallback 进一步限定为 key-id 确实不存在（最终 HEAD，父提交为 `dc987a2`）
- 裁定依据: [PC-03 第四轮复核裁定](./2026-11-22-pCryoxy-PC03第四轮复核裁定-3934b65-zhn-tbxg2iah-win.md) §2

## §2 第 1～5 项逐项证据

| # | 要求 | 修复与证据 |
|---|---|---|
| 1 | List 序列化兼容 5.1/7 | `Get-W5TestResult` 将 `checks` 改为 `$checks.ToArray()`；W5 stage 汇总同时把 `$w5Results` 改为 `.ToArray()`，消除 `PSCustomObject` 遇到 `List[object]` 时的 `Argument types do not match`。两个宿主实际三阶段运行均未崩溃，六个请求都生成 `.done`，无 `.running`。 |
| 2 | 5.1 显式加载 `System.Security` | runner 启动时检测并显式 `Add-Type -AssemblyName System.Security`，同时验证 `ProtectedData` 类型可用。5.1.26100.9818 与 7.6.10 两处实测均为 `dpapi=True`；六个请求的 preflight 均为 `READY`，`dpapi=ok`。 |
| 3 | 修 clippy 并贴门禁退出码 | `tests.rs:1186` 去掉 `create_dir_all` 的 needless borrow。`cargo fmt --package secure-store -- --check` exit 0；`cargo clippy -p secure-store --all-targets -- -D warnings` exit 0；`cargo test -p secure-store --lib` exit 0（17 passed，0 failed，4 ignored）。 |
| 4 | 两宿主实际三阶段 | 使用最终项目提交 `2885bab…` 生成的测试二进制，Windows PowerShell 5.1 与 pwsh 7.6.10 各跑 write-own → read-foreign → cleanup；新请求 ID 见下表。每个阶段均有 `.done` 与 `.result`，预检均 READY。这里按裁定采用 Zhn_X 同账户自测，read-foreign 的结构化 FAIL 是预期的“缺少 pcx-t2 交换 fixture”判定，不代表真实跨账户 W5 通过。 |
| 5 | 两项低风险 | 代码注释明确 `dpapi-protected.bin` 只是跨账户 DPAPI 探针，产品 vault 主密钥仍在 Credential Manager。cleanup 只在两个精确 `<id>` 根为普通目录或不存在、manifest 无 target，且本地/交换 key-id 均确实不存在时视为“初始化尚未到凭据写入”；任何 marker 已存在但不可读或无效时仍拒绝，避免误删可恢复凭据。额外用空目录请求 `8e000000000000000000000000000001` 实跑 cleanup：exit 0，credential/local/exchange 三项均为 `absent`。 |

## 双宿主 `.done/.result` 摘要

测试二进制 SHA-256：`7A98A368335BA556723D295978A80148FD51B287DC9405486869694A6435786C`。

runner 源与 Public 固定副本 SHA-256：`D223DFB3FF5DAF47BEE266B77B0D18AA45C12C2CD1BE6EDB390927287BAFFD29`。

| 宿主 | 请求 ID | 阶段 | preflight | stage | `.done` hashes.sha256 | `.running` |
|---|---|---|---|---|---|---|
| 5.1.26100.9818 | `53000000000000000000000000000001` | write-own | READY | PASS | `4ba586d3d2967363271f257dc5629703354f2a28b409a78b6e3d5cf7d572c8ae` | 无 |
| 5.1.26100.9818 | `53000000000000000000000000000002` | read-foreign | READY | FAIL | `3aeac3cd5963406c9a9a31f4046f5ad1d451cc2888136106fa5442b1ffc62217` | 无 |
| 5.1.26100.9818 | `53000000000000000000000000000003` | cleanup | READY | PASS | `3072dc0cc00a827f10ac7caa7bbff90a521c785d061658c43605f657a08b8f83` | 无 |
| pwsh 7.6.10 | `71000000000000000000000000000001` | write-own | READY | PASS | `4193d3a0d2cf4f2888073c235dfe6730a2e5fce1884ed8251ebab9044bfd59e5` | 无 |
| pwsh 7.6.10 | `71000000000000000000000000000002` | read-foreign | READY | FAIL | `f7d92fadfdf4eed57f323ed9ee9a990f460b2b1df68478fa33fb2065dc094549` | 无 |
| pwsh 7.6.10 | `71000000000000000000000000000003` | cleanup | READY | PASS | `9fabe0f93eb10f8ca7a2a5871f225d480e1bebb7d00db4d1b476dd811db12be6` | 无 |

两个 read-foreign 结果各包含三个检查：`read-foreign / all-checks-pass / error / exchange-fixture-missing`，以及 reader 凭据、临时目录均为 `absent`。这证明 runner 在 Zhn_X 同账户自测下完成结构化判定与收尾，而不把缺少异账户 fixture 错报为跨账户 PASS。

六个请求均通过 DPAPI、Credential Manager（cleanup retry 0）与 ACL 预检；`C:\Users\Public\pcryoxy-xacct\inbox\<id>.result` 和 `.done` 保留作本机证据。清理完成后 `%LOCALAPPDATA%\pcryoxy-xacct` 子项数为 0，`x\zhn_x`、`x\pcx-t2` 子项数均为 0，W5 凭据 target 数为 0。outbox 的历史 pcx-t2 产物未由 Zhn_X 改写。

## 尚待审核

未执行计划任务，也未宣称真实双账户 W5 通过。下一轮审核方应使用新 ID 对 Zhn_X→pcx-t2 与 pcx-t2→Zhn_X 两个方向分别执行 write-own → read-foreign → cleanup，并复核四项安全判定。
