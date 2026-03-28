// Aggregates `flutter test --file-reporter=json:...` output + optional lcov
// into JSON/CSV for charts (Excel, Sheets, thesis figures).
// Optional `--perf-json` merges a `docs/PERF_RESULTS_*.json` snapshot into the
// same overview file for a single “quality + runtime” dashboard export.
//
// Usage (from expat_app/):
//   flutter test --coverage --file-reporter=json:build/test_events.json
//   dart run tool/aggregate_test_metrics.dart
//   dart run tool/aggregate_test_metrics.dart --perf-json ../docs/PERF_RESULTS_2026-03-27.json

import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final eventsPath = arg(args, '--events') ?? 'build/test_events.json';
  final lcovPath = arg(args, '--lcov') ?? 'coverage/lcov.info';
  final outDirPath = arg(args, '--out') ?? '../docs/qa/generated';
  final perfPath = arg(args, '--perf-json');

  final eventsFile = File(eventsPath);
  if (!eventsFile.existsSync()) {
    stderr.writeln(
      'Missing $eventsPath. Run:\n'
      '  flutter test --coverage --file-reporter=json:$eventsPath',
    );
    exitCode = 1;
    return;
  }

  final outDir = Directory(outDirPath);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final testSuiteByTestId = <int, int>{};
  final testStartTime = <int, int>{};
  final suitePathById = <int, String>{};
  var passed = 0;
  var failed = 0;
  var skipped = 0;
  var runSuccess = false;
  int? wallMs;

  final suitePassed = <int, int>{};
  final suiteFailed = <int, int>{};
  final suiteSkipped = <int, int>{};
  final suiteDurationMs = <int, int>{};

  for (final line in eventsFile.readAsLinesSync()) {
    if (line.isEmpty) continue;
    final o = jsonDecode(line) as Map<String, dynamic>;
    switch (o['type']) {
      case 'suite':
        final s = o['suite'] as Map<String, dynamic>;
        suitePathById[s['id'] as int] = s['path'] as String? ?? '';
      case 'testStart':
        final t = o['test'] as Map<String, dynamic>?;
        if (t != null) {
          final id = t['id'] as int?;
          final sid = t['suiteID'] as int?;
          if (id != null && sid != null) {
            testSuiteByTestId[id] = sid;
            testStartTime[id] = o['time'] as int? ?? 0;
          }
        }
      case 'testDone':
        if (o['hidden'] == true) break;
        final tid = o['testID'] as int?;
        if (tid == null) break;
        final sid = testSuiteByTestId[tid];
        final start = testStartTime[tid] ?? 0;
        final end = o['time'] as int? ?? start;
        final delta = (end - start).clamp(0, 1 << 30);
        if (sid != null) {
          suiteDurationMs[sid] = (suiteDurationMs[sid] ?? 0) + delta;
        }
        if (o['skipped'] == true) {
          skipped++;
          if (sid != null) suiteSkipped[sid] = (suiteSkipped[sid] ?? 0) + 1;
        } else {
          switch (o['result']) {
            case 'success':
              passed++;
              if (sid != null) suitePassed[sid] = (suitePassed[sid] ?? 0) + 1;
            default:
              failed++;
              if (sid != null) suiteFailed[sid] = (suiteFailed[sid] ?? 0) + 1;
          }
        }
      case 'done':
        runSuccess = o['success'] == true;
        wallMs = o['time'] as int?;
    }
  }

  final cov = _parseLcov(File(lcovPath));

  final suites = <Map<String, dynamic>>[];
  for (final id in suitePathById.keys.toList()..sort()) {
    final path = suitePathById[id]!;
    if (path.isEmpty) continue;
    final p = suitePassed[id] ?? 0;
    final f = suiteFailed[id] ?? 0;
    final sk = suiteSkipped[id] ?? 0;
    if (p + f + sk == 0) continue;
    suites.add({
      'suiteId': id,
      'path': path,
      'passed': p,
      'failed': f,
      'skipped': sk,
      'durationMs': suiteDurationMs[id] ?? 0,
    });
  }

  final generatedAt = DateTime.now().toUtc().toIso8601String();
  final total = passed + failed + skipped;
  final executed = passed + failed;
  final passRatePercent = executed > 0
      ? double.parse((100.0 * passed / executed).toStringAsFixed(2))
      : 0.0;
  var suitesWithZeroFailures = 0;
  for (final s in suites) {
    if ((s['failed'] as int) == 0 &&
        (s['passed'] as int) + (s['failed'] as int) + (s['skipped'] as int) >
            0) {
      suitesWithZeroFailures++;
    }
  }
  final linePct = cov == null ? null : (cov['linePercent'] as num).toDouble();
  final wallSec = wallMs == null
      ? null
      : double.parse((wallMs / 1000.0).toStringAsFixed(2));

  final perfFile = perfPath != null ? File(perfPath) : null;
  final perfSlice = _parsePerfResultsJson(perfFile);

  final executiveSummary = <String, dynamic>{
    'automatedTestPassRatePercent': passRatePercent,
    'testsExecutedNonSkipped': executed,
    'testsSkipped': skipped,
    'suiteCount': suites.length,
    'suitesWithZeroFailures': suitesWithZeroFailures,
    'lineCoveragePercent': linePct,
    'wallClockSeconds': wallSec,
    'flutterTestRunnerSuccess': runSuccess,
  };

  final evidenceScope = <String, dynamic>{
    'whatAutomatedMetricsCover': <String>[
      'Regression signal: unit/widget tests that ran on this commit.',
      'Breadth: how many test libraries and cases executed.',
      'Line coverage (lcov aggregate): share of instrumented lines touched by tests — trend metric, not proof every path is correct.',
    ],
    'whatTheyDoNotReplace': <String>[
      'End-user UX, accessibility, and visual polish (use docs/QA_CHECKLIST.md + manual template).',
      'Production SLOs, crash-free sessions, or real-device latency unless you also ship runtime benchmarks.',
      'Third-party services (Maps, Places) behavior offline or under quota errors.',
    ],
    'optionalRuntimeBenchmark': perfSlice == null
        ? 'No --perf-json provided; omit runtime rows or re-run with latest docs/PERF_RESULTS_*.json.'
        : 'Merged from perf JSON; read viewer_note on each row and docs/PERF_BENCHMARK.md for methodology.',
  };

  final viewerBrief = <String>[
    'Automated pass rate (${passRatePercent.toStringAsFixed(1)}%) reflects $executed executed tests ($skipped skipped).',
    if (linePct != null)
      'Aggregate line coverage is ${linePct.toStringAsFixed(2)}% of instrumented lines in lcov.info.',
    if (wallSec != null)
      'CI test wall time was ~${wallSec}s (machine-dependent).',
    'Pair this export with manual QA completion (see docs/qa/templates/manual_qa_completion_template.csv) for a credible “overall quality” story.',
  ];

  final payload = <String, dynamic>{
    'generatedAt': generatedAt,
    'flutterTestSuccess': runSuccess,
    'summary': {
      'total': total,
      'passed': passed,
      'failed': failed,
      'skipped': skipped,
      'wallClockMs': wallMs,
    },
    'executiveSummary': executiveSummary,
    'evidenceScope': evidenceScope,
    'viewerBrief': viewerBrief,
    'suites': suites,
    'coverage': cov,
    if (perfSlice != null) 'runtimeBenchmark': perfSlice,
  };

  final jsonOut = File('${outDir.path}/test_metrics.json');
  jsonOut.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(payload));

  // CSV rows for quick charting (e.g. suite vs passed/failed)
  final csv = StringBuffer()
    ..writeln('kind,key,passed,failed,skipped,durationMs')
    ..writeln('TOTAL,_all,$passed,$failed,$skipped,${wallMs ?? ''}');
  for (final s in suites) {
    final p = (s['path'] as String).replaceAll(',', ';');
    csv.writeln(
      'SUITE,$p,${s['passed']},${s['failed']},${s['skipped']},${s['durationMs']}',
    );
  }
  if (cov != null) {
    csv.writeln(
      'COVERAGE,linePercent,,,,${cov['linePercent']}',
    );
    csv.writeln(
      'COVERAGE,linesHit,,,,${cov['linesHit']}',
    );
    csv.writeln(
      'COVERAGE,linesFound,,,,${cov['linesFound']}',
    );
  }
  File('${outDir.path}/test_metrics.csv').writeAsStringSync(csv.toString());

  _writeSystemOverviewForCharts(
    outDir: outDir,
    passRatePercent: passRatePercent,
    executed: executed,
    skipped: skipped,
    suiteCount: suites.length,
    suitesWithZeroFailures: suitesWithZeroFailures,
    linePct: linePct,
    wallSec: wallSec,
    runSuccess: runSuccess,
    perf: perfSlice,
  );

  stdout.writeln('Wrote ${jsonOut.path}');
  stdout.writeln('Wrote ${outDir.path}/test_metrics.csv');
  stdout.writeln('Wrote ${outDir.path}/system_overview_for_charts.csv');
}

