# Workflow performance history (time series)

This folder stores **one JSON object per line** (JSONL) produced by the Flutter perf probe. Each line uses `schema: workflow_perf/v1` and the same five workflow IDs everywhere so you can plot **grouped column charts** (one cluster per date, one column per workflow) for metrics like `avg_ms`, `max_ms`, and `p90_ms`.

## Real data only (default)

- **`workflow_history.jsonl`** — append one line per successful probe run. This file starts empty until you capture a run.
- **`docs/PERF_RESULTS_*.json`** — older format with **no per-workflow breakdown**; it cannot be converted honestly into the five workflow series. Re-run the current probe to populate JSONL.

Synthetic numbers live only under **`examples/SYNTHETIC_layout_demo_only.jsonl`** for layout tests — **do not** cite them as results.

## Capture a run (recommended)

From the **repository root** (PowerShell), with an **Android emulator or device** running (default target):

```powershell
.\scripts\collect-workflow-perf.ps1
```

The script will:

1. Pick the first Android device from `flutter devices --machine` (or pass `-Device emulator-5554` explicitly).
2. Ask **permission** before reading `expat_app/env/google_maps.properties` — it only reports whether `GOOGLE_MAPS_API_KEY` looks set (the key is **never** printed).
3. Prompt for **Firebase email** and **password** (hidden), unless `PERF_PROBE_EMAIL` / `PERF_PROBE_PASSWORD` are already set in the environment.
4. Asks for a **benchmark role tag** (`landlord`, `agent`, or `expat`) stored in each JSON line under `environment.benchmark_role` so you can run **three separate captures** (one test user per role) and filter or plot by role later. The current probe **logic** is still **landlord-centric** (creates listings, assigns agents); agent/expat accounts may hit permission failures for some steps unless we add role-specific probes later.

5. Run the probe with `--dart-define-from-file` (safe for special characters in passwords), then append `PERF_WORKFLOW_HISTORY_JSON` to `workflow_history.jsonl`.
6. If the append succeeds, **generate PNG charts** under `docs/perf/history/plots/` (`plot_workflow_timeseries.py` for all roles present in the JSONL; for `-Role expat`, also `plot_expat_iteration_linechart.py`). Use **`-SkipPlots`** on the collect script to skip this step.

### Storing credentials per role (recommended for repeat runs)

**One file for everything (best if you want an assistant to drive runs):**

| Path | Purpose |
|------|---------|
| `scripts/perf-probe-credentials.local.ps1` | **Put all role credentials here.** Gitignored. `collect-workflow-perf.ps1` loads it automatically. You do **not** need to paste passwords in chat—after saving, ask your assistant to run the script for `-Role landlord` / `agent` / `expat`. |

1. Copy `scripts/perf-probe-credentials.example.ps1` → `scripts/perf-probe-credentials.local.ps1`.
2. Fill in Firebase **test** accounts only (never production passwords):

| Variable | Used when |
|----------|-----------|
| `PERF_PROBE_LANDLORD_EMAIL` / `PERF_PROBE_LANDLORD_PASSWORD` | `-Role landlord` (default if generic env is set) |
| `PERF_PROBE_AGENT_EMAIL` / `PERF_PROBE_AGENT_PASSWORD` | `-Role agent` |
| `PERF_PROBE_EXPAT_EMAIL` / `PERF_PROBE_EXPAT_PASSWORD` | `-Role expat` |
| `PERF_PROBE_EMAIL` / `PERF_PROBE_PASSWORD` | Fallback if the role-specific pair is empty |

`collect-workflow-perf.ps1` **dot-sources** `perf-probe-credentials.local.ps1` automatically when that file exists.

Examples:

```powershell
.\scripts\collect-workflow-perf.ps1 -Role landlord
.\scripts\collect-workflow-perf.ps1 -Role agent
.\scripts\collect-workflow-perf.ps1 -Role expat
```

If only agent/expat env vars are set, you **must** pass `-Role agent` or `-Role expat` (otherwise the script assumes `landlord`).

### Non-interactive sign-in without a `.local` file

```powershell
$env:PERF_PROBE_EMAIL = 'your-benchmark-user@example.com'
$env:PERF_PROBE_PASSWORD = '...'
.\scripts\collect-workflow-perf.ps1 -Role landlord
```

Requires email/password enabled for each test user in Firebase Auth.

Or manually:

```bash
cd expat_app
flutter run -t lib/dev/perf_probe_main.dart
```

Requirements: Firebase sign-in, `env/google_maps.properties` for Rides/Explore steps, and (for assignment) a registered agent when the signed-in user is a landlord.

Save the full console output, then:

```powershell
python scripts/append_workflow_history.py --from-console path\to\console.txt --dedupe
```

Or paste the JSON object (single line) into a file and:

```powershell
python scripts/append_workflow_history.py pasted.json
```

## Plot charts

`collect-workflow-perf.ps1` runs plotting automatically after a successful JSONL append (installs `scripts/requirements-plot.txt` via pip if needed). To regenerate charts without re-running the probe:

```bash
pip install -r scripts/requirements-plot.txt
python scripts/plot_workflow_timeseries.py
python scripts/plot_expat_iteration_linechart.py
```

Fails with instructions if `workflow_history.jsonl` is empty (no silent fallback to fake data).

**Dev-only** (chart layout, not real data):

```bash
python scripts/plot_workflow_timeseries.py --allow-synthetic-layout-demo
```

## Files

| File | Purpose |
|------|---------|
| `workflow_history.jsonl` | **Your real runs** (commit if you want the dataset in-repo) |
| `last_probe_console.txt` | Last full console from `collect-workflow-perf.ps1` (optional; may contain noise) |
| `examples/SYNTHETIC_layout_demo_only.jsonl` | Layout demo only |
| `plots/*.png` | Generated from real JSONL via `plot_workflow_timeseries.py` |

See also `docs/PERF_BENCHMARK.md`.
