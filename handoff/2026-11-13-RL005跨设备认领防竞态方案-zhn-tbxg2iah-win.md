# RL-005 跨设备任务认领防竞态方案（设计交付，待批准）

[@trae @zhn-tbxg2iah-win~zhn-x-w 2026-11-13 10:54 UTC+8]　项目: 全局

> 任务：`handoff/2026-11-13-多设备多Agent协同评估后续任务卡-zhn-tbxg2iah-win.md` 第三节 RL-005。
> 本文件只做设计与临时副本演练；**未改现有任务登记格式、未新增 `memory/claims/`、未实现锁服务、未改规范**。
> 防撞键始终为「项目 + 任务ID」；账号只用于定责与联系，不作为互斥键。

## 一、结论

当前 append-only 登记 + Git 同步**不能提供原子互斥**：两台设备都 append 后各自 push，Git 可能自动合并两行，合并结果就是双认领；若 push 冲突，也没有规定谁必须停。

推荐 **A. 固定路径 claim 文件 + 隔离 worktree 中 `git push origin HEAD:main` 作为仲裁 + 双远端同步 + 失败关闭**，并保留现有登记行作为人类可读台账（claim 管锁、登记管审计）。该方案不引入外部服务、不新增依赖，只用现有 Git；代价是认领多一次 commit/push，且必须严格遵守「推送边界只含 claim、push 被拒即停、backup 未成功不开工」。

## 二、现状与失败原因

| 事实 | 影响 |
|---|---|
| 认领 = 在 `memory/projects/<项目>.md` 追加一行 | 两行可同时存在；Git 合并不会判断语义冲突 |
| 拉取只从 origin，backup 只做镜像 | 若有人向 backup 写，仲裁失效；必须明确 **origin 唯一写入口** |
| 无 claim 文件、无租约、无释放协议 | 执行者异常退出后，任务可能永久显示 doing，或被人误以为可抢 |
| `env/git-sync.sh` 用 `push --all` | 认领场景不能用它，必须显式 `git push origin main`，避免顺带推其他分支/标签 |

## 三、威胁／竞态场景表

| # | 场景 | 触发条件 | 后果 | 检测方式 | 恢复／失败关闭 |
|---|---|---|---|---|---|
| 1 | 两设备同时认领同一任务 | 双方都看到 todo，同时 append／创建 claim | 双开工、重复改动 | push 一成功一被拒；或合并后出现两行 | 被拒方 fetch 后看到他人 active claim，**立即停工**；不自动 rebase 重试 |
| 2 | 离线旧快照 | 设备长时间未 fetch，或网络不可达 | 以为任务空闲，实际已被认领 | 开工前 fetch 失败；或 claim 已存在 | **fetch 失败即停**；离线只允许只读，不允许认领/写共享仓 |
| 3 | 同步冲突 | 双方改同一登记文件相邻行，或同时改 claim | 合并冲突/自动合并出双认领 | `git push` 非快进；`git status` 冲突 | 不手工猜谁赢；以 origin 的 claim 为准；冲突交人类裁决 |
| 4 | 执行者异常退出 | 认领后崩溃、断电、会话丢失 | claim 长期 active，任务被占死 | claim 时间戳过旧；登记 doing 无进展 | 不自动过期、不自动抢占；由 owner 或人类把 claim 标 `abandoned` 并写明原因 |
| 5 | 时钟偏差／租约误判 | 两设备时间不同，自动过期 | 双方都认为对方过期，双抢占 | 两边都改 claim | **不做自动过期**；租约只作提示，释放必须人类/owner 显式提交 |
| 6 | 写错远端 | 向 backup 或本地分支 push claim | origin 无锁，仲裁失效 | `git ls-remote origin` 与本地不一致 | 只允许 `git push origin HEAD:main` + `git push backup HEAD:main`；backup 只读镜像 |
| 7 | 本地 main 领先／工作区脏 | 本地已有无关提交或未提交改动 | 直接 push 会把无关改动一并发布 | `HEAD != origin/main` 或 `git status --porcelain` 非空 | **停**；改用临时 worktree；不 reset/stash/代提交 |
| 8 | 推送边界混入其他文件 | 用了 `git add -A`／`commit -a` | 无关改动随 claim 发布 | `git diff --name-only origin/main..HEAD` 不是仅 claim | 立即停、不推送、丢弃临时 worktree |
| 9 | backup 推送失败 | GitHub 不可达/凭据失效 | origin 占锁但未完成双写 | `ls-remote backup` != origin | 不开工；重试 backup；人类可标 `aborted` |

