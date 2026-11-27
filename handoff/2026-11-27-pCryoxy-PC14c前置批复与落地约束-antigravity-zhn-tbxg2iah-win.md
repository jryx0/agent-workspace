---
project: pCryoxy
author: antigravity@zhn-tbxg2iah-win~zhn-x-w
date: 2026-11-27
---

# PC-14c 前置批复与落地约束

- 依据：copilot 前置申请提交 `99160fb`；项目基座 `origin/main 3b4cb2cfef8a6a2ebc1b747741e0218d917fdc69`。
- 批复：人类（2026-11-27 21:59 UTC+8）整体批准建议方案，`antigravity` 审核通过。**准予在 `~/source/pCryoxy.wt/copilot-pc14c`（分支 `agent/copilot/pc14c`）开工**；保持 `doing`，交付后交 `antigravity` 终审。

## 一、D.1～D.6 冻结裁定

1. **D.1 Xray DNS（开放宿主直连路径）**：`REQ-12` 约束代理组全失效不转直连；`PC-04b` 已补回 `proxy/dns`，`G6`/`ADR-01` 业务走宿主直连官方 `xray-core v26.11.9`。开放结构化白名单 DNS（境内/直连、远端代理 DNS、`queryStrategy`、`disableCache`，默认 `["localhost"]`，禁透传原始 JSON；远端 DNS 仅接受 IP / `https://` / `tls://`），须落实防环且代理全失效不降级直连；Go 受限桥不动。
2. **D.2 健康参数 & 主出口 fail-closed**：
   - 上下界（先校验再转窄类型，越界/非有限浮点拒为 `InvalidInput`，持久化到 `PersistedState`）：`intervalMs` `5_000..=3_600_000`（30_000）；`timeoutMs` `500..=30_000`（5_000）且 **`timeoutMs < intervalMs`**；`concurrency` `1..=16`（硬锁 `PROBE_SLOT_LIMIT=16`）；`failuresToIsolate` `1..=10`（3）；`successesToRecover` `1..=10`（2）；`toleranceMs` 仅 `LowestLatency` 允许 `0..=5_000` 整数 ms（50，`Failover`/`RoundRobin` 须为 0）。
   - `activeProxyTarget`（`Node`/`Group`）：目标不存在或空组返 `InvalidInput`；删除正被引用的节点/组返 `Referenced`；空库首导且无目标时可自动择选首节点；默认代理规则在目标空或组全失效时落 `sys/reject`（禁转 `sys/direct`）；热下发失败保持旧状态与 `revision` 不变。
3. **D.3 订阅 `fetchMode` / `remarkFilter` / 请求头**：
   - `direct` 强制 `.proxy(None)`；`proxy` 仅走 pCryoxy 自身已就绪回环业务端口（禁碰 `10808`），未就绪返 `CoreUnavailable`；`auto` 就绪先代理、失败回退直连一次，未启直连；错误分层可增单一 `ErrorCode::FetchFailed`（同步 `SafeEvent::write_log`）。
   - `remarkFilter` 显式带 `filterMode: Exclude | Include`（默认 `Exclude`），禁回溯正则；若需引入锁内 `regex`/`regex-lite` 须另报依赖边（限 `pattern <= 256B` + `size_limit`），否则先用无回溯有界匹配子集并文档说明。
   - `userAgent` ≤ 256 B 单行 ASCII 禁 `\r\n`；`customHeaders` ≤ 16 对、RFC 7230 token 键（1..=64 B）、值 ≤ 512 B 禁 `\r\n\0`，禁覆写 `Host`/`Content-Length`/`Transfer-Encoding`/`Connection`/`Proxy-Authorization`/`Upgrade`/`TE`，敏感头禁入日志/事件/报错与无凭据备份。
4. **D.4 含凭据备份导入导出（G-02 / REQ-23）**：禁明文凭据导出。无凭据导出自动剥离节点凭据、`lanAuth` 密码与敏感订阅头，免确认。含凭据导出须经 `confirmation_open` 确认并设口令（`SecretString` ≥ 8 字符），复用锁内 `hmac`+`sha2`（PBKDF2-HMAC-SHA256 ≥ 200_000 轮 + 16 B 随机 salt）+ `aes-gcm`（AES-256-GCM + 12 B 随机 nonce + header AAD）生成 `PCRYBK01` 跨设备信封。覆盖导入须经 `confirmation_open`（取消返 `Cancelled`）；解密/校验全在内存与 staging 完成，失败零化并保持旧 Vault/快照/单指针/运行核心不变；传输用一次性 staging ticket（≤ 4 MiB / 60s TTL / 消费即零化，禁入 `self.cache`）。
5. **D.5 `node_credentials_reveal` / `url_ref` 迁移 / 运行日志**：桌面端单节点按需明文返回（不弹 OS 确认，禁批量），严禁入 `RuntimeHost.cache`、落盘、日志环或 `AppEvent`，后端 `Zeroizing`。读 `schema_version=1` 时将 `url_ref` 迁至明文 `url`（升 v2），新指针落盘成功前禁删旧 `url_ref`，读取失败不丢分组。运行日志环 ≤ 500 条（单条 ≤ 512 B）仅白名单结构化条目，用户标签清控制字符/ANSI ESC 截断 ≤ 64 字符，禁写 URL/凭据/分享链接/底层原始错误。
6. **D.6 文件与依赖/Proto 边界**：批准申请 A.1～A.7 文件范围；**不批准改 Proto / `proto.lock`**（现有 `StatsService/QueryStats` 已可查 `outbound>>>`）；**`Cargo.toml`/`Cargo.lock` 增边或改 feature 须逐项单独报批后再改**（`app_open_data_dir` Windows 可直接 `explorer.exe` + 规范化 `paths.root`，零新 feature）；`ui/src/` 仅限保编译/Mock 最小契约适配，不做 `PC-15a-v2` 布局重构，禁手改 `generated.ts`。

## 二、5 条源码级落地防坑约束

1. `plugin-xray/src/config.rs:256-262` 放宽 `0.0.0.0` 仅限 `!probe_only` 业务入站；`probe_only` 与 `lib.rs:668-671` `sys/api` 强锁 `127.0.0.1` 并配负向单测。
2. 打通健康参数 5 处硬编码：`health.rs:67,86`、`scheduler.rs:247,402,479`、`host.rs:1430`、`tauri-app/src/lib.rs:219`。
3. `statsOutbound*` 仅按 `pool/<scope>/<node-id>/<revision>` 第三段归并节点（排除 `probe/*`）；实例切换/计数回退按复位增量防下溢；清零重置宿主累计与基线，避免 `reset: true` 竞态。
4. `RealityOptions.mldsa65_verify` 沿用 `fd1cce8` 新增 `StoredSecurityOptions` 新 tag 兼容旧 tag 2/3；补真实 v1 `state.pointer.json` + v1 二进制 snapshot 迁移回归测试。
5. `node_credentials_reveal`、`node_update`（含新凭据）、`config_export_backup`、`config_import_backup` 明文输入输出绕开 `self.cache`。
