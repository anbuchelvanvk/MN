import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
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

class HrPortalScreen extends StatefulWidget {
  const HrPortalScreen({super.key});

  @override
  State<HrPortalScreen> createState() => _HrPortalScreenState();
}

class _HrPortalScreenState extends State<HrPortalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PillarsPopupDialog.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final allEmployees = eco.employees;
    final delegations = eco.delegations;

    final totalStaff = allEmployees.length;
    final absentStaffCount = allEmployees.where((e) => eco.isEmployeeAbsent(e.id)).length;
    final presentStaffCount = totalStaff - absentStaffCount;
    final leaveReqCount = eco.allPendingPermissions.length + eco.allPendingMedicalLeaves.length;

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: RoleAppBar(
        roleName: 'HR Admin',
        userName: '${eco.currentEmployee.name} (HR Admin)',
        roleColor: AppColors.ragGreen,
        roleIcon: Icons.manage_accounts_outlined,
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
                        child: Center(
                          child: Text(
                            eco.currentEmployee.initials.isNotEmpty ? eco.currentEmployee.initials : 'MG',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.white,
                            ),
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
                                Expanded(
                                  child: Text(
                                    eco.currentEmployee.name,
                                    style: GoogleFonts.plusJakartaSans(
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
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Text(
                                    'HR ADMIN',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${eco.currentEmployee.role} • ID: ${eco.currentEmployee.id}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
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
                            'HR MANAGEMENT PORTALS',
                            style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
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
                          label: 'Leaves & Permissions',
                          icon: Icons.beach_access_outlined,
                          badge: delegations.isNotEmpty ? '${delegations.length}' : '',
                          destination: const HrLeavesPermissionsScreen(),
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Staff Directory & Credentials',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
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
                  const SizedBox(width: 6),
                  LiquidMetricCard(
                    label: 'Present',
                    value: '$presentStaffCount',
                    subtitle: 'Active Today',
                    icon: Icons.badge_outlined,
                    color: AppColors.sandPrimary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HrAttendanceScreen()),
                    ),
                  ),
                  const SizedBox(width: 6),
                  LiquidMetricCard(
                    label: 'Leave Req',
                    value: '$leaveReqCount',
                    subtitle: 'Pending Review',
                    icon: Icons.time_to_leave_outlined,
                    color: AppColors.sandLight,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HrLeavesPermissionsScreen()),
                    ),
                  ),
                  const SizedBox(width: 6),
                  LiquidMetricCard(
                    label: 'Absent Staff',
                    value: '$absentStaffCount',
                    subtitle: 'Absent Today',
                    icon: Icons.person_off_outlined,
                    color: absentStaffCount == 0 ? AppColors.ragGreen : AppColors.ragRed,
                    onTap: () => AssignTasksToOthersModal.show(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Assign Tasks to Others Primary Action Button
              LiquidGlassButton(
                label: 'Assign Tasks to Others ($absentStaffCount Absent)',
                icon: Icons.assignment_ind_outlined,
                height: 40,
                onPressed: () => AssignTasksToOthersModal.show(context),
              ),
              const SizedBox(height: 16),

              // HR Management Broadcast & To-Do Reminder Dispatcher (Positioned at end)
              const HrBroadcastSection(
                senderName: 'Mohankumar G (HR)',
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
                  style: GoogleFonts.plusJakartaSans(
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
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
