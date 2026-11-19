import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/pillars/profile_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/health_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/family_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/social_cause_pillar_screen.dart';
import 'celebration_marquee_banner.dart';

class QuickPillarNavRow extends StatelessWidget {
  final bool forceAttendance;

  const QuickPillarNavRow({
    super.key,
    this.forceAttendance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EcosystemProvider>(
      builder: (context, eco, _) {
        return Column(
          children: [
            const CelebrationMarqueeBanner(),
            // Row 1: Health & Family
            Row(
              children: [
                Expanded(
                  child: _PillarItem(
                    title: 'Health',
                    icon: Icons.favorite_rounded,
                    primaryColor: const Color(0xFFE11D48),
                    bgColor: const Color(0xFFFFF1F2),
                    badgeCount: eco.healthPillarBadgeCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HealthPillarScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PillarItem(
                    title: 'Family',
                    icon: Icons.family_restroom_rounded,
                    primaryColor: const Color(0xFF7C3AED),
                    bgColor: const Color(0xFFF5F3FF),
                    badgeCount: eco.familyPillarBadgeCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FamilyPillarScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Work & Social Cause
            Row(
              children: [
                Expanded(
                  child: _PillarItem(
                    title: 'Work',
                    icon: Icons.work_outline_rounded,
                    primaryColor: const Color(0xFFD97706),
                    bgColor: const Color(0xFFFFFBEB),
                    badgeCount: eco.workPillarBadgeCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfilePillarScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PillarItem(
                    title: 'Social Cause',
                    icon: Icons.volunteer_activism_rounded,
                    primaryColor: const Color(0xFF059669),
                    bgColor: const Color(0xFFECFDF5),
                    badgeCount: eco.socialCausePillarBadgeCount,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SocialCausePillarScreen(isStandalone: true)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PillarItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primaryColor;
  final Color bgColor;
  final int badgeCount;
  final VoidCallback onTap;

  const _PillarItem({
    required this.title,
    required this.icon,
    required this.primaryColor,
    required this.bgColor,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 9),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: primaryColor),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: primaryColor.withOpacity(0.55),
                  ),
                ],
              ),
            ),

            // Numbering notification badge in corner
            if (badgeCount > 0)
              Positioned(
                top: -5,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withOpacity(0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


