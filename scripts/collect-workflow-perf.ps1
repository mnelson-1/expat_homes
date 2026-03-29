# Run the perf probe on Android (default) and append workflow JSONL + optional plots.
#
# Usage (repo root):  .\scripts\collect-workflow-perf.ps1
# Optional:           .\scripts\collect-workflow-perf.ps1 -Device emulator-5554 -Role landlord
# Optional:           .\scripts\collect-workflow-perf.ps1 -PrepareAvd [-ClearAppData]
#   Runs prepare-avd-for-perf.ps1 first (trim caches; -ClearAppData resets the app package).
# After a successful JSONL append, runs plot scripts (matplotlib). Use -SkipPlots to disable.
#
# Credentials (in order of preference for the selected -Role):
#   PERF_PROBE_<ROLE>_EMAIL / PERF_PROBE_<ROLE>_PASSWORD   (e.g. PERF_PROBE_AGENT_EMAIL)
#   PERF_PROBE_EMAIL / PERF_PROBE_PASSWORD                  (fallback for any role)
# Optional: copy scripts/perf-probe-credentials.example.ps1 -> perf-probe-credentials.local.ps1
#   (gitignored); it is dot-sourced automatically when present.
#
# - Asks permission before reading google_maps.properties unless -SkipMapsPrompt (for automation).
# - Picks the first connected Android device/emulator if -Device is omitted.
# - Tags each JSONL row with benchmark_role (landlord | agent | expat) via PERF_PROBE_BENCHMARK_ROLE.
# - Uses --dart-define-from-file for credentials (handles special characters in passwords).

param(
    [string] $Device = "",
    [string] $Role = "",
    [switch] $SkipMapsPrompt,
    [switch] $PrepareAvd,
    [switch] $ClearAppData,
    [switch] $SkipPlots
)

$ErrorActionPreference = "Stop"
# Ensure adb is on PATH (fixes intermittent "ADB exited with exit code 1" when only Flutter sees the SDK).
$androidPt = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools"
if (Test-Path $androidPt) {
    $env:Path = "$androidPt;$env:Path"
}
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root "expat_app"
$definesFile = $null

if (-not (Test-Path $app)) {
    Write-Error "expat_app not found at $app"
}

$localCred = Join-Path $PSScriptRoot "perf-probe-credentials.local.ps1"
if (Test-Path $localCred) {
    Write-Host "Loading perf-probe-credentials.local.ps1 (gitignored)" -ForegroundColor DarkGray
    . $localCred
}

