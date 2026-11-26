# 双节点监控面板聚合部署交接（2026-11-27）

执行：workbuddy@zhn-tbxg2iah-win~zhn-x-w　|　档位：T2　|　基线：a6c5af6

## 一、交付内容

1. **Oracle 面板上线**：在 `129.146.248.98:30102`（VM.Standard.E2.1.Micro，AMD Always Free，phx）部署 vnStat + vpspanel 服务，与 RackNerd 同构。模板来自 RackNerd，参数改为 `IFACE=ens3`/`CAP_GB=10240`/`DISK_CAP_GB=45`/`TZ=utc`。`active`+`enabled`，绑 `127.0.0.1:8080`，本月读到 253GB。Oracle 未装 ufw，依赖只绑回环 + 云安全组。
2. **本机聚合器**：`C:\Users\Zhn_X\WorkBuddy\2026-11-05-16-22-04\vps-aggregator.py` + `启动VPS监控.bat`。绑 `127.0.0.1:18090`，单页看两台，无需 SSH 隧道。Python 标准库零依赖，30 秒缓存，校准录入反向转发到目标节点。
3. 端到端验收全通过：两台面板重启恢复、聚合页 200、双节点数据正确、校准转发成功。

## 二、怎么用

- 双击 `启动VPS监控.bat` → 浏览器开 `http://127.0.0.1:18090`
- 关闭：窗口内 `Ctrl+C` 或关窗口（前台程序，不残留）
- 公司代理：`export VPS_AGENT_PROXY=socks5://127.0.0.1:10808` 后启动

## 三、关键坑（避免重犯）

1. **本机平台全局代理**导致 `curl` / `/dev/tcp` 探测公网 IP 假报 OPEN。验证零暴露必须用 `curl --noproxy '*'`，实测两台 8080 均 HTTP=000。
2. **Git Bash 双 PID**：MSYS PID ≠ Windows PID，`kill` 杀不掉 Windows 原生进程；关闭进程用 PowerShell 按 `CommandLine` 特征匹配。
3. **`-f -N` SSH 隧道脱离终端常驻**，关窗口无效（前次会话已踩）；本方案改用前台聚合器规避。
4. Oracle 元数据端点 403 需带 `Authorization: Bearer Oracle` 头。

## 四、数据安全

- 校准转发测试记录已在 Oracle 用 sudo 删除（records=0）；RackNerd 原有 6 条真实用户录入**未动**。
- 私钥仅引用 `~/.ssh/` 路径，未复制进聚合器、未入 Git。
- 两台面板目录 `/opt/vpspanel`（750 vpspanel:vpspanel），systemd 四项加固全开。

## 五、资料与留痕

- 运维文档：`docs://技术资料/261116｜部署｜Xray代理服务/261127｜运维｜双节点监控面板聚合部署.md`，飞书索引 rev 48 落库。
- 当日日志：`.workbuddy/memory/2026-11-27.md`。
- 未改现有 Xray/SSH/ufw 配置；共享仓仅本交接文档为本次新增。

## 六、待办

- 两台节点继续手工录入面板读数（Oracle 从 0 开始，RackNerd 已有 6 条），累计 5~7 天后复核规则反推。
- 计费仍以 RackNerd 面板 / Oracle 控制台为准，本地面板仅趋势参考。
