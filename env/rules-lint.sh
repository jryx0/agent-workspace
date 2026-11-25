#!/usr/bin/env bash
# env/rules-lint.sh — global/rules.md (v3.0) 与 global/spec/*.md 自动化只读校验
#
# 用法：bash ~/.agent-shared/env/rules-lint.sh
# 校验项（global/spec/governance.md#S9.3）：
#   L1  路由完整性：rules.md 所有 [spec/<f>.md#S<id>] 指向真实文件与节号；所有 spec/*.md 均被引用
#   L2  分卷头规范：每份 global/spec/*.md 前 6 行含 > **Section**:
#   L3  分卷内跨卷引用有效
#   L4  纯 ASCII 编号：global/rules.md、global/spec/*.md（跳过 governance.md S9.4 历史表）与 L1 模板不含圆圈数字或旧中文编号
#   L5  最小红线 R1-R5 在 rules.md S0.3 与 env/execution-enforcement.md L1 中完整存在
#   L6  体积上限：L1 粘贴文本 <= 1500 Unicode 字符；global/rules.md <= 12000 Unicode 字符
#   L7  核心运行文件存在性（memory/suspended.md、env/startup-check.sh、env/git-sync.sh、env/kb-endpoints.md）且冗余 global/AGENTS-startup.prompt.md 已移除
#
# 退出码：0 = 全过；1 = 有失败项。纯只读，不修改任何文件。

set -euo pipefail

SHARED="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULES="$SHARED/global/rules.md"
SPEC_DIR="$SHARED/global/spec"
ENF="$SHARED/env/execution-enforcement.md"

FAIL=0
pass() { echo "[PASS] $*"; }
fail() { echo "[FAIL] $*"; FAIL=1; }

# 辅助：检查某文件是否包含指定节号（## S<id> / ### S<id> / **S<id>）
has_section() {
  local file="$1"
  local sec="$2"
  grep -Eq "(^#{1,4}[[:space:]]+${sec}(\b|[^a-zA-Z0-9])|\*\*${sec}(\b|[^a-zA-Z0-9]))" "$file"
}

# 辅助：提取文件内所有 [spec/<file>.md#S<id>] 引用
extract_refs() {
  grep -oE '\[spec/[a-z0-9-]+\.md#S[0-9]+(\.[0-9]+)?[a-z]?\]' "$1" 2>/dev/null | sort -u || true
}

# 辅助：计算标准输入的 Unicode 字符数（优先 python3/python，兜底 awk）
count_chars() {
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import sys; print(len(sys.stdin.read()))'
  elif command -v python >/dev/null 2>&1; then
    python -c 'import sys; print(len(sys.stdin.read()))'
  else
    LC_ALL=C.UTF-8 wc -m | tr -d ' '
  fi
}

# ---------------- L1: rules.md 路由完整性 ----------------
L1_ERR=0
while IFS= read -r ref; do
  [ -z "$ref" ] && continue
  inner="${ref#[spec/}"
  inner="${inner%]}"
  f="${inner%%#*}"
  sec="${inner#*#}"
  target="$SPEC_DIR/$f"
  if [ ! -f "$target" ]; then
    fail "L1 rules.md cites missing spec file: $ref"
    L1_ERR=1
  elif ! has_section "$target" "$sec"; then
    fail "L1 rules.md cites missing section $sec in spec/$f"
    L1_ERR=1
  fi
done < <(extract_refs "$RULES")

