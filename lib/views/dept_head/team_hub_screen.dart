import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/assign_tasks_to_others_modal.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/widgets/export_audit_modal.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../../models/attendance_models.dart';
import '../../models/employee_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../hr/hr_employee_inspection_screen.dart';
import '../konar/konar_book_detail_screen.dart';
import '../media/creative_media_review_board_screen.dart';
import '../notes/personal_notes_screen.dart';
import '../orders/online_orders_handler_screen.dart';
import 'dept_head_portal_screen.dart';
import 'dept_head_subpages.dart';
import 'monthly_scorecard_screen.dart';

/// The team lead's "My Team" tab: who is on the team today, what needs
/// attention, and every team tool in one place.
class TeamHubScreen extends StatelessWidget {
  const TeamHubScreen({super.key});

  void _open(BuildContext context, Widget screen) {
    final eco = context.read<EcosystemProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(value: eco, child: screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final me = eco.currentEmployee;
    final dept = me.dept.isNotEmpty ? me.dept : 'Department';
    final members = eco.myTeamMembers;
    final staff = members.where((m) => !m.isExternalSupport).toList();
    final outside = members.where((m) => m.isExternalSupport).toList();
    final today = eco.todayAttendanceFor(staff.map((m) => m.id));
    final tally = eco.tallyTodayAttendance(staff);
    final absent = staff.where((m) => today[m.id] == TodayAttendance.absent).toList();
    final String presentValue;
    final String presentLabel;
    final Color presentColor;
    if (tally.tracked == 0) {
      presentValue = '–';
      presentLabel = 'Attendance';
      presentColor = TodayAttendance.notTracked.color;
    } else if (tally.weekOff == tally.tracked) {
      presentValue = '–';
      presentLabel = 'Week off';
      presentColor = TodayAttendance.weekOff.color;
    } else if (tally.notUpdatedYet) {
      presentValue = '–';
      presentLabel = 'Yet to update';
      presentColor = TodayAttendance.yetToUpdate.color;
    } else {
      presentValue = '${tally.present}/${tally.tracked}';
      presentLabel = tally.yetToUpdate > 0 ? 'Present • ${tally.yetToUpdate} pending' : 'Present';
      presentColor = TodayAttendance.present.color;
    }
    final absenteesHint = absent.isNotEmpty
        ? '${absent.length} absent'
        : (tally.yetToUpdate > 0 ? 'Yet to update' : (tally.tracked == 0 ? 'No attendance' : 'All present'));
    final teamTasks = eco.operationsDeptTasks;
    final openTasks = teamTasks.where((t) => t.isPending).length;
    final postponed = teamTasks.where((t) => t.isPostponed).length;
    final isOnline = dept.toLowerCase().contains('online');

    final tools = <_Tool>[
      _Tool(Icons.assignment_rounded, 'Team Tasks', '$openTasks open', const Color(0xFFE11D48),
          () => _open(context, const TlTeamTasksScreen())),
      _Tool(Icons.schedule_rounded, 'Team Attendance', 'Daily status', const Color(0xFF059669),
          () => _open(context, const TlTeamAttendanceScreen())),
      _Tool(Icons.person_off_rounded, 'Absentees', absenteesHint,
          const Color(0xFFDC2626), () => _open(context, const TlAbsenteesScreen())),
      _Tool(Icons.shield_rounded, 'Blocker Tickets', 'Escalations', const Color(0xFFD97706),
          () => _open(context, const TlBlockerTicketsScreen())),
      _Tool(Icons.task_alt_rounded, 'My Tasks', 'Your own list', const Color(0xFFBE185D),
          () => _open(context, const TlMyTasksScreen())),
      _Tool(Icons.assessment_rounded, 'Scorecard', 'Monthly review', const Color(0xFF2563EB),
          () => _open(context, const MonthlyScorecardScreen())),
      _Tool(Icons.video_collection_rounded, 'Media Review',
          eco.pendingMediaApprovalsCount > 0 ? '${eco.pendingMediaApprovalsCount} waiting' : 'Reels & shoots',
          const Color(0xFF9D174D), () => _open(context, const CreativeMediaReviewBoardScreen())),
      _Tool(Icons.menu_book_rounded, 'Konar Book', 'Team handbook', const Color(0xFF881337),
          () => _open(context, KonarBookDetailScreen(department: me.dept.isNotEmpty ? me.dept : 'Online Department'))),
      if (isOnline)
        _Tool(Icons.shopping_bag_rounded, 'Online Orders', 'Track & dispatch', const Color(0xFFEA580C),
            () => _open(context, const OnlineOrdersHandlerScreen())),
      _Tool(Icons.lock_rounded, 'Personal Notes', 'Private to you', const Color(0xFF5B5068),
          () => _open(context, const PersonalNotesScreen())),
      _Tool(Icons.file_download_rounded, 'Team Report', 'Export audit', const Color(0xFF0F766E),
          () => ExportAuditModal.showTeamLead(context)),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MnAppBar(
        title: 'My Team',
        subtitle: outside.isEmpty
            ? '$dept • ${staff.length} staff'
            : '$dept • ${staff.length} staff • ${outside.length} outside',
        actions: [
          MnHeaderPill(
            icon: Icons.campaign_rounded,
            label: 'Nudge',
            onTap: () => DeptHeadPortalScreen.showNudgeTeam(context, eco),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => eco.refreshAllData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // Today at a glance
            Row(
              children: [
                _StatCard(
                  icon: Icons.groups_rounded,
                  value: '${staff.length}',
                  label: 'Staff',
                  color: AppColors.primary,
                  onTap: () => _open(context, const TlTeamDirectoryScreen()),
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.how_to_reg_rounded,
                  value: presentValue,
                  label: presentLabel,
                  color: presentColor,
                  onTap: () => _open(context, const TlAbsenteesScreen()),
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.pending_actions_rounded,
                  value: '$openTasks',
                  label: postponed > 0 ? 'Open • $postponed later' : 'Open tasks',
                  color: const Color(0xFFD97706),
                  onTap: () => _open(context, const TlTeamTasksScreen()),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _AssistantLeadRow(
              assistant: eco.assistantLeadOf(me.dept),
              canChange: me.isTeamLead || eco.isCeo || eco.isHr,
              onChange: () => _pickAssistantLead(context, eco, staff),
            ),
            const SizedBox(height: 14),

            if (absent.isNotEmpty) ...[
              _AbsentBanner(
                count: absent.length,
                names: absent.map((e) => e.name.split(' ').first).take(3).join(', '),
                onResolve: () => AssignTasksToOthersModal.show(context),
                onView: () => _open(context, const TlAbsenteesScreen()),
              ),
              const SizedBox(height: 14),
            ],

            // Main actions
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => AssignTasksToOthersModal.show(context),
                    icon: const Icon(Icons.assignment_ind_rounded, size: 18),
                    label: const Text('Assign tasks'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => DeptHeadPortalScreen.showNudgeTeam(context, eco),
                    icon: const Icon(Icons.campaign_rounded, size: 18),
                    label: const Text('Nudge team'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            const MnSectionTitle('Team tools'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final w = (c.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [for (final t in tools) SizedBox(width: w, child: _ToolTile(tool: t))],
                );
              },
            ),
            const SizedBox(height: 24),

            MnSectionTitle(
              'Team members (${staff.length})',
              actionLabel: members.isEmpty ? null : 'Directory',
              onAction: () => _open(context, const TlTeamDirectoryScreen()),
            ),
            const SizedBox(height: 10),
            if (staff.isEmpty)
              const _EmptyTeam()
            else
              for (final m in staff)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MemberCard(
                    employee: m,
                    state: today[m.id] ?? TodayAttendance.notTracked,
                    isAssistant: eco.isAssistantLead(m.id),
                    openTasks: eco.tasks.where((t) => t.empId == m.id && t.isPending).length,
                    onTap: () => _open(context, HrEmployeeInspectionScreen(employee: m)),
                  ),
                ),
            if (outside.isNotEmpty) ...[
              const SizedBox(height: 14),
              MnSectionTitle('Outside support (${outside.length})'),
              const SizedBox(height: 6),
              const OutsideSupportNote(),
              const SizedBox(height: 10),
              for (final m in outside)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MemberCard(
                    employee: m,
                    state: TodayAttendance.notTracked,
                    outsideSupport: true,
                    openTasks: eco.tasks.where((t) => t.empId == m.id && t.isPending).length,
                    onTap: () => _open(context, HrEmployeeInspectionScreen(employee: m)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet: the TL picks one Assistant TL from the team (or none).
Future<void> _pickAssistantLead(BuildContext context, EcosystemProvider eco, List<Employee> staff) async {
  final current = eco.assistantLeadOf(eco.currentEmployee.dept)?.id;
  final picked = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Choose Assistant TL',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text('One person from your team helps you lead. You can change this any time.',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            if (staff.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No team members yet.', style: GoogleFonts.outfit(color: AppColors.textMuted)),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final m in staff)
                    ListTile(
                      key: Key('atl_${m.id}'),
                      leading: EmployeeAvatar(avatar: m.avatar, initials: m.initials, size: 38),
                      title: Text(m.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                      subtitle: Text(m.straightCutDesignation, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Icon(
                        m.id == current ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: m.id == current ? AppColors.primary : const Color(0xFFCBB8C4),
                      ),
                      onTap: () => Navigator.pop(ctx, m.id),
                    ),
                ],
              ),
            ),
            if (current != null)
              TextButton.icon(
                icon: const Icon(Icons.person_remove_rounded),
                label: const Text('No Assistant TL'),
                onPressed: () => Navigator.pop(ctx, ''),
              ),
          ],
        ),
      ),
    ),
  );
  if (picked == null || picked == current) return;
  final err = await eco.setAssistantLead(picked.isEmpty ? null : picked);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(err ??
        (picked.isEmpty
            ? 'Assistant TL removed.'
            : '${staff.firstWhere((e) => e.id == picked).name} is now Assistant TL.')),
  ));
}

class _AssistantLeadRow extends StatelessWidget {
  final Employee? assistant;
  final bool canChange;
  final VoidCallback onChange;
  const _AssistantLeadRow({required this.assistant, required this.canChange, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: canChange ? onChange : null,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.military_tech_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assistant TL',
                        style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    Text(assistant?.name ?? 'Not chosen',
                        key: const Key('atl_name'),
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  ],
                ),
              ),
              if (canChange)
                TextButton(
                  key: const Key('atl_change'),
                  onPressed: onChange,
                  child: Text(assistant == null ? 'Choose' : 'Change'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tool {
  final IconData icon;
  final String label;
  final String hint;
  final Color color;
  final VoidCallback onTap;
  const _Tool(this.icon, this.label, this.hint, this.color, this.onTap);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
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

class _AbsentBanner extends StatelessWidget {
  final int count;
  final String names;
  final VoidCallback onResolve;
  final VoidCallback onView;
  const _AbsentBanner({
    required this.count,
    required this.names,
    required this.onResolve,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onView,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.ragRed, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1 ? '1 person absent today' : '$count people absent today',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '$names • reassign their tasks',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(onPressed: onResolve, child: const Text('Reassign')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final _Tool tool;
  const _ToolTile({required this.tool});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: tool.onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tool.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tool.icon, size: 20, color: tool.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      tool.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Employee employee;
  final TodayAttendance state;
  final bool outsideSupport;
  final bool isAssistant;
  final int openTasks;
  final VoidCallback onTap;
  const _MemberCard({
    required this.employee,
    required this.state,
    required this.openTasks,
    required this.onTap,
    this.outsideSupport = false,
    this.isAssistant = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = outsideSupport ? const Color(0xFF6D28D9) : state.color;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  EmployeeAvatar(avatar: employee.avatar, initials: employee.initials, size: 46),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      employee.straightCutDesignation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(outsideSupport ? 'Outside support' : state.label, statusColor),
                        if (isAssistant) _chip('Assistant TL', AppColors.primary),
                        _chip(openTasks == 1 ? '1 open task' : '$openTasks open tasks', AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBB8C4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      );
}

class _EmptyTeam extends StatelessWidget {
  const _EmptyTeam();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(Icons.group_off_rounded, size: 36, color: Color(0xFFCBB8C4)),
          const SizedBox(height: 8),
          Text(
            'No team members yet',
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          Text(
            'Members of your department will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Explains who "outside support" people are, wherever they are listed.
class OutsideSupportNote extends StatelessWidget {
  const OutsideSupportNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.public_rounded, size: 18, color: Color(0xFF6D28D9)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'They support the online team from outside. They are not MN Jewel Park staff, so they have no attendance or grooming, only tasks.',
              style: GoogleFonts.outfit(fontSize: 12, height: 1.35, color: const Color(0xFF4C1D95)),
            ),
          ),
        ],
      ),
    );
  }
}
