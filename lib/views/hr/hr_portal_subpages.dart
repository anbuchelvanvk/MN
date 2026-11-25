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
import '../../models/hr_attendance_sheet_models.dart';
import '../../providers/ecosystem_provider.dart';
import 'hr_biometric_punch_audit_screen.dart';
import 'hr_employee_inspection_screen.dart';
import 'hr_management_widgets.dart';
import '../../core/utils/password_generator.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../dept_head/team_hub_screen.dart' show OutsideSupportNote;

// ============================================================================
// 1. REUSABLE HR SUBPAGE SCAFFOLD (Standard Top-Left Back Button Architecture)
// ============================================================================
class HrSubpageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const HrSubpageScaffold({
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MnAppBar(
        title: title,
        subtitle: subtitle,
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: body,
      ),
    );
  }
}

// ============================================================================
// 2. STAFF DIRECTORY & CREDENTIALS SCREEN
// ============================================================================
class HrStaffDirectoryScreen extends StatefulWidget {
  const HrStaffDirectoryScreen({super.key});

  static void openAddHireDialog(BuildContext context, EcosystemProvider eco) {
    _HrStaffDirectoryScreenState.openAddHireDialog(context, eco);
  }

  @override
  State<HrStaffDirectoryScreen> createState() => _HrStaffDirectoryScreenState();
}

class _HrStaffDirectoryScreenState extends State<HrStaffDirectoryScreen> {
  String _searchQuery = '';
  final String _deptFilter = 'all';
  final Map<String, bool> _revealedPasswords = {};

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final allEmployees = eco.employees;

    final filteredEmployees = allEmployees.where((e) {
      final matchesDept = _deptFilter == 'all' || e.dept == _deptFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.role.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.id.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDept && matchesSearch;
    }).toList();

    final adminEmployees = filteredEmployees.where((e) =>
      e.dept.toLowerCase().contains('admin') ||
      e.roleType.toLowerCase() == 'ceo' ||
      e.roleType.toLowerCase() == 'hr' ||
      e.id == 'MN-CEO01' ||
      e.id == 'MN-HR1001'
    ).toList();

    final outsideSupport = filteredEmployees.where((e) => e.isExternalSupport && !adminEmployees.contains(e)).toList();
    final onlineEmployees =
        filteredEmployees.where((e) => !adminEmployees.contains(e) && !outsideSupport.contains(e)).toList();
    final outsideTotal = allEmployees.where((e) => e.isExternalSupport).length;

