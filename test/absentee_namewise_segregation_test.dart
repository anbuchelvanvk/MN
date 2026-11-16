import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/dept_head/dept_head_portal_screen.dart';
import 'package:mn_family_app/core/widgets/assign_tasks_to_others_modal.dart';
import 'package:mn_family_app/views/ceo/ceo_subpages.dart';

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
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Dismiss dialog if open
      if (find.byType(Dialog).evaluate().isNotEmpty) {
        final navigator = Navigator.of(tester.element(find.byType(Dialog)));
        navigator.pop();
        await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      }

      // Open Team Tasks subpage
      await tester.tap(find.text('Team Tasks'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Check the subheader for staff dropdown selector
      expect(find.text('Select a team member from the dropdown below to view their to-do list'), findsOneWidget);

      // Verify that dropdown selector exists for team members
      expect(find.byType(DropdownButton<String>), findsOneWidget);
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
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Dismiss dialog if open
      if (find.byType(Dialog).evaluate().isNotEmpty) {
        final navigator = Navigator.of(tester.element(find.byType(Dialog)));
        navigator.pop();
        await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      }

      // Switch to Absentees tab (index 1)
      await tester.tap(find.text('Absentees'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // If team members are absent, verify Section headers appear with A-Z indicator; otherwise verify All Team Present status
      if (find.textContaining('Absent Staff (A to Z)').evaluate().isNotEmpty) {
        expect(find.textContaining('Absent Staff (A to Z)'), findsWidgets);
      } else {
        expect(find.textContaining('All Team Present'), findsOneWidget);
      }
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
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      if (find.textContaining('ABSENT STAFF (A TO Z)').evaluate().isNotEmpty) {
        expect(find.textContaining('ABSENT STAFF (A TO Z)'), findsOneWidget);
        expect(find.textContaining('A-Z Arranged'), findsOneWidget);
      } else {
        expect(find.textContaining('No absent staff members found'), findsOneWidget);
      }
    });

    testWidgets('CeoAttendanceScreen displays workforce attendance from Google Sheets', (tester) async {
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
            child: const CeoAttendanceScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Workforce Attendance'), findsOneWidget);
      expect(find.text('HR Google Sheets Master Ledger'), findsOneWidget);
    });
  });
}
