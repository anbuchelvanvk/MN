import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/role_app_bar.dart';
import '../../models/attendance_models.dart';
import '../../models/ecosystem_models.dart';
import '../../models/employee_model.dart';
import '../../models/profile_pillar_models.dart';
import '../../providers/ecosystem_provider.dart';
import '../auth/pillars_popup_dialog.dart';
import '../pillars/attendance_pillar_screen.dart';
import '../hr/hr_management_widgets.dart';
import '../../core/widgets/personal_todo_section.dart';
import '../orders/online_orders_handler_screen.dart';
import '../employee/employee_profile_screen.dart';
import '../../core/widgets/export_audit_modal.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../core/widgets/assign_tasks_to_others_modal.dart';
import '../../core/widgets/cross_dept_blocker_section.dart';
import '../../core/widgets/emergency_permission_modal.dart';
import '../../core/widgets/emergency_medical_leave_modal.dart';
import '../../core/widgets/prescription_viewer_dialog.dart';

class CeoSuiteScreen extends StatefulWidget {
  const CeoSuiteScreen({super.key});

  @override
  State<CeoSuiteScreen> createState() => _CeoSuiteScreenState();
}

class _CeoSuiteScreenState extends State<CeoSuiteScreen> {
  final ScrollController _mainScrollController = ScrollController();
  final ScrollController _tabsScrollController = ScrollController();
  final GlobalKey _tabSectionKey = GlobalKey();

