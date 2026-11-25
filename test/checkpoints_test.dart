import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/theme/app_theme.dart';
import 'package:mn_family_app/core/widgets/attendance_publish_check.dart';
import 'package:mn_family_app/models/hr_attendance_sheet_models.dart';
import 'package:mn_family_app/models/online_order_model.dart';
import 'package:mn_family_app/models/social_cause_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/ceo/data_vault_screen.dart';

/// A weekday that is not Tuesday, near today.
DateTime notTuesday([int offset = 0]) {
  var d = DateTime.now().add(Duration(days: offset));
  while (d.weekday == DateTime.tuesday) {
    d = d.add(const Duration(days: 1));
  }
  return DateTime(d.year, d.month, d.day, 11);
}

DateTime nextTuesday() {
  var d = DateTime.now();
  while (d.weekday != DateTime.tuesday) {
    d = d.add(const Duration(days: 1));
  }
  return d;
}

HrMonthlyAttendanceSheet sheet(Map<String, String> people, {required int filledUpTo, String code = 'P'}) {
  var n = 1;
  final now = DateTime.now();
  return HrMonthlyAttendanceSheet(
    monthTitle: 'TEST',
    lastUpdated: now,
    rows: [
      for (final e in people.entries)
        HrEmployeeAttendanceRow(
          sNo: n++,
          empNo: e.key,
          name: e.value,
          days: {
            for (var d = 1; d <= filledUpTo; d++)
              d: HrAttendanceDayRecord.parse(d, code,
                  isColumnHoliday: DateTime(now.year, now.month, d).weekday == DateTime.tuesday),
          },
        ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ------------------------------------------------------------------ 1
  group('1. Attendance publish check', () {
    const staff = {'6': 'Gokulakrishnan K', '7': 'Mohankumar G', '33': 'Mithra M', '65': 'Kaaviya', '67': 'Nisha'};

    test('a complete sheet has no problems', () {
      final eco = EcosystemProvider();
      final today = DateTime.now().day;
      eco.setAttendanceSheetForTesting(sheet(staff, filledUpTo: today));
      final r = eco.checkAttendanceBeforePublish('$today');
      expect(r.staffMissing, isEmpty);
      expect(r.blankDays, isEmpty);
      expect(r.futureDate, isNull);
    });

    test('missing staff, blank days, unknown numbers and future dates are flagged', () {
      final eco = EcosystemProvider();
      final today = DateTime.now().day;
      final s = sheet({...staff, '99': 'Stranger Person'}..remove('67'), filledUpTo: today > 2 ? today - 2 : 0);
      eco.setAttendanceSheetForTesting(s);
      final r = eco.checkAttendanceBeforePublish('$today');
      expect(r.staffMissing, contains('Nisha'));
      expect(r.unknownNumbers.single, contains('Stranger Person'));
      if (today > 2 && List.generate(2, (i) => DateTime.now().subtract(Duration(days: i)))
          .any((d) => d.weekday != DateTime.tuesday)) {
        expect(r.blankDays, isNotEmpty);
      }
      expect(r.problemCount, greaterThan(1));

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      if (tomorrow.month == DateTime.now().month) {
        expect(eco.checkAttendanceBeforePublish('${tomorrow.day}').futureDate, isNotNull);
      }
    });

    test('no sheet loaded is one problem and cannot be published', () {
      const r = AttendancePublishReport(sheetMissing: true); // as returned when no sheet is loaded
      expect(r.sheetMissing, isTrue);
      expect(r.problemCount, 1);
    });

    testWidgets('review dialog shows the problems and "Publish anyway"', (tester) async {
      final eco = EcosystemProvider();
      eco.setAttendanceSheetForTesting(sheet({'99': 'Stranger Person'}, filledUpTo: 1));
      bool? result;
      await tester.pumpWidget(MaterialApp(
        theme: AppThemes.whiteMagentaTheme,
        home: Builder(
          builder: (ctx) => TextButton(
            onPressed: () async => result = await confirmAttendancePublish(ctx, eco, '1'),
            child: const Text('send'),
          ),
        ),
      ));
      await tester.tap(find.text('send'));
      await tester.pumpAndSettle();
      expect(find.textContaining('problems in the sheet'), findsOneWidget);
      expect(find.textContaining('Stranger Person'), findsOneWidget);
      await tester.tap(find.byKey(const Key('publish_anyway')));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });

  // ------------------------------------------------------------------ 2
  group('2. Relieving staff', () {
    test('open tasks block relieving until handed over', () async {
      final eco = EcosystemProvider();
      await eco.loginWithFirebase(email: 'hr@mnj.com', password: 'x');
      eco.assignTask(
        empId: '65',
        title: 'Call back customer',
        category: 'Manager Directive',
        priority: 'Standard',
        due: '23:59',
        assignedByRole: 'hr',
        assignedByName: 'HR',
      );
      expect(eco.relieveBlockers('65'), contains('1 open task'));
      expect(eco.relieveEmployee('65'), isFalse);
      expect(eco.notificationMessage, contains('Reassign them'));
      expect(eco.employees.any((e) => e.id == '65'), isTrue);
    });

    test('an open online order blocks relieving', () async {
      final eco = EcosystemProvider();
      await eco.loginWithFirebase(email: 'hr@mnj.com', password: 'x');
      eco.tasks.removeWhere((t) => t.empId == '67');
      eco.createOnlineOrder(OnlineOrderModel(
        orderId: 'T-100',
        customerName: 'Test',
        salesChannel: 'WhatsApp',
        handledByEmpId: '67',
        handledByName: 'Nisha',
        brand: 'Vadivam',
        expectedDeliveryDate: '',
        createdAt: '2026-11-25',
        stages: OnlineOrderModel.createDefaultStages(),
        checklist: OnlineOrderModel.createDefaultChecklist(),
      ));
      eco.tasks.removeWhere((t) => t.empId == '67');
      expect(eco.relieveBlockers('67').single, contains('#T-100'));
      expect(eco.relieveEmployee('67'), isFalse);
    });

    test('with nothing open, relieving goes ahead', () async {
      final eco = EcosystemProvider();
      await eco.loginWithFirebase(email: 'hr@mnj.com', password: 'x');
      eco.tasks.removeWhere((t) => t.empId == '33');
      expect(eco.relieveBlockers('33'), isEmpty);
      expect(eco.relieveEmployee('33'), isTrue);
    });
  });

  // ------------------------------------------------------------------ 3
  group('3. Leave and permission', () {
    test('Tuesday is refused for showroom staff', () {
      final eco = EcosystemProvider();
      expect(eco.leaveRequestProblem(empId: '65', date: nextTuesday(), permissionHours: 1),
          contains('week off'));
      expect(eco.leaveRequestProblem(empId: '65', date: nextTuesday(), leaveDays: 2),
          contains('cannot start on a Tuesday'));
    });

    test('overlapping leave is refused', () async {
      final eco = EcosystemProvider();
      final ok = await eco.requestEmergencyMedicalLeave(
        empId: '65', days: 3, reason: 'Fever', prescriptionBase64: 'abc', requesterRole: 'Employee');
      if (DateTime.now().weekday == DateTime.tuesday) {
        expect(ok, isFalse);
        return;
      }
      expect(ok, isTrue);
      final again = await eco.requestEmergencyMedicalLeave(
        empId: '65', days: 1, reason: 'Again', prescriptionBase64: 'abc', requesterRole: 'Employee');
      expect(again, isFalse);
      expect(eco.lastLeaveRequestProblem, contains('already have leave'));
      expect(eco.leaveRequestProblem(empId: '65', date: DateTime.now(), permissionHours: 1),
          contains('on leave'));
    });

    test('going past the monthly permission limit is refused', () {
      final eco = EcosystemProvider();
      final day = notTuesday();
      expect(eco.requestEmployeePermission(empId: '67', requestedHours: 3, reason: 'Bank', date: day), isNull);
      final refused = eco.requestEmployeePermission(empId: '67', requestedHours: 2, reason: 'More', date: day);
      expect(refused, contains('monthly permission limit'));
      expect(refused, contains('1 h left'));
    });
  });

  // ------------------------------------------------------------------ 4
  group('4. Profile details', () {
    test('phone, birth date and email are checked', () {
      final eco = EcosystemProvider();
      expect(eco.staffDetailsProblem(phone: '12345'), contains('10-digit'));
      expect(eco.staffDetailsProblem(phone: '+91 91234 56780'), isNull);
      final other = eco.employees.firstWhere((e) => e.id == '65');
      expect(eco.staffDetailsProblem(phone: other.phone, exceptEmpId: '67'), contains(other.name));
      expect(eco.staffDetailsProblem(dob: '2015-01-01'), contains('18'));
      expect(eco.staffDetailsProblem(dob: '1930-01-01'), contains('80'));
      expect(eco.staffDetailsProblem(dob: '31-02-1995'), contains('YYYY-MM-DD'));
      expect(eco.staffDetailsProblem(dob: '1995-06-15'), isNull);
      expect(eco.staffDetailsProblem(email: other.email, exceptEmpId: '67'), contains('already used'));
      expect(eco.staffDetailsProblem(email: 'not-an-email'), contains('valid email'));
    });

    test('profile save refuses a bad phone and keeps the old one', () async {
      final eco = EcosystemProvider();
      final before = eco.employees.firstWhere((e) => e.id == '67').phone;
      final problem = await eco.updateEmployeePersonalDetails(
        empId: '67', name: 'Nisha', phone: '555', dob: '1999-12-05', relationshipStatus: 'Single');
      expect(problem, contains('10-digit'));
      expect(eco.employees.firstWhere((e) => e.id == '67').phone, before);
    });
  });

  // ------------------------------------------------------------------ 5
  group('5. Assigning tasks', () {
    test('outside support never gets attendance or grooming tasks', () {
      final eco = EcosystemProvider();
      expect(eco.taskAssignBlock(empId: 'EXT-VPE', title: 'Fix grooming checklist'), contains('outside support'));
      expect(eco.taskAssignBlock(empId: 'EXT-VPE', title: 'Edit the Diwali reel'), isNull);
      expect(eco.taskAssignBlock(empId: '65', title: 'Grooming check'), isNull);
      expect(
          eco.assignTask(
              empId: 'EXT-VPE',
              title: 'Mark attendance',
              category: 'x',
              priority: 'Standard',
              due: '06:00 PM',
              assignedByRole: 'ceo',
              assignedByName: 'CEO'),
          isNotNull);
      expect(eco.tasks.any((t) => t.title == 'Mark attendance'), isFalse);
    });

    test('a passed deadline is warned about', () {
      final eco = EcosystemProvider();
      final now = DateTime.now();
      final pastDate = '${now.year - 1}-01-01';
      expect(eco.taskAssignWarnings(empId: '65', due: pastDate).join(), contains('already passed'));
      expect(eco.taskAssignWarnings(empId: '65', due: '${now.year + 1}-01-01').where((w) => w.contains('passed')),
          isEmpty);
      expect(EcosystemProvider.parseTaskDue('06:00 PM', now: DateTime(2026, 1, 1, 9))!.hour, 18);
      expect(EcosystemProvider.parseTaskDue('12:00 PM', now: DateTime(2026, 1, 1))!.hour, 12);
    });
  });

  // ------------------------------------------------------------------ 6
  group('6. Online order stages', () {
    test('stages go in order and payment comes before dispatch', () async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-TL1002');
      final order = OnlineOrderModel(
        orderId: 'T-200',
        customerName: 'Test',
        salesChannel: 'WhatsApp',
        handledByEmpId: '65',
        handledByName: 'Kaaviya',
        brand: 'MN Jewel Park',
        expectedDeliveryDate: '',
        createdAt: '2026-11-25',
        stages: OnlineOrderModel.createDefaultStages(),
        checklist: OnlineOrderModel.createDefaultChecklist(),
      );
      expect(eco.createOnlineOrder(order), isTrue);
      expect(eco.createOnlineOrder(order), isFalse, reason: 'same order number twice');

      Future<String?> tick(String id) =>
          eco.toggleOrderItemCompletion(orderId: 'T-200', itemId: id, actingEmpId: 'MN-TL1002');

      expect(await tick('PD-8'), contains('Payment must be confirmed'));
      expect(await tick('PV-1'), contains('Customer Verification'));
      for (final c in order.checklist.where((c) => c.stageId == 'stage1')) {
        expect(await tick(c.id), isNull);
      }
      expect(await tick('PV-1'), isNull);
      expect(await tick('CV-1'), contains('Untick "Product Verification" first'));
    });
  });

  // ------------------------------------------------------------------ 7
  group('7. Social causes', () {
    test('big amounts need a receipt and same-day repeats are flagged', () {
      final eco = EcosystemProvider();
      String? submit({double amount = 500, String? image}) => eco.submitSocialCause(
            empId: '65',
            employeeName: 'Kaaviya',
            employeeRole: 'OS1',
            causeType: SocialCauseType.treePlanting,
            title: 'Planted trees',
            description: '',
            amountSpent: amount,
            imageUrl: image,
          );
      expect(submit(amount: 1500), contains('receipt photo'));
      expect(eco.isPossibleDuplicateSocialCause(empId: '65', title: 'Planted trees'), isFalse);
      expect(submit(amount: 1500, image: 'data:image/png;base64,AA=='), isNull);
      expect(eco.isPossibleDuplicateSocialCause(empId: '65', title: ' planted TREES '), isTrue);
      expect(submit(), isNull);
      expect(eco.acceptancePopups.first.message, contains('Possible duplicate'));
    });
  });

  // ------------------------------------------------------------------ 8
  test('8. Restore shows how old the backup is', () {
    final now = DateTime(2026, 11, 25, 12);
    expect(backupAgeText(DateTime(2026, 11, 22, 10), now: now),
        'Made 3 days ago (22 Nov 2026, 10:00 AM)');
    expect(backupAgeText(null), 'Backup date unknown');
  });

  // ------------------------------------------------------------------ 10
  test('10. Steps record where they came from and flag big numbers', () {
    final eco = EcosystemProvider();
    final day = DateTime.now();
    expect(eco.stepSourceFor(day), isNull);
    eco.recordDailySteps(date: day, steps: 52000);
    expect(eco.stepSourceFor(day), 'typed');
    expect(eco.isUnusualSteps(52000), isTrue);
    expect(eco.isUnusualSteps(12000), isFalse);
  });

  testWidgets('8. Restore dialog shows age and record count', (tester) async {
    final eco = EcosystemProvider();
    final backup = <String, dynamic>{
      'format': 'mn-family-backup',
      'version': 1,
      'createdAt': DateTime.now().subtract(const Duration(days: 40)).toUtc().toIso8601String(),
      'counts': {'social_causes': 2},
      'collections': {
        'social_causes': [
          {'id': 'S1', 'data': {'title': 'A'}},
          {'id': 'S2', 'data': {'title': 'B'}},
        ],
      },
    };
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: eco,
      child: MaterialApp(theme: AppThemes.whiteMagentaTheme, home: BackupViewerScreen(backup: backup, fileName: 'b.json')),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Restore this backup'));
    await tester.pumpAndSettle();
    expect(find.text('Restore?'), findsOneWidget);
    expect(find.textContaining('Made 40 days ago'), findsOneWidget);
    expect(find.text('2 records will be put back'), findsOneWidget);
    expect(find.textContaining('more than a month old'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
