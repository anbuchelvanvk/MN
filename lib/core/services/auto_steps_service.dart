import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';

/// Where automatic step counting stands on this phone.
enum AutoStepsStatus {
  /// The person has not switched it on.
  off,

  /// Not a phone (web, desktop, tests).
  unsupported,

  /// Android: the Health Connect app is missing or needs an update.
  needsHealthConnect,

  /// Switched on, but the person has not allowed step access (or turned it off).
  needsPermission,

  /// Working: steps fill in automatically.
  on,
}

/// Reads the phone's step count: Health Connect on Android, Apple Health on
/// iPhone. Read only — the app never writes to the person's health data.
class AutoStepsService {
  AutoStepsService._();

  static final Health _health = Health();
  static const _channel = MethodChannel('com.mnjewelpark.mn_family_app/background_permissions');
  static const _types = [HealthDataType.STEPS];
  static const _read = [HealthDataAccess.READ];
  static bool _configured = false;

  /// Test hooks: pretend to be a phone with these answers.
  @visibleForTesting
  static bool? debugIsIOS;
  @visibleForTesting
  static AutoStepsStatus? debugStatus;
  @visibleForTesting
  static int? Function(DateTime day)? debugStepsForDay;

  static bool get _faked => debugStatus != null;
  static bool get isSupported => _faked || (!kIsWeb && (Platform.isAndroid || Platform.isIOS));
  static bool get isIOS => debugIsIOS ?? (!kIsWeb && Platform.isIOS);

  /// "Apple Health" or "Health Connect", for messages.
  static String get sourceName => isIOS ? 'Apple Health' : 'Health Connect';

  static Future<void> _configure() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Current state without showing any prompt.
  static Future<AutoStepsStatus> check() async {
    if (_faked) return debugStatus!;
    if (!isSupported) return AutoStepsStatus.unsupported;
    try {
      await _configure();
      if (Platform.isAndroid) {
        final sdk = await _health.getHealthConnectSdkStatus();
        if (sdk != HealthConnectSdkStatus.sdkAvailable) return AutoStepsStatus.needsHealthConnect;
        final granted = await _health.hasPermissions(_types, permissions: _read);
        return granted == true ? AutoStepsStatus.on : AutoStepsStatus.needsPermission;
      }
      // iPhone: Apple Health never says whether reading was allowed (privacy).
      // We treat it as on and show a hint when no steps come back.
      return AutoStepsStatus.on;
    } catch (e) {
      debugPrint('AutoSteps check: $e');
      return AutoStepsStatus.needsPermission;
    }
  }

  /// Asks for step access (shows the system prompt). Returns the new state.
  static Future<AutoStepsStatus> enable() async {
    if (_faked) return debugStatus!;
    if (!isSupported) return AutoStepsStatus.unsupported;
    try {
      await _configure();
      if (Platform.isAndroid) {
        final sdk = await _health.getHealthConnectSdkStatus();
        if (sdk != HealthConnectSdkStatus.sdkAvailable) return AutoStepsStatus.needsHealthConnect;
        // Lets the phone itself count steps (Android 10+).
        try {
          await _channel.invokeMethod('requestActivityRecognition');
        } catch (_) {}
      }
      final ok = await _health.requestAuthorization(_types, permissions: _read);
      if (Platform.isIOS) return AutoStepsStatus.on;
      return ok ? AutoStepsStatus.on : AutoStepsStatus.needsPermission;
    } catch (e) {
      debugPrint('AutoSteps enable: $e');
      return AutoStepsStatus.needsPermission;
    }
  }

  /// Opens the Play Store page for Health Connect (Android only).
  static Future<void> installHealthConnect() async {
    if (_faked || !isSupported || Platform.isIOS) return;
    try {
      await _health.installHealthConnect();
    } catch (_) {}
  }

  /// Total steps for one calendar day, or null if they could not be read.
  static Future<int?> stepsForDay(DateTime day) async {
    if (_faked) return debugStepsForDay?.call(day);
    if (!isSupported) return null;
    try {
      await _configure();
      final start = DateTime(day.year, day.month, day.day);
      final now = DateTime.now();
      var end = start.add(const Duration(days: 1));
      if (end.isAfter(now)) end = now;
      if (!end.isAfter(start)) return 0;
      return await _health.getTotalStepsInInterval(start, end) ?? 0;
    } catch (e) {
      debugPrint('AutoSteps read: $e');
      return null;
    }
  }
}
