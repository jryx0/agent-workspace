# 组织级记忆（append-only，规范 三-1）

> 只允许在文件末尾追加，禁止修改/删除/重排已有行。
> 每条格式：[@agent名 @设备名 YYYY-MM-DD HH:mm UTC+8] 内容

[@workbuddy @zhn-tbxg2iah-win 2026-11-04 15:35 UTC+8] 本机完成规范 v1.7 初始化：建立 ~/.agent-shared（Git 仓库，main 分支）、~/.agent-tools（含 venvs/workbuddy）、~/.agent-docs 三大目录；生成 env/ 全套登记表与模板。待办：人类建 Gitee 主库 + GitHub 备份库并配置双远端；选定文档同步工具；rclone 与 gitleaks 未安装；MCP 服务未配置；文档同步区与 NAS 挂载未接入。

[@workbuddy @zhn-tbxg2iah-win 2026-11-04 15:45 UTC+8] 双远端配置完成并首推成功：origin=Gitee 主库 https://gitee.com/ParvaUltra/agent-workspace.git，backup=GitHub 备份库 https://github.com/jryx0/agent-workspace.git。仓库级 Git 身份设为 zhn <997524210@qq.com>（首提交已重置署名，新号 176a4a3）。已封装 env/git-sync.sh 与 git alias `git sync`（双远端推送）。待办：人类提供 GitHub 提交邮箱或改用 noreply 地址；gitleaks/rclone 安装；文档同步工具与 NAS 接入。

[@workbuddy @zhn-tbxg2iah-win 2026-11-04 15:55 UTC+8] 状态更新：① GitHub 提交邮箱与 Gitee 相同（997524210@qq.com），无需改配置，人类需自行确认该邮箱已在 GitHub 账号验证；② 本机暂定为主设备（后续会改，已登记 _devices.md）；③ NAS 已映射 Z:\ 并验证可达（22T），`nas://` 解析已写入设备档案；④ 百度网盘冷备改用 NAS 自带云同步工具，rclone 不安装（方案变更，manifest 生成与月度恢复演练要求不变，由人类在 NAS 侧配置）；⑤ gitleaks v8.30.1 已装至 ~/.agent-tools/bin 并加入用户 PATH，全局 pre-commit hook（~/.agent-tools/hooks，core.hooksPath 已设）经假私钥测试确认可拦截。剩余待办：文档同步工具选型接入 ~/.agent-docs；MCP 服务配置；密钥手动分发至 config/。

[@workbuddy @zhn-tbxg2iah-win 2026-11-04 16:05 UTC+8] ① NAS 规范目录 Z:\backup\ 与 Z:\docs\ 已创建；② keys-checklist.md 登记两把 PuTTY 私钥（putty-oraclevps.ppk、putty-printer-monitor.ppk，待人类复制到本机 config/）；③ github.com 已配置作用域 SOCKS5 代理 socks5://127.0.0.1:10808（仅 GitHub 生效，Gitee 直连；经 ls-remote 验证走代理可达，代理客户端未运行时 GitHub 访问会失败）。

[@workbuddy @zhn-tbxg2iah-win 2026-11-04 16:15 UTC+8] NAS→百度网盘冷备链路已由人类在 NAS 侧打通。按规范 五-3 执行要点：部署后第一周人类每日核对 manifest 是否生成；每月随机抽 1–2 文件做恢复演练（拉回比对 sha256）；连续 3 天失败必须人工可感知告警。密钥分发进行中：keys-checklist.md 两把 PuTTY 私钥（putty-oraclevps.ppk、putty-printer-monitor.ppk）待人类复制到本机 ~/.agent-shared/config/，复制完成后由 agent 核对存在性并更新清单状态。

[@workbuddy @zhn-tbxg2iah-win 2026-11-04 16:16 UTC+8] 密钥分发完成：私钥原件位于 ~/.ssh/（OpenSSH+PuTTY 双格式），已复制 5 个私钥文件至本机 config/（Oracle-ssh-key-2026-10-06.key/.ppk、printer_ubuntu、id_ed25519/.ppk），git check-ignore 确认 config/ 被排除。keys-checklist.md 已更新为实际文件名并标注已分发日期。注意：~/.ssh/ 为 SSH 实际工作位置（ssh/git 直接引用），config/ 为规范指定的登记副本，两处内容一致。

