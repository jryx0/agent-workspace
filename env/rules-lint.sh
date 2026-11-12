#!/usr/bin/env bash
# rules-lint.sh — 只读规范一致性校验（v2.6 分卷化 + 锚句 + 注入端红线）
#
# 硬约束：
#   - 只读：不写任何文件、不联网、不执行 git 操作。
#   - 纯 bash + POSIX 工具（awk/sed/grep/wc/head/printf），不依赖 Python。
#   - 字符数按 Unicode 字符计（wc -m），启动时自测 locale，失败退出码 2。
#   - 语义参照候选稿 _build/check.py（只读借鉴，不调用它）。
#
# 退出码：0 全部通过 / 1 存在失败项 / 2 参数或环境错误。
#
# 用法：
#   bash env/rules-lint.sh [--rules 文件] [--spec 目录] [--l1 文件]
# 默认（相对 ~/.agent-shared）：
#   --rules global/rules.md
#   --spec  global/spec
#   --l1    env/execution-enforcement.md

set -u

usage() {
  cat <<'EOF'
用法: bash env/rules-lint.sh [--rules <文件>] [--spec <目录>] [--l1 <文件>]

  --rules  规范常驻层正文（默认 global/rules.md）
  --spec   分卷目录（默认 global/spec）
  --l1     L1 注入端文件（默认 env/execution-enforcement.md）
  -h,--help 显示本帮助

检查项：
  C1 每份分卷 anchors 块内每条锚句：正文恰好 1 次，且 --rules 至少 1 次
  C2 每份分卷前 6 行含「> **原编号**：」
  C3 --rules 分流表/内联指针的字符数与分卷实际字符数一致，且每卷至少被引用一次
  C4 分卷正文指向其他分卷的章节编号必须紧跟「〔spec/目标.md〕」
  C5 〇⑦③ 最小红线集第 1–5 条核心禁令在 L1 粘贴正文中逐条出现
  C6 L1 粘贴正文（「粘贴正文」标题下第一个代码块）≤ 1500 字符

退出码：0 全部通过 / 1 存在失败项 / 2 参数或环境错误
EOF
}

# ---------- 参数解析 ----------
RULES=global/rules.md
SPEC=global/spec
L1=env/execution-enforcement.md

