import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/ecosystem_provider.dart';
import '../theme/app_colors.dart';

/// The one "Add To-Do" dialog used everywhere in the app (home page, My Tasks).
/// Collects a title, category, due time and priority.
Future<void> showAddPersonalTodoDialog(
  BuildContext context,
  EcosystemProvider eco, {
  String? empId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AddTodoDialog(eco: eco, empId: empId ?? eco.activeEmpId, hostContext: context),
  );
}

class _AddTodoDialog extends StatefulWidget {
  final EcosystemProvider eco;
  final String empId;
  final BuildContext hostContext;
  const _AddTodoDialog({required this.eco, required this.empId, required this.hostContext});

  @override
  State<_AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<_AddTodoDialog> {
  static const _categories = ['General', 'Customer', 'Audit', 'Personal SOP', 'Inventory', 'Briefing'];
  static const _priorities = ['Standard', 'High', 'Critical SLA'];

  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'General');
  TimeOfDay _due = const TimeOfDay(hour: 18, minute: 0);
  String _priority = 'Standard';
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _due);
    if (picked != null) setState(() => _due = picked);
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Please enter what needs to be done');
      return;
    }
    final category = _categoryCtrl.text.trim().isEmpty ? 'General' : _categoryCtrl.text.trim();
    widget.eco.addEmployeePersonalTodo(
      empId: widget.empId,
      title: title,
      category: category,
      dueTime: _fmt(_due),
      priority: _priority,
    );
    Navigator.pop(context);
    ScaffoldMessenger.maybeOf(widget.hostContext)?.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF059669),
        content: Text('To-do "$title" added for ${_fmt(_due)}.'),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 6),
      contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 4),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'New to-do',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('What needs to be done?'),
            TextField(
              key: const ValueKey('add_todo_title'),
              controller: _titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: 'e.g. Call customer, post reel',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            _label('Category'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _categories)
                  ChoiceChip(
                    label: Text(c),
                    selected: _categoryCtrl.text == c,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _categoryCtrl.text == c ? Colors.white : AppColors.textDark,
                    ),
                    onSelected: (_) => setState(() => _categoryCtrl.text = c),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Due time'),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _pickTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            suffixIcon: Icon(Icons.schedule_rounded, size: 20),
                          ),
                          child: Text(
                            _fmt(_due),
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Priority'),
                      DropdownButtonFormField<String>(
                        value: _priority,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(14),
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textDark),
                        items: [
                          for (final p in _priorities) DropdownMenuItem(value: p, child: Text(p)),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _priority = v);
                        },
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
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Add To-Do')),
      ],
    );
  }
}