## 四、方案比较

### A. 固定路径 claim 文件 + origin push 仲裁（推荐）

- 路径：`memory/claims/<项目>/<任务ID>.claim`（**固定文件名**，同任务只有这一个路径）。
- 内容（YAML 风格纯文本，便于 diff）：
  ```text
  project: global
  task_id: RL-005
  owner: trae@zhn-tbxg2iah-win~zhn-x-w
  status: active            # active | released | abandoned
  claimed_at: 2026-11-13T10:46:00+08:00
  base_commit: <认领时 origin/main 的 SHA>
  note: <可选，一句话>
  ```
- 认领协议（必须按序，**隔离推送边界**）：
  1. `git fetch origin`；失败 → **停**。确认 `origin/main` 为唯一仲裁基线。
  2. 读 `git show origin/main:memory/claims/<项目>/<任务ID>.claim`：
     - `active` 且 owner 不是自己 → **停**；
     - `released` / `abandoned` / 不存在 → 可继续。
  3. **隔离工作区**：`git worktree add --detach <tmp> origin/main`，不直接在本地 `main` 上提交；进入后确认 `git status --porcelain` 为空。
  4. 只写 claim（固定路径），`git add -- <claim路径>`，用 `git commit --only -- <claim路径>`；**禁止** `git add -A`、`git commit -a`、无 refspec 的 `git push`、`git push --all`、`git-sync.sh`（后者会推所有分支/标签）。
  5. 推送前自检：`git rev-parse HEAD^` 必须等于 `origin/main`，且 `git diff --name-only origin/main..HEAD` **只有 claim 一个文件**；任一不满足 → **停，不推送**。
  6. `git push origin HEAD:main`；被拒 → **停**，不自动 rebase 重试。
  7. `git push backup HEAD:main`；失败 → claim 仅在 origin 生效，**不得开工**，重试 backup 或交人类处理；不放宽为单远端。
  8. 双远端 `git ls-remote` 均等于本地 HEAD，且回读 claim 的 owner/base 是自己；全部一致才在 `memory/projects/<项目>.md` 追加认领行并开工。
  9. 移除临时 worktree。
- 若本地 `main` 领先 `origin/main`、或工作区有未提交改动：**不 reset、不 stash、不提交他人改动**，直接改用临时 worktree；无法隔离 → **停**。
- 释放：owner 把 claim 改为 `status: released`，同样只在隔离 worktree 中提交，`git push origin HEAD:main` + `git push backup HEAD:main`；不删除文件（保留最后一次状态，历史在 Git log）。
- 异常：owner 失联时，由人类把 claim 改 `abandoned` 并写明原因/时间；**其他 agent 不得自行接管**。
- 优点：最小、无新服务；固定路径使 Git push 成为事实上的 compare-and-swap；审计完整。
- 缺点：每次认领多一次 commit/push；依赖所有人遵守「被拒即停」；需人类/owner 处理僵尸 claim。
- 适用：当前两设备、低频认领、强审计的协同仓。

### 与现行双远端规则的兼容（不改规则）

- claim 是共享仓写入，**默认仍遵守现行「五-1 双远端」**：先 `origin`、后 `backup`，两者都成功才算认领生效。origin 只承担仲裁，backup 只做镜像，不参与仲裁。
- **backup 推送失败**时：origin 上的 active claim 已占锁，其他设备会保守地停；owner **不得开工**，必须补推 backup，或由人类把 claim 标 `aborted` 后再释放。这样不违反「禁止只推一个远端」——因为未双推成功前不算认领完成。
- `git-sync.sh` 用 `push --all`，会带出无关分支/标签，**不用于 claim**；claim 只用显式 refspec `HEAD:main` 分别推两个远端。
- 若希望「backup 不可用时仍允许认领」，那是**规则例外**，需人类明确批准修改 五-1 或 三-5 ⑤；本方案不默认采用。

