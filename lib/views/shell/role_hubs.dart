import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/assign_tasks_to_others_modal.dart';
import '../../core/widgets/export_audit_modal.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../../providers/ecosystem_provider.dart';
import '../ceo/admin_role_access_management_screen.dart';
import '../ceo/ceo_subpages.dart';
import '../ceo/ceo_suite_screen.dart';
import '../ceo/data_vault_screen.dart';
import '../dept_head/monthly_scorecard_screen.dart';
import '../hr/hr_employee_inspection_screen.dart';
import '../hr/hr_management_widgets.dart';
import '../hr/hr_password_requests_screen.dart';
import '../hr/hr_portal_screen.dart';
import '../hr/hr_portal_subpages.dart';
import '../konar/konar_books_directory_screen.dart';
import '../media/creative_media_review_board_screen.dart';
import '../notes/personal_notes_screen.dart';
import '../orders/online_orders_handler_screen.dart';
import 'role_hub_widgets.dart';

/// Shared layout for the CEO Suite and HR Desk tabs.
class _RoleHub extends StatelessWidget {
  final String title;
  final String subtitle;
  final String announcer;
  final String announcerRole;
  final List<HubTool> Function(BuildContext, EcosystemProvider) tools;
  final Widget classicPortal;

  const _RoleHub({
    required this.title,
    required this.subtitle,
    required this.announcer,
    required this.announcerRole,
    required this.tools,
    required this.classicPortal,
  });

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final staff = eco.employees.where((e) => !e.isCeo).toList();
    final absent = staff.where((e) => eco.isEmployeeAbsent(e.id)).toList();
    final openTasks = eco.tasks.where((t) => t.isPending).length;
    final approvals = eco.pendingSocialCauses.length + eco.pendingMediaApprovalsCount;

