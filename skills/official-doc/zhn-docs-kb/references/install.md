# Skill Installation, Distribution & Multi-Account Guide (`zhn-docs-kb/references/install.md`)

> 按需加载：仅在新设备/新 Agent 安装、升级、漂移排查或处理多账号共存时读取。

## 1. Single Source & Standard Install

唯一权威原件：`~/.agent-shared/skills/official-doc/{zhn-docs-kb,zhn-docs-std}/`。所有平台技能目录下的副本均为**单向复制**，禁止手改副本（改副本会导致 `--check` 报 `[DRIFT]`）。

```bash
cd ~/.agent-shared && git pull --rebase
bash ~/.agent-shared/env/install-skill.sh --all
bash ~/.agent-shared/env/install-skill.sh --check   # 应全部 [OK]
```

常用变体：
- `--list`：只读查看已装状态；
- `zhn-docs-kb --dest <目录>`：装到非默认探测目录（覆盖 `$AGENT_SKILLS_DIR` 自动探测）；
- `--force`：覆盖无 `.zhn-installed.json` 标记的同名目录（自动备份至 `~/.agent-tools/backups/skills/`）；
- `--uninstall --dest <目录>`：显式卸载。

升级流程：改权威原件 → `env/git-sync.sh` → 其他设备 `git pull --rebase` → `install-skill.sh --all` → `--check` 全 `[OK]`。

## 2. Agents Without Skill Directories (Pointer Only)

不要复制正文，在项目规则文件仅加一行指针：
```text
涉及文档存放/命名/索引/预览/交付时，读 ~/.agent-shared/skills/official-doc/zhn-docs-kb/SKILL.md 与 zhn-docs-std/SKILL.md 执行。
```

## 3. Multi-Account / Multi-Edition Coexistence

| 资产层 | 典型位置 | 隔离维度 | 规则 |
|---|---|---|---|
| 共享技能副本 | `~/.workbuddy/skills/` 等 | 机器级（按 OS 用户） | 只装一次，多账号共用；注意企业策略可能停用用户级技能或与云市场撞名 |
| 身份与私有记忆 | `~/.workbuddy/user-<id>-*/` | **账号级** | **严禁跨账号复制**（`[spec/accounts.md#S3.8f]`） |
| 凭证与连接器 | `config/`、`mcp.json`、`~/.lark-cli/` | 机器/软件级 | 仅「同设备 + 同 Agent 软件 + 同主体」可共用，**严禁跨设备或跨软件复制**（`S3.8g`） |
| 规范与文档原件 | `~/.agent-shared/`、`~/.agent-docs/` | 与账号无关 | Git / 统一同步工具 |

切换账号后跑 `install-skill.sh --check` 并让 Agent 报出版本号即完成验证。
