import '../hr/hr_password_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/role_app_bar.dart';
import '../../models/attendance_models.dart';
import '../../models/ecosystem_models.dart';
import '../../models/employee_model.dart';
import '../../models/hr_attendance_sheet_models.dart';
import '../../models/profile_pillar_models.dart';
import '../../providers/ecosystem_provider.dart';
import '../auth/pillars_popup_dialog.dart';
import '../employee/employee_profile_screen.dart';
import '../pillars/attendance_pillar_screen.dart';
import '../hr/hr_management_widgets.dart';
import '../orders/online_orders_handler_screen.dart';
import '../../core/widgets/export_audit_modal.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../core/widgets/assign_tasks_to_others_modal.dart';
import '../../core/widgets/cross_dept_blocker_section.dart';

import '../hr/hr_employee_inspection_screen.dart';
import '../hr/hr_portal_subpages.dart';
import '../../core/widgets/quick_pillar_nav_row.dart';
import 'ceo_subpages.dart';
import 'data_vault_screen.dart';
import '../notes/personal_notes_screen.dart';
import '../dept_head/monthly_scorecard_screen.dart';
import '../chat/chat_hub_screen.dart';
import '../../core/widgets/daily_pending_actions_dialog.dart';
import '../../core/widgets/birthday_celebration_dialog.dart';
import '../konar/konar_books_directory_screen.dart';
import '../../core/widgets/image_preview_dialog.dart';
import '../../services/image_optimization_service.dart';
import '../pillars/family_pillar_screen.dart';
import 'admin_role_access_management_screen.dart';
import '../media/creative_media_review_board_screen.dart';
import '../../core/utils/password_generator.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/widgets/task_assign_check.dart';

class CeoSuiteScreen extends StatefulWidget {
  /// True when shown as a tab inside the main shell (start-up popups are
  /// handled by the shell instead).
  final bool embedded;
  const CeoSuiteScreen({super.key, this.embedded = false});

  @override
  State<CeoSuiteScreen> createState() => _CeoSuiteScreenState();
}

class _CeoSuiteScreenState extends State<CeoSuiteScreen> {
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _tabsScrollController = ScrollController();
  final GlobalKey _tabSectionKey = GlobalKey();

  // ignore: unused_field
  final int _activeTab = 0; // 0: Role Allocation, 1: Pipelines & Blockers, 2: Delay Analytics, 3: Incidents
  String? _selectedEmpId;
  String _selectedRole = 'Dept Head';
  String _selectedDept = 'Gold Jewellery';
  final TextEditingController _employeeSearchController = TextEditingController();
  final Set<String> _selectedPerks = {
    'Can Assign Works to Others',
    'Can Approve Negotiation Discounts',
    'Can Approve Staff Permission Slips',
  };
  bool _isAttendanceExpanded = false;
  String _attendanceFilter = 'all'; // 'all', 'present', 'absent'
  String _attendanceTabFilter = 'all'; // 'all', 'present', 'absent', 'ontime', 'late', 'lunch'
  String? _selectedAttendanceInspectorEmpId;

