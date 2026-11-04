#!/usr/bin/env bash
# start-mcp.sh — 启动本机 MCP SSE 服务（规范 四-2）
# 文件系统服务: http://127.0.0.1:9101/sse  (根目录: ~/.agent-shared 与 NAS 挂载点)
# Git 操作服务: http://127.0.0.1:9102/sse
# 运行日志与 PID 写入 ~/.agent-tools/run/
set -euo pipefail

RUN_DIR="$HOME/.agent-tools/run"
mkdir -p "$RUN_DIR"
ENV_DIR="$(cd "$(dirname "$0")" && pwd)"

start_one() {
  local name="$1" port="$2" ; shift 2
  if curl -s -m 2 -o /dev/null "http://127.0.0.1:${port}/sse"; then
    echo "[mcp] ${name} 已在线 (port ${port})，跳过"
    return 0
  fi
  echo "[mcp] 启动 ${name} (port ${port}) ..."
  nohup "$@" >> "${RUN_DIR}/${name}.log" 2>&1 &
  echo $! > "${RUN_DIR}/${name}.pid"
  echo "[mcp] ${name} pid=$(cat "${RUN_DIR}/${name}.pid")"
}

# 注意：以下命令为占位骨架。首次使用前请先确认 mcp-filesystem-server 与
# mcp-git-server 的实际包名/命令，并按 env/mcp-config.json 中的配置调整参数。
# start_one fs 9101 npx -y @modelcontextprotocol/server-filesystem --sse --port 9101 "$HOME/.agent-shared"
# start_one git 9102 npx -y mcp-server-git --sse --port 9102

echo "[mcp] 提示：当前为初始化骨架，具体启动命令请按 env/mcp-config.json 与 mcp-registry.md 配置后启用。"
