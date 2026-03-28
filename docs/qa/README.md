# QA test metrics (for charts)

This folder holds **generated** machine-readable summaries of the Flutter test run so you can plot results (pass/fail by suite, duration, line coverage) in Excel, Google Sheets, Python, or thesis figures.

## Generate files

From the **repository root** (Windows PowerShell):

```powershell
.\scripts\collect-test-metrics.ps1
```

Or manually from `expat_app/`:

```bash
flutter test --coverage --file-reporter=json:build/test_events.json
dart run tool/aggregate_test_metrics.dart
```

## Outputs (gitignored)

After generation, see `docs/qa/generated/`:

| File | Use |
|------|-----|
| `test_metrics.json` | **Charts:** `summary`, `executiveSummary`, `evidenceScope`, `viewerBrief`, `suites[]`, optional `runtimeBenchmark`, `coverage` |
| `test_metrics.csv` | Quick pivot tables; rows tagged `TOTAL`, `SUITE`, `COVERAGE` |
| `system_overview_for_charts.csv` | **Single “overall quality” sheet:** one row per KPI with `chart_group` and `recommended_chart` so you can filter to comparable scales (e.g. only `percent_0_100`) |
| `system_overview_charts.png` / `.svg` | **Pre-built figure** (after you run `python scripts/plot_system_overview.py`) |

### JSON shape (high level)

- `generatedAt` — UTC ISO-8601 timestamp  
- `flutterTestSuccess` — whether the runner finished without failures  
- `summary` — `total`, `passed`, `failed`, `skipped`, `wallClockMs`  
- `executiveSummary` — pass rate %, executed/skipped counts, suite stats, coverage %, wall-clock seconds, runner success  
- `evidenceScope` — short lists of what these metrics do and do **not** prove (for thesis or stakeholder slides)  
- `viewerBrief` — copy-ready bullet strings for captions  
- `suites` — one entry per test library with `path`, counts, `durationMs`  
- `coverage` — optional; requires `--coverage` and `coverage/lcov.info`  
- `runtimeBenchmark` — optional; present when aggregation merged a `docs/PERF_RESULTS_*.json` file  

**Note:** Coverage is a **project-wide line sum** from `lcov.info`, useful for trend charts, not a substitute for line-by-file review.

### Building “overall performance” charts (honest + persuasive)

1. **Import** `system_overview_for_charts.csv` into Sheets or Excel.  
2. **Filter** `chart_group` = `percent_0_100` for one chart where the Y axis is comparable (pass rate, line coverage, workflow success % from the probe).  
3. Add a **second chart** for `milliseconds` or `seconds` groups so you do not mix milliseconds with percentages on one axis.  
4. **Manual QA:** fill `docs/qa/templates/manual_qa_completion_template.csv` (Pass=1 / Fail=0) and plot completion % — that is what convinces reviewers that UX and integrations were exercised, not only CI tests.  
5. Cite `evidenceScope` and probe `notes` from `runtimeBenchmark` so limitations (e.g. benchmark criteria) are visible next to the figure.

`.\scripts\collect-test-metrics.ps1` automatically merges the **newest** `docs/PERF_RESULTS*.json` if present. To pin a file or skip merging, run `dart run tool/aggregate_test_metrics.dart` manually with or without `--perf-json`.

### Static plots (PNG + SVG)

From the **repository root** (after `system_overview_for_charts.csv` exists):

```bash
pip install -r scripts/requirements-plot.txt
python scripts/plot_system_overview.py
```

Writes `docs/qa/generated/system_overview_charts.png` and `system_overview_charts.svg` (four panels: % metrics, counts, probe ms, seconds + gate).

## Custom paths

```bash
dart run tool/aggregate_test_metrics.dart --events build/test_events.json --lcov coverage/lcov.info --out ../docs/qa/generated --perf-json ../docs/PERF_RESULTS_2026-03-27.json
```
