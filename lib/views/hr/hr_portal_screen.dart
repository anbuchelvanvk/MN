import '../../core/widgets/export_audit_modal.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../core/widgets/cross_dept_blocker_section.dart';
import '../../core/widgets/assign_tasks_to_others_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/role_app_bar.dart';
import '../../models/attendance_models.dart';
import '../../models/employee_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../auth/pillars_popup_dialog.dart';
import '../pillars/attendance_pillar_screen.dart';
import 'hr_management_widgets.dart';
import '../../core/widgets/company_notification_sheet.dart';
import '../../core/widgets/personal_todo_section.dart';
import '../../core/widgets/emergency_permission_modal.dart';
import '../../core/widgets/emergency_medical_leave_modal.dart';
import '../../core/widgets/prescription_viewer_dialog.dart';

class HrPortalScreen extends StatefulWidget {
  const HrPortalScreen({super.key});

  @override
  State<HrPortalScreen> createState() => _HrPortalScreenState();
}

class _HrPortalScreenState extends State<HrPortalScreen> {
  int _activeTab = 0; // 0: Directory & Passwords, 4: Biometric Attendance, 2: Leave Delegation, 3: Grooming
  String _deptFilter = 'all';
  String _searchQuery = '';
  final Map<String, bool> _revealedPasswords = {};
  String? _selectedGroomingEmpId;
  String _selectedGroomingCategory = 'Uniform & Ironing';
  int _selectedPointsChange = 10;
  final TextEditingController _groomingRemarksCtrl = TextEditingController();

  @override
  void dispose() {
    _groomingRemarksCtrl.dispose();
    super.dispose();
  }

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

