import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Saves [bytes] where the user chooses (Android "Save to" screen, which
/// includes Downloads; a browser download on web).
///
/// Android 10+ does not let apps write straight into the public Downloads
/// folder, so the system picker is the reliable way to save a file the user
/// can find later. Returns the saved location, or null if cancelled.
Future<String?> saveBytesWithPicker({
  required Uint8List bytes,
  required String fileName,
  required List<String> extensions,
  String dialogTitle = 'Save file',
}) async {
  final saved = await FilePicker.saveFile(
    dialogTitle: dialogTitle,
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: extensions,
    bytes: bytes,
  );
  // Desktop pickers only return a path; write the bytes ourselves there.
  if (saved != null &&
      !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await File(saved).writeAsBytes(bytes, flush: true);
  }
  return saved;
}
