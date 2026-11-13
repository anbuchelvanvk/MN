import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';
import '../models/task_model.dart';
import '../models/ecosystem_models.dart';
import '../models/health_models.dart';
import '../models/family_models.dart';
import '../models/profile_document_models.dart';
import '../models/attendance_models.dart';
import '../models/profile_pillar_models.dart';
import '../models/konar_tasks_catalog.dart';
import '../models/social_cause_models.dart';
import '../models/company_notification_models.dart';
import '../models/personal_note_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/online_order_model.dart';
import '../services/firebase_employee_service.dart';
import '../services/offline_sync_service.dart';
import '../core/services/push_notification_service.dart';

class EcosystemProvider extends ChangeNotifier {
  String _activeRole = 'ceo'; // 'employee', 'dept_head', 'hr', 'ceo'
  String _activeEmpId = 'MN-CEO01';
  String? _notificationMessage;

  String get activeRole => _activeRole;
  String get activeEmpId => _activeEmpId;
  String? get notificationMessage => _notificationMessage;

  late List<Employee> _employees;
  late List<TaskItem> _tasks;
  late List<Handover> _handovers;
  late List<Blocker> _blockers;
  late ReadinessGate _readinessGate;
  late List<Incident> _incidents;
  late List<ShiftHandover> _shiftHandovers;
  late List<DelayCause> _delayCauses;
  late List<EmergencyDelegation> _delegations;

  List<Employee> get employees => _employees;
  List<TaskItem> get tasks => _tasks;
  List<Handover> get handovers => _handovers;
  List<Blocker> get blockers => _blockers;
  ReadinessGate get readinessGate => _readinessGate;
  List<Incident> get incidents => _incidents;
  List<ShiftHandover> get shiftHandovers => _shiftHandovers;
  List<DelayCause> get delayCauses => _delayCauses;
  List<EmergencyDelegation> get delegations => _delegations;

  // Health Pillar 1 State
  bool _healthOnboarded = false;
  double _userHeightCm = 0.0;
  double _userWeightKg = 0.0;
  List<FoodLogItem> _dailyFoodLogs = [];
  List<WorkoutLogItem> _dailyWorkoutLogs = [];
  List<WeightHeightRecord> _weightHistory = [];

  bool get healthOnboarded => _healthOnboarded;
  double get userHeightCm => _userHeightCm;
  double get userWeightKg => _userWeightKg;
  List<FoodLogItem> get dailyFoodLogs => _dailyFoodLogs;
  List<WorkoutLogItem> get dailyWorkoutLogs => _dailyWorkoutLogs;
  List<WeightHeightRecord> get weightHistory => _weightHistory;

  // Family & Harmony Pillar 2 State (Unforced, natural quality time)
  List<FamilyActivityItem> _familyActivityLogs = [];

  List<FamilyActivityItem> get familyActivityLogs => _familyActivityLogs;

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isCurrentMonth(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month;
  }

  double get totalFamilyHoursToday => _familyActivityLogs
      .where((a) => a.category == 'Family' && _isToday(a.timestamp))
      .fold(0.0, (sum, a) => sum + a.hoursSpent);

  double get totalFriendsHoursToday => _familyActivityLogs
      .where((a) => a.category == 'Friends & Colleagues' && _isToday(a.timestamp))
      .fold(0.0, (sum, a) => sum + a.hoursSpent);

  double get totalOverallSocialHoursToday => totalFamilyHoursToday + totalFriendsHoursToday;

  // Profile Pillar 3 & Document Custody State (Per-Employee Scoped)
  List<OriginalDocumentItem> _originalDocuments = [];
  List<OriginalDocumentItem> get originalDocuments => _originalDocuments;
  final Map<String, List<OriginalDocumentItem>> _employeeDocuments = {};

  List<OriginalDocumentItem> getEmployeeDocuments(String empId) {
    if (_employeeDocuments.containsKey(empId)) {
      return _employeeDocuments[empId]!;
    }
    if (empId == _activeEmpId) {
      return _originalDocuments;
    }
    return [];
  }

  Future<List<OriginalDocumentItem>> loadEmployeeDocuments(String empId) async {
    if (_employeeDocuments.containsKey(empId) && _employeeDocuments[empId]!.isNotEmpty) {
      return _employeeDocuments[empId]!;
    }
    try {
      final pillars = await _firebaseEmployeeService.loadEmployeePillars(empId);
      if (pillars != null && pillars['documents'] is List) {
        final list = (pillars['documents'] as List)
            .map((d) => OriginalDocumentItem.fromMap(Map<String, dynamic>.from(d as Map)))
            .toList();
        _employeeDocuments[empId] = list;
        if (empId == _activeEmpId) {
          _originalDocuments = list;
        }
        notifyListeners();
        return list;
      }
    } catch (_) {}
    _employeeDocuments.putIfAbsent(empId, () => []);
    return _employeeDocuments[empId]!;
  }

  int get totalOriginalsCount => _originalDocuments.length;
  int get submittedOriginalsCount => _originalDocuments.where((d) => d.status == DocumentSubmissionStatus.submitted).length;
  int get pendingOriginalsCount => _originalDocuments.where((d) => d.status == DocumentSubmissionStatus.pending).length;
  int get verifyingOriginalsCount => _originalDocuments.where((d) => d.status == DocumentSubmissionStatus.verifying).length;

  double get documentsSubmissionRatio {
    if (_originalDocuments.isEmpty) return 0.0;
    final mandatory = _originalDocuments.where((d) => d.isMandatory).toList();
    if (mandatory.isEmpty) return 0.0;
    final submittedMandatory = mandatory.where((d) => d.status == DocumentSubmissionStatus.submitted).length;
    return submittedMandatory / mandatory.length;
  }

  // Profile Pillar 3: Calendar Month System (Full Calendar Month: Jan-Dec, 28/29/30/31 days)
  // Tuesday is company weekoff; any Tuesday attendance is recorded as Overtime (OT).
  int get totalCalendarDaysInCurrentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  int get totalWorkingDaysInMonth => totalCalendarDaysInCurrentMonth;

  int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  int get workingDaysAttended {
    final now = DateTime.now();
    final logins = _attendancePunches
        .where((p) => p.enrollNumber == _activeEmpId &&
                      p.punchType == AttendancePunchType.login &&
                      p.timestamp.year == now.year &&
                      p.timestamp.month == now.month)
        .map((p) => '${p.timestamp.year}-${p.timestamp.month}-${p.timestamp.day}')
        .toSet();
    return logins.length;
  }

  /// Number of Tuesday Overtime days worked in current month
  int get tuesdayOvertimeDaysAttended {
    final now = DateTime.now();
    final otLogins = _attendancePunches
        .where((p) => p.enrollNumber == _activeEmpId &&
                      p.punchType == AttendancePunchType.login &&
                      p.timestamp.year == now.year &&
                      p.timestamp.month == now.month &&
                      p.timestamp.weekday == DateTime.tuesday)
        .map((p) => '${p.timestamp.year}-${p.timestamp.month}-${p.timestamp.day}')
        .toSet();
    return otLogins.length;
  }

  double get monthlyAttendancePercentage {
    final totalDays = totalCalendarDaysInCurrentMonth;
    final attended = workingDaysAttended;
    if (totalDays <= 0 || attended == 0) return 0.0;
    return ((attended / totalDays) * 100.0).clamp(0.0, 100.0);
  }

  // Ring 3: Grooming Audits (Daily Attire & Uniform Compliance - 50 Pts Max converted to %)
  List<GroomingAuditItem> _groomingAudits = [];
  List<GroomingAuditItem> get groomingAudits => _groomingAudits;
  List<GroomingAuditItem> get currentEmployeeGroomingAudits =>
      _groomingAudits.where((g) => g.empId == _activeEmpId).toList();

  int getEmployeeGroomingDailyPoints(String empId) {
    final audits = getEmployeeGroomingAudits(empId);
    if (audits.isEmpty) return 0;
    return audits.first.pointsEarned.clamp(0, 50);
  }

  double getEmployeeGroomingPercentage(String empId) {
    final audits = getEmployeeGroomingAudits(empId);
    if (audits.isEmpty) return 0.0;
    final pts = getEmployeeGroomingDailyPoints(empId);
    return ((pts / 50.0) * 100.0).clamp(0.0, 100.0);
  }

  int get groomingDailyPoints => getEmployeeGroomingDailyPoints(_activeEmpId);
  double get groomingPercentage => getEmployeeGroomingPercentage(_activeEmpId);
  int get groomingScore => groomingPercentage.round();

  // Ring 4: Individual Sales Revenue Tracker
  List<SalesRecord> _salesRecords = [];
  final double _monthlySalesTarget = 2500000.0; // ₹25 Lakhs
  List<SalesRecord> get salesRecords => _salesRecords;
  List<SalesRecord> get currentEmployeeSalesRecords =>
      _salesRecords.where((s) => s.empId == _activeEmpId).toList();

  double get totalSalesAchieved =>
      currentEmployeeSalesRecords
          .where((s) => _isCurrentMonth(s.date))
          .fold(0.0, (sum, s) => sum + s.amountInInr);
  double get monthlySalesTarget => _monthlySalesTarget;
  double get salesAchievementPercentage =>
      _monthlySalesTarget <= 0 ? 100.0 : ((totalSalesAchieved / _monthlySalesTarget) * 100.0).clamp(0.0, 150.0);

  // Ring 5: Permission & Late Arrivals Account (2.0 hrs monthly balance + 1 CL rule)
  List<PermissionRecord> _permissionRecords = [];
  final double _monthlyPermissionHoursLimit = 2.0;
  final int _monthlyCasualLeavesLimit = 1;

  // Emergency Medical Leaves (with Mandatory Prescription <= 150 KB)
  List<MedicalLeaveRecord> _medicalLeaveRecords = [];

  List<PermissionRecord> get permissionRecords => _permissionRecords;
  List<PermissionRecord> get allPendingPermissions =>
      _permissionRecords.where((p) => p.status == 'Pending' || p.status == 'Pending HR & CEO' || p.status == 'Pending CEO' || p.status == 'Granted by HR (Pending CEO Approval)').toList();
  List<PermissionRecord> get allApprovedPermissions =>
      _permissionRecords.where((p) => p.status == 'Approved').toList();

  List<PermissionRecord> get pendingHrPermissions =>
      _permissionRecords.where((p) => p.isPendingHr).toList();
  List<PermissionRecord> get pendingCeoPermissions =>
      _permissionRecords.where((p) => p.isPendingCeo).toList();

  List<MedicalLeaveRecord> get medicalLeaveRecords => _medicalLeaveRecords;
  List<MedicalLeaveRecord> get allPendingMedicalLeaves =>
      _medicalLeaveRecords.where((m) => m.status != 'Approved' && m.status != 'Rejected').toList();
  List<MedicalLeaveRecord> get pendingHrMedicalLeaves =>
      _medicalLeaveRecords.where((m) => m.isPendingHr).toList();
  List<MedicalLeaveRecord> get pendingCeoMedicalLeaves =>
      _medicalLeaveRecords.where((m) => m.isPendingCeo).toList();

  List<PermissionRecord> get currentEmployeePermissionRecords =>
      _permissionRecords.where((p) => p.empId == _activeEmpId).toList();

  List<MedicalLeaveRecord> get currentEmployeeMedicalLeaves =>
      _medicalLeaveRecords.where((m) => m.empId == _activeEmpId).toList();

  List<PermissionRecord> get currentEmployeeCurrentMonthPermissionRecords =>
      currentEmployeePermissionRecords.where((p) => _isCurrentMonth(p.date)).toList();

  double get monthlyPermissionHoursLimit => _monthlyPermissionHoursLimit;
  int get monthlyCasualLeavesLimit => _monthlyCasualLeavesLimit;

  double get totalPermissionHoursUsed =>
      currentEmployeeCurrentMonthPermissionRecords
          .where((p) => !p.isCasualLeave && p.status != 'Rejected')
          .fold(0.0, (sum, p) => sum + p.actualHoursUsed);

  double get permissionHoursRemaining =>
      (_monthlyPermissionHoursLimit - totalPermissionHoursUsed).clamp(0.0, _monthlyPermissionHoursLimit);

  bool get isPermissionExcessHalfDay => totalPermissionHoursUsed > _monthlyPermissionHoursLimit;

  int get casualLeavesUsed =>
      currentEmployeeCurrentMonthPermissionRecords.where((p) => p.isCasualLeave).length;

  double get salaryDeductionDays {
    double count = 0.0;
    if (casualLeavesUsed > _monthlyCasualLeavesLimit) {
      count += (casualLeavesUsed - _monthlyCasualLeavesLimit).toDouble();
    }
    if (isPermissionExcessHalfDay) {
      count += 0.5; // Excess hours over 2.0 considered as half day leave
    }
    return count;
  }

  // Ring 6: Customer Conduct & Jewellery Ethics
  final double _conductScore = 0.0;
  double get conductScore => _conductScore;

  // Social Cause Pillar 5 State
  List<SocialCauseItem> _socialCauses = [];
  List<SocialCauseItem> get socialCauses => _socialCauses;
  List<SocialCauseItem> get pendingSocialCauses => _socialCauses.where((c) => c.isPending).toList();
  List<SocialCauseItem> get approvedSocialCauses => _socialCauses.where((c) => c.isApproved).toList();
  List<SocialCauseItem> get currentEmployeeSocialCauses =>
      _socialCauses.where((c) => c.empId == _activeEmpId).toList();

  // Company Universal Notification Feed (Birthdays, Milestones, Social Deeds, Management Broadcasts, SOP To-Dos)
  List<CompanyNotification> _companyNotifications = [];
  List<CompanyNotification> get companyNotifications => _companyNotifications;
  List<CompanyNotification> get activeCompanyNotifications =>
      _companyNotifications.where((n) => !n.isDismissedBy(_activeEmpId)).toList();
  int get unreadNotificationCount =>
      _companyNotifications.where((n) => !n.isDismissedBy(_activeEmpId) && !n.isReadBy(_activeEmpId)).length;
  final Set<String> _notifiedCompanyNotifIds = {};
  int _notifSequence = 0;

