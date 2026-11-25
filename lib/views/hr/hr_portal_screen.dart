import 'hr_password_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/employee_model.dart';
import '../../core/widgets/assign_tasks_to_others_modal.dart';
import '../../core/widgets/company_notification_sheet.dart';
import '../../core/widgets/export_audit_modal.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../core/widgets/role_app_bar.dart';
import '../../core/widgets/quick_pillar_nav_row.dart';
import '../../providers/ecosystem_provider.dart';
import '../auth/pillars_popup_dialog.dart';
import '../employee/employee_profile_screen.dart';
import 'hr_management_widgets.dart';
import 'hr_portal_subpages.dart';
import '../notes/personal_notes_screen.dart';
import '../chat/chat_hub_screen.dart';
import '../ceo/ceo_suite_screen.dart';
import '../../core/widgets/daily_pending_actions_dialog.dart';
import '../../core/widgets/birthday_celebration_dialog.dart';
import '../konar/konar_books_directory_screen.dart';
import '../../core/widgets/employee_avatar.dart';

class HrPortalScreen extends StatefulWidget {
  /// True when shown as a tab inside the main shell (start-up popups are
  /// handled by the shell instead).
  final bool embedded;
  const HrPortalScreen({super.key, this.embedded = false});

  @override
  State<HrPortalScreen> createState() => _HrPortalScreenState();
}

