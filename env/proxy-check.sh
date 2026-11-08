#!/usr/bin/env bash
# env/proxy-check.sh — 代理与双远端可用性只读核对（配套 〇 / 五-1 / 八 启动自检）
#
# 用法：bash ~/.agent-shared/env/proxy-check.sh [--quiet]
#   --quiet  仅输出提醒项与结论，省略明细
# 退出码：0 = 符合预期；1 = 存在需提醒人类的异常项（脚本本身不阻塞、不改任何配置）
#
# 设计约束：只读、不改 git 配置、不写仓库、不下载、不启动任何进程、单次探测有超时。
# 期望基线（规范记录）：Gitee(origin) 直连；仅 GitHub(backup) 走
#   git config --global http.https://github.com.proxy socks5://127.0.0.1:10808

set -u

SHARED="${HOME}/.agent-shared"
QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1
REMIND=0

say() { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }
remind() {
  REMIND=1
  printf '[REMIND][需人类处理] %s\n' "$*"
}

port_open() {
  timeout 2 bash -c "echo > /dev/tcp/127.0.0.1/$1" >/dev/null 2>&1
}

say "=== 代理与双远端核对 $(date '+%Y-%m-%d %H:%M:%S %z') ==="

# 1. git 代理配置
GLOBAL_PROXY="$(git config --global --get http.proxy 2>/dev/null || true)"
GH_PROXY="$(git config --global --get http.https://github.com.proxy 2>/dev/null || true)"
say "git 全局 http.proxy    : ${GLOBAL_PROXY:-<未设置 = 直连>}"
say "git GitHub 专用 proxy  : ${GH_PROXY:-<未设置>}"

if [ -n "$GLOBAL_PROXY" ]; then
  remind "检测到全局 http.proxy=${GLOBAL_PROXY}，Gitee 也被强制走代理（规范期望「Gitee 直连、仅 GitHub 走代理」）。代理软件一关，origin 与 backup 会一起失败；建议由人类确认后执行 git config --global --unset http.proxy。"
fi

# 2. 代理端口与软件运行状态
PORT="$(printf '%s' "${GH_PROXY:-${GLOBAL_PROXY:-}}" | sed -n 's/.*:\([0-9][0-9]*\)$/\1/p')"
[ -n "$PORT" ] || PORT=10808
if port_open "$PORT"; then
  say "代理端口 127.0.0.1:${PORT} : 可连（代理软件在运行）"
else
  remind "代理端口 127.0.0.1:${PORT} 不可连 —— v2rayN / xray 很可能未启动。请先打开代理软件再执行 git sync；不要用会话临时 HTTP 代理绕过（其端口每会话随机变化，本轮 62212 / 上轮 57893，且不一定能访问 GitHub）。"
fi

# 3. 会话环境代理（仅提示，不作为 git 通道）
ENV_PROXY="${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-${http_proxy:-}}}}"
say "会话环境代理           : ${ENV_PROXY:-<未设置>}（平台动态分配，禁止写入 git 全局配置）"

# 4. 双远端只读可达性 + 与本地 HEAD 比对
if [ -d "$SHARED/.git" ]; then
  LOCAL="$(git -C "$SHARED" rev-parse --short HEAD 2>/dev/null || echo '?')"
  say "本地 HEAD              : $LOCAL"
  for R in origin backup; do
    OUT="$(timeout 15 git -C "$SHARED" ls-remote "$R" refs/heads/main 2>/dev/null || true)"
    RH="$(printf '%s' "$OUT" | cut -c1-7)"
    if [ -n "$RH" ]; then
      if [ "$RH" = "$LOCAL" ]; then
        say "远端 $R              : $RH（与本地一致）"
      else
        remind "远端 $R 的 main 为 $RH，本地为 $LOCAL，版本不一致 —— 需 git push/pull 对齐后再收官，禁止只推一个远端。"
      fi
    else
      remind "远端 $R 不可达 —— 先查代理软件与 git 代理配置，不要改用临时代理只推另一个远端。"
    fi
  done
else
  remind "$SHARED 不是 Git 仓库，跳过远端核对。"
fi

if [ "$REMIND" -eq 0 ]; then
  say "结论：代理与双远端符合预期，可以执行 git sync。"
  exit 0
fi
say "结论：存在需人类处理的异常项，先处理再 git sync；本脚本未改动任何配置。"
exit 1
