import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/prescription_viewer_dialog.dart';
import '../../models/employee_model.dart';
import '../../models/profile_document_models.dart';
import '../../providers/ecosystem_provider.dart';

class HrEmployeeInspectionScreen extends StatefulWidget {
  final Employee employee;

  const HrEmployeeInspectionScreen({super.key, required this.employee});

  @override
  State<HrEmployeeInspectionScreen> createState() => _HrEmployeeInspectionScreenState();
}

class _HrEmployeeInspectionScreenState extends State<HrEmployeeInspectionScreen> {
  bool _isPasswordRevealed = false;
  final Map<String, bool> _groomingChecks = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EcosystemProvider>().loadEmployeeDocuments(widget.employee.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final emp = eco.employees.firstWhere(
      (e) => e.id == widget.employee.id,
      orElse: () => widget.employee,
    );
    final role = eco.activeRole.toLowerCase();
    final isCeo = role == 'ceo' || eco.activeEmpId == 'MN-CEO01';
    final isHr = role == 'hr' || eco.activeEmpId == 'MN-HR1001';
    final isTeamLead = role == 'dept_head' || role == 'team_lead' || eco.activeEmpId == 'MN-TL1002';
    final isAbsent = eco.isEmployeeAbsent(emp.id);
    final docs = eco.getEmployeeDocuments(emp.id);
    final submittedDocsCount = docs.where((d) => d.status == DocumentSubmissionStatus.submitted).length;
    final totalDocsCount = docs.length;
    final submissionPercent = totalDocsCount == 0 ? 0 : ((submittedDocsCount / totalDocsCount) * 100).toInt();

    final empPermissions = eco.permissionRecords.where((p) => p.empId == emp.id).toList();
    final empMedicalLeaves = eco.medicalLeaveRecords.where((m) => m.empId == emp.id).toList();
    final empPassword = emp.password;
    final isTargetCeo = emp.roleType.toLowerCase() == 'ceo' || emp.id.toUpperCase() == 'MN-CEO01';

    // Real Attendance Calculations from Past 1-Week Ledger (Full Calendar Days)
    final weekRecords = eco.getPast7DaysAttendanceForEmployee(emp.id);
    int daysPresent = 0;
    int totalMinutes = 0;
    int tuesdayOvertimeCount = 0;
    for (final r in weekRecords) {
      if (r.isOvertime || (r.date.weekday == DateTime.tuesday && r.loginTime != '--:-- --')) {
        tuesdayOvertimeCount++;
      }
      if (r.loginTime != '--:-- --') {
        daysPresent++;
        final match = RegExp(r'(\d+)h\s*(\d+)m').firstMatch(r.netHours);
        if (match != null) {
          final h = int.tryParse(match.group(1) ?? '0') ?? 0;
          final m = int.tryParse(match.group(2) ?? '0') ?? 0;
          totalMinutes += (h * 60 + m);
        }
      }
    }
    final standardDutyDays = weekRecords.where((r) => r.date.weekday != DateTime.tuesday).length;
    final realTotalHoursFormatted = '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';
    final realAttendancePercent = standardDutyDays > 0 ? (((daysPresent) / standardDutyDays) * 100).round().clamp(0, 100) : 100;

    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee Dossier',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              '${emp.name} • #${emp.id}',
              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Executive Hero Card
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isAbsent
                          ? const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)])
                          : AppColors.magentaGradient,
                      boxShadow: [
                        BoxShadow(
                          color: (isAbsent ? const Color(0xFFEF4444) : AppColors.magentaPrimary).withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        emp.initials,
                        style: GoogleFonts.plusJakartaSans(
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
                                emp.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAbsent ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isAbsent ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0),
                                ),
                              ),
                              child: Text(
                                isAbsent ? 'ABSENT TODAY' : 'ON DUTY',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: isAbsent ? const Color(0xFFE11D48) : const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          emp.straightCutDesignation,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.magentaPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${emp.department.isNotEmpty ? emp.department : "Operations"} • #${emp.id}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 1. Personal & Contact Details Card
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 18, color: AppColors.magentaPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Personal & KYC Information',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _openEditProfileModal(context, eco, emp),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.magentaSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.magentaPrimary.withOpacity(0.3), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_outlined, size: 13, color: AppColors.magentaPrimary),
                              const SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
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
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  _buildDetailRow(Icons.phone_outlined, 'Mobile Number', emp.phone.isNotEmpty ? emp.phone : 'Not provided'),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.email_outlined, 'Official Email', emp.email),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.cake_outlined, 'Date of Birth', emp.dob.isNotEmpty ? emp.dob : 'Not provided'),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.wc_outlined, 'Gender', emp.gender.isNotEmpty ? emp.gender : 'Male'),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.favorite_outline, 'Relationship Status', emp.relationshipStatus.isNotEmpty ? emp.relationshipStatus : 'Single'),
                  if (emp.relationshipStatus.toLowerCase() == 'married' && emp.anniversaryDate.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.celebration_outlined, 'Wedding Anniversary', emp.anniversaryDate),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Credentials & Password Management Card (Hidden for TL, Reset ONLY for CEO)
            if (!isTeamLead) ...[
              LiquidGlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_outline, size: 18, color: AppColors.magentaPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Portal Access & Credentials',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCeo || isHr) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.lock_reset, size: 14, color: AppColors.magentaPrimary),
                            label: Text(
                              'Reset',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.magentaPrimary,
                              ),
                            ),
                            onPressed: () => _openResetPasswordDialog(context, eco, emp),
                          ),
                        ],
                      ],
                    ),
                    const Divider(color: Color(0xFFF1F5F9), height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.key, size: 15, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Text(
                            'Active Password: ',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _isPasswordRevealed ? empPassword : '••••••••',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isPasswordRevealed ? Icons.visibility_off : Icons.visibility,
                              size: 17,
                              color: AppColors.magentaPrimary,
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
              ),
              const SizedBox(height: 14),
            ],

            if (isTargetCeo) ...[
              LiquidGlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.sandGold.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium, color: AppColors.sandGold, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Executive CEO Governance',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Exempt from retail punch logs and document vault custody.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 3. Document Submission Status & Vault Custody (Exempt for CEO)
            if (!isTargetCeo) ...[
              LiquidGlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_shared_outlined, size: 18, color: AppColors.magentaPrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Document Vault Custody',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
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
                          color: submissionPercent >= 80 ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: submissionPercent >= 80 ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Text(
                          '$submissionPercent% Submitted ($submittedDocsCount/$totalDocsCount)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: submissionPercent >= 80 ? const Color(0xFF059669) : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HR Custody of employee certificates & original ID verifications.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),

                  // Real Document List (Scattered or Clean State)
                  if (docs.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No Certificates Deposited Yet',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Employee has not reported certificate submission in MN Pillar yet. Once deposited, original records will appear here.',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...docs.map((d) {
                      final isSubmitted = d.status == DocumentSubmissionStatus.submitted;
                      final isPending = d.status == DocumentSubmissionStatus.pending;
                      final badgeColor = isSubmitted ? const Color(0xFF059669) : (isPending ? const Color(0xFFE11D48) : const Color(0xFFD97706));
                      final badgeBg = isSubmitted ? const Color(0xFFECFDF5) : (isPending ? const Color(0xFFFFF1F2) : const Color(0xFFFFFBEB));
                      final badgeBorder = isSubmitted ? const Color(0xFFA7F3D0) : (isPending ? const Color(0xFFFECDD3) : const Color(0xFFFDE68A));

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
                            Icon(
                              isSubmitted ? Icons.check_circle : (isPending ? Icons.pending_outlined : Icons.hourglass_top),
                              size: 16,
                              color: badgeColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${d.category} • Vault: ${d.vaultLockerRef}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            PopupMenuButton<DocumentSubmissionStatus>(
                              onSelected: (newStatus) {
                                eco.updateOriginalDocumentStatus(d.id, newStatus, emp.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Updated "${d.title}" status to ${newStatus.name}.')),
                                );
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: DocumentSubmissionStatus.submitted,
                                  child: Text('Mark Submitted'),
                                ),
                                const PopupMenuItem(
                                  value: DocumentSubmissionStatus.pending,
                                  child: Text('Mark Pending'),
                                ),
                                const PopupMenuItem(
                                  value: DocumentSubmissionStatus.verifying,
                                  child: Text('Mark Verifying'),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: badgeBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      d.status.name.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: badgeColor,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(Icons.arrow_drop_down, size: 14, color: badgeColor),
                                  ],
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
          ],

          // 4. Attendance & 1-Week Performance (Exempt for CEO and OTM)
          if (emp.hasAttendanceAndGrooming && !isTargetCeo) ...[
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fingerprint, size: 18, color: AppColors.magentaPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Attendance & Punch Log',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _attendanceMetricTile(
                          'Today Status',
                          isAbsent ? 'Absent' : 'Present',
                          isAbsent ? const Color(0xFFE11D48) : const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _attendanceMetricTile(
                          'Attendance Rate',
                          '$realAttendancePercent%',
                          realAttendancePercent >= 80
                              ? const Color(0xFF059669)
                              : (realAttendancePercent > 0 ? const Color(0xFFD97706) : const Color(0xFFE11D48)),
                          tuesdayOvertimeCount > 0 ? '+$tuesdayOvertimeCount Tuesday OT' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _attendanceMetricTile(
                          'Total Hours',
                          realTotalHoursFormatted,
                          AppColors.magentaPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

            // 5. Gender-Based Staff Attire & Grooming Audit (Exempt for OTM Praveenkumar)
            if (emp.hasAttendanceAndGrooming) ...[
              _buildGroomingAuditCard(context, eco, emp),
              const SizedBox(height: 14),
            ],

            // 5. Active Requests & Leaves History
            if (empPermissions.isNotEmpty || empMedicalLeaves.isNotEmpty) ...[
              LiquidGlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_toggle_off, size: 18, color: AppColors.magentaPrimary),
                        const SizedBox(width: 8),
                        Text(
                          'Permissions & Medical Leaves',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFF1F5F9), height: 20),
                    ...empPermissions.map((p) {
                      final isOrange = p.isOrangeFlagged || p.requestedHours > 2.0;
                      final durText = p.actualHoursUsed < 1.0 ? '${(p.actualHoursUsed * 60).round()}m' : '${p.actualHoursUsed}h';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isOrange ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isOrange ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined, size: 15, color: isOrange ? const Color(0xFFD97706) : AppColors.magentaPrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency Permission ($durText)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isOrange ? const Color(0xFFD97706) : AppColors.textDark,
                                    ),
                                  ),
                                  Text(p.reason, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Text(
                              p.status,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: p.status == 'Approved' ? const Color(0xFF059669) : AppColors.magentaPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    ...empMedicalLeaves.map((m) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.medical_services_outlined, size: 15, color: Color(0xFFEF4444)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Medical Leave (${m.days} Days)',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  Text(m.reason, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                              icon: const Icon(Icons.image, size: 12, color: AppColors.magentaPrimary),
                              label: Text('Prescription', style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.magentaPrimary)),
                              onPressed: () => PrescriptionViewerDialog.show(context, leave: m),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _attendanceMetricTile(String label, String value, Color color, [String? subLabel]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: color),
          ),
          if (subLabel != null) ...[
            const SizedBox(height: 1),
            Text(subLabel, style: const TextStyle(fontSize: 8.5, color: Color(0xFF8B5CF6), fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _buildGroomingAuditCard(BuildContext context, EcosystemProvider eco, Employee emp) {
    final isFemale = emp.isFemale;
    final checklist = isFemale ? EcosystemProvider.getFemaleGroomingChecklist() : EcosystemProvider.getMaleGroomingChecklist();
    final audits = eco.getEmployeeGroomingAudits(emp.id);

    // Initialize checks if not set
    final hasExistingAudit = audits.isNotEmpty && audits.first.followedItems.isNotEmpty;
    for (final item in checklist) {
      _groomingChecks.putIfAbsent(
        item,
        () => hasExistingAudit ? audits.first.followedItems.contains(item) : false,
      );
    }
    final checkedCount = checklist.where((item) => _groomingChecks[item] ?? false).length;
    final livePoints = (checkedCount * 10).clamp(0, 50);
    final livePercentage = ((livePoints / 50.0) * 100.0).round();
    final isCompliant = livePercentage >= 80;
    final isPendingAudit = !hasExistingAudit && checkedCount == 0;

    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dry_cleaning_outlined, size: 18, color: AppColors.magentaPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Attire & Grooming Compliance',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isFemale ? const Color(0xFFFDF2F8) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isFemale ? const Color(0xFFFBCFE8) : const Color(0xFFBFDBFE),
                  ),
                ),
                child: Text(
                  isFemale ? 'FEMALE (SAREE)' : 'MALE (FORMAL)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isFemale ? AppColors.magentaPrimary : const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Gender: ${emp.genderDisplay} • 50 Pts Scale',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isPendingAudit
                      ? 'Pending Floor Audit (0/50 Pts)'
                      : 'Score: $livePercentage% ($livePoints/50 Pts)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPendingAudit
                        ? AppColors.textMuted
                        : (isCompliant ? const Color(0xFF059669) : const Color(0xFFE11D48)),
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 18),

          // Quick selection controls
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    for (final item in checklist) {
                      _groomingChecks[item] = true;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    'Select All (50 Pts)',
                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    for (final item in checklist) {
                      _groomingChecks[item] = false;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    'Deselect All',
                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Checklist Items with Multiple Selection / Deselection
          ...checklist.map((item) {
            final isChecked = _groomingChecks[item] ?? false;
            return InkWell(
              onTap: () {
                setState(() {
                  _groomingChecks[item] = !isChecked;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: isChecked ? const Color(0xFF059669) : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: isChecked ? AppColors.textDark : AppColors.textSecondary,
                          fontWeight: isChecked ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isChecked ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isChecked ? '+10 Pts' : '0 Pts',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isChecked ? const Color(0xFF059669) : const Color(0xFFE11D48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 14),
          // Save Daily Grooming Audit Button
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 14, color: Colors.white),
            label: Text(
              'Save Grooming Audit ($livePoints/50 Pts • $livePercentage%)',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompliant ? const Color(0xFF059669) : AppColors.magentaPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final followed = checklist.where((i) => _groomingChecks[i] ?? true).toList();
              eco.recordDailyGroomingAudit(
                empId: emp.id,
                followedItems: followed,
                pointsEarned: livePoints,
                maxPoints: 50,
                reason: 'HR dossier inspection completed.',
                auditedBy: 'Mohankumar G (HR)',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Saved Grooming Audit: $livePoints/50 Pts ($livePercentage%) for ${emp.name}'),
                  backgroundColor: const Color(0xFF059669),
                ),
              );
            },
          ),

          if (audits.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Recent Audits: ${audits.take(2).map((a) => "${a.pointsChange > 0 ? '+' : ''}${a.pointsChange}pts (${a.category})").join(" • ")}',
              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.textMuted),
            ),
          ],
        ],
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

  void _openEditProfileModal(BuildContext context, EcosystemProvider eco, Employee emp) {
    final nameCtrl = TextEditingController(text: emp.name);
    final phoneCtrl = TextEditingController(text: emp.phone);
    final dobCtrl = TextEditingController(text: emp.dob);
    final annivCtrl = TextEditingController(text: emp.anniversaryDate);
    String relStatus = emp.relationshipStatus.isNotEmpty ? emp.relationshipStatus : 'Single';
    String gender = emp.gender.isNotEmpty ? emp.gender : 'Male';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                        const Icon(Icons.edit_note_rounded, color: AppColors.magentaPrimary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Edit Staff Profile',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  'Update details for ${emp.name} (#${emp.id}) and sync to Cloud Firestore.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),

                // Name
                Text('Full Legal Name', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 4),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: AppColors.magentaPrimary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Phone
                Text('Mobile Phone Number', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 4),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.magentaPrimary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Date of Birth
                Text('Date of Birth (DOB)', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 4),
                TextField(
                  controller: dobCtrl,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(1995, 1, 1),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setModalState(() {
                        dobCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                      });
                    }
                  },
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.cake_outlined, size: 18, color: AppColors.magentaPrimary),
                    suffixIcon: const Icon(Icons.calendar_today, size: 16, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),

                // Gender
                Text('Gender (Attire & Grooming Allocation)', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: gender,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.wc_outlined, size: 18, color: AppColors.magentaPrimary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => gender = val);
                  },
                ),
                const SizedBox(height: 12),

                // Relationship Status
                Text('Relationship Status', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: relStatus,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.favorite_border, size: 18, color: AppColors.magentaPrimary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Single', child: Text('Single')),
                    DropdownMenuItem(value: 'Married', child: Text('Married')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => relStatus = val);
                  },
                ),

                if (relStatus == 'Married') ...[
                  const SizedBox(height: 12),
                  Text('Marriage Anniversary Date', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: annivCtrl,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime(2020, 1, 1),
                        firstDate: DateTime(1970),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() {
                          annivCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        });
                      }
                    },
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.celebration_outlined, size: 18, color: AppColors.magentaPrimary),
                      suffixIcon: const Icon(Icons.calendar_month, size: 16, color: AppColors.textMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ],
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
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text('Save Profile to Firebase', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () async {
                      final updatedName = nameCtrl.text.trim();
                      if (updatedName.isEmpty) return;
                      final messenger = ScaffoldMessenger.of(context);
                      await eco.updateEmployeePersonalDetails(
                        empId: emp.id,
                        name: updatedName,
                        phone: phoneCtrl.text.trim(),
                        dob: dobCtrl.text.trim(),
                        relationshipStatus: relStatus,
                        anniversaryDate: relStatus == 'Married' ? annivCtrl.text.trim() : '',
                        gender: gender,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Profile for $updatedName updated and saved to Cloud Firestore!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
