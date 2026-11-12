#!/usr/bin/env bash
# install-skill.sh — 共享技能一键安装 / 校验 / 卸载
# 权威原件在 ~/.agent-shared/skills/<分类>/<技能名>/，本脚本只做「单向复制 + 校验」，
# 不复制条款正文到各 agent 的规则文件（规范 〇⑤ 单一原件）。
#
# 用法：
#   bash ~/.agent-shared/env/install-skill.sh                    # 列出技能与安装状态（只读）
#   bash ~/.agent-shared/env/install-skill.sh --all              # 安装全部技能到已探测到的目录
#   bash ~/.agent-shared/env/install-skill.sh zhn-docs-kb        # 安装单个技能
#   bash ~/.agent-shared/env/install-skill.sh zhn-docs-kb --check   # 只校验是否与原件一致（漂移检测）
#   bash ~/.agent-shared/env/install-skill.sh zhn-docs-kb --dest ~/.claude/skills
#   bash ~/.agent-shared/env/install-skill.sh zhn-docs-kb --force   # 覆盖无标记的同名目录（先备份 .bak）
#   bash ~/.agent-shared/env/install-skill.sh zhn-docs-kb --uninstall
#
# 目标目录探测顺序（只增不改；存在才用）：
#   $AGENT_SKILLS_DIR → ~/.workbuddy/skills → ~/.claude/skills → ~/.codex/skills
#   → ~/.trae/skills → ~/.cursor/skills → ~/.gemini/skills → ~/.qwen/skills
#
# 设计原则：
#   1. 幂等：原件与副本树哈希一致即「已是最新」，不重复写。
#   2. 不静默覆盖：无安装标记的同名目录默认拒绝，需 --force 且自动留 .bak。
#   3. 可对账：每份副本写 .zhn-installed.json（来源路径 / 源提交 / 树哈希 / 时间），
#      --check 用它判断「副本是否落后于原件」。
#
# 退出码：0 成功或一致 / 1 --check 发现漂移或缺失 / 2 用法或环境错误

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/skills"
MARKER=".zhn-installed.json"

MODE="install"
FORCE=0
DEST_OVERRIDE=""
NAMES=()

usage() {
  sed -n '4,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --all)       NAMES+=("@all") ;;
    --check)     MODE="check" ;;
    --uninstall) MODE="uninstall" ;;
    --force)     FORCE=1 ;;
    --dest)      shift; DEST_OVERRIDE="${1:-}" ;;
    --list|-h|--help) MODE="list" ;;
    -*)          echo "[ERR] 未知参数：$1" >&2; usage >&2; exit 2 ;;
    *)           NAMES+=("$1") ;;
  esac
  shift
done

[ -d "$SKILLS_DIR" ] || { echo "[ERR] 找不到技能目录：$SKILLS_DIR" >&2; exit 2; }

# ---------- 通用函数 ----------

tree_hash() {
  local d="$1"
  [ -d "$d" ] || return 1
  ( cd "$d" || exit 1
    find . -type f ! -name "$MARKER" ! -name '*.bak' ! -name '*.bak.*' -print0 2>/dev/null \
      | sort -z | xargs -0 -r sha256sum 2>/dev/null | sha256sum | awk '{print $1}' )
}

detect_targets() {
  local c
  # 显式指定时**只**用它，不再叠加探测（避免 --dest/AGENT_SKILLS_DIR 被默认目录污染）
  if [ -n "${AGENT_SKILLS_DIR:-}" ]; then
    [ -d "$AGENT_SKILLS_DIR" ] && echo "$AGENT_SKILLS_DIR"
    return 0
  fi
  for c in "$HOME/.workbuddy/skills" "$HOME/.claude/skills" "$HOME/.codex/skills" \
           "$HOME/.trae/skills" "$HOME/.cursor/skills" "$HOME/.gemini/skills" "$HOME/.qwen/skills"; do
    [ -d "$c" ] && echo "$c"
  done
}

all_skills() {
  local p
  for p in "$SKILLS_DIR"/*/*/; do
    [ -f "${p}SKILL.md" ] && basename "$p"
  done
}

skill_src() {
  local name="$1" p
  p="$(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -type d -name "$name" 2>/dev/null | head -1)"
  [ -n "$p" ] && [ -f "${p}/SKILL.md" ] && echo "$p"
}

marker_get() {
  local file="$1" key="$2"
  [ -f "$file" ] || return 1
  sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$file" | head -1
}

