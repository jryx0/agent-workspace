#!/usr/bin/env bash
# git-sync.sh — 双远端推送（规范 五-1 / v1.3）
# 用法：~/.agent-shared/env/git-sync.sh
# 每次推送必须依次推 origin(Gitee主库) 与 backup(GitHub备份库)，禁止只推一个远端；拉取永远只从 origin。
set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/.agent-shared")"

echo "[sync] 推送 origin (Gitee 主库) ..."
git push origin --all && git push origin --tags
echo "[sync] 推送 backup (GitHub 备份库) ..."
git push backup --all && git push backup --tags
echo "[sync] 双远端推送完成。"
