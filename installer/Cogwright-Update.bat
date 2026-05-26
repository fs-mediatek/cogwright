@echo off
REM Wrapper: startet PowerShell mit Bypass-Policy.
REM Arg 1 = URL zur files.json (Manifest mit Hashes), Arg 2 = erwartete Version
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Cogwright-Update.ps1" -ManifestUrl "%~1" -ExpectedVersion "%~2"
