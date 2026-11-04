@echo off
REM start-mcp.bat - Windows 启动 MCP 服务（规范 四-2，v1.5 勘误新增）
REM 与 start-mcp.sh 等价；也可改用 PowerShell 计划任务实现开机自启。
REM 运行日志与 PID 写入 %USERPROFILE%\.agent-tools\run\
echo [mcp] 提示：当前为初始化骨架，具体启动命令请按 env\mcp-config.json 与 mcp-registry.md 配置后启用。
echo [mcp] 建议以 PowerShell 计划任务注册开机自启（规范 九-6）。
