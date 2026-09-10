@echo off
setlocal

cd /d "%~dp0"
if not exist "%~dp0Auto-GeoFree.ps1" (
    echo ERROR: Place Auto-GeoFree.ps1 beside this launcher.
    echo.
    echo Extract the ZIP archive first, then run this file from the extracted folder.
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Auto-GeoFree.ps1"
pause
