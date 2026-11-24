import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A reset request started on this phone (kept so the user can close the app
/// and come back while HR verifies the code).
class PendingPasswordReset {
  final String requestId;
  final String token;
  final String code;
  final String email;
  final String name;
  final int expiresAt;

  const PendingPasswordReset({
    required this.requestId,
    required this.token,
    required this.code,
    required this.email,
    required this.name,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'token': token,
        'code': code,
        'email': email,
        'name': name,
        'expiresAt': expiresAt,
      };

  factory PendingPasswordReset.fromJson(Map<String, dynamic> j) => PendingPasswordReset(
        requestId: j['requestId'] as String,
        token: j['token'] as String,
        code: j['code'] as String,
        email: j['email'] as String,
        name: (j['name'] ?? '') as String,
        expiresAt: (j['expiresAt'] as num).toInt(),
      );
}

class PasswordResetException implements Exception {
  final String message;
  PasswordResetException(this.message);
  @override
  String toString() => message;
}

/// HR-verified password reset (see functions/index.js for the server side).
class PasswordResetService {
  static const _prefsKey = 'pending_password_reset';
  static FirebaseFunctions get _fn => FirebaseFunctions.instanceFor(region: 'asia-south1');

  static Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    try {
      final res = await _fn.httpsCallable(name).call<Map<String, dynamic>>(data);
      return Map<String, dynamic>.from(res.data);
    } on FirebaseFunctionsException catch (e) {
      throw PasswordResetException(e.message ?? 'Something went wrong. Please try again.');
    } catch (_) {
      throw PasswordResetException('Could not reach the server. Check your internet and try again.');
    }
  }

  /// Staff: start a reset and get the 5-character code to give HR.
  static Future<PendingPasswordReset> request(String email) async {
    final d = await _call('requestPasswordReset', {'email': email.trim()});
    final pending = PendingPasswordReset(
      requestId: d['requestId'] as String,
      token: d['token'] as String,
      code: d['code'] as String,
      email: email.trim().toLowerCase(),
      name: (d['name'] ?? '') as String,
      expiresAt: (d['expiresAt'] as num).toInt(),
    );
    await _save(pending);
    return pending;
  }

  /// Staff: 'pending', 'approved', 'completed', 'expired', 'locked' or 'cancelled'.
  static Future<String> status(PendingPasswordReset p) async {
    final d = await _call('getPasswordResetStatus', {'requestId': p.requestId, 'token': p.token});
    return (d['status'] ?? 'pending') as String;
  }

  /// Staff: set the new password once HR has approved.
  static Future<void> complete(PendingPasswordReset p, String newPassword) async {
    await _call('completePasswordReset', {
      'requestId': p.requestId,
      'token': p.token,
      'newPassword': newPassword,
    });
    await clearPending();
  }

  /// HR / CEO: approve a request with the code the staff member read out.
  static Future<String> hrVerify(String requestId, String code) async {
    final d = await _call('hrVerifyPasswordReset', {
      'requestId': requestId,
      'code': code.trim().toUpperCase(),
    });
    return (d['name'] ?? '') as String;
  }

  static Future<void> _save(PendingPasswordReset p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(p.toJson()));
    } catch (_) {}
  }

  static Future<PendingPasswordReset?> loadPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return null;
      final p = PendingPasswordReset.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return p;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearPending() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }
}
