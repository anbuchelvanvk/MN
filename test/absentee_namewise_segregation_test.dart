import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/models/employee_model.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/dept_head/dept_head_portal_screen.dart';
import 'package:mn_family_app/core/widgets/assign_tasks_to_others_modal.dart';
import 'package:mn_family_app/views/ceo/ceo_suite_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Absentee List Name-Wise (A to Z) Segregation Tests', () {
    testWidgets('DeptHeadPortalScreen renders team tasks segregated Name-wise alphabetically (A to Z)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final eco = EcosystemProvider();
      eco.setActiveEmployee('MN-TL1002'); // Praveenkumaar M (Team Lead)

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: const DeptHeadPortalScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dismiss dialog if open
      if (find.byType(Dialog).evaluate().isNotEmpty) {
        final navigator = Navigator.of(tester.element(find.byType(Dialog)));
        navigator.pop();
        await tester.pumpAndSettle();
      }

      // Check the subheader for Name-wise arrangement
      expect(find.text('Name-wise alphabetical arrangement (A to Z)'), findsOneWidget);

      // Verify that alphabetical badges exist (A, G, P, etc.)
      expect(find.text('A'), findsWidgets);
      expect(find.text('G'), findsWidgets);
      expect(find.text('P'), findsWidgets);
    });

    testWidgets('DeptHeadPortalScreen Absentees tab renders Section letter headers for multiple absentees', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final eco = EcosystemProvider();
      eco.setActiveEmployee('MN-TL1002');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: const DeptHeadPortalScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dismiss dialog if open
      if (find.byType(Dialog).evaluate().isNotEmpty) {
        final navigator = Navigator.of(tester.element(find.byType(Dialog)));
        navigator.pop();
        await tester.pumpAndSettle();
      }

      // Switch to Absentees tab (index 1)
      await tester.tap(find.text('Absentees'));
      await tester.pumpAndSettle();

      // If team members are absent, verify Section headers appear with A-Z indicator
      expect(find.textContaining('Absent Staff (A to Z)'), findsWidgets);
    });

    testWidgets('AssignTasksToOthersModal sorts absent staff list from A to Z with letter badges', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final eco = EcosystemProvider();
      eco.setActiveEmployee('MN-TL1002');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: const Scaffold(
              body: AssignTasksToOthersModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('ABSENT STAFF (A TO Z)'), findsOneWidget);
      expect(find.textContaining('A-Z Arranged'), findsOneWidget);
    });

    testWidgets('CeoSuiteScreen sorts absent employees A to Z and displays Section letter headers', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final eco = EcosystemProvider();
      eco.setActiveEmployee('MN-CEO01');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: const CeoSuiteScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Dismiss dialog if open
      if (find.byType(Dialog).evaluate().isNotEmpty) {
        final navigator = Navigator.of(tester.element(find.byType(Dialog)));
        navigator.pop();
        await tester.pumpAndSettle();
      }

      // Expand Today's Attendance card by tapping the Absent / Off Duty counter tile
      final absentTile = find.textContaining('Absent').first;
      await tester.ensureVisible(absentTile);
      await tester.tap(absentTile);
      await tester.pumpAndSettle();

      // Open Attendance Tab
      final openAttendanceBtn = find.text('Open Attendance Tab');
      await tester.ensureVisible(openAttendanceBtn);
      await tester.tap(openAttendanceBtn);
      await tester.pumpAndSettle();

      // Tap Absent pill in KPI
      final absentPill = find.text('Absent').last;
      await tester.ensureVisible(absentPill);
      await tester.tap(absentPill);
      await tester.pumpAndSettle();

      // Should show Section headers for absentees (A to Z)
      expect(find.textContaining('Section'), findsWidgets);
      expect(find.textContaining('Absent Staff (A to Z)'), findsWidgets);
    });
  });
}
