import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/auth/pillars_popup_dialog.dart';
import 'package:mn_family_app/views/hr/hr_biometric_punch_audit_screen.dart';
import 'package:mn_family_app/views/hr/hr_portal_screen.dart';
import 'package:mn_family_app/views/hr/hr_portal_subpages.dart';

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

  group('HR Direct Access Subpages & Biometric Punch Audit Tests', () {
    testWidgets('HR Portal Screen renders 8 Direct Access tiles and home page does not show inline tab contents', (tester) async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-HR1001');

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const HrPortalScreen(), eco: eco));
      await tester.pumpAndSettle();
      await dismissPillarsPopupIfPresent(tester);

      // Verify HR Portal Screen renders
      expect(find.byType(HrPortalScreen), findsOneWidget);
      expect(find.text('HR MANAGEMENT PORTALS'), findsOneWidget);
      expect(find.text('Direct Access'), findsOneWidget);

      // Verify all 8 Direct Access tiles exist
      expect(find.text('Staff Directory'), findsWidgets);
      expect(find.text('Personal To-Dos'), findsOneWidget);
      expect(find.text('Social Causes'), findsOneWidget);
      expect(find.text('Staff Tasks'), findsOneWidget);
      expect(find.text('Blocker Tickets'), findsOneWidget);
      expect(find.text('Attendance'), findsWidgets);
      expect(find.text('Leaves & Permissions'), findsOneWidget);
      expect(find.text('Grooming Audit'), findsOneWidget);

      // Verify inline subpage content is NOT rendered on the home page
      expect(find.byType(HrStaffDirectoryScreen), findsNothing);
      expect(find.byType(HrAttendanceScreen), findsNothing);
      expect(find.byType(HrLeavesPermissionsScreen), findsNothing);
      expect(find.byType(HrGroomingAuditScreen), findsNothing);
    });

    testWidgets('Tapping Staff Directory opens HrStaffDirectoryScreen with top-left back button', (tester) async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-HR1001');

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const HrPortalScreen(), eco: eco));
      await tester.pumpAndSettle();
      await dismissPillarsPopupIfPresent(tester);

      // Tap on Staff Directory tile
      final staffDirectoryTile = find.text('Staff Directory').first;
      await tester.tap(staffDirectoryTile);
      await tester.pumpAndSettle();

      // Verify navigated into HrStaffDirectoryScreen
      expect(find.byType(HrStaffDirectoryScreen), findsOneWidget);

      // Verify top-left back button exists and pops back to HrPortalScreen
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(HrStaffDirectoryScreen), findsNothing);
      expect(find.byType(HrPortalScreen), findsOneWidget);
    });

    testWidgets('Tapping Attendance opens HrAttendanceScreen with biometric punch audit links', (tester) async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-HR1001');

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: const HrPortalScreen(), eco: eco));
      await tester.pumpAndSettle();
      await dismissPillarsPopupIfPresent(tester);

      // Tap Attendance Direct Access tile
      final attendanceTile = find.text('Attendance').last;
      await tester.tap(attendanceTile);
      await tester.pumpAndSettle();

      // Verify on HrAttendanceScreen
      expect(find.byType(HrAttendanceScreen), findsOneWidget);

      // Switch to Today's Shifts tab to inspect live punches
      final shiftsTab = find.text("Today's Shifts");
      expect(shiftsTab, findsOneWidget);
      await tester.tap(shiftsTab);
      await tester.pumpAndSettle();

      expect(find.text('View Biometric Punch Audit'), findsWidgets);

      // Tap View Biometric Punch Audit on first staff
      final auditBtn = find.text('View Biometric Punch Audit').first;
      await tester.tap(auditBtn);
      await tester.pumpAndSettle();

      // Verify navigated to HrBiometricPunchAuditScreen
      expect(find.byType(HrBiometricPunchAuditScreen), findsOneWidget);
      expect(find.text('Biometric Punch Audit'), findsOneWidget);
      expect(find.text('Attendance Rate'), findsOneWidget);
      expect(find.text('Leaves Taken'), findsOneWidget);
      expect(find.text('Permissions Taken'), findsOneWidget);
      expect(find.text('On-Time Punctuality'), findsOneWidget);

      // Verify back button pops back to HrAttendanceScreen
      final auditBackButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(auditBackButton, findsOneWidget);
      await tester.tap(auditBackButton);
      await tester.pumpAndSettle();

      expect(find.byType(HrBiometricPunchAuditScreen), findsNothing);
      expect(find.byType(HrAttendanceScreen), findsOneWidget);
    });

    testWidgets('HrBiometricPunchAuditScreen renders staff details, punch records, and logs', (tester) async {
      final eco = EcosystemProvider();
      final emp = eco.employees.first;

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapWithApp(child: HrBiometricPunchAuditScreen(employee: emp), eco: eco));
      await tester.pumpAndSettle();

      expect(find.byType(HrBiometricPunchAuditScreen), findsOneWidget);
      expect(find.text(emp.name), findsWidgets);
      expect(find.text("Today's Biometric Log"), findsOneWidget);
      expect(find.text("Recent Attendance Activity (Past 7 Days)"), findsOneWidget);
      expect(find.textContaining("Total Permissions Taken"), findsOneWidget);
      expect(find.textContaining("Total Leaves Taken"), findsOneWidget);
      expect(find.textContaining("Raw Biometric Punch Stream"), findsOneWidget);
    });
  });
}
