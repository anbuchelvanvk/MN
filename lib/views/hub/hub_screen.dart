import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/live_gold_ticker.dart';
import '../../providers/ecosystem_provider.dart';
import '../employee/employee_portal_screen.dart';
import '../dept_head/dept_head_portal_screen.dart';
import '../hr/hr_portal_screen.dart';
import '../ceo/ceo_suite_screen.dart';
import '../auth/pillars_popup_dialog.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header with Brand Monogram
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.sandPrimary,
                          width: 1.5,
                        ),
                        color: Colors.black,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.burgundyPrimary.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.diamond_outlined,
                            color: AppColors.burgundyPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'MN JEWEL PARK',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Internal Operations Nerve Center & Executive Management Hub.\nDynamic probation rules, daily SOP proof audits & enterprise clearance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Live Gold Ticker
              const LiveGoldTicker(),
              const SizedBox(height: 12),

              // 4 Operational Pillars Quick Launch Banner
              GestureDetector(
                onTap: () => PillarsPopupDialog.show(context),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.burgundyPrimary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.burgundyPrimary.withOpacity(0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.sandPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.widgets_outlined, color: AppColors.sandPrimary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '4 Operational Pillars',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tap to open: Health, Family, Work, Profile inputs',
                              style: TextStyle(fontSize: 10.5, color: AppColors.sandLight),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.sandPrimary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3 Highlights Grid
              Row(
                children: [
                  _highlightCard(
                    icon: Icons.timer_outlined,
                    title: 'Probation Rules',
                    desc: '3+ Yrs Exp = 2 Wks; Fresher = 1 Mo (4 Wks). Mentor diary.',
                  ),
                  const SizedBox(width: 8),
                  _highlightCard(
                    icon: Icons.verified_outlined,
                    title: 'SOP Proofs',
                    desc: 'Photo verification or logged postpone reasons for review.',
                  ),
                  const SizedBox(width: 8),
                  _highlightCard(
                    icon: Icons.shield_outlined,
                    title: 'Role Hierarchy',
                    desc: 'CEO Directives, Dept Lead monitor & HR task coverage.',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4 Role Portals Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'ENTERPRISE PORTALS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: AppColors.burgundyPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // 1. Employee Portal
              _roleCard(
                context: context,
                title: 'Employee Portal',
                subtitle: 'Daily SOP "Things To Do", photo proof uploads, postpone reason logging, 100% profile authorization & training diary.',
                roleTag: 'Employee',
                roleColor: AppColors.burgundyPrimary,
                icon: Icons.person_outline,
                onTap: () {
                  eco.setActiveRole('employee');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployeePortalScreen()),
                  );
                },
              ),

              // 2. Dept Head Portal
              _roleCard(
                context: context,
                title: 'Department Head Portal',
                subtitle: 'Team deliverables monitor, attached proof review, staff postponement audit, mentor sign-offs & team nudges.',
                roleTag: 'Dept Head',
                roleColor: AppColors.statusBlue,
                icon: Icons.shield_outlined,
                onTap: () {
                  eco.setActiveRole('dept_head');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DeptHeadPortalScreen()),
                  );
                },
              ),

              // 3. HR Admin Portal
              _roleCard(
                context: context,
                title: 'HR Management Portal',
                subtitle: 'Dynamic probation setup (2 wks vs 1 mo), mentor allocation, emergency leave task delegation hub & staff clearance.',
                roleTag: 'HR Admin',
                roleColor: AppColors.ragGreen,
                icon: Icons.manage_accounts_outlined,
                onTap: () {
                  eco.setActiveRole('hr');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HrPortalScreen()),
                  );
                },
              ),

              // 4. CEO Suite
              _roleCard(
                context: context,
                title: 'Executive CEO Suite',
                subtitle: 'Cross-department universal task dispatch, 10:00 AM store opening readiness gate, delay root cause analytics & audit export.',
                roleTag: 'CEO Suite',
                roleColor: AppColors.sandGold,
                icon: Icons.workspace_premium_outlined,
                onTap: () {
                  eco.setActiveRole('ceo');
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CeoSuiteScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _highlightCard({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Expanded(
      child: LiquidGlassCard(
        padding: const EdgeInsets.all(10),
        borderRadius: 14,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.burgundyPrimary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textMuted,
                height: 1.3,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String roleTag,
    required Color roleColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return LiquidGlassCard(
      onTap: onTap,
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: roleColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: roleColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: roleColor, size: 18),
              ),
              LiquidGlassPill(
                label: roleTag,
                color: roleColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Open Portal',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: roleColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 13, color: roleColor),
            ],
          ),
        ],
      ),
    );
  }
}
