# BDS-Mcpack-Installer.ps1
# Ferramenta para instalar arquivos .mcpack (único ou BP/RP separados)
# Fluxo similar à ferramenta .mcaddon com todas as melhorias anteriores
# Execute a partir da raiz do servidor: pwsh .\TOOLS\BDS-Mcpack-Installer.ps1

param(
    [ValidateSet("en","pt")]
    [string]$Lang = "en"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir

if (-not (Test-Path (Join-Path $root "bedrock_server.exe"))) {
    if ($Lang -eq "pt") {
        Write-Host "Erro: Não foi possível encontrar o bedrock_server.exe. Execute a partir da raiz do servidor." -ForegroundColor Red
    } else {
        Write-Host "Error: Could not find bedrock_server.exe. Run from server root." -ForegroundColor Red
    }
    exit 1
}

function Get-Text {
    param([string]$Key, [object[]]$Args = @())
    if ($Lang -eq "pt") {
        $base = switch ($Key) {
            "HeaderTitle" { "=== Instalador Mcpack Bedrock ===" }
            "Server" { "Servidor: {0}" }
            "Mod" { "Mod: {0}" }
            "BP" { "BP: {0}" }
            "RP" { "RP: {0}" }
            "Footer" { "Use números. Ctrl+C para sair a qualquer momento." }
            "NoMcpack" { "Nenhum .mcpack encontrado em {0}" }
            "SelectMcpack" { "=== Selecionar arquivos .mcpack ===" }
            "AvailableMcpack" { "Arquivos .mcpack disponíveis:" }
            "HowProvided" { "Como este mod é fornecido?" }
            "Single" { "1. Único .mcpack que é o mod (BP ou RP ou ambos dentro)" }
            "Two" { "2. Dois .mcpack separados (um BP, um RP)" }
            "Choose1or2" { "Escolha 1 ou 2" }
            "ChooseMcpackNumber" { "Escolha o número do .mcpack" }
            "Invalid" { "Inválido." }
            "UnpackedTo" { "Descompactado para {0}" }
            "ContainsMultiple" { "`nEste .mcpack contém múltiplos packs dentro:" }
            "ChooseForBP" { "Escolha número para Behavior Pack (0 para nenhum)" }
            "ChooseForRP" { "Escolha número para Resource Pack (0 para nenhum)" }
            "SinglePackDetected" { "`nPack único detectado neste .mcpack." }
            "IsBPOrRP" { "É Behavior Pack ou Resource Pack?" }
            "ChooseBP" { "1. Behavior Pack (BP)" }
            "ChooseRP" { "2. Resource Pack (RP)" }
            "ChooseMcpackForBP" { "`nEscolha .mcpack para Behavior Pack:" }
            "NumberForBP" { "Número para BP .mcpack (0 para nenhum)" }
            "ChooseSubForBP" { "Escolha sub para BP" }
            "NameForBP" { "Nome para este BP na pasta oficial" }
            "ChooseMcpackForRP" { "`nEscolha .mcpack para Resource Pack:" }
            "NumberForRP" { "Número para RP .mcpack (0 para nenhum)" }
            "ChooseSubForRP" { "Escolha sub para RP" }
            "NameForRP" { "Nome para este RP na pasta oficial" }
            "InstallSummary" { "=== Resumo da Instalação ===" }
            "ModProcessed" { "Mod processado." }
            "CurrentCustom" { "Packs oficiais atuais (apenas custom):" }
            "BehaviorPacks" { "Behavior packs:" }
            "ResourcePacks" { "Resource packs:" }
            "DeletedMcpack" { " .mcpack deletado: {0}" }
            "SelectWorld" { "=== Selecionar Mundo ===" }
            "NoWorlds" { "Nenhum mundo encontrado" }
            "ServerRanOnce" { "o server.exe foi executado pelo menos uma vez???" }
            "Refresh" { "1. Atualizar lista de mundos" }
            "Discard" { "2. Descartar alterações e sair (remove packs instalados, mantém .mcpack)" }
            "ChooseOption" { "Escolha a opção" }
            "Worlds" { "Mundos:" }
            "ChooseWorldNumber" { "Escolha o número do mundo" }
            "SelectedWorld" { "Mundo selecionado: {0}" }
            "Complete" { "=== Completo ===" }
            "Success" { "=== Sucesso ===" }
            "PacksRegistered" { "Packs registrados para o mundo '{0}'." }
            "NameStoredBP" { "Nome do BP armazenado: {0}" }
            "NameStoredRP" { "Nome do RP armazenado: {0}" }
            "CurrentlyInstalled" { "`nAtualmente instalado no mundo '{0}' (dos jsons):" }
            "RestartServer" { "Reinicie o servidor para testar." }
            default { $Key }
        }
    } else {
        $base = switch ($Key) {
            "HeaderTitle" { "=== Bedrock Mcpack Installer ===" }
            "Server" { "Server: {0}" }
            "Mod" { "Mod: {0}" }
            "BP" { "BP: {0}" }
            "RP" { "RP: {0}" }
            "Footer" { "Use numbers. Ctrl+C to exit anytime." }
            "NoMcpack" { "No .mcpack found in {0}" }
            "SelectMcpack" { "=== Select .mcpack file(s) ===" }
            "AvailableMcpack" { "Available .mcpack files:" }
            "HowProvided" { "How is this mod provided?" }
            "Single" { "1. Single .mcpack that is the mod (BP or RP or both inside)" }
            "Two" { "2. Two separate .mcpack files (one BP, one RP)" }
            "Choose1or2" { "Choose 1 or 2" }
            "ChooseMcpackNumber" { "Choose the .mcpack number" }
            "Invalid" { "Invalid." }
            "UnpackedTo" { "Unpacked to {0}" }
            "ContainsMultiple" { "`nThis .mcpack contains multiple packs inside:" }
            "ChooseForBP" { "Choose number for Behavior Pack (0 for none)" }
            "ChooseForRP" { "Choose number for Resource Pack (0 for none)" }
            "SinglePackDetected" { "`nSingle pack detected in this .mcpack." }
            "IsBPOrRP" { "Is this a Behavior Pack or Resource Pack?" }
            "ChooseBP" { "1. Behavior Pack (BP)" }
            "ChooseRP" { "2. Resource Pack (RP)" }
            "ChooseMcpackForBP" { "`nChoose .mcpack for Behavior Pack:" }
            "NumberForBP" { "Number for BP .mcpack (0 for none)" }
            "ChooseSubForBP" { "Choose sub for BP" }
            "NameForBP" { "Name for this BP in official folder" }
            "ChooseMcpackForRP" { "`nChoose .mcpack for Resource Pack:" }
            "NumberForRP" { "Number for RP .mcpack (0 for none)" }
            "ChooseSubForRP" { "Choose sub for RP" }
            "NameForRP" { "Name for this RP in official folder" }
            "InstallSummary" { "=== Installation Summary ===" }
            "ModProcessed" { "Mod processed." }
            "CurrentCustom" { "Current official (custom only):" }
            "BehaviorPacks" { "Behavior packs:" }
            "ResourcePacks" { "Resource packs:" }
            "DeletedMcpack" { "Deleted .mcpack: {0}" }
            "SelectWorld" { "=== Select World ===" }
            "NoWorlds" { "No worlds found" }
            "ServerRanOnce" { "was the server.exe ran atleast once???" }
            "Refresh" { "1. Refresh world list" }
            "Discard" { "2. Discard changes and leave (removes installed packs, keeps .mcpack)" }
            "ChooseOption" { "Choose option" }
            "Worlds" { "Worlds:" }
            "ChooseWorldNumber" { "Choose world number" }
            "SelectedWorld" { "Selected world: {0}" }
            "Complete" { "=== Complete ===" }
            "Success" { "=== Success ===" }
            "PacksRegistered" { "Packs registered for world '{0}'." }
            "NameStoredBP" { "BP name stored: {0}" }
            "NameStoredRP" { "RP name stored: {0}" }
            "CurrentlyInstalled" { "`nCurrently installed in world '{0}' (from jsons):" }
            "RestartServer" { "Restart the server to test." }
            default { $Key }
        }
    }
    if ($Args.Count -gt 0) {
        return ($base -f $Args)
    }
    return $base
}

$unpackedDir = Join-Path $root "UNPACKED MODS"
$bpDir = Join-Path $root "behavior_packs"
$rpDir = Join-Path $root "resource_packs"
$worldsDir = Join-Path $root "worlds"
$mcpackSourceDir = Join-Path $root "UNPACKED MODS"

@($unpackedDir, $bpDir, $rpDir, $worldsDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

function ShowHeader($title) {
    Clear-Host
    Write-Host (Get-Text "HeaderTitle") -ForegroundColor Cyan
    Write-Host (Get-Text "Server" $root) -ForegroundColor Gray
    if ($modBase) { Write-Host (Get-Text "Mod" $modBase) -ForegroundColor Yellow }
    if ($bpName) { Write-Host (Get-Text "BP" $bpName) -ForegroundColor Yellow }
    if ($rpName) { Write-Host (Get-Text "RP" $rpName) -ForegroundColor Yellow }
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
        Uuid = $data.header.uuid
        Version = $data.header.version
        Type = if ($data.modules[0].type -eq "data") { "behavior" } else { "resource" }
    }
}

function Write-WorldJson($path, $packId, $version, $modName) {
    $packs = @()
    if (Test-Path $path) {
        # Strip comment lines for backward compatibility with old files that had // comments
        $lines = Get-Content $path | Where-Object { $_.Trim() -notmatch '^//' -and $_.Trim() -ne '' }
        $jsonText = $lines -join "`n"
        try {
            $raw = if ($jsonText.Trim()) { $jsonText | ConvertFrom-Json } else { @() }
            if ($null -eq $raw) {
                $packs = @()
            } elseif ($raw -is [array]) {
                $packs = $raw
            } else {
                $packs = @($raw)
            }
        } catch {
            Write-Host "Warning: Could not parse existing $(Split-Path $path -Leaf), starting fresh." -ForegroundColor Yellow
            $packs = @()
        }
    }
    # Remove any existing entry with same pack_id (to update)
    $packs = @($packs | Where-Object { $_ -and $_.pack_id -ne $packId })
    # Add new entry, including human-readable name
    $packs += [pscustomobject]@{
        pack_id = $packId
        version = $version
        name    = $modName
    }
    # Write clean, valid JSON (no comments in file)
    $packs | ConvertTo-Json -Depth 5 | Set-Content $path -Encoding UTF8
}

function Copy-PackWithCheck($sourceFolder, $destDir, $name, $packType) {
    $dest = Join-Path $destDir $name
    $skipped = $false
    if (Test-Path $dest) {
        Write-Host "Folder '$name' already exists in $packType packs." -ForegroundColor Yellow
        $ow = Read-Host "Overwrite? (y/n)"
        if ($ow -eq 'y' -or $ow -eq 'Y') {
            Remove-Item $dest -Recurse -Force
            Write-Host "Overwriting..." -ForegroundColor Yellow
        } else {
            Write-Host "Skipping $packType copy." -ForegroundColor Yellow
            $skipped = $true
        }
    }
    if (-not $skipped) {
        New-Item -Path $dest -ItemType Directory -Force | Out-Null
        Copy-Item -Path (Join-Path $sourceFolder '*') -Destination $dest -Recurse -Force
        Write-Host "Successfully installed $packType as '$name' in $($packType.ToLower())_packs" -ForegroundColor Green
    }
    return @{
        Dest = $dest
        Skipped = $skipped
        Name = $name
    }
}

# === New flexible .mcpack handling ===
ShowHeader (Get-Text "SelectMcpack")
$mcpacks = Get-ChildItem -Path $mcpackSourceDir -Filter "*.mcpack" -ErrorAction SilentlyContinue
if ($mcpacks.Count -eq 0) {
    Write-Host (Get-Text "NoMcpack" $mcpackSourceDir)
    exit
}

Write-Host (Get-Text "AvailableMcpack")
for ($i=0; $i -lt $mcpacks.Count; $i++) {
    Write-Host "$($i+1). $($mcpacks[$i].Name)"
}

# Ask for setup type
Write-Host ""
Write-Host (Get-Text "HowProvided")
Write-Host (Get-Text "Single")
Write-Host (Get-Text "Two")
$setupType = Read-Host (Get-Text "Choose1or2")

$bpName = $null
$rpName = $null
$bpFolderPath = $null
$rpFolderPath = $null
$usedMcpackFiles = @()
$bpDest = $null
$rpDest = $null

if ($setupType -eq "1") {
    # Single file
    do {
        $choice = Read-Host "Choose the .mcpack number"
        $valid = $choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $mcpacks.Count
        if (-not $valid) { Write-Host "Invalid." -ForegroundColor Red }
    } while (-not $valid)
    $chosenMcpack = $mcpacks[[int]$choice - 1]
    $usedMcpackFiles += $chosenMcpack

    $extractPath = Join-Path $unpackedDir ($chosenMcpack.BaseName + "_extract")
    if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
    $tempZip = Join-Path $env:TEMP ($chosenMcpack.BaseName + ".zip")
    Copy-Item $chosenMcpack.FullName $tempZip -Force
    Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force
    Remove-Item $tempZip
    Write-Host "Unpacked to $extractPath" -ForegroundColor Green

    # Find pack roots
    $packRoots = Get-ChildItem $extractPath -Directory | Where-Object { Test-Path (Join-Path $_.FullName "manifest.json") }
    if ($packRoots.Count -eq 0) {
        if (Test-Path (Join-Path $extractPath "manifest.json")) {
            $packRoots = @( [pscustomobject]@{FullName = $extractPath; Name = (Split-Path $extractPath -Leaf)} )
        } else {
            Write-Host "No valid manifest found."
            exit
        }
    }

    if ($packRoots.Count -gt 1) {
        # Contains both
        Write-Host "`nThis .mcpack contains multiple packs inside:"
        for ($i=0; $i -lt $packRoots.Count; $i++) {
            Write-Host "$($i+1). $($packRoots[$i].Name)"
        }
        do {
            $bSub = Read-Host "Choose number for Behavior Pack (0 for none)"
            $valid = $bSub -match '^\d+$' -and [int]$bSub -ge 0 -and [int]$bSub -le $packRoots.Count
            if (-not $valid) { Write-Host "Invalid." -ForegroundColor Red }
        } while (-not $valid)
        if ($bSub -ne "0") {
            $bpFolderPath = $packRoots[[int]$bSub-1].FullName
            $bpName = Read-Host "Name for this BP in official folder"
        }

        do {
            $rSub = Read-Host "Choose number for Resource Pack (0 for none)"
            $valid = $rSub -match '^\d+$' -and [int]$rSub -ge 0 -and [int]$rSub -le $packRoots.Count
            if (-not $valid) { Write-Host "Invalid." -ForegroundColor Red }
        } while (-not $valid)
        if ($rSub -ne "0") {
            $rpFolderPath = $packRoots[[int]$rSub-1].FullName
            $rpName = Read-Host "Name for this RP in official folder"
        }
    } else {
        # Single pack
        $singleRoot = $packRoots[0].FullName
        Write-Host "`nSingle pack detected in this .mcpack."
        Write-Host "Is this a Behavior Pack or Resource Pack?"
        Write-Host "1. Behavior Pack (BP)"
        Write-Host "2. Resource Pack (RP)"
        $typeChoice = Read-Host "Choose 1 or 2"
        if ($typeChoice -eq "1") {
            $bpFolderPath = $singleRoot
            $bpName = Read-Host "Name for this BP in official folder"
        } elseif ($typeChoice -eq "2") {
            $rpFolderPath = $singleRoot
            $rpName = Read-Host "Name for this RP in official folder"
        } else {
            Write-Host "Invalid."
            exit
        }
    }
} else {
    # Two separate files
    # BP
    Write-Host "`nChoose .mcpack for Behavior Pack:"
    for ($i=0; $i -lt $mcpacks.Count; $i++) {
        Write-Host "$($i+1). $($mcpacks[$i].Name)"
    }
    do {
        $bC = Read-Host "Number for BP .mcpack (0 for none)"
        $valid = $bC -match '^\d+$' -and [int]$bC -ge 0 -and [int]$bC -le $mcpacks.Count
        if (-not $valid) { Write-Host "Invalid." -ForegroundColor Red }
    } while (-not $valid)
    if ($bC -ne "0") {
        $bpMc = $mcpacks[[int]$bC - 1]
        $usedMcpackFiles += $bpMc
        $safeBase = ($bpMc.BaseName -replace '[\[\](){}\s+]', '_')
        $bExtract = Join-Path $unpackedDir ($safeBase + "_extract")
        if (Test-Path $bExtract) { Remove-Item $bExtract -Recurse -Force }
        $t = Join-Path $env:TEMP ($safeBase + ".zip")
        Copy-Item $bpMc.FullName $t -Force
        Expand-Archive $t $bExtract -Force
        Remove-Item $t
        $bRoots = Get-ChildItem $bExtract -Directory | Where-Object { Test-Path (Join-Path $_.FullName "manifest.json") }
        if ($bRoots.Count -gt 1) {
            for ($i=0; $i -lt $bRoots.Count; $i++) { Write-Host "$($i+1). $($bRoots[$i].Name)" }
            $sb = Read-Host (Get-Text "ChooseSubForBP")
            $bpFolderPath = $bRoots[[int]$sb-1].FullName
        } else {
            $bpFolderPath = if ($bRoots.Count -eq 1) { $bRoots[0].FullName } else { $bExtract }
        }
        $bpInfo = Get-PackInfo $bpFolderPath
        $bpName = Read-Host (Get-Text "NameForBP")
    }

    # RP
    Write-Host "`nChoose .mcpack for Resource Pack:"
    for ($i=0; $i -lt $mcpacks.Count; $i++) {
        Write-Host "$($i+1). $($mcpacks[$i].Name)"
    }
    do {
        $rC = Read-Host "Number for RP .mcpack (0 for none)"
        $valid = $rC -match '^\d+$' -and [int]$rC -ge 0 -and [int]$rC -le $mcpacks.Count
        if (-not $valid) { Write-Host "Invalid." -ForegroundColor Red }
    } while (-not $valid)
    if ($rC -ne "0") {
        $rpMc = $mcpacks[[int]$rC - 1]
        $usedMcpackFiles += $rpMc
        $rExtract = Join-Path $unpackedDir ($rpMc.BaseName + "_extract")
        if (Test-Path $rExtract) { Remove-Item $rExtract -Recurse -Force }
        $t = Join-Path $env:TEMP ($rpMc.BaseName + ".zip")
        Copy-Item $rpMc.FullName $t -Force
        Expand-Archive $t $rExtract -Force
        Remove-Item $t
        $rRoots = Get-ChildItem $rExtract -Directory | Where-Object { Test-Path (Join-Path $_.FullName "manifest.json") }
        if ($rRoots.Count -gt 1) {
            for ($i=0; $i -lt $rRoots.Count; $i++) { Write-Host "$($i+1). $($rRoots[$i].Name)" }
            $sr = Read-Host "Choose sub for RP"
            $rpFolderPath = $rRoots[[int]$sr-1].FullName
        } else {
            $rpFolderPath = if ($rRoots.Count -eq 1) { $rRoots[0].FullName } else { $rExtract }
        }
        $rpInfo = Get-PackInfo $rpFolderPath
        $rpName = Read-Host "Name for this RP in official folder"
    }
}

ShowFooter

# Copy with checks
$skipBP = $true
$skipRP = $true
if ($bpFolderPath -and $bpName) {
    $bpDestInfo = Copy-PackWithCheck $bpFolderPath $bpDir $bpName "Behavior"
    $skipBP = $bpDestInfo.Skipped
    $bpDest = $bpDestInfo.Dest
}
if ($rpFolderPath -and $rpName) {
    $rpDestInfo = Copy-PackWithCheck $rpFolderPath $rpDir $rpName "Resource"
    $skipRP = $rpDestInfo.Skipped
    $rpDest = $rpDestInfo.Dest
}

ShowFooter

# === Summary and Cleanup ===
Clear-Host
Write-Host "=== Installation Summary ===" -ForegroundColor Cyan
Write-Host "Mod processed."
if (-not $skipBP) { Write-Host "BP: $bpName (in behavior_packs)" }
if (-not $skipRP) { Write-Host "RP: $rpName (in resource_packs)" }
Write-Host ""
Write-Host "Current official (custom only):"
$excluded = 'vanilla*', 'chemistry*', 'editor*', 'server_*', 'experimental_*'
Write-Host "Behavior packs:"
Get-ChildItem $bpDir -Directory | Where-Object { 
    $n = $_.Name
    ($excluded | Where-Object { $n -like $_ }).Count -eq 0
} | ForEach-Object { "  $($_.Name)" }

Write-Host "Resource packs:"
Get-ChildItem $rpDir -Directory | Where-Object { 
    $n = $_.Name
    ($excluded | Where-Object { $n -like $_ }).Count -eq 0
} | ForEach-Object { "  $($_.Name)" }

# Delete the processed .mcpack files
foreach ($f in ($usedMcpackFiles | Select-Object -Unique)) {
    Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted .mcpack: $($f.Name)"
}

ShowFooter

# === World Selection with improvements ===
Clear-Host
Write-Host "=== Select World ===" -ForegroundColor Cyan
Write-Host "Mod processed."
if (-not $skipBP) { Write-Host "BP: $bpName" }
if (-not $skipRP) { Write-Host "RP: $rpName" }
Write-Host ""

:worldLoop while ($true) {
    $worldList = Get-ChildItem $worldsDir -Directory
    if ($worldList.Count -eq 0) {
        Write-Host "No worlds found"
        Write-Host "was the server.exe ran atleast once???"
        Write-Host ""
        Write-Host "Options:"
        Write-Host "1. Refresh world list"
        Write-Host "2. Discard changes and leave (removes installed packs, keeps .mcpack)"
        $wOpt = Read-Host "Choose option"
        if ($wOpt -eq "1") {
            Clear-Host
            Write-Host "=== Select World ===" -ForegroundColor Cyan
            Write-Host "Mod processed."
            if (-not $skipBP) { Write-Host "BP: $bpName" }
            if (-not $skipRP) { Write-Host "RP: $rpName" }
            Write-Host ""
            continue :worldLoop
        } elseif ($wOpt -eq "2") {
            if (-not $skipBP -and (Test-Path $bpDest)) { Remove-Item $bpDest -Recurse -Force }
            if (-not $skipRP -and (Test-Path $rpDest)) { Remove-Item $rpDest -Recurse -Force }
            Write-Host "Changes discarded. .mcpack(s) remain for retry."
            exit
        } else {
            continue :worldLoop
        }
    }
    Write-Host "Worlds:"
    for ($i=0; $i -lt $worldList.Count; $i++) {
        Write-Host "$($i+1). $($worldList[$i].Name)"
    }
    do {
        $wChoice = Read-Host "Choose world number"
        $valid = $wChoice -match '^\d+$' -and [int]$wChoice -ge 1 -and [int]$wChoice -le $worldList.Count
        if (-not $valid) { Write-Host "Invalid choice, try again." -ForegroundColor Red }
    } while (-not $valid)
    $worldName = $worldList[[int]$wChoice - 1].Name
    Write-Host "Selected world: $worldName" -ForegroundColor Green
    break :worldLoop
}

ShowFooter

# Get UUIDs and register
if (-not $skipBP) {
    $bpInfo = Get-PackInfo $bpDest
    $bpWorldJson = Join-Path $worldsDir $worldName "world_behavior_packs.json"
    Write-WorldJson $bpWorldJson $bpInfo.Uuid $bpInfo.Version $bpName
}
if (-not $skipRP) {
    $rpInfo = Get-PackInfo $rpDest
    $rpWorldJson = Join-Path $worldsDir $worldName "world_resource_packs.json"
    Write-WorldJson $rpWorldJson $rpInfo.Uuid $rpInfo.Version $rpName
}

Clear-Host
Write-Host "=== Complete ===" -ForegroundColor Green
Write-Host "Mod processed."
if (-not $skipBP) { Write-Host "BP: $bpName" } else { Write-Host "BP: Skipped" }
if (-not $skipRP) { Write-Host "RP: $rpName" } else { Write-Host "RP: Skipped" }
Write-Host "World: $worldName"
Write-Host ""
Write-Host "=== Success ==="
Write-Host "Packs registered for world '$worldName'."
if (-not $skipBP) { Write-Host "BP name stored: $bpName" }
if (-not $skipRP) { Write-Host "RP name stored: $rpName" }

Write-Host "`nCurrently installed in world '$worldName' (from jsons):"
if (-not $skipBP -and (Test-Path $bpWorldJson)) {
    $bpPacks = Get-Content $bpWorldJson -Raw | ConvertFrom-Json
    if ($bpPacks) {
        $bpPacks | ForEach-Object {
            $n = if ($_.name) { $_.name } else { "" }
            Write-Host "  BP: $($_.pack_id) v$($_.version -join '.') $n"
        }
    }
}
if (-not $skipRP -and (Test-Path $rpWorldJson)) {
    $rpPacks = Get-Content $rpWorldJson -Raw | ConvertFrom-Json
    if ($rpPacks) {
        $rpPacks | ForEach-Object {
            $n = if ($_.name) { $_.name } else { "" }
            Write-Host "  RP: $($_.pack_id) v$($_.version -join '.') $n"
        }
    }
}

Write-Host ""
Write-Host "Restart the server to test." -ForegroundColor Yellow
ShowFooter