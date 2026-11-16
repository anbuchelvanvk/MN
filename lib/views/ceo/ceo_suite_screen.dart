import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../pillars/attendance_pillar_screen.dart';
import '../hr/hr_management_widgets.dart';
import '../orders/online_orders_handler_screen.dart';
import '../employee/employee_profile_screen.dart';
import '../../core/widgets/export_audit_modal.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../core/widgets/assign_tasks_to_others_modal.dart';
import '../../core/widgets/cross_dept_blocker_section.dart';
import '../../core/widgets/emergency_permission_modal.dart';
import '../../core/widgets/emergency_medical_leave_modal.dart';
import '../../core/widgets/prescription_viewer_dialog.dart';
import '../hr/hr_employee_inspection_screen.dart';
import '../../core/widgets/quick_pillar_nav_row.dart';
import 'ceo_subpages.dart';
import '../notes/personal_notes_screen.dart';

class CeoSuiteScreen extends StatefulWidget {
  const CeoSuiteScreen({super.key});

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
  final Map<String, bool> _revealedPasswords = {};

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eco = context.read<EcosystemProvider>();
      if (eco.activeEmpId != 'MN-CEO01') {
        eco.setActiveEmpId('MN-CEO01');
      }
      if (mounted) {
        PillarsPopupDialog.show(context);
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
        password: 'adminnaandhan',
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
                          child: Center(
                            child: Text(
                              ceoEmp.initials,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
                                        fontSize: 10.5,
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
                                        Text('${eco.employees.length} Corporate Staff', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
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
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ragGreen),
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
                          'EXECUTIVE COMMAND PORTALS',
                          style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _verticalCeoTabTile(
                        context: context,
                        eco: eco,
                        label: 'Roles & Privileges',
                        icon: Icons.admin_panel_settings_outlined,
                        badge: '',
                        destination: const CeoRolesPrivilegesScreen(),
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
                        label: 'Leaves & Slips',
                        icon: Icons.beach_access_outlined,
                        badge: (eco.pendingCeoPermissions.length + eco.pendingCeoMedicalLeaves.length) > 0 ? '${eco.pendingCeoPermissions.length + eco.pendingCeoMedicalLeaves.length}' : '',
                        destination: const CeoLeavesSlipsScreen(),
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
                            fontSize: 10,
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
                              const Text('MN Jewel Park', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
                              const Text('Vadivam', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
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
                              Text('Overdue SLA', style: TextStyle(fontSize: 10, color: eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed : AppColors.textSecondary)),
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
                  color: AppColors.magentaSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Executive authority to reassign departments, grant leadership tiers (Dept Head, HR, Employee, CEO), and designate task assignment perks.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: AppColors.sandGold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _employeeSearchController,
          style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: AppColors.sandGold, size: 20),
            hintText: 'Type employee name, ID, or role...',
            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 12),
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
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.sandGold : AppColors.sandLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${emp.id} • ${emp.dept}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: const Color(0xFF94A3B8)),
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
                      style: GoogleFonts.plusJakartaSans(
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
                                style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
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
                          style: GoogleFonts.plusJakartaSans(
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
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
                              style: GoogleFonts.plusJakartaSans(
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
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
                          style: GoogleFonts.plusJakartaSans(
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
                      style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
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
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              ...[
                'Can Assign Works to Others',
                'Can Approve Negotiation Discounts (Up to 3%)',
                'Can Approve Staff Permission & Leave Slips',
                'Vault Key Custodian Clearance (Physical Locker)',
                'Priority Showroom Shift Scheduling',
                'Direct Hotline Clearance to CEO Office',
              ].map((perk) {
                final isGranted = _selectedPerks.contains(perk);
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.magentaPrimary,
                  checkColor: Colors.white,
                  value: isGranted,
                  title: Text(
                    perk,
                    style: GoogleFonts.plusJakartaSans(
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
                );
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
            style: GoogleFonts.plusJakartaSans(
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
          onPressed: () {
            eco.allocateEmployeeRole(
              empId: activeEmp.id,
              newRole: _selectedRole,
              newDept: _selectedDept,
              perks: _selectedPerks.toList(),
              responsibilities: roleConfig.responsibilities,
            );
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
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.magentaPrimary),
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
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isDone ? AppColors.ragGreen : (isInProg ? AppColors.goldBright : const Color(0xFF64748B)),
                              ),
                            ),
                            Text(
                              step.completedBy ?? 'Pending',
                              style: const TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8)),
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
                    value: staffList.any((e) => e.id == selectedEmp) ? selectedEmp : staffList.first.id,
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
                    onPressed: () {
                      if (selectedEmp == null) return;
                      final t = titleController.text.trim();
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
    final onDutyEmps = eco.employees.where((e) {
      final matches = allSummaries.where((x) => x.employeeId == e.id);
      if (matches.isEmpty) return false;
      final s = matches.first;
      return s.isPresent && s.logoutPunch == null;
    }).toList();
    final shiftOverEmps = eco.employees.where((e) {
      final matches = allSummaries.where((x) => x.employeeId == e.id);
      if (matches.isEmpty) return false;
      final s = matches.first;
      return s.isPresent && s.logoutPunch != null;
    }).toList();
    final absentEmps = eco.employees.where((e) => eco.isEmployeeAbsent(e.id)).toList();
    final totalStaff = eco.employees.length;

    List<Employee> displayedList;
    if (_attendanceFilter == 'present') {
      displayedList = eco.employees.where((e) => !eco.isEmployeeAbsent(e.id)).toList();
    } else if (_attendanceFilter == 'on_duty') {
      displayedList = onDutyEmps;
    } else if (_attendanceFilter == 'shift_over') {
      displayedList = shiftOverEmps;
    } else if (_attendanceFilter == 'absent') {
      displayedList = absentEmps;
    } else {
      displayedList = eco.employees;
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
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Expanded(
                                child: Text(
                                  'On Duty',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isPresentActive ? Icons.check_circle : Icons.check_circle_outline,
                                size: 14,
                                color: const Color(0xFF10B981),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${onDutyEmps.length} On Duty',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shiftOverEmps.isNotEmpty
                                ? '${shiftOverEmps.length} Shift Over'
                                : (isPresentActive ? 'Viewing on duty ▼' : 'Tap to view'),
                            style: TextStyle(
                              fontSize: 9.5,
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

              // Absent Counter Tile
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
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Expanded(
                                child: Text(
                                  'Off Duty',
                                  style: TextStyle(fontSize: 10, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isAbsentActive ? Icons.error : Icons.error_outline,
                                size: 14,
                                color: const Color(0xFFEF4444),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${absentEmps.length} Absent',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ragRed,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAbsentActive ? 'Viewing absent ▼' : 'Tap to view',
                            style: TextStyle(
                              fontSize: 9.5,
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
                              ? 'No staff are absent today. Full team is on duty.'
                              : (_attendanceFilter == 'shift_over'
                                  ? 'No staff have completed their shift yet today.'
                                  : 'No staff members found.'),
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

                        String timeInfo = '';
                        if (isAbsent) {
                          timeInfo = ' • Absent';
                        } else if (summary.logoutPunch != null) {
                          timeInfo = ' • In: ${summary.inTimeString} • Out: ${summary.outTimeString}';
                        } else if (summary.loginPunch != null) {
                          timeInfo = ' • In: ${summary.inTimeString} • Working: ${summary.workHoursFormatted}';
                        }

                        String badgeText;
                        Color badgeColor;
                        if (isAbsent) {
                          badgeText = 'Absent';
                          badgeColor = const Color(0xFFEF4444);
                        } else if (summary.logoutPunch != null) {
                          if (summary.netWorkHours < 8.0) {
                            badgeText = 'Left Early (${summary.workHoursFormatted})';
                            badgeColor = const Color(0xFFF59E0B);
                          } else {
                            badgeText = 'Shift Over (${summary.workHoursFormatted})';
                            badgeColor = const Color(0xFF8B5CF6);
                          }
                        } else if (summary.isCurrentlyOnLunch) {
                          badgeText = 'On Lunch';
                          badgeColor = const Color(0xFF3B82F6);
                        } else {
                          badgeText = 'On Duty';
                          badgeColor = const Color(0xFF10B981);
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isAbsent ? const Color(0xFFFFF1F2) : AppColors.whiteBg,
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
                                    fontSize: 10,
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
                                              fontSize: 9.5,
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
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildCeoLeavesAndPermissionsTab(BuildContext context, EcosystemProvider eco) {
    final pendingPerms = eco.pendingCeoPermissions;
    final pendingMedLeaves = eco.pendingCeoMedicalLeaves;
    final totalPending = pendingPerms.length + pendingMedLeaves.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Executive Header Card
        LiquidGlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFBCFE8)),
                    ),
                    child: const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.magentaPrimary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CEO APPROVALS & LEAVE DESK',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Direct CEO authority for emergency permissions & medical leaves',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: totalPending > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: totalPending > 0 ? const Color(0xFFF59E0B) : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Text(
                      totalPending > 0 ? '$totalPending PENDING' : 'ALL APPROVED',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: totalPending > 0 ? const Color(0xFFD97706) : const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // CEO Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.magentaPrimary,
                        side: const BorderSide(color: AppColors.magentaBorder),
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => EmergencyPermissionModal.show(context),
                      icon: const Icon(Icons.access_time_rounded, size: 14, color: AppColors.magentaPrimary),
                      label: Text(
                        'Request Permission',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.magentaPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.magentaPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => EmergencyMedicalLeaveModal.show(context),
                      icon: const Icon(Icons.medical_services_outlined, size: 14, color: Colors.white),
                      label: Text(
                        'Medical Leave',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Section 1: Pending Permissions Awaiting CEO Action
        LiquidGlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Permissions (${pendingPerms.length})',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  if (pendingPerms.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Action Needed',
                        style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                      ),
                    ),
                ],
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 18),
              if (pendingPerms.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'No pending emergency permission requests awaiting CEO review.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...pendingPerms.map((p) {
                  final isOrange = p.isOrangeFlagged || p.requestedHours > 2.0;
                  final durText = p.actualHoursUsed < 1.0 ? '${(p.actualHoursUsed * 60).round()}m' : '${p.actualHoursUsed}h';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isOrange ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOrange ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                        width: isOrange ? 1.0 : 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.magentaSubtle,
                              child: Text(
                                (p.employeeName?.substring(0, 1) ?? 'E'),
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.magentaPrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${p.employeeName ?? p.empId} (${p.requesterRole ?? "Staff"})',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      ),
                                      if (isOrange) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFF59E0B), width: 0.6),
                                          ),
                                          child: Text(
                                            '>2h Orange Mark',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 8.5, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${p.department ?? "General"} • Permission: $durText • Reason: "${p.reason}"',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => eco.rejectPermission(p.id, rejectedBy: 'CEO'),
                              icon: const Icon(Icons.close, size: 12, color: Color(0xFFEF4444)),
                              label: Text('Reject', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFFEF4444))),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                eco.ceoApprovePermission(p.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Permission of $durText approved by CEO!')),
                                );
                              },
                              icon: const Icon(Icons.check, size: 12, color: Colors.white),
                              label: Text('Accept & Approve', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Section 2: Pending Medical Leaves Awaiting CEO Action
        LiquidGlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Medical Leaves (${pendingMedLeaves.length})',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  if (pendingMedLeaves.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Prescription Verification',
                        style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFFE11D48)),
                      ),
                    ),
                ],
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 18),
              if (pendingMedLeaves.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'No emergency medical leaves awaiting CEO review.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...pendingMedLeaves.map((m) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFFFFF1F2),
                              child: const Icon(Icons.local_hospital_outlined, size: 14, color: Color(0xFFE11D48)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${m.empName} • ${m.days} Day(s) Medical Leave',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  Text(
                                    'Reason: "${m.reason}" • Endorsed by HR: ${m.hrEndorsed ? "Yes" : "Pending"}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                              onPressed: () => PrescriptionViewerDialog.show(context, leave: m),
                              icon: const Icon(Icons.image, size: 13, color: AppColors.magentaPrimary),
                              label: Text('Prescription', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.magentaPrimary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => eco.rejectMedicalLeave(m.id, rejectedBy: 'CEO'),
                              icon: const Icon(Icons.close, size: 12, color: Color(0xFFEF4444)),
                              label: Text('Reject', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFFEF4444))),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                eco.ceoApproveMedicalLeave(m.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Emergency medical leave approved for ${m.empName}!')),
                                );
                              },
                              icon: const Icon(Icons.check, size: 12, color: Colors.white),
                              label: Text('Accept Medical Leave', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildBiometricAttendanceTab(BuildContext context, EcosystemProvider eco) {
    final summaries = eco.allEmployeesTodayAttendance;
    final total = summaries.length;
    final presentCount = summaries.where((s) => !eco.isEmployeeAbsent(s.employeeId)).length;
    final absentCount = summaries.where((s) => eco.isEmployeeAbsent(s.employeeId)).length;
    final onTimeCount = summaries.where((s) => s.status == DailyAttendanceStatus.presentOnTime).length;
    final lateCount = summaries.where((s) => s.status == DailyAttendanceStatus.lateLogin).length;
    final onLunchCount = summaries.where((s) => s.isCurrentlyOnLunch).length;

    List<EmployeeDailyAttendanceSummary> filteredSummaries = summaries;
    if (_attendanceTabFilter == 'present') {
      filteredSummaries = summaries.where((s) => !eco.isEmployeeAbsent(s.employeeId)).toList();
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
                  style: GoogleFonts.plusJakartaSans(
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

        // Emergency Quick Action Buttons (Permission & Medical Leave)
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.magentaSubtle,
                  foregroundColor: AppColors.magentaPrimary,
                  side: const BorderSide(color: AppColors.magentaBorder),
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () => EmergencyPermissionModal.show(context),
                icon: const Icon(Icons.access_time_rounded, size: 14, color: AppColors.magentaPrimary),
                label: const Text('Permission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.magentaPrimary)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.magentaPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                onPressed: () => EmergencyMedicalLeaveModal.show(context),
                icon: const Icon(Icons.medical_services_outlined, size: 14, color: Colors.white),
                label: const Text('Medical Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // CEO Approvals Pipeline: Emergency Permissions & Medical Leaves
        if (eco.pendingCeoPermissions.isNotEmpty || eco.pendingCeoMedicalLeaves.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ragYellow, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: AppColors.ragYellow, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'PENDING CEO ACCEPTANCE (${eco.pendingCeoPermissions.length + eco.pendingCeoMedicalLeaves.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ragYellow,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Emergency Permissions
                ...eco.pendingCeoPermissions.map((p) {
                  final isOrange = p.isOrangeFlagged || p.requestedHours > 2.0;
                  final durText = p.actualHoursUsed < 1.0 ? '${(p.actualHoursUsed * 60).round()}m' : '${p.actualHoursUsed}h';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isOrange ? AppColors.ragYellow.withOpacity(0.12) : AppColors.whiteBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOrange ? AppColors.ragYellow : AppColors.sandBorder,
                        width: isOrange ? 1.0 : 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: AppColors.magentaSubtle,
                              child: Text(
                                (p.employeeName?.substring(0, 1) ?? 'E'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.magentaPrimary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${p.employeeName ?? p.empId} (${p.requesterRole ?? "Staff"})',
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      ),
                                      if (isOrange) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.ragYellow.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: AppColors.ragYellow, width: 0.8),
                                          ),
                                          child: const Text(
                                            '>2h Orange Mark',
                                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.ragYellow),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${p.department ?? "General"} • Permission: $durText • Reason: "${p.reason}"',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.ragRed),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => eco.rejectPermission(p.id, rejectedBy: 'CEO'),
                              icon: const Icon(Icons.close, size: 12, color: AppColors.ragRed),
                              label: const Text('Reject', style: TextStyle(fontSize: 10.5, color: AppColors.ragRed)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ragGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                eco.ceoApprovePermission(p.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Permission of $durText approved by CEO!')),
                                );
                              },
                              icon: const Icon(Icons.check, size: 12, color: Colors.white),
                              label: const Text('Accept & Approve', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                // Emergency Medical Leaves
                ...eco.pendingCeoMedicalLeaves.map((m) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.whiteBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.sandBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.medical_services_outlined, color: Color(0xFFEF4444), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${m.empName} (${m.empRole}) • ${m.days} Days Medical Leave',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  Text(
                                    'Diagnosis: "${m.reason}" • Prescription Attached',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                backgroundColor: AppColors.magentaSubtle,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => PrescriptionViewerDialog.show(context, leave: m, isCeo: true),
                              icon: const Icon(Icons.image, size: 13, color: AppColors.magentaPrimary),
                              label: const Text('View Prescription', style: TextStyle(fontSize: 10.5, color: AppColors.magentaPrimary, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.ragRed),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => eco.rejectMedicalLeave(m.id, rejectedBy: 'CEO'),
                              icon: const Icon(Icons.close, size: 12, color: AppColors.ragRed),
                              label: const Text('Reject', style: TextStyle(fontSize: 10.5, color: AppColors.ragRed)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.ragGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                eco.ceoApproveMedicalLeave(m.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Emergency medical leave approved for ${m.empName}!')),
                                );
                              },
                              icon: const Icon(Icons.check, size: 12, color: Colors.white),
                              label: const Text('Accept Medical Leave', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

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
          style: GoogleFonts.plusJakartaSans(
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
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
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
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandLight,
                                ),
                              ),
                              Text(
                                '${item.employeeId} • ${item.department} (${item.role})',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
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
                          item.logoutPunch != null
                              ? '${item.statusBadgeText.toUpperCase()} (${item.workHoursFormatted})'
                              : item.statusBadgeText.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: item.statusBadgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3 Timestamps: In-Time, Lunch Break, Out-Time
                  Row(
                    children: [
                      // IN TIME
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.burgundySurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.sandBorder.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.login, size: 12, color: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text('In Time', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.inTimeString,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: item.isPresent ? AppColors.sandLight : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // LUNCH BREAK
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.burgundySurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: item.isCurrentlyOnLunch 
                                  ? const Color(0xFFF59E0B) 
                                  : AppColors.sandBorder.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.restaurant_outlined, 
                                    size: 12, 
                                    color: item.isCurrentlyOnLunch ? const Color(0xFFF59E0B) : const Color(0xFF60A5FA),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('Lunch Break', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.lunchSummary,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: item.lunchOutPunch != null ? AppColors.sandGold : AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // OUT TIME
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.burgundySurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.sandBorder.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.logout, size: 12, color: Color(0xFFEF4444)),
                                  SizedBox(width: 4),
                                  Text('Out Time', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.outTimeString,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: item.logoutPunch != null ? AppColors.sandLight : (item.isCurrentlyOnDuty ? const Color(0xFFF59E0B) : AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Footer: Net Hours + Open Ledger Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.isLeftEarly
                              ? 'Net Working: ${item.workHoursFormatted} (Left Early)'
                              : 'Net Working: ${item.workHoursFormatted}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: item.isLeftEarly ? const Color(0xFFF59E0B) : AppColors.sandGold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
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
                            child: Row(
                              children: const [
                                Icon(Icons.assignment_ind_outlined, size: 12, color: AppColors.sandGold),
                                SizedBox(width: 3),
                                Text(
                                  'Dossier',
                                  style: TextStyle(fontSize: 10, color: AppColors.sandGold, fontWeight: FontWeight.bold),
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
                                  style: TextStyle(fontSize: 10, color: AppColors.sandLight, fontWeight: FontWeight.bold),
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select any staff profile to view KYC, document custody, attendance records, and reset portal passwords.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
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
              style: GoogleFonts.plusJakartaSans(
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
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
    final isPasswordRevealed = _revealedPasswords[emp.id] ?? false;
    final empPassword = emp.password.isNotEmpty ? emp.password : 'password123';

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
                          style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${emp.phone} • ${emp.email}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
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

          // Inline Password & Reset Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F8),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(top: BorderSide(color: AppColors.sandBorder)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, size: 13, color: AppColors.sandGold),
                const SizedBox(width: 6),
                Text(
                  'Password: ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandGold,
                  ),
                ),
                Expanded(
                  child: Text(
                    isPasswordRevealed ? empPassword : '••••••••',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPasswordRevealed ? AppColors.sandLight : AppColors.textSecondary,
                      letterSpacing: isPasswordRevealed ? 0 : 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => setState(() => _revealedPasswords[emp.id] = !isPasswordRevealed),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isPasswordRevealed ? Icons.visibility_off : Icons.visibility,
                      size: 15,
                      color: AppColors.sandGold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: empPassword));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Password for ${emp.name} copied to clipboard!'),
                        backgroundColor: const Color(0xFF10B981),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy_rounded, size: 14, color: AppColors.sandLight),
                  ),
                ),
                const SizedBox(width: 6),
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
                          'Reset',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                          ),
                        ),
                      ],
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

  void _openResetPasswordDialog(BuildContext context, EcosystemProvider eco, Employee emp) {
    final newPassCtrl = TextEditingController();
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
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset portal password for ${emp.name}:',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPassCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.sandLight),
              decoration: InputDecoration(
                hintText: 'Enter new password (min 6 chars)',
                hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.6)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.sandBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.sandBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.magentaPrimary),
                ),
              ),
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
              final newPass = newPassCtrl.text.trim();
              if (newPass.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              await eco.adminResetEmployeePassword(empId: emp.id, newPassword: newPass);
              if (ctx.mounted) Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Password for ${emp.name} reset to: $newPass'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Save & Reset', style: TextStyle(fontWeight: FontWeight.bold)),
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
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8.5,
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
    DateTime? selectedDob;
    String selectedGender = 'Male';
    String roleHierarchy = 'HR Management'; // 'HR Management', 'Team Lead', 'Employee'

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
                              style: GoogleFonts.plusJakartaSans(
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
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandGold, fontWeight: FontWeight.bold),
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
                                    style: GoogleFonts.plusJakartaSans(
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
                                    style: GoogleFonts.plusJakartaSans(
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
                                    style: GoogleFonts.plusJakartaSans(
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

                    // Gender Selection (Attire & Grooming Segregation)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gender (Attire & Grooming):',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandGold, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: selectedGender == 'Female' ? const Color(0xFFFDF2F8) : const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: selectedGender == 'Female' ? const Color(0xFFFBCFE8) : const Color(0xFFBAE6FD),
                            ),
                          ),
                          child: Text(
                            selectedGender == 'Female' ? 'Saree Specification' : 'Formal Wear Specification',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
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
                                    style: GoogleFonts.plusJakartaSans(
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
                                    style: GoogleFonts.plusJakartaSans(
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
                                    style: GoogleFonts.plusJakartaSans(
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
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
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
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: empIdController,
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Enter Employee ID / Number',
                              labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.sandPrimary, fontSize: 11),
                              hintText: 'e.g. 75, 10, MN-1011...',
                              hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11),
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
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFCA5A5),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Employee ID "${empIdController.text.trim()}" is already registered as ${alreadyHiredStaff!.name} (${alreadyHiredStaff!.role}, ${alreadyHiredStaff!.dept}).',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.sandLight),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Cannot add duplicate Employee ID.',
                                          style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFFF87171)),
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
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
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
                                          passwordController.text = '$cleanName@mnj123';
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
                                                style: GoogleFonts.plusJakartaSans(
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
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.sandPrimary),
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Meera Krishnan',
                        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12),
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
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
                          style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Tap to select Birthday Date (DD-MM-YYYY)',
                            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11.5),
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
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: emailController,
                                style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'hr@mnjewelpark.com',
                                  hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11),
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
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: phoneController,
                                style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: '+91 98450 XXXXX',
                                  hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11),
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
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: passwordController,
                                style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Default: password123',
                                  hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11),
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
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: roleController,
                                style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
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
                        final assignedDept = roleHierarchy == 'HR Management' ? 'HR & Admin' : 'Online Department';
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
                          password: passwordController.text.trim().isNotEmpty ? passwordController.text.trim() : 'password123',
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
