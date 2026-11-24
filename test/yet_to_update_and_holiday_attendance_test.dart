import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/models/attendance_models.dart';
import 'package:mn_family_app/models/hr_attendance_sheet_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Yet to Update and Holiday Attendance Tests', () {
    test('HR Sheet empty day parses as pendingUpdate with Yet to update label in yellow', () {
      final rec = HrAttendanceDayRecord.parse(18, '');
      expect(rec.type, HrAttendanceDayType.pendingUpdate);
      expect(rec.displayLabel, 'Yet to update');
      expect(rec.backgroundColor, const Color(0xFFFEF9C3));
      expect(rec.borderColor, const Color(0xFFFACC15));
      expect(rec.textColor, const Color(0xFFB45309));
    });

    test('HR Sheet Tuesday column parses as holiday', () {
      final rec = HrAttendanceDayRecord.parse(17, '', isColumnHoliday: true);
      expect(rec.type, HrAttendanceDayType.holiday);
      expect(rec.displayLabel, 'Holiday (Tuesday)');
      expect(rec.backgroundColor, const Color(0xFFF1F5F9));
      expect(rec.textColor, const Color(0xFF64748B));
    });

    test('DailyAttendanceStatus.yetToUpdate gives Yet to update badge in yellow', () {
      final summary = EmployeeDailyAttendanceSummary(
        employeeId: 'EMP-6',
        employeeName: 'Gokulakrishnan K',
        department: 'Online Department',
        role: 'Photographer',
        avatar: '',
        initials: 'GK',
        isPresent: false,
        isOnTime: false,
        isCurrentlyOnLunch: false,
        isCurrentlyOnDuty: false,
        lunchDurationMinutes: 0,
        netWorkHours: 0,
        status: DailyAttendanceStatus.yetToUpdate,
      );

      expect(summary.statusBadgeText, 'Yet to update');
      expect(summary.statusBadgeColor, const Color(0xFFF59E0B));
      expect(summary.isCurrentlyOnDuty, false);
    });

    test('DailyAttendanceStatus.weekOff gives Week off badge in slate/gray and NOT on duty', () {
      final summary = EmployeeDailyAttendanceSummary(
        employeeId: 'EMP-7',
        employeeName: 'Mohankumar G',
        department: 'Administration',
        role: 'HR Manager',
        avatar: '',
        initials: 'MG',
        isPresent: false,
        isOnTime: false,
        isCurrentlyOnLunch: false,
        isCurrentlyOnDuty: false,
        lunchDurationMinutes: 0,
        netWorkHours: 0,
        status: DailyAttendanceStatus.weekOff,
      );

      expect(summary.statusBadgeText, 'Week off');
      expect(summary.statusBadgeColor, const Color(0xFF94A3B8));
      expect(summary.isCurrentlyOnDuty, false);
    });

    test('EcosystemProvider allEmployeesTodayAttendance sets weekOff on Tuesday and does not mark showroom staff as on duty', () {
      final eco = EcosystemProvider();
      final summaries = eco.allEmployeesTodayAttendance;
      final now = DateTime.now();

      final showroomStaff = summaries.where((s) =>
        s.employeeId != 'MN-CEO01' &&
        !s.employeeId.toUpperCase().startsWith('EXT-') && // external support staff are exempt
        !s.employeeName.toLowerCase().contains('praveen') &&
        s.department != 'External Support Staff [Online]' &&
        !s.role.contains('External Support')
      ).toList();

      if (now.weekday == DateTime.tuesday) {
        for (final s in showroomStaff) {
          expect(s.isCurrentlyOnDuty, false);
          expect(s.status, DailyAttendanceStatus.weekOff);
          expect(s.statusBadgeText, 'Week off');
        }
      }
    });
  });
}
