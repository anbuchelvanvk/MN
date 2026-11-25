import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/employee_model.dart';
import '../../providers/ecosystem_provider.dart';
import 'ceo_subpages.dart';

/// Enterprise Role-Based Access Control (RBAC) & Feature Permission Management
/// Allows CEO & Executive Board to manage role assignments and granular module/pillar permissions.
class AdminRoleAccessManagementScreen extends StatefulWidget {
  const AdminRoleAccessManagementScreen({super.key});

  @override
  State<AdminRoleAccessManagementScreen> createState() =>
      _AdminRoleAccessManagementScreenState();
}

class _AdminRoleAccessManagementScreenState
    extends State<AdminRoleAccessManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDept = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CeoSubpageScaffold(
      title: 'Role & Access Control',
      subtitle: 'Granular RBAC & Feature Permissions',
      body: Consumer<EcosystemProvider>(
        builder: (context, eco, _) {
          final query = _searchController.text.trim().toLowerCase();
          final allEmployees = eco.employees;

          // Collect unique departments (Strictly Corporate Architecture)
          final depts = <String>['All', ...eco.availableDepartments];

          // Filter employees
          final filtered = allEmployees.where((emp) {
            final matchesSearch = query.isEmpty ||
                emp.name.toLowerCase().contains(query) ||
                emp.role.toLowerCase().contains(query) ||
                emp.roleCode.toLowerCase().contains(query) ||
                emp.email.toLowerCase().contains(query) ||
                emp.displayEmpId.toLowerCase().contains(query) ||
                emp.id.toLowerCase().contains(query);

            final matchesDept = _selectedDept == 'All' ||
                Employee.normalizeDept(emp.dept) == _selectedDept ||
                (_selectedDept == 'Online Department' && eco.teamKeyOf(emp) == 'online' && !emp.isCeo && !emp.isHr);

            return matchesSearch && matchesDept;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Banner
              _buildOverviewBanner(allEmployees),
              const SizedBox(height: 16),

              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 12),

              // Department Filter Chips
              _buildDeptFilters(depts.toList()),
              const SizedBox(height: 16),

              // Results Header
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    'STAFF DIRECTORY (${filtered.length})',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.magentaPrimary,
                    ),
                  ),
                  Text(
                    'Tap card to edit permissions',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off_rounded,
                          size: 44, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No staff members match the selected filters.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...filtered
                    .map((emp) => _buildEmployeeAccessCard(context, emp, eco)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewBanner(List<Employee> employees) {
    int fullAccessCount = 0;
    int standardStaffCount = 0;
    for (final e in employees) {
      if (e.canAccessCeoSuite || e.canManageRoles) {
        fullAccessCount++;
      } else {
        standardStaffCount++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.magentaSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.magentaBorder),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.magentaPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Access Policy & Governance',
                      style: GoogleFonts.outfit(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Changes persist instantly to cloud Firestore & execution runtime.',
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatChip(
                label: 'Total Staff',
                value: '${employees.length}',
                icon: Icons.people_alt_outlined,
                bgColor: const Color(0xFFFFF1F4),
                accentColor: const Color(0xFFBE185D),
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                label: 'Executive / Admin',
                value: '$fullAccessCount',
                icon: Icons.security_rounded,
                bgColor: const Color(0xFFFEF3C7),
                accentColor: const Color(0xFFB45309),
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                label: 'Standard Staff',
                value: '$standardStaffCount',
                icon: Icons.badge_outlined,
                bgColor: const Color(0xFFFFE4E6),
                accentColor: AppColors.magentaPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: accentColor),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.outfit(
          color: AppColors.textDark,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search by staff name, role code, email, ID...',
          hintStyle: GoogleFonts.outfit(
            color: AppColors.textMuted,
            fontSize: 12.5,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.magentaPrimary,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDeptFilters(List<String> depts) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: depts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final d = depts[index];
          final isSelected = _selectedDept == d;
          return ChoiceChip(
            label: Text(d),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedDept = d),
            selectedColor: AppColors.magentaPrimary,
            backgroundColor: Colors.white,
            labelStyle: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppColors.magentaPrimary
                  : const Color(0xFFE2E8F0),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeAccessCard(
      BuildContext context, Employee emp, EcosystemProvider eco) {
    final isCeo = emp.id.toUpperCase() == 'MN-CEO01';
    final perms = emp.permissions;

    // Count active module permissions
    int moduleCount = 0;
    if (perms.canAccessCeoSuite) moduleCount++;
    if (perms.canAccessHrPortal) moduleCount++;
    if (perms.canAccessDeptHeadPortal) moduleCount++;
    if (perms.canManageOrders) moduleCount++;
    if (perms.canAccessKonarBooks) moduleCount++;
    if (perms.canAssignTasksToOthers) moduleCount++;
    if (perms.canExportAudit) moduleCount++;
    if (perms.canManageRoles) moduleCount++;

    // Count active pillar permissions
    int pillarCount = 0;
    if (perms.canAccessAttendancePillar) pillarCount++;
    if (perms.canAccessHealthPillar) pillarCount++;
    if (perms.canAccessFamilyPillar) pillarCount++;
    if (perms.canAccessProfilePillar) pillarCount++;
    if (perms.canAccessSocialCausePillar) pillarCount++;
    if (perms.canAccessTierPillar) pillarCount++;
    if (perms.canAccessWorkPillar) pillarCount++;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCeo
              ? AppColors.magentaPrimary.withOpacity(0.4)
              : const Color(0xFFE2E8F0),
          width: isCeo ? 1.2 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openAccessEditorModal(context, emp, eco),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar / Initials
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCeo
                            ? AppColors.magentaPrimary
                            : AppColors.magentaSubtle,
                        border: Border.all(
                          color: isCeo
                              ? AppColors.magentaPrimary
                              : AppColors.magentaBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emp.initials.isNotEmpty ? emp.initials : '?',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isCeo ? Colors.white : AppColors.magentaPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name & ID
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  emp.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Role Code Tag
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.magentaSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.magentaBorder,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  emp.roleCode.isNotEmpty
                                      ? emp.roleCode
                                      : emp.straightCutRole,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.magentaPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${emp.straightCutDesignation} • ${emp.dept}',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Configure Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.magentaSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.magentaBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune_rounded,
                              size: 14, color: AppColors.magentaPrimary),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.magentaPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 10),

                // Access Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildPermissionPill(
                      label: '$moduleCount/8 Modules',
                      active: moduleCount > 0,
                      icon: Icons.apps_rounded,
                    ),
                    _buildPermissionPill(
                      label: '$pillarCount/7 Pillars',
                      active: pillarCount > 0,
                      icon: Icons.account_balance_outlined,
                    ),
                    if (isCeo)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFFDE68A), width: 0.8),
                        ),
                        child: Text(
                          'Executive Admin (Protected)',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      )
                    else if (perms.canAccessCeoSuite)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFBFDBFE), width: 0.8),
                        ),
                        child: Text(
                          'Executive Access',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                      )
                    else if (perms.canAccessHrPortal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFFECDD3), width: 0.8),
                        ),
                        child: Text(
                          'HR Admin',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE11D48),
                          ),
                        ),
                      )
                    else if (perms.canAccessDeptHeadPortal)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: const Color(0xFFBBF7D0), width: 0.8),
                        ),
                        child: Text(
                          'Team Lead',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionPill({
    required String label,
    required bool active,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: active ? AppColors.magentaPrimary : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active ? AppColors.textDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _openAccessEditorModal(
      BuildContext context, Employee emp, EcosystemProvider eco) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AccessEditorSheet(employee: emp, eco: eco),
    );
  }
}

