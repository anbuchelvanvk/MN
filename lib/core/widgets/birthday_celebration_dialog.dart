import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../../models/company_notification_models.dart';
import '../../providers/ecosystem_provider.dart';

/// Floating Celebration Modal displayed exclusively for the employee celebrating
/// their Birthday or Wedding Anniversary today.
/// Displays immediately on app launch BEFORE the 4-Pillars dialog, strictly ONCE per day.
class BirthdayCelebrationDialog extends StatelessWidget {
  final CelebrationEvent event;

  const BirthdayCelebrationDialog({super.key, required this.event});

  static bool _isShowing = false;

  /// Evaluates whether the currently logged-in user is celebrating their Birthday or Anniversary today,
  /// and displays the celebration popup ONCE per day inside THEIR account before any other dialogs.
  /// Strictly blocked before login and blocked for non-celebrating users.
  static Future<void> showIfNeeded(BuildContext context) async {
    if (_isShowing) return;
    final eco = Provider.of<EcosystemProvider>(context, listen: false);

    // 1. Strictly enforce: User must be authenticated and logged into their account
    if (!eco.isLoggedIn) return;

    final now = DateTime.now();

    // 2. Check if the currently logged-in workforce member matches the celebrating person
    final currentEmp = eco.currentEmployee;
    final activeId = eco.activeEmpId.trim().toLowerCase();
    final activeName = currentEmp.name.trim().toLowerCase();

    // If active employee name or id is empty, do not trigger
    if (activeId.isEmpty && activeName.isEmpty) return;

    final myCelebration = eco.todayCelebrations.where((c) {
      final celebEmpId = c.employeeId.trim().toLowerCase();
      final celebName = c.employeeName.trim().toLowerCase();

      // Direct Employee ID match (e.g. MN-CEO01, MN-TL1002, etc.)
      if (activeId.isNotEmpty &&
          celebEmpId.isNotEmpty &&
          activeId == celebEmpId) {
        return true;
      }

      // Direct Name match between currently logged in user and celebrant
      if (activeName.isNotEmpty && celebName.isNotEmpty) {
        if (activeName == celebName) return true;
        // Substring matching for multi-word names (e.g. "M N Naveenraaj" contains "naveenraaj")
        final activeParts = activeName
            .split(RegExp(r'[\s._-]+'))
            .where((p) => p.length >= 3);
        final celebParts = celebName
            .split(RegExp(r'[\s._-]+'))
            .where((p) => p.length >= 3);
        for (final ap in activeParts) {
          for (final cp in celebParts) {
            if (ap == cp) return true;
          }
        }
      }

      return false;
    }).toList();

    // 3. If the logged-in user is NOT the celebrating person, exit immediately (no popup for others)
    if (myCelebration.isEmpty) return;

    final event = myCelebration.first;
    final todayStr = '${now.year}_${now.month}_${now.day}';
    final storageKey =
        'celebration_modal_shown_${eco.activeEmpId}_${event.type}_$todayStr';

    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyShown = prefs.getBool(storageKey) ?? false;
      if (alreadyShown) return;

      if (!context.mounted) return;

      _isShowing = true;
      await showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.75),
        builder: (ctx) => BirthdayCelebrationDialog(event: event),
      );

      // Mark as shown for today so it is omitted for the rest of the day
      await prefs.setBool(storageKey, true);
    } catch (e) {
      debugPrint('Celebration modal preference error: $e');
    } finally {
      _isShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBirthday = event.type == 'birthday';
    final title = isBirthday ? 'Happy Birthday!' : 'Happy Wedding Anniversary!';
    final greeting = isBirthday
        ? '🎉 Wishing You A Wonderful Birthday! 🎂'
        : '💍 Wishing You A Joyful Anniversary! 💐';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBEB), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Festive Header Ribbon
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF831843),
                          Color(0xFFBE185D),
                          Color(0xFFB45309),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(26),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Animated Icon Badge
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Text(
                            isBirthday ? '🎂' : '💐',
                            style: const TextStyle(fontSize: 38),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFDE68A),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.employeeName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Greeting Content Body
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        Text(
                          greeting,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9D174D),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            isBirthday
                                ? 'May this milestone year bring you robust health, great joy, endless prosperity, and continued achievements across your life and career with the MN Jewel Park family! 🌟'
                                : 'May your shared journey be blessed with everlasting love, happiness, peace, and mutual prosperity throughout the years ahead! 💐',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF78350F),
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Warmest wishes from the entire MN Jewel Park Executive Board & Workforce.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Thank You Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.magentaPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Thank You! 🎊',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
