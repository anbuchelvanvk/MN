import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../../core/widgets/pillar_kit.dart';
import '../../models/employee_model.dart';
import '../../models/konar_tasks_catalog.dart';
import '../../providers/ecosystem_provider.dart';

/// What each kind of role is responsible for, in plain words.
class RoleGuide {
  final String label;
  final Color color;
  final IconData icon;
  final List<String> duties;
  const RoleGuide(this.label, this.color, this.icon, this.duties);

  static RoleGuide of(Employee e, EcosystemProvider eco) {
    if (e.isCeo) {
      return const RoleGuide('CEO', Color(0xFFB45309), Icons.workspace_premium_rounded, [
        'Leads MN Jewel Park and every department',
        'Creates departments and sets everyone\'s role and access',
        'Final approval on leave, permissions and social causes',
        'Data Vault: backup, restore and reset',
      ]);
    }
    if (e.isHr && e.roleCode.toUpperCase() == 'AHR') {
      return const RoleGuide('Asst. HR', Color(0xFF0369A1), Icons.support_agent_rounded, [
        'Supports HR in the departments the CEO assigns',
        'Attendance sheet, grooming audits and password help',
        'Other HR tasks only when the CEO grants them',
      ]);
    }
    if (e.isHr) {
      return const RoleGuide('HR', Color(0xFF047857), Icons.badge_rounded, [
        'Hiring, relieving and staff records',
        'Attendance sheet, leave and permission approvals',
        'Grooming audits, password help and announcements',
        'Works in the departments the CEO assigns',
      ]);
    }
    if (e.isExternalSupport) {
      return const RoleGuide('Outside support', Color(0xFF6D28D9), Icons.public_rounded, [
        'Supports the online team from outside MN Jewel Park',
        'Works on assigned tasks and Konar Book milestones',
        'No attendance or grooming',
      ]);
    }
    if (e.isTeamLead) {
      return const RoleGuide('Team Lead', Color(0xFF1D4ED8), Icons.shield_rounded, [
        'Leads one team: assigns tasks, nudges and announces',
        'Reviews the team\'s attendance and daily work',
        'Chooses one Assistant TL from the team',
        'Keeps the team\'s Konar Book up to date',
      ]);
    }
    if (eco.isAssistantLead(e.id)) {
      return const RoleGuide('Assistant TL', Color(0xFFBE185D), Icons.military_tech_rounded, [
        'Helps the team lead run the team',
        'Daily work and tasks of their own role',
      ]);
    }
    return const RoleGuide('Employee', Color(0xFFE11D48), Icons.person_rounded, [
      'Daily tasks and SOPs of their role',
      'Attendance, grooming and the four pillars',
    ]);
  }
}

