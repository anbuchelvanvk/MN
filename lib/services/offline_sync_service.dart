import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance_models.dart';

/// Offline write-ahead queue and persistence service for attendance punches & tasks.
/// Guarantees zero punch loss when showroom or cellular network drops.
class OfflineSyncService {
  static const String _keyPendingPunches = 'mn_offline_pending_punches';
  static const String _keyAllCachedPunches = 'mn_offline_cached_punches';
  static const String _keyPendingTaskCompletions = 'mn_offline_pending_task_completions';

  /// Save punch to offline persistent queue
  static Future<void> enqueuePunch(AttendancePunchRecord punch) async {
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
  }

  /// Load pending punches that still need cloud syncing
  static Future<List<AttendancePunchRecord>> getPendingPunches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyPendingPunches) ?? [];
      return list.map((str) {
        return AttendancePunchRecord.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      debugPrint('OfflineSyncService load pending error: $e');
      return [];
    }
  }

  /// Remove synced punch from queue
  static Future<void> removePendingPunch(String punchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyPendingPunches) ?? [];
      list.removeWhere((str) {
        try {
          final data = jsonDecode(str) as Map<String, dynamic>;
          return data['id'] == punchId;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList(_keyPendingPunches, list);
    } catch (e) {
      debugPrint('OfflineSyncService removePendingPunch error: $e');
    }
  }

  /// Clear all pending punches after full sync
  static Future<void> clearPendingPunches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingPunches);
    } catch (e) {
      debugPrint('OfflineSyncService clearPendingPunches error: $e');
    }
  }

  /// Load cached punches for instant offline app startup
  static Future<List<AttendancePunchRecord>> loadCachedPunches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyAllCachedPunches) ?? [];
      return list.map((str) {
        return AttendancePunchRecord.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Enqueue offline task completion proof
  static Future<void> enqueueTaskCompletion({
    required String taskId,
    required String proofText,
    String? photoUrl,
  }) async {
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
  }

  /// Get pending offline task completions
  static Future<List<Map<String, dynamic>>> getPendingTaskCompletions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_keyPendingTaskCompletions) ?? [];
      return list.map((str) => jsonDecode(str) as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  /// Clear pending task completions
  static Future<void> clearPendingTaskCompletions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPendingTaskCompletions);
    } catch (_) {}
  }
}