  @override
  void dispose() {
    _mainScrollController.dispose();
    _tabsScrollController.dispose();
    _employeeSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final eco = context.read<EcosystemProvider>();
      eco.setLoggedIn(true);
      if (eco.activeEmpId != 'MN-CEO01') {
        eco.setActiveEmpId('MN-CEO01');
      }
      if (widget.embedded) return;
      if (mounted) {
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final ceoEmp = eco.employees.firstWhere(
      (e) => e.id == 'MN-CEO01' || e.roleType == 'ceo',
      orElse: () => Employee(
        id: 'MN-CEO01',
        name: 'M N Naveenraaj',
        role: 'Managing Director & CEO',
        roleType: 'ceo',
        dept: 'Executive Board',
        phone: '+91 98450 00001',
        email: 'ceoofmn@mnjpark.com',
        avatar: '',
        initials: 'MN',
        doj: '2020-01-01',
        experienceYears: '25 yrs in Fine Jewellery',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1975-01-15',
        relationshipStatus: 'Married',
        anniversaryDate: '2001-05-20',
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: RoleAppBar(
        roleName: 'CEO Suite',
        userName: 'M N Naveenraaj (CEO)',
        roleColor: AppColors.goldBright,
        roleIcon: Icons.workspace_premium_outlined,
        onExportPressed: () => _exportCsvAudit(context, eco),
      ),
      body: RefreshIndicator(
        color: AppColors.sandGold,
        backgroundColor: AppColors.burgundyCard,
        onRefresh: () => eco.refreshAllData(),
        child: SingleChildScrollView(
          controller: _mainScrollController,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CEO Hero Card with Profile Navigation
            InkWell(
              onTap: () {
                final ecoProvider = context.read<EcosystemProvider>();
                if (ecoProvider.activeEmpId != ceoEmp.id) {
                  ecoProvider.setActiveEmpId(ceoEmp.id);
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: LiquidGlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(14),
                borderColor: const Color(0xFFF1F5F9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.magentaGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.magentaPrimary.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: EmployeeAvatar(avatar: ceoEmp.avatar, initials: ceoEmp.initials, size: 50),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'M N Naveenraaj',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.magentaSubtle,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.magentaBorder, width: 0.8),
                                    ),
                                    child: Text(
                                      'ID: ${ceoEmp.id}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.magentaPrimary,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Managing Director & CEO',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.magentaSubtle,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.sandBorder, width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.business_outlined, size: 10, color: AppColors.magentaPrimary),
                                        const SizedBox(width: 4),
                                        Flexible(child: Text('${eco.employees.length} Corporate Staff', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.ragGreen.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.ragGreen.withOpacity(0.4), width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.ragGreen),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${eco.employees.length} Active Staff',
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.ragGreen),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const QuickPillarNavRow(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Vertical Segmented Navigation Grid (Direct Access right below CEO profile & 4 pillars)
            Container(
              key: _tabSectionKey,
              decoration: BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sandGold.withOpacity(0.35)),
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
                      const Icon(Icons.apps_rounded, size: 16, color: AppColors.sandGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'YOUR TOOLS',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
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
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      // Team Chat is a bottom-bar tab inside the main shell.
                      if (!widget.embedded) ...[
                        _verticalCeoTabTile(
                          context: context,
                          eco: eco,
                          label: 'Team Chat',
                          icon: Icons.chat_bubble_outline_rounded,
                          badge: eco.unreadTotalChatCount > 0 ? '${eco.unreadTotalChatCount}' : '',
                          destination: const ChatHubScreen(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Media Review Board',
                        icon: Icons.video_collection_outlined,
                        badge: eco.pendingMediaApprovalsCount > 0 ? '${eco.pendingMediaApprovalsCount}' : '',
                        destination: const CreativeMediaReviewBoardScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'KONAR Books',
                        icon: Icons.menu_book_rounded,
                        badge: '',
                        destination: const KonarBooksDirectoryScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Monthly Scorecard',
                        icon: Icons.assessment_outlined,
                        badge: '',
                        destination: const MonthlyScorecardScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Password Requests',
                        icon: Icons.lock_reset_rounded,
                        badge: '',
                        destination: const HrPasswordRequestsScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Staff Dossiers',
                        icon: Icons.badge_outlined,
                        badge: '${eco.employees.length}',
                        destination: const CeoStaffDossiersScreen(),
                      ),
                      const SizedBox(height: 8),

                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Personal To-Dos',
                        icon: Icons.task_alt_outlined,
                        badge: '',
                        destination: const CeoPersonalTodosScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Social Causes',
                        icon: Icons.volunteer_activism_outlined,
                        badge: eco.pendingSocialCauses.isNotEmpty ? '${eco.pendingSocialCauses.length}' : '',
                        destination: const CeoSocialCausesScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Staff Tasks',
                        icon: Icons.assignment_outlined,
                        badge: '',
                        destination: const CeoStaffTasksScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Attendance',
                        icon: Icons.fingerprint,
                        badge: '',
                        destination: const CeoAttendanceScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Pipelines & Blockers',
                        icon: Icons.hub_outlined,
                        badge: '',
                        destination: const CeoPipelinesBlockersScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Grooming Audit',
                        icon: Icons.dry_cleaning_outlined,
                        badge: '',
                        destination: const HrGroomingAuditScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Blocker Tickets',
                        icon: Icons.shield_outlined,
                        badge: '',
                        destination: const HrBlockerTicketsScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Personal Notes',
                        icon: Icons.lock_outline_rounded,
                        badge: 'Private',
                        destination: const PersonalNotesScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Data Vault & Reset DB',
                        icon: Icons.table_chart_outlined,
                        badge: '',
                        destination: const DataVaultScreen(),
                      ),
                      const SizedBox(height: 8),
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Role & Access Control',
                        icon: Icons.admin_panel_settings_outlined,
                        badge: '',
                        destination: const AdminRoleAccessManagementScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // CEO Quick Action Controls: Assign Tasks to Others & Onboard New Hire
            Row(
              children: [
                Expanded(
                  child: LiquidGlassButton(
                    label: DateTime.now().weekday == DateTime.tuesday
                        ? 'Assign Tasks (Tue Week-off)'
                        : 'Assign Tasks to Others',
                    icon: Icons.assignment_ind_outlined,
                    height: 40,
                    onPressed: () => AssignTasksToOthersModal.show(context),
                  ),
                ),
                const SizedBox(width: 8),
                LiquidGlassButton(
                  label: 'New Hire',
                  icon: Icons.person_add_alt_1,
                  height: 40,
                  onPressed: () => HrStaffDirectoryScreen.openAddHireDialog(context, eco),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Online Orders Handler & Executive SLA Command Card (Database Integrated)
            LiquidGlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 18,
              borderColor: const Color(0xFFF1F5F9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed : AppColors.magentaPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Online Orders',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed : AppColors.ragGreen).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed : AppColors.ragGreen).withOpacity(0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          eco.overdueOnlineOrders.isNotEmpty
                              ? '${eco.overdueOnlineOrders.length} Overdue'
                              : '${eco.onlineOrders.length} Active',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed : AppColors.ragGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Order Workflow Tracking',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                  ),
                  const SizedBox(height: 12),

                  // 3 KPI metric tiles
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.magentaSubtle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.sandBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MN Jewel Park', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text('${eco.os1Orders.length} Orders (OS1)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.magentaSubtle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.sandBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Vadivam', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text('${eco.os2Orders.length} Orders (OS2)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed.withOpacity(0.18) : AppColors.magentaSubtle,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed : AppColors.sandBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Overdue SLA', style: TextStyle(fontSize: 11.5, color: eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed : AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text('${eco.overdueOnlineOrders.length} Alerts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed : AppColors.ragGreen)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OnlineOrdersHandlerScreen()),
                      ),
                      icon: const Icon(Icons.assignment_turned_in_outlined, size: 16, color: Colors.white),
                      label: const Text('Open Online Orders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sandGold,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Dedicated Daily Attendance Space (Live Present & Absent Counters with interactive drilldown)
            _buildTodayAttendanceOverview(context, eco),
            const SizedBox(height: 12),

            // Universal Push Directive CTA Button & Assign Tasks to Others
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: LiquidGlassButton(
                    label: 'Assign Tasks (${eco.absentEmployeeIds.length} Absent)',
                    icon: Icons.assignment_ind_outlined,
                    onPressed: () => AssignTasksToOthersModal.show(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: LiquidGlassButton(
                    label: 'Universal Directive',
                    icon: Icons.campaign_outlined,
                    isPrimary: false,
                    onPressed: () => _openUniversalPushDialog(context, eco),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // CEO Broadcast & High-Priority To-Do Reminder Dispatcher
            HrBroadcastSection(
              senderName: ceoEmp.name,
              senderRole: ceoEmp.role,
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

  Widget _verticalCeoTabTile({
    required BuildContext context,
    required EcosystemProvider eco,
    required String label,
    required IconData icon,
    required String badge,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
              value: eco,
              child: destination,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.sandBorder,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.magentaSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
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
                  color: AppColors.magentaSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.magentaPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // --- ROLE ALLOCATION & EXECUTIVE PRIVILEGES TAB ---

  // ignore: unused_element
  Widget _buildRoleAllocationTab(BuildContext context, EcosystemProvider eco) {
    final allEmployees = eco.employees;
    final query = _employeeSearchController.text.toLowerCase().trim();
    final filtered = allEmployees.where((e) {
      if (query.isEmpty) return true;
      return e.name.toLowerCase().contains(query) ||
             e.id.toLowerCase().contains(query) ||
             e.dept.toLowerCase().contains(query) ||
             e.role.toLowerCase().contains(query);
    }).toList();

    // Default to first employee if none selected
    final activeEmp = allEmployees.firstWhere(
      (e) => e.id == _selectedEmpId,
      orElse: () => allEmployees.first,
    );

    final roleConfig = RoleAllocationConfig.defaultRoleProfiles[_selectedRole] ??
        RoleAllocationConfig.defaultRoleProfiles['Employee']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Executive Allocation Hero Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.burgundyCard,
                AppColors.burgundySurface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  boxShadow: [
                    BoxShadow(color: AppColors.sandGold.withOpacity(0.4), blurRadius: 10),
                  ],
                ),
                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROLE & PRIVILEGE ALLOCATION',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Executive authority to reassign departments, grant leadership tiers (Dept Head, HR, Employee, CEO), and designate task assignment perks.',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Executive Create HR / Staff CTA
        LiquidGlassButton(
          label: 'Create & Register HR / Executive Staff',
          icon: Icons.person_add_alt_1,
          onPressed: () => _openCreateStaffModal(context, eco),
        ),
        const SizedBox(height: 16),

        // 2. Type and Search Employee Filter
        Text(
          '1. SELECT EMPLOYEE (TYPE & SEARCH)',
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: AppColors.sandGold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _employeeSearchController,
          style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: AppColors.sandGold, size: 20),
            hintText: 'Type employee name, ID, or role...',
            hintStyle: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
            filled: true,
            fillColor: AppColors.burgundyCard,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.sandBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.sandBorder.withOpacity(0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.sandGold, width: 1.3),
            ),
            suffixIcon: _employeeSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, color: AppColors.sandLight, size: 16),
                    onPressed: () {
                      _employeeSearchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),

        // Horizontally Scrollable Matching Staff Cards
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, idx) {
              final emp = filtered[idx];
              final isSelected = emp.id == activeEmp.id;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedEmpId = emp.id;
                    _selectedRole = emp.role;
                    _selectedDept = emp.dept;
                    // Reset perks to role defaults
                    final profile = RoleAllocationConfig.defaultRoleProfiles[_selectedRole] ??
                        RoleAllocationConfig.defaultRoleProfiles['Employee']!;
                    _selectedPerks.clear();
                    _selectedPerks.addAll(profile.perks);
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.burgundySurface : AppColors.burgundyCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.sandGold : AppColors.sandBorder.withOpacity(0.5),
                      width: isSelected ? 1.6 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: AppColors.sandGold.withOpacity(0.2), blurRadius: 8)]
                        : null,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.sandGold.withOpacity(0.2),
                        child: Text(
                          emp.initials,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              emp.name,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.sandGold : AppColors.sandLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${emp.id} • ${emp.dept}',
                              style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // 3. Current Selection Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.burgundySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.sandGold.withOpacity(0.25),
                    child: Text(
                      activeEmp.initials,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
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
                                activeEmp.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            LiquidGlassPill(
                              label: activeEmp.id,
                              color: AppColors.sandGold,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Current Assignment: ${activeEmp.dept} • ${activeEmp.role}',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: AppColors.sandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // View Full Dossier CTA
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HrEmployeeInspectionScreen(employee: activeEmp),
                  ),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.sandGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_ind_outlined, size: 15, color: AppColors.sandGold),
                        const SizedBox(width: 8),
                        Text(
                          'View Full Dossier & Reset Password',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.sandGold),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(color: AppColors.sandBorder, height: 20),

              // 4. Department Dropdown Selector
              Text(
                'ASSIGN SHOWROOM DEPARTMENT',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandGold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: RoleAllocationConfig.availableDepartments.contains(_selectedDept)
                        ? _selectedDept
                        : RoleAllocationConfig.availableDepartments.first,
                    isExpanded: true,
                    dropdownColor: AppColors.burgundyCard,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.sandGold),
                    items: RoleAllocationConfig.availableDepartments.map((dept) {
                      return DropdownMenuItem<String>(
                        value: dept,
                        child: Row(
                          children: [
                            const Icon(Icons.store_mall_directory_outlined, size: 16, color: AppColors.sandGold),
                            const SizedBox(width: 8),
                            Text(
                              dept,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.sandLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDept = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Role Dropdown / Selector
              Text(
                'ASSIGN LEADERSHIP ROLE TIER',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandGold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: RoleAllocationConfig.standardRoles.map((role) {
                  final isRoleActive = _selectedRole.toLowerCase() == role.toLowerCase();
                  final p = RoleAllocationConfig.defaultRoleProfiles[role];
                  final col = p?.badgeColor ?? AppColors.sandGold;

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(p?.icon ?? Icons.badge, size: 14, color: isRoleActive ? Colors.white : col),
                        const SizedBox(width: 6),
                        Text(
                          role,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isRoleActive ? Colors.white : AppColors.sandLight,
                          ),
                        ),
                      ],
                    ),
                    selected: isRoleActive,
                    selectedColor: col,
                    backgroundColor: AppColors.burgundyCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: isRoleActive ? col : AppColors.sandBorder),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedRole = role;
                          // auto-seed role perks
                          final newProfile = RoleAllocationConfig.defaultRoleProfiles[role];
                          if (newProfile != null) {
                            _selectedPerks.clear();
                            _selectedPerks.addAll(newProfile.perks);
                          }
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 6. Responsibilities Matrix
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(roleConfig.icon, color: AppColors.magentaPrimary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CORE MANDATES & DUTIES FOR ${_selectedRole.toUpperCase()}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...roleConfig.responsibilities.map((resp) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.magentaPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          resp,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: const Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 7. Executive Perks & Privileges Checklist
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.stars_rounded, color: AppColors.magentaPrimary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'OPERATIONAL PERKS & PRIVILEGES',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Toggle clearances granted to ${activeEmp.name}:',
                style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              ...[
                'Can Assign Works to Others',
                'Can Approve Negotiation Discounts (Up to 3%)',
                'Vault Key Custodian Clearance (Physical Locker)',
                'Priority Showroom Shift Scheduling',
                'Direct Hotline Clearance to CEO Office',
              ].map((perk) {
                final isGranted = _selectedPerks.contains(perk);
                return Material(type: MaterialType.transparency, child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.magentaPrimary,
                  checkColor: Colors.white,
                  value: isGranted,
                  title: Text(
                    perk,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: isGranted ? FontWeight.w600 : FontWeight.normal,
                      color: isGranted ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedPerks.add(perk);
                      } else {
                        _selectedPerks.remove(perk);
                      }
                    });
                  },
                ));
              }),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 8. Commit Save Button
        ElevatedButton.icon(
          icon: const Icon(Icons.verified_rounded, size: 18, color: Colors.white),
          label: Text(
            'CONFIRM & ALLOCATE ROLE',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.6,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.magentaPrimary,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final refused = await eco.allocateEmployeeRole(
              empId: activeEmp.id,
              newRole: _selectedRole,
              newDept: _selectedDept,
              perks: _selectedPerks.toList(),
              responsibilities: roleConfig.responsibilities,
            );
            if (refused != null) {
              messenger.showSnackBar(SnackBar(backgroundColor: const Color(0xFFDC2626), content: Text(refused)));
              return;
            }
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF10B981),
                content: Text(
                  '${activeEmp.name} allocated as $_selectedRole in $_selectedDept with ${_selectedPerks.length} privileges!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildHandoverAndBlockerTab(
    BuildContext context,
    EcosystemProvider eco,
    List<Handover> handovers,
    List<Blocker> blockers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Inter-Department Handover Pipeline
        Row(
          children: [
            const Expanded(
              child: Text(
                '1. Inter-Department Handover Pipeline',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.magentaPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.magentaPrimary.withOpacity(0.2), width: 0.8),
              ),
              child: const Text(
                'Workshop → Assay',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.magentaPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...handovers.map((ho) {
          final isCompleted = ho.status == 'completed';
          return LiquidGlassCard(
            padding: const EdgeInsets.all(14),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ho.batch,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    LiquidGlassPill(
                      label: isCompleted ? 'COMPLETED' : 'IN PROGRESS',
                      color: isCompleted ? AppColors.ragGreen : AppColors.magentaPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Current Stage: ${ho.stage}', style: const TextStyle(fontSize: 11, color: AppColors.magentaDark, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                // 3 Steps visual chain
                Row(
                  children: ho.steps.asMap().entries.map((e) {
                    final step = e.value;
                    final isDone = step.status == 'done';
                    final isInProg = step.status == 'in_progress';

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.ragGreen.withOpacity(0.15)
                              : (isInProg ? AppColors.magentaPrimary.withOpacity(0.15) : AppColors.magentaSubtle),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDone
                                ? AppColors.ragGreen.withOpacity(0.5)
                                : (isInProg ? AppColors.magentaPrimary.withOpacity(0.5) : AppColors.sandBorder),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              step.dept,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDone ? AppColors.ragGreen : (isInProg ? AppColors.goldBright : const Color(0xFF64748B)),
                              ),
                            ),
                            Text(
                              step.completedBy ?? 'Pending',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (!isCompleted) ...[
                  const SizedBox(height: 10),
                  LiquidGlassButton(
                    label: 'Advance to Next Department Handover',
                    icon: Icons.fast_forward_outlined,
                    height: 34,
                    onPressed: () {
                      eco.advanceHandover(ho.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Handover batch advanced to next stage!')),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 14),

        // 2. Cross-Department Blocker Escalation (CEO Escalation Filter: Late Tickets Only)
        const CrossDeptBlockerSection(
          department: 'Executive Command',
          isCeoView: true,
        ),
      ],
    );
  }

  void _exportCsvAudit(BuildContext context, EcosystemProvider eco) {
    ExportAuditModal.show(context);
  }

  void _openUniversalPushDialog(BuildContext context, EcosystemProvider eco) {
    final staffList = eco.employees;
    if (staffList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.burgundyPrimary,
          content: Text('No staff members registered yet to assign directives.'),
        ),
      );
      return;
    }
    String? selectedEmp = staffList.first.id;
    final titleController = TextEditingController();
    String priority = 'Critical SLA';
    String due = '05:00 PM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
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
                      const Text('Assign Task to Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Text('Assign a direct task to any employee.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),

                  const Text('Select Employee:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: staffList.any((e) => e.id == selectedEmp)
                        ? selectedEmp
                        : (staffList.isNotEmpty ? staffList.first.id : null),
                    isExpanded: true,
                    dropdownColor: AppColors.burgundySurface,
                    style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.burgundySurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: staffList.map((e) {
                      return DropdownMenuItem(
                        value: e.id,
                        child: Text(
                          '${e.name} (${e.dept} • ${e.role})',
                          style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedEmp = v);
                    },
                  ),
                  const SizedBox(height: 10),

                  const Text('Task Title:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Enter task title...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      filled: true,
                      fillColor: AppColors.magentaSubtle,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.magentaPrimary)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  LiquidGlassButton(
                    label: 'Assign Task',
                    icon: Icons.send,
                    onPressed: () async {
                      if (selectedEmp == null) return;
                      final t = titleController.text.trim();
                      final go = await confirmTaskAssignment(
                        ctx,
                        eco,
                        empId: selectedEmp!,
                        title: t.isNotEmpty ? t : 'CEO Priority Task',
                        category: 'CEO Task',
                        due: due,
                      );
                      if (!go || !ctx.mounted) return;
                      eco.assignTask(
                        empId: selectedEmp!,
                        title: t.isNotEmpty ? t : 'CEO Priority Task',
                        category: 'CEO Task',
                        priority: priority,
                        due: due,
                        assignedByRole: 'ceo',
                        assignedByName: '${eco.currentEmployee.name} (CEO)',
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task assigned successfully!')),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTodayAttendanceOverview(BuildContext context, EcosystemProvider eco) {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${now.day} ${months[now.month - 1]}';

    final allSummaries = eco.allEmployeesTodayAttendance;
    // Outside support is not MN Jewel Park staff and has no attendance.
    final attendanceStaff = eco.employees.where((e) => !e.isExternalSupport).toList();
    final onDutyEmps = attendanceStaff.where((e) {
      final matches = allSummaries.where((x) => x.employeeId == e.id);
      if (matches.isEmpty) return false;
      return matches.first.isCurrentlyOnDuty;
    }).toList();
    final shiftOverEmps = attendanceStaff.where((e) {
      final matches = allSummaries.where((x) => x.employeeId == e.id);
      if (matches.isEmpty) return false;
      final s = matches.first;
      return !s.isCurrentlyOnDuty && s.isPresent;
    }).toList();
    final absentEmps = attendanceStaff.where((e) {
      final isManuallyAbsent = eco.isEmployeeAbsent(e.id);
      final matches = allSummaries.where((x) => x.employeeId == e.id);
      final isAbsentStatus = matches.isNotEmpty && matches.first.status == DailyAttendanceStatus.absent;
      return isManuallyAbsent || isAbsentStatus;
    }).toList();
    final weekOffEmps = attendanceStaff.where((e) {
      final matches = allSummaries.where((x) => x.employeeId == e.id);
      return matches.isNotEmpty && matches.first.status == DailyAttendanceStatus.weekOff;
    }).toList();
    final yetToUpdateEmps = attendanceStaff.where((e) {
      final matches = allSummaries.where((x) => x.employeeId == e.id);
      return matches.isNotEmpty && matches.first.status == DailyAttendanceStatus.yetToUpdate;
    }).toList();
    final totalStaff = attendanceStaff.length;

    List<Employee> displayedList;
    if (_attendanceFilter == 'present') {
      displayedList = attendanceStaff.where((e) => eco.todayAttendanceOf(e.id) == TodayAttendance.present || !e.hasAttendanceAndGrooming).toList();
    } else if (_attendanceFilter == 'on_duty') {
      displayedList = onDutyEmps;
    } else if (_attendanceFilter == 'week_off') {
      displayedList = weekOffEmps;
    } else if (_attendanceFilter == 'yet_to_update') {
      displayedList = yetToUpdateEmps;
    } else if (_attendanceFilter == 'shift_over') {
      displayedList = shiftOverEmps;
    } else if (_attendanceFilter == 'absent') {
      displayedList = absentEmps;
    } else {
      displayedList = attendanceStaff;
    }

    final isPresentActive = _isAttendanceExpanded && (_attendanceFilter == 'present' || _attendanceFilter == 'on_duty');
    final isAbsentActive = _isAttendanceExpanded && _attendanceFilter == 'absent';

    return LiquidGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      borderColor: const Color(0xFFF1F5F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Expand/Collapse Toggle
          InkWell(
            onTap: () {
              setState(() {
                _isAttendanceExpanded = !_isAttendanceExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                const Icon(
                  Icons.how_to_reg_outlined,
                  color: AppColors.sandGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
                        child: Text(
                          "Today's Attendance",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.magentaSubtle,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.sandBorder, width: 0.8),
                        ),
                        child: Text(
                          dateStr,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isAttendanceExpanded ? 'Hide' : 'View Staff',
                  style: const TextStyle(fontSize: 11, color: AppColors.magentaPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 2),
                Icon(
                  _isAttendanceExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.magentaPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Two Clickable Metric Counters: X Present & Y Absent
          Row(
            children: [
              // Present Counter Tile
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        if (_isAttendanceExpanded && _attendanceFilter == 'present') {
                          _isAttendanceExpanded = false;
                        } else {
                          _isAttendanceExpanded = true;
                          _attendanceFilter = 'present';
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isPresentActive ? AppColors.ragGreenBg : AppColors.whiteBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPresentActive ? const Color(0xFF10B981) : AppColors.sandBorder,
                          width: isPresentActive ? 1.6 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (now.weekday == DateTime.tuesday || weekOffEmps.length >= 5)
                                      ? const Color(0xFF94A3B8)
                                      : (yetToUpdateEmps.length >= 5 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  (now.weekday == DateTime.tuesday || weekOffEmps.length >= 5)
                                      ? 'Week off'
                                      : (yetToUpdateEmps.length >= 5 ? 'Yet to update' : 'On Duty'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: (now.weekday == DateTime.tuesday || weekOffEmps.length >= 5)
                                        ? const Color(0xFF64748B)
                                        : (yetToUpdateEmps.length >= 5 ? const Color(0xFFB45309) : const Color(0xFF047857)),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isPresentActive ? Icons.check_circle : Icons.check_circle_outline,
                                size: 14,
                                color: (now.weekday == DateTime.tuesday || weekOffEmps.length >= 5)
                                    ? const Color(0xFF94A3B8)
                                    : (yetToUpdateEmps.length >= 5 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (now.weekday == DateTime.tuesday || weekOffEmps.length >= 5)
                                ? '${weekOffEmps.length} Week off'
                                : (yetToUpdateEmps.length >= 5
                                    ? '${yetToUpdateEmps.length} Yet to update'
                                    : '${onDutyEmps.length} On Duty'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (now.weekday == DateTime.tuesday || weekOffEmps.length >= 5)
                                ? (onDutyEmps.isNotEmpty ? '${onDutyEmps.length} 24/7 Available' : 'Showroom Closed')
                                : (shiftOverEmps.isNotEmpty
                                    ? '${shiftOverEmps.length} Shift Over'
                                    : (isPresentActive ? 'Viewing on duty ▼' : 'Tap to view')),
                            style: TextStyle(
                              fontSize: 11,
                              color: isPresentActive ? const Color(0xFF047857) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Absent / Pending Counter Tile
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        if (_isAttendanceExpanded && _attendanceFilter == 'absent') {
                          _isAttendanceExpanded = false;
                        } else {
                          _isAttendanceExpanded = true;
                          _attendanceFilter = 'absent';
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: isAbsentActive ? AppColors.ragRedBg : AppColors.whiteBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAbsentActive ? const Color(0xFFEF4444) : AppColors.sandBorder,
                          width: isAbsentActive ? 1.6 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (absentEmps.isEmpty && yetToUpdateEmps.isNotEmpty)
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  (absentEmps.isEmpty && yetToUpdateEmps.isNotEmpty) ? 'Yet to update' : 'Off Duty',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: (absentEmps.isEmpty && yetToUpdateEmps.isNotEmpty)
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFFB91C1C),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isAbsentActive ? Icons.error : Icons.error_outline,
                                size: 14,
                                color: (absentEmps.isEmpty && yetToUpdateEmps.isNotEmpty)
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (absentEmps.isEmpty && yetToUpdateEmps.isNotEmpty)
                                ? '${yetToUpdateEmps.length} Yet to update'
                                : '${absentEmps.length} Absent',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: (absentEmps.isEmpty && yetToUpdateEmps.isNotEmpty)
                                  ? const Color(0xFFB45309)
                                  : AppColors.ragRed,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAbsentActive
                                ? 'Viewing absent ▼'
                                : ((absentEmps.isEmpty && yetToUpdateEmps.isNotEmpty) ? 'Pending HR Sheet' : 'Tap to view'),
                            style: TextStyle(
                              fontSize: 11,
                              color: isAbsentActive ? const Color(0xFFB91C1C) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Detailed List when expanded
          if (_isAttendanceExpanded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.whiteBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips inside expanded view
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _attendanceFilterChip('all', 'All ($totalStaff)'),
                        const SizedBox(width: 6),
                        _attendanceFilterChip('on_duty', 'On Duty (${onDutyEmps.length})'),
                        if (yetToUpdateEmps.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _attendanceFilterChip('yet_to_update', 'Yet to update (${yetToUpdateEmps.length})'),
                        ],
                        if (weekOffEmps.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _attendanceFilterChip('week_off', 'Week off (${weekOffEmps.length})'),
                        ],
                        const SizedBox(width: 6),
                        _attendanceFilterChip('shift_over', 'Shift Over (${shiftOverEmps.length})'),
                        const SizedBox(width: 6),
                        _attendanceFilterChip('absent', 'Absent (${absentEmps.length})'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Staff List
                  if (displayedList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          _attendanceFilter == 'absent'
                              ? 'No staff are absent today.'
                              : (_attendanceFilter == 'yet_to_update'
                                  ? 'All staff attendance has been updated.'
                                  : (_attendanceFilter == 'week_off'
                                      ? 'No staff scheduled for week-off.'
                                      : (_attendanceFilter == 'shift_over'
                                          ? 'No staff have completed their shift yet today.'
                                          : 'No staff members found.'))),
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (ctx, idx) {
                        final emp = displayedList[idx];
                        final isAbsent = eco.isEmployeeAbsent(emp.id);
                        final summary = eco.allEmployeesTodayAttendance.firstWhere(
                          (s) => s.employeeId == emp.id,
                          orElse: () => EmployeeDailyAttendanceSummary(
                            employeeId: emp.id,
                            employeeName: emp.name,
                            department: emp.dept,
                            role: emp.role,
                            avatar: emp.avatar,
                            initials: emp.initials,
                            loginPunch: null,
                            logoutPunch: null,
                            lunchOutPunch: null,
                            lunchInPunch: null,
                            isPresent: !isAbsent,
                            isOnTime: false,
                            isCurrentlyOnLunch: false,
                            isCurrentlyOnDuty: !isAbsent,
                            lunchDurationMinutes: 0,
                            netWorkHours: 0,
                            status: isAbsent ? DailyAttendanceStatus.absent : DailyAttendanceStatus.presentOnTime,
                          ),
                        );

                        String timeInfo = isAbsent ? ' • Absent' : '';

                        String badgeText;
                        Color badgeColor;
                        if (emp.isCeo || emp.name.toLowerCase().contains('praveen')) {
                          badgeText = 'Available (24/7)';
                          badgeColor = const Color(0xFF10B981);
                        } else if (emp.isExternalSupport) {
                          badgeText = 'Online Tasks';
                          badgeColor = const Color(0xFF3B82F6);
                        } else if (isAbsent || summary.status == DailyAttendanceStatus.absent) {
                          badgeText = 'Absent';
                          badgeColor = const Color(0xFFEF4444);
                        } else if (summary.status == DailyAttendanceStatus.weekOff || (now.weekday == DateTime.tuesday && !emp.isExternalSupport)) {
                          badgeText = 'Week off';
                          badgeColor = const Color(0xFF94A3B8);
                        } else if (summary.status == DailyAttendanceStatus.yetToUpdate) {
                          badgeText = 'Yet to update';
                          badgeColor = const Color(0xFFF59E0B);
                        } else if (now.hour >= 21 || now.hour < 9) {
                          badgeText = 'Off Duty (9 PM)';
                          badgeColor = const Color(0xFFF65C8F);
                        } else if (summary.logoutPunch != null || summary.status == DailyAttendanceStatus.completed) {
                          if (summary.netWorkHours > 0 && summary.netWorkHours < 8.0) {
                            badgeText = 'Left Early';
                            badgeColor = const Color(0xFFF59E0B);
                          } else {
                            badgeText = 'Shift Over';
                            badgeColor = const Color(0xFFF65C8F);
                          }
                        } else if (summary.isCurrentlyOnLunch) {
                          badgeText = 'On Lunch';
                          badgeColor = const Color(0xFF3B82F6);
                        } else if (summary.status == DailyAttendanceStatus.lateLogin) {
                          badgeText = 'Late In';
                          badgeColor = const Color(0xFFF59E0B);
                        } else if (summary.isCurrentlyOnDuty) {
                          badgeText = 'On Duty';
                          badgeColor = const Color(0xFF10B981);
                        } else {
                          badgeText = 'Yet to update';
                          badgeColor = const Color(0xFFF59E0B);
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isAbsent ? const Color(0xFFFFF1F4) : AppColors.whiteBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: badgeColor.withOpacity(0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: badgeColor.withOpacity(0.2),
                                child: Text(
                                  emp.initials,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Name on left, Timing badge on right with breathing room
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            emp.name,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: badgeColor.withOpacity(0.5),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: badgeColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),

                                    // Row 2: Department and punch timings across the full width
                                    Text(
                                      '${emp.dept}$timeInfo',
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 320;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.sandGold.withOpacity(0.6), width: 1.0),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                backgroundColor: AppColors.sandGold.withOpacity(0.08),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AttendancePillarScreen()),
                                );
                              },
                              icon: const Icon(Icons.fingerprint, size: 13, color: AppColors.sandGold),
                              label: Text(
                                isNarrow ? 'Biometric' : 'Biometric Ledger',
                                style: const TextStyle(fontSize: 11, color: AppColors.sandGold, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.sandGold,
                                foregroundColor: AppColors.burgundyCard,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
                                      value: eco,
                                      child: const CeoAttendanceScreen(initialFilter: 'all', initialTab: 1),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.arrow_downward, size: 13, color: AppColors.burgundyCard),
                              label: Text(
                                isNarrow ? 'Attendance Tab' : 'Open Attendance Tab',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.burgundyCard),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          // Comprehensive Staff Activity & Audit Dossier Inspector
          _buildStaffActivityDossierInspector(context, eco),
        ],
      ),
    );
  }

  Widget _buildStaffActivityDossierInspector(BuildContext context, EcosystemProvider eco) {
    final staffList = eco.employees.where((e) => !e.isCeo).toList();
    if (staffList.isEmpty) return const SizedBox.shrink();

    final selectedId = _selectedAttendanceInspectorEmpId ?? staffList.first.id;
    final selectedEmp = staffList.firstWhere(
      (e) => e.id == selectedId,
      orElse: () => staffList.first,
    );

    final sheetRow = eco.getEmployeeSheetRow(selectedEmp.id);
    final groomingPts = eco.getEmployeeGroomingDailyPoints(selectedEmp.id);
    final isGroomingStar = groomingPts >= 40;
    final deeds = eco.socialCauses.where((c) => c.empId == selectedEmp.id || c.employeeName == selectedEmp.name).toList();
    final todaySteps = eco.getStepsForDate(DateTime.now());
    final stepGoal = eco.dailyStepGoal;
    final todayCalories = eco.getCaloriesConsumedForDate(DateTime.now());

    // Google Sheets attendance metrics
    final lates = sheetRow?.lateCount ?? 0;
    final clUsed = sheetRow?.clDaysUsed ?? 0.0;
    final lopUsed = sheetRow?.lopDaysUsed ?? 0.0;
    final permissionHoursUsed = sheetRow?.totalPermissionHours ?? 0.0;
    final presentCount = sheetRow?.presentDaysCount ?? (eco.isEmployeeAbsent(selectedEmp.id) ? 0 : 1);

    // Recent 5 days from sheet
    final recentDayRecords = <HrAttendanceDayRecord>[];
    if (sheetRow != null) {
      final now = DateTime.now();
      for (int i = 0; i < 5; i++) {
        final d = now.day - i;
        if (d >= 1 && sheetRow.days.containsKey(d)) {
          recentDayRecords.add(sheetRow.days[d]!);
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 16, color: AppColors.magentaPrimary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'STAFF ACTIVITY & AUDIT DOSSIER',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.magentaSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Deep Inspection',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dropdown selector of employee names
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedId,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.magentaPrimary),
                items: staffList.map((emp) {
                  return DropdownMenuItem<String>(
                    value: emp.id,
                    child: Text(
                      '${emp.name} • ${emp.dept} (${emp.role})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedAttendanceInspectorEmpId = val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Dossier details for selected employee
          // 1. Google Sheets Live Attendance
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.sandGold),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Google Sheets Attendance',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$presentCount Days Present',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _dossierMiniKpi('Lates', '$lates / 3 Max', lates > 3 ? AppColors.ragRed : const Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _dossierMiniKpi('Casual Leave', '${clUsed.toStringAsFixed(clUsed.truncateToDouble() == clUsed ? 0 : 1)} / 1 CL', clUsed > 1 ? AppColors.ragRed : const Color(0xFF3B82F6)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _dossierMiniKpi('Loss of Pay', '${lopUsed.toStringAsFixed(lopUsed.truncateToDouble() == lopUsed ? 0 : 1)} LOP', lopUsed > 0 ? AppColors.ragRed : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _dossierMiniKpi('Permission', '${permissionHoursUsed.toStringAsFixed(1)}h / 4.0h', permissionHoursUsed > 4 ? AppColors.ragRed : const Color(0xFF10B981)),
                    ),
                  ],
                ),
                if (recentDayRecords.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: recentDayRecords.map((r) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: r.backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: r.borderColor, width: 0.8),
                        ),
                        child: Text(
                          'Day ${r.day}: ${r.displayLabel}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: r.textColor),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. Grooming Activity & Compliance
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.dry_cleaning_outlined, size: 16, color: AppColors.sandGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daily Grooming & Attire Audit',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(
                        selectedEmp.hasAttendanceAndGrooming
                            ? 'Score: $groomingPts/50 Pts • ${isGroomingStar ? "★ Star Groomed" : "Standard Grooming"}'
                            : 'Exempt from showroom grooming audits',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: !selectedEmp.hasAttendanceAndGrooming
                        ? const Color(0xFFF1F5F9)
                        : (isGroomingStar ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    !selectedEmp.hasAttendanceAndGrooming ? 'Exempt' : '$groomingPts / 50',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: !selectedEmp.hasAttendanceAndGrooming
                          ? const Color(0xFF64748B)
                          : (isGroomingStar ? const Color(0xFF166534) : const Color(0xFF92400E)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 3. Social Causes & Deeds
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.volunteer_activism_outlined, size: 16, color: Color(0xFFBE185D)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Social Cause & CSR Deeds',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          Text(
                            deeds.isNotEmpty
                                ? '${deeds.length} deeds registered • Latest: "${deeds.first.title}"'
                                : 'No community deeds submitted yet',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: deeds.isNotEmpty ? const Color(0xFFFFE4E6) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${deeds.length} Deeds',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: deeds.isNotEmpty ? const Color(0xFFBE185D) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                if (deeds.isNotEmpty && deeds.first.imageUrl != null && deeds.first.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => ImagePreviewDialog.show(
                      context,
                      imageUrl: deeds.first.imageUrl!,
                      title: '${selectedEmp.name} - ${deeds.first.title}',
                      subtitle: '₹${deeds.first.amountSpent.toStringAsFixed(0)} • ${deeds.first.causeType}',
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ImageOptimizationService.buildImageWidget(
                            deeds.first.imageUrl!,
                            height: 95,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            margin: const EdgeInsets.all(6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fullscreen, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Preview Deed Photo', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 4. Family & Social Harmony Inspection Link
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmployeeFamilyActivitiesScreen()),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.family_restroom, size: 16, color: Color(0xFFA855F7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Family & Social Activity Diary',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        Text(
                          'Inspect ${selectedEmp.name}\'s logged moments & photo proofs',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Inspect Photos',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBE185D),
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_ios, size: 9, color: Color(0xFFBE185D)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 5. Personal Achievement & Health
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_outline, size: 16, color: Color(0xFFEF4444)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Health & Personal Milestone',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(
                        'Steps: $todaySteps / $stepGoal • Calories: ${todayCalories.toStringAsFixed(0)} kcal',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${todaySteps > 0 ? ((todaySteps / stepGoal) * 100).round() : 0}% Goal',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 5. Special Dates & Life Milestones
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake_outlined, size: 16, color: Color(0xFFF65C8F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Special Dates & Milestones',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(
                        'DOB: ${selectedEmp.dob.isNotEmpty ? selectedEmp.dob : "Not recorded"} • Status: ${selectedEmp.relationshipStatus}${selectedEmp.anniversaryDate.isNotEmpty ? " • Anniversary: ${selectedEmp.anniversaryDate}" : ""}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    selectedEmp.relationshipStatus,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBE185D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dossierMiniKpi(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text(value, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _attendanceFilterChip(String filterKey, String label) {
    final isSelected = _attendanceFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _attendanceFilter = filterKey),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.magentaGradient : null,
          color: isSelected ? null : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.sandBorder,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.magentaPrimary.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBiometricAttendanceTab(BuildContext context, EcosystemProvider eco) {
    final summaries = eco.allEmployeesTodayAttendance;
    final total = summaries.length;
    final presentCount = summaries.where((s) => !eco.isEmployeeAbsent(s.employeeId) && s.status != DailyAttendanceStatus.yetToUpdate && s.status != DailyAttendanceStatus.weekOff).length;
    final absentCount = summaries.where((s) => eco.isEmployeeAbsent(s.employeeId)).length;
    final onTimeCount = summaries.where((s) => s.status == DailyAttendanceStatus.presentOnTime).length;
    final lateCount = summaries.where((s) => s.status == DailyAttendanceStatus.lateLogin).length;
    final onLunchCount = summaries.where((s) => s.isCurrentlyOnLunch).length;

    List<EmployeeDailyAttendanceSummary> filteredSummaries = summaries;
    if (_attendanceTabFilter == 'present') {
      filteredSummaries = summaries.where((s) => !eco.isEmployeeAbsent(s.employeeId) && s.status != DailyAttendanceStatus.yetToUpdate && s.status != DailyAttendanceStatus.weekOff).toList();
    } else if (_attendanceTabFilter == 'absent') {
      filteredSummaries = summaries.where((s) => eco.isEmployeeAbsent(s.employeeId)).toList();
      if (filteredSummaries.length > 1) {
        filteredSummaries.sort((a, b) => a.employeeName.toLowerCase().compareTo(b.employeeName.toLowerCase()));
      }
    } else if (_attendanceTabFilter == 'ontime') {
      filteredSummaries = summaries.where((s) => s.status == DailyAttendanceStatus.presentOnTime).toList();
    } else if (_attendanceTabFilter == 'late') {
      filteredSummaries = summaries.where((s) => s.status == DailyAttendanceStatus.lateLogin).toList();
    } else if (_attendanceTabFilter == 'lunch') {
      filteredSummaries = summaries.where((s) => s.isCurrentlyOnLunch).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Device sync banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live Attendance Active',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 13, color: AppColors.sandGold),
                label: const Text('Refresh', style: TextStyle(fontSize: 11, color: AppColors.sandGold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.sandGold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  await eco.syncFromEsslDevice();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF10B981),
                      content: Text('Attendance refreshed across all departments!'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),


        // KPI Metric Chips (Present & Absent Live Oversight)
        Row(
          children: [
            Expanded(
              child: _kpiPill(
                'Total Staff',
                '$total',
                AppColors.sandGold,
                Icons.groups,
                onTap: () => setState(() => _attendanceTabFilter = 'all'),
                isSelected: _attendanceTabFilter == 'all',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _kpiPill(
                'Present',
                '$presentCount',
                const Color(0xFF10B981),
                Icons.check_circle_outline,
                onTap: () => setState(() => _attendanceTabFilter = _attendanceTabFilter == 'present' ? 'all' : 'present'),
                isSelected: _attendanceTabFilter == 'present',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _kpiPill(
                'Absent',
                '$absentCount',
                const Color(0xFFEF4444),
                Icons.error_outline,
                onTap: () => setState(() => _attendanceTabFilter = _attendanceTabFilter == 'absent' ? 'all' : 'absent'),
                isSelected: _attendanceTabFilter == 'absent',
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _kpiPill(
                'On-Time',
                '$onTimeCount',
                const Color(0xFF10B981),
                Icons.schedule,
                onTap: () => setState(() => _attendanceTabFilter = _attendanceTabFilter == 'ontime' ? 'all' : 'ontime'),
                isSelected: _attendanceTabFilter == 'ontime',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _kpiPill(
                'Late In',
                '$lateCount',
                const Color(0xFFEAB308),
                Icons.access_time,
                onTap: () => setState(() => _attendanceTabFilter = _attendanceTabFilter == 'late' ? 'all' : 'late'),
                isSelected: _attendanceTabFilter == 'late',
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _kpiPill(
                'On Lunch',
                '$onLunchCount',
                const Color(0xFF3B82F6),
                Icons.restaurant,
                onTap: () => setState(() => _attendanceTabFilter = _attendanceTabFilter == 'lunch' ? 'all' : 'lunch'),
                isSelected: _attendanceTabFilter == 'lunch',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Section Title
        Text(
          'EXECUTIVE WORKFORCE ATTENDANCE & IN/OUT ROSTER',
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: AppColors.sandGold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),

        // Employee Cards List
        if (filteredSummaries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No staff members match the selected filter.',
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSummaries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final item = filteredSummaries[idx];
              final isAbsentView = _attendanceTabFilter == 'absent' && filteredSummaries.length > 1;
              final firstLetter = item.employeeName.isNotEmpty ? item.employeeName[0].toUpperCase() : '#';
              final prevLetter = (idx > 0 && filteredSummaries[idx - 1].employeeName.isNotEmpty)
                  ? filteredSummaries[idx - 1].employeeName[0].toUpperCase()
                  : null;
              final showSectionHeader = isAbsentView && (idx == 0 || firstLetter != prevLetter);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showSectionHeader) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, top: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEF4444),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              firstLetter,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Section $firstLetter • Absent Staff (A to Z)',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.burgundyCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: item.statusBadgeColor.withOpacity(0.5), width: 1.1),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A0F172A),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Top Row: Avatar, Name, Dept, Status Badge
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          final emp = eco.employees.firstWhere(
                            (e) => e.id == item.employeeId,
                            orElse: () => eco.employees.first,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HrEmployeeInspectionScreen(employee: emp),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.sandGold.withOpacity(0.2),
                          child: Text(
                            item.initials,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.sandGold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            final emp = eco.employees.firstWhere(
                              (e) => e.id == item.employeeId,
                              orElse: () => eco.employees.first,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HrEmployeeInspectionScreen(employee: emp),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.employeeName,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandLight,
                                ),
                              ),
                              Text(
                                '${item.employeeId} • ${item.department} (${item.role})',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.statusBadgeColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: item.statusBadgeColor.withOpacity(0.6)),
                        ),
                        child: Text(
                          item.statusBadgeText.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: item.statusBadgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Footer: Open Ledger Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          final emp = eco.employees.firstWhere(
                            (e) => e.id == item.employeeId,
                            orElse: () => eco.employees.first,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HrEmployeeInspectionScreen(employee: emp),
                            ),
                          );
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.assignment_ind_outlined, size: 12, color: AppColors.sandGold),
                            SizedBox(width: 3),
                            Text(
                                  'Dossier',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.sandGold, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: () {
                              eco.setActiveEmployee(item.employeeId);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AttendancePillarScreen()),
                              );
                            },
                            child: Row(
                              children: const [
                                Text(
                                  'Open Biometric Ledger',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.sandLight, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 3),
                                Icon(Icons.arrow_forward_ios, size: 9, color: AppColors.sandLight),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildStaffDossiersDirectoryTab(BuildContext context, EcosystemProvider eco) {
    final allEmployees = eco.employees;
    final adminEmployees = allEmployees.where((e) =>
      e.dept.toLowerCase().contains('admin') ||
      e.roleType.toLowerCase() == 'ceo' ||
      e.roleType.toLowerCase() == 'hr' ||
      e.id == 'MN-CEO01' ||
      e.id == 'MN-HR1001'
    ).toList();
    
    final onlineEmployees = allEmployees.where((e) =>
      !adminEmployees.any((a) => a.id == e.id)
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sandGold.withOpacity(0.15),
                ),
                child: const Icon(Icons.badge_outlined, color: AppColors.sandGold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPANY EMPLOYEE DOSSIERS',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select any staff profile to view KYC, document custody, attendance records, and reset portal passwords.',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 1. Administration Section (CEO & HR)
        if (adminEmployees.isNotEmpty) ...[
          _ceoDeptHeader(
            title: 'Administration',
            icon: Icons.admin_panel_settings_outlined,
            count: adminEmployees.length,
            accent: AppColors.sandGold,
          ),
          const SizedBox(height: 10),
          ...adminEmployees.map((emp) => _buildCeoStaffCard(context, eco, emp)),
          const SizedBox(height: 14),
        ],

        // 2. Online Department Section (Operations & TL)
        if (onlineEmployees.isNotEmpty) ...[
          _ceoDeptHeader(
            title: 'Online Department',
            icon: Icons.corporate_fare_rounded,
            count: onlineEmployees.length,
            accent: AppColors.sandLight,
          ),
          const SizedBox(height: 10),
          ...onlineEmployees.map((emp) => _buildCeoStaffCard(context, eco, emp)),
        ],
      ],
    );
  }

  Widget _ceoDeptHeader({
    required String title,
    required IconData icon,
    required int count,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Text(
              '$count Staff',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCeoStaffCard(BuildContext context, EcosystemProvider eco, Employee emp) {
    final isAbsent = eco.isEmployeeAbsent(emp.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAbsent ? const Color(0xFFFECDD3).withOpacity(0.5) : AppColors.sandBorder.withOpacity(0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tappable Header leading to full Inspection Dossier
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HrEmployeeInspectionScreen(employee: emp),
              ),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isAbsent ? AppColors.ragRed : AppColors.sandGold.withOpacity(0.2),
                    child: Text(
                      emp.initials,
                      style: TextStyle(
                        color: isAbsent ? Colors.white : AppColors.sandGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.name,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${emp.straightCutDesignation} • ${emp.dept}',
                          style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${emp.phone} • ${emp.email}',
                          style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  LiquidGlassPill(
                    label: isAbsent ? 'ABSENT' : 'PRESENT',
                    color: isAbsent ? AppColors.ragRed : AppColors.ragGreen,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.sandGold),
                ],
              ),
            ),
          ),

          // Inline Password & Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F4),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(top: BorderSide(color: AppColors.sandBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    InkWell(
                      onTap: () => _openResetPasswordDialog(context, eco, emp),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.sandGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_reset, size: 11, color: AppColors.sandGold),
                            const SizedBox(width: 3),
                            Text(
                              'Reset Password',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sandGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!emp.isCeo)
                      InkWell(
                        onTap: () => _confirmRelieveEmployee(context, eco, emp),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_remove_outlined, size: 11, color: Color(0xFFEF4444)),
                              const SizedBox(width: 3),
                              Text(
                                'Relieve Staff',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRelieveEmployee(BuildContext context, EcosystemProvider eco, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 8),
            Text(
              'Relieve Staff Member',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to officially relieve ${emp.name} (EMP #${emp.empNo.isNotEmpty ? emp.empNo : emp.id}) from MN Jewel Park?\n\n'
          'This will revoke app login credentials, relieve them from duties, and remove them from active workforce rosters.',
          style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.sandLight, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final name = emp.name;
              final idStr = emp.empNo.isNotEmpty ? 'EMP #${emp.empNo}' : emp.id;
              final success = eco.relieveEmployee(emp.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: success ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                  duration: Duration(seconds: success ? 4 : 7),
                  content: Text(success
                      ? '$name ($idStr) has been relieved and their sign-in switched off.'
                      : (eco.notificationMessage ?? 'Could not relieve $name.')),
                ),
              );
            },
            child: const Text('Relieve from Company'),
          ),
        ],
      ),
    );
  }

  void _openResetPasswordDialog(BuildContext context, EcosystemProvider eco, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.sandGold.withOpacity(0.4)),
        ),
        title: Text(
          'Reset Password',
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset portal password for ${emp.name}:',
              style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Text(
              'A secure reset link will be emailed to ${emp.email.isNotEmpty ? emp.email : 'their login email'}. '
              'They set the new password themselves, so it is never shared or visible to HR/CEO.',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sandGold,
              foregroundColor: AppColors.burgundyCard,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final error = await eco.adminResetEmployeePassword(empId: emp.id);
              if (ctx.mounted) Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(error ?? 'Password reset link sent to ${emp.email}. ${emp.name} must open it to set a new password.'),
                  backgroundColor: error == null ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                ),
              );
            },
            child: const Text('Send Reset Link', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _kpiPill(String label, String value, Color color, IconData icon, {VoidCallback? onTap, bool isSelected = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.18) : AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : color.withOpacity(0.4), width: isSelected ? 1.5 : 1.0),
          ),
          child: Column(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? color : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCreateStaffModal(BuildContext context, EcosystemProvider eco) {
    final empIdController = TextEditingController();
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final dobController = TextEditingController();
    final customDeptController = TextEditingController();
    DateTime? selectedDob;
    String selectedGender = 'Male';
    String roleHierarchy = 'HR Management'; // 'HR Management', 'Team Lead', 'Employee'
    String selectedDept = 'Online Department';
    bool isCustomDept = false;

    // Live search and sync state
    bool isSyncingSheets = false;
    String? syncStatusMessage;
    Employee? alreadyHiredStaff;
    List<GoogleSheetEmployeeEntry> matchedSheetStaff = [];
    GoogleSheetEmployeeEntry? selectedSheetStaff;

    void runInstantSearch(String query, StateSetter setModalState) {
      final clean = query.trim();
      if (clean.isEmpty) {
        setModalState(() {
          alreadyHiredStaff = null;
          matchedSheetStaff = [];
          selectedSheetStaff = null;
        });
        return;
      }

      final hired = eco.findHiredEmployeeByIdOrEmpNo(clean);
      if (hired != null) {
        setModalState(() {
          alreadyHiredStaff = hired;
          matchedSheetStaff = [];
          selectedSheetStaff = null;
        });
      } else {
        final matches = eco.findGoogleSheetEmployees(clean, unassignedOnly: true);
        setModalState(() {
          alreadyHiredStaff = null;
          matchedSheetStaff = matches;
          if (selectedSheetStaff != null && !matches.any((m) => m.empNo == selectedSheetStaff!.empNo)) {
            selectedSheetStaff = null;
          }
          // If exact match on empNo and name field is empty, automatically pre-fill name and credentials
          if (matches.length == 1 && matches.first.empNo.toLowerCase() == clean.toLowerCase() && nameController.text.trim().isEmpty) {
            final match = matches.first;
            selectedSheetStaff = match;
            nameController.text = match.name;
            final cleanName = match.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            emailController.text = '$cleanName@mnjewelpark.com';
            passwordController.text = generateTemporaryPassword();
          }
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.burgundySurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.sandGold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.shield_outlined, size: 16, color: AppColors.sandGold),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CEO: Provision Staff Account',
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sandLight,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Live Google Sheets Refresh Button
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: isSyncingSheets
                                  ? null
                                  : () async {
                                      setModalState(() {
                                        isSyncingSheets = true;
                                        syncStatusMessage = null;
                                      });
                                      final success = await eco.refreshGoogleSheetsAttendance();
                                      setModalState(() {
                                        isSyncingSheets = false;
                                        syncStatusMessage = success
                                            ? '✓ Sheets Synced (${eco.allGoogleSheetEmployees.length} rows)'
                                            : '⚠️ Sync failed';
                                      });
                                      runInstantSearch(empIdController.text, setModalState);
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.burgundyBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.sandBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSyncingSheets)
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sandGold),
                                      )
                                    else
                                      const Icon(Icons.refresh, size: 14, color: AppColors.sandGold),
                                    const SizedBox(width: 4),
                                    Text(
                                      isSyncingSheets ? 'Syncing...' : 'Refresh Sheets',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.sandGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.sandPrimary, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (syncStatusMessage != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: syncStatusMessage!.startsWith('✓') ? const Color(0x2210B981) : const Color(0x22EF4444),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: syncStatusMessage!.startsWith('✓') ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                        child: Text(
                          syncStatusMessage!,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: syncStatusMessage!.startsWith('✓') ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Role Type Selection
                    Text(
                      'Assign Operational Role:',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandGold, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                roleHierarchy = 'HR Management';
                                roleController.text = 'Head of People & HR';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: roleHierarchy == 'HR Management' ? AppColors.magentaPrimary : AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: roleHierarchy == 'HR Management' ? AppColors.magentaPrimary : AppColors.sandBorder,
                                  width: roleHierarchy == 'HR Management' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.badge, size: 16, color: roleHierarchy == 'HR Management' ? Colors.white : AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'HR',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: roleHierarchy == 'HR Management' ? Colors.white : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                roleHierarchy = 'Team Lead';
                                roleController.text = 'Online Department Team Lead';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: roleHierarchy == 'Team Lead' ? AppColors.magentaPrimary : AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: roleHierarchy == 'Team Lead' ? AppColors.magentaPrimary : AppColors.sandBorder,
                                  width: roleHierarchy == 'Team Lead' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shield_outlined, size: 16, color: roleHierarchy == 'Team Lead' ? Colors.white : AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Team Lead',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: roleHierarchy == 'Team Lead' ? Colors.white : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                roleHierarchy = 'Employee';
                                roleController.text = 'Online Department Executive';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: roleHierarchy == 'Employee' ? AppColors.magentaPrimary : AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: roleHierarchy == 'Employee' ? AppColors.magentaPrimary : AppColors.sandBorder,
                                  width: roleHierarchy == 'Employee' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person, size: 16, color: roleHierarchy == 'Employee' ? Colors.white : AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Employee',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: roleHierarchy == 'Employee' ? Colors.white : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Department Allocation
                    Text(
                      'Department Allocation:',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandGold, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Builder(builder: (_) {
                      final allDepts = eco.availableDepartments;
                      final effectiveSelected = isCustomDept
                          ? '__NEW__'
                          : (allDepts.contains(selectedDept) ? selectedDept : allDepts.first);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.burgundyBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.sandBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: effectiveSelected,
                                isExpanded: true,
                                dropdownColor: AppColors.burgundySurface,
                                icon: const Icon(Icons.arrow_drop_down, color: AppColors.sandGold),
                                style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 12),
                                items: [
                                  ...allDepts.map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: '__NEW__',
                                    child: Row(
                                      children: const [
                                        Icon(Icons.add_circle_outline, size: 14, color: AppColors.sandGold),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            '+ Create New Department...',
                                            style: TextStyle(color: AppColors.sandGold, fontWeight: FontWeight.bold, fontSize: 11),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == '__NEW__') {
                                      isCustomDept = true;
                                    } else {
                                      isCustomDept = false;
                                      selectedDept = val ?? 'Online Department';
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                          if (isCustomDept) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: customDeptController,
                              style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Enter new department name',
                                hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11),
                                filled: true,
                                fillColor: AppColors.burgundyBg,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandGold)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandGold)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
                    const SizedBox(height: 12),

                    // Gender Selection (Attire & Grooming Segregation)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gender (Attire & Grooming):',
                          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandGold, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: selectedGender == 'Female' ? const Color(0xFFFFF1F4) : const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: selectedGender == 'Female' ? const Color(0xFFFECDD3) : const Color(0xFFBAE6FD),
                            ),
                          ),
                          child: Text(
                            selectedGender == 'Female' ? 'Saree Specification' : 'Formal Wear Specification',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: selectedGender == 'Female' ? const Color(0xFFBE185D) : const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedGender = 'Male';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedGender == 'Male' ? const Color(0xFF0284C7) : AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedGender == 'Male' ? const Color(0xFF0284C7) : AppColors.sandBorder,
                                  width: selectedGender == 'Male' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.male, size: 18, color: selectedGender == 'Male' ? Colors.white : AppColors.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Male (Formal)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: selectedGender == 'Male' ? Colors.white : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedGender = 'Female';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: selectedGender == 'Female' ? AppColors.magentaPrimary : AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selectedGender == 'Female' ? AppColors.magentaPrimary : AppColors.sandBorder,
                                  width: selectedGender == 'Female' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.female, size: 18, color: selectedGender == 'Female' ? Colors.white : AppColors.textMuted),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Female (Saree)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: selectedGender == 'Female' ? Colors.white : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Employee ID Section (Manual Entry with Instant Search & Auto-Fill)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: alreadyHiredStaff != null
                              ? const Color(0xFFEF4444)
                              : (matchedSheetStaff.isNotEmpty ? const Color(0xFF10B981) : AppColors.sandBorder),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.badge_outlined, size: 15, color: AppColors.sandGold),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Employee ID (Manual Entry):',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.sandGold,
                                    ),
                                  ),
                                ],
                              ),
                              if (matchedSheetStaff.isNotEmpty && alreadyHiredStaff == null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x2210B981),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFF10B981)),
                                  ),
                                  child: Text(
                                    'Sheet Match',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF34D399),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Type Employee ID manually. Instantly searches database and Google Sheets.',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: empIdController,
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Enter Employee ID / Number',
                              labelStyle: GoogleFonts.outfit(color: AppColors.sandPrimary, fontSize: 11),
                              hintText: 'e.g. 75, 10, MN-1011...',
                              hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11),
                              filled: true,
                              fillColor: AppColors.burgundyBg,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              suffixIcon: empIdController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16, color: AppColors.sandPrimary),
                                      onPressed: () {
                                        empIdController.clear();
                                        runInstantSearch('', setModalState);
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (val) {
                              runInstantSearch(val, setModalState);
                            },
                          ),

                          // Instant Search Feedback 1: ALREADY HIRED in Database
                          if (alreadyHiredStaff != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0x33EF4444),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFEF4444)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.cancel, color: Color(0xFFF87171), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ALREADY HIRED IN DATABASE',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFCA5A5),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Employee ID "${empIdController.text.trim()}" is already registered as ${alreadyHiredStaff!.name} (${alreadyHiredStaff!.role}, ${alreadyHiredStaff!.dept}).',
                                          style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.sandLight),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Cannot add duplicate Employee ID.',
                                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFF87171)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]

                          // Instant Search Feedback 2: MATCHED IN GOOGLE SHEETS
                          else if (matchedSheetStaff.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0x2210B981),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline, color: Color(0xFF34D399), size: 15),
                                      const SizedBox(width: 6),
                                      Text(
                                        'FOUND IN GOOGLE SHEETS (${matchedSheetStaff.length} match)',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF34D399),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ...matchedSheetStaff.map((sheetEmp) {
                                    final isSelected = selectedSheetStaff?.empNo == sheetEmp.empNo;
                                    return InkWell(
                                      onTap: () {
                                        setModalState(() {
                                          selectedSheetStaff = sheetEmp;
                                          empIdController.text = sheetEmp.empNo;
                                          nameController.text = sheetEmp.name;
                                          final cleanName = sheetEmp.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
                                          emailController.text = '$cleanName@mnjewelpark.com';
                                          passwordController.text = generateTemporaryPassword();
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0x3310B981) : AppColors.burgundyBg,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: isSelected ? const Color(0xFF10B981) : AppColors.sandBorder),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'EMP #${sheetEmp.empNo} — ${sheetEmp.name}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.sandLight,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isSelected ? const Color(0xFF059669) : const Color(0xFF10B981),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isSelected ? 'Selected' : 'Auto-fill',
                                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ]

                          // Instant Search Feedback 3: CUSTOM / MANUAL ID
                          else if (empIdController.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.info_outline, size: 13, color: AppColors.sandPrimary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Custom ID "${empIdController.text.trim()}". Enter candidate details below.',
                                    style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.sandPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Full Name
                    Text(
                      'Candidate Full Name:',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Meera Krishnan',
                        hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.burgundyBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Birthday Date (DOB)
                    Text(
                      'Birthday Date (DOB):',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDob ?? DateTime(now.year - 22, 1, 1),
                          firstDate: DateTime(1950),
                          lastDate: now,
                          builder: (pickerCtx, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.magentaPrimary,
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: AppColors.textDark,
                                ),
                                dialogBackgroundColor: Colors.white,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDob = picked;
                            dobController.text =
                                '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: dobController,
                          style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Tap to select Birthday Date (DD-MM-YYYY)',
                            hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11.5),
                            filled: true,
                            fillColor: AppColors.burgundyBg,
                            prefixIcon: const Icon(Icons.cake_outlined, size: 18, color: AppColors.sandPrimary),
                            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.sandPrimary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.sandBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.sandBorder),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Email and Phone
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Official Email (Login ID):',
                                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: emailController,
                                style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'hr@mnjewelpark.com',
                                  hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11),
                                  filled: true,
                                  fillColor: AppColors.burgundyBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phone Number:',
                                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: phoneController,
                                style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: '+91 98450 XXXXX',
                                  hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11),
                                  filled: true,
                                  fillColor: AppColors.burgundyBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Password and Role Title
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Password:',
                                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: passwordController,
                                style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Leave blank to auto-generate a secure password',
                                  hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11),
                                  filled: true,
                                  fillColor: AppColors.burgundyBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Role Title:',
                                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: roleController,
                                style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 12),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.burgundyBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    LiquidGlassButton(
                      label: alreadyHiredStaff != null ? 'Employee ID Already Hired' : 'Register Staff Account',
                      icon: alreadyHiredStaff != null ? Icons.block : Icons.person_add_alt_1_outlined,
                      onPressed: () {
                        final cleanEmpId = empIdController.text.trim();
                        if (cleanEmpId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFFEF4444),
                              content: Text('Please enter an Employee ID'),
                            ),
                          );
                          return;
                        }

                        final already = eco.findHiredEmployeeByIdOrEmpNo(cleanEmpId);
                        if (already != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFEF4444),
                              content: Text('Cannot hire: Employee ID "$cleanEmpId" is already hired (${already.name}).'),
                            ),
                          );
                          return;
                        }

                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: Color(0xFFEF4444),
                              content: Text('Please enter Candidate Full Name'),
                            ),
                          );
                          return;
                        }

                        final assignedRoleType = roleHierarchy == 'HR Management'
                            ? 'hr'
                            : (roleHierarchy == 'Team Lead' ? 'team_lead' : 'employee');

                        final cleanDept = isCustomDept
                            ? customDeptController.text.trim()
                            : selectedDept.trim();
                        final assignedDept = cleanDept.isNotEmpty
                            ? cleanDept
                            : (roleHierarchy == 'HR Management' ? 'HR & Administration' : 'Online Department');

                        if (isCustomDept && cleanDept.isNotEmpty) {
                          eco.createNewDepartment(cleanDept);
                        }

                        final staffEmail = emailController.text.trim().isNotEmpty
                            ? emailController.text.trim()
                            : '${nameController.text.trim().toLowerCase().replaceAll(' ', '.')}@mnjewelpark.com';

                        eco.addNewEmployee(
                          name: nameController.text.trim(),
                          role: roleController.text.trim().isNotEmpty ? roleController.text.trim() : 'Operational Executive',
                          roleType: assignedRoleType,
                          dept: assignedDept,
                          phone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : '+91 98450 00000',
                          email: staffEmail,
                          password: passwordController.text.trim(),
                          experienceCategory: 'experienced',
                          experienceYears: '3+ yrs in Corporate',
                          dob: dobController.text.trim().isNotEmpty ? dobController.text.trim() : '01-01-2000',
                          gender: selectedGender,
                          customEmpId: cleanEmpId,
                          empNo: cleanEmpId,
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('Registered $roleHierarchy: ${nameController.text.trim()} (EMP #$cleanEmpId) successfully!'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
