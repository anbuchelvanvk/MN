import '../../core/widgets/export_audit_modal.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../core/widgets/cross_dept_blocker_section.dart';
import '../../core/widgets/assign_tasks_to_others_modal.dart';
import '../../core/widgets/task_action_dialogs.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/role_app_bar.dart';
import '../../core/widgets/personal_todo_section.dart';
import '../../models/attendance_models.dart';
import '../../models/employee_model.dart';
import '../../models/task_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../auth/pillars_popup_dialog.dart';
import '../pillars/attendance_pillar_screen.dart';
import '../../core/widgets/emergency_permission_modal.dart';
import '../../core/widgets/emergency_medical_leave_modal.dart';
import '../employee/employee_profile_screen.dart';
import '../orders/online_orders_handler_screen.dart';

class DeptHeadPortalScreen extends StatefulWidget {
  const DeptHeadPortalScreen({super.key});

  @override
  State<DeptHeadPortalScreen> createState() => _DeptHeadPortalScreenState();
}

class _DeptHeadPortalScreenState extends State<DeptHeadPortalScreen> {
  int _activeTab = 0; // 0: Deliverables, 1: Absentee & Shift Hub, 2: SOPs, 3: Team Directory, 6: Team Attendance
  String? _selectedAttendanceMemberId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PillarsPopupDialog.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final opsTasks = eco.operationsDeptTasks;
    final openCount = opsTasks.where((t) => t.isPending).length;
    final postponedCount = opsTasks.where((t) => t.isPostponed).length;
    final teamMembers = eco.employees.where((e) {
      final isCeo = e.roleType == 'ceo' || e.role.toLowerCase().contains('ceo') || e.id.toUpperCase().contains('CEO');
      final isHr = e.roleType == 'hr' || e.role.toLowerCase().contains('hr') || e.id.toUpperCase().contains('HR');
      return !isCeo && !isHr;
    }).toList();
    final teamAbsentees = teamMembers.where((m) => eco.isEmployeeAbsent(m.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: RoleAppBar(
        roleName: 'Team Lead',
        userName: '${eco.currentEmployee.name} (Team Lead)',
        roleColor: AppColors.statusBlue,
        roleIcon: Icons.shield_outlined,
        onExportPressed: () => ExportAuditModal.showTeamLead(context),
      ),
      body: RefreshIndicator(
        color: AppColors.sandGold,
        backgroundColor: AppColors.burgundyCard,
        onRefresh: () => eco.refreshAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lead Hero Card with Profile Navigation
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: LiquidGlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          eco.currentEmployee.initials,
                          style: const TextStyle(
                            fontFamily: 'Cinzel',
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
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
                                  eco.currentEmployee.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppColors.sandGold.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.sandGold.withOpacity(0.35), width: 0.8),
                                ),
                                child: Text(
                                  'ID: ${eco.currentEmployee.id}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandGold,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Team Lead',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.group, size: 10, color: Color(0xFF94A3B8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${eco.employees.where((e) => e.roleType != 'ceo' && e.roleType != 'hr').length} Members',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
                                    ),
                                  ],
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
            ),
            const SizedBox(height: 12),

            // 3 KPIs
            Row(
              children: [
                LiquidMetricCard(
                  label: 'Active Tasks',
                  value: '$openCount',
                  icon: Icons.checklist,
                  color: AppColors.goldPrimary,
                  onTap: () => setState(() => _activeTab = 0),
                ),
                const SizedBox(width: 8),
                LiquidMetricCard(
                  label: 'Postponed',
                  value: '$postponedCount',
                  icon: Icons.history_toggle_off,
                  color: AppColors.ragRed,
                  onTap: () => setState(() => _activeTab = 0),
                ),
                const SizedBox(width: 8),
                LiquidMetricCard(
                  label: 'Absent Staff',
                  value: '${teamAbsentees.length} Absent',
                  icon: Icons.person_off_outlined,
                  color: teamAbsentees.isEmpty ? AppColors.ragGreen : AppColors.ragRed,
                  onTap: () => setState(() => _activeTab = 1),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Absentee Alert Banner (Visible when any team member is absent)
            if (teamAbsentees.isNotEmpty) ...[
              LiquidGlassCard(
                borderRadius: 14,
                padding: const EdgeInsets.all(12),
                backgroundColor: AppColors.ragRed.withOpacity(0.15),
                borderColor: AppColors.ragRed.withOpacity(0.4),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.ragRed, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Absentee Notice (${teamAbsentees.length})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Reallocate SOP Tasks',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFFFCA5A5)),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => AssignTasksToOthersModal.show(context),
                      child: const Text('Resolve', style: TextStyle(color: AppColors.goldBright, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Primary Action Buttons
            Row(
              children: [
                Expanded(
                  child: LiquidGlassButton(
                    label: 'Assign Tasks to Others',
                    icon: Icons.assignment_ind_outlined,
                    onPressed: () => AssignTasksToOthersModal.show(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LiquidGlassButton(
                    label: 'Nudge Team',
                    icon: Icons.campaign_outlined,
                    isPrimary: false,
                    onPressed: () => _nudgeTeam(context, eco),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Online Orders Handler Quick Access
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnlineOrdersHandlerScreen()),
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF59E0B).withOpacity(0.18),
                      const Color(0xFFB45309).withOpacity(0.10),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4), width: 1.1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const FaIcon(FontAwesomeIcons.bagShopping, color: Color(0xFFF59E0B), size: 14),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Online Orders',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Workflow Checklist',
                            style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('Open', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black)),
                          SizedBox(width: 3),
                          Icon(Icons.arrow_forward_ios, size: 9, color: Colors.black),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // User Requirement: Overdue for the online order red pop-up / alert banner
            if (eco.overdueOnlineOrders.isNotEmpty) ...[
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnlineOrdersHandlerScreen()),
                ),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.ragRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.ragRed, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.ragRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overdue for Online Orders (${eco.overdueOnlineOrders.length} Orders)',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SLA due dates passed for ${eco.overdueOnlineOrders.map((o) => "#${o.orderId} (${o.brand})").join(", ")}. Tap to review & reassign.',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFFFFCDD2)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white70),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Segmented Tabs
            SingleChildScrollView(
              key: const ValueKey('dept_head_tabs_scroll'),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _tabChip(0, 'Team Tasks'),
                  _tabChip(1, 'Absentees'),
                  _tabChip(2, 'My Tasks'),
                  _tabChip(3, 'Daily SOPs'),
                  _tabChip(4, 'Team'),
                  _tabChip(5, 'Blocker Tickets'),
                  _tabChip(6, 'Team Attendance'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Tab Content
            if (_activeTab == 0) ...[
              _buildDeliverablesMonitor(context, eco, opsTasks),
            ] else if (_activeTab == 1) ...[
              _buildAbsenteeAndShiftHub(context, eco, teamMembers, teamAbsentees),
            ] else if (_activeTab == 2) ...[
              const PersonalTodoSectionWidget(
                title: 'Personal To-Dos',
                subtitle: 'Tasks & Follow-ups',
              ),
            ] else if (_activeTab == 3) ...[
              _buildAllTasksList(context, eco, opsTasks),
            ] else if (_activeTab == 4) ...[
              _buildTeamDirectory(context, eco),
            ] else if (_activeTab == 5) ...[
              CrossDeptBlockerSection(department: eco.currentEmployee.dept),
            ] else ...[
              _buildTeamAttendanceSection(context, eco, teamMembers),
            ],
            const SizedBox(height: 16),

            // Logout Button with confirmation
            LogoutConfirmDialog.buildButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
  }

  Widget _tabChip(int index, String label) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.statusBlue : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.statusBlue : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliverablesMonitor(BuildContext context, EcosystemProvider eco, List<TaskItem> tasks) {
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

    // Group tasks by Employee to eliminate raw unsorted list
    final tasksByEmpId = <String, List<TaskItem>>{};
    for (final task in tasks) {
      tasksByEmpId.putIfAbsent(task.empId, () => []).add(task);
    }

    // Resolve employee objects and sort A to Z by Name (A, B, C to Z arrangement)
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Name-wise alphabetical arrangement (A to Z)',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.sandGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
              ),
              child: Text(
                '${sortedEmps.length} Staff • ${tasks.length} Tasks',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.sandGold),
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
                // Name-wise segregation header with Alphabet Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isAbsent ? const Color(0xFFEF4444).withOpacity(0.14) : AppColors.burgundyCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAbsent ? const Color(0xFFEF4444).withOpacity(0.4) : AppColors.sandGold.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAbsent ? const Color(0xFFEF4444) : AppColors.sandGold,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          firstLetter,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: isAbsent ? Colors.white : Colors.black,
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
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              '${emp.role} • ${emp.dept}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isAbsent ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.2),
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
                            color: isAbsent ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Employee Tasks Cards
                ...empTasks.map((task) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => TaskActionDialogs.handleTaskTap(context, eco, task),
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
                                        backgroundColor: isAbsent ? const Color(0xFFEF4444).withOpacity(0.3) : AppColors.statusBlue.withOpacity(0.3),
                                        child: Text(emp.initials, style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          emp.name,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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
                                fontWeight: FontWeight.w600,
                                color: task.isCompleted ? const Color(0xFF64748B) : const Color(0xFFE2E8F0),
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
                                Text('Due: ${task.due}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                                Text('• Priority: ${task.priority}', style: const TextStyle(fontSize: 10.5, color: AppColors.goldBright)),
                              ],
                            ),

                            if (task.proof != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.ragGreen.withOpacity(0.3)),
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
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFFFCA5A5)),
                                    ),
                                    Text(
                                      'Rescheduled to: ${task.postponeInfo!.postponedTo}',
                                      style: const TextStyle(fontSize: 9.5, color: Color(0xFFCBD5E1)),
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

  Widget _buildAllTasksList(BuildContext context, EcosystemProvider eco, List<TaskItem> tasks) {
    return Column(
      children: tasks.map((t) => _buildDeliverablesMonitor(context, eco, [t])).toList(),
    );
  }

  Widget _buildAbsenteeAndShiftHub(
    BuildContext context,
    EcosystemProvider eco,
    List<Employee> teamMembers,
    List<Employee> teamAbsentees,
  ) {
    return Column(
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
                        Icon(Icons.how_to_reg, color: AppColors.goldBright, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Team Attendance Roster',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.3),
              ),
              const SizedBox(height: 12),

              ...teamMembers.map((emp) {
                final summary = eco.allEmployeesTodayAttendance.firstWhere(
                  (s) => s.employeeId == emp.id,
                  orElse: () => EmployeeDailyAttendanceSummary(
                    employeeId: emp.id,
                    employeeName: emp.name,
                    department: emp.dept,
                    role: emp.role,
                    avatar: emp.avatar,
                    initials: emp.initials,
                    isPresent: false,
                    isOnTime: false,
                    isCurrentlyOnLunch: false,
                    isCurrentlyOnDuty: false,
                    lunchDurationMinutes: 0,
                    netWorkHours: 0,
                    status: DailyAttendanceStatus.absent,
                  ),
                );
                final isAbsent = eco.isEmployeeAbsent(emp.id);
                final badgeColor = isAbsent ? AppColors.ragRed : summary.statusBadgeColor;
                final badgeText = isAbsent ? 'Absent (No Login)' : summary.statusBadgeText;
                final punchInfo = summary.isPresent
                    ? 'In: ${summary.inTimeString}${summary.logoutPunch != null ? " • Out: ${summary.outTimeString}" : (summary.isCurrentlyOnLunch ? " • On Lunch" : " • On Duty")}'
                    : 'No attendance punch recorded today';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isAbsent ? AppColors.ragRed.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAbsent ? AppColors.ragRed.withOpacity(0.4) : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: isAbsent ? AppColors.ragRed : AppColors.statusBlue,
                        child: Text(emp.initials, style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    emp.name,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    eco.toggleEmployeeAbsentStatus(emp.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isAbsent ? '${emp.name} marked Present manually' : '${emp.name} marked Absent. SOPs ready for shift/reallocation.',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isAbsent ? AppColors.ragRed.withOpacity(0.2) : badgeColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isAbsent ? AppColors.ragRed : badgeColor,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isAbsent ? Icons.person_off : (summary.isCurrentlyOnLunch ? Icons.restaurant : Icons.check_circle_outline),
                                          size: 12,
                                          color: isAbsent ? AppColors.ragRed : badgeColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          badgeText,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: isAbsent ? AppColors.ragRed : badgeColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('${emp.role} • $punchInfo', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sandGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => EmergencyPermissionModal.show(context),
                      icon: const FaIcon(FontAwesomeIcons.clock, size: 13, color: Colors.black),
                      label: const Text('Permission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => EmergencyMedicalLeaveModal.show(context),
                      icon: const FaIcon(FontAwesomeIcons.kitMedical, size: 13, color: Colors.white),
                      label: const Text('Medical Leave', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AttendancePillarScreen()),
                  ),
                  icon: const Icon(Icons.launch, size: 12, color: AppColors.sandGold),
                  label: const Text('Open Full Biometric Ledger', style: TextStyle(fontSize: 10.5, color: AppColors.sandGold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Section: Team Attendance (1-Week Performance & History)
        _buildTeamAttendanceSection(context, eco, teamMembers),
        const SizedBox(height: 16),

        // Section 2: Absent Staff Work Reallocation Hub
        const Text(
          'Absentee Work Reallocation',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.goldBright),
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
                  Text('All Team Present', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 4),
                  Text(
                    'No Absentee Tasks',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ...(){
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
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.ragRed.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.ragRed.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.ragRed,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            letter,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Section $letter • Absent Staff (A to Z)',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.goldBright),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final pendingTasks = eco.tasks.where((t) => t.empId == absentEmp.id && t.status == 'pending').toList();
              widgets.add(
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: LiquidGlassCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(12),
                    borderColor: AppColors.ragRed.withOpacity(0.35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.ragRed,
                              child: Text(absentEmp.initials, style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(absentEmp.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('${absentEmp.role} (Absent Today)', style: const TextStyle(fontSize: 10.5, color: Color(0xFFFCA5A5))),
                            ],
                          ),
                        ),
                        LiquidGlassPill(label: '${pendingTasks.length} Pending Tasks', color: AppColors.ragRed),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 16),

                    if (pendingTasks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No pending SOP tasks for this member.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      ...pendingTasks.map((task) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  LiquidGlassPill(label: task.priority, color: AppColors.goldBright),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text('Due: ${task.due}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '• Category: ${task.category}',
                                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 2 Action Buttons: Shift Tomorrow & Reassign
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        eco.shiftTaskToNextDay(task.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Shifted "${task.title}" to tomorrow queue.'),
                                            backgroundColor: AppColors.statusBlue,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.schedule_send, size: 13, color: AppColors.goldBright),
                                      label: const Text(
                                        'Shift Tomorrow',
                                        style: TextStyle(fontSize: 10.5, color: AppColors.goldBright),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColors.goldPrimary, width: 0.8),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _openReassignDialog(context, eco, task, absentEmp.id),
                                      icon: const Icon(Icons.swap_horiz, size: 13, color: Colors.white),
                                      label: const Text(
                                        'Reassign',
                                        style: TextStyle(fontSize: 10.5, color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.statusBlue,
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              ),
            ),
          );
        }
        return widgets;
      }(),
        ],
      ],
    );
  }

  void _openReassignDialog(BuildContext context, EcosystemProvider eco, TaskItem task, String currentEmpId) {
    AssignTasksToOthersModal.show(context, defaultAbsentEmpId: currentEmpId);
  }

  Widget _buildTeamDirectory(BuildContext context, EcosystemProvider eco) {
    final teamMembers = eco.employees.where((e) => e.roleType != 'ceo' && e.roleType != 'hr').toList();

    return Column(
      children: teamMembers.map((m) {
        final isAbsent = eco.isEmployeeAbsent(m.id);
        return LiquidGlassCard(
          padding: const EdgeInsets.all(12),
          borderRadius: 14,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isAbsent ? AppColors.ragRed : AppColors.statusBlue,
                radius: 18,
                child: Text(m.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('${m.role} • ${m.dept}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 2),
                    Text('${m.mobile} • ${m.email}', style: const TextStyle(fontSize: 10, color: AppColors.goldLight)),
                  ],
                ),
              ),
              LiquidGlassPill(
                label: isAbsent ? 'ABSENT' : 'CONFIRMED',
                color: isAbsent ? AppColors.ragRed : AppColors.ragGreen,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _nudgeTeam(BuildContext context, EcosystemProvider eco) {
    final msgController = TextEditingController(
      text: 'Shift Alert: Please verify your attendance, complete pending deliverables, and upload task proofs before deadline.',
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: AppColors.burgundyCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.statusBlue, width: 1.2),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusBlue.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_outlined, color: AppColors.statusBlue, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Nudge Team Members',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send a quick reminder to all team members on duty.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1), height: 1.35),
                ),
                const SizedBox(height: 12),
                const Text('Message:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                const SizedBox(height: 6),
                TextField(
                  controller: msgController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.sandBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    'Upload Proofs Before 4PM',
                    'Morning Briefing Starting',
                    'Follow Up Hot Leads',
                  ].map((preset) {
                    return InkWell(
                      onTap: () => setDialogState(() => msgController.text = preset),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          preset,
                          style: const TextStyle(fontSize: 10, color: AppColors.sandLight),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final text = msgController.text.trim();
                  if (text.isNotEmpty) {
                    eco.postBroadcastNotification(
                      title: 'Team Lead Shift Nudge',
                      content: text,
                      senderRole: 'Team Lead',
                      senderName: eco.currentEmployee.name,
                    );
                    eco.sendRoutineNudge('Team Lead Nudge', text);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Shift nudge broadcasted to team members successfully!'),
                        backgroundColor: AppColors.ragGreen,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text('Send Nudge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openAssignTaskDialog(BuildContext context, EcosystemProvider eco) {
    // Strictly filter: Team Lead can ONLY assign to department subordinates / team members, NEVER to CEO or HR or self!
    final staffList = eco.employees.where((e) {
      final isCeo = e.roleType == 'ceo' ||
          e.role.toLowerCase().contains('ceo') ||
          e.role.toLowerCase().contains('managing director') ||
          e.id.toUpperCase().contains('CEO');
      final isHr = e.roleType == 'hr' ||
          e.role.toLowerCase().contains('hr') ||
          e.role.toLowerCase().contains('human resources') ||
          e.id.toUpperCase().contains('HR');
      final isSelf = e.id == eco.activeEmpId;
      return !isCeo && !isHr && !isSelf;
    }).toList();

    if (staffList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No subordinate staff members available for task assignment.'),
          backgroundColor: AppColors.ragRed,
        ),
      );
      return;
    }

    String? selectedEmp = staffList.first.id;
    final titleController = TextEditingController();
    String priority = 'Critical SLA';
    String due = '04:00 PM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final validSelectedEmp = staffList.any((e) => e.id == selectedEmp)
                ? selectedEmp
                : (staffList.isNotEmpty ? staffList.first.id : null);

            return Container(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Assign Department Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  const Text('Assign To Staff Member:', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: validSelectedEmp,
                    dropdownColor: AppColors.burgundySurface,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    items: staffList.map((e) {
                      return DropdownMenuItem(value: e.id, child: Text('${e.name} (${e.role})'));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setModalState(() => selectedEmp = v);
                    },
                  ),
                  const SizedBox(height: 10),

                  const Text('Task Title & Deliverable:', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Enter task description or SLA deliverable...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Priority SLA:', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: priority,
                              dropdownColor: AppColors.burgundySurface,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Critical SLA', child: Text('Critical SLA')),
                                DropdownMenuItem(value: 'High', child: Text('High')),
                                DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                              ],
                              onChanged: (v) {
                                if (v != null) setModalState(() => priority = v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Due Time:', style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
                            const SizedBox(height: 4),
                            TextFormField(
                              initialValue: due,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              ),
                              onChanged: (v) => due = v,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  LiquidGlassButton(
                    label: 'Dispatch Task to Member',
                    icon: Icons.send,
                    onPressed: () {
                      final targetId = validSelectedEmp;
                      if (targetId == null || titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select staff member and enter task description.')),
                        );
                        return;
                      }

                      eco.assignTask(
                        empId: targetId,
                        title: titleController.text.trim(),
                        category: 'Department Directive',
                        priority: priority,
                        due: due,
                        assignedByRole: 'dept_head',
                        assignedByName: '${eco.currentEmployee.name} (Team Lead)',
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Department task dispatched successfully!')),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeamAttendanceSection(
    BuildContext context,
    EcosystemProvider eco,
    List<Employee> teamMembers,
  ) {
    final sortedMembers = List<Employee>.from(teamMembers);
    if (sortedMembers.length > 1) {
      sortedMembers.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    if (sortedMembers.isEmpty) {
      return LiquidGlassCard(
        borderRadius: 16,
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text('No team members assigned', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final effectiveMemberId = (_selectedAttendanceMemberId != null &&
            sortedMembers.any((m) => m.id == _selectedAttendanceMemberId))
        ? _selectedAttendanceMemberId!
        : sortedMembers.first.id;

    final selectedEmp = sortedMembers.firstWhere(
      (m) => m.id == effectiveMemberId,
      orElse: () => sortedMembers.first,
    );

    final weekRecords = eco.getPast7DaysAttendanceForEmployee(selectedEmp.id);

    int daysPresent = 0;
    int onTimeCount = 0;
    int totalMinutes = 0;

    for (final r in weekRecords) {
      if (r.loginTime != '--:-- --') {
        daysPresent++;
        if (!r.status.toLowerCase().contains('late') &&
            !r.status.toLowerCase().contains('absent') &&
            !r.status.toLowerCase().contains('no punch')) {
          onTimeCount++;
        }
        final match = RegExp(r'(\d+)h\s*(\d+)m').firstMatch(r.netHours);
        if (match != null) {
          final h = int.tryParse(match.group(1) ?? '0') ?? 0;
          final m = int.tryParse(match.group(2) ?? '0') ?? 0;
          totalMinutes += (h * 60 + m);
        }
      }
    }
    final totalHoursFormatted = '${totalMinutes ~/ 60}h ${totalMinutes % 60}m';
    final onTimePercent = daysPresent > 0 ? ((onTimeCount / daysPresent) * 100).round() : 100;

    return LiquidGlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.sandGold.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                      ),
                      child: const FaIcon(FontAwesomeIcons.calendarCheck, size: 14, color: AppColors.sandGold),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Team Attendance',
                            style: GoogleFonts.cinzel(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandGold,
                              letterSpacing: 0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            '1-Week Attendance Performance',
                            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              LiquidGlassPill(
                label: '7-Day History',
                color: AppColors.sandGold,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dropdown Label
          Text(
            'SELECT TEAM MEMBER',
            style: GoogleFonts.cinzel(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.sandLight,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),

          // Team Member Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.sandGold.withOpacity(0.35)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: effectiveMemberId,
                isExpanded: true,
                dropdownColor: const Color(0xFF200B0B),
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.sandGold),
                items: sortedMembers.map((emp) {
                  final isAbsent = eco.isEmployeeAbsent(emp.id);
                  final todaySummary = eco.allEmployeesTodayAttendance.firstWhere(
                    (s) => s.employeeId == emp.id,
                    orElse: () => EmployeeDailyAttendanceSummary(
                      employeeId: emp.id,
                      employeeName: emp.name,
                      department: emp.dept,
                      role: emp.role,
                      avatar: emp.avatar,
                      initials: emp.initials,
                      isPresent: false,
                      isOnTime: false,
                      isCurrentlyOnLunch: false,
                      isCurrentlyOnDuty: false,
                      lunchDurationMinutes: 0,
                      netWorkHours: 0,
                      status: DailyAttendanceStatus.absent,
                    ),
                  );
                  final badgeText = isAbsent ? 'Absent' : todaySummary.statusBadgeText;
                  final badgeColor = isAbsent ? AppColors.ragRed : todaySummary.statusBadgeColor;

                  return DropdownMenuItem<String>(
                    value: emp.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: badgeColor.withOpacity(0.2),
                          child: Text(
                            emp.initials,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                emp.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${emp.dept} • ${emp.role}',
                                style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: badgeColor.withOpacity(0.4), width: 0.8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedAttendanceMemberId = val;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Selected Staff Quick Summary & KPI Chips
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.sandGold.withOpacity(0.2),
                      child: Text(
                        selectedEmp.initials,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedEmp.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${selectedEmp.role} (ID: ${selectedEmp.id})',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildAttendanceMetricTile(
                        label: 'Present',
                        value: '$daysPresent / 6 Days',
                        icon: Icons.event_available,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildAttendanceMetricTile(
                        label: 'Total Hours',
                        value: totalHoursFormatted,
                        icon: Icons.timer_outlined,
                        color: AppColors.sandGold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildAttendanceMetricTile(
                        label: 'On-Time',
                        value: '$onTimePercent%',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 1-Week Attendance Performance Table
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.sandBorder.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.table_chart_outlined, size: 13, color: AppColors.sandGold),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Past 1-Week Attendance Performance',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${weekRecords.length} Days',
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.sandBorder, height: 1),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: DataTable(
                    headingRowHeight: 34,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 44,
                    horizontalMargin: 12,
                    columnSpacing: 14,
                    headingRowColor: MaterialStateProperty.all(const Color(0xFF2A0D0D)),
                    columns: const [
                      DataColumn(
                        label: Text('Date', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                      ),
                      DataColumn(
                        label: Text('Login Time', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      ),
                      DataColumn(
                        label: Text('Lunch Out', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                      ),
                      DataColumn(
                        label: Text('Lunch In', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
                      ),
                      DataColumn(
                        label: Text('Logout Time', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                      ),
                      DataColumn(
                        label: Text('Net Hours', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.sandLight)),
                      ),
                      DataColumn(
                        label: Text('Shift Status', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                    rows: weekRecords.map((r) {
                      final isToday = r.dateLabel.startsWith('Today');
                      return DataRow(
                        color: MaterialStateProperty.resolveWith<Color?>((states) {
                          if (isToday) return AppColors.sandGold.withOpacity(0.08);
                          return null;
                        }),
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isToday)
                                  Container(
                                    width: 5,
                                    height: 5,
                                    margin: const EdgeInsets.only(right: 5),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                Text(
                                  r.dateLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                    color: isToday ? AppColors.sandGold : AppColors.sandLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              r.loginTime,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                            ),
                          ),
                          DataCell(
                            Text(
                              r.lunchOutTime,
                              style: const TextStyle(fontSize: 10, color: Color(0xFFF59E0B)),
                            ),
                          ),
                          DataCell(
                            Text(
                              r.lunchInTime,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF38BDF8)),
                            ),
                          ),
                          DataCell(
                            Text(
                              r.logoutTime,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: r.logoutTime.contains('Active') || r.logoutTime.contains('On Duty')
                                    ? const Color(0xFF10B981)
                                    : AppColors.sandLight,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              r.netHours,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: r.statusColor.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: r.statusColor.withOpacity(0.4)),
                              ),
                              child: Text(
                                r.status,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: r.statusColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 8.5, color: color, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
