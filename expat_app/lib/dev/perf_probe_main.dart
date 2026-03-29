import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/perf_benchmark_service.dart';
import 'package:expat_app/screens/get_started_screen.dart';

import 'perf_probe_exit_stub.dart'
    if (dart.library.io) 'perf_probe_exit_io.dart' as perf_exit;
import 'perf_probe_results_stub.dart'
    if (dart.library.io) 'perf_probe_results_io.dart' as perf_results;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await _perfProbeMaybeAutoSignIn();
  runApp(const _PerfProbeApp());
}

/// Optional non-interactive sign-in for CI / scripted runs.
/// Pass via `--dart-define=PERF_PROBE_EMAIL=...` and `PERF_PROBE_PASSWORD=...`.
/// Do not commit real credentials; use a throwaway Firebase test user.
Future<void> _perfProbeMaybeAutoSignIn() async {
  const email = String.fromEnvironment('PERF_PROBE_EMAIL', defaultValue: '');
  const password = String.fromEnvironment('PERF_PROBE_PASSWORD', defaultValue: '');
  if (email.isEmpty || password.isEmpty) return;
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // ignore: avoid_print
    print('PERF_PROBE_AUTO_SIGN_IN=ok');
  } catch (e) {
    // ignore: avoid_print
    print('PERF_PROBE_AUTO_SIGN_IN_FAILED=$e');
  }
}

void _scheduleProcessExit(int code) {
  if (kIsWeb) return;
  const shouldExit = bool.fromEnvironment(
    'PERF_PROBE_EXIT_WHEN_DONE',
    defaultValue: false,
  );
  if (!shouldExit) return;
  Future<void>(() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    perf_exit.perfProbeExit(code);
  });
}

class _PerfProbeApp extends StatefulWidget {
  const _PerfProbeApp();

  @override
  State<_PerfProbeApp> createState() => _PerfProbeAppState();
}

class _PerfProbeAppState extends State<_PerfProbeApp> {
  bool _ran = false;
  String _status = 'Waiting for sign-in...';

  Future<void> _runOnceIfNeeded(User? user) async {
    if (_ran || user == null) return;
    _ran = true;

    try {
      final userId = user.uid;
      debugPrint('PERF_PROBE_USER=$userId');
      // ignore: avoid_print
      print('PERF_PROBE_USER=$userId');

      final full = await PerfBenchmarkService().runBenchmarks(runs: 5);
      final history = Map<String, dynamic>.from(
        full.remove('workflow_history')! as Map,
      );
      final env = history['environment'] as Map<String, dynamic>?;
      final benchmarkRole =
          (env?['benchmark_role'] as String?)?.toLowerCase() ?? 'landlord';

      final iterations = (history['iterations'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final rawIterJson = const JsonEncoder.withIndent('  ').convert(iterations);

      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('========== PERF: RAW ITERATION DATA (JSON ARRAY) ==========');
      // ignore: avoid_print
      print(rawIterJson);
      // ignore: avoid_print
      print('========== END RAW ITERATION DATA ==========');
      // ignore: avoid_print
      print('PERF_RAW_ITERATION_JSON=$rawIterJson');

      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('========== PERF: SUMMARY METRICS ==========');
      final prettySummary =
          const JsonEncoder.withIndent('  ').convert(full);
      // ignore: avoid_print
      print(prettySummary);
      // ignore: avoid_print
      print('========== END SUMMARY METRICS ==========');
      // ignore: avoid_print
      print('PERF_SUMMARY_JSON=${jsonEncode(full)}');

      // ignore: avoid_print
      print('PERF_PROBE_RESULT=${jsonEncode(full)}');
      debugPrint('PERF_PROBE_RESULT=$full');

      final forConsole = Map<String, dynamic>.from(history);
      final histLine = jsonEncode(forConsole);
      // ignore: avoid_print
      print('');
      // ignore: avoid_print
      print('========== PERF: WORKFLOW HISTORY ==========');
      // ignore: avoid_print
      print(const JsonEncoder.withIndent('  ').convert(forConsole));
      // ignore: avoid_print
      print('========== END WORKFLOW HISTORY ==========');
      // ignore: avoid_print
      print('PERF_WORKFLOW_HISTORY_JSON=$histLine');
      debugPrint('PERF_WORKFLOW_HISTORY_JSON=${jsonEncode(history)}');

      final perfResultsFile = switch (benchmarkRole) {
        'expat' => 'expat_performance.json',
        'landlord' => 'landlord_performance.json',
        'agent' => 'agent_performance.json',
        _ => null,
      };
      if (perfResultsFile != null) {
        try {
          await perf_results.savePerfProbeJsonFile(
            relativeSegments: perfResultsFile,
            payload: <String, dynamic>{
              'recorded_at': history['recorded_at'],
              'benchmark_role': benchmarkRole,
              'iterations': iterations,
              'summary': Map<String, dynamic>.from(full),
              'workflow_history': Map<String, dynamic>.from(forConsole),
            },
          );
        } catch (e, st) {
          debugPrint('PERF_SAVE_FAILED=$e\n$st');
          // ignore: avoid_print
          print('PERF_SAVE_FAILED=$e');
        }
      }

      if (!mounted) return;
      setState(
        () => _status =
            'Benchmark finished ($benchmarkRole). Console: PERF_RAW_ITERATION_JSON, '
            'PERF_SUMMARY_JSON, PERF_WORKFLOW_HISTORY_JSON; '
            'results: test_results/expat_performance.json | landlord_performance.json | agent_performance.json.',
      );
      _scheduleProcessExit(0);
    } catch (e) {
      debugPrint('PERF_PROBE_ERROR=$e');
      // ignore: avoid_print
      print('PERF_PROBE_ERROR=$e');
      if (!mounted) return;
      setState(() => _status = 'Benchmark failed: $e');
      _scheduleProcessExit(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Perf Probe')),
        body: StreamBuilder<User?>(
          stream: AuthService().authStateChanges,
          builder: (context, snap) {
            final user = snap.data;
            if (user == null) {
              return const GetStartedScreen();
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _runOnceIfNeeded(user);
            });

            return Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(_status),
            );
          },
        ),
      ),
    );
  }
}
