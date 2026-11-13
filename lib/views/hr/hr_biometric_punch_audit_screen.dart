import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/prescription_viewer_dialog.dart';
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

    // 2. Permission Records
    final empPermissions = eco.permissionRecords.where((p) => p.empId == emp.id).toList();
    final approvedPermissions = empPermissions.where((p) => p.status == 'Approved').toList();
    final totalPermHoursUsed = approvedPermissions.fold<double>(0.0, (sum, p) => sum + p.requestedHours);
    final remainingPermHours = (2.0 - totalPermHoursUsed).clamp(0.0, 2.0);

    // 3. Leave Records (Casual Delegations + Medical Leaves)
    final empCasualLeaves = eco.delegations.where((d) => d.absentEmpId == emp.id).toList();
    final empMedicalLeaves = eco.medicalLeaveRecords.where((m) => m.empId == emp.id).toList();
    final approvedMedicalLeaves = empMedicalLeaves.where((m) => m.status == 'Approved').toList();
    final totalLeavesTakenCount = empCasualLeaves.length + approvedMedicalLeaves.length;

    // 4. Today's Live Attendance Punch Summary
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
              'Biometric Punch Audit',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              '${emp.name} • #${emp.id}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
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
                                  fontSize: 9,
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
                                  fontSize: 10.5,
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

            // High-Level Attendance & Leaves KPI Grid
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
                    title: 'Leaves Taken',
                    value: '$totalLeavesTakenCount Days',
                    subtext: 'Casual: ${empCasualLeaves.length} • Medical: ${approvedMedicalLeaves.length}',
                    icon: Icons.beach_access_rounded,
                    color: totalLeavesTakenCount > 2 ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _kpiCard(
                    title: 'Permissions Taken',
                    value: '${approvedPermissions.length} Taken',
                    subtext: '${totalPermHoursUsed.toStringAsFixed(1)}h Used (${remainingPermHours.toStringAsFixed(1)}h Quota Left)',
                    icon: Icons.timer_outlined,
                    color: remainingPermHours < 0.5 ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6),
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
                      const SizedBox(width: 8),
                      Text(
                        'Total: ${todaySummary.workHoursFormatted}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.magentaPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _punchBox(
                          label: 'IN TIME',
                          time: todaySummary.inTimeString,
                          icon: Icons.login_rounded,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _punchBox(
                          label: 'LUNCH BREAK',
                          time: todaySummary.lunchSummary,
                          icon: Icons.restaurant_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _punchBox(
                          label: 'OUT TIME',
                          time: todaySummary.outTimeString,
                          icon: Icons.logout_rounded,
                          color: const Color(0xFF64748B),
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
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 2,
                                    children: [
                                      Text(
                                        'In: ${day.loginTime}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF334155), fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Out: ${day.logoutTime}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF334155), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Net Hours: ${day.netHours}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.textMuted),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: day.statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: day.statusColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                day.status,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
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

            // Permissions History
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
                      Expanded(
                        child: Text(
                          'Total Permissions Taken (${empPermissions.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quota: ${remainingPermHours.toStringAsFixed(1)}h Left',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.magentaPrimary),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  if (empPermissions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No emergency permissions recorded for this employee.', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11.5)),
                    )
                  else
                    ...empPermissions.map((perm) {
                      final isApproved = perm.status == 'Approved';
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
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.timer, size: 14, color: isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${perm.requestedHours} Hour(s) Permission • ${perm.date}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Reason: ${perm.reason}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: (isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                perm.status,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: isApproved ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
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

            // Leaves & Medical Slips History
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
                      Expanded(
                        child: Text(
                          'Total Leaves Taken (${empCasualLeaves.length + empMedicalLeaves.length})',
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
                  if (empCasualLeaves.isEmpty && empMedicalLeaves.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No casual or medical leaves recorded.', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11.5)),
                    )
                  else ...[
                    // Medical Leaves
                    ...empMedicalLeaves.map((m) {
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
                            const Icon(Icons.local_hospital_rounded, size: 16, color: Color(0xFFEF4444)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency Medical Leave • ${m.date}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Reason: ${m.reason}', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            if (m.prescriptionBase64.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.magentaPrimary),
                                tooltip: 'View Prescription',
                                onPressed: () => PrescriptionViewerDialog.show(context, leave: m, isHr: true),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: (m.status == 'Approved' ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m.status,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: m.status == 'Approved' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    // Casual Leaves
                    ...empCasualLeaves.map((c) {
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
                            const Icon(Icons.beach_access_rounded, size: 16, color: Color(0xFF3B82F6)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Casual Leave • ${c.date}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Substitute: ${c.coveringEmpName}', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Approved',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF10B981),
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
                              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'at ${p.timeString}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ID: ${p.id}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 9, color: const Color(0xFF94A3B8)),
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
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
            style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _punchBox({
    required String label,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
