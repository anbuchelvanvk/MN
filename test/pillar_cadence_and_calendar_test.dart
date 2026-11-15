import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/models/attendance_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Pillar Cadences & Full Calendar Verification Tests', () {
    late EcosystemProvider provider;

    setUp(() {
      provider = EcosystemProvider();
    });

    test('Full calendar days dynamic calculation for all 12 months (no static 26 days)', () {
      // Leap year 2024
      expect(provider.daysInMonth(2024, 1), 31); // Jan
      expect(provider.daysInMonth(2024, 2), 29); // Feb (Leap)
      expect(provider.daysInMonth(2024, 3), 31); // Mar
      expect(provider.daysInMonth(2024, 4), 30); // Apr
      expect(provider.daysInMonth(2024, 5), 31); // May
      expect(provider.daysInMonth(2024, 6), 30); // Jun
      expect(provider.daysInMonth(2024, 7), 31); // Jul
      expect(provider.daysInMonth(2024, 8), 31); // Aug
      expect(provider.daysInMonth(2024, 9), 30); // Sep
      expect(provider.daysInMonth(2024, 10), 31); // Oct
      expect(provider.daysInMonth(2024, 11), 30); // Nov
      expect(provider.daysInMonth(2024, 12), 31); // Dec

      // Non-leap year 2025
      expect(provider.daysInMonth(2025, 2), 28); // Feb (Non-leap)

      // Total calendar days for current month
      final now = DateTime.now();
      final expectedDays = DateTime(now.year, now.month + 1, 0).day;
      expect(provider.totalCalendarDaysInCurrentMonth, expectedDays);
      expect(provider.totalWorkingDaysInMonth, expectedDays);
    });

    test('getMonthlyAttendanceForEmployee generates full calendar records (28-31 days)', () {
      final empId = provider.employees.first.id;

      // February non-leap year (2025) -> 28 records
      final febRecords = provider.getMonthlyAttendanceForEmployee(empId, year: 2025, month: 2);
      expect(febRecords.length, 28);

      // January (31 days) -> 31 records
      final janRecords = provider.getMonthlyAttendanceForEmployee(empId, year: 2025, month: 1);
      expect(janRecords.length, 31);

      // April (30 days) -> 30 records
      final aprRecords = provider.getMonthlyAttendanceForEmployee(empId, year: 2025, month: 4);
      expect(aprRecords.length, 30);
    });

    test('Tuesday Week-off and Tuesday Overtime Rule Verification', () {
      final empId = provider.employees.first.id;

      // In November 2026:
      // Nov 3, 2026 is Tuesday
      // Nov 10, 2026 is Tuesday
      // Nov 17, 2026 is Tuesday
      // Nov 24, 2026 is Tuesday
      final novRecords = provider.getMonthlyAttendanceForEmployee(empId, year: 2026, month: 11);
      expect(novRecords.length, 30);

      // Find Tuesday Nov 3, 2026 without any punch
      final tuesdayNov3 = novRecords.firstWhere((r) => r.date.year == 2026 && r.date.month == 11 && r.date.day == 3);
      expect(tuesdayNov3.date.weekday, DateTime.tuesday);
      expect(tuesdayNov3.isWeekoff, isTrue);
      expect(tuesdayNov3.isOvertime, isFalse);
      expect(tuesdayNov3.status, 'Tuesday (Week-off)');

      // Record a punch on Tuesday Nov 10, 2026
      final tuesdayTime = DateTime(2026, 11, 10, 9, 30);
      final otPunchLogin = AttendancePunchRecord(
        id: 'TEST-OT-LOGIN',
        enrollNumber: empId,
        timestamp: tuesdayTime,
        punchType: AttendancePunchType.login,
      );
      final otPunchLogout = AttendancePunchRecord(
        id: 'TEST-OT-LOGOUT',
        enrollNumber: empId,
        timestamp: tuesdayTime.add(const Duration(hours: 8)),
        punchType: AttendancePunchType.logout,
      );

      provider.attendancePunches.add(otPunchLogin);
      provider.attendancePunches.add(otPunchLogout);

      final updatedNovRecords = provider.getMonthlyAttendanceForEmployee(empId, year: 2026, month: 11);
      final tuesdayNov10 = updatedNovRecords.firstWhere((r) => r.date.year == 2026 && r.date.month == 11 && r.date.day == 10);
      expect(tuesdayNov10.date.weekday, DateTime.tuesday);
      expect(tuesdayNov10.isOvertime, isTrue);
      expect(tuesdayNov10.isWeekoff, isFalse);
      expect(tuesdayNov10.status.contains('Tuesday Overtime'), isTrue);
    });

    test('Pillar Logs maintain date and time timestamps', () {
      // 1. Health Food Log
      provider.addFoodLog(
        foodName: 'Idli & Sambar',
        mealType: 'Breakfast',
        grams: 150,
        calories: 220,
      );
      expect(provider.dailyFoodLogs.isNotEmpty, isTrue);
      final foodLog = provider.dailyFoodLogs.first;
      expect(foodLog.timeString, isNotEmpty);
      expect(foodLog.timeString.contains(':'), isTrue); // Has time
      expect(foodLog.timeString.contains('202'), isTrue); // Has year

      // 2. Health Workout Log
      provider.addWorkoutLog(
        activityName: 'Brisk Walk',
        durationMinutes: 30,
        steps: 3500,
        distanceKm: 2.2,
        caloriesBurned: 120,
        intensity: 'Moderate',
        timeAllocation: 'Morning',
      );
      expect(provider.dailyWorkoutLogs.isNotEmpty, isTrue);
      final workoutLog = provider.dailyWorkoutLogs.first;
      expect(workoutLog.timeString, isNotEmpty);
      expect(workoutLog.timeString.contains(':'), isTrue);

      // 3. Family Activity Log
      provider.addFamilyActivity(
        activityName: 'Evening Dinner with Parents',
        category: 'Family',
        subCategory: 'Dinner',
        hoursSpent: 1.5,
        iconEmoji: '🍽️',
      );
      expect(provider.familyActivityLogs.isNotEmpty, isTrue);
      final familyLog = provider.familyActivityLogs.first;
      expect(familyLog.timeString, isNotEmpty);
      expect(familyLog.timeString.contains(':'), isTrue);

      // 4. Custody Document Log
      provider.addOriginalDocument(
        title: 'Degree Certificate',
        category: 'Education',
        certificateNumber: 'DEG-12345',
        vaultLockerRef: 'Safe Vault Locker #B-14',
      );
      final doc = provider.originalDocuments.firstWhere((d) => d.title == 'Degree Certificate');
      expect(doc.submissionDate, isNotEmpty);
      expect(doc.submissionDate.contains(':'), isTrue); // Date and time
    });

    test('Biometric punch deduplication ignores rapid identical punch within 3-5 seconds', () {
      // First login
      final result1 = provider.recordThumbImpressionPunch(
        punchType: AttendancePunchType.login,
      );
      expect(result1, isTrue);

      // Rapid duplicate login immediately
      final result2 = provider.recordThumbImpressionPunch(
        punchType: AttendancePunchType.login,
      );
      expect(result2, isFalse); // Debounced!
    });
  });
}
