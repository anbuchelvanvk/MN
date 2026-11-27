import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ecosystem_provider.dart';
import '../../views/pillars/health_pillar_screen.dart';
import '../../views/pillars/family_pillar_screen.dart';
import '../../views/pillars/profile_pillar_screen.dart';
import '../../views/pillars/social_cause_pillar_screen.dart';

class DailyPendingActionsDialog extends StatelessWidget {
  const DailyPendingActionsDialog({super.key});

  /// Allows unit/widget tests to selectively enable auto dialog display
  static bool enableAutoShowInTests = false;

  /// Evaluates pending daily priorities and shows the floating attention dialog if any are pending
  static Future<void> showIfNeeded(BuildContext context) async {
    final bool isTestMode = WidgetsBinding.instance.runtimeType.toString().toLowerCase().contains('test');
    if (isTestMode && !enableAutoShowInTests) {
      return;
    }

    final eco = Provider.of<EcosystemProvider>(context, listen: false);

    final bool hasHealthPending = !eco.isHealthLoggedToday;
    final bool hasFamilyPending = !eco.isFamilyLoggedToday;
    final bool hasWorkPending = eco.todayPendingTodosCount > 0;
    final bool hasSocialPending = (eco.isCeo || eco.isHr) && eco.pendingSocialCausesCount > 0;

    if (hasHealthPending || hasFamilyPending || hasWorkPending || hasSocialPending) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.65),
        builder: (ctx) => ChangeNotifierProvider<EcosystemProvider>.value(
          value: eco,
          child: const DailyPendingActionsDialog(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();

    final bool hasHealthPending = !eco.isHealthLoggedToday;
    final bool hasFamilyPending = !eco.isFamilyLoggedToday;
    final bool hasWorkPending = eco.todayPendingTodosCount > 0;
    final bool hasSocialPending = (eco.isCeo || eco.isHr) && eco.pendingSocialCausesCount > 0;

    final totalPending = (hasHealthPending ? 1 : 0) +
        (hasFamilyPending ? 1 : 0) +
        (hasWorkPending ? 1 : 0) +
        (hasSocialPending ? 1 : 0);

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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Attention Badge & Close Icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: const Icon(
                          Icons.notification_important_rounded,
                          size: 20,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Attention Required',
                              style: GoogleFonts.outfit(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '$totalPending pending item${totalPending > 1 ? 's' : ''} need your action today',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 14),

                  // 1. Health Pillar Alert (Everyone including CEO & HR)
                  if (hasHealthPending) ...[
                    _buildPriorityCard(
                      context: context,
                      icon: Icons.favorite_rounded,
                      title: 'Health Log Pending',
                      subtitle: 'Calorie, hydration, steps, or workout check-in has not been recorded today.',
                      badgeText: 'Health Pillar Commitment',
                      primaryColor: const Color(0xFFE11D48),
                      bgColor: const Color(0xFFFFF1F4),
                      actionLabel: 'Log Health',
                      onAction: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HealthPillarScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 2. Family Pillar Alert (Everyone including CEO & HR)
                  if (hasFamilyPending) ...[
                    _buildPriorityCard(
                      context: context,
                      icon: Icons.family_restroom_rounded,
                      title: 'Family Moment Pending',
                      subtitle: 'Quality family time or milestone has not been logged for today.',
                      badgeText: 'Family Pillar Commitment',
                      primaryColor: const Color(0xFFBE185D),
                      bgColor: const Color(0xFFFFF3F7),
                      actionLabel: 'Log Family',
                      onAction: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FamilyPillarScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 3. Work Daily To-Dos Alert (Incomplete tasks for today)
                  if (hasWorkPending) ...[
                    _buildPriorityCard(
                      context: context,
                      icon: Icons.work_outline_rounded,
                      title: '${eco.todayPendingTodosCount} Incomplete Daily To-Dos',
                      subtitle: 'You have ${eco.todayPendingTodosCount} operational tasks scheduled for today that remain incomplete.',
                      badgeText: 'Work Pillar Commitment',
                      primaryColor: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFFBEB),
                      actionLabel: 'View Tasks',
                      onAction: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfilePillarScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // 4. Social Cause Review Alert (HR & CEO alone)
                  if (hasSocialPending) ...[
                    _buildPriorityCard(
                      context: context,
                      icon: Icons.volunteer_activism_rounded,
                      title: '${eco.pendingSocialCausesCount} Social Services Awaiting Review',
                      subtitle: 'Staff social deed submissions require executive approval (Accept or Reject).',
                      badgeText: 'Executive Action',
                      primaryColor: const Color(0xFF059669),
                      bgColor: const Color(0xFFECFDF5),
                      actionLabel: 'Review Deeds',
                      onAction: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SocialCausePillarScreen(isStandalone: true)),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  const SizedBox(height: 8),
                  // Primary Dismiss Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.magentaPrimary,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'I Will Update Now',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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

  Widget _buildPriorityCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color primaryColor,
    required Color bgColor,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withOpacity(0.25), width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: primaryColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
