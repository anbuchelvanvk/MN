import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/employee/employee_profile_screen.dart';
import 'package:mn_family_app/views/pillars/health_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/family_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/attendance_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/social_cause_pillar_screen.dart';

class QuickPillarNavRow extends StatelessWidget {
  final bool forceAttendance;

  const QuickPillarNavRow({
    super.key,
    this.forceAttendance = false,
  });

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final showAttendance = forceAttendance || eco.currentEmployee.hasAttendanceAndGrooming;

    return Row(
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
        const SizedBox(width: 6),
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
        const SizedBox(width: 6),
        Expanded(
          child: _PillarItem(
            title: showAttendance ? 'Attendance' : 'Profile',
            icon: showAttendance ? Icons.fingerprint_rounded : Icons.person_rounded,
            primaryColor: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => showAttendance
                      ? const AttendancePillarScreen()
                      : const EmployeeProfileScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 6),
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: primaryColor.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: primaryColor),
              const SizedBox(height: 3),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

