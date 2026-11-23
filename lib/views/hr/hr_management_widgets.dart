import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/image_preview_dialog.dart';
import '../../services/image_optimization_service.dart';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
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
              color: const Color(0xFFFFF1F4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notification_important_rounded, color: AppColors.magentaPrimary, size: 18),
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
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Pushes an instant alert to every employee account & mobile notification bar',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.magentaPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.send_time_extension, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "Nudge Pending Tasks",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Custom Management Broadcast Form
          Row(
            children: const [
              Icon(Icons.campaign_rounded, color: AppColors.magentaPrimary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Broadcast Notification',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _titleCtrl,
            style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'Broadcast Title (Required)',
              labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              hintText: 'e.g. Townhall Announcement, Counter Meeting, Purity Audit...',
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.magentaPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _contentCtrl,
            maxLines: 2,
            style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'Message Content (Optional)',
              labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              hintText: 'Enter details to display in notification...',
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.magentaPrimary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send, size: 15, color: Colors.white),
              label: const Text(
                'Send Notification to All Mobiles',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.magentaPrimary,
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.sandLight),
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
            const Flexible(
              child: Text(
                'Pending Submissions for Approval',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.sandLight),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                '${pendingCauses.length}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
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
          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
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
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Color(0xFF059669), size: 14),
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
                                '${c.employeeName} (${c.employeeRole})',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Text(
                                '₹${c.amountSpent.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF059669)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${c.causeType}: ${c.title}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.verified_outlined, size: 12, color: Color(0xFF059669)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Approved & broadcasted by ${c.approvedByName ?? "Management"}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF059669), fontWeight: FontWeight.w500),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cause.employeeName,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      cause.employeeRole,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFBCFE8)),
                ),
                child: Text(
                  '₹${cause.amountSpent.toStringAsFixed(0)} Spent',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Text(
              cause.causeType,
              style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cause.title,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          if (cause.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              cause.description,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          if (cause.imageUrl != null && cause.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => ImagePreviewDialog.show(
                context,
                imageUrl: cause.imageUrl!,
                title: '${cause.employeeName} - ${cause.title}',
                subtitle: '₹${cause.amountSpent.toStringAsFixed(0)} Spent • ${cause.causeType}',
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ImageOptimizationService.buildImageWidget(
                      cause.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fullscreen, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Preview Proof Photo', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                label: const Text(
                  'Approve & Broadcast to All',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.sandLight),
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
            Expanded(
              child: Text(
                'Tasks for ${currentSelectedEmp.name} (${empTasks.length})',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.sandLight),
              ),
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
      onTap: () => _showTaskInspectionModal(context, eco, task, emp),
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
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      '${task.category} • Due: ${task.due}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textMuted)),
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

  void _showTaskInspectionModal(BuildContext context, EcosystemProvider eco, TaskItem task, Employee emp) {
    final isAbsent = eco.isEmployeeAbsent(emp.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.magentaSubtle,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.assignment_outlined, color: AppColors.magentaPrimary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Task Details & Oversight',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(bottomSheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Task Title & Category Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.magentaSubtle,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  task.category,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.magentaPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  task.priority,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            task.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status and Update Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: task.isCompleted
                            ? const Color(0xFFECFDF5)
                            : (task.isPostponed ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: task.isCompleted
                              ? const Color(0xFFA7F3D0)
                              : (task.isPostponed ? const Color(0xFFFECACA) : const Color(0xFFFDE68A)),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                task.isCompleted
                                    ? Icons.check_circle_rounded
                                    : (task.isPostponed ? Icons.schedule_rounded : Icons.pending_rounded),
                                size: 18,
                                color: task.isCompleted
                                    ? const Color(0xFF059669)
                                    : (task.isPostponed ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                task.isCompleted
                                    ? 'STATUS: COMPLETED'
                                    : (task.isPostponed ? 'STATUS: POSTPONED' : 'STATUS: PENDING'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: task.isCompleted
                                      ? const Color(0xFF059669)
                                      : (task.isPostponed ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                                ),
                              ),
                            ],
                          ),
                          if (task.proof?.content != null && task.proof!.content.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Remarks: ${task.proof!.content}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDark),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Due Date & Time Details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Due Time & SLA:', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(task.due, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Assigned By:', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(task.assignedByName, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Assigned Staff & Absent Warning Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isAbsent ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isAbsent ? const Color(0xFFFCA5A5) : const Color(0xFFBBF7D0),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: isAbsent ? const Color(0xFFEF4444) : AppColors.magentaPrimary,
                                child: Text(emp.initials, style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(emp.name, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                    Text('${emp.role} • ${emp.dept}', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isAbsent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isAbsent ? 'ABSENT TODAY' : 'PRESENT',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          if (isAbsent) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${emp.name} is Absent Today. Reassign this task immediately to maintain daily operations.',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Action Buttons: Reassign & Delete
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.magentaPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                            label: Text(
                              'Reassign Task',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.pop(bottomSheetCtx);
                              _openReassignTaskDialog(context, eco, task, emp);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(color: Color(0xFFFCA5A5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () {
                              Navigator.pop(bottomSheetCtx);
                              _confirmDeleteTask(context, eco, task, emp);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openReassignTaskDialog(BuildContext context, EcosystemProvider eco, TaskItem task, Employee currentEmp) {
    final availableEmployees = eco.employees.where((e) => e.id != currentEmp.id).toList();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.swap_horiz_rounded, color: AppColors.magentaPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Reassign Task',
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select team member to take over "${task.title}":',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableEmployees.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (ctx, i) {
                    final target = availableEmployees[i];
                    final isTargetAbsent = eco.isEmployeeAbsent(target.id);
                    return Material(type: MaterialType.transparency, child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isTargetAbsent ? const Color(0xFFEF4444) : AppColors.magentaSubtle,
                        child: Text(
                          target.initials,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isTargetAbsent ? Colors.white : AppColors.magentaPrimary,
                          ),
                        ),
                      ),
                      title: Text(
                        target.name,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      subtitle: Text(
                        '${target.role} • ${target.dept}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textMuted),
                      ),
                      trailing: isTargetAbsent
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(4)),
                              child: Text('Absent', style: GoogleFonts.plusJakartaSans(fontSize: 9, color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                            )
                          : const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                      onTap: () {
                        eco.reassignTask(
                          taskId: task.id,
                          newEmpId: target.id,
                          assignedByName: widget.authorizedName,
                        );
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('Task "${task.title}" reassigned to ${target.name} successfully!'),
                          ),
                        );
                      },
                    ));
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTask(BuildContext context, EcosystemProvider eco, TaskItem task, Employee emp) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFEF4444))),
        title: const Text('Delete Employee Task?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
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
