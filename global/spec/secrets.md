> **来源**：`global/rules.md` 的分卷（v2.6 起拆出；**不单独编号**，随 `rules.md` 版本生效）
> **原编号**：六（含 六-1）
> **触发**：新增／轮换／废弃密钥、配置 gitleaks 钩子、处置密钥泄漏事故时
> **效力**：与 `rules.md` 同等，受最小红线④保护，修订流程见 `rules.md` 第十节；本文件是该章节的**唯一正文**（〇⑤）。
> **引用写法**：`三-7〔spec/deploy.md〕` 表示该章节正文在所注分卷；未注路径的编号在 `rules.md` 常驻层。

## 六、 密钥管理

- 密钥**永不入 Git**，采用**手动分发**：新设备初始化时，由人类参照根目录 `keys-checklist.md`（该清单只列密钥名称与用途，不含密钥值）逐项手动复制到本机 `~/.agent-shared/config/`。
- `keys-checklist.md` 与密钥文件必须同步维护：新增密钥时，先更新清单再分发；废弃密钥时，清单标注废弃日期。
- 各设备 agent 在启动自检中核对：清单中的每一项在本机 `config/` 是否存在（只查存在性，不读内容）。缺项时报错并提醒人类补齐。
- **凭据共用边界（正文见 三-8 ⑥⑦〔spec/accounts.md〕）**：**跨设备、跨 agent 软件禁止**复制／分发同一份私钥／token，禁止搬用登录态与连接器授权；新增密钥时须在 `keys-checklist.md` 标注「适用设备 + agent 软件」。同一设备同一 agent 软件下若出现不同主体账号，是否仍共用须人类单独裁决。身份／记忆目录 `user-<id>-*` **仍按账号隔离，禁止跨账号复制**，不因本条放宽。

### 1. 防泄漏技术措施
"密钥不入 Git"不能只靠纪律，仓库根目录**必须**落实：
- **`.gitignore` 强制模板**（存于 `env/.gitignore.template`，clone 后首先复制生效）：
  ```gitignore
  config/
  tmp/
  *venv*/
  node_modules/
  .env
  *.pyc
  ```
- **gitleaks pre-commit hook**：每台设备安装 [gitleaks](https://github.com/gitleaks/gitleaks) 并配置为 pre-commit hook（`gitleaks protect --staged`）。**hook 必须链式委托**：全局 `core.hooksPath` 指向 `~/.agent-tools/hooks`，该 hook 先执行 gitleaks，随后**转发调用项目自身的 pre-commit**（`$(git rev-parse --git-dir)/hooks/pre-commit`），不得整体覆盖 husky 等项目级钩子。Linux/Termux 与 Windows（Git Bash hook 通用）一致。
- **服务端扫描（可选）**：GitHub 私有库的 push protection/secret scanning 属付费高级功能，Gitee 个人版无此功能；**有条件则开启，无条件以本地 hook 为准**。
- **事故处置**：一旦密钥被提交并推送：
  1. **立即轮换该密钥**——仅删除文件无效，密钥已永久留在 Git 历史中；
  2. 在 `keys-checklist.md` 标注泄漏与轮换日期；
  3. 历史清理：简单场景直接**重建仓库**（删库重推，双远端同步重建），保留场景用 `git filter-repo` 清洗后强推双远端；
  4. 排查泄漏窗口期内的 clone 记录（哪些设备/人拉取过）。

<!-- anchors：以下每行「|」后的文本须在本文件正文（本注释之外）与 global/rules.md 原位摘要壳中各逐字出现一次；改任一侧须同步另一侧（〇⑤ 受控例外二、第十节）。
六 | 密钥**永不入 Git**，采用**手动分发**
六 | 只查存在性，不读内容
六 | **跨设备、跨 agent 软件禁止**复制／分发同一份私钥／token
六 | 同一设备同一 agent 软件下若出现不同主体账号，是否仍共用须人类单独裁决
六-1 | **hook 必须链式委托**
六-1 | 不得整体覆盖 husky 等项目级钩子
六-1 | **立即轮换该密钥**——仅删除文件无效，密钥已永久留在 Git 历史中
-->
