import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/models/attendance_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  group('Shift Status & Working Hours Tests', () {
    test('Employee logging out with < 8.0 hours is marked Left Early with actual hours', () {
      final loginPunch = AttendancePunchRecord(
        id: 'PUNCH-IN',
        enrollNumber: 'MN-CEO01',
        timestamp: DateTime(2026, 11, 5, 7, 49),
        punchType: AttendancePunchType.login,
      );
      final logoutPunch = AttendancePunchRecord(
        id: 'PUNCH-OUT',
        enrollNumber: 'MN-CEO01',
        timestamp: DateTime(2026, 11, 5, 11, 53),
        punchType: AttendancePunchType.logout,
      );

      final summary = EmployeeDailyAttendanceSummary(
        employeeId: 'MN-CEO01',
        employeeName: 'M N Naveenraaj',
        department: 'Executive Board',
        role: 'Managing Director & CEO',
        avatar: '',
        initials: 'MN',
        loginPunch: loginPunch,
        logoutPunch: logoutPunch,
        isPresent: true,
        isOnTime: true,
        isCurrentlyOnLunch: false,
        isCurrentlyOnDuty: false,
        lunchDurationMinutes: 0,
        netWorkHours: 4.07, // ~4h 4m
        status: DailyAttendanceStatus.completed,
      );

      expect(summary.isLeftEarly, isTrue);
      expect(summary.statusBadgeText, equals('Left Early'));
      expect(summary.workHoursFormatted, equals('4h 4m'));
      expect(summary.statusBadgeColor, equals(const Color(0xFFF59E0B))); // Amber
    });

    test('Employee logging out with >= 8.0 hours is marked Shift Over with actual hours', () {
      final loginPunch = AttendancePunchRecord(
        id: 'PUNCH-IN',
        enrollNumber: 'MN-1002',
        timestamp: DateTime(2026, 11, 5, 9, 30),
        punchType: AttendancePunchType.login,
      );
      final logoutPunch = AttendancePunchRecord(
        id: 'PUNCH-OUT',
        enrollNumber: 'MN-1002',
        timestamp: DateTime(2026, 11, 5, 18, 0),
        punchType: AttendancePunchType.logout,
      );

      final summary = EmployeeDailyAttendanceSummary(
        employeeId: 'MN-1002',
        employeeName: 'Praveenkumar M',
        department: 'Online Department',
        role: 'Team Lead',
        avatar: '',
        initials: 'PM',
        loginPunch: loginPunch,
        logoutPunch: logoutPunch,
        isPresent: true,
        isOnTime: true,
        isCurrentlyOnLunch: false,
        isCurrentlyOnDuty: false,
        lunchDurationMinutes: 30,
        netWorkHours: 8.0,
        status: DailyAttendanceStatus.completed,
      );

      expect(summary.isLeftEarly, isFalse);
      expect(summary.statusBadgeText, equals('Shift Over'));
      expect(summary.workHoursFormatted, equals('8h 0m'));
      expect(summary.statusBadgeColor, equals(const Color(0xFF8B5CF6))); // Purple
    });

    test('Employee actively on duty is marked On Duty', () {
      final loginPunch = AttendancePunchRecord(
        id: 'PUNCH-IN',
        enrollNumber: 'MN-1007',
        timestamp: DateTime(2026, 11, 5, 9, 15),
        punchType: AttendancePunchType.login,
      );

      final summary = EmployeeDailyAttendanceSummary(
        employeeId: 'MN-1007',
        employeeName: 'Kaaviya',
        department: 'Online Department',
        role: 'Online Sale Person 1',
        avatar: '',
        initials: 'KV',
        loginPunch: loginPunch,
        logoutPunch: null,
        isPresent: true,
        isOnTime: true,
        isCurrentlyOnLunch: false,
        isCurrentlyOnDuty: true,
        lunchDurationMinutes: 0,
        netWorkHours: 3.5,
        status: DailyAttendanceStatus.presentOnTime,
      );

      expect(summary.isLeftEarly, isFalse);
      expect(summary.statusBadgeText, equals('On Duty'));
      expect(summary.statusBadgeColor, equals(const Color(0xFF10B981))); // Emerald Green
    });
  });

  group('Permissions System Tests (HR & Employee)', () {
    testWidgets('HR can directly mark permission for an employee', (tester) async {
      final eco = EcosystemProvider();
      expect(eco.permissionRecords.isEmpty, isTrue);

      eco.markPermissionByHr(
        empId: 'MN-1007',
        hours: 1.5,
        reason: 'Bank work token appointment',
      );

      expect(eco.permissionRecords.length, equals(1));
      final rec = eco.permissionRecords.first;
      expect(rec.empId, equals('MN-1007'));
      expect(rec.actualHoursUsed, equals(1.5));
      expect(rec.reason, equals('Bank work token appointment'));
      expect(rec.status, equals('Approved'));
      expect(rec.grantedBy, equals('HR (Mohankumar G)'));
    });

    testWidgets('Employee can request permission and HR can approve it', (tester) async {
      final eco = EcosystemProvider();

      // Employee requests permission
      eco.requestEmployeePermission(
        empId: 'MN-1008',
        requestedHours: 1.0,
        reason: 'Hospital follow-up',
      );

      expect(eco.allPendingPermissions.length, equals(1));
      final pendingRec = eco.allPendingPermissions.first;
      expect(pendingRec.status, equals('Pending'));
      expect(pendingRec.grantedBy, equals('Employee Request'));

      // HR approves the permission
      eco.approvePermission(pendingRec.id);

      expect(eco.allPendingPermissions.isEmpty, isTrue);
      expect(eco.allApprovedPermissions.length, equals(1));
      final approvedRec = eco.allApprovedPermissions.first;
      expect(approvedRec.status, equals('Approved'));
    });

    testWidgets('HR can reject employee permission request', (tester) async {
      final eco = EcosystemProvider();

      eco.requestEmployeePermission(
        empId: 'MN-1007',
        requestedHours: 2.0,
        reason: 'Personal shopping',
      );

      final recId = eco.allPendingPermissions.first.id;
      eco.rejectPermission(recId);

      expect(eco.allPendingPermissions.isEmpty, isTrue);
      expect(eco.permissionRecords.first.status, equals('Rejected'));
    });
  });
}

