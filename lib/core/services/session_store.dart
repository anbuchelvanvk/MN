import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A signed-in session that can be restored on app start.
class RestoredSession {
  final String empId;
  final String role; // 'ceo' | 'hr' | 'dept_head' | 'employee'
  final String email;
  const RestoredSession({required this.empId, required this.role, required this.email});
}

/// Keeps the user signed in across app restarts (including after the app is
/// swiped away from Recents). Only an explicit Logout clears the session.
class SessionStore {
  static const _kEmpId = 'saved_emp_id';
  static const _kRole = 'saved_role';
  static const _kEmail = 'saved_email';
  static const _kCredEmail = 'mn_cred_email';
  static const _kCredPass = 'mn_cred_pass';

  // Encrypted with the Android Keystore / iOS Keychain. Used only to sign the
  // person back in silently if Firebase ever loses its own session.
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static Future<void> save({
    required String empId,
    required String role,
    required String email,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEmpId, empId);
    await prefs.setString(_kRole, role);
    await prefs.setString(_kEmail, email);
    if (password != null && password.isNotEmpty) {
      try {
        await _secure.write(key: _kCredEmail, value: email.trim().toLowerCase());
        await _secure.write(key: _kCredPass, value: password);
      } catch (e) {
        debugPrint('Secure credential save note: $e');
      }
    }
  }

  /// Called only by the Logout action (and when the saved password is rejected).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kEmpId);
    await prefs.remove(_kRole);
    await prefs.remove(_kEmail);
    try {
      await _secure.delete(key: _kCredEmail);
      await _secure.delete(key: _kCredPass);
    } catch (_) {}
  }

  /// Signs back in with the stored credentials. Returns true on success,
  /// false if the password was rejected, null if it could not be checked
  /// (offline, nothing stored, ...).
  static Future<bool?> _silentSignIn() async {
    try {
      final email = await _secure.read(key: _kCredEmail);
      final pass = await _secure.read(key: _kCredPass);
      if (email == null || pass == null || email.isEmpty || pass.isEmpty) return null;
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass)
          .timeout(const Duration(seconds: 10));
      return true;
    } on FirebaseAuthException catch (e) {
      const rejected = {'wrong-password', 'invalid-credential', 'user-disabled', 'user-not-found', 'invalid-email'};
      return rejected.contains(e.code) ? false : null;
    } catch (_) {
      return null;
    }
  }

  /// Waits for Firebase to restore the signed-in user. On a cold start the
  /// user can arrive a moment after launch, so reading `currentUser` once is
  /// not enough (that made the app look logged out after being closed).
  static Future<User?> waitForFirebaseUser({Duration timeout = const Duration(seconds: 6)}) async {
    try {
      final now = FirebaseAuth.instance.currentUser;
      if (now != null) return now;
      return await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null)
          .timeout(timeout, onTimeout: () => null);
    } catch (e) {
      debugPrint('Session restore: auth not available ($e)');
      return null;
    }
  }

  /// Restores the saved session if Firebase still has the user signed in.
  /// If the saved copy is missing (e.g. app data partly cleared), rebuilds it
  /// from the user's staff record.
  static Future<RestoredSession?> restore() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {}
    final savedEmpId = prefs?.getString(_kEmpId);
    final savedRole = prefs?.getString(_kRole);
    final savedEmail = prefs?.getString(_kEmail) ?? '';

    // Only wait for Firebase when there is a reason to expect a session.
    final user = (savedEmpId != null && savedEmpId.isNotEmpty)
        ? await waitForFirebaseUser()
        : await waitForFirebaseUser(timeout: const Duration(milliseconds: 1500));
    final hasSaved = savedEmpId != null && savedEmpId.isNotEmpty;
    if (user == null) {
      if (!hasSaved) return null;
      // Firebase did not bring the user back. Sign in again silently; only a
      // rejected password ends the session — never a slow phone or network.
      final ok = await _silentSignIn();
      if (ok == false) {
        await clear();
        return null;
      }
      return RestoredSession(
        empId: savedEmpId,
        role: savedRole ?? 'employee',
        email: savedEmail.toLowerCase(),
      );
    }

    final email = (user.email ?? savedEmail).toLowerCase();
    if (hasSaved) {
      return RestoredSession(
        empId: savedEmpId,
        role: savedRole ?? 'employee',
        email: email,
      );
    }

    // Signed in with Firebase but no saved copy: look the person up.
    if (email.isEmpty) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(email).get();
      final data = doc.data();
      if (data == null) return null;
      final empId = (data['empId'] ?? '').toString();
      if (empId.isEmpty) return null;
      final rawRole = (data['roleType'] ?? data['role'] ?? 'employee').toString().toLowerCase();
      final role = switch (rawRole) {
        'ceo' => 'ceo',
        'hr' => 'hr',
        'team_lead' || 'dept_head' => 'dept_head',
        _ => 'employee',
      };
      await save(empId: empId, role: role, email: email);
      return RestoredSession(empId: empId, role: role, email: email);
    } catch (e) {
      debugPrint('Session restore lookup note: $e');
      return null;
    }
  }
}
