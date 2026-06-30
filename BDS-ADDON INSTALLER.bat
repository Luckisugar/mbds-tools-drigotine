@echo off
cd /d "%~dp0"
pwsh.exe -ExecutionPolicy Bypass -File ".\TOOLS\BDS-Installers-Launcher.ps1"
pause