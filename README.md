# DSH Web Launcher

[English](./README.en.md) | **简体中文**

一个面向 Windows 的 **DeepSeek Harness（dsh）** 桌面启动器。双击即可在后台启动 `dsh web` 服务，服务就绪后自动用浏览器打开 Web UI，关闭启动器窗口即停止服务。配合自带的 `icon.ico` 创建桌面快捷方式，实现真正的一键启动。

> DeepSeek Harness（简称 dsh）是 DeepSeek 开源的 Agent 框架，提供 Web UI / CLI / Headless 三种使用形态，其 Web UI 默认运行在 `http://127.0.0.1:3080`。

## ✨ 功能特性

- **一键启动**：双击 `DSHstart.cmd`（或其桌面快捷方式）即可启动 `dsh web` 并自动打开浏览器
- **智能就绪检测**：服务在后台启动、主流程同步轮询端口——只有当服务真正就绪时才打开浏览器，避免“浏览器先开、页面却报错”
- **可配置代理**：一键开启/关闭 HTTP 代理，便于在受限网络下访问外部模型服务
- **可配置浏览器**：支持 Firefox 与 Chrome，自动探测安装路径
- **自动清理旧进程**：启动前终止残留的 dsh 进程，释放被占用的端口
- **关窗即停**：关闭启动器窗口即停止服务，无需手动结束进程
- **依赖自检**：未检测到 Node.js / dsh 时会给出清晰的安装提示；浏览器缺失时自动回退到另一个，两者都没有则提示手动访问

## 📋 前置要求

1. **Node.js**（建议 18 及以上）—— [nodejs.org](https://nodejs.org/)
2. **DeepSeek Harness 已安装**：
   ```bash
   npm install -g @deepseek-ai/dsh
   ```
   安装后 `dsh` 命令应可在终端运行（`dsh.cmd` 位于 PATH 中）；也可直接使用 `npx @deepseek-ai/dsh web`。
3. **浏览器**：Firefox 或 Chrome（任选其一）

> 启动器在运行时会自检以上依赖。若 Node.js 或 dsh 缺失，会直接提示安装命令；若未找到任何浏览器，仍会照常启动服务并提示你手动打开 URL。

## 🚀 快速开始

### 方式一：一键创建桌面快捷方式（推荐）

运行本目录下的 `create-shortcut.ps1`，它会在桌面生成一个带图标的快捷方式：

- 在文件资源管理器中右键 `create-shortcut.ps1` → **使用 PowerShell 运行**；或在该目录打开 PowerShell 执行：
  ```powershell
  .\create-shortcut.ps1
  ```
- 之后双击桌面上的 **DSH Web Launcher** 即可一键启动；关闭窗口即停止服务。

> 若系统提示执行策略受限，可改用：
> ```powershell
> powershell -ExecutionPolicy Bypass -File .\create-shortcut.ps1
> ```

### 方式二：手动创建桌面快捷方式

1. 右键 `DSHstart.cmd` → **发送到** → **桌面快捷方式**
2. 右键桌面快捷方式 → **属性** → **更改图标** → 选择本目录下的 `icon.ico`

### 方式三：直接运行（不创建快捷方式）

双击 `DSHstart.cmd`，或在该目录下打开终端执行：

```powershell
.\DSHstart.cmd
```

启动后会看到三步进度输出：

```
[1/3] Cleaning up stale dsh processes...
[2/3] Starting dsh web, will open it in chrome once ready...
      Waiting for port 3080 to start listening...
      Service ready; opened http://127.0.0.1:3080 in chrome
[3/3] dsh web is running (close this window to stop)
```

> 首次进入 Web UI：打开 Settings → 填入模型 API Key → 选择 workspace → 开始使用。

## ⚙️ 配置

所有配置项集中在同目录下的 **`config.ps1`** 文件中（独立成文件，便于单独编辑，无需改动主脚本）：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `$UseProxy` | `$false` | 是否启用 HTTP 代理 |
| `$ProxyHost` | `127.0.0.1` | 代理地址 |
| `$ProxyPort` | `7897` | 代理端口 |
| `$Browser` | `chrome` | 打开 UI 的浏览器：`firefox` 或 `chrome` |
| `$Port` | `3080` | dsh web 监听端口（dsh 默认 3080） |
| `$StartupTimeoutSec` | `60` | 等待服务就绪的超时时间（秒） |

例如，启用本地代理并把浏览器改为 Firefox：

```powershell
$UseProxy = $true
$Browser  = 'firefox'
```

### 个人配置（不进版本库）

如果你 clone 后想长期使用自己的偏好（且以后 `git pull` 不会被冲突干扰），可复制 `config.local.ps1.example` 为同目录下的 `config.local.ps1` 并修改其中各项。该文件已被 `.gitignore` 忽略，其中定义的变量会**覆盖** `config.ps1` 中的同名项。

## 🧩 工作原理

启动器分三步执行：

1. **[1/3] 清理旧进程**：终止残留的 dsh node 进程，释放被占用的端口
2. **[2/3] 启动并等待就绪**：后台启动 `dsh web`，主流程同步轮询目标端口；一旦端口进入监听状态（服务就绪），立即用浏览器打开 UI。这一步会**阻塞到浏览器实际打开**，确保 UI 只在服务准备好后才被访问
3. **[3/3] 前台运行**：`dsh web` 在前台持续运行并输出日志，关闭窗口即停止服务

## 📁 项目结构

```
dsh_start/
├── DSHstart.cmd            # Windows 入口（双击运行 / 快捷方式目标）
├── dsh-web-launcher.ps1    # 主逻辑
├── config.ps1              # 用户配置（代理、浏览器、端口等）
├── config.local.ps1.example # 个人配置模板（复制为 config.local.ps1 使用，不进版本库）
├── create-shortcut.ps1     # 一键创建桌面快捷方式
├── icon.ico                # 快捷方式图标
├── LICENSE                 # MIT 许可证
├── README.md               # 中文说明（本文件）
└── README.en.md            # English readme
```

## 📄 许可证

本项目基于 [MIT License](./LICENSE) © 2026 Meng, Xiangxi。
