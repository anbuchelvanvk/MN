import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/employee_model.dart';
import '../../models/hr_attendance_sheet_models.dart';
import '../../providers/ecosystem_provider.dart';
import '../ceo/ceo_subpages.dart';
import '../dept_head/dept_head_subpages.dart';
import 'tier_pillar_screen.dart';
import '../../core/widgets/mn_app_bar.dart';

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

    // For CEO: Directly open Executive Company-Wide Attendance Dashboard
    // where CEO inspects all employees' attendance, monthly records, and Google Sheets ledger
    if (currentEmp.isCeo) {
      return const CeoAttendanceScreen();
    }

    final bool isExempt = !currentEmp.hasAttendanceAndGrooming;
    final row = provider.currentEmployeeHrAttendanceRow;
    final sheet = provider.hrAttendanceSheet;
    final lastSynced = provider.attendanceSheetLastSynced;
    final isSyncing = provider.isLoadingAttendanceSheet;

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: MnAppBar(
        title: 'Attendance',
        subtitle: isExempt
            ? 'Exempt from the shift roster'
            : '${_titleCase(sheet?.monthTitle ?? 'This month')} • from the HR attendance sheet',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: isExempt
            ? _buildLeadershipExemptionSection(context, currentEmp)
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

                  // 4. Recent Attendance Performance (Past 7 Days Record from Sheet)
                  _buildPast7DaysAttendanceLogCard(context, provider, currentEmp),
                  const SizedBox(height: 16),

                  // 5. Interactive 31-Day Attendance Ledger Calendar Grid
                  _buildAttendanceCalendarCard(context, row, sheet),
                  const SizedBox(height: 16),



                  // 6. Sovereign Green Light Impact Gateway
                  _buildGreenLightGateway(context, provider),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }

  // --- 1. LEADERSHIP & OTM EXEMPTION VIEW ---
  Widget _buildLeadershipExemptionSection(BuildContext context, Employee emp) {
    final isCeo = emp.roleType.toLowerCase() == 'ceo' || emp.id.toUpperCase() == 'MN-CEO01';
    final isExt = emp.isExternalSupport || emp.dept == 'External Support Staff [Online]';
    final roleHeader = isCeo
        ? 'MANAGING DIRECTOR & CEO'
        : (isExt
            ? 'EXTERNAL SUPPORT STAFF [ONLINE]'
            : 'ONLINE TEAM MANAGER (OTM)');
    final desc = isExt
        ? 'Exempt from Retail Showroom Attendance & Grooming.\nOff-site contractor governed by Konar deliverables & tasks.'
        : 'Exempt from Attendance & Showroom Grooming.';

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
            roleHeader,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
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
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.magentaPrimary,
              size: 22,
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
                        'HOW ATTENDANCE WORKS',
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
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'HR MANAGED',
                        style: TextStyle(
                          fontSize: 11,
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
                  'HR Department • hr@mnj.com',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
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
    final timeStr = lastSynced != null
        ? DateFormat('hh:mm a').format(lastSynced)
        : 'Auto';

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
                      await provider.syncGoogleSheetsAttendance(
                        notifyIfUpdated: true,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF10B981),
                            content: Text(
                              'Attendance synchronized with Google Sheet!',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.magentaPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.magentaPrimary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSyncing)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.magentaPrimary,
                        ),
                      )
                    else
                      const Icon(
                        Icons.sync_rounded,
                        size: 14,
                        color: AppColors.magentaPrimary,
                      ),
                    const SizedBox(width: 5),
                    Text(
                      isSyncing ? 'Syncing...' : 'Sync from Sheet',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
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
  Widget _buildMonthlyKpiGrid(
    BuildContext context,
    HrEmployeeAttendanceRow? row,
  ) {
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
                subtext: isLateOver
                    ? '⚠️ $penaltyDays Penalty Day(s)'
                    : 'Within monthly grace',
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
                value:
                    'CL: ${clUsed.toStringAsFixed(clUsed == clUsed.roundToDouble() ? 0 : 1)}/1 • LOP: ${lopUsed.toStringAsFixed(lopUsed == lopUsed.roundToDouble() ? 0 : 1)}',
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
                subtext: isPermOver
                    ? '⚠️ Exceeded 4h Quota'
                    : '$permRemStr Remaining',
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
                title: 'FIELD VISITS (MNW)',
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
                    fontSize: 11.5,
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
              fontSize: 11,
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

  // --- 4B. PAST 7 DAYS RECENT ATTENDANCE PERFORMANCE LOG ---
  Widget _buildPast7DaysAttendanceLogCard(
    BuildContext context,
    EcosystemProvider provider,
    Employee currentEmp,
  ) {
    final records = provider.getPast7DaysAttendanceForEmployee(currentEmp.id);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.sandGold.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded, size: 18, color: AppColors.sandGold),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LAST 7 DAYS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.sandGold,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Official Past 7 Days Record from HR Ledger',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PAST 7 DAYS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No recent attendance entries recorded yet.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ...records.asMap().entries.map((entry) {
              final idx = entry.key;
              final rec = entry.value;
              final isLast = idx == records.length - 1;

              return Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.burgundySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: rec.statusColor.withOpacity(0.35),
                    width: 1.0,
                  ),
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
                              Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.sandGold.withOpacity(0.8)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  rec.dateLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: rec.statusColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: rec.statusColor.withOpacity(0.5)),
                          ),
                          child: Text(
                            rec.status,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: rec.statusColor,
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
                      '$monthTitle CALENDAR',
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
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.magentaPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  sheet?.latestRecordedDay != null
                      ? 'Updated up to ${_ordinal(sheet!.latestRecordedDay)} • $daysCount Days'
                      : 'Not updated yet',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.magentaPrimary,
                  ),
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
                _legendItem(
                  'Present (Nil)',
                  Colors.white,
                  const Color(0xFFE2E8F0),
                  const Color(0xFF0F172A),
                ),
                const SizedBox(width: 6),
                _legendItem(
                  'Late (L-1..3)',
                  const Color(0xFFFEF9C3),
                  const Color(0xFFFACC15),
                  const Color(0xFF854D0E),
                ),
                const SizedBox(width: 6),
                _legendItem(
                  'Leave (CL/LOP)',
                  const Color(0xFFFEE2E2),
                  const Color(0xFFF87171),
                  const Color(0xFF991B1B),
                ),
                const SizedBox(width: 6),
                _legendItem(
                  'Permission (4h)',
                  const Color(0xFFDCFCE7),
                  const Color(0xFF4ADE80),
                  const Color(0xFF166534),
                ),
                const SizedBox(width: 6),
                _legendItem(
                  'Late+1/2D',
                  const Color(0xFFFFEDD5),
                  const Color(0xFFFB923C),
                  const Color(0xFF9A3412),
                ),
                const SizedBox(width: 6),
                _legendItem(
                  'MNW (Duty)',
                  const Color(0xFFDBEAFE),
                  const Color(0xFF3B82F6),
                  const Color(0xFF1E40AF),
                ),
                const SizedBox(width: 6),
                _legendItem(
                  'Holiday',
                  const Color(0xFFF1F5F9),
                  const Color(0xFFCBD5E1),
                  const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                _legendItem(
                  'Yet to update',
                  const Color(0xFFFEF9C3),
                  const Color(0xFFFACC15),
                  const Color(0xFFB45309),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Notice for Unmapped / Executive Profiles
          if (row == null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.sandGold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Executive View: You are not assigned to the showroom shift roster. View full workforce sheet in HR Portal.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

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
              final isTuesday = (day == 3 || day == 10 || day == 17 || day == 24);
              final record =
                  row?.days[day] ??
                  (isTuesday
                      ? HrAttendanceDayRecord(
                          day: day,
                          rawValue: 'H',
                          type: HrAttendanceDayType.holiday,
                          displayLabel: 'Holiday (Tuesday)',
                        )
                      : HrAttendanceDayRecord(
                          day: day,
                          rawValue: '',
                          type: HrAttendanceDayType.pendingUpdate,
                          displayLabel: 'Yet to update',
                        ));

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
                      color: isSelected
                          ? AppColors.magentaPrimary
                          : record.borderColor,
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
                  child: FittedBox(fit: BoxFit.scaleDown, child: Column(
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
                  )),
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
          fontSize: 11,
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
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: record.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      case HrAttendanceDayType.leaveCl:
        return const Text(
          'CL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF991B1B),
          ),
        );
      case HrAttendanceDayType.leaveLop:
        return const Text(
          'LOP',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF991B1B),
          ),
        );
      case HrAttendanceDayType.leaveHalfDay:
        return const Text(
          '1/2D',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF991B1B),
          ),
        );
      case HrAttendanceDayType.permission:
        return Text(
          record.rawValue.trim(),
          style: TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.bold,
            color: record.textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      case HrAttendanceDayType.lateAndHalfDay:
        return const Text(
          'L+1/2',
          style: TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9A3412),
          ),
        );
      case HrAttendanceDayType.mnw:
        return const Text(
          'MNW',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
          ),
        );
      case HrAttendanceDayType.holiday:
        return Text(
          record.rawValue.trim().isNotEmpty
              ? record.rawValue.trim().toUpperCase()
              : 'H',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        );
      case HrAttendanceDayType.notApplicable:
        return const Text(
          '-',
          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        );
      case HrAttendanceDayType.pendingUpdate:
        return const Text(
          '—',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFFCBD5E1),
          ),
        );
      case HrAttendanceDayType.present:
        return const Text(
          'P',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF10B981),
          ),
        );
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
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFFE2E8F0), height: 1),
            const SizedBox(height: 14),

            // Detail Attributes
            _detailRow(
              'Status Category',
              record.displayLabel,
              record.textColor,
            ),
            const SizedBox(height: 8),
            _detailRow(
              'Sheet Raw Value',
              record.type == HrAttendanceDayType.pendingUpdate
                  ? '— (Awaiting HR Upload)'
                  : (record.rawValue.isEmpty ? 'nil (Fully Present)' : record.rawValue),
              AppColors.textDark,
            ),
            if (record.permissionMinutes > 0) ...[
              const SizedBox(height: 8),
              _detailRow(
                'Permission Minutes',
                '${record.permissionMinutes.round()} Min (${(record.permissionMinutes / 60.0).toStringAsFixed(1)} Hours)',
                const Color(0xFF166534),
              ),
            ],
            const SizedBox(height: 8),
            _detailRow(
              'Official Authority',
              record.type == HrAttendanceDayType.pendingUpdate
                  ? 'HR Department (Pending Entry)'
                  : (record.type == HrAttendanceDayType.holiday
                      ? 'Showroom Schedule (Weekly Holiday)'
                      : 'HR Department (Uploaded & Audited)'),
              AppColors.sandGold,
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                record.type == HrAttendanceDayType.pendingUpdate
                    ? '📌 Note: Attendance records in the HR master sheet are currently updated up to the 14th. When HR uploads data for this date, it will automatically reflect here.'
                    : '📌 Note: If you have any discrepancy regarding this date, please reach out to HR for verification and spreadsheet adjustment.',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // --- 7. GREEN LIGHT IMPACT GATEWAY ---
  Widget _buildGreenLightGateway(
    BuildContext context,
    EcosystemProvider provider,
  ) {
    final color = provider.holisticTierColor;
    final isRed = color == AppColors.ragRed;
    final isGreen = color == AppColors.ragGreen;
    final pillBg = isRed
        ? const Color(0xFFFFF1F4)
        : (isGreen ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB));
    final pillBorder = isRed
        ? const Color(0xFFFECDD3)
        : (isGreen ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A));
    final pillTextColor = isRed
        ? const Color(0xFFE11D48)
        : (isGreen ? const Color(0xFF059669) : const Color(0xFFD97706));

    final isAttendanceOnTime = provider.hasLoggedAttendanceToday && provider.isAttendanceOnTime;
    final statusPillBg = isAttendanceOnTime ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F4);
    final statusPillBorder = isAttendanceOnTime ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3);
    final statusPillTextColor = isAttendanceOnTime ? const Color(0xFF059669) : const Color(0xFFE11D48);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const TierPillarScreen()),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: pillBorder, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.light_mode, size: 12, color: pillTextColor),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: pillTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusPillBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusPillBorder, width: 1),
                      ),
                      child: Text(
                        isAttendanceOnTime ? 'On-Time Verified' : 'Attendance Pending',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: statusPillTextColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.sandGold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_outlined,
                      color: AppColors.sandGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Impact on your overall status',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Attendance and leaves count towards your monthly score',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.sandGold,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1 -> 1st, 2 -> 2nd, 3 -> 3rd, 11 -> 11th, 22 -> 22nd ...
String _ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

String _titleCase(String s) => s
    .toLowerCase()
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');
