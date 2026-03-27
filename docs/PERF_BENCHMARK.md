# ExpatHomes Performance Benchmark

This benchmark measures **real runtime behavior** against your configured Firebase
project (no simulation).

## What it measures

- Firestore/Storage response timings for:
  - `create_listing`
  - `fetch_listings`
  - `send_message`
  - `create_assignment`
  - `accept_assignment`
  - `verify_listing_update`
- Workflow success rate for:
  - listing creation -> verification update -> retrieval
  - agent assignment -> acceptance
- Message latency:
  - send call to stream-observed message (`messagesStream`)

## How to run

1. Ensure a real Flutter runtime device is available (Android emulator/physical device preferred).
2. Sign in once in the normal app.
3. Run the probe entrypoint:

```bash
flutter run -t lib/dev/perf_probe_main.dart
```

4. Look for console output:

```text
PERF_PROBE_RESULT={response_time_avg_ms: ..., response_time_max_ms: ..., workflow_success_rate: ..., message_latency_ms: ..., notes: ...}
```

## Output contract

```json
{
  "response_time_avg_ms": 0,
  "response_time_max_ms": 0,
  "workflow_success_rate": 0,
  "message_latency_ms": 0,
  "notes": "..."
}
```

## Notes

- The benchmark runs 5 iterations by default.
- Assignment workflow requires at least one registered agent in Firestore.
- If the signed-in user is not authorized to publish listings, verification step can fail, reducing success rate.
