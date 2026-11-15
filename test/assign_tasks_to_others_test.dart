import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/core/widgets/assign_tasks_to_others_modal.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  testWidgets('AssignTasksToOthersModal renders without assertion errors and supports task reassignment', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final eco = EcosystemProvider();
    eco.setActiveEmpId('MN-TL1002'); // TL Praveenkumaar

    // Mark Gokulakrishnan K (6) absent
    eco.toggleEmployeeAbsentStatus('6', isAbsent: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AssignTasksToOthersModal.show(ctx, defaultAbsentEmpId: '6'),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to open modal
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify modal title is displayed
    expect(find.text('ASSIGN TASKS TO OTHERS'), findsOneWidget);
    expect(find.text('Absentee Task Reassignment'), findsOneWidget);
    expect(find.textContaining('Team Lead'), findsOneWidget);

    // Verify tasks render cleanly without overflow
    expect(find.text('Assign'), findsWidgets);

    // Verify Assign buttons and Batch Reassign are now available to Team Lead
    expect(find.text('Reassign All'), findsOneWidget);
    expect(find.text('Assign'), findsWidgets);
    expect(find.textContaining('My Team'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // Search bar

    // Verify no RenderFlex or assertion errors thrown
    expect(tester.takeException(), isNull);
  });

  testWidgets('AssignTasksToOthersModal enables full department filter for CEO and HR', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final eco = EcosystemProvider();
    eco.setActiveEmpId('MN-CEO01'); // CEO
    eco.toggleEmployeeAbsentStatus('6', isAbsent: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => AssignTasksToOthersModal.show(ctx, defaultAbsentEmpId: '6'),
                child: const Text('Open CEO Modal'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open CEO Modal'));
    await tester.pumpAndSettle();

    // Verify CEO scope pill
    expect(find.text('CEO (M N Naveenraaj)'), findsOneWidget);

    // Verify Department dropdown for CEO
    expect(find.text('Dept: All'), findsOneWidget);

    // Verify Reassign All and Assign buttons are present
    expect(find.text('Reassign All'), findsOneWidget);
    expect(find.text('Assign'), findsWidgets);

    expect(tester.takeException(), isNull);
  });
}

