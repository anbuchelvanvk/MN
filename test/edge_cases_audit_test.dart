import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/auth/pillars_popup_dialog.dart';
import 'package:mn_family_app/views/employee/employee_portal_screen.dart';
import 'package:mn_family_app/views/dept_head/dept_head_portal_screen.dart';
import 'package:mn_family_app/views/hr/hr_portal_screen.dart';
import 'package:mn_family_app/views/ceo/ceo_suite_screen.dart';
import 'package:mn_family_app/core/widgets/assign_tasks_to_others_modal.dart';
import 'package:mn_family_app/core/widgets/cross_dept_blocker_section.dart';

Widget wrapWithApp({required Widget child, EcosystemProvider? eco}) {
  return ChangeNotifierProvider<EcosystemProvider>.value(
    value: eco ?? EcosystemProvider(),
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

Future<void> dismissPillarsPopupIfPresent(WidgetTester tester) async {
  if (find.byType(PillarsPopupDialog).evaluate().isNotEmpty) {
    final closeBtn = find.descendant(
      of: find.byType(PillarsPopupDialog),
      matching: find.byIcon(Icons.close),
    );
    if (closeBtn.evaluate().isNotEmpty) {
      await tester.tap(closeBtn.first);
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Role-Based Edge Cases Audit', () {
    // 1. Employee Portal Edge Cases
    testWidgets('Employee: renders cleanly with 0 tasks and empty state', (tester) async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-1003');

      // Edge case: clear all tasks for this employee
      eco.tasks.removeWhere((t) => t.empId == 'MN-1003');

      tester.view.physicalSize = const Size(2600, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const EmployeePortalScreen(), eco: eco));
      await tester.pumpAndSettle();
      await dismissPillarsPopupIfPresent(tester);

      expect(find.byType(EmployeePortalScreen), findsOneWidget);
      expect(find.byType(CrossDeptBlockerSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Employee: small screen (360x640) renders without overflow', (tester) async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-1003');

      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const EmployeePortalScreen(), eco: eco));
      await tester.pumpAndSettle();
      await dismissPillarsPopupIfPresent(tester);

      expect(tester.takeException(), isNull);
    });

    // 2. Team Lead Edge Cases
    testWidgets('Team Lead: renders tabs and Absentee Hub without errors', (tester) async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-TL1002'); // Praveenkumar (TL)

      tester.view.physicalSize = const Size(2600, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const DeptHeadPortalScreen(), eco: eco));
      await tester.pumpAndSettle();
      await dismissPillarsPopupIfPresent(tester);

      expect(find.byType(DeptHeadPortalScreen), findsOneWidget);

      final blockerTab = find.text('Blocker Tickets');
      expect(blockerTab, findsOneWidget);
      await tester.tap(blockerTab);
      await tester.pumpAndSettle();

      expect(find.byType(CrossDeptBlockerSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 3. HR Portal Edge Cases
    testWidgets('HR Portal: renders all tabs including Blocker Tickets without errors', (tester) async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-HR1001'); // Mohankumar (HR)

      tester.view.physicalSize = const Size(2600, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const HrPortalScreen(), eco: eco));
      await tester.pumpAndSettle();
      await dismissPillarsPopupIfPresent(tester);

      expect(find.byType(HrPortalScreen), findsOneWidget);

      final blockerTab = find.text('Blocker Tickets');
      expect(blockerTab, findsOneWidget);
      await tester.tap(blockerTab);
      await tester.pumpAndSettle();

      expect(find.byType(CrossDeptBlockerSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 4. CEO Suite Edge Cases
    testWidgets('CEO Suite: renders cleanly with full enterprise blocker view and no delay analytics crash', (tester) async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-CEO01');

      tester.view.physicalSize = const Size(2600, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const CeoSuiteScreen(), eco: eco));
      await tester.pumpAndSettle();
      await dismissPillarsPopupIfPresent(tester);

      expect(find.byType(CeoSuiteScreen), findsOneWidget);

      final blockerTab = find.text('Pipelines & Blockers');
      expect(blockerTab, findsOneWidget);
      await tester.tap(blockerTab);
      await tester.pumpAndSettle();

      expect(find.byType(CrossDeptBlockerSection), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 5. CrossDeptBlockerSection Edge Cases
    testWidgets('BlockerSection: handles raise blocker and response edge cases', (tester) async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-1003');

      await tester.pumpWidget(wrapWithApp(
        child: const CrossDeptBlockerSection(department: 'Workshop', isCeoView: false),
        eco: eco,
      ));
      await tester.pumpAndSettle();

      // Raise blocker
      eco.raiseBlocker(
        raisedByDept: 'Workshop',
        raisedByName: 'Gokul (Goldsmith)',
        blockingDept: 'Showroom Sales',
        issue: 'Awaiting stone confirmation',
        slaDue: '04:00 PM',
      );
      await tester.pumpAndSettle();

      expect(find.text('Awaiting stone confirmation'), findsOneWidget);
      expect(find.text('AWAITING REPLY'), findsOneWidget);

      // Respond to blocker
      final blk = eco.blockers.first;
      eco.respondToBlocker(
        blockerId: blk.id,
        responseText: 'Stone details forwarded via bill #102',
        respondedByName: 'Sales TL',
      );
      await tester.pumpAndSettle();

      expect(find.text('RESPONDED'), findsOneWidget);
      expect(find.text('Stone details forwarded via bill #102'), findsOneWidget);

      // Resolve blocker
      eco.resolveBlocker(blk.id);
      await tester.pumpAndSettle();

      expect(find.text('RESOLVED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 6. AssignTasksToOthersModal Edge Cases
    testWidgets('AssignTasksToOthersModal: absent employee with 0 tasks behaves cleanly', (tester) async {
      final eco = EcosystemProvider();
      eco.toggleEmployeeAbsentStatus('MN-1005', isAbsent: true);
      eco.tasks.removeWhere((t) => t.empId == 'MN-1005');

      await tester.pumpWidget(wrapWithApp(
        child: const AssignTasksToOthersModal(initialAbsentEmpId: 'MN-1005'),
        eco: eco,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AssignTasksToOthersModal), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AssignTasksToOthersModal: full attendance (0 absentees) behaves cleanly', (tester) async {
      final eco = EcosystemProvider();
      for (final emp in eco.employees) {
        eco.toggleEmployeeAbsentStatus(emp.id, isAbsent: false);
      }

      await tester.pumpWidget(wrapWithApp(
        child: const AssignTasksToOthersModal(),
        eco: eco,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AssignTasksToOthersModal), findsOneWidget);
      expect(find.text('All Staff Present Today'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