### B. 专用 claims 分支／ref

- `refs/heads/claims/<项目>/<任务ID>` 原子创建；释放删除 ref。
- 优点：不污染 main 工作树，ref 创建/删除本身就是原子操作，审计在 reflog。
- 缺点：agent 工具链要理解 refs；clone/fetch 默认不取自定义 ref；排障成本高；仍需规定「push 被拒即停」。
- 结论：作为 A 的审计增强备选，不作为首选。

### C. 人工确认 fail-closed

- 跨设备认领必须先由人类在共享通道确认，agent 才开工。
- 优点：零新机制、最强兜底；缺点：吞吐低、依赖人类在线。
- 结论：作为 A 失效时的最小兜底；不单独作为长期方案。

### D. 外部锁／协调服务

- 需新增服务、凭据、可用性保障；违反「不预设外部服务、不新增依赖」。
- 结论：仅在未来设备数/并发显著上升且人类另行批准时评估；本次不选。

## 五、失败行为与恢复步骤

| 失败点 | 必须行为 | 恢复 |
|---|---|---|
| `git fetch` 失败 | 不认领、不写共享仓 | 网络恢复后重新走协议 |
| claim 已 active（他人） | 不 append 登记、不开工 | 等释放或请人类裁决 |
| `git push` 被拒 | 不自动 rebase/重试；fetch 后重读 | 若他人 active → 停；若已释放 → 重新按协议认领 |
| push 成功但 fetch 校验不一致 | 视为未认领，停止 | 报告人类，人工核对 origin |
| 执行者中断 | claim 保持 active | owner 释放；owner 失联由人类标 abandoned |
| 双认领已发生 | 双方立即停写共享仓 | 人类按 claim 时间/commit/证据裁决，败者回滚未提交改动 |
| 本地 main 领先或工作区脏 | 不在本地 main 上提交；改用临时 worktree | 无法隔离 → 停；不 reset/stash/代提交 |
| claim 提交混入其他文件 | 不推送；丢弃临时 worktree | 重新从 `origin/main` 建隔离 worktree |
| backup 推送失败 | origin claim 已占锁，但**不开工** | 重试 backup；人类可把 claim 标 `aborted` 后释放 |

## 六、并发演练（可重复）

### 设计

在系统临时目录建 bare origin + bare backup + 两个 clone（A/B），不改共享仓：

1. 初始化 bare origin + bare backup，seed 提交 `memory/claims/demo/.keep`，分支 `main`，双远端同步。
2. A/B 各自写同一路径 `memory/claims/demo/T-001.claim`（owner 不同），各自 commit。
3. **顺序轮**：A 先 push；B 再 push，预期 B 非快进被拒。
4. B fetch 后读取 `origin/main` 的 claim，确认 owner=A；B 必须停。
5. A 释放（status: released）并 push；B fetch 后重新认领，预期成功。
6. **并发轮**：A/B 同时写 T-002 并同时 push；统计退出码，预期恰好一个 0、一个非 0；读取远端 winner。
7. **推送边界轮**：在本地 `main` 先造一个无关提交，协议必须检测 `HEAD != origin/main` 并停止；随后用 `git worktree add --detach origin/main` 隔离，确认 `HEAD^ == origin/main` 且 `diff --name-only` 只有 claim。
8. **双远端轮**：隔离 worktree 中先后 `git push origin HEAD:main`、`git push backup HEAD:main`，确认两边 SHA 相同；再把 backup URL 指向不存在路径，确认 backup 失败后必须停、不得开工。
9. 清理临时目录。

### 实际结果（2026-11-13 10:49–10:53，本机临时副本）

```text
顺序轮：
A push OK
B push REJECTED (fail-closed)
origin claim: owner: A / status: active
A release OK
B claim after release OK
origin claim: owner: B / status: active

并发轮（同时 push 同一路径）：
exit codes: A=0 B=1
origin winner: owner: A / status: active

推送边界轮：
dirty/ahead check: HEAD=22097ca origin=064a87c -> STOP if differ
STOP: local main ahead, do not push
parent_is_origin=yes
changed_files=memory/claims/demo/T-004.claim,
origin claim push OK
backup claim push OK
origin=f11caddc backup=f11caddc head=f11cadd
backup failure -> claim on origin only, agent must NOT start
```

