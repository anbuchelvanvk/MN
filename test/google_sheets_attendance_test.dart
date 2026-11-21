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

      // Verify that sheet is updated up to the 16th (Day 15 & 16 synced)
      expect(sheet.latestRecordedDay, equals(16));

      // Day 1..16 are recorded (Day 3 & 10 are holidays, Day 1..2 & 4..9 & 11..16 are present)
      expect(mohan.days[1]!.type, equals(HrAttendanceDayType.present));
      expect(mohan.days[3]!.type, equals(HrAttendanceDayType.holiday));
      expect(mohan.days[14]!.type, equals(HrAttendanceDayType.present));
      expect(mohan.days[15]!.type, equals(HrAttendanceDayType.present));
      expect(mohan.days[16]!.type, equals(HrAttendanceDayType.present));

      // Day 18.. are pending HR updates (NOT present!)
      expect(mohan.days[18]!.type, equals(HrAttendanceDayType.pendingUpdate));
      expect(mohan.days[31]!.type, equals(HrAttendanceDayType.pendingUpdate));

      // Days 17 & 24 are Sundays / Holidays
      expect(mohan.days[17]!.type, equals(HrAttendanceDayType.holiday));
      expect(mohan.days[24]!.type, equals(HrAttendanceDayType.holiday));

      // Present days count should count actual 'nil' days up to 16th (14 days for Mohankumar)
      expect(mohan.presentDaysCount, equals(14));
      expect(mohan.pendingDaysCount, greaterThan(0));

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
      // 1. Present / nil
      final p1 = HrAttendanceDayRecord.parse(1, 'nil');
      expect(p1.type, equals(HrAttendanceDayType.present));
      expect(p1.displayLabel, equals('Present'));

      // Empty cell should be pendingUpdate (awaiting HR entry)
      final pEmpty = HrAttendanceDayRecord.parse(18, '');
      expect(pEmpty.type, equals(HrAttendanceDayType.pendingUpdate));
      expect(pEmpty.displayLabel, equals('Yet to update'));

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

      // 8. Edge Cases: Composite permission formats & alternate phrases
      final comp1 = HrAttendanceDayRecord.parse(12, '1h 30m');
      expect(comp1.type, equals(HrAttendanceDayType.permission));
      expect(comp1.permissionMinutes, equals(90.0));

      final comp2 = HrAttendanceDayRecord.parse(13, '2 hrs 15 mins');
      expect(comp2.type, equals(HrAttendanceDayType.permission));
      expect(comp2.permissionMinutes, equals(135.0));

      final clPhrase = HrAttendanceDayRecord.parse(14, 'Casual Leave');
      expect(clPhrase.type, equals(HrAttendanceDayType.leaveCl));

      final lopPhrase = HrAttendanceDayRecord.parse(15, 'Loss Of Pay');
      expect(lopPhrase.type, equals(HrAttendanceDayType.leaveLop));

      final halfPhrase = HrAttendanceDayRecord.parse(16, 'Half-Day');
      expect(halfPhrase.type, equals(HrAttendanceDayType.leaveHalfDay));

      final onDuty = HrAttendanceDayRecord.parse(17, 'On Duty');
      expect(onDuty.type, equals(HrAttendanceDayType.mnw));

      // 9. Additional Edge Cases: Spaced late entries, permission prefixes, decimals, non-holiday single letters
      final lateSpaced = HrAttendanceDayRecord.parse(18, 'l 1');
      expect(lateSpaced.type, equals(HrAttendanceDayType.late));
      expect(lateSpaced.displayLabel, equals('L-1'));

      final lateDashSpaced = HrAttendanceDayRecord.parse(19, 'L - 2');
      expect(lateDashSpaced.type, equals(HrAttendanceDayType.late));
      expect(lateDashSpaced.displayLabel, equals('L-2'));

      final permPrefixed = HrAttendanceDayRecord.parse(20, 'perm 2h');
      expect(permPrefixed.type, equals(HrAttendanceDayType.permission));
      expect(permPrefixed.permissionMinutes, equals(120.0));

      final permDashPrefixed = HrAttendanceDayRecord.parse(21, 'p - 45m');
      expect(permDashPrefixed.type, equals(HrAttendanceDayType.permission));
      expect(permDashPrefixed.permissionMinutes, equals(45.0));

      final permDecimal = HrAttendanceDayRecord.parse(22, '0.5h');
      expect(permDecimal.type, equals(HrAttendanceDayType.permission));
      expect(permDecimal.permissionMinutes, equals(30.0));

      // On a non-holiday column (isColumnHoliday: false), 'A' is Absent (LOP), not holiday!
      final absent = HrAttendanceDayRecord.parse(23, 'A', isColumnHoliday: false);
      expect(absent.type, equals(HrAttendanceDayType.leaveLop));
      expect(absent.displayLabel, equals('Absent (LOP)'));

      // On a holiday column (isColumnHoliday: true), 'A' is a holiday vertical letter!
      final holidayLetter = HrAttendanceDayRecord.parse(24, 'A', isColumnHoliday: true);
      expect(holidayLetter.type, equals(HrAttendanceDayType.holiday));

      // WFH
      final wfh = HrAttendanceDayRecord.parse(25, 'wfh');
      expect(wfh.type, equals(HrAttendanceDayType.present));
    });

    test('Leave pooling and chronological CL vs LOP calculations work accurately', () {
      final daysMap = <int, HrAttendanceDayRecord>{
        1: HrAttendanceDayRecord.parse(1, 'nil'),
        2: HrAttendanceDayRecord.parse(2, '1/2 d'), // 0.5 CL
        3: HrAttendanceDayRecord.parse(3, 'H', isColumnHoliday: true),
        4: HrAttendanceDayRecord.parse(4, '1/2 d'), // 0.5 CL (CL full: 1.0)
        5: HrAttendanceDayRecord.parse(5, '1/2 d'), // 0.5 LOP (excess beyond 1 CL)
        6: HrAttendanceDayRecord.parse(6, 'lop'),   // 1.0 LOP
      };

      final empRow = HrEmployeeAttendanceRow(
        sNo: 1,
        empNo: '99',
        name: 'Test Staff',
        days: daysMap,
      );

      expect(empRow.clDaysUsed, equals(1.0));
      expect(empRow.lopDaysUsed, equals(1.5)); // 0.5 from 3rd half day + 1.0 explicit LOP
    });

    test('Employee matching with leading zeros and non-digit prefix', () {
      final sheet = GoogleSheetsAttendanceService.parseCsvToAttendanceSheet(GoogleSheetsAttendanceService.embeddedNovemberSeedCsv);
      // Sheet has '6' for Gokulakrishnan; profile may search with '06' or 'EMP-06'
      final match1 = sheet.findForEmployee(name: 'Gokulakrishnan K', empNo: '06');
      expect(match1, isNotNull);
      expect(match1!.name, equals('Gokulakrishnan'));

      final match2 = sheet.findForEmployee(name: 'Mohankumar G', empNo: 'EMP-07');
      expect(match2, isNotNull);
      expect(match2!.name, equals('Mohankumar'));
    });

    test('OTM Praveenkumar is exempt and has no employee number or attendance/grooming requirement', () {
      final eco = EcosystemProvider();
      final otm = eco.employees.firstWhere((e) => e.name.toLowerCase().contains('praveen'));
      expect(otm.isOtm, isTrue);
      expect(otm.hasAttendanceAndGrooming, isFalse);
      expect(otm.empNo, isEmpty);
      expect(otm.displayEmpId, equals('MN-TL1002'));

      // Check regular staff employee numbers
      final mohan = eco.employees.firstWhere((e) => e.name == 'Mohankumar G');
      expect(mohan.empNo, equals('7'));
      expect(mohan.displayEmpId, equals('7'));

      final gokul = eco.employees.firstWhere((e) => e.name == 'Gokulakrishnan K');
      expect(gokul.empNo, equals('6'));
      expect(gokul.displayEmpId, equals('6'));

      final mithra = eco.employees.firstWhere((e) => e.name == 'Mithra M');
      expect(mithra.empNo, equals('33'));
      expect(mithra.displayEmpId, equals('33'));

      final kaaviya = eco.employees.firstWhere((e) => e.name == 'Kaaviya');
      expect(kaaviya.empNo, equals('65'));
      expect(kaaviya.displayEmpId, equals('65'));

      final nisha = eco.employees.firstWhere((e) => e.name == 'Nisha');
      expect(nisha.empNo, equals('67'));
      expect(nisha.displayEmpId, equals('67'));

      // In-house corporate staff count is strictly 7 (Naveenraaj, Mohankumar, Praveenkumar, Gokulakrishnan, Mithra, Kaaviya, Nisha)
      // Plus External Support Staff [Online] (Aravinda Samy, Midhun Kumar, Subash, K B Eshwar, Sam Roy, and E-Commerce Executive)
      expect(eco.employees.where((e) => !e.isExternalSupport).length, equals(7));
      expect(eco.employees.length, equals(13));
    });

    test('Total permission quota is 4.0 Hours in EcosystemProvider', () {
      final eco = EcosystemProvider();
      expect(eco.monthlyPermissionHoursLimit, equals(4.0));
      expect(eco.permissionHoursRemaining, equals(4.0));
    });

    test('Parses EMP #77 Anbu from sheet and matches in findGoogleSheetEmployees', () {
      final eco = EcosystemProvider();
      final sheet = GoogleSheetsAttendanceService.parseCsvToAttendanceSheet(
        GoogleSheetsAttendanceService.embeddedNovemberSeedCsv,
      );
      eco.setAttendanceSheetForTesting(sheet);

      // Verify row 35 (EMP.NO 77, Anbu) is present
      final anbu = sheet.findForEmployee(name: 'Anbu', empNo: '77');
      expect(anbu, isNotNull);
      expect(anbu!.sNo, equals(35));
      expect(anbu.empNo, equals('77'));
      expect(anbu.name, equals('Anbu'));

      // Test searching with '77'
      final matchesByEmpNo = eco.findGoogleSheetEmployees('77', unassignedOnly: true);
      expect(matchesByEmpNo.isNotEmpty, isTrue);
      expect(matchesByEmpNo.first.name, equals('Anbu'));
      expect(matchesByEmpNo.first.empNo, equals('77'));

      // Test searching with S.NO '35'
      final matchesBySNo = eco.findGoogleSheetEmployees('35', unassignedOnly: true);
      expect(matchesBySNo.isNotEmpty, isTrue);
      expect(matchesBySNo.any((e) => e.name == 'Anbu'), isTrue);

      // Test searching with Name 'anbu'
      final matchesByName = eco.findGoogleSheetEmployees('anbu', unassignedOnly: true);
      expect(matchesByName.isNotEmpty, isTrue);
      expect(matchesByName.first.empNo, equals('77'));

      // Anbu is unassigned, not yet in active hired workforce
      expect(eco.findHiredEmployeeByIdOrEmpNo('77'), isNull);

      // Mohankumar (EMP NO: 7) is already hired
      expect(eco.findHiredEmployeeByIdOrEmpNo('7'), isNotNull);
      expect(eco.findHiredEmployeeByIdOrEmpNo('7')!.name, equals('Mohankumar G'));
    });

    test('Clean attendance update message formatting and notification dispatch', () {
      final eco = EcosystemProvider();

      // Test date range label cleaner
      const rawMultiDays = '1 NOVEMBER, 2 NOVEMBER, 4 NOVEMBER, 5 NOVEMBER, 6 NOVEMBER, 7 NOVEMBER, 8 NOVEMBER, 13 NOVEMBER, 14 NOVEMBER, 15 NOVEMBER';
      final cleanMulti = EcosystemProvider.formatAttendanceDateLabel(rawMultiDays);
      expect(cleanMulti, equals('November 1–15'));

      final cleanSingle = EcosystemProvider.formatAttendanceDateLabel('15 Nov');
      expect(cleanSingle, equals('November 15'));

      // Test broadcasting notification
      eco.broadcastAttendanceUpdateNotification('15 Nov');
      final notif = eco.activeCompanyNotifications.first;

      expect(notif.actionTag, equals('ATTENDANCE'));
      expect(notif.categoryLabel, equals('Attendance Update'));
      expect(notif.title, equals('📋 November 15 Attendance Update'));
      expect(
        notif.content,
        equals('November 15 Attendance update has been made by HR. Please head to your attendance section and check yours.'),
      );
    });
  });
}