class _HrPortalScreenState extends State<HrPortalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || widget.embedded) return;
      final eco = context.read<EcosystemProvider>();
      // M N Naveenraaj is the Managing Director & CEO, strictly not HR.
      // If CEO credentials are active, seamlessly redirect to the Executive CEO Suite.
      if ((eco.activeEmpId == 'MN-CEO01' || eco.currentEmployee.isCeo || eco.currentEmployee.name.toLowerCase().contains('naveenraaj')) &&
          (eco.activeRole == 'ceo' || eco.isCeo)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CeoSuiteScreen()),
        );
        return;
      }
      context.read<EcosystemProvider>().setLoggedIn(true);
      await BirthdayCelebrationDialog.showIfNeeded(context);
      if (mounted) {
        await PillarsPopupDialog.show(context);
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 250));
          if (mounted) {
            await DailyPendingActionsDialog.showIfNeeded(context);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final isCeo = eco.currentEmployee.isCeo || eco.activeRole == 'ceo' || eco.activeEmpId == 'MN-CEO01' || eco.currentEmployee.name.toLowerCase().contains('naveenraaj');
    final hrEmp = eco.employees.firstWhere(
      (e) => (e.roleType == 'hr' || e.id == '7' || e.id == 'MN-HR1001' || e.name.toLowerCase().contains('mohankumar')) && !e.isCeo,
      orElse: () {
        if (eco.currentEmployee.isHr || eco.currentEmployee.id == '7' || eco.currentEmployee.name.toLowerCase().contains('mohankumar')) {
          return eco.currentEmployee;
        }
        return Employee(
          id: '7',
          empNo: '7',
          name: 'Mohankumar G',
          role: 'HR Manager & Operations Custodian',
          roleType: 'hr',
          dept: 'Administration',
          phone: '+91 94433 11000',
          email: 'hr@mnj.com',
          avatar: '',
          initials: 'MG',
          doj: '2021-03-10',
          experienceYears: '8 yrs in HR Management',
          experienceCategory: 'experienced',
          probationWeeks: 0,
          probationStatus: 'cleared',
          probationEndDate: 'Completed',
          status: 'active',
          ragStatus: 'green',
          lastActive: 'Active now',
          profileCompletion: ProfileCompletion(
            percentage: 100,
            isAuthorized: true,
            photoVerified: true,
            addressVerified: true,
            kycVerified: true,
            sopRolesAcknowledged: true,
          ),
        );
      },
    );

    final allEmployees = eco.employees;
    final totalStaff = allEmployees.length;
    final isTuesday = DateTime.now().weekday == DateTime.tuesday;
    final absentStaffCount = allEmployees.where((e) => eco.isEmployeeAbsent(e.id)).length;
    final weekOffStaffCount = isTuesday
        ? allEmployees.where((e) => !e.isExternalSupport && !e.isCeo && !eco.isEmployeeAbsent(e.id)).length
        : 0;
    final presentStaffCount = isTuesday ? 0 : (totalStaff - absentStaffCount);

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: RoleAppBar(
        roleName: isCeo ? 'CEO Suite' : 'HR Admin',
        userName: isCeo ? '${eco.currentEmployee.name} (CEO)' : '${hrEmp.name} (HR Admin)',
        roleColor: isCeo ? AppColors.sandGold : AppColors.ragGreen,
        roleIcon: isCeo ? Icons.workspace_premium_outlined : Icons.manage_accounts_outlined,
        onBellPressed: () => CompanyNotificationSheet.show(context),
        onExportPressed: () => ExportAuditModal.show(context),
      ),
      body: RefreshIndicator(
        color: AppColors.sandGold,
        backgroundColor: AppColors.burgundyCard,
        onRefresh: () => eco.refreshAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HR Executive Profile Card with Profile Navigation
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: LiquidGlassCard(
                  padding: const EdgeInsets.all(14),
                  borderRadius: 16,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.magentaGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.magentaPrimary.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: EmployeeAvatar(avatar: (isCeo ? eco.currentEmployee : hrEmp).avatar, initials: (isCeo ? eco.currentEmployee : hrEmp).initials, size: 48),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isCeo ? eco.currentEmployee.name : hrEmp.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isCeo ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isCeo ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
                                    ),
                                  ),
                                  child: Text(
                                    isCeo ? 'CEO' : 'HR ADMIN',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isCeo ? const Color(0xFFD97706) : const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isCeo ? eco.currentEmployee.role : hrEmp.role} • ID: ${isCeo ? eco.currentEmployee.id : hrEmp.id}',
                              style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Four Pillars Quick Nav Row (Health, Family, Attendance, Social Cause)
              const QuickPillarNavRow(forceAttendance: true),
              const SizedBox(height: 14),

              // HR Management Portals [Direct Access] - Moved right below Profile section
              Container(
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.apps_rounded, size: 16, color: AppColors.magentaPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'YOUR TOOLS',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Direct Access',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        // Team Chat is a bottom-bar tab inside the main shell.
                        if (!widget.embedded) ...[
                          _portalDirectAccessTile(
                            context: context,
                            label: 'Team Chat',
                            icon: Icons.chat_bubble_outline_rounded,
                            badge: eco.unreadTotalChatCount > 0 ? '${eco.unreadTotalChatCount}' : '',
                            destination: const ChatHubScreen(),
                          ),
                          const SizedBox(height: 8),
                        ],
                        _portalDirectAccessTile(
                          context: context,
                          label: 'KONAR Books',
                          icon: Icons.menu_book_rounded,
                          badge: '',
                          destination: const KonarBooksDirectoryScreen(),
                        ),
                        const SizedBox(height: 8),
                        _portalDirectAccessTile(
                          context: context,
                          label: 'Password Requests',
                          icon: Icons.lock_reset_rounded,
                          badge: '',
                          destination: const HrPasswordRequestsScreen(),
                        ),
                        const SizedBox(height: 8),
                        _portalDirectAccessTile(
                          context: context,
                          label: 'Staff Directory',
                          icon: Icons.badge_outlined,
                          badge: '$totalStaff',
                          destination: const HrStaffDirectoryScreen(),
                        ),
                        const SizedBox(height: 8),
                        _portalDirectAccessTile(
                          context: context,
                          label: 'Personal To-Dos',
                          icon: Icons.task_alt_outlined,
                          badge: '',
                          destination: const HrPersonalTodosScreen(),
                        ),
                        const SizedBox(height: 8),
                        _portalDirectAccessTile(
                          context: context,
                          label: 'Social Causes',
                          icon: Icons.volunteer_activism_outlined,
                          badge: eco.pendingSocialCauses.isNotEmpty ? '${eco.pendingSocialCauses.length}' : '',
                          destination: const HrSocialCausesScreen(),
                        ),
                        const SizedBox(height: 8),
                        _portalDirectAccessTile(
                          context: context,
                          label: 'Staff Tasks',
                          icon: Icons.assignment_outlined,
                          badge: '',
                          destination: const HrStaffTasksScreen(),
                        ),
                        const SizedBox(height: 8),
                        _portalDirectAccessTile(
                          context: context,
                          label: 'Blocker Tickets',
                          icon: Icons.shield_outlined,
                          badge: '',
                          destination: const HrBlockerTicketsScreen(),
                        ),
                        const SizedBox(height: 8),
                        _portalDirectAccessTile(
                          context: context,
                          label: 'Attendance',
                          icon: Icons.schedule_outlined,
                          badge: '',
                          destination: const HrAttendanceScreen(),
                        ),
                        const SizedBox(height: 8),
                        _portalDirectAccessTile(
                          context: context,
                          label: 'Grooming Audit',
                          icon: Icons.dry_cleaning_outlined,
                          badge: '',
                          destination: const HrGroomingAuditScreen(),
                        ),
                        const SizedBox(height: 8),
                        _portalDirectAccessTile(
                          context: context,
                          label: 'Personal Notes',
                          icon: Icons.lock_outline_rounded,
                          badge: 'Private',
                          destination: const PersonalNotesScreen(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // HR Header & Quick Actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Workforce & Credentials Management',
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Staff Directory & Credentials',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  LiquidGlassButton(
                    label: 'New Hire',
                    icon: Icons.person_add_alt_1,
                    height: 34,
                    onPressed: () => HrStaffDirectoryScreen.openAddHireDialog(context, eco),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4 Stat Tiles in Burgundy & Sand (Guaranteed Tally: Present + Absent == Total Staff)
              Row(
                children: [
                  LiquidMetricCard(
                    label: 'Total Staff',
                    value: '$totalStaff',
                    subtitle: 'Total Directory',
                    icon: Icons.groups_outlined,
                    color: AppColors.sandGold,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HrStaffDirectoryScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  LiquidMetricCard(
                    label: isTuesday ? 'Week-off' : 'Present',
                    value: isTuesday ? '$weekOffStaffCount' : '$presentStaffCount',
                    subtitle: isTuesday ? 'Tuesday Week-off' : 'Active Today',
                    icon: isTuesday ? Icons.weekend_outlined : Icons.badge_outlined,
                    color: isTuesday ? const Color(0xFF94A3B8) : AppColors.sandPrimary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HrAttendanceScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  LiquidMetricCard(
                    label: 'Absent Staff',
                    value: '$absentStaffCount',
                    subtitle: isTuesday ? 'Leave / Absent' : 'Absent Today',
                    icon: Icons.person_off_outlined,
                    color: absentStaffCount == 0 ? AppColors.ragGreen : AppColors.ragRed,
                    onTap: () => AssignTasksToOthersModal.show(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Assign Tasks to Others Primary Action Button
              LiquidGlassButton(
                label: isTuesday
                    ? 'Assign Tasks to Others (Tuesday Week-off)'
                    : 'Assign Tasks to Others ($absentStaffCount Absent)',
                icon: Icons.assignment_ind_outlined,
                height: 40,
                onPressed: () => AssignTasksToOthersModal.show(context),
              ),
              const SizedBox(height: 16),

              // HR Management Broadcast & To-Do Reminder Dispatcher (Positioned at end)
              HrBroadcastSection(
                senderName: '${eco.currentEmployee.name} (HR)',
                senderRole: 'HR Manager & Custodian',
              ),
              const SizedBox(height: 16),

              // Logout Button with confirmation
              LogoutConfirmDialog.buildButton(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _portalDirectAccessTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required String badge,
    required Widget destination,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.magentaSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 16,
                  color: AppColors.magentaPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: AppColors.magentaPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
