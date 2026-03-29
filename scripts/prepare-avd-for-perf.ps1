# Free AVD / device space before a perf probe (run once per role if you hit install/storage errors).
#
# Repo root is expat_homes (parent of expat_app). Run from repo root:
#   .\scripts\prepare-avd-for-perf.ps1
#   .\scripts\prepare-avd-for-perf.ps1 -Device emulator-5554
#   .\scripts\prepare-avd-for-perf.ps1 -ClearAppData   # also resets ExpatHomes app (fresh sign-in on next probe)
#
# Then run:
#   .\scripts\collect-workflow-perf.ps1 -Role expat

param(
    [string] $Device = "",
    [switch] $ClearAppData
)

$ErrorActionPreference = "Stop"
$androidPt = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools"
if (Test-Path $androidPt) {
    $env:Path = "$androidPt;$env:Path"
}

function Get-FlutterAndroidDeviceId {
    $raw = & flutter devices --machine 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "flutter devices --machine failed: $raw"
        return $null
    }
    try {
        $devices = $raw | ConvertFrom-Json
    } catch {
        return $null
    }
    if (-not $devices) { return $null }
    foreach ($d in @($devices)) {
        if ($null -eq $d) { continue }
        $id = [string]$d.id
        $name = [string]$d.name
        $tp = [string]$d.targetPlatform
        if ($tp -like '*android*' -or $name -like '*emulator*' -or $id -like 'emulator*') {
            return $id
        }
    }
    return $null
}

Write-Host ""
Write-Host "=== Prepare AVD / Android device for perf probe ===" -ForegroundColor Cyan

if (-not $Device) {
    $Device = Get-FlutterAndroidDeviceId
    if (-not $Device) {
        Write-Error "No Android device found. Start an emulator (or plug in a device), then run: flutter devices"
    }
    Write-Host "Using device: $Device" -ForegroundColor Green
} else {
    Write-Host "Using device: $Device" -ForegroundColor Green
}

$adbExe = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbExe)) {
    Write-Error "adb not found at $adbExe"
}

Write-Host "Trimming package caches (pm trim-caches)..." -ForegroundColor DarkGray
$prev = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& $adbExe -s $Device shell pm trim-caches 2147483647 2>&1 | Out-Null
$ErrorActionPreference = $prev

if ($ClearAppData) {
    $pkg = "com.example.expat_app"
    Write-Host "Clearing app data: $pkg (next probe will auto sign-in again if credentials are set)..." -ForegroundColor Yellow
    & $adbExe -s $Device shell pm clear $pkg
}

Write-Host ""
Write-Host "Done. When ready, run from repo root (expat_homes):" -ForegroundColor Green
Write-Host "  .\scripts\collect-workflow-perf.ps1 -Role landlord   # or agent | expat" -ForegroundColor White
Write-Host ""
