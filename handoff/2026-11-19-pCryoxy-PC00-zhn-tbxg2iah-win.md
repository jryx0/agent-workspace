# pCryoxy PC-00 交接

- 项目: pCryoxy
- 卡ID: PC-00
- 日期: 2026-11-19
- 交接: copilot@zhn-tbxg2iah-win~zhn-x-w
- 当前状态: 实施与干净 checkout 构建已完成；缺真实 Android 设备，按卡面记 **blocked**，未标 done；待 WorkBuddy 给出“通过 / 退回 / 受外部条件阻塞”

## 1. 已完成

- 建立独立 Gitee 私有仓 `https://gitee.com/ParvaUltra/pCryoxy.git`，默认分支 `main`。
- 新仓与其他代理项目隔离；gitleaks 对暂存内容扫描无命中，仓库文件中无 `pRayShell` 字符串或文件引用。
- 建立 Rust workspace、Tauri v2、SolidJS/Vite/TypeScript 空壳与锁文件。
- 生成并保留 Tauri Android 基线工程，固定 PC-00 所需两种 64 位 ABI。
- 写入 Xray `v26.11.9` / `676eaf66f8f05d4d558ee7a74b4736623d3feeb9` 与平台资产 SHA-256。
- 从远端干净 checkout `3288de7b5012` 完成 Windows release 与 Android arm64-v8a/x86_64 release APK，构建结束后 `git status --porcelain` 为空。
- 未部署、未签发证书、未上传应用、未修改系统全局配置。

## 2. 现场

| 项 | 取值 |
|---|---|
| worktree | `C:\Users\Zhn_X\source\pCryoxy` |
| 分支 | `main`（tracking `origin/main`） |
| 最终提交 | `c3dae630d64669d619c24a00cfab22c01928d28a`（文档值补录）；构建实测提交 `3288de7b501265e47443db30cc7d86094bfcbd45` |
| 首版提交 | `fa947fe` |
| bootstrap 修复 | `7d30cb5` |
| 换行复现修复 | `3288de7` |
| 实际 Android 值补录 | `c3dae63` |
| 远端 | `https://gitee.com/ParvaUltra/pCryoxy.git` |
| 共享仓认领提交 | `6b5ddd6` |

## 3. 探测与安装结果

所有缺失项均先报并取得 2026-11-19 当次用户批准，运行时只安装到 `~/.agent-tools/`；项目依赖只进入项目 `node_modules/` 与 lock。

| 工具 | 初始结果 | 最终真实取值 | 来源/位置 |
|---|---|---|---|
| Rust / Cargo / rustup | 缺失 | rustc/cargo `1.100.0`；rustup `1.29.3` | 官方 rustup；`~/.agent-tools/runtimes/rust` |
| Go | 缺失 | `go1.27.4 windows/amd64` | 官方 `go.dev` zip + SHA-256 |
| JDK | 缺失 | Temurin `21.0.13+9-LTS` | Adoptium 官方 zip + SHA-256；`~/.agent-tools/runtimes/jdk-21` |
| Android CLI | 缺失 | Android CLI `23.0.0` / backend `1.1.16919734` | Google command-line tools 23.0 |
| Android Platform-Tools | 缺失 | `37.0.1-15733141`，ADB `1.0.41` | `~/.agent-tools/android-sdk` |
| Android Platform | 缺失 | package `platforms/android-37.2`；generated compile/target API `37` | Google SDK |
| Android Build-Tools | 缺失；构建实际又安装 36.0.0 | 基线 `37.0.0`；Tauri/AGP 9.3.1 实际还解析 `36.0.0` 作为兼容构建工具 | `~/.agent-tools/android-sdk/build-tools` |
| Android NDK | 缺失 | `29.0.14206865`；Clang `21.0.0` | Google SDK |
| Node / npm | 已有 | Node `22.22.2`，npm `10.9.7`，Corepack `0.34.6` | 复用 WorkBuddy 托管 Node |
| pnpm | 缺失 | `12.21.0`，仅项目本地 | `package.json` + `pnpm-lock.yaml` |
| MSVC / WebView2 | 已有 | Visual Studio Community 2026；WebView2 `157.0.4341.60` | 复用 |

真实登记值：

- 发行通道：`stable`
- Rust MSRV/工具链：`1.100.0`
- Android 最低 API：`24`
- Android compile/target API：`37`（Platform 包 `37.2`）
- Android ABI：`arm64-v8a`、`x86_64`（与固定 Xray 的 64 位 Android 资产一致）
- Windows 架构：`x86_64-pc-windows-msvc`

## 4. 锁文件

`contracts/core-lock.json` 实际内容：

```json
{
  "schemaVersion": 1,
  "releaseChannel": "stable",
  "upstream": {
    "repository": "https://github.com/XTLS/Xray-core",
    "tag": "v26.11.9",
    "commit": "676eaf66f8f05d4d558ee7a74b4736623d3feeb9",
    "publishedAt": "2026-11-09T05:31:16Z"
  },
  "bridge": {
    "name": "pcryoxy-bridge",
    "version": "0.0.1",
    "protocol": "pcryoxy.bridge.v1",
    "status": "baseline-declared",
    "xrayCommit": "676eaf66f8f05d4d558ee7a74b4736623d3feeb9",
    "patchSet": []
  },
  "assets": [
    {
      "platform": "windows",
      "architecture": "x86_64-msvc",
      "abi": "none",
      "filename": "Xray-windows-64.zip",
      "size": 16697596,
      "sha256": "1262522266337b824f07beb8e1375786b437683b3890105469088f8e17e0a69d"
    },
    {
      "platform": "android",
      "architecture": "arm64-v8a",
      "abi": "aarch64-linux-android",
      "filename": "Xray-android-arm64-v8a.zip",
      "size": 15621040,
      "sha256": "edcefc25b9b3195b11e18624c8269a969d6aabc39c6298a9a5ab29de15d46f3b"
    },
    {
      "platform": "android",
      "architecture": "x86_64",
      "abi": "x86_64-linux-android",
      "filename": "Xray-android-amd64.zip",
      "size": 16900215,
      "sha256": "48c266cdb9660dade968814e2f91d84e6aff534b7c3762ca3e385fb8aa475bd8"
    }
  ]
}
```