  int _activeTab = 0; // 0: Role Allocation, 1: Pipelines & Blockers, 2: Delay Analytics, 3: Incidents
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
    final handovers = eco.handovers;
    final blockers = eco.blockers;

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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: LiquidGlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(14),
                borderColor: AppColors.goldPrimary.withOpacity(0.5),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.goldPrimary.withOpacity(0.4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          ceoEmp.initials,
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
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
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppColors.sandGold.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.sandGold.withOpacity(0.35), width: 0.8),
                                ),
                                child: Text(
                                  'ID: ${ceoEmp.id}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandGold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Managing Director & CEO',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.business_outlined, size: 10, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Text('${eco.employees.length} Corporate Staff', style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1))),
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
              ),
            ),
            const SizedBox(height: 12),

            // Online Orders Handler & Executive SLA Command Card (Database Integrated)
            LiquidGlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 18,
              borderColor: eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed : AppColors.goldPrimary.withOpacity(0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed : AppColors.goldBright,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Online Orders',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
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
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.3),
                  ),
                  const SizedBox(height: 12),

                  // 3 KPI metric tiles
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MN Jewel Park', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                              const SizedBox(height: 2),
                              Text('${eco.os1Orders.length} Orders (OS1)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Vadivam', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                              const SizedBox(height: 2),
                              Text('${eco.os2Orders.length} Orders (OS2)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed.withOpacity(0.18) : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed : Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Overdue SLA', style: TextStyle(fontSize: 10, color: eco.overdueOnlineOrders.isNotEmpty ? AppColors.ragRed : const Color(0xFF94A3B8))),
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
                      icon: const Icon(Icons.assignment_turned_in_outlined, size: 16, color: Colors.black),
                      label: const Text('Open Online Orders', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
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
                  child: LiquidGlassButton(
                    label: 'Assign Tasks to Others (${eco.absentEmployeeIds.length} Absent)',
                    icon: Icons.assignment_ind_outlined,
                    onPressed: () => AssignTasksToOthersModal.show(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
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

            // Segmented Tabs
            Container(
              key: _tabSectionKey,
              child: SingleChildScrollView(
                controller: _tabsScrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _tabChip(0, 'Roles & Permissions'),
                    _tabChip(7, 'Personal To-Dos'),
                    _tabChip(5, 'Social Causes (${eco.pendingSocialCauses.length})'),
                    _tabChip(6, 'Staff Tasks'),
                    _tabChip(4, 'Attendance'),
                    _tabChip(1, 'Pipelines & Blockers'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Tab Content
            if (_activeTab == 0) ...[
              _buildRoleAllocationTab(context, eco),
            ] else if (_activeTab == 7) ...[
              const PersonalTodoSectionWidget(
                title: 'Personal To-Dos',
                subtitle: 'Strategic priorities & reviews',
              ),
            ] else if (_activeTab == 5) ...[
              HrSocialCauseApprovalSection(
                reviewerName: ceoEmp.name,
                reviewerRole: ceoEmp.role,
              ),
            ] else if (_activeTab == 6) ...[
              HrEmployeeTodoManagementSection(
                authorizedName: ceoEmp.name,
                authorizedRole: ceoEmp.role,
              ),
            ] else if (_activeTab == 4) ...[
              _buildBiometricAttendanceTab(context, eco),
            ] else ...[
              _buildHandoverAndBlockerTab(context, eco, handovers, blockers),
            ],
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

  Widget _tabChip(int index, String label) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldPrimary : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.goldPrimary : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.black : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  // --- ROLE ALLOCATION & EXECUTIVE PRIVILEGES TAB ---

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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
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
                child: const Icon(Icons.admin_panel_settings, color: Colors.black, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROLE & PRIVILEGE ALLOCATION',
                      style: GoogleFonts.cinzel(
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
                        color: AppColors.sandPrimary,
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
          label: '+ Create & Register HR / Executive Staff',
          icon: Icons.person_add_alt_1,
          onPressed: () => _openCreateStaffModal(context, eco),
        ),
        const SizedBox(height: 16),

        // 2. Type and Search Employee Filter
        Text(
          '1. SELECT EMPLOYEE (TYPE & SEARCH)',
          style: GoogleFonts.cinzel(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: AppColors.sandGold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _employeeSearchController,
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
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
                      style: GoogleFonts.cinzel(
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
                                style: GoogleFonts.cinzel(
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
              const Divider(color: AppColors.sandBorder, height: 20),

              // 4. Department Dropdown Selector
              Text(
                'ASSIGN SHOWROOM DEPARTMENT',
                style: GoogleFonts.cinzel(
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
                style: GoogleFonts.cinzel(
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
                        Icon(p?.icon ?? Icons.badge, size: 14, color: isRoleActive ? Colors.black : col),
                        const SizedBox(width: 6),
                        Text(
                          role,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isRoleActive ? Colors.black : AppColors.sandLight,
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
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: roleConfig.badgeColor.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(roleConfig.icon, color: roleConfig.badgeColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CORE MANDATES & DUTIES FOR ${_selectedRole.toUpperCase()}',
                      style: GoogleFonts.cinzel(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: roleConfig.badgeColor,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...roleConfig.responsibilities.map((resp) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline, size: 14, color: roleConfig.badgeColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          resp,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.sandLight,
                            height: 1.35,
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
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.stars, color: AppColors.sandGold, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'OPERATIONAL PERKS & PRIVILEGES',
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandGold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Toggle clearances granted to ${activeEmp.name}:',
                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF94A3B8)),
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
                  activeColor: AppColors.sandGold,
                  checkColor: Colors.black,
                  value: isGranted,
                  title: Text(
                    perk,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: isGranted ? FontWeight.bold : FontWeight.normal,
                      color: isGranted ? AppColors.sandLight : const Color(0xFF94A3B8),
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
          icon: const Icon(Icons.verified, size: 18, color: Colors.black),
          label: Text(
            'CONFIRM & ALLOCATE ROLE',
            style: GoogleFonts.cinzel(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              letterSpacing: 0.6,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sandGold,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 8,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              '1. Inter-Department Handover Pipeline',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'Workshop → Assay → Showroom',
              style: TextStyle(fontSize: 10.5, color: AppColors.goldLight),
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    LiquidGlassPill(
                      label: isCompleted ? 'COMPLETED' : 'IN PROGRESS',
                      color: isCompleted ? AppColors.ragGreen : AppColors.goldPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Current Stage: ${ho.stage}', style: const TextStyle(fontSize: 11, color: AppColors.goldBright)),
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
                              ? AppColors.ragGreen.withOpacity(0.2)
                              : (isInProg ? AppColors.goldPrimary.withOpacity(0.2) : Colors.white.withOpacity(0.04)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDone
                                ? AppColors.ragGreen.withOpacity(0.5)
                                : (isInProg ? AppColors.goldPrimary.withOpacity(0.5) : Colors.white12),
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
                      const Text('Assign Task to Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Text('Assign a direct task to any employee.', style: TextStyle(fontSize: 11, color: AppColors.goldLight)),
                  const SizedBox(height: 12),

                  const Text('Select Employee:', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: staffList.any((e) => e.id == selectedEmp) ? selectedEmp : staffList.first.id,
                    isExpanded: true,
                    dropdownColor: AppColors.burgundySurface,
                    style: const TextStyle(color: AppColors.sandLight, fontSize: 12),
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
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedEmp = v);
                    },
                  ),
                  const SizedBox(height: 10),

                  const Text('Task Title:', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Enter task title...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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

  void _openRaiseBlockerDialog(BuildContext context, EcosystemProvider eco) {
    String fromDept = 'Showroom Sales';
    String toDept = 'Workshop Crafting';
    final issueController = TextEditingController();

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
                      const Text('Raise Blocker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('From:', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: fromDept,
                              dropdownColor: AppColors.burgundySurface,
                              style: const TextStyle(color: Colors.white, fontSize: 11.5),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Showroom Sales', child: Text('Sales')),
                                DropdownMenuItem(value: 'Workshop Crafting', child: Text('Workshop')),
                                DropdownMenuItem(value: 'Quality Assay QA', child: Text('Assay QA')),
                                DropdownMenuItem(value: 'Vault Security', child: Text('Vault')),
                              ],
                              onChanged: (v) {
                                if (v != null) setModalState(() => fromDept = v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Against:', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: toDept,
                              dropdownColor: AppColors.burgundySurface,
                              style: const TextStyle(color: Colors.white, fontSize: 11.5),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Workshop Crafting', child: Text('Workshop')),
                                DropdownMenuItem(value: 'Showroom Sales', child: Text('Sales')),
                                DropdownMenuItem(value: 'Quality Assay QA', child: Text('Assay QA')),
                                DropdownMenuItem(value: 'Vault Security', child: Text('Vault')),
                              ],
                              onChanged: (v) {
                                if (v != null) setModalState(() => toDept = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  const Text('Problem / Reason:', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: issueController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  LiquidGlassButton(
                    label: 'Report Blocker',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.ragRed,
                    onPressed: () {
                      eco.raiseBlocker(
                        raisedByDept: fromDept,
                        raisedByName: 'Executive Desk',
                        blockingDept: toDept,
                        issue: issueController.text,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Blocker reported successfully!')),
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
      final s = allSummaries.firstWhere((x) => x.employeeId == e.id, orElse: () => null as dynamic);
      return s != null && s.isPresent && s.logoutPunch == null;
    }).toList();
    final shiftOverEmps = eco.employees.where((e) {
      final s = allSummaries.firstWhere((x) => x.employeeId == e.id, orElse: () => null as dynamic);
      return s != null && s.isPresent && s.logoutPunch != null;
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
      borderColor: absentEmps.isNotEmpty ? const Color(0xFFEF4444).withOpacity(0.4) : AppColors.goldPrimary.withOpacity(0.4),
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
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          dateStr,
                          style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isAttendanceExpanded ? 'Hide' : 'View Staff',
                  style: const TextStyle(fontSize: 11, color: AppColors.sandGold, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 2),
                Icon(
                  _isAttendanceExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppColors.sandGold,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isPresentActive ? const Color(0xFF064E3B).withOpacity(0.7) : const Color(0xFF064E3B).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPresentActive ? const Color(0xFF10B981) : const Color(0xFF10B981).withOpacity(0.4),
                          width: isPresentActive ? 1.6 : 1.0,
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
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'On Duty',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF6EE7B7), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
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
                              color: Colors.white,
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
                              color: isPresentActive ? const Color(0xFF6EE7B7) : const Color(0xFF94A3B8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isAbsentActive ? const Color(0xFF450A0A).withOpacity(0.7) : const Color(0xFF450A0A).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAbsentActive ? const Color(0xFFEF4444) : const Color(0xFFEF4444).withOpacity(0.4),
                          width: isAbsentActive ? 1.6 : 1.0,
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
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'Off Duty',
                                    style: TextStyle(fontSize: 10, color: Color(0xFFFCA5A5), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
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
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isAbsentActive ? 'Viewing absent ▼' : 'Tap to view',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: isAbsentActive ? const Color(0xFFFCA5A5) : const Color(0xFF94A3B8),
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
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                            color: isAbsent ? const Color(0xFFEF4444).withOpacity(0.08) : Colors.white.withOpacity(0.04),
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
                                              color: Colors.white,
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
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
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
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AttendancePillarScreen()),
                          );
                        },
                        icon: const Icon(Icons.fingerprint, size: 12, color: AppColors.sandGold),
                        label: const Text('Biometric Ledger', style: TextStyle(fontSize: 10.5, color: AppColors.sandGold)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sandGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          setState(() => _activeTab = 4);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_tabSectionKey.currentContext != null) {
                              Scrollable.ensureVisible(
                                _tabSectionKey.currentContext!,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                            if (_tabsScrollController.hasClients) {
                              _tabsScrollController.animateTo(
                                260.0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                              );
                            }
                          });
                        },
                        icon: const Icon(Icons.arrow_downward, size: 12, color: Colors.black),
                        label: const Text('Open Attendance Tab', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                    ],
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sandGold : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.sandGold : Colors.white.withOpacity(0.12),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

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
                  backgroundColor: AppColors.sandGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => EmergencyPermissionModal.show(context),
                icon: const FaIcon(FontAwesomeIcons.clock, size: 13, color: Colors.black),
                label: const Text('Permission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => EmergencyMedicalLeaveModal.show(context),
                icon: const FaIcon(FontAwesomeIcons.kitMedical, size: 13, color: Colors.white),
                label: const Text('Medical Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
                      style: GoogleFonts.cinzel(
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
                      color: isOrange ? AppColors.ragYellow.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOrange ? AppColors.ragYellow : Colors.white.withOpacity(0.1),
                        width: isOrange ? 1.0 : 0.6,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: AppColors.sandGold.withOpacity(0.2),
                              child: Text(
                                (p.employeeName?.substring(0, 1) ?? 'E'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.sandGold),
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
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
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
                                foregroundColor: Colors.black,
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
                              icon: const Icon(Icons.check, size: 12, color: Colors.black),
                              label: const Text('Accept & Approve', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
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
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
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
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
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
                                backgroundColor: AppColors.sandGold.withOpacity(0.15),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => PrescriptionViewerDialog.show(context, leave: m, isCeo: true),
                              icon: const Icon(Icons.image, size: 13, color: AppColors.sandGold),
                              label: const Text('View Prescription', style: TextStyle(fontSize: 10.5, color: AppColors.sandGold, fontWeight: FontWeight.bold)),
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
                                foregroundColor: Colors.black,
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
                              icon: const Icon(Icons.check, size: 12, color: Colors.black),
                              label: const Text('Accept Medical Leave', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
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
          style: GoogleFonts.cinzel(
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Top Row: Avatar, Name, Dept, Status Badge
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.sandGold.withOpacity(0.2),
                        child: Text(
                          item.initials,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.sandGold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
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
                                style: GoogleFonts.cinzel(
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
                                style: GoogleFonts.cinzel(
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
                      Text(
                        item.isLeftEarly
                            ? 'Net Working: ${item.workHoursFormatted} (Left Early)'
                            : 'Net Working: ${item.workHoursFormatted}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: item.isLeftEarly ? const Color(0xFFF59E0B) : AppColors.sandGold,
                        ),
                      ),
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
            ),
          ],
        );
      },
        ),
      ],
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
                style: GoogleFonts.cinzel(fontSize: 13, fontWeight: FontWeight.bold, color: color),
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
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String roleHierarchy = 'HR Management'; // 'HR Management', 'Team Lead', 'Employee'

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
                        Text(
                          'CEO: Create & Provision Staff',
                          style: GoogleFonts.cinzel(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.sandPrimary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
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
                                color: roleHierarchy == 'HR Management' ? AppColors.burgundyPrimary : AppColors.burgundyBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: roleHierarchy == 'HR Management' ? AppColors.sandGold : AppColors.sandBorder,
                                  width: roleHierarchy == 'HR Management' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.badge, size: 16, color: roleHierarchy == 'HR Management' ? AppColors.sandGold : AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'HR',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: roleHierarchy == 'HR Management' ? AppColors.sandLight : AppColors.textMuted,
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
                                color: roleHierarchy == 'Team Lead' ? AppColors.burgundyPrimary : AppColors.burgundyBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: roleHierarchy == 'Team Lead' ? AppColors.sandGold : AppColors.sandBorder,
                                  width: roleHierarchy == 'Team Lead' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shield_outlined, size: 16, color: roleHierarchy == 'Team Lead' ? AppColors.sandGold : AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Team Lead',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: roleHierarchy == 'Team Lead' ? AppColors.sandLight : AppColors.textMuted,
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
                                color: roleHierarchy == 'Employee' ? AppColors.burgundyPrimary : AppColors.burgundyBg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: roleHierarchy == 'Employee' ? AppColors.sandGold : AppColors.sandBorder,
                                  width: roleHierarchy == 'Employee' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person, size: 16, color: roleHierarchy == 'Employee' ? AppColors.sandGold : AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Employee',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: roleHierarchy == 'Employee' ? AppColors.sandLight : AppColors.textMuted,
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
                      label: 'Register Staff Account',
                      icon: Icons.person_add_alt_1_outlined,
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;
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
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('Registered $roleHierarchy: ${nameController.text.trim()} successfully!'),
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
