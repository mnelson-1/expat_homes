# Collect Flutter test JSON + lcov and write chart-friendly metrics under docs/qa/generated/
# Run from repository root:  .\scripts\collect-test-metrics.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root "expat_app"

if (-not (Test-Path $app)) {
    Write-Error "expat_app not found at $app"
}

Push-Location $app
try {
    if (-not (Test-Path "build")) { New-Item -ItemType Directory -Path "build" | Out-Null }
    flutter test --coverage --file-reporter=json:build/test_events.json
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Tests failed; metrics still generated for analysis."
    }
    $perfFiles = Get-ChildItem -Path (Join-Path $root "docs") -Filter "PERF_RESULTS*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    $latestPerf = $perfFiles | Select-Object -First 1
    if ($latestPerf) {
        Write-Host "Merging latest perf snapshot: $($latestPerf.Name)"
        dart run tool/aggregate_test_metrics.dart --perf-json $latestPerf.FullName
    } else {
        dart run tool/aggregate_test_metrics.dart
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Error "aggregate_test_metrics.dart failed"
    }
} finally {
    Pop-Location
}

Write-Host "Done. See docs/qa/generated/test_metrics.json, test_metrics.csv, system_overview_for_charts.csv"