    final filteredEmployees = allEmployees.where((e) {
      final matchesDept = _deptFilter == 'all' || e.dept == _deptFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.id.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDept && matchesSearch;
    }).toList();

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
                        style: GoogleFonts.cinzel(
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
                  label: '+ New Hire',
                  icon: Icons.person_add_alt_1,
                  height: 34,
                  onPressed: () => _openAddHireDialog(context, eco),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4 Stat Tiles in Burgundy & Sand
            Row(
              children: [
                LiquidMetricCard(
                  label: 'Total Staff',
                  value: '${allEmployees.length}',
                  subtitle: 'Total Directory',
                  icon: Icons.groups_outlined,
                  color: AppColors.sandGold,
                  onTap: () => setState(() => _activeTab = 0),
                ),
                const SizedBox(width: 6),
                LiquidMetricCard(
                  label: 'Present',
                  value: '${allEmployees.where((e) => !eco.isEmployeeAbsent(e.id)).length}',
                  subtitle: 'Active Today',
                  icon: Icons.badge_outlined,
                  color: AppColors.sandPrimary,
                  onTap: () => setState(() => _activeTab = 4),
                ),
                const SizedBox(width: 6),
                LiquidMetricCard(
                  label: 'Leave Cover',
                  value: '${delegations.length}',
                  subtitle: 'Delegations',
                  icon: Icons.handshake_outlined,
                  color: AppColors.sandLight,
                  onTap: () => setState(() => _activeTab = 2),
                ),
                const SizedBox(width: 6),
                LiquidMetricCard(
                  label: 'Absent Staff',
                  value: '${eco.absentEmployeeIds.length}',
                  subtitle: 'Absent Today',
                  icon: Icons.person_off_outlined,
                  color: eco.absentEmployeeIds.isEmpty ? AppColors.ragGreen : AppColors.ragRed,
                  onTap: () => AssignTasksToOthersModal.show(context),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Assign Tasks to Others Primary Action Button
            LiquidGlassButton(
              label: 'Assign Tasks to Others (${eco.absentEmployeeIds.length} Absent)',
              icon: Icons.assignment_ind_outlined,
              height: 40,
              onPressed: () => AssignTasksToOthersModal.show(context),
            ),
            const SizedBox(height: 14),

            // HR Management Broadcast & To-Do Reminder Dispatcher
            const HrBroadcastSection(
              senderName: 'Mohankumar G (HR)',
              senderRole: 'HR Manager & Custodian',
            ),
            const SizedBox(height: 16),

            // Segmented Tabs
            SingleChildScrollView(
              key: const ValueKey('hr_tabs_scroll'),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _tabChip(0, 'Staff'),
                  _tabChip(6, 'Personal To-Dos'),
                  _tabChip(1, 'Social Causes (${eco.pendingSocialCauses.length})'),
                  _tabChip(5, 'Staff Tasks'),
                  _tabChip(7, 'Blocker Tickets'),
                  _tabChip(4, 'Attendance'),
                  _tabChip(2, 'Leaves & Permissions'),
                  _tabChip(3, 'Grooming'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tab Content
            if (_activeTab == 0) ...[
              _buildStaffDirectoryAndCredentials(context, eco, filteredEmployees),
            ] else if (_activeTab == 6) ...[
              const PersonalTodoSectionWidget(
                title: 'Personal To-Dos',
                subtitle: 'Daily tasks & checklists',
              ),
            ] else if (_activeTab == 1) ...[
              const HrSocialCauseApprovalSection(
                reviewerName: 'Mohankumar G (HR)',
                reviewerRole: 'HR Manager & Custodian',
              ),
            ] else if (_activeTab == 5) ...[
              const HrEmployeeTodoManagementSection(
                authorizedName: 'Mohankumar G (HR)',
                authorizedRole: 'HR Manager & Custodian',
              ),
            ] else if (_activeTab == 7) ...[
              const CrossDeptBlockerSection(
                department: 'Human Resources',
                isCeoView: true,
              ),
            ] else if (_activeTab == 4) ...[
              _buildHrAttendanceComplianceSection(context, eco),
            ] else if (_activeTab == 2) ...[
              _buildLeaveDelegationSection(context, eco, delegations),
            ] else ...[
              _buildGroomingAuditSection(context, eco),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.burgundyPrimary : AppColors.burgundySurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.sandLight : AppColors.sandPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStaffDirectoryAndCredentials(BuildContext context, EcosystemProvider eco, List<Employee> employees) {
    final deptsList = ['all', ...eco.employees.map((e) => e.dept).toSet()];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Box
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.burgundySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: AppColors.sandGold),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search staff by name, role, email, phone or ID...',
                    hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11.5),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Department Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: deptsList.map((d) {
              return _deptChip(d, d == 'all' ? 'All Units' : d);
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        if (employees.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sandBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              'No staff members found matching filter.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
            ),
          )
        else
          ...employees.map((emp) {
            final isAbsent = eco.isEmployeeAbsent(emp.id);
            final isPasswordRevealed = _revealedPasswords[emp.id] ?? false;
            final empPassword = emp.password.isNotEmpty ? emp.password : 'password123';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: LiquidGlassCard(
                padding: const EdgeInsets.all(14),
                borderRadius: 16,
                borderColor: isAbsent ? AppColors.ragRed.withOpacity(0.4) : AppColors.sandBorder,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Avatar, Name, Role, Status Pill
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.burgundySurface,
                          radius: 19,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: isAbsent ? AppColors.ragRed : AppColors.sandGold, width: 1.2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              emp.initials,
                              style: TextStyle(
                                color: isAbsent ? AppColors.ragRed : AppColors.sandGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      emp.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.sandLight,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '#${emp.id}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.sandPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Text(
                                emp.straightCutDesignation,
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        LiquidGlassPill(
                          label: isAbsent ? 'ABSENT' : 'PRESENT',
                          color: isAbsent ? AppColors.ragRed : AppColors.ragGreen,
                        ),
                        if (eco.canManageEmployees() &&
                            emp.roleType.toLowerCase() != 'ceo' &&
                            emp.roleType.toLowerCase() != 'hr' &&
                            emp.id.toUpperCase() != 'MN-CEO01' &&
                            emp.email.toLowerCase() != 'ceoofmn@mnjpark.com') ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.person_remove_outlined, size: 18, color: AppColors.ragRed),
                            tooltip: 'Remove Staff',
                            onPressed: () => _confirmRemoveEmployee(context, eco, emp),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ],
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 16),

                    // Row 2: Personal Details Grid
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _infoRow(Icons.phone_outlined, 'Mobile', emp.phone),
                              ),
                              Expanded(
                                child: _infoRow(Icons.email_outlined, 'Email', emp.email),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _infoRow(
                                  Icons.cake_outlined,
                                  'DOB',
                                  emp.dob.isNotEmpty ? emp.dob : 'Not provided',
                                ),
                              ),
                              Expanded(
                                child: _infoRow(
                                  Icons.favorite_outline,
                                  'Relationship',
                                  emp.relationshipStatus.isNotEmpty ? emp.relationshipStatus : 'Single',
                                ),
                              ),
                            ],
                          ),
                          if (emp.relationshipStatus.toLowerCase() == 'married' &&
                              emp.anniversaryDate.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _infoRow(Icons.celebration_outlined, 'Anniversary', emp.anniversaryDate),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Row 3: Credentials & Password Management Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.burgundyPrimary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.sandGold.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, size: 14, color: AppColors.sandGold),
                          const SizedBox(width: 6),
                          Text(
                            'Password: ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
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
                                color: isPasswordRevealed ? Colors.white : AppColors.sandLight,
                                letterSpacing: isPasswordRevealed ? 0 : 1.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Eye Toggle Button
                          InkWell(
                            onTap: () {
                              setState(() {
                                _revealedPasswords[emp.id] = !isPasswordRevealed;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                isPasswordRevealed ? Icons.visibility_off : Icons.visibility,
                                size: 16,
                                color: AppColors.sandLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // Copy Password Button
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: empPassword));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Password for ${emp.name} copied to clipboard!'),
                                  backgroundColor: AppColors.statusBlue,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.copy_rounded, size: 16, color: AppColors.sandLight),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Reset Password Button
                          InkWell(
                            onTap: () => _openPasswordResetDialog(context, eco, emp),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.sandGold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Reset',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.sandPrimary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$label: $value',
            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.sandLight),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _openPasswordResetDialog(BuildContext context, EcosystemProvider eco, Employee emp) {
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Reset Password: ${emp.name}',
            style: GoogleFonts.cinzel(color: AppColors.sandLight, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Employee ID: ${emp.id}', style: GoogleFonts.plusJakartaSans(color: AppColors.sandGold, fontSize: 11)),
              Text('Email: ${emp.email}', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11)),
              const SizedBox(height: 12),
              Text('Set New Password:', style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 11.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: newPassCtrl,
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter new password (min 6 characters)...',
                  hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12),
                  filled: true,
                  fillColor: AppColors.burgundyBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.sandGold),
              onPressed: () async {
                final newPass = newPassCtrl.text.trim();
                if (newPass.isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                await eco.adminResetEmployeePassword(empId: emp.id, newPassword: newPass);
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Password for ${emp.name} reset to: $newPass'),
                    backgroundColor: AppColors.ragGreen,
                  ),
                );
              },
              child: const Text('Save & Reset', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _deptChip(String dept, String label) {
    final isSelected = _deptFilter == dept;
    return GestureDetector(
      onTap: () => setState(() => _deptFilter = dept),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.burgundyPrimary : AppColors.burgundySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.sandLight : AppColors.sandPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveDelegationSection(BuildContext context, EcosystemProvider eco, List<dynamic> delegations) {
    final permissions = eco.permissionRecords;
    final pendingPerms = eco.allPendingPermissions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. DEDICATED SECTION: Staff Permissions & Early Departures
        LiquidGlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: 16,
          borderColor: pendingPerms.isNotEmpty ? const Color(0xFFF59E0B).withOpacity(0.5) : AppColors.sandBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: AppColors.sandGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Staff Permissions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  LiquidGlassButton(
                    label: '+ Permission',
                    height: 30,
                    onPressed: () => EmergencyPermissionModal.show(context),
                  ),
                  const SizedBox(width: 6),
                  LiquidGlassButton(
                    label: '+ Medical Leave',
                    height: 30,
                    onPressed: () => EmergencyMedicalLeaveModal.show(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Mark short permissions directly or review employee requests (2.0 hrs/mo limit).',
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),

              // KPI Counters
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.burgundySurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.sandBorder.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Records', style: TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text('${permissions.length}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: pendingPerms.isNotEmpty ? const Color(0xFFF59E0B).withOpacity(0.15) : AppColors.burgundySurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: pendingPerms.isNotEmpty ? const Color(0xFFF59E0B) : AppColors.sandBorder.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pending Review', style: TextStyle(fontSize: 9.5, color: pendingPerms.isNotEmpty ? const Color(0xFFF59E0B) : AppColors.textMuted)),
                          const SizedBox(height: 2),
                          Text('${pendingPerms.length}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: pendingPerms.isNotEmpty ? const Color(0xFFF59E0B) : Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Staff Permissions List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Permission Records',
              style: GoogleFonts.cinzel(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
            if (permissions.isNotEmpty)
              Text('${permissions.length} total', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 8),

        if (permissions.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sandBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              'No permission records yet.\nTap "+ Mark Permission" to grant permission to staff.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
            ),
          )
        else
          ...permissions.map((rec) {
            final emp = eco.employees.firstWhere((e) => e.id == rec.empId, orElse: () => eco.employees.first);
            final isPending = rec.isPendingHr;
            final isApproved = rec.status == 'Approved';
            final isOrange = rec.isOrangeFlagged || rec.actualHoursUsed > 2.0;
            final statusColor = isOrange
                ? AppColors.ragYellow
                : (isPending
                    ? const Color(0xFFF59E0B)
                    : (isApproved ? const Color(0xFF10B981) : const Color(0xFFEF4444)));

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOrange ? AppColors.ragYellow.withOpacity(0.08) : AppColors.burgundyCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor.withOpacity(0.5), width: isOrange ? 1.2 : 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.sandGold.withOpacity(0.2),
                        child: Text(
                          emp.initials,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.sandGold),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  emp.name,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.sandLight),
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
                              '${emp.dept} • ${rec.dateFormatted} • ${rec.grantedBy}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          rec.status.toUpperCase(),
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.burgundySurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Reason: ${rec.reason}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.sandLight),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOrange ? AppColors.ragYellow.withOpacity(0.2) : AppColors.sandGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${rec.actualHoursUsed} hrs',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isOrange ? AppColors.ragYellow : AppColors.sandGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Quick Action Buttons if Pending
                  if (isPending) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 12, color: Color(0xFFEF4444)),
                          label: const Text('Reject', style: TextStyle(fontSize: 10.5, color: Color(0xFFEF4444))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => eco.rejectPermission(rec.id, rejectedBy: 'HR'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 12, color: Colors.white),
                          label: const Text('Grant / Forward to CEO', style: TextStyle(fontSize: 10.5, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sandGold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => eco.hrGrantPermission(rec.id),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 16),

        // Emergency Medical Leaves Review Section (Mandatory Prescription <= 150 KB)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Emergency Medical Leaves',
              style: GoogleFonts.cinzel(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
            if (eco.medicalLeaveRecords.isNotEmpty)
              Text('${eco.medicalLeaveRecords.length} records', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 8),

        if (eco.medicalLeaveRecords.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sandBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              'No emergency medical leaves submitted yet.\nDoctor prescription is mandatory for all requests.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
            ),
          )
        else
          ...eco.medicalLeaveRecords.map((m) {
            final isPending = m.status == 'Pending HR & CEO' || m.status == 'Pending HR';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_hospital_outlined, color: AppColors.ragRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${m.empName} (${m.empRole}) • ${m.days} Days',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              '${m.department} • ${m.dateFormatted} • Status: ${m.status}',
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
                        onPressed: () => PrescriptionViewerDialog.show(context, leave: m, isHr: true),
                        icon: const Icon(Icons.image, size: 12, color: AppColors.sandGold),
                        label: const Text('View Prescription', style: TextStyle(fontSize: 10, color: AppColors.sandGold, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Diagnosis: "${m.reason}"',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.sandLight),
                  ),
                  if (isPending) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 12, color: Color(0xFFEF4444)),
                          label: const Text('Reject', style: TextStyle(fontSize: 10.5, color: Color(0xFFEF4444))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => eco.rejectMedicalLeave(m.id, rejectedBy: 'HR'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check, size: 12, color: Colors.black),
                          label: const Text('Grant / Forward to CEO', style: TextStyle(fontSize: 10.5, color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sandGold,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => eco.hrGrantMedicalLeave(m.id),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
        const SizedBox(height: 16),

        // 2. EMERGENCY LEAVE DELEGATION
        LiquidGlassCard(
          padding: const EdgeInsets.all(14),
          borderRadius: 16,
          borderColor: AppColors.sandBorder,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.handshake_outlined, size: 18, color: AppColors.sandGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Emergency Leave Delegation',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  LiquidGlassButton(
                    label: '+ Delegate',
                    height: 30,
                    onPressed: () => _openEmergencyDelegationDialog(context, eco),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Reassign daily SOP checklist tasks when staff members take unplanned emergency leave.',
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Text(
          'Delegation Audit Trail',
          style: GoogleFonts.cinzel(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.sandLight),
        ),
        const SizedBox(height: 8),

        if (delegations.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sandBorder),
            ),
            alignment: Alignment.center,
            child: Text(
              'No emergency leave delegations logged yet.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
            ),
          )
        else
          ...delegations.map((del) {
          return LiquidGlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: const Icon(Icons.swap_calls, color: AppColors.sandGold, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${del.absentEmpName} → Covered by ${del.coveringEmpName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${del.date} • ${del.taskCount} Tasks • Reason: ${del.reason}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                LiquidGlassPill(label: 'CO-SIGNED', color: AppColors.ragGreen),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _confirmRemoveEmployee(BuildContext context, EcosystemProvider eco, Employee emp) {
    if (emp.roleType.toLowerCase() == 'ceo' || emp.id == 'MN-CEO01') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ragRed,
          content: Text('Action Denied: Executive CEO account cannot be removed.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundySurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ragRed, width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.ragRed, size: 22),
            const SizedBox(width: 8),
            Text(
              'Remove Employee',
              style: GoogleFonts.cinzel(
                color: AppColors.sandLight,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${emp.name} (${emp.id}) from Online Department?\n\nThis action can only be performed by HR Management.',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textMuted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ragRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final success = eco.removeEmployee(emp.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.burgundyPrimary,
                    content: Text('${emp.name} removed by HR successfully.'),
                  ),
                );
              }
            },
            child: const Text('Remove Employee'),
          ),
        ],
      ),
    );
  }

  void _openAddHireDialog(BuildContext context, EcosystemProvider eco) {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String expCategory = 'standard';
    String roleHierarchy = 'Employee'; // 'Employee' or 'Team Lead'
    String selectedDept = 'Operations';

    final deptOptions = ['Operations', 'Sales', 'Technology', 'Media', 'Accounts', 'HR', 'Online Department'];

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
                          'Add New Staff & Credentials',
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

                    // Role Type Selection (Employee vs Team Lead)
                    Text(
                      'Assign Role Type:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandGold, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                roleHierarchy = 'Employee';
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
                                  const SizedBox(width: 6),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setModalState(() {
                                roleHierarchy = 'Team Lead';
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
                                  const SizedBox(width: 6),
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
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Full Name
                    Text(
                      'Staff Full Name:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'e.g. Ramesh Chandran',
                        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11.5),
                        filled: true,
                        fillColor: AppColors.burgundyBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Department & Role Title
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Department:',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: selectedDept,
                                dropdownColor: AppColors.burgundyBg,
                                style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 11.5),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.burgundyBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                                items: deptOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                                onChanged: (v) {
                                  if (v != null) setModalState(() => selectedDept = v);
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
                              Text(
                                'Role Title:',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: roleController,
                                style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Online Sale Person',
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

                    // Email & Phone
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
                                  hintText: 'ramesh@mnj.com',
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

                    // Initial Password & Seniority
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Login Password:',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: passwordController,
                                style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Enter password (min 6 characters)',
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
                                'Seniority Status:',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: expCategory,
                                dropdownColor: AppColors.burgundyBg,
                                style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 11.5),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.burgundyBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'standard', child: Text('Standard Staff')),
                                  DropdownMenuItem(value: 'senior', child: Text('Senior Executive')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setModalState(() => expCategory = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    LiquidGlassButton(
                      label: 'Register Staff & Grant Access',
                      icon: Icons.check,
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;
                        final defaultRole = roleHierarchy == 'Team Lead' ? 'Operations Team Lead' : 'Operations Executive';
                        final assignedRoleType = roleHierarchy == 'Team Lead' ? 'team_lead' : 'employee';
                        final staffEmail = emailController.text.trim().isNotEmpty
                            ? emailController.text.trim()
                            : '${nameController.text.trim().toLowerCase().replaceAll(' ', '')}@mnj.com';

                        eco.addNewEmployee(
                          name: nameController.text.trim(),
                          role: roleController.text.trim().isNotEmpty ? roleController.text.trim() : defaultRole,
                          roleType: assignedRoleType,
                          dept: selectedDept,
                          phone: phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : '+91 94433 00000',
                          email: staffEmail,
                          password: passwordController.text.trim().isNotEmpty ? passwordController.text.trim() : 'staff@mnj123',
                          experienceCategory: expCategory,
                          experienceYears: expCategory == 'senior' ? '3+ Years' : 'Confirmed Corporate Staff',
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.burgundyPrimary,
                            content: Text('Registered confirmed $roleHierarchy: ${nameController.text.trim()} in Firestore!'),
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

  void _openHrMarkPermissionDialog(BuildContext context, EcosystemProvider eco) {
    String? selectedEmpId = eco.employees.isNotEmpty ? eco.employees.first.id : null;
    double selectedHours = 1.0;
    final reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
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
                              const Icon(Icons.timer_outlined, color: AppColors.sandGold, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Mark Staff Permission',
                                style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                              ),
                            ],
                          ),
                          IconButton(icon: const Icon(Icons.close, color: AppColors.sandPrimary), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      Text(
                        'Directly grant permission / early departure hours to an employee.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 14),

                      // Select Employee
                      Text('Select Staff Member', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.burgundyCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.sandBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedEmpId,
                            isExpanded: true,
                            dropdownColor: AppColors.burgundySurface,
                            items: eco.employees.map((e) {
                              return DropdownMenuItem<String>(
                                value: e.id,
                                child: Text(
                                  '${e.name} (${e.dept})',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.sandLight),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => selectedEmpId = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Hours Duration Selector
                      Text('Permission Duration', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [0.5, 1.0, 1.5, 2.0, 3.0, 4.0].map((h) {
                            final isSel = selectedHours == h;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('${h}h ${h == 0.5 ? "(30m)" : (h == 4.0 ? "(Half Day)" : "")}'),
                                selected: isSel,
                                selectedColor: AppColors.sandGold,
                                backgroundColor: AppColors.burgundyCard,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? AppColors.burgundyBg : AppColors.sandLight,
                                ),
                                onSelected: (_) => setModalState(() => selectedHours = h),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Reason Field
                      Text('Reason / Notes', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: reasonController,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'e.g. Medical token, personal bank work, early exit',
                          hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11),
                          filled: true,
                          fillColor: AppColors.burgundyCard,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandGold)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: Text(
                            'Grant Permission (${selectedHours}h)',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (selectedEmpId == null) return;
                            final reason = reasonController.text.trim().isEmpty ? 'HR Approved Permission' : reasonController.text.trim();
                            eco.markPermissionByHr(
                              empId: selectedEmpId!,
                              hours: selectedHours,
                              reason: reason,
                              date: selectedDate,
                            );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: const Color(0xFF10B981),
                                content: Text('Permission of ${selectedHours}h successfully marked!'),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openEmergencyDelegationDialog(BuildContext context, EcosystemProvider eco) {
    String? absentEmp;
    String? coveringEmp;
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.burgundySurface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delegate Emergency Leave Tasks',
                        style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.sandPrimary), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  Text(
                    'Reassign SOP tasks immediately so store operations run without blockage.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Absent Employee on Leave:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: absentEmp,
                    dropdownColor: AppColors.burgundyBg,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.burgundyBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                    ),
                    items: eco.employees.map((e) {
                      return DropdownMenuItem(value: e.id, child: Text('${e.name} (${e.dept})'));
                    }).toList(),
                    onChanged: (v) => setModalState(() => absentEmp = v),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Designate Covering Colleague:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: coveringEmp,
                    dropdownColor: AppColors.burgundyBg,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.burgundyBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                    ),
                    items: eco.employees.where((e) => e.id != absentEmp).map((e) {
                      return DropdownMenuItem(value: e.id, child: Text('${e.name} (${e.role})'));
                    }).toList(),
                    onChanged: (v) => setModalState(() => coveringEmp = v),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    'Reason for Delegation:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: reasonController,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Enter reason (e.g. Leave, emergency duty)...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11),
                      filled: true,
                      fillColor: AppColors.burgundyBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),

                  LiquidGlassButton(
                    label: 'Confirm Emergency Task Delegation',
                    icon: Icons.swap_horiz,
                    onPressed: () {
                      if (absentEmp == null || coveringEmp == null) return;
                      final a = eco.employees.firstWhere((e) => e.id == absentEmp, orElse: () => eco.employees.first);
                      final c = eco.employees.firstWhere((e) => e.id == coveringEmp, orElse: () => eco.employees.first);
                      eco.delegateEmergencyLeave(
                        absentEmpId: absentEmp!,
                        coveringEmpId: coveringEmp!,
                        reason: reasonController.text.trim().isEmpty ? 'Leave Coverage' : reasonController.text.trim(),
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.burgundyPrimary,
                          content: Text('Tasks delegated from ${a.name} to ${c.name}'),
                        ),
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

  // --- GROOMING & ATTIRE AUDIT TAB ---

  Widget _buildGroomingAuditSection(BuildContext context, EcosystemProvider eco) {
    final employees = eco.employees;
    final selectedEmp = employees.firstWhere(
      (e) => e.id == (_selectedGroomingEmpId ?? eco.currentEmployee.id),
      orElse: () => employees.first,
    );

    final auditHistory = eco.groomingAudits;

    const categories = [
      'Uniform & Ironing',
      'Haircut & Shave',
      'ID Badge & Lapel Pin',
      'Footwear Standards',
      'Hygiene & Fragrance',
    ];

    final presetDeltas = [
      {'label': '+10 Pts (Exemplary Blazer & Uniform)', 'val': 10, 'isPos': true},
      {'label': '+5 Pts (Sharp Haircut & Clean Shave)', 'val': 5, 'isPos': true},
      {'label': '+5 Pts (Pristine Lapel Badge)', 'val': 5, 'isPos': true},
      {'label': '-5 Pts (Tilted / Missing Badge)', 'val': -5, 'isPos': false},
      {'label': '-10 Pts (Unironed / Wrinkled Uniform)', 'val': -10, 'isPos': false},
      {'label': '-10 Pts (Unkempt Hair / Beard)', 'val': -10, 'isPos': false},
      {'label': '-15 Pts (Casual / Non-Formal Shoes)', 'val': -15, 'isPos': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // HR Auditing Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dry_cleaning_outlined, color: AppColors.sandGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'STAFF ATTIRE & GROOMING AUDIT',
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.sandGold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                    ),
                    child: Text(
                      'HR AUDIT TOOL',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Review staff grooming. These points update the employee\'s Profile score and overall status.',
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),

              // Staff Selector Dropdown
              Text(
                'Select Staff Member to Inspect:',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandLight),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.burgundySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    dropdownColor: AppColors.burgundySurface,
                    value: selectedEmp.id,
                    items: employees.map((e) {
                      return DropdownMenuItem(
                        value: e.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.sandGold,
                              child: Text(
                                e.initials,
                                style: const TextStyle(fontSize: 10, color: AppColors.burgundyDark, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${e.name} (${e.id}) • ${e.dept}',
                                style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGroomingEmpId = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Grooming Category
              Text(
                'Attire & Grooming Category:',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandLight),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: categories.map((cat) {
                  final isSel = _selectedGroomingCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    selectedColor: AppColors.sandGold.withOpacity(0.25),
                    backgroundColor: AppColors.burgundySurface,
                    side: BorderSide(color: isSel ? AppColors.sandGold : AppColors.sandBorder),
                    labelStyle: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      color: isSel ? AppColors.sandGold : AppColors.sandLight,
                    ),
                    onSelected: (_) => setState(() => _selectedGroomingCategory = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Points Award or Penalty
              Text(
                'Select Points Adjustment (Addition or Penalty Removal):',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandLight),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: presetDeltas.map((item) {
                  final val = item['val'] as int;
                  final isPos = item['isPos'] as bool;
                  final isSel = _selectedPointsChange == val;
                  final color = isPos ? AppColors.ragGreen : const Color(0xFFEF4444);

                  return InkWell(
                    onTap: () => setState(() => _selectedPointsChange = val),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? color.withOpacity(0.25) : AppColors.burgundySurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel ? color : AppColors.sandBorder,
                          width: isSel ? 1.5 : 1.0,
                        ),
                      ),
                      child: Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? color : AppColors.sandLight,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Remarks
              Text(
                'Floor Observation / Audit Notes:',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandLight),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _groomingRemarksCtrl,
                style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'e.g. Crisp uniform inspected during morning briefing',
                  hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.burgundySurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.sandBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.sandBorder),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Submit Action Button
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.burgundyBg),
                label: Text(
                  _selectedPointsChange >= 0
                      ? 'Award +$_selectedPointsChange Points to ${selectedEmp.name.split(' ').first}'
                      : 'Apply $_selectedPointsChange Penalty to ${selectedEmp.name.split(' ').first}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.burgundyBg,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPointsChange >= 0 ? AppColors.sandGold : const Color(0xFFEF4444),
                  minimumSize: const Size.fromHeight(42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final reason = _groomingRemarksCtrl.text.trim().isEmpty
                      ? 'Routine showroom floor inspection'
                      : _groomingRemarksCtrl.text.trim();

                  eco.addGroomingAudit(
                    empId: selectedEmp.id,
                    category: _selectedGroomingCategory,
                    pointsChange: _selectedPointsChange,
                    reason: reason,
                    auditedBy: 'Meera Krishnan (Head of HR)',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: _selectedPointsChange >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      content: Text(
                        'Audit logged: ${_selectedPointsChange >= 0 ? "+$_selectedPointsChange" : "$_selectedPointsChange"} pts applied to ${selectedEmp.name}',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Live HR Audit Ledger
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'COMPANY-WIDE GROOMING AUDIT LOG',
                    style: GoogleFonts.cinzel(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                    ),
                  ),
                  Text(
                    '${auditHistory.length} Audits',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppColors.sandGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (auditHistory.isEmpty)
                Text(
                  'No grooming audits recorded yet.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: auditHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final item = auditHistory[idx];
                    final isPos = item.pointsChange >= 0;
                    final targetStaff = employees.firstWhere(
                      (e) => e.id == item.empId,
                      orElse: () => employees.first,
                    );

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.burgundyCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPos
                              ? AppColors.ragGreen.withOpacity(0.3)
                              : const Color(0xFFEF4444).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPos
                                  ? AppColors.ragGreen.withOpacity(0.2)
                                  : const Color(0xFFEF4444).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPos ? '+${item.pointsChange} Pts' : '${item.pointsChange} Pts',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPos ? AppColors.ragGreen : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      targetStaff.name,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.sandLight,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${item.category})',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: AppColors.sandGold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.reason,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.dateFormatted,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHrAttendanceComplianceSection(BuildContext context, EcosystemProvider eco) {
    final allSummaries = eco.allEmployeesTodayAttendance;
    final filteredSummaries = allSummaries.where((s) {
      final matchesDept = _deptFilter == 'all' || s.department == _deptFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          s.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.employeeId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.role.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDept && matchesSearch;
    }).toList();

    final onTimeCount = allSummaries.where((s) => s.status == DailyAttendanceStatus.presentOnTime).length;
    final lateCount = allSummaries.where((s) => s.status == DailyAttendanceStatus.lateLogin).length;
    final lunchOverstayCount = allSummaries.where((s) => s.lunchDurationMinutes > 45).length;
    final activeDutyCount = allSummaries.where((s) => s.isCurrentlyOnDuty).length;
    final availableDepts = ['all', ...eco.employees.map((e) => e.dept).toSet()];
    final safeDeptValue = availableDepts.contains(_deptFilter) ? _deptFilter : 'all';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compliance Banner
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.fingerprint, color: Color(0xFF10B981), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workforce Attendance & Shift Compliance',
                                style: GoogleFonts.cinzel(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Live In/Out timestamps, lunch break audits & shift tracking',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      await eco.syncFromEsslDevice();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF10B981),
                          content: Text('HR Attendance ledger synchronized!'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.sandGold),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sync, size: 12, color: AppColors.sandGold),
                          const SizedBox(width: 4),
                          Text(
                            'Sync',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // KPI Row
              Row(
                children: [
                  Expanded(
                    child: _hrMetricPill('On Duty', '$activeDutyCount', const Color(0xFF10B981), Icons.work_outline),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _hrMetricPill('On-Time', '$onTimeCount', const Color(0xFF10B981), Icons.check_circle_outline),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _hrMetricPill('Late In', '$lateCount', const Color(0xFFEAB308), Icons.warning_amber),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _hrMetricPill('Lunch >45m', '$lunchOverstayCount', lunchOverstayCount > 0 ? const Color(0xFFEF4444) : AppColors.sandGold, Icons.restaurant),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Emergency Actions Row in HR Attendance tab
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
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: TextField(
                  style: const TextStyle(fontSize: 11, color: AppColors.sandLight),
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: const InputDecoration(
                    hintText: 'Search by staff name, ID or role...',
                    hintStyle: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    prefixIcon: Icon(Icons.search, size: 16, color: AppColors.sandGold),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 9),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: safeDeptValue,
                  dropdownColor: AppColors.burgundyCard,
                  icon: const Icon(Icons.filter_list, size: 16, color: AppColors.sandGold),
                  style: const TextStyle(fontSize: 11, color: AppColors.sandLight),
                  items: availableDepts.map((d) {
                    return DropdownMenuItem(value: d, child: Text(d == 'all' ? 'All Depts' : d));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _deptFilter = v);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // List of Employees Attendance Cards
        if (filteredSummaries.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text('No attendance records match your search filter.', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSummaries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final s = filteredSummaries[idx];
              final isOverstay = s.lunchDurationMinutes > 45;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: s.statusBadgeColor.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: AppColors.sandGold.withOpacity(0.2),
                          child: Text(
                            s.initials,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.sandGold),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.employeeName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandLight,
                                ),
                              ),
                              Text(
                                '${s.employeeId} • ${s.department}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: s.statusBadgeColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: s.statusBadgeColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            s.statusBadgeText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: s.statusBadgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Punch Timeline Row (In, Lunch, Out)
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
                                    Icon(Icons.login, size: 11, color: Color(0xFF10B981)),
                                    SizedBox(width: 4),
                                    Text('In Time', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.inTimeString,
                                  style: GoogleFonts.cinzel(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: s.isPresent ? AppColors.sandLight : AppColors.textMuted,
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
                                color: isOverstay 
                                    ? const Color(0xFFEF4444) 
                                    : (s.isCurrentlyOnLunch ? const Color(0xFFF59E0B) : AppColors.sandBorder.withOpacity(0.5)),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.restaurant, 
                                      size: 11, 
                                      color: isOverstay ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isOverstay ? 'Lunch (Overstay)' : 'Lunch Break', 
                                      style: TextStyle(
                                        fontSize: 9, 
                                        color: isOverstay ? const Color(0xFFEF4444) : AppColors.textMuted,
                                        fontWeight: isOverstay ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.lunchSummary,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: isOverstay ? const Color(0xFFEF4444) : (s.lunchOutPunch != null ? AppColors.sandGold : AppColors.textMuted),
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
                                    Icon(Icons.logout, size: 11, color: Color(0xFFEF4444)),
                                    SizedBox(width: 4),
                                    Text('Out Time', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.outTimeString,
                                  style: GoogleFonts.cinzel(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: s.logoutPunch != null ? AppColors.sandLight : (s.isCurrentlyOnDuty ? const Color(0xFFF59E0B) : AppColors.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Working Hours & Navigation Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Net Work: ${s.workHoursFormatted}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            eco.setActiveEmployee(s.employeeId);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AttendancePillarScreen()),
                            );
                          },
                          child: Row(
                            children: const [
                              Text(
                                'View Biometric Punch Audit',
                                style: TextStyle(fontSize: 9.5, color: AppColors.sandLight, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_forward_ios, size: 8, color: AppColors.sandLight),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _hrMetricPill(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.burgundySurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.cinzel(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
