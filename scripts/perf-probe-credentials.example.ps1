# === WHERE TO PUT REAL CREDENTIALS (single place) ===
#
# 1. Copy THIS file to exactly:
#      scripts/perf-probe-credentials.local.ps1
#    (same folder as this example — repo root is expat_homes/)
#
# 2. Fill in the $env:... lines below with your Firebase *test* accounts.
#
# 3. That .local.ps1 file is GITIGNORED — it will not be committed.
#
# 4. For Cursor / an assistant: after you save .local.ps1, say e.g.
#      "Credentials are in perf-probe-credentials.local.ps1 — run landlord probe"
#    The script loads that file itself; you do not need to paste passwords in chat.
#
# collect-workflow-perf.ps1 dot-sources perf-probe-credentials.local.ps1 when it exists.
#
# Per-role variables (preferred when running -Role landlord | agent | expat):
#   PERF_PROBE_LANDLORD_EMAIL / PERF_PROBE_LANDLORD_PASSWORD
#   PERF_PROBE_AGENT_EMAIL    / PERF_PROBE_AGENT_PASSWORD
#   PERF_PROBE_EXPAT_EMAIL    / PERF_PROBE_EXPAT_PASSWORD
#
# Fallback for any role if the role-specific pair is empty:
#   PERF_PROBE_EMAIL / PERF_PROBE_PASSWORD

$env:PERF_PROBE_LANDLORD_EMAIL = ''
$env:PERF_PROBE_LANDLORD_PASSWORD = ''
$env:PERF_PROBE_AGENT_EMAIL = ''
$env:PERF_PROBE_AGENT_PASSWORD = ''
$env:PERF_PROBE_EXPAT_EMAIL = ''
$env:PERF_PROBE_EXPAT_PASSWORD = ''

# Optional single-account fallback (e.g. only landlord tests)
$env:PERF_PROBE_EMAIL = ''
$env:PERF_PROBE_PASSWORD = ''