String? arg(List<String> args, String flag) {
  final i = args.indexOf(flag);
  if (i >= 0 && i + 1 < args.length) return args[i + 1];
  return null;
}

/// Sums LF/LH across lcov.info for a rough line-coverage ratio.
Map<String, dynamic>? _parseLcov(File f) {
  if (!f.existsSync()) return null;
  var lf = 0;
  var lh = 0;
  for (final line in f.readAsLinesSync()) {
    if (line.startsWith('LF:')) {
      lf += int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LH:')) {
      lh += int.tryParse(line.substring(3).trim()) ?? 0;
    }
  }
  if (lf == 0) {
    return {'linesFound': 0, 'linesHit': 0, 'linePercent': 0.0};
  }
  return {
    'linesFound': lf,
    'linesHit': lh,
    'linePercent': double.parse((100.0 * lh / lf).toStringAsFixed(2)),
  };
}

/// Optional merge of `docs/PERF_RESULTS_*.json` (wrapper with `result` object).
Map<String, dynamic>? _parsePerfResultsJson(File? f) {
  if (f == null || !f.existsSync()) return null;
  try {
    final o = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final r = o['result'];
    if (r is! Map<String, dynamic>) return null;
    return {
      'sourcePath': f.path,
      'runTimestampUtc': o['run_timestamp_utc'],
      'environment': o['environment'],
      'response_time_avg_ms': r['response_time_avg_ms'],
      'response_time_max_ms': r['response_time_max_ms'],
      'workflow_success_rate': r['workflow_success_rate'],
      'message_latency_ms': r['message_latency_ms'],
      'notes': r['notes'],
    };
  } catch (_) {
    return null;
  }
}

