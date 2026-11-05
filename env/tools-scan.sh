#!/usr/bin/env bash
# tools-scan.sh — 本机工具链扫描（规范 四-4，v1.8.3）
#
# 用法：
#   ./tools-scan.sh              输出 markdown 表格到 stdout（供人看/临时核对）
#   ./tools-scan.sh --write      全量扫描并写入 memory/devices/tools-<设备名>.md，刷新 stamp
#   ./tools-scan.sh --check      只核对基线，不写文件（自检第 8 步用）；有缺项/低版本时退出码 1
#
# 设计原则（四-4）：
#   1. 探测优先：已装且满足基线即"复用"，禁止重复下载
#   2. 首次扫描一次：--write 生成设备清单 + stamp，之后 30 天内不再全量扫描
#   3. 新装/升级/卸载后必须 --write 刷新，并在 env/toolchain.md 变更日志 append 一行
#
# 退出码：0 正常 / 1 --check 发现缺项或低于基线 / 2 环境异常

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_BIN="${HOME}/.agent-tools/bin"
RUN_DIR="${HOME}/.agent-tools/run"
STAMP="${RUN_DIR}/tools-scan.stamp"
MODE="${1:-table}"

# 项目级 CLI 白名单探测（四-4 ⑦）：这些工具只允许装在项目 node_modules 内，
# 出现在 npm 全局列表 = 不合规，须卸载并项目本地化
PROJECT_CLIS=(wrangler vite tsc eslint prettier turbo)
GLOBAL_CLI_WARN=0

scan_global_clis() {
  local npm_bin out c ver
  npm_bin="$(locate npm 2>/dev/null)" || return
  out="$("$npm_bin" list -g --depth=0 2>/dev/null)" || return
  for c in "${PROJECT_CLIS[@]}"; do
    ver="$(echo "$out" | grep -E "^[├└]── ${c}@" | head -1 | sed "s/.*${c}@//")"
    [ -z "$ver" ] && continue
    echo "⚠️ 全局安装的项目级 CLI：${c}@${ver}（不合规，四-4 ⑦）——应卸载并声明为项目 devDependency，用 npx 调用"
    GLOBAL_CLI_WARN=$((GLOBAL_CLI_WARN+1))
  done
}

# 设备名：<hostname>-<os>，全小写（规范 二-0.5）
DEVICE="${AGENT_DEVICE:-$(hostname 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d ' ')}-win"

# 探测项：命令名|用途|基线（用于 --check 的最低版本，空=只查存在）
# 基线以 env/toolchain.md 为准，此处仅作 --check 的快速判定
TOOLS=(
  "git|版本控制|2.40"
  "python|Python 运行时|3.11"
  "node|Node 运行时|20"
  "npm|Node 包管理器|"
  "pnpm|Node 包管理器（可选）|"
  "gh|GitHub CLI（可选）|"
  "gitleaks|密钥扫描 pre-commit hook|8.20"
  "jq|JSON 处理（可选）|"
  "curl|网络请求|"
  "unzip|解压|"
  "ssh|SSH 客户端|"
  "ssh-keygen|SSH 密钥工具|"
  "puttygen|PuTTY 密钥转换（可选）|"
  "rclone|云存储同步（本机按决策不装）|"
  "docker|容器（可选）|"
  "ffmpeg|音视频处理（可选）|"
)

# 取版本号（$1=命令名，$2=已定位的绝对路径；用绝对路径执行，避免"装了但不在 PATH"取不到版本）
get_version() {
  local c="$1" bin="${2:-$1}"
  case "$c" in
    git)        "$bin" --version 2>/dev/null | awk '{print $3}' ;;
    python)     "$bin" --version 2>/dev/null | awk '{print $2}' ;;
    node)       "$bin" --version 2>/dev/null | sed 's/^v//' ;;
    npm)        "$bin" --version 2>/dev/null | head -1 ;;
    pnpm)       "$bin" --version 2>/dev/null | head -1 ;;
    gh)         "$bin" --version 2>/dev/null | head -1 | awk '{print $3}' ;;
    gitleaks)   "$bin" version 2>/dev/null | head -1 | sed 's/^v//' ;;
    jq)         "$bin" --version 2>/dev/null | sed 's/^jq-//' ;;
    curl)       "$bin" --version 2>/dev/null | head -1 | awk '{print $2}' ;;
    unzip)      "$bin" -v 2>/dev/null | head -1 | awk '{print $2}' ;;
    ssh|ssh-keygen) ssh -V 2>&1 | head -1 | sed 's/.*OpenSSH_\([^,]*\).*/\1/' ;;
    puttygen)   echo "未探测（GUI 程序，执行会弹窗）" ;;
    rclone)     "$bin" version 2>/dev/null | head -1 | awk '{print $2}' ;;
    docker)     "$bin" --version 2>/dev/null | awk '{print $3}' | tr -d ',' ;;
    ffmpeg)     "$bin" -version 2>/dev/null | head -1 | awk '{print $3}' ;;
    *)          echo "" ;;
  esac
}

