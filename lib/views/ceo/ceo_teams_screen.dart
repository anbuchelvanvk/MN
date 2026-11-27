import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../../core/widgets/pillar_kit.dart';
import '../../models/attendance_models.dart';
import '../../models/ecosystem_models.dart';
import '../../models/employee_model.dart';
import '../../models/task_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../hr/hr_employee_inspection_screen.dart';
import '../shell/role_hub_widgets.dart';

/// Live numbers for one department, worked out from what the app already
/// holds (it updates as soon as anything changes).
class DeptSnapshot {
  final String name;
  final List<Employee> members;
  final Employee? lead;
  final Employee? assistant;
  final AttendanceTally tally;
  final Map<String, TodayAttendance> today;
  final List<TaskItem> tasks;
  final List<Blocker> blockers;
  final int pendingRequests;
  final int causesThisMonth;
  final double causesAmount;
  final int ordersActive;
  final int ordersOverdue;
  final int mediaPending;
  final bool isOnline;

  DeptSnapshot._({
    required this.name,
    required this.members,
    required this.lead,
    required this.assistant,
    required this.tally,
    required this.today,
    required this.tasks,
    required this.blockers,
    required this.pendingRequests,
    required this.causesThisMonth,
    required this.causesAmount,
    required this.ordersActive,
    required this.ordersOverdue,
    required this.mediaPending,
    required this.isOnline,
  });

  int get done => tasks.where((t) => t.isCompleted).length;
  int get pending => tasks.where((t) => t.isPending).length;
  int get later => tasks.where((t) => t.isPostponed).length;
  double get completion => tasks.isEmpty ? 0 : done / tasks.length;
  List<Blocker> get activeBlockers => blockers.where((b) => b.status != 'resolved').toList();
  int get resolvedBlockers => blockers.where((b) => b.status == 'resolved').length;

