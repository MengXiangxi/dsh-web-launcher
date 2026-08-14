#requires -Version 5.1
# ============================================================
#  DSH Web Launcher
#  Starts `dsh web` and opens it in a browser once the service
#  is ready. All user-tunable settings live in config.ps1.
#
#  Steps:
#    1) kills stale dsh processes (frees the configured port)
#    2) boots `dsh web` in the background, waits for the port to
#       enter the listening state, then opens it in a browser
#    3) keeps `dsh web` in the foreground (logs shown; close the
#       window to stop)
# ============================================================

# --- Console UTF-8 output (matches the chcp 65001 in the .cmd entry) ---
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# -------------------- Helpers --------------------

# Print an error block, wait for the user to acknowledge, then exit.
# The first line is shown in red (the error); the rest in yellow (hints).
function Fail {
    param([Parameter(Mandatory)][string[]]$Lines)
    Write-Host ''
    $i = 0
    foreach ($l in $Lines) {
        if ($i -eq 0) { Write-Host $l -ForegroundColor Red }
        else          { Write-Host ('   ' + $l) -ForegroundColor Yellow }
        $i++
    }
    Write-Host ''
    Write-Host 'Press Enter to close this window...' -NoNewline
    Read-Host | Out-Null
    exit 1
}

# Find a browser executable by name: standard install paths first, then PATH.
function Get-BrowserPath {
    param([string]$Name)
    $candidates = switch ($Name) {
        'firefox' {
            @("$env:PROGRAMFILES\Mozilla Firefox\firefox.exe",
              "${env:PROGRAMFILES(x86)}\Mozilla Firefox\firefox.exe")
        }
        'chrome' {
            @("$env:PROGRAMFILES\Google\Chrome\Application\chrome.exe",
              "${env:PROGRAMFILES(x86)}\Google\Chrome\Application\chrome.exe",
              "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe")
        }
        'edge' {
            @("$env:PROGRAMFILES\Microsoft\Edge\Application\msedge.exe",
              "${env:PROGRAMFILES(x86)}\Microsoft\Edge\Application\msedge.exe",
              "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe")
        }
        default { @() }
    }
    foreach ($c in $candidates) { if ($c -and (Test-Path $c)) { return $c } }

    $commandName = switch ($Name) {
        'firefox' { 'firefox' }
        'chrome'  { 'chrome' }
        'edge'    { 'msedge' }
        default   { $null }
    }
    if ($commandName) {
        $cmd = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

# --- Load user configuration ---
$configPath = Join-Path $PSScriptRoot 'config.ps1'
if (-not (Test-Path $configPath)) {
    Fail @(
        'ERROR: config.ps1 was not found next to the launcher.'
        'It ships with this tool - restore it from your download and try again.'
    )
}
. $configPath

# Optional personal overrides: config.local.ps1 is meant to stay out of
# version control (see .gitignore). Values set there win over config.ps1.
$localConfigPath = Join-Path $PSScriptRoot 'config.local.ps1'
if (Test-Path $localConfigPath) { . $localConfigPath }

# Sensible defaults in case an option was removed from config.ps1.
if (-not (Get-Variable UseProxy          -ErrorAction SilentlyContinue)) { $UseProxy          = $false }
if (-not (Get-Variable ProxyHost         -ErrorAction SilentlyContinue)) { $ProxyHost         = '127.0.0.1' }
if (-not (Get-Variable ProxyPort         -ErrorAction SilentlyContinue)) { $ProxyPort         = 7897 }
if (-not (Get-Variable Browser           -ErrorAction SilentlyContinue)) { $Browser           = 'chrome' }
if (-not (Get-Variable Port              -ErrorAction SilentlyContinue)) { $Port              = 3080 }
if (-not (Get-Variable StartupTimeoutSec -ErrorAction SilentlyContinue)) { $StartupTimeoutSec = 60 }

# --- Pre-flight: verify prerequisites ---
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Fail @(
        'ERROR: Node.js was not found on your PATH.'
        'dsh needs Node.js to run.'
        'Install it from https://nodejs.org/ and try again.'
    )
}
$dshCmd = Get-Command dsh.cmd -ErrorAction SilentlyContinue
if (-not $dshCmd) {
    Fail @(
        'ERROR: dsh (DeepSeek Harness) was not found on your PATH.'
        'Install it with:'
        '    npm install -g @deepseek-ai/dsh'
        'Then restart this launcher.'
    )
}
$bin = Join-Path (Split-Path $dshCmd.Source) 'node_modules\@deepseek-ai\dsh\lib\bin.js'
if (-not (Test-Path $bin)) {
    Fail @(
        'ERROR: expected dsh entry not found:'
        "    $bin"
        'Your dsh install may be broken. Try reinstalling:'
        '    npm install -g @deepseek-ai/dsh'
    )
}

# --- Apply proxy settings if enabled ---
if ($UseProxy) {
    $proxyUrl = 'http://{0}:{1}' -f $ProxyHost, $ProxyPort
    $env:NODE_USE_ENV_PROXY = '1'
    $env:HTTP_PROXY  = $proxyUrl
    $env:HTTPS_PROXY = $proxyUrl
}

# --- Working directory: user home ---
Set-Location $env:USERPROFILE

Write-Host ''
Write-Host '============================================================'
if ($UseProxy) {
    Write-Host ('  DSH Web Launcher   (proxy {0}:{1})' -f $ProxyHost, $ProxyPort)
} else {
    Write-Host '  DSH Web Launcher'
}
Write-Host '============================================================'
Write-Host ''

# --- [1/3] Kill stale dsh processes to free the port ---
Write-Host '[1/3] Cleaning up stale dsh processes...'
$stale = Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
    Where-Object { $_.CommandLine -and ($_.CommandLine -match 'deepseek-ai.*dsh') }
if (-not $stale) {
    Write-Host '      No stale processes found'
} else {
    foreach ($s in $stale) {
        Write-Host ('      Terminated PID {0}' -f $s.ProcessId)
        Stop-Process -Id $s.ProcessId -Force -ErrorAction SilentlyContinue
    }
}
Start-Sleep -Seconds 2

# --- Resolve the browser (fall back through the supported browser list) ---
$supportedBrowsers = @('chrome', 'edge', 'firefox')
if ($Browser -notin $supportedBrowsers) {
    Write-Host ("      WARNING: unsupported browser '{0}' in config; falling back to chrome." -f $Browser) -ForegroundColor Yellow
    $Browser = 'chrome'
}

$configuredBrowser = $Browser
$browserPath = $null
$browserOrder = @($configuredBrowser) + @($supportedBrowsers | Where-Object { $_ -ne $configuredBrowser })
foreach ($candidateBrowser in $browserOrder) {
    $candidatePath = Get-BrowserPath -Name $candidateBrowser
    if ($candidatePath) {
        $browserPath = $candidatePath
        $Browser = $candidateBrowser
        break
    }
}

if ($browserPath) {
    if ($Browser -ne $configuredBrowser) {
        Write-Host ('      Note: {0} not found; will use {1} instead.' -f $configuredBrowser, $Browser)
    }
} else {
    Write-Host '      WARNING: no supported browser (Chrome, Edge, or Firefox) was found.' -ForegroundColor Yellow
    Write-Host '               Install one to auto-open the UI, or open the URL manually when ready.'
}

# --- [2/3] Boot dsh web in the background, wait for the port, then open the browser ---
if ($browserPath) {
    Write-Host ('[2/3] Starting dsh web, will open it in {0} once ready...' -f $Browser)
} else {
    Write-Host '[2/3] Starting dsh web (no browser detected - open the URL manually when ready)...'
}

# dsh web must be running before its port can listen, so we start it in the
# background and poll the port on the main thread. This keeps [2/3] blocking
# until the browser is actually launched.
$dshProc = Start-Process -FilePath 'node' -ArgumentList @($bin, 'web') -PassThru -NoNewWindow

Write-Host ('      Waiting for port {0} to start listening...' -f $Port)
$ready = $false
$tries = [int]($StartupTimeoutSec * 2)   # 500 ms per iteration
for ($i = 0; $i -lt $tries; $i++) {
    if ($dshProc.HasExited) {
        Write-Host ('      ERROR: dsh web exited early (exit code {0})' -f $dshProc.ExitCode) -ForegroundColor Red
        break
    }
    Start-Sleep -Milliseconds 500
    if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) {
        $ready = $true
        break
    }
}

if ($ready) {
    $url = 'http://127.0.0.1:{0}' -f $Port
    if ($browserPath) {
        Start-Process -FilePath $browserPath -ArgumentList $url
        Write-Host ('      Service ready; opened {0} in {1}' -f $url, $Browser)
    } else {
        Write-Host ('      Service ready; open this URL manually: {0}' -f $url) -ForegroundColor Yellow
    }
} elseif (-not $dshProc.HasExited) {
    Write-Host ('      WARNING: timed out after {0}s, port {1} still not listening (browser not opened)' -f $StartupTimeoutSec, $Port) -ForegroundColor Yellow
}

# --- [3/3] Keep dsh web in the foreground (logs shown; close the window to stop) ---
Write-Host '[3/3] dsh web is running (close this window to stop)'
Write-Host '------------------------------------------------------------'
try {
    $dshProc.WaitForExit()
} finally {
    if (-not $dshProc.HasExited) {
        Stop-Process -Id $dshProc.Id -Force -ErrorAction SilentlyContinue
    }
}
