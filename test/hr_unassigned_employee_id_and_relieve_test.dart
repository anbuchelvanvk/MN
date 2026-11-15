import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/models/hr_attendance_sheet_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/services/google_sheets_attendance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HR Unassigned Employee IDs from Google Sheets & Relieving Flow', () {
    late EcosystemProvider eco;

    setUp(() {
      eco = EcosystemProvider();
    });

    test('All Google Sheet rows are parsed and unassigned IDs are dynamically discovered', () {
      final unassigned = eco.unassignedGoogleSheetEmployees;
      expect(unassigned.isNotEmpty, isTrue);

      // Verify currently active workforce (6, 7, 33, 65, 67) are NOT in unassigned list
      final unassignedEmpNos = unassigned.map((e) => e.empNo).toSet();
      expect(unassignedEmpNos.contains('6'), isFalse, reason: 'Gokulakrishnan is active');
      expect(unassignedEmpNos.contains('7'), isFalse, reason: 'Mohankumar is active');
      expect(unassignedEmpNos.contains('33'), isFalse, reason: 'Mithra is active');
      expect(unassignedEmpNos.contains('65'), isFalse, reason: 'Kaaviya is active');
      expect(unassignedEmpNos.contains('67'), isFalse, reason: 'Nisha is active');

      // Verify unassigned staff from sheet ARE present
      expect(unassignedEmpNos.contains('1'), isTrue, reason: 'Sakthivel should be unassigned');
      expect(unassignedEmpNos.contains('2'), isTrue, reason: 'Sivakumar should be unassigned');
      expect(unassignedEmpNos.contains('4'), isTrue, reason: 'Balaji should be unassigned');
      expect(unassignedEmpNos.contains('10'), isTrue, reason: 'Somu should be unassigned');

      final sakthivel = unassigned.firstWhere((e) => e.empNo == '1');
      expect(sakthivel.name, 'Sakthivel');
    });

    test('Registering an unassigned employee assigns their sheet ID and activates their attendance row', () {
      // 1. Initial active workforce count
      final initialActiveCount = eco.activeAttendanceSheetRows.length;
      expect(initialActiveCount, 5); // 6, 7, 33, 65, 67

      // 2. Register Somu (EMP #10) from Google Sheets
      eco.addNewEmployee(
        name: 'Somu',
        role: 'Store Executive',
        phone: '+91 94444 11010',
        email: 'somu@mnjewelpark.com',
        experienceCategory: 'experienced',
        experienceYears: '4 yrs',
        customEmpId: '10',
        empNo: '10',
      );

      // Verify Somu is now an active employee
      final somu = eco.employees.firstWhere((e) => e.id == '10');
      expect(somu.name, 'Somu');
      expect(somu.empNo, '10');
      expect(somu.displayEmpId, '10');

      // 3. Somu must NO LONGER appear in unassignedGoogleSheetEmployees
      final unassignedAfter = eco.unassignedGoogleSheetEmployees;
      expect(unassignedAfter.any((e) => e.empNo == '10'), isFalse);

      // 4. Somu's attendance row must now be active in activeAttendanceSheetRows
      final activeRowsAfter = eco.activeAttendanceSheetRows;
      expect(activeRowsAfter.length, initialActiveCount + 1);
      final somuRow = activeRowsAfter.firstWhere((r) => r.empNo == '10');
      expect(somuRow.name, 'Somu');
      // Day 7 for Somu in sheet was L-1, Day 14 was 1:20 m permission
      expect(somuRow.days[7]?.type, HrAttendanceDayType.late);
      expect(somuRow.days[14]?.type, HrAttendanceDayType.permission);
    });

    test('Relieving an employee removes them from active workforce and returns their ID to unassigned', () {
      // 1. Register Balaji (EMP #4)
      eco.addNewEmployee(
        name: 'Balaji',
        role: 'Operations Assistant',
        phone: '+91 94444 11004',
        email: 'balaji@mnjewelpark.com',
        experienceCategory: 'experienced',
        experienceYears: '2 yrs',
        customEmpId: '4',
        empNo: '4',
      );

      expect(eco.employees.any((e) => e.id == '4'), isTrue);
      expect(eco.unassignedGoogleSheetEmployees.any((e) => e.empNo == '4'), isFalse);

      // 2. Relieve Balaji from the company
      final relieved = eco.relieveEmployee('4');
      expect(relieved, isTrue);

      // 3. Balaji is removed from active workforce
      expect(eco.employees.any((e) => e.id == '4'), isFalse);
      expect(eco.activeAttendanceSheetRows.any((r) => r.empNo == '4'), isFalse);

      // 4. EMP #4 returns to unassigned dropdown
      expect(eco.unassignedGoogleSheetEmployees.any((e) => e.empNo == '4'), isTrue);

      // 5. Workforce announcement was generated
      final announcement = eco.companyNotifications.firstWhere(
        (n) => n.title.contains('Staff Relieved'),
      );
      expect(announcement.content.contains('Balaji'), isTrue);
    });

    test('CEO account cannot be relieved', () {
      final relieved = eco.relieveEmployee('MN-CEO01');
      expect(relieved, isFalse);
      expect(eco.employees.any((e) => e.id == 'MN-CEO01'), isTrue);
    });

    test('HR Attendance Sheet getActiveRowsFor handles dynamic workforce accurately', () {
      final sheet = GoogleSheetsAttendanceService.parseCsvToAttendanceSheet(
        GoogleSheetsAttendanceService.embeddedNovemberSeedCsv,
      );

      // All 34 sheet rows are parsed
      expect(sheet.allSheetRows.length, greaterThanOrEqualTo(34));

      // Filter for subset
      final subset = sheet.getActiveRowsFor({'1', '33'}, {'Sakthivel', 'Mithra'});
      expect(subset.length, 2);
      expect(subset.map((s) => s.empNo).toSet(), {'1', '33'});
    });
  });
}