function Get-PerfProbeCredentialsForRole {
    param([Parameter(Mandatory)][string] $BenchmarkRole)

    $e = $null
    $p = $null
    switch ($BenchmarkRole) {
        "landlord" {
            $e = $env:PERF_PROBE_LANDLORD_EMAIL
            $p = $env:PERF_PROBE_LANDLORD_PASSWORD
        }
        "agent" {
            $e = $env:PERF_PROBE_AGENT_EMAIL
            $p = $env:PERF_PROBE_AGENT_PASSWORD
        }
        "expat" {
            $e = $env:PERF_PROBE_EXPAT_EMAIL
            $p = $env:PERF_PROBE_EXPAT_PASSWORD
        }
        Default {
            throw "Unknown role: $BenchmarkRole"
        }
    }
    if ([string]::IsNullOrWhiteSpace($e)) { $e = $env:PERF_PROBE_EMAIL }
    if ([string]::IsNullOrWhiteSpace($p)) { $p = $env:PERF_PROBE_PASSWORD }
    return @{ Email = $e; Password = $p }
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

function Test-MapsKeyFilePresent {
    param([string] $MapsPath)
    if (-not (Test-Path $MapsPath)) { return $false }
    $lines = Get-Content -Path $MapsPath -ErrorAction SilentlyContinue
    foreach ($line in $lines) {
        $t = $line.Trim()
        if ($t.StartsWith("#") -or $t.Length -eq 0) { continue }
        if ($t -match '^\s*GOOGLE_MAPS_API_KEY\s*=\s*(.+)\s*$') {
            $v = $matches[1].Trim()
            if ($v.Length -gt 0) { return $true }
        }
    }
    return $false
}

Write-Host ""
Write-Host "=== ExpatHomes workflow perf capture ===" -ForegroundColor Cyan

if (-not $Device) {
    $Device = Get-FlutterAndroidDeviceId
    if (-not $Device) {
        Write-Error "No Android device/emulator found. Start an emulator (or connect a device), then run: flutter devices"
    }
    Write-Host "Using Android device: $Device" -ForegroundColor Green
} else {
    Write-Host "Using device: $Device" -ForegroundColor Green
}

if ($PrepareAvd) {
    $prep = Join-Path $PSScriptRoot "prepare-avd-for-perf.ps1"
    Write-Host ""
    Write-Host "Running prepare-avd-for-perf.ps1 (-PrepareAvd)..." -ForegroundColor Cyan
    if ($ClearAppData) {
        & $prep -Device $Device -ClearAppData
    } else {
        & $prep -Device $Device
    }
}
elseif ($ClearAppData) {
    Write-Warning "-ClearAppData is ignored without -PrepareAvd. Run: .\scripts\prepare-avd-for-perf.ps1 -ClearAppData"
}

$hasGenericCreds = $env:PERF_PROBE_EMAIL -and $env:PERF_PROBE_PASSWORD
$hasLandlordCreds = $env:PERF_PROBE_LANDLORD_EMAIL -and $env:PERF_PROBE_LANDLORD_PASSWORD

if ($Role) {
    $Role = $Role.Trim().ToLowerInvariant()
    if ($Role -notin @("landlord", "agent", "expat")) {
        Write-Warning "Invalid -Role '$Role'; using landlord."
        $Role = "landlord"
    }
} elseif ($hasGenericCreds -or $hasLandlordCreds) {
    $Role = "landlord"
    Write-Host ""
    Write-Host "Env credentials present without -Role: using benchmark_role=landlord (pass -Role agent or -Role expat for other accounts)." -ForegroundColor DarkGray
} else {
    $Role = Read-Host 'Benchmark role tag for JSONL (landlord | agent | expat) [landlord]'
    if ([string]::IsNullOrWhiteSpace($Role)) {
        $Role = "landlord"
    }
    $Role = $Role.Trim().ToLowerInvariant()
    if ($Role -notin @("landlord", "agent", "expat")) {
        Write-Warning "Unknown role '$Role'; using landlord."
        $Role = "landlord"
    }
}
Write-Host "benchmark_role for this run: $Role" -ForegroundColor Cyan

$log = Join-Path $root ("docs\perf\history\last_probe_console_{0}.txt" -f $Role)

Write-Host ""
$mapsPath = Join-Path $root "expat_app\env\google_maps.properties"
if ($SkipMapsPrompt) {
    Write-Host "Skipping maps file prompt (-SkipMapsPrompt)." -ForegroundColor DarkGray
} else {
    $promptMaps = 'May I read ''{0}'' only to report whether GOOGLE_MAPS_API_KEY looks set? (nothing is displayed) [y/N]' -f $mapsPath
    $perm = Read-Host $promptMaps
    if ($perm -eq "y" -or $perm -eq "Y") {
        if (Test-MapsKeyFilePresent -MapsPath $mapsPath) {
            Write-Host "google_maps.properties: GOOGLE_MAPS_API_KEY appears SET." -ForegroundColor Green
        } else {
            Write-Host "google_maps.properties: key missing or empty (Rides/Explore probe steps may fail)." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Skipped maps file check (your choice)." -ForegroundColor DarkGray
    }
}

$cred = Get-PerfProbeCredentialsForRole -BenchmarkRole $Role
$email = $cred.Email
$plainPassword = $cred.Password
$useAuto = $false

if ($email -and $plainPassword) {
    Write-Host ""
    $ru = $Role.ToUpperInvariant()
    Write-Host "Using credentials from environment (PERF_PROBE_${ru}_EMAIL or PERF_PROBE_EMAIL)." -ForegroundColor DarkGray
    $useAuto = $true
} else {
    Write-Host ""
    Write-Host "No env credentials for role '$Role'. Set PERF_PROBE_$($Role.ToUpper())_EMAIL/PASSWORD or PERF_PROBE_EMAIL/PASSWORD, or use perf-probe-credentials.local.ps1" -ForegroundColor Yellow
    Write-Host "Firebase benchmark sign-in (dedicated test account)." -ForegroundColor Cyan
    $email = Read-Host "Email"
    $sec = Read-Host -AsSecureString "Password"
    if ([string]::IsNullOrWhiteSpace($email)) {
        Write-Host "No email: running without auto sign-in - sign in manually in the app when it opens." -ForegroundColor Yellow
    } elseif ($sec.Length -eq 0) {
        Write-Host "Empty password: running without auto sign-in." -ForegroundColor Yellow
    } else {
        $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec)
        try {
            $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
        } finally {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        }
        $useAuto = $true
    }
}

$flutterArgs = [System.Collections.ArrayList]@()
[void]$flutterArgs.Add("run")
[void]$flutterArgs.Add("-d")
[void]$flutterArgs.Add($Device)
[void]$flutterArgs.Add("-t")
[void]$flutterArgs.Add("lib/dev/perf_probe_main.dart")
[void]$flutterArgs.Add("--dart-define=PERF_PROBE_BENCHMARK_ROLE=$Role")

if ($useAuto) {
    $defines = [ordered]@{
        PERF_PROBE_EMAIL          = $email
        PERF_PROBE_PASSWORD       = $plainPassword
        PERF_PROBE_EXIT_WHEN_DONE = "true"
    }
    $json = $defines | ConvertTo-Json -Compress
    $definesFile = Join-Path $env:TEMP ("perf_dart_defines_{0}.json" -f [guid]::NewGuid().ToString("N"))
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($definesFile, $json, $utf8NoBom)
    [void]$flutterArgs.Add("--dart-define-from-file=$definesFile")
    Write-Host ""
    Write-Host "Auto sign-in + exit when done (credentials file deleted after run)." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Manual sign-in: complete Get Started in the app; stop with q in this terminal when finished." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Logging to: $log"
Write-Host "Command: flutter $($flutterArgs -join ' ')"
Write-Host ""

$adbExe = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if ((Test-Path $adbExe) -and $Device) {
    Write-Host "Trimming emulator caches (free space for install)..." -ForegroundColor DarkGray
    & $adbExe -s $Device shell pm trim-caches 2147483647 2>$null
}

Push-Location $app
try {
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & flutter @flutterArgs 2>&1 | Tee-Object -FilePath $log
    } finally {
        $ErrorActionPreference = $prevEap
    }
} finally {
    Pop-Location
    if ($definesFile -and (Test-Path $definesFile)) {
        Remove-Item -LiteralPath $definesFile -Force -ErrorAction SilentlyContinue
    }
    $plainPassword = $null
}

Write-Host ""
Write-Host "Importing PERF_WORKFLOW_HISTORY_JSON lines (if any)..."
$appendOk = $false
Push-Location $root
try {
    python scripts/append_workflow_history.py --from-console $log --dedupe
    if ($LASTEXITCODE -eq 0) {
        $appendOk = $true
    } else {
        Write-Warning "Append failed or no PERF_WORKFLOW_HISTORY_JSON in log. Check $log manually."
    }
} finally {
    Pop-Location
}

if (-not $SkipPlots) {
    Push-Location $root
    try {
        Write-Host ""
        Write-Host "Installing plot dependencies (if needed)..." -ForegroundColor DarkGray
        python -m pip install -q -r scripts/requirements-plot.txt
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "pip install for scripts/requirements-plot.txt failed; charts may not generate."
        }

        if ($appendOk) {
            Write-Host "Generating charts under docs/perf/history/plots/ ..." -ForegroundColor Cyan
            python scripts/plot_workflow_timeseries.py
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "plot_workflow_timeseries.py exited with code $LASTEXITCODE (empty JSONL or missing role rows?)."
            }
            if ($Role -eq "expat") {
                python scripts/plot_expat_iteration_linechart.py
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "plot_expat_iteration_linechart.py failed (needs expat row with iterations in workflow_history.jsonl)."
                }
                python scripts/plot_expat_performance_charts.py
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "plot_expat_performance_charts.py exited with code $LASTEXITCODE."
                }
            }
            if ($Role -eq "landlord") {
                python scripts/plot_landlord_performance_charts.py
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "plot_landlord_performance_charts.py exited with code $LASTEXITCODE."
                }
            }
            if ($Role -eq "agent") {
                python scripts/plot_agent_performance_charts.py
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "plot_agent_performance_charts.py exited with code $LASTEXITCODE."
                }
            }
            $plotsDir = Join-Path $root "docs\perf\history\plots"
            $testPlotsDir = Join-Path $root "test_results\plots"
            if (Test-Path $plotsDir) {
                Write-Host "Chart files (open in Explorer or your IDE):" -ForegroundColor Green
                Get-ChildItem -Path $plotsDir -Filter "*.png" -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    ForEach-Object { Write-Host "  $($_.FullName)" }
            }
            if (Test-Path $testPlotsDir) {
                Write-Host "test_results/plots:" -ForegroundColor Green
                Get-ChildItem -Path $testPlotsDir -Filter "*.png" -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    ForEach-Object { Write-Host "  $($_.FullName)" }
            }
        } else {
            Write-Host ""
            Write-Warning "Skipping chart generation (JSONL append did not succeed)."
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host ""
    Write-Host "Skipped chart generation (-SkipPlots)." -ForegroundColor DarkGray
}
