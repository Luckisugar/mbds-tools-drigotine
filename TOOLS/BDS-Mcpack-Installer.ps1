# BDS-Mcpack-Installer.ps1
# Tool for installing .mcpack files (single or separate BP/RP)
# Similar workflow to the .mcaddon tool with all previous improvements
# Run from server root: pwsh .\TOOLS\BDS-Mcpack-Installer.ps1

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir

if (-not (Test-Path (Join-Path $root "bedrock_server.exe"))) {
    Write-Host "Error: Could not find bedrock_server.exe. Run from server root." -ForegroundColor Red
    exit 1
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
    Write-Host "=== Bedrock Mcpack Installer ===" -ForegroundColor Cyan
    Write-Host "Server: $root" -ForegroundColor Gray
    if ($modBase) { Write-Host "Mod: $modBase" -ForegroundColor Yellow }
    if ($bpName) { Write-Host "BP: $bpName" -ForegroundColor Yellow }
    if ($rpName) { Write-Host "RP: $rpName" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "=== $title ===" -ForegroundColor Cyan
    Write-Host ""
}

function ShowFooter {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Use numbers. Ctrl+C to exit anytime." -ForegroundColor DarkGray
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
ShowHeader "Select .mcpack file(s)"
$mcpacks = Get-ChildItem -Path $mcpackSourceDir -Filter "*.mcpack" -ErrorAction SilentlyContinue
if ($mcpacks.Count -eq 0) {
    Write-Host "No .mcpack found in $mcpackSourceDir"
    exit
}

Write-Host "Available .mcpack files:"
for ($i=0; $i -lt $mcpacks.Count; $i++) {
    Write-Host "$($i+1). $($mcpacks[$i].Name)"
}

# Ask for setup type
Write-Host ""
Write-Host "How is this mod provided?"
Write-Host "1. Single .mcpack that is the mod (BP or RP or both inside)"
Write-Host "2. Two separate .mcpack files (one BP, one RP)"
$setupType = Read-Host "Choose 1 or 2"

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
        $bExtract = Join-Path $unpackedDir ($bpMc.BaseName + "_extract")
        if (Test-Path $bExtract) { Remove-Item $bExtract -Recurse -Force }
        $t = Join-Path $env:TEMP ($bpMc.BaseName + ".zip")
        Copy-Item $bpMc.FullName $t -Force
        Expand-Archive $t $bExtract -Force
        Remove-Item $t
        $bRoots = Get-ChildItem $bExtract -Directory | Where-Object { Test-Path (Join-Path $_.FullName "manifest.json") }
        if ($bRoots.Count -gt 1) {
            for ($i=0; $i -lt $bRoots.Count; $i++) { Write-Host "$($i+1). $($bRoots[$i].Name)" }
            $sb = Read-Host "Choose sub for BP"
            $bpFolderPath = $bRoots[[int]$sb-1].FullName
        } else {
            $bpFolderPath = if ($bRoots.Count -eq 1) { $bRoots[0].FullName } else { $bExtract }
        }
        $bpInfo = Get-PackInfo $bpFolderPath
        $bpName = Read-Host "Name for this BP in official folder"
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