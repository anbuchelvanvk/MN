import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../../views/auth/login_screen.dart';

class LogoutConfirmDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.sandBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.sandGold, size: 22),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: GoogleFonts.cinzel(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.sandGold,
              ),
            ),
          ],
        ),
        content: Text(
          'Do you want to logout?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.sandLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'No',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              SessionManager.logout(context);
            },
            child: Text(
              'Yes',
              style: GoogleFonts.plusJakartaSans(
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
          foregroundColor: const Color(0xFFEF4444),
          side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.6), width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFFEF4444).withOpacity(0.08),
        ),
        icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
        label: Text(
          'Logout',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFEF4444),
            letterSpacing: 0.5,
          ),
        ),
        onPressed: () => show(context),
      ),
    );
  }
}