## 5. 实际测试与产物

| 命令/检查 | 退出码 | 实测 |
|---|---:|---|
| `tools-scan.sh --check` | 0 | 基线通过 |
| `pnpm install --frozen-lockfile`（干净 checkout） | 0 | lock 一致；supply-chain policy 通过 |
| `pnpm build` | 0 | TypeScript + Vite 8.3.8 通过 |
| `cargo fmt --all -- --check` | 0 | 通过 |
| `cargo clippy --workspace --all-targets --locked -- -D warnings` | 0 | 通过 |
| `cargo check --workspace --locked` | 0 | 通过 |
| `tools/build-windows.ps1`（干净 checkout） | 0 | `pcryoxy.exe` 4,180,480 B |
| `tools/build-android.ps1`（干净 checkout） | 0 | arm64 + x86_64 unsigned APK |
| 构建后 `git status --porcelain` | 0 | 空；构建未改跟踪文件 |
| `adb devices -l` | 0 | 无设备；进入外部条件阻塞 |
| gitleaks staged patch | 0 | 无泄漏 |

最终干净 checkout `3288de7b5012` 产物：

| 产物 | 字节 | SHA-256 |
|---|---:|---|
| `pcryoxy.exe` | 4,180,480 | `1EC27882BD3A2FBB658B5FE5772DF91C7F11EDBB41947099E16B061DE1FC1002` |
| `app-arm64-release-unsigned.apk` | 5,789,255 | `FE8CBCF7B6971468552C59924B14F4E64020892E77799C1600ED9CC7C2B8E74A` |
| `app-x86_64-release-unsigned.apk` | 6,281,196 | `5347D9D8958C0344BCD414A09DFD2761A70A1D13E77F942EE4170911B3D73361` |

Windows 同机场景在本地构建散列与干净 checkout 散列不同，故本文不声称 bit-for-bit reproducibility；可复现范围是来源、版本、lock、构建命令、目标与产物形态。

## 6. Git sync 实际回显

PC-00 认领提交 `6b5ddd6` 的共享仓双远端同步实际输出：

```text
结论：代理与双远端符合预期，可以执行 git sync。
[sync] 推送 origin (Gitee 主库) ...
   38722b6..6b5ddd6  main -> main
Everything up-to-date
[sync] 推送 backup (GitHub 备份库) ...
   38722b6..6b5ddd6  main -> main
Everything up-to-date
[sync] 双远端推送完成。
```

项目仓自身实际推送：

```text
To https://gitee.com/ParvaUltra/pCryoxy.git
 * [new branch]      main -> main
ref: refs/heads/main HEAD
3288de7b501265e47443db30cc7d86094bfcbd45 HEAD
```

## 7. 未覆盖项

- 没有真实 Android 设备，未做安装、启动、VPN 权限、TUN FD、TCP/UDP、DNS、protect、进程杀灭/重建验证。
- 没实现 Xray 薄 Go 桥、RPC、RouteView、Geo 事务或核心升级；这些属于 PC-04/05/08 等后续卡。
- APK 为 unsigned release；未签发证书、未上传、未部署。
- 未验证应用 <10MB、内存/PSS、启动时延、系统代理或真实代理互通。
- 未覆盖 Windows ARM64、Android 32-bit ABI、iOS、macOS。
- Gradle 构建包含上游 Tauri/AGP 弃用警告与 Java 8 source/target 警告；未把警告当作功能通过。

## 8. 下一步

1. WorkBuddy 审核本交接，输出“通过 / 退回 / 受外部条件阻塞”。
2. 若结论为受外部条件阻塞，提供真实 Android 设备或明确将真机验收移交 PC-05 后再裁定。
3. 审核通过后再按拓扑认领 PC-01；不得提前认领其他卡。

## 9. §5 审核交接

- 卡ID：PC-00
- commit：`c3dae630d64669d619c24a00cfab22c01928d28a`；构建实测提交 `3288de7b501265e47443db30cc7d86094bfcbd45`（含 `fa947fe` / `7d30cb5` / `3288de7` / `c3dae63`）
- 文件清单：102 个跟踪文件；根基线、Cargo/ pnpm lock、`contracts/core-lock.json`、`crates/tauri-app/`（源码、Tauri 配置、Android 工程、schemas、icons）、`ui/`、`tools/build-*`、`docs/BUILD.md`
- 输入版本：需求确认基线 v1.0；工程蓝图 v0.2；API Spec v1.0；实施任务卡 v1.0
- 依赖审核号：2026-11-19 用户当次明确批准工具链与最小依赖；无独立工单号
- 实际测试：见第 5 节；Windows/Android 干净 checkout release 构建通过，ADB 设备列表为空
- 预期与实测：预期双端空壳可复现构建；实测两端生成产物且 checkout 保持干净；预期真机验收有设备，实测无设备
- 未覆盖项：见第 7 节
- 凭据脱敏检查：gitleaks staged patch 通过；仓库无真实凭据、证书、keystore、节点配置或本地 SDK/NDK 路径
- 是否新增依赖：是；Tauri Rust crates 2.12.x、Tauri CLI 2.12.6、SolidJS 1.9.19、Vite 8.3.8、vite-plugin-solid 2.11.17、TypeScript 7.0.2、pnpm 12.21.0，均有 lock