write_marker() {
  local dest="$1" src="$2" src_hash="$3"
  local commit ts
  commit="$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  ts="$(date '+%Y-%m-%d %H:%M:%S %z')"
  cat > "${dest}/${MARKER}" <<EOF
{
  "skill": "$(basename "$dest")",
  "source": "${src#"$HOME"/}",
  "source_commit": "${commit}",
  "source_hash": "${src_hash}",
  "installed_at": "${ts}",
  "installer": "${AGENT_NAME:-unknown}@${AGENT_DEVICE:-unknown}",
  "note": "由 env/install-skill.sh 生成，改动请改权威原件后重装，勿手改副本"
}
EOF
}

# ---------- 各模式 ----------

do_list() {
  local targets=() name src dest status src_hash dest_hash commit
  mapfile -t targets < <(detect_targets) 2>/dev/null || targets=()
  echo "=== 共享技能清单（原件：${SKILLS_DIR#"$HOME"/}）==="
  printf "%-18s %-10s %s\n" "技能" "原件版本" "安装状态"
  while read -r name; do
    [ -n "$name" ] || continue
    src="$(skill_src "$name")"
    local ver
    ver="$(sed -n 's/^version:[[:space:]]*//p' "${src}/SKILL.md" | head -1)"
    if [ ${#targets[@]} -eq 0 ]; then
      echo "  ${name}  v${ver:--}  （未探测到任何 agent 技能目录）"
      continue
    fi
    for dest_root in "${targets[@]}"; do
      dest="${dest_root}/${name}"
      if [ ! -d "$dest" ]; then
        echo "  ${name}  v${ver:--}  ${dest_root#"$HOME"/}/ → 未安装"
        continue
      fi
      src_hash="$(tree_hash "$src")"; dest_hash="$(tree_hash "$dest")"
      if [ "$src_hash" = "$dest_hash" ]; then status="最新"; else status="过期（需重装）"; fi
      if [ ! -f "${dest}/${MARKER}" ]; then status="${status} · 无安装标记"; fi
      echo "  ${name}  v${ver:--}  ${dest_root#"$HOME"/}/ → ${status}"
    done
  done < <(all_skills)
  echo
  echo "提示：未探测到目录的 agent（如 trae），用 --dest <技能根目录> 指定；"
  echo "      完全没有技能机制的 agent，直接让它读 ~/.agent-shared/skills/<分类>/<技能>/SKILL.md。"
}

do_install() {
  local targets=() name src src_hash dest cur_hash
  if [ -n "$DEST_OVERRIDE" ]; then
    # 允许 ~ 展开与相对路径
    eval "DEST_OVERRIDE=\"$DEST_OVERRIDE\""
    targets=("$DEST_OVERRIDE")
    [ -d "$DEST_OVERRIDE" ] || { echo "[ERR] --dest 目录不存在：$DEST_OVERRIDE" >&2; exit 2; }
  else
    mapfile -t targets < <(detect_targets) 2>/dev/null || targets=()
  fi
  if [ ${#targets[@]} -eq 0 ]; then
    echo "[ERR] 未探测到任何 agent 技能目录。请用 --dest 指定，例如：" >&2
    echo "      bash $0 <技能名> --dest ~/.claude/skills" >&2
    exit 2
  fi

  local rc=0
  for name in "${NAMES[@]}"; do
    src="$(skill_src "$name")"
    if [ -z "$src" ]; then echo "[ERR] 技能不存在：$name（可用 --list 查看）" >&2; rc=2; continue; fi
    src_hash="$(tree_hash "$src")"
    for dest_root in "${targets[@]}"; do
      dest="${dest_root}/${name}"
      if [ -d "$dest" ]; then
        cur_hash="$(tree_hash "$dest")"
        if [ "$src_hash" = "$cur_hash" ]; then
          write_marker "$dest" "$src" "$src_hash"
          echo "[OK] ${name} @ ${dest_root#"$HOME"/} 已是最新（v$(sed -n 's/^version:[[:space:]]*//p' "${src}/SKILL.md" | head -1)）"
          continue
        fi
        if [ ! -f "${dest}/${MARKER}" ] && [ "$FORCE" -ne 1 ]; then
          echo "[SKIP] ${dest_root#"$HOME"/}/${name} 已存在且无安装标记，可能由人工维护；" >&2
          echo "       确认可覆盖再加 --force（会保留 .bak 备份）" >&2
          rc=1
          continue
        fi
        # 备份必须放在技能根目录之外：留在 <dest_root> 下会被 agent 当成新技能扫描
        local bak_root="${HOME}/.agent-tools/backups/skills"
        local bak="${bak_root}/$(basename "$dest").$(date '+%Y%m%d-%H%M%S')"
        mkdir -p "$bak_root"
        cp -a "$dest" "$bak" 2>/dev/null && echo "[BAK] ${bak#"$HOME"/}"
      fi
      mkdir -p "$dest"
      cp -a "${src}/." "$dest/" 2>/dev/null
      rm -f "${dest}/${MARKER}"
      write_marker "$dest" "$src" "$src_hash"
      echo "[OK] ${name} → ${dest_root#"$HOME"/}/${name}（树哈希 ${src_hash:0:12}…）"
    done
  done
  return $rc
}

do_check() {
  local targets=() name src src_hash dest="" dest_hash rc=0 checked=0
  mapfile -t targets < <(detect_targets) 2>/dev/null || targets=()
  for name in "${NAMES[@]}"; do
    src="$(skill_src "$name")"
    if [ -z "$src" ]; then echo "[ERR] 技能不存在：$name" >&2; rc=2; continue; fi
    src_hash="$(tree_hash "$src")"
    for dest_root in "${targets[@]}"; do
      dest="${dest_root}/${name}"
      checked=$((checked + 1))
      if [ ! -d "$dest" ]; then
        echo "[MISS] ${dest_root#"$HOME"/}/${name} 未安装"
        rc=1
        continue
      fi
      dest_hash="$(tree_hash "$dest")"
      if [ "$src_hash" = "$dest_hash" ]; then
        echo "[OK]   ${dest_root#"$HOME"/}/${name} 与原件一致"
      else
        local mhash
        mhash="$(marker_get "${dest}/${MARKER}" source_hash 2>/dev/null)"
        if [ -n "$mhash" ] && [ "$mhash" != "$src_hash" ]; then
          echo "[STALE] ${dest_root#"$HOME"/}/${name} 落后于原件（安装于次优提交，建议重装）"
        else
          echo "[DRIFT] ${dest_root#"$HOME"/}/${name} 副本被本地修改或来源不明"
        fi
        rc=1
      fi
    done
  done
  if [ "$checked" -eq 0 ]; then echo "[WARN] 未探测到安装目录，可用 AGENT_SKILLS_DIR 或 --dest 指定" >&2; rc=1; fi
  return $rc
}

do_uninstall() {
  local targets=() name dest
  # 卸载必须显式指定目标：--dest 或 AGENT_SKILLS_DIR，禁止「探测到的全部」批量删除
  if [ -n "$DEST_OVERRIDE" ]; then
    eval "DEST_OVERRIDE=\"$DEST_OVERRIDE\""
    [ -d "$DEST_OVERRIDE" ] || { echo "[ERR] --dest 目录不存在：$DEST_OVERRIDE" >&2; exit 2; }
    targets=("$DEST_OVERRIDE")
  else
    mapfile -t targets < <(detect_targets) 2>/dev/null || targets=()
    if [ ${#targets[@]} -gt 1 ]; then
      echo "[ERR] 探测到多个安装目录，卸载必须显式指定，避免误删：" >&2
      for t in "${targets[@]}"; do echo "      --dest ${t#"$HOME"/}" >&2; done
      exit 2
    fi
  fi
  local rc=0
  for name in "${NAMES[@]}"; do
    for dest_root in "${targets[@]}"; do
      dest="${dest_root}/${name}"
      [ -d "$dest" ] || continue
      if [ ! -f "${dest}/${MARKER}" ]; then
        echo "[SKIP] ${dest#"$HOME"/} 无安装标记，非本脚本安装，拒绝删除（确需删除请人工处理）" >&2
        rc=1; continue
      fi
      rm -rf "$dest" && echo "[DEL] ${dest#"$HOME"/}"
    done
  done
  return $rc
}

# ---------- 入口 ----------

if [ "$MODE" = "list" ] && [ ${#NAMES[@]} -eq 0 ]; then do_list; exit 0; fi
if [ ${#NAMES[@]} -eq 0 ]; then do_list; exit 0; fi

# 展开 --all
EXPANDED=()
for n in "${NAMES[@]}"; do
  if [ "$n" = "@all" ]; then
    while read -r s; do [ -n "$s" ] && EXPANDED+=("$s"); done < <(all_skills)
  else
    EXPANDED+=("$n")
  fi
done
NAMES=("${EXPANDED[@]}")

case "$MODE" in
  list)      do_list ;;
  check)     do_check ;;
  uninstall) do_uninstall ;;
  *)         do_install ;;
esac
