import 'dart:convert';
import 'dart:io';

/// Host repo: `<repo>/test_results/`. On Android/iOS: app temp dir (adb pull / device file browser).
Future<void> savePerfProbeJsonFile({
  required String relativeSegments,
  required Map<String, dynamic> payload,
}) async {
  final segs = relativeSegments
      .replaceAll(r'\', '/')
      .split('/')
      .where((s) => s.isNotEmpty)
      .toList();
  final name = segs.isEmpty ? 'expat_performance.json' : segs.last;
  late final File file;
  if (Platform.isAndroid || Platform.isIOS) {
    final dir = Directory('${Directory.systemTemp.path}/expat_perf');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    file = File('${dir.path}${Platform.pathSeparator}$name');
  } else {
    final root = _resolveRepoRoot();
    final dir = Directory('$root/test_results');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    file = File('${dir.path}${Platform.pathSeparator}$name');
  }
  await file.writeAsString(JsonEncoder.withIndent('  ').convert(payload));
  // ignore: avoid_print
  print('PERF_RESULTS_FILE=${file.absolute.path}');
}

String _resolveRepoRoot() {
  final cwd = Directory.current.path;
  final parts = cwd.split(Platform.pathSeparator).where((s) => s.isNotEmpty);
  final last = parts.isEmpty ? '' : parts.last;
  if (last == 'expat_app') {
    return Directory(cwd).parent.path;
  }
  return cwd;
}
