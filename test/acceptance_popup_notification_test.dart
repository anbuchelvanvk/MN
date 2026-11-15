import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/core/services/push_notification_service.dart';
import 'package:mn_family_app/core/widgets/app_notification_host.dart';
import 'package:mn_family_app/models/acceptance_notification_model.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Permission & Leave Acceptance Pop-up Notifications Tests', () {
    late EcosystemProvider provider;

    setUp(() {
      provider = EcosystemProvider();
      PushNotificationService.testNotificationLog.clear();
    });

    test('Permission acceptance by CEO dispatches popup and push to HR, CEO, and TL', () {
      // 1. Employee requests permission
      final employee = provider.employees.firstWhere((e) => e.name.contains('Gokulakrishnan'));
      provider.requestEmployeePermission(
        empId: employee.id,
        requestedHours: 2.0,
        reason: 'Family Emergency',
      );

      final permRecord = provider.permissionRecords.firstWhere((p) => p.empId == employee.id);
      expect(permRecord.status, equals('Pending'));

      PushNotificationService.testNotificationLog.clear();

      // 2. CEO accepts/approves permission
      provider.ceoApprovePermission(permRecord.id);

      // Verify permission is now approved
      final approvedRec = provider.permissionRecords.firstWhere((p) => p.id == permRecord.id);
      expect(approvedRec.status, equals('Approved'));
      expect(approvedRec.ceoApprovedBy, contains('CEO'));

      // Verify Pop-Up Notification was created
      expect(provider.acceptancePopups.isNotEmpty, isTrue);
      final popup = provider.acceptancePopups.first;
      expect(popup.requestType, equals(AcceptanceRequestType.permission));
      expect(popup.employeeName, equals(employee.name));
      expect(popup.durationOrDays, contains('2.0 Hours'));
      expect(popup.approvedBy, contains('CEO'));

      // Verify targeted roles include HR, CEO, and TL
      expect(popup.targetRoles, contains('hr'));
      expect(popup.targetRoles, contains('ceo'));
      expect(popup.targetRoles, contains('team_lead'));

      // Verify targetEmpIds contains CEO, HR, TL, and requesting employee
      expect(popup.targetEmpIds, contains('MN-CEO01'));
      expect(popup.targetEmpIds, contains('MN-HR1001'));
      expect(popup.targetEmpIds, contains('MN-TL1002'));
      expect(popup.targetEmpIds, contains(employee.id));

      // Verify native push notification was sent
      expect(
        PushNotificationService.testNotificationLog.any((n) =>
            n['title']!.contains('Permission Request Accepted') &&
            n['body']!.contains('HR') &&
            n['body']!.contains('CEO') &&
            n['body']!.contains('TL')),
        isTrue,
      );

      // Verify company broadcast notification (Bell Icon) was inserted
      final bellNotif = provider.companyNotifications.firstWhere((n) => n.actionTag == 'PERM_ACCEPTED');
      expect(bellNotif.title, contains('Permission Request Accepted'));
      expect(bellNotif.content, contains('HR'));
      expect(bellNotif.content, contains('CEO'));
      expect(bellNotif.content, contains('Team Lead'));
    });

    test('Leave acceptance (Emergency Medical Leave) by CEO dispatches popup and push to HR, CEO, and TL', () async {
      final employee = provider.employees.firstWhere((e) => e.name.contains('Mithra'));

      // 1. Employee submits medical leave
      await provider.requestEmergencyMedicalLeave(
        empId: employee.id,
        days: 2,
        reason: 'Viral Fever with prescription',
        prescriptionBase64: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        requesterRole: employee.role,
      );

      final medLeave = provider.medicalLeaveRecords.firstWhere((m) => m.empId == employee.id);
      expect(medLeave.status, contains('Pending'));

      PushNotificationService.testNotificationLog.clear();

      // 2. CEO accepts/approves medical leave
      provider.ceoApproveMedicalLeave(medLeave.id);

      final approvedLeave = provider.medicalLeaveRecords.firstWhere((m) => m.id == medLeave.id);
      expect(approvedLeave.status, equals('Approved'));
      expect(approvedLeave.ceoApprovedBy, contains('CEO'));

      // Verify Pop-Up Notification was created
      final popup = provider.acceptancePopups.first;
      expect(popup.requestType, equals(AcceptanceRequestType.leave));
      expect(popup.employeeName, equals(employee.name));
      expect(popup.durationOrDays, contains('2 Days'));
      expect(popup.approvedBy, contains('CEO'));

      // Verify targetEmpIds contains CEO, HR, and TL
      expect(popup.targetEmpIds, contains('MN-CEO01'));
      expect(popup.targetEmpIds, contains('MN-HR1001'));
      expect(popup.targetEmpIds, contains('MN-TL1002'));

      // Verify native push notification was sent
      expect(
        PushNotificationService.testNotificationLog.any((n) =>
            n['title']!.contains('Leave Request Accepted') &&
            n['body']!.contains('HR') &&
            n['body']!.contains('CEO') &&
            n['body']!.contains('TL')),
        isTrue,
      );

      // Verify company broadcast notification (Bell Icon) was inserted
      final bellNotif = provider.companyNotifications.firstWhere((n) => n.actionTag == 'LEAVE_ACCEPTED');
      expect(bellNotif.title, contains('Leave Request Accepted'));
      expect(bellNotif.content, contains('Praveenkumar'));
    });

    test('HR, CEO, and TL all see the active popup, while other unrelated staff do not', () {
      final employee = provider.employees.firstWhere((e) => e.name.contains('Gokulakrishnan'));
      provider.dispatchAcceptanceNotification(
        requestType: AcceptanceRequestType.permission,
        employeeId: employee.id,
        employeeName: employee.name,
        durationOrDays: '1.5 Hours',
        reason: 'Doctor Visit',
        approvedBy: 'CEO (M N Naveenraaj)',
      );

      final popup = provider.acceptancePopups.first;

      // CEO session
      expect(popup.isTargetedFor(empId: 'MN-CEO01', roleType: 'ceo'), isTrue);

      // HR session
      expect(popup.isTargetedFor(empId: 'MN-HR1001', roleType: 'hr'), isTrue);

      // TL session (Praveenkumar)
      expect(popup.isTargetedFor(empId: 'MN-TL1002', roleType: 'team_lead'), isTrue);

      // Requesting Employee session
      expect(popup.isTargetedFor(empId: employee.id, roleType: 'employee'), isTrue);

      // Unrelated Employee (e.g. Kaaviya) - should NOT be targeted if not in targetEmpIds
      final otherEmp = provider.employees.firstWhere((e) => e.name == 'Kaaviya');
      expect(popup.isTargetedFor(empId: otherEmp.id, roleType: 'employee'), isFalse);
    });

    test('Acknowledging/dismissing popup removes it for that specific user', () {
      final employee = provider.employees.firstWhere((e) => e.name.contains('Gokulakrishnan'));
      provider.dispatchAcceptanceNotification(
        requestType: AcceptanceRequestType.permission,
        employeeId: employee.id,
        employeeName: employee.name,
        durationOrDays: '2.0 Hours',
        reason: 'Bank Work',
        approvedBy: 'HR (Mohankumar G)',
      );

      final popup = provider.acceptancePopups.first;

      // Active user is CEO by default in provider
      expect(provider.currentAcceptancePopupForActiveUser, isNotNull);

      // CEO acknowledges
      provider.acknowledgeAcceptancePopup(popup.id);

      // Now CEO no longer sees it
      expect(provider.currentAcceptancePopupForActiveUser, isNull);

      // But if we check for HR, HR still hasn't acknowledged yet
      expect(popup.isTargetedFor(empId: 'MN-HR1001', roleType: 'hr'), isTrue);
    });

    testWidgets('AppNotificationHost renders AcceptancePopupBanner and handles tap detail modal', (tester) async {
      final employee = provider.employees.firstWhere((e) => e.name.contains('Gokulakrishnan'));
      provider.dispatchAcceptanceNotification(
        requestType: AcceptanceRequestType.permission,
        employeeId: employee.id,
        employeeName: employee.name,
        durationOrDays: '2.0 Hours',
        reason: 'Exam Registration',
        approvedBy: 'CEO (M N Naveenraaj)',
      );

      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Provider in tree
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Scaffold(
              body: AppNotificationHost(
                child: const Center(child: Text('Dashboard Screen')),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify banner appears
      expect(find.text('PERMISSION ACCEPTED'), findsOneWidget);
      expect(find.textContaining('Gokulakrishnan K'), findsOneWidget);
      expect(find.textContaining('CEO (M N Naveenraaj)'), findsOneWidget);
      expect(find.textContaining('Notified to: HR'), findsOneWidget);

      // Tap on banner to open detail modal
      await tester.tap(find.text('PERMISSION ACCEPTED'));
      await tester.pumpAndSettle();

      // Verify detail modal opened with all recipients
      expect(find.text('Official Executive Endorsement'), findsOneWidget);
      expect(find.text('HR Department (Mohankumar G)'), findsOneWidget);
      expect(find.text('Executive CEO (M N Naveenraaj)'), findsOneWidget);
      expect(find.text('Team Lead (Praveenkumar M)'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Acknowledge & Close'));
      await tester.pumpAndSettle();

      // Verify banner dismissed
      expect(find.text('PERMISSION ACCEPTED'), findsNothing);
    });
  });
}
