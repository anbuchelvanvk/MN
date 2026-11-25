import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/add_todo_dialog.dart';
import '../../core/widgets/pillar_kit.dart';
import '../../providers/ecosystem_provider.dart';
import '../employee/employee_subpages.dart';

/// The signed-in person's whole to-do list (every task, with its time),
/// shown on the Work page and on every role's own tab.
class MyTodoListCard extends StatelessWidget {
  const MyTodoListCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EcosystemProvider>();
    final tasks = List.of(provider.currentEmployeeTasks);
    // Pending first, then by time of day; completed at the end
    int minutes(String due) {
      final t = EcosystemProvider.parseTaskDue(due, now: DateTime(2000, 1, 1));
      return t == null ? 24 * 60 : t.hour * 60 + t.minute;
    }

    tasks.sort((a, b) {
      final da = a.status == 'completed' ? 1 : 0;
      final db = b.status == 'completed' ? 1 : 0;
      if (da != db) return da.compareTo(db);
      return minutes(a.due).compareTo(minutes(b.due));
    });
    final pending = tasks.where((t) => t.status != 'completed').length;
    final completed = tasks.length - pending;

    void openList() => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeThingsToDoScreen()),
        );

    return KitCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const KitIcon(Icons.checklist_rounded, Color(0xFFD97706)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To-Do list', style: kitTitle(16)),
                    Text('$pending pending · $completed done', style: kitBody(12.5)),
                  ],
                ),
              ),
              KitChipButton(
                buttonKey: const Key('work_add_todo'),
                label: 'Add One',
                icon: Icons.add_rounded,
                onTap: () => showAddPersonalTodoDialog(context, provider),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('Nothing on your list yet.', textAlign: TextAlign.center, style: kitBody(13)),
            ),
          for (final task in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: task.status == 'completed' ? const Color(0xFFF0FDF4) : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: openList,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 62,
                          child: Text(
                            task.due.isEmpty ? '—' : task.due,
                            style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                          ),
                        ),
                        Icon(
                          task.status == 'completed'
                              ? Icons.check_circle_rounded
                              : (task.status == 'postponed' ? Icons.schedule_rounded : Icons.radio_button_unchecked),
                          size: 18,
                          color: task.status == 'completed'
                              ? const Color(0xFF10B981)
                              : (task.status == 'postponed' ? const Color(0xFF6366F1) : const Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                              decoration: task.status == 'completed' ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (task.isDefaultSop) const KitPill('Daily', Color(0xFF0EA5E9)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
