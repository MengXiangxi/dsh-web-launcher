#requires -Version 5.1
# ============================================================
#  Create a desktop shortcut for DSH Web Launcher
#  Run this once to put a one-click launcher on your desktop.
#
#  Usage (in this folder):
#    right-click -> Run with PowerShell
#    or:  powershell -ExecutionPolicy Bypass -File .\create-shortcut.ps1
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$selfDir = $PSScriptRoot
$target  = Join-Path $selfDir 'DSHstart.cmd'
$icon    = Join-Path $selfDir 'icon.ico'
$lnkPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'DSH Web Launcher.lnk'

if (-not (Test-Path $target)) {
    Write-Host ('ERROR: DSHstart.cmd not found in {0}' -f $selfDir) -ForegroundColor Red
    Write-Host ''
    Write-Host 'Press Enter to close...' -NoNewline; Read-Host | Out-Null
    exit 1
}

try {
    $ws  = New-Object -ComObject WScript.Shell
    $lnk = $ws.CreateShortcut($lnkPath)
    $lnk.TargetPath       = $target
    $lnk.WorkingDirectory = $selfDir
    if (Test-Path $icon) { $lnk.IconLocation = $icon }
    $lnk.Save()
} catch {
    Write-Host ('ERROR: failed to create shortcut: {0}' -f $_.Exception.Message) -ForegroundColor Red
    Write-Host ''
    Write-Host 'Press Enter to close...' -NoNewline; Read-Host | Out-Null
    exit 1
}

Write-Host ('Desktop shortcut created: {0}' -f $lnkPath) -ForegroundColor Green
Write-Host ''
Write-Host 'Press Enter to close...' -NoNewline; Read-Host | Out-Null
