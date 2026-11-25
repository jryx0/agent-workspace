#!/usr/bin/env bash
# env/git-sync.sh — 双远端推送（规范 S5.1b / v3.0）
# 用法：bash ~/.agent-shared/env/git-sync.sh
# 推送前自动执行 env/proxy-check.sh --quiet；异常即停并报告人类（禁止临时代理绕过）。
# 推送顺序：origin (Gitee 主库) -> backup (GitHub 备份库)；禁止只推一个远端。

set -euo pipefail

SHARED="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/.agent-shared")"
cd "$SHARED"

if [ -f "$SHARED/env/proxy-check.sh" ]; then
  echo "[sync] 推送前核对代理与双远端 (proxy-check.sh) ..."
  if ! bash "$SHARED/env/proxy-check.sh" --quiet; then
    echo "[sync] 代理或双远端核对未通过，已中止推送。请按上方 [REMIND] 提示处理，禁止临时代理绕过。" >&2
    exit 1
  fi
fi

echo "[sync] 推送 origin (Gitee 主库) ..."
git push origin --all && git push origin --tags
echo "[sync] 推送 backup (GitHub 备份库) ..."
git push backup --all && git push backup --tags
echo "[sync] 双远端推送完成。"
