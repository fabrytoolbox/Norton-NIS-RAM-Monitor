@echo off
setlocal
cd /d "%~dp0"
where pwsh.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Norton-RAM-Monitor.ps1"
) else (
    echo PowerShell 7 non trovato!
    pause
)
endlocal
