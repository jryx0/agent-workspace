> **Source**: `global/rules.md` spec volume (v3.0, synced with `rules.md`)
> **Section**: `S6` (`S6.1`)
> **Trigger**: 新增/轮换/废弃密钥、配置 gitleaks 钩子、处置密钥泄漏事故时
> **Authority**: 与 `rules.md` 同等效力，受 `R4` 保护；修订见 `[spec/governance.md#S9]`。

## S6. Secrets Management

- **S6a 手动分发**：密钥**永不入 Git**（`R1`）。新设备由人类对照根目录 `keys-checklist.md`（仅列名称、用途、适用设备与软件，不含值）逐项手动复制到 `~/.agent-shared/config/`。
- **S6b 同步维护**：新增密钥先更新 `keys-checklist.md` 再分发；废弃密钥标注废弃日期。
- **S6c 只查存在性**：自检脚本与 Agent 仅核对 `keys-checklist.md` 所列文件在 `config/` 中是否存在，**禁止读取或打印密钥值**；缺项上报人类补齐。
- **S6d 共用边界**：严格遵循 `[spec/accounts.md#S3.8g]`——仅同一台设备 + 同一个 Agent 软件且同一主体可共用 `config/`；**跨设备、跨 Agent 软件严禁复制或分发私钥/Token/登录态/连接器授权**；`user-<id>-*` 身份记忆严禁跨账号复制。

### S6.1 Leak Prevention & Incident Response
- **S6.1a `.gitignore` 强制模板**：新设备 clone 后立即启用 `env/.gitignore.template`（排除 `config/`、`tmp/`、`*venv*/`、`node_modules/`、`.env`、`*.pyc`）。
- **S6.1b 链式 gitleaks pre-commit hook**：每台设备安装 `gitleaks`（`~/.agent-tools/bin/`）并将全局 `core.hooksPath` 指向 `~/.agent-tools/hooks`。该 hook 先执行 `gitleaks protect --staged`，随后**链式转发**调用项目自有 `$(git rev-parse --git-dir)/hooks/pre-commit`，**不得覆盖 husky 等项目级钩子**。
- **S6.1c 服务端扫描（可选）**：平台支持 secret scanning / push protection 则开启，无条件以本地 hook 为准。
- **S6.1d 泄漏事故处置（按序执行）**：
  1. **立即轮换该密钥**（仅删文件无效，密钥已留在 Git 历史中）；
  2. 在 `keys-checklist.md` 标注泄漏与轮换日期；
  3. 清理历史：简单场景双远端同步重建仓库，保留场景用 `git filter-repo` 清洗后强推双远端；
  4. 排查泄漏窗口内的拉取/访问记录。
