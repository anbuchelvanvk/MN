import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/personal_todo_section.dart';
import '../../core/widgets/cross_dept_blocker_section.dart';
import '../../models/attendance_models.dart';
import '../../models/employee_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../../services/ceo_excel_backup_service.dart';
import '../hr/hr_management_widgets.dart';
import '../hr/hr_employee_inspection_screen.dart';
import '../hr/hr_portal_subpages.dart';
import '../../core/widgets/mn_app_bar.dart';

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
      appBar: MnAppBar(
        title: title,
        subtitle: subtitle,
        actions: actions,
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
    'Access to Vault Keys & Custody',
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
                            fontSize: 11,
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
                Text('ASSIGNED DESIGNATION', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
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
                Text('DEPARTMENT / DIVISION', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
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
                Text('EXECUTIVE PRIVILEGES & PERKS', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                const SizedBox(height: 8),
                ...[
                  'Can Assign Works to Others',
                  'Can Approve Negotiation Discounts',
                  'Access to Vault Keys & Custody',
                  'View Biometric Workforce Reports',
                  'Access Company Audit Logs',
                  'Manage Department Tasks & Blockers',
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
                    onPressed: () async {
                      await eco.allocateEmployeeRole(
                        empId: activeEmp.id,
                        newRole: effectiveRole,
                        newDept: effectiveDept,
                        perks: _selectedPerks.toList(),
                        responsibilities: const ['Executive Leadership', 'Corporate Governance'],
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('Updated ${activeEmp.name} to $effectiveRole in $effectiveDept and dispatched personal notification!'),
                          ),
                        );
                      }
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

          // Corporate Departments & Divisions Management
          Text(
            'ORGANIZATIONAL DEPARTMENTS (${eco.availableDepartments.length})',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: AppColors.sandGold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
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
                    const Icon(Icons.apartment_rounded, color: AppColors.sandGold, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Department Master Governance',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage organization divisions. Deleting a department prompts you to either delete or reallocate its assigned workforce.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight.withOpacity(0.75)),
                ),
                const SizedBox(height: 14),
                ...eco.availableDepartments.map((dept) {
                  final deptStaff = eco.employees
                      .where((e) => e.dept.trim().toLowerCase() == dept.trim().toLowerCase())
                      .toList();
                  final isProtected = dept.toLowerCase() == 'administration' || dept.toLowerCase() == 'executive board' || dept.toLowerCase() == 'hr & administration' || dept.toLowerCase() == 'online department';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.burgundySurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.sandBorder.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.burgundyBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.business_center_outlined, color: AppColors.sandGold, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dept,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${deptStaff.length} workforce member(s)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppColors.sandLight.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isProtected)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFF87171),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            icon: const Icon(Icons.delete_forever_rounded, size: 16),
                            label: const Text('Delete', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            onPressed: () => _startDeleteDepartmentWorkflow(context, eco, dept),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.sandGold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'CORE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sandGold,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _startDeleteDepartmentWorkflow(BuildContext context, EcosystemProvider eco, String deptName) {
    showDialog(
      context: context,
      builder: (ctx1) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.sandGold, size: 24),
            SizedBox(width: 8),
            Text('Delete Department?', style: TextStyle(color: AppColors.sandLight)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the department "$deptName" completely from MN Jewel Park?',
          style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.sandLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx1),
            child: const Text('Cancel', style: TextStyle(color: AppColors.sandLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx1);
              _promptAlongWithEmployees(context, eco, deptName);
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _promptAlongWithEmployees(BuildContext context, EcosystemProvider eco, String deptName) {
    final deptEmployees = eco.employees
        .where((e) => e.dept.trim().toLowerCase() == deptName.trim().toLowerCase())
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx2) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.people_outline_rounded, color: AppColors.sandGold, size: 24),
            SizedBox(width: 8),
            Flexible(child: Text('Staff Disposition', style: TextStyle(color: AppColors.sandLight))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Along with the employees?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.sandGold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Department "$deptName" currently has ${deptEmployees.length} staff member(s).\n\n• Select "Yes" to delete all employees along with the department.\n• Select "No" to reallocate the department members to another department.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.sandLight, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx2),
            child: const Text('Cancel', style: TextStyle(color: AppColors.sandLight)),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.sandGold,
              side: const BorderSide(color: AppColors.sandGold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx2);
              _openReallocationScreen(context, eco, deptName, deptEmployees);
            },
            child: const Text('No (Reallocate)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx2);
              await _confirmAndDeleteWithEmployees(context, eco, deptName, deptEmployees.length);
            },
            child: const Text('Yes (Delete All)'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteWithEmployees(
    BuildContext context,
    EcosystemProvider eco,
    String deptName,
    int employeeCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Total Deletion', style: TextStyle(color: AppColors.sandLight)),
        content: Text(
          'Are you absolutely sure you want to permanently delete department "$deptName" along with all $employeeCount employee accounts and documents?',
          style: const TextStyle(fontSize: 13, color: AppColors.sandLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.sandLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await eco.deleteDepartmentWithWorkflow(deptName: deptName, deleteEmployees: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Department "$deptName" and $employeeCount employee accounts were permanently deleted.'),
          ),
        );
      }
    }
  }

  void _openReallocationScreen(
    BuildContext context,
    EcosystemProvider eco,
    String deptName,
    List<dynamic> deptEmployees,
  ) {
    final availableTargets = eco.availableDepartments
        .where((d) => d.trim().toLowerCase() != deptName.trim().toLowerCase())
        .toList();

    String selectedTarget = availableTargets.isNotEmpty ? availableTargets.first : 'Online Department';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctxSheet) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.sandBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.burgundySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.swap_horiz_rounded, color: AppColors.sandGold, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reallocate Department Staff',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                            ),
                          ),
                          Text(
                            'Reassigning ${deptEmployees.length} member(s) from "$deptName"',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.sandBorder),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'SELECT TARGET DEPARTMENT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandGold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTarget,
                      isExpanded: true,
                      dropdownColor: AppColors.burgundySurface,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.sandGold),
                      items: availableTargets.map((d) {
                        return DropdownMenuItem<String>(
                          value: d,
                          child: Text(
                            d,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.sandLight,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedTarget = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'STAFF MEMBERS BEING TRANSFERRED (${deptEmployees.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandGold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: deptEmployees.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.burgundySurface),
                    itemBuilder: (context, index) {
                      final emp = deptEmployees[index];
                      return Material(type: MaterialType.transparency, child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.burgundySurface,
                          child: Text(
                            emp.initials.toString().isNotEmpty ? emp.initials.toString() : 'MN',
                            style: const TextStyle(fontSize: 11, color: AppColors.sandGold, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          emp.name.toString(),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.sandLight),
                        ),
                        subtitle: Text(
                          '${emp.role} • ID: ${emp.id}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.sandBorder),
                        ),
                        trailing: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.sandGold),
                      ));
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sandGold,
                      foregroundColor: AppColors.burgundyCard,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctxSheet);
                      await eco.deleteDepartmentWithWorkflow(
                        deptName: deptName,
                        deleteEmployees: false,
                        reallocateToDept: selectedTarget,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text(
                              'Successfully transferred ${deptEmployees.length} employee(s) to "$selectedTarget" and deleted "$deptName".',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Reallocate to $selectedTarget & Delete Dept',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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

          // Search Bar & New Hire Button Row
          Row(
            children: [
              Expanded(
                child: Container(
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
                            hintText: 'Search staff by name, role, ID, phone...',
                            hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12),
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
              ),
              const SizedBox(width: 8),
              LiquidGlassButton(
                label: 'New Hire',
                icon: Icons.person_add_alt_1,
                height: 42,
                onPressed: () => HrStaffDirectoryScreen.openAddHireDialog(context, eco),
              ),
            ],
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
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCeoStaffCard(BuildContext context, EcosystemProvider eco, Employee emp) {
    final isPasswordRevealed = _revealedPasswords[emp.id] ?? false;
    final empPassword = emp.password.isNotEmpty ? emp.password : 'Not stored (use Send Reset Link)';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.sandBorder.withOpacity(0.6),
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
                    backgroundColor: AppColors.sandGold.withOpacity(0.2),
                    child: Text(
                      emp.initials,
                      style: const TextStyle(
                        color: AppColors.sandGold,
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${emp.phone} • ${emp.email}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.sandGold),
                ],
              ),
            ),
          ),

          // Inline Password & Action Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0FF),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
              border: Border(top: BorderSide(color: AppColors.sandBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 13, color: AppColors.sandGold),
                    const SizedBox(width: 6),
                    Text(
                      'Password: ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
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
                        if (emp.password.isEmpty) return;
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
                  ],
                ),
                const SizedBox(height: 6),
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
                              style: GoogleFonts.plusJakartaSans(
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
                                style: GoogleFonts.plusJakartaSans(
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
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to officially relieve ${emp.name} (EMP #${emp.empNo.isNotEmpty ? emp.empNo : emp.id}) from MN Jewel Park?\n\n'
          'This will revoke app login credentials, relieve them from duties, and remove them from active workforce rosters.',
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.sandLight, height: 1.4),
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
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFFDC2626),
                    content: Text('$name ($idStr) has been officially relieved from the company.'),
                  ),
                );
              }
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
            Text(
              'A secure reset link will be emailed to ${emp.email.isNotEmpty ? emp.email : 'their login email'}. '
              'They set the new password themselves, so it is never shared or visible to HR/CEO.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
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
      subtitle: 'Review staff good deeds',
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
          icon: const Icon(Icons.campaign_outlined, color: AppColors.goldBright),
          tooltip: 'Broadcast Update to Staff',
          onPressed: () => _showBroadcastUpdateDialog(context, eco),
        ),
        IconButton(
          icon: isSyncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.sync_rounded, color: Colors.white),
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
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold),
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
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
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
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tc),
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
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
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
                        color: isEmpAbsent ? const Color(0xFFC7D2FE).withOpacity(0.5) : AppColors.sandBorder.withOpacity(0.4),
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
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            eco.toggleEmployeeAbsent(s.employeeId);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: LiquidGlassPill(
                            label: isEmpAbsent ? 'ABSENT' : s.statusBadgeText.toUpperCase(),
                            color: isEmpAbsent ? AppColors.ragRed : s.statusBadgeColor,
                          ),
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

  void _showBroadcastUpdateDialog(BuildContext context, EcosystemProvider eco) {
    final recordedDay = eco.hrAttendanceSheet?.latestRecordedDay ?? DateTime.now().day;
    final defaultDate = '$recordedDay Nov';
    final controller = TextEditingController(text: defaultDate);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.sandGold.withOpacity(0.4)),
        ),
        title: Row(
          children: const [
            Icon(Icons.campaign_rounded, color: AppColors.sandGold, size: 24),
            SizedBox(width: 8),
            Text(
              'Broadcast Attendance Update',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notify all employees that their attendance for a specific date has been officially recorded or reviewed by Executive Management.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            const Text(
              'DATE / DATES UPDATED',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. 14 Nov or 12 Nov, 13 Nov',
                hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.sandBorder)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sandGold,
              foregroundColor: AppColors.burgundyBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final dateText = controller.text.trim();
              if (dateText.isNotEmpty) {
                eco.broadcastAttendanceUpdateNotification(dateText);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text('Attendance notification sent to all staff for $dateText!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Send Notification to All Staff', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
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
                          fontSize: 11.5,
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
                    fontSize: 11.5,
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
                  fontSize: 11.5,
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
          const SizedBox(height: 16),

          // Cross-Dept Blocker Section
          const CrossDeptBlockerSection(department: 'Executive Board'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// 12. CEO DATA VAULT & SYSTEM RESET SUBPAGE
class CeoDataVaultAndResetScreen extends StatefulWidget {
  const CeoDataVaultAndResetScreen({super.key});

  @override
  State<CeoDataVaultAndResetScreen> createState() => _CeoDataVaultAndResetScreenState();
}

class _CeoDataVaultAndResetScreenState extends State<CeoDataVaultAndResetScreen> {
  bool _isDownloading = false;
  bool _isUploading = false;
  bool _isResetting = false;

  String? _uploadedFileName;
  Map<String, List<List<String>>> _uploadedSheets = {};
  String? _activeSheetKey;

  Future<void> _handleDownloadBackup(EcosystemProvider eco) async {
    setState(() => _isDownloading = true);
    try {
      final path = await CeoExcelBackupService.generateCompleteExcelBackup(eco);
      if (mounted) {
        await Share.shareXFiles(
          [XFile(path)],
          text: 'MN Jewel Park Master System Backup (8 Comprehensive Datasets)',
          subject: 'MN Jewel Park Master Backup .xlsx',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF10B981),
              content: Text('Excel backup generated successfully: ${path.split(RegExp(r"[\\/]")).last}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Error generating Excel backup: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleUploadBackup() async {
    setState(() => _isUploading = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        List<int>? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }

        if (bytes != null && bytes.isNotEmpty) {
          final parsed = CeoExcelBackupService.parseExcelBackupBytes(bytes);
          setState(() {
            _uploadedFileName = file.name;
            _uploadedSheets = parsed;
            _activeSheetKey = parsed.keys.isNotEmpty ? parsed.keys.first : null;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF10B981),
                content: Text('Successfully loaded "${file.name}" with ${parsed.length} sheets!'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Error parsing uploaded Excel file: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _confirmAndResetOperationalData(EcosystemProvider eco) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirm Database Reset',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandLight,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to clean operational database records?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.sandLight,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '• ALL old & current notifications will be permanently deleted from Firebase.\n• ALL social cause feed entries will be cleared.\n\n• STRICTLY PRESERVED: Employee accounts, departments, health metrics (BMI/height/weight/calories), and document vault submissions & safe custody.\n\nEnsure you have downloaded an Excel backup before proceeding.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppColors.sandGold, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Reset Operational Data',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isResetting = true);
      try {
        await eco.resetOperationalData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF10B981),
              content: Text('Firebase operational collections reset successfully! Users, health, and documents preserved.'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFEF4444),
              content: Text('Failed to reset operational data: $e'),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isResetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();

    return CeoSubpageScaffold(
      title: 'DATA VAULT & RESET',
      subtitle: 'Multi-Sheet Excel Backups & Database Maintenance',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Executive Download Backup Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.file_download_outlined, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DOWNLOAD MASTER BACKUP (.XLSX)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '8 Comprehensive sheets exported to Microsoft Excel format',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.sandGold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    _DatasetChip(label: 'Staff Directory'),
                    _DatasetChip(label: 'Attendance Master'),
                    _DatasetChip(label: 'Social Causes'),
                    _DatasetChip(label: 'Notifications'),
                    _DatasetChip(label: 'Health Profiles'),
                    _DatasetChip(label: 'Document Vault'),
                    _DatasetChip(label: 'Grooming Audits'),
                    _DatasetChip(label: 'Operations Tasks'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_download_outlined, size: 18),
                    label: Text(
                      _isDownloading ? 'Generating Excel Workbook...' : 'Download Full Backup (.xlsx)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isDownloading ? null : () => _handleDownloadBackup(eco),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Upload & Inspect Backup Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sandGold.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.table_view_rounded, color: AppColors.sandGold, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INSPECT & VERIFY BACKUP (.XLSX)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Upload previously generated Excel backup to verify and view data',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.sandGold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.sandGold,
                      side: const BorderSide(color: AppColors.sandGold, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: AppColors.sandGold, strokeWidth: 2),
                          )
                        : const Icon(Icons.file_upload_outlined, size: 18),
                    label: Text(
                      _isUploading ? 'Reading Excel File...' : 'Upload Backup File (.xlsx)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isUploading ? null : _handleUploadBackup,
                  ),
                ),

                // Sheet Tabs & Table Preview
                if (_uploadedSheets.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 15, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Loaded: ${_uploadedFileName ?? "Backup.xlsx"} (${_uploadedSheets.length} sheets)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Sheet Selector Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _uploadedSheets.keys.map((sheetKey) {
                        final isSelected = _activeSheetKey == sheetKey;
                        final rowCount = _uploadedSheets[sheetKey]?.length ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text('$sheetKey ($rowCount)'),
                            selected: isSelected,
                            selectedColor: AppColors.sandGold,
                            backgroundColor: AppColors.burgundyBg,
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.burgundyCard : AppColors.sandLight,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
                              width: 1,
                            ),
                            onSelected: (_) => setState(() => _activeSheetKey = sheetKey),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Scrollable Table Preview
                  if (_activeSheetKey != null && _uploadedSheets.containsKey(_activeSheetKey))
                    _buildSheetTablePreview(_uploadedSheets[_activeSheetKey]!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Reset Operational Data (Danger Zone / Admin Maintenance)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFEF4444), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RESET OPERATIONAL DATA (CLEAN FIREBASE)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF87171),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Cleans notifications and social causes while preserving users & documents',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.burgundyBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Preserved: All User Accounts, Staff Directory, Departments, Health Profiles (BMI, weight, height, calorie targets), and Document Vault Submissions & Safe Custody.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF10B981), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.cleaning_services_outlined, size: 14, color: Color(0xFFF87171)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Erased from Firebase: All company and personal notification alerts, social cause posts, and transient logs to keep database performant.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFFF87171), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    icon: _isResetting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_forever_rounded, size: 18),
                    label: Text(
                      _isResetting ? 'Resetting Firebase Collections...' : 'Reset Operational Data',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isResetting ? null : () => _confirmAndResetOperationalData(eco),
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

  Widget _buildSheetTablePreview(List<List<String>> rows) {
    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        alignment: Alignment.center,
        child: Text(
          'This sheet contains no data.',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
        ),
      );
    }

    final headers = rows.first;
    final dataRows = rows.skip(1).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: AppColors.burgundyBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.sandGold.withOpacity(0.15)),
              headingTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.sandGold,
              ),
              dataTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.sandLight,
              ),
              horizontalMargin: 12,
              columnSpacing: 16,
              headingRowHeight: 36,
              dataRowMinHeight: 30,
              dataRowMaxHeight: 38,
              columns: headers.map((h) => DataColumn(label: Text(h.isNotEmpty ? h : '-'))).toList(),
              rows: dataRows.map((row) {
                return DataRow(
                  cells: List.generate(headers.length, (colIdx) {
                    final cellVal = colIdx < row.length ? row[colIdx] : '';
                    return DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          cellVal,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    );
                  }),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DatasetChip extends StatelessWidget {
  final String label;
  const _DatasetChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 11, color: Color(0xFF10B981)),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF10B981),
            ),
          ),
        ],
      ),
    );
  }
}