for sf in "$SPEC_DIR"/*.md; do
  base="$(basename "$sf")"
  if ! grep -q "spec/$base" "$RULES"; then
    fail "L1 unreferenced spec volume in global/spec/: $base"
    L1_ERR=1
  fi
done
[ "$L1_ERR" -eq 0 ] && pass "L1 routing integrity (all spec refs valid & all spec volumes referenced)"

# ---------------- L2: 分卷头规范 ----------------
L2_ERR=0
for sf in "$SPEC_DIR"/*.md; do
  base="$(basename "$sf")"
  if ! head -n 6 "$sf" | grep -q '^> \*\*Section\*\*:'; then
    fail "L2 spec/$base missing '> **Section**:' in top 6 lines"
    L2_ERR=1
  fi
done
[ "$L2_ERR" -eq 0 ] && pass "L2 spec volume headers valid"

# ---------------- L3: 分卷内跨卷引用有效 ----------------
L3_ERR=0
for sf in "$SPEC_DIR"/*.md; do
  base="$(basename "$sf")"
  while IFS= read -r ref; do
    [ -z "$ref" ] && continue
    inner="${ref#[spec/}"
    inner="${inner%]}"
    f="${inner%%#*}"
    sec="${inner#*#}"
    target="$SPEC_DIR/$f"
    if [ ! -f "$target" ]; then
      fail "L3 spec/$base cites missing file: $ref"
      L3_ERR=1
    elif ! has_section "$target" "$sec"; then
      fail "L3 spec/$base cites missing section $sec in spec/$f"
      L3_ERR=1
    fi
  done < <(extract_refs "$sf")
done
[ "$L3_ERR" -eq 0 ] && pass "L3 intra-spec cross references valid"

# ---------------- L4: 纯 ASCII 编号检查 ----------------
L4_ERR=0
PY_BIN=""
if command -v python3 >/dev/null 2>&1; then
  PY_BIN="python3"
elif command -v python >/dev/null 2>&1; then
  PY_BIN="python"
fi

check_ascii_numbering() {
  local label="$1"
  local content="$2"
  local hits=""
  if [ -n "$PY_BIN" ]; then
    hits="$(printf '%s\n' "$content" | "$PY_BIN" -c '
import re, sys
pat = re.compile(r"[\u2460-\u2469\u3007]|(?:^|[\s#])[\u4e00\u4e8c\u4e09\u56db\u4e94\u516d\u4e03\u516b\u4e5d\u5341]\u3001|\u7b2c[\u4e00\u4e8c\u4e09\u56db\u4e94\u516d\u4e03\u516b\u4e5d\u53410-9]+\u8282|\u00a7[\u4e00\u4e8c\u4e09\u56db\u4e94\u516d\u4e03\u516b\u4e5d\u5341]")
for i, line in enumerate(sys.stdin, 1):
    if pat.search(line):
        print(f"{i}:{line.rstrip()}")
')"
  else
    hits="$(printf '%s\n' "$content" | grep -nF -e '①' -e '②' -e '③' -e '④' -e '⑤' -e '⑥' -e '⑦' -e '⑧' -e '⑨' -e '⑩' -e '〇' || true)"
  fi
  if [ -n "$hits" ]; then
    fail "L4 legacy Chinese/circled numbering found in $label:"
    printf '%s\n' "$hits" | head -n 5 | sed 's/^/  /'
    L4_ERR=1
  fi
}

check_ascii_numbering "global/rules.md" "$(cat "$RULES")"
for sf in "$SPEC_DIR"/*.md; do
  base="$(basename "$sf")"
  if [ "$base" = "governance.md" ]; then
    # 跳过 S9.4 历史编号映射表
    body="$(awk '/^###? S9\.4 /{exit} {print}' "$sf")"
    check_ascii_numbering "global/spec/$base (pre-S9.4)" "$body"
  else
    check_ascii_numbering "global/spec/$base" "$(cat "$sf")"
  fi
done

L1_BLOCK="$(awk '/^```text$/{f=1;next} /^```$/ && f{exit} f{print}' "$ENF")"
check_ascii_numbering "env/execution-enforcement.md (L1 block)" "$L1_BLOCK"
[ "$L4_ERR" -eq 0 ] && pass "L4 pure ASCII numbering enforced across global/ and L1"

# ---------------- L5: R1-R5 红线双侧对齐 ----------------
L5_ERR=0
for r in R1 R2 R3 R4 R5; do
  if ! grep -q "\*\*${r}\*\*" "$RULES"; then
    fail "L5 rules.md missing **$r**"
    L5_ERR=1
  fi
  if ! printf '%s\n' "$L1_BLOCK" | grep -q "${r} "; then
    fail "L5 L1 block missing $r"
    L5_ERR=1
  fi
done
[ "$L5_ERR" -eq 0 ] && pass "L5 minimal red lines R1-R5 present in both rules.md and L1"

# ---------------- L6: 体积上限 ----------------
L6_ERR=0
L1_LEN="$(printf '%s' "$L1_BLOCK" | count_chars)"
RULES_LEN="$(count_chars < "$RULES")"
if [ "$L1_LEN" -gt 1500 ]; then
  fail "L6 L1 block exceeds 1500 chars: $L1_LEN"
  L6_ERR=1
fi
if [ "$RULES_LEN" -gt 12000 ]; then
  fail "L6 global/rules.md exceeds 12000 chars: $RULES_LEN"
  L6_ERR=1
fi
[ "$L6_ERR" -eq 0 ] && pass "L6 size limits OK (L1=${L1_LEN}/1500 chars, rules.md=${RULES_LEN}/12000 chars)"

# ---------------- L7: 关键运行资产存在性与冗余清理 ----------------
L7_ERR=0
for req in "memory/suspended.md" "env/startup-check.sh" "env/git-sync.sh" "env/kb-endpoints.md"; do
  if [ ! -f "$SHARED/$req" ]; then
    fail "L7 required runtime file missing: $req"
    L7_ERR=1
  fi
done
if [ -f "$SHARED/global/AGENTS-startup.prompt.md" ]; then
  fail "L7 redundant global/AGENTS-startup.prompt.md still exists"
  L7_ERR=1
fi
[ "$L7_ERR" -eq 0 ] && pass "L7 runtime artifacts present and redundant startup prompt removed"

echo "---"
if [ "$FAIL" -eq 0 ]; then
  echo "ALL LINT CHECKS PASSED (v3.0)"
  exit 0
else
  echo "LINT FAILED — fix items above before committing."
  exit 1
fi
