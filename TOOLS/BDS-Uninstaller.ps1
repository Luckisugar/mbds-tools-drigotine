# BDS-Uninstaller.ps1
# Ferramenta para desinstalar mods de um mundo.
# Remove entradas dos arquivos world_behavior_packs.json / world_resource_packs.json
# Opcionalmente deleta as pastas correspondentes de behavior_packs / resource_packs.
# Combina com o estilo, robustez e UX das ferramentas de instalacao.
# Run from the server root: powershell -ExecutionPolicy Bypass -File ".\TOOLS\BDS-Uninstaller.ps1"

param(
    [ValidateSet("en","pt")]
    [string]$Lang = "en"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir

if (-not (Test-Path (Join-Path $root "bedrock_server.exe"))) {
    if ($Lang -eq "pt") {
        Write-Host "Erro: Nao foi possivel encontrar o bedrock_server.exe na pasta pai de TOOLS." -ForegroundColor Red
        Write-Host 'Execute o script a partir da raiz do servidor como: powershell -ExecutionPolicy Bypass -File ".\TOOLS\BDS-Uninstaller.ps1"'
    } else {
        Write-Host "Error: Could not find bedrock_server.exe in parent of TOOLS folder." -ForegroundColor Red
        Write-Host 'Run the script from the server root like: powershell -ExecutionPolicy Bypass -File ".\TOOLS\BDS-Uninstaller.ps1"'
    }
    exit 1
}

function Get-Text {
    param(
        [string]$Key,
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Args
    )
    if ($Lang -eq "pt") {
        $base = switch ($Key) {
            "HeaderTitle" { "=== Desinstalador Bedrock ===" }
            "Server" { "Servidor: {0}" }
            "SelectWorld" { "=== Selecionar Mundo ===" }
            "NoWorlds" { "Nenhum mundo encontrado." }
            "ServerRanOnce" { "o server.exe foi executado pelo menos uma vez???" }
            "Refresh" { "1. Atualizar lista de mundos" }
            "Exit" { "2. Sair" }
            "Choose" { "Escolha" }
            "Worlds" { "Mundos:" }
            "ChooseWorldNumber" { "Escolha o numero do mundo" }
            "InvalidChoice" { "Escolha invalida." }
            "InstalledPacks" { "=== Packs Instalados em {0} ===" }
            "NoCustomPacks" { "Nenhum pack custom encontrado registrado para o mundo '{0}'." }
            "NothingToUninstall" { "Nada para desinstalar." }
            "ChoosePack" { "Escolha o pack para desinstalar" }
            "Cancelled" { "Cancelado." }
            "UninstallConfirmation" { "=== Confirmacao de Desinstalacao ===" }
            "World" { "Mundo: {0}" }
            "Pack" { "Pack: {0}" }
            "BehaviorPackUUID" { "  Behavior Pack UUID:  {0}   v{1}" }
            "ResourcePackUUID" { "  Resource Pack UUID:  {0}   v{1}" }
            "FoundOnDisk" { "Encontrado no disco:" }
            "DeleteFolders" { "Deletar as pastas do pack do disco tambem? (s/n)" }
            "NoFoldersFound" { "Nenhuma pasta correspondente encontrada no disco (ja removida ou nome de pasta diferente)." -ForegroundColor Yellow }
            "ThisWill" { "Isso vai:" }
            "RemoveRegistration" { "  - Remover o registro dos arquivos json do mundo" }
            "DeleteFoldersAbove" { "  - DELETAR as pastas acima" }
            "LeaveFolders" { "  - Deixar as pastas no disco (apenas remover o registro)" }
            "Proceed" { "Prosseguir? (s/n)" }
            "DeletedFolder" { "Pasta deletada: {0}" }
            "UninstallComplete" { "=== Desinstalacao Completa ===" }
            "Removed" { "Removido: {0}" }
            "FoldersDeleted" { "Pastas dos packs foram deletadas." }
            "FoldersLeft" { "Pastas dos packs foram deixadas no disco." }
            "UpdatedWorldFiles" { "Arquivos do mundo atualizados:" }
            "RestartServer" { "Reinicie o servidor para aplicar as alteracoes." }
            "Done" { "Pronto." }
            default { $Key }
        }
    } else {
        $base = switch ($Key) {
            "HeaderTitle" { "=== Bedrock Uninstaller ===" }
            "Server" { "Server: {0}" }
            "SelectWorld" { "=== Select World ===" }
            "NoWorlds" { "No worlds found." }
            "ServerRanOnce" { "was the server.exe ran at least once???" }
            "Refresh" { "1. Refresh world list" }
            "Exit" { "2. Exit" }
            "Choose" { "Choose" }
            "Worlds" { "Worlds:" }
            "ChooseWorldNumber" { "Choose world number" }
            "InvalidChoice" { "Invalid choice." }
            "InstalledPacks" { "=== Installed Packs in {0} ===" }
            "NoCustomPacks" { "No custom packs found registered for world '{0}'." }
            "NothingToUninstall" { "Nothing to uninstall." }
            "ChoosePack" { "Choose pack to uninstall" }
            "Cancelled" { "Cancelled." }
            "UninstallConfirmation" { "=== Uninstall Confirmation ===" }
            "World" { "World: {0}" }
            "Pack" { "Pack: {0}" }
            "BehaviorPackUUID" { "  Behavior Pack UUID:  {0}   v{1}" }
            "ResourcePackUUID" { "  Resource Pack UUID:  {0}   v{1}" }
            "FoundOnDisk" { "Found on disk:" }
            "DeleteFolders" { "Delete the pack folder(s) from disk as well? (y/n)" }
            "NoFoldersFound" { "No matching folders found on disk (already removed or different folder name)." }
            "ThisWill" { "This will:" }
            "RemoveRegistration" { "  - Remove pack registration from the world's json files" }
            "DeleteFoldersAbove" { "  - DELETE the folders above" }
            "LeaveFolders" { "  - Leave the folders on disk (just unregister them)" }
            "Proceed" { "Proceed? (y/n)" }
            "DeletedFolder" { "Deleted folder: {0}" }
            "UninstallComplete" { "=== Uninstall Complete ===" }
            "Removed" { "Removed: {0}" }
            "FoldersDeleted" { "Pack folders were deleted." }
            "FoldersLeft" { "Pack folders were left on disk." }
            "UpdatedWorldFiles" { "Updated world files:" }
            "RestartServer" { "Restart the server to apply changes." }
            "Done" { "Done." }
            default { $Key }
        }
    }
    try {
        if ($Args -and $Args.Count -gt 0) {
            return ($base -f $Args)
        }
    } catch {
        return $base
    }
    return $base
}

$bpDir = Join-Path $root "behavior_packs"
$rpDir = Join-Path $root "resource_packs"
$worldsDir = Join-Path $root "worlds"

function ShowHeader($title) {
    Clear-Host
    Write-Host (Get-Text "HeaderTitle") -ForegroundColor Cyan
    Write-Host (Get-Text "Server" $root) -ForegroundColor Gray
    Write-Host ""
    Write-Host "=== $title ===" -ForegroundColor Cyan
    Write-Host ""
}

function ShowFooter {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host (Get-Text "Footer") -ForegroundColor DarkGray
}

function Get-PackInfo($packPath) {
    $man = Get-ChildItem $packPath -Recurse -Filter "manifest.json" | Select-Object -First 1
    if (-not $man) { throw "No manifest.json found in $packPath" }
    $data = Get-Content $man.FullName -Raw | ConvertFrom-Json
    @{
        Uuid    = $data.header.uuid
        Version = $data.header.version
    }
}

function Get-JsonContent($path) {
    if (Test-Path $path) {
        $lines = Get-Content $path | Where-Object { $_.Trim() -notmatch '^//' -and $_.Trim() -ne '' }
        $jsonText = $lines -join "`n"
        if ($jsonText.Trim()) {
            try {
                $raw = $jsonText | ConvertFrom-Json
                if ($null -eq $raw) { return @() }
                if ($raw -is [array]) { return $raw }
                return @($raw)
            } catch {
                Write-Host "Warning: Could not parse $path cleanly." -ForegroundColor Yellow
                return @()
            }
        }
    }
    return @()
}

function Get-PacksFromJson($path) {
    if (-not (Test-Path $path)) { return @() }

    $rawLines = Get-Content $path
    $commentNameForUuid = @{}

    $currentName = $null
    foreach ($line in $rawLines) {
        $trim = $line.Trim()
        if ($trim -match '^//') {
            $currentName = ($trim -replace '^//\s*', '').Trim()
            continue
        }
        if ($trim -match '"pack_id"\s*:\s*"([^"]+)"') {
            $uuid = $matches[1]
            if ($currentName) {
                $commentNameForUuid[$uuid] = $currentName
            }
            $currentName = $null
        }
    }

    $parsed = Get-JsonContent $path
    $result = @()

    foreach ($p in $parsed) {
        if (-not $p -or -not $p.pack_id) { continue }

        $name = $null
        if ($p.PSObject.Properties.Name -contains 'name' -and $p.name) {
            $name = $p.name
        } elseif ($commentNameForUuid.ContainsKey($p.pack_id)) {
            $name = $commentNameForUuid[$p.pack_id]
        }

        $ver = $p.version
        if (-not $ver) { $ver = @(1,0,0) }

        $result += [pscustomobject]@{
            Name    = if ($name) { $name } else { "Unknown" }
            Uuid    = $p.pack_id
            Version = $ver
        }
    }

    return $result
}

function Write-PacksToJson($path, $packs) {
    if (-not $packs -or $packs.Count -eq 0) {
        "[]" | Set-Content $path -Encoding UTF8
        return
    }

    $out = @()
    foreach ($p in $packs) {
        $out += [pscustomobject]@{
            pack_id = $p.Uuid
            version = $p.Version
            name    = if ($p.Name -and $p.Name -ne "Unknown") { $p.Name } else { "" }
        }
    }

    $out | ConvertTo-Json -Depth 5 | Set-Content $path -Encoding UTF8
}

function Get-FolderByUuid($baseDir, $uuid) {
    foreach ($dir in (Get-ChildItem $baseDir -Directory)) {
        try {
            $info = Get-PackInfo $dir.FullName
            if ($info.Uuid -eq $uuid) {
                return $dir.FullName
            }
        } catch {}
    }
    return $null
}

# === Main flow ===

ShowHeader (Get-Text "SelectWorld")

:worldLoop while ($true) {
    $worldList = @(Get-ChildItem $worldsDir -Directory | Select-Object -ExpandProperty Name)
    if ($worldList.Count -eq 0) {
        Write-Host (Get-Text "NoWorlds")
        Write-Host (Get-Text "ServerRanOnce")
        Write-Host ""
        Write-Host (Get-Text "Options")
        Write-Host (Get-Text "Refresh")
        Write-Host (Get-Text "Exit")
        $wOpt = Read-Host (Get-Text "Choose")
        if ($wOpt -eq "1") {
            continue :worldLoop
        } else {
            exit
        }
    }

    Write-Host (Get-Text "Worlds")
    for ($i = 0; $i -lt $worldList.Count; $i++) {
        Write-Host "$($i+1). $($worldList[$i])"
    }

    do {
        $wChoice = Read-Host (Get-Text "ChooseWorldNumber")
        $valid = $wChoice -match '^\d+$' -and [int]$wChoice -ge 1 -and [int]$wChoice -le $worldList.Count
        if (-not $valid) { Write-Host (Get-Text "InvalidChoice") -ForegroundColor Red }
    } while (-not $valid)

    $worldName = $worldList[[int]$wChoice - 1]
    $worldPath = Join-Path $worldsDir $worldName
    break :worldLoop
}

$bpJson = Join-Path $worldPath "world_behavior_packs.json"
$rpJson = Join-Path $worldPath "world_resource_packs.json"

$bpPacks = Get-PacksFromJson $bpJson
$rpPacks = Get-PacksFromJson $rpJson

# Combine by name (BP + RP together when they share a name)
$modMap = @{}
foreach ($p in $bpPacks) {
    $key = $p.Name
    if (-not $modMap.ContainsKey($key)) {
        $modMap[$key] = @{ Name = $p.Name; BP = $p; RP = $null }
    } else {
        $modMap[$key].BP = $p
    }
}
foreach ($p in $rpPacks) {
    $key = $p.Name
    if (-not $modMap.ContainsKey($key)) {
        $modMap[$key] = @{ Name = $p.Name; BP = $null; RP = $p }
    } else {
        $modMap[$key].RP = $p
    }
}

if ($modMap.Count -eq 0) {
    Write-Host (Get-Text "NoCustomPacks" $worldName)
    Write-Host (Get-Text "NothingToUninstall")
    ShowFooter
    exit
}

ShowHeader (Get-Text "InstalledPacks" $worldName)

$modList = @($modMap.Keys | Sort-Object)
for ($i = 0; $i -lt $modList.Count; $i++) {
    $n = $modList[$i]
    $entry = $modMap[$n]
    $has = @()
    if ($entry.BP) { $has += "BP" }
    if ($entry.RP) { $has += "RP" }
    $hasStr = if ($has.Count -gt 0) { " (" + ($has -join "+") + ")" } else { "" }
    Write-Host "$($i+1). $n$hasStr"
}

Write-Host ""
Write-Host "0. Cancel"

do {
    $choice = Read-Host (Get-Text "ChoosePack")
    $valid = $choice -match '^\d+$' -and [int]$choice -ge 0 -and [int]$choice -le $modList.Count
    if (-not $valid) { Write-Host (Get-Text "InvalidChoice") -ForegroundColor Red }
} while (-not $valid)

if ($choice -eq "0") {
    Write-Host (Get-Text "Cancelled")
    exit
}

$chosenName = $modList[[int]$choice - 1]
$modInfo = $modMap[$chosenName]

Clear-Host
Write-Host (Get-Text "UninstallConfirmation") -ForegroundColor Cyan
Write-Host (Get-Text "World" $worldName)
Write-Host (Get-Text "Pack" $chosenName)
Write-Host ""
if ($modInfo.BP) { Write-Host (Get-Text "BehaviorPackUUID" $modInfo.BP.Uuid ($modInfo.BP.Version -join '.')) }
if ($modInfo.RP) { Write-Host (Get-Text "ResourcePackUUID" $modInfo.RP.Uuid ($modInfo.RP.Version -join '.')) }
Write-Host ""

# Resolve real folders using UUID (reliable)
$bpFolder = $null
$rpFolder = $null
if ($modInfo.BP) { $bpFolder = Get-FolderByUuid $bpDir $modInfo.BP.Uuid }
if ($modInfo.RP) { $rpFolder = Get-FolderByUuid $rpDir $modInfo.RP.Uuid }

if ($bpFolder -or $rpFolder) {
    Write-Host (Get-Text "FoundOnDisk")
    if ($bpFolder) { Write-Host "  behavior_packs/$([System.IO.Path]::GetFileName($bpFolder))" }
    if ($rpFolder) { Write-Host "  resource_packs/$([System.IO.Path]::GetFileName($rpFolder))" }

    Write-Host ""
    $delFolders = Read-Host (Get-Text "DeleteFolders")
    $doDeleteFolders = ($delFolders -eq 'y' -or $delFolders -eq 'Y' -or $delFolders -eq 's' -or $delFolders -eq 'S')
} else {
    Write-Host (Get-Text "NoFoldersFound") -ForegroundColor Yellow
    $doDeleteFolders = $false
}

Write-Host ""
Write-Host (Get-Text "ThisWill")
Write-Host (Get-Text "RemoveRegistration")
if ($doDeleteFolders) {
    Write-Host (Get-Text "DeleteFoldersAbove") -ForegroundColor Red
} else {
    Write-Host (Get-Text "LeaveFolders")
}
Write-Host ""

$confirm = Read-Host (Get-Text "Proceed")
if ($confirm -ne 'y' -and $confirm -ne 'Y' -and $confirm -ne 's' -and $confirm -ne 'S') {
    Write-Host (Get-Text "Cancelled")
    exit
}

# Remove from JSONs
if ($modInfo.BP) {
    $remainingBP = $bpPacks | Where-Object { $_.Uuid -ne $modInfo.BP.Uuid }
    Write-PacksToJson $bpJson $remainingBP
}
if ($modInfo.RP) {
    $remainingRP = $rpPacks | Where-Object { $_.Uuid -ne $modInfo.RP.Uuid }
    Write-PacksToJson $rpJson $remainingRP
}

# Optionally delete folders
if ($doDeleteFolders) {
    if ($bpFolder -and (Test-Path $bpFolder)) {
        Remove-Item $bpFolder -Recurse -Force
        Write-Host (Get-Text "DeletedFolder" $bpFolder) -ForegroundColor Yellow
    }
    if ($rpFolder -and (Test-Path $rpFolder)) {
        Remove-Item $rpFolder -Recurse -Force
        Write-Host (Get-Text "DeletedFolder" $rpFolder) -ForegroundColor Yellow
    }
}

Clear-Host
Write-Host (Get-Text "UninstallComplete") -ForegroundColor Green
Write-Host (Get-Text "World" $worldName)
Write-Host (Get-Text "Removed" $chosenName)
if ($doDeleteFolders) {
    Write-Host (Get-Text "FoldersDeleted")
} else {
    Write-Host (Get-Text "FoldersLeft")
}
Write-Host ""
Write-Host (Get-Text "UpdatedWorldFiles")

if (Test-Path $bpJson) {
    Write-Host "`nworld_behavior_packs.json:"
    Get-Content $bpJson -Raw | Write-Host
}
if (Test-Path $rpJson) {
    Write-Host "`nworld_resource_packs.json:"
    Get-Content $rpJson -Raw | Write-Host
}

Write-Host ""
Write-Host (Get-Text "RestartServer") -ForegroundColor Yellow
ShowFooter

Write-Host (Get-Text "Done")
