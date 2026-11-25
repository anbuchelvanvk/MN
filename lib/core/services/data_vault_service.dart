import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';

class DataVaultException implements Exception {
  final String message;
  DataVaultException(this.message);
  @override
  String toString() => message;
}

/// CEO-only company data backup / delete / restore (server side in
/// functions/data_vault.js).
class DataVaultService {
  static const backupFormat = 'mn-family-backup';

  static HttpsCallable _fn(String name) => FirebaseFunctions.instanceFor(region: 'asia-south1')
      .httpsCallable(name, options: HttpsCallableOptions(timeout: const Duration(minutes: 9)));

  static Future<Map<String, dynamic>> _call(String name, [Map<String, dynamic>? data]) async {
    try {
      final res = await _fn(name).call<dynamic>(data ?? <String, dynamic>{});
      return _deepMap(res.data) as Map<String, dynamic>;
    } on FirebaseFunctionsException catch (e) {
      throw DataVaultException(e.message ?? 'Something went wrong. Please try again.');
    } catch (_) {
      throw DataVaultException('Could not reach the server. Check your internet and try again.');
    }
  }

  /// Converts the platform's map types into plain Dart JSON maps/lists.
  static dynamic _deepMap(dynamic v) {
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), _deepMap(val)));
    if (v is List) return v.map(_deepMap).toList();
    return v;
  }

  /// Full backup of the database as a JSON document.
  static Future<Map<String, dynamic>> exportBackup() => _call('exportBackup');

  /// Deletes everything except staff details. Returns what was removed.
  static Future<Map<String, dynamic>> wipe({required bool includeActivity}) =>
      _call('wipeOperationalData', {'confirm': 'DELETE', 'includeActivity': includeActivity});

  /// Writes a backup's activity data back to the database.
  static Future<Map<String, dynamic>> restore(Map<String, dynamic> backup, {required bool includeActivity}) =>
      _call('restoreBackup', {'backup': backup, 'includeActivity': includeActivity});

  /// Reads a backup file; throws if it is not an MN Family backup.
  static Map<String, dynamic> parseFile(List<int> bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw DataVaultException('This file could not be read. Choose an MN Family backup (.json).');
    }
    if (decoded is! Map<String, dynamic> || decoded['format'] != backupFormat || decoded['collections'] is! Map) {
      throw DataVaultException('This is not an MN Family backup file.');
    }
    return decoded;
  }

  static int totalDocs(Map<String, dynamic> backup) {
    final counts = backup['counts'];
    if (counts is Map) return counts.values.fold<int>(0, (s, v) => s + ((v as num?)?.toInt() ?? 0));
    return 0;
  }
}
