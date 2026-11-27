import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/assign_tasks_to_others_modal.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../../core/widgets/pillar_kit.dart';
import '../../models/employee_model.dart';
import '../../models/konar_tasks_catalog.dart';
import '../../providers/ecosystem_provider.dart';
import '../ceo/ceo_subpages.dart';
import '../dept_head/dept_head_subpages.dart';
import '../hr/hr_employee_inspection_screen.dart';
import '../hr/hr_management_widgets.dart';
import '../hr/hr_password_requests_screen.dart';
import '../hr/hr_portal_subpages.dart';
import '../orders/online_orders_handler_screen.dart';
import 'role_hub_widgets.dart';

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
    final viewerIsCeo = eco.isCeo || eco.activeRole.toLowerCase() == 'ceo';
    final me = eco.currentEmployee;
    // Each access chip opens the page for that job. A chip is only tappable
    // when the person looking at the card can use that page too.
    VoidCallback? go(bool Function(RolePermissions) perk, Widget Function() page) =>
        eco.hasPerk(perk) ? () => openHubScreen(context, page()) : null;
    final perks = <(String, VoidCallback?)>[
      if (e.isHr || e.isCeo) ...[
        if (p.canHireStaff || e.isCeo) ('Hire staff', go((x) => x.canHireStaff, () => const HrStaffDirectoryScreen())),
        if (p.canRelieveStaff || e.isCeo)
          ('Relieve staff', go((x) => x.canRelieveStaff, () => const HrStaffDirectoryScreen())),
        if (p.canApproveLeave || e.isCeo)
          ('Approve leave',
              go((x) => x.canApproveLeave, () => viewerIsCeo ? const CeoAttendanceScreen() : const HrAttendanceScreen())),
        if (p.canManageAttendance || e.isCeo)
          ('Attendance',
              go((x) => x.canManageAttendance,
                  () => viewerIsCeo ? const CeoAttendanceScreen() : const HrAttendanceScreen())),
        if (p.canAuditGrooming || e.isCeo) ('Grooming', go((x) => x.canAuditGrooming, () => const HrGroomingAuditScreen())),
        if (p.canSendAnnouncements || e.isCeo)
          ('Announcements',
              go(
                  (x) => x.canSendAnnouncements,
                  () => HubSectionPage(
                        title: 'Announcement',
                        subtitle: 'Send a notice to all staff',
                        child: HrBroadcastSection(
                          senderName: viewerIsCeo ? me.name : '${me.name} (HR)',
                          senderRole: viewerIsCeo ? me.role : 'HR Manager',
                        ),
                      ))),
        if (p.canResetPasswords || e.isCeo)
          ('Password help', go((x) => x.canResetPasswords, () => const HrPasswordRequestsScreen())),
        if (p.canApproveSocialCauses || e.isCeo)
          ('Social causes',
              go((x) => x.canApproveSocialCauses,
                  () => viewerIsCeo ? const CeoSocialCausesScreen() : const HrSocialCausesScreen())),
      ],
      if (p.canAssignTasksToOthers && !e.isHr && !e.isCeo)
        ('Assign tasks',
            eco.hasPerk((x) => x.canAssignTasksToOthers) || me.isTeamLead
                ? () => AssignTasksToOthersModal.show(context)
                : null),
      if (p.canManageOrders && !e.isCeo)
        ('Online orders', go((x) => x.canManageOrders, () => const OnlineOrdersHandlerScreen())),
    ];
    // "+ N more" / the task heading opens that person's tasks: your own list
    // for you, the staff inspection page for someone you look after.
    final VoidCallback openTasks = widget.isMe
        ? () => openHubScreen(context, const TlMyTasksScreen())
        : () => openHubScreen(context, HrEmployeeInspectionScreen(employee: e));
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
              InkWell(
                onTap: openTasks,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Daily tasks (${daily.length})',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    ),
                    Text('Open', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              for (final t in daily.take(8)) _bullet(t, AppColors.textMuted, icon: Icons.task_alt_rounded),
              if (daily.length > 8)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _ActionChip(
                      key: Key('roles_more_tasks_${e.id}'),
                      label: '+ ${daily.length - 8} more tasks',
                      icon: Icons.arrow_forward_rounded,
                      onTap: openTasks,
                    ),
                  ),
                ),
            ],
            if (perks.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Access', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final x in perks)
                  _ActionChip(
                    label: x.$1,
                    icon: x.$2 == null ? null : Icons.arrow_forward_rounded,
                    onTap: x.$2,
                  ),
              ]),
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

/// A pill that opens a page when tapped (grey when the viewer cannot open it).
class _ActionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const _ActionChip({super.key, required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = enabled ? AppColors.primary : const Color(0xFF475569);
    return Material(
      color: color.withOpacity(enabled ? 0.10 : 0.08),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              if (enabled && icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 14, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
