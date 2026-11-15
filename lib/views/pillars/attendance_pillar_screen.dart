import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/emergency_permission_modal.dart';
import '../../core/widgets/emergency_medical_leave_modal.dart';
import '../../core/widgets/prescription_viewer_dialog.dart';
import '../../models/employee_model.dart';
import '../../models/hr_attendance_sheet_models.dart';
import '../../providers/ecosystem_provider.dart';
import 'tier_pillar_screen.dart';

class AttendancePillarScreen extends StatefulWidget {
  const AttendancePillarScreen({super.key});

  @override
  State<AttendancePillarScreen> createState() => _AttendancePillarScreenState();
}

class _AttendancePillarScreenState extends State<AttendancePillarScreen> {
  int? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EcosystemProvider>();
    final currentEmp = provider.currentEmployee;
    final bool isOtm = currentEmp.isOtm;
    final row = provider.currentEmployeeHrAttendanceRow;
    final sheet = provider.hrAttendanceSheet;
    final lastSynced = provider.attendanceSheetLastSynced;
    final isSyncing = provider.isLoadingAttendanceSheet;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ATTENDANCE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.sandLight,
                letterSpacing: 0.8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              isOtm
                  ? 'Autonomous Cadence • Project Deliverables'
                  : '${sheet?.monthTitle ?? "November 2026"} • Official HR Master Ledger',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: AppColors.sandGold,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: LiquidGlassPill(
                label: isOtm ? 'OTM EXEMPT' : 'PILLAR 4 • HR AUDIT',
                color: isOtm ? const Color(0xFF10B981) : AppColors.magentaPrimary,
                icon: isOtm ? Icons.verified : Icons.assignment_turned_in_rounded,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: isOtm
            ? _buildOtmExemptionSection(context, currentEmp)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Official HR Notice Card
                  _buildHrNoticeCard(context),
                  const SizedBox(height: 14),

                  // 2. Google Sheets Live Sync Bar
                  _buildLiveSyncBar(context, provider, lastSynced, isSyncing),
                  const SizedBox(height: 14),

                  // 3. Four Core Monthly Metrics (Late, Leaves, 4h Permission, MNW)
                  _buildMonthlyKpiGrid(context, row),
                  const SizedBox(height: 16),

                  // 4. Interactive 31-Day Attendance Ledger Calendar Grid
                  _buildAttendanceCalendarCard(context, row, sheet),
                  const SizedBox(height: 16),

                  // 5. Emergency Permissions (4-Hour Quota) & Medical Leave Section
                  _buildEmergencyPermissionsAndLeavesSection(context, provider),
                  const SizedBox(height: 16),

                  // 6. Sovereign Green Light Impact Gateway
                  _buildGreenLightGateway(context, provider),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  // --- 1. OTM EXEMPTION VIEW ---
  Widget _buildOtmExemptionSection(BuildContext context, Employee emp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 2),
                ),
                child: const Icon(Icons.verified_rounded, size: 36, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 16),
              Text(
                'ONLINE TEAM MANAGER (OTM)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.sandLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Attendance & Daily Grooming Exemption',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF059669),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFE2E8F0), height: 1),
              const SizedBox(height: 14),
              Text(
                'As the Online Team Manager, ${emp.name} operates under autonomous project deliverable milestones, creative video turnarounds, and digital catalog SLA metrics.\n\nDaily retail showroom attendance punching, lunch logs, and grooming audits are Not Applicable to this executive function.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _exemptionBadge(Icons.assignment_turned_in, 'Milestone SLA Cadence', const Color(0xFF3B82F6)),
                  _exemptionBadge(Icons.fingerprint, 'Biometrics Waived', const Color(0xFF10B981)),
                  _exemptionBadge(Icons.face_retouching_natural, 'Grooming Exempt', const Color(0xFF8B5CF6)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Emergency Step-Out Pass for OTM
        _buildEmergencyPermissionsAndLeavesSection(context, context.watch<EcosystemProvider>()),
      ],
    );
  }

  Widget _exemptionBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. OFFICIAL HR NOTICE CARD ---
  Widget _buildHrNoticeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.magentaPrimary.withOpacity(0.12),
            ),
            child: const Icon(Icons.verified_user_rounded, color: AppColors.magentaPrimary, size: 22),
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
                      'OFFICIAL HR ATTENDANCE RECORDING',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sandGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'HR MANAGED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Your attendance will be recorded and uploaded by HR. If any queries, please contact HR.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sandLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'HR Custodian: Mohankumar G • Ext: 1001 • hr@mnj.com',
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
    );
  }

  // --- 3. LIVE SYNC BAR ---
  Widget _buildLiveSyncBar(
    BuildContext context,
    EcosystemProvider provider,
    DateTime? lastSynced,
    bool isSyncing,
  ) {
    final timeStr = lastSynced != null ? DateFormat('hh:mm a').format(lastSynced) : 'Auto';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.burgundySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Google Sheet Synced ($timeStr)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isSyncing
                  ? null
                  : () async {
                      await provider.syncGoogleSheetsAttendance(notifyIfUpdated: true);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF10B981),
                            content: Text('Attendance synchronized with Google Sheet!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.magentaPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.magentaPrimary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSyncing)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.magentaPrimary),
                      )
                    else
                      const Icon(Icons.sync_rounded, size: 14, color: AppColors.magentaPrimary),
                    const SizedBox(width: 5),
                    Text(
                      isSyncing ? 'Syncing...' : 'Sync from Sheet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.magentaPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. FOUR CORE MONTHLY METRICS ---
  Widget _buildMonthlyKpiGrid(BuildContext context, HrEmployeeAttendanceRow? row) {
    final lateCount = row?.lateCount ?? 0;
    final isLateOver = lateCount > 3;
    final penaltyDays = row?.latePenaltyDays ?? 0;

    final clUsed = row?.clDaysUsed ?? 0.0;
    final lopUsed = row?.lopDaysUsed ?? 0.0;

    final permUsedStr = row?.formattedPermissionUsed ?? '0m';
    final permRemStr = row?.formattedPermissionRemaining ?? '4.0h';
    final isPermOver = row?.isPermissionExceeded ?? false;

    final mnwDays = row?.mnwDaysCount ?? 0;

    return Column(
      children: [
        Row(
          children: [
            // 🟨 LATE (Allowed up to 3)
            Expanded(
              child: _kpiMetricCard(
                title: 'LATE COMING',
                value: '$lateCount / 3 Allowed',
                subtext: isLateOver ? '⚠️ $penaltyDays Penalty Day(s)' : 'Within monthly grace',
                bgColor: const Color(0xFFFEF9C3),
                borderColor: const Color(0xFFFACC15),
                textColor: const Color(0xFF854D0E),
                icon: Icons.access_time_rounded,
              ),
            ),
            const SizedBox(width: 10),

            // 🟥 LEAVES (CL: 1, rest LOP)
            Expanded(
              child: _kpiMetricCard(
                title: 'LEAVES TAKEN',
                value: 'CL: ${clUsed.toStringAsFixed(clUsed == clUsed.roundToDouble() ? 0 : 1)}/1 • LOP: ${lopUsed.toStringAsFixed(lopUsed == lopUsed.roundToDouble() ? 0 : 1)}',
                subtext: 'CL (Casual) • LOP (Penalty)',
                bgColor: const Color(0xFFFEE2E2),
                borderColor: const Color(0xFFF87171),
                textColor: const Color(0xFF991B1B),
                icon: Icons.event_busy_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // 🟩 PERMISSION (4.0 Hours Quota)
            Expanded(
              child: _kpiMetricCard(
                title: 'PERMISSION (4h)',
                value: '$permUsedStr Used',
                subtext: isPermOver ? '⚠️ Exceeded 4h Quota' : '$permRemStr Remaining',
                bgColor: const Color(0xFFDCFCE7),
                borderColor: const Color(0xFF4ADE80),
                textColor: const Color(0xFF166534),
                icon: Icons.timer_outlined,
              ),
            ),
            const SizedBox(width: 10),

            // 🟦 MNW (Official Work Outside)
            Expanded(
              child: _kpiMetricCard(
                title: 'MNW (OFFICIAL)',
                value: '$mnwDays Days',
                subtext: 'Official client & field visits',
                bgColor: const Color(0xFFDBEAFE),
                borderColor: const Color(0xFF3B82F6),
                textColor: const Color(0xFF1E40AF),
                icon: Icons.storefront_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiMetricCard({
    required String title,
    required String value,
    required String subtext,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: textColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- 5. INTERACTIVE 31-DAY ATTENDANCE CALENDAR ---
  Widget _buildAttendanceCalendarCard(
    BuildContext context,
    HrEmployeeAttendanceRow? row,
    HrMonthlyAttendanceSheet? sheet,
  ) {
    final daysCount = sheet?.daysInMonth ?? 31;
    final monthTitle = sheet?.monthTitle ?? 'November 2026';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$monthTitle ATTENDANCE LEDGER',
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
                      'Tap any day tile to inspect official remarks & HR notes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.magentaPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$daysCount Days',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.magentaPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Color Code Legend
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _legendItem('Present (Nil)', Colors.white, const Color(0xFFE2E8F0), const Color(0xFF0F172A)),
                const SizedBox(width: 6),
                _legendItem('Late (L-1..3)', const Color(0xFFFEF9C3), const Color(0xFFFACC15), const Color(0xFF854D0E)),
                const SizedBox(width: 6),
                _legendItem('Leave (CL/LOP)', const Color(0xFFFEE2E2), const Color(0xFFF87171), const Color(0xFF991B1B)),
                const SizedBox(width: 6),
                _legendItem('Permission (4h)', const Color(0xFFDCFCE7), const Color(0xFF4ADE80), const Color(0xFF166534)),
                const SizedBox(width: 6),
                _legendItem('Late+1/2D', const Color(0xFFFFEDD5), const Color(0xFFFB923C), const Color(0xFF9A3412)),
                const SizedBox(width: 6),
                _legendItem('MNW (Duty)', const Color(0xFFDBEAFE), const Color(0xFF3B82F6), const Color(0xFF1E40AF)),
                const SizedBox(width: 6),
                _legendItem('Holiday', const Color(0xFFF1F5F9), const Color(0xFFCBD5E1), const Color(0xFF64748B)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 31-Day Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: daysCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (ctx, index) {
              final day = index + 1;
              final record = row?.days[day] ??
                  HrAttendanceDayRecord(
                    day: day,
                    rawValue: '',
                    type: HrAttendanceDayType.present,
                    displayLabel: 'Present',
                  );

              final isSelected = _selectedDay == day;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDay = day);
                  _showDayDetailModal(context, day, record, monthTitle);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: record.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.magentaPrimary : record.borderColor,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.magentaPrimary.withOpacity(0.3),
                          blurRadius: 6,
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: record.textColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      _renderCellBadge(record),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color bg, Color border, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }

  Widget _renderCellBadge(HrAttendanceDayRecord record) {
    switch (record.type) {
      case HrAttendanceDayType.late:
        return Text(
          record.rawValue.trim().toUpperCase(),
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: record.textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      case HrAttendanceDayType.leaveCl:
        return const Text('CL', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)));
      case HrAttendanceDayType.leaveLop:
        return const Text('LOP', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)));
      case HrAttendanceDayType.leaveHalfDay:
        return const Text('1/2D', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)));
      case HrAttendanceDayType.permission:
        return Text(
          record.rawValue.trim(),
          style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: record.textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      case HrAttendanceDayType.lateAndHalfDay:
        return const Text('L+1/2', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)));
      case HrAttendanceDayType.mnw:
        return const Text('MNW', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)));
      case HrAttendanceDayType.holiday:
        return Text(
          record.rawValue.trim().isNotEmpty ? record.rawValue.trim().toUpperCase() : 'H',
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
        );
      case HrAttendanceDayType.notApplicable:
        return const Text('-', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)));
      case HrAttendanceDayType.present:
        return const Text('P', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF10B981)));
    }
  }

  void _showDayDetailModal(
    BuildContext context,
    int day,
    HrAttendanceDayRecord record,
    String monthTitle,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: record.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: record.borderColor, width: 1.5),
                  ),
                  child: Text(
                    '$day',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: record.textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$day $monthTitle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'HR Attendance Classification',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 14),

            // Detail Attributes
            _detailRow('Status Category', record.displayLabel, record.textColor),
            const SizedBox(height: 8),
            _detailRow('Sheet Raw Value', record.rawValue.isEmpty ? 'nil (Fully Present)' : record.rawValue, AppColors.textDark),
            if (record.permissionMinutes > 0) ...[
              const SizedBox(height: 8),
              _detailRow(
                'Permission Minutes',
                '${record.permissionMinutes.round()} Min (${(record.permissionMinutes / 60.0).toStringAsFixed(1)} Hours)',
                const Color(0xFF166534),
              ),
            ],
            const SizedBox(height: 8),
            _detailRow('Official Authority', 'HR Department (Uploaded & Audited)', AppColors.sandGold),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                '📌 Note: If you have any discrepancy regarding this date, please reach out to HR for verification and spreadsheet adjustment.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  // --- 6. EMERGENCY PERMISSIONS (4H QUOTA) & MEDICAL LEAVE SECTION ---
  Widget _buildEmergencyPermissionsAndLeavesSection(BuildContext context, EcosystemProvider provider) {
    final permissions = provider.currentEmployeePermissionRecords;
    final medicalLeaves = provider.currentEmployeeMedicalLeaves;
    final usedHours = provider.totalPermissionHoursUsed;
    final remainingHours = provider.permissionHoursRemaining;
    final isOverQuota = usedHours > 4.0;

    return LiquidGlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.sandGold.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.sandGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flash_on, color: AppColors.sandGold, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMERGENCY PASS & MEDICAL LEAVE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      'Direct CEO & HR approval pipeline',
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Two Action Buttons: Emergency Permission & Emergency Medical Leave
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sandGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                  onPressed: () => EmergencyPermissionModal.show(context),
                  icon: const Icon(Icons.access_time_rounded, size: 13, color: Colors.white),
                  label: const Text(
                    'Permission',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                  onPressed: () => EmergencyMedicalLeaveModal.show(context),
                  icon: const Icon(Icons.medical_services_outlined, size: 13, color: Colors.white),
                  label: const Text(
                    'Medical Leave',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4.0 Hours Permission Quota Tally Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOverQuota ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isOverQuota ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('4-Hour Monthly Quota Tally', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text(
                        '${usedHours.toStringAsFixed(1)}h Used • ${remainingHours.toStringAsFixed(1)}h Remaining',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOverQuota
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isOverQuota ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isOverQuota ? '⚠️ Over 4h (Penalty Trigger)' : 'Quota Healthy',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: isOverQuota ? const Color(0xFFD97706) : const Color(0xFF059669),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recent Requests List
          if (permissions.isNotEmpty || medicalLeaves.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Your Active Requests:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
            const SizedBox(height: 6),
            ...permissions.map((p) {
              final isOrange = p.isOrangeFlagged || p.requestedHours > 4.0;
              final durStr = p.actualHoursUsed < 1.0 ? '${(p.actualHoursUsed * 60).round()}m' : '${p.actualHoursUsed}h';
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isOrange ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOrange ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOrange ? Icons.warning_amber_rounded : Icons.timer_outlined,
                      size: 15,
                      color: isOrange ? const Color(0xFFD97706) : AppColors.sandGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Emergency Permission ($durStr)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOrange ? const Color(0xFFD97706) : AppColors.textDark,
                                ),
                              ),
                              if (isOrange) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFF59E0B), width: 0.6),
                                  ),
                                  child: const Text(
                                    '>4h Mark',
                                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            p.reason,
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.status == 'Approved'
                            ? const Color(0xFFECFDF5)
                            : p.status == 'Rejected'
                                ? const Color(0xFFFFF1F2)
                                : const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: p.status == 'Approved'
                              ? const Color(0xFFA7F3D0)
                              : p.status == 'Rejected'
                                  ? const Color(0xFFFECDD3)
                                  : const Color(0xFFFBCFE8),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        p.status,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: p.status == 'Approved'
                              ? const Color(0xFF059669)
                              : p.status == 'Rejected'
                                  ? const Color(0xFFE11D48)
                                  : AppColors.sandGold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            ...medicalLeaves.map((m) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, size: 15, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Medical Leave (${m.days} Days)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          Text(
                            m.reason,
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => PrescriptionViewerDialog.show(context, leave: m),
                      icon: const Icon(Icons.image, size: 12, color: AppColors.sandGold),
                      label: const Text('Prescription', style: TextStyle(fontSize: 9.5, color: AppColors.sandGold)),
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

  // --- 7. GREEN LIGHT IMPACT GATEWAY ---
  Widget _buildGreenLightGateway(BuildContext context, EcosystemProvider provider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => const TierPillarScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sandGold.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.workspace_premium_outlined, color: AppColors.sandGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sovereign Green Light Impact',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pillar 4 attendance & leaves tally into your monthly Sovereign Tier scoring',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.sandGold),
            ],
          ),
        ),
      ),
    );
  }
}
