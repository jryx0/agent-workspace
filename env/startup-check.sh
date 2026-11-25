#!/usr/bin/env bash
# env/startup-check.sh — T2 一键只读启动自检脚本（global/rules.md#S8.1）
#
# 用法：bash ~/.agent-shared/env/startup-check.sh [--project <项目名>]
# 特性：纯只读、不联网、不修改任何文件或配置；秒级输出紧凑状态供 Agent 填写 S8.4 简报。
# 退出码：0 = 无阻断级异常；1 = 存在必须上报的异常（如缺共享仓或存在压缩锁）

set -u

SHARED="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --project|-p) PROJECT="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done

ALERT=0

# 1. Rules version
RULES_VER="$(head -n 1 "$SHARED/global/rules.md" 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+(\.[0-9]+)?' || echo 'UNKNOWN')"
echo "RULES: $RULES_VER ($SHARED/global/rules.md)"

# 2. Compaction lock
if [ -f "$SHARED/memory/.compact-lock" ]; then
  LOCK_INFO="$(tr '\n' ' ' < "$SHARED/memory/.compact-lock" | sed 's/[[:space:]]*$//')"
  echo "COMPACT_LOCK: LOCKED ($LOCK_INFO) -- STOP memory writes!"
  ALERT=1
else
  echo "COMPACT_LOCK: unlocked"
fi

# 3. Git working tree status (read-only)
if command -v git >/dev/null 2>&1; then
  DIRTY="$(git -C "$SHARED" status --short 2>/dev/null || true)"
  if [ -z "$DIRTY" ]; then
    echo "GIT_SHARED: clean (safe to pull --rebase origin main)"
  else
    CNT="$(printf '%s\n' "$DIRTY" | wc -l | tr -d ' ')"
    echo "GIT_SHARED: dirty ($CNT files; DO NOT pull/touch others' changes per R5)"
    printf '%s\n' "$DIRTY" | head -n 10 | sed 's/^/  /'
  fi
else
  echo "GIT_SHARED: git not found in PATH"
  ALERT=1
fi

# 4. Config / keys existence check (presence only, NEVER read contents)
CFG_DIR="$SHARED/config"
if [ -d "$CFG_DIR" ]; then
  CFG_CNT="$(find "$CFG_DIR" -maxdepth 2 -type f 2>/dev/null | wc -l | tr -d ' ')"
  echo "CONFIG_DIR: present ($CFG_CNT files in config/; verify against keys-checklist.md if adding keys)"
else
  echo "CONFIG_DIR: MISSING ($CFG_DIR)"
  ALERT=1
fi

# 5. Tools baseline check (--check only, no --write)
if [ -f "$SHARED/env/tools-scan.sh" ]; then
  TOOLS_OUT="$(bash "$SHARED/env/tools-scan.sh" --check 2>&1 || true)"
  TOOLS_SUMMARY="$(printf '%s\n' "$TOOLS_OUT" | grep -E '总结|汇总|PASS|FAIL|OK|缺失|过期|基线|结果' | tail -n 2 | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  [ -z "$TOOLS_SUMMARY" ] && TOOLS_SUMMARY="$(printf '%s\n' "$TOOLS_OUT" | tail -n 2 | tr '\n' ' ' | sed 's/[[:space:]]*$//')"
  echo "TOOLS_CHECK: $TOOLS_SUMMARY"
else
  echo "TOOLS_CHECK: env/tools-scan.sh missing"
fi

# 6. Suspended tasks (from memory/suspended.md)
SUSP_FILE="$SHARED/memory/suspended.md"
if [ -f "$SUSP_FILE" ]; then
  SUSP_ROWS="$(awk '
    /^## Active Suspended Tasks/ { in_tbl=1; next }
    /^## / { in_tbl=0 }
    in_tbl && /^\|/ && $0 !~ /^\|[[:space:]]*Project/ && $0 !~ /^\|---/ && $0 !~ /\(none/ {
      print
    }
  ' "$SUSP_FILE")"
  if [ -z "$SUSP_ROWS" ]; then
    echo "SUSPENDED: 0 active"
  else
    SCNT="$(printf '%s\n' "$SUSP_ROWS" | wc -l | tr -d ' ')"
    echo "SUSPENDED: $SCNT active (DO NOT claim/start any of these)"
    printf '%s\n' "$SUSP_ROWS" | awk -F'|' '{gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$3); gsub(/^ +| +$/,"",$4); printf "  - [%s] %s: %s\n", $2, $3, $4}'
  fi
else
  echo "SUSPENDED: memory/suspended.md MISSING"
  ALERT=1
fi

# 7. Latest handoff (project-scoped if --project given) + size check
if [ -d "$SHARED/handoff" ]; then
  LATEST_HO=""
  if [ -n "$PROJECT" ]; then
    LATEST_HO="$(ls -1t "$SHARED"/handoff/*"${PROJECT}"*.md 2>/dev/null | head -n 1 || true)"
    if [ -z "$LATEST_HO" ]; then
      LATEST_HO="$(grep -liE "^(project|项目):[[:space:]]*${PROJECT}" "$SHARED"/handoff/*.md 2>/dev/null | xargs -r ls -1t 2>/dev/null | head -n 1 || true)"
    fi
  fi
  [ -z "$LATEST_HO" ] && LATEST_HO="$(ls -1t "$SHARED"/handoff/*.md 2>/dev/null | head -n 1 || true)"
  if [ -n "$LATEST_HO" ]; then
    HO_BYTES="$(wc -c < "$LATEST_HO" | tr -d ' ')"
    HO_NOTE=""
    [ "$HO_BYTES" -gt 4096 ] && HO_NOTE=" [>4KB: read header/summary only]"
    echo "LATEST_HANDOFF: $(basename "$LATEST_HO") (${HO_BYTES}B)${HO_NOTE}"
  else
    echo "LATEST_HANDOFF: none"
  fi
fi

# 8. Optional project AGENTS.md hook check
if [ -n "$PROJECT" ]; then
  PROJ_DIR="$HOME/source/$PROJECT"
  if [ -d "$PROJ_DIR" ]; then
    if [ -f "$PROJ_DIR/AGENTS.md" ] && head -n 20 "$PROJ_DIR/AGENTS.md" | grep -q 'global/rules\.md'; then
      echo "PROJECT_HOOK($PROJECT): OK (AGENTS.md references global/rules.md)"
    elif [ -f "$PROJ_DIR/CODEBUDDY.md" ] && head -n 20 "$PROJ_DIR/CODEBUDDY.md" | grep -q 'global/rules\.md'; then
      echo "PROJECT_HOOK($PROJECT): OK (CODEBUDDY.md references global/rules.md)"
    else
      echo "PROJECT_HOOK($PROJECT): MISSING hook in $PROJ_DIR (report to human per S0.1c)"
    fi
  else
    echo "PROJECT_HOOK($PROJECT): no ~/source/$PROJECT dir (check env/repos.md S7.1 if non-git project)"
  fi
fi

exit "$ALERT"