while [ $# -gt 0 ]; do
  case "$1" in
    --rules) [ $# -ge 2 ] || { echo "✗ 参数错误：--rules 缺少取值" >&2; exit 2; }; RULES=$2; shift 2 ;;
    --spec)  [ $# -ge 2 ] || { echo "✗ 参数错误：--spec 缺少取值" >&2; exit 2; };  SPEC=$2;  shift 2 ;;
    --l1)    [ $# -ge 2 ] || { echo "✗ 参数错误：--l1 缺少取值" >&2; exit 2; };    L1=$2;    shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "✗ 参数错误：未知参数 $1" >&2; usage >&2; exit 2 ;;
  esac
done

# 相对路径解析：优先相对脚本所在共享仓根（~/.agent-shared），其次当前目录
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SHARED_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)
resolve() {
  case "$1" in
    /*|[A-Za-z]:[\\/]*) printf '%s\n' "$1" ;;
    *) if [ -e "$SHARED_ROOT/$1" ]; then printf '%s\n' "$SHARED_ROOT/$1"; else printf '%s\n' "$1"; fi ;;
  esac
}
RULES=$(resolve "$RULES")
SPEC=$(resolve "$SPEC")
L1=$(resolve "$L1")

# ---------- locale 自测（Unicode 字符计数） ----------
locale_ok=0
for cand in C.UTF-8 C.utf8 en_US.UTF-8 en_US.utf8; do
  if [ "$(printf '中' | LC_ALL=$cand wc -m 2>/dev/null | tr -cd '0-9')" = "1" ]; then
    export LC_ALL=$cand
    locale_ok=1
    break
  fi
done
if [ "$locale_ok" -eq 0 ]; then
  if [ "$(printf '中' | wc -m | tr -cd '0-9')" = "1" ]; then
    echo "· locale 自测：沿用当前 locale（Unicode 计数正常）"
  else
    echo "✗ 环境错误：当前 locale 无法按 Unicode 字符计数（printf '中' | wc -m ≠ 1），请设置 LC_ALL=C.UTF-8 后重试" >&2
    exit 2
  fi
else
  echo "· locale 自测：LC_ALL=$LC_ALL（Unicode 计数正常）"
fi

# ---------- 环境校验 ----------
if [ ! -f "$RULES" ]; then
  echo "✗ 环境错误：rules 文件不存在: $RULES" >&2
  exit 2
fi
if [ ! -d "$SPEC" ]; then
  echo "✗ 环境错误：spec 目录不存在: $SPEC" >&2
  exit 2
fi
if [ ! -f "$L1" ]; then
  echo "✗ 环境错误：L1 文件不存在: $L1" >&2
  exit 2
fi

SPEC_N=0
for f in "$SPEC"/*.md; do
  [ -f "$f" ] && SPEC_N=$((SPEC_N + 1))
done
if [ "$SPEC_N" -eq 0 ]; then
  echo "✗ 环境错误：spec 目录为空（无 .md 分卷）: $SPEC" >&2
  exit 2
fi

echo "rules-lint: rules=$RULES"
echo "            spec=$SPEC（$SPEC_N 卷）"
echo "            l1=$L1"
echo "----------------------------------------"

# ---------- 通用工具 ----------
FAILS=0
ok()  { printf 'PASS %-2s %s\n' "$1" "$2"; }
bad() { printf 'FAIL %-2s %s\n' "$1" "$2"; FAILS=$((FAILS + 1)); }

# 提取 anchors 块内「|」后的锚句文本（每行一条）
anchors_of() {
  awk 'index($0,"<!-- anchors")==1 {ina=1; next}
       ina && $0=="-->" {ina=0; next}
       ina && index($0," | ")>0 {print substr($0, index($0," | ")+3)}' "$1"
}

# 去掉 anchors 块后的正文
body_of() {
  awk 'index($0,"<!-- anchors")==1 {ina=1; next}
       ina && $0=="-->" {ina=0; next}
       !ina' "$1"
}

# 提取「粘贴正文」标题下第一个代码块的内容（不保留末尾换行）
paste_body() {
  awk 'substr($0,1,1)=="#" && index($0,"粘贴正文")>0 {h=1; next}
       h && !inb && substr($0,1,3)=="```" {inb=1; next}
       inb && substr($0,1,3)=="```" {exit}
       inb { n++; if (n==1) s=$0; else s=s "\n" $0 }
       END { printf "%s", s }' "$1"
}

CIRCLED='①|②|③|④|⑤|⑥|⑦|⑧|⑨|⑩'
valid_ref_pat() {
  printf '%s( *(%s))*(-补[0-9]+)?〔spec/[A-Za-z0-9._/-]+〕' "$1" "$CIRCLED"
}

# ---------- C3 指针表（先跑，供 C4/C1 之外的整体校验） ----------
PTR_N=0
while IFS=' ' read -r name num; do
  [ -n "${name:-}" ] || continue
  PTR_N=$((PTR_N + 1))
  if [ ! -f "$SPEC/$name" ]; then
    bad C3 "分流表引用不存在的分卷: spec/$name"
    continue
  fi
  actual=$(wc -m < "$SPEC/$name" | tr -cd '0-9')
  want=$(printf '%s' "$num" | tr -cd '0-9')
  if [ "$actual" != "$want" ]; then
    bad C3 "spec/$name 字符数不符：分流表写 $want，实际 $actual"
  else
    ok C3 "spec/$name = $actual 字符"
  fi
done < <(
  sed -nE 's/.*`spec\/([A-Za-z0-9._-]+)`[[:space:]]*\|[[:space:]]*([0-9,]+).*/\1 \2/p' "$RULES"
  sed -nE 's/.*`global\/spec\/([A-Za-z0-9._-]+)`（([0-9,]+) 字符.*/\1 \2/p' "$RULES"
)

