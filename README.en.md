# DSH Web Launcher

**English** | [简体中文](./README.md)

A Windows desktop launcher for **DeepSeek Harness (dsh)**. Double-click to start the `dsh web` service in the background; once it's ready, the launcher automatically opens the Web UI in your browser. Closing the launcher window stops the service. Pair it with the bundled `icon.ico` to create a desktop shortcut for true one-click startup.

> DeepSeek Harness (dsh) is DeepSeek's open-source agent framework, available as a Web UI, CLI, or headless runner. Its Web UI runs at `http://127.0.0.1:3080` by default.

## 🎬 Demo

![DSH Web Launcher demo](./screenshot.gif)

## ✨ Features

- **One-click startup**: double-click `DSHstart.cmd` (or a desktop shortcut to it) to launch `dsh web` and open the browser automatically
- **Smart readiness detection**: the service starts in the background while the main thread polls the port — the browser opens only once the service is truly ready, avoiding "the browser opens before the page works"
- **Configurable proxy**: toggle an HTTP proxy on/off for reaching external model services on restricted networks
- **Configurable browser**: Chrome, Edge, or Firefox, with automatic install-path detection
- **Stale-process cleanup**: terminates leftover dsh processes before launch to free the port
- **Close-to-stop**: close the launcher window to stop the service — no manual process killing
- **Dependency self-check**: prints clear install hints when Node.js / dsh are missing; falls back to another supported browser automatically, and if none is found, prompts you to open the URL manually

## 📋 Prerequisites

1. **Node.js** (18+ recommended) — [nodejs.org](https://nodejs.org/)
2. **DeepSeek Harness installed**:
   ```bash
   npm install -g @deepseek-ai/dsh
   ```
   After install, the `dsh` command (`dsh.cmd`) should be on your PATH. You can also use `npx @deepseek-ai/dsh web` directly.
3. **A browser**: Chrome, Edge, or Firefox (any one works)

> The launcher self-checks these at runtime. If Node.js or dsh is missing it prints the install command; if no browser is found it still starts the service and tells you to open the URL manually.

## 🚀 Quick Start

### Option 1: Create a desktop shortcut in one click (recommended)

Run `create-shortcut.ps1` in this folder to create an icon-bearing shortcut on your desktop:

- Right-click `create-shortcut.ps1` → **Run with PowerShell**; or from a PowerShell prompt in this folder:
  ```powershell
  .\create-shortcut.ps1
  ```
- Then double-click **DSH Web Launcher** on your desktop to launch; close its window to stop.

> If execution policy blocks it, run instead:
> ```powershell
> powershell -ExecutionPolicy Bypass -File .\create-shortcut.ps1
> ```

### Option 2: Create the shortcut manually

1. Right-click `DSHstart.cmd` → **Send to** → **Desktop (create shortcut)**
2. Right-click the desktop shortcut → **Properties** → **Change Icon** → pick `icon.ico` from this folder

### Option 3: Run directly (no shortcut)

Double-click `DSHstart.cmd`, or from a terminal in this folder:

```powershell
.\DSHstart.cmd
```

You'll see a three-step progress output:

```
[1/3] Cleaning up stale dsh processes...
[2/3] Starting dsh web, will open it in chrome once ready...
      Waiting for port 3080 to start listening...
      Service ready; opened http://127.0.0.1:3080 in chrome
[3/3] dsh web is running (close this window to stop)
```

> First time in the Web UI: open Settings → enter your model API key → pick a workspace → get started.

## ⚙️ Configuration

All options live in a separate **`config.ps1`** file next to the launcher (kept apart from the main script so it's easy to edit):

| Option | Default | Description |
|--------|---------|-------------|
| `$UseProxy` | `$false` | Enable the HTTP proxy |
| `$ProxyHost` | `127.0.0.1` | Proxy host |
| `$ProxyPort` | `7897` | Proxy port |
| `$Browser` | `chrome` | Browser for the UI: `chrome`, `edge`, or `firefox` |
| `$Port` | `3080` | Port dsh web listens on (dsh default is 3080) |
| `$StartupTimeoutSec` | `60` | Seconds to wait for the service to become ready |

For example, to enable a local proxy and use Firefox:

```powershell
$UseProxy = $true
$Browser  = 'firefox'
```

### Personal settings (kept out of version control)

If you cloned this repo and want your own long-term preferences (without merge conflicts on future `git pull`s), copy `config.local.ps1.example` to `config.local.ps1` in the same folder and edit it. That file is gitignored, and any variable it defines **overrides** the same variable in `config.ps1`.

## 🧩 How it works

The launcher runs in three steps:

1. **[1/3] Clean up**: terminates leftover dsh node processes to free the port
2. **[2/3] Start & wait for ready**: launches `dsh web` in the background while the main thread polls the target port; the moment the port is listening (service ready), it opens the UI in the browser. This step **blocks until the browser actually opens**, ensuring the UI is reached only after the service is ready
3. **[3/3] Run in foreground**: `dsh web` keeps running in the foreground with live logs; close the window to stop

## 📁 Project structure

```
dsh_start/
├── DSHstart.cmd            # Windows entry point (double-click / shortcut target)
├── dsh-web-launcher.ps1    # Main logic
├── config.ps1              # User configuration (proxy, browser, port, ...)
├── config.local.ps1.example # Personal-override template (copy to config.local.ps1; gitignored)
├── create-shortcut.ps1     # Create a desktop shortcut in one click
├── icon.ico                # Shortcut icon
├── LICENSE                 # MIT License
├── README.md               # Chinese readme
└── README.en.md            # English readme (this file)
```

## 📄 License

Licensed under the [MIT License](./LICENSE) © 2026 Meng, Xiangxi.
