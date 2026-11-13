import 'task_action_dialogs.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import 'liquid_glass.dart';
import '../../models/task_model.dart';
import '../../providers/ecosystem_provider.dart';

class PersonalTodoSectionWidget extends StatefulWidget {
  final String? empId;
  final String title;
  final String subtitle;

  const PersonalTodoSectionWidget({
    super.key,
    this.empId,
    this.title = 'Personal To-Do Checklist',
    this.subtitle = 'Manage your personal action items, follow-ups, and operational tasks.',
  });

  @override
  State<PersonalTodoSectionWidget> createState() => _PersonalTodoSectionWidgetState();
}

class _PersonalTodoSectionWidgetState extends State<PersonalTodoSectionWidget> {
  String _filter = 'all'; // 'all', 'pending', 'completed'
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final targetEmpId = widget.empId ?? eco.activeEmpId;
    final allUserTasks = eco.tasks.where((t) => t.empId == targetEmpId).toList();
    final categories = ['All', ...allUserTasks.map((t) => t.category).toSet()];

    final filteredTasks = allUserTasks.where((t) {
      if (_filter == 'pending' && t.status == 'completed') return false;
      if (_filter == 'completed' && t.status != 'completed') return false;
      if (_selectedCategory != 'All' && t.category != _selectedCategory) return false;
      return true;
    }).toList();