for f in "$SPEC"/*.md; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  if grep -qF -- "spec/$base" "$RULES"; then
    ok C3 "$base 已被 --rules 引用"
  else
    bad C3 "$base 未被 --rules 引用"
  fi
done

# ---------- 逐卷：C2 / C1 / C4 ----------
for f in "$SPEC"/*.md; do
  [ -f "$f" ] || continue
  base=$(basename "$f")

  # C2 原编号（前 6 行）
  if head -n 6 "$f" | grep -qF -- '> **原编号**：'; then
    ok C2 "$base 前 6 行含原编号"
  else
    bad C2 "$base 前 6 行缺「> **原编号**：」"
  fi

  # C1 锚句
  c1_before=$FAILS
  c1_n=0
  while IFS= read -r needle; do
    [ -n "$needle" ] || continue
    c1_n=$((c1_n + 1))
    nb=$(body_of "$f" | grep -oF -- "$needle" | wc -l | tr -cd '0-9')
    nr=$(grep -oF -- "$needle" "$RULES" | wc -l | tr -cd '0-9')
    if [ "$nb" -ne 1 ]; then
      bad C1 "$base 锚句在本卷正文出现 ${nb:-0} 次（应为 1）: $needle"
    fi
    if [ "${nr:-0}" -lt 1 ]; then
      bad C1 "$base 锚句未在 --rules 出现: $needle"
    fi
  done < <(anchors_of "$f")
  if [ "$FAILS" -eq "$c1_before" ]; then
    if [ "$c1_n" -eq 0 ]; then
      ok C1 "$base 无 anchors 块（跳过）"
    else
      ok C1 "$base 锚句 $c1_n 条一致（正文恰 1 次 + rules 命中）"
    fi
  fi

  # C4 跨卷引用：指向他卷的章节编号必须紧跟 〔spec/目标.md〕
  c4_bad=0
  c4_n=0
  for pair in \
    '三-2:memory-compaction.md' '三-6:worktree.md' '三-7:deploy.md' '三-8:accounts.md' \
    '五-2:backup.md' '五-3:backup.md' '六-1:secrets.md' '七-1:projects.md' \
    '二-[0-9]:layout.md' '四-[0-9]:toolchain.md'; do
    key=${pair%%:*}
    tgt=${pair##*:}
    [ "$base" = "$tgt" ] && continue
    total=$(body_of "$f" | grep -oE -- "$key" | wc -l | tr -cd '0-9')
    [ "${total:-0}" -eq 0 ] && continue
    valid=$(body_of "$f" | grep -oE -- "$(valid_ref_pat "$key")" | wc -l | tr -cd '0-9')
    c4_n=$((c4_n + total))
    if [ "${valid:-0}" -ne "$total" ]; then
      c4_bad=$((c4_bad + 1))
      bad C4 "$base 存在未标注分卷的引用: ${key}（$total 处中 $((total - valid)) 处未紧跟 〔spec/$tgt〕）"
    fi
  done
  if [ "$c4_bad" -eq 0 ]; then
    ok C4 "$base 跨卷引用 $c4_n 处均已标注分卷"
  fi
done

# ---------- C5 / C6：L1 注入端 ----------
L1_BODY=$(paste_body "$L1")

if [ -z "$L1_BODY" ]; then
  bad C6 "未在 $L1 找到「粘贴正文」标题下的代码块"
else
  L1_CHARS=$(printf '%s' "$L1_BODY" | wc -m | tr -cd '0-9')
  if [ "${L1_CHARS:-0}" -gt 1500 ]; then
    bad C6 "L1 粘贴正文 ${L1_CHARS} 字符 > 1500"
  else
    ok C6 "L1 粘贴正文 ${L1_CHARS} 字符（≤1500）"
  fi

  for phrase in \
    '密钥永不入 Git' \
    '禁把依赖装进全局或用户级位置' \
    '不并行修改我正在配置的目录' \
    '不改 global/ 下规范正文（rules.md 与 spec/）' \
    '不碰他人未提交改动、不代提交、不强 rebase'; do
    if printf '%s' "$L1_BODY" | grep -qF -- "$phrase"; then
      ok C5 "红线: $phrase"
    else
      bad C5 "L1 粘贴正文缺红线: $phrase"
    fi
  done
fi

# ---------- 汇总 ----------
echo "----------------------------------------"
echo "检查: C1 锚句 / C2 原编号 / C3 指针 $PTR_N 条 / C4 跨卷引用 / C5 红线 5 条 / C6 L1 正文"
if [ "$FAILS" -eq 0 ]; then
  echo "结果: 全部通过"
  exit 0
fi
echo "结果: $FAILS 项失败"
exit 1
