# Workflow performance history (time series)

This folder stores **one JSON object per line** (JSONL) produced by the Flutter perf probe. Each line uses `schema: workflow_perf/v1` and the same five workflow IDs everywhere so you can plot **grouped column charts** (one cluster per date, one column per workflow) for metrics like `avg_ms`, `max_ms`, and `p90_ms`.

## Why this exists

Git and CI logs in this repo do **not** contain historical millisecond timings for product workflows. To show improvement **over the project timeline**, you append a new line after each benchmark run on a real device/emulator.

## How to record a run

1. Run the probe (signed in, Maps key configured for Rides/Explore steps):

   ```bash
   cd expat_app
   flutter run -t lib/dev/perf_probe_main.dart
   ```

2. Copy the console line starting with `PERF_WORKFLOW_HISTORY_JSON=` (value only: valid JSON).

3. Append it as **one line** to `workflow_history.jsonl` (create the file if needed):

   ```powershell
   # From repo root — paste JSON between single quotes or use a file
   python scripts/append_workflow_history.py path/to/pasted.json
   ```

   Or append manually in an editor (must be a single line per run).

See also `docs/PERF_BENCHMARK.md`.

## Plot charts

From the repo root (requires `matplotlib`; same as `scripts/requirements-plot.txt`):

```bash
pip install -r scripts/requirements-plot.txt
python scripts/plot_workflow_timeseries.py
```

- Reads `workflow_history.jsonl` if it exists and is non-empty; otherwise uses `workflow_history.example.jsonl` (**synthetic** trend for layout checks only).
- Writes PNGs under `docs/perf/history/plots/` (`workflow_avg_ms_over_time.png`, `workflow_max_ms_over_time.png`, `workflow_p90_ms_over_time.png`).

## Files

| File | Purpose |
|------|---------|
| `workflow_history.jsonl` | Your real runs (optional; not committed if empty — add to git if you want the thesis dataset in-repo) |
| `workflow_history.example.jsonl` | Demo data — **not** real measurements; replace with your JSONL |
| `plots/*.png` | Generated figures (re-run the Python script after updating JSONL) |
