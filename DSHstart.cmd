@echo off
rem ============================================================
rem  DSH Web Launcher - desktop entry point
rem  Runs dsh-web-launcher.ps1 (in the same folder as this .cmd):
rem    1) kills stale dsh processes (frees the configured port)
rem    2) boots `dsh web` in the background, waits for the port to
rem       listen, then opens it in the configured browser
rem    3) keeps `dsh web` in the foreground (logs shown; close the
rem       window to stop)
rem  All settings live in the CONFIG section of dsh-web-launcher.ps1.
rem ============================================================
chcp 65001 >nul
title DSH Web Launcher
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0dsh-web-launcher.ps1" %*
