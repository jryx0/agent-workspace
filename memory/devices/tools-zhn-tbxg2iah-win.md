# 本机工具清单 — zhn-tbxg2iah-win

> 由 `env/tools-scan.sh --write` 自动生成，**请勿手工编辑**（改动会在下次扫描被覆盖）。
> 来源类型与基线定义见 `env/toolchain.md`；新装/升级工具后必须重跑本脚本并提交。

## 扫描信息

| 项 | 值 |
|---|---|
| 设备 | `zhn-tbxg2iah-win` |
| 扫描时间 | 2026-11-05 09:03 UTC+8 |
| 主机名 | `Zhn-TBXG2IAH` |
| 脚本 | `env/tools-scan.sh` (v1.8.3) |

## 工具明细

| 工具 | 版本 | 状态 | 路径 | PATH 可见 | 用途 |
|---|---|---|---|---|---|
| git | 2.55.0.windows.3 | ✅ 可用（复用） | /mingw64/bin/git | 是 | 版本控制 |
| python | 3.13.14 | ✅ 可用（复用） | ~/.workbuddy/binaries/python/versions/3.13.12/python | 是 | Python 运行时 |
| node | 22.22.2 | ✅ 可用（复用） | ~/.workbuddy/binaries/node/versions/22.22.2-6/node | 是 | Node 运行时 |
| npm | 10.9.7 | ✅ 可用（复用） | ~/.workbuddy/binaries/node/versions/22.22.2-6/npm | 是 | Node 包管理器 |
| pnpm | - | ❌ 未安装 | - | - | Node 包管理器（可选） |
| gh | 2.101.0 | ✅ 可用（复用） | /c/Program Files/GitHub CLI/gh | 是 | GitHub CLI（可选） |
| gitleaks | 8.30.1 | ✅ 可用（复用） | ~/.agent-tools/bin/gitleaks | 否（仅工具区，需新开终端或加 PATH） | 密钥扫描 pre-commit hook |
| jq | - | ❌ 未安装 | - | - | JSON 处理（可选） |
| curl | 8.21.0 | ✅ 可用（复用） | /c/WINDOWS/system32/curl | 是 | 网络请求 |
| unzip | 6.00 | ✅ 可用（复用） | /usr/bin/unzip | 是 | 解压 |
| ssh | 10.3p1 | ✅ 可用（复用） | /usr/bin/ssh | 是 | SSH 客户端 |
| ssh-keygen | 10.3p1 | ✅ 可用（复用） | /usr/bin/ssh-keygen | 是 | SSH 密钥工具 |
| puttygen | 未探测（GUI 程序，执行会弹窗） | ✅ 可用（复用） | /c/Program Files/PuTTY/puttygen | 是 | PuTTY 密钥转换（可选） |
| rclone | - | ❌ 未安装 | - | - | 云存储同步（本机按决策不装） |
| docker | - | ❌ 未安装 | - | - | 容器（可选） |
| ffmpeg | - | ❌ 未安装 | - | - | 音视频处理（可选） |

> 统计：可用 11 / 未安装 5 / 低于基线 0 ｜ 扫描时间 2026-11-05 09:03 ｜ 设备 `zhn-tbxg2iah-win`
