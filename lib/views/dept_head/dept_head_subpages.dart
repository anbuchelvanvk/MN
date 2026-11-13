import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/personal_todo_section.dart';
import '../../core/widgets/cross_dept_blocker_section.dart';
import '../../core/widgets/assign_tasks_to_others_modal.dart';
import '../../core/widgets/task_action_dialogs.dart';
import '../../models/attendance_models.dart';
import '../../models/employee_model.dart';
import '../../models/task_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../hr/hr_employee_inspection_screen.dart';

/// Reusable Scaffold for all Team Lead Subpages (Clean White/Magenta styling with top-left back button)
class TlSubpageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const TlSubpageScaffold({
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
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

/// 1. TL Team Tasks Screen (Deliverables Monitor sorted Name-wise A to Z)
class TlTeamTasksScreen extends StatelessWidget {
  const TlTeamTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final opsTasks = eco.operationsDeptTasks;

    return TlSubpageScaffold(
      title: 'Team Tasks',
      subtitle: '${opsTasks.length} Operations Tasks Tracked',
      body: _buildDeliverablesMonitor(context, eco, opsTasks),
    );
  }

  static Widget _buildDeliverablesMonitor(BuildContext context, EcosystemProvider eco, List<TaskItem> tasks) {
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No tasks available.',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    // Group tasks by Employee
    final tasksByEmpId = <String, List<TaskItem>>{};
    for (final task in tasks) {
      tasksByEmpId.putIfAbsent(task.empId, () => []).add(task);
    }

    final sortedEmps = tasksByEmpId.keys.map((id) {
      return eco.employees.firstWhere(
        (e) => e.id == id,
        orElse: () => eco.employees.first,
      );
    }).toList();

    if (sortedEmps.length > 1) {
      sortedEmps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Team Tasks',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Name-wise alphabetical arrangement (A to Z)',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.magentaSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.magentaBorder),
              ),
              child: Text(
                '${sortedEmps.length} Staff • ${tasks.length} Tasks',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...sortedEmps.map((emp) {
          final empTasks = tasksByEmpId[emp.id] ?? [];
          final isAbsent = eco.isEmployeeAbsent(emp.id);
          final firstLetter = emp.name.isNotEmpty ? emp.name.substring(0, 1).toUpperCase() : '#';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isAbsent ? const Color(0xFFFFF1F2) : AppColors.whiteBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAbsent ? const Color(0xFFFECDD3) : AppColors.sandBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAbsent ? const Color(0xFFEF4444) : AppColors.magentaPrimary,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          firstLetter,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp.name,
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            Text(
                              '${emp.role} • ${emp.dept}',
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAbsent ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isAbsent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isAbsent ? 'ABSENT (${empTasks.length})' : 'ON DUTY (${empTasks.length})',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isAbsent ? AppColors.ragRed : const Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                ...empTasks.map((task) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => TaskActionDialogs.handleTaskTap(context, eco, task, emp),
                      borderRadius: BorderRadius.circular(16),
                      child: LiquidGlassCard(
                        padding: const EdgeInsets.all(12),
                        borderRadius: 16,
                        borderColor: task.isCompleted ? AppColors.ragGreen.withOpacity(0.35) : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: isAbsent ? const Color(0xFFEF4444).withOpacity(0.2) : AppColors.magentaSubtle,
                                        child: Text(emp.initials, style: TextStyle(fontSize: 9.5, color: isAbsent ? AppColors.ragRed : AppColors.magentaPrimary, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          emp.name,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                LiquidGlassPill(
                                  label: task.status.toUpperCase(),
                                  color: task.isCompleted ? AppColors.ragGreen : (task.isPostponed ? AppColors.ragRed : AppColors.ragYellow),
                                  icon: task.isCompleted ? Icons.check_circle : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: task.isCompleted ? const Color(0xFF64748B) : AppColors.textDark,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                decorationColor: task.isCompleted ? AppColors.ragGreen : null,
                                decorationThickness: 2.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text('Due: ${task.due}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                Text('• Priority: ${task.priority}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                              ],
                            ),

                            if (task.proof != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.ragGreen.withOpacity(0.35)),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        task.proof!.photoUrl ?? '',
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Proof Uploaded', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.ragGreen)),
                                          Text(
                                            task.proof!.timestamp.isNotEmpty ? 'Verified (${task.proof!.timestamp})' : 'Pending verification',
                                            style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            if (task.postponeInfo != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.ragRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.ragRed.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Postpone Reason: ${task.postponeInfo!.reason}',
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.ragRed),
                                    ),
                                    Text(
                                      'Rescheduled to: ${task.postponeInfo!.postponedTo}',
                                      style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// 2. TL Absentees & Shift Hub Screen
class TlAbsenteesScreen extends StatefulWidget {
  const TlAbsenteesScreen({super.key});

  @override
  State<TlAbsenteesScreen> createState() => _TlAbsenteesScreenState();
}

class _TlAbsenteesScreenState extends State<TlAbsenteesScreen> {
  String? _selectedAttendanceMemberId;

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final teamMembers = eco.employees.where((e) => e.dept == 'Online Department' || e.dept == 'Operations').toList();
    final teamAbsentees = teamMembers.where((e) => eco.isEmployeeAbsent(e.id)).toList();

    return TlSubpageScaffold(
      title: 'Absentees & Shift Hub',
      subtitle: '${teamAbsentees.length} Absent Today • ${teamMembers.length} Total Team',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Attendance & Absence Hub Card
          LiquidGlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: const [
                          Icon(Icons.how_to_reg, color: AppColors.magentaPrimary, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Team Attendance Roster',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    LiquidGlassPill(
                      label: '${teamMembers.length - teamAbsentees.length}/${teamMembers.length} Present',
                      color: teamAbsentees.isEmpty ? AppColors.ragGreen : AppColors.ragYellow,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Biometric Roster Status',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 12),

                ...teamMembers.map((emp) {
                  final isAbsent = eco.isEmployeeAbsent(emp.id);
                  final summary = eco.allEmployeesTodayAttendance.firstWhere(
                    (s) => s.employeeId == emp.id,
                    orElse: () => EmployeeDailyAttendanceSummary(
                      employeeId: emp.id,
                      employeeName: emp.name,
                      department: emp.dept,
                      role: emp.role,
                      avatar: emp.avatar,
                      initials: emp.initials,
                      isPresent: !isAbsent,
                      isOnTime: false,
                      isCurrentlyOnLunch: false,
                      isCurrentlyOnDuty: !isAbsent,
                      lunchDurationMinutes: 0,
                      netWorkHours: 0.0,
                      status: isAbsent ? DailyAttendanceStatus.absent : DailyAttendanceStatus.onDuty,
                    ),
                  );

                  final statusColor = isAbsent ? AppColors.ragRed : AppColors.ragGreen;
                  final statusText = isAbsent ? 'Absent' : summary.statusBadgeText;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isAbsent ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isAbsent ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: statusColor.withOpacity(0.15),
                          child: Text(
                            emp.initials,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emp.name,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                              Text(
                                '${emp.straightCutDesignation} • ${summary.workHoursFormatted}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        LiquidGlassPill(
                          label: statusText,
                          color: statusColor,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Team Attendance (1-Week Performance & History)
          _buildTeamAttendanceWidget(context, eco, teamMembers),
          const SizedBox(height: 16),

          // Absent Staff Work Reallocation Hub
          const Text(
            'Absentee Work Reallocation',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Reassign Staff Tasks',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 10),

          if (teamAbsentees.isEmpty) ...[
            LiquidGlassCard(
              borderRadius: 14,
              padding: const EdgeInsets.all(20),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.verified, color: AppColors.ragGreen, size: 36),
                    SizedBox(height: 8),
                    Text('All Team Present', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    SizedBox(height: 4),
                    Text(
                      'No Absentee Tasks',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...() {
              final sortedAbsentees = List<Employee>.from(teamAbsentees);
              if (sortedAbsentees.length > 1) {
                sortedAbsentees.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
              }

              final widgets = <Widget>[];
              String? currentLetter;

              for (final absentEmp in sortedAbsentees) {
                final letter = absentEmp.name.isNotEmpty ? absentEmp.name[0].toUpperCase() : '#';
                if (sortedAbsentees.length > 1 && letter != currentLetter) {
                  currentLetter = letter;
                  widgets.add(
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Section $letter • Absent Staff (A to Z)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB91C1C),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final empTasks = eco.tasks.where((t) => t.empId == absentEmp.id).toList();

                widgets.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LiquidGlassCard(
                      borderRadius: 14,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFEF4444).withOpacity(0.15),
                                child: Text(
                                  absentEmp.initials,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.ragRed),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      absentEmp.name,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                    ),
                                    Text(
                                      '${absentEmp.straightCutDesignation} • ${empTasks.length} Pending Tasks',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.magentaPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.swap_horiz, size: 14, color: Colors.white),
                                label: const Text('Reassign', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                onPressed: () {
                                  AssignTasksToOthersModal.show(context, defaultAbsentEmpId: absentEmp.id);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return widgets;
            }(),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamAttendanceWidget(BuildContext context, EcosystemProvider eco, List<Employee> teamMembers) {
    final effectiveEmpId = _selectedAttendanceMemberId ?? (teamMembers.isNotEmpty ? teamMembers.first.id : '');
    final selectedEmp = teamMembers.firstWhere(
      (e) => e.id == effectiveEmpId,
      orElse: () => teamMembers.isNotEmpty ? teamMembers.first : eco.currentEmployee,
    );

    final weekRecords = eco.getPast7DaysAttendanceForEmployee(selectedEmp.id);
    int daysPresent = 0;
    int totalMinutes = 0;
    int onTimeCount = 0;
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
        if (r.loginTime != '--:-- --') onTimeCount++;
      }
    }

    final totalDaysCount = weekRecords.length;
    final totalHoursStr = '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';
    final onTimeRateStr = daysPresent > 0 ? '${((onTimeCount / daysPresent) * 100).round()}%' : '0%';

    return LiquidGlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.schedule, color: AppColors.magentaPrimary, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Team Attendance',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            '1-Week Attendance Performance',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          Text(
            'Past 1-Week Attendance Performance (${selectedEmp.name})',
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          const Text(
            'SELECT TEAM MEMBER',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: effectiveEmpId,
                items: teamMembers.map((m) {
                  return DropdownMenuItem<String>(
                    value: m.id,
                    child: Text(
                      m.name,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedAttendanceMemberId = val);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _metricTile('Present', '$daysPresent/$totalDaysCount Days${tuesdayOvertimeCount > 0 ? " (+$tuesdayOvertimeCount OT)" : ""}', const Color(0xFF059669)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricTile('Total Hours', totalHoursStr, AppColors.magentaPrimary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _metricTile('On-Time', onTimeRateStr, const Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1-Week Table Headers & Content with Horizontal Scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: 520,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: Text('Date', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        Expanded(flex: 3, child: Text('Login Time', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text('Lunch Out', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text('Lunch In', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        Expanded(flex: 3, child: Text('Logout Time', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text('Net Hours', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                        Expanded(flex: 2, child: Text('Shift Status', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...weekRecords.map((r) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(r.dateLabel, style: const TextStyle(fontSize: 10, color: AppColors.textDark, fontWeight: FontWeight.w600))),
                          Expanded(flex: 3, child: Text(r.loginTime, style: const TextStyle(fontSize: 10, color: AppColors.textDark))),
                          Expanded(flex: 2, child: Text(r.lunchOutTime, style: const TextStyle(fontSize: 10, color: AppColors.textMuted))),
                          Expanded(flex: 2, child: Text(r.lunchInTime, style: const TextStyle(fontSize: 10, color: AppColors.textMuted))),
                          Expanded(flex: 3, child: Text(r.logoutTime, style: const TextStyle(fontSize: 10, color: AppColors.textDark))),
                          Expanded(flex: 2, child: Text(r.netHours, style: const TextStyle(fontSize: 10, color: AppColors.textDark))),
                          Expanded(flex: 2, child: Text(r.status, style: const TextStyle(fontSize: 10, color: AppColors.textDark))),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// 3. TL My Tasks Screen
class TlMyTasksScreen extends StatelessWidget {
  const TlMyTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TlSubpageScaffold(
      title: 'My Tasks',
      subtitle: 'Personal To-Dos & Operational Actions',
      body: PersonalTodoSectionWidget(
        title: 'Personal To-Dos',
        subtitle: 'Tasks & Follow-ups',
      ),
    );
  }
}

/// 4. TL Daily SOPs Screen
class TlDailySopsScreen extends StatelessWidget {
  const TlDailySopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final opsTasks = eco.operationsDeptTasks;

    return TlSubpageScaffold(
      title: 'Daily SOPs',
      subtitle: 'Daily Standard Operating Procedures',
      body: TlTeamTasksScreen._buildDeliverablesMonitor(context, eco, opsTasks),
    );
  }
}

/// 5. TL Team Directory Screen
class TlTeamDirectoryScreen extends StatelessWidget {
  const TlTeamDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final teamMembers = eco.employees.where((e) => e.dept == 'Online Department' || e.dept == 'Operations').toList();

    return TlSubpageScaffold(
      title: 'Team Directory',
      subtitle: '${teamMembers.length} Members in Online Department',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...teamMembers.map((emp) {
            final isAbsent = eco.isEmployeeAbsent(emp.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: LiquidGlassCard(
                borderRadius: 14,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isAbsent ? const Color(0xFFEF4444).withOpacity(0.15) : AppColors.magentaSubtle,
                      child: Text(
                        emp.initials,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isAbsent ? AppColors.ragRed : AppColors.magentaPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  emp.name,
                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAbsent ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isAbsent ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0),
                                  ),
                                ),
                                child: Text(
                                  isAbsent ? 'ABSENT' : 'ON DUTY',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isAbsent ? const Color(0xFFE11D48) : const Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            emp.straightCutDesignation,
                            style: const TextStyle(fontSize: 11, color: AppColors.magentaPrimary, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${emp.email} • ${emp.phone}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HrEmployeeInspectionScreen(employee: emp),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 6. TL Blocker Tickets Screen
class TlBlockerTicketsScreen extends StatelessWidget {
  const TlBlockerTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();

    return TlSubpageScaffold(
      title: 'Blocker Tickets',
      subtitle: 'Cross-Department Operational Blockers',
      body: CrossDeptBlockerSection(department: eco.currentEmployee.dept),
    );
  }
}

/// 7. TL Team Attendance Screen
class TlTeamAttendanceScreen extends StatelessWidget {
  const TlTeamAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TlAbsenteesScreen();
  }
}
