import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'read_platform_file_bytes_stub.dart'
    if (dart.library.io) 'read_platform_file_bytes_io.dart' as impl;

/// Loads bytes from a [PlatformFile], using [File] on IO when [PlatformFile.bytes] is null.
Future<Uint8List?> readPlatformFileBytes(PlatformFile file) =>
    impl.readPlatformFileBytes(file);