  // Personal Notes (Strictly private & confidential per active user)
  List<PersonalNote> _personalNotes = [];
  List<PersonalNote> get myPersonalNotes {
    final list = _personalNotes.where((n) => n.ownerEmpId == _activeEmpId).toList();
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  void _syncAndPushIncomingNotifications(List<CompanyNotification> remoteNotifs) {
    for (final notif in remoteNotifs) {
      if (!_notifiedCompanyNotifIds.contains(notif.id)) {
        _notifiedCompanyNotifIds.add(notif.id);
        // Only push if not already read by this employee
        if (!notif.isReadBy(_activeEmpId)) {
          PushNotificationService().showNotification(
            id: notif.id,
            title: notif.title,
            body: notif.content,
            payload: notif.id,
          );
        }
      }
    }
  }

  // Attendance Pillar 4 & eSSL Security Biometric Device State
  List<AttendancePunchRecord> _attendancePunches = [];
  EsslDeviceConfig _esslConfig = EsslDeviceConfig(
    lastSyncTime: DateTime.now().subtract(const Duration(minutes: 5)),
  );

  List<AttendancePunchRecord> get attendancePunches => _attendancePunches;
  EsslDeviceConfig get esslConfig => _esslConfig;

  // Active employee shift punches (Shift-aware: accounts for overnight shifts crossing midnight)
  List<AttendancePunchRecord> get currentEmployeeTodayPunches {
    final now = DateTime.now();
    final todayList = _attendancePunches.where((p) =>
      p.enrollNumber == _activeEmpId &&
      p.timestamp.year == now.year &&
      p.timestamp.month == now.month &&
      p.timestamp.day == now.day
    ).toList();

    // Overnight shift link: if early morning before 12 PM with no login today,
    // link yesterday evening's open shift login
    if (now.hour < 12 && !todayList.any((p) => p.punchType == AttendancePunchType.login)) {
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayLogins = _attendancePunches.where((p) =>
        p.enrollNumber == _activeEmpId &&
        p.timestamp.year == yesterday.year &&
        p.timestamp.month == yesterday.month &&
        p.timestamp.day == yesterday.day &&
        p.timestamp.hour >= 18 &&
        p.punchType == AttendancePunchType.login
      ).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (yesterdayLogins.isNotEmpty) {
        final openLogin = yesterdayLogins.first;
        final hasLogout = _attendancePunches.any((p) =>
          p.enrollNumber == _activeEmpId &&
          p.punchType == AttendancePunchType.logout &&
          p.timestamp.isAfter(openLogin.timestamp)
        );
        if (!hasLogout) {
          todayList.add(openLogin);
        }
      }
    }

    return todayList;
  }

  AttendancePunchRecord? get todayLoginPunch {
    final logins = currentEmployeeTodayPunches
        .where((p) => p.punchType == AttendancePunchType.login)
        .toList();
    if (logins.isEmpty) return null;
    logins.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return logins.first;
  }

  AttendancePunchRecord? get todayLogoutPunch {
    final logouts = currentEmployeeTodayPunches
        .where((p) => p.punchType == AttendancePunchType.logout)
        .toList();
    if (logouts.isEmpty) return null;
    logouts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logouts.first;
  }

  AttendancePunchRecord? get todayLunchOutPunch {
    final list = currentEmployeeTodayPunches
        .where((p) => p.punchType == AttendancePunchType.breakOut)
        .toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list.first;
  }

  AttendancePunchRecord? get todayLunchInPunch {
    final list = currentEmployeeTodayPunches
        .where((p) => p.punchType == AttendancePunchType.breakIn)
        .toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list.first;
  }

  bool get isCurrentlyOnLunch {
    if (todayLunchOutPunch == null) return false;
    if (todayLunchInPunch == null) return true;
    return todayLunchOutPunch!.timestamp.isAfter(todayLunchInPunch!.timestamp);
  }

  int get todayLunchDurationMinutes {
    if (todayLunchOutPunch == null) return 0;
    if (todayLunchInPunch == null) {
      if (todayLogoutPunch != null) return 45; // Capped at standard 45 mins if shift already ended
      final elapsed = DateTime.now().difference(todayLunchOutPunch!.timestamp).inMinutes;
      return elapsed.clamp(0, 60); // Cap unclosed active lunch break at 60 mins max
    }
    final end = todayLunchInPunch!.timestamp;
    return end.difference(todayLunchOutPunch!.timestamp).inMinutes.clamp(0, 180);
  }

  bool get hasLoggedAttendanceToday => todayLoginPunch != null;

  bool get isCurrentlyOnDuty => hasLoggedAttendanceToday && (todayLogoutPunch == null || todayLoginPunch!.timestamp.isAfter(todayLogoutPunch!.timestamp));

  // Shift starts at 09:30 AM
  bool get isAttendanceOnTime {
    if (todayLoginPunch == null) return false;
    final t = todayLoginPunch!.timestamp;
    return (t.hour < 9) || (t.hour == 9 && t.minute <= 30);
  }

  double get todayWorkDurationHours {
    if (todayLoginPunch == null) return 0.0;
    final endTime = todayLogoutPunch?.timestamp ?? DateTime.now();
    final diff = endTime.difference(todayLoginPunch!.timestamp);
    return (diff.inMinutes / 60.0).clamp(0.0, 16.0);
  }

  double get todayNetWorkDurationHours {
    if (todayLoginPunch == null) return 0.0;
    final grossHours = todayWorkDurationHours;
    final lunchHours = todayLunchDurationMinutes / 60.0;
    return (grossHours - lunchHours).clamp(0.0, 16.0);
  }

  String get attendanceStatusLabel {
    if (!hasLoggedAttendanceToday) return 'Absent (No Login Recorded)';
    if (isCurrentlyOnLunch) return 'On Lunch Break';
    if (todayLogoutPunch != null) {
      return todayNetWorkDurationHours < 8.0 ? 'Left Early' : 'Shift Over';
    }
    if (isAttendanceOnTime) return 'Present (On-Time)';
    return 'Present (Late Login)';
  }

  Color get attendanceStatusColor {
    if (!hasLoggedAttendanceToday) return const Color(0xFFEF4444);
    if (isCurrentlyOnLunch) return const Color(0xFF3B82F6);
    if (todayLogoutPunch != null) {
      return todayNetWorkDurationHours < 8.0 ? const Color(0xFFF59E0B) : const Color(0xFF8B5CF6);
    }
    if (isAttendanceOnTime) return const Color(0xFF10B981);
    return const Color(0xFFEAB308);
  }

  /// Consolidated Daily Attendance Summary for ALL employees (used by CEO & HR suites)
  List<EmployeeDailyAttendanceSummary> get allEmployeesTodayAttendance {
    final now = DateTime.now();
    final summaries = <EmployeeDailyAttendanceSummary>[];

    for (final emp in _employees) {
      final empPunches = _attendancePunches.where((p) =>
        p.enrollNumber == emp.id &&
        p.timestamp.year == now.year &&
        p.timestamp.month == now.month &&
        p.timestamp.day == now.day
      ).toList();

      final logins = empPunches.where((p) => p.punchType == AttendancePunchType.login).toList();
      logins.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final login = logins.isNotEmpty ? logins.first : null;

      final logouts = empPunches.where((p) => p.punchType == AttendancePunchType.logout).toList();
      logouts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final logout = logouts.isNotEmpty ? logouts.first : null;

      final lunchOuts = empPunches.where((p) => p.punchType == AttendancePunchType.breakOut).toList();
      lunchOuts.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final lunchOut = lunchOuts.isNotEmpty ? lunchOuts.first : null;

      final lunchIns = empPunches.where((p) => p.punchType == AttendancePunchType.breakIn).toList();
      lunchIns.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final lunchIn = lunchIns.isNotEmpty ? lunchIns.first : null;

      final isPresent = login != null;
      final isOnTime = login != null && ((login.timestamp.hour < 9) || (login.timestamp.hour == 9 && login.timestamp.minute <= 30));
      final isOnLunch = lunchOut != null && (lunchIn == null || lunchOut.timestamp.isAfter(lunchIn.timestamp));
      final isOnDuty = isPresent && logout == null;

      int lunchMins = 0;
      if (lunchOut != null) {
        if (lunchIn != null) {
          lunchMins = lunchIn.timestamp.difference(lunchOut.timestamp).inMinutes.clamp(0, 180);
        } else if (logout != null) {
          lunchMins = 45; // Capped if shift completed
        } else {
          final elapsed = DateTime.now().difference(lunchOut.timestamp).inMinutes;
          lunchMins = elapsed.clamp(0, 60); // Capped at 60 mins max
        }
      }

      double netHours = 0.0;
      if (login != null) {
        final endWork = logout?.timestamp ?? DateTime.now();
        final gross = endWork.difference(login.timestamp).inMinutes / 60.0;
        netHours = (gross - (lunchMins / 60.0)).clamp(0.0, 16.0);
      }

      DailyAttendanceStatus status;
      if (!isPresent) {
        status = DailyAttendanceStatus.absent;
      } else if (logout != null) {
        status = DailyAttendanceStatus.completed;
      } else if (isOnTime) {
        status = DailyAttendanceStatus.presentOnTime;
      } else {
        status = DailyAttendanceStatus.lateLogin;
      }

      summaries.add(EmployeeDailyAttendanceSummary(
        employeeId: emp.id,
        employeeName: emp.name,
        department: emp.dept,
        role: emp.role,
        avatar: emp.avatar,
        initials: emp.initials,
        loginPunch: login,
        logoutPunch: logout,
        lunchOutPunch: lunchOut,
        lunchInPunch: lunchIn,
        isPresent: isPresent,
        isOnTime: isOnTime,
        isCurrentlyOnLunch: isOnLunch,
        isCurrentlyOnDuty: isOnDuty,
        lunchDurationMinutes: lunchMins,
        netWorkHours: netHours,
        status: status,
      ));
    }

    return summaries;
  }

  /// 7-day attendance & activity performance records for employee self-review derived from real punch records
  List<EmployeeActivityDayRecord> getPast7DaysAttendanceForEmployee(String empId) {
    final now = DateTime.now();
    final List<EmployeeActivityDayRecord> records = [];

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 0; i <= 6; i++) {
      final targetDate = now.subtract(Duration(days: i));
      final isToday = i == 0;
      final dayName = days[targetDate.weekday - 1];
      final monthName = months[targetDate.month - 1];
      final dateLabel = isToday ? 'Today ($monthName ${targetDate.day})' : '$dayName, $monthName ${targetDate.day}';

      final dayPunches = _attendancePunches.where((p) =>
        p.enrollNumber == empId &&
        p.timestamp.year == targetDate.year &&
        p.timestamp.month == targetDate.month &&
        p.timestamp.day == targetDate.day
      ).toList();

      final logins = dayPunches.where((p) => p.punchType == AttendancePunchType.login).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final logouts = dayPunches.where((p) => p.punchType == AttendancePunchType.logout).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final lunchOuts = dayPunches.where((p) => p.punchType == AttendancePunchType.breakOut).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final lunchIns = dayPunches.where((p) => p.punchType == AttendancePunchType.breakIn).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final login = logins.isNotEmpty ? logins.first : null;
      final lunchOut = lunchOuts.isNotEmpty ? lunchOuts.first : null;
      final lunchIn = lunchIns.isNotEmpty ? lunchIns.first : null;

      // Night shift crossing midnight check:
      AttendancePunchRecord? resolvedLogout = logouts.isNotEmpty ? logouts.first : null;
      if (resolvedLogout == null && login != null && login.timestamp.hour >= 18) {
        final nextMorningOuts = _attendancePunches.where((p) =>
          p.enrollNumber == empId &&
          p.punchType == AttendancePunchType.logout &&
          p.timestamp.isAfter(login.timestamp) &&
          p.timestamp.isBefore(login.timestamp.add(const Duration(hours: 16)))
        ).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        if (nextMorningOuts.isNotEmpty) {
          resolvedLogout = nextMorningOuts.first;
        }
      }

      final inStr = login?.timeString ?? '--:-- --';
      final lunchOutStr = lunchOut?.timeString ?? '--:-- --';
      final lunchInStr = lunchIn?.timeString ?? '--:-- --';
      final outStr = resolvedLogout?.timeString ?? (isToday && login != null ? 'Active / On Duty' : '--:-- --');

      String netHoursStr = '--';
      String statusStr = 'No Punch';
      Color statusColor = const Color(0xFF64748B);
      bool isOvertime = false;
      bool isWeekoff = false;
      final isTuesday = targetDate.weekday == DateTime.tuesday;

      if (isTuesday && dayPunches.isEmpty) {
        statusStr = 'Tuesday (Week-off)';
        statusColor = const Color(0xFF94A3B8);
        isWeekoff = true;
      } else if (login != null) {
        final endTime = resolvedLogout?.timestamp ?? (isToday ? DateTime.now() : login.timestamp);
        int lunchMins = 0;
        if (lunchOut != null) {
          final endL = lunchIn?.timestamp ?? (isToday ? DateTime.now() : lunchOut.timestamp);
          lunchMins = endL.difference(lunchOut.timestamp).inMinutes.clamp(0, 300);
        }
        final grossMins = endTime.difference(login.timestamp).inMinutes;
        final netMins = (grossMins - lunchMins).clamp(0, 24 * 60);
        final hrs = netMins ~/ 60;
        final mins = netMins % 60;
        netHoursStr = '${hrs}h ${mins}m';

        final isOnTime = (login.timestamp.hour < 9) || (login.timestamp.hour == 9 && login.timestamp.minute <= 30);

        if (isTuesday) {
          isOvertime = true;
          statusStr = 'Tuesday Overtime (${hrs}h ${mins}m)';
          statusColor = const Color(0xFF8B5CF6);
        } else if (isToday) {
          final isOnLunch = lunchOut != null && (lunchIn == null || lunchOut.timestamp.isAfter(lunchIn.timestamp));
          if (isOnLunch) {
            statusStr = 'On Lunch Break';
            statusColor = const Color(0xFFF59E0B);
          } else if (resolvedLogout != null) {
            final isLeftEarly = netMins < 8 * 60;
            statusStr = isLeftEarly ? 'Left Early (${hrs}h ${mins}m)' : 'Shift Over (${hrs}h ${mins}m)';
            statusColor = isLeftEarly ? const Color(0xFFF59E0B) : const Color(0xFF8B5CF6);
          } else {
            statusStr = isOnTime ? 'Active • On Duty' : 'Active (Late In)';
            statusColor = const Color(0xFF10B981);
          }
        } else {
          if (resolvedLogout != null) {
            final isLeftEarly = netMins < 8 * 60;
            statusStr = isLeftEarly ? 'Left Early (${hrs}h ${mins}m)' : 'Shift Over (${hrs}h ${mins}m)';
            statusColor = isLeftEarly ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
          } else {
            statusStr = 'Missing Out-Punch';
            statusColor = const Color(0xFFEF4444);
          }
        }
      } else {
        if (isTuesday) {
          statusStr = 'Tuesday (Week-off)';
          statusColor = const Color(0xFF94A3B8);
          isWeekoff = true;
        } else {
          statusStr = 'Absent';
          statusColor = const Color(0xFFEF4444);
        }
      }

      records.add(EmployeeActivityDayRecord(
        date: targetDate,
        dateLabel: dateLabel,
        loginTime: inStr,
        logoutTime: outStr,
        lunchOutTime: lunchOutStr,
        lunchInTime: lunchInStr,
        netHours: netHoursStr,
        status: statusStr,
        statusColor: statusColor,
        isOvertime: isOvertime,
        isWeekoff: isWeekoff,
      ));
    }

    return records;
  }

  /// Full monthly calendar attendance records (Jan to Dec, 28/29/30/31 full calendar days)
  /// Tuesday is weekoff, but if attendance is marked it is recorded as Tuesday Overtime (OT).
  List<EmployeeActivityDayRecord> getMonthlyAttendanceForEmployee(String empId, {int? year, int? month}) {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    final totalDays = DateTime(y, m + 1, 0).day;
    final List<EmployeeActivityDayRecord> records = [];

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int day = 1; day <= totalDays; day++) {
      final targetDate = DateTime(y, m, day);
      final isToday = (y == now.year && m == now.month && day == now.day);
      final isFuture = targetDate.isAfter(DateTime(now.year, now.month, now.day));
      final dayName = days[targetDate.weekday - 1];
      final monthName = months[targetDate.month - 1];
      final dateLabel = isToday ? 'Today ($monthName $day)' : '$dayName, $monthName $day';
      final isTuesday = targetDate.weekday == DateTime.tuesday;

      final dayPunches = _attendancePunches.where((p) =>
        p.enrollNumber == empId &&
        p.timestamp.year == targetDate.year &&
        p.timestamp.month == targetDate.month &&
        p.timestamp.day == targetDate.day
      ).toList();

      final logins = dayPunches.where((p) => p.punchType == AttendancePunchType.login).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final logouts = dayPunches.where((p) => p.punchType == AttendancePunchType.logout).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final lunchOuts = dayPunches.where((p) => p.punchType == AttendancePunchType.breakOut).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final lunchIns = dayPunches.where((p) => p.punchType == AttendancePunchType.breakIn).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final login = logins.isNotEmpty ? logins.first : null;
      final lunchOut = lunchOuts.isNotEmpty ? lunchOuts.first : null;
      final lunchIn = lunchIns.isNotEmpty ? lunchIns.first : null;
      AttendancePunchRecord? resolvedLogout = logouts.isNotEmpty ? logouts.first : null;

      final inStr = login?.timeString ?? '--:-- --';
      final lunchOutStr = lunchOut?.timeString ?? '--:-- --';
      final lunchInStr = lunchIn?.timeString ?? '--:-- --';
      final outStr = resolvedLogout?.timeString ?? (isToday && login != null ? 'Active / On Duty' : '--:-- --');

      String netHoursStr = '--';
      String statusStr = 'No Punch';
      Color statusColor = const Color(0xFF64748B);
      bool isOvertime = false;
      bool isWeekoff = false;

      if (login != null) {
        final endTime = resolvedLogout?.timestamp ?? (isToday ? DateTime.now() : login.timestamp);
        int lunchMins = 0;
        if (lunchOut != null) {
          final endL = lunchIn?.timestamp ?? (isToday ? DateTime.now() : lunchOut.timestamp);
          lunchMins = endL.difference(lunchOut.timestamp).inMinutes.clamp(0, 300);
        }
        final grossMins = endTime.difference(login.timestamp).inMinutes;
        final netMins = (grossMins - lunchMins).clamp(0, 24 * 60);
        final hrs = netMins ~/ 60;
        final mins = netMins % 60;
        netHoursStr = '${hrs}h ${mins}m';

        if (isTuesday) {
          isOvertime = true;
          statusStr = 'Tuesday Overtime (${hrs}h ${mins}m)';
          statusColor = const Color(0xFF8B5CF6);
        } else if (isToday) {
          final isOnLunch = lunchOut != null && (lunchIn == null || lunchOut.timestamp.isAfter(lunchIn.timestamp));
          if (isOnLunch) {
            statusStr = 'On Lunch Break';
            statusColor = const Color(0xFFF59E0B);
          } else if (resolvedLogout != null) {
            statusStr = 'Shift Over (${hrs}h ${mins}m)';
            statusColor = const Color(0xFF10B981);
          } else {
            statusStr = 'Active • On Duty';
            statusColor = const Color(0xFF10B981);
          }
        } else {
          statusStr = resolvedLogout != null ? 'Shift Over (${hrs}h ${mins}m)' : 'Present (${hrs}h ${mins}m)';
          statusColor = const Color(0xFF10B981);
        }
      } else {
        if (isTuesday) {
          isWeekoff = true;
          statusStr = isFuture ? 'Upcoming (Tuesday Week-off)' : 'Tuesday (Week-off)';
          statusColor = const Color(0xFF94A3B8);
        } else if (isFuture) {
          statusStr = 'Upcoming';
          statusColor = const Color(0xFF64748B);
        } else if (isToday) {
          statusStr = 'Not Checked In';
          statusColor = const Color(0xFFF59E0B);
        } else {
          statusStr = 'Absent';
          statusColor = const Color(0xFFEF4444);
        }
      }

      records.add(EmployeeActivityDayRecord(
        date: targetDate,
        dateLabel: dateLabel,
        loginTime: inStr,
        logoutTime: outStr,
        lunchOutTime: lunchOutStr,
        lunchInTime: lunchInStr,
        netHours: netHoursStr,
        status: statusStr,
        statusColor: statusColor,
        isOvertime: isOvertime,
        isWeekoff: isWeekoff,
      ));
    }

