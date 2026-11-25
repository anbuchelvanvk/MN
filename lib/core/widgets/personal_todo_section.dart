import 'package:google_fonts/google_fonts.dart';
import 'add_todo_dialog.dart';
import 'task_action_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
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
    final allUserTasks = eco.getTasksForEmployee(targetEmpId);
    final categories = ['All', ...allUserTasks.map((t) => t.category).where((c) => c.trim().isNotEmpty).toSet()];
    if (!categories.contains(_selectedCategory)) _selectedCategory = 'All';

    final filteredTasks = allUserTasks.where((t) {
      if (_filter == 'pending' && t.status == 'completed') return false;
      if (_filter == 'completed' && t.status != 'completed') return false;
      if (_selectedCategory != 'All' && t.category != _selectedCategory) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        // Open tasks first, then by priority
        final ac = a.status == 'completed' ? 1 : 0;
        final bc = b.status == 'completed' ? 1 : 0;
        if (ac != bc) return ac - bc;
        return _priorityRank(a.priority) - _priorityRank(b.priority);
      });

    final pendingCount = allUserTasks.where((t) => t.status != 'completed').length;
    final completedCount = allUserTasks.where((t) => t.status == 'completed').length;
    final total = allUserTasks.length;
    final progress = total == 0 ? 0.0 : completedCount / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress summary + add button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          total == 0
                              ? 'Nothing planned yet'
                              : pendingCount == 0
                                  ? 'All done for now 🎉'
                                  : '$pendingCount to do',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$completedCount of $total completed',
                          style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showAddTodoDialog(context, eco, targetEmpId),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add To-Do'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.primarySoft,
                  valueColor: const AlwaysStoppedAnimation(AppColors.ragGreen),
                ),
              ),
              const SizedBox(height: 14),
              // Status filter (segmented)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EEF2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _segment('all', 'All', total),
                    _segment('pending', 'To do', pendingCount),
                    _segment('completed', 'Done', completedCount),
                  ],
                ),
              ),
              if (categories.length > 2) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      for (final cat in categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: _selectedCategory == cat,
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            selectedColor: AppColors.primary,
                            labelStyle: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _selectedCategory == cat ? Colors.white : AppColors.textSecondary,
                            ),
                            onSelected: (_) => setState(() => _selectedCategory = cat),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (filteredTasks.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                Icon(
                  _filter == 'completed' ? Icons.check_circle_outline_rounded : Icons.task_alt_rounded,
                  size: 42,
                  color: AppColors.primary.withOpacity(0.35),
                ),
                const SizedBox(height: 10),
                Text(
                  _filter == 'completed' ? 'Nothing completed yet' : 'No open to-dos here',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap "Add To-Do" to plan something.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          )
        else
          ...filteredTasks.map((task) => _buildTodoCard(context, eco, task)),
      ],
    );
  }

  static int _priorityRank(String p) {
    final l = p.toLowerCase();
    if (l.contains('critical')) return 0;
    if (l.contains('high')) return 1;
    return 2;
  }

  Widget _segment(String key, String label, int count) {
    final selected = _filter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x14881337), blurRadius: 8, offset: Offset(0, 2))]
                : null,
          ),
          child: Text(
            '$label ($count)',
            textAlign: TextAlign.center,
            maxLines: 1,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodoCard(BuildContext context, EcosystemProvider eco, TaskItem task) {
    final isCompleted = task.status == 'completed';
    final p = task.priority.toLowerCase();
    final Color priorityColor = p.contains('critical')
        ? AppColors.ragRed
        : p.contains('high')
            ? const Color(0xFFD97706)
            : AppColors.primary;
    final priorityLabel = p.contains('critical') ? 'Critical' : (task.priority.isEmpty ? 'Standard' : task.priority);
    final due = task.due.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => TaskActionDialogs.handleTaskTap(context, eco, task),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isCompleted ? AppColors.ragGreen.withOpacity(0.35) : AppColors.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority stripe + check circle
                Container(
                  width: 4,
                  height: 44,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.ragGreen : priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.ragGreen : Colors.white,
                    border: Border.all(
                      color: isCompleted ? AppColors.ragGreen : const Color(0xFFD9C3CF),
                      width: 2,
                    ),
                  ),
                  child: isCompleted ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: isCompleted ? AppColors.textMuted : AppColors.textDark,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.ragGreen,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (due.isNotEmpty) _meta(Icons.schedule_rounded, due, AppColors.textSecondary),
                          _meta(Icons.flag_rounded, priorityLabel, priorityColor),
                          if (task.category.trim().isNotEmpty)
                            _meta(Icons.label_outline_rounded, task.category, AppColors.textMuted, maxWidth: 150),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFB9A3AF)),
                  tooltip: 'Delete To-Do',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDeleteDialog(context, eco, task),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, Color color, {double maxWidth = 200}) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
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
    showAddPersonalTodoDialog(context, eco, empId: empId);
  }
}