[@workbuddy @zhn-tbxg2iah-win 2026-11-04 17:00 UTC+8] 文档同步区接入完成：~/.agent-docs 为 Junction → WPS企业云盘\中建三局\我的企业文档\agent-docs（人类以共享文件夹方式在 WPS 单独同步此目录，联接读写测试通过）。规范二-3 的同步工具选型由人类定为 WPS 网盘企业版（替代坚果云建议）。已知限制：① WPS 网盘无 Linux 同步客户端，Linux/Termux 设备 docs:// 引用走金山文档网页版或 NAS 中转，已记入设备档案；② 团队文档（中建三局团队文档树）已全量落地本机磁盘，为 WPS 同步行为，agent-docs 本身经共享文件夹隔离不受影响；③ `账号信息整理.html`（含账号敏感信息）现位于 agent-docs 并同步至企业云盘，已提示人类注意敏感文件分级。

[@workbuddy @zhn-tbxg2iah-win 2026-11-04 17:10 UTC+8] 【事故复盘】agent-docs 同步配置冲突（2026-11-04 16:20-17:05，已解决）：人类自行在 WPS 配置共享文件夹同步期间，agent 并行执行了删快捷方式/建联接/建目录等操作，导致云端出现 agent-docs 与 .agent-docs 双条目、本地删除与云端回拉拉锯。最终人类自行清理，~/.agent-docs 恢复为本地普通目录（22 文件完整），WPS 侧已清空，同步载体暂未选定。教训（后续 agent 必读）：
1. 【协作纪律】人类正在操作的目录/工具，agent 不得并行修改；动手前先确认人类配置进度与意图，宁可等一轮确认。
2. 【同步目录铁律】Windows 快捷方式（.lnk）放入同步目录只上传文件本身，内容不同步；固定路径需求用目录联接（mklink /J），方向必须是 本地固定路径 → 同步工具的真实文件夹。
3. 【云端权威】云同步工具运行时，云端副本是权威：本地删除会被立即拉回；删除云端条目必须在客户端/网页 UI 操作。
4. 【删除保护】本机 safe-delete（genie-trash）对联接和同步活动目录的删除会 fail-closed 拦截且无法绕过；此类删除优先由人类在 UI 完成，agent 不要反复重试。
5. 【选型先核平台矩阵】WPS 网盘无 Linux 同步客户端（WPS Office Linux 版只管编辑）；选定同步工具前先核对 Windows/Linux/iOS/鸿蒙 全平台支持。
6. 【当前状态】~/.agent-docs=本地普通目录，docs:// 引用仅本机可解析，跨设备能力待同步载体确定后恢复；WPS 企业云盘中的 agent-docs 云端副本由人类自行处置。

[@workbuddy @zhn-tbxg2iah-win 2026-11-04 17:45 UTC+8] 【规范升级 v1.8】人类批准并采纳全部六条修订，global/rules.md 已更新：① 项目代码根统一 `~/source`（原 ~/work 废弃），目录已建，布局 主worktree `~/source/<项目名>` + agent worktree `~/source/<项目名>.wt/<agent名>`；② 任务认领机制（memory/projects/<项目>.md 任务登记节，登记即锁定）；③ 分支准出标准（rebase+自测+`Agent:` trailer，worktree 内独立身份 user.name=zhn-<agent名>）；④ gitleaks 全局 hook 改链式委托（~/.agent-tools/hooks/pre-commit 已重写并验证：先 gitleaks 后转发项目自身钩子，husky 不再被覆盖）；⑤ agent 端口段：trae=9200-9299、workbuddy=9300-9399（已登记设备档案）；⑥ 人类操作优先原则成文。影响范围：trae 的既有 handoff 中 ~/work 表述按 v1.8 理解为 ~/source。


[@workbuddy @zhn-tbxg2iah-win 2026-11-04 17:15 UTC+8] Trae 侧私有记忆已按人类要求清空（删除 .trae-cn/memory 下本项目 topics.md），本项目后续唯一事实源改为 ~/.agent-shared。核对 global/rules.md 与人类下发 v1.7 一致，无需覆盖。自检（规范八）：keys-checklist 5 项在 config/ 齐全、无 .compact-lock、venvs/workbuddy 存在、~/.agent-docs 存在、git 已最新；**MCP 9101/9102 未启动**。待办：①人类运行 env/start-mcp.bat；②打印机监控项目未登记 repos.md；③线上域名 prnmgt.parva.dpdns.org 带 #/overview 刷新报「脚本未执行」，该文案不在本仓库代码中，疑为另一套前端部署，待确认归属。交接见 handoff/2026-11-04-trae重置与规范接入-zhn-tbxg2iah-win.md。

[@trae @zhn-tbxg2iah-win 2026-11-04 17:20 UTC+8] 【署名更正】人类指出本会话实际执行者为 trae，不是 workbuddy。已在 env/agents.md 新增 `trae | zhn-tbxg2iah-win` 登记行；自本条起所有记忆与交接一律署名 trae。上一条 17:15 的署名 workbuddy 按 append-only 原则保留原文不改，但该署名无效（内容仍有效）。