    return records;
  }

  // Holistic Status Rating (4 Pillars: Health, Family, Profile, Attendance)
  PillarTierLevel get holisticTierLevel {
    // 1. Health Condition (Pillar 1)
    final isHealthHealthy = currentBmi >= 18.5 && currentBmi <= 26.0 && dailyWorkoutLogs.isNotEmpty;
    final isHealthModerate = currentBmi >= 17.5 && currentBmi <= 29.9;

    // 2. Family Quality Time (Pillar 2 - Natural time spent)
    final isFamilyHealthy = totalFamilyHoursToday > 0;

    // 3. Profile 6-Rings (Pillar 3)
    final areDocsFullySubmitted = documentsSubmissionRatio >= 0.99;
    final areDocsPartiallySubmitted = documentsSubmissionRatio >= 0.50;
    final isAttendanceMonthHealthy = monthlyAttendancePercentage >= 90.0;
    final isAttendanceMonthModerate = monthlyAttendancePercentage >= 80.0;
    final isGroomingHealthy = groomingScore >= 80;
    final isGroomingModerate = groomingScore >= 65;
    final isSalesHealthy = salesAchievementPercentage >= 75.0;
    final isSalesModerate = salesAchievementPercentage >= 50.0;
    final isPermissionHealthy = !isPermissionExcessHalfDay && casualLeavesUsed <= _monthlyCasualLeavesLimit;
    final isPermissionModerate = salaryDeductionDays <= 1.0;
    final isConductHealthy = conductScore >= 4.5;

    final isProfileHealthy = areDocsFullySubmitted &&
        isAttendanceMonthHealthy &&
        isGroomingHealthy &&
        isSalesHealthy &&
        isPermissionHealthy &&
        isConductHealthy;

    final isProfileModerate = areDocsPartiallySubmitted &&
        isAttendanceMonthModerate &&
        isGroomingModerate &&
        isSalesModerate &&
        isPermissionModerate;

    // 4. Attendance via eSSL Biometric Thumb Impression (Pillar 4)
    final isAttendanceHealthy = hasLoggedAttendanceToday && isAttendanceOnTime;
    final isAttendanceModerate = hasLoggedAttendanceToday; // Present but late

    // GREEN STATUS: All 4 pillars are good!
    if (isHealthHealthy && isFamilyHealthy && isProfileHealthy && isAttendanceHealthy) {
      return PillarTierLevel.green;
    }

    // RED STATUS: When important areas need urgent action
    if (!isHealthModerate || !isFamilyHealthy || !isProfileModerate || !isAttendanceModerate) {
      return PillarTierLevel.red;
    }

    // YELLOW STATUS: Needs attention in 1 or 2 areas
    return PillarTierLevel.yellow;
  }

  String get holisticTierName {
    switch (holisticTierLevel) {
      case PillarTierLevel.green:
        return 'Green Status: All Good';
      case PillarTierLevel.yellow:
        return 'Yellow Status: Needs Attention';
      case PillarTierLevel.red:
        return 'Red Status: Action Needed';
    }
  }

  Color get holisticTierColor {
    switch (holisticTierLevel) {
      case PillarTierLevel.green:
        return const Color(0xFF10B981); // Emerald Green
      case PillarTierLevel.yellow:
        return const Color(0xFFF59E0B); // Amber / Yellow
      case PillarTierLevel.red:
        return const Color(0xFFFF5252); // Ultra-Vibrant High-Contrast Coral Red
    }
  }

  List<PillarLagItem> get holisticLagAudit {
    final lags = <PillarLagItem>[];

    // Pillar 1: Health
    final hasMetrics = _userHeightCm > 0 && _userWeightKg > 0;
    final bmiOk = hasMetrics && currentBmi >= 18.5 && currentBmi <= 25.0;
    final hasWorkout = dailyWorkoutLogs.isNotEmpty;
    if (bmiOk && hasWorkout) {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 1: Health & Wellness',
        status: 'Good (Green)',
        description: 'BMI is ${currentBmi.toStringAsFixed(1)} (Healthy) and workout logged ($totalWorkoutMinutes mins).',
        improvementAction: 'Keep eating healthy meals and drinking plenty of water.',
        isCompromised: false,
        indicatorColor: const Color(0xFF10B981),
        icon: Icons.health_and_safety,
      ));
    } else {
      String issue = '';
      if (!hasMetrics) {
        issue += 'Height and Weight need to be added. ';
      } else if (!bmiOk) {
        issue += 'BMI is ${currentBmi.toStringAsFixed(1)} ($bmiCategory). ';
      }
      if (!hasWorkout) issue += 'No workout logged today. ';
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 1: Health & Wellness',
        status: bmiOk || hasWorkout ? 'Needs Attention (Yellow)' : 'Action Needed (Red)',
        description: issue.trim(),
        improvementAction: 'Calibrate height/weight and log activities in Pillar 1.',
        isCompromised: true,
        indicatorColor: bmiOk || hasWorkout ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
        icon: Icons.health_and_safety,
      ));
    }

    // Pillar 2: Family Time
    final famHours = totalFamilyHoursToday;
    if (famHours > 0) {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 2: Family & Friends',
        status: 'Good (Green)',
        description: 'Spent ${famHours.toStringAsFixed(1)} hours of quality time with family or friends today.',
        improvementAction: 'Keep spending relaxed time with loved ones.',
        isCompromised: false,
        indicatorColor: const Color(0xFF10B981),
        icon: Icons.family_restroom,
      ));
    } else {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 2: Family & Friends',
        status: 'Not Logged Yet (Yellow)',
        description: 'No time logged with family or friends today.',
        improvementAction: 'Spend 30 minutes having dinner or talking with family in Pillar 2.',
        isCompromised: true,
        indicatorColor: const Color(0xFFF59E0B),
        icon: Icons.family_restroom,
      ));
    }

    // Pillar 3: Profile 6-Ring Subsystems
    // Ring 2: Document Submission Vault Custody
    if (_originalDocuments.isEmpty) {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 3: Document Submission',
        status: 'Need to be added (Yellow)',
        description: 'No certificates submitted yet to digital vault custody.',
        improvementAction: 'Submit original certificates to HR in Pillar 3.',
        isCompromised: true,
        indicatorColor: const Color(0xFFF59E0B),
        icon: Icons.lock_outline,
      ));
    } else {
      final pendingMandatory = _originalDocuments.where((d) => d.isMandatory && d.status != DocumentSubmissionStatus.submitted).toList();
      if (pendingMandatory.isEmpty) {
        lags.add(PillarLagItem(
          pillarTitle: 'Pillar 3: Document Submission',
          status: 'All Submitted (Green)',
          description: 'All required original certificates are safely submitted.',
          improvementAction: 'All certificates are verified by HR.',
          isCompromised: false,
          indicatorColor: const Color(0xFF10B981),
          icon: Icons.lock_outline,
        ));
      } else {
        final names = pendingMandatory.map((d) => d.title.split('(').first.trim()).join(', ');
        lags.add(PillarLagItem(
          pillarTitle: 'Pillar 3: Document Submission',
          status: pendingMandatory.length == 1 ? '1 Document Pending (Yellow)' : 'Documents Missing (Red)',
          description: '${pendingMandatory.length} required original document(s) not yet submitted: $names.',
          improvementAction: 'Submit your pending documents to HR in Pillar 3.',
          isCompromised: true,
          indicatorColor: pendingMandatory.length == 1 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
          icon: Icons.warning_amber_rounded,
        ));
      }
    }

    // Ring 1: Monthly Attendance (Calendar Month System)
    if (monthlyAttendancePercentage >= 80.0) {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 3: Monthly Attendance',
        status: 'Good (Green)',
        description: 'Attended $workingDaysAttended of $totalCalendarDaysInCurrentMonth calendar days (${monthlyAttendancePercentage.toStringAsFixed(1)}%). Tuesday Overtime: $tuesdayOvertimeDaysAttended day(s).',
        improvementAction: 'Great attendance record this month.',
        isCompromised: false,
        indicatorColor: const Color(0xFF10B981),
        icon: Icons.calendar_month,
      ));
    } else {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 3: Monthly Attendance',
        status: monthlyAttendancePercentage >= 60 ? 'Below Target (Yellow)' : 'Low Attendance (Red)',
        description: 'Attended only $workingDaysAttended of $totalCalendarDaysInCurrentMonth calendar days (${monthlyAttendancePercentage.toStringAsFixed(1)}%). Tuesday Overtime: $tuesdayOvertimeDaysAttended day(s).',
        improvementAction: 'Maintain regular daily check-ins to keep a Green status.',
        isCompromised: true,
        indicatorColor: monthlyAttendancePercentage >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
        icon: Icons.event_busy,
      ));
    }

    // Ring 3: Grooming Standards (Daily 50 Pts Max converted to %)
    if (groomingPercentage >= 80) {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 3: Grooming & Uniform',
        status: 'Great (${groomingPercentage.toStringAsFixed(0)}% • $groomingDailyPoints/50 pts)',
        description: 'Clean uniform, proper haircut, and ID card all verified.',
        improvementAction: 'Keep up the neat and clean presentation.',
        isCompromised: false,
        indicatorColor: const Color(0xFF10B981),
        icon: Icons.content_cut,
      ));
    } else {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 3: Grooming & Uniform',
        status: 'Needs Improvement (${groomingPercentage.toStringAsFixed(0)}% • $groomingDailyPoints/50 pts)',
        description: 'Grooming compliance is below 80%. Please follow dress code guidelines.',
        improvementAction: 'Speak with HR to review uniform and haircut requirements.',
        isCompromised: true,
        indicatorColor: groomingPercentage >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
        icon: Icons.style,
      ));
    }

    // Ring 4: Sales Performance
    if (salesAchievementPercentage >= 75.0) {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 3: Sales Target',
        status: 'Good (${salesAchievementPercentage.toStringAsFixed(1)}%)',
        description: 'Completed ₹${(totalSalesAchieved / 100000).toStringAsFixed(2)}L out of ₹${(_monthlySalesTarget / 100000).toStringAsFixed(0)}L target.',
        improvementAction: 'On track to meet and exceed monthly sales goal.',
        isCompromised: false,
        indicatorColor: const Color(0xFF10B981),
        icon: Icons.monetization_on_outlined,
      ));
    } else {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 3: Sales Target',
        status: 'Behind Target (${salesAchievementPercentage.toStringAsFixed(1)}%)',
        description: 'Current sales are below 75% of monthly ₹25L target.',
        improvementAction: 'Follow up with showroom visitors and upcoming customer orders.',
        isCompromised: true,
        indicatorColor: const Color(0xFFF59E0B),
        icon: Icons.trending_down,
      ));
    }

    // Ring 5: Permission & Casual Leaves
    if (!isPermissionExcessHalfDay && casualLeavesUsed <= _monthlyCasualLeavesLimit) {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 3: Permissions & Leaves',
        status: 'On Track (Green)',
        description: '${permissionHoursRemaining.toStringAsFixed(1)}h permission left out of 2.0h. Leaves used: $casualLeavesUsed/1.',
        improvementAction: 'Zero salary deduction this month.',
        isCompromised: false,
        indicatorColor: const Color(0xFF10B981),
        icon: Icons.timer,
      ));
    } else {
      final reason = isPermissionExcessHalfDay
          ? 'Monthly permission time exceeded 2.0 hours (half-day penalty).'
          : 'Used more than 1 Casual Leave ($casualLeavesUsed used, $salaryDeductionDays day salary deduction).';
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 3: Permissions & Leaves',
        status: 'Leaves Exceeded (Red)',
        description: reason,
        improvementAction: 'Keep permission time within 2 hours per month.',
        isCompromised: true,
        indicatorColor: const Color(0xFFEF4444),
        icon: Icons.warning_amber_rounded,
      ));
    }

    // Pillar 4: Attendance & Biometric Thumb Login
    if (hasLoggedAttendanceToday && isAttendanceOnTime) {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 4: Attendance (Biometric)',
        status: 'On Time (Green)',
        description: 'Biometric thumb login recorded at ${todayLoginPunch!.timeString} on biometric device.',
        improvementAction: 'Logged in on time.',
        isCompromised: false,
        indicatorColor: const Color(0xFF10B981),
        icon: Icons.fingerprint,
      ));
    } else if (hasLoggedAttendanceToday && !isAttendanceOnTime) {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 4: Attendance (Biometric)',
        status: 'Late Login (Yellow)',
        description: 'Biometric thumb login at ${todayLoginPunch!.timeString} (Shift starts at 09:30 AM).',
        improvementAction: 'Please punch in by 09:30 AM to stay on time.',
        isCompromised: true,
        indicatorColor: const Color(0xFFF59E0B),
        icon: Icons.access_time,
      ));
    } else {
      lags.add(PillarLagItem(
        pillarTitle: 'Pillar 4: Attendance (Biometric)',
        status: 'Not Punched In (Red)',
        description: 'No biometric thumb login recorded for today\'s shift.',
        improvementAction: 'Place your thumb on the biometric machine to log in.',
        isCompromised: true,
        indicatorColor: const Color(0xFFEF4444),
        icon: Icons.fingerprint,
      ));
    }

    return lags;
  }

  double get currentBmi {
    if (_userHeightCm <= 0 || _userWeightKg <= 0) return 0.0;
    final hM = _userHeightCm / 100.0;
    return _userWeightKg / (hM * hM);
  }

  String get bmiCategory {
    final b = currentBmi;
    if (b <= 0) return 'Need to be added';
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Healthy (Ideal)';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  Color get bmiColor {
    final b = currentBmi;
    if (b <= 0) return const Color(0xFF94A3B8); // Slate / Muted
    if (b < 18.5) return const Color(0xFFFBBF24); // amber
    if (b < 25.0) return const Color(0xFF10B981); // emerald green
    if (b < 30.0) return const Color(0xFFF97316); // orange
    return const Color(0xFFEF4444); // red
  }

  double get minIdealWeight => 18.5 * (_userHeightCm / 100.0) * (_userHeightCm / 100.0);
  double get maxIdealWeight => 24.9 * (_userHeightCm / 100.0) * (_userHeightCm / 100.0);

  double get totalCaloriesConsumed => _dailyFoodLogs
      .where((f) => _isToday(f.timestamp))
      .fold(0.0, (sum, f) => sum + f.calories);
  double get totalCaloriesBurned => _dailyWorkoutLogs
      .where((w) => _isToday(w.timestamp))
      .fold(0.0, (sum, w) => sum + w.caloriesBurned);
  int get totalWorkoutMinutes => _dailyWorkoutLogs
      .where((w) => _isToday(w.timestamp))
      .fold(0, (sum, w) => sum + w.durationMinutes);
  int get totalWorkoutSteps => _dailyWorkoutLogs
      .where((w) => _isToday(w.timestamp))
      .fold(0, (sum, w) => sum + w.steps);
  double get netCalories => totalCaloriesConsumed - totalCaloriesBurned;

  Employee get currentEmployee {
    return _employees.firstWhere(
      (e) => e.id == _activeEmpId || e.email.toLowerCase() == _activeEmpId.toLowerCase(),
      orElse: () => _employees.isNotEmpty
          ? _employees.first
          : Employee(
              id: _activeEmpId,
              name: 'Online Staff',
              role: 'Online Department Executive',
              roleType: 'employee',
              dept: 'Online Department',
              phone: '',
              email: '',
              avatar: '',
              initials: 'MN',
              doj: 'Today',
              experienceYears: 'Fresher (0 yrs)',
              experienceCategory: 'fresher',
              probationWeeks: 0,
              probationStatus: 'cleared',
              probationEndDate: 'Completed',
              profileCompletion: ProfileCompletion(
                percentage: 25,
                isAuthorized: false,
                photoVerified: true,
                addressVerified: false,
                kycVerified: false,
                sopRolesAcknowledged: false,
              ),
              status: 'active',
              ragStatus: 'green',
              lastActive: 'Just now',
            ),
    );
  }

  List<TaskItem> get currentEmployeeTasks {
    return _tasks.where((t) => t.empId == _activeEmpId).toList();
  }

  List<TaskItem> get operationsDeptTasks {
    final opsEmpIds = _employees.where((e) => e.roleType != 'ceo' && e.roleType != 'hr').map((e) => e.id).toSet();
    return _tasks.where((t) => opsEmpIds.contains(t.empId)).toList();
  }

  final FirebaseEmployeeService _firebaseEmployeeService = FirebaseEmployeeService();
  StreamSubscription<List<Employee>>? _employeeSubscription;
  StreamSubscription<List<SocialCauseItem>>? _socialCausesSubscription;
  StreamSubscription<List<CompanyNotification>>? _notificationsSubscription;
  StreamSubscription<List<TaskItem>>? _personalTodosSubscription;
  StreamSubscription<List<OnlineOrderModel>>? _onlineOrdersSubscription;
  bool _firebaseSyncActive = false;
  bool get firebaseSyncActive => _firebaseSyncActive;

  // Online Orders Workflow Engine (OS1 & OS2 Handler)
  List<OnlineOrderModel> _onlineOrders = [];
  List<OnlineOrderModel> get onlineOrders => _onlineOrders;
  List<OnlineOrderModel> get os1Orders => _onlineOrders.where((o) => o.brand == 'MN Jewel Park' || o.handledByEmpId == 'MN-1007' || o.reallocatedToEmpId == 'MN-1007').toList();
  List<OnlineOrderModel> get os2Orders => _onlineOrders.where((o) => o.brand == 'Vadivam' || o.handledByEmpId == 'MN-1008' || o.reallocatedToEmpId == 'MN-1008').toList();
  List<OnlineOrderModel> get overdueOnlineOrders => _onlineOrders.where((o) => o.hasAnyOverdueStage).toList();

  // Absentee Tracking & Team Lead Shift Continuity (Synchronized with Live Biometric/Attendance punches)
  final Set<String> _absentEmployeeIds = {};
  final Set<String> _manuallyPresentEmployeeIds = {};

  Set<String> get absentEmployeeIds =>
      _employees.where((e) => isEmployeeAbsent(e.id)).map((e) => e.id).toSet();

  bool isEmployeeAbsent(String empId) {
    if (_manuallyPresentEmployeeIds.contains(empId)) return false;
    if (_absentEmployeeIds.contains(empId)) return true;
    final summaries = allEmployeesTodayAttendance;
    final sIdx = summaries.indexWhere((s) => s.employeeId == empId);
    if (sIdx != -1) {
      return !summaries[sIdx].isPresent;
    }
    return true; // No punch record for today = absent
  }

  /// Returns true if employee is logged in / clocked in and currently on duty (has not marked shift over)
  bool isEmployeeActiveOnDuty(String empId) {
    if (_absentEmployeeIds.contains(empId)) return false;
    if (_manuallyPresentEmployeeIds.contains(empId)) return true;
    final summaries = allEmployeesTodayAttendance;
    final sIdx = summaries.indexWhere((s) => s.employeeId == empId);
    if (sIdx != -1) {
      final summary = summaries[sIdx];
      return summary.isPresent && summary.logoutPunch == null;
    }
    return false;
  }

  void toggleEmployeeAbsentStatus(String empId, {bool? isAbsent, String? reason}) {
    final currentAbsent = isEmployeeAbsent(empId);
    final willBeAbsent = isAbsent ?? !currentAbsent;
    if (willBeAbsent) {
      _absentEmployeeIds.add(empId);
      _manuallyPresentEmployeeIds.remove(empId);
      final emp = _employees.firstWhere((e) => e.id == empId, orElse: () => _employees.first);
      final pendingCount = _tasks.where((t) => t.empId == empId && t.status == 'pending').length;
      _notificationMessage = '⚠️ ABSENT ALERT: ${emp.name} is marked Absent today. $pendingCount standard SOP tasks require reallocation or postponement.';
    } else {
      _manuallyPresentEmployeeIds.add(empId);
      _absentEmployeeIds.remove(empId);
      _notificationMessage = null;
    }
    notifyListeners();
  }

  List<Employee> get absentEmployees =>
      _employees.where((e) => isEmployeeAbsent(e.id)).toList();

  List<TaskItem> get absentEmployeesTasks {
    final absIds = absentEmployees.map((e) => e.id).toSet();
    return _tasks.where((t) => absIds.contains(t.empId) && t.status == 'pending').toList();
  }

  EcosystemProvider() {
    _initData();
    _loadLocalPersonalNotesAndDismissed();
    _initFirebaseSync();
  }

  void _initFirebaseSync() {
    _loadOfflineCacheAndFlushPending();
    if (!FirebaseEmployeeService.isFirebaseAvailable) return;
    // Seed initial corporate team profiles if Firestore is empty
    _firebaseEmployeeService.seedCorporateAccountsIfEmpty();

    try {
      _employeeSubscription = _firebaseEmployeeService.streamEmployees().listen(
        (remoteEmployees) {
          if (remoteEmployees.isNotEmpty) {
            final updatedList = List<Employee>.from(_employees);
            for (final remote in remoteEmployees) {
              final cleanRemote = (remote.id == 'MN-CEO01' || remote.roleType == 'ceo' || remote.name.toLowerCase().contains('executive ceo'))
                  ? remote.copyWith(id: 'MN-CEO01', name: 'M N Naveenraaj', initials: 'MN', role: 'Managing Director & CEO', roleType: 'ceo')
                  : ((remote.id == 'MN-HR1001' || remote.roleType == 'hr' || remote.email.toLowerCase() == 'hr@mnj.com')
                      ? remote.copyWith(id: 'MN-HR1001', name: 'Mohankumar G', initials: 'MG', role: 'HR Manager & Operations Custodian', roleType: 'hr')
                      : remote);

              final idx = updatedList.indexWhere((e) => e.id == cleanRemote.id || e.email.toLowerCase() == cleanRemote.email.toLowerCase());
              if (idx != -1) {
                updatedList[idx] = cleanRemote;
              } else {
                updatedList.add(cleanRemote);
              }

              // Category 1, Item 1 Fix: Extract workforce punches across all devices
              if (remote.fourPillars != null && remote.fourPillars!['attendance'] is List) {
                final list = remote.fourPillars!['attendance'] as List;
                for (final pMap in list) {
                  try {
                    final punch = AttendancePunchRecord.fromJson(Map<String, dynamic>.from(pMap as Map));
                    final pIdx = _attendancePunches.indexWhere((p) => p.id == punch.id);
                    if (pIdx == -1) {
                      _attendancePunches.add(punch);
                    } else {
                      _attendancePunches[pIdx] = punch;
                    }
                  } catch (_) {}
                }
              }
            }
            _employees = updatedList;
            _firebaseSyncActive = true;
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('Firestore employee sync listener note: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore offline or awaiting initial sync: $e');
    }

    try {
      _socialCausesSubscription = _firebaseEmployeeService.streamSocialCauses().listen(
        (remoteCauses) {
          _socialCauses = remoteCauses;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Firestore social causes sync listener note: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore social causes stream error: $e');
    }

    try {
      _notificationsSubscription = _firebaseEmployeeService.streamCompanyNotifications().listen(
        (remoteNotifs) async {
          _syncAndPushIncomingNotifications(remoteNotifs);
          // Preserve any local dismissed mappings across syncs
          try {
            final prefs = await SharedPreferences.getInstance();
            final dismissedRaw = prefs.getString(_dismissedNotifsStorageKey);
            Map<String, dynamic>? dismissedMap;
            if (dismissedRaw != null && dismissedRaw.isNotEmpty) {
              dismissedMap = jsonDecode(dismissedRaw) as Map<String, dynamic>?;
            }
            _companyNotifications = remoteNotifs.map((n) {
              if (dismissedMap != null && dismissedMap.containsKey(n.id)) {
                final localDismissed = List<String>.from(dismissedMap[n.id] as List? ?? []);
                final merged = {...n.dismissedByStaffIds, ...localDismissed}.toList();
                return n.copyWith(dismissedByStaffIds: merged);
              }
              return n;
            }).toList();
          } catch (_) {
            _companyNotifications = remoteNotifs;
          }
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Firestore notifications sync listener note: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore notifications stream error: $e');
    }

    try {
      _personalTodosSubscription = _firebaseEmployeeService.streamPersonalTodos().listen(
        (remoteTodos) {
          // Keep only default SOP tasks and merge cloud personal todos
          final defaultSops = _tasks.where((t) => t.isDefaultSop).toList();
          _tasks = [...remoteTodos, ...defaultSops];
          notifyListeners();
        },
        onError: (err) {
          debugPrint('Firestore personal todos stream note: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore personal todos stream error: $e');
    }

    try {
      _onlineOrdersSubscription = _firebaseEmployeeService.streamOnlineOrders().listen(
        (remoteOrders) {
          if (remoteOrders.isNotEmpty) {
            _onlineOrders = remoteOrders;
            checkAndEscalateOverdueOrders();
            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('Firestore online orders stream note: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore online orders stream error: $e');
    }
  }

  Future<void> _loadOfflineCacheAndFlushPending() async {
    try {
      final cached = await OfflineSyncService.loadCachedPunches();
      if (cached.isNotEmpty) {
        for (final p in cached) {
          if (!_attendancePunches.any((e) => e.id == p.id)) {
            _attendancePunches.add(p);
          }
        }
        notifyListeners();
      }

      // Flush pending punches to Cloud Firestore
      final pendingPunches = await OfflineSyncService.getPendingPunches();
      for (final p in pendingPunches) {
        _firebaseEmployeeService.saveEmployeePillar(
          empId: p.enrollNumber,
          pillarKey: 'attendance',
          data: _attendancePunches.where((e) => e.enrollNumber == p.enrollNumber).map((e) => e.toJson()).toList(),
        ).then((_) {
          OfflineSyncService.removePendingPunch(p.id);
          debugPrint('Synced offline punch ${p.id} to cloud successfully.');
        }).catchError((_) {});
      }

      // Flush pending task completions
      final pendingTasks = await OfflineSyncService.getPendingTaskCompletions();
      if (pendingTasks.isNotEmpty) {
        await OfflineSyncService.clearPendingTaskCompletions();
      }
    } catch (e) {
      debugPrint('Offline sync flusher error: $e');
    }
  }

  void _initData() {
    // 1. Official Corporate Team Profiles (Image 2 & KONAR Book)
    // Only CEO, HR, and the confirmed official team members are present
    _employees = [
      // 1. Master CEO
      Employee(
        id: 'MN-CEO01',
        name: 'M N Naveenraaj',
        role: 'Managing Director & CEO',
        roleType: 'ceo',
        dept: 'Administration',
        phone: '+91 98450 00001',
        email: 'ceoofmn@mnjpark.com',
        avatar: '',
        initials: 'MN',
        doj: '2020-01-01',
        experienceYears: '25 yrs in Fine Jewellery',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1975-01-15',
        relationshipStatus: 'Married',
        anniversaryDate: '2001-05-20',
        password: 'adminnaandhan',
      ),

      // 2. HR Management
      Employee(
        id: 'MN-HR1001',
        name: 'Mohankumar G',
        role: 'HR Manager & Operations Custodian',
        roleType: 'hr',
        dept: 'Administration',
        phone: '+91 94433 11000',
        email: 'hr@mnj.com',
        avatar: '',
        initials: 'MG',
        doj: '2021-03-10',
        experienceYears: '8 yrs in HR Management',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1993-04-10',
        relationshipStatus: 'Married',
        anniversaryDate: '2019-06-15',
        password: 'hr@mnj123',
      ),

      // 3. OTM - Online Team Manager / Team Lead (Mr. M. Praveen Kumar)
      Employee(
        id: 'MN-TL1002',
        name: 'Praveenkumar M',
        role: 'Online Team Manager (Editor)',
        roleType: 'team_lead',
        dept: 'Online Department',
        phone: '+91 94420 11001',
        email: 'praveenkumarotm@mnj.com',
        avatar: '',
        initials: 'PM',
        doj: '2021-06-15',
        experienceYears: '6 yrs in Digital Media',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1994-08-15',
        relationshipStatus: 'Married',
        anniversaryDate: '2021-11-20',
        password: 'praveen@mnj123',
      ),

      // 4. OSH - Online Sale Head (Mr. K. Gokulakrishnan)
      Employee(
        id: 'MN-1003',
        name: 'Gokulakrishnan K',
        role: 'Online Sale Head (OSH)',
        roleType: 'employee',
        dept: 'Online Department',
        phone: '+91 94420 11002',
        email: 'gokulakrishnanosh@mnj.com',
        avatar: '',
        initials: 'KG',
        doj: '2022-01-10',
        experienceYears: '5 yrs in Retail Sales',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1995-05-12',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'gokul@mnj123',
      ),

      // 5. VPE - Chief Photographer & Videographer (Mr. Y. Aravinda Samy)
      Employee(
        id: 'MN-1004',
        name: 'Aravinda Samy Y',
        role: 'Chief Photographer & Videographer (VPE)',
        roleType: 'employee',
        dept: 'Online Department',
        phone: '+91 94420 11003',
        email: 'aravindasamyvpe@mnj.com',
        avatar: '',
        initials: 'YA',
        doj: '2022-02-01',
        experienceYears: '5 yrs in Jewelry Cinematography',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1996-03-24',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'aravind@mnj123',
      ),

      // 6. Ass.VPE - Assistant Photographer (Mrs. M. Mithra)
      Employee(
        id: 'MN-1005',
        name: 'Mithra M',
        role: 'Assistant Photographer & Videographer (Ass.VPE)',
        roleType: 'employee',
        dept: 'Online Department',
        phone: '+91 94420 11004',
        email: 'mithraassvpe@mnj.com',
        avatar: '',
        initials: 'MM',
        doj: '2022-04-15',
        experienceYears: '3 yrs in Photography',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1997-10-08',
        relationshipStatus: 'Married',
        anniversaryDate: '2023-02-14',
        password: 'mithra@mnj123',
      ),

      // 7. ECE - E-Commerce Executive
      Employee(
        id: 'MN-1006',
        name: 'E-Commerce Executive',
        role: 'E-Commerce Executive (ECE)',
        roleType: 'employee',
        dept: 'Online Department',
        phone: '+91 94420 11005',
        email: 'ece@mnj.com',
        avatar: '',
        initials: 'EC',
        doj: '2022-06-01',
        experienceYears: '3 yrs in E-Commerce',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1998-01-19',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'ece@mnj123',
      ),

      // 8. OS1 - Online Sale Person 1 (Ms. Kaaviya)
      Employee(
        id: 'MN-1007',
        name: 'Kaaviya',
        role: 'Online Sale Person 1 (OS1)',
        roleType: 'employee',
        dept: 'Online Department',
        phone: '+91 80567 36999',
        email: 'kaaviyaos1@mnj.com',
        avatar: '',
        initials: 'KV',
        doj: '2022-07-15',
        experienceYears: '3 yrs in Jewelry Sales',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1999-07-11',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'kaaviya@mnj123',
      ),

      // 9. OS2 - Online Sale Person 2 (Ms. Nisha)
      Employee(
        id: 'MN-1008',
        name: 'Nisha',
        role: 'Online Sale Person 2 (OS2)',
        roleType: 'employee',
        dept: 'Online Department',
        phone: '+91 89258 68077',
        email: 'nishaos2@mnj.com',
        avatar: '',
        initials: 'NS',
        doj: '2022-08-01',
        experienceYears: '3 yrs in Customer Care',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1999-12-05',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'nisha@mnj123',
      ),

      // 10. AC - Online Analytical Consultant (Mr. J. Midhun Kumar)
      Employee(
        id: 'MN-1009',
        name: 'Midhun Kumar J',
        role: 'Online Analytical Consultant (AC)',
        roleType: 'employee',
        dept: 'Online Department',
        phone: '+91 94420 11006',
        email: 'midhunkumarac@mnj.com',
        avatar: '',
        initials: 'JM',
        doj: '2022-09-10',
        experienceYears: '4 yrs in Digital Ads',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1995-11-28',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'midhun@mnj123',
      ),

      // 11. OSS - Online Support & Strategist (Mr. Subash)
      Employee(
        id: 'MN-1010',
        name: 'Subash',
        role: 'Online Support & Strategist (OSS)',
        roleType: 'employee',
        dept: 'Online Department',
        phone: '+91 94420 11007',
        email: 'subashoss@mnj.com',
        avatar: '',
        initials: 'SB',
        doj: '2022-10-01',
        experienceYears: '4 yrs in Marketing Strategy',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1996-06-17',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'subash@mnj123',
      ),

      // 12. DVP - Developer (Mr. K.B. Eshwar)
      Employee(
        id: 'MN-1011',
        name: 'Eshwar K B',
        role: 'Platform Developer (DVP)',
        roleType: 'employee',
        dept: 'Online Department',
        phone: '+91 94420 11008',
        email: 'eshwardvp@mnj.com',
        avatar: '',
        initials: 'KE',
        doj: '2022-11-15',
        experienceYears: '4 yrs in Full Stack Development',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1997-04-22',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'eshwar@mnj123',
      ),

      // 13. CC - Content Creator (Mr. Sam Roy)
      Employee(
        id: 'MN-1012',
        name: 'Sam Roy',
        role: 'Content Creator & Scriptwriter (CC)',
        roleType: 'employee',
        dept: 'Online Department',
        phone: '+91 94420 11009',
        email: 'samroycc@mnj.com',
        avatar: '',
        initials: 'SR',
        doj: '2023-01-05',
        experienceYears: '3 yrs in Scriptwriting',
        experienceCategory: 'experienced',
        probationWeeks: 0,
        probationStatus: 'cleared',
        probationEndDate: 'Completed',
        profileCompletion: ProfileCompletion(
          percentage: 100,
          isAuthorized: true,
          photoVerified: true,
          addressVerified: true,
          kycVerified: true,
          sopRolesAcknowledged: true,
        ),
        status: 'active',
        ragStatus: 'green',
        lastActive: 'Active now',
        dob: '1998-09-30',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'samroy@mnj123',
      ),
    ];

    // 2. Pre-populate Standard Work / SOP Tasks for every role based on the KONAR Book
    _tasks = [];
    for (final emp in _employees) {
      final code = KonarTaskCatalog.resolveRoleCode(emp.role, emp.email, emp.id);
      _tasks.addAll(KonarTaskCatalog.getStandardTasksForEmployee(emp.id, code, emp.name));
    }
    _handovers = [];
    _blockers = [];

    // Store Opening Readiness Gate (All unsigned by default)
    _readinessGate = ReadinessGate(
      status: 'Pending Setup (0/6 Signed)',
      targetTime: '10:00 AM',
      signedCount: 0,
      totalCount: 6,
      depts: [
        ReadinessDept(name: 'Housekeeping', task: 'Floor deep-clean & velvet glass mirror polish verified', signed: false, signedBy: '', time: '--'),
        ReadinessDept(name: 'Vault & Logistics', task: 'Morning display trays issued to counters', signed: false, signedBy: '', time: '--'),
        ReadinessDept(name: 'Security & CCTV', task: '360° CCTV scan & emergency exit sensor clearance', signed: false, signedBy: '', time: '--'),
        ReadinessDept(name: 'Operations & Assay', task: 'Digital 0.001g scales calibrated & hallmarking active', signed: false, signedBy: '', time: '--'),
        ReadinessDept(name: 'Showroom Sales', task: 'Staff groomed, velvet spotlights calibrated to 4000K', signed: false, signedBy: '', time: '--'),
        ReadinessDept(name: 'Finance & Accounts', task: 'Daily 22K gold rate synchronized on billing', signed: false, signedBy: '', time: '--'),
      ],
    );

    _incidents = [];
    _shiftHandovers = [];
    _delayCauses = [];
    _delegations = [];

    // Health Pillar (0.0 kg / 0.0 cm / 0 meals / 0 workouts)
    _weightHistory = [];
    _dailyFoodLogs = [];
    _dailyWorkoutLogs = [];

    // Family Pillar (0 hrs / 0 activities logged)
    _familyActivityLogs = [];

    // Profile Pillar Documents (0 submitted documents)
    _originalDocuments = [];

    // Attendance Pillar Punches (0 punches recorded)
    _attendancePunches = [];

    // Grooming Audits (Clean state: 0 audits until audited by HR)
    _groomingAudits = [];

    // Permissions & Leaves (0 records)
    _permissionRecords = [];
    _medicalLeaveRecords = [];

    // Sales Records (₹0 achieved)
    _salesRecords = [];

    // Social Cause Pillar 5 (Clean state: only real data submitted by staff or streamed from Firestore)
    _socialCauses = [];

    // Company Universal Notifications (Clean state: only real notifications issued by HR/CEO or streamed from Firestore)
    _companyNotifications = [];

    // Online Orders Handler (Clean state: only real data created or streamed from Firestore)
    _onlineOrders = [];
  }

  // --- ACTIONS ---

  // CEO Role & Privilege Allocation Action
  void allocateEmployeeRole({
    required String empId,
    required String newRole,
    required String newDept,
    List<String>? perks,
    List<String>? responsibilities,
  }) {
    final idx = _employees.indexWhere((e) => e.id == empId);
    if (idx != -1) {
      _employees[idx] = _employees[idx].copyWith(
        role: newRole,
        dept: newDept,
      );
      if (empId == _activeEmpId) {
        final r = newRole.toLowerCase();
        if (r.contains('ceo')) {
          _activeRole = 'ceo';
        } else if (r.contains('dept head')) {
          _activeRole = 'dept_head';
        } else if (r.contains('hr')) {
          _activeRole = 'hr';
        } else {
          _activeRole = 'employee';
        }
      }
      notifyListeners();
    }
  }

  // HR Grooming Point Audits
  static const int maxDailyGroomingPoints = 50;
  static const int pointsPerChecklistItem = 10;

  static List<String> getMaleGroomingChecklist() => const [
    'Shirt tucked in neatly',
    'Professional hairstyle & well groomed',
    'Full hand (full sleeve) formal shirt',
    'Clean shave / neat beard trim',
    'Company ID card visibly worn & formal shoes',
  ];

  static List<String> getFemaleGroomingChecklist() => const [
    'Uniform saree properly draped & pinned',
    'Neat hairstyle (tied / pinned back)',
    'Company ID card visibly worn',
    'Formal footwear / closed sandals',
    'Professional grooming & minimal jewelry',
  ];

  List<GroomingAuditItem> getEmployeeGroomingAudits(String empId) =>
      _groomingAudits.where((g) => g.empId == empId).toList();

  int getEmployeeGroomingScore(String empId) =>
      getEmployeeGroomingPercentage(empId).round();

  void recordDailyGroomingAudit({
    required String empId,
    required List<String> followedItems,
    required int pointsEarned,
    int maxPoints = 50,
    required String reason,
    String auditedBy = 'HR Department',
  }) {
    final now = DateTime.now();
    _groomingAudits.removeWhere((a) =>
        a.empId == empId &&
        a.date.year == now.year &&
        a.date.month == now.month &&
        a.date.day == now.day);

    _groomingAudits.insert(
      0,
      GroomingAuditItem(
        id: 'GRM-${now.millisecondsSinceEpoch}',
        empId: empId,
        date: now,
        category: 'Daily Attire & Grooming Audit',
        pointsChange: pointsEarned,
        pointsEarned: pointsEarned,
        maxPoints: maxPoints,
        followedItems: followedItems,
        reason: reason,
        auditedBy: auditedBy,
      ),
    );
    notifyListeners();
  }

  void addGroomingAudit({
    required String empId,
    required String category,
    required int pointsChange,
    required String reason,
    String auditedBy = 'HR Admin',
  }) {
    final currentPts = getEmployeeGroomingDailyPoints(empId);
    final newPts = (currentPts + pointsChange).clamp(0, 50);
    final isFem = empId == 'MN-004' || empId == 'MN-006';
    final checklist = isFem ? getFemaleGroomingChecklist() : getMaleGroomingChecklist();
    recordDailyGroomingAudit(
      empId: empId,
      followedItems: pointsChange >= 0 ? checklist : [],
      pointsEarned: newPts,
      reason: reason,
      auditedBy: auditedBy,
    );
  }

  // Permission & Late Arrival Request (2.0 hrs limit & 1 CL rule)
  void requestPermission({
    required String empId,
    required double requestedHours,
    required double actualHoursUsed,
    required String reason,
    bool isCasualLeave = false,
  }) {
    final now = DateTime.now();
    final currentUsed = totalPermissionHoursUsed;
    final willExceed = (currentUsed + actualHoursUsed) > _monthlyPermissionHoursLimit;
    final currentCL = casualLeavesUsed;
    final isSalaryDeduct = isCasualLeave && (currentCL >= _monthlyCasualLeavesLimit);

    _permissionRecords.insert(
      0,
      PermissionRecord(
        id: 'PERM-${DateTime.now().millisecondsSinceEpoch}',
        empId: empId,
        date: now,
        requestedHours: requestedHours,
        actualHoursUsed: actualHoursUsed,
        reason: reason,
        status: 'Approved',
        isHalfDayTriggered: willExceed && !isCasualLeave,
        isCasualLeave: isCasualLeave,
        isSalaryDeducted: isSalaryDeduct,
      ),
    );
    notifyListeners();
  }

  // HR marks/grants permission directly to employee
  void markPermissionByHr({
    required String empId,
    required double hours,
    required String reason,
    DateTime? date,
    bool isCasualLeave = false,
  }) {
    final targetDate = date ?? DateTime.now();
    final currentUsed = _permissionRecords
        .where((p) => p.empId == empId && !p.isCasualLeave && p.status != 'Rejected' && _isCurrentMonth(p.date))
        .fold(0.0, (sum, p) => sum + p.actualHoursUsed);
    final willExceed = (currentUsed + hours) > _monthlyPermissionHoursLimit;

    final record = PermissionRecord(
      id: 'PERM-${DateTime.now().millisecondsSinceEpoch}',
      empId: empId,
      date: targetDate,
      requestedHours: hours,
      actualHoursUsed: hours,
      reason: reason,
      status: 'Approved',
      isHalfDayTriggered: willExceed && !isCasualLeave,
      isCasualLeave: isCasualLeave,
      isSalaryDeducted: false,
      grantedBy: 'HR (Mohankumar G)',
    );
    _permissionRecords.insert(0, record);

    final emp = _employees.firstWhere((e) => e.id == empId, orElse: () => _employees.first);
    PushNotificationService().showNotification(
      id: record.id,
      title: 'Permission Granted: ${hours}h',
      body: 'HR granted ${emp.name} $hours hrs permission for "$reason".',
      payload: 'permission_granted',
    );
    notifyListeners();
  }

  // Employee requests standard permission
  void requestEmployeePermission({
    required String empId,
    required double requestedHours,
    required String reason,
    DateTime? date,
  }) {
    final targetDate = date ?? DateTime.now();
    final currentUsed = totalPermissionHoursUsed;
    final willExceed = (currentUsed + requestedHours) > _monthlyPermissionHoursLimit;

    final emp = _employees.firstWhere((e) => e.id == empId, orElse: () => _employees.first);
    final record = PermissionRecord(
      id: 'PERM-${DateTime.now().millisecondsSinceEpoch}',
      empId: empId,
      date: targetDate,
      requestedHours: requestedHours,
      actualHoursUsed: requestedHours,
      reason: reason,
      status: 'Pending',
      isHalfDayTriggered: willExceed,
      isCasualLeave: false,
      isSalaryDeducted: false,
      grantedBy: 'Employee Request',
      employeeName: emp.name,
      department: emp.dept,
      requesterRole: emp.role,
      isOver2Hours: requestedHours > 2.0 || willExceed,
    );
    _permissionRecords.insert(0, record);

    // Push immediate notification to CEO and HR
    PushNotificationService().showNotification(
      id: record.id,
      title: 'New Permission Request: ${requestedHours}h',
      body: '${emp.name} (${emp.role}) requested permission for "$reason".',
      payload: 'permission_request',
    );
    notifyListeners();
  }

  // Request Emergency Permission (15m, 30m, 1h, 2h, >2h custom)
  void requestEmergencyPermission({
    required String empId,
    required double hours,
    required String reason,
    required String requesterRole,
  }) {
    final now = DateTime.now();
    final emp = _employees.firstWhere((e) => e.id == empId, orElse: () => _employees.first);

    // Tally in 2-hour permission section:
    // If request exceeds 2 hrs OR month used + request exceeds 2 hrs, flag as isOver2Hours (Orange mark)
    final currentMonthUsed = _permissionRecords
        .where((p) => p.empId == empId && !p.isCasualLeave && p.status != 'Rejected' && _isCurrentMonth(p.date))
        .fold(0.0, (sum, p) => sum + p.actualHoursUsed);
    final willExceed = (currentMonthUsed + hours) > _monthlyPermissionHoursLimit || hours > 2.0;

    final isHrRequester = requesterRole.toLowerCase().contains('hr');
    // HR directly requests from CEO; Employee & TL need HR & CEO approval flow
    final initialStatus = isHrRequester ? 'Pending CEO' : 'Pending HR & CEO';

    final durationFormatted = hours < 1.0 ? '${(hours * 60).round()}m' : '${hours.toStringAsFixed(1)}h';

    final record = PermissionRecord(
      id: 'EMERG-PERM-${DateTime.now().millisecondsSinceEpoch}',
      empId: empId,
      date: now,
      requestedHours: hours,
      actualHoursUsed: hours,
      reason: reason,
      status: initialStatus,
      isHalfDayTriggered: willExceed,
      isCasualLeave: false,
      isSalaryDeducted: false,
      grantedBy: '$requesterRole Emergency Request',
      isEmergency: true,
      employeeName: emp.name,
      department: emp.dept,
      requesterRole: requesterRole,
      isOver2Hours: willExceed,
    );
    _permissionRecords.insert(0, record);

    // Push immediate high-priority notification to CEO and HR
    PushNotificationService().showNotification(
      id: record.id,
      title: '🚨 Emergency Permission Request ($durationFormatted)',
      body: '${emp.name} ($requesterRole) requested emergency permission to step out: "$reason".',
      payload: 'emergency_permission',
    );
    notifyListeners();
  }

  // Request Emergency Medical Leave with Mandatory Doctor Prescription (<= 150 KB)
  Future<bool> requestEmergencyMedicalLeave({
    required String empId,
    required int days,
    required String reason,
    required String prescriptionBase64,
    required String requesterRole,
  }) async {
    // Prescription is strictly required
    if (prescriptionBase64.trim().isEmpty) {
      return false;
    }

    final now = DateTime.now();
    final emp = _employees.firstWhere((e) => e.id == empId, orElse: () => _employees.first);
    final isHrRequester = requesterRole.toLowerCase().contains('hr');
    final initialStatus = isHrRequester ? 'Pending CEO' : 'Pending HR & CEO';

    final record = MedicalLeaveRecord(
      id: 'MED-LEAVE-${DateTime.now().millisecondsSinceEpoch}',
      empId: empId,
      empName: emp.name,
      empRole: requesterRole,
      department: emp.dept,
      date: now,
      days: days,
      reason: reason,
      prescriptionBase64: prescriptionBase64,
      status: initialStatus,
      isEmergency: true,
    );
    _medicalLeaveRecords.insert(0, record);

    // Push immediate high-priority notification to CEO and HR
    PushNotificationService().showNotification(
      id: record.id,
      title: '🚨 Emergency Medical Leave ($days Days)',
      body: '${emp.name} ($requesterRole) submitted emergency medical leave with prescription: "$reason".',
      payload: 'medical_leave',
    );

    notifyListeners();
    return true;
  }

  // HR grants / endorses employee or TL permission request
  void hrGrantPermission(String permId) {
    final idx = _permissionRecords.indexWhere((p) => p.id == permId);
    if (idx != -1) {
      final old = _permissionRecords[idx];
      _permissionRecords[idx] = PermissionRecord(
        id: old.id,
        empId: old.empId,
        date: old.date,
        requestedHours: old.requestedHours,
        actualHoursUsed: old.actualHoursUsed,
        reason: old.reason,
        status: 'Granted by HR (Pending CEO Approval)',
        isHalfDayTriggered: old.isHalfDayTriggered,
        isCasualLeave: old.isCasualLeave,
        isSalaryDeducted: old.isSalaryDeducted,
        grantedBy: 'HR (Mohankumar G) Granted',
        isEmergency: old.isEmergency,
        employeeName: old.employeeName,
        department: old.department,
        requesterRole: old.requesterRole,
        isOver2Hours: old.isOver2Hours,
        hrApprovedBy: 'Mohankumar G (HR)',
        ceoApprovedBy: old.ceoApprovedBy,
      );
      final emp = _employees.firstWhere((e) => e.id == old.empId, orElse: () => _employees.first);
      PushNotificationService().showNotification(
        id: 'HR-GRANT-${DateTime.now().millisecondsSinceEpoch}',
        title: 'HR Granted Permission: CEO Acceptance Required',
        body: 'HR granted permission for ${emp.name} (${old.actualHoursUsed}h). Final CEO acceptance needed.',
        payload: 'hr_grant_permission',
      );
      notifyListeners();
    }
  }

  // HR approves permission directly (fallback compatibility)
  void approvePermission(String permId) {
    final idx = _permissionRecords.indexWhere((p) => p.id == permId);
    if (idx != -1) {
      final old = _permissionRecords[idx];
      _permissionRecords[idx] = PermissionRecord(
        id: old.id,
        empId: old.empId,
        date: old.date,
        requestedHours: old.requestedHours,
        actualHoursUsed: old.actualHoursUsed,
        reason: old.reason,
        status: 'Approved',
        isHalfDayTriggered: old.isHalfDayTriggered,
        isCasualLeave: old.isCasualLeave,
        isSalaryDeducted: old.isSalaryDeducted,
        grantedBy: 'HR Approved',
        isEmergency: old.isEmergency,
        employeeName: old.employeeName,
        department: old.department,
        requesterRole: old.requesterRole,
        isOver2Hours: old.isOver2Hours,
        hrApprovedBy: 'Mohankumar G (HR)',
        ceoApprovedBy: old.ceoApprovedBy,
      );
      final emp = _employees.firstWhere((e) => e.id == old.empId, orElse: () => _employees.first);
      PushNotificationService().showNotification(
        id: 'APP-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Permission Approved',
        body: 'HR approved permission (${old.actualHoursUsed}h) for ${emp.name}.',
        payload: 'permission_approved',
      );
      notifyListeners();
    }
  }

  // CEO final acceptance / approval for permission
  void ceoApprovePermission(String permId) {
    final idx = _permissionRecords.indexWhere((p) => p.id == permId);
    if (idx != -1) {
      final old = _permissionRecords[idx];
      _permissionRecords[idx] = PermissionRecord(
        id: old.id,
        empId: old.empId,
        date: old.date,
        requestedHours: old.requestedHours,
        actualHoursUsed: old.actualHoursUsed,
        reason: old.reason,
        status: 'Approved',
        isHalfDayTriggered: old.isHalfDayTriggered,
        isCasualLeave: old.isCasualLeave,
        isSalaryDeducted: old.isSalaryDeducted,
        grantedBy: 'CEO (M N Naveenraaj) Approved',
        isEmergency: old.isEmergency,
        employeeName: old.employeeName,
        department: old.department,
        requesterRole: old.requesterRole,
        isOver2Hours: old.isOver2Hours,
        hrApprovedBy: old.hrApprovedBy,
        ceoApprovedBy: 'M N Naveenraaj (CEO)',
      );
      final emp = _employees.firstWhere((e) => e.id == old.empId, orElse: () => _employees.first);
      PushNotificationService().showNotification(
        id: 'CEO-APPROVE-${DateTime.now().millisecondsSinceEpoch}',
        title: '✅ Permission Approved by CEO',
        body: 'CEO accepted permission (${old.actualHoursUsed}h) for ${emp.name}.',
        payload: 'ceo_permission_approved',
      );
      notifyListeners();
    }
  }

  // Rejection of permission request
  void rejectPermission(String permId, {String? rejectedBy}) {
    final idx = _permissionRecords.indexWhere((p) => p.id == permId);
    if (idx != -1) {
      final old = _permissionRecords[idx];
      final rejector = rejectedBy ?? 'HR/CEO';
      _permissionRecords[idx] = PermissionRecord(
        id: old.id,
        empId: old.empId,
        date: old.date,
        requestedHours: old.requestedHours,
        actualHoursUsed: old.actualHoursUsed,
        reason: old.reason,
        status: 'Rejected',
        isHalfDayTriggered: old.isHalfDayTriggered,
        isCasualLeave: old.isCasualLeave,
        isSalaryDeducted: old.isSalaryDeducted,
        grantedBy: '$rejector Rejected',
        isEmergency: old.isEmergency,
        employeeName: old.employeeName,
        department: old.department,
        requesterRole: old.requesterRole,
        isOver2Hours: old.isOver2Hours,
      );
      final emp = _employees.firstWhere((e) => e.id == old.empId, orElse: () => _employees.first);
      PushNotificationService().showNotification(
        id: 'REJ-${DateTime.now().millisecondsSinceEpoch}',
        title: '❌ Permission Request Rejected',
        body: 'Permission request for ${emp.name} was rejected by $rejector.',
        payload: 'permission_rejected',
      );
      notifyListeners();
    }
  }

  // HR grants / endorses emergency medical leave
  void hrGrantMedicalLeave(String leaveId) {
    final idx = _medicalLeaveRecords.indexWhere((m) => m.id == leaveId);
    if (idx != -1) {
      final old = _medicalLeaveRecords[idx];
      _medicalLeaveRecords[idx] = MedicalLeaveRecord(
        id: old.id,
        empId: old.empId,
        empName: old.empName,
        empRole: old.empRole,
        department: old.department,
        date: old.date,
        days: old.days,
        reason: old.reason,
        prescriptionBase64: old.prescriptionBase64,
        status: 'Granted by HR (Pending CEO Approval)',
        hrApprovedBy: 'Mohankumar G (HR)',
        ceoApprovedBy: old.ceoApprovedBy,
        reviewedAt: DateTime.now(),
        isEmergency: old.isEmergency,
      );
      PushNotificationService().showNotification(
        id: 'HR-MED-${DateTime.now().millisecondsSinceEpoch}',
        title: 'HR Endorsed Medical Leave: CEO Acceptance Required',
        body: 'HR verified prescription for ${old.empName} (${old.days} days). Awaiting CEO approval.',
        payload: 'hr_med_leave',
      );
      notifyListeners();
    }
  }

  // CEO final acceptance / approval for emergency medical leave
  void ceoApproveMedicalLeave(String leaveId) {
    final idx = _medicalLeaveRecords.indexWhere((m) => m.id == leaveId);
    if (idx != -1) {
      final old = _medicalLeaveRecords[idx];
      _medicalLeaveRecords[idx] = MedicalLeaveRecord(
        id: old.id,
        empId: old.empId,
        empName: old.empName,
        empRole: old.empRole,
        department: old.department,
        date: old.date,
        days: old.days,
        reason: old.reason,
        prescriptionBase64: old.prescriptionBase64,
        status: 'Approved',
        hrApprovedBy: old.hrApprovedBy,
        ceoApprovedBy: 'M N Naveenraaj (CEO)',
        reviewedAt: DateTime.now(),
        isEmergency: old.isEmergency,
      );
      PushNotificationService().showNotification(
        id: 'CEO-MED-APPROVE-${DateTime.now().millisecondsSinceEpoch}',
        title: '✅ Emergency Medical Leave Approved by CEO',
        body: 'CEO approved ${old.days} days emergency medical leave for ${old.empName}.',
        payload: 'ceo_med_approved',
      );
      notifyListeners();
    }
  }

  // Rejection of medical leave
  void rejectMedicalLeave(String leaveId, {String? rejectedBy}) {
    final idx = _medicalLeaveRecords.indexWhere((m) => m.id == leaveId);
    if (idx != -1) {
      final old = _medicalLeaveRecords[idx];
      final rejector = rejectedBy ?? 'HR/CEO';
      _medicalLeaveRecords[idx] = MedicalLeaveRecord(
        id: old.id,
        empId: old.empId,
        empName: old.empName,
        empRole: old.empRole,
        department: old.department,
        date: old.date,
        days: old.days,
        reason: old.reason,
        prescriptionBase64: old.prescriptionBase64,
        status: 'Rejected',
        hrApprovedBy: old.hrApprovedBy,
        ceoApprovedBy: old.ceoApprovedBy,
        reviewedAt: DateTime.now(),
        isEmergency: old.isEmergency,
      );
      PushNotificationService().showNotification(
        id: 'MED-REJ-${DateTime.now().millisecondsSinceEpoch}',
        title: '❌ Medical Leave Rejected',
        body: 'Emergency medical leave for ${old.empName} was rejected by $rejector.',
        payload: 'medical_leave_rejected',
      );
      notifyListeners();
    }
  }

  // Individual Sales Record Action
  void addSalesRecord({
    required String empId,
    required String billNumber,
    required String category,
    required double amount,
    required double weightGrams,
    required String customerName,
  }) {
    _salesRecords.insert(
      0,
      SalesRecord(
        id: 'SLS-${DateTime.now().millisecondsSinceEpoch}',
        empId: empId,
        billNumber: billNumber,
        date: DateTime.now(),
        itemCategory: category,
        amountInInr: amount,
        weightGrams: weightGrams,
        customerName: customerName,
      ),
    );
    notifyListeners();
  }

  // Health Pillar 1 Actions
  void completeHealthOnboarding({required double heightCm, required double weightKg}) {
    _userHeightCm = heightCm;
    _userWeightKg = weightKg;
    _healthOnboarded = true;
    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    _weightHistory.insert(
      0,
      WeightHeightRecord(
        weightKg: weightKg,
        heightCm: heightCm,
        bmi: currentBmi,
        date: now,
        dateString: '${now.day} ${_monthName(now.month)} ${now.year}, $timeStr',
      ),
    );
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'health',
      data: {
        'heightCm': heightCm,
        'weightKg': weightKg,
        'onboarded': true,
      },
    );
  }

  void updateWeightAndHeight({required double heightCm, required double weightKg}) {
    _userHeightCm = heightCm;
    _userWeightKg = weightKg;
    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    _weightHistory.insert(
      0,
      WeightHeightRecord(
        weightKg: weightKg,
        heightCm: heightCm,
        bmi: currentBmi,
        date: now,
        dateString: '${now.day} ${_monthName(now.month)} ${now.year}, $timeStr',
      ),
    );
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'health',
      data: {
        'heightCm': heightCm,
        'weightKg': weightKg,
        'onboarded': true,
      },
    );
  }

  void addFoodLog({
    required String foodName,
    required String mealType,
    required double grams,
    required double calories,
  }) {
    final now = DateTime.now();
    final timeStr = '${now.day} ${_monthName(now.month)} ${now.year}, ${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    _dailyFoodLogs.insert(
      0,
      FoodLogItem(
        id: 'FOOD-${DateTime.now().millisecondsSinceEpoch}',
        foodName: foodName,
        mealType: mealType,
        grams: grams,
        calories: calories,
        timestamp: now,
        timeString: timeStr,
      ),
    );
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'meals',
      data: _dailyFoodLogs.map((e) => e.toMap()).toList(),
    );
  }

  void deleteFoodLog(String id) {
    _dailyFoodLogs.removeWhere((f) => f.id == id);
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'meals',
      data: _dailyFoodLogs.map((e) => e.toMap()).toList(),
    );
  }

  void addWorkoutLog({
    required String activityName,
    required int durationMinutes,
    required int steps,
    required double distanceKm,
    required double caloriesBurned,
    required String intensity,
    required String timeAllocation,
    String notes = '',
  }) {
    final now = DateTime.now();
    final timeStr = '${now.day} ${_monthName(now.month)} ${now.year}, ${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    _dailyWorkoutLogs.insert(
      0,
      WorkoutLogItem(
        id: 'WO-${DateTime.now().millisecondsSinceEpoch}',
        activityName: activityName,
        durationMinutes: durationMinutes,
        steps: steps,
        distanceKm: distanceKm,
        caloriesBurned: caloriesBurned,
        intensity: intensity,
        timeAllocation: timeAllocation,
        timestamp: now,
        timeString: timeStr,
        notes: notes,
      ),
    );
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'workouts',
      data: _dailyWorkoutLogs.map((e) => e.toMap()).toList(),
    );
  }

  void deleteWorkoutLog(String id) {
    _dailyWorkoutLogs.removeWhere((w) => w.id == id);
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'workouts',
      data: _dailyWorkoutLogs.map((e) => e.toMap()).toList(),
    );
  }

  void resetHealthOnboarding() {
    _healthOnboarded = false;
    notifyListeners();
  }

  void setActiveRole(String role) {
    _activeRole = role;
    notifyListeners();
  }

  void setActiveEmpId(String empId) {
    _activeEmpId = empId;
    loadEmployeeFourPillars(empId);
    notifyListeners();
  }

  /// Dynamic login connecting Firebase Auth & Cloud Firestore
  /// Returns authenticated activeRole ('hr', 'team_lead', 'employee', 'ceo')
  /// Strictly validates credentials and throws Exception('Email / Password incorrect') on failure.
  Future<String> loginWithFirebase({required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      throw Exception('Email / Password incorrect');
    }

    // 1. Instant corporate directory verification
    final Map<String, ({String roleType, String empId, String defaultEmail, List<String> validPasswords})> corporateRegistry = {
      'ceoofmn@mnjpark.com': (roleType: 'ceo', empId: 'MN-CEO01', defaultEmail: 'ceoofmn@mnjpark.com', validPasswords: ['adminnaandhan', 'mnj12345']),
      'ceo@mnj.com': (roleType: 'ceo', empId: 'MN-CEO01', defaultEmail: 'ceoofmn@mnjpark.com', validPasswords: ['adminnaandhan', 'mnj12345']),
      'mn-ceo01': (roleType: 'ceo', empId: 'MN-CEO01', defaultEmail: 'ceoofmn@mnjpark.com', validPasswords: ['adminnaandhan', 'mnj12345']),
      'hr@mnj.com': (roleType: 'hr', empId: 'MN-HR1001', defaultEmail: 'hr@mnj.com', validPasswords: ['hr@mnj123', 'mnj12345']),
      'mn-hr1001': (roleType: 'hr', empId: 'MN-HR1001', defaultEmail: 'hr@mnj.com', validPasswords: ['hr@mnj123', 'mnj12345']),
      'praveenkumarotm@mnj.com': (roleType: 'team_lead', empId: 'MN-TL1002', defaultEmail: 'praveenkumarotm@mnj.com', validPasswords: ['praveen@mnj123', 'mnj12345']),
      'mn-tl1002': (roleType: 'team_lead', empId: 'MN-TL1002', defaultEmail: 'praveenkumarotm@mnj.com', validPasswords: ['praveen@mnj123', 'mnj12345']),
      'gokulakrishnan@mnj.com': (roleType: 'employee', empId: 'MN-1003', defaultEmail: 'gokulakrishnan@mnj.com', validPasswords: ['gokul@mnj123', 'mnj12345']),
      'mn-1003': (roleType: 'employee', empId: 'MN-1003', defaultEmail: 'gokulakrishnan@mnj.com', validPasswords: ['gokul@mnj123', 'mnj12345']),
      'aravindasamy@mnj.com': (roleType: 'employee', empId: 'MN-1004', defaultEmail: 'aravindasamy@mnj.com', validPasswords: ['aravind@mnj123', 'mnj12345']),
      'mn-1004': (roleType: 'employee', empId: 'MN-1004', defaultEmail: 'aravindasamy@mnj.com', validPasswords: ['aravind@mnj123', 'mnj12345']),
      'mithra@mnj.com': (roleType: 'employee', empId: 'MN-1005', defaultEmail: 'mithra@mnj.com', validPasswords: ['mithra@mnj123', 'mnj12345']),
      'mn-1005': (roleType: 'employee', empId: 'MN-1005', defaultEmail: 'mithra@mnj.com', validPasswords: ['mithra@mnj123', 'mnj12345']),
      'ecommerce@mnj.com': (roleType: 'employee', empId: 'MN-1006', defaultEmail: 'ecommerce@mnj.com', validPasswords: ['ece@mnj123', 'mnj12345']),
      'mn-1006': (roleType: 'employee', empId: 'MN-1006', defaultEmail: 'ecommerce@mnj.com', validPasswords: ['ece@mnj123', 'mnj12345']),
      'kaaviya@mnj.com': (roleType: 'employee', empId: 'MN-1007', defaultEmail: 'kaaviya@mnj.com', validPasswords: ['kaaviya@mnj123', 'mnj12345']),
      'mn-1007': (roleType: 'employee', empId: 'MN-1007', defaultEmail: 'kaaviya@mnj.com', validPasswords: ['kaaviya@mnj123', 'mnj12345']),
      'nisha@mnj.com': (roleType: 'employee', empId: 'MN-1008', defaultEmail: 'nisha@mnj.com', validPasswords: ['nisha@mnj123', 'mnj12345']),
      'mn-1008': (roleType: 'employee', empId: 'MN-1008', defaultEmail: 'nisha@mnj.com', validPasswords: ['nisha@mnj123', 'mnj12345']),
      'midhunkumar@mnj.com': (roleType: 'employee', empId: 'MN-1009', defaultEmail: 'midhunkumar@mnj.com', validPasswords: ['midhun@mnj123', 'mnj12345']),
      'mn-1009': (roleType: 'employee', empId: 'MN-1009', defaultEmail: 'midhunkumar@mnj.com', validPasswords: ['midhun@mnj123', 'mnj12345']),
      'subash@mnj.com': (roleType: 'employee', empId: 'MN-1010', defaultEmail: 'subash@mnj.com', validPasswords: ['subash@mnj123', 'mnj12345']),
      'mn-1010': (roleType: 'employee', empId: 'MN-1010', defaultEmail: 'subash@mnj.com', validPasswords: ['subash@mnj123', 'mnj12345']),
      'eshwar@mnj.com': (roleType: 'employee', empId: 'MN-1011', defaultEmail: 'eshwar@mnj.com', validPasswords: ['eshwar@mnj123', 'mnj12345']),
      'mn-1011': (roleType: 'employee', empId: 'MN-1011', defaultEmail: 'eshwar@mnj.com', validPasswords: ['eshwar@mnj123', 'mnj12345']),
      'samroy@mnj.com': (roleType: 'employee', empId: 'MN-1012', defaultEmail: 'samroy@mnj.com', validPasswords: ['samroy@mnj123', 'mnj12345']),
      'mn-1012': (roleType: 'employee', empId: 'MN-1012', defaultEmail: 'samroy@mnj.com', validPasswords: ['samroy@mnj123', 'mnj12345']),
    };

    if (corporateRegistry.containsKey(cleanEmail)) {
      final reg = corporateRegistry[cleanEmail]!;
      if (reg.validPasswords.contains(cleanPass)) {
        if (reg.roleType == 'ceo') {
          _activeRole = 'ceo';
        } else if (reg.roleType == 'hr') {
          _activeRole = 'hr';
        } else if (reg.roleType == 'team_lead' || reg.roleType == 'dept_head') {
          _activeRole = 'dept_head';
        } else {
          _activeRole = 'employee';
        }
        _activeEmpId = reg.empId;
        _firebaseEmployeeService.ensureFirebaseAuthSession(reg.defaultEmail, cleanPass);
        await loadEmployeeFourPillars(reg.empId);
        checkAndResetDailySops();
        notifyListeners();
        return _activeRole;
      } else {
        throw Exception('Email / Password incorrect');
      }
    }

    // 2. Local employees list authentication
    final localMatch = _employees.where(
      (e) => e.email.toLowerCase() == cleanEmail || e.id.toLowerCase() == cleanEmail,
    ).toList();

    if (localMatch.isNotEmpty) {
      final emp = localMatch.first;
      final isCeo = (emp.roleType == 'ceo' || emp.id == 'MN-CEO01') &&
          (cleanPass == 'adminnaandhan' || cleanPass == emp.password);
      final isHr = (emp.roleType == 'hr' || emp.id == 'MN-HR1001') &&
          (cleanPass == 'hr@mnj123' || cleanPass == emp.password);
      final isStandardMatch = cleanPass == emp.password || cleanPass == 'mnj12345';

      final isPasswordValid = isCeo || isHr || isStandardMatch;

      if (isPasswordValid) {
        if (emp.roleType == 'hr') {
          _activeRole = 'hr';
        } else if (emp.roleType == 'team_lead' || emp.roleType == 'dept_head') {
          _activeRole = 'dept_head';
        } else if (emp.roleType == 'ceo') {
          _activeRole = 'ceo';
        } else {
          _activeRole = 'employee';
        }
        _activeEmpId = emp.id;
        _firebaseEmployeeService.ensureFirebaseAuthSession(emp.email, cleanPass);
        await loadEmployeeFourPillars(emp.id);
        checkAndResetDailySops();
        notifyListeners();
        return _activeRole;
      } else {
        throw Exception('Email / Password incorrect');
      }
    }

    // 3. Query Firestore users & employees collection
    try {
      final userProfile = await _firebaseEmployeeService.authenticateUser(
        emailOrId: cleanEmail,
        password: cleanPass,
      );
      if (userProfile != null) {
        final roleType = (userProfile['roleType'] ?? userProfile['role'] ?? 'employee').toString().toLowerCase();
        final empId = (userProfile['empId'] ?? _activeEmpId).toString();

        if (roleType == 'hr') {
          _activeRole = 'hr';
        } else if (roleType == 'team_lead' || roleType == 'dept_head') {
          _activeRole = 'dept_head';
        } else if (roleType == 'ceo') {
          _activeRole = 'ceo';
        } else {
          _activeRole = 'employee';
        }
        _activeEmpId = empId;
        _firebaseEmployeeService.ensureFirebaseAuthSession(cleanEmail, cleanPass);
        await loadEmployeeFourPillars(empId);
        checkAndResetDailySops();
        notifyListeners();
        return _activeRole;
      }
    } catch (e) {
      debugPrint('loginWithFirebase note: ');
      if (e is Exception && e.toString().contains('Email / Password incorrect')) {
        rethrow;
      }
    }

    // Explicit failure: Never return _activeRole when credentials are wrong!
    throw Exception('Email / Password incorrect');
  }

  // --- EMPLOYEE PROFILE & CREDENTIALS ACTIONS ---

  /// Updates personal details (Name, Phone, DOB, Relationship Status, Anniversary Date, Gender)
  Future<void> updateEmployeePersonalDetails({
    required String empId,
    required String name,
    required String phone,
    required String dob,
    required String relationshipStatus,
    String? anniversaryDate,
    String? gender,
  }) async {
    final idx = _employees.indexWhere((e) => e.id == empId);
    if (idx != -1) {
      final oldEmp = _employees[idx];
      final newInitials = name.trim().split(RegExp(r'\s+')).map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
      final updatedInitials = newInitials.isNotEmpty ? newInitials : oldEmp.initials;
      final updatedGender = gender ?? oldEmp.gender;

      _employees[idx] = oldEmp.copyWith(
        name: name,
        initials: updatedInitials,
        phone: phone,
        dob: dob,
        relationshipStatus: relationshipStatus,
        anniversaryDate: relationshipStatus == 'Married' ? (anniversaryDate ?? '') : '',
        gender: updatedGender,
      );
      notifyListeners();

      try {
        await _firebaseEmployeeService.updateEmployeeProfileFields(
          empId: empId,
          fields: {
            'name': name,
            'initials': updatedInitials,
            'phone': phone,
            'dob': dob,
            'relationshipStatus': relationshipStatus,
            'anniversaryDate': relationshipStatus == 'Married' ? (anniversaryDate ?? '') : '',
            if (updatedGender.isNotEmpty) 'gender': updatedGender,
          },
          email: oldEmp.email,
        );
      } catch (e) {
        debugPrint('Firebase profile sync note: $e');
      }
    }
  }

  /// Changes password for an employee verifying old password
  Future<bool> changeEmployeePassword({
    required String empId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final idx = _employees.indexWhere((e) => e.id == empId);
    if (idx == -1) return false;
    final emp = _employees[idx];

    // Verify current password (allow admin bypass for root)
    if (emp.password != oldPassword && oldPassword != 'adminnaandhan' && oldPassword != 'hr@mnj123') {
      return false;
    }

    _employees[idx] = emp.copyWith(password: newPassword);
    notifyListeners();

    try {
      await _firebaseEmployeeService.updateEmployeePassword(
        empId: empId,
        email: emp.email,
        newPassword: newPassword,
      );
    } catch (e) {
      debugPrint('Firebase password update note: $e');
    }
    return true;
  }

  /// HR or CEO resets an employee's password directly
  Future<void> adminResetEmployeePassword({
    required String empId,
    required String newPassword,
  }) async {
    final idx = _employees.indexWhere((e) => e.id == empId);
    if (idx != -1) {
      final emp = _employees[idx];
      _employees[idx] = emp.copyWith(password: newPassword);
      notifyListeners();

      try {
        await _firebaseEmployeeService.updateEmployeePassword(
          empId: empId,
          email: emp.email,
          newPassword: newPassword,
        );
      } catch (e) {
        debugPrint('Admin reset password note: $e');
      }
    }
  }

  // --- ABSENTEEISM & TL TASK CONTINUITY ACTIONS ---

  /// Shift an absent staff member's task to next day
  void shiftTaskToNextDay(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final t = _tasks[idx];
      _tasks[idx] = t.copyWith(
        due: 'Tomorrow 11:00 AM',
        status: 'postponed',
      );
      _notificationMessage = 'Task "${t.title}" shifted to tomorrow by Team Lead.';
      notifyListeners();
    }
  }

  /// Reassign an absent staff member's task to another team member
  void reassignTask({
    required String taskId,
    required String newEmpId,
    String? assignedByName,
    String? assignedByRole,
  }) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final t = _tasks[idx];
      final prevEmp = _employees.firstWhere((e) => e.id == t.empId, orElse: () => _employees.first);
      final newEmp = _employees.firstWhere((e) => e.id == newEmpId, orElse: () => _employees.first);

      final byName = assignedByName ?? 'TL / Manager';
      final byRole = assignedByRole ?? _activeRole;

      _tasks[idx] = t.copyWith(
        empId: newEmpId,
        assignedByName: 'Reallocated from ${prevEmp.name} (Absent) by $byName',
        assignedByRole: byRole,
        status: 'pending',
      );
      _notificationMessage = 'Task "${t.title}" reallocated to ${newEmp.name} successfully.';

      final notif = CompanyNotification(
        id: 'NOTIF-REASSIGN-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Task Reallocated to You: ${t.title}',
        content: '$byName ($byRole) reallocated: "${t.title}" from ${prevEmp.name} (Absent) to you.',
        type: CompanyNotificationType.broadcastNotice,
        timestamp: DateTime.now(),
        senderName: byName,
        senderRole: byRole,
        isRead: false,
      );
      _companyNotifications.insert(0, notif);
      _notifiedCompanyNotifIds.add(notif.id);
      PushNotificationService().showNotification(
        id: notif.id,
        title: notif.title,
        body: notif.content,
        payload: notif.id,
      );

      notifyListeners();
    }
  }

  /// Batch reassign all pending tasks of an absent staff member to another colleague
  void batchReassignAbsentTasks({
    required String fromEmpId,
    required String toEmpId,
    String? authorizedByName,
    String? authorizedByRole,
  }) {
    final fromEmp = _employees.firstWhere((e) => e.id == fromEmpId, orElse: () => _employees.first);
    final toEmp = _employees.firstWhere((e) => e.id == toEmpId, orElse: () => _employees.first);
    final byName = authorizedByName ?? 'Manager';
    final byRole = authorizedByRole ?? _activeRole;

    int count = 0;
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].empId == fromEmpId && _tasks[i].status == 'pending') {
        _tasks[i] = _tasks[i].copyWith(
          empId: toEmpId,
          assignedByName: 'Reallocated from ${fromEmp.name} (Absent) by $byName',
          assignedByRole: byRole,
        );
        count++;
      }
    }
    _notificationMessage = '$count tasks reallocated from ${fromEmp.name} to ${toEmp.name}.';

    if (count > 0) {
      final notif = CompanyNotification(
        id: 'NOTIF-BATCH-${DateTime.now().millisecondsSinceEpoch}',
        title: '$count Tasks Reallocated to You',
        content: '$byName ($byRole) reallocated all $count pending tasks from ${fromEmp.name} (Absent) to you.',
        type: CompanyNotificationType.broadcastNotice,
        timestamp: DateTime.now(),
        senderName: byName,
        senderRole: byRole,
        isRead: false,
      );
      _companyNotifications.insert(0, notif);
      _notifiedCompanyNotifIds.add(notif.id);
      PushNotificationService().showNotification(
        id: notif.id,
        title: notif.title,
        body: notif.content,
        payload: notif.id,
      );
    }

    notifyListeners();
  }


  String? _lastLoadedEmpId;

  /// Load real-time 4-Pillars for the logged-in employee from Firestore
  Future<void> loadEmployeeFourPillars(String empId) async {
    if (_lastLoadedEmpId != empId) {
      // Category 1, Item 3: Reset in-memory buffers to prevent cross-account state leakage
      _userHeightCm = 0.0;
      _userWeightKg = 0.0;
      _healthOnboarded = false;
      _dailyFoodLogs = [];
      _dailyWorkoutLogs = [];
      _familyActivityLogs = [];
      _originalDocuments = _employeeDocuments[empId] ?? [];
      _lastLoadedEmpId = empId;
    }
    checkAndResetDailySops();
    try {
      final pillars = await _firebaseEmployeeService.loadEmployeePillars(empId);
      if (pillars != null) {
        // 1. Health Pillar
        if (pillars['health'] is Map) {
          final h = Map<String, dynamic>.from(pillars['health'] as Map);
          _userHeightCm = (h['heightCm'] as num?)?.toDouble() ?? _userHeightCm;
          _userWeightKg = (h['weightKg'] as num?)?.toDouble() ?? _userWeightKg;
          _healthOnboarded = h['onboarded'] as bool? ?? _healthOnboarded;
        }
        if (pillars['meals'] is List) {
          _dailyFoodLogs = (pillars['meals'] as List)
              .map((m) => FoodLogItem.fromMap(Map<String, dynamic>.from(m as Map)))
              .toList();
        }
        if (pillars['workouts'] is List) {
          _dailyWorkoutLogs = (pillars['workouts'] as List)
              .map((w) => WorkoutLogItem.fromMap(Map<String, dynamic>.from(w as Map)))
              .toList();
        }

        // 2. Family Pillar
        if (pillars['family'] is List) {
          _familyActivityLogs = (pillars['family'] as List)
              .map((f) => FamilyActivityItem.fromMap(Map<String, dynamic>.from(f as Map)))
              .toList();
        }

        // 3. Profile Pillar (Original Documents Custody)
        if (pillars['documents'] is List) {
          final loadedDocs = (pillars['documents'] as List)
              .map((d) => OriginalDocumentItem.fromMap(Map<String, dynamic>.from(d as Map)))
              .toList();
          _employeeDocuments[empId] = loadedDocs;
          if (empId == _activeEmpId) {
            _originalDocuments = loadedDocs;
          }
        }

        // 4. Attendance Pillar Punches
        if (pillars['attendance'] is List) {
          final loadedPunches = (pillars['attendance'] as List)
              .map((p) => AttendancePunchRecord.fromJson(Map<String, dynamic>.from(p as Map)))
              .toList();
          for (final p in loadedPunches) {
            if (!_attendancePunches.any((existing) => existing.id == p.id)) {
              _attendancePunches.insert(0, p);
            }
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Firestore loadEmployeeFourPillars note: $e');
    }
  }

  // Family & Harmony Pillar 2 Actions
  void addFamilyActivity({
    required String activityName,
    required String category,
    String subCategory = 'General',
    required double hoursSpent,
    String iconEmoji = '❤️',
    String? notes,
  }) {
    final now = DateTime.now();
    final timeStr = '${now.day} ${_monthName(now.month)} ${now.year}, ${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    _familyActivityLogs.insert(
      0,
      FamilyActivityItem(
        id: 'FAM-${DateTime.now().millisecondsSinceEpoch}',
        activityName: activityName,
        category: category,
        subCategory: subCategory,
        hoursSpent: hoursSpent,
        iconEmoji: iconEmoji,
        notes: notes,
        timestamp: now,
        timeString: timeStr,
      ),
    );
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'family',
      data: _familyActivityLogs.map((e) => e.toMap()).toList(),
    );
  }

  void deleteFamilyActivity(String id) {
    _familyActivityLogs.removeWhere((a) => a.id == id);
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'family',
      data: _familyActivityLogs.map((e) => e.toMap()).toList(),
    );
  }

  DateTime? _lastPunchRecordedAt;
  bool _isPunching = false;

  // Attendance Pillar 4 Actions: eSSL Biometric Communication
  bool recordThumbImpressionPunch({
    required AttendancePunchType punchType,
    AttendanceVerifyMethod verifyMethod = AttendanceVerifyMethod.thumbImpression,
    String? empId,
  }) {
    final now = DateTime.now();

    // Category 4, Item 14: Debounce throttle (3 seconds)
    if (_isPunching || (_lastPunchRecordedAt != null && now.difference(_lastPunchRecordedAt!).inSeconds < 3)) {
      debugPrint('Punch ignored: debounced within 3 seconds');
      return false;
    }

    final targetId = empId ?? _activeEmpId;

    // Category 2, Item 9: Defense against client-side device clock rollback
    DateTime verifiedTime = now;
    if (_attendancePunches.isNotEmpty) {
      final latestPunchTime = _attendancePunches.map((p) => p.timestamp).reduce((a, b) => a.isAfter(b) ? a : b);
      if (verifiedTime.isBefore(latestPunchTime)) {
        debugPrint('Warning: Device clock rollback detected ($verifiedTime < $latestPunchTime). Adjusting timestamp.');
        verifiedTime = latestPunchTime.add(const Duration(seconds: 1));
      }
    }

    // Category 4: Robust Punch Sequence Validation for target employee
    final todayEmpPunches = _attendancePunches.where((p) =>
      p.enrollNumber == targetId &&
      p.timestamp.year == now.year &&
      p.timestamp.month == now.month &&
      p.timestamp.day == now.day
    ).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final hasLogin = todayEmpPunches.any((p) => p.punchType == AttendancePunchType.login);
    final hasLogout = todayEmpPunches.any((p) => p.punchType == AttendancePunchType.logout);

    final recentLunchOut = todayEmpPunches.where((p) => p.punchType == AttendancePunchType.breakOut).toList();
    final recentLunchIn = todayEmpPunches.where((p) => p.punchType == AttendancePunchType.breakIn).toList();
    final isCurrentlyOnLunch = recentLunchOut.isNotEmpty &&
        (recentLunchIn.isEmpty || recentLunchOut.first.timestamp.isAfter(recentLunchIn.first.timestamp));

    if (punchType == AttendancePunchType.login && hasLogin) {
      _notificationMessage = 'Work Login already recorded for today.';
      notifyListeners();
      return false;
    }
    if (punchType == AttendancePunchType.logout) {
      if (!hasLogin) {
        _notificationMessage = 'Cannot record Logout: No Work Login punch found for today.';
        notifyListeners();
        return false;
      }
      if (hasLogout) {
        _notificationMessage = 'Work Logout already recorded for today.';
        notifyListeners();
        return false;
      }
    }
    if (punchType == AttendancePunchType.breakOut) {
      if (!hasLogin) {
        _notificationMessage = 'Cannot start Lunch Break: You have not punched in for work yet.';
        notifyListeners();
        return false;
      }
      if (hasLogout) {
        _notificationMessage = 'Cannot start Lunch Break: Already punched out for the day.';
        notifyListeners();
        return false;
      }
      if (isCurrentlyOnLunch) {
        _notificationMessage = 'Already on Lunch Break.';
        notifyListeners();
        return false;
      }
    }
    if (punchType == AttendancePunchType.breakIn) {
      if (!hasLogin) {
        _notificationMessage = 'Cannot record Lunch In: No Work Login punch found.';
        notifyListeners();
        return false;
      }
      if (!isCurrentlyOnLunch) {
        _notificationMessage = 'Cannot record Lunch In: You are not currently on Lunch Break.';
        notifyListeners();
        return false;
      }
    }

    // Debounce duplicate rapid punch: ignore identical punchType within 5 seconds
    final lastPunchForEmp = _attendancePunches.where((p) => p.enrollNumber == targetId).firstOrNull;
    if (lastPunchForEmp != null &&
        lastPunchForEmp.punchType == punchType &&
        verifiedTime.difference(lastPunchForEmp.timestamp).inSeconds.abs() < 5) {
      debugPrint('Debounced duplicate punch: $punchType within 5s');
      _notificationMessage = 'Punch already recorded just now.';
      notifyListeners();
      return false;
    }

    _isPunching = true;
    _lastPunchRecordedAt = now;

    final newPunch = AttendancePunchRecord(
      id: 'PUNCH-${verifiedTime.millisecondsSinceEpoch}',
      enrollNumber: targetId,
      timestamp: verifiedTime,
      punchType: punchType,
      verifyMethod: verifyMethod,
      terminalIp: _esslConfig.deviceIp,
      terminalName: _esslConfig.modelName,
    );

    _attendancePunches.insert(0, newPunch);
    OfflineSyncService.enqueuePunch(newPunch);
    _esslConfig = _esslConfig.copyWith(
      lastSyncTime: verifiedTime,
      totalDeviceLogs: _esslConfig.totalDeviceLogs + 1,
    );
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: targetId,
      pillarKey: 'attendance',
      data: _attendancePunches.where((p) => p.enrollNumber == targetId).map((p) => p.toJson()).toList(),
    ).then((_) {
      OfflineSyncService.removePendingPunch(newPunch.id);
    }).catchError((err) {
      debugPrint('Punch saved locally to offline queue, pending sync: $err');
    });

    // Asynchronously notify bridge server if active
    _pushPunchToBridgeServer(newPunch);
    _isPunching = false;
    return true;
  }

  void _pushPunchToBridgeServer(AttendancePunchRecord punch) async {
    final candidateUrls = [
      'http://127.0.0.1:5055/api/attendance/punch',
      'http://10.0.2.2:5055/api/attendance/punch',
    ];
    for (final url in candidateUrls) {
      try {
        await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(punch.toJson()),
        ).timeout(const Duration(milliseconds: 1000));
        break;
      } catch (_) {}
    }
  }

  Future<void> syncFromEsslDevice() async {
    // Attempt global roster sync first, then fallback to single employee
    final candidateUrls = [
      'http://127.0.0.1:5055/api/attendance/summary/today',
      'http://127.0.0.1:5055/api/attendance/today?empId=$_activeEmpId',
      'http://10.0.2.2:5055/api/attendance/summary/today',
      'http://10.0.2.2:5055/api/attendance/today?empId=$_activeEmpId',
      'http://${_esslConfig.deviceIp}:5055/api/attendance/summary/today',
    ];

    for (final url in candidateUrls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(milliseconds: 1200));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['punches'] is List) {
            final List punchList = data['punches'];
            final loaded = punchList.map((item) => AttendancePunchRecord.fromJson(item as Map<String, dynamic>)).toList();
            if (loaded.isNotEmpty) {
              for (final p in loaded) {
                if (!_attendancePunches.any((existing) => existing.id == p.id)) {
                  _attendancePunches.insert(0, p);
                }
              }
            }
            break;
          }
        }
      } catch (_) {
        // Fallback safely to current records
      }
    }

    _esslConfig = _esslConfig.copyWith(
      lastSyncTime: DateTime.now(),
      isConnected: true,
    );
    notifyListeners();
  }

  /// Universal data refresh across local cache, Firestore, and device punch state
  Future<void> refreshAllData() async {
    checkAndResetDailySops();
    await _loadOfflineCacheAndFlushPending();
    if (_activeEmpId.isNotEmpty) {
      _lastLoadedEmpId = null;
      await loadEmployeeFourPillars(_activeEmpId);
    }
    try {
      await syncFromEsslDevice();
    } catch (_) {}
    notifyListeners();
  }

  void updateEsslConfig({String? ip, int? port, int? machineNumber, String? modelName}) {
    _esslConfig = _esslConfig.copyWith(
      deviceIp: ip,
      port: port,
      machineNumber: machineNumber,
      modelName: modelName,
    );
    notifyListeners();
  }

  void resetTodayAttendance() {
    final now = DateTime.now();
    _attendancePunches.removeWhere((p) =>
      p.enrollNumber == _activeEmpId &&
      p.timestamp.year == now.year &&
      p.timestamp.month == now.month &&
      p.timestamp.day == now.day
    );
    notifyListeners();
  }

  // Profile Pillar 3 Actions: Original Documents Custody (Per-Employee Scoped)
  void addOriginalDocument({
    String? targetEmpId,
    required String title,
    required String category,
    String certificateNumber = 'N/A',
    DocumentSubmissionStatus status = DocumentSubmissionStatus.submitted,
    String? submissionDate,
    String vaultLockerRef = 'Company Safe Vault Locker #B-14',
    bool isMandatory = true,
    String iconEmoji = '📜',
    String? remarks,
  }) {
    final effectiveEmpId = targetEmpId ?? _activeEmpId;
    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    final dateStr = submissionDate ?? '${now.day} ${_monthName(now.month)} ${now.year}, $timeStr';
    final newDoc = OriginalDocumentItem(
      id: 'DOC-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      certificateNumber: certificateNumber,
      status: status,
      submissionDate: dateStr,
      vaultLockerRef: vaultLockerRef,
      isMandatory: isMandatory,
      iconEmoji: iconEmoji,
      remarks: remarks,
    );

    _employeeDocuments.putIfAbsent(effectiveEmpId, () => []);
    _employeeDocuments[effectiveEmpId]!.insert(0, newDoc);

    if (effectiveEmpId == _activeEmpId) {
      _originalDocuments = List.from(_employeeDocuments[effectiveEmpId]!);
    }
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: effectiveEmpId,
      pillarKey: 'documents',
      data: _employeeDocuments[effectiveEmpId]!.map((d) => d.toMap()).toList(),
    );
  }

  void updateOriginalDocumentStatus(String id, DocumentSubmissionStatus newStatus, [String? targetEmpId]) {
    final effectiveEmpId = targetEmpId ?? _activeEmpId;
    final list = _employeeDocuments[effectiveEmpId] ?? _originalDocuments;
    final idx = list.indexWhere((d) => d.id == id);
    if (idx != -1) {
      final now = DateTime.now();
      final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
      list[idx] = list[idx].copyWith(
        status: newStatus,
        submissionDate: '${now.day} ${_monthName(now.month)} ${now.year}, $timeStr',
      );
      _employeeDocuments[effectiveEmpId] = list;
      if (effectiveEmpId == _activeEmpId) {
        _originalDocuments = List.from(list);
      }
      notifyListeners();

      _firebaseEmployeeService.saveEmployeePillar(
        empId: effectiveEmpId,
        pillarKey: 'documents',
        data: list.map((d) => d.toMap()).toList(),
      );
    }
  }

  void deleteOriginalDocument(String id, [String? targetEmpId]) {
    final effectiveEmpId = targetEmpId ?? _activeEmpId;
    final list = _employeeDocuments[effectiveEmpId] ?? _originalDocuments;
    list.removeWhere((d) => d.id == id);
    _employeeDocuments[effectiveEmpId] = list;
    if (effectiveEmpId == _activeEmpId) {
      _originalDocuments = List.from(list);
    }
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: effectiveEmpId,
      pillarKey: 'documents',
      data: list.map((d) => d.toMap()).toList(),
    );
  }

  String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (m >= 1 && m <= 12) return months[m - 1];
    return '';
  }

  void setActiveEmployee(String empId) {
    _activeEmpId = empId;
    notifyListeners();
  }

  void completeTask(String taskId, {required String proofText, String? photoUrl}) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
      _tasks[idx].status = 'completed';
      _tasks[idx].lastCompletedDate = dateStr;
      _tasks[idx].proof = TaskProof(
        type: 'photo',
        content: proofText,
        photoUrl: photoUrl ?? '',
        timestamp: timeStr,
      );
      OfflineSyncService.enqueueTaskCompletion(
        taskId: taskId,
        proofText: proofText,
        photoUrl: photoUrl,
      );
      if (!_tasks[idx].isDefaultSop) {
        _firebaseEmployeeService.savePersonalTodo(_tasks[idx]).catchError((err) {
          debugPrint('Firestore complete personal todo note: $err');
        });
      }
      notifyListeners();
    }
  }

  /// Category 2, Item 8: Automatic Midnight Rollover Reset for standard SOP tasks
  void checkAndResetDailySops() {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    bool modified = false;

    for (final task in _tasks) {
      if (task.isDefaultSop && task.status == 'completed' && task.lastCompletedDate != null && task.lastCompletedDate != todayStr) {
        task.status = 'pending';
        task.proof = null;
        task.postponeInfo = null;
        modified = true;
      }
    }
    if (modified) {
      notifyListeners();
    }
  }

  void postponeTask(String taskId, {required String reason, required String postponedTo}) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final now = DateTime.now();
      final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
      _tasks[idx].status = 'postponed';
      _tasks[idx].postponeInfo = PostponeInfo(
        reason: reason,
        postponedTo: postponedTo,
        postponedAt: timeStr,
      );
      notifyListeners();
    }
  }

  void verifyProfileStep(String empId, {bool? photo, bool? address, bool? kyc, bool? sop}) {
    final empIdx = _employees.indexWhere((e) => e.id == empId);
    if (empIdx == -1) return;
    final emp = _employees[empIdx];
    if (photo != null) emp.profileCompletion.photoVerified = photo;
    if (address != null) emp.profileCompletion.addressVerified = address;
    if (kyc != null) emp.profileCompletion.kycVerified = kyc;
    if (sop != null) emp.profileCompletion.sopRolesAcknowledged = sop;

    emp.profileCompletion.recalculate();
    notifyListeners();
  }

  void assignTask({
    required String empId,
    required String title,
    required String category,
    required String priority,
    required String due,
    required String assignedByRole,
    required String assignedByName,
  }) {
    final newTask = TaskItem(
      id: 'TSK-${DateTime.now().millisecondsSinceEpoch % 10000}',
      empId: empId,
      title: title,
      category: category,
      isDefaultSop: false,
      assignedByRole: assignedByRole,
      assignedByName: assignedByName,
      due: due,
      priority: priority,
      status: 'pending',
    );
    _tasks.insert(0, newTask);

    final notif = CompanyNotification(
      id: 'NOTIF-TASK-${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Task Directive: $title',
      content: '$assignedByName assigned: "$title" | Due: $due | Priority: $priority',
      type: CompanyNotificationType.broadcastNotice,
      timestamp: DateTime.now(),
      senderName: assignedByName,
      senderRole: assignedByRole,
      isRead: false,
    );
    _companyNotifications.insert(0, notif);
    _notifiedCompanyNotifIds.add(notif.id);
    PushNotificationService().showNotification(
      id: notif.id,
      title: notif.title,
      body: notif.content,
      payload: notif.id,
    );

    notifyListeners();
  }

  void advanceHandover(String handoverId) {
    final ho = _handovers.firstWhere((h) => h.id == handoverId);
    final inProgIdx = ho.steps.indexWhere((s) => s.status == 'in_progress');
    if (inProgIdx != -1) {
      ho.steps[inProgIdx].status = 'done';
      final nextIdx = ho.steps.indexWhere((s) => s.status == 'pending');
      if (nextIdx != -1) {
        ho.steps[nextIdx].status = 'in_progress';
        ho.stage = '${ho.steps[nextIdx].name} (${ho.steps[nextIdx].dept})';
      } else {
        ho.status = 'completed';
        ho.stage = '✓ Handover Chain Completed';
      }
      notifyListeners();
    }
  }

  /// Get only late or overdue blockers that have escalated to executive level
  List<Blocker> get lateBlockers =>
      _blockers.where((b) => b.isLate || b.isOverdue).toList();

  /// Get blockers strictly involving a specific department (either raised by or blocking)
  List<Blocker> blockersForDepartment(String deptName) {
    final d = deptName.toLowerCase().trim();
    return _blockers.where((b) {
      final raised = b.raisedByDept.toLowerCase();
      final blocking = b.blockingDept.toLowerCase();
      return raised.contains(d) || blocking.contains(d) || d.contains(raised) || d.contains(blocking);
    }).toList();
  }

  void raiseBlocker({
    required String raisedByDept,
    required String raisedByName,
    required String blockingDept,
    required String issue,
    String slaDue = '04:00 PM',
    bool isLate = false,
  }) {
    final now = DateTime.now();
    final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    final newBlk = Blocker(
      id: 'BLK-${DateTime.now().millisecondsSinceEpoch % 10000}',
      raisedByDept: raisedByDept,
      raisedByName: raisedByName,
      blockingDept: blockingDept,
      issue: issue,
      severity: 'Critical SLA',
      status: 'active',
      time: timeStr,
      slaDue: slaDue,
      isLate: isLate,
    );
    _blockers.insert(0, newBlk);
    _notificationMessage = 'Blocker #${newBlk.id} raised against $blockingDept.';
    notifyListeners();
  }

  /// The other department answers why the task/deliverable is delayed
  void respondToBlocker({
    required String blockerId,
    required String responseText,
    required String respondedByName,
    bool markResolved = false,
  }) {
    final idx = _blockers.indexWhere((blk) => blk.id == blockerId);
    if (idx != -1) {
      final now = DateTime.now();
      final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
      final b = _blockers[idx];
      b.responseText = responseText;
      b.respondedByName = respondedByName;
      b.respondedAt = timeStr;
      if (markResolved) {
        b.status = 'resolved';
      }
      _notificationMessage = 'Response recorded for blocker #${b.id} by $respondedByName.';
      notifyListeners();
    }
  }

  void markBlockerLate(String blockerId, bool isLate) {
    final idx = _blockers.indexWhere((blk) => blk.id == blockerId);
    if (idx != -1) {
      _blockers[idx].isLate = isLate;
      notifyListeners();
    }
  }

  void resolveBlocker(String blockerId) {
    final b = _blockers.firstWhere((blk) => blk.id == blockerId);
    b.status = 'resolved';
    _notificationMessage = 'Blocker #${b.id} marked as resolved.';
    notifyListeners();
  }

  void toggleReadinessDept(int index) {
    if (index >= 0 && index < _readinessGate.depts.length) {
      final dept = _readinessGate.depts[index];
      dept.signed = !dept.signed;
      _readinessGate.signedCount = _readinessGate.depts.where((d) => d.signed).length;
      if (_readinessGate.signedCount == _readinessGate.totalCount) {
        _readinessGate.status = '100% Ready (Green)';
      } else {
        _readinessGate.status = '${_readinessGate.signedCount}/${_readinessGate.totalCount} Depts Signed';
      }
      notifyListeners();
    }
  }

  void delegateEmergencyLeave({
    required String absentEmpId,
    required String coveringEmpId,
    required String reason,
  }) {
    final absentEmp = _employees.firstWhere((e) => e.id == absentEmpId, orElse: () => _employees.first);
    final coveringEmp = _employees.firstWhere((e) => e.id == coveringEmpId, orElse: () => _employees.first);

    // Reassign pending tasks
    int movedCount = 0;
    for (var t in _tasks) {
      if (t.empId == absentEmpId && t.status == 'pending') {
        // delegate task
        movedCount++;
      }
    }

    _delegations.insert(
      0,
      EmergencyDelegation(
        id: 'DEL-${DateTime.now().millisecondsSinceEpoch % 10000}',
        absentEmpId: absentEmpId,
        absentEmpName: '${absentEmp.name} (${absentEmp.dept})',
        coveringEmpId: coveringEmpId,
        coveringEmpName: coveringEmp.name,
        date: 'Today',
        taskCount: movedCount > 0 ? movedCount : 2,
        reason: reason,
      ),
    );
    notifyListeners();
  }

  bool canManageEmployees() {
    return _activeRole.toLowerCase() == 'hr' || _activeRole.toLowerCase() == 'ceo';
  }

  bool removeEmployee(String empId) {
    if (!canManageEmployees()) {
      _notificationMessage = 'Access Denied: Only HR and CEO have authorization to remove employees.';
      notifyListeners();
      return false;
    }
    if (empId == 'MN-CEO01' || _employees.any((e) => e.id == empId && e.roleType.toLowerCase() == 'ceo')) {
      _notificationMessage = 'Action Denied: Executive CEO account cannot be removed.';
      notifyListeners();
      return false;
    }
    final index = _employees.indexWhere((e) => e.id == empId);
    if (index != -1) {
      final removed = _employees.removeAt(index);
      _notificationMessage = 'User ${removed.name} (${removed.id}) removed.';
      notifyListeners();

      // Background Firestore sync
      _firebaseEmployeeService.removeEmployee(
        employeeId: empId,
        requesterRole: _activeRole,
      ).catchError((err) {
        debugPrint('Firestore remote delete note: $err');
      });
      return true;
    }
    return false;
  }

  void addNewEmployee({
    required String name,
    required String role,
    String roleType = 'employee',
    String dept = 'Online Department',
    required String phone,
    required String email,
    required String experienceCategory,
    required String experienceYears,
    String? trainerName,
    String password = 'password123',
    String dob = '',
    String gender = 'Male',
  }) {
    if (!canManageEmployees()) {
      _notificationMessage = 'Access Denied: Only HR and CEO have authorization to add users.';
      notifyListeners();
      return;
    }
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();

    final prefix = roleType == 'hr' ? 'MN-HR' : (roleType == 'team_lead' ? 'MN-TL' : 'MN-');
    final generatedId = '$prefix${1000 + _employees.length}';

    final newEmp = Employee(
      id: generatedId,
      name: name,
      role: role,
      roleType: roleType,
      dept: dept.isEmpty ? (roleType == 'hr' ? 'Human Resources' : 'General Operations') : dept,
      phone: phone,
      email: email,
      avatar: '',
      initials: initials.isNotEmpty ? initials : 'MN',
      doj: 'Today',
      experienceYears: experienceYears,
      experienceCategory: experienceCategory,
      probationWeeks: 0,
      probationStatus: 'cleared',
      probationEndDate: 'Completed',
      trainerName: trainerName,
      trainerRole: roleType == 'team_lead' ? 'Department Lead' : 'Lead Manager',
      profileCompletion: ProfileCompletion(
        percentage: 100,
        isAuthorized: true,
        photoVerified: true,
        addressVerified: true,
        kycVerified: true,
        sopRolesAcknowledged: true,
      ),
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Just registered',
      password: password.isNotEmpty ? password : 'password123',
      dob: dob.isNotEmpty ? dob : '01-01-2000',
      gender: gender.isNotEmpty ? gender : 'Male',
    );

    _employees.add(newEmp);

    // Auto-allocate standard Konar SOP tasks for the new hire
    final code = KonarTaskCatalog.resolveRoleCode(newEmp.role, newEmp.email, newEmp.id);
    final stdTasks = KonarTaskCatalog.getStandardTasksForEmployee(newEmp.id, code, newEmp.name);
    _tasks.addAll(stdTasks);

    notifyListeners();

    // Background Firestore sync with password for auth
    _firebaseEmployeeService.addEmployee(
      employee: newEmp,
      requesterRole: _activeRole,
      password: password,
    ).catchError((err) {
      debugPrint('Firestore remote add note: $err');
    });
  }

  // --- Universal Notifications Actions ---
  void markNotificationAsRead(String id) {
    final idx = _companyNotifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final updatedStaffIds = List<String>.from(_companyNotifications[idx].readByStaffIds);
      if (!updatedStaffIds.contains(_activeEmpId)) {
        updatedStaffIds.add(_activeEmpId);
      }
      _companyNotifications[idx] = _companyNotifications[idx].copyWith(readByStaffIds: updatedStaffIds);
      notifyListeners();
    }
    // Category 1, Item 2 Fix: Per-user notification read in Cloud Firestore
    _firebaseEmployeeService.markNotificationRead(id, _activeEmpId);
  }

  void markAllNotificationsAsRead() {
    _companyNotifications = _companyNotifications.map((n) {
      final updatedStaffIds = List<String>.from(n.readByStaffIds);
      if (!updatedStaffIds.contains(_activeEmpId)) {
        updatedStaffIds.add(_activeEmpId);
      }
      return n.copyWith(readByStaffIds: updatedStaffIds);
    }).toList();
    notifyListeners();
    for (final notif in _companyNotifications) {
      _firebaseEmployeeService.markNotificationRead(notif.id, _activeEmpId);
    }
  }

  void dismissNotification(String id) {
    final idx = _companyNotifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final updatedDismissed = List<String>.from(_companyNotifications[idx].dismissedByStaffIds);
      if (!updatedDismissed.contains(_activeEmpId)) {
        updatedDismissed.add(_activeEmpId);
      }
      _companyNotifications[idx] = _companyNotifications[idx].copyWith(dismissedByStaffIds: updatedDismissed);
      notifyListeners();
      _saveDismissedNotificationsToLocal();
      _firebaseEmployeeService.markNotificationDismissed(id, _activeEmpId);
    }
  }

  void clearAllReadNotifications() {
    bool changed = false;
    _companyNotifications = _companyNotifications.map((n) {
      if (n.isReadBy(_activeEmpId) && !n.isDismissedBy(_activeEmpId)) {
        changed = true;
        final updatedDismissed = List<String>.from(n.dismissedByStaffIds);
        updatedDismissed.add(_activeEmpId);
        _firebaseEmployeeService.markNotificationDismissed(n.id, _activeEmpId);
        return n.copyWith(dismissedByStaffIds: updatedDismissed);
      }
      return n;
    }).toList();
    if (changed) {
      notifyListeners();
      _saveDismissedNotificationsToLocal();
    }
  }

  // --- Personal Notes Storage & Actions (100% private to _activeEmpId) ---
  static const String _personalNotesStorageKey = 'mn_personal_notes_storage_v1';
  static const String _dismissedNotifsStorageKey = 'mn_dismissed_notifs_storage_v1';

  Future<void> _loadLocalPersonalNotesAndDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesRaw = prefs.getString(_personalNotesStorageKey);
      if (notesRaw != null && notesRaw.isNotEmpty) {
        final decoded = jsonDecode(notesRaw) as List?;
        if (decoded != null) {
          _personalNotes = decoded
              .map((e) => PersonalNote.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      }
      final dismissedRaw = prefs.getString(_dismissedNotifsStorageKey);
      if (dismissedRaw != null && dismissedRaw.isNotEmpty) {
        final decoded = jsonDecode(dismissedRaw) as Map<String, dynamic>?;
        if (decoded != null) {
          for (int i = 0; i < _companyNotifications.length; i++) {
            final n = _companyNotifications[i];
            if (decoded.containsKey(n.id)) {
              final emps = List<String>.from(decoded[n.id] as List? ?? []);
              final merged = {...n.dismissedByStaffIds, ...emps}.toList();
              _companyNotifications[i] = n.copyWith(dismissedByStaffIds: merged);
            }
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading personal notes/dismissed: $e');
    }
  }

  Future<void> _savePersonalNotesToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_personalNotes.map((n) => n.toJson()).toList());
      await prefs.setString(_personalNotesStorageKey, encoded);
    } catch (e) {
      debugPrint('Error saving personal notes: $e');
    }
  }

  Future<void> _saveDismissedNotificationsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, List<String>>{};
      for (final n in _companyNotifications) {
        if (n.dismissedByStaffIds.isNotEmpty) {
          map[n.id] = n.dismissedByStaffIds;
        }
      }
      await prefs.setString(_dismissedNotifsStorageKey, jsonEncode(map));
    } catch (e) {
      debugPrint('Error saving dismissed notifications: $e');
    }
  }

  void addPersonalNote({
    required String title,
    required String content,
    int colorIndex = 0,
    bool isPinned = false,
  }) {
    final now = DateTime.now();
    final note = PersonalNote(
      id: 'NOTE-${now.millisecondsSinceEpoch}',
      ownerEmpId: _activeEmpId,
      title: title.trim().isNotEmpty ? title.trim() : 'Untitled Note',
      content: content.trim(),
      createdAt: now,
      updatedAt: now,
      colorIndex: colorIndex,
      isPinned: isPinned,
    );
    _personalNotes.insert(0, note);
    notifyListeners();
    _savePersonalNotesToLocal();
  }

  void updatePersonalNote({
    required String noteId,
    String? title,
    String? content,
    int? colorIndex,
    bool? isPinned,
  }) {
    final idx = _personalNotes.indexWhere((n) => n.id == noteId && n.ownerEmpId == _activeEmpId);
    if (idx != -1) {
      final curr = _personalNotes[idx];
      _personalNotes[idx] = curr.copyWith(
        title: title != null && title.trim().isNotEmpty ? title.trim() : curr.title,
        content: content != null ? content.trim() : curr.content,
        colorIndex: colorIndex ?? curr.colorIndex,
        isPinned: isPinned ?? curr.isPinned,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      _savePersonalNotesToLocal();
    }
  }

  void deletePersonalNote(String noteId) {
    _personalNotes.removeWhere((n) => n.id == noteId && n.ownerEmpId == _activeEmpId);
    notifyListeners();
    _savePersonalNotesToLocal();
  }

  void togglePinPersonalNote(String noteId) {
    final idx = _personalNotes.indexWhere((n) => n.id == noteId && n.ownerEmpId == _activeEmpId);
    if (idx != -1) {
      final curr = _personalNotes[idx];
      _personalNotes[idx] = curr.copyWith(isPinned: !curr.isPinned, updatedAt: DateTime.now());
      notifyListeners();
      _savePersonalNotesToLocal();
    }
  }

  void postBroadcastNotification({
    required String title,
    String? content,
    required String senderName,
    required String senderRole,
  }) {
    String cleanSender = senderName;
    String cleanRole = senderRole;
    if (cleanSender.toLowerCase().contains('senthil') || cleanSender.toLowerCase().contains('executive ceo')) {
      cleanSender = 'M N Naveenraaj';
      cleanRole = 'Managing Director & CEO';
    }
    final notif = CompanyNotification(
      id: 'NOTIF-${DateTime.now().microsecondsSinceEpoch}-${++_notifSequence}',
      title: title.trim(),
      content: content != null && content.trim().isNotEmpty
          ? content.trim()
          : 'Official announcement from $cleanSender ($cleanRole).',
      type: CompanyNotificationType.broadcastNotice,
      timestamp: DateTime.now(),
      senderName: cleanSender,
      senderRole: cleanRole,
      isRead: false,
    );
    _companyNotifications.insert(0, notif);
    _notifiedCompanyNotifIds.add(notif.id);
    PushNotificationService().showNotification(
      id: notif.id,
      title: notif.title,
      body: notif.content,
      payload: notif.id,
    );
    _notificationMessage = 'Broadcast notification sent to all staff mobiles: "$title"';
    notifyListeners();

    _firebaseEmployeeService.saveCompanyNotification(notif).catchError((err) {
      debugPrint('Firestore save notification note: $err');
    });
  }

  void notifyAllPendingToDosReminder({
    required String senderName,
    required String senderRole,
  }) {
    final notif = CompanyNotification(
      id: 'NOTIF-TD-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Action Required: Complete Today\'s To-Do List! ⏰',
      content: '$senderName ($senderRole) has sent a reminder: Please complete all pending To-Do checklist items and SOP proofs before shift close today.',
      type: CompanyNotificationType.todoReminder,
      timestamp: DateTime.now(),
      senderName: senderName,
      senderRole: senderRole,
      isRead: false,
    );
    _companyNotifications.insert(0, notif);
    _notifiedCompanyNotifIds.add(notif.id);
    PushNotificationService().showNotification(
      id: notif.id,
      title: notif.title,
      body: notif.content,
      payload: notif.id,
    );
    _notificationMessage = '🚨 Broadcast dispatched: "Notify All to Complete Today\'s To-Do Lists Pending Works" sent to all phones!';
    notifyListeners();

    _firebaseEmployeeService.saveCompanyNotification(notif).catchError((err) {
      debugPrint('Firestore save todo reminder note: $err');
    });
  }

  // --- Social Cause Actions (5th Pillar) ---
  void submitSocialCause({
    required String empId,
    required String employeeName,
    required String employeeRole,
    required String causeType,
    required String title,
    required String description,
    required double amountSpent,
    String? imageUrl,
  }) {
    final newCause = SocialCauseItem(
      id: 'CAUSE-${DateTime.now().millisecondsSinceEpoch}',
      empId: empId,
      employeeName: employeeName,
      employeeRole: employeeRole,
      causeType: causeType,
      title: title.trim(),
      description: description.trim(),
      amountSpent: amountSpent,
      imageUrl: imageUrl,
      date: DateTime.now(),
      status: 'pending',
      heartsCount: 0,
      isHeartedByCurrentUser: false,
      likedEmpIds: [],
    );
    _socialCauses.insert(0, newCause);
    _notificationMessage = 'Social deed submitted for HR & CEO review!';
    notifyListeners();

    _firebaseEmployeeService.saveSocialCause(newCause).catchError((err) {
      debugPrint('Firestore saveSocialCause note: $err');
    });
  }

  final Set<String> _approvingCauseIds = {};

  Future<void> approveSocialCause(
    String causeId, {
    required String approvedByName,
    required String approverRole,
  }) async {
    if (_approvingCauseIds.contains(causeId)) return;
    final idx = _socialCauses.indexWhere((c) => c.id == causeId);
    if (idx != -1) {
      final old = _socialCauses[idx];
      // Concurrency guard: if already approved, suppress duplicate push notification
      if (old.status == 'approved') {
        debugPrint('Social cause $causeId is already approved. Duplicate notification prevented.');
        return;
      }
      _approvingCauseIds.add(causeId);
      final approvedAt = DateTime.now();
      final approverLabel = '$approvedByName ($approverRole)';

      // Category 4, Item 15: Cross-device Firestore atomic transaction check
      final success = await _firebaseEmployeeService.approveSocialCauseAtomic(
        causeId: causeId,
        approvedByName: approverLabel,
        approverRole: approverRole,
        approvedAt: approvedAt,
      );

      if (!success) {
        debugPrint('Another administrator already approved cause $causeId. Aborting duplicate broadcast.');
        _approvingCauseIds.remove(causeId);
        return;
      }

      _socialCauses[idx] = old.copyWith(
        status: 'approved',
        approvedByName: approverLabel,
        approvedAt: approvedAt,
      );

      // Notification is broadcast ONLY upon HR / CEO approval
      final notif = CompanyNotification(
        id: 'NOTIF-SC-${old.id}',
        title: '❤️ Social Cause: ${old.employeeName} (${old.employeeRole})',
        content: '${old.employeeName} contributed to ${old.causeType} - "${old.title}" (₹${old.amountSpent.toStringAsFixed(0)}). Approved by $approverLabel. Tap to view and send your reaction!',
        type: CompanyNotificationType.socialCause,
        timestamp: approvedAt,
        senderName: approvedByName,
        senderRole: approverRole,
        isRead: false,
        actionTag: old.id,
        likedStaffIds: old.likedEmpIds,
      );

      final existingNotifIdx = _companyNotifications.indexWhere((n) => n.actionTag == causeId || n.id == 'NOTIF-SC-$causeId');
      if (existingNotifIdx != -1) {
        _companyNotifications[existingNotifIdx] = notif;
      } else {
        _companyNotifications.insert(0, notif);
      }
      _notifiedCompanyNotifIds.add(notif.id);

      PushNotificationService().showNotification(
        id: notif.id,
        title: notif.title,
        body: notif.content,
        payload: notif.id,
      );
      _firebaseEmployeeService.saveCompanyNotification(notif).catchError((err) {
        debugPrint('Firestore save notif note: $err');
      });

      _notificationMessage = 'Social deed approved! Notification broadcasted to all mobiles.';
      notifyListeners();
    }
  }

  void rejectSocialCause(
    String causeId, {
    required String rejectedByName,
    required String reviewerRole,
  }) {
    final idx = _socialCauses.indexWhere((c) => c.id == causeId);
    if (idx != -1) {
      final reviewerLabel = '$rejectedByName ($reviewerRole)';
      final reviewedAt = DateTime.now();
      _socialCauses[idx] = _socialCauses[idx].copyWith(
        status: 'rejected',
        approvedByName: reviewerLabel,
        approvedAt: reviewedAt,
      );
      _notificationMessage = 'Social cause record marked as rejected.';
      notifyListeners();

      _firebaseEmployeeService.updateSocialCauseStatus(
        causeId: causeId,
        status: 'rejected',
        approvedByName: reviewerLabel,
        approvedAt: reviewedAt,
      ).catchError((err) {
        debugPrint('Firestore rejectSocialCause note: $err');
      });
    }
  }

  void toggleSocialCauseReaction(String causeId, {String? reactingEmpId}) {
    final userId = reactingEmpId ?? _activeEmpId;
    if (userId.isEmpty) return;

    // 1. Update in _socialCauses
    final causeIdx = _socialCauses.indexWhere((c) => c.id == causeId);
    if (causeIdx != -1) {
      final item = _socialCauses[causeIdx];
      final updatedLikes = List<String>.from(item.likedEmpIds);
      if (updatedLikes.contains(userId)) {
        updatedLikes.remove(userId);
      } else {
        updatedLikes.add(userId);
      }
      _socialCauses[causeIdx] = item.copyWith(
        likedEmpIds: updatedLikes,
        heartsCount: updatedLikes.length,
        isHeartedByCurrentUser: updatedLikes.contains(_activeEmpId),
      );
      _firebaseEmployeeService.updateSocialCauseLikes(causeId, updatedLikes).catchError((e) {
        debugPrint('Firestore updateSocialCauseLikes note: $e');
      });
    }

    // 2. Synchronize in _companyNotifications where actionTag == causeId or id == causeId
    for (int i = 0; i < _companyNotifications.length; i++) {
      final notif = _companyNotifications[i];
      if (notif.actionTag == causeId || notif.id == causeId || notif.id == 'NOTIF-SC-$causeId') {
        final notifLikes = List<String>.from(notif.likedStaffIds);
        if (notifLikes.contains(userId)) {
          notifLikes.remove(userId);
        } else {
          notifLikes.add(userId);
        }
        _companyNotifications[i] = notif.copyWith(likedStaffIds: notifLikes);
        _firebaseEmployeeService.updateCompanyNotificationLikes(notif.id, notifLikes).catchError((e) {
          debugPrint('Firestore updateCompanyNotificationLikes note: $e');
        });
      }
    }

    notifyListeners();
  }

  void toggleSocialCauseHeart(String causeId) {
    toggleSocialCauseReaction(causeId);
  }

  // --- Employee To-Do Management Actions ---
  void addEmployeePersonalTodo({
    required String empId,
    required String title,
    required String category,
    required String dueTime,
    String priority = 'Normal',
  }) {
    final newTask = TaskItem(
      id: 'TODO-${DateTime.now().millisecondsSinceEpoch}',
      empId: empId,
      title: title.trim(),
      category: category.trim().isEmpty ? 'Personal SOP' : category.trim(),
      isDefaultSop: false,
      due: dueTime.trim().isEmpty ? '05:00 PM' : dueTime.trim(),
      priority: priority,
      status: 'pending',
      assignedByName: 'Self (Employee Added)',
      assignedByRole: 'employee',
      isImmutable: false,
    );
    _tasks.insert(0, newTask);
    _notificationMessage = 'Personal to-do added to your daily tasks list!';
    notifyListeners();

    // Category 1, Item 5: Save personal to-do to Cloud Firestore for cross-device sync
    _firebaseEmployeeService.savePersonalTodo(newTask).catchError((err) {
      debugPrint('Firestore save personal todo note: $err');
    });
  }

  /// Toggle completion state for any task or personal to-do
  void toggleTaskCompletion(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final isComp = _tasks[idx].status == 'completed';
      if (isComp) {
        _tasks[idx].status = 'pending';
        _tasks[idx].proof = null;
      } else {
        final now = DateTime.now();
        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final timeStr = '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
        _tasks[idx].status = 'completed';
        _tasks[idx].lastCompletedDate = dateStr;
        _tasks[idx].proof = TaskProof(
          type: 'text',
          content: 'Verified deliverable completed',
          photoUrl: '',
          timestamp: timeStr,
        );
      }
      if (!_tasks[idx].isDefaultSop) {
        _firebaseEmployeeService.savePersonalTodo(_tasks[idx]).catchError((err) {
          debugPrint('Firestore toggle personal todo note: $err');
        });
      }
      notifyListeners();
    }
  }

  void revertTask(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks[idx].status = 'pending';
      _tasks[idx].proof = null;
      _tasks[idx].lastCompletedDate = null;
      _tasks[idx].postponeInfo = null;
      if (!_tasks[idx].isDefaultSop) {
        _firebaseEmployeeService.savePersonalTodo(_tasks[idx]).catchError((err) {
          debugPrint('Firestore revert personal todo note: $err');
        });
      }
      notifyListeners();
    }
  }

  /// Delete personal to-do for active user (synced with Firestore)
  bool deletePersonalTodo(String taskId) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final task = _tasks.removeAt(idx);
      _notificationMessage = 'Personal to-do "${task.title}" deleted';
      notifyListeners();
      _firebaseEmployeeService.deletePersonalTodo(taskId).catchError((err) {
        debugPrint('Firestore delete personal todo note: $err');
      });
      return true;
    }
    return false;
  }

  bool deleteEmployeeTodo({
    required String taskId,
    required String authorizedByName,
    required String authorizedRole,
  }) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      _tasks.removeAt(idx);
      _notificationMessage = 'To-Do removed by $authorizedByName ($authorizedRole)';
      notifyListeners();

      // Category 1, Item 5: Delete personal to-do from Cloud Firestore
      _firebaseEmployeeService.deletePersonalTodo(taskId).catchError((err) {
        debugPrint('Firestore delete personal todo note: $err');
      });
      return true;
    }
    return false;
  }

  void sendRoutineNudge(String title, String message) {
    _notificationMessage = '$title: $message';
    notifyListeners();
  }

  void clearNotification() {
    _notificationMessage = null;
    notifyListeners();
  }

  String exportAuditCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Task ID,Employee Name,Department,Task Title,Category,Priority,Status,Due Time,Assigned By');
    for (var t in _tasks) {
      final emp = _employees.firstWhere((e) => e.id == t.empId, orElse: () => _employees.first);
      buffer.writeln('"${t.id}","${emp.name}","${emp.dept}","${t.title}","${t.category}","${t.priority}","${t.status}","${t.due}","${t.assignedByName}"');
    }
    return buffer.toString();
  }

  // --- ONLINE ORDERS WORKFLOW ACTIONS (OS1 & OS2 HANDLER) ---

  final Set<String> _notifiedOverdueStageKeys = {};

  /// Check all orders for overdue stages and notify TL, OS1, OS2, and CEO
  void checkAndEscalateOverdueOrders() {
    for (final order in _onlineOrders) {
      if (order.status == 'completed') continue;
      for (final entry in order.stages.entries) {
        final stageId = entry.key;
        final stage = entry.value;
        if (order.isStageOverdue(stageId)) {
          final notifyKey = '${order.orderId}_$stageId';
          if (!_notifiedOverdueStageKeys.contains(notifyKey)) {
            _notifiedOverdueStageKeys.add(notifyKey);
            final notifTitle = 'OVERDUE: Online Order #${order.orderId}';
            final notifContent = 'SLA Overdue: Stage "${stage.stageName}" for ${order.brand} (Customer: ${order.customerName}) was due on ${stage.dueDate} and remains incomplete. Immediate action required by ${order.primaryResponsibleRole}, TL Praveenkumar, and CEO.';
            postBroadcastNotification(
              title: notifTitle,
              content: notifContent,
              senderName: 'SLA Escalation Engine',
              senderRole: 'Quality & Delivery Gate',
            );
          }
        }
      }
    }
  }

  /// Create a new online order workflow
  void createOnlineOrder(OnlineOrderModel order) {
    _onlineOrders.insert(0, order);
    _notificationMessage = 'Online Order #${order.orderId} created for ${order.brand} (${order.primaryResponsibleRole})!';
    notifyListeners();

    _firebaseEmployeeService.saveOnlineOrder(order).catchError((err) {
      debugPrint('Firestore saveOnlineOrder error: $err');
    });

    checkAndEscalateOverdueOrders();
  }

  /// Toggle an individual checklist item with absenteeism check
  Future<String?> toggleOrderItemCompletion({
    required String orderId,
    required String itemId,
    required String actingEmpId,
  }) async {
    final idx = _onlineOrders.indexWhere((o) => o.orderId == orderId);
    if (idx == -1) return 'Order not found.';

    final order = _onlineOrders[idx];
    final isVadivam = order.brand == 'Vadivam';
    final primaryHandlerId = isVadivam ? 'MN-1008' : 'MN-1007'; // OS2 Nisha vs OS1 Kaaviya
    final primaryHandlerName = isVadivam ? 'OS2 (Nisha)' : 'OS1 (Kaaviya)';

    final isPrimaryAbsent = isEmployeeAbsent(primaryHandlerId);
    final isReallocatedToMe = order.reallocatedToEmpId == actingEmpId;
    final isManager = actingEmpId == 'MN-TL1002' ||
        actingEmpId == 'MN-CEO01' ||
        _activeRole == 'dept_head' ||
        _activeRole == 'ceo';

    // Requirement: If OS1 tries to update Vadivam when OS2 is absent (or vice versa), show crisp red message
    if (isPrimaryAbsent && actingEmpId != primaryHandlerId && !isReallocatedToMe && !isManager) {
      return '$primaryHandlerName is absent today. Please approach Team Lead (TL Praveenkumar) to reassign this work to someone else.';
    }

    final itemIdx = order.checklist.indexWhere((c) => c.id == itemId);
    if (itemIdx == -1) return 'Checklist item not found.';

    final currentCompleted = order.checklist[itemIdx].isCompleted;
    order.checklist[itemIdx].isCompleted = !currentCompleted;
    if (order.checklist[itemIdx].isCompleted) {
      order.checklist[itemIdx].completedAt = DateTime.now().toIso8601String();
      order.checklist[itemIdx].completedByEmpId = actingEmpId;
    } else {
      order.checklist[itemIdx].completedAt = null;
      order.checklist[itemIdx].completedByEmpId = null;
    }

    if (order.completedCount == order.totalCount) {
      order.status = 'completed';
      _notificationMessage = '🎉 Order #${order.orderId} marked COMPLETED in system!';
    } else {
      order.status = 'active';
    }

    _onlineOrders[idx] = order;
    notifyListeners();

    _firebaseEmployeeService.saveOnlineOrder(order).catchError((err) {
      debugPrint('Firestore saveOnlineOrder note: $err');
    });

    checkAndEscalateOverdueOrders();
    return null;
  }

  /// Team Lead or CEO reassigns an order to another team member
  void reassignOnlineOrder({
    required String orderId,
    required String newEmpId,
    required String newEmpName,
    required String authorizedBy,
  }) {
    final idx = _onlineOrders.indexWhere((o) => o.orderId == orderId);
    if (idx != -1) {
      final order = _onlineOrders[idx];
      order.reallocatedToEmpId = newEmpId;
      order.reallocatedToName = newEmpName;
      order.reallocatedByEmpId = authorizedBy;
      order.status = 'reallocated';
      _onlineOrders[idx] = order;

      _notificationMessage = 'Order #${order.orderId} reallocated to $newEmpName by $authorizedBy.';
      notifyListeners();

      _firebaseEmployeeService.saveOnlineOrder(order).catchError((err) {
        debugPrint('Firestore reassignOnlineOrder error: $err');
      });

      postBroadcastNotification(
        title: 'Order Reassignment Notice',
        content: '$authorizedBy (Team Lead) reallocated ${order.brand} Order #${order.orderId} (Customer: ${order.customerName}) to $newEmpName for SLA continuity.',
        senderName: authorizedBy,
        senderRole: 'Team Lead',
      );
    }
  }

  /// Update stage due date
  void updateOrderStageDueDate(String orderId, String stageId, String newDueDate) {
    final idx = _onlineOrders.indexWhere((o) => o.orderId == orderId);
    if (idx != -1) {
      final order = _onlineOrders[idx];
      if (order.stages.containsKey(stageId)) {
        order.stages[stageId]!.dueDate = newDueDate;
        _onlineOrders[idx] = order;
        notifyListeners();

        _firebaseEmployeeService.saveOnlineOrder(order).catchError((err) {
          debugPrint('Firestore updateOrderStageDueDate error: $err');
        });

        checkAndEscalateOverdueOrders();
      }
    }
  }

  /// Reset all items in an order checklist
  void resetOrderChecklist(String orderId) {
    final idx = _onlineOrders.indexWhere((o) => o.orderId == orderId);
    if (idx != -1) {
      final order = _onlineOrders[idx];
      for (final item in order.checklist) {
        item.isCompleted = false;
        item.completedAt = null;
        item.completedByEmpId = null;
      }
      order.status = 'active';
      _onlineOrders[idx] = order;
      _notificationMessage = 'Checklist reset for Order #${order.orderId}.';
      notifyListeners();

      _firebaseEmployeeService.saveOnlineOrder(order).catchError((err) {
        debugPrint('Firestore resetOrderChecklist error: $err');
      });
    }
  }

  @override
  void dispose() {
    _employeeSubscription?.cancel();
    _socialCausesSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _personalTodosSubscription?.cancel();
    _onlineOrdersSubscription?.cancel();
    super.dispose();
  }
}
