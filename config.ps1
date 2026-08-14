# ============================================================
#  DSH Web Launcher - User Configuration
#  Edit the values below to suit your setup. This file is loaded
#  automatically by dsh-web-launcher.ps1 at startup, so you can
#  change settings here without touching the main script.
# ============================================================

# Proxy: set $UseProxy to $true to route dsh's network traffic through a
# local HTTP proxy. Leave it $false for a direct connection.
$UseProxy  = $true
$ProxyHost = '127.0.0.1'
$ProxyPort = 7897

# Browser used to open the UI: 'firefox' or 'chrome'.
$Browser = 'firefox'

# Port that `dsh web` listens on (dsh default is 3080).
$Port = 3080

# How long (in seconds) to wait for the service to become ready.
$StartupTimeoutSec = 60
