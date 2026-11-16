import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/personal_todo_section.dart';
import '../../core/widgets/cross_dept_blocker_section.dart';
import '../../models/attendance_models.dart';
import '../../models/employee_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../hr/hr_management_widgets.dart';
import '../hr/hr_employee_inspection_screen.dart';

/// Reusable Luxury Executive Scaffold for CEO Subpages (Executive Burgundy & Sand Gold theme with top-left back button)
class CeoSubpageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const CeoSubpageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: AppBar(
        backgroundColor: AppColors.burgundyBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.sandGold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.sandLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.sandGold.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.sandGold.withOpacity(0.2), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

// 1. ROLES & PRIVILEGES SUBPAGE
class CeoRolesPrivilegesScreen extends StatefulWidget {
  const CeoRolesPrivilegesScreen({super.key});

  @override
  State<CeoRolesPrivilegesScreen> createState() => _CeoRolesPrivilegesScreenState();
}

class _CeoRolesPrivilegesScreenState extends State<CeoRolesPrivilegesScreen> {
  String? _selectedEmpId;
  String? _selectedRole;
  String? _selectedDept;
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedPerks = {
    'Can Assign Works to Others',
    'Can Approve Negotiation Discounts',
    'Can Approve Staff Permission Slips',
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final allEmployees = eco.employees;
    final query = _searchCtrl.text.toLowerCase().trim();
    final filtered = allEmployees.where((e) {
      if (query.isEmpty) return true;
      return e.name.toLowerCase().contains(query) ||
             e.id.toLowerCase().contains(query) ||
             e.dept.toLowerCase().contains(query) ||
             e.role.toLowerCase().contains(query);
    }).toList();

    final activeEmp = allEmployees.firstWhere(
      (e) => e.id == _selectedEmpId,
      orElse: () => allEmployees.first,
    );

    final currentRole = _selectedRole ?? activeEmp.role;
    final currentDept = _selectedDept ?? activeEmp.dept;

    final dynamicRoles = <String>{
      'Managing Director & CEO',
      'HR Manager & Operations Custodian',
      'HR Manager',
      'Online Team Manager (Editor)',
      'Online Team Manager (OTM)',
      'Online Sale Head (OSH)',
      'Chief Photographer & Videographer (VPE)',
      'Assistant Photographer & Videographer (Ass.VPE)',
      'E-Commerce Executive (ECE)',
      'Online Sale Person 1 (OS1)',
      'Online Sale Person 2 (OS2)',
      'Online Analytical Consultant (AC)',
      'Online Support & Strategist (OSS)',
      'Platform Developer (DVP)',
      'Content Creator & Scriptwriter (CC)',
      'Dept Head / Team Lead',
      'Dept Head',
      'Operations Specialist 1',
      'Operations Specialist 1 (OS1)',
      'Operations Specialist 2',
      'Operations Specialist 2 (OS2)',
      'Order Fulfillment Officer',
      'Senior Quality Officer',
      'Staff Member',
      ...allEmployees.map((e) => e.role),
      activeEmp.role,
      currentRole,
    }.where((r) => r.trim().isNotEmpty).toSet().toList()..sort();

    final dynamicDepts = <String>{
      'Administration',
      'Administration (CEO / HR)',
      'Online Department',
      'Gold Jewellery',
      'Silver & Diamond',
      'Logistics & Vault',
      'Human Resources',
      'General Operations',
      ...allEmployees.map((e) => e.dept),
      activeEmp.dept,
      currentDept,
    }.where((d) => d.trim().isNotEmpty).toSet().toList()..sort();

    final effectiveRole = dynamicRoles.contains(currentRole)
        ? currentRole
        : (dynamicRoles.contains(activeEmp.role) ? activeEmp.role : dynamicRoles.first);

    final effectiveDept = dynamicDepts.contains(currentDept)
        ? currentDept
        : (dynamicDepts.contains(activeEmp.dept) ? activeEmp.dept : dynamicDepts.first);

    return CeoSubpageScaffold(
      title: 'Roles & Privileges',
      subtitle: 'Authority & Privilege Governance',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Executive Allocation Hero Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.burgundyCard, AppColors.burgundySurface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.sandGold.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.sandGold, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXECUTIVE GOVERNANCE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Promote or reassign workforce roles, departments, and executive privileges across the organization.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.sandLight.withOpacity(0.85),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search Staff Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sandGold.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.sandGold),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.sandLight),
                    decoration: InputDecoration(
                      hintText: 'Search staff by name, role or ID...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12),
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: AppColors.sandGold),
                    onPressed: () => setState(() => _searchCtrl.clear()),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Staff Selector Carousel / Grid
          Text(
            'SELECT TEAM MEMBER (${filtered.length})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: AppColors.sandGold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 98,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final emp = filtered[index];
                final isSelected = emp.id == activeEmp.id;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEmpId = emp.id;
                      _selectedRole = emp.role;
                      _selectedDept = emp.dept;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.magentaPrimary : AppColors.burgundyCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.magentaPrimary : AppColors.sandBorder.withOpacity(0.6),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isSelected ? Colors.white : AppColors.sandGold.withOpacity(0.15),
                          child: Text(
                            emp.initials,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandGold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          emp.name.split(' ').first,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.sandLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          emp.id,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            color: isSelected ? Colors.white.withOpacity(0.85) : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Role Reallocation Editor Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.sandGold.withOpacity(0.2),
                      child: Text(activeEmp.initials, style: const TextStyle(color: AppColors.sandGold, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeEmp.name,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                          ),
                          Text(
                            'Current: ${activeEmp.role} • ${activeEmp.dept}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandGold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0x33F8FAFC), height: 24),

                // Designation Dropdown
                Text('ASSIGNED DESIGNATION', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: effectiveRole,
                      dropdownColor: AppColors.burgundyCard,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.sandGold),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.sandLight),
                      items: dynamicRoles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(
                            role,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.sandLight,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRole = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Department Dropdown
                Text('DEPARTMENT / DIVISION', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: effectiveDept,
                      dropdownColor: AppColors.burgundyCard,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.sandGold),
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.sandLight),
                      items: dynamicDepts.map((dept) {
                        return DropdownMenuItem<String>(
                          value: dept,
                          child: Text(
                            dept,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.sandLight,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDept = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Privilege Perks Toggles
                Text('EXECUTIVE PRIVILEGES & PERKS', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                const SizedBox(height: 8),
                ...[
                  'Can Assign Works to Others',
                  'Can Approve Negotiation Discounts',
                  'Can Approve Staff Permission Slips',
                  'Access to Vault Keys & Custody',
                  'Authority to Grant Medical Leaves',
                ].map((perk) {
                  final isChecked = _selectedPerks.contains(perk);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isChecked) {
                            _selectedPerks.remove(perk);
                          } else {
                            _selectedPerks.add(perk);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isChecked ? AppColors.magentaSubtle : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isChecked ? AppColors.sandGold.withOpacity(0.4) : AppColors.sandBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                              size: 18,
                              color: isChecked ? AppColors.sandGold : AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                perk,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: isChecked ? AppColors.sandLight : AppColors.textSecondary,
                                  fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),

                // Save Role Allocation Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sandGold,
                      foregroundColor: AppColors.burgundyCard,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      eco.allocateEmployeeRole(
                        empId: activeEmp.id,
                        newRole: effectiveRole,
                        newDept: effectiveDept,
                        perks: _selectedPerks.toList(),
                        responsibilities: const ['Executive Leadership', 'Corporate Governance'],
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF10B981),
                          content: Text('Updated ${activeEmp.name} to $effectiveRole in $effectiveDept!'),
                        ),
                      );
                    },
                    child: Text(
                      'Confirm & Save Role Allocation',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// 2. STAFF DOSSIERS SUBPAGE
class CeoStaffDossiersScreen extends StatefulWidget {
  const CeoStaffDossiersScreen({super.key});

  @override
  State<CeoStaffDossiersScreen> createState() => _CeoStaffDossiersScreenState();
}

class _CeoStaffDossiersScreenState extends State<CeoStaffDossiersScreen> {
  final Map<String, bool> _revealedPasswords = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final allEmployees = eco.employees;

    bool matchesQuery(Employee e) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return e.name.toLowerCase().contains(q) ||
          e.id.toLowerCase().contains(q) ||
          e.role.toLowerCase().contains(q) ||
          e.dept.toLowerCase().contains(q) ||
          e.phone.toLowerCase().contains(q) ||
          e.email.toLowerCase().contains(q);
    }

    final rawAdminEmployees = allEmployees.where((e) =>
      e.dept.toLowerCase().contains('admin') ||
      e.roleType.toLowerCase() == 'ceo' ||
      e.roleType.toLowerCase() == 'hr' ||
      e.id == 'MN-CEO01' ||
      e.id == 'MN-HR1001'
    ).toList();
    
    final rawOnlineEmployees = allEmployees.where((e) =>
      !rawAdminEmployees.any((a) => a.id == e.id)
    ).toList();

    final adminEmployees = rawAdminEmployees.where(matchesQuery).toList();
    final onlineEmployees = rawOnlineEmployees.where(matchesQuery).toList();

    return CeoSubpageScaffold(
      title: 'Staff Dossiers',
      subtitle: 'Company Workforce Profiles & Credentials',
      body: Column(
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

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sandGold.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.sandGold),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.sandLight),
                    decoration: InputDecoration(
                      hintText: 'Search staff by name, role, ID, phone, or department...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12.5),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() {
                      _searchCtrl.clear();
                      _searchQuery = '';
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.sandGold.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14, color: AppColors.sandGold),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Empty Search Results State
          if (adminEmployees.isEmpty && onlineEmployees.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.person_search_outlined, size: 48, color: AppColors.sandGold.withOpacity(0.6)),
                  const SizedBox(height: 12),
                  Text(
                    'No staff members found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No staff matched "$_searchQuery". Try searching with another name, ID, phone, or role.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

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
          const SizedBox(height: 24),
        ],
      ),
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
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: accent.withOpacity(0.3)),
            ),
            child: Text(
              '$count Staff',
              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: accent),
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
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HrEmployeeInspectionScreen(employee: emp)),
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
}

// 4. PERSONAL TO-DOS SUBPAGE
class CeoPersonalTodosScreen extends StatelessWidget {
  const CeoPersonalTodosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CeoSubpageScaffold(
      title: 'Personal To-Dos',
      subtitle: 'Executive Priorities & Reviews',
      body: PersonalTodoSectionWidget(
        title: 'Personal To-Dos',
        subtitle: 'Strategic priorities & reviews',
      ),
    );
  }
}

// 5. SOCIAL CAUSES SUBPAGE
class CeoSocialCausesScreen extends StatelessWidget {
  const CeoSocialCausesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final ceoEmp = eco.employees.firstWhere(
      (e) => e.id == 'MN-CEO01' || e.roleType == 'ceo',
      orElse: () => eco.currentEmployee,
    );

    return CeoSubpageScaffold(
      title: 'Social Causes',
      subtitle: 'Pillar 5 CSR Proposals & Approvals',
      body: HrSocialCauseApprovalSection(
        reviewerName: ceoEmp.name,
        reviewerRole: ceoEmp.role,
      ),
    );
  }
}

// 6. STAFF TASKS SUBPAGE
class CeoStaffTasksScreen extends StatelessWidget {
  const CeoStaffTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final ceoEmp = eco.employees.firstWhere(
      (e) => e.id == 'MN-CEO01' || e.roleType == 'ceo',
      orElse: () => eco.currentEmployee,
    );

    return CeoSubpageScaffold(
      title: 'Staff Tasks',
      subtitle: 'Workforce Operational Tasks & Reallocation',
      body: HrEmployeeTodoManagementSection(
        authorizedName: ceoEmp.name,
        authorizedRole: ceoEmp.role,
      ),
    );
  }
}

// 7. BIOMETRIC ATTENDANCE SUBPAGE
class CeoAttendanceScreen extends StatefulWidget {
  final String initialFilter;
  final int initialTab;
  const CeoAttendanceScreen({super.key, this.initialFilter = 'all', this.initialTab = 0});

  @override
  State<CeoAttendanceScreen> createState() => _CeoAttendanceScreenState();
}

class _CeoAttendanceScreenState extends State<CeoAttendanceScreen> {
  late String _filter;
  late int _activeViewTab;
  String _selectedEmpFilter = 'all'; // 'all', '6', '7', '33', '65', '67'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _activeViewTab = widget.initialFilter != 'all' ? 1 : widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final summaries = eco.allEmployeesTodayAttendance;
    final total = summaries.length;
    final presentCount = summaries.where((s) => !eco.isEmployeeAbsent(s.employeeId)).length;
    final absentCount = summaries.where((s) => eco.isEmployeeAbsent(s.employeeId)).length;
    final onTimeCount = summaries.where((s) => s.status == DailyAttendanceStatus.presentOnTime).length;
    final lateCount = summaries.where((s) => s.status == DailyAttendanceStatus.lateLogin).length;

    final isSyncing = eco.isLoadingAttendanceSheet;
    final allSheetRows = eco.activeAttendanceSheetRows;
    final filteredSheetRows = allSheetRows.where((r) {
      if (_selectedEmpFilter != 'all' && r.empNo.trim() != _selectedEmpFilter) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.name.toLowerCase().contains(q) || r.empNo.toLowerCase().contains(q);
    }).toList();

    List<EmployeeDailyAttendanceSummary> filtered = summaries;
    if (_filter == 'present') {
      filtered = summaries.where((s) => !eco.isEmployeeAbsent(s.employeeId)).toList();
    } else if (_filter == 'absent') {
      filtered = summaries.where((s) => eco.isEmployeeAbsent(s.employeeId)).toList();
      filtered.sort((a, b) => a.employeeName.toLowerCase().compareTo(b.employeeName.toLowerCase()));
    } else if (_filter == 'ontime') {
      filtered = summaries.where((s) => s.status == DailyAttendanceStatus.presentOnTime).toList();
    } else if (_filter == 'late') {
      filtered = summaries.where((s) => s.status == DailyAttendanceStatus.lateLogin).toList();
    }

    return CeoSubpageScaffold(
      title: 'Workforce Attendance',
      subtitle: _activeViewTab == 0 ? 'HR Google Sheets Master Ledger' : 'Live Biometrics & Shift Punches',
      actions: [
        IconButton(
          icon: isSyncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sandGold),
                )
              : const Icon(Icons.sync_rounded, color: AppColors.sandGold),
          tooltip: 'Sync Google Sheets Attendance',
          onPressed: () async {
            await eco.syncGoogleSheetsAttendance(notifyIfUpdated: true);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF10B981),
                content: Text('Attendance synchronized with Google Sheets!'),
              ),
            );
          },
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // View Switcher Tabs: Google Sheets Master vs Today's Shifts
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeViewTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeViewTab == 0 ? AppColors.sandGold : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_chart_rounded,
                            size: 14,
                            color: _activeViewTab == 0 ? AppColors.burgundyBg : AppColors.sandPrimary,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Master Sheet',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _activeViewTab == 0 ? AppColors.burgundyBg : AppColors.sandLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeViewTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeViewTab == 1 ? AppColors.sandGold : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            size: 14,
                            color: _activeViewTab == 1 ? AppColors.burgundyBg : AppColors.sandPrimary,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Today\'s Shifts',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _activeViewTab == 1 ? AppColors.burgundyBg : AppColors.sandLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_activeViewTab == 0) ...[
            // Month Selector
            _buildCeoMonthSelector(context, eco),

            // Employee Selector
            _buildCeoEmployeeSelector(context, eco),

            // Search Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: AppColors.sandGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.sandLight),
                      decoration: InputDecoration(
                        hintText: 'Search staff by name or EMP NO...',
                        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11.5),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (filteredSheetRows.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                alignment: Alignment.center,
                child: Text('No employee records found in this month sheet.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted)),
              )
            else
              ...filteredSheetRows.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.burgundyCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sandBorder),
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
                                if (r.empNo.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.sandGold.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      'EMP #${r.empNo}',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    r.name,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'S.No ${r.sNo}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Metrics Pills Row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _ceoMetricChip('Late', '${r.lateCount}/3', const Color(0xFFFEF9C3), const Color(0xFF854D0E)),
                          _ceoMetricChip('CL', '${r.clDaysUsed}', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                          _ceoMetricChip('LOP', '${r.lopDaysUsed}', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                          _ceoMetricChip('Perm', r.formattedPermissionUsed, const Color(0xFFDCFCE7), const Color(0xFF166534)),
                          _ceoMetricChip('MNW', '${r.mnwDaysCount}d', const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Horizontal 31-day visual strip
                      SizedBox(
                        height: 28,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: List.generate(31, (idx) {
                              final day = idx + 1;
                              final rec = r.days[day];
                              final bg = rec?.backgroundColor ?? const Color(0xFFF8FAFC);
                              final tc = rec?.textColor ?? const Color(0xFF94A3B8);
                              final bc = rec?.borderColor ?? const Color(0xFFE2E8F0);

                              return Container(
                                width: 26,
                                margin: const EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: bc, width: 0.8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$day',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: tc),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ] else ...[
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
                    'Biometric Stream Active • $total Staff Tracked',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 13, color: AppColors.sandGold),
                  label: const Text('Sync', style: TextStyle(fontSize: 11, color: AppColors.sandGold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.sandGold),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: () async {
                    await eco.syncFromEsslDevice();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('eSSL Biometric synchronized!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Attendance KPI Pills Grid
          Row(
            children: [
              Expanded(
                child: _kpiPill(
                  'Total Staff',
                  '$total',
                  AppColors.sandGold,
                  Icons.groups,
                  onTap: () => setState(() => _filter = 'all'),
                  isSelected: _filter == 'all',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _kpiPill(
                  'Present',
                  '$presentCount',
                  const Color(0xFF10B981),
                  Icons.check_circle_outline,
                  onTap: () => setState(() => _filter = _filter == 'present' ? 'all' : 'present'),
                  isSelected: _filter == 'present',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _kpiPill(
                  'Absent',
                  '$absentCount',
                  const Color(0xFFEF4444),
                  Icons.error_outline,
                  onTap: () => setState(() => _filter = _filter == 'absent' ? 'all' : 'absent'),
                  isSelected: _filter == 'absent',
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
                  Icons.alarm_on,
                  onTap: () => setState(() => _filter = _filter == 'ontime' ? 'all' : 'ontime'),
                  isSelected: _filter == 'ontime',
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _kpiPill(
                  'Late In',
                  '$lateCount',
                  const Color(0xFFF59E0B),
                  Icons.alarm,
                  onTap: () => setState(() => _filter = _filter == 'late' ? 'all' : 'late'),
                  isSelected: _filter == 'late',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Attendance Staff List
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sandBorder.withOpacity(0.3)),
              ),
              child: Center(
                child: Text('No staff matching filter criteria.', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12)),
              ),
            )
          else
            ...filtered.asMap().entries.map((entry) {
              final idx = entry.key;
              final s = entry.value;
              final isEmpAbsent = eco.isEmployeeAbsent(s.employeeId);
              final isAbsentView = _filter == 'absent';
              final firstLetter = s.employeeName.isNotEmpty ? s.employeeName[0].toUpperCase() : '#';
              final prevLetter = (idx > 0 && filtered[idx - 1].employeeName.isNotEmpty)
                  ? filtered[idx - 1].employeeName[0].toUpperCase()
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
                          Expanded(
                            child: Text(
                              'Section $firstLetter • Absent Staff (A to Z)',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.burgundyCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isEmpAbsent ? const Color(0xFFFECDD3).withOpacity(0.5) : AppColors.sandBorder.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isEmpAbsent ? AppColors.ragRed : AppColors.sandGold.withOpacity(0.2),
                          child: Text(
                            s.initials,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isEmpAbsent ? Colors.white : AppColors.sandGold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.employeeName,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${s.employeeId} • ${s.department}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF94A3B8)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        LiquidGlassPill(
                          label: isEmpAbsent ? 'ABSENT' : s.statusBadgeText.toUpperCase(),
                          color: isEmpAbsent ? AppColors.ragRed : s.statusBadgeColor,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          const SizedBox(height: 24),
        ],
      ],
    ),
  );
}

  Widget _ceoMetricChip(String label, String value, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: text.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Widget _buildCeoMonthSelector(BuildContext context, EcosystemProvider eco) {
    final currentMonth = eco.selectedAttendanceMonth;
    final months = [
      (1, '1. Jan'),
      (2, '2. Feb'),
      (3, '3. Mar'),
      (4, '4. Apr'),
      (5, '5. May'),
      (6, '6. Jun'),
      (7, '7. Jul'),
      (8, '8. Aug'),
      (9, '9. Sep'),
      (10, '10. Oct'),
      (11, '11. Nov'),
      (12, '12. Dec'),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder),
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
                    const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.sandGold),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'SELECT ATTENDANCE MONTH',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.sandGold,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sandGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                ),
                child: Text(
                  eco.hrAttendanceSheet?.monthTitle ?? 'November 2026',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: months.map((m) {
                final isSel = currentMonth == m.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      m.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                        color: isSel ? AppColors.burgundyBg : AppColors.sandLight,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: AppColors.sandGold,
                    backgroundColor: AppColors.burgundySurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSel ? AppColors.sandGold : AppColors.sandBorder,
                      ),
                    ),
                    onSelected: (val) async {
                      if (val) {
                        await eco.selectAttendanceMonth(m.$1);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCeoEmployeeSelector(BuildContext context, EcosystemProvider eco) {
    final allRows = eco.activeAttendanceSheetRows;
    final staffOptions = [
      ('all', 'All Active Staff (${allRows.length})'),
      ...allRows.map((r) => (r.empNo.trim(), '${r.name} (#${r.empNo})')),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_search_rounded, size: 16, color: AppColors.sandGold),
              const SizedBox(width: 6),
              Text(
                'FILTER BY EMPLOYEE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.sandGold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: staffOptions.map((opt) {
                final isSel = _selectedEmpFilter == opt.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      opt.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                        color: isSel ? AppColors.burgundyBg : AppColors.sandLight,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: AppColors.sandGold,
                    backgroundColor: AppColors.burgundySurface,
                    checkmarkColor: AppColors.burgundyBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSel ? AppColors.sandGold : AppColors.sandBorder,
                      ),
                    ),
                    onSelected: (val) {
                      setState(() => _selectedEmpFilter = opt.$1);
                    },
                  ),
                );
              }).toList(),
            ),
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
}

// 8. PIPELINES & BLOCKERS SUBPAGE
class CeoPipelinesBlockersScreen extends StatelessWidget {
  const CeoPipelinesBlockersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CeoSubpageScaffold(
      title: 'Pipelines & Blockers',
      subtitle: 'Cross-Department Handovers & Operational Blockers',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handover Pipeline Overview
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
                  child: const Icon(Icons.hub_outlined, color: AppColors.sandGold, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PIPELINES & BLOCKER DESK',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Monitor cross-departmental blocker escalations and shift handovers in real time.',
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
          const SizedBox(height: 16),

          // Cross-Dept Blocker Section
          const CrossDeptBlockerSection(department: 'Executive Board'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
