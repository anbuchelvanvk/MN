import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/personal_todo_section.dart';
import '../../core/widgets/prescription_viewer_dialog.dart';
import '../../core/widgets/cross_dept_blocker_section.dart';
import '../../models/attendance_models.dart';
import '../../models/employee_model.dart';
import '../../providers/ecosystem_provider.dart';
import 'hr_biometric_punch_audit_screen.dart';
import 'hr_employee_inspection_screen.dart';
import 'hr_management_widgets.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
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

    final onlineEmployees = filteredEmployees.where((e) => !adminEmployees.contains(e)).toList();

    return HrSubpageScaffold(
      title: 'Staff Directory',
      subtitle: '${allEmployees.length} Corporate Personnel',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.magentaSubtle,
              foregroundColor: AppColors.magentaPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.person_add_alt_1, size: 16),
            label: Text('New Hire', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
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
                    style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Search staff by name, role, email, phone, ID...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11.5),
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
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
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
              style: GoogleFonts.plusJakartaSans(
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

  Widget _buildStaffCard(BuildContext context, EcosystemProvider eco, Employee emp) {
    final isAbsent = eco.isEmployeeAbsent(emp.id);
    final isPasswordRevealed = _revealedPasswords[emp.id] ?? false;
    final empPassword = emp.password.isNotEmpty ? emp.password : 'password123';

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
                      style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isAbsent ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAbsent ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAbsent ? const Color(0xFFE11D48) : const Color(0xFF059669),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAbsent ? 'ABSENT' : 'PRESENT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isAbsent ? const Color(0xFFE11D48) : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.email_outlined, size: 12, color: AppColors.magentaPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Email: ${emp.email}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textDark),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.wc_outlined, size: 12, color: AppColors.magentaPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Gender: ${emp.gender.isNotEmpty ? emp.gender : 'Male'}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textDark),
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
                color: const Color(0xFFFDF2F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCE7F3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 13, color: AppColors.magentaPrimary),
                  const SizedBox(width: 5),
                  Text(
                    'Password: ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.magentaPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      isPasswordRevealed ? empPassword : '••••••••',
                      style: GoogleFonts.plusJakartaSans(
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
                  const SizedBox(width: 6),
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
                          const SizedBox(width: 2),
                          Text(
                            'Reset',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.magentaPrimary,
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
      ),
    );
  }

  void _openResetPasswordDialog(BuildContext context, EcosystemProvider eco, Employee emp) {
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Password',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset password for ${emp.name} (#${emp.id}):', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted)),
            const SizedBox(height: 10),
            TextField(
              controller: newPassCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Enter new password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
              backgroundColor: AppColors.magentaPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newPass = newPassCtrl.text.trim();
              if (newPass.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              await eco.adminResetEmployeePassword(empId: emp.id, newPassword: newPass);
              if (ctx.mounted) Navigator.pop(ctx);
              messenger.showSnackBar(
                SnackBar(content: Text('Password for ${emp.name} reset to: $newPass'), backgroundColor: const Color(0xFF10B981)),
              );
            },
            child: const Text('Save & Reset'),
          ),
        ],
      ),
    );
  }

  static void openAddHireDialog(BuildContext context, EcosystemProvider eco) {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final dobController = TextEditingController();
    DateTime? selectedDob;
    String selectedGender = 'Male';
    String roleHierarchy = 'Employee';
    String selectedDept = 'Online Department';

    final deptOptions = ['Online Department', 'Administration', 'Operations', 'Sales', 'Technology', 'Media', 'Accounts', 'HR'];

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
                        Text(
                          'Add New Staff & Credentials',
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Role Type Toggle
                    Text('Assign Role Type:', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark)),
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

                    // Full Name
                    Text('Staff Full Name:', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark),
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
                              Text('Gender:', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
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
                              Text('Date of Birth:', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Department:', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: selectedDept,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                                items: deptOptions.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (v) => setModalState(() => selectedDept = v ?? 'Online Department'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Role Title:', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: roleController,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDark),
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
                    const SizedBox(height: 12),

                    // Email & Phone
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Official Email (Login ID):', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: emailController,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDark),
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
                              Text('Phone Number:', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDark),
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
                    Text('App Login Password:', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: passwordController,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDark),
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
                          backgroundColor: AppColors.magentaPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text('Register Staff & Grant Access', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                        onPressed: () {
                          if (nameController.text.trim().isEmpty) return;
                          final genEmail = emailController.text.trim().isNotEmpty
                              ? emailController.text.trim()
                              : '${nameController.text.trim().toLowerCase().replaceAll(' ', '.')}@mnjewelpark.com';
                          final cleanPass = passwordController.text.trim().isNotEmpty ? passwordController.text.trim() : 'mnj12345';
                          final cleanRole = roleController.text.trim().isNotEmpty ? roleController.text.trim() : 'Operations Staff';
                          final cleanPhone = phoneController.text.trim().isNotEmpty ? phoneController.text.trim() : '+91 98450 00000';

                          eco.addNewEmployee(
                            name: nameController.text.trim(),
                            role: cleanRole,
                            phone: cleanPhone,
                            email: genEmail,
                            dept: selectedDept,
                            experienceCategory: 'standard',
                            experienceYears: 'Confirmed Corporate Staff',
                            roleType: roleHierarchy == 'Team Lead' ? 'team_lead' : 'employee',
                            password: cleanPass,
                            dob: dobController.text.trim().isNotEmpty ? dobController.text.trim() : '01-01-2000',
                            gender: selectedGender,
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
    return const HrSubpageScaffold(
      title: 'Social Causes',
      subtitle: 'Pillar 5 Workforce Approval',
      body: HrSocialCauseApprovalSection(
        reviewerName: 'Mohankumar G (HR)',
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
    return const HrSubpageScaffold(
      title: 'Staff Tasks',
      subtitle: 'Task Allocation & Operations',
      body: HrEmployeeTodoManagementSection(
        authorizedName: 'Mohankumar G (HR)',
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
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
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

    final onTimeCount = allSummaries.where((s) => s.status == DailyAttendanceStatus.presentOnTime).length;
    final lateCount = allSummaries.where((s) => s.status == DailyAttendanceStatus.lateLogin).length;
    final activeDutyCount = allSummaries.where((s) => s.isCurrentlyOnDuty).length;

    // Filter Google Sheet rows
    final allSheetRows = hrSheet?.employees ?? [];
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
          icon: const Icon(Icons.campaign_rounded, color: AppColors.magentaPrimary),
          tooltip: 'Broadcast Attendance Update to Staff',
          onPressed: () => _showBroadcastUpdateDialog(context, eco),
        ),
        IconButton(
          icon: isSyncing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.magentaPrimary),
                )
              : const Icon(Icons.sync_rounded, color: AppColors.magentaPrimary),
          tooltip: 'Sync Google Sheets Attendance',
          onPressed: () async {
            await eco.syncGoogleSheetsAttendance(notifyIfUpdated: true);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF10B981),
                content: Text('HR Attendance synchronized with Google Sheets!'),
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
                              style: GoogleFonts.plusJakartaSans(
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
                              style: GoogleFonts.plusJakartaSans(
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
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '${allSheetRows.length} Workforce Rows • Live Synced',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDark),
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
                child: Text('No employee sheet records match query.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted)),
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
                                      style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    r.name,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
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
                    style: GoogleFonts.plusJakartaSans(
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
                    '$activeDutyCount ON DUTY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
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
              Expanded(child: _kpiPill('On-Time', '$onTimeCount Staff', const Color(0xFF10B981), Icons.check_circle_outline)),
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
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Search by staff name, ID or role...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11.5),
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
              child: Text('No attendance records found matching query.', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted)),
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
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.employeeName,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${s.employeeId} • ${s.department}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: s.statusBadgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 2: In Time, Lunch Break, Out Time
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.login_rounded, size: 11, color: Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'In Time',
                                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(s.inTimeString, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.restaurant_rounded, size: 11, color: Color(0xFFF59E0B)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Lunch Break',
                                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(s.lunchSummary, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.logout_rounded, size: 11, color: Color(0xFFE11D48)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Out Time',
                                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(s.outTimeString, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Row 3: Total Net Work & View Biometric Punch Audit Link
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Total Net Work: ${s.workHoursFormatted}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
                        ),
                        InkWell(
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
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: AppColors.magentaPrimary),
                              ],
                            ),
                          ),
                        ),
                      ],
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
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: text),
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
                  color: AppColors.magentaPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  eco.hrAttendanceSheet?.monthTitle ?? 'November 2026',
                  style: const TextStyle(
                    fontSize: 9.5,
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
    final staffOptions = [
      ('all', 'All Active Staff (5)'),
      ('7', 'Mohankumar G (#7 - HR)'),
      ('6', 'Gokulakrishnan K (#6)'),
      ('33', 'Mithra M (#33)'),
      ('65', 'Kaaviya (#65)'),
      ('67', 'Nisha (#67)'),
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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
// 8. LEAVES & PERMISSIONS SCREEN
// ============================================================================
class HrLeavesPermissionsScreen extends StatefulWidget {
  const HrLeavesPermissionsScreen({super.key});

  @override
  State<HrLeavesPermissionsScreen> createState() => _HrLeavesPermissionsScreenState();
}

class _HrLeavesPermissionsScreenState extends State<HrLeavesPermissionsScreen> {
  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final pendingPermissions = eco.allPendingPermissions;
    final pendingMedLeaves = eco.allPendingMedicalLeaves;
    final delegations = eco.delegations;

    return HrSubpageScaffold(
      title: 'Leaves & Permissions',
      subtitle: '${pendingPermissions.length + pendingMedLeaves.length} Pending Approval',
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppColors.magentaPrimary),
          tooltip: 'Delegate Emergency Leave',
          onPressed: () => _openEmergencyDelegationDialog(context, eco),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Emergency Permissions (2-Hour Quota Flow)
          LiquidGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            borderColor: const Color(0xFFE2E8F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.magentaPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Emergency Permission Requests',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.magentaSubtle, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${pendingPermissions.length} Pending',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'HR grants permission within 2.0h monthly quota. CEO gives final acceptance.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 20),

                if (pendingPermissions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No pending permission requests.', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted)),
                  )
                else
                  ...pendingPermissions.map((perm) {
                    final emp = eco.employees.firstWhere((e) => e.id == perm.empId, orElse: () => eco.employees.first);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.magentaPrimary,
                                child: Text(emp.initials, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(emp.name, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                    Text('${perm.requestedHours} Hour(s) Requested • ${perm.date}', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                                child: Text(perm.status, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Reason: ${perm.reason}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF475569))),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => eco.rejectPermission(perm.id, rejectedBy: 'HR'),
                                child: const Text('Reject', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11.5)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => eco.hrGrantPermission(perm.id),
                                child: const Text('Grant to CEO', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 16),

          // Section 2: Medical Leaves (Mandatory Prescription <= 150 KB)
          LiquidGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            borderColor: const Color(0xFFE2E8F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, color: AppColors.magentaPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Emergency Medical Leaves',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.magentaSubtle, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        '${pendingMedLeaves.length} Pending',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Requires authenticated prescription inspection before granting.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 20),

                if (pendingMedLeaves.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No pending medical leave requests.', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted)),
                  )
                else
                  ...pendingMedLeaves.map((m) {
                    final emp = eco.employees.firstWhere((e) => e.id == m.empId, orElse: () => eco.employees.first);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFEF4444),
                                child: Text(emp.initials, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(emp.name, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                    Text('Medical Leave • ${m.date}', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              if (m.prescriptionBase64.isNotEmpty)
                                TextButton.icon(
                                  icon: const Icon(Icons.remove_red_eye, size: 14, color: AppColors.magentaPrimary),
                                  label: const Text('Prescription', style: TextStyle(fontSize: 11, color: AppColors.magentaPrimary)),
                                  onPressed: () => PrescriptionViewerDialog.show(context, leave: m, isHr: true),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Doctor / Medical Reason: ${m.reason}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF475569))),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => eco.rejectMedicalLeave(m.id, rejectedBy: 'HR'),
                                child: const Text('Reject', style: TextStyle(color: Color(0xFFEF4444), fontSize: 11.5)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => eco.hrGrantMedicalLeave(m.id),
                                child: const Text('Grant to CEO', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 16),

          // Section 3: Leave Delegations Ledger
          LiquidGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            borderColor: const Color(0xFFE2E8F0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, color: AppColors.magentaPrimary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Leave Task Delegations (${delegations.length})',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 20),
                if (delegations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No active leave task delegations in the company.', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted)),
                  )
                else
                  ...delegations.map((d) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_pin_rounded, size: 16, color: AppColors.magentaPrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${d.absentEmpName} → ${d.coveringEmpName}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                Text('Tasks delegated: ${d.taskCount} • ${d.date}', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Active', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                          ),
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
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delegate Emergency Leave Tasks', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  Text('Reassign SOP tasks immediately so operations run without blockage.', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 12),

                  Text('Absent Employee on Leave:', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: absentEmp,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    items: eco.employees.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.name} (${e.dept})'))).toList(),
                    onChanged: (v) => setModalState(() => absentEmp = v),
                  ),
                  const SizedBox(height: 12),

                  Text('Substitute Employee to Cover:', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: coveringEmp,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    items: eco.employees.map((e) => DropdownMenuItem(value: e.id, child: Text('${e.name} (${e.role})'))).toList(),
                    onChanged: (v) => setModalState(() => coveringEmp = v),
                  ),
                  const SizedBox(height: 12),

                  Text('Reason / Handover Notes:', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Sudden medical emergency, covering morning sales floor',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.magentaPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Execute Delegation & Reassign Tasks'),
                      onPressed: () {
                        if (absentEmp == null || coveringEmp == null) return;
                        eco.delegateEmergencyLeave(
                          absentEmpId: absentEmp!,
                          coveringEmpId: coveringEmp!,
                          reason: reasonController.text.trim().isEmpty ? 'Leave Coverage' : reasonController.text.trim(),
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF10B981),
                            content: Text('Emergency delegation active! Tasks reassigned to substitute.'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: selectedEmp.id,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, size: 18, color: AppColors.magentaPrimary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  items: employees.map((e) {
                    return DropdownMenuItem(
                      value: e.id,
                      child: Text('${e.name} (${e.dept}) • ${e.gender.isNotEmpty ? e.gender : 'Male'}', style: const TextStyle(fontSize: 12.5)),
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
                      backgroundColor: isFemale ? const Color(0xFFEC4899) : const Color(0xFF2563EB),
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
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isFemale ? const Color(0xFFFDF2F8) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isFemale ? const Color(0xFFFBCFE8) : const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  isFemale ? 'FEMALE (SAREE/UNIFORM)' : 'MALE (FORMAL SUIT)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: isFemale ? const Color(0xFFDB2777) : const Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('Daily 50 Pts Scale • Score: $percentage% ($earnedPoints/50 Pts)',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: isScoreGood ? const Color(0xFF059669) : const Color(0xFFD97706))),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 20),

                // Select All / Deselect All
                Row(
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
                              style: GoogleFonts.plusJakartaSans(
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
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Optional audit remarks (e.g. Ironing neat, hair trimmed)',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
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
                        auditedBy: 'Mohankumar G (HR)',
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
                    Text('COMPANY-WIDE GROOMING AUDIT LOG', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.magentaSubtle, borderRadius: BorderRadius.circular(6)),
                      child: Text('${auditHistory.length} Audits', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary)),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFFF1F5F9), height: 20),
                if (auditHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No grooming audits recorded yet today.', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted)),
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
                              color: isPass ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              children: [
                                Text('${audit.percentage}%', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: isPass ? const Color(0xFF059669) : const Color(0xFFE11D48))),
                                Text('${audit.pointsEarned}/${audit.maxPoints}', style: GoogleFonts.plusJakartaSans(fontSize: 8.5, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${emp.name} • ${emp.dept}', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                const SizedBox(height: 2),
                                Text(audit.reason, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          Text('Followed: ${audit.followedItems.length}/5', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: const Color(0xFF059669), fontWeight: FontWeight.bold)),
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
