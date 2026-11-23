import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../models/employee_model.dart';
import '../../models/profile_document_models.dart';
import '../../providers/ecosystem_provider.dart';
import '../ceo/ceo_subpages.dart';
import '../dept_head/dept_head_subpages.dart';
import '../employee/employee_subpages.dart';
import 'tier_pillar_screen.dart';

class ProfilePillarScreen extends StatefulWidget {
  const ProfilePillarScreen({super.key});

  @override
  State<ProfilePillarScreen> createState() => _ProfilePillarScreenState();
}

class _ProfilePillarScreenState extends State<ProfilePillarScreen> {
  String? _selectedDropdownDoc;
  String _activeFilter = 'All'; // 'All', 'Submitted', 'Pending'
  int _selectedRingIndex = 1; // 0: Attendance, 1: Documents, 2: Grooming, 3: Sale, 4: Permission, 5: Conduct
  bool _isPasswordRevealed = false;
  int _selectedCalendarMonth = DateTime.now().month;
  final int _selectedCalendarYear = DateTime.now().year;
  String _ceoSelectedStaffId = 'all';
  String _ceoStaffDocFilter = 'All';

  @override
  void initState() {
    super.initState();
    // Default selected option in dropdown
    _selectedDropdownDoc = DocumentTemplates.standardOptions.first['title'];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EcosystemProvider>();
    final employee = provider.currentEmployee;
    final docs = provider.originalDocuments;

    final filteredDocs = docs.where((d) {
      if (_activeFilter == 'Submitted') {
        return d.status == DocumentSubmissionStatus.submitted;
      } else if (_activeFilter == 'Pending') {
        return d.status == DocumentSubmissionStatus.pending;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: AppBar(
        backgroundColor: AppColors.burgundyBg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.sandPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'WORK & OPERATIONS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.sandLight,
            letterSpacing: 0.8,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: LiquidGlassPill(
                label: employee.dept.toUpperCase(),
                color: AppColors.sandGold,
                icon: Icons.badge_outlined,
              ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Staff Profile Overview Card
            _buildStaffProfileCard(employee),
            const SizedBox(height: 12),

            // 1b. My Work & To-Do Tasks
            _buildWorkTasksCard(context, provider, employee),
            const SizedBox(height: 12),

            // 1c. Account Security & Password Management
            _buildAccountSecurityCard(context, provider, employee),
            const SizedBox(height: 14),

            // 2. The 6 Professional Profile Rings Matrix
            _buildSixRingsMatrix(context, provider),
            const SizedBox(height: 16),

            // 3. Subsystem Selector Tabs
            _buildSubsystemTabs(),
            const SizedBox(height: 14),

            // 4. Dynamic Subsystem Views based on selected ring
            if (_selectedRingIndex == 0) ...[
              if (employee.isCeo || employee.isTeamLead)
                _buildCeoStaffAttendanceSection(context, provider)
              else if (employee.isExternalSupport)
                _buildOtmExemptSection('Attendance', employee)
              else
                _buildMonthlyAttendanceSection(context, provider),
            ] else if (_selectedRingIndex == 1) ...[
              if (employee.isCeo || employee.isTeamLead)
                _buildCeoStaffVaultCustodySection(context, provider)
              else if (employee.isExternalSupport)
                _buildOtmExemptSection('Document Verification & Safe Vault Custody', employee)
              else ...[
                // Inside here: Document Submission (Original Document Custody)
                _buildVaultMetricsBar(provider),
                const SizedBox(height: 16),
                _buildDropdownAndAddSection(context, provider),
                const SizedBox(height: 16),
                _buildLedgerHeaderWithFilter(docs),
                const SizedBox(height: 10),
                if (filteredDocs.isEmpty)
                  _buildEmptyState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) => _buildDocumentCard(ctx, provider, filteredDocs[idx]),
                  ),
              ],
            ] else if (_selectedRingIndex == 2) ...[
              if (employee.isTeamLead)
                _buildTeamGroomingInspectionSection(context, provider)
              else if (employee.isCeo || employee.isExternalSupport)
                _buildOtmExemptSection('Daily Retail Showroom Grooming & Attire', employee)
              else
                _buildGroomingSection(context, provider),
            ],
            const SizedBox(height: 20),

            // 5. Direct Gateway to Pillar 4: Tier Rating
            _buildPillar4Gateway(context, provider),
            const SizedBox(height: 12),

            // Logout Button
            LogoutConfirmDialog.buildButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildAccountSecurityCard(BuildContext context, EcosystemProvider provider, dynamic employee) {
    final empPassword = (employee.password as String?)?.isNotEmpty == true
        ? employee.password as String
        : 'Not stored (managed by Firebase Auth)';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandGold.withOpacity(0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
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
                  color: AppColors.sandGold.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 16, color: AppColors.sandGold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ACCOUNT SECURITY & CREDENTIALS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandGold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sandGold,
                  foregroundColor: AppColors.burgundyCard,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showChangePasswordDialog(context, provider, employee),
                icon: const Icon(Icons.lock_reset, size: 13, color: AppColors.burgundyCard),
                label: const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.burgundyCard),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFCE7F3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.key, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(
                  'Active Password: ',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                ),
                Expanded(
                  child: Text(
                    _isPasswordRevealed ? empPassword : '••••••••',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                      letterSpacing: _isPasswordRevealed ? 0 : 1.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isPasswordRevealed ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                    color: AppColors.sandGold,
                  ),
                  onPressed: () => setState(() => _isPasswordRevealed = !_isPasswordRevealed),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, EcosystemProvider provider, dynamic employee) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool hideCurrent = true;
    bool hideNew = true;
    bool hideConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.sandGold.withOpacity(0.4)),
          ),
          title: Text(
            'Change Account Password',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update your login credentials for official portal access.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currentPassCtrl,
                  obscureText: hideCurrent,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.sandLight),
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.magentaPrimary)),
                    suffixIcon: IconButton(
                      icon: Icon(hideCurrent ? Icons.visibility : Icons.visibility_off, size: 16, color: AppColors.sandGold),
                      onPressed: () => setDlgState(() => hideCurrent = !hideCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPassCtrl,
                  obscureText: hideNew,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.sandLight),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.magentaPrimary)),
                    suffixIcon: IconButton(
                      icon: Icon(hideNew ? Icons.visibility : Icons.visibility_off, size: 16, color: AppColors.sandGold),
                      onPressed: () => setDlgState(() => hideNew = !hideNew),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: hideConfirm,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.sandLight),
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.magentaPrimary)),
                    suffixIcon: IconButton(
                      icon: Icon(hideConfirm ? Icons.visibility : Icons.visibility_off, size: 16, color: AppColors.sandGold),
                      onPressed: () => setDlgState(() => hideConfirm = !hideConfirm),
                    ),
                  ),
                ),
              ],
            ),
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
                final currentPass = currentPassCtrl.text.trim();
                final newPass = newPassCtrl.text.trim();
                final confirmPass = confirmPassCtrl.text.trim();

                final messenger = ScaffoldMessenger.of(context);

                if (currentPass.isEmpty || newPass.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Please fill all required password fields.'), backgroundColor: AppColors.ragRed),
                  );
                  return;
                }
                if (newPass.length < 6) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('New password must be at least 6 characters.'), backgroundColor: AppColors.ragRed),
                  );
                  return;
                }
                if (newPass != confirmPass) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('New password and confirm password do not match.'), backgroundColor: AppColors.ragRed),
                  );
                  return;
                }

                final error = await provider.changeEmployeePasswordWithReason(
                  empId: employee.id,
                  oldPassword: currentPass,
                  newPassword: newPass,
                );

                if (ctx.mounted) Navigator.pop(ctx);

                if (error == null) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: AppColors.ragRed,
                    ),
                  );
                }
              },
              child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffProfileCard(dynamic employee) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.magentaPrimary, width: 2),
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
                employee.initials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
                    Flexible(
                      child: Text(
                        employee.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sandGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                      ),
                      child: Text(
                        employee.id,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  employee.straightCutDesignation,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.sandPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.sandGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.sandGold.withOpacity(0.35)),
                      ),
                      child: Text(
                        'Occasional',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sandGold,
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

  Widget _buildWorkTasksCard(BuildContext context, EcosystemProvider provider, dynamic employee) {
    final tasks = provider.currentEmployeeTasks;
    final pendingTasks = tasks.where((t) => t.status == 'pending').toList();
    final completedTasks = tasks.where((t) => t.status == 'completed').toList();

    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_outlined, size: 18, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MY WORK & TO-DO TASKS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${pendingTasks.length} Pending • ${completedTasks.length} Completed',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployeeThingsToDoScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD97706).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFD97706)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (pendingTasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...pendingTasks.take(2).map((task) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.burgundySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radio_button_unchecked, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.sandLight,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.priority.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD97706),
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

  Widget _buildSixRingsMatrix(BuildContext context, EcosystemProvider provider) {
    final employee = provider.currentEmployee;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
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
                    const Icon(Icons.incomplete_circle_outlined, color: AppColors.sandGold, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'WORK & OPERATIONS RINGS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.sandGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                ),
                child: Text(
                  'WORK PILLAR 3',
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
            'Tap any ring to inspect individual subsystem audits, policies, and actions.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),

          // CEO has 2 governance rings: Staff Attendance & Staff Vault Custody
          if (employee.isCeo) ...[
            Row(
              children: [
                Expanded(
                  child: _buildRingCard(
                    index: 0,
                    title: 'Staff Attend',
                    displayValue: '100%',
                    subText: 'All On-Duty',
                    progress: 1.0,
                    ringColor: AppColors.ragGreen,
                    icon: Icons.fact_check_outlined,
                    statusText: 'Company Duty',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRingCard(
                    index: 1,
                    title: 'Staff Vault',
                    displayValue: provider.allStaffDocsCount == 0 ? '0 Docs' : '${provider.allStaffSubmittedCount}/${provider.allStaffDocsCount}',
                    subText: provider.allStaffDocsCount == 0 ? '0 Verified' : '${provider.allStaffSubmittedCount} Verified',
                    progress: 1.0,
                    ringColor: provider.allStaffPendingCount == 0 ? AppColors.ragGreen : const Color(0xFFF59E0B),
                    icon: Icons.lock_clock_outlined,
                    statusText: provider.allStaffPendingCount == 0 ? 'Custody Safe' : '${provider.allStaffPendingCount} Pending',
                  ),
                ),
              ],
            ),
          ] else ...[
            // Staff & Team Lead have 3 rings: Attendance, Documents, Grooming
            Builder(builder: (_) {
              final isTuesday = DateTime.now().weekday == DateTime.tuesday;
              final isLead = employee.isTeamLead;
              final deptTeam = provider.employees.where((e) =>
                  e.dept.toLowerCase() == employee.dept.toLowerCase() &&
                  e.id != employee.id &&
                  e.hasAttendanceAndGrooming).toList();
              final deptTotal = deptTeam.length;
              final deptPresent = isTuesday ? 0 : deptTeam.where((e) => !provider.isEmployeeAbsent(e.id)).length;
              final deptDocs = deptTeam.expand((e) => provider.getEmployeeDocuments(e.id)).toList();
              final deptSubmittedDocs = deptDocs.where((d) => d.status == DocumentSubmissionStatus.submitted).length;
              final deptTotalDocs = deptDocs.length;

              return Row(
                children: [
                  Expanded(
                    child: _buildRingCard(
                      index: 0,
                      title: isLead ? 'Team Attend' : 'Attendance',
                      displayValue: isLead
                          ? (isTuesday
                              ? 'Week-off'
                              : (deptTotal > 0 ? '$deptPresent/$deptTotal' : 'All Set'))
                          : '${provider.monthlyAttendancePercentage.toStringAsFixed(0)}%',
                      subText: isLead
                          ? (isTuesday ? 'Tuesday Week-off' : '${employee.dept} Team')
                          : '${provider.workingDaysAttended}/${provider.totalCalendarDaysInCurrentMonth} Days',
                      progress: isLead
                          ? (isTuesday ? 1.0 : (deptTotal > 0 ? (deptPresent / deptTotal) : 1.0))
                          : (provider.monthlyAttendancePercentage / 100.0).clamp(0.0, 1.0),
                      ringColor: isLead
                          ? (isTuesday ? const Color(0xFF94A3B8) : const Color(0xFF10B981))
                          : (provider.workingDaysAttended == 0 ? const Color(0xFF94A3B8) : (provider.monthlyAttendancePercentage >= 90.0 ? AppColors.ragGreen : const Color(0xFFF59E0B))),
                      icon: Icons.fact_check_outlined,
                      statusText: isLead
                          ? (isTuesday ? 'Tuesday Week-off' : (deptTotal > 0 ? '$deptPresent Present' : 'All Set'))
                          : (provider.workingDaysAttended == 0 ? 'No Punches' : '${provider.monthlyAttendancePercentage.toStringAsFixed(1)}% Ratio'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRingCard(
                      index: 1,
                      title: isLead ? 'Team Vault' : 'Documents',
                      displayValue: isLead
                          ? (deptTotalDocs > 0 ? '$deptSubmittedDocs/$deptTotalDocs' : 'Safe')
                          : (provider.totalOriginalsCount == 0 ? '0 Docs' : '${(provider.documentsSubmissionRatio * 100).toStringAsFixed(0)}%'),
                      subText: isLead
                          ? 'Custody Safe'
                          : (provider.totalOriginalsCount == 0 ? '0 Uploaded' : '${provider.submittedOriginalsCount}/${provider.totalOriginalsCount} Vault'),
                      progress: isLead
                          ? (deptTotalDocs > 0 ? (deptSubmittedDocs / deptTotalDocs) : 1.0)
                          : provider.documentsSubmissionRatio,
                      ringColor: isLead
                          ? const Color(0xFF10B981)
                          : (provider.totalOriginalsCount == 0 ? const Color(0xFF94A3B8) : (provider.pendingOriginalsCount == 0 ? AppColors.ragGreen : const Color(0xFFEF4444))),
                      icon: Icons.lock_clock_outlined,
                      statusText: isLead
                          ? (deptTotalDocs > 0 ? '$deptSubmittedDocs Verified' : 'Custody Safe')
                          : (provider.totalOriginalsCount == 0 ? 'Need to be added' : (provider.pendingOriginalsCount == 0 ? 'Custody Safe' : '${provider.pendingOriginalsCount} Pending')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildRingCard(
                      index: 2,
                      title: isLead ? 'Team Groom' : 'Grooming',
                      displayValue: isLead
                          ? '50 Pts'
                          : (provider.getEmployeeGroomingAudits(provider.activeEmpId).isNotEmpty ? '${provider.getEmployeeGroomingPercentage(provider.activeEmpId).toStringAsFixed(0)}%' : '0%'),
                      subText: isLead
                          ? 'Inspection'
                          : (provider.getEmployeeGroomingAudits(provider.activeEmpId).isNotEmpty ? '${provider.getEmployeeGroomingDailyPoints(provider.activeEmpId)}/50 Pts' : 'Pending Audit'),
                      progress: isLead ? 1.0 : (provider.getEmployeeGroomingPercentage(provider.activeEmpId) / 100.0).clamp(0.0, 1.0),
                      ringColor: isLead
                          ? AppColors.sandGold
                          : (provider.getEmployeeGroomingAudits(provider.activeEmpId).isEmpty
                              ? const Color(0xFF94A3B8)
                              : (provider.getEmployeeGroomingPercentage(provider.activeEmpId) >= 80 ? AppColors.magentaPrimary : const Color(0xFFF59E0B))),
                      icon: Icons.face_retouching_natural,
                      statusText: isLead ? 'Team Audits' : 'Showroom Attire',
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildRingCard({
    required int index,
    required String title,
    required String displayValue,
    required String subText,
    required double progress,
    required Color ringColor,
    required IconData icon,
    required String statusText,
  }) {
    final isSelected = _selectedRingIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedRingIndex = index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pureWhite : AppColors.burgundySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.magentaPrimary : AppColors.sandBorder,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.magentaPrimary.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2.8,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 13.5,
                          color: isSelected ? AppColors.magentaPrimary : ringColor,
                        ),
                        const SizedBox(height: 1.5),
                        Text(
                          displayValue,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.magentaPrimary : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: ringColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  color: ringColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubsystemTabs() {
    final employee = context.watch<EcosystemProvider>().currentEmployee;
    final List<Map<String, dynamic>> tabs;

    if (employee.isOtm) {
      // Praveenkumar (OTM) guides his Online Department team
      tabs = [
        {'index': 0, 'label': '1. Team Attendance Overview', 'icon': Icons.fact_check_outlined},
        {'index': 1, 'label': '2. Team Vault Custody', 'icon': Icons.shield_outlined},
        {'index': 2, 'label': '3. Team Grooming Inspection', 'icon': Icons.face_retouching_natural},
      ];
    } else if (employee.isCeo) {
      // CEO inspects staff attendance and document vault custody
      tabs = [
        {'index': 0, 'label': '1. Staff Attendance Overview', 'icon': Icons.fact_check_outlined},
        {'index': 1, 'label': '2. Staff Document Vault Ledger', 'icon': Icons.lock_clock_outlined},
      ];
    } else {
      tabs = [
        {'index': 0, 'label': '1. Calendar Attendance', 'icon': Icons.fact_check_outlined},
        {'index': 1, 'label': '2. Vault Custody', 'icon': Icons.lock_clock_outlined},
        {'index': 2, 'label': '3. Grooming & Attire', 'icon': Icons.face_retouching_natural},
      ];
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: tabs.map((tab) {
          final ringIdx = tab['index'] as int;
          final isSelected = _selectedRingIndex == ringIdx;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedRingIndex = ringIdx),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.magentaPrimary : AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.magentaPrimary : AppColors.sandBorder,
                    width: isSelected ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 13,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab['label'] as String,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- SUBSYSTEM 0: MONTHLY ATTENDANCE (FULL CALENDAR JAN–DEC) ---

  Widget _buildMonthlyAttendanceSection(BuildContext context, EcosystemProvider provider) {
    final monthlyRecords = provider.getMonthlyAttendanceForEmployee(
      provider.activeEmpId,
      year: _selectedCalendarYear,
      month: _selectedCalendarMonth,
    );

    final totalMonthDays = monthlyRecords.length;
    final presentCount = monthlyRecords.where((r) =>
        !r.isWeekoff &&
        !r.isOvertime &&
        (r.status.contains('Present') ||
            r.status.contains('Late') ||
            r.status.contains('Permission') ||
            r.status.contains('MN Work') ||
            (r.loginTime != '--:-- --' && r.loginTime != '--' && !r.status.contains('Absent') && !r.status.contains('Leave')))).length;
    final tuesdayOtCount = monthlyRecords.where((r) => r.isOvertime).length;
    final weekoffCount = monthlyRecords.where((r) => r.isWeekoff).length;
    final workingDaysCount = (totalMonthDays - weekoffCount).clamp(1, 31);
    final liveAttendancePercentage = totalMonthDays > 0
        ? (((presentCount + tuesdayOtCount) / workingDaysCount) * 100).round().clamp(0, 100)
        : 0;

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Calendar Attendance Metric Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Month Selector Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FULL CALENDAR ATTENDANCE',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${monthNames[_selectedCalendarMonth - 1]} $_selectedCalendarYear • $totalMonthDays Days Full Calendar',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Month Picker Dropdown (Jan to Dec)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.burgundySurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.sandBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedCalendarMonth,
                        dropdownColor: AppColors.burgundySurface,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.sandGold, size: 18),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                        ),
                        items: List.generate(12, (index) {
                          final m = index + 1;
                          return DropdownMenuItem<int>(
                            value: m,
                            child: Text(monthNames[index]),
                          );
                        }),
                        onChanged: (newMonth) {
                          if (newMonth != null) {
                            setState(() => _selectedCalendarMonth = newMonth);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (liveAttendancePercentage / 100.0).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.burgundySurface,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ragGreen),
                ),
              ),
              const SizedBox(height: 14),

              // 4 Stat tiles
              Row(
                children: [
                  Expanded(
                    child: _metricColumn(
                      title: 'Month Total',
                      value: '$totalMonthDays Days',
                      color: AppColors.sandLight,
                      icon: Icons.calendar_month,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Present',
                      value: '$presentCount Days',
                      color: AppColors.ragGreen,
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Tuesday OT',
                      value: '$tuesdayOtCount OT',
                      color: const Color(0xFF8B5CF6),
                      icon: Icons.access_time_filled_rounded,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Week-offs',
                      value: '$weekoffCount Days',
                      color: AppColors.sandGold,
                      icon: Icons.beach_access_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Full Month Calendar Matrix Container
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
                  Expanded(
                    child: Text(
                      '${monthNames[_selectedCalendarMonth - 1].toUpperCase()} PUNCH MATRIX ($totalMonthDays DAYS)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.5)),
                    ),
                    child: Text(
                      'Tuesday = Overtime (OT)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFC084FC),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Calendar Grid (All 28 to 31 Days of the Selected Month)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: monthlyRecords.map((r) {
                  final dayNumber = r.date.day;
                  const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final wLabel = weekdayLabels[r.date.weekday - 1];

                  Color boxColor = AppColors.burgundyCard;
                  Color borderColor = AppColors.sandBorder.withOpacity(0.5);
                  Color textColor = AppColors.textMuted;
                  String statusTag = '--';
                  IconData? icon;

                  if (r.isOvertime) {
                    boxColor = const Color(0xFF8B5CF6).withOpacity(0.2);
                    borderColor = const Color(0xFF8B5CF6);
                    textColor = const Color(0xFFC084FC);
                    statusTag = 'OT';
                    icon = Icons.bolt;
                  } else if (r.isWeekoff) {
                    boxColor = const Color(0xFF334155).withOpacity(0.4);
                    borderColor = const Color(0xFF475569);
                    textColor = const Color(0xFF94A3B8);
                    statusTag = 'OFF';
                    icon = Icons.beach_access;
                  } else if (r.status.contains('Yet to update') ||
                      r.status.contains('Pending') ||
                      r.status.contains('Upcoming') ||
                      r.status == 'No Punch') {
                    boxColor = const Color(0xFFFEF9C3).withOpacity(0.18);
                    borderColor = const Color(0xFFFACC15).withOpacity(0.6);
                    textColor = const Color(0xFFFACC15);
                    statusTag = 'YTD';
                    icon = Icons.hourglass_top;
                  } else if (r.status.contains('Late')) {
                    boxColor = const Color(0xFFFEF9C3).withOpacity(0.18);
                    borderColor = const Color(0xFFFACC15);
                    textColor = const Color(0xFFFACC15);
                    final lMatch = RegExp(r'L-\d+').firstMatch(r.status);
                    statusTag = lMatch != null ? lMatch.group(0)! : 'L';
                    icon = Icons.access_time;
                  } else if (r.status.contains('Permission')) {
                    boxColor = const Color(0xFFDCFCE7).withOpacity(0.18);
                    borderColor = const Color(0xFF4ADE80);
                    textColor = const Color(0xFF4ADE80);
                    statusTag = 'PM';
                    icon = Icons.timer;
                  } else if (r.status.contains('Loss of Pay') || r.status.contains('LOP')) {
                    boxColor = const Color(0xFFDC2626).withOpacity(0.18);
                    borderColor = const Color(0xFFDC2626);
                    textColor = const Color(0xFFF87171);
                    statusTag = 'LOP';
                    icon = Icons.event_busy;
                  } else if (r.status.contains('Casual Leave') || r.status.contains('CL') || r.status.contains('Leave')) {
                    boxColor = const Color(0xFFEF4444).withOpacity(0.18);
                    borderColor = const Color(0xFFEF4444);
                    textColor = const Color(0xFFF87171);
                    statusTag = 'CL';
                    icon = Icons.event_busy;
                  } else if (r.status.contains('Half Day') || r.status.contains('1/2 D')) {
                    boxColor = const Color(0xFFF97316).withOpacity(0.18);
                    borderColor = const Color(0xFFF97316);
                    textColor = const Color(0xFFFB923C);
                    statusTag = '½D';
                    icon = Icons.hourglass_bottom;
                  } else if (r.status.contains('MN Work') || r.status.contains('MNW')) {
                    boxColor = const Color(0xFF2563EB).withOpacity(0.18);
                    borderColor = const Color(0xFF3B82F6);
                    textColor = const Color(0xFF60A5FA);
                    statusTag = 'MNW';
                    icon = Icons.storefront;
                  } else if (r.status.contains('Present') ||
                      r.status.contains('On Duty') ||
                      r.status.contains('Shift Over') ||
                      (r.loginTime != '--:-- --' && r.loginTime != '--' && !r.status.contains('Absent') && !r.status.contains('Leave'))) {
                    boxColor = AppColors.ragGreen.withOpacity(0.18);
                    borderColor = AppColors.ragGreen.withOpacity(0.6);
                    textColor = AppColors.ragGreen;
                    statusTag = 'P';
                    icon = Icons.check;
                  } else if (r.status.contains('Absent')) {
                    boxColor = const Color(0xFFEF4444).withOpacity(0.18);
                    borderColor = const Color(0xFFEF4444).withOpacity(0.5);
                    textColor = const Color(0xFFEF4444);
                    statusTag = 'A';
                    icon = Icons.close;
                  } else {
                    boxColor = AppColors.burgundyCard;
                    borderColor = AppColors.sandBorder.withOpacity(0.35);
                    textColor = AppColors.textMuted;
                    statusTag = '--';
                    icon = Icons.more_horiz;
                  }

                  return Container(
                    width: 44,
                    height: 52,
                    decoration: BoxDecoration(
                      color: boxColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNumber $wLabel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 10, color: textColor),
                            const SizedBox(width: 2),
                            Text(
                              statusTag,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _legendPill(label: 'Present (P)', color: AppColors.ragGreen),
                  _legendPill(label: 'Late (L)', color: const Color(0xFFF59E0B)),
                  _legendPill(label: 'Permission (PM)', color: const Color(0xFF10B981)),
                  _legendPill(label: 'Tuesday Overtime (OT)', color: const Color(0xFF8B5CF6)),
                  _legendPill(label: 'Tuesday Week-off (OFF)', color: const Color(0xFF94A3B8)),
                  _legendPill(label: 'Leave (CL/LOP)', color: const Color(0xFFEF4444)),
                  _legendPill(label: 'Absent (A)', color: const Color(0xFFEF4444)),
                ],
              ),
              const SizedBox(height: 10),

              // Info Banner explaining Tuesday Week-off & Overtime
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.sandGold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Full calendar tracking (Jan–Dec, 28-31 days). Tuesday is the company week-off; any attendance punched on Tuesday is strictly recorded as Overtime (OT). Each calendar day is logged.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.sandLight),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendPill({required String label, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.sandLight,
          ),
        ),
      ],
    );
  }

  // --- SUBSYSTEM 2: GROOMING & ATTIRE ---

  Widget _buildGroomingSection(BuildContext context, EcosystemProvider provider) {
    final emp = provider.currentEmployee;
    if (emp.isOtm) {
      return LiquidGlassCard(
        padding: const EdgeInsets.all(22),
        borderRadius: 18,
        child: Column(
          children: [
            const Icon(Icons.verified_user_outlined, size: 36, color: AppColors.sandGold),
            const SizedBox(height: 10),
            Text(
              'Grooming & Attire: Not Applicable',
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
            const SizedBox(height: 6),
            const Text(
              'Online Team Manager (OTM) operates under digital project delivery and media editor standards, and is exempt from retail showroom attire & grooming audits.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      );
    }
    final isFemale = emp.isFemale;
    final dailyPoints = provider.getEmployeeGroomingDailyPoints(emp.id);
    final percentage = provider.getEmployeeGroomingPercentage(emp.id);
    final checklist = isFemale
        ? EcosystemProvider.getFemaleGroomingChecklist()
        : EcosystemProvider.getMaleGroomingChecklist();

    final audits = provider.getEmployeeGroomingAudits(emp.id);
    final hasAudit = audits.isNotEmpty;
    final latestAudit = hasAudit ? audits.first : null;
    final followedSet = latestAudit != null && latestAudit.followedItems.isNotEmpty
        ? latestAudit.followedItems.toSet()
        : <String>{};

    final isCompliant = hasAudit && percentage >= 80;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Grooming Score Overview Card (Converted into Percentage & 50 Pts Max)
        LiquidGlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.dry_cleaning_outlined, size: 18, color: AppColors.magentaPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'GROOMING COMPLIANCE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: !hasAudit
                          ? const Color(0xFFF1F5F9)
                          : (isCompliant ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !hasAudit
                            ? const Color(0xFFE2E8F0)
                            : (isCompliant ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3)),
                      ),
                    ),
                    child: Text(
                      hasAudit ? '${percentage.toStringAsFixed(0)}% ($dailyPoints/50)' : 'Pending HR Audit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: !hasAudit
                            ? AppColors.textSecondary
                            : (isCompliant ? const Color(0xFF059669) : const Color(0xFFE11D48)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Evaluated across 5 daily criteria (10 pts each, 50 pts max) and converted into compliance percentage.',
                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),

              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: hasAudit ? (percentage / 100.0).clamp(0.0, 1.0) : 0.0,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompliant ? AppColors.magentaPrimary : const Color(0xFFEF4444),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    !hasAudit
                        ? Icons.hourglass_top
                        : (isCompliant ? Icons.verified : Icons.info_outline),
                    size: 15,
                    color: !hasAudit
                        ? AppColors.textMuted
                        : (isCompliant ? const Color(0xFF059669) : const Color(0xFFE11D48)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      !hasAudit
                          ? 'Pending Daily Floor Audit by HR'
                          : (percentage >= 100
                              ? 'Exemplary Showroom Grooming Standard (100% Compliant)'
                              : (isCompliant
                                  ? 'Approved Daily Attire (${percentage.toStringAsFixed(0)}% • $dailyPoints/50 Pts)'
                                  : 'Attire Standard Attention Needed (${percentage.toStringAsFixed(0)}%)')),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: !hasAudit
                            ? AppColors.textSecondary
                            : (isCompliant ? const Color(0xFF059669) : const Color(0xFFE11D48)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Today's Attire Criteria Breakdown (5 items x 10 pts = 50 pts)
        LiquidGlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isFemale ? "TODAY'S SAREE & ATTIRE CHECKLIST" : "TODAY'S FORMAL ATTIRE CHECKLIST",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '50 Pts Max',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.magentaPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ...checklist.map((item) {
                final isFollowed = followedSet.contains(item);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFollowed ? const Color(0xFFF8FAFC) : const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isFollowed ? const Color(0xFFE2E8F0) : const Color(0xFFFECDD3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFollowed ? Icons.check_circle : Icons.cancel_outlined,
                        size: 16,
                        color: isFollowed ? const Color(0xFF059669) : const Color(0xFFE11D48),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: isFollowed ? FontWeight.w600 : FontWeight.normal,
                            color: isFollowed ? AppColors.textDark : const Color(0xFF9F1239),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isFollowed ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isFollowed ? '+10 Pts' : '0 Pts',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isFollowed ? const Color(0xFF059669) : const Color(0xFFE11D48),
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
        const SizedBox(height: 14),

        // 3. Real-Time HR Attire Audit History
        LiquidGlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'HR GROOMING AUDIT HISTORY',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${audits.length} Records',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (audits.isEmpty)
                Text(
                  'No grooming audits recorded yet.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: audits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final audit = audits[idx];
                    final auditPercent = audit.percentage;
                    final isGood = auditPercent >= 80;

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isGood ? const Color(0xFFE2E8F0) : const Color(0xFFFECDD3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isGood ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${auditPercent.toStringAsFixed(0)}%\n${audit.pointsEarned}/50',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isGood ? const Color(0xFF059669) : const Color(0xFFE11D48),
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  audit.category,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  audit.reason,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                audit.dateFormatted,
                                style: GoogleFonts.plusJakartaSans(fontSize: 9, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                audit.auditedBy.split(' ').first,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  color: AppColors.magentaPrimary,
                                  fontWeight: FontWeight.w600,
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
          ),
        ),
      ],
    );
  }

  // --- SUBSYSTEM 3: PERMISSION & LATE ARRIVALS ---


  Widget _buildVaultMetricsBar(EcosystemProvider provider) {
    final total = provider.totalOriginalsCount;
    final submitted = provider.submittedOriginalsCount;
    final pending = provider.pendingOriginalsCount;
    final compliancePct = (provider.documentsSubmissionRatio * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.burgundySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'VAULT COMPLIANCE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandGold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: total == 0
                      ? const Color(0xFF94A3B8).withOpacity(0.15)
                      : (pending == 0
                          ? const Color(0xFF10B981).withOpacity(0.2)
                          : const Color(0xFFEF4444).withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: total == 0
                        ? const Color(0xFF94A3B8).withOpacity(0.4)
                        : (pending == 0
                            ? const Color(0xFF10B981).withOpacity(0.5)
                            : const Color(0xFFEF4444).withOpacity(0.5)),
                  ),
                ),
                child: Text(
                  total == 0
                      ? '0 DOCUMENTS'
                      : (pending == 0 ? '$compliancePct% SECURED' : '$pending ACTION REQUIRED'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: total == 0
                        ? const Color(0xFF94A3B8)
                        : (pending == 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricColumn(
                  title: 'Total Tracked',
                  value: '$total',
                  color: AppColors.sandLight,
                  icon: Icons.folder_outlined,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.sandBorder),
              Expanded(
                child: _metricColumn(
                  title: 'In Safe Vault',
                  value: '$submitted',
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle_outline,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.sandBorder),
              Expanded(
                child: _metricColumn(
                  title: 'Pending Submit',
                  value: '$pending',
                  color: const Color(0xFFEF4444),
                  icon: Icons.pending_actions_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricColumn({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDropdownAndAddSection(BuildContext context, EcosystemProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_outlined, color: AppColors.magentaPrimary, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Custody Registry',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Prominent + Icon button to add custom document
              InkWell(
                onTap: () => _showAddDocumentDialog(context, provider),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.magentaPrimary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.magentaPrimary.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        'Add Certificate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select prefilled standard company originals or add custom ones via the + button:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // PREFILLED DROPDOWN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: AppColors.pureWhite,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                value: _selectedDropdownDoc,
                items: DocumentTemplates.standardOptions.map((opt) {
                  final title = opt['title']!;
                  final emoji = opt['emoji'] ?? '📜';
                  return DropdownMenuItem<String>(
                    value: title,
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedDropdownDoc = val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action bar for the selected dropdown document
          _buildDropdownActionCard(provider),
        ],
      ),
    );
  }

  Widget _buildDropdownActionCard(EcosystemProvider provider) {
    if (_selectedDropdownDoc == null) return const SizedBox.shrink();

    // Check if this document already exists in user's custody ledger
    final existingDoc = provider.originalDocuments.firstWhere(
      (d) => d.title.toLowerCase().contains(_selectedDropdownDoc!.split('(').first.trim().toLowerCase()) ||
             _selectedDropdownDoc!.toLowerCase().contains(d.title.split('(').first.trim().toLowerCase()),
      orElse: () => OriginalDocumentItem(
        id: '',
        title: '',
        category: '',
        status: DocumentSubmissionStatus.pending,
        submissionDate: '',
      ),
    );

    final isAlreadyPresent = existingDoc.id.isNotEmpty;

    if (isAlreadyPresent) {
      final isSubmitted = existingDoc.status == DocumentSubmissionStatus.submitted;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSubmitted ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSubmitted ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isSubmitted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSubmitted ? Icons.check_circle_outline : Icons.pending_outlined,
                size: 16,
                color: isSubmitted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSubmitted ? 'Already Deposited in Vault' : 'Tracked as Pending in Vault',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSubmitted ? const Color(0xFF166534) : const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${existingDoc.vaultLockerRef} • Status: ${existingDoc.statusLabel}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: isSubmitted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Clean neutral toggle button
            InkWell(
              onTap: () {
                final newStatus = existingDoc.status == DocumentSubmissionStatus.submitted
                    ? DocumentSubmissionStatus.pending
                    : DocumentSubmissionStatus.submitted;
                provider.updateOriginalDocumentStatus(existingDoc.id, newStatus);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSubmitted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSubmitted ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
                  ),
                ),
                child: Text(
                  isSubmitted ? 'Mark Pending' : 'Mark Submitted',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSubmitted ? const Color(0xFF166534) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.magentaSubtle,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 16,
              color: AppColors.magentaPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not in Vault Ledger yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Ready to deposit into safe vault locker',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.file_upload_outlined, size: 14, color: Colors.white),
            label: Text(
              'Submit to Vault',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.magentaPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              final selectedTemplate = DocumentTemplates.standardOptions.firstWhere(
                (t) => t['title'] == _selectedDropdownDoc,
                orElse: () => {
                  'title': _selectedDropdownDoc!,
                  'category': 'Academic Record',
                  'emoji': '📜',
                },
              );

              provider.addOriginalDocument(
                title: selectedTemplate['title']!,
                category: selectedTemplate['category'] ?? 'Academic Record',
                certificateNumber: 'CERT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                status: DocumentSubmissionStatus.submitted,
                vaultLockerRef: 'Safe Custody',
                isMandatory: selectedTemplate['mandatory'] == 'true',
                iconEmoji: selectedTemplate['emoji'] ?? '📜',
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF10B981),
                  content: Text('${selectedTemplate['title']} added and deposited in safe vault!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerHeaderWithFilter(List<OriginalDocumentItem> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'VAULT LEDGER',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: 0.6,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('All', docs.length),
              const SizedBox(width: 6),
              _filterChip(
                'Submitted',
                docs.where((d) => d.status == DocumentSubmissionStatus.submitted).length,
                activeColor: const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              _filterChip(
                'Pending',
                docs.where((d) => d.status == DocumentSubmissionStatus.pending).length,
                activeColor: const Color(0xFFEF4444),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, int count, {Color? activeColor}) {
    final isSelected = _activeFilter == label;
    final color = activeColor ?? AppColors.magentaPrimary;

    return InkWell(
      onTap: () => setState(() => _activeFilter = label),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? (activeColor != null ? color.withOpacity(0.12) : const Color(0xFFFFF1F4)) : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, EcosystemProvider provider, OriginalDocumentItem doc) {
    final isSubmitted = doc.status == DocumentSubmissionStatus.submitted;
    final isVerifying = doc.status == DocumentSubmissionStatus.verifying;

    final statusColor = doc.statusColor;
    final statusBgColor = isSubmitted
        ? const Color(0xFFF0FDF4)
        : (isVerifying ? const Color(0xFFFFFBEB) : const Color(0xFFFFF1F2));
    final statusBorderColor = isSubmitted
        ? const Color(0xFFBBF7D0)
        : (isVerifying ? const Color(0xFFFDE68A) : const Color(0xFFFECDD3));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSubmitted ? const Color(0xFFE2E8F0) : const Color(0xFFFECDD3),
          width: 1.1,
        ),
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
          // 1. Top Section: Emoji Icon, Title, Mandatory Tag, Category & Certificate No
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji Icon Container
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isSubmitted ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSubmitted ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: Text(doc.iconEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),

                // Document Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              doc.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                height: 1.25,
                              ),
                            ),
                          ),
                          if (doc.isMandatory) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0xFFFFE4E6)),
                              ),
                              child: Text(
                                'MANDATORY',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.magentaPrimary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            doc.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (doc.certificateNumber.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Cert #: ${doc.certificateNumber}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF475569),
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
          ),

          // 2. Metadata Strip (Vault Locker & Submission Date & Time)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFF8FAFC),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                // Safe Vault Custody reference
                if (doc.vaultLockerRef.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        doc.vaultLockerRef,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                // Submission Date & Time
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      doc.submissionDate.isNotEmpty ? 'Date: ${doc.submissionDate}' : 'Date: Pending',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),

          // 3. Action Footer: Status Selector Pill (Left) & Delete Icon (Right)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Interactive Status Dropdown Menu
                Flexible(
                  child: PopupMenuButton<DocumentSubmissionStatus>(
                  color: AppColors.pureWhite,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  initialValue: doc.status,
                  onSelected: (newStatus) {
                    provider.updateOriginalDocumentStatus(doc.id, newStatus);
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: DocumentSubmissionStatus.submitted,
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                          SizedBox(width: 8),
                          Text('Submitted (In Safe Vault)', style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: DocumentSubmissionStatus.pending,
                      child: Row(
                        children: const [
                          Icon(Icons.schedule, color: Color(0xFFEF4444), size: 16),
                          SizedBox(width: 8),
                          Text('Pending Submission', style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: DocumentSubmissionStatus.verifying,
                      child: Row(
                        children: const [
                          Icon(Icons.hourglass_top, color: Color(0xFFF59E0B), size: 16),
                          SizedBox(width: 8),
                          Text('Under Verification', style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusBorderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isSubmitted ? 'Submitted (In Safe Vault)' : doc.statusLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, size: 16, color: statusColor),
                      ],
                    ),
                  ),
                ),
              ),

                // Delete Action Button
                InkWell(
                  onTap: () => _confirmDeleteDocument(context, provider, doc),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.delete_outline, size: 16, color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.folder_off_outlined, color: AppColors.magentaPrimary, size: 36),
            const SizedBox(height: 8),
            Text(
              'No documents found in this filter',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select from dropdown above or click the + button to add.',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillar4Gateway(BuildContext context, EcosystemProvider provider) {
    final tier = provider.holisticTierLevel;
    final tierName = provider.holisticTierName;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.magentaBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: LiquidGlassPill(
                  label: 'GREEN FACTOR',
                  color: AppColors.magentaPrimary,
                  icon: Icons.light_mode,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tier == PillarTierLevel.green ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tier == PillarTierLevel.green ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3)),
                ),
                child: Text(
                  tier == PillarTierLevel.green ? 'CRITERIA MET' : 'PENDING',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: tier == PillarTierLevel.green ? const Color(0xFF059669) : AppColors.ragRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'How Documents Affect Your Status',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Submitting your original documents helps you maintain a Green status ($tierName). Keeping all required documents safely submitted ensures your status stays green.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            icon: const Icon(Icons.radar_outlined, size: 16, color: Colors.white),
            label: Text(
              'Check Your Overall Status',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.magentaPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TierPillarScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- DIALOGS ---

  void _showAddDocumentDialog(BuildContext context, EcosystemProvider provider) {
    final titleCtrl = TextEditingController();
    final certCtrl = TextEditingController();
    String selectedCategory = 'Academic Marksheet';
    DocumentSubmissionStatus selectedStatus = DocumentSubmissionStatus.submitted;
    bool isMandatory = true;
    String selectedEmoji = '📜';

    const categories = [
      'Academic Marksheet',
      'Degree Certificate',
      'Academic Record',
      'Identity Proof',
      'Employment Record',
      'Trade License',
      'Health Record',
      'Other Official Original',
    ];

    const emojis = ['📜', '🎓', '📑', '🪪', '💳', '📄', '💍', '🛂', '🏥', '⭐'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
          ),
          title: Row(
            children: [
              const Icon(Icons.add_circle, color: AppColors.magentaPrimary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Add Original Document',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deposit original certificate record into company vault:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),

                // Title input
                _dialogTextField(
                  controller: titleCtrl,
                  label: 'Document Title / Description',
                  hint: 'e.g. 10th Marksheet, M.Tech Degree, TC...',
                  icon: Icons.title,
                ),
                const SizedBox(height: 10),

                // Certificate Number
                _dialogTextField(
                  controller: certCtrl,
                  label: 'Register / Certificate Number',
                  hint: 'e.g. SSLC-2016-887410',
                  icon: Icons.tag,
                ),
                const SizedBox(height: 10),

                // Category dropdown
                Text(
                  'Category',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: AppColors.pureWhite,
                      value: selectedCategory,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.textDark)))).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Custody Status Selection
                Text(
                  'Submission Status',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _statusChoiceChip(
                        label: 'Submitted',
                        selected: selectedStatus == DocumentSubmissionStatus.submitted,
                        color: const Color(0xFF10B981),
                        onTap: () => setDlgState(() => selectedStatus = DocumentSubmissionStatus.submitted),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _statusChoiceChip(
                        label: 'Pending',
                        selected: selectedStatus == DocumentSubmissionStatus.pending,
                        color: const Color(0xFFEF4444),
                        onTap: () => setDlgState(() => selectedStatus = DocumentSubmissionStatus.pending),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Mandatory Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.magentaPrimary,
                  title: Text(
                    'Mandatory for Company Verification',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textDark),
                  ),
                  value: isMandatory,
                  onChanged: (v) => setDlgState(() => isMandatory = v),
                ),

                // Emoji Picker
                Text(
                  'Icon Emoji',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: emojis.map((e) {
                    final isPicked = selectedEmoji == e;
                    return InkWell(
                      onTap: () => setDlgState(() => selectedEmoji = e),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isPicked ? AppColors.magentaPrimary : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isPicked ? AppColors.magentaPrimary : const Color(0xFFE2E8F0)),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.magentaPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;

                provider.addOriginalDocument(
                  title: title,
                  category: selectedCategory,
                  certificateNumber: certCtrl.text.trim().isEmpty ? 'N/A' : certCtrl.text.trim(),
                  status: selectedStatus,
                  vaultLockerRef: 'Safe Custody',
                  isMandatory: isMandatory,
                  iconEmoji: selectedEmoji,
                );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text('"$title" added to vault ledger!'),
                  ),
                );
              },
              child: Text(
                'Save to Vault',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textDark),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
            prefixIcon: Icon(icon, size: 16, color: AppColors.magentaPrimary),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChoiceChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : const Color(0xFFE2E8F0), width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? color : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  void _confirmDeleteDocument(BuildContext context, EcosystemProvider provider, OriginalDocumentItem doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.pureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        title: Text(
          'Remove Document Record?',
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        content: Text(
          'Are you sure you want to remove "${doc.title}" from the custody tracking registry?',
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              provider.deleteOriginalDocument(doc.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Document record removed')),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CEO EXECUTIVE VIEWS: STAFF ATTENDANCE, VAULT CUSTODY & PERMISSIONS
  // =========================================================================

  Widget _buildCeoStaffAttendanceSection(BuildContext context, EcosystemProvider provider) {
    final isLead = provider.currentEmployee.isTeamLead;
    final corporateStaff = isLead
        ? provider.employees.where((e) => e.hasAttendanceAndGrooming && e.dept.toLowerCase() == provider.currentEmployee.dept.toLowerCase() && e.id != provider.currentEmployee.id).toList()
        : provider.employees.where((e) => e.hasAttendanceAndGrooming && e.roleType != 'ceo').toList();
    final sheet = provider.hrAttendanceSheet;
    final lastSynced = provider.attendanceSheetLastSynced;
    final timeStr = lastSynced != null ? DateFormat('hh:mm a').format(lastSynced) : 'Live';

    Employee? selectedEmployee;
    if (_ceoSelectedStaffId != 'all') {
      try {
        selectedEmployee = corporateStaff.firstWhere((e) => e.id == _ceoSelectedStaffId || e.empNo == _ceoSelectedStaffId);
      } catch (_) {
        selectedEmployee = null; // selected staff no longer exists: show the overview
      }
    }

    final isTuesday = DateTime.now().weekday == DateTime.tuesday;
    final presentTotal = isTuesday ? 0 : corporateStaff.where((e) => !provider.isEmployeeAbsent(e.id)).length;
    final absentTotal = corporateStaff.where((e) => provider.isEmployeeAbsent(e.id)).length;
    final weekOffTotal = isTuesday ? corporateStaff.length : 0;

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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fact_check_rounded, color: Color(0xFF10B981), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isLead ? '${provider.currentEmployee.dept.toUpperCase()} ATTENDANCE' : 'STAFF ATTENDANCE OVERVIEW',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandLight,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${sheet?.monthTitle ?? "November 2026"} • Google Sheet ($timeStr)',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.sandGold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CeoAttendanceScreen()),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 12, color: AppColors.sandGold),
                    label: Text(
                      'Full Console',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.sandGold.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _miniKpiBox(
                      label: 'TOTAL ACTIVE',
                      value: '${corporateStaff.length}',
                      color: AppColors.sandGold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniKpiBox(
                      label: isTuesday ? 'WEEK OFF' : 'ON DUTY',
                      value: isTuesday ? '$weekOffTotal' : '$presentTotal',
                      color: isTuesday ? const Color(0xFF94A3B8) : const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniKpiBox(
                      label: 'ON LEAVE / ABSENT',
                      value: '$absentTotal',
                      color: absentTotal > 0 ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _staffFilterChip(
                label: 'All Staff (${corporateStaff.length})',
                isSelected: _ceoSelectedStaffId == 'all',
                onTap: () => setState(() => _ceoSelectedStaffId = 'all'),
              ),
              ...corporateStaff.map((emp) {
                final isSel = _ceoSelectedStaffId == emp.id || _ceoSelectedStaffId == emp.empNo;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _staffFilterChip(
                    label: emp.name,
                    isSelected: isSel,
                    onTap: () => setState(() => _ceoSelectedStaffId = emp.id),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (selectedEmployee != null) ...[
          _buildCeoEmployeePunchCard(context, provider, selectedEmployee),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: corporateStaff.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final emp = corporateStaff[idx];
              final isAbsent = provider.isEmployeeAbsent(emp.id);
              final isEmpWeekOff = isTuesday && !emp.isExternalSupport && !emp.isCeo;
              final statusText = isAbsent ? 'ABSENT' : (isEmpWeekOff ? 'WEEK OFF' : 'ON DUTY');
              final statusColor = isAbsent ? const Color(0xFFEF4444) : (isEmpWeekOff ? const Color(0xFF94A3B8) : const Color(0xFF10B981));

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.burgundySurface,
                        border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                      ),
                      child: Center(
                        child: Text(
                          emp.initials,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppColors.sandLight,
                          ),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.sandLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            emp.dept,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: AppColors.sandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.calendar_month, size: 18, color: AppColors.sandGold),
                      tooltip: 'View Punch Calendar',
                      onPressed: () => setState(() => _ceoSelectedStaffId = emp.id),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCeoEmployeePunchCard(BuildContext context, EcosystemProvider provider, Employee emp) {
    final monthlyRecords = provider.getMonthlyAttendanceForEmployee(
      emp.id,
      year: _selectedCalendarYear,
      month: _selectedCalendarMonth,
    );

    final totalMonthDays = monthlyRecords.length;
    final presentCount = monthlyRecords.where((r) =>
        !r.isWeekoff &&
        !r.isOvertime &&
        (r.status.contains('Present') ||
            r.status.contains('Late') ||
            r.status.contains('Permission') ||
            r.status.contains('MN Work') ||
            (r.loginTime != '--:-- --' && r.loginTime != '--' && !r.status.contains('Absent') && !r.status.contains('Leave')))).length;
    final tuesdayOtCount = monthlyRecords.where((r) => r.isOvertime).length;
    final weekoffCount = monthlyRecords.where((r) => r.isWeekoff).length;

    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final currentMonthName = monthNames[_selectedCalendarMonth - 1];

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp.name.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                      ),
                    ),
                    Text(
                      '${emp.dept} • $currentMonthName $_selectedCalendarYear',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.sandGold),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _ceoSelectedStaffId = 'all'),
                icon: const Icon(Icons.arrow_back, size: 12, color: AppColors.sandPrimary),
                label: Text(
                  'All Staff',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _kpiPill('$totalMonthDays Days', 'Month Total', AppColors.sandLight),
              const SizedBox(width: 6),
              _kpiPill('$presentCount Days', 'Present', const Color(0xFF10B981)),
              const SizedBox(width: 6),
              _kpiPill('$tuesdayOtCount OT', 'Tuesday OT', const Color(0xFF8B5CF6)),
              const SizedBox(width: 6),
              _kpiPill('$weekoffCount Days', 'Week-offs', const Color(0xFFE11D48)),
            ],
          ),
          const SizedBox(height: 14),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: monthlyRecords.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 0.95,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (ctx, idx) {
              final rec = monthlyRecords[idx];
              final isOt = rec.isOvertime;
              final isOff = rec.isWeekoff;

              final Color bgColor;
              final Color borderColor;
              final Color textColor;
              final String badgeText;

              if (isOff) {
                bgColor = const Color(0xFF334155).withOpacity(0.6);
                borderColor = const Color(0xFF475569);
                textColor = const Color(0xFF94A3B8);
                badgeText = 'OFF';
              } else if (isOt) {
                bgColor = const Color(0xFF8B5CF6).withOpacity(0.2);
                borderColor = const Color(0xFF8B5CF6).withOpacity(0.6);
                textColor = const Color(0xFFA78BFA);
                badgeText = 'OT';
              } else if (rec.status.contains('Yet to update') ||
                  rec.status.contains('Pending') ||
                  rec.status.contains('Upcoming') ||
                  rec.status == 'No Punch') {
                bgColor = const Color(0xFFFEF9C3).withOpacity(0.18);
                borderColor = const Color(0xFFFACC15).withOpacity(0.6);
                textColor = const Color(0xFFFACC15);
                badgeText = 'Yet to update';
              } else if (rec.status.contains('Late')) {
                bgColor = const Color(0xFFFEF9C3).withOpacity(0.18);
                borderColor = const Color(0xFFFACC15);
                textColor = const Color(0xFFFACC15);
                final lMatch = RegExp(r'L-\d+').firstMatch(rec.status);
                badgeText = lMatch != null ? lMatch.group(0)! : 'L';
              } else if (rec.status.contains('Permission')) {
                bgColor = const Color(0xFFDCFCE7).withOpacity(0.18);
                borderColor = const Color(0xFF4ADE80);
                textColor = const Color(0xFF4ADE80);
                badgeText = 'PM';
              } else if (rec.status.contains('Loss of Pay') || rec.status.contains('LOP')) {
                bgColor = const Color(0xFFDC2626).withOpacity(0.18);
                borderColor = const Color(0xFFDC2626);
                textColor = const Color(0xFFF87171);
                badgeText = 'LOP';
              } else if (rec.status.contains('Casual Leave') || rec.status.contains('CL') || rec.status.contains('Leave')) {
                bgColor = const Color(0xFFEF4444).withOpacity(0.18);
                borderColor = const Color(0xFFEF4444);
                textColor = const Color(0xFFF87171);
                badgeText = 'CL';
              } else if (rec.status.contains('Half Day') || rec.status.contains('1/2 D')) {
                bgColor = const Color(0xFFF97316).withOpacity(0.18);
                borderColor = const Color(0xFFF97316);
                textColor = const Color(0xFFFB923C);
                badgeText = '½D';
              } else if (rec.status.contains('MN Work') || rec.status.contains('MNW')) {
                bgColor = const Color(0xFF2563EB).withOpacity(0.18);
                borderColor = const Color(0xFF3B82F6);
                textColor = const Color(0xFF60A5FA);
                badgeText = 'MNW';
              } else if (rec.status.contains('Present') ||
                  rec.status.contains('On Duty') ||
                  rec.status.contains('Shift Over') ||
                  (rec.loginTime != '--:-- --' && rec.loginTime != '--' && !rec.status.contains('Absent') && !rec.status.contains('Leave'))) {
                bgColor = const Color(0xFF10B981).withOpacity(0.18);
                borderColor = const Color(0xFF10B981).withOpacity(0.5);
                textColor = const Color(0xFF34D399);
                badgeText = 'P';
              } else if (rec.status.contains('Absent')) {
                bgColor = const Color(0xFFEF4444).withOpacity(0.12);
                borderColor = const Color(0xFFEF4444).withOpacity(0.35);
                textColor = const Color(0xFFF87171);
                badgeText = 'A';
              } else {
                bgColor = AppColors.burgundyCard;
                borderColor = AppColors.sandBorder.withOpacity(0.35);
                textColor = AppColors.textMuted;
                badgeText = '--';
              }

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${rec.date.day} ${DateFormat('E').format(rec.date)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    badgeText == 'Yet to update'
                        ? Text(
                            'Yet to\nupdate',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 7.8,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.05,
                            ),
                          )
                        : Text(
                            badgeText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCeoStaffVaultCustodySection(BuildContext context, EcosystemProvider provider) {
    final isLead = provider.currentEmployee.isTeamLead;
    final corporateStaff = isLead
        ? provider.employees.where((e) => e.hasAttendanceAndGrooming && e.dept.toLowerCase() == provider.currentEmployee.dept.toLowerCase() && e.id != provider.currentEmployee.id).toList()
        : provider.employees.where((e) => e.hasAttendanceAndGrooming && e.roleType != 'ceo').toList();

    final List<_StaffDocEntry> allStaffDocs = [];
    for (final emp in corporateStaff) {
      final empDocs = provider.getEmployeeDocuments(emp.id);
      for (final doc in empDocs) {
        allStaffDocs.add(_StaffDocEntry(employee: emp, doc: doc));
      }
    }

    final filtered = allStaffDocs.where((entry) {
      if (_ceoSelectedStaffId != 'all' && entry.employee.id != _ceoSelectedStaffId && entry.employee.empNo != _ceoSelectedStaffId) {
        return false;
      }
      if (_ceoStaffDocFilter == 'Submitted') {
        return entry.doc.status == DocumentSubmissionStatus.submitted;
      } else if (_ceoStaffDocFilter == 'Pending') {
        return entry.doc.status == DocumentSubmissionStatus.pending;
      }
      return true;
    }).toList();

    final submittedCount = allStaffDocs.where((e) => e.doc.status == DocumentSubmissionStatus.submitted).length;
    final totalCount = allStaffDocs.length;

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
                    child: const Icon(Icons.shield_outlined, color: AppColors.sandGold, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLead ? '${provider.currentEmployee.dept.toUpperCase()} VAULT CUSTODY' : 'STAFF VAULT CUSTODY & VERIFICATION',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Official academic marksheets, KYC, and ID proofs locked in safe custody',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _miniKpiBox(
                      label: 'TOTAL DEPOSITED',
                      value: '$submittedCount / $totalCount',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniKpiBox(
                      label: 'SAFE CUSTODY',
                      value: totalCount == 0 ? '0 Verified' : '$submittedCount Verified',
                      color: AppColors.sandGold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _miniKpiBox(
                      label: 'VERIFIED RATIO',
                      value: totalCount > 0 ? '${((submittedCount / totalCount) * 100).toInt()}%' : '0%',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _staffFilterChip(
                label: 'All Staff (${corporateStaff.length})',
                isSelected: _ceoSelectedStaffId == 'all',
                onTap: () => setState(() => _ceoSelectedStaffId = 'all'),
              ),
              ...corporateStaff.map((emp) {
                final isSel = _ceoSelectedStaffId == emp.id || _ceoSelectedStaffId == emp.empNo;
                return Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _staffFilterChip(
                    label: emp.name,
                    isSelected: isSel,
                    onTap: () => setState(() => _ceoSelectedStaffId = emp.id),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _statusFilterChip('All ($totalCount)', 'All'),
              const SizedBox(width: 8),
              _statusFilterChip('Submitted ($submittedCount)', 'Submitted'),
              const SizedBox(width: 8),
              _statusFilterChip('Pending (${totalCount - submittedCount})', 'Pending'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.folder_off_outlined, color: AppColors.magentaPrimary, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'No documents found in safe vault',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Staff documents will appear here once submitted and verified.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) {
              final entry = filtered[idx];
              return _buildCeoDocumentCard(ctx, provider, entry);
            },
          ),
      ],
    );
  }

  Widget _buildCeoDocumentCard(BuildContext context, EcosystemProvider provider, _StaffDocEntry entry) {
    final doc = entry.doc;
    final emp = entry.employee;
    final isSubmitted = doc.status == DocumentSubmissionStatus.submitted;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin, size: 14, color: AppColors.magentaPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          emp.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  emp.dept,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Center(
                    child: Text(
                      doc.iconEmoji.isNotEmpty ? doc.iconEmoji : '📜',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              doc.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (doc.isMandatory) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'MANDATORY',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            doc.category,
                            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Cert #: ${doc.certificateNumber}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_outlined, size: 11, color: Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Safe Custody',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.textDark, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time, size: 11, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Date: ${doc.submissionDate}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSubmitted ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSubmitted ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: isSubmitted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    doc.statusLabel,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSubmitted ? const Color(0xFF059669) : const Color(0xFFD97706),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified, size: 11, color: Color(0xFF10B981)),
                                const SizedBox(width: 3),
                                Text(
                                  'HR Verified',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF059669),
                                  ),
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
        ],
      ),
    );
  }


  Widget _buildOtmExemptSection(String subsystemName, [dynamic employee]) {
    final isExt = employee != null && (employee.isExternalSupport == true || employee.dept == 'External Support Staff [Online]');
    final isLead = employee != null && (employee.isTeamLead == true);
    final header = isExt
        ? 'EXTERNAL SUPPORT STAFF [ONLINE]'
        : (isLead
            ? '${(employee.role as String).toUpperCase()} (${(employee.dept as String).toUpperCase()})'
            : 'ONLINE TEAM MANAGER (OTM)');
    final desc = isExt
        ? 'Exempt from retail showroom $subsystemName. Off-site contractor managed via Konar deliverables & tasks.'
        : (isLead
            ? 'Exempt from personal showroom $subsystemName. Manages ${employee.dept} team operations.'
            : 'Exempt from $subsystemName.');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withOpacity(0.12),
            ),
            child: const Icon(Icons.verified, color: Color(0xFF10B981), size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            header,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.sandLight,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.sandPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isExt) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TlTeamAttendanceScreen()),
              ),
              icon: const Icon(Icons.people_alt, size: 15),
              label: const Text('View Online Team Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.magentaPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniKpiBox({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.burgundySurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.sandLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _staffFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.magentaPrimary : AppColors.burgundySurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.sandLight,
          ),
        ),
      ),
    );
  }

  Widget _statusFilterChip(String label, String value) {
    final isSel = _ceoStaffDocFilter == value;
    return InkWell(
      onTap: () => setState(() => _ceoStaffDocFilter = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? AppColors.sandGold : AppColors.burgundySurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSel ? AppColors.sandGold : AppColors.sandBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
            color: isSel ? AppColors.burgundyBg : AppColors.sandPrimary,
          ),
        ),
      ),
    );
  }

  Widget _kpiPill(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.burgundySurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 8, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamGroomingInspectionSection(BuildContext context, EcosystemProvider provider) {
    final teamStaff = provider.employees.where((e) => e.hasAttendanceAndGrooming && e.dept.toLowerCase().contains('online') && e.id != provider.currentEmployee.id).toList();

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
                    child: const Icon(Icons.face_retouching_natural, color: AppColors.sandGold, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ONLINE TEAM GROOMING INSPECTION',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Daily showroom attire & grooming compliance across online team staff',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.sandGold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...teamStaff.map((emp) {
          final pts = provider.getEmployeeGroomingDailyPoints(emp.id);
          final isCompliant = pts >= 40;
          final audits = provider.getEmployeeGroomingAudits(emp.id);
          final latestAudit = audits.isNotEmpty ? audits.first : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
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
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.sandGold.withOpacity(0.2),
                            child: Text(
                              emp.initials,
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  emp.name,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${emp.id} • ${emp.straightCutDesignation}',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isCompliant ? const Color(0xFF10B981).withOpacity(0.15) : AppColors.sandGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isCompliant ? const Color(0xFF10B981).withOpacity(0.3) : AppColors.sandGold.withOpacity(0.3)),
                      ),
                      child: Text(
                        '$pts / 50 Pts',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCompliant ? const Color(0xFF10B981) : AppColors.sandGold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (latestAudit != null && latestAudit.followedItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: latestAudit.followedItems.take(4).map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.burgundyBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.sandBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, size: 10, color: Color(0xFF10B981)),
                            const SizedBox(width: 3),
                            Text(
                              item,
                              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.sandLight),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _StaffDocEntry {
  final Employee employee;
  final OriginalDocumentItem doc;
  _StaffDocEntry({required this.employee, required this.doc});
}