/// Bottom Sheet for editing an employee's role code, department, and granular permissions
class _AccessEditorSheet extends StatefulWidget {
  final Employee employee;
  final EcosystemProvider eco;

  const _AccessEditorSheet({required this.employee, required this.eco});

  @override
  State<_AccessEditorSheet> createState() => _AccessEditorSheetState();
}

class _AccessEditorSheetState extends State<_AccessEditorSheet> {
  late String _roleCode;
  late String _dept;
  late String _roleTitle;
  late String _roleType;
  late RolePermissions _perms;
  bool _isSaving = false;

  final List<String> _commonRoleCodes = [
    'CEO',
    'HR',
    'AHR',
    'TL',
    'OTM',
    'OSH',
    'VPE',
    'Ass.VPE',
    'ECE',
    'OS1',
    'OS2',
    'AC',
    'OSS',
    'DVP',
    'CC',
  ];

  List<String> get _departments => widget.eco.availableDepartments;

  /// Plain-language summary of each role, shown above the switches.
  static const Map<String, (String, List<String>)> _roleGuide = {
    'CEO': ('CEO · Administration Department', [
      'Sees and manages every department (always, cannot be removed)',
      'Creates departments, hires HR / Asst. HR, sets everyone\'s access',
      'Final approval on leave, permissions and social causes',
      'Data Vault: backup, restore and reset',
    ]),
    'HR': ('HR · Administration Department', [
      'Hiring, relieving and staff records for the departments you tick below',
      'Attendance sheet, grooming audits and password help',
      'First approval on leave and permissions; social cause review',
      'Company announcements',
    ]),
    'AHR': ('Asst. HR · Administration Department', [
      'Supports HR: attendance, grooming audits and password help',
      'Hiring, relieving, approvals and announcements only if you switch them on',
      'Works only in the departments you tick below',
    ]),
    'TL': ('Team Lead · one per team', [
      'Leads one team: assigns tasks, nudges, reviews attendance',
      'Can choose one Assistant TL from the team',
      'Starts and edits the team\'s Konar Book',
    ]),
    'OTM': ('Online Team Manager · Online team lead', [
      'Leads the online team and its outside support',
      'Orders, media review, scorecard and the Online Konar Book',
    ]),
  };

