import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<Uint8List?> readPlatformFileBytes(PlatformFile file) async {
  if (file.bytes != null) return file.bytes;
  final path = file.path;
  if (path != null && path.isNotEmpty) {
    try {
      return await File(path).readAsBytes();
    } catch (_) {
      return null;
    }
  }
  return null;
}
