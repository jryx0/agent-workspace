# pRayShell v0.4 审核结论处置与待确认

- 项目: pRayShell
- 日期: 2026-11-19
- 跨 Agent 交互标识: `copilot@zhn-x-w`
- Worktree: `~/source/pRayShell.wt/copilot-second-round`
- Branch: `agent/copilot/prayshell-second-round`
- 基座: `master` @ `3d551c9edb009bc313c1966864584dcbe3152bfc`
- 状态: v0.4 文档修订完成，等待人类确认推荐项和后续复审；未认领实施任务

## 当前状态

独立审核结论为“有条件通过”。已将外部审核的高优先问题及用户裁决纳入 v0.4：

- Windows + Android 同步首发。
- HarmonyOS NEXT / iOS 均为后续升级平台。
- xray-core 是首发必选核心；其他核心保留 `ICoreProvider` 插件边界。
- app / core / Geo 分别支持检查、更新、校验、回滚。
- GeoIP/GeoSite 规则分流进入 P0。
- 小体积进入发布门槛。
- K-06 仅适用于共享仓 handoff/提示词等生成物；项目 `docs/` 可直接修订。
- `copilot@zhn-x-w` 是本 Agent 与其他 Agent 交互的唯一标识。

## 挂起任务（当前全量快照）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置 | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | S1 T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停 | S3 裁定 + 新 ADR + 重编卡面 | 无 worktree；todo | 重新认领 | 人类 |
| prnmgt | S2 P0 二次真机调研 | 2026-11-11 人类确认 | 厂家后台升级 | 升级 + 复跑 + 更新文档 | tmp 保留；worktree 已 remove | 续跑 | 人类 |
| prnmgt | S3 v4 / #18 | 2026-11-07 15:11 | 纸张口径未定 | S2 结论 + D-5~D-10 + 新 ADR | 仅 DRAFT | 重编卡后认领 | 人类 |

## v0.4 已落地

### 已裁决

| 事项 | 结果 |
|---|---|
| iOS | 与 HarmonyOS NEXT 同列后续升级 |
| Agent 交互标识 | 仅使用 `copilot@zhn-x-w` |
| K-06 | 仅适用于共享仓生成文档；项目 `docs/` 可直接修改 |

### 设计修正

- H-01：补运行时核心配置的私有目录、最小权限、退出/崩溃清理、不入诊断包。
- H-02：补 `Published → Revoked`。
- H-04：测试报告模板补齐 PAR/SUB/HLT/AI/WIN/AND 全组。
- H-05：新增“需求 → PRD → 架构 → 任务 → 测试”追溯矩阵。
- H-06：声明 v0.4 指标优先于根目录旧设计口径。
- K-01：增加低概率防御代码门槛。
- K-02：增加入口单次校验边界。
- K-03：接口按 P0/P1/P2 分级。
- K-04/K-05：主函数简洁、注释只写“为什么”。
- K-07：采用建议口径——真实逻辑优先；不可控外部依赖才用替身；FakePublisher 安全断言；真实 xray 冒烟必须存在。

## 推荐但尚未锁定

1. **UI**：原生 Windows/Android 与 Flutter/KMP 各做小型 PoC，比较体积、启动、系统 API 和维护成本。
2. **xray 接入**：Windows 验证受控进程；Android 验证 library/FFI；共同实现 `ICoreRuntime`。
3. **运行时配置**：建议用用户私有临时文件 + 最小权限 + 清理。若要求绝不落盘，只能走 in-process FFI。
4. **AI**：保持 P1，不参与核心连接闭环。
5. **共享**：保持 P1；首发只落同意、DryRun、publisher contract。
6. **更新模式**：自动检查，是否自动安装由用户策略与平台权限决定；任何组件替换均可回滚。
7. **签名**：release manifest 强制 SHA-256 + 签名，source/channel 白名单。
8. **Geo**：基础集内置或按需下载由双平台体积 PoC 决定，禁止重复打包 ABI。
9. **体积基线**：选低端 Android + 低端 Windows，统计总包、UI、业务、xray-core、Geo、ABI、资源。

## T2 自检 1–10

1. `memory/` 与 `config/` 存在，ACL 仅系统/管理员/当前用户；SSH key 项存在；`feishu-app-secret-parva.txt` 存在，`feishu-app-id-parva.txt` 缺失，已记录为人类整改项，未读取内容。
2. MCP 9101 离线；本轮使用内置文件工具，不阻塞。
3. 共享仓已只读 fetch；HEAD 与 origin/backup 基线一致，工作区有既有他人改动，未 pull、未同步。
4. 无 `memory/.compact-lock`。
5. 未使用 Python/venv，标记不适用。
6. 定制 MCP registry 无项目所需条目，本轮不安装 MCP，标记不适用。
7. `~/.agent-docs` 可达，未发现 conflict 文件；未直接编辑同步区。
8. `tools-scan.sh --check` 通过。
9. 全局规范已注入；pRayShell `AGENTS.md` 已挂接 `global/rules.md` 与第八节。
10. `proxy-check.sh` 通过；代理端口可连，双远端与 HEAD 一致；pRayShell 项目仓无 remote。

## 验证结果

- 七份 `docs/` 文档已升至 v0.4。
- Markdown 本地链接、敏感信息、真实 URL、盘符路径检查待最终复跑。
- 未写工程代码、未安装依赖、未认领任务、未执行测试、未 push/sync/deploy。
- 主 worktree 既有改动未触碰。

## 下一步

1. 其他 Agent 以 `copilot@zhn-x-w` 对 v0.4 做只读复核。
2. 人类确认推荐项。
3. 冻结推荐项后生成正式任务卡。
4. 其他 Agent 按独占 worktree 实施；主审 Agent 审核。

> 交互署名：`copilot@zhn-x-w`
