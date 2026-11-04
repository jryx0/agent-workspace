# 组织级记忆（append-only，规范 三-1）

> 只允许在文件末尾追加，禁止修改/删除/重排已有行。
> 每条格式：[@agent名 @设备名 YYYY-MM-DD HH:mm UTC+8] 内容

[@workbuddy @zhn-tbxg2iah-win 2026-11-04 15:35 UTC+8] 本机完成规范 v1.7 初始化：建立 ~/.agent-shared（Git 仓库，main 分支）、~/.agent-tools（含 venvs/workbuddy）、~/.agent-docs 三大目录；生成 env/ 全套登记表与模板。待办：人类建 Gitee 主库 + GitHub 备份库并配置双远端；选定文档同步工具；rclone 与 gitleaks 未安装；MCP 服务未配置；文档同步区与 NAS 挂载未接入。

[@workbuddy @zhn-tbxg2iah-win 2026-11-04 15:45 UTC+8] 双远端配置完成并首推成功：origin=Gitee 主库 https://gitee.com/ParvaUltra/agent-workspace.git，backup=GitHub 备份库 https://github.com/jryx0/agent-workspace.git。仓库级 Git 身份设为 zhn <997524210@qq.com>（首提交已重置署名，新号 176a4a3）。已封装 env/git-sync.sh 与 git alias `git sync`（双远端推送）。待办：人类提供 GitHub 提交邮箱或改用 noreply 地址；gitleaks/rclone 安装；文档同步工具与 NAS 接入。

[@workbuddy @zhn-tbxg2iah-win 2026-11-04 15:55 UTC+8] 状态更新：① GitHub 提交邮箱与 Gitee 相同（997524210@qq.com），无需改配置，人类需自行确认该邮箱已在 GitHub 账号验证；② 本机暂定为主设备（后续会改，已登记 _devices.md）；③ NAS 已映射 Z:\ 并验证可达（22T），`nas://` 解析已写入设备档案；④ 百度网盘冷备改用 NAS 自带云同步工具，rclone 不安装（方案变更，manifest 生成与月度恢复演练要求不变，由人类在 NAS 侧配置）；⑤ gitleaks v8.30.1 已装至 ~/.agent-tools/bin 并加入用户 PATH，全局 pre-commit hook（~/.agent-tools/hooks，core.hooksPath 已设）经假私钥测试确认可拦截。剩余待办：文档同步工具选型接入 ~/.agent-docs；MCP 服务配置；密钥手动分发至 config/。

