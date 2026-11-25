import 'package:flutter/material.dart';

import '../../providers/ecosystem_provider.dart';

/// Checkpoint before a task is assigned. Blocks tasks that cannot go to this
/// person, and asks "Assign anyway?" when they are away today or the
/// deadline has passed. Returns true to go ahead.
Future<bool> confirmTaskAssignment(
  BuildContext context,
  EcosystemProvider eco, {
  required String empId,
  required String title,
  required String category,
  required String due,
}) async {
  final block = eco.taskAssignBlock(empId: empId, title: title, category: category);
  if (block != null) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.block_rounded, color: Color(0xFFDC2626)),
        title: const Text('Cannot assign this task'),
        content: Text(block),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
    return false;
  }
  final warnings = eco.taskAssignWarnings(empId: empId, due: due);
  if (warnings.isEmpty) return true;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
      title: const Text('Assign anyway?'),
      content: Text(warnings.join('\n')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Change')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Assign anyway')),
      ],
    ),
  );
  return go == true;
}
