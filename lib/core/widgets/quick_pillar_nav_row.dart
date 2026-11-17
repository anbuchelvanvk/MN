import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mn_family_app/views/pillars/profile_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/health_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/family_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/social_cause_pillar_screen.dart';

class QuickPillarNavRow extends StatelessWidget {
  final bool forceAttendance;

  const QuickPillarNavRow({
    super.key,
    this.forceAttendance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Health & Family
        Row(
          children: [
            Expanded(
              child: _PillarItem(
                title: 'Health',
                icon: Icons.favorite_rounded,
                primaryColor: const Color(0xFFE11D48),
                bgColor: const Color(0xFFFFF1F2),
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
  }
}

class _PillarItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primaryColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _PillarItem({
    required this.title,
    required this.icon,
    required this.primaryColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 17, color: primaryColor),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: primaryColor.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

