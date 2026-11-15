import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/services/push_notification_service.dart';
import 'package:mn_family_app/core/widgets/emergency_permission_modal.dart';
import 'package:mn_family_app/core/widgets/prescription_viewer_dialog.dart';
import 'package:mn_family_app/models/profile_pillar_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/pillars/attendance_pillar_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Emergency Permission Flow & 2-Hour Quota Tests', () {
    late EcosystemProvider provider;

    setUp(() {
      PushNotificationService.testNotificationLog.clear();
      provider = EcosystemProvider();
    });

    test('Emergency permission request within 2 hours is normal quota', () {
      provider.requestEmergencyPermission(
        empId: 'MN-1007',
        hours: 1.0, // 1 hour request
        reason: 'Bank visit',
        requesterRole: 'Employee',
      );

      expect(provider.permissionRecords.length, equals(1));
      final rec = provider.permissionRecords.first;
      expect(rec.isEmergency, isTrue);
      expect(rec.requestedHours, equals(1.0));
      expect(rec.isOver2Hours, isFalse);
      expect(rec.isOrangeFlagged, isFalse);
      expect(rec.status, equals('Pending HR & CEO'));

      // Verify immediate push notification to CEO and HR
      expect(PushNotificationService.testNotificationLog.isNotEmpty, isTrue);
      final notification = PushNotificationService.testNotificationLog.first;
      expect(notification['title'], contains('Emergency Permission'));
      expect(notification['body'], contains('Bank visit'));
    });

    test('Emergency permission request exceeding 4 hours triggers Orange Mark', () {
      provider.requestEmergencyPermission(
        empId: 'MN-1007',
        hours: 5.0, // Exceeds 4 hours
        reason: 'Urgent family emergency',
        requesterRole: 'Employee',
      );

      final rec = provider.permissionRecords.first;
      expect(rec.requestedHours, equals(5.0));
      expect(rec.isOver4Hours, isTrue);
      expect(rec.isOrangeFlagged, isTrue); // Triggers Orange mark in permission section
    });

    test('Employee/TL Approval Flow: HR grants -> CEO accepts -> Approved', () {
      provider.requestEmergencyPermission(
        empId: 'MN-1002', // Team Lead
        hours: 2.0,
        reason: 'Client meeting step-out',
        requesterRole: 'Team Lead',
      );

      final permId = provider.permissionRecords.first.id;
      expect(provider.permissionRecords.first.status, equals('Pending HR & CEO'));

      // 1. HR grants / endorses
      provider.hrGrantPermission(permId);
      expect(provider.permissionRecords.first.status, equals('Granted by HR (Pending CEO Approval)'));

      // 2. CEO accepts / approves
      provider.ceoApprovePermission(permId);
      expect(provider.permissionRecords.first.status, equals('Approved'));
      expect(provider.permissionRecords.first.ceoApprovedBy, contains('CEO'));
    });

    test('HR direct request goes directly to CEO and CEO acceptance is sufficient', () {
      provider.requestEmergencyPermission(
        empId: 'MN-HR1001',
        hours: 0.5, // 30m
        reason: 'Hospital visit',
        requesterRole: 'HR Manager',
      );

      final rec = provider.permissionRecords.first;
      expect(rec.status, equals('Pending CEO'));

      // CEO accepts directly
      provider.ceoApprovePermission(rec.id);
      expect(provider.permissionRecords.first.status, equals('Approved'));
    });
  });

  group('Emergency Medical Leave & Mandatory Prescription Tests', () {
    late EcosystemProvider provider;

    setUp(() {
      PushNotificationService.testNotificationLog.clear();
      provider = EcosystemProvider();
    });

    test('Medical leave submission is strictly blocked without prescription', () async {
      final success = await provider.requestEmergencyMedicalLeave(
        empId: 'MN-1007',
        days: 2,
        reason: 'High fever',
        prescriptionBase64: '', // Empty prescription
        requesterRole: 'Employee',
      );

      expect(success, isFalse);
      expect(provider.medicalLeaveRecords.isEmpty, isTrue);
    });

    test('Medical leave submission succeeds with valid prescription and pushes alert to CEO/HR', () async {
      // Create valid 1x1 transparent png dummy bytes
      final dummyBytes = base64Encode([137, 80, 78, 71, 13, 10, 26, 10]);

      final success = await provider.requestEmergencyMedicalLeave(
        empId: 'MN-1007',
        days: 3,
        reason: 'Severe food poisoning prescribed 3 days rest',
        prescriptionBase64: dummyBytes,
        requesterRole: 'Employee',
      );

      expect(success, isTrue);
      expect(provider.medicalLeaveRecords.length, equals(1));
      final leave = provider.medicalLeaveRecords.first;
      expect(leave.days, equals(3));
      expect(leave.isEmergency, isTrue);
      expect(leave.prescriptionBase64, equals(dummyBytes));
      expect(leave.status, equals('Pending HR & CEO'));

      // Verify push notification
      expect(PushNotificationService.testNotificationLog.any((n) => n['title']!.contains('Medical Leave')), isTrue);
    });

    test('HR grants medical leave then CEO gives final approval', () async {
      final dummyBytes = base64Encode([137, 80, 78, 71, 13, 10, 26, 10]);
      await provider.requestEmergencyMedicalLeave(
        empId: 'MN-1002',
        days: 2,
        reason: 'Viral Infection',
        prescriptionBase64: dummyBytes,
        requesterRole: 'Team Lead',
      );

      final leaveId = provider.medicalLeaveRecords.first.id;

      // HR verifies and endorses
      provider.hrGrantMedicalLeave(leaveId);
      expect(provider.medicalLeaveRecords.first.status, equals('Granted by HR (Pending CEO Approval)'));

      // CEO accepts
      provider.ceoApproveMedicalLeave(leaveId);
      expect(provider.medicalLeaveRecords.first.status, equals('Approved'));
    });
  });

  group('UI Widgets Tests for Emergency Permissions and Leaves', () {
    testWidgets('EmergencyPermissionModal renders with 15m, 30m, 1h, 2h duration options and quota warning', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = EcosystemProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: provider,
            child: const Scaffold(
              body: EmergencyPermissionModal(),
            ),
          ),
        ),
      );

      expect(find.text('EMERGENCY PERMISSION'), findsOneWidget);
      expect(find.text('15 Min'), findsOneWidget);
      expect(find.text('30 Min'), findsOneWidget);
      expect(find.text('1 Hour'), findsOneWidget);
      expect(find.text('2 Hours'), findsOneWidget);
      expect(find.text('4 Hours'), findsOneWidget);
      expect(find.text('> 4h Custom'), findsOneWidget);

      // Tap > 4h Custom chip
      final customChip = find.widgetWithText(ChoiceChip, '> 4h Custom');
      await tester.ensureVisible(customChip);
      await tester.tap(customChip);
      await tester.pumpAndSettle();

      // Check dynamic quota exceed warning format:
      // "The time you gave [{time_given}] exceeds your quota of 4hr window, by [{time_difference}]. Do you still want to proceed?"
      expect(
        find.text('The time you gave [4.5hr] exceeds your quota of 4hr window, by [0.5hr]. Do you still want to proceed?'),
        findsOneWidget,
      );
    });

    testWidgets('PrescriptionViewerDialog renders prescription view and actions', (tester) async {
      final dummyBytes = base64Encode([137, 80, 78, 71, 13, 10, 26, 10]);
      final leave = MedicalLeaveRecord(
        id: 'MED-01',
        empId: 'MN-1007',
        empName: 'Kaaviya',
        empRole: 'Online Sale Person 1 (OS1)',
        department: 'Online Sales',
        date: DateTime.now(),
        days: 2,
        reason: 'Acute Gastroenteritis',
        prescriptionBase64: dummyBytes,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrescriptionViewerDialog(
              leave: leave,
              isCeo: true,
            ),
          ),
        ),
      );

      expect(find.text('Doctor Prescription Review'), findsOneWidget);
      expect(find.textContaining('Kaaviya'), findsOneWidget);
      expect(find.text('Accept Medical Leave'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('AttendancePillarScreen renders HR notice, calendar, and 4-Hour quota tally', (tester) async {
      final provider = EcosystemProvider();
      provider.setActiveRole('employee');
      provider.setActiveEmployee('6');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: provider,
            child: const AttendancePillarScreen(),
          ),
        ),
      );

      expect(find.text('OFFICIAL HR ATTENDANCE RECORDING'), findsOneWidget);
      expect(find.text('Your attendance will be recorded and uploaded by HR. If any queries, please contact HR.'), findsOneWidget);
      expect(find.text('OFFICIAL ATTENDANCE, LEAVES & PERMISSIONS'), findsOneWidget);
      expect(find.text('4-Hour Monthly Quota Tally'), findsOneWidget);
      expect(find.text('EMERGENCY PASS & MEDICAL LEAVE'), findsNothing);
      expect(find.text('PUSH TO LOG'), findsNothing);
      expect(find.text('SCAN THUMB'), findsNothing);
    });
  });
}