### 通过／失败判据

- **通过**：同一任务同一时刻只有一个 push 成功；失败方 fetch 后检测到他人 active 并停止，无共享仓写入；释放后他人可重新认领；并发轮退出码恰好一个 0；本地领先时协议停止；claim 提交仅含一个文件；origin/backup SHA 一致；backup 失败时不开工。
- **失败**：两个 push 都成功；失败方继续开工；失败方自动 rebase 重试覆盖 winner；claim 路径不固定导致两条记录并存；直接向 backup 先写或只写 backup；claim 提交混入其他文件；本地领先仍直接 push。

## 七、需人类批准的事项（未实施）

1. 在规范 三-5 ⑤／三-4 增加「认领 claim 协议」：固定路径、**origin 唯一仲裁入口 + backup 镜像（仍按 五-1 双推）**、隔离 worktree、推送边界只含 claim、push 被拒即停、禁止自动 rebase 重试、释放/abandoned 规则。
2. 新增目录 `memory/claims/<项目>/`（首次使用时由认领者创建）。
3. 是否增加极简 `env/claim.sh`（只封装 fetch→读→写→push→校验）——属新增脚本，需批准。
4. 是否在 origin 开分支保护（禁止 force-push、要求线性历史）——服务器设置，需人类操作。
5. 是否保留现有登记行作为台账（推荐保留；claim 管锁，登记管人类可读审计）。

## 八、未做

- 未创建 `memory/claims/`，未改任何任务登记行格式，未改规则正文，未加脚本或依赖，未改远端设置。
- 未把演练用的临时仓留在共享仓或工作区。

## 九、挂起任务（当前全量快照，2026-11-13 10:54 UTC+8）

| 项目 | 任务ID | 挂起于／裁决出处 | 原因 | 解挂前置（可验证条件） | 现场 | 解挂后动作 | 解挂权 |
|---|---|---|---|---|---|---|---|
| prnmgt | **S1** T-059/T-060/T-061 | 2026-11-07 人类 D-4 | v3 三卡暂停，合并为一次 ALTER + 一次部署 | S3 人类裁定 + 新 ADR 批准 + 重编卡面 | 无 worktree；卡面 todo | 重编卡面后重新认领 | 人类 |
| prnmgt | **S2** P0 二次真机调研 | 2026-11-11 人类确认 | 富士 CWIS 无单双面统计，厂家后台升级中 | 厂家升级完成 + 复跑三台探测 + 更新调研文档 | tmp 快照保留；worktree 已 remove | 续跑不重开卡 | 人类 |
| prnmgt | **S3** v4 批次 / #18 | 2026-11-07 15:11 | 纸张消耗口径重编，数据可行性未定 | S2 结论 + D-5~D-10 逐条裁定 + 新 ADR | 仅 DRAFT，未写卡面 | 裁定后重编拆卡再认领 | 人类 |

**已解挂／不计入防撞**：prnmgt S4 T-064 已解挂回 todo。

## 十、返工记录（2026-11-13 10:54 UTC+8，按审查意见）

1. **push 边界**：改为在 `git worktree add --detach origin/main` 的隔离工作区认领，只提交固定 claim 路径；推送前强制校验 `HEAD^ == origin/main` 且 `diff --name-only origin/main..HEAD` 只有 claim；禁止 `add -A`／`commit -a`／无 refspec push／`push --all`／`git-sync.sh`。本地 main 领先或工作区脏时直接停，不 reset/stash/代提交。
2. **与双远端规则兼容**：claim 仍按 五-1 双推 origin→backup，两者都成功才算认领生效；origin 只仲裁、backup 只镜像。backup 失败时 claim 留在 origin 占锁但**不得开工**，补推或由人类标 `aborted`；「backup 不可用仍可认领」属规则例外，需人类批准，不默认。
3. **时间戳**：快照与文件头由 10:52 更正为实际生成时间 **10:54 UTC+8**。
4. 任务卡中「819438」串字为他人未提交改动，本 agent 未修改、未纳入提交。
