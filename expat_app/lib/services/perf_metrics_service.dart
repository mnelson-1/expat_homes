import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'perf_workflow_ids.dart';

class PerfSample {
  PerfSample({
    required this.metric,
    required this.elapsedMs,
    required this.at,
    this.ok = true,
    this.error,
    this.iterationIndex = 0,
  });

  final String metric;
  final int elapsedMs;
  final DateTime at;
  final bool ok;
  final String? error;
  final int iterationIndex;
}

class PerfMetricsService {
  PerfMetricsService._();
  static final PerfMetricsService _instance = PerfMetricsService._();
  factory PerfMetricsService() => _instance;

  /// Used for legacy `response_time_*` (Firestore-focused samples only).
  static const Set<String> legacyAggregateMetrics = {
    'create_listing',
    'verify_listing_update',
    'fetch_listings',
    'create_assignment',
    'accept_assignment',
    'send_message',
  };

  final List<PerfSample> _samples = <PerfSample>[];
  int _workflowRuns = 0;
  int _workflowSuccesses = 0;
  int? _lastMessageLatencyMs;
  int _currentIteration = 0;

  void reset() {
    _samples.clear();
    _workflowRuns = 0;
    _workflowSuccesses = 0;
    _lastMessageLatencyMs = null;
    _currentIteration = 0;
  }

  /// Call at the start of each benchmark loop iteration so nested services pick up the index.
  void setIteration(int index) => _currentIteration = index;

  void addSample(
    String metric,
    int elapsedMs, {
    bool ok = true,
    String? error,
    int? iterationIndex,
  }) {
    final s = PerfSample(
      metric: metric,
      elapsedMs: elapsedMs,
      at: DateTime.now(),
      ok: ok,
      error: error,
      iterationIndex: iterationIndex ?? _currentIteration,
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
    final opTimes = _samples
        .where((e) => legacyAggregateMetrics.contains(e.metric))
        .map((e) => e.elapsedMs)
        .toList();
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
          'response_time_* uses Firestore-path samples only (${legacyAggregateMetrics.join(", ")}). '
          'workflow_success_rate is full benchmark loop pass rate. '
          'message_latency_ms is send→stream. '
          'Use workflow_history / PERF_WORKFLOW_HISTORY_JSON for role UX workflows.',
    };
  }

  /// One JSON object to append to `docs/perf/history/workflow_history.jsonl`.
  Map<String, dynamic> buildWorkflowHistoryRecord({
    required Map<String, dynamic> environment,
    required String benchmarkRole,
    DateTime? recordedAt,
  }) {
    final at = (recordedAt ?? DateTime.now()).toUtc();
    final order = PerfWorkflowIds.chartOrderForRole(benchmarkRole);
    final workflows = <String, dynamic>{};
    for (final id in order) {
      final metric = _metricNameForWorkflow(id);
      final rel = _samples.where((s) => s.metric == metric).toList();
      final times = rel.map((s) => s.elapsedMs).toList();
      final block = Map<String, dynamic>.from(_statsMap(times));
      if (rel.isNotEmpty) {
        final okN = rel.where((s) => s.ok).length;
        block['success_rate'] = ((okN / rel.length) * 100).round();
      }
      workflows[id] = block;
    }

    final iterations = <Map<String, dynamic>>[];
    final maxIter = _samples.fold<int>(
      0,
      (m, s) => s.iterationIndex > m ? s.iterationIndex : m,
    );
    for (var i = 0; i <= maxIter; i++) {
      final row = <String, dynamic>{'iteration': i};
      for (final id in order) {
        final metric = _metricNameForWorkflow(id);
        final hit = _samples
            .where((s) => s.metric == metric && s.iterationIndex == i)
            .map((s) => s.elapsedMs)
            .toList();
        row[id] = hit.isEmpty ? null : hit.first;
      }
      iterations.add(row);
    }

    return <String, dynamic>{
      'recorded_at': at.toIso8601String(),
      'schema': 'workflow_perf/v1',
      'environment': environment,
      'workflows': workflows,
      'iterations': iterations,
    };
  }

  static String _metricNameForWorkflow(String workflowId) {
    switch (workflowId) {
      case PerfWorkflowIds.landlordListingCreation:
        return 'create_listing';
      case PerfWorkflowIds.landlordListingAssignment:
        return 'listing_assignment';
      default:
        return workflowId;
    }
  }

  static Map<String, dynamic> _statsMap(List<int> times) {
    if (times.isEmpty) {
      return <String, dynamic>{
        'avg_ms': null,
        'max_ms': null,
        'min_ms': null,
        'p90_ms': null,
        'n': 0,
      };
    }
    final sorted = List<int>.from(times)..sort();
    final n = sorted.length;
    final sum = sorted.reduce((a, b) => a + b);
    final p90i = ((n * 0.9).ceil() - 1).clamp(0, n - 1);
    return <String, dynamic>{
      'avg_ms': (sum / n).round(),
      'max_ms': sorted.last,
      'min_ms': sorted.first,
      'p90_ms': sorted[p90i],
      'n': n,
    };
  }

  String summaryJsonString() => const JsonEncoder.withIndent('  ').convert(
        summaryJson(),
      );
}
