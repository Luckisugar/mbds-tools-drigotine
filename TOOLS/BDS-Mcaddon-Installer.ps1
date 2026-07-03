# BDS-Mcaddon-Installer.ps1
# Ferramenta para descompactar .mcaddon, selecionar pastas bp/rp, copiar para oficial com nome, registrar uuids com comentarios no json do mundo.
# IMPORTANT: Run from the SERVER ROOT (not inside TOOLS):
#   cd "C:\path\to\your\server"
#   powershell -ExecutionPolicy Bypass -File ".\TOOLS\BDS-Mcaddon-Installer.ps1"

param(
    [ValidateSet("en","pt")]
    [string]$Lang = "en"
)

$ErrorActionPreference = "Stop"

# Determine server root from script location (in TOOLS), not current dir
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir

if (-not (Test-Path (Join-Path $root "bedrock_server.exe"))) {
    if ($Lang -eq "pt") {
        Write-Host "Erro: Nao foi possivel encontrar o bedrock_server.exe na pasta pai de TOOLS."
        Write-Host 'Execute o script a partir da raiz do servidor como: powershell -ExecutionPolicy Bypass -File ".\TOOLS\BDS-Mcaddon-Installer.ps1"'
    } else {
        Write-Host "Error: Could not find bedrock_server.exe in parent of TOOLS folder."
        Write-Host 'Run the script from the server root like: powershell -ExecutionPolicy Bypass -File ".\TOOLS\BDS-Mcaddon-Installer.ps1"'
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
            "HeaderTitle" { "=== Instalador de Addons Bedrock ===" }
            "Server" { "Servidor: {0}" }
            "Source" { "Fonte: {0}" }
            "Footer" { "Use setas ou numeros. Ctrl+C para sair." }
            "NoMcaddon" { "Nenhum .mcaddon encontrado em {0}" }
            "SelectMcaddon" { "=== Selecionar .mcaddon ===" }
            "LookingIn" { "Procurando em: {0}" }
            "AvailableMcaddons" { ".mcaddons disponiveis:" }
            "ChooseNumber" { "Escolha o numero" }
            "InvalidChoice" { "Escolha invalida, digite um numero entre 1 e {0}" }
            "Selected" { "Selecionado: {0}" }
            "Unpacking" { "=== Descompactando ===" }
            "Mod" { "Mod: {0}" }
            "UnpackedTo" { "Descompactado para {0}" }
            "NoSubfolders" { "Nenhum subpasta apos descompactar. Verifique {0}" }
            "FoundNestedMcpacks" { "Encontrados {0} .mcpack aninhado(s), descompactando..." }
            "SinglePackDetected" { "`nPack unico detectado neste .mcaddon." }
            "IsBPOrRP" { "É Behavior Pack ou Resource Pack?" }
            "ChooseBP" { "1. Behavior Pack (BP)" }
            "ChooseRP" { "2. Resource Pack (RP)" }
            "Choose1or2" { "Escolha 1 ou 2" }
            "SelectBP" { "=== Selecionar Behavior Pack ===" }
            "Unpacked" { "Descompactado: {0}" }
            "Subfolders" { "Subpastas no descompactado:" }
            "NumberForBP" { "Numero para a pasta BP" }
            "InvalidTryAgain" { "Escolha invalida, tente novamente." }
            "NameForBP" { "Nome para este BP na pasta oficial" }
            "InvalidName" { "Nome invalido (sem caracteres especiais ou vazio). Tente novamente." }
            "FolderExists" { "Pasta '{0}' ja existe em behavior_packs." }
            "Overwrite" { "Sobrescrever? (s/n)" }
            "Overwriting" { "Sobrescrevendo..." }
            "SkippingBP" { "Pulando copia do BP." }
            "SuccessBP" { "BP instalado com sucesso como '{0}' em behavior_packs" }
            "SelectRP" { "=== Selecionar Resource Pack ===" }
            "BP" { "BP: {0} (de {1})" }
            "BPOnly" { "BP: {0}" }
            "RPOnly" { "RP: {0}" }
            "BPSkipped" { "BP: Pulado" }
            "NumberForRP" { "Numero para a pasta RP" }
            "SuccessRP" { "RP instalado com sucesso como '{0}' em resource_packs" }
            "RP skipped" { "RP pulado." }
            "InstallSummary" { "=== Resumo da Instalacao ===" }
            "CurrentCustom" { "Packs oficiais atuais (apenas custom):" }
            "BehaviorPacks" { "Behavior packs:" }
            "ResourcePacks" { "Resource packs:" }
            "SelectWorld" { "=== Selecionar Mundo ===" }
            "NoWorlds" { "Nenhum mundo encontrado" }
            "ServerRanOnce" { "o server.exe foi executado pelo menos uma vez???" }
            "Options" { "Opcoes:" }
            "Refresh" { "1. Atualizar lista de mundos" }
            "Discard" { "2. Descartar alteracoes e sair (remove packs instalados, mantem .mcaddon)" }
            "ChooseOption" { "Escolha a opcao" }
            "Worlds" { "Mundos:" }
            "ChooseWorldNumber" { "Escolha o numero do mundo" }
            "SelectedWorld" { "Mundo selecionado: {0}" }
            "World" { "Mundo: {0}" }
            "EnterWorldName" { "Digite o nome do mundo ou numero da lista" }
            "Complete" { "=== Completo ===" }
            "Success" { "=== Sucesso ===" }
            "BPAndRPRegistered" { "BP e RP registrados para o mundo '{0}'." }
            "NameStoredBP" { "Nome armazenado para BP: {0}" }
            "NameStoredRP" { "Nome armazenado para RP: {0}" }
            "CurrentlyInstalled" { "`nAtualmente instalado no mundo '{0}' (dos jsons):" }
            "RestartServer" { "Reinicie o servidor para testar." }
            "DeletedOriginal" { ".mcaddon original deletado: {0}" }
            default { $Key }
        }
    } else {
        $base = switch ($Key) {
            "HeaderTitle" { "=== Bedrock Addon Installer ===" }
            "Server" { "Server: {0}" }
            "Source" { "Source: {0}" }
            "Footer" { "Use arrows or numbers. Ctrl+C to exit." }
            "NoMcaddon" { "No .mcaddon found in {0}" }
            "SelectMcaddon" { "=== Select .mcaddon ===" }
            "LookingIn" { "Looking in: {0}" }
            "AvailableMcaddons" { "Available .mcaddons:" }
            "ChooseNumber" { "Choose number" }
            "InvalidChoice" { "Invalid choice, enter a number between 1 and {0}" }
            "Selected" { "Selected: {0}" }
            "Unpacking" { "=== Unpacking ===" }
            "Mod" { "Mod: {0}" }
            "UnpackedTo" { "Unpacked to {0}" }
            "NoSubfolders" { "No subfolders after unpack. Check {0}" }
            "FoundNestedMcpacks" { "Found {0} nested .mcpack file(s), unpacking them..." }
            "SinglePackDetected" { "`nSingle pack detected in this .mcaddon." }
            "IsBPOrRP" { "Is this a Behavior Pack or Resource Pack?" }
            "ChooseBP" { "1. Behavior Pack (BP)" }
            "ChooseRP" { "2. Resource Pack (RP)" }
            "Choose1or2" { "Choose 1 or 2" }
            "SelectBP" { "=== Select Behavior Pack ===" }
            "Unpacked" { "Unpacked: {0}" }
            "Subfolders" { "Subfolders in unpacked:" }
            "NumberForBP" { "Number for BP folder" }
            "InvalidTryAgain" { "Invalid choice, try again." }
            "NameForBP" { "Name for this BP in official folder" }
            "InvalidName" { "Invalid name (no special chars or empty). Try again." }
            "FolderExists" { "Folder '{0}' already exists in behavior_packs." }
            "Overwrite" { "Overwrite? (y/n)" }
            "Overwriting" { "Overwriting..." }
            "SkippingBP" { "Skipping BP copy." }
            "SuccessBP" { "Successfully installed BP as '{0}' in behavior_packs" }
            "SelectRP" { "=== Select Resource Pack ===" }
            "BP" { "BP: {0} (from {1})" }
            "BPOnly" { "BP: {0}" }
            "RPOnly" { "RP: {0}" }
            "BPSkipped" { "BP: Skipped" }
            "NumberForRP" { "Number for RP folder" }
            "SuccessRP" { "Successfully installed RP as '{0}' in resource_packs" }
            "RP skipped" { "RP skipped." }
            "SkippingRP" { "Skipping RP copy." }
            "InstallSummary" { "=== Installation Summary ===" }
            "CurrentCustom" { "Current official (custom only):" }
            "BehaviorPacks" { "Behavior packs:" }
            "ResourcePacks" { "Resource packs:" }
            "SelectWorld" { "=== Select World ===" }
            "NoWorlds" { "No worlds found" }
            "ServerRanOnce" { "was the server.exe ran atleast once???" }
            "Options" { "Options:" }
            "Refresh" { "1. Refresh world list" }
            "Discard" { "2. Discard changes and leave (removes installed packs, keeps .mcaddon)" }
            "ChooseOption" { "Choose option" }
            "Worlds" { "Worlds:" }
            "ChooseWorldNumber" { "Choose world number" }
            "SelectedWorld" { "Selected world: {0}" }
            "World" { "World: {0}" }
            "EnterWorldName" { "Enter world name or number from list" }
            "Complete" { "=== Complete ===" }
            "Success" { "=== Success ===" }
            "BPAndRPRegistered" { "BP and RP registered for world '{0}'." }
            "NameStoredBP" { "Name stored for BP: {0}" }
            "NameStoredRP" { "Name stored for RP: {0}" }
            "CurrentlyInstalled" { "`nCurrently installed in world '{0}' (from jsons):" }
            "RestartServer" { "Restart the server to test." }
            "DeletedOriginal" { "Deleted original .mcaddon: {0}" }
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

$unpackedDir = Join-Path $root "UNPACKED MODS"
$bpDir = Join-Path $root "behavior_packs"
$rpDir = Join-Path $root "resource_packs"
$worldsDir = Join-Path $root "worlds"
$originalDir = Join-Path $root "UNPACKED MODS"

$bpDest = $null
$rpDest = $null
$bpFolder = $null
$rpFolder = $null
$bpInfo = $null
$rpInfo = $null

# Ensure folders
@($unpackedDir, $bpDir, $rpDir, $worldsDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

Clear-Host
Write-Host (Get-Text "HeaderTitle") -ForegroundColor Cyan
Write-Host (Get-Text "Server" $root)
Write-Host (Get-Text "Source" $originalDir)
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

function ShowFooter {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host (Get-Text "Footer") -ForegroundColor DarkGray
}

function Get-JsonContent($path) {
    if (Test-Path $path) {
        # Strip lines that are comments (for backward compat with files that had // comments)
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

function Write-WorldJson($path, $packId, $version, $modName) {
    $packs = Get-JsonContent $path
    if ($null -eq $packs) { $packs = @() }
    if ($packs -isnot [array]) { $packs = @($packs) }
    # remove dup by pack_id
    $packs = @($packs | Where-Object { $_ -and $_.pack_id -ne $packId })
    # add new with name for readability
    $packs += [pscustomobject]@{
        pack_id = $packId
        version = $version
        name    = $modName
    }
    # Always write clean valid JSON (game ignores extra 'name' field)
    $packs | ConvertTo-Json -Depth 5 | Set-Content $path -Encoding UTF8
}

function Get-PackInfo($packPath) {
    $man = Get-ChildItem -LiteralPath $packPath -Recurse -Filter "manifest.json" | Select-Object -First 1
    if (-not $man) { 
        Write-Host "No manifest found in $packPath (searched recursively)" -ForegroundColor Red
        throw "No manifest in $packPath" 
    }
    $data = [System.IO.File]::ReadAllText($man.FullName, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    @{
        Uuid = $data.header.uuid
        Version = $data.header.version
    }
}

# List .mcaddon
$mcaddons = Get-ChildItem -Path $originalDir -Filter "*.mcaddon" -ErrorAction SilentlyContinue
if ($mcaddons.Count -eq 0) {
    Write-Host (Get-Text "NoMcaddon" $originalDir)
    exit
}

Clear-Host
Write-Host (Get-Text "SelectMcaddon") -ForegroundColor Cyan
Write-Host (Get-Text "LookingIn" $originalDir)
Write-Host ""
Write-Host (Get-Text "AvailableMcaddons")
for ($i=0; $i -lt $mcaddons.Count; $i++) {
    Write-Host "$($i+1). $($mcaddons[$i].Name)"
}
do {
    $choice = Read-Host (Get-Text "ChooseNumber")
    $valid = $choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $mcaddons.Count
    if (-not $valid) { Write-Host ((Get-Text "InvalidChoice") -f $mcaddons.Count) -ForegroundColor Red }
} while (-not $valid)
$mcaddon = $mcaddons[[int]$choice - 1]
$modBase = $mcaddon.BaseName
Write-Host (Get-Text "Selected" $modBase) -ForegroundColor Green
ShowFooter

# Unpack
Clear-Host
Write-Host (Get-Text "Unpacking") -ForegroundColor Cyan
Write-Host (Get-Text "Mod" $modBase)
Write-Host ""
$unpackPath = Join-Path $unpackedDir $modBase
if (Test-Path $unpackPath) { Remove-Item $unpackPath -Recurse -Force }
$tempZip = Join-Path $env:TEMP "$modBase.zip"
Copy-Item $mcaddon.FullName $tempZip -Force
Expand-Archive -Path $tempZip -DestinationPath $unpackPath -Force
Remove-Item $tempZip
Write-Host (Get-Text "UnpackedTo" $unpackPath) -ForegroundColor Green
ShowFooter

# Auto-unpack any .mcpack files found inside the extracted .mcaddon
# (some .mcaddon contain .mcpack archives instead of pre-extracted folders)
$innerMcpacks = Get-ChildItem $unpackPath -Filter "*.mcpack" -Recurse
if ($innerMcpacks.Count -gt 0) {
    Write-Host (Get-Text "FoundNestedMcpacks" $innerMcpacks.Count) -ForegroundColor Green
    $idx = 0
    # resolve TEMP to full long path to avoid short name (~) issues
    $tempRoot = $env:TEMP
    if ($tempRoot) {
        try { $tempRoot = (Get-Item -LiteralPath $tempRoot).FullName } catch {}
    }
    if (-not $tempRoot) { $tempRoot = [System.IO.Path]::GetTempPath() }
    foreach ($mcp in $innerMcpacks) {
        if ($mcp.PSIsContainer -or -not (Test-Path -LiteralPath $mcp.FullName -PathType Leaf)) {
            Write-Host "Skipping non-file item: $($mcp.FullName)" -ForegroundColor Yellow
            continue
        }
        $baseName = $mcp.BaseName
        if ([string]::IsNullOrWhiteSpace($baseName)) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($mcp.Name)
        }
        if ([string]::IsNullOrWhiteSpace($baseName)) {
            $baseName = "pack$idx"
        }
        # sanitize for invalid path chars
        $baseName = $baseName -replace '[\\/:*?"<>|]', '_'
        $subDir = Join-Path $mcp.Directory $baseName
        if (Test-Path -LiteralPath $subDir) { Remove-Item -LiteralPath $subDir -Recurse -Force }
        # use guid for temp to avoid any name issues
        $unique = [guid]::NewGuid().ToString()
        $t = Join-Path $tempRoot ($unique + ".zip")
        Copy-Item -LiteralPath $mcp.FullName -Destination $t -Force
        if (-not (Test-Path -LiteralPath $t)) {
            Write-Host "Failed to copy temp file for $($mcp.Name)" -ForegroundColor Red
            continue
        }
        Expand-Archive -Path $t -DestinationPath $subDir -Force
        Remove-Item -LiteralPath $t -Force
        Remove-Item -LiteralPath $mcp.FullName -Force
        $idx++
    }
}

$skipBP = $false
$skipRP = $false

# Get subfolders - list top level subfolders (original behaviour)
# drill down logic will find the actual pack with manifest inside chosen ones (for nested cases)
$subs = Get-ChildItem $unpackPath -Directory
if ($subs.Count -eq 0) {
    Write-Host (Get-Text "NoSubfolders" $unpackPath)
    exit
}

Clear-Host
Write-Host (Get-Text "SelectBP") -ForegroundColor Cyan
Write-Host (Get-Text "Mod" $modBase)
Write-Host (Get-Text "Unpacked" $unpackPath)
Write-Host ""
Write-Host (Get-Text "Subfolders")
for ($i=0; $i -lt $subs.Count; $i++) {
    Write-Host "$($i+1). $($subs[$i].Name)"
}

Write-Host ""
do {
    $bpChoice = Read-Host (Get-Text "NumberForBP")
    $valid = $bpChoice -match '^\d+$' -and [int]$bpChoice -ge 1 -and [int]$bpChoice -le $subs.Count
    if (-not $valid) { Write-Host (Get-Text "InvalidTryAgain") -ForegroundColor Red }
} while (-not $valid)
$chosenSub = $subs[[int]$bpChoice - 1]

# Drill down inside the chosen sub to find the actual pack root that has manifest.json
# (handles cases where chosen sub is a container and the real pack is nested inside)
$packRoots = Get-ChildItem -LiteralPath $chosenSub.FullName -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "manifest.json") }
if ($packRoots.Count -eq 0) {
    if (Test-Path -LiteralPath (Join-Path $chosenSub.FullName "manifest.json")) {
        $bpFolder = $chosenSub
    } else {
        $manifests = Get-ChildItem -LiteralPath $chosenSub.FullName -Recurse -Filter "manifest.json" | Select-Object -First 1
        if ($manifests) {
            $bpFolder = $manifests.Directory
            Write-Host "Found nested pack in: $($bpFolder.Name)" -ForegroundColor Yellow
        } else {
            $bpFolder = $chosenSub
        }
    }
} else {
    $bpFolder = $packRoots[0]  # if multiple, take first; could add picker later
}

do {
    $bpName = Read-Host (Get-Text "NameForBP")
    if ($bpName -match '[\\/:*?"<>|]' -or [string]::IsNullOrWhiteSpace($bpName)) {
        Write-Host (Get-Text "InvalidName") -ForegroundColor Red
    }
} while ($bpName -match '[\\/:*?"<>|]' -or [string]::IsNullOrWhiteSpace($bpName))
$bpDest = Join-Path $bpDir $bpName

# Get info from source
$bpInfo = Get-PackInfo $bpFolder.FullName

# Check for existing
$skipBP = $false
if (Test-Path $bpDest) {
    Write-Host (Get-Text "FolderExists" $bpName) -ForegroundColor Yellow
    $ow = Read-Host (Get-Text "Overwrite")
    if ($ow -eq 'y' -or $ow -eq 'Y' -or $ow -eq 's' -or $ow -eq 'S') {
        Remove-Item $bpDest -Recurse -Force
        Write-Host (Get-Text "Overwriting") -ForegroundColor Yellow
    } else {
        Write-Host (Get-Text "SkippingBP") -ForegroundColor Yellow
        $skipBP = $true
    }
}
if (-not $skipBP) {
    Copy-Item -LiteralPath $bpFolder.FullName -Destination $bpDest -Recurse -Force
    Write-Host (Get-Text "SuccessBP" $bpName) -ForegroundColor Green
}
ShowFooter

# RP - re-list subfolders and reuse the same name
Clear-Host
Write-Host (Get-Text "SelectRP") -ForegroundColor Cyan
Write-Host (Get-Text "Mod" $modBase)
if (-not $skipBP) {
    Write-Host (Get-Text "BP" $bpName $bpFolder.Name)
} else {
    Write-Host (Get-Text "BPSkipped")
}
Write-Host ""
Write-Host (Get-Text "Subfolders")
for ($i=0; $i -lt $subs.Count; $i++) {
    Write-Host "$($i+1). $($subs[$i].Name)"
}

Write-Host ""
do {
    $rpChoice = Read-Host (Get-Text "NumberForRP")
    $valid = $rpChoice -match '^\d+$' -and [int]$rpChoice -ge 1 -and [int]$rpChoice -le $subs.Count
    if (-not $valid) { Write-Host (Get-Text "InvalidTryAgain") -ForegroundColor Red }
} while (-not $valid)
$chosenSub = $subs[[int]$rpChoice - 1]

# Drill down inside the chosen sub to find the actual pack root that has manifest.json
$packRoots = Get-ChildItem -LiteralPath $chosenSub.FullName -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "manifest.json") }
if ($packRoots.Count -eq 0) {
    if (Test-Path -LiteralPath (Join-Path $chosenSub.FullName "manifest.json")) {
        $rpFolder = $chosenSub
    } else {
        $manifests = Get-ChildItem -LiteralPath $chosenSub.FullName -Recurse -Filter "manifest.json" | Select-Object -First 1
        if ($manifests) {
            $rpFolder = $manifests.Directory
            Write-Host "Found nested pack in: $($rpFolder.Name)" -ForegroundColor Yellow
        } else {
            $rpFolder = $chosenSub
        }
    }
} else {
    $rpFolder = $packRoots[0]
}
$rpName = $bpName
$rpDest = Join-Path $rpDir $rpName

$rpInfo = Get-PackInfo $rpFolder.FullName

# Check for existing RP
$skipRP = $false
if (Test-Path $rpDest) {
    Write-Host (Get-Text "FolderExists" $rpName) -ForegroundColor Yellow
    $ow = Read-Host (Get-Text "Overwrite")
    if ($ow -eq 'y' -or $ow -eq 'Y' -or $ow -eq 's' -or $ow -eq 'S') {
        Remove-Item $rpDest -Recurse -Force
        Write-Host (Get-Text "Overwriting") -ForegroundColor Yellow
    } else {
        Write-Host (Get-Text "SkippingRP") -ForegroundColor Yellow
        $skipRP = $true
    }
}
if (-not $skipRP) {
    Copy-Item -LiteralPath $rpFolder.FullName -Destination $rpDest -Recurse -Force
    Write-Host (Get-Text "SuccessRP" $rpName) -ForegroundColor Green
} else {
    Write-Host (Get-Text "RP skipped")
}
ShowFooter

# List new and current
Clear-Host
Write-Host (Get-Text "InstallSummary") -ForegroundColor Cyan
Write-Host (Get-Text "Mod" $modBase)
if (-not $skipBP) { Write-Host (Get-Text "BPOnly" $bpName) } else { Write-Host (Get-Text "BPSkipped") }
if (-not $skipRP) { Write-Host (Get-Text "RPOnly" $rpName) } else { Write-Host (Get-Text "RP skipped") }
Write-Host ""
Write-Host (Get-Text "CurrentCustom")
Write-Host (Get-Text "BehaviorPacks")
$excluded = 'vanilla*', 'chemistry*', 'editor*', 'server_*', 'experimental_*'
Get-ChildItem $bpDir -Directory | Where-Object { 
    $n = $_.Name
    ($excluded | Where-Object { $n -like $_ }).Count -eq 0
} | ForEach-Object { "  $($_.Name)" }

Write-Host (Get-Text "ResourcePacks")
Get-ChildItem $rpDir -Directory | Where-Object { 
    $n = $_.Name
    ($excluded | Where-Object { $n -like $_ }).Count -eq 0
} | ForEach-Object { "  $($_.Name)" }
ShowFooter
ShowFooter

Clear-Host
Write-Host (Get-Text "SelectWorld") -ForegroundColor Cyan
Write-Host (Get-Text "Mod" $modBase)
if (-not $skipBP) { Write-Host (Get-Text "BPOnly" $bpName) } else { Write-Host (Get-Text "BPSkipped") }
if (-not $skipRP) { Write-Host (Get-Text "RPOnly" $rpName) } else { Write-Host (Get-Text "RP skipped") }
Write-Host ""

$worldList = Get-ChildItem $worldsDir -Directory
if ($worldList.Count -gt 0) {
    Write-Host (Get-Text "Worlds")
    for ($i=0; $i -lt $worldList.Count; $i++) {
        Write-Host "$($i+1). $($worldList[$i].Name)"
    }
    Write-Host ""
}
$inputWorld = Read-Host (Get-Text "EnterWorldName")
if ($inputWorld -match '^\d+$' -and $worldList.Count -gt 0) {
    $idx = [int]$inputWorld - 1
    if ($idx -ge 0 -and $idx -lt $worldList.Count) {
        $worldName = $worldList[$idx].Name
    } else {
        $worldName = $inputWorld
    }
} else {
    $worldName = $inputWorld
}
Write-Host (Get-Text "SelectedWorld" $worldName) -ForegroundColor Green
ShowFooter

$worldDir = Join-Path $worldsDir $worldName
if (-not (Test-Path $worldDir)) {
    New-Item -ItemType Directory -Path $worldDir -Force | Out-Null
}
$bpWorldJson = Join-Path $worldDir "world_behavior_packs.json"
$rpWorldJson = Join-Path $worldDir "world_resource_packs.json"

if (-not $skipBP) {
    Write-WorldJson $bpWorldJson $bpInfo.Uuid $bpInfo.Version $bpName
}
if (-not $skipRP) {
    Write-WorldJson $rpWorldJson $rpInfo.Uuid $rpInfo.Version $rpName
}

# Now safe to delete the .mcaddon since world registration succeeded
Remove-Item $mcaddon.FullName -Force -ErrorAction SilentlyContinue
Write-Host (Get-Text "DeletedOriginal" $mcaddon.Name)

Clear-Host
Write-Host (Get-Text "Complete") -ForegroundColor Green
Write-Host (Get-Text "Mod" $modBase)
if (-not $skipBP) { Write-Host (Get-Text "BPOnly" $bpName) } else { Write-Host (Get-Text "BPSkipped") }
if (-not $skipRP) { Write-Host (Get-Text "RPOnly" $rpName) } else { Write-Host (Get-Text "RP skipped") }
Write-Host (Get-Text "World" $worldName)
Write-Host ""
Write-Host (Get-Text "Success")
Write-Host (Get-Text "BPAndRPRegistered" $worldName)
Write-Host (Get-Text "NameStoredBP" $bpName)
Write-Host (Get-Text "NameStoredRP" $rpName)
ShowFooter

# List from jsons
Write-Host (Get-Text "CurrentlyInstalled" $worldName)
if (Test-Path $bpWorldJson) {
    $bpPacks = [System.IO.File]::ReadAllText($bpWorldJson, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    if ($bpPacks) {
        $bpPacks | ForEach-Object {
            $n = if ($_.name) { $_.name } else { "" }
            Write-Host "  BP: $($_.pack_id) v$($_.version -join '.') $n"
        }
    }
}
if (Test-Path $rpWorldJson) {
    $rpPacks = [System.IO.File]::ReadAllText($rpWorldJson, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    if ($rpPacks) {
        $rpPacks | ForEach-Object {
            $n = if ($_.name) { $_.name } else { "" }
            Write-Host "  RP: $($_.pack_id) v$($_.version -join '.') $n"
        }
    }
}

Write-Host ""
Write-Host (Get-Text "RestartServer") -ForegroundColor Yellow