  @override
  void initState() {
    super.initState();
    _roleCode = widget.employee.roleCode.isNotEmpty
        ? widget.employee.roleCode
        : widget.employee.straightCutRole;
    final rawDept = Employee.normalizeDept(widget.employee.dept);
    _dept = _departments.contains(rawDept)
        ? rawDept
        : (widget.eco.teamKeyOf(widget.employee) == 'online' ? 'Online Department' : _departments.first);
    _roleTitle = widget.employee.role;
    _roleType = widget.employee.roleType;
    _perms = widget.employee.permissions;
  }

  void _applyRoleDefaults(String roleCode) {
    String detectedType = 'employee';
    if (roleCode == 'CEO') detectedType = 'ceo';
    if (roleCode == 'HR' || roleCode == 'AHR') detectedType = 'hr';
    if (['OTM', 'TL'].contains(roleCode)) detectedType = 'team_lead';

    setState(() {
      _roleCode = roleCode;
      _roleType = detectedType;
      if (roleCode == 'AHR' && !_roleTitle.toLowerCase().contains('assistant')) _roleTitle = 'Assistant HR';
      if (roleCode == 'HR' && _roleTitle.toLowerCase().contains('assistant')) _roleTitle = 'HR Manager';
      if (roleCode == 'CEO' || roleCode == 'HR' || roleCode == 'AHR') {
        _dept = Employee.administrationDept;
      } else if (roleCode == 'OTM') {
        _dept = 'Online Department';
      } else if (Employee.isAdministrationDept(_dept)) {
        _dept = 'Online Department';
      }
      _perms = RolePermissions.defaultForRole(
        roleType: detectedType,
        roleCode: roleCode,
      );
    });
  }

  void _grantFullAccess() {
    setState(() {
      _perms = const RolePermissions(
        canAccessCeoSuite: true,
        canAccessHrPortal: true,
        canAccessDeptHeadPortal: true,
        canManageOrders: true,
        canAccessKonarBooks: true,
        canAssignTasksToOthers: true,
        canExportAudit: true,
        canManageRoles: true,
        canAccessAttendancePillar: true,
        canAccessHealthPillar: true,
        canAccessFamilyPillar: true,
        canAccessProfilePillar: true,
        canAccessSocialCausePillar: true,
        canAccessTierPillar: true,
        canAccessWorkPillar: true,
      );
    });
  }

  void _grantPillarsOnly() {
    setState(() {
      _perms = const RolePermissions(
        canAccessCeoSuite: false,
        canAccessHrPortal: false,
        canAccessDeptHeadPortal: false,
        canManageOrders: false,
        canAccessKonarBooks: true,
        canAssignTasksToOthers: false,
        canExportAudit: false,
        canManageRoles: false,
        canAccessAttendancePillar: true,
        canAccessHealthPillar: true,
        canAccessFamilyPillar: true,
        canAccessProfilePillar: true,
        canAccessSocialCausePillar: true,
        canAccessTierPillar: true,
        canAccessWorkPillar: true,
      );
    });
  }

