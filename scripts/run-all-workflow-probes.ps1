# Run landlord, agent, and expat perf probes back-to-back (non-interactive maps),
# then plot workflow charts. Requires perf-probe-credentials.local.ps1 and Android device.
#
# Usage (repo root):  .\scripts\run-all-workflow-probes.ps1
# Optional device:    .\scripts\run-all-workflow-probes.ps1 -Device emulator-5554

param([string] $Device = "")

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
$script = Join-Path $PSScriptRoot "collect-workflow-perf.ps1"

foreach ($r in @("landlord", "agent", "expat")) {
    Write-Host ""
    Write-Host "========== WORKFLOW PROBE: $r ==========" -ForegroundColor Cyan
    if ($Device) {
        & $script -Role $r -SkipMapsPrompt -Device $Device
    } else {
        & $script -Role $r -SkipMapsPrompt
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "collect-workflow-perf.ps1 reported failure for role $r (check log under docs/perf/history/)."
    }
}

Push-Location $root
try {
    Write-Host ""
    Write-Host "========== PLOTTING ==========" -ForegroundColor Cyan
    pip install -q -r scripts/requirements-plot.txt
    python scripts/plot_workflow_timeseries.py
} finally {
    Pop-Location
}
