import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../models/profile_document_models.dart';
import 'package:provider/provider.dart';
import '../../providers/ecosystem_provider.dart';
import '../pillars/health_pillar_screen.dart';
import '../pillars/family_pillar_screen.dart';
import '../pillars/profile_pillar_screen.dart';
import '../pillars/attendance_pillar_screen.dart';
import '../pillars/tier_pillar_screen.dart';
import '../pillars/social_cause_pillar_screen.dart';

class PillarsPopupDialog extends StatelessWidget {
  const PillarsPopupDialog({super.key});

  static Future<void> show(BuildContext context) {
    final eco = Provider.of<EcosystemProvider>(context, listen: false);
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (ctx) => ChangeNotifierProvider<EcosystemProvider>.value(
        value: eco,
        child: const PillarsPopupDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: AppColors.burgundySurface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.sandGold.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.burgundyPrimary.withOpacity(0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.sandGold.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Monogram, Title & Close Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sandGold, width: 1.2),
                          color: AppColors.burgundyPrimary.withOpacity(0.4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.diamond_outlined,
                                color: AppColors.sandGold,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MN FAMILY PILLARS',
                              style: GoogleFonts.cinzel(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sandLight,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Vital Inputs & Operations',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.sandPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.burgundyPrimary.withOpacity(0.4),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.sandBorder),
                          ),
                          child: const Icon(Icons.close, size: 16, color: AppColors.sandLight),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.sandBorder, height: 1),
                  const SizedBox(height: 14),

                  Text(
                    'Select Pillar:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.sandLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5 Clickable Pillar Buttons in Burgundy & Sand
                  _pillarButton(
                    context: context,
                    title: 'Health',
                    subtitle: 'Health & Workout',
                    badgeText: 'Pillar 1',
                    badgeColor: AppColors.ragGreen,
                    icon: Icons.health_and_safety_outlined,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthPillarScreen()));
                    },
                  ),
                  const SizedBox(height: 10),

                  _pillarButton(
                    context: context,
                    title: 'Family',
                    subtitle: 'Family & Friends',
                    badgeText: 'Pillar 2',
                    badgeColor: const Color(0xFFA855F7),
                    icon: Icons.family_restroom,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyPillarScreen()));
                    },
                  ),
                  const SizedBox(height: 10),

                  _pillarButton(
                    context: context,
                    title: 'Profile',
                    subtitle: 'KYC & Vault',
                    badgeText: 'Pillar 3',
                    badgeColor: AppColors.sandGold,
                    icon: Icons.badge_outlined,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePillarScreen()));
                    },
                  ),
                  const SizedBox(height: 10),

                  _pillarButton(
                    context: context,
                    title: 'Attendance',
                    subtitle: 'Punch & Hours',
                    badgeText: 'Pillar 4',
                    badgeColor: const Color(0xFF10B981),
                    icon: Icons.fingerprint,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendancePillarScreen()));
                    },
                  ),
                  const SizedBox(height: 10),

                  _pillarButton(
                    context: context,
                    title: 'Social Cause',
                    subtitle: 'Community & Deeds',
                    badgeText: 'Pillar 5',
                    badgeColor: const Color(0xFFEF4444),
                    icon: Icons.volunteer_activism,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SocialCausePillarScreen()));
                    },
                  ),
                  const SizedBox(height: 14),

                  // SOVEREIGN GREEN LIGHT TIER RATING BANNER
                  Consumer<EcosystemProvider>(
                    builder: (ctx, eco, _) {
                      final tierColor = eco.holisticTierColor;
                      final tierName = eco.holisticTierName;
                      final isRed = eco.holisticTierLevel == PillarTierLevel.red;
                      final activeColor = isRed ? const Color(0xFFFF4D4D) : tierColor;
                      final textColor = isRed ? const Color(0xFFFFD2D2) : tierColor;

                      return Container(
                        decoration: BoxDecoration(
                          color: isRed ? const Color(0xFF1F080E) : AppColors.burgundyCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isRed ? const Color(0xFFFF4D4D) : activeColor.withOpacity(0.6),
                            width: 1.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isRed ? const Color(0xFFFF4D4D).withOpacity(0.35) : activeColor.withOpacity(0.2),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const TierPillarScreen()));
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isRed ? const Color(0xFFDC2626) : activeColor.withOpacity(0.22),
                                      border: Border.all(color: isRed ? Colors.white : activeColor, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isRed ? const Color(0xFFFF4D4D).withOpacity(0.5) : activeColor.withOpacity(0.4),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isRed ? Icons.priority_high : Icons.light_mode,
                                        color: isRed ? Colors.white : activeColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'YOUR STATUS',
                                                style: GoogleFonts.cinzel(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.sandLight,
                                                  letterSpacing: 0.5,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: isRed ? const Color(0xFFDC2626) : activeColor.withOpacity(0.25),
                                                borderRadius: BorderRadius.circular(5),
                                                border: Border.all(
                                                  color: isRed ? const Color(0xFFFF8585) : activeColor.withOpacity(0.7),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                isRed ? 'ACTION NEEDED' : 'STATUS',
                                                style: const TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          tierName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                            letterSpacing: 0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 13, color: AppColors.sandGold),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dismiss & Continue into Portal
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Continue to Enterprise Portal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                        ),
                      ),
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

  Widget _pillarButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: AppColors.sandGold.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.burgundyPrimary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.sandBorder.withOpacity(0.5)),
                  ),
                  child: Icon(icon, color: AppColors.sandGold, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sandLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: badgeColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 13,
                  color: AppColors.sandGold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