# 定位可执行文件，返回码含义：
#   0 = PATH 中找到 ｜ 1 = 工具区找到（PATH 不可见）｜ 3 = 磁盘已装但当前 PATH 无（禁止重复安装）｜ 2 = 确实未安装
# rc=3 的情形（v1.8.3 补丁）：WorkBuddy/系统托管运行时在磁盘上，但不同 agent 会话注入的 PATH 不同，
# 若直接判为"未安装"会诱使后续 agent 重复下载——违反 四-4 ① 探测优先。
locate() {
  local c="$1" p cand d
  p="$(command -v "$c" 2>/dev/null)" && { echo "$p"; return 0; }
  for cand in "${TOOLS_BIN}/${c}" "${TOOLS_BIN}/${c}.exe"; do
    [ -x "$cand" ] || [ -f "$cand" ] && { echo "$cand"; return 1; }
  done
  # 托管运行时磁盘探测（按工具名分别找）
  case "$c" in
    node|npm)
      for d in "${HOME}/.workbuddy/binaries/node/versions/"*/; do
        [ -d "$d" ] || continue
        cand="${d}${c}.exe"; [ -f "$cand" ] || cand="${d}${c}"
        [ -f "$cand" ] && { echo "$cand"; return 3; }
      done ;;
    python|python3)
      for d in "${HOME}/.workbuddy/binaries/python/versions/"*/; do
        [ -d "$d" ] || continue
        cand="${d}python.exe"; [ -f "$cand" ] || cand="${d}python"
        [ -f "$cand" ] && { echo "$cand"; return 3; }
      done ;;
  esac
  return 2
}

# 版本比较：$1 >= $2 → 0
ver_ge() {
  local a b
  a="$(echo "$1" | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')"
  b="$(echo "$2" | awk -F. '{printf "%d%03d%03d", $1, $2, $3}')"
  [ "$a" -ge "$b" ] 2>/dev/null
}

emit_table() {
  echo "| 工具 | 版本 | 状态 | 路径 | PATH 可见 | 用途 |"
  echo "|---|---|---|---|---|---|"
  local ok=0 miss=0 low=0
  for row in "${TOOLS[@]}"; do
    IFS='|' read -r c use base <<< "$row"
    local path rc ver status visible
    path="$(locate "$c")"; rc=$?
    if [ $rc -eq 2 ]; then
      printf "| %s | - | ❌ 未安装 | - | - | %s |\n" "$c" "$use"
      miss=$((miss+1)); continue
    fi
    ver="$(get_version "$c" "$path")"
    [ -z "$ver" ] && ver="未知"
    if [ $rc -eq 3 ]; then
      ver="$(get_version "$c" "$path")"
      printf "| %s | %s | ⚠️ 已装但当前 PATH 不可见（**无需安装**，修 PATH 或注入路径） | %s | 否（磁盘存在） | %s |\n" \
        "$c" "${ver:-未知}" "$(echo "$path" | sed "s|^$HOME|~|")" "$use"
      ok=$((ok+1)); continue
    fi
    if [ $rc -eq 1 ]; then visible="否（仅工具区，需新开终端或加 PATH）"; else visible="是"; fi
    if [ -n "$base" ] && [ "$ver" != "未知" ] && ! ver_ge "$ver" "$base"; then
      status="⚠️ 低于基线 $base"; low=$((low+1))
    else
      status="✅ 可用（复用）"; ok=$((ok+1))
    fi
    printf "| %s | %s | %s | %s | %s | %s |\n" "$c" "$ver" "$status" "$(echo "$path" | sed "s|^$HOME|~|")" "$visible" "$use"
  done
  echo ""
  echo "> 统计：可用 $ok / 未安装 $miss / 低于基线 $low ｜ 扫描时间 $(date '+%Y-%m-%d %H:%M') ｜ 设备 \`$DEVICE\`"
  local g
  g="$(scan_global_clis)"
  if [ -n "$g" ]; then echo ""; echo "## 全局项目级 CLI 违规（四-4 ⑦）"; echo ""; echo "$g"; fi
}