    return HrSubpageScaffold(
      title: 'Staff Directory',
      subtitle: outsideTotal > 0
          ? '${allEmployees.length - outsideTotal} staff + $outsideTotal outside support'
          : '${allEmployees.length} Corporate Personnel',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.magentaPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.person_add_alt_1, size: 16),
            label: Text('New Hire', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => openAddHireDialog(context, eco),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Filter Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x040F172A), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.magentaPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Search staff by name, role, email, phone, ID...',
                      hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11.5),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                    onPressed: () => setState(() => _searchQuery = ''),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (filteredEmployees.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Text(
                'No staff members found matching filter.',
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else ...[
            // Section 1: Administration
            if (adminEmployees.isNotEmpty) ...[
              _departmentHeader(
                title: 'Administration',
                icon: Icons.admin_panel_settings_outlined,
                count: adminEmployees.length,
                bg: const Color(0xFFF8FAFC),
                border: const Color(0xFFE2E8F0),
                accent: AppColors.textDark,
              ),
              const SizedBox(height: 10),
              ...adminEmployees.map((emp) => _buildStaffCard(context, eco, emp)),
              const SizedBox(height: 14),
            ],

            // Section 2: Online Department
            if (onlineEmployees.isNotEmpty) ...[
              _departmentHeader(
                title: 'Online Department',
                icon: Icons.corporate_fare_rounded,
                count: onlineEmployees.length,
                bg: AppColors.magentaSubtle,
                border: AppColors.magentaBorder,
                accent: AppColors.magentaPrimary,
              ),
              const SizedBox(height: 10),
              ...onlineEmployees.map((emp) => _buildStaffCard(context, eco, emp)),
            ],

            // Section 3: Outside support (not MN Jewel Park staff)
            if (outsideSupport.isNotEmpty) ...[
              const SizedBox(height: 14),
              _departmentHeader(
                title: 'Outside Support (not MN staff)',
                icon: Icons.public_rounded,
                count: outsideSupport.length,
                bg: const Color(0xFFF5F3FF),
                border: const Color(0xFFDDD6FE),
                accent: const Color(0xFF6D28D9),
              ),
              const SizedBox(height: 8),
              const OutsideSupportNote(),
              const SizedBox(height: 10),
              ...outsideSupport.map((emp) => _buildStaffCard(context, eco, emp)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _departmentHeader({
    required String title,
    required IconData icon,
    required int count,
    required Color bg,
    required Color border,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
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
                color: AppColors.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: border),
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

  Widget _buildStaffCard(BuildContext context, EcosystemProvider eco, Employee emp) {
    final todayState = eco.todayAttendanceOf(emp.id);
    final isAbsent = todayState == TodayAttendance.absent;
    // Leadership has no attendance: no badge. Outside support gets its own tag.
    final String? badgeText = emp.isExternalSupport
        ? 'OUTSIDE SUPPORT'
        : (todayState == TodayAttendance.notTracked ? null : todayState.label.toUpperCase());
    final badgeColor = emp.isExternalSupport ? const Color(0xFF6D28D9) : todayState.color;
    final isPasswordRevealed = _revealedPasswords[emp.id] ?? false;
    final empPassword = emp.password.isNotEmpty ? emp.password : 'Not stored — reset via Password Requests';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: LiquidGlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: 16,
        borderColor: isAbsent ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Avatar, Full Name, Role, Status Pill (Tappable for full profile dossier)
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HrEmployeeInspectionScreen(employee: emp)),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isAbsent ? const Color(0xFFFDA4AF) : AppColors.magentaPrimary,
                    child: Text(
                      emp.initials,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.name,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          emp.role,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (badgeText != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: badgeColor.withOpacity(0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: badgeColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badgeText,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ],
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Row 2: Contact Details
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 12, color: AppColors.magentaPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Mobile: ${emp.phone.isNotEmpty ? emp.phone : 'Not provided'}',
                          style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.email_outlined, size: 12, color: AppColors.magentaPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Email: ${emp.email}',
                          style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.cake_outlined, size: 12, color: AppColors.magentaPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'DOB: ${emp.dob.isNotEmpty ? emp.dob : 'Not provided'}',
                          style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.wc_outlined, size: 12, color: AppColors.magentaPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Gender: ${emp.gender.isNotEmpty ? emp.gender : 'Male'}',
                          style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Row 3: Password & Credentials Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE4E6)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_outline, size: 13, color: AppColors.magentaPrimary),
                      const SizedBox(width: 5),
                      Text(
                        'Password: ',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.magentaPrimary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          isPasswordRevealed ? empPassword : '••••••••',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            letterSpacing: isPasswordRevealed ? 0 : 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _revealedPasswords[emp.id] = !isPasswordRevealed;
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isPasswordRevealed ? Icons.visibility_off : Icons.visibility,
                            size: 15,
                            color: AppColors.textSecondary,
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
                              backgroundColor: const Color(0xFF10B981),
                              content: Text('Password for ${emp.name} copied to clipboard!'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondary),
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
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.magentaBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_reset, size: 11, color: AppColors.magentaPrimary),
                              const SizedBox(width: 3),
                              Text(
                                'Reset',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.magentaPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (emp.id != 'MN-CEO01' && emp.id != '7' && emp.roleType != 'ceo') ...[
                        InkWell(
                          onTap: () => _confirmRelieveEmployee(context, eco, emp),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_remove_outlined, size: 11, color: Color(0xFFDC2626)),
                                const SizedBox(width: 3),
                                Text(
                                  'Relieve Staff',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRelieveEmployee(BuildContext context, EcosystemProvider eco, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 8),
            Text(
              'Relieve Staff Member',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to officially relieve ${emp.name} (EMP #${emp.empNo.isNotEmpty ? emp.empNo : emp.id}) from MN Jewel Park?\n\n'
          'This will revoke app login credentials, relieve them from duties, and remove them from active workforce rosters.',
          style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textDark),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Password',
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset password for ${emp.name} (#${emp.id}):', style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted)),
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
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.magentaPrimary,
              foregroundColor: Colors.white,
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
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  static void openAddHireDialog(BuildContext context, EcosystemProvider eco) {
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
    String roleHierarchy = 'Employee';
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
                color: Colors.white,
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
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.magentaPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.person_add_alt_1, size: 18, color: AppColors.magentaPrimary),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Add New Staff',
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                                            ? '✓ Synced (${eco.allGoogleSheetEmployees.length})'
                                            : '⚠️ Sync failed';
                                      });
                                      runInstantSearch(empIdController.text, setModalState);
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSyncingSheets)
                                      const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.magentaPrimary),
                                      )
                                    else
                                      const Icon(Icons.refresh, size: 14, color: AppColors.magentaPrimary),
                                    const SizedBox(width: 4),
                                    Text(
                                      isSyncingSheets ? 'Syncing...' : 'Sync Sheets',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.magentaPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
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
                          color: syncStatusMessage!.startsWith('✓') ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          syncStatusMessage!,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: syncStatusMessage!.startsWith('✓') ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Role Type Toggle
                    Text('Assign Role Type:', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => roleHierarchy = 'Employee'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: roleHierarchy == 'Employee' ? AppColors.magentaPrimary : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person, size: 15, color: roleHierarchy == 'Employee' ? Colors.white : AppColors.textDark),
                                  const SizedBox(width: 6),
                                  Text('Employee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: roleHierarchy == 'Employee' ? Colors.white : AppColors.textDark)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(() => roleHierarchy = 'Team Lead'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: roleHierarchy == 'Team Lead' ? AppColors.magentaPrimary : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shield_outlined, size: 15, color: roleHierarchy == 'Team Lead' ? Colors.white : AppColors.textDark),
                                  const SizedBox(width: 6),
                                  Text('Team Lead', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: roleHierarchy == 'Team Lead' ? Colors.white : AppColors.textDark)),
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
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: alreadyHiredStaff != null
                              ? const Color(0xFFF87171)
                              : (matchedSheetStaff.isNotEmpty ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0)),
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
                                  const Icon(Icons.badge_outlined, size: 15, color: AppColors.magentaPrimary),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Employee ID (Manual Entry):',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              if (matchedSheetStaff.isNotEmpty && alreadyHiredStaff == null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Sheet Match',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Type the Employee ID manually. It will instantly search database and Google Sheets.',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: empIdController,
                            keyboardType: TextInputType.text,
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                            decoration: InputDecoration(
                              labelText: 'Enter Employee ID / Number',
                              hintText: 'e.g. 75, 10, MN-1011...',
                              hintStyle: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              fillColor: Colors.white,
                              filled: true,
                              suffixIcon: empIdController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
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
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ALREADY HIRED IN DATABASE',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF991B1B),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Employee ID "${empIdController.text.trim()}" is already registered as ${alreadyHiredStaff!.name} (${alreadyHiredStaff!.role}, ${alreadyHiredStaff!.dept}).',
                                          style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF7F1D1D)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Cannot add duplicate Employee ID.',
                                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFFDC2626)),
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
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 15),
                                      const SizedBox(width: 6),
                                      Text(
                                        'FOUND IN GOOGLE SHEETS (${matchedSheetStaff.length} match)',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF15803D),
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
                                          color: isSelected ? const Color(0xFFDCFCE7) : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFBBF7D0)),
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
                                                  color: const Color(0xFF14532D),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isSelected ? const Color(0xFF15803D) : const Color(0xFF22C55E),
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
                                const Icon(Icons.info_outline, size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Custom ID "${empIdController.text.trim()}". Enter details below.',
                                    style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFF64748B)),
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
                    Text('Staff Full Name:', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'e.g. Ramesh Chandran',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Gender & DOB Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gender:', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: selectedGender,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                                ],
                                onChanged: (v) => setModalState(() => selectedGender = v ?? 'Male'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date of Birth:', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: dobController,
                                readOnly: true,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDob ?? DateTime(1998, 5, 20),
                                    firstDate: DateTime(1960),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setModalState(() {
                                      selectedDob = picked;
                                      dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'YYYY-MM-DD',
                                  suffixIcon: const Icon(Icons.cake_outlined, size: 16),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Department & Role
                    Builder(builder: (_) {
                      final allDepts = eco.availableDepartments;
                      final effectiveSelected = isCustomDept
                          ? '__NEW__'
                          : (allDepts.contains(selectedDept) ? selectedDept : allDepts.first);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Department:',
                                      style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<String>(
                                      value: effectiveSelected,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      ),
                                      items: [
                                        ...allDepts.map((d) => DropdownMenuItem(
                                              value: d,
                                              child: Text(
                                                d,
                                                style: const TextStyle(fontSize: 12),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            )),
                                        DropdownMenuItem(
                                          value: '__NEW__',
                                          child: Row(
                                            children: const [
                                              Icon(Icons.add_circle_outline, size: 14, color: AppColors.magentaPrimary),
                                              SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  '+ Create New Department...',
                                                  style: TextStyle(color: AppColors.magentaPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        setModalState(() {
                                          if (v == '__NEW__') {
                                            isCustomDept = true;
                                          } else {
                                            isCustomDept = false;
                                            selectedDept = v ?? 'Online Department';
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Role Title:', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                    const SizedBox(height: 4),
                                    TextField(
                                      controller: roleController,
                                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textDark),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Sales Executive',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (isCustomDept) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: customDeptController,
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textDark),
                              decoration: InputDecoration(
                                labelText: 'New Department Name',
                                hintText: 'e.g. Logistics, Retail Store, Manufacturing...',
                                hintStyle: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
                    const SizedBox(height: 12),

                    // Email & Phone
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Official Email (Login ID):', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: emailController,
                                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textDark),
                                decoration: InputDecoration(
                                  hintText: 'user@mnj.com',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phone Number:', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textDark),
                                decoration: InputDecoration(
                                  hintText: '+91 98450 XXXXX',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Password
                    Text('App Login Password:', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: passwordController,
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Enter password (min 6 characters)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: alreadyHiredStaff != null ? const Color(0xFFEF4444) : AppColors.magentaPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(alreadyHiredStaff != null ? Icons.block : Icons.check_circle_outline, size: 18),
                        label: Text(
                          alreadyHiredStaff != null
                              ? 'Employee ID Already Hired'
                              : 'Register Staff & Grant Access',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
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
                                content: Text('Please enter Staff Full Name'),
                              ),
                            );
                            return;
                          }

                          final genEmail = emailController.text.trim().isNotEmpty
                              ? emailController.text.trim()
                              : '${nameController.text.trim().toLowerCase().replaceAll(' ', '.')}@mnjewelpark.com';
                          final cleanPass = passwordController.text.trim().isNotEmpty ? passwordController.text.trim() : 'mnj12345';
                          final cleanRole = roleController.text.trim().isNotEmpty ? roleController.text.trim() : 'Operations Staff';
                          final cleanPhone = phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : '+91 98450 00000';

                          final cleanDept = isCustomDept
                              ? customDeptController.text.trim()
                              : selectedDept.trim();
                          final effectiveDept = cleanDept.isNotEmpty ? cleanDept : 'Online Department';

                          if (isCustomDept && cleanDept.isNotEmpty) {
                            eco.createNewDepartment(cleanDept);
                          }

                          eco.addNewEmployee(
                            name: nameController.text.trim(),
                            role: cleanRole,
                            phone: cleanPhone,
                            email: genEmail,
                            dept: effectiveDept,
                            experienceCategory: 'standard',
                            experienceYears: 'Confirmed Corporate Staff',
                            roleType: effectiveDept.toLowerCase().contains('external support')
                                ? 'external_support'
                                : (roleHierarchy == 'Team Lead' ? 'team_lead' : 'employee'),
                            password: cleanPass,
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

// ============================================================================
// 3. PERSONAL TO-DOS SCREEN
// ============================================================================
class HrPersonalTodosScreen extends StatelessWidget {
  const HrPersonalTodosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HrSubpageScaffold(
      title: 'Personal To-Dos',
      subtitle: 'Daily tasks & checklists',
      body: PersonalTodoSectionWidget(
        title: 'Personal To-Dos',
        subtitle: 'Daily tasks & checklists',
      ),
    );
  }
}

// ============================================================================
// 4. SOCIAL CAUSES SCREEN
// ============================================================================
class HrSocialCausesScreen extends StatelessWidget {
  const HrSocialCausesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrSubpageScaffold(
      title: 'Social Causes',
      subtitle: 'Review staff good deeds',
      body: HrSocialCauseApprovalSection(
        reviewerName: '${context.read<EcosystemProvider>().currentEmployee.name} (HR)',
        reviewerRole: 'HR Manager & Custodian',
      ),
    );
  }
}

// ============================================================================
// 5. STAFF TASKS SCREEN
// ============================================================================
class HrStaffTasksScreen extends StatelessWidget {
  const HrStaffTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrSubpageScaffold(
      title: 'Staff Tasks',
      subtitle: 'Task Allocation & Operations',
      body: HrEmployeeTodoManagementSection(
        authorizedName: '${context.read<EcosystemProvider>().currentEmployee.name} (HR)',
        authorizedRole: 'HR Manager & Custodian',
      ),
    );
  }
}

// ============================================================================
// 6. BLOCKER TICKETS SCREEN
// ============================================================================
class HrBlockerTicketsScreen extends StatelessWidget {
  const HrBlockerTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HrSubpageScaffold(
      title: 'Blocker Tickets',
      subtitle: 'Enterprise Operations SLA',
      body: CrossDeptBlockerSection(
        department: 'Human Resources',
        isCeoView: true,
      ),
    );
  }
}

// ============================================================================
// 7. ATTENDANCE & BIOMETRIC COMPLIANCE SCREEN
// ============================================================================
class HrAttendanceScreen extends StatefulWidget {
  const HrAttendanceScreen({super.key});

  @override
  State<HrAttendanceScreen> createState() => _HrAttendanceScreenState();
}

class _HrAttendanceScreenState extends State<HrAttendanceScreen> {
  String _searchQuery = '';
  final String _deptFilter = 'all';
  String _selectedEmpFilter = 'all'; // 'all', '6', '7', '33', '65', '67'
  int _activeViewTab = 0; // 0 = Google Sheets Master, 1 = Daily Shift Punches

  void _showBroadcastUpdateDialog(BuildContext context, EcosystemProvider eco) {
    final recordedDay = eco.hrAttendanceSheet?.latestRecordedDay ?? DateTime.now().day;
    final defaultDate = '$recordedDay Nov';
    final controller = TextEditingController(text: defaultDate);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.campaign_rounded, color: AppColors.magentaPrimary, size: 24),
            SizedBox(width: 8),
            Text(
              'Broadcast Update',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notify all employees that their attendance for a specific date has been officially recorded or corrected by HR in Google Sheets.',
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
              decoration: InputDecoration(
                hintText: 'e.g. 14 Nov or 12 Nov, 13 Nov',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
              backgroundColor: AppColors.magentaPrimary,
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
            child: const Text('Send Notification to All Staff', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _sheetNoticeCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          if (trailing != null) ...[const SizedBox(height: 8), trailing],
        ],
      ),
    );
  }

  /// Staff whose EMP number is missing from the selected month's sheet.
  /// Sync no longer relieves them automatically; HR decides here.
  Widget _buildMissingFromSheetPanel(BuildContext context, EcosystemProvider eco) {
    final missing = eco.staffMissingFromAttendanceSheet;
    if (missing.isEmpty) return const SizedBox.shrink();
    return _sheetNoticeCard(
      icon: Icons.person_search_rounded,
      color: AppColors.ragYellow,
      title: "${missing.length} staff not found in this month's attendance sheet",
      body: 'They may have left, or the sheet may be missing a row. Nothing is removed automatically - review each person below.',
      trailing: Column(
        children: [
          for (final emp in missing)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${emp.name} (EMP #${emp.empNo}) - ${emp.dept}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textDark),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _confirmRelieve(context, eco, emp),
                    child: const Text('Relieve', style: TextStyle(color: AppColors.ragRed, fontSize: 11.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmRelieve(BuildContext context, EcosystemProvider eco, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Relieve from company?'),
        content: Text(
          '${emp.name} (EMP #${emp.empNo}) will be removed from the workforce and their login disabled in the app. This cannot be undone from the app.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ragRed, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              final ok = eco.relieveEmployee(emp.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? '${emp.name} has been relieved.' : (eco.notificationMessage ?? 'Could not relieve ${emp.name}.')),
                ),
              );
            },
            child: const Text('Relieve'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final allSummaries = eco.allEmployeesTodayAttendance;
    final hrSheet = eco.hrAttendanceSheet;
    final isSyncing = eco.isLoadingAttendanceSheet;

    final filteredSummaries = allSummaries.where((s) {
      final matchesDept = _deptFilter == 'all' || s.department == _deptFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          s.employeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.employeeId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.role.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesDept && matchesSearch;
    }).toList();

    final isTuesday = DateTime.now().weekday == DateTime.tuesday;
    final onTimeCount = isTuesday ? 0 : allSummaries.where((s) => s.status == DailyAttendanceStatus.presentOnTime).length;
    final lateCount = isTuesday ? 0 : allSummaries.where((s) => s.status == DailyAttendanceStatus.lateLogin).length;
    final activeDutyCount = isTuesday ? 0 : allSummaries.where((s) => s.isCurrentlyOnDuty).length;
    final weekOffCount = isTuesday ? allSummaries.where((s) => s.status == DailyAttendanceStatus.weekOff).length : 0;

    // Filter Google Sheet rows (matching active workforce)
    final allSheetRows = eco.activeAttendanceSheetRows;
    final filteredSheetRows = allSheetRows.where((r) {
      if (_selectedEmpFilter != 'all' && r.empNo.trim() != _selectedEmpFilter) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.name.toLowerCase().contains(q) || r.empNo.toLowerCase().contains(q);
    }).toList();

    return HrSubpageScaffold(
      title: 'Workforce Attendance',
      subtitle: 'Google Sheets Master & Biometrics',
      actions: [
        IconButton(
          icon: const Icon(Icons.campaign_rounded, color: AppColors.heroAccent),
          tooltip: 'Broadcast Attendance Update to Staff',
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
            final err = eco.attendanceSheetError;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: err == null ? const Color(0xFF10B981) : AppColors.ragRed,
                content: Text(err == null
                    ? 'HR Attendance synchronized with Google Sheets!'
                    : 'Sync failed: ${err.replaceFirst('Exception: ', '')}'),
              ),
            );
          },
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (eco.attendanceSheetError != null)
            _sheetNoticeCard(
              icon: Icons.error_outline_rounded,
              color: AppColors.ragRed,
              title: 'Attendance sheet could not be loaded',
              body: eco.attendanceSheetError!.replaceFirst('Exception: ', ''),
            ),
          _buildMissingFromSheetPanel(context, eco),

          // View Switcher Tabs: Google Sheets Master vs Today's Shifts
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeViewTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeViewTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _activeViewTab == 0
                            ? const [BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_chart_rounded,
                            size: 14,
                            color: _activeViewTab == 0 ? AppColors.magentaPrimary : AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Master Sheet',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _activeViewTab == 0 ? AppColors.textDark : AppColors.textMuted,
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
                        color: _activeViewTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _activeViewTab == 1
                            ? const [BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 2))]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: _activeViewTab == 1 ? AppColors.magentaPrimary : AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Today\'s Shifts',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _activeViewTab == 1 ? AppColors.textDark : AppColors.textMuted,
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
            // --- TAB 0: GOOGLE SHEETS MASTER ---
            // Live Sync Header Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withOpacity(0.12),
                        ),
                        child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${hrSheet?.monthTitle ?? "November 2026"} HR Master Sheet',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '${allSheetRows.length} Workforce Rows • Live Synced',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.magentaPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () => _showBroadcastUpdateDialog(context, eco),
                        icon: const Icon(Icons.send_rounded, size: 12, color: Colors.white),
                        label: const Text('Broadcast', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 1. Month Selector for HR
            _buildMonthSelector(context, eco),

            // 2. Employee Selector for HR
            _buildEmployeeSelector(context, eco),

            // Search Box for Sheet
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: AppColors.magentaPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'Search staff by name or EMP NO...',
                        hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11.5),
                        border: InputBorder.none,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Employee Google Sheet Rows List
            if (filteredSheetRows.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: Text('No employee sheet records match query.', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
              )
            else
              ...filteredSheetRows.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Text(
                                      'EMP #${r.empNo}',
                                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    r.name,
                                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'S.No ${r.sNo}',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Metrics Pills Row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _hrMetricChip('Late', '${r.lateCount}/3', const Color(0xFFFEF9C3), const Color(0xFF854D0E)),
                          _hrMetricChip('CL', '${r.clDaysUsed}', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                          _hrMetricChip('LOP', '${r.lopDaysUsed}', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                          _hrMetricChip('Perm', r.formattedPermissionUsed, const Color(0xFFDCFCE7), const Color(0xFF166534)),
                          _hrMetricChip('MNW', '${r.mnwDaysCount}d', const Color(0xFFDBEAFE), const Color(0xFF1E40AF)),
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
                            children: List.generate(hrSheet?.daysInMonth ?? 31, (dIdx) {
                              final day = dIdx + 1;
                              final rec = r.days[day];
                              final bg = rec?.backgroundColor ?? Colors.white;
                              final tc = rec?.textColor ?? const Color(0xFF64748B);
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
            // --- TAB 1: TODAY'S SHIFTS ---
          // Live Date Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.magentaPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Today: ${DateTime.now().day} ${_monthName(DateTime.now().month)} ${DateTime.now().year}',
                    style: GoogleFonts.outfit(
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
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isTuesday ? '$weekOffCount WEEK OFF' : '$activeDutyCount ON DUTY',
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isTuesday ? const Color(0xFF64748B) : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3 Attendance KPI Pills
          Row(
            children: [
              Expanded(
                child: _kpiPill(
                  isTuesday ? 'Week-off' : 'On-Time',
                  isTuesday ? '$weekOffCount Staff' : '$onTimeCount Staff',
                  isTuesday ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
                  isTuesday ? Icons.weekend_outlined : Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _kpiPill('Late In', '$lateCount Staff', const Color(0xFFF59E0B), Icons.alarm)),
              const SizedBox(width: 8),
              Expanded(child: _kpiPill('On Duty', '$activeDutyCount Staff', const Color(0xFF3B82F6), Icons.badge_outlined)),
            ],
          ),
          const SizedBox(height: 14),

          // Search Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.magentaPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Search by staff name, ID or role...',
                      hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11.5),
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Staff Attendance Cards List
          if (filteredSummaries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Text('No attendance records found matching query.', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
            )
          else
            ...filteredSummaries.map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: !s.isPresent ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x040F172A), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Avatar, Name, Dept, Status
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: !s.isPresent ? const Color(0xFFFDA4AF) : AppColors.magentaPrimary,
                          child: Text(
                            s.initials,
                            style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.employeeName,
                                style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${s.employeeId} • ${s.department}',
                                style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: s.statusBadgeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: s.statusBadgeColor.withOpacity(0.35)),
                          ),
                          child: Text(
                            s.statusBadgeText,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: s.statusBadgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                          final emp = eco.employees.firstWhere(
                            (e) => e.id == s.employeeId,
                            orElse: () => eco.employees.first,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HrBiometricPunchAuditScreen(employee: emp)),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Biometric Punch Audit',
                                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: AppColors.magentaPrimary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _hrMetricChip(String label, String value, Color bg, Color text) {
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

  Widget _buildMonthSelector(BuildContext context, EcosystemProvider eco) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.magentaPrimary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'SELECT ATTENDANCE MONTH',
                        style: GoogleFonts.outfit(
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
                  color: AppColors.magentaPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  eco.hrAttendanceSheet?.monthTitle ?? 'November 2026',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.magentaPrimary,
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
                        color: isSel ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: AppColors.magentaPrimary,
                    backgroundColor: const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSel ? AppColors.magentaPrimary : const Color(0xFFCBD5E1),
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

  Widget _buildEmployeeSelector(BuildContext context, EcosystemProvider eco) {
    final allRows = eco.activeAttendanceSheetRows;
    final staffOptions = [
      ('all', 'All Active Staff (${allRows.length})'),
      ...allRows.map((r) => (r.empNo.trim(), '${r.name} (#${r.empNo})')),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                style: GoogleFonts.outfit(
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
                        color: isSel ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xFF1E293B),
                    backgroundColor: const Color(0xFFF8FAFC),
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSel ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
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

  Widget _kpiPill(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[(m - 1).clamp(0, 11)];
  }
}

// ============================================================================
// 9. GROOMING AUDIT SCREEN
// ============================================================================
class HrGroomingAuditScreen extends StatefulWidget {
  const HrGroomingAuditScreen({super.key});

  @override
  State<HrGroomingAuditScreen> createState() => _HrGroomingAuditScreenState();
}

class _HrGroomingAuditScreenState extends State<HrGroomingAuditScreen> {
  String? _selectedGroomingEmpId;
  final TextEditingController _groomingRemarksCtrl = TextEditingController();
  final Map<String, Set<String>> _employeeFollowedGrooming = {};

  Set<String> _getFollowedItems(Employee emp, EcosystemProvider eco) {
    if (_employeeFollowedGrooming.containsKey(emp.id)) {
      return _employeeFollowedGrooming[emp.id]!;
    }
    final audits = eco.getEmployeeGroomingAudits(emp.id);
    final checklist = emp.isFemale
        ? EcosystemProvider.getFemaleGroomingChecklist()
        : EcosystemProvider.getMaleGroomingChecklist();
    if (audits.isNotEmpty && audits.first.followedItems.isNotEmpty) {
      final set = audits.first.followedItems.toSet();
      _employeeFollowedGrooming[emp.id] = set;
      return set;
    }
    final defaultPts = eco.getEmployeeGroomingDailyPoints(emp.id);
    final count = (defaultPts / 10).round().clamp(0, checklist.length);
    final initialSet = checklist.take(count).toSet();
    _employeeFollowedGrooming[emp.id] = initialSet;
    return initialSet;
  }

  @override
  void dispose() {
    _groomingRemarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    // Exclude CEO and OTM Praveenkumar from showroom attire and grooming audits
    final employees = eco.employees.where((e) => e.hasAttendanceAndGrooming && e.roleType != 'ceo').toList();
    final selectedEmp = employees.firstWhere(
      (e) => e.id == (_selectedGroomingEmpId ?? eco.currentEmployee.id),
      orElse: () => employees.isNotEmpty ? employees.first : eco.employees.first,
    );

    final auditHistory = eco.groomingAudits;
    final isFemale = selectedEmp.isFemale;
    final checklist = isFemale
        ? EcosystemProvider.getFemaleGroomingChecklist()
        : EcosystemProvider.getMaleGroomingChecklist();

    final followed = _getFollowedItems(selectedEmp, eco);
    final earnedPoints = (followed.length * 10).clamp(0, 50);
    final percentage = ((earnedPoints / 50.0) * 100.0).round();
    final isScoreGood = percentage >= 80;

    return HrSubpageScaffold(
      title: 'Attire & Grooming',
      subtitle: '50 Pts Daily Compliance Scale',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Staff Selector Dropdown & Info Card
          LiquidGlassCard(
            padding: const EdgeInsets.all(14),
            borderRadius: 16,
            borderColor: const Color(0xFFE2E8F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Staff Member to Audit:',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedEmp.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, size: 18, color: AppColors.magentaPrimary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: employees.map((e) {
                    return DropdownMenuItem(
                      value: e.id,
                      child: Text(
                        '${e.name} (${e.dept})',
                        style: const TextStyle(fontSize: 12.5),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedGroomingEmpId = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Active Employee Checklist & Scoring Card
          LiquidGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            borderColor: const Color(0xFFE2E8F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isFemale ? const Color(0xFFBE185D) : const Color(0xFF2563EB),
                      child: Text(selectedEmp.initials, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedEmp.name,
                                  style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Flexible(child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isFemale ? const Color(0xFFFFF1F4) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isFemale ? const Color(0xFFFECDD3) : const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  isFemale ? 'FEMALE (SAREE/UNIFORM)' : 'MALE (FORMAL SUIT)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isFemale ? const Color(0xFFBE185D) : const Color(0xFF1D4ED8),
                                  ),
                                ),
                              )),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Daily 50 Pts Scale • Score: $percentage% ($earnedPoints/50 Pts)',
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: isScoreGood ? const Color(0xFF059669) : const Color(0xFFD97706))),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 20),

                // Select All / Deselect All
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFECFDF5),
                        foregroundColor: const Color(0xFF059669),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.select_all, size: 14),
                      label: const Text('Select All (50 Pts)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setState(() {
                          _employeeFollowedGrooming[selectedEmp.id] = checklist.toSet();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        setState(() {
                          _employeeFollowedGrooming[selectedEmp.id] = {};
                        });
                      },
                      child: const Text('Deselect All', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Checklist Items
                ...checklist.map((item) {
                  final isChecked = followed.contains(item);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        final currentSet = Set<String>.from(followed);
                        if (isChecked) {
                          currentSet.remove(item);
                        } else {
                          currentSet.add(item);
                        }
                        _employeeFollowedGrooming[selectedEmp.id] = currentSet;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isChecked ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isChecked ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                              size: 18, color: isChecked ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                                color: isChecked ? const Color(0xFF065F46) : AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: isChecked ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+10 Pts',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isChecked ? const Color(0xFF059669) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),

                // Remarks Field
                TextField(
                  controller: _groomingRemarksCtrl,
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Optional audit remarks (e.g. Ironing neat, hair trimmed)',
                    hintStyle: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                // Save Audit Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isScoreGood ? const Color(0xFF059669) : AppColors.magentaPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      'Save Grooming Audit ($earnedPoints/50 Pts • $percentage%)',
                      style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      final remarks = _groomingRemarksCtrl.text.trim().isNotEmpty
                          ? _groomingRemarksCtrl.text.trim()
                          : (isScoreGood ? 'Daily grooming compliance verified.' : 'Grooming audit recorded.');
                      eco.recordDailyGroomingAudit(
                        empId: selectedEmp.id,
                        followedItems: followed.toList(),
                        pointsEarned: earnedPoints,
                        maxPoints: 50,
                        reason: remarks,
                        auditedBy: '${context.read<EcosystemProvider>().currentEmployee.name} (HR)',
                      );
                      _groomingRemarksCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF059669),
                          content: Text('Saved Grooming Audit: $earnedPoints/50 Pts ($percentage%) for ${selectedEmp.name}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Company-Wide Grooming Audit Log
          LiquidGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            borderColor: const Color(0xFFE2E8F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('COMPANY-WIDE GROOMING AUDIT LOG', overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.magentaSubtle, borderRadius: BorderRadius.circular(6)),
                      child: Text('${auditHistory.length} Audits', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary)),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 20),
                if (auditHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No grooming audits recorded yet today.', style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted)),
                  )
                else
                  ...auditHistory.map((audit) {
                    final emp = employees.firstWhere((e) => e.id == audit.empId, orElse: () => employees.first);
                    final isPass = audit.percentage >= 80;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isPass ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPass ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              children: [
                                Text('${audit.percentage}%', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: isPass ? const Color(0xFF059669) : const Color(0xFFE11D48))),
                                Text('${audit.pointsEarned}/${audit.maxPoints}', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${emp.name} • ${emp.dept}', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                const SizedBox(height: 2),
                                Text(audit.reason, style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Text('Followed: ${audit.followedItems.length}/5', style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF059669), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