/// "Roles" tab: the CEO sees everyone, HR the departments granted to them,
/// a team lead their team, and staff their own role.
class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  String _query = '';

  List<Employee> _people(EcosystemProvider eco) {
    final me = eco.currentEmployee;
    final isCeo = eco.isCeo || eco.activeRole.toLowerCase() == 'ceo';
    if (isCeo) return eco.employees;
    if (eco.isHr || eco.activeRole.toLowerCase() == 'hr') {
      return {me, ...eco.employeesInMyScope}.toList();
    }
    if (me.isTeamLead) return [me, ...eco.myTeamMembers];
    return [me];
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final me = eco.currentEmployee;
    final isCeo = eco.isCeo || eco.activeRole.toLowerCase() == 'ceo';
    var people = _people(eco);
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      people = people
          .where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.role.toLowerCase().contains(q) ||
              e.dept.toLowerCase().contains(q))
          .toList();
    }
    // Group by team / department
    final groups = <String, List<Employee>>{};
    for (final e in people) {
      final key = e.isCeo || e.isHr
          ? Employee.administrationDept
          : (eco.teamKeyOf(e) == 'online' ? (e.isExternalSupport ? 'Outside support' : 'Online Department') : e.dept);
      groups.putIfAbsent(key, () => []).add(e);
    }
    for (final list in groups.values) {
      list.sort((a, b) {
        int rank(Employee x) => x.isCeo ? 0 : (x.isHr ? 1 : (x.isTeamLead ? 2 : (eco.isAssistantLead(x.id) ? 3 : 4)));
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : a.name.compareTo(b.name);
      });
    }
    final order = groups.keys.toList()
      ..sort((a, b) {
        int w(String k) => k == Employee.administrationDept ? 0 : (k == 'Online Department' ? 1 : (k == 'Outside support' ? 3 : 2));
        final c = w(a).compareTo(w(b));
        return c != 0 ? c : a.compareTo(b);
      });

    final subtitle = isCeo
        ? 'Everyone · ${eco.employees.length} people'
        : (me.isTeamLead
            ? 'Your team · ${people.length} people'
            : ((eco.isHr) ? 'Your departments · ${people.length} people' : 'Your role'));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MnAppBar(title: 'Roles', subtitle: subtitle),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          if (people.length > 3 || _query.isNotEmpty) ...[
            TextField(
              key: const Key('roles_search'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search by name, role or department',
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
            const SizedBox(height: 14),
          ],
          if (people.isEmpty)
            const KitEmptyState(icon: Icons.person_search_rounded, title: 'No one found', message: 'Try another name.'),
          for (final g in order) ...[
            KitSectionHeader(g, subtitle: '${groups[g]!.length} ${groups[g]!.length == 1 ? 'person' : 'people'}'),
            const SizedBox(height: 10),
            for (final e in groups[g]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RoleCard(employee: e, isMe: e.id == me.id, expandedByDefault: people.length == 1),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final Employee employee;
  final bool isMe;
  final bool expandedByDefault;
  const _RoleCard({required this.employee, required this.isMe, required this.expandedByDefault});

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  late bool _open = widget.expandedByDefault;

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final e = widget.employee;
    final guide = RoleGuide.of(e, eco);
    final code = KonarTaskCatalog.resolveRoleCode(e.role, e.email, e.id, e.dept);
    final daily = KonarTaskCatalog.getStandardTasksForEmployee(e.id, code, e.name, e.role, e.dept)
        .map((t) => t.title)
        .toSet()
        .toList();
    final p = e.permissions;
    final perks = <String>[
      if (e.isHr || e.isCeo) ...[
        if (p.canHireStaff || e.isCeo) 'Hire staff',
        if (p.canRelieveStaff || e.isCeo) 'Relieve staff',
        if (p.canApproveLeave || e.isCeo) 'Approve leave',
        if (p.canManageAttendance || e.isCeo) 'Attendance',
        if (p.canAuditGrooming || e.isCeo) 'Grooming',
        if (p.canSendAnnouncements || e.isCeo) 'Announcements',
        if (p.canResetPasswords || e.isCeo) 'Password help',
        if (p.canApproveSocialCauses || e.isCeo) 'Social causes',
      ],
      if (p.canAssignTasksToOthers && !e.isHr && !e.isCeo) 'Assign tasks',
      if (p.canManageOrders && !e.isCeo) 'Online orders',
    ];
    final access = e.isCeo
        ? 'All departments'
        : (e.isHr ? p.departmentAccess.map(Employee.normalizeDept).join(', ') : null);

    return KitCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      onTap: () => setState(() => _open = !_open),
      borderColor: widget.isMe ? AppColors.primary.withOpacity(0.35) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              EmployeeAvatar(avatar: e.avatar, initials: e.initials, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.isMe ? '${e.name} (you)' : e.name, style: kitTitle(15)),
                    Text(e.straightCutDesignation,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: kitBody(12.5)),
                    const SizedBox(height: 5),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      KitPill(guide.label, guide.color, icon: guide.icon),
                      if (eco.isAssistantLead(e.id) && guide.label != 'Assistant TL')
                        const KitPill('Assistant TL', Color(0xFFBE185D)),
                    ]),
                  ],
                ),
              ),
              Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.textMuted),
            ],
          ),
          if (_open) ...[
            const SizedBox(height: 12),
            Text('Responsibilities', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 4),
            for (final d in guide.duties) _bullet(d, guide.color),
            if (daily.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Daily tasks (${daily.length})',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 4),
              for (final t in daily.take(8)) _bullet(t, AppColors.textMuted, icon: Icons.task_alt_rounded),
              if (daily.length > 8)
                Text('+ ${daily.length - 8} more', style: kitBody(12)),
            ],
            if (perks.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Access', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final x in perks) KitPill(x, const Color(0xFF475569))]),
            ],
            if (access != null && access.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Departments: $access', style: kitBody(12)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _bullet(String text, Color color, {IconData icon = Icons.check_circle_rounded}) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 2), child: Icon(icon, size: 14, color: color)),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35))),
          ],
        ),
      );
}
