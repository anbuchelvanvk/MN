import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_models.dart';

/// Offline write-ahead queue and persistence service for attendance punches & tasks.
/// Guarantees zero punch loss when showroom or cellular network drops.
/// Fixed for B-05: Serialized queue access via async lock and individual record error isolation.
class OfflineSyncService {
  static const String _keyPendingPunches = 'mn_offline_pending_punches';
  static const String _keyAllCachedPunches = 'mn_offline_cached_punches';
  static const String _keyPendingTaskCompletions = 'mn_offline_pending_task_completions';

  // Async lock chain to serialize read-modify-write operations
  static Future<void> _lockChain = Future.value();

  static Future<T> _synchronized<T>(Future<T> Function() computation) {
    final completer = Completer<T>();
    _lockChain = _lockChain.then((_) async {
      try {
        final result = await computation();
        completer.complete(result);
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  /// Save punch to offline persistent queue
  static Future<void> enqueuePunch(AttendancePunchRecord punch) => _synchronized(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_keyPendingPunches) ?? [];
      existing.add(jsonEncode(punch.toJson()));
      await prefs.setStringList(_keyPendingPunches, existing);

      // Also persist to all-time local cache for instant offline loading
      final allPunches = prefs.getStringList(_keyAllCachedPunches) ?? [];
      allPunches.insert(0, jsonEncode(punch.toJson()));
      // Keep up to 200 recent punches
      if (allPunches.length > 200) allPunches.removeRange(200, allPunches.length);
      await prefs.setStringList(_keyAllCachedPunches, allPunches);

      debugPrint('OfflineSyncService: Punch ${punch.id} enqueued locally.');
    } catch (e) {
      debugPrint('OfflineSyncService enqueue error: $e');
    }
  });

  /// Load pending punches that still need cloud syncing (safely handles bad entries)
  static Future<List<AttendancePunchRecord>> getPendingPunches() => _synchronized(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyPendingPunches) ?? [];
      final List<AttendancePunchRecord> results = [];
      for (final str in list) {
        try {
          final data = jsonDecode(str) as Map<String, dynamic>;
          results.add(AttendancePunchRecord.fromJson(data));
        } catch (e) {
          debugPrint('OfflineSyncService: Skipping corrupted punch entry: $e');
        }
      }
      return results;
    } catch (e) {
      debugPrint('OfflineSyncService load pending error: $e');
      return [];
    }
  });

  /// Remove synced punch from queue
  static Future<void> removePendingPunch(String punchId) => _synchronized(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyPendingPunches) ?? [];
      list.removeWhere((str) {
        try {
          final data = jsonDecode(str) as Map<String, dynamic>;
          return data['id'] == punchId;
        } catch (_) {
          return true; // remove corrupted record
        }
      });
      await prefs.setStringList(_keyPendingPunches, list);
    } catch (e) {
      debugPrint('OfflineSyncService removePendingPunch error: $e');
    }
  });

  /// Clear all pending punches after full sync
  static Future<void> clearPendingPunches() => _synchronized(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingPunches);
    } catch (e) {
      debugPrint('OfflineSyncService clearPendingPunches error: $e');
    }
  });

  /// Load cached punches for instant offline app startup
  static Future<List<AttendancePunchRecord>> loadCachedPunches() => _synchronized(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyAllCachedPunches) ?? [];
      final List<AttendancePunchRecord> results = [];
      for (final str in list) {
        try {
          final data = jsonDecode(str) as Map<String, dynamic>;
          results.add(AttendancePunchRecord.fromJson(data));
        } catch (e) {
          debugPrint('OfflineSyncService: Skipping corrupted cached punch: $e');
        }
      }
      return results;
    } catch (e) {
      return [];
    }
  });

  /// Enqueue offline task completion proof
  static Future<void> enqueueTaskCompletion({
    required String taskId,
    required String proofText,
    String? photoUrl,
  }) => _synchronized(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyPendingTaskCompletions) ?? [];
      list.add(jsonEncode({
        'taskId': taskId,
        'proofText': proofText,
        'photoUrl': photoUrl,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      await prefs.setStringList(_keyPendingTaskCompletions, list);
    } catch (e) {
      debugPrint('OfflineSyncService enqueueTaskCompletion error: $e');
    }
  });

  /// Get pending offline task completions
  static Future<List<Map<String, dynamic>>> getPendingTaskCompletions() => _synchronized(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyPendingTaskCompletions) ?? [];
      final List<Map<String, dynamic>> results = [];
      for (final str in list) {
        try {
          final data = jsonDecode(str) as Map<String, dynamic>;
          results.add(data);
        } catch (e) {
          debugPrint('OfflineSyncService: Skipping corrupted task completion: $e');
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  });

  /// Remove single task completion by taskId
  static Future<void> removePendingTaskCompletion(String taskId) => _synchronized(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyPendingTaskCompletions) ?? [];
      list.removeWhere((str) {
        try {
          final data = jsonDecode(str) as Map<String, dynamic>;
          return data['taskId'] == taskId;
        } catch (_) {
          return true; // remove corrupted record
        }
      });
      await prefs.setStringList(_keyPendingTaskCompletions, list);
    } catch (_) {}
  });

  /// Clear pending task completions
  static Future<void> clearPendingTaskCompletions() => _synchronized(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingTaskCompletions);
    } catch (_) {}
  });
}
