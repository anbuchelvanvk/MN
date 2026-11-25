import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/core/theme/app_theme.dart';
import 'package:mn_family_app/views/hr/hr_portal_subpages.dart';
import 'package:mn_family_app/models/hr_attendance_sheet_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

HrMonthlyAttendanceSheet sheet(List<(String, String)> rows) {
  var n = 1;
  return HrMonthlyAttendanceSheet(
    monthTitle: 'TEST',
    lastUpdated: DateTime.now(),
    rows: [
      for (final r in rows) HrEmployeeAttendanceRow(sNo: n++, empNo: r.$1, name: r.$2, days: const {}),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  EcosystemProvider withSheet() {
    final eco = EcosystemProvider();
    eco.setAttendanceSheetForTesting(sheet([
      ('6', 'Gokulakrishnan K'),
      ('90', 'Ravi Kumar'),
      ('', 'No Number Person'),
    ]));
    return eco;
  }

  test('number and name in the sheet, not in the database: allowed', () {
    final c = withSheet().checkNewHire(empNo: '90', name: 'Ravi  kumar');
    expect(c.ok, isTrue);
    expect(c.sheetEntry?.name, 'Ravi Kumar');
  });

  test('blank name takes the name from the sheet', () {
    final c = withSheet().checkNewHire(empNo: '090', name: '');
    expect(c.ok, isTrue);
    expect(c.sheetEntry?.empNo, '90');
  });

  test('already in the database: says who and under which number', () {
    final c = withSheet().checkNewHire(empNo: '6', name: 'Gokulakrishnan K');
    expect(c.result, NewHireCheckResult.alreadyHired);
    expect(c.message, 'Already filled up in the name Gokulakrishnan K under the employee number 6.');
  });

  test('same person under a new number is also caught', () {
    final c = withSheet().checkNewHire(empNo: '90', name: 'Kaaviya');
    expect(c.result, NewHireCheckResult.alreadyHired);
    expect(c.message, contains('Kaaviya'));
  });

  test('number not in the sheet: stops with the thumb impression message', () {
    final c = withSheet().checkNewHire(empNo: '123', name: 'New Person');
    expect(c.result, NewHireCheckResult.notInSheet);
    expect(
      c.message,
      'No name or employee number found in the attendance. Make a new entry in Thumb impression '
      'and update in google sheets along with the employee number and name.',
    );
  });

  test('a sheet row without a number does not count', () {
    final c = withSheet().checkNewHire(empNo: '0', name: 'No Number Person');
    expect(c.result, NewHireCheckResult.notInSheet);
  });

  test('name different from the sheet is stopped', () {
    final c = withSheet().checkNewHire(empNo: '90', name: 'Someone Else');
    expect(c.result, NewHireCheckResult.nameMismatch);
    expect(c.message, contains('"Ravi Kumar"'));
  });

  test('outside support skips the sheet but not the database', () {
    final eco = withSheet();
    expect(eco.checkNewHire(empNo: 'EXT-NEW', name: 'Outside Person', outsideSupport: true).ok, isTrue);
    expect(eco.checkNewHire(empNo: 'EXT-VPE', name: 'x', outsideSupport: true).result,
        NewHireCheckResult.alreadyHired);
  });

  test('empty number is asked for', () {
    expect(withSheet().checkNewHire(empNo: ' ', name: 'A').result, NewHireCheckResult.missingNumber);
  });

  testWidgets('New Hire form warns as soon as an unknown number is typed', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final eco = withSheet();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: eco,
      child: MaterialApp(
        theme: AppThemes.whiteMagentaTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => HrStaffDirectoryScreen.openAddHireDialog(context, eco),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final idField = find.widgetWithText(TextField, 'Enter Employee ID / Number');
    await tester.enterText(idField, '123');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('new_hire_not_in_sheet')), findsOneWidget);
    expect(find.textContaining('Make a new entry in Thumb impression'), findsOneWidget);

    await tester.enterText(idField, '6');
    await tester.pumpAndSettle();
    expect(find.textContaining('Already filled up in the name Gokulakrishnan K under the employee number 6.'),
        findsOneWidget);
  });
}
