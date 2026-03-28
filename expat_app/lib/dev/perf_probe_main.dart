import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:expat_app/services/auth_service.dart';
import 'package:expat_app/services/perf_benchmark_service.dart';
import 'package:expat_app/screens/get_started_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const _PerfProbeApp());
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
      final history = full.remove('workflow_history');
      // ignore: avoid_print
      print('PERF_PROBE_RESULT=$full');
      debugPrint('PERF_PROBE_RESULT=$full');
      final histLine = jsonEncode(history);
      // ignore: avoid_print
      print('PERF_WORKFLOW_HISTORY_JSON=$histLine');
      debugPrint('PERF_WORKFLOW_HISTORY_JSON=$histLine');

      if (!mounted) return;
      setState(() => _status = full.toString());
    } catch (e) {
      debugPrint('PERF_PROBE_ERROR=$e');
      if (!mounted) return;
      setState(() => _status = 'Benchmark failed: $e');
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
              // Show the normal onboarding/login UI so a real Firebase session
              // exists before the benchmark runs.
              return const GetStartedScreen();
            }

            // Run once right after sign-in.
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

