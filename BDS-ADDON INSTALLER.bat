@echo off
cd /d "%~dp0"

where pwsh.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    pwsh.exe -ExecutionPolicy Bypass -File ".\TOOLS\BDS-Installers-Launcher.ps1"
) else (
    powershell.exe -ExecutionPolicy Bypass -File ".\TOOLS\BDS-Installers-Launcher.ps1"
)

pause