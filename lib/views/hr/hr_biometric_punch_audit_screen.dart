import '../../core/widgets/mn_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../models/attendance_models.dart';
import '../../models/employee_model.dart';
import '../../providers/ecosystem_provider.dart';

/// Dedicated Biometric Punch & Attendance Audit Screen for HR & Leadership
/// Displays:
/// - Recent 7-day attendance activity
/// - Total leaves taken (casual & medical)
/// - Total permissions taken & quota
/// - Today's biometric in/lunch/out punch logs
/// - Full historical permission and leave logs
class HrBiometricPunchAuditScreen extends StatelessWidget {
  final Employee employee;

  const HrBiometricPunchAuditScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final emp = eco.employees.firstWhere(
      (e) => e.id == employee.id,
      orElse: () => employee,
    );

    // 1. Past 7-Day Attendance Ledger Records (Full Calendar Days)
    final weekRecords = eco.getPast7DaysAttendanceForEmployee(emp.id);
    int daysPresent = 0;
    int tuesdayOvertimeCount = 0;
    int onTimeCount = 0;
    for (final r in weekRecords) {
      if (r.isOvertime || (r.date.weekday == DateTime.tuesday && r.loginTime != '--:-- --')) {
        tuesdayOvertimeCount++;
      }
      if (r.loginTime != '--:-- --') {
        daysPresent++;
        if (r.status.toLowerCase().contains('on time') || r.status.toLowerCase().contains('active') || r.status.toLowerCase().contains('overtime')) {
          onTimeCount++;
        }
      }
    }
    final totalTrackedDays = weekRecords.length;
    final standardDutyDays = weekRecords.where((r) => r.date.weekday != DateTime.tuesday).length;
    final attendanceRatioPercent = (standardDutyDays > 0)
        ? (((daysPresent) / standardDutyDays) * 100).round().clamp(0, 100)
        : 100;
    final onTimeRatePercent = (daysPresent > 0 && onTimeCount > 0) ? ((onTimeCount / daysPresent) * 100).round() : 0;

    // 2. Today's Live Attendance Status Summary
    final summaries = eco.allEmployeesTodayAttendance;
    final todaySummary = summaries.firstWhere(
      (s) => s.employeeId == emp.id,
      orElse: () => EmployeeDailyAttendanceSummary(
        employeeId: emp.id,
        employeeName: emp.name,
        department: emp.dept,
        role: emp.role,
        avatar: emp.avatar,
        initials: emp.initials,
        isPresent: !eco.isEmployeeAbsent(emp.id),
        isOnTime: false,
        isCurrentlyOnLunch: false,
        isCurrentlyOnDuty: !eco.isEmployeeAbsent(emp.id),
        lunchDurationMinutes: 0,
        netWorkHours: 0.0,
        status: eco.isEmployeeAbsent(emp.id) ? DailyAttendanceStatus.absent : DailyAttendanceStatus.presentOnTime,
      ),
    );

    // 5. Raw Biometric Punches with deduplication of rapid duplicate sensor/button taps
    final allRaw = eco.attendancePunches.where((p) => p.enrollNumber == emp.id).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final rawPunches = <AttendancePunchRecord>[];
    for (final p in allRaw) {
      if (rawPunches.isEmpty) {
        rawPunches.add(p);
      } else {
        final last = rawPunches.last;
        final isDup = last.punchType == p.punchType &&
            last.timestamp.difference(p.timestamp).inSeconds.abs() < 5;
        if (!isDup) {
          rawPunches.add(p);
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MnAppBar(
        title: 'Punch Audit',
        subtitle: '${emp.name} • #${emp.id}',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Staff Hero Identification Card
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              borderColor: const Color(0xFFE2E8F0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.magentaPrimary,
                    child: Text(
                      emp.initials,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: todaySummary.statusBadgeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: todaySummary.statusBadgeColor.withOpacity(0.35)),
                              ),
                              child: Text(
                                todaySummary.statusBadgeText.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: todaySummary.statusBadgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${emp.role} • ${emp.dept}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Staff ID: #${emp.id}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                                overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 14),

            // High-Level Attendance KPI Grid
            Row(
              children: [
                Expanded(
                  child: _kpiCard(
                    title: 'Attendance Rate',
                    value: '$attendanceRatioPercent%',
                    subtext: '$daysPresent / $totalTrackedDays Days${tuesdayOvertimeCount > 0 ? " (+$tuesdayOvertimeCount Tuesday OT)" : ""}',
                    icon: Icons.checklist_rtl_rounded,
                    color: attendanceRatioPercent >= 85 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _kpiCard(
                    title: 'On-Time Punctuality',
                    value: '$onTimeRatePercent%',
                    subtext: 'Past 7 Days Compliance',
                    icon: Icons.access_time_filled_rounded,
                    color: onTimeRatePercent >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Today's Live Biometric Log Card
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              borderColor: const Color(0xFFE2E8F0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fingerprint_rounded, color: AppColors.magentaPrimary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Today's Biometric Log",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.sandGold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Official duty attendance and records are maintained directly by HR in the Master Ledger.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recent 7-Day Attendance Activity Ledger
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              borderColor: const Color(0xFFE2E8F0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, color: AppColors.magentaPrimary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Recent Attendance Activity (Past 7 Days)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Daily breakdown of punch ins, lunch intervals, punch outs and net duty hours.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),

                  if (weekRecords.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('No attendance history available.', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12)),
                    )
                  else
                    ...weekRecords.map((day) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 68,
                              child: Text(
                                day.dateLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
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
                                color: day.statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: day.statusColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                day.status,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: day.statusColor,
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
            const SizedBox(height: 16),

            // Raw Biometric Stream
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              borderColor: const Color(0xFFE2E8F0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal_rounded, color: AppColors.magentaPrimary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Raw Biometric Punch Stream (${rawPunches.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  if (rawPunches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No raw biometric punch logs recorded yet today.', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11.5)),
                    )
                  else
                    ...rawPunches.map((p) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 6, color: AppColors.magentaPrimary),
                            const SizedBox(width: 6),
                            Text(
                              p.punchType.name.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'at ${p.timeString}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ID: ${p.id}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8)),
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
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


}
