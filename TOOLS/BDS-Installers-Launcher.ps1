# BDS-Installers-Launcher.ps1
# Menu principal para ferramentas do Bedrock Dedicated Server (BDS).
# Forma principal de executar: clique duplo no BDS-ADDON INSTALLER.bat
# (or directly: powershell -ExecutionPolicy Bypass -File ".\TOOLS\BDS-Installers-Launcher.ps1")
# Easy to extend: add to the $installers array below.
# New: BDS-Mod-Manager.ps1 to check existing mods and automatically determine/set load order.

param(
    [ValidateSet("en","pt")]
    [string]$Lang = ""
)

$ErrorActionPreference = "Stop"

# Determine paths (script is in TOOLS)
$scriptDir = $PSScriptRoot
$root = Split-Path -Parent $scriptDir

if (-not (Test-Path (Join-Path $root "bedrock_server.exe"))) {
    Write-Host "Error: Could not find bedrock_server.exe. Run from the server root." -ForegroundColor Red
    exit 1
}

# Language selection - first thing
if (-not $Lang) {
    Clear-Host
    Write-Host "=== Escolha o idioma / Choose language ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🇺🇸  1. English"
    Write-Host "🇧🇷  2. Portugues (Brasil)"
    Write-Host ""
    $langChoice = Read-Host "Digite 1 ou 2 / Enter 1 or 2"
    if ($langChoice -eq "2") {
        $Lang = "pt"
    } else {
        $Lang = "en"
    }
}

# === CONFIG: Add new installers here for easy extensibility ===
if ($Lang -eq "pt") {
    $installers = @(
        @{
            Name = "Instalar arquivos .mcaddon"
            Script = "BDS-Mcaddon-Installer.ps1"
            Description = "Para pacotes .mcaddon (geralmente contem BP + RP)"
        },
        @{
            Name = "Instalar arquivos .mcpack"
            Script = "BDS-Mcpack-Installer.ps1"
            Description = "Para arquivos .mcpack individuais (BP ou RP unico)"
        },
        @{
            Name = "Desinstalar um mod"
            Script = "BDS-Uninstaller.ps1"
            Description = "Remover registro de um mundo + opcionalmente deletar pastas dos packs"
        },
        @{
            Name = "Verificar e Gerenciar Mods (ordem)"
            Script = "BDS-Mod-Manager.ps1"
            Description = "Listar mods instalados, verificar e auto-reordenar carregamento (dependencias)"
        }
        # To add a new one in the future:
        # , @{ Name = "Install XYZ"; Script = "BDS-XYZ-Installer.ps1"; Description = "Description here" }
    )
    $headerTitle = "=== Ferramentas Bedrock ==="
    $availableLabel = "Ferramentas disponiveis:"
    $exitLabel = "0. Sair"
    $chooseLabel = "Escolha uma opcao"
    $invalidMsg = "Opcao invalida."
    $pressEnterMsg = "Pressione Enter para tentar novamente"
    $runAnotherMsg = "Executar outra ferramenta? (s/n)"
    $exitingMsg = "Saindo..."
} else {
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
        },
        @{
            Name = "Check & Manage Mods (load order)"
            Script = "BDS-Mod-Manager.ps1"
            Description = "List installed mods, check and auto-reorder load order based on dependencies"
        }
    )
    $headerTitle = "=== Bedrock Tools ==="
    $availableLabel = "Available tools:"
    $exitLabel = "0. Exit"
    $chooseLabel = "Choose option"
    $invalidMsg = "Invalid choice."
    $pressEnterMsg = "Press Enter to try again"
    $runAnotherMsg = "Run another tool? (y/n)"
    $exitingMsg = "Exiting..."
}

function ShowHeader {
    Clear-Host
    Write-Host $headerTitle -ForegroundColor Cyan
    Write-Host "Server root: $root" -ForegroundColor Gray
    Write-Host ""
}

function ShowFooter {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    if ($Lang -eq "pt") {
        Write-Host "Selecione uma opcao. Ctrl+C para sair." -ForegroundColor DarkGray
    } else {
        Write-Host "Select an option. Ctrl+C to exit." -ForegroundColor DarkGray
    }
}

# Main menu screen
ShowHeader
Write-Host $availableLabel -ForegroundColor White
Write-Host ""

for ($i = 0; $i -lt $installers.Count; $i++) {
    $num = $i + 1
    Write-Host "$num. $($installers[$i].Name)" -ForegroundColor White
    Write-Host "   $($installers[$i].Description)" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host $exitLabel -ForegroundColor White
ShowFooter

$choice = Read-Host $chooseLabel

if ($choice -eq "0") {
    Clear-Host
    Write-Host $exitingMsg -ForegroundColor Yellow
    exit 0
}

$index = [int]$choice - 1

if ($index -lt 0 -or $index -ge $installers.Count) {
    Write-Host $invalidMsg -ForegroundColor Red
    Read-Host $pressEnterMsg
    & $MyInvocation.MyCommand.Path -Lang $Lang
    exit
}

$selected = $installers[$index]

# Run the selected script seamlessly (same session, sub-script will Clear-Host immediately)
# Note: A brief transition may occur before the sub-script's Clear-Host.
$scriptPath = Join-Path $scriptDir $selected.Script
& $scriptPath -Lang $Lang

# After sub-script, ask if user wants to do another action.
# This is nicer when launching via the .bat (most common way).
Write-Host ""
$again = Read-Host $runAnotherMsg
if ($again -eq 'y' -or $again -eq 'Y' -or $again -eq 's' -or $again -eq 'S') {
    & $MyInvocation.MyCommand.Path -Lang $Lang
    exit
}
Clear-Host
Write-Host $exitingMsg -ForegroundColor Yellow
exit 0