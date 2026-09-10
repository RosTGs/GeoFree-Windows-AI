@echo off
setlocal

cd /d "%~dp0"
if not exist "%~dp0Remove-GeoFree.ps1" (
    echo ERROR: Place Remove-GeoFree.ps1 beside this launcher.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Remove-GeoFree.ps1"
pause