    void announce() => openHubScreen(
          context,
          HubSectionPage(
            title: 'Announcement',
            subtitle: 'Send a notice to all staff',
            child: HrBroadcastSection(senderName: announcer, senderRole: announcerRole),
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MnAppBar(
        title: title,
        subtitle: subtitle,
        actions: [
          MnHeaderPill(icon: Icons.campaign_rounded, label: 'Announce', onTap: announce),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => eco.refreshAllData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            HubStatsRow(stats: [
              HubStat(Icons.groups_rounded, '${staff.length}', 'Staff', AppColors.primary,
                  onTap: () => openHubScreen(context, const HrStaffDirectoryScreen())),
              HubStat(Icons.person_off_rounded, '${absent.length}', 'Absent today',
                  absent.isEmpty ? AppColors.ragGreen : AppColors.ragRed,
                  onTap: () => openHubScreen(context, const HrAttendanceScreen())),
              HubStat(Icons.pending_actions_rounded, '$openTasks', 'Open tasks', const Color(0xFFD97706),
                  onTap: () => openHubScreen(context, const HrStaffTasksScreen())),
            ]),
            const SizedBox(height: 14),
            if (approvals > 0) ...[
              HubAlertBanner(
                icon: Icons.fact_check_rounded,
                color: const Color(0xFFD97706),
                title: approvals == 1 ? '1 approval waiting' : '$approvals approvals waiting',
                subtitle: [
                  if (eco.pendingSocialCauses.isNotEmpty) '${eco.pendingSocialCauses.length} social causes',
                  if (eco.pendingMediaApprovalsCount > 0) '${eco.pendingMediaApprovalsCount} media posts',
                ].join(' • '),
                actionLabel: 'Review',
                onAction: () => openHubScreen(
                  context,
                  eco.pendingSocialCauses.isNotEmpty
                      ? const HrSocialCausesScreen()
                      : const CreativeMediaReviewBoardScreen(),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => AssignTasksToOthersModal.show(context),
                    icon: const Icon(Icons.assignment_ind_rounded, size: 18),
                    label: const Text('Assign tasks'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => HrStaffDirectoryScreen.openAddHireDialog(context, eco),
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text('New hire'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const MnSectionTitle('Tools'),
            const SizedBox(height: 12),
            HubToolGrid(tools: tools(context, eco)),
            const SizedBox(height: 24),
            MnSectionTitle(
              absent.isEmpty ? 'Everyone is in today' : 'Away today (${absent.length})',
              actionLabel: 'Attendance',
              onAction: () => openHubScreen(context, const HrAttendanceScreen()),
            ),
            const SizedBox(height: 10),
            for (final e in absent.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HubPersonRow(
                  employee: e,
                  status: 'Absent',
                  statusColor: AppColors.ragRed,
                  onTap: () => openHubScreen(context, HrEmployeeInspectionScreen(employee: e)),
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () => openHubScreen(context, classicPortal),
                icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
                label: const Text('Open full dashboard (all tools)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CEO's third tab.
class CeoHubScreen extends StatelessWidget {
  const CeoHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<EcosystemProvider>().currentEmployee;
    return _RoleHub(
      title: 'CEO Suite',
      subtitle: 'Company overview & approvals',
      announcer: me.name,
      announcerRole: me.role,
      classicPortal: const CeoSuiteScreen(embedded: true),
      tools: (context, eco) => [
        HubTool(Icons.badge_rounded, 'Staff Dossiers', '${eco.employees.length} people', AppColors.primary,
            () => openHubScreen(context, const CeoStaffDossiersScreen())),
        HubTool(Icons.fingerprint_rounded, 'Attendance', 'Daily status', const Color(0xFF059669),
            () => openHubScreen(context, const CeoAttendanceScreen())),
        HubTool(Icons.assignment_rounded, 'Staff Tasks', 'All departments', const Color(0xFFD97706),
            () => openHubScreen(context, const CeoStaffTasksScreen())),
        HubTool(Icons.volunteer_activism_rounded, 'Social Causes', 'Approve good deeds', const Color(0xFF0F766E),
            () => openHubScreen(context, const CeoSocialCausesScreen()),
            badge: eco.pendingSocialCauses.length),
        HubTool(Icons.video_collection_rounded, 'Media Review', 'Reels & shoots', const Color(0xFF9D174D),
            () => openHubScreen(context, const CreativeMediaReviewBoardScreen()),
            badge: eco.pendingMediaApprovalsCount),
        HubTool(Icons.hub_rounded, 'Pipelines', 'Blockers & handovers', const Color(0xFF2563EB),
            () => openHubScreen(context, const CeoPipelinesBlockersScreen())),
        HubTool(Icons.shield_rounded, 'Blocker Tickets', 'Escalations', const Color(0xFFDC2626),
            () => openHubScreen(context, const HrBlockerTicketsScreen())),
        HubTool(Icons.dry_cleaning_rounded, 'Grooming Audit', 'Dress & presentation', const Color(0xFF7C2D12),
            () => openHubScreen(context, const HrGroomingAuditScreen())),
        HubTool(Icons.assessment_rounded, 'Scorecard', 'Monthly review', const Color(0xFF1D4ED8),
            () => openHubScreen(context, const MonthlyScorecardScreen())),
        HubTool(Icons.shopping_bag_rounded, 'Online Orders', 'Track & dispatch', const Color(0xFFEA580C),
            () => openHubScreen(context, const OnlineOrdersHandlerScreen())),
        HubTool(Icons.menu_book_rounded, 'Konar Books', 'Department handbooks', const Color(0xFF881337),
            () => openHubScreen(context, const KonarBooksDirectoryScreen())),
        HubTool(Icons.lock_reset_rounded, 'Password Requests', 'Verify staff codes', const Color(0xFFBE185D),
            () => openHubScreen(context, const HrPasswordRequestsScreen())),
        HubTool(Icons.task_alt_rounded, 'Personal To-Dos', 'Your own list', const Color(0xFF5B21B6),
            () => openHubScreen(context, const CeoPersonalTodosScreen())),
        HubTool(Icons.lock_rounded, 'Personal Notes', 'Private to you', const Color(0xFF5B5068),
            () => openHubScreen(context, const PersonalNotesScreen())),
        HubTool(Icons.admin_panel_settings_rounded, 'Roles & Access', 'Who can do what', const Color(0xFF334155),
            () => openHubScreen(context, const AdminRoleAccessManagementScreen())),
        HubTool(Icons.table_chart_rounded, 'Data Vault', 'Backup, restore, reset', const Color(0xFF475569),
            () => openHubScreen(context, const DataVaultScreen())),
        HubTool(Icons.file_download_rounded, 'Company Report', 'Export audit', const Color(0xFF0F766E),
            () => ExportAuditModal.show(context)),
      ],
    );
  }
}

/// HR's third tab.
class HrHubScreen extends StatelessWidget {
  const HrHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<EcosystemProvider>().currentEmployee;
    return _RoleHub(
      title: 'HR Desk',
      subtitle: 'People, attendance & requests',
      announcer: '${me.name} (HR)',
      announcerRole: 'HR Manager',
      classicPortal: const HrPortalScreen(embedded: true),
      tools: (context, eco) => [
        HubTool(Icons.badge_rounded, 'Staff Directory', '${eco.employees.length} people', AppColors.primary,
            () => openHubScreen(context, const HrStaffDirectoryScreen())),
        HubTool(Icons.fingerprint_rounded, 'Attendance', 'Sheet & leaves', const Color(0xFF059669),
            () => openHubScreen(context, const HrAttendanceScreen())),
        HubTool(Icons.lock_reset_rounded, 'Password Requests', 'Verify staff codes', const Color(0xFFBE185D),
            () => openHubScreen(context, const HrPasswordRequestsScreen())),
        HubTool(Icons.assignment_rounded, 'Staff Tasks', 'All departments', const Color(0xFFD97706),
            () => openHubScreen(context, const HrStaffTasksScreen())),
        HubTool(Icons.volunteer_activism_rounded, 'Social Causes', 'Approve good deeds', const Color(0xFF0F766E),
            () => openHubScreen(context, const HrSocialCausesScreen()),
            badge: eco.pendingSocialCauses.length),
        HubTool(Icons.dry_cleaning_rounded, 'Grooming Audit', 'Dress & presentation', const Color(0xFF7C2D12),
            () => openHubScreen(context, const HrGroomingAuditScreen())),
        HubTool(Icons.shield_rounded, 'Blocker Tickets', 'Escalations', const Color(0xFFDC2626),
            () => openHubScreen(context, const HrBlockerTicketsScreen())),
        HubTool(Icons.menu_book_rounded, 'Konar Books', 'Department handbooks', const Color(0xFF881337),
            () => openHubScreen(context, const KonarBooksDirectoryScreen())),
        HubTool(Icons.task_alt_rounded, 'Personal To-Dos', 'Your own list', const Color(0xFF5B21B6),
            () => openHubScreen(context, const HrPersonalTodosScreen())),
        HubTool(Icons.lock_rounded, 'Personal Notes', 'Private to you', const Color(0xFF5B5068),
            () => openHubScreen(context, const PersonalNotesScreen())),
        HubTool(Icons.file_download_rounded, 'HR Report', 'Export audit', const Color(0xFF0F766E),
            () => ExportAuditModal.show(context)),
      ],
    );
  }
}
