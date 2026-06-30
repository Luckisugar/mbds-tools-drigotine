# BDS-Uninstaller.ps1
# Tool to uninstall mods from a world.
# Removes entries from world_behavior_packs.json / world_resource_packs.json
# Optionally deletes the corresponding folders from behavior_packs / resource_packs.
# Matches the style, robustness and UX of the installer tools.
# Run from server root: pwsh .\TOOLS\BDS-Uninstaller.ps1

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir

if (-not (Test-Path (Join-Path $root "bedrock_server.exe"))) {
    Write-Host "Error: Could not find bedrock_server.exe in parent of TOOLS folder." -ForegroundColor Red
    Write-Host "Run the script from the server root like: pwsh .\TOOLS\BDS-Uninstaller.ps1"
    exit 1
}

$bpDir = Join-Path $root "behavior_packs"
$rpDir = Join-Path $root "resource_packs"
$worldsDir = Join-Path $root "worlds"

function ShowHeader($title) {
    Clear-Host
    Write-Host "=== Bedrock Uninstaller ===" -ForegroundColor Cyan
    Write-Host "Server: $root" -ForegroundColor Gray
    Write-Host ""
    Write-Host "=== $title ===" -ForegroundColor Cyan
    Write-Host ""
}

function ShowFooter {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Use numbers. Ctrl+C to exit." -ForegroundColor DarkGray
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

ShowHeader "Select World"

:worldLoop while ($true) {
    $worldList = @(Get-ChildItem $worldsDir -Directory | Select-Object -ExpandProperty Name)
    if ($worldList.Count -eq 0) {
        Write-Host "No worlds found."
        Write-Host "was the server.exe ran at least once???"
        Write-Host ""
        Write-Host "Options:"
        Write-Host "1. Refresh world list"
        Write-Host "2. Exit"
        $wOpt = Read-Host "Choose"
        if ($wOpt -eq "1") {
            continue :worldLoop
        } else {
            exit
        }
    }

    Write-Host "Worlds:"
    for ($i = 0; $i -lt $worldList.Count; $i++) {
        Write-Host "$($i+1). $($worldList[$i])"
    }

    do {
        $wChoice = Read-Host "Choose world number"
        $valid = $wChoice -match '^\d+$' -and [int]$wChoice -ge 1 -and [int]$wChoice -le $worldList.Count
        if (-not $valid) { Write-Host "Invalid choice." -ForegroundColor Red }
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
    Write-Host "No custom packs found registered for world '$worldName'."
    Write-Host "Nothing to uninstall."
    ShowFooter
    exit
}

ShowHeader "Installed Packs in $worldName"

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
    $choice = Read-Host "Choose pack to uninstall"
    $valid = $choice -match '^\d+$' -and [int]$choice -ge 0 -and [int]$choice -le $modList.Count
    if (-not $valid) { Write-Host "Invalid." -ForegroundColor Red }
} while (-not $valid)

if ($choice -eq "0") {
    Write-Host "Cancelled."
    exit
}

$chosenName = $modList[[int]$choice - 1]
$modInfo = $modMap[$chosenName]

Clear-Host
Write-Host "=== Uninstall Confirmation ===" -ForegroundColor Cyan
Write-Host "World: $worldName"
Write-Host "Pack:  $chosenName"
Write-Host ""
if ($modInfo.BP) { Write-Host "  Behavior Pack UUID:  $($modInfo.BP.Uuid)   v$($modInfo.BP.Version -join '.')" }
if ($modInfo.RP) { Write-Host "  Resource Pack UUID:  $($modInfo.RP.Uuid)   v$($modInfo.RP.Version -join '.')" }
Write-Host ""

# Resolve real folders using UUID (reliable)
$bpFolder = $null
$rpFolder = $null
if ($modInfo.BP) { $bpFolder = Get-FolderByUuid $bpDir $modInfo.BP.Uuid }
if ($modInfo.RP) { $rpFolder = Get-FolderByUuid $rpDir $modInfo.RP.Uuid }

if ($bpFolder -or $rpFolder) {
    Write-Host "Found on disk:"
    if ($bpFolder) { Write-Host "  behavior_packs/$([System.IO.Path]::GetFileName($bpFolder))" }
    if ($rpFolder) { Write-Host "  resource_packs/$([System.IO.Path]::GetFileName($rpFolder))" }

    Write-Host ""
    $delFolders = Read-Host "Delete the pack folder(s) from disk as well? (y/n)"
    $doDeleteFolders = ($delFolders -eq 'y' -or $delFolders -eq 'Y')
} else {
    Write-Host "No matching folders found on disk (already removed or different folder name)." -ForegroundColor Yellow
    $doDeleteFolders = $false
}

Write-Host ""
Write-Host "This will:"
Write-Host "  - Remove pack registration from the world's json files"
if ($doDeleteFolders) {
    Write-Host "  - DELETE the folders above" -ForegroundColor Red
} else {
    Write-Host "  - Leave the folders on disk (just unregister them)"
}
Write-Host ""

$confirm = Read-Host "Proceed? (y/n)"
if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Host "Cancelled."
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
        Write-Host "Deleted folder: $bpFolder" -ForegroundColor Yellow
    }
    if ($rpFolder -and (Test-Path $rpFolder)) {
        Remove-Item $rpFolder -Recurse -Force
        Write-Host "Deleted folder: $rpFolder" -ForegroundColor Yellow
    }
}

Clear-Host
Write-Host "=== Uninstall Complete ===" -ForegroundColor Green
Write-Host "World: $worldName"
Write-Host "Removed: $chosenName"
if ($doDeleteFolders) {
    Write-Host "Pack folders were deleted."
} else {
    Write-Host "Pack folders were left on disk."
}
Write-Host ""
Write-Host "Updated world files:"

if (Test-Path $bpJson) {
    Write-Host "`nworld_behavior_packs.json:"
    Get-Content $bpJson -Raw | Write-Host
}
if (Test-Path $rpJson) {
    Write-Host "`nworld_resource_packs.json:"
    Get-Content $rpJson -Raw | Write-Host
}

Write-Host ""
Write-Host "Restart the server to apply changes." -ForegroundColor Yellow
ShowFooter

Write-Host "Done."
