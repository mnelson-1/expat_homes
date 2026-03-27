import 'dart:convert';

import 'package:flutter/foundation.dart';

class PerfSample {
  const PerfSample({
    required this.metric,
    required this.elapsedMs,
    required this.at,
    this.ok = true,
    this.error,
  });

  final String metric;
  final int elapsedMs;
  final DateTime at;
  final bool ok;
  final String? error;
}

class PerfMetricsService {
  PerfMetricsService._();
  static final PerfMetricsService _instance = PerfMetricsService._();
  factory PerfMetricsService() => _instance;

  final List<PerfSample> _samples = <PerfSample>[];
  int _workflowRuns = 0;
  int _workflowSuccesses = 0;
  int? _lastMessageLatencyMs;

  void reset() {
    _samples.clear();
    _workflowRuns = 0;
    _workflowSuccesses = 0;
    _lastMessageLatencyMs = null;
  }

  void addSample(
    String metric,
    int elapsedMs, {
    bool ok = true,
    String? error,
  }) {
    final s = PerfSample(
      metric: metric,
      elapsedMs: elapsedMs,
      at: DateTime.now(),
      ok: ok,
      error: error,
    );
    _samples.add(s);
    debugPrint(
      '[PERF][$metric] ${elapsedMs}ms'
      '${ok ? '' : ' FAIL'}${error == null ? '' : ' error=$error'}',
    );
  }

  void addWorkflowResult(bool ok) {
    _workflowRuns += 1;
    if (ok) _workflowSuccesses += 1;
  }

  void setMessageLatencyMs(int elapsedMs) {
    _lastMessageLatencyMs = elapsedMs;
    debugPrint('[PERF][message_latency] ${elapsedMs}ms');
  }

  Map<String, dynamic> summaryJson() {
    final opTimes = _samples.map((e) => e.elapsedMs).toList();
    final avg = opTimes.isEmpty
        ? 0
        : (opTimes.reduce((a, b) => a + b) / opTimes.length).round();
    final max = opTimes.isEmpty ? 0 : opTimes.reduce((a, b) => a > b ? a : b);
    final successRate = _workflowRuns == 0
        ? 0
        : ((_workflowSuccesses / _workflowRuns) * 100).round();

    return <String, dynamic>{
      'response_time_avg_ms': avg,
      'response_time_max_ms': max,
      'workflow_success_rate': successRate,
      'message_latency_ms': _lastMessageLatencyMs ?? 0,
      'notes':
          'response_time_* aggregates measured Firestore operations. '
          'workflow_success_rate is benchmark workflow pass percentage. '
          'message_latency_ms measures send->stream-observed latency.',
    };
  }

  String summaryJsonString() => const JsonEncoder.withIndent('  ').convert(
        summaryJson(),
      );
}

