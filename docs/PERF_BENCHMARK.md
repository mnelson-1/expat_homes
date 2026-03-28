# ExpatHomes Performance Benchmark

This benchmark measures **real runtime behavior** against your configured Firebase
project (no simulation).

## What it measures

### Firestore / Storage (legacy aggregate in `PERF_PROBE_RESULT`)

- `create_listing` (landlord upload path)
- `fetch_listings`
- `send_message`
- `create_assignment` / `accept_assignment`
- `verify_listing_update`

### Five UX workflows (same IDs for every run — for charts over time)

These are rolled into `PERF_WORKFLOW_HISTORY_JSON` (and `workflow_history` inside the Dart map before stripping):

| Workflow ID | What is timed |
|-------------|----------------|
| `landlord_listing_upload` | Full `createListing` (Storage + Firestore) |
| `message_translate` | ML Kit `translateIncoming` (on-device; not web) |
| `rides_estimate` | Google Directions request + local RWF fare estimate |
| `explore_places` | Places autocomplete (`cafe kigali`, Rwanda bias) |
| `listing_assignment` | Create assignment + accept (single combined ms per iteration) |

Also still measured: **message send → stream** latency (see `message_latency_ms` in `PERF_PROBE_RESULT`).

### Workflow success rate

- Full loop: publish listing → fetch by search text → assignment (if agent exists) → chat → translate → rides → explore.

## How to run

1. Ensure a real Flutter runtime device is available (Android emulator/physical device preferred).
2. Configure `env/google_maps.properties` so **Rides** and **Explore** steps can call Google APIs.
3. Sign in once in the normal app.
4. Run the probe entrypoint:

```bash
cd expat_app
flutter run -t lib/dev/perf_probe_main.dart
```

5. Console output:

```text
PERF_PROBE_RESULT={response_time_avg_ms: ..., response_time_max_ms: ..., workflow_success_rate: ..., message_latency_ms: ..., notes: ...}
PERF_WORKFLOW_HISTORY_JSON={"recorded_at":"...","schema":"workflow_perf/v1",...}
```

## Output contracts

### Legacy summary (`PERF_PROBE_RESULT`)

```json
{
  "response_time_avg_ms": 0,
  "response_time_max_ms": 0,
  "workflow_success_rate": 0,
  "message_latency_ms": 0,
  "notes": "..."
}
```

`response_time_*` uses Firestore-path samples only (not Maps-only steps).

### Time series (`PERF_WORKFLOW_HISTORY_JSON`)

`schema: workflow_perf/v1` — append each run as one line to `docs/perf/history/workflow_history.jsonl` and plot with `scripts/plot_workflow_timeseries.py`. See **`docs/perf/history/README.md`**.

## Notes

- The benchmark runs 5 iterations by default.
- Assignment workflow requires at least one registered agent in Firestore.
- If the signed-in user is not authorized to publish listings, verification step can fail, reducing success rate.
- **Historical charts:** Git does not store past probe timings; you build the timeline by appending each `PERF_WORKFLOW_HISTORY_JSON` line over the project.
