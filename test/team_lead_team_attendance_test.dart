import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/dept_head/dept_head_portal_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Team Lead Team Attendance 1-Week Performance Tests', () {
    testWidgets('DeptHeadPortalScreen renders Team Attendance section under Absentees tab', (tester) async {
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

      // Switch to Absentees tab (which contains the Team Attendance section)
      final absenteesTab = find.text('Absentees');
      expect(absenteesTab, findsOneWidget);
      await tester.tap(absenteesTab);
      await tester.pumpAndSettle();

      // Verify "Team Attendance" section title and subheader exist
      expect(find.text('Team Attendance'), findsWidgets);
      expect(find.text('1-Week Attendance Performance'), findsWidgets);
      expect(find.text('SELECT TEAM MEMBER'), findsWidgets);

      // Verify KPI summary chips exist
      expect(find.text('Present'), findsWidgets);
      expect(find.text('Total Hours'), findsWidgets);
      expect(find.text('On-Time'), findsWidgets);

      // Verify 1-Week Table exists with column headers
      expect(find.text('Date'), findsWidgets);
      expect(find.text('Login Time'), findsWidgets);
      expect(find.text('Lunch Out'), findsWidgets);
      expect(find.text('Lunch In'), findsWidgets);
      expect(find.text('Logout Time'), findsWidgets);
      expect(find.text('Net Hours'), findsWidgets);
      expect(find.text('Shift Status'), findsWidgets);
    });

    testWidgets('DeptHeadPortalScreen switches team member via dropdown and updates 1-week attendance table', (tester) async {
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

      // Scroll horizontal tabs to ensure Team Attendance tab is visible and tap it
      final teamAttendanceTab = find.text('Team Attendance').first;
      await tester.ensureVisible(teamAttendanceTab);
      await tester.tap(teamAttendanceTab);
      await tester.pumpAndSettle();

      // Locate the dropdown
      final dropdownFinder = find.byType(DropdownButton<String>);
      expect(dropdownFinder, findsOneWidget);

      // Open the dropdown
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Pick another team member from the dropdown, e.g. "Gokulakrishnan K"
      final gokulItem = find.text('Gokulakrishnan K').last;
      await tester.tap(gokulItem);
      await tester.pumpAndSettle();

      // Verify selected employee details are shown
      expect(find.textContaining('Gokulakrishnan K'), findsWidgets);
      expect(find.textContaining('Past 1-Week Attendance Performance'), findsOneWidget);
    });
  });
}
