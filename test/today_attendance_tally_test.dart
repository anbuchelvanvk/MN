import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/models/attendance_models.dart';
import 'package:mn_family_app/models/hr_attendance_sheet_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

HrMonthlyAttendanceSheet sheetWith(Map<String, String> todayByEmpNo, {Map<String, String> yesterday = const {}}) {
  final today = DateTime.now().day;
  var sNo = 1;
  return HrMonthlyAttendanceSheet(
    monthTitle: 'TEST',
    lastUpdated: DateTime.now(),
    rows: [
      for (final entry in {'6': 'Gokulakrishnan K', '33': 'Mithra M', '65': 'Kaaviya', '67': 'Nisha'}.entries)
        HrEmployeeAttendanceRow(
          sNo: sNo++,
          empNo: entry.key,
          name: entry.value,
          days: {
            if (today > 1 && yesterday.containsKey(entry.key))
              today - 1: HrAttendanceDayRecord.parse(today - 1, yesterday[entry.key]!),
            if (todayByEmpNo.containsKey(entry.key))
              today: HrAttendanceDayRecord.parse(today, todayByEmpNo[entry.key]!),
          },
        ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final isTuesday = DateTime.now().weekday == DateTime.tuesday;

  test('nobody is "present" when HR has not updated today', () {
    final eco = EcosystemProvider();
    eco.setAttendanceSheetForTesting(sheetWith({}, yesterday: {'65': 'CL'}));
    final staff = eco.employees.where((e) => e.hasAttendanceAndGrooming && !e.isHr).toList();
    expect(staff, isNotEmpty);
    final tally = eco.tallyTodayAttendance(staff);
    expect(tally.present, 0);
    if (!isTuesday) {
      expect(tally.notUpdatedYet, isTrue, reason: 'all staff should be "Yet to update"');
      expect(tally.headline, 'Yet to update');
      // Yesterday's leave must not make someone absent today.
      expect(tally.absent, 0);
    }
  }, skip: false);

  test('present and absent are counted once HR fills today in', () {
    if (isTuesday) return; // showroom week off
    final eco = EcosystemProvider();
    eco.setAttendanceSheetForTesting(sheetWith({'6': 'P', '33': 'P', '65': 'CL'}));
    final staff = eco.employees.where((e) => ['6', '33', '65', '67'].contains(e.id)).toList();
    final map = eco.todayAttendanceFor(staff.map((e) => e.id));
    expect(map['6'], TodayAttendance.present);
    expect(map['65'], TodayAttendance.absent);
    expect(map['67'], TodayAttendance.yetToUpdate);
    final tally = eco.tallyTodayAttendance(staff);
    expect(tally.present, 2);
    expect(tally.absent, 1);
    expect(tally.yetToUpdate, 1);
    expect(tally.headline, '2/4 present');
  });

  test('outside support has no attendance and is not counted as staff present', () {
    final eco = EcosystemProvider();
    final outside = eco.employees.where((e) => e.isExternalSupport).toList();
    expect(outside, isNotEmpty);
    for (final e in outside) {
      expect(eco.todayAttendanceOf(e.id), TodayAttendance.notTracked);
      expect(eco.isEmployeeAbsent(e.id), isFalse);
    }
    final ids = eco.allEmployeesTodayAttendance.map((s) => s.employeeId).toSet();
    expect(outside.any((e) => ids.contains(e.id)), isFalse);
  });

  test('labels', () {
    expect(TodayAttendance.yetToUpdate.label, 'Yet to update');
    expect(const AttendanceTally().headline, 'No attendance');
    expect(const AttendanceTally(weekOff: 3).headline, 'Week off');
  });
}
