import '../../core/widgets/task_action_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ecosystem_provider.dart';
import '../../models/social_cause_models.dart';
import '../../models/employee_model.dart';
import '../../models/task_model.dart';

/// Broadcast Section: Quick To-Do Reminder dispatch button & Custom Broadcast composer
class HrBroadcastSection extends StatefulWidget {
  final String senderName;
  final String senderRole;

  const HrBroadcastSection({
    super.key,
    required this.senderName,
    required this.senderRole,
  });

  @override
  State<HrBroadcastSection> createState() => _HrBroadcastSectionState();
}

class _HrBroadcastSectionState extends State<HrBroadcastSection> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Mandatory Fast Action: Notify All to Complete Today's To-Do Lists
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B1015), Color(0xFF20090C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notification_important, color: Color(0xFFEF4444), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'One-Tap Shift Nudge Broadcast',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFECACA),
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Pushes an instant alert to every employee account & mobile notification bar',
                            style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send_time_extension, size: 16, color: Colors.white),
                    label: const Text(
                      "Notify All to Complete Today's To-Do Lists Pending Works",
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 3,
                    ),
                    onPressed: () {
                      final eco = context.read<EcosystemProvider>();
                      eco.notifyAllPendingToDosReminder(
                        senderName: widget.senderName,
                        senderRole: widget.senderRole,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Color(0xFF10B981),
                          content: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Broadcast sent! Notification pushed to all employee accounts & mobile status bars.'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Custom Management Broadcast Form
          Row(
            children: const [
              Icon(Icons.campaign, color: AppColors.sandGold, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Broadcast Notification',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
            decoration: InputDecoration(
              labelText: 'Broadcast Title (Required)',
              labelStyle: const TextStyle(fontSize: 11, color: AppColors.sandGold),
              hintText: 'e.g. Townhall Announcement, Counter Meeting, Purity Audit...',
              hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.burgundySurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.sandBorder),
              ),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _contentCtrl,
            maxLines: 2,
            style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
            decoration: InputDecoration(
              labelText: 'Message Content (Optional)',
              labelStyle: const TextStyle(fontSize: 11, color: AppColors.sandGold),
              hintText: 'Enter details to display in notification...',
              hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.burgundySurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.sandBorder),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send, size: 15, color: AppColors.burgundyBg),
              label: const Text(
                'Send Notification to All Mobiles',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.burgundyBg),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sandGold,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final title = _titleCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a broadcast title.')),
                  );
                  return;
                }
                final eco = context.read<EcosystemProvider>();
                eco.postBroadcastNotification(
                  title: title,
                  content: _contentCtrl.text.trim().isNotEmpty ? _contentCtrl.text.trim() : null,
                  senderName: widget.senderName,
                  senderRole: widget.senderRole,
                );
                _titleCtrl.clear();
                _contentCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF10B981),
                    content: Text('Broadcast notification dispatched to all employee phones'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Social Cause Approvals Hub for HR & CEO
class HrSocialCauseApprovalSection extends StatelessWidget {
  final String reviewerName;
  final String reviewerRole;

  const HrSocialCauseApprovalSection({
    super.key,
    required this.reviewerName,
    required this.reviewerRole,
  });

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final pendingCauses = eco.pendingSocialCauses;
    final approvedCauses = eco.approvedSocialCauses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sandGold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volunteer_activism, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Social Cause Approval & Broadcast Hub',
                      style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Review staff good deeds. Approved causes automatically notify all employees with deed & amount!',
                      style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Pending Submissions
        Row(
          children: [
            const Text(
              'Pending Submissions for Approval',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${pendingCauses.length}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (pendingCauses.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sandBorder),
            ),
            alignment: Alignment.center,
            child: const Text(
              'No pending social cause submissions awaiting review.',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pendingCauses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, idx) => _buildPendingCauseCard(context, eco, pendingCauses[idx]),
          ),
        const SizedBox(height: 20),

        // Approved Submissions History
        Text(
          'Recently Approved Good Deeds (${approvedCauses.length})',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.sandLight),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: approvedCauses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, idx) {
            final c = approvedCauses[idx];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Color(0xFF10B981), size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${c.employeeName} (${c.employeeRole}) • ${c.causeType}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.title,
                          style: const TextStyle(fontSize: 11, color: AppColors.sandLight),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${c.amountSpent.toStringAsFixed(0)} sponsored • Approved by ${c.approvedByName ?? "Management"}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPendingCauseCard(BuildContext context, EcosystemProvider eco, SocialCauseItem cause) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${cause.employeeName} • ${cause.employeeRole}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.sandLight),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.sandGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '₹${cause.amountSpent.toStringAsFixed(0)} Spent',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${cause.causeType}: ${cause.title}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.sandLight),
          ),
          if (cause.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              cause.description,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  eco.rejectSocialCause(cause.id, rejectedByName: reviewerName, reviewerRole: reviewerRole);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cause rejected.')),
                  );
                },
                child: const Text('Reject', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 14, color: AppColors.burgundyBg),
                label: const Text(
                  'Approve & Broadcast to All',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.burgundyBg),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  eco.approveSocialCause(
                    cause.id,
                    approvedByName: reviewerName,
                    approverRole: reviewerRole,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF10B981),
                      content: Text(
                        'Approved: "${cause.employeeName} - ${cause.causeType} (₹${cause.amountSpent.toStringAsFixed(0)})"',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Employee To-Do Oversight & Task Deletion Hub for HR & CEO
class HrEmployeeTodoManagementSection extends StatefulWidget {
  final String authorizedName;
  final String authorizedRole;

  const HrEmployeeTodoManagementSection({
    super.key,
    required this.authorizedName,
    required this.authorizedRole,
  });

  @override
  State<HrEmployeeTodoManagementSection> createState() => _HrEmployeeTodoManagementSectionState();
}

class _HrEmployeeTodoManagementSectionState extends State<HrEmployeeTodoManagementSection> {
  String? _selectedEmpId;
  String _taskSearch = '';

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final employees = eco.employees;

    if (_selectedEmpId == null && employees.isNotEmpty) {
      _selectedEmpId = employees.first.id;
    }

    final currentSelectedEmp = employees.firstWhere(
      (e) => e.id == _selectedEmpId,
      orElse: () => employees.first,
    );

    final empTasks = eco.tasks.where((t) {
      final matchesEmp = t.empId == _selectedEmpId;
      final matchesSearch = _taskSearch.isEmpty || t.title.toLowerCase().contains(_taskSearch.toLowerCase());
      return matchesEmp && matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.sandGold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sandGold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.playlist_remove, color: AppColors.sandGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employee To-Do Oversight & Task Deletion',
                      style: GoogleFonts.cinzel(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Employees cannot delete tasks themselves. As HR/CEO, you can inspect and remove tasks across all staff.',
                      style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Employee Selector Dropdown
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedEmpId,
                    dropdownColor: AppColors.burgundyCard,
                    icon: const Icon(Icons.person_search, color: AppColors.sandGold),
                    style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                    items: employees.map((emp) {
                      return DropdownMenuItem(
                        value: emp.id,
                        child: Text('${emp.name} (${emp.role} - ${emp.dept})'),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedEmpId = v);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Task Search Field
        TextField(
          style: const TextStyle(fontSize: 11, color: AppColors.sandLight),
          onChanged: (val) => setState(() => _taskSearch = val),
          decoration: InputDecoration(
            hintText: 'Search tasks for ${currentSelectedEmp.name}...',
            hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.sandGold),
            filled: true,
            fillColor: AppColors.burgundyCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
        const SizedBox(height: 12),

        // Task List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Tasks for ${currentSelectedEmp.name} (${empTasks.length})',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (empTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sandBorder),
            ),
            alignment: Alignment.center,
            child: const Text('No tasks found for this employee.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: empTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) => _buildManageTaskCard(context, eco, empTasks[idx], currentSelectedEmp),
          ),
      ],
    );
  }

  Widget _buildManageTaskCard(BuildContext context, EcosystemProvider eco, TaskItem task, Employee emp) {
    return InkWell(
      onTap: () => TaskActionDialogs.handleTaskTap(context, eco, task),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.burgundyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.isCompleted ? AppColors.ragGreen.withOpacity(0.4) : AppColors.sandBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? const Color(0xFF10B981).withOpacity(0.15)
                    : (task.isPostponed ? const Color(0xFFEF4444).withOpacity(0.15) : const Color(0xFFF59E0B).withOpacity(0.15)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                task.isCompleted ? Icons.check_circle : (task.isPostponed ? Icons.schedule : Icons.pending),
                size: 16,
                color: task.isCompleted
                    ? const Color(0xFF10B981)
                    : (task.isPostponed ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: task.isCompleted ? const Color(0xFF64748B) : AppColors.sandLight,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: task.isCompleted ? AppColors.ragGreen : null,
                      decorationThickness: 2.0,
                    ),
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${task.category} • Due: ${task.due}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textMuted)),
                    const SizedBox(width: 6),
                    Text(
                      'By: ${task.assignedByName}',
                      style: const TextStyle(fontSize: 10, color: AppColors.sandGold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Color(0xFFEF4444), size: 20),
            tooltip: 'Remove / Delete Task for Employee',
            onPressed: () => _confirmDeleteTask(context, eco, task, emp),
          ),
        ],
      ),
    ),
  );
  }

  void _confirmDeleteTask(BuildContext context, EcosystemProvider eco, TaskItem task, Employee emp) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFEF4444))),
        title: const Text('Delete Employee Task?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text(
          'Are you sure you want to delete the task:\n"${task.title}"\nassigned to ${emp.name}?',
          style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              eco.deleteEmployeeTodo(
                taskId: task.id,
                authorizedByName: widget.authorizedName,
                authorizedRole: widget.authorizedRole,
              );
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFFEF4444),
                  content: Text('Task removed for ${emp.name} by ${widget.authorizedName}.'),
                ),
              );
            },
            child: const Text('Delete Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
