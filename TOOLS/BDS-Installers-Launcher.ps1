# BDS-Installers-Launcher.ps1
# Main menu for Bedrock Dedicated Server (BDS) tools.
# Primary way to run: double-click INSTALADOR DE MCADDON.bat
# (or directly: pwsh .\TOOLS\BDS-Installers-Launcher.ps1)
# Easy to extend: just add to the $installers array below.

$ErrorActionPreference = "Stop"

# Determine paths (script is in TOOLS)
$scriptDir = $PSScriptRoot
$root = Split-Path -Parent $scriptDir

if (-not (Test-Path (Join-Path $root "bedrock_server.exe"))) {
    Write-Host "Error: Could not find bedrock_server.exe. Run from the server root." -ForegroundColor Red
    exit 1
}

# === CONFIG: Add new installers here for easy extensibility ===
$installers = @(
    @{
        Name = "Install .mcaddon files"
        Script = "BDS-Mcaddon-Installer.ps1"
        Description = "For .mcaddon bundles (usually contains BP + RP)"
    },
    @{
        Name = "Install .mcpack files"
        Script = "BDS-Mcpack-Installer.ps1"
        Description = "For individual .mcpack files (single BP or RP)"
    },
    @{
        Name = "Uninstall a mod"
        Script = "BDS-Uninstaller.ps1"
        Description = "Remove registration from a world + optionally delete pack folders"
    }
    # To add a new one in the future:
    # , @{ Name = "Install XYZ"; Script = "BDS-XYZ-Installer.ps1"; Description = "Description here" }
)

function ShowHeader {
    Clear-Host
    Write-Host "=== Bedrock Tools ===" -ForegroundColor Cyan
    Write-Host "Server root: $root" -ForegroundColor Gray
    Write-Host ""
}

function ShowFooter {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Select an option. Ctrl+C to exit." -ForegroundColor DarkGray
}

# Main menu screen
ShowHeader
Write-Host "Available tools:" -ForegroundColor White
Write-Host ""

for ($i = 0; $i -lt $installers.Count; $i++) {
    $num = $i + 1
    Write-Host "$num. $($installers[$i].Name)" -ForegroundColor White
    Write-Host "   $($installers[$i].Description)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "0. Exit" -ForegroundColor White
ShowFooter

$choice = Read-Host "Choose option"

if ($choice -eq "0") {
    Clear-Host
    Write-Host "Exiting..." -ForegroundColor Yellow
    exit 0
}

$index = [int]$choice - 1

if ($index -lt 0 -or $index -ge $installers.Count) {
    Write-Host "Invalid choice." -ForegroundColor Red
    Read-Host "Press Enter to try again"
    & $MyInvocation.MyCommand.Path
    exit
}

$selected = $installers[$index]

# Run the selected script seamlessly (same session, sub-script will Clear-Host immediately)
# Note: A brief transition may occur before the sub-script's Clear-Host.
$scriptPath = Join-Path $scriptDir $selected.Script
& $scriptPath

# After sub-script, ask if user wants to do another action.
# This is nicer when launching via the .bat (most common way).
Write-Host ""
$again = Read-Host "Run another tool? (y/n)"
if ($again -eq 'y' -or $again -eq 'Y') {
    & $MyInvocation.MyCommand.Path
    exit
}
Clear-Host
Write-Host "Exiting..." -ForegroundColor Yellow
exit 0