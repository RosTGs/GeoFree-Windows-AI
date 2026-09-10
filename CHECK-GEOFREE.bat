@echo off
setlocal

cd /d "%~dp0"
if not exist "%~dp0Check-GeoFree.ps1" (
    echo ERROR: Place Check-GeoFree.ps1 beside this launcher.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Check-GeoFree.ps1"
pause