  /// Who belongs to [dept]: Administration holds the CEO and HR; outside
  /// support has its own entry; everyone else goes by team.
  static List<Employee> membersOf(EcosystemProvider eco, String dept) {
    final key = EcosystemProvider.teamKey(dept);
    final isAdmin = Employee.normalizeDept(dept) == Employee.administrationDept;
    final isOutside = dept.toLowerCase().contains('external support');
    return eco.employees.where((e) {
      if (isAdmin) return e.isCeo || e.isHr || Employee.normalizeDept(e.dept) == Employee.administrationDept;
      if (e.isCeo || e.isHr) return false;
      if (isOutside) return e.isExternalSupport;
      if (e.isExternalSupport) return false;
      return eco.teamKeyOf(e) == key;
    }).toList()
      ..sort((a, b) {
        int rank(Employee x) => x.isCeo ? 0 : (x.isHr ? 1 : (x.isTeamLead ? 2 : (eco.isAssistantLead(x.id) ? 3 : 4)));
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
  }

  factory DeptSnapshot.of(EcosystemProvider eco, String dept) {
    final members = membersOf(eco, dept);
    final ids = members.map((e) => e.id).toSet();
    final now = DateTime.now();
    final isOnline = EcosystemProvider.isOnlineDept(dept);
    final tracked = members.where((m) => !m.isExternalSupport && !m.isCeo).toList();
    final causes = eco.socialCauses
        .where((c) => ids.contains(c.empId) && c.date.year == now.year && c.date.month == now.month)
        .toList();
    final pendingPerm = eco.allPendingPermissions.where((p) => ids.contains(p.empId)).length;
    final pendingLeave = eco.allPendingMedicalLeaves.where((l) => ids.contains(l.empId)).length;
    final orders = eco.onlineOrders.where((o) => ids.contains(o.handledByEmpId)).toList();
    return DeptSnapshot._(
      name: dept,
      members: members,
      lead: Employee.normalizeDept(dept) == Employee.administrationDept ? null : eco.teamLeadOf(dept),
      assistant: eco.assistantLeadOf(dept),
      tally: eco.tallyTodayAttendance(tracked),
      today: eco.todayAttendanceFor(tracked.map((e) => e.id)),
      tasks: eco.tasks.where((t) => ids.contains(t.empId)).toList(),
      blockers: eco.blockersForDepartment(dept),
      pendingRequests: pendingPerm + pendingLeave,
      causesThisMonth: causes.length,
      causesAmount: causes.where((c) => c.isApproved).fold(0.0, (s, c) => s + c.amountSpent),
      ordersActive: orders.where((o) => o.status == 'active' || o.status == 'overdue').length,
      ordersOverdue: orders.where((o) => o.status == 'overdue').length,
      mediaPending: eco.mediaAssets.where((m) => ids.contains(m.creatorId) && m.isPendingReview).length,
      isOnline: isOnline,
    );
  }
}

String _rupees(double v) =>
    '₹${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

String _attendanceHeadline(AttendanceTally t) {
  if (t.tracked == 0) return 'No attendance';
  if (t.weekOff == t.tracked) return 'Week off';
  if (t.notUpdatedYet) return 'Yet to update';
  return '${t.present}/${t.tracked} present';
}

Color _scoreColor(double v) =>
    v >= 0.8 ? const Color(0xFF059669) : (v >= 0.5 ? const Color(0xFFD97706) : const Color(0xFFDC2626));

/// CEO: every department in MN Family, with live numbers.
class CeoTeamsScreen extends StatelessWidget {
  const CeoTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final depts = eco.availableDepartments.toList()
      ..sort((a, b) {
        int w(String k) => Employee.normalizeDept(k) == Employee.administrationDept
            ? 0
            : (EcosystemProvider.isOnlineDept(k) ? 1 : (k.toLowerCase().contains('external') ? 3 : 2));
        final c = w(a).compareTo(w(b));
        return c != 0 ? c : a.compareTo(b);
      });
    final snaps = [for (final d in depts) DeptSnapshot.of(eco, d)];

    // Company totals (each person counted once).
    final allTasks = eco.tasks;
    final done = allTasks.where((t) => t.isCompleted).length;
    final completion = allTasks.isEmpty ? 0.0 : done / allTasks.length;
    final staff = eco.employees.where((e) => !e.isCeo && !e.isExternalSupport).toList();
    final tally = eco.tallyTodayAttendance(staff);
    final activeBlockers = eco.blockers.where((b) => b.status != 'resolved').length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MnAppBar(title: 'Teams', subtitle: '${depts.length} departments • live'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => eco.refreshAllData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _CompanySummary(
              completion: completion,
              done: done,
              total: allTasks.length,
              attendance: _attendanceHeadline(tally),
              activeBlockers: activeBlockers,
              pendingRequests: eco.allPendingPermissions.length + eco.allPendingMedicalLeaves.length,
            ),
            const SizedBox(height: 18),
            const KitSectionHeader('Departments', subtitle: 'Tap a department for its full picture'),
            const SizedBox(height: 10),
            for (final s in snaps)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DeptCard(
                  snap: s,
                  onTap: () => openHubScreen(context, DepartmentDashboardScreen(department: s.name)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompanySummary extends StatelessWidget {
  final double completion;
  final int done;
  final int total;
  final String attendance;
  final int activeBlockers;
  final int pendingRequests;
  const _CompanySummary({
    required this.completion,
    required this.done,
    required this.total,
    required this.attendance,
    required this.activeBlockers,
    required this.pendingRequests,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          KitRing(
            progress: completion,
            color: Colors.white,
            size: 84,
            stroke: 8,
            center: Text('${(completion * 100).round()}%',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MN Family today',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                _line(Icons.task_alt_rounded, '$done of $total tasks done'),
                _line(Icons.how_to_reg_rounded, attendance),
                _line(Icons.shield_rounded, '$activeBlockers open blocker${activeBlockers == 1 ? '' : 's'}'),
                _line(Icons.pending_actions_rounded,
                    '$pendingRequests leave / permission request${pendingRequests == 1 ? '' : 's'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFFFFD6E5)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFFFFE4EE))),
            ),
          ],
        ),
      );
}

class _DeptCard extends StatelessWidget {
  final DeptSnapshot snap;
  final VoidCallback onTap;
  const _DeptCard({required this.snap, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = snap;
    final color = _scoreColor(s.completion);
    return KitCard(
      key: Key('dept_card_${s.name}'),
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              KitRing(
                progress: s.completion,
                color: color,
                size: 52,
                stroke: 5,
                center: Text('${(s.completion * 100).round()}%', style: kitTitle(12.5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: kitTitle(15.5)),
                    Text(
                      [
                        '${s.members.length} ${s.members.length == 1 ? 'person' : 'people'}',
                        if (s.lead != null) 'TL ${s.lead!.name.split(' ').first}',
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kitBody(12.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              KitPill('${s.done}/${s.tasks.length} tasks', const Color(0xFF2563EB), icon: Icons.task_alt_rounded),
              KitPill(_attendanceHeadline(s.tally), const Color(0xFF059669), icon: Icons.how_to_reg_rounded),
              if (s.activeBlockers.isNotEmpty)
                KitPill('${s.activeBlockers.length} blocker${s.activeBlockers.length == 1 ? '' : 's'}',
                    const Color(0xFFDC2626), icon: Icons.shield_rounded),
              if (s.pendingRequests > 0)
                KitPill('${s.pendingRequests} request${s.pendingRequests == 1 ? '' : 's'}', const Color(0xFFD97706),
                    icon: Icons.pending_actions_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

/// Everything about one department, live.
class DepartmentDashboardScreen extends StatelessWidget {
  final String department;
  const DepartmentDashboardScreen({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final s = DeptSnapshot.of(eco, department);
    final color = _scoreColor(s.completion);

    Widget tile(IconData icon, String value, String label, Color c) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: c),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: kitValue(20)),
                ),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: kitBody(11.5)),
              ],
            ),
          ),
        );
    Widget row(List<Widget> tiles) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            for (var i = 0; i < tiles.length; i++) ...[if (i > 0) const SizedBox(width: 10), tiles[i]],
          ]),
        );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MnAppBar(title: department, subtitle: '${s.members.length} people • live'),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => eco.refreshAllData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // Overall performance
            KitCard(
              child: Row(
                children: [
                  KitRing(
                    progress: s.completion,
                    color: color,
                    size: 92,
                    center: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${(s.completion * 100).round()}%', style: kitValue(22).copyWith(color: color)),
                        Text('done', style: kitBody(11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overall performance', style: kitTitle(16)),
                        const SizedBox(height: 4),
                        Text('${s.done} of ${s.tasks.length} tasks done today', style: kitBody(13)),
                        if (s.lead != null) Text('Team lead: ${s.lead!.name}', style: kitBody(12.5)),
                        if (s.assistant != null) Text('Assistant TL: ${s.assistant!.name}', style: kitBody(12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const KitSectionHeader('Attendance today'),
            const SizedBox(height: 8),
            row([
              tile(Icons.how_to_reg_rounded, '${s.tally.present}', 'Present', TodayAttendance.present.color),
              tile(Icons.person_off_rounded, '${s.tally.absent}', 'Absent', TodayAttendance.absent.color),
              tile(Icons.hourglass_top_rounded, '${s.tally.yetToUpdate}', 'Yet to update',
                  TodayAttendance.yetToUpdate.color),
            ]),
            const SizedBox(height: 6),

            const KitSectionHeader('Tasks'),
            const SizedBox(height: 8),
            row([
              tile(Icons.task_alt_rounded, '${s.done}', 'Completed', const Color(0xFF059669)),
              tile(Icons.pending_actions_rounded, '${s.pending}', 'Pending', const Color(0xFFD97706)),
              tile(Icons.schedule_rounded, '${s.later}', 'Later', const Color(0xFF6366F1)),
            ]),
            const SizedBox(height: 6),

            const KitSectionHeader('Blockers & requests'),
            const SizedBox(height: 8),
            row([
              tile(Icons.shield_rounded, '${s.activeBlockers.length}', 'Open blockers', const Color(0xFFDC2626)),
              tile(Icons.verified_rounded, '${s.resolvedBlockers}', 'Resolved', const Color(0xFF059669)),
              tile(Icons.event_busy_rounded, '${s.pendingRequests}', 'Requests', const Color(0xFFD97706)),
            ]),
            row([
              tile(Icons.volunteer_activism_rounded, '${s.causesThisMonth}', 'Good deeds',
                  const Color(0xFF0F766E)),
              tile(Icons.currency_rupee_rounded, _rupees(s.causesAmount), 'Deeds ₹', const Color(0xFFB7791F)),
              if (s.isOnline)
                tile(Icons.shopping_bag_rounded, '${s.ordersActive}',
                    s.ordersOverdue > 0 ? 'Orders • ${s.ordersOverdue} late' : 'Active orders', const Color(0xFFEA580C))
              else
                tile(Icons.groups_rounded, '${s.members.length}', 'People', AppColors.primary),
            ]),
            if (s.isOnline)
              row([
                tile(Icons.video_collection_rounded, '${s.mediaPending}', 'Media to review',
                    const Color(0xFF9D174D)),
                tile(Icons.person_outline_rounded, '${s.members.length}', 'People', AppColors.primary),
              ]),

            if (s.activeBlockers.isNotEmpty) ...[
              const SizedBox(height: 6),
              const KitSectionHeader('Open blockers'),
              const SizedBox(height: 8),
              for (final b in s.activeBlockers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: KitCard(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('${b.raisedByDept} → ${b.blockingDept}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: kitTitle(13.5)),
                            ),
                            KitPill(b.isOverdue ? 'Late' : b.severity,
                                b.isOverdue ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(b.issue, style: kitBody(13)),
                        Text('Raised by ${b.raisedByName} • ${b.time} • due ${b.slaDue}', style: kitBody(11.5)),
                      ],
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 6),
            KitSectionHeader('People (${s.members.length})', subtitle: 'Tap someone for their full record'),
            const SizedBox(height: 8),
            if (s.members.isEmpty)
              const KitEmptyState(
                icon: Icons.group_off_rounded,
                title: 'No one here yet',
                message: 'People added to this department will show here.',
              ),
            for (final m in s.members)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MemberRow(
                  employee: m,
                  attendance: s.today[m.id],
                  isAssistant: eco.isAssistantLead(m.id),
                  tasks: s.tasks.where((t) => t.empId == m.id).toList(),
                  onTap: () => openHubScreen(context, HrEmployeeInspectionScreen(employee: m)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final Employee employee;
  final TodayAttendance? attendance;
  final bool isAssistant;
  final List<TaskItem> tasks;
  final VoidCallback onTap;
  const _MemberRow({
    required this.employee,
    required this.attendance,
    required this.isAssistant,
    required this.tasks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.isCompleted).length;
    final ratio = tasks.isEmpty ? 0.0 : done / tasks.length;
    final status = employee.isExternalSupport
        ? ('Outside support', const Color(0xFF6D28D9))
        : (employee.isCeo
            ? ('CEO', const Color(0xFFB45309))
            : ((attendance ?? TodayAttendance.notTracked).label, (attendance ?? TodayAttendance.notTracked).color));
    return KitCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          EmployeeAvatar(avatar: employee.avatar, initials: employee.initials, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: kitTitle(14)),
                Text(employee.straightCutDesignation,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: kitBody(12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: KitBar(progress: ratio, color: _scoreColor(ratio), height: 6)),
                    const SizedBox(width: 8),
                    Text('$done/${tasks.length}', style: kitTitle(12)),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  KitPill(status.$1, status.$2),
                  if (employee.isTeamLead) const KitPill('Team Lead', Color(0xFF1D4ED8)),
                  if (isAssistant) const KitPill('Assistant TL', Color(0xFFBE185D)),
                ]),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
