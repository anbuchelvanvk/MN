import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/task_action_dialogs.dart';
import '../../models/task_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../pillars/social_cause_pillar_screen.dart';
import 'employee_profile_screen.dart';

/// Reusable Scaffold for all Employee Subpages (Clean White/Magenta styling with top-left back button)
class EmployeeSubpageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const EmployeeSubpageScaffold({
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
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

// 1. THINGS TO DO SUBPAGE
class EmployeeThingsToDoScreen extends StatefulWidget {
  const EmployeeThingsToDoScreen({super.key});

  @override
  State<EmployeeThingsToDoScreen> createState() => _EmployeeThingsToDoScreenState();
}

class _EmployeeThingsToDoScreenState extends State<EmployeeThingsToDoScreen> {
  String _taskFilter = 'all'; // 'all', 'pending', 'completed'

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final allTasks = eco.currentEmployeeTasks;
    final filteredTasks = allTasks.where((t) {
      if (_taskFilter == 'pending') return t.status == 'pending';
      if (_taskFilter == 'completed') return t.status == 'completed';
      return true;
    }).toList();

    final pendingCount = allTasks.where((t) => t.status == 'pending').length;
    final completedCount = allTasks.where((t) => t.status == 'completed').length;

    return EmployeeSubpageScaffold(
      title: 'Things To Do',
      subtitle: 'Daily SOP Routines & Personal Action Items',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 14, color: Colors.white),
            label: const Text('Add Task', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.magentaPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _openAddPersonalTaskDialog(context, eco),
          ),
        ),
      ],
      body: RefreshIndicator(
        color: AppColors.magentaPrimary,
        backgroundColor: Colors.white,
        onRefresh: () => eco.refreshAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filter Tabs (All, Pending, Completed)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _filterButton('all', 'All (${allTasks.length})'),
                    const SizedBox(width: 8),
                    _filterButton('pending', 'Pending ($pendingCount)'),
                    const SizedBox(width: 8),
                    _filterButton('completed', 'Done ($completedCount)'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (filteredTasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 40, color: Color(0xFF10B981)),
                        const SizedBox(height: 10),
                        Text(
                          'No Tasks Found',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All tasks in this category are completely cleared!',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredTasks.map((task) => _taskCard(context, eco, task)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterButton(String key, String label) {
    final isSelected = _taskFilter == key;
    return InkWell(
      onTap: () => setState(() => _taskFilter = key),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.magentaPrimary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.magentaPrimary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _taskCard(BuildContext context, EcosystemProvider eco, TaskItem task) {
    final isDone = task.status == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? const Color(0xFFD1FAE5) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x040F172A), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFECFDF5) : AppColors.magentaSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                  size: 16,
                  color: isDone ? const Color(0xFF10B981) : AppColors.magentaPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDone ? AppColors.textMuted : AppColors.textDark,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      '${task.category} • Due: ${task.due} • ${task.priority}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDone ? 'DONE' : 'PENDING',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDone ? const Color(0xFF059669) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          if (task.proof != null) ...[
            const SizedBox(height: 8),
            Text(
              'Proof: ${task.proof!.content} (${task.proof!.timestamp})',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF059669), fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isDone) ...[
                OutlinedButton.icon(
                  icon: const Icon(Icons.undo_rounded, size: 13, color: Color(0xFF64748B)),
                  label: const Text('Revert to Pending', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: () => TaskActionDialogs.showRevertDialog(context, eco, task),
                ),
              ] else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  label: const Text('Mark Complete', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => TaskActionDialogs.showCompletionModal(context, eco, task),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _openAddPersonalTaskDialog(BuildContext context, EcosystemProvider eco) {
    final titleCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add Daily Task',
          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Task Title (e.g. Clean display velvet tray)',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Category (e.g. Showroom Display, Audit...)',
                hintStyle: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.magentaPrimary, foregroundColor: Colors.white),
            onPressed: () {
              final t = titleCtrl.text.trim();
              if (t.isEmpty) return;
              eco.addEmployeePersonalTodo(
                empId: eco.currentEmployee.id,
                title: t,
                category: categoryCtrl.text.trim().isEmpty ? 'General' : categoryCtrl.text.trim(),
                dueTime: '06:00 PM',
                priority: 'Standard',
              );
              Navigator.pop(ctx);
            },
            child: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// 2. SOCIAL CAUSE SUBPAGE
class EmployeeSocialCauseScreen extends StatelessWidget {
  const EmployeeSocialCauseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmployeeSubpageScaffold(
      title: 'Social Cause',
      subtitle: 'Pillar 5 CSR & Community Impact',
      body: SocialCausePillarScreen(isStandalone: false),
    );
  }
}

// 3. DIGITAL ID VAULT SUBPAGE
class EmployeeDigitalIdScreen extends StatelessWidget {
  const EmployeeDigitalIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final emp = eco.currentEmployee;

    return EmployeeSubpageScaffold(
      title: 'Digital ID Vault',
      subtitle: 'Official Workforce Credentials & Custody',
      actions: [
        IconButton(
          icon: const Icon(Icons.badge_outlined, color: AppColors.magentaPrimary),
          tooltip: 'Open Full Profile',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
            );
          },
        ),
      ],
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Employee Digital ID Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.magentaPrimary, Color(0xFFBE185D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x22E11D48), blurRadius: 14, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Row(
                        children: [
                          const Icon(Icons.diamond_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 6),
                          Flexible(child: Text(
                            'MN JEWEL PARK',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),),                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.4)),
                        ),
                        child: Text(
                          'OFFICIAL ID',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white,
                        child: Text(
                          emp.initials,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              emp.role,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.white.withOpacity(0.85)),
                            ),
                            Text(
                              'ID: ${emp.id} • ${emp.dept}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.white.withOpacity(0.75)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text('Vault Security Status', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: Colors.white.withOpacity(0.85)))),
                        Text('VERIFIED ACTIVE', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Profile & KYC Details Card
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(
                        'Personal & Contact Details',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      )),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                          );
                        },
                        child: Text(
                          'Edit Profile',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  _infoRow(Icons.phone_outlined, 'Mobile Number', emp.phone.isNotEmpty ? emp.phone : 'Not provided'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.email_outlined, 'Official Email', emp.email),
                  const SizedBox(height: 8),
                  _infoRow(Icons.corporate_fare_outlined, 'Department', emp.dept),
                  const SizedBox(height: 8),
                  _infoRow(Icons.calendar_today_outlined, 'Date of Birth', emp.dob.isNotEmpty ? emp.dob : 'Not provided'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.favorite_outline, 'Relationship Status', emp.relationshipStatus.isNotEmpty ? emp.relationshipStatus : 'Single'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Portal Access Credentials
            LiquidGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portal Access & Credentials',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  Row(
                    children: [
                      const Icon(Icons.key_outlined, size: 16, color: AppColors.magentaPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Login & password',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.magentaPrimary),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        child: const Text('Change', style: TextStyle(fontSize: 11, color: AppColors.magentaPrimary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.magentaPrimary),
        const SizedBox(width: 8),
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 130), child: Text('$label: ', overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted))),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
