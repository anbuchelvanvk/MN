import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Runs before every test file.
///
/// The app's text uses the Outfit font through google_fonts, loaded from
/// assets/google_fonts/ in the background the first time each weight is
/// used. When a weight finished loading after a test had ended, Flutter
/// scheduled a font-change frame with no widgets left, and newer Flutter
/// (3.50+) fails the test for it ("An animation is still running even after
/// the widget tree was disposed"). Loading every weight up front avoids that.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Tests never download fonts; the bundled files are used.
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final weight in FontWeight.values) {
    GoogleFonts.outfit(fontWeight: weight);
  }
  await GoogleFonts.pendingFonts();
  await testMain();
}
