import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../views/auth/login_screen.dart';

class LogoutConfirmDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 22),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Text(
          'Do you want to logout?',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              SessionManager.logout(context);
            },
            child: Text(
              'Logout',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16, bottom: 24),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFE11D48),
          side: const BorderSide(color: Color(0xFFFECDD3), width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: const Color(0xFFFFF1F4),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFE11D48)),
        label: Text(
          'Logout',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE11D48),
            letterSpacing: 0.5,
          ),
        ),
        onPressed: () => show(context),
      ),
    );
  }
}