    final pendingCount = allUserTasks.where((t) => t.status != 'completed').length;
    final completedCount = allUserTasks.where((t) => t.status == 'completed').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header Card
        LiquidGlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.sandGold.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const FaIcon(FontAwesomeIcons.listCheck, color: AppColors.sandGold, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$pendingCount Pending • $completedCount Completed',
                                style: const TextStyle(fontSize: 10.5, color: AppColors.sandLight),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showAddTodoDialog(context, eco, targetEmpId),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AppColors.magentaGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.magentaPrimary.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          FaIcon(FontAwesomeIcons.plus, size: 11, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Add To-Do',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.3),
              ),
              const SizedBox(height: 14),

              // Filter Chips
              Row(
                children: [
                  _filterChip('all', 'All (${allUserTasks.length})'),
                  const SizedBox(width: 8),
                  _filterChip('pending', 'Pending ($pendingCount)'),
                  const SizedBox(width: 8),
                  _filterChip('completed', 'Completed ($completedCount)'),
                ],
              ),
              if (categories.length > 2) ...[
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      final catTasks = cat == 'All'
                          ? allUserTasks
                          : allUserTasks.where((t) => t.category == cat).toList();
                      final completedInCat = catTasks.where((t) => t.status == 'completed').length;
                      final countBadge = '$completedInCat/${catTasks.length}';

                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setState(() => _selectedCategory = cat),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.magentaSubtle : AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.magentaPrimary : AppColors.sandBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.magentaPrimary : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.magentaPrimary : AppColors.sandBorder.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    countBadge,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Task List or Empty State
        if (filteredTasks.isEmpty) ...[
          LiquidGlassCard(
            borderRadius: 14,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    _filter == 'completed' ? Icons.check_circle_outline : Icons.task_alt,
                    size: 40,
                    color: AppColors.sandGold.withOpacity(0.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _filter == 'completed' ? 'No completed tasks yet.' : 'No pending to-dos on your checklist.',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap "+ Add To-Do" above to log a personal follow-up or priority.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ...filteredTasks.map((task) => _buildTodoCard(context, eco, task)),
        ],
      ],
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = _filter == filterKey;
    return InkWell(
      onTap: () => setState(() => _filter = filterKey),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.magentaGradient : null,
          color: isSelected ? null : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.sandBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.magentaPrimary.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTodoCard(BuildContext context, EcosystemProvider eco, TaskItem task) {
    final isCompleted = task.status == 'completed';
    Color priorityColor = AppColors.sandGold;
    if (task.priority.toLowerCase().contains('critical')) {
      priorityColor = AppColors.ragRed;
    } else if (task.priority.toLowerCase().contains('high')) {
      priorityColor = const Color(0xFFF97316);
    }

    return InkWell(
      onTap: () => TaskActionDialogs.handleTaskTap(context, eco, task),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.white.withOpacity(0.03) : AppColors.burgundyCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? AppColors.ragGreen.withOpacity(0.4) : AppColors.sandGold.withOpacity(0.25),
            width: isCompleted ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox / Status Indicator with Green Tick
            InkWell(
              onTap: () => TaskActionDialogs.handleTaskTap(context, eco, task),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.ragGreen : Colors.white.withOpacity(0.05),
                  border: Border.all(
                    color: isCompleted ? AppColors.ragGreen : AppColors.sandGold.withOpacity(0.6),
                    width: 1.5,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Title & Details (Strikethrough and green tick when completed)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? const Color(0xFF94A3B8) : AppColors.textDark,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: isCompleted ? AppColors.ragGreen : null,
                      decorationThickness: 2.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.priority,
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: priorityColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${task.category} • Due: ${task.due}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle, size: 12, color: AppColors.ragGreen),
                            SizedBox(width: 3),
                            Text(
                              'Done',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.ragGreen),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Delete Action
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.trashCan, size: 14, color: Color(0xFF94A3B8)),
              tooltip: 'Delete To-Do',
              onPressed: () => _confirmDeleteDialog(context, eco, task),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDialog(BuildContext context, EcosystemProvider eco, TaskItem task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.sandGold, width: 1.2),
        ),
        title: const Text('Delete Personal To-Do?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: Text(
          'Are you sure you want to remove "${task.title}" from your checklist?',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ragRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              eco.deletePersonalTodo(task.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Personal to-do deleted successfully.'),
                  backgroundColor: AppColors.ragRed,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context, EcosystemProvider eco, String empId) {
    final titleCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'General');
    final dueCtrl = TextEditingController(text: '06:00 PM');
    String selectedPriority = 'Standard';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.sandGold),
          ),
          title: Row(
            children: const [
              Icon(Icons.add_task, color: AppColors.sandGold, size: 20),
              SizedBox(width: 8),
              Text(
                'Add Personal To-Do',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('To-Do Title / Task', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                  decoration: InputDecoration(
                    hintText: 'e.g. Call customer, review daily dispatch, checklist...',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                const SizedBox(height: 6),
                TextField(
                  controller: categoryCtrl,
                  style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                  decoration: InputDecoration(
                    hintText: 'e.g. Customer Follow-up, Audit, Personal SOP...',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: ['Customer', 'Audit', 'Personal SOP', 'Inventory', 'Briefing'].map((cat) {
                    return InkWell(
                      onTap: () => setDialogState(() => categoryCtrl.text = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: categoryCtrl.text == cat ? AppColors.magentaPrimary : AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: categoryCtrl.text == cat ? AppColors.magentaPrimary : AppColors.sandBorder,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 10,
                            color: categoryCtrl.text == cat ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Due Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: dueCtrl,
                            style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                            decoration: InputDecoration(
                              hintText: '06:00 PM',
                              hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.burgundySurface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Priority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: AppColors.burgundySurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.sandBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedPriority,
                                isExpanded: true,
                                dropdownColor: AppColors.burgundySurface,
                                style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                                items: const [
                                  DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                                  DropdownMenuItem(value: 'High', child: Text('High')),
                                  DropdownMenuItem(value: 'Critical SLA', child: Text('Critical SLA')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setDialogState(() => selectedPriority = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.magentaPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a to-do title')),
                  );
                  return;
                }
                eco.addEmployeePersonalTodo(
                  empId: empId,
                  title: title,
                  category: categoryCtrl.text.trim().isEmpty ? 'General' : categoryCtrl.text.trim(),
                  dueTime: dueCtrl.text.trim().isEmpty ? '06:00 PM' : dueCtrl.text.trim(),
                  priority: selectedPriority,
                );
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF10B981),
                    content: Text('Personal to-do added successfully!'),
                  ),
                );
              },
              child: const Text('Add To-Do', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

