@echo off
REM Wrapper: startet PowerShell mit Bypass-Policy, leitet ggf. URL als 1. Arg weiter
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Cogwright-Update.ps1" -DownloadUrl "%~1" -ExpectedVersion "%~2"
