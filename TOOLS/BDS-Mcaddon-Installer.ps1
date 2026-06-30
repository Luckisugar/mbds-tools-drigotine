# BDS-Addon-Installer.ps1
# Tool to unpack .mcaddon, select bp/rp folders, copy to official with name, register uuids with comments in world json.
# IMPORTANT: Run from the SERVER ROOT (not inside TOOLS):
#   cd "C:\path\to\your\server"
#   pwsh .\TOOLS\BDS-Addon-Installer.ps1

$ErrorActionPreference = "Stop"

# Determine server root from script location (in TOOLS), not current dir
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir

if (-not (Test-Path (Join-Path $root "bedrock_server.exe"))) {
    Write-Host "Error: Could not find bedrock_server.exe in parent of TOOLS folder."
    Write-Host "Run the script from the server root like: pwsh .\TOOLS\BDS-Addon-Installer.ps1"
    exit 1
}

$unpackedDir = Join-Path $root "UNPACKED MODS"
$bpDir = Join-Path $root "behavior_packs"
$rpDir = Join-Path $root "resource_packs"
$worldsDir = Join-Path $root "worlds"
$originalDir = Join-Path $root "UNPACKED MODS"

# Ensure folders
@($unpackedDir, $bpDir, $rpDir, $worldsDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

Clear-Host
Write-Host "=== Bedrock Addon Installer ===" -ForegroundColor Cyan
Write-Host "Server: $root"
Write-Host "Source: $originalDir"
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

function ShowFooter {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Use arrows or numbers. Ctrl+C to exit." -ForegroundColor DarkGray
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
    $man = Get-ChildItem $packPath -Recurse -Filter "manifest.json" | Select-Object -First 1
    if (-not $man) { throw "No manifest in $packPath" }
    $data = Get-Content $man.FullName -Raw | ConvertFrom-Json
    @{
        Uuid = $data.header.uuid
        Version = $data.header.version
    }
}

# List .mcaddon
$mcaddons = Get-ChildItem -Path $originalDir -Filter "*.mcaddon" -ErrorAction SilentlyContinue
if ($mcaddons.Count -eq 0) {
    Write-Host "No .mcaddon found in $originalDir"
    exit
}

Clear-Host
Write-Host "=== Select .mcaddon ===" -ForegroundColor Cyan
Write-Host "Looking in: $originalDir"
Write-Host ""
Write-Host "Available .mcaddons:"
for ($i=0; $i -lt $mcaddons.Count; $i++) {
    Write-Host "$($i+1). $($mcaddons[$i].Name)"
}
do {
    $choice = Read-Host "Choose number"
    $valid = $choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $mcaddons.Count
    if (-not $valid) { Write-Host "Invalid choice, enter a number between 1 and $($mcaddons.Count)" -ForegroundColor Red }
} while (-not $valid)
$mcaddon = $mcaddons[[int]$choice - 1]
$modBase = $mcaddon.BaseName
Write-Host "Selected: $modBase" -ForegroundColor Green
ShowFooter

# Unpack
Clear-Host
Write-Host "=== Unpacking ===" -ForegroundColor Cyan
Write-Host "Mod: $modBase"
Write-Host ""
$unpackPath = Join-Path $unpackedDir $modBase
if (Test-Path $unpackPath) { Remove-Item $unpackPath -Recurse -Force }
$tempZip = Join-Path $env:TEMP "$modBase.zip"
Copy-Item $mcaddon.FullName $tempZip -Force
Expand-Archive -Path $tempZip -DestinationPath $unpackPath -Force
Remove-Item $tempZip
Write-Host "Unpacked to $unpackPath" -ForegroundColor Green
ShowFooter

$skipBP = $false
$skipRP = $false

# Get subfolders
$subs = Get-ChildItem $unpackPath -Directory
if ($subs.Count -eq 0) {
    Write-Host "No subfolders after unpack. Check $unpackPath"
    exit
}

Clear-Host
Write-Host "=== Select Behavior Pack ===" -ForegroundColor Cyan
Write-Host "Mod: $modBase"
Write-Host "Unpacked: $unpackPath"
Write-Host ""
Write-Host "Subfolders in unpacked:"
for ($i=0; $i -lt $subs.Count; $i++) {
    Write-Host "$($i+1). $($subs[$i].Name)"
}

Write-Host ""
do {
    $bpChoice = Read-Host "Number for BP folder"
    $valid = $bpChoice -match '^\d+$' -and [int]$bpChoice -ge 1 -and [int]$bpChoice -le $subs.Count
    if (-not $valid) { Write-Host "Invalid choice, try again." -ForegroundColor Red }
} while (-not $valid)
$bpFolder = $subs[[int]$bpChoice - 1]
do {
    $bpName = Read-Host "Name for this BP in official folder"
    if ($bpName -match '[\\/:*?"<>|]' -or [string]::IsNullOrWhiteSpace($bpName)) {
        Write-Host "Invalid name (no special chars or empty). Try again." -ForegroundColor Red
    }
} while ($bpName -match '[\\/:*?"<>|]' -or [string]::IsNullOrWhiteSpace($bpName))
$bpDest = Join-Path $bpDir $bpName

# Get info from source
$bpInfo = Get-PackInfo $bpFolder.FullName

# Check for existing
$skipBP = $false
if (Test-Path $bpDest) {
    Write-Host "Folder '$bpName' already exists in behavior_packs." -ForegroundColor Yellow
    $ow = Read-Host "Overwrite? (y/n)"
    if ($ow -eq 'y' -or $ow -eq 'Y') {
        Remove-Item $bpDest -Recurse -Force
        Write-Host "Overwriting..." -ForegroundColor Yellow
    } else {
        Write-Host "Skipping BP copy." -ForegroundColor Yellow
        $skipBP = $true
    }
}
if (-not $skipBP) {
    Copy-Item $bpFolder.FullName $bpDest -Recurse -Force
    Write-Host "Successfully installed BP as '$bpName' in behavior_packs" -ForegroundColor Green
}
ShowFooter

# RP - re-list subfolders and reuse the same name
Clear-Host
Write-Host "=== Select Resource Pack ===" -ForegroundColor Cyan
Write-Host "Mod: $modBase"
if (-not $skipBP) {
    Write-Host "BP: $bpName (from $($bpFolder.Name))"
} else {
    Write-Host "BP: Skipped"
}
Write-Host ""
Write-Host "Subfolders in unpacked:"
for ($i=0; $i -lt $subs.Count; $i++) {
    Write-Host "$($i+1). $($subs[$i].Name)"
}

Write-Host ""
do {
    $rpChoice = Read-Host "Number for RP folder"
    $valid = $rpChoice -match '^\d+$' -and [int]$rpChoice -ge 1 -and [int]$rpChoice -le $subs.Count
    if (-not $valid) { Write-Host "Invalid choice, try again." -ForegroundColor Red }
} while (-not $valid)
$rpFolder = $subs[[int]$rpChoice - 1]
$rpName = $bpName
$rpDest = Join-Path $rpDir $rpName

$rpInfo = Get-PackInfo $rpFolder.FullName

# Check for existing RP
$skipRP = $false
if (Test-Path $rpDest) {
    Write-Host "Folder '$rpName' already exists in resource_packs." -ForegroundColor Yellow
    $ow = Read-Host "Overwrite? (y/n)"
    if ($ow -eq 'y' -or $ow -eq 'Y') {
        Remove-Item $rpDest -Recurse -Force
        Write-Host "Overwriting..." -ForegroundColor Yellow
    } else {
        Write-Host "Skipping RP copy." -ForegroundColor Yellow
        $skipRP = $true
    }
}
if (-not $skipRP) {
    Copy-Item $rpFolder.FullName $rpDest -Recurse -Force
    Write-Host "Successfully installed RP as '$rpName' in resource_packs" -ForegroundColor Green
} else {
    Write-Host "RP skipped."
}
ShowFooter

# List new and current
Clear-Host
Write-Host "=== Installation Summary ===" -ForegroundColor Cyan
Write-Host "Mod: $modBase"
if (-not $skipBP) { Write-Host "BP: $bpName" } else { Write-Host "BP: Skipped" }
if (-not $skipRP) { Write-Host "RP: $rpName" } else { Write-Host "RP: Skipped" }
Write-Host ""
Write-Host "Current official (custom only):"
Write-Host "Behavior packs:"
$excluded = 'vanilla*', 'chemistry*', 'editor*', 'server_*', 'experimental_*'
Get-ChildItem $bpDir -Directory | Where-Object { 
    $n = $_.Name
    ($excluded | Where-Object { $n -like $_ }).Count -eq 0
} | ForEach-Object { "  $($_.Name)" }

Write-Host "Resource packs:"
Get-ChildItem $rpDir -Directory | Where-Object { 
    $n = $_.Name
    ($excluded | Where-Object { $n -like $_ }).Count -eq 0
} | ForEach-Object { "  $($_.Name)" }
ShowFooter
ShowFooter

Clear-Host
Write-Host "=== Select World ===" -ForegroundColor Cyan
Write-Host "Mod: $modBase"
if (-not $skipBP) { Write-Host "BP: $bpName" } else { Write-Host "BP: Skipped" }
if (-not $skipRP) { Write-Host "RP: $rpName" } else { Write-Host "RP: Skipped" }
Write-Host ""
:worldLoop while ($true) {
    $worldList = Get-ChildItem $worldsDir -Directory
    if ($worldList.Count -eq 0) {
        Write-Host "No worlds found"
        Write-Host "was the server.exe ran atleast once???"
        Write-Host ""
        Write-Host "Options:"
        Write-Host "1. Refresh world list"
        Write-Host "2. Discard changes and leave (removes installed packs, keeps .mcaddon)"
        $wOpt = Read-Host "Choose option"
        if ($wOpt -eq "1") {
            Clear-Host
            Write-Host "=== Select World ===" -ForegroundColor Cyan
            Write-Host "Mod: $modBase"
            if (-not $skipBP) { Write-Host "BP: $bpName" } else { Write-Host "BP: Skipped" }
            if (-not $skipRP) { Write-Host "RP: $rpName" } else { Write-Host "RP: Skipped" }
            Write-Host ""
            continue :worldLoop
        } elseif ($wOpt -eq "2") {
            if (-not $skipBP -and (Test-Path $bpDest)) { Remove-Item $bpDest -Recurse -Force }
            if (-not $skipRP -and (Test-Path $rpDest)) { Remove-Item $rpDest -Recurse -Force }
            Write-Host "Changes discarded. .mcaddon remains for retry."
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
    ShowFooter
    break :worldLoop
}

# Write to world jsons
$bpWorldJson = Join-Path $worldsDir $worldName "world_behavior_packs.json"
$rpWorldJson = Join-Path $worldsDir $worldName "world_resource_packs.json"

if (-not $skipBP) {
    Write-WorldJson $bpWorldJson $bpInfo.Uuid $bpInfo.Version $bpName
}
if (-not $skipRP) {
    Write-WorldJson $rpWorldJson $rpInfo.Uuid $rpInfo.Version $rpName
}

# Now safe to delete the .mcaddon since world registration succeeded
Remove-Item $mcaddon.FullName -Force -ErrorAction SilentlyContinue
Write-Host "Deleted original .mcaddon: $($mcaddon.Name)"

Clear-Host
Write-Host "=== Complete ===" -ForegroundColor Green
Write-Host "Mod: $modBase"
if (-not $skipBP) { Write-Host "BP: $bpName" } else { Write-Host "BP: Skipped" }
if (-not $skipRP) { Write-Host "RP: $rpName" } else { Write-Host "RP: Skipped" }
Write-Host "World: $worldName"
Write-Host ""
Write-Host "=== Success ==="
Write-Host "BP and RP registered for world '$worldName'."
Write-Host "Name stored for BP: $bpName"
Write-Host "Name stored for RP: $rpName"
ShowFooter

# List from jsons
Write-Host "`nCurrently installed in world '$worldName' (from jsons):"
if (Test-Path $bpWorldJson) {
    $bpPacks = Get-Content $bpWorldJson -Raw | ConvertFrom-Json
    if ($bpPacks) {
        $bpPacks | ForEach-Object {
            $n = if ($_.name) { $_.name } else { "" }
            Write-Host "  BP: $($_.pack_id) v$($_.version -join '.') $n"
        }
    }
}
if (Test-Path $rpWorldJson) {
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