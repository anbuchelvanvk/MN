import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/models/hr_attendance_sheet_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/services/google_sheets_attendance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Google Sheets Attendance Service & Models Tests', () {
    test('Parses HR Attendance CSV accurately with all color codes', () {
      final sheet = GoogleSheetsAttendanceService.parseCsvToAttendanceSheet(GoogleSheetsAttendanceService.embeddedNovemberSeedCsv);
      expect(sheet.employees.isNotEmpty, isTrue);
      expect(sheet.monthTitle, equals('NOVEMBER'));

      // Check Mohankumar G (EMP NO: 7)
      final mohan = sheet.findForEmployee(name: 'Mohankumar G', empNo: '7');
      expect(mohan, isNotNull);
      expect(mohan!.sNo, equals(5));
      expect(mohan.empNo, equals('7'));

      // Check Gokulakrishnan K (EMP NO: 6)
      final gokul = sheet.findForEmployee(name: 'Gokulakrishnan K', empNo: '6');
      expect(gokul, isNotNull);
      expect(gokul!.empNo, equals('6'));

      // Check Mithra M (EMP NO: 33)
      final mithra = sheet.findForEmployee(name: 'Mithra M', empNo: '33');
      expect(mithra, isNotNull);
      expect(mithra!.empNo, equals('33'));

      // Check Kaaviya (EMP NO: 65)
      final kaaviya = sheet.findForEmployee(name: 'Kaaviya', empNo: '65');
      expect(kaaviya, isNotNull);
      expect(kaaviya!.empNo, equals('65'));

      // Check Nisha (EMP NO: 67)
      final nisha = sheet.findForEmployee(name: 'Nisha', empNo: '67');
      expect(nisha, isNotNull);
      expect(nisha!.empNo, equals('67'));
    });

    test('Color category parsing and display labels match rules', () {
      // 1. Present / nil / empty
      final p1 = HrAttendanceDayRecord.parse(1, 'nil');
      expect(p1.type, equals(HrAttendanceDayType.present));
      expect(p1.displayLabel, equals('Present'));

      // 2. Late coming (Yellow: l-1, l-2)
      final l1 = HrAttendanceDayRecord.parse(2, 'l-1');
      expect(l1.type, equals(HrAttendanceDayType.late));
      expect(l1.backgroundColor.value, equals(0xFFFEF9C3));

      // 3. Leaves (Red: cl, lop, 1/2 d)
      final cl = HrAttendanceDayRecord.parse(3, 'cl');
      expect(cl.type, equals(HrAttendanceDayType.leaveCl));
      expect(cl.backgroundColor.value, equals(0xFFFEE2E2));

      final lop = HrAttendanceDayRecord.parse(4, 'lop');
      expect(lop.type, equals(HrAttendanceDayType.leaveLop));

      final halfD = HrAttendanceDayRecord.parse(5, '1/2 d');
      expect(halfD.type, equals(HrAttendanceDayType.leaveHalfDay));

      // 4. Permission (Green: 38 m, 1:58 m, 2 h, 4 h)
      final perm1 = HrAttendanceDayRecord.parse(6, '38 m');
      expect(perm1.type, equals(HrAttendanceDayType.permission));
      expect(perm1.permissionMinutes, equals(38.0));
      expect(perm1.backgroundColor.value, equals(0xFFDCFCE7));

      final perm2 = HrAttendanceDayRecord.parse(7, '1:58 m');
      expect(perm2.type, equals(HrAttendanceDayType.permission));
      expect(perm2.permissionMinutes, equals(118.0));

      final perm3 = HrAttendanceDayRecord.parse(8, '2 h');
      expect(perm3.type, equals(HrAttendanceDayType.permission));
      expect(perm3.permissionMinutes, equals(120.0));

      // 5. Orange: Late & Half day
      final lateHalf = HrAttendanceDayRecord.parse(9, 'l- & 1/2 d');
      expect(lateHalf.type, equals(HrAttendanceDayType.lateAndHalfDay));
      expect(lateHalf.backgroundColor.value, equals(0xFFFFEDD5));

      // 6. Dark Blue: MNW
      final mnw = HrAttendanceDayRecord.parse(10, 'mnw');
      expect(mnw.type, equals(HrAttendanceDayType.mnw));
      expect(mnw.backgroundColor.value, equals(0xFFDBEAFE));

      // 7. Gray: Holiday
      final h = HrAttendanceDayRecord.parse(11, 'H');
      expect(h.type, equals(HrAttendanceDayType.holiday));
      expect(h.backgroundColor.value, equals(0xFFF1F5F9));
    });

    test('OTM Praveenkumar is exempt and has no employee number or attendance/grooming requirement', () {
      final eco = EcosystemProvider();
      final otm = eco.employees.firstWhere((e) => e.name.toLowerCase().contains('praveen'));
      expect(otm.isOtm, isTrue);
      expect(otm.hasAttendanceAndGrooming, isFalse);
      expect(otm.empNo, isEmpty);
      expect(otm.displayEmpId, equals('OTM'));

      // Check regular staff employee numbers
      final mohan = eco.employees.firstWhere((e) => e.name == 'Mohankumar G');
      expect(mohan.empNo, equals('7'));
      expect(mohan.displayEmpId, equals('EMP #7'));

      final gokul = eco.employees.firstWhere((e) => e.name == 'Gokulakrishnan K');
      expect(gokul.empNo, equals('6'));
      expect(gokul.displayEmpId, equals('EMP #6'));

      final mithra = eco.employees.firstWhere((e) => e.name == 'Mithra M');
      expect(mithra.empNo, equals('33'));
      expect(mithra.displayEmpId, equals('EMP #33'));

      final kaaviya = eco.employees.firstWhere((e) => e.name == 'Kaaviya');
      expect(kaaviya.empNo, equals('65'));
      expect(kaaviya.displayEmpId, equals('EMP #65'));

      final nisha = eco.employees.firstWhere((e) => e.name == 'Nisha');
      expect(nisha.empNo, equals('67'));
      expect(nisha.displayEmpId, equals('EMP #67'));

      // Non-listed employees have empty empNo
      final aravind = eco.employees.firstWhere((e) => e.name.contains('Aravinda'));
      expect(aravind.empNo, isEmpty);
      expect(aravind.displayEmpId, isEmpty);
    });

    test('Total permission quota is 4.0 Hours in EcosystemProvider', () {
      final eco = EcosystemProvider();
      expect(eco.monthlyPermissionHoursLimit, equals(4.0));
      expect(eco.permissionHoursRemaining, equals(4.0));
    });
  });
}
