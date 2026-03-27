# Performance Run Interpretation (2026-03-27)

## What was actually executed

- Launched Android emulator (`emulator-5554`, API 35).
- Ran Flutter probe entrypoint:
  - `flutter run -d emulator-5554 -t lib/dev/perf_probe_main.dart`
- Captured runtime probe logs from app output.

## Actual observed runtime result

- `PERF_PROBE_USER=4hVP9zdIEeYsg9w5epEO3ThiUa53`
- `PERF_PROBE_RESULT={response_time_avg_ms: 766, response_time_max_ms: 2288, workflow_success_rate: 0, message_latency_ms: 0, notes: ...}`

## Interpretation

The benchmark harness executed on a real Android emulator runtime and measured Firestore operation response times.

As a result:
- Response time samples were collected (aggregated response_time_avg_ms=766ms, response_time_max_ms=2288ms).
- Workflow success rate is 0 due to the probe’s retrieval success criteria failing (it uses `searchQuery` with `listing.id`, but the filter matches title/location/description text fields).
- message_latency_ms is 0 because the probe did not record a send→stream-observed latency value in this run.

## Practical implication

This run validates the instrumentation pipeline and produced real response-time measurements in the emulator.

Why workflow_success_rate=0 and message_latency_ms=0:
- workflow_success_rate is controlled by the probe’s internal success criteria (not Firestore moderation outcomes). In the probe, the “verification → retrieval” check calls a published listings fetch with `searchQuery` set to the `listing.id`; that text search filters by title/location/description, so the `found` check fails.
- message_latency_ms=0 indicates the probe did not record a send→stream-observed latency value for this run (no `[PERF][message_latency]` log was emitted during the benchmark).

