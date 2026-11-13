import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../models/profile_document_models.dart';
import '../../providers/ecosystem_provider.dart';
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
          'STAFF PROFILE',
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
              child: LiquidGlassPill(
                label: 'OCCASIONAL',
                color: AppColors.sandGold,
                icon: Icons.badge_outlined,
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

            // 1b. Account Security & Password Management
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
              _buildMonthlyAttendanceSection(context, provider),
            ] else if (_selectedRingIndex == 1) ...[
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
            ] else if (_selectedRingIndex == 2) ...[
              _buildGroomingSection(context, provider),
            ] else if (_selectedRingIndex == 3) ...[
              _buildSalesSection(context, provider),
            ] else if (_selectedRingIndex == 4) ...[
              _buildPermissionSection(context, provider),
            ] else ...[
              _buildEthicsConductSection(context, provider),
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
        : 'password123';

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

                final success = await provider.changeEmployeePassword(
                  empId: employee.id,
                  oldPassword: currentPass,
                  newPassword: newPass,
                );

                if (ctx.mounted) Navigator.pop(ctx);

                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Password updated successfully!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Incorrect current password. Please try again.'),
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_clock_outlined, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          'Locker #B-14',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.textMuted,
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
      ),
    );
  }

  // --- 6-RING SUBSYSTEM MATRIX ---

  Widget _buildSixRingsMatrix(BuildContext context, EcosystemProvider provider) {
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
                        'PROFILE RINGS',
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
                  'PILLAR 3 SUITE',
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

          // 2 Rows of 3 Rings
          Row(
            children: [
              Expanded(
                child: _buildRingCard(
                  index: 0,
                  title: 'Attendance',
                  displayValue: '${provider.monthlyAttendancePercentage.toStringAsFixed(0)}%',
                  subText: '${provider.workingDaysAttended}/${provider.totalCalendarDaysInCurrentMonth} Days',
                  progress: (provider.monthlyAttendancePercentage / 100.0).clamp(0.0, 1.0),
                  ringColor: provider.workingDaysAttended == 0
                      ? const Color(0xFF94A3B8)
                      : (provider.monthlyAttendancePercentage >= 90.0 ? AppColors.ragGreen : const Color(0xFFF59E0B)),
                  icon: Icons.fact_check_outlined,
                  statusText: provider.workingDaysAttended == 0
                      ? 'No Punches'
                      : '${provider.monthlyAttendancePercentage.toStringAsFixed(1)}% Ratio',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRingCard(
                  index: 1,
                  title: 'Documents',
                  displayValue: '${(provider.documentsSubmissionRatio * 100).toStringAsFixed(0)}%',
                  subText: '${provider.submittedOriginalsCount}/${provider.totalOriginalsCount} Vault',
                  progress: provider.documentsSubmissionRatio,
                  ringColor: provider.totalOriginalsCount == 0
                      ? const Color(0xFF94A3B8)
                      : (provider.pendingOriginalsCount == 0 ? AppColors.ragGreen : const Color(0xFFEF4444)),
                  icon: Icons.lock_clock_outlined,
                  statusText: provider.totalOriginalsCount == 0
                      ? 'Need to be added'
                      : (provider.pendingOriginalsCount == 0 ? 'Custody Safe' : '${provider.pendingOriginalsCount} Pending'),
                ),
              ),
              const SizedBox(width: 8),
              Builder(
                builder: (context) {
                  final hasAudit = provider.getEmployeeGroomingAudits(provider.activeEmpId).isNotEmpty;
                  final groomingPercent = provider.getEmployeeGroomingPercentage(provider.activeEmpId);
                  final groomingPoints = provider.getEmployeeGroomingDailyPoints(provider.activeEmpId);

                  return Expanded(
                    child: _buildRingCard(
                      index: 2,
                      title: 'Grooming',
                      displayValue: hasAudit ? '${groomingPercent.toStringAsFixed(0)}%' : '0%',
                      subText: hasAudit ? '$groomingPoints/50 Pts' : 'Pending Audit',
                      progress: hasAudit ? (groomingPercent / 100.0).clamp(0.0, 1.0) : 0.0,
                      ringColor: !hasAudit
                          ? const Color(0xFF94A3B8)
                          : (groomingPercent >= 80
                              ? AppColors.magentaPrimary
                              : (groomingPercent >= 60
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFEF4444))),
                      icon: Icons.face_retouching_natural,
                      statusText: hasAudit ? '$groomingPoints/50 Pts' : 'Pending Audit',
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRingCard(
                  index: 3,
                  title: 'Sales Target',
                  displayValue: '${provider.salesAchievementPercentage.toStringAsFixed(0)}%',
                  subText: '₹${(provider.totalSalesAchieved / 100000).toStringAsFixed(1)}L / ₹25L',
                  progress: (provider.salesAchievementPercentage / 100.0).clamp(0.0, 1.0),
                  ringColor: provider.totalSalesAchieved <= 0
                      ? const Color(0xFF94A3B8)
                      : (provider.salesAchievementPercentage >= 85.0 ? AppColors.magentaPrimary : const Color(0xFFF59E0B)),
                  icon: Icons.monetization_on_outlined,
                  statusText: provider.totalSalesAchieved <= 0
                      ? '₹0.0 Achieved'
                      : '${provider.salesAchievementPercentage.toStringAsFixed(0)}% Target',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRingCard(
                  index: 4,
                  title: 'Permissions',
                  displayValue: '${provider.permissionHoursRemaining.toStringAsFixed(1)}h',
                  subText: '${provider.totalPermissionHoursUsed.toStringAsFixed(1)}h Used | 1 CL',
                  progress: (provider.permissionHoursRemaining / provider.monthlyPermissionHoursLimit).clamp(0.0, 1.0),
                  ringColor: provider.isPermissionExcessHalfDay ? const Color(0xFFEF4444) : AppColors.magentaPrimary,
                  icon: Icons.timer_outlined,
                  statusText: provider.isPermissionExcessHalfDay
                      ? 'Half Day'
                      : '${provider.permissionHoursRemaining.toStringAsFixed(1)}h Left',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRingCard(
                  index: 5,
                  title: 'Ethics & Assay',
                  displayValue: provider.conductScore > 0 ? '${provider.conductScore}' : '0.0',
                  subText: provider.conductScore > 0 ? 'Zero Hallmark Lag' : 'No Audits',
                  progress: provider.conductScore > 0 ? (provider.conductScore / 5.0).clamp(0.0, 1.0) : 0.0,
                  ringColor: provider.conductScore > 0 ? AppColors.ragGreen : const Color(0xFF94A3B8),
                  icon: Icons.verified_user_outlined,
                  statusText: provider.conductScore > 0 ? '${provider.conductScore} / 5.0' : 'Need to be added',
                ),
              ),
            ],
          ),
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
    final tabs = [
      {'label': '1. Calendar Attendance', 'icon': Icons.fact_check_outlined},
      {'label': '2. Vault Custody', 'icon': Icons.lock_clock_outlined},
      {'label': '3. Grooming & Attire', 'icon': Icons.face_retouching_natural},
      {'label': '4. Showroom Sales', 'icon': Icons.monetization_on_outlined},
      {'label': '5. Permission & Leave', 'icon': Icons.timer_outlined},
      {'label': '6. Ethics & Hallmark', 'icon': Icons.verified_user_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _selectedRingIndex == idx;
          final tab = tabs[idx];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedRingIndex = idx),
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
        }),
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
    final presentCount = monthlyRecords.where((r) => !r.isWeekoff && !r.isOvertime && r.loginTime != '--:-- --').length;
    final tuesdayOtCount = monthlyRecords.where((r) => r.isOvertime).length;
    final weekoffCount = monthlyRecords.where((r) => r.isWeekoff).length;
    final liveAttendancePercentage = totalMonthDays > 0 ? (((presentCount + tuesdayOtCount) / totalMonthDays) * 100).round() : 0;

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
                  } else if (r.loginTime != '--:-- --') {
                    boxColor = AppColors.ragGreen.withOpacity(0.18);
                    borderColor = AppColors.ragGreen.withOpacity(0.6);
                    textColor = AppColors.ragGreen;
                    statusTag = 'P';
                    icon = Icons.check;
                  } else if (r.status == 'Absent') {
                    boxColor = const Color(0xFFEF4444).withOpacity(0.18);
                    borderColor = const Color(0xFFEF4444).withOpacity(0.5);
                    textColor = const Color(0xFFEF4444);
                    statusTag = 'A';
                    icon = Icons.close;
                  } else {
                    boxColor = AppColors.burgundyCard;
                    borderColor = AppColors.sandBorder.withOpacity(0.3);
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
                  _legendPill(label: 'Tuesday Overtime (OT)', color: const Color(0xFF8B5CF6)),
                  _legendPill(label: 'Tuesday Week-off (OFF)', color: const Color(0xFF94A3B8)),
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

  // --- SUBSYSTEM 3: ACTUAL SALES PERFORMANCE ---

  Widget _buildSalesSection(BuildContext context, EcosystemProvider provider) {
    final achievedLakhs = (provider.totalSalesAchieved / 100000).toStringAsFixed(2);
    final targetLakhs = (provider.monthlySalesTarget / 100000).toStringAsFixed(0);
    final remainingLakhs = ((provider.monthlySalesTarget - provider.totalSalesAchieved).clamp(0, double.infinity) / 100000).toStringAsFixed(2);
    final pct = (provider.salesAchievementPercentage * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sales Target & Achieved Card
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SALES TARGET',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sales Performance',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  LiquidGlassButton(
                    label: 'Log Sale',
                    icon: Icons.add,
                    height: 32,
                    onPressed: () => _openRecordSaleDialog(context, provider),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: provider.salesAchievementPercentage.clamp(0.0, 1.0),
                  minHeight: 9,
                  backgroundColor: AppColors.burgundySurface,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sandGold),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _metricColumn(
                      title: 'Target',
                      value: '₹${targetLakhs}L',
                      color: AppColors.sandLight,
                      icon: Icons.flag_outlined,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Achieved',
                      value: '₹${achievedLakhs}L',
                      color: AppColors.sandGold,
                      icon: Icons.monetization_on_outlined,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Target %',
                      value: '$pct%',
                      color: AppColors.ragGreen,
                      icon: Icons.trending_up,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Remaining',
                      value: '₹${remainingLakhs}L',
                      color: AppColors.sandPrimary,
                      icon: Icons.hourglass_bottom,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Sales Invoices Ledger
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
              Text(
                'SHOWROOM TRANSACTIONS & BILLS LOG',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandLight,
                ),
              ),
              const SizedBox(height: 10),

              if (provider.salesRecords.isEmpty)
                Text(
                  'No sales transactions logged yet.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.salesRecords.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final sale = provider.salesRecords[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.burgundyCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.burgundySurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                            ),
                            child: const Center(
                              child: Icon(Icons.diamond_outlined, size: 18, color: AppColors.sandGold),
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
                                    Text(
                                      sale.itemCategory,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.sandLight,
                                      ),
                                    ),
                                    Text(
                                      '₹${(sale.amountInInr / 100000).toStringAsFixed(2)} Lakhs',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.sandGold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Bill #${sale.billNumber} • ${sale.customerName}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${sale.weightGrams}g Gold/Diamond',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: AppColors.sandPrimary,
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
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _openRecordSaleDialog(BuildContext context, EcosystemProvider provider) {
    final billCtrl = TextEditingController(text: 'MN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final custCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String category = '22K Antique Temple Choker';

    final categories = [
      '22K Antique Temple Choker',
      'VVS Solitaire Bridal Ring',
      '22K Temple Kasu Mala',
      'Polki Kundan Bridal Set',
      'Rose Gold Diamond Bangle',
      'Traditional Navaratna Necklace',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.sandGold),
          ),
          title: Text(
            'Record Showroom Customer Sale',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.sandLight),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogTextField(controller: billCtrl, label: 'Invoice / Bill Number', hint: 'e.g. MN-2026-9041', icon: Icons.receipt),
                const SizedBox(height: 10),
                _dialogTextField(controller: custCtrl, label: 'Customer Name', hint: 'e.g. Smt. Rajeshwari K.', icon: Icons.person_outline),
                const SizedBox(height: 10),
                Text('Jewellery Category', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: AppColors.burgundySurface,
                      value: category,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.sandLight)))).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => category = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _dialogTextField(controller: weightCtrl, label: 'Gross Weight (Grams)', hint: 'e.g. 45.5', icon: Icons.scale),
                const SizedBox(height: 10),
                _dialogTextField(controller: amtCtrl, label: 'Total Invoice Amount (INR)', hint: 'e.g. 350000', icon: Icons.currency_rupee),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sandGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final amt = double.tryParse(amtCtrl.text.trim());
                final weight = double.tryParse(weightCtrl.text.trim()) ?? 0.0;
                final cust = custCtrl.text.trim().isEmpty ? 'Showroom Customer' : custCtrl.text.trim();
                final bill = billCtrl.text.trim();

                if (bill.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an invoice or bill number')),
                  );
                  return;
                }

                if (amt == null || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid invoice amount greater than ₹0')),
                  );
                  return;
                }

                provider.addSalesRecord(
                  empId: provider.currentEmployee.id,
                  billNumber: bill,
                  category: category,
                  amount: amt,
                  weightGrams: weight,
                  customerName: cust,
                );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text('Sale of ₹${(amt / 100000).toStringAsFixed(2)} Lakhs recorded!'),
                  ),
                );
              },
              child: Text('Log Sale', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppColors.burgundyBg)),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUBSYSTEM 4: PERMISSION & LATE ARRIVALS ---

  Widget _buildPermissionSection(BuildContext context, EcosystemProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Permission Policy & Account Ledger Card
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERMISSION & LEAVES',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Monthly Quota',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  LiquidGlassButton(
                    label: 'Request',
                    icon: Icons.timer,
                    height: 32,
                    onPressed: () => _openRequestPermissionDialog(context, provider),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Account Status Bar
              Row(
                children: [
                  Expanded(
                    child: _metricColumn(
                      title: 'Quota',
                      value: '2.0h',
                      color: AppColors.sandLight,
                      icon: Icons.hourglass_top,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Used',
                      value: '${provider.totalPermissionHoursUsed.toStringAsFixed(1)}h',
                      color: AppColors.sandGold,
                      icon: Icons.history,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Balance',
                      value: '${provider.permissionHoursRemaining.toStringAsFixed(1)}h',
                      color: provider.isPermissionExcessHalfDay ? const Color(0xFFEF4444) : AppColors.ragGreen,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Casual Leave',
                      value: '${provider.casualLeavesUsed}/1',
                      color: AppColors.sandPrimary,
                      icon: Icons.event_busy_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Half Day & Salary Deduction Status Indicators
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.burgundySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: provider.isPermissionExcessHalfDay
                        ? const Color(0xFFEF4444)
                        : AppColors.ragGreen.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      provider.isPermissionExcessHalfDay ? Icons.warning : Icons.shield_outlined,
                      size: 18,
                      color: provider.isPermissionExcessHalfDay ? const Color(0xFFEF4444) : AppColors.ragGreen,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.isPermissionExcessHalfDay
                                ? 'Half-Day Leave Triggered'
                                : 'Permission Safe Standing',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: provider.isPermissionExcessHalfDay ? const Color(0xFFEF4444) : AppColors.sandLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Early arrival automatically credits back to balance.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Permission Request History List
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
              Text(
                'LOGGED PERMISSION & ARRIVAL REQUESTS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandLight,
                ),
              ),
              const SizedBox(height: 10),

              if (provider.permissionRecords.isEmpty)
                Text(
                  'No permission requests recorded this month.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.permissionRecords.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final rec = provider.permissionRecords[idx];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.burgundyCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.alarm_on, size: 14, color: AppColors.sandGold),
                                  const SizedBox(width: 6),
                                  Text(
                                    rec.reason,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.sandLight,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.ragGreen.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Credited: +${rec.creditedBackHours.toStringAsFixed(1)}h',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ragGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Requested: ${rec.requestedHours.toStringAsFixed(1)}h  •  Actual Used: ${rec.actualHoursUsed.toStringAsFixed(1)}h',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.sandLight),
                              ),
                              Text(
                                rec.dateFormatted,
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
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

  void _openRequestPermissionDialog(BuildContext context, EcosystemProvider provider) {
    final reasonCtrl = TextEditingController();
    double requestedHours = 2.0;
    double actualArrivedHours = 1.0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final credited = (requestedHours - actualArrivedHours).clamp(0.0, requestedHours);
          final newTotalUsed = provider.totalPermissionHoursUsed + actualArrivedHours;
          final willExceed = newTotalUsed > provider.monthlyPermissionHoursLimit;

          return AlertDialog(
            backgroundColor: AppColors.burgundyCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.sandGold),
            ),
            title: Text(
              'Request Permission / Late Arrival',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogTextField(controller: reasonCtrl, label: 'Reason for Permission', hint: 'e.g. Bank token, medical', icon: Icons.edit_note),
                  const SizedBox(height: 12),

                  Text('Requested Permission Hours:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [0.5, 1.0, 1.5, 2.0].map((h) {
                      final isSel = requestedHours == h;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () => setDlgState(() => requestedHours = h),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.magentaPrimary : AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSel ? AppColors.magentaPrimary : AppColors.sandBorder),
                              ),
                              child: Text(
                                '${h}h',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : AppColors.textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  Text('Actual Arrival / Time Spent:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [0.5, 1.0, 1.5, 2.0].map((h) {
                      final isSel = actualArrivedHours == h;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            onTap: () => setDlgState(() => actualArrivedHours = h),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.magentaPrimary : AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSel ? AppColors.magentaPrimary : AppColors.sandBorder),
                              ),
                              child: Text(
                                '${h}h',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : AppColors.textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Real-time calculation preview box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.burgundySurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: willExceed ? const Color(0xFFEF4444) : AppColors.ragGreen.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Auto Credit-Back:', style: TextStyle(fontSize: 11, color: AppColors.sandLight)),
                            Text('+${credited.toStringAsFixed(1)}h kept in account', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ragGreen)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('New Monthly Used:', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            Text('${newTotalUsed.toStringAsFixed(1)}h / 2.0h', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: willExceed ? const Color(0xFFEF4444) : AppColors.sandLight)),
                          ],
                        ),
                        if (willExceed) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Warning: Exceeds 2.0h allowance. Will trigger Half-Day Leave.',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sandGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final reason = reasonCtrl.text.trim().isEmpty ? 'General Permission' : reasonCtrl.text.trim();
                  provider.requestPermission(
                    empId: provider.currentEmployee.id,
                    reason: reason,
                    requestedHours: requestedHours,
                    actualHoursUsed: actualArrivedHours,
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF10B981),
                      content: Text('Permission recorded: ${credited.toStringAsFixed(1)}h credited back to account!'),
                    ),
                  );
                },
                child: Text('Submit & Sync', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppColors.burgundyBg)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- SUBSYSTEM 5: ETHICS & CONDUCT ---

  Widget _buildEthicsConductSection(BuildContext context, EcosystemProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ETHICS & ASSAY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Integrity Standards',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ragGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.ragGreen),
                    ),
                    child: Text(
                      '${provider.conductScore} / 5.0',
                      maxLines: 1,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ragGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _metricColumn(
                      title: 'Variance',
                      value: '0.00%',
                      color: AppColors.ragGreen,
                      icon: Icons.verified,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Rating',
                      value: '4.9 ★',
                      color: AppColors.sandGold,
                      icon: Icons.star,
                    ),
                  ),
                  Container(width: 1, height: 30, color: AppColors.sandBorder),
                  Expanded(
                    child: _metricColumn(
                      title: 'Safe Key',
                      value: 'Passed',
                      color: AppColors.sandLight,
                      icon: Icons.vpn_key_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                  color: pending == 0
                      ? const Color(0xFF10B981).withOpacity(0.2)
                      : const Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: pending == 0
                        ? const Color(0xFF10B981).withOpacity(0.5)
                        : const Color(0xFFEF4444).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  pending == 0 ? '$compliancePct% SECURED' : '$pending ACTION REQUIRED',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: pending == 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
                vaultLockerRef: 'Safe Vault Locker #B-14',
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
                // Safe Vault Locker reference
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      doc.vaultLockerRef.isNotEmpty ? doc.vaultLockerRef : 'Safe Vault Locker #B-14',
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
                PopupMenuButton<DocumentSubmissionStatus>(
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
                        Text(
                          isSubmitted ? 'Submitted (In Safe Vault)' : doc.statusLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, size: 16, color: statusColor),
                      ],
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
    final lockerCtrl = TextEditingController();
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

                // Safe Vault Locker Reference
                _dialogTextField(
                  controller: lockerCtrl,
                  label: 'Safe Vault Locker Box',
                  hint: 'Company Safe Vault Locker #B-14',
                  icon: Icons.lock_outline,
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
                  vaultLockerRef: lockerCtrl.text.trim().isEmpty ? 'Safe Vault Locker #B-14' : lockerCtrl.text.trim(),
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
}
