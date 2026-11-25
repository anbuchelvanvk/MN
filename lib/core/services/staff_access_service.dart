import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

/// Server-side sign-in control (functions/index.js: disableStaffLogin).
class StaffAccessService {
  StaffAccessService._();

  /// Switches off a relieved staff member's sign-in and signs them out of
  /// every phone. HR or CEO only. Returns true when done.
  static Future<bool> disableLogin(String email) async {
    if (Firebase.apps.isEmpty) return false; // tests / not configured
    final res = await FirebaseFunctions.instanceFor(region: 'asia-south1')
        .httpsCallable('disableStaffLogin')
        .call<dynamic>({'email': email.trim().toLowerCase()});
    final data = res.data;
    return data is Map && data['ok'] == true;
  }
}