case "$MODE" in
  --write)
    mkdir -p "$RUN_DIR" "${REPO_ROOT}/memory/devices"
    out="${REPO_ROOT}/memory/devices/tools-${DEVICE}.md"
    {
      echo "# 本机工具清单 — ${DEVICE}"
      echo ""
      echo "> 由 \`env/tools-scan.sh --write\` 自动生成，**请勿手工编辑**（改动会在下次扫描被覆盖）。"
      echo "> 来源类型与基线定义见 \`env/toolchain.md\`；新装/升级工具后必须重跑本脚本并提交。"
      echo ""
      echo "## 扫描信息"
      echo ""
      echo "| 项 | 值 |"
      echo "|---|---|"
      echo "| 设备 | \`${DEVICE}\` |"
      echo "| 扫描时间 | $(date '+%Y-%m-%d %H:%M') UTC+8 |"
      echo "| 主机名 | \`$(hostname 2>/dev/null)\` |"
      echo "| 脚本 | \`env/tools-scan.sh\` (v1.8.3) |"
      echo ""
      echo "## 工具明细"
      echo ""
      emit_table
    } > "$out"
    {
      echo "device=${DEVICE}"
      echo "scanned_at=$(date '+%Y-%m-%dT%H:%M:%S%z')"
      echo "file=memory/devices/tools-${DEVICE}.md"
      echo "script=v1.8.3"
    } > "$STAMP"
    echo "✅ 已写入 ${out/#$HOME/~}"
    echo "✅ 已刷新 stamp：${STAMP/#$HOME/~}"
    ;;
  --check)
    [ -f "$STAMP" ] || { echo "⚠️ 无扫描记录（stamp 缺失）：请先执行 tools-scan.sh --write"; exit 1; }
    scanned="$(grep '^scanned_at=' "$STAMP" | cut -d= -f2)"
    age_days=$(( ( $(date +%s) - $(date -d "${scanned:0:19}" +%s 2>/dev/null || echo 0) ) / 86400 ))
    echo "上次扫描：${scanned}（约 ${age_days} 天前）"
    [ "$age_days" -ge 30 ] && echo "⚠️ 清单已超过 30 天，建议重新全量扫描（--write）"
    bad=0 pathwarn=0
    for row in "${TOOLS[@]}"; do
      IFS='|' read -r c use base <<< "$row"
      [ "$c" = "rclone" ] && continue   # 本机按决策不装
      [ -z "$base" ] && continue
      path="$(locate "$c")"; rc=$?
      if [ $rc -eq 2 ]; then echo "❌ 缺失：$c（基线 >=$base，用途：$use）——需按 四-4 ① 探测后安装并登记"; bad=1; continue; fi
      if [ $rc -eq 3 ]; then
        echo "⚠️ 已装但当前 PATH 不可见：$c（磁盘路径 $path）——**禁止重复安装**，请注入 PATH 或用绝对路径调用"
        pathwarn=$((pathwarn+1)); continue
      fi
      ver="$(get_version "$c" "$path")"
      if [ -n "$ver" ] && ! ver_ge "$ver" "$base"; then echo "⚠️ 低于基线：$c $ver < $base"; bad=1; fi
    done
    [ $pathwarn -gt 0 ] && echo "ℹ️ 共 $pathwarn 项属 PATH 注入差异（不同 agent 会话 PATH 不同），非安装缺失，不视为基线失败"
    g="$(scan_global_clis)"
    if [ -n "$g" ]; then echo "$g"; echo "ℹ️ 以上为四-4 ⑦ 存量违规，不计入基线失败，但须按存量整改流程处理"; fi
    [ $bad -eq 0 ] && echo "✅ 基线核对通过，无需全量扫描"
    exit $bad
    ;;
  *)
    echo "# 工具扫描（临时视图，未写入文件）"
    echo ""
    emit_table
    ;;
esac
