import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/models/task_model.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/core/widgets/personal_todo_section.dart';

void main() {
  testWidgets('To-Do Task completion with proof and revert workflow', (WidgetTester tester) async {
    final eco = EcosystemProvider();
    
    // Add a test to-do
    final testTask = TaskItem(
      id: 'TEST-TODO-001',
      empId: eco.activeEmpId,
      title: 'Audit gold purity batch #99',
      category: 'Store SOP',
      isDefaultSop: false,
      assignedByRole: 'ceo',
      assignedByName: 'CEO Office',
      due: '04:00 PM',
      priority: 'High',
      status: 'pending',
    );
    eco.tasks.insert(0, testTask);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: const SingleChildScrollView(
              child: PersonalTodoSectionWidget(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial State: Pending task is visible, not struck through
    expect(find.text('Audit gold purity batch #99'), findsOneWidget);
    final initialText = tester.widget<Text>(find.text('Audit gold purity batch #99'));
    expect(initialText.style?.decoration, isNull);

    // 2. Click the task card -> Completion modal opens with required comment and optional proof
    await tester.tap(find.text('Audit gold purity batch #99'));
    await tester.pumpAndSettle();

    expect(find.text('Complete Task'), findsOneWidget);
    expect(find.textContaining('Completion Comment'), findsOneWidget);
    expect(find.text('Required'), findsOneWidget);
    expect(find.textContaining('Proof Attachment'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Choose Image'), findsOneWidget);
    expect(find.text('Mark Completed'), findsOneWidget);

    // 3. Tapping 'Mark Completed' without words in comment box should be blocked (Required field)
    await tester.tap(find.text('Mark Completed'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Completion comment is required'), findsWidgets);
    expect(eco.tasks.firstWhere((t) => t.id == 'TEST-TODO-001').isCompleted, isFalse);

    // 4. Enter words in the required comment box and submit
    await tester.enterText(find.byType(TextField), 'Audit batch purity verified at 91.6% with laboratory spectrophotometer');
    await tester.tap(find.text('Mark Completed'));
    await tester.pumpAndSettle();

    // 5. Verify task is completed, stricken out, comment saved in proof, and green tick appears
    final completedTask = eco.tasks.firstWhere((t) => t.id == 'TEST-TODO-001');
    expect(completedTask.isCompleted, isTrue);
    expect(completedTask.proof?.content, 'Audit batch purity verified at 91.6% with laboratory spectrophotometer');
    final completedText = tester.widget<Text>(find.text('Audit gold purity batch #99'));
    expect(completedText.style?.decoration, equals(TextDecoration.lineThrough));
    expect(find.text('Done'), findsOneWidget);

    // 6. Click the completed task again -> Revert warning dialog appears
    await tester.tap(find.text('Audit gold purity batch #99'));
    await tester.pumpAndSettle();

    expect(find.text('Mark Unfinished?'), findsOneWidget);
    expect(find.text('Mark Unfinished'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // 7. Confirm reversion back to unfinished
    await tester.tap(find.widgetWithText(ElevatedButton, 'Mark Unfinished'));
    await tester.pumpAndSettle();

    // 8. Verify task is back to pending, strikethrough removed, green tick removed
    expect(eco.tasks.firstWhere((t) => t.id == 'TEST-TODO-001').isPending, isTrue);
    final revertedText = tester.widget<Text>(find.text('Audit gold purity batch #99'));
    expect(revertedText.style?.decoration, isNull);
    expect(find.text('Done'), findsNothing);
  });
}

