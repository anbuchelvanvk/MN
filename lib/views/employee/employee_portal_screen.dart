import '../../core/widgets/logout_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/role_app_bar.dart';
import '../../providers/ecosystem_provider.dart';
import '../pillars/social_cause_pillar_screen.dart';
import '../../core/widgets/company_notification_sheet.dart';
import 'employee_profile_screen.dart';
import '../../core/widgets/daily_pending_actions_dialog.dart';
import '../../core/widgets/birthday_celebration_dialog.dart';
import '../home/modern_home_screen.dart';
import '../../core/widgets/employee_avatar.dart';

class EmployeePortalScreen extends StatefulWidget {
  const EmployeePortalScreen({super.key});

  @override
  State<EmployeePortalScreen> createState() => _EmployeePortalScreenState();
}

class _EmployeePortalScreenState extends State<EmployeePortalScreen> {
  int _activeBottomNav = 0; // 0: Home, 1: Social Cause, 2: ID Vault

  @override
  void initState() {
    super.initState();
    // Display the 4-button closable popup once the user is logged in, followed by pending actions floating dialog
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        context.read<EcosystemProvider>().setLoggedIn(true);
        await BirthdayCelebrationDialog.showIfNeeded(context);
        if (mounted) {
          if (mounted) {
            if (mounted) {
              await DailyPendingActionsDialog.showIfNeeded(context);
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final emp = eco.currentEmployee;

    return Scaffold(
      backgroundColor: _activeBottomNav == 0 ? const Color(0xFFFBF8FA) : AppColors.burgundyBg,
      appBar: _activeBottomNav == 0
          ? null
          : RoleAppBar(
              roleName: 'Employee',
              userName: '${emp.name} (${emp.straightCutRole})',
              roleColor: AppColors.goldPrimary,
              roleIcon: Icons.person_outline,
              onBellPressed: () => CompanyNotificationSheet.show(context),
            ),
      body: IndexedStack(
        index: _activeBottomNav,
        children: [
          // Screen 0: Home Dashboard
          const ModernHomeScreen(isEmbedded: true),

          // Screen 1: Social Cause (Pillar 5)
          const SocialCausePillarScreen(isStandalone: false),

          // Screen 2: Digital Vault & Profile Audit
          _buildProfileVaultScreen(context, eco, emp),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNav(context),
    );
  }

  Widget _buildGlassBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.burgundySurface,
        border: Border(
          top: BorderSide(
            color: AppColors.sandBorder,
            width: 1.2,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _navItem(0, Icons.dashboard_outlined, 'Home')),
              Expanded(child: _navItem(1, Icons.volunteer_activism_outlined, 'Social Service')),
              Expanded(child: _navItem(2, Icons.badge_outlined, 'ID Vault')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _activeBottomNav == index;
    return InkWell(
      onTap: () => setState(() => _activeBottomNav = index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.magentaSubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.magentaPrimary : AppColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.magentaPrimary : AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileVaultScreen(
    BuildContext context,
    EcosystemProvider eco,
    dynamic emp,
  ) {
    return RefreshIndicator(
      color: AppColors.sandGold,
      backgroundColor: AppColors.burgundyCard,
      onRefresh: () => eco.refreshAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Digital Smart ID Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.magentaPrimary.withOpacity(0.35), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.magentaPrimary),
                            color: Colors.black,
                          ),
                          child: ClipOval(
                            child: Image.asset('assets/images/mnjlogo.jpg', fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'MN JEWEL PARK',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'STAFF SMART ID',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary, letterSpacing: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    EmployeeAvatar(avatar: emp.avatar, initials: emp.initials, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          Text(emp.role, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('EMP ID: ${emp.id}', style: const TextStyle(fontSize: 11, color: AppColors.magentaPrimary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.sandBorder, height: 1),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    Text('Dept: ${emp.dept}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    Text('DOJ: ${emp.doj.isNotEmpty ? emp.doj : '-'}', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                    Builder(builder: (_) {
                      final verified = emp.profileCompletion.kycVerified && emp.profileCompletion.photoVerified;
                      return Text(
                        verified ? 'Status: VERIFIED' : 'Status: PENDING VERIFICATION',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: verified ? AppColors.ragGreen : AppColors.ragYellow,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Personal Profile & Password Actions Card
          LiquidGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.manage_accounts_outlined, color: AppColors.magentaPrimary, size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Personal Details & Security',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    LiquidGlassPill(label: 'CONFIDENTIAL', color: AppColors.magentaPrimary),
                  ],
                ),
                const SizedBox(height: 12),
                _personalInfoRow('Mobile Phone', emp.phone.isNotEmpty ? emp.phone : 'Not added'),
                _personalInfoRow('Official Email', emp.email),
                _personalInfoRow('Date of Birth (DOB)', emp.dob.isNotEmpty ? emp.dob : 'Not added'),
                _personalInfoRow('Relationship', emp.relationshipStatus.isNotEmpty ? emp.relationshipStatus : 'Single'),
                if (emp.relationshipStatus == 'Married')
                  _personalInfoRow('Anniversary Date', emp.anniversaryDate.isNotEmpty ? emp.anniversaryDate : 'Not added'),
                const SizedBox(height: 14),
                LiquidGlassButton(
                  label: 'Edit Profile & Change Password',
                  icon: Icons.edit_note,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Profile Clearance Checklist Card
          LiquidGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enterprise Compliance & KYC Checklist',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                _clearanceRow('1. Biometric Photo Identity', emp.profileCompletion.photoVerified),
                _clearanceRow('2. Residential Address Proof & Aadhaar', emp.profileCompletion.addressVerified),
                _clearanceRow('3. Government Tax KYC & PAN Card', emp.profileCompletion.kycVerified),
                _clearanceRow('4. Daily SOP Role Responsibilities Signed', emp.profileCompletion.sopRolesAcknowledged),
                const SizedBox(height: 12),
                LiquidGlassButton(
                  label: 'Update Clearance Status',
                  icon: Icons.edit_note,
                  onPressed: () => _openProfileWizard(context, eco, emp),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Logout Button with confirmation
          LogoutConfirmDialog.buildButton(context),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

  Widget _personalInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clearanceRow(String title, bool verified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ),
          const SizedBox(width: 8),
          Icon(
            verified ? Icons.check_circle : Icons.cancel_outlined,
            size: 16,
            color: verified ? AppColors.ragGreen : AppColors.ragRed,
          ),
        ],
      ),
    );
  }

  void _openProfileWizard(BuildContext context, EcosystemProvider eco, dynamic emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final pc = emp.profileCompletion;
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Profile Verification Wizard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  Text('Progress: ${pc.percentage}% • ${pc.isAuthorized ? "VERIFIED" : "ACTION REQUIRED"}', style: const TextStyle(fontSize: 11.5, color: AppColors.magentaPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Material(type: MaterialType.transparency, child: CheckboxListTile(
                    title: const Text('1. Photo Identity Verified', style: TextStyle(color: AppColors.textDark, fontSize: 12.5)),
                    subtitle: const Text('Biometric pass verified', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                    value: pc.photoVerified,
                    activeColor: AppColors.magentaPrimary,
                    onChanged: (v) {
                      eco.verifyProfileStep(emp.id, photo: v);
                      setModalState(() {});
                    },
                  )),
                  Material(type: MaterialType.transparency, child: CheckboxListTile(
                    title: const Text('2. Residential Address Proof', style: TextStyle(color: AppColors.textDark, fontSize: 12.5)),
                    subtitle: const Text('Utility bill & Aadhaar copy verified', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                    value: pc.addressVerified,
                    activeColor: AppColors.magentaPrimary,
                    onChanged: (v) {
                      eco.verifyProfileStep(emp.id, address: v);
                      setModalState(() {});
                    },
                  )),
                  Material(type: MaterialType.transparency, child: CheckboxListTile(
                    title: const Text('3. Government Tax KYC & PAN Card', style: TextStyle(color: AppColors.textDark, fontSize: 12.5)),
                    subtitle: const Text('PAN linked to payroll portal', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                    value: pc.kycVerified,
                    activeColor: AppColors.magentaPrimary,
                    onChanged: (v) {
                      eco.verifyProfileStep(emp.id, kyc: v);
                      setModalState(() {});
                    },
                  )),
                  Material(type: MaterialType.transparency, child: CheckboxListTile(
                    title: const Text('4. Predefined Daily SOP Responsibilities', style: TextStyle(color: AppColors.textDark, fontSize: 12.5)),
                    subtitle: const Text('Digitally signed and acknowledged', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
                    value: pc.sopRolesAcknowledged,
                    activeColor: AppColors.magentaPrimary,
                    onChanged: (v) {
                      eco.verifyProfileStep(emp.id, sop: v);
                      setModalState(() {});
                    },
                  )),
                  const SizedBox(height: 14),
                  LiquidGlassButton(
                    label: 'Save & Close Wizard',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

}