  Future<void> _saveChanges() async {
    final isCeo = widget.employee.id.toUpperCase() == 'MN-CEO01';
    if (isCeo && (!_perms.canAccessCeoSuite || !_perms.canManageRoles)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Security Guard: Cannot revoke CEO Suite or Role Management permissions from Executive CEO.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.eco.updateEmployeeRoleAndAccess(
        employeeId: widget.employee.id,
        newRoleCode: _roleCode,
        newRoleType: _roleType,
        newRole: _roleTitle,
        newDept: _dept,
        permissions: _perms,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissions updated for ${widget.employee.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is ArgumentError ? '${e.message}' : 'Error updating permissions: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCeo = widget.employee.id.toUpperCase() == 'MN-CEO01';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.magentaSubtle,
                  child: Text(
                    widget.employee.initials.isNotEmpty
                        ? widget.employee.initials
                        : '?',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppColors.magentaPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configure Access: ${widget.employee.name}',
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Role: ${widget.employee.straightCutDesignation} • ${widget.employee.dept}',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              physics: const BouncingScrollPhysics(),
              children: [
                // Quick Role Presets
                Text(
                  'QUICK ROLE PRESETS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.magentaPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _presetChip('CEO', () => _applyRoleDefaults('CEO')),
                    _presetChip('HR', () => _applyRoleDefaults('HR')),
                    _presetChip('Asst. HR', () => _applyRoleDefaults('AHR')),
                    _presetChip('Team Lead', () => _applyRoleDefaults('TL')),
                    _presetChip('Online TL (OTM)', () => _applyRoleDefaults('OTM')),
                    _presetChip('Sales (OSH/OS1)', () => _applyRoleDefaults('OSH')),
                    _presetChip(
                        'Full Access', _grantFullAccess, color: const Color(0xFF047857), bgColor: const Color(0xFFECFDF5)),
                    _presetChip(
                        'Pillars Only', _grantPillarsOnly, color: const Color(0xFF1D4ED8), bgColor: const Color(0xFFEFF6FF)),
                  ],
                ),
                const SizedBox(height: 16),
                if (_roleGuide[_roleCode] != null)
                  Container(
                    key: const Key('role_guide'),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF1E4EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_roleGuide[_roleCode]!.$1,
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                        const SizedBox(height: 6),
                        for (final line in _roleGuide[_roleCode]!.$2)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Icon(Icons.check_circle_rounded, size: 13, color: AppColors.magentaPrimary),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(line,
                                      style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Role Code Dropdown
                Text(
                  'ROLE CODE & CLASSIFICATION',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.magentaPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _commonRoleCodes.contains(_roleCode)
                          ? _roleCode
                          : _commonRoleCodes.first,
                      dropdownColor: Colors.white,
                      style: GoogleFonts.outfit(
                          color: AppColors.textDark, fontSize: 13.5, fontWeight: FontWeight.w600),
                      items: _commonRoleCodes.map((code) {
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Text(code),
                        );
                      }).toList(),
                      onChanged: (newCode) {
                        if (newCode != null) _applyRoleDefaults(newCode);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Department Dropdown
                Text(
                  'DEPARTMENT ASSIGNMENT',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppColors.magentaPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _departments.contains(_dept)
                          ? _dept
                          : _departments.first,
                      dropdownColor: Colors.white,
                      style: GoogleFonts.outfit(
                          color: AppColors.textDark, fontSize: 13.5, fontWeight: FontWeight.w600),
                      items: _departments.map((dept) {
                        return DropdownMenuItem<String>(
                          value: dept,
                          child: Text(dept),
                        );
                      }).toList(),
                      onChanged: (newDept) {
                        if (newDept != null) setState(() => _dept = newDept);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 8 Platform Core Modules Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CORE PLATFORM MODULES (8)',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.magentaPrimary,
                      ),
                    ),
                    Text(
                      'Granular Routing',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // CEO Suite Switch (Locked for CEO)
                _buildSwitchTile(
                  title: 'CEO Suite & Executive Portal',
                  subtitle:
                      'Full corporate oversight, financial KPIs, and backups',
                  value: _perms.canAccessCeoSuite,
                  isLocked: isCeo,
                  lockTooltip: 'CEO Suite access is permanent for Executive CEO',
                  onChanged: (val) {
                    setState(() => _perms =
                        _perms.copyWith(canAccessCeoSuite: val));
                  },
                ),

                // Role Management Switch (Locked for CEO)
                _buildSwitchTile(
                  title: 'Role & Access Management',
                  subtitle:
                      'Permission governance console and staff privilege assignment',
                  value: _perms.canManageRoles,
                  isLocked: isCeo,
                  lockTooltip:
                      'Role Management access is permanent for Executive CEO',
                  onChanged: (val) {
                    setState(() =>
                        _perms = _perms.copyWith(canManageRoles: val));
                  },
                ),

                // HR Portal Switch
                _buildSwitchTile(
                  title: 'HR Management Portal',
                  subtitle:
                      'Biometric punches, attendance register, and employee dossiers',
                  value: _perms.canAccessHrPortal,
                  onChanged: (val) {
                    setState(() =>
                        _perms = _perms.copyWith(canAccessHrPortal: val));
                  },
                ),

                // Department Head Portal Switch
                _buildSwitchTile(
                  title: 'Team Lead & Dept Head Portal',
                  subtitle:
                      'Team task assignment, shift absentees hub, and daily roster',
                  value: _perms.canAccessDeptHeadPortal,
                  onChanged: (val) {
                    setState(() => _perms =
                        _perms.copyWith(canAccessDeptHeadPortal: val));
                  },
                ),

                // Online Orders Handler Switch
                _buildSwitchTile(
                  title: 'Online Orders Handler',
                  subtitle:
                      'Live orders pipeline, customer leads, and dispatch processing',
                  value: _perms.canManageOrders,
                  onChanged: (val) {
                    setState(
                        () => _perms = _perms.copyWith(canManageOrders: val));
                  },
                ),

                // Konar Books Directory Switch
                _buildSwitchTile(
                  title: 'KONAR Books & SOP Directory',
                  subtitle:
                      'Standard operating procedures, chapter curriculums, and PDF exports',
                  value: _perms.canAccessKonarBooks,
                  onChanged: (val) {
                    setState(() =>
                        _perms = _perms.copyWith(canAccessKonarBooks: val));
                  },
                ),

                // Work Delegation Switch
                _buildSwitchTile(
                  title: 'Cross-Department Task Delegation',
                  subtitle:
                      'Permission to reassign and delegate tasks to others',
                  value: _perms.canAssignTasksToOthers,
                  onChanged: (val) {
                    setState(() => _perms =
                        _perms.copyWith(canAssignTasksToOthers: val));
                  },
                ),

                // Audit Export Switch
                _buildSwitchTile(
                  title: 'Audit & Compliance Reports',
                  subtitle:
                      'Download complete corporate CSV and PDF audit ledgers',
                  value: _perms.canExportAudit,
                  onChanged: (val) {
                    setState(
                        () => _perms = _perms.copyWith(canExportAudit: val));
                  },
                ),

                const SizedBox(height: 24),

                // 7 Core Pillars Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '7 CORE PILLARS OF LIFE (7)',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.magentaPrimary,
                      ),
                    ),
                    Text(
                      'Ecosystem Foundations',
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _buildSwitchTile(
                  title: 'Pillar 1: Attendance & Shift',
                  subtitle:
                      'Biometric clock-in, overtime logs, and monthly calendar',
                  value: _perms.canAccessAttendancePillar,
                  onChanged: (val) {
                    setState(() => _perms =
                        _perms.copyWith(canAccessAttendancePillar: val));
                  },
                ),

                _buildSwitchTile(
                  title: 'Pillar 2: Health & Wellness',
                  subtitle:
                      'Daily diet logs, medical leave, and emergency prescriptions',
                  value: _perms.canAccessHealthPillar,
                  onChanged: (val) {
                    setState(() =>
                        _perms = _perms.copyWith(canAccessHealthPillar: val));
                  },
                ),

                _buildSwitchTile(
                  title: 'Pillar 3: Family & Relationships',
                  subtitle:
                      'Family time logging, activity dairy, and time ratio analytics',
                  value: _perms.canAccessFamilyPillar,
                  onChanged: (val) {
                    setState(() =>
                        _perms = _perms.copyWith(canAccessFamilyPillar: val));
                  },
                ),

                _buildSwitchTile(
                  title: 'Pillar 4: Profile & Verification',
                  subtitle:
                      'KYC verification, document vault custody, and personal details',
                  value: _perms.canAccessProfilePillar,
                  onChanged: (val) {
                    setState(() =>
                        _perms = _perms.copyWith(canAccessProfilePillar: val));
                  },
                ),

                _buildSwitchTile(
                  title: 'Pillar 5: Social Causes & Giving',
                  subtitle:
                      'Philanthropy logs, community milestones, and corporate giving',
                  value: _perms.canAccessSocialCausePillar,
                  onChanged: (val) {
                    setState(() => _perms =
                        _perms.copyWith(canAccessSocialCausePillar: val));
                  },
                ),

                _buildSwitchTile(
                  title: 'Pillar 6: Tier & Career Milestones',
                  subtitle:
                      'Corporate performance tiers, seniority badges, and evaluations',
                  value: _perms.canAccessTierPillar,
                  onChanged: (val) {
                    setState(() =>
                        _perms = _perms.copyWith(canAccessTierPillar: val));
                  },
                ),

                _buildSwitchTile(
                  title: 'Pillar 7: Daily Work & Tasks',
                  subtitle:
                      'Standard operating tasks, milestone completion, and blocker reports',
                  value: _perms.canAccessWorkPillar,
                  onChanged: (val) {
                    setState(() =>
                        _perms = _perms.copyWith(canAccessWorkPillar: val));
                  },
                ),
                if (_roleType == 'hr' || _roleType == 'ceo') ..._buildHrPerksAndDepartments(),
              ],
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.magentaPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Access Permissions',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, VoidCallback onTap,
      {Color? color, Color? bgColor}) {
    final effectiveColor = color ?? AppColors.magentaPrimary;
    final effectiveBg = bgColor ?? AppColors.magentaSubtle;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: effectiveColor.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: effectiveColor,
          ),
        ),
      ),
    );
  }

  /// HR perks and which departments HR / Asst. HR may manage.
  /// The CEO always has everything (shown locked).
  List<Widget> _buildHrPerksAndDepartments() {
    final isCeoRole = _roleType == 'ceo';
    Widget header(String title, String hint) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                      fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.magentaPrimary)),
              Flexible(
                child: Text(hint,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
    Widget perk(String title, String subtitle, bool value, RolePermissions Function(bool v) apply) => _buildSwitchTile(
          title: title,
          subtitle: subtitle,
          value: isCeoRole ? true : value,
          isLocked: isCeoRole,
          lockTooltip: 'The CEO always has this',
          onChanged: (v) => setState(() => _perms = apply(v)),
        );
    final access = _perms.departmentAccess.map(Employee.normalizeDept).toSet();
    return [
      header('HR PERKS (8)', isCeoRole ? 'Always on for the CEO' : 'Grant or remove'),
      perk('Hire staff', 'Add new employees and team leads (not HR)', _perms.canHireStaff,
          (v) => _perms.copyWith(canHireStaff: v)),
      perk('Relieve staff', 'Relieve staff and switch their sign-in off', _perms.canRelieveStaff,
          (v) => _perms.copyWith(canRelieveStaff: v)),
      perk('Password help', 'Verify staff codes and reset passwords', _perms.canResetPasswords,
          (v) => _perms.copyWith(canResetPasswords: v)),
      perk('Announcements', 'Send notices to all staff', _perms.canSendAnnouncements,
          (v) => _perms.copyWith(canSendAnnouncements: v)),
      perk('Approve leave & permission', 'First approval before the CEO', _perms.canApproveLeave,
          (v) => _perms.copyWith(canApproveLeave: v)),
      perk('Attendance sheet', 'Sync the sheet and publish attendance', _perms.canManageAttendance,
          (v) => _perms.copyWith(canManageAttendance: v)),
      perk('Grooming audits', 'Dress and presentation checks', _perms.canAuditGrooming,
          (v) => _perms.copyWith(canAuditGrooming: v)),
      perk('Social cause approvals', 'Review and approve good deeds', _perms.canApproveSocialCauses,
          (v) => _perms.copyWith(canApproveSocialCauses: v)),
      header('DEPARTMENT ACCESS', isCeoRole ? 'All departments, always' : 'Only ticked departments'),
      if (isCeoRole)
        _buildSwitchTile(
          title: 'All departments',
          subtitle: 'Only the CEO has access to every department, including new ones',
          value: true,
          isLocked: true,
          lockTooltip: 'Permanent for the CEO',
          onChanged: (_) {},
        )
      else
        Wrap(
          key: const Key('dept_access_chips'),
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in _departments)
              FilterChip(
                label: Text(d),
                selected: access.contains(d),
                selectedColor: AppColors.magentaPrimary.withOpacity(0.15),
                checkmarkColor: AppColors.magentaPrimary,
                onSelected: (on) => setState(() {
                  final next = {...access};
                  on ? next.add(d) : next.remove(d);
                  _perms = _perms.copyWith(departmentAccess: next.toList());
                }),
              ),
          ],
        ),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLocked = false,
    String? lockTooltip,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppColors.magentaPrimary.withOpacity(0.3)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                            color: AppColors.textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 6),
                        Tooltip(
                          message: lockTooltip ?? 'Locked',
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch.adaptive(
              value: value,
              activeColor: AppColors.magentaPrimary,
              onChanged: isLocked ? null : onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