void _writeSystemOverviewForCharts({
  required Directory outDir,
  required double passRatePercent,
  required int executed,
  required int skipped,
  required int suiteCount,
  required int suitesWithZeroFailures,
  required double? linePct,
  required double? wallSec,
  required bool runSuccess,
  required Map<String, dynamic>? perf,
}) {
  final rows = <List<String>>[
    <String>[
      'metric_key',
      'metric_label',
      'value_numeric',
      'value_display',
      'chart_group',
      'recommended_chart',
      'viewer_note',
    ],
    _overviewRow(
      'pass_rate_pct',
      'Automated test pass rate (executed only)',
      passRatePercent,
      '${passRatePercent.toStringAsFixed(1)}%',
      'percent_0_100',
      'bar_or_gauge',
      'Passed / (passed+failed). Skipped tests are excluded from the rate.',
    ),
    _overviewRow(
      'tests_executed',
      'Tests executed (non-skipped)',
      executed.toDouble(),
      '$executed',
      'counts',
      'bar',
      'Raw count of test cases that ran.',
    ),
    _overviewRow(
      'tests_skipped',
      'Tests skipped',
      skipped.toDouble(),
      '$skipped',
      'counts',
      'bar',
      'Skipped tests are excluded from pass rate.',
    ),
    _overviewRow(
      'suite_count',
      'Test suites (libraries)',
      suiteCount.toDouble(),
      '$suiteCount',
      'counts',
      'bar',
      'One row per test library with at least one executed test.',
    ),
    _overviewRow(
      'suites_zero_failures',
      'Suites with zero failures',
      suitesWithZeroFailures.toDouble(),
      '$suitesWithZeroFailures',
      'counts',
      'bar',
      'Among suites that ran at least one test.',
    ),
    if (linePct != null)
      _overviewRow(
        'line_coverage_pct',
        'Line coverage (lcov aggregate)',
        linePct,
        '${linePct.toStringAsFixed(2)}%',
        'percent_0_100',
        'bar_or_gauge',
        'Project-wide LF/LH sum from lcov.info; use for trends, not line-by-line sign-off.',
      ),
    if (wallSec != null)
      _overviewRow(
        'test_wall_clock_s',
        'Flutter test run wall time',
        wallSec,
        '${wallSec}s',
        'seconds',
        'bar',
        'Machine/IO dependent; compare across commits on the same runner.',
      ),
    _overviewRow(
      'flutter_runner_success',
      'Flutter test runner success flag',
      runSuccess ? 1.0 : 0.0,
      runSuccess ? '1 (success)' : '0 (failures)',
      'gate',
      'bar',
      '1 if the test process exited clean; still inspect failed counts for detail.',
    ),
  ];

  if (perf != null) {
    final avg = perf['response_time_avg_ms'];
    final max = perf['response_time_max_ms'];
    final wf = perf['workflow_success_rate'];
    final msg = perf['message_latency_ms'];
    final wfNum = wf is num ? wf.toDouble() : null;
    final wfPct = wfNum == null ? null : (wfNum * 100.0);

    if (avg is num) {
      rows.add(
        _overviewRow(
          'firestore_response_avg_ms',
          'Runtime: Firestore ops avg response (probe)',
          avg.toDouble(),
          '${avg.round()} ms',
          'milliseconds',
          'bar',
          'From merged perf JSON; real device/emulator. See notes field in JSON for caveats.',
        ),
      );
    }
    if (max is num) {
      rows.add(
        _overviewRow(
          'firestore_response_max_ms',
          'Runtime: Firestore ops max response (probe)',
          max.toDouble(),
          '${max.round()} ms',
          'milliseconds',
          'bar',
          'Worst iteration in the probe run.',
        ),
      );
    }
    if (wfPct != null) {
      rows.add(
        _overviewRow(
          'workflow_success_rate_pct',
          'Runtime: workflow success rate (probe)',
          wfPct,
          '${wfPct.toStringAsFixed(1)}%',
          'percent_0_100',
          'bar_or_gauge',
          'Probe-defined workflow (listing/search/assignment). Interpret with JSON notes; 0% can mean benchmark criteria mismatch.',
        ),
      );
    }
    if (msg is num) {
      rows.add(
        _overviewRow(
          'message_latency_ms',
          'Runtime: chat send→stream latency (probe)',
          msg.toDouble(),
          msg > 0 ? '${msg.round()} ms' : '0 (no sample)',
          'milliseconds',
          'bar',
          '0 usually means the probe did not record a send→stream latency in that run.',
        ),
      );
    }
  }

  final buf = StringBuffer();
  for (final row in rows) {
    buf.writeln(row.map(_csvEscape).join(','));
  }
  File('${outDir.path}/system_overview_for_charts.csv')
      .writeAsStringSync(buf.toString());
}

List<String> _overviewRow(
  String key,
  String label,
  double valueNumeric,
  String valueDisplay,
  String chartGroup,
  String recommendedChart,
  String viewerNote,
) {
  return [
    key,
    label,
    valueNumeric.toString(),
    valueDisplay,
    chartGroup,
    recommendedChart,
    viewerNote,
  ];
}

String _csvEscape(String field) {
  if (field.contains(',') ||
      field.contains('"') ||
      field.contains('\n') ||
      field.contains('\r')) {
    return '"${field.replaceAll('"', '""')}"';
  }
  return field;
}
