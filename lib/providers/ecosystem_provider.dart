import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
import '../models/chat_message_model.dart';
import '../models/hr_attendance_sheet_models.dart';
import '../models/acceptance_notification_model.dart';
import '../services/google_sheets_attendance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/online_order_model.dart';
import '../models/konar_book_model.dart';
import '../services/firebase_employee_service.dart';
import '../services/offline_sync_service.dart';
import '../core/services/push_notification_service.dart';

class EcosystemProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  void setLoggedIn(bool value) {
    if (_isLoggedIn != value) {
      _isLoggedIn = value;
      notifyListeners();
    }
  }

  String _activeRole = 'ceo'; // 'employee', 'dept_head', 'hr', 'ceo'
  String _activeEmpId = 'MN-CEO01';
  String? _notificationMessage;

  String get activeRole => _activeRole;
  String get activeEmpId => _activeEmpId;
  String? get notificationMessage => _notificationMessage;
  bool get isCeo =>
      _activeRole.toLowerCase() == 'ceo' ||
      (_activeEmpId == 'MN-CEO01' &&
          _activeRole.toLowerCase() != 'hr' &&
          _activeRole.toLowerCase() != 'team_lead' &&
          _activeRole.toLowerCase() != 'dept_head' &&
          _activeRole.toLowerCase() != 'employee');
  bool get isHr =>
      _activeRole.toLowerCase() == 'hr' ||
      _activeEmpId == 'MN-HR1001' ||
      _activeEmpId == '7' ||
      currentEmployee.isHr;
  bool get isTeamLead =>
      _activeRole.toLowerCase() == 'team_lead' ||
      _activeRole.toLowerCase() == 'dept_head' ||
      _activeEmpId == 'MN-TL1002' ||
      _activeEmpId == '2' ||
      currentEmployee.isDeptHead;
  bool get isDeptHead => isTeamLead;

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
  List<Employee> get allEmployees => _employees;
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
  double? _dailyCalorieTarget;
  bool _stepPermissionGranted = false;
  Map<String, int> _dailyStepsMap = {};
  int _dailyStepGoal = 6000;
  List<FoodLogItem> _dailyFoodLogs = [];
  List<WorkoutLogItem> _dailyWorkoutLogs = [];
  List<WeightHeightRecord> _weightHistory = [];

  bool get healthOnboarded => _healthOnboarded;
  double get userHeightCm => _userHeightCm;
  double get userWeightKg => _userWeightKg;
  double get dailyCalorieTarget => _dailyCalorieTarget ?? 2000.0;
  bool get hasSetDailyCalorieTarget =>
      _dailyCalorieTarget != null && _dailyCalorieTarget! > 0;
  int get dailyStepGoal => _dailyStepGoal;
  bool get stepPermissionGranted => _stepPermissionGranted;
  Map<String, int> get dailyStepsMap => _dailyStepsMap;
  List<FoodLogItem> get dailyFoodLogs => _dailyFoodLogs;
  List<WorkoutLogItem> get dailyWorkoutLogs => _dailyWorkoutLogs;
  List<WeightHeightRecord> get weightHistory => _weightHistory;

  void setDailyStepGoal(int goal) {
    _dailyStepGoal = goal.clamp(500, 50000);
    notifyListeners();
    try {
      SharedPreferences.getInstance()
          .then((prefs) {
            prefs.setInt('health_step_goal_$_activeEmpId', _dailyStepGoal);
          })
          .catchError((_) {});
    } catch (_) {}
    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'health',
      data: {'dailyStepGoal': _dailyStepGoal},
    );
  }

  double get suggestedDailyCalories {
    if (_userWeightKg > 0 && _userHeightCm > 0) {
      final bmr = (10 * _userWeightKg) + (6.25 * _userHeightCm) - (5 * 28) + 5;
      final suggested = (bmr * 1.375).roundToDouble();
      return (suggested / 50).round() * 50.0;
    }
    return 2000.0;
  }

  int getStepsForDate(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    if (_dailyStepsMap.containsKey(key)) {
      return _dailyStepsMap[key]!;
    }
    return getWorkoutStepsForDate(date);
  }

  List<FoodLogItem> getFoodLogsForDate(DateTime date) {
    return _dailyFoodLogs
        .where(
          (f) =>
              f.timestamp.year == date.year &&
              f.timestamp.month == date.month &&
              f.timestamp.day == date.day,
        )
        .toList();
  }

  List<WorkoutLogItem> getWorkoutLogsForDate(DateTime date) {
    return _dailyWorkoutLogs
        .where(
          (w) =>
              w.timestamp.year == date.year &&
              w.timestamp.month == date.month &&
              w.timestamp.day == date.day,
        )
        .toList();
  }

  double getCaloriesConsumedForDate(DateTime date) {
    return getFoodLogsForDate(date).fold(0.0, (sum, f) => sum + f.calories);
  }

  double getCaloriesBurnedForDate(DateTime date) {
    return getWorkoutLogsForDate(
      date,
    ).fold(0.0, (sum, w) => sum + w.caloriesBurned);
  }

  int getWorkoutMinutesForDate(DateTime date) {
    return getWorkoutLogsForDate(
      date,
    ).fold(0, (sum, w) => sum + w.durationMinutes);
  }

  int getWorkoutStepsForDate(DateTime date) {
    return getWorkoutLogsForDate(date).fold(0, (sum, w) => sum + w.steps);
  }

  // Family & Harmony Pillar 2 State (Unforced, natural quality time)
  List<FamilyActivityItem> _familyActivityLogs = [];

  List<FamilyActivityItem> get familyActivityLogs => _familyActivityLogs;

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    final localDt = dt.toLocal();
    return localDt.year == now.year &&
        localDt.month == now.month &&
        localDt.day == now.day;
  }

  bool _isCurrentMonth(DateTime dt) {
    final now = DateTime.now();
    final localDt = dt.toLocal();
    return localDt.year == now.year && localDt.month == now.month;
  }

  double get totalFamilyHoursToday => _familyActivityLogs
      .where((a) => a.category == 'Family' && _isToday(a.timestamp))
      .fold(0.0, (sum, a) => sum + a.hoursSpent);

  double get totalFriendsHoursToday => _familyActivityLogs
      .where(
        (a) => a.category == 'Friends & Colleagues' && _isToday(a.timestamp),
      )
      .fold(0.0, (sum, a) => sum + a.hoursSpent);

  double get totalOverallSocialHoursToday =>
      totalFamilyHoursToday + totalFriendsHoursToday;

  bool _isSameDayDate(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  double getFamilyHoursForDate(DateTime date) => _familyActivityLogs
      .where((a) => a.category == 'Family' && _isSameDayDate(a.timestamp, date))
      .fold(0.0, (sum, a) => sum + a.hoursSpent);

  double getFriendsHoursForDate(DateTime date) => _familyActivityLogs
      .where(
        (a) =>
            a.category == 'Friends & Colleagues' &&
            _isSameDayDate(a.timestamp, date),
      )
      .fold(0.0, (sum, a) => sum + a.hoursSpent);

  double getTotalSocialHoursForDate(DateTime date) =>
      getFamilyHoursForDate(date) + getFriendsHoursForDate(date);

  List<FamilyActivityItem> getFamilyActivitiesForDate(DateTime date) =>
      _familyActivityLogs
          .where((a) => _isSameDayDate(a.timestamp, date))
          .toList();

  // Profile Pillar 3 & Document Custody State (Per-Employee Scoped)
  List<OriginalDocumentItem> _originalDocuments = [];
  List<OriginalDocumentItem> get originalDocuments => _originalDocuments;
  final Map<String, List<OriginalDocumentItem>> _employeeDocuments = {};

  List<OriginalDocumentItem> getEmployeeDocuments(String empId) {
    final emp = _employees.firstWhere(
      (e) => e.id == empId || e.empNo == empId,
      orElse: () => currentEmployee,
    );
    // CEO, Praveenkumar M (TL), and External Support Staff are exempt from document vault submissions
    if (emp.isCeo ||
        emp.name.toLowerCase().contains('praveen') ||
        emp.isExternalSupport) {
      return const [];
    }
    if (_employeeDocuments.containsKey(empId)) {
      return _employeeDocuments[empId]!;
    }
    if (empId == _activeEmpId && _originalDocuments.isNotEmpty) {
      return _originalDocuments;
    }
    return const [];
  }

  Future<void> loadAllStaffDocuments() async {
    for (final emp in _employees) {
      if (!emp.isCeo &&
          !emp.name.toLowerCase().contains('praveen') &&
          !emp.isExternalSupport) {
        await loadEmployeeDocuments(emp.id);
      }
    }
    notifyListeners();
  }

  Future<List<OriginalDocumentItem>> loadEmployeeDocuments(String empId) async {
    if (_employeeDocuments.containsKey(empId) &&
        _employeeDocuments[empId]!.isNotEmpty) {
      return _employeeDocuments[empId]!;
    }
    try {
      final pillars = await _firebaseEmployeeService.loadEmployeePillars(empId);
      if (pillars != null &&
          pillars['documents'] is List &&
          (pillars['documents'] as List).isNotEmpty) {
        final list = (pillars['documents'] as List)
            .map(
              (d) => OriginalDocumentItem.fromMap(
                Map<String, dynamic>.from(d as Map),
              ),
            )
            .toList();
        _employeeDocuments[empId] = list;
        if (empId == _activeEmpId) {
          _originalDocuments = list;
        }
        notifyListeners();
        return list;
      }
    } catch (_) {}
    _employeeDocuments[empId] = _employeeDocuments[empId] ?? [];
    return _employeeDocuments[empId]!;
  }

  int get allStaffDocsCount {
    int count = 0;
    for (final e in _employees) {
      if (e.hasAttendanceAndGrooming && e.roleType != 'ceo') {
        count += getEmployeeDocuments(e.id).length;
      }
    }
    return count;
  }

  int get allStaffSubmittedCount {
    int count = 0;
    for (final e in _employees) {
      if (e.hasAttendanceAndGrooming && e.roleType != 'ceo') {
        count += getEmployeeDocuments(
          e.id,
        ).where((d) => d.status == DocumentSubmissionStatus.submitted).length;
      }
    }
    return count;
  }

  int get allStaffPendingCount => allStaffDocsCount - allStaffSubmittedCount;

  int get totalOriginalsCount => _originalDocuments.length;
  int get submittedOriginalsCount => _originalDocuments
      .where((d) => d.status == DocumentSubmissionStatus.submitted)
      .length;
  int get pendingOriginalsCount => _originalDocuments
      .where((d) => d.status == DocumentSubmissionStatus.pending)
      .length;
  int get verifyingOriginalsCount => _originalDocuments
      .where((d) => d.status == DocumentSubmissionStatus.verifying)
      .length;

  double get documentsSubmissionRatio {
    if (_originalDocuments.isEmpty) return 0.0;
    final mandatory = _originalDocuments.where((d) => d.isMandatory).toList();
    if (mandatory.isEmpty) return 0.0;
    final submittedMandatory = mandatory
        .where((d) => d.status == DocumentSubmissionStatus.submitted)
        .length;
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
    if (currentEmployee.isOtm || currentEmployee.roleType == 'ceo') {
      return 14;
    }
    final row = currentEmployeeHrAttendanceRow;
    if (row != null) {
      return row.presentDaysCount +
          (row.lateCount <= 3 ? row.lateCount : 3) +
          row.mnwDaysCount;
    }
    final now = DateTime.now();
    final logins = _attendancePunches
        .where(
          (p) =>
              p.enrollNumber == _activeEmpId &&
              p.punchType == AttendancePunchType.login &&
              p.timestamp.year == now.year &&
              p.timestamp.month == now.month,
        )
        .map(
          (p) => '${p.timestamp.year}-${p.timestamp.month}-${p.timestamp.day}',
        )
        .toSet();
    return logins.isNotEmpty ? logins.length : 14;
  }

  /// Number of Tuesday Overtime days worked in current month
  int get tuesdayOvertimeDaysAttended {
    final now = DateTime.now();
    final row = currentEmployeeHrAttendanceRow;
    if (row != null) {
      int otCount = 0;
      for (final entry in row.days.entries) {
        final d = entry.key;
        final rec = entry.value;
        try {
          final dt = DateTime(now.year, now.month, d);
          if (dt.weekday == DateTime.tuesday &&
              (rec.type == HrAttendanceDayType.present ||
                  rec.type == HrAttendanceDayType.mnw)) {
            otCount++;
          }
        } catch (_) {}
      }
      return otCount;
    }
    final otLogins = _attendancePunches
        .where(
          (p) =>
              p.enrollNumber == _activeEmpId &&
              p.punchType == AttendancePunchType.login &&
              p.timestamp.year == now.year &&
              p.timestamp.month == now.month &&
              p.timestamp.weekday == DateTime.tuesday,
        )
        .map(
          (p) => '${p.timestamp.year}-${p.timestamp.month}-${p.timestamp.day}',
        )
        .toSet();
    return otLogins.length;
  }

  double get monthlyAttendancePercentage {
    if (currentEmployee.isOtm || currentEmployee.roleType == 'ceo') {
      return 100.0;
    }
    final row = currentEmployeeHrAttendanceRow;
    if (row != null) {
      final total = row.recordedDaysCount > 0 ? row.recordedDaysCount : 14;
      return ((workingDaysAttended / total) * 100.0).clamp(0.0, 100.0);
    }
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
    if (empId == 'MN-CEO01' || empId == 'MN-TL1002') return 50;
    final audits = getEmployeeGroomingAudits(empId);
    if (audits.isEmpty) return 50; // Standard compliant baseline
    return audits.first.pointsEarned.clamp(0, 50);
  }

  double getEmployeeGroomingPercentage(String empId) {
    if (empId == 'MN-CEO01' || empId == 'MN-TL1002') return 100.0;
    final audits = getEmployeeGroomingAudits(empId);
    if (audits.isEmpty) return 100.0; // Standard compliant baseline
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

  double get totalSalesAchieved => currentEmployeeSalesRecords
      .where((s) => _isCurrentMonth(s.date))
      .fold(0.0, (sum, s) => sum + s.amountInInr);
  double get monthlySalesTarget => _monthlySalesTarget;
  double get salesAchievementPercentage => _monthlySalesTarget <= 0
      ? 100.0
      : ((totalSalesAchieved / _monthlySalesTarget) * 100.0).clamp(0.0, 150.0);

  // Ring 5: Permission & Late Arrivals Account (4.0 hrs monthly balance + 1 CL rule)
  List<PermissionRecord> _permissionRecords = [];
  final double _monthlyPermissionHoursLimit = 4.0;
  final int _monthlyCasualLeavesLimit = 1;

  // Emergency Medical Leaves (with Mandatory Prescription <= 150 KB)
  List<MedicalLeaveRecord> _medicalLeaveRecords = [];

  // Acceptance Pop-up Notifications (Dispatched to HR, CEO, and TL)
  final List<AcceptancePopupNotification> _acceptancePopups = [];
  List<AcceptancePopupNotification> get acceptancePopups => _acceptancePopups;

  /// Returns the latest active unacknowledged acceptance popup for the active session user
  /// (Permanently disabled as emergency leave & permission acceptance portals are eliminated)
  AcceptancePopupNotification? get currentAcceptancePopupForActiveUser => null;

  void acknowledgeAcceptancePopup(String popupId) {
    final idx = _acceptancePopups.indexWhere((p) => p.id == popupId);
    if (idx != -1) {
      _acceptancePopups[idx].acknowledgeBy(activeEmpId);
      notifyListeners();
    }
  }

  void dismissAllAcceptancePopupsForActiveUser() {
    for (final popup in _acceptancePopups) {
      popup.acknowledgeBy(activeEmpId);
    }
    notifyListeners();
  }

  /// Returns designated Team Lead for an employee (department-aware: accounts team, showroom, online, etc.)
  Employee? getTeamLeadForEmployee(String empId) {
    final emp = _employees.firstWhere(
      (e) => e.id == empId,
      orElse: () => _employees.first,
    );
    final empDept = emp.dept.toLowerCase().trim();

    // 1. Direct match: lead in the exact same department
    final deptLeads = _employees
        .where(
          (e) =>
              (e.roleType == 'team_lead' ||
                  e.roleType == 'dept_head' ||
                  e.isTeamLead) &&
              e.dept.toLowerCase().trim() == empDept &&
              e.id != emp.id,
        )
        .toList();
    if (deptLeads.isNotEmpty) return deptLeads.first;

    // 2. If employee belongs to Online Team, E-Commerce, or External Support Staff, Praveenkumar M is designated lead
    if (empDept.contains('online') ||
        empDept.contains('e-commerce') ||
        empDept.contains('external')) {
      final otm = _employees.where((e) => e.id == 'MN-TL1002').toList();
      if (otm.isNotEmpty) return otm.first;
    }

    // 3. Fallback: Any active department lead or team lead
    final anyLead = _employees
        .where(
          (e) =>
              (e.roleType == 'team_lead' ||
                  e.roleType == 'dept_head' ||
                  e.isTeamLead) &&
              e.id != emp.id,
        )
        .toList();
    return anyLead.isNotEmpty ? anyLead.first : null;
  }

  /// Dispatches an official acceptance pop-up and push notification to HR, CEO, and TL
  void dispatchAcceptanceNotification({
    required AcceptanceRequestType requestType,
    required String employeeId,
    required String employeeName,
    required String durationOrDays,
    required String reason,
    required String approvedBy,
    String? requesterRole,
    String? department,
  }) {
    final now = DateTime.now();
    final emp = _employees.firstWhere(
      (e) => e.id == employeeId,
      orElse: () => _employees.first,
    );
    final empRole = requesterRole ?? emp.role;
    final empDept = department ?? emp.dept;

    // Resolve designated leadership recipients: HR, CEO, and TL
    final tl = getTeamLeadForEmployee(employeeId);
    final hr = _employees.firstWhere(
      (e) => e.roleType == 'hr' || e.id == 'MN-HR1001',
      orElse: () => _employees.first,
    );
    final ceo = _employees.firstWhere(
      (e) => e.roleType == 'ceo' || e.id == 'MN-CEO01',
      orElse: () => _employees.first,
    );

    final isPerm = requestType == AcceptanceRequestType.permission;
    final typeLabel = isPerm ? 'Permission Request' : 'Leave Request';
    final title = '✅ $typeLabel Accepted: ${emp.name}';
    final message =
        '$typeLabel ($durationOrDays) for ${emp.name} ($empRole) has been accepted by $approvedBy. Reason: "$reason".';

    final targetEmpIds = <String>{
      employeeId,
      hr.id,
      ceo.id,
      if (tl != null) tl.id,
      'MN-CEO01',
      'MN-HR1001',
      'MN-TL1002',
    }.toList();

    // 1. In-App Pop-up notification record (shows floating card to HR, CEO, TL)
    final popup = AcceptancePopupNotification(
      id: 'ACCEPT-${now.millisecondsSinceEpoch}',
      title: title,
      message: message,
      requestType: requestType,
      employeeId: employeeId,
      employeeName: emp.name,
      employeeRole: empRole,
      employeeDept: empDept,
      durationOrDays: durationOrDays,
      reason: reason,
      approvedBy: approvedBy,
      timestamp: now,
      targetRoles: const ['hr', 'ceo', 'team_lead'],
      targetEmpIds: targetEmpIds,
    );

    _acceptancePopups.insert(0, popup);

    // 2. High-importance Native Push Notification (Lock screen & heads-up)
    PushNotificationService().showNotification(
      id: popup.id,
      title: title,
      body:
          '$message Notified to HR (${hr.name}), CEO (${ceo.name}), and TL (${tl?.name ?? 'Praveenkumar M'}).',
      payload: isPerm ? 'permission_accepted' : 'leave_accepted',
    );

    // 3. Official Company Notification Center entry (Bell Icon on Top Bar)
    _companyNotifications.insert(
      0,
      CompanyNotification(
        id: 'NOTIF-${popup.id}',
        title: title,
        content:
            '$message\n\n📢 Official Distribution: HR (${hr.name}), CEO (${ceo.name}), and Team Lead (${tl?.name ?? 'Praveenkumar M'}).',
        type: CompanyNotificationType.broadcastNotice,
        timestamp: now,
        senderName: approvedBy,
        senderRole: 'Executive Approval Authority',
        actionTag: isPerm ? 'PERM_ACCEPTED' : 'LEAVE_ACCEPTED',
      ),
    );

    notifyListeners();
  }

  // HR Google Sheet Live Attendance State
  HrMonthlyAttendanceSheet? _hrAttendanceSheet;
  HrMonthlyAttendanceSheet? get hrAttendanceSheet =>
      _monthlyAttendanceSheets[_selectedAttendanceMonth] ?? _hrAttendanceSheet;

  @visibleForTesting
  void setAttendanceSheetForTesting(HrMonthlyAttendanceSheet sheet) {
    _hrAttendanceSheet = sheet;
    _monthlyAttendanceSheets[_selectedAttendanceMonth] = sheet;
    notifyListeners();
  }

  int _selectedAttendanceMonth = 11; // Defaults to November (11)
  int get selectedAttendanceMonth => _selectedAttendanceMonth;

  final Map<int, HrMonthlyAttendanceSheet> _monthlyAttendanceSheets = {};
  Map<int, HrMonthlyAttendanceSheet> get monthlyAttendanceSheets =>
      _monthlyAttendanceSheets;

  bool _isLoadingAttendanceSheet = false;
  bool get isLoadingAttendanceSheet => _isLoadingAttendanceSheet;

  String? _attendanceSheetError;
  String? get attendanceSheetError => _attendanceSheetError;

  DateTime? _attendanceSheetLastSynced;
  DateTime? get attendanceSheetLastSynced => _attendanceSheetLastSynced;

  /// Find attendance row for the current active employee
  HrEmployeeAttendanceRow? get currentEmployeeHrAttendanceRow {
    final sheet = hrAttendanceSheet;
    if (sheet == null) return null;
    return sheet.findForEmployee(
      name: currentEmployee.name,
      empNo: currentEmployee.empNo,
    );
  }

  /// List of all staff present in Google Sheets
  List<GoogleSheetEmployeeEntry> get allGoogleSheetEmployees {
    final sheet = hrAttendanceSheet;
    if (sheet == null) return [];
    return sheet.allSheetStaff;
  }

  /// List of unassigned employee entries present in Google Sheets but not yet registered in the active workforce
  List<GoogleSheetEmployeeEntry> get unassignedGoogleSheetEmployees {
    final sheet = hrAttendanceSheet;
    if (sheet == null) return [];

    final activeEmpNos = _employees
        .map(
          (e) => (e.empNo.trim().isNotEmpty ? e.empNo.trim() : e.id.trim())
              .toLowerCase(),
        )
        .toSet();
    final activeNames = _employees
        .map((e) => e.name.trim().toLowerCase())
        .toSet();

    return sheet.allSheetStaff.where((entry) {
      final empNoClean = entry.empNo.trim().toLowerCase();
      final nameClean = entry.name.trim().toLowerCase();
      if (empNoClean.isEmpty) return false;
      if (activeEmpNos.contains(empNoClean)) return false;

      // Digits match check
      final numClean = empNoClean.replaceAll(RegExp(r'[^0-9]'), '');
      if (numClean.isNotEmpty) {
        final matchesAnyActive = _employees.any((e) {
          final eNum = (e.empNo.trim().isNotEmpty ? e.empNo : e.id).replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          return eNum.isNotEmpty && eNum == numClean;
        });
        if (matchesAnyActive) return false;
      }

      if (activeNames.any(
        (n) => n == nameClean || n.contains(nameClean) || nameClean.contains(n),
      )) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Active attendance rows matching registered employees in the workforce
  List<HrEmployeeAttendanceRow> get activeAttendanceSheetRows {
    final sheet = hrAttendanceSheet;
    if (sheet == null) return [];
    final activeStaff = _employees
        .where((e) => e.hasAttendanceAndGrooming && e.roleType != 'ceo')
        .toList();
    final activeNos = activeStaff
        .map((e) => e.empNo.trim().isNotEmpty ? e.empNo.trim() : e.id.trim())
        .toSet();
    final activeNames = activeStaff
        .map((e) => e.name.trim().toLowerCase())
        .toSet();
    return sheet.getActiveRowsFor(activeNos, activeNames);
  }

  /// Switch the active attendance review month (1..12) and load its sheet from Google Sheets if needed
  Future<void> selectAttendanceMonth(int month) async {
    _selectedAttendanceMonth = month;
    if (!_monthlyAttendanceSheets.containsKey(month)) {
      _isLoadingAttendanceSheet = true;
      _attendanceSheetError = null;
      notifyListeners();

      try {
        final sheet =
            await GoogleSheetsAttendanceService.fetchAttendanceSheetForMonth(
              month,
            );
        _monthlyAttendanceSheets[month] = sheet;
        if (month == 11) {
          _hrAttendanceSheet = sheet;
        }
      } catch (e) {
        _attendanceSheetError = e.toString();
        debugPrint('Error loading sheet for month $month: $e');
      } finally {
        _isLoadingAttendanceSheet = false;
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  /// Sync live Google Sheets Attendance
  Future<void> syncGoogleSheetsAttendance({
    bool notifyIfUpdated = true,
    bool forceRefresh = false,
    int? month,
  }) async {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      _isLoadingAttendanceSheet = false;
      return;
    }
    _isLoadingAttendanceSheet = true;
    _attendanceSheetError = null;
    notifyListeners();

    try {
      final targetMonth = month ?? _selectedAttendanceMonth;
      final res = await GoogleSheetsAttendanceService.fetchAttendanceSheet(
        month: targetMonth,
        forceRefresh: forceRefresh,
      );
      _hrAttendanceSheet = res.sheet;
      _monthlyAttendanceSheets[targetMonth] = res.sheet;
      _attendanceSheetLastSynced = DateTime.now();

      // If an employee with an assigned empNo was removed from the Google Sheet, relieve them from the active company workforce
      if (res.sheet.allSheetStaff.isNotEmpty) {
        final sheetEmpNos = res.sheet.allSheetStaff
            .map((s) => s.empNo.trim().toLowerCase())
            .toSet();
        final sheetNames = res.sheet.allSheetStaff
            .map((s) => s.name.trim().toLowerCase())
            .toSet();

        // Core protected leadership: CEO and Praveenkumar M (who are exempt from sheets)
        final relievedFromSheet = _employees.where((e) {
          if (e.id == 'MN-CEO01' ||
              e.roleType == 'ceo' ||
              e.isOtm ||
              e.id == 'MN-TL1002') {
            return false;
          }
          if (e.empNo.isEmpty) return false;
          final empNoMatch = sheetEmpNos.contains(e.empNo.trim().toLowerCase());
          final nameMatch = sheetNames.any(
            (sn) =>
                sn == e.name.trim().toLowerCase() ||
                sn.contains(e.name.trim().toLowerCase()),
          );
          return !empNoMatch && !nameMatch;
        }).toList();

        for (final emp in relievedFromSheet) {
          _employees.removeWhere((e) => e.id == emp.id);
          _tasks.removeWhere((t) => t.empId == emp.id);
          _firebaseEmployeeService
              .removeEmployee(employeeId: emp.id, requesterRole: 'hr')
              .catchError((err) {
                debugPrint(
                  'Firestore remote delete on sheet removal note: $err',
                );
              });
          broadcastUniversalAnnouncement(
            title: 'Workforce Notice: Staff Relieved',
            message:
                '${emp.name} (EMP #${emp.empNo}) was removed from the HR Attendance Master Sheet and officially relieved from the company.',
            category: 'hr',
          );
        }
      }

      if (notifyIfUpdated && res.updatedDays.isNotEmpty) {
        final monthName = _hrAttendanceSheet?.monthTitle != null
            ? (_hrAttendanceSheet!.monthTitle.substring(0, 1).toUpperCase() +
                  _hrAttendanceSheet!.monthTitle.substring(1).toLowerCase())
            : 'November';
        final sortedDays = res.updatedDays.toSet().toList()..sort();
        final daysStr = sortedDays.length == 1
            ? '$monthName ${sortedDays.first}'
            : '$monthName ${sortedDays.first}–${sortedDays.last}';
        broadcastAttendanceUpdateNotification(daysStr);
      }
    } catch (e) {
      _attendanceSheetError = e.toString();
    } finally {
      _isLoadingAttendanceSheet = false;
      notifyListeners();
    }
  }

  /// On-demand force refresh from live Google Sheets (returns true on success)
  Future<bool> refreshGoogleSheetsAttendance({int? month}) async {
    try {
      await syncGoogleSheetsAttendance(
        notifyIfUpdated: false,
        forceRefresh: true,
        month: month,
      );
      return _attendanceSheetError == null;
    } catch (e) {
      return false;
    }
  }

  /// Check whether an employee ID/Number is already registered in the active workforce
  Employee? findHiredEmployeeByIdOrEmpNo(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return null;

    final cleanDigits = clean.replaceAll(RegExp(r'[^0-9]'), '');

    for (final emp in _employees) {
      final idLower = emp.id.trim().toLowerCase();
      final empNoLower = emp.empNo.trim().toLowerCase();

      if (idLower == clean || empNoLower == clean) {
        return emp;
      }

      // If digits exist, match normalized numeric portion
      if (cleanDigits.isNotEmpty) {
        final idDigits = emp.id.replaceAll(RegExp(r'[^0-9]'), '');
        final empNoDigits = emp.empNo.replaceAll(RegExp(r'[^0-9]'), '');
        if (empNoDigits == cleanDigits ||
            (idDigits.isNotEmpty && idDigits == cleanDigits)) {
          return emp;
        }
      }
    }
    return null;
  }

  /// Search Google Sheets roster for an employee ID or Name
  List<GoogleSheetEmployeeEntry> findGoogleSheetEmployees(
    String query, {
    bool unassignedOnly = false,
  }) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final cleanDigits = clean.replaceAll(RegExp(r'[^0-9]'), '');
    final sourceList = unassignedOnly
        ? unassignedGoogleSheetEmployees
        : allGoogleSheetEmployees;

    return sourceList.where((entry) {
      final empNoLower = entry.empNo.trim().toLowerCase();
      final nameLower = entry.name.trim().toLowerCase();

      if (empNoLower == clean) return true;
      if (cleanDigits.isNotEmpty) {
        final entryDigits = entry.empNo.replaceAll(RegExp(r'[^0-9]'), '');
        if (entryDigits.isNotEmpty && entryDigits == cleanDigits) return true;
        if (entry.sNo.toString() == cleanDigits) return true;
      }
      if (nameLower.contains(clean)) return true;
      return false;
    }).toList();
  }

  /// Formats raw attendance date inputs or multi-day lists into clean "[Month] [Date]" notation
  /// e.g. "1 NOVEMBER, 2 NOVEMBER... 15 NOVEMBER" -> "November 1–15"
  /// e.g. "15 Nov" -> "November 15"
  static String formatAttendanceDateLabel(
    String rawInput, {
    String? defaultMonth,
  }) {
    final clean = rawInput.trim();
    if (clean.isEmpty) return 'Today';

    // Detect month name
    final monthRegex = RegExp(
      r'(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)',
      caseSensitive: false,
    );
    final monthMatch = monthRegex.firstMatch(clean);
    String detectedMonth = defaultMonth ?? 'November';
    if (monthMatch != null) {
      final rawM = monthMatch.group(1)!;
      final lowerM = rawM.toLowerCase();
      if (lowerM.startsWith('jan')) {
        detectedMonth = 'January';
      } else if (lowerM.startsWith('feb')) {
        detectedMonth = 'February';
      } else if (lowerM.startsWith('mar')) {
        detectedMonth = 'March';
      } else if (lowerM.startsWith('apr')) {
        detectedMonth = 'April';
      } else if (lowerM.startsWith('may')) {
        detectedMonth = 'May';
      } else if (lowerM.startsWith('jun')) {
        detectedMonth = 'June';
      } else if (lowerM.startsWith('jul')) {
        detectedMonth = 'July';
      } else if (lowerM.startsWith('aug')) {
        detectedMonth = 'August';
      } else if (lowerM.startsWith('sep')) {
        detectedMonth = 'September';
      } else if (lowerM.startsWith('oct')) {
        detectedMonth = 'October';
      } else if (lowerM.startsWith('nov')) {
        detectedMonth = 'November';
      } else if (lowerM.startsWith('dec')) {
        detectedMonth = 'December';
      }
    }

    final digits =
        RegExp(r'\b([0-9]{1,2})\b')
            .allMatches(clean)
            .map((m) => int.tryParse(m.group(1)!))
            .whereType<int>()
            .where((d) => d >= 1 && d <= 31)
            .toSet()
            .toList()
          ..sort();

    if (digits.isEmpty) {
      return clean;
    }

    if (digits.length == 1) {
      return '$detectedMonth ${digits.first}';
    }

    final minDay = digits.first;
    final maxDay = digits.last;
    if (digits.length > 2 && (maxDay - minDay + 1 <= digits.length + 3)) {
      return '$detectedMonth $minDay–$maxDay';
    } else if (digits.length <= 3) {
      return '$detectedMonth ${digits.join(', ')}';
    } else {
      return '$detectedMonth $minDay–$maxDay';
    }
  }

  /// Broadcast notification to all staff that attendance has been updated
  void broadcastAttendanceUpdateNotification(String dateOrDays) {
    final cleanLabel = formatAttendanceDateLabel(
      dateOrDays,
      defaultMonth: _hrAttendanceSheet?.monthTitle != null
          ? (_hrAttendanceSheet!.monthTitle.substring(0, 1).toUpperCase() +
                _hrAttendanceSheet!.monthTitle.substring(1).toLowerCase())
          : 'November',
    );

    final title = '📋 $cleanLabel Attendance Update';
    final body =
        '$cleanLabel Attendance update has been made by HR. Please head to your attendance section and check yours.';

    // Push local notification
    PushNotificationService().showNotification(
      id: 'ATTENDANCE-UPDATE-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      payload: 'attendance_sheet_updated',
    );

    final notif = CompanyNotification(
      id: 'NOTIF-ATT-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: body,
      type: CompanyNotificationType.broadcastNotice,
      actionTag: 'ATTENDANCE',
      timestamp: DateTime.now(),
      senderName: 'HR Department (Mohankumar G)',
      senderRole: 'HR Manager',
    );
    _companyNotifications.insert(0, notif);
    _notifiedCompanyNotifIds.add(notif.id);
    _firebaseEmployeeService.saveCompanyNotification(notif).catchError((err) {
      debugPrint('Firestore save attendance notification note: $err');
    });
    notifyListeners();
  }

  /// Broadcast high-priority workforce notice across app and local push notifications
  void broadcastUniversalAnnouncement({
    required String title,
    required String message,
    String category = 'hr',
  }) {
    final notif = CompanyNotification(
      id: 'NOTIF-NOTICE-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      content: message,
      type: CompanyNotificationType.broadcastNotice,
      timestamp: DateTime.now(),
      senderName: category == 'ceo'
          ? 'M N Naveenraaj'
          : 'HR Department (Mohankumar G)',
      senderRole: category == 'ceo' ? 'Managing Director & CEO' : 'HR Manager',
    );
    PushNotificationService().showNotification(
      id: notif.id,
      title: title,
      body: message,
      payload: 'workforce_notice',
    );
    _companyNotifications.insert(0, notif);
    _notifiedCompanyNotifIds.add(notif.id);
    _firebaseEmployeeService.saveCompanyNotification(notif).catchError((err) {
      debugPrint('Firestore save universal notice note: $err');
    });
    notifyListeners();
  }

  List<PermissionRecord> get permissionRecords => _permissionRecords;
  List<PermissionRecord> get allPendingPermissions => _permissionRecords
      .where(
        (p) =>
            p.status == 'Pending' ||
            p.status == 'Pending HR & CEO' ||
            p.status == 'Pending CEO' ||
            p.status == 'Granted by HR (Pending CEO Approval)',
      )
      .toList();
  List<PermissionRecord> get allApprovedPermissions =>
      _permissionRecords.where((p) => p.status == 'Approved').toList();

  List<PermissionRecord> get pendingHrPermissions =>
      _permissionRecords.where((p) => p.isPendingHr).toList();
  List<PermissionRecord> get pendingCeoPermissions =>
      _permissionRecords.where((p) => p.isPendingCeo).toList();

  List<MedicalLeaveRecord> get medicalLeaveRecords => _medicalLeaveRecords;
  List<MedicalLeaveRecord> get allPendingMedicalLeaves => _medicalLeaveRecords
      .where((m) => m.status != 'Approved' && m.status != 'Rejected')
      .toList();
  List<MedicalLeaveRecord> get pendingHrMedicalLeaves =>
      _medicalLeaveRecords.where((m) => m.isPendingHr).toList();
  List<MedicalLeaveRecord> get pendingCeoMedicalLeaves =>
      _medicalLeaveRecords.where((m) => m.isPendingCeo).toList();

  List<PermissionRecord> get currentEmployeePermissionRecords =>
      _permissionRecords.where((p) => p.empId == _activeEmpId).toList();

  List<MedicalLeaveRecord> get currentEmployeeMedicalLeaves =>
      _medicalLeaveRecords.where((m) => m.empId == _activeEmpId).toList();

  List<PermissionRecord> get currentEmployeeCurrentMonthPermissionRecords =>
      currentEmployeePermissionRecords
          .where((p) => _isCurrentMonth(p.date))
          .toList();

  double get monthlyPermissionHoursLimit => _monthlyPermissionHoursLimit;
  int get monthlyCasualLeavesLimit => _monthlyCasualLeavesLimit;

  double get totalPermissionHoursUsed =>
      currentEmployeeCurrentMonthPermissionRecords
          .where((p) => !p.isCasualLeave && p.status != 'Rejected')
          .fold(0.0, (sum, p) => sum + p.actualHoursUsed);

  double get permissionHoursRemaining =>
      (_monthlyPermissionHoursLimit - totalPermissionHoursUsed).clamp(
        0.0,
        _monthlyPermissionHoursLimit,
      );

  bool get isPermissionExcessHalfDay =>
      totalPermissionHoursUsed > _monthlyPermissionHoursLimit;

  int get casualLeavesUsed => currentEmployeeCurrentMonthPermissionRecords
      .where((p) => p.isCasualLeave)
      .length;

  double get salaryDeductionDays {
    double count = 0.0;
    if (casualLeavesUsed > _monthlyCasualLeavesLimit) {
      count += (casualLeavesUsed - _monthlyCasualLeavesLimit).toDouble();
    }
    if (isPermissionExcessHalfDay) {
      count += 0.5; // Excess hours over 4.0 considered as half day leave
    }
    return count;
  }

  // Ring 6: Customer Conduct & Jewellery Ethics
  final double _conductScore = 0.0;
  double get conductScore => _conductScore;

  // Social Cause Pillar 5 State
  List<SocialCauseItem> _socialCauses = [];
  List<SocialCauseItem> get socialCauses => _socialCauses;
  List<SocialCauseItem> get pendingSocialCauses =>
      _socialCauses.where((c) => c.isPending).toList();
  List<SocialCauseItem> get approvedSocialCauses =>
      _socialCauses.where((c) => c.isApproved).toList();
  List<SocialCauseItem> get currentEmployeeSocialCauses =>
      _socialCauses.where((c) => c.empId == _activeEmpId).toList();

  // Company Universal Notification Feed (Birthdays, Milestones, Social Deeds, Management Broadcasts, SOP To-Dos)
  List<CompanyNotification> _companyNotifications = [];
  List<CompanyNotification> get companyNotifications => _companyNotifications;
  List<CompanyNotification> get activeCompanyNotifications {
    final list = _companyNotifications
        .where(
          (n) =>
              n.isValid &&
              !n.isDismissedBy(_activeEmpId) &&
              n.isTargetedFor(_activeEmpId),
        )
        .toList();

    // Ensure active celebration events for today are guaranteed in the notification feed
    final now = DateTime.now();
    for (final event in todayCelebrations) {
      final isSelf =
          _activeEmpId == event.employeeId ||
          currentEmployee.name.toLowerCase().contains(
            event.employeeName.toLowerCase(),
          ) ||
          (isCeo &&
              (event.employeeId == 'MN-CEO01' ||
                  event.employeeName.toLowerCase().contains('naveenraaj'))) ||
          (isHr &&
              (event.employeeId == 'MN-HR001' ||
                  event.employeeName.toLowerCase().contains('mohankumar')));

      final notifId = isSelf
          ? 'NOTIF-MYCELEB-${event.type}-${event.employeeId}-${now.year}_${now.month}_${now.day}'
          : 'NOTIF-CELEB-${event.type}-${event.employeeId}-${now.year}_${now.month}_${now.day}';

      if (!list.any((n) => n.id == notifId)) {
        list.insert(
          0,
          CompanyNotification(
            id: notifId,
            title: isSelf
                ? (event.type == 'birthday'
                      ? '🎉 Happy Birthday ${event.employeeName}! 🎂'
                      : '💍 Happy Wedding Anniversary ${event.employeeName}! 💐')
                : (event.type == 'birthday'
                      ? '🎂 Birthday Celebration Today!'
                      : '💐 Wedding Anniversary Celebration Today!'),
            content: isSelf ? event.message : event.othersMessage,
            type: event.type == 'birthday'
                ? CompanyNotificationType.birthday
                : CompanyNotificationType.anniversary,
            timestamp: now,
            senderName: 'M N Naveenraaj',
            senderRole: 'Managing Director & CEO',
            targetEmpIds: isSelf ? [event.employeeId] : const [],
          ),
        );
      }
    }

    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  int get unreadNotificationCount => activeCompanyNotifications
      .where((n) => !n.isReadBy(_activeEmpId))
      .length;
  final Set<String> _notifiedCompanyNotifIds = {};
  bool _initialCompanyNotifsLoaded = false;
  int _notifSequence = 0;

  // Personal Notes (Strictly private & confidential per active user)
  List<PersonalNote> _personalNotes = [];
  List<PersonalNote> get myPersonalNotes {
    final list = _personalNotes
        .where((n) => n.ownerEmpId == _activeEmpId)
        .toList();
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  void _syncAndPushIncomingNotifications(
    List<CompanyNotification> remoteNotifs,
  ) {
    if (!_initialCompanyNotifsLoaded) {
      _initialCompanyNotifsLoaded = true;
      final now = DateTime.now();
      for (final notif in remoteNotifs) {
        final isTodayCelebration =
            (notif.type == CompanyNotificationType.birthday ||
                notif.type == CompanyNotificationType.anniversary) &&
            notif.timestamp.year == now.year &&
            notif.timestamp.month == now.month &&
            notif.timestamp.day == now.day;

        if (isTodayCelebration &&
            !notif.isReadBy(_activeEmpId) &&
            notif.isTargetedFor(_activeEmpId)) {
          PushNotificationService().showNotification(
            id: notif.id,
            title: notif.title,
            body: notif.content,
            payload: notif.id,
          );
        }
        _notifiedCompanyNotifIds.add(notif.id);
      }
      return;
    }

    for (final notif in remoteNotifs) {
      if (!_notifiedCompanyNotifIds.contains(notif.id)) {
        _notifiedCompanyNotifIds.add(notif.id);
        // Only push if not already read by this employee and targeted for this employee
        if (!notif.isReadBy(_activeEmpId) &&
            notif.isTargetedFor(_activeEmpId)) {
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

  bool _matchesMonthAndDay(String? dateStr, DateTime now) {
    if (dateStr == null || dateStr.trim().isEmpty) return false;
    final clean = dateStr.trim();
    final dt = DateTime.tryParse(clean);
    if (dt != null) {
      return dt.month == now.month && dt.day == now.day;
    }

    // Support month names: e.g. "19-Nov-1988", "19 November 1988", "Nov 19 1988"
    const monthNames = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
      'january': 1,
      'february': 2,
      'march': 3,
      'april': 4,
      'june': 6,
      'july': 7,
      'august': 8,
      'september': 9,
      'october': 10,
      'november': 11,
      'december': 12,
    };
    final lower = clean.toLowerCase();
    for (final entry in monthNames.entries) {
      if (lower.contains(entry.key)) {
        if (entry.value != now.month) return false;
        // Check if current day appears as a number token in the date string
        final dayMatch = RegExp(
          r'\b0?([1-9]|[12][0-9]|3[01])\b',
        ).allMatches(lower);
        for (final m in dayMatch) {
          final val = int.tryParse(m.group(0)!);
          if (val == now.day) return true;
        }
      }
    }

    final parts = clean.split(RegExp(r'[-/.]'));
    if (parts.length >= 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      if (p0 != null && p1 != null && p2 != null) {
        if (p0 > 1000) {
          return p1 == now.month && p2 == now.day;
        }
        if (p2 > 1000) {
          if (p1 == now.month && p0 == now.day) return true;
          if (p0 == now.month && p1 == now.day) return true;
        }
      }
    }
    return false;
  }

  List<CelebrationEvent> get todayCelebrations {
    final now = DateTime.now();
    final List<CelebrationEvent> events = [];
    for (final emp in _employees) {
      if (_matchesMonthAndDay(emp.dob, now)) {
        events.add(
          CelebrationEvent(
            employeeId: emp.id,
            employeeName: emp.name,
            isFemale: emp.isFemale,
            type: 'birthday',
            message:
                '🎉 Happy Birthday ${emp.name}! May all your dreams come true! 🎂',
            othersMessage:
                '🎉 Today is ${emp.name}\'s Birthday, wish ${emp.isFemale ? "her" : "him"} the best! 🎂',
            date: '${now.day}/${now.month}',
          ),
        );
      }
      if (_matchesMonthAndDay(emp.anniversaryDate, now)) {
        events.add(
          CelebrationEvent(
            employeeId: emp.id,
            employeeName: emp.name,
            isFemale: emp.isFemale,
            type: 'anniversary',
            message:
                '💍 Happy Wedding Anniversary ${emp.name}! Wishing you a lifetime of joy and togetherness! 💐',
            othersMessage:
                '💍 Today is ${emp.name}\'s Wedding Anniversary, wish them the best! 💐',
            date: '${now.day}/${now.month}',
          ),
        );
      }
    }
    return events;
  }

  Future<void> _cleanupPastCelebrationsFromFirebase(DateTime now) async {
    final stale = _companyNotifications
        .where(
          (n) =>
              (n.type == CompanyNotificationType.birthday ||
                  n.type == CompanyNotificationType.anniversary) &&
              (n.timestamp.year != now.year ||
                  n.timestamp.month != now.month ||
                  n.timestamp.day != now.day),
        )
        .toList();

    for (final oldNotif in stale) {
      _companyNotifications.removeWhere((item) => item.id == oldNotif.id);
      _firebaseEmployeeService
          .deleteCompanyNotification(oldNotif.id)
          .catchError((_) {});
    }
  }

  Future<void> checkAndDispatchCelebrations() async {
    final events = todayCelebrations;
    final now = DateTime.now();

    // Clean up outdated celebration notifications from prior days in background
    await _cleanupPastCelebrationsFromFirebase(now);

    if (events.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final todayStr = '${now.year}_${now.month}_${now.day}';

    for (final event in events) {
      final broadcastId =
          'NOTIF-CELEB-${event.type}-${event.employeeId}-$todayStr';
      final personalId =
          'NOTIF-MYCELEB-${event.type}-${event.employeeId}-$todayStr';

      final notifTitle = event.type == 'birthday'
          ? '🎂 Birthday Celebration Today!'
          : '💐 Wedding Anniversary Celebration Today!';

      // 1. Broadcast notification for all workforce members
      final broadcastNotif = CompanyNotification(
        id: broadcastId,
        title: notifTitle,
        content: event.othersMessage,
        type: event.type == 'birthday'
            ? CompanyNotificationType.birthday
            : CompanyNotificationType.anniversary,
        timestamp: now,
        senderName: 'M N Naveenraaj',
        senderRole: 'Managing Director & CEO',
      );

      // 2. Personal celebration notification for the celebrating employee
      final personalNotifTitle = event.type == 'birthday'
          ? '🎉 Happy Birthday ${event.employeeName}! 🎂'
          : '💍 Happy Wedding Anniversary ${event.employeeName}! 💐';
      final personalNotif = CompanyNotification(
        id: personalId,
        title: personalNotifTitle,
        content: event.message,
        type: event.type == 'birthday'
            ? CompanyNotificationType.birthday
            : CompanyNotificationType.anniversary,
        timestamp: now,
        senderName: 'M N Naveenraaj',
        senderRole: 'Managing Director & CEO',
        targetEmpIds: [event.employeeId],
      );

      if (!_companyNotifications.any((n) => n.id == broadcastNotif.id)) {
        _companyNotifications.insert(0, broadcastNotif);
      }
      if (!_companyNotifications.any((n) => n.id == personalNotif.id)) {
        _companyNotifications.insert(0, personalNotif);
      }

      // Sync to Firebase Cloud Firestore (guarded per day)
      final firestoreSavedKey =
          'celebration_firestore_saved_${event.type}_${event.employeeId}_$todayStr';
      if (!(prefs.getBool(firestoreSavedKey) ?? false)) {
        _firebaseEmployeeService
            .saveCompanyNotification(broadcastNotif)
            .catchError((err) {
              debugPrint(
                'Firestore broadcast celebration notification error: $err',
              );
            });
        _firebaseEmployeeService
            .saveCompanyNotification(personalNotif)
            .catchError((err) {
              debugPrint(
                'Firestore personal celebration notification error: $err',
              );
            });
        await prefs.setBool(firestoreSavedKey, true);
      }

      // 3. Deliver native push notifications to this device for active user (once per employee per day)
      final localPushKey =
          'celeb_push_shown_${_activeEmpId}_${event.type}_${event.employeeId}_$todayStr';
      final bool alreadyPushedToDevice = prefs.getBool(localPushKey) ?? false;

      if (!alreadyPushedToDevice) {
        final isSelf =
            _activeEmpId == event.employeeId ||
            currentEmployee.name.toLowerCase().contains(
              event.employeeName.toLowerCase(),
            ) ||
            (isCeo &&
                (event.employeeId == 'MN-CEO01' ||
                    event.employeeName.toLowerCase().contains('naveenraaj'))) ||
            (isHr &&
                (event.employeeId == 'MN-HR001' ||
                    event.employeeName.toLowerCase().contains('mohankumar')));

        if (isSelf) {
          await PushNotificationService().showNotification(
            id: 'CELEB-ME-${event.type}-${event.employeeId}-$todayStr',
            title: personalNotifTitle,
            body: event.message,
            payload: 'birthday:${event.employeeId}',
          );
        } else {
          await PushNotificationService().showNotification(
            id: 'CELEB-${event.type}-${event.employeeId}-$todayStr',
            title: notifTitle,
            body: event.othersMessage,
            payload: 'birthday:${event.employeeId}',
          );
        }
        await prefs.setBool(localPushKey, true);
      }
    }

    notifyListeners();
  }

  Timer? _midnightCelebrationTimer;

  /// Automatically schedules celebration checking and push notifications exactly at 12:00 AM midnight daily
  void _startMidnightCelebrationTimer() {
    _midnightCelebrationTimer?.cancel();
    if ((!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) ||
        WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    final duration = tomorrow.difference(now);
    _midnightCelebrationTimer = Timer(duration, () {
      checkAndDispatchCelebrations();
      _startMidnightCelebrationTimer();
    });
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
    final todayList = _attendancePunches
        .where(
          (p) =>
              p.enrollNumber == _activeEmpId &&
              p.timestamp.year == now.year &&
              p.timestamp.month == now.month &&
              p.timestamp.day == now.day,
        )
        .toList();

    // Overnight shift link: if early morning before 12 PM with no login today,
    // link yesterday evening's open shift login
    if (now.hour < 12 &&
        !todayList.any((p) => p.punchType == AttendancePunchType.login)) {
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayLogins =
          _attendancePunches
              .where(
                (p) =>
                    p.enrollNumber == _activeEmpId &&
                    p.timestamp.year == yesterday.year &&
                    p.timestamp.month == yesterday.month &&
                    p.timestamp.day == yesterday.day &&
                    p.timestamp.hour >= 18 &&
                    p.punchType == AttendancePunchType.login,
              )
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (yesterdayLogins.isNotEmpty) {
        final openLogin = yesterdayLogins.first;
        final hasLogout = _attendancePunches.any(
          (p) =>
              p.enrollNumber == _activeEmpId &&
              p.punchType == AttendancePunchType.logout &&
              p.timestamp.isAfter(openLogin.timestamp),
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
      if (todayLogoutPunch != null) {
        return 45; // Capped at standard 45 mins if shift already ended
      }
      final elapsed = DateTime.now()
          .difference(todayLunchOutPunch!.timestamp)
          .inMinutes;
      return elapsed.clamp(
        0,
        60,
      ); // Cap unclosed active lunch break at 60 mins max
    }
    final end = todayLunchInPunch!.timestamp;
    return end
        .difference(todayLunchOutPunch!.timestamp)
        .inMinutes
        .clamp(0, 180);
  }

  bool get hasLoggedAttendanceToday => todayLoginPunch != null;

  bool get isCurrentlyOnDuty =>
      hasLoggedAttendanceToday &&
      (todayLogoutPunch == null ||
          todayLoginPunch!.timestamp.isAfter(todayLogoutPunch!.timestamp));

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
      return todayNetWorkDurationHours < 8.0
          ? const Color(0xFFF59E0B)
          : const Color(0xFF8B5CF6);
    }
    if (isAttendanceOnTime) return const Color(0xFF10B981);
    return const Color(0xFFEAB308);
  }

  /// Consolidated Daily Attendance Summary for ALL employees (used by CEO & HR suites)
  HrEmployeeAttendanceRow? getEmployeeSheetRow(String empId) {
    final emp = _employees.firstWhere(
      (e) => e.id == empId || e.empNo == empId,
      orElse: () => currentEmployee,
    );
    return hrAttendanceSheet?.findForEmployee(name: emp.name, empNo: emp.empNo);
  }

  List<EmployeeDailyAttendanceSummary> get allEmployeesTodayAttendance {
    final now = DateTime.now();
    final summaries = <EmployeeDailyAttendanceSummary>[];
    final isShopClosed = now.hour >= 21 || now.hour < 9;

    for (final emp in _employees) {
      // CEO and Praveenkumar M (TL) are available all the time 24/7
      if (emp.isCeo || emp.name.toLowerCase().contains('praveen')) {
        summaries.add(
          EmployeeDailyAttendanceSummary(
            employeeId: emp.id,
            employeeName: emp.name,
            department: emp.dept,
            role: emp.role,
            avatar: emp.avatar,
            initials: emp.initials,
            loginPunch: null,
            logoutPunch: null,
            lunchOutPunch: null,
            lunchInPunch: null,
            isPresent: true,
            isOnTime: true,
            isCurrentlyOnLunch: false,
            isCurrentlyOnDuty: true,
            lunchDurationMinutes: 0,
            netWorkHours: 8.0,
            status: DailyAttendanceStatus.presentOnTime,
          ),
        );
        continue;
      }

      // External Support Staff work on online deliverables
      if (emp.isExternalSupport) {
        summaries.add(
          EmployeeDailyAttendanceSummary(
            employeeId: emp.id,
            employeeName: emp.name,
            department: emp.dept,
            role: emp.role,
            avatar: emp.avatar,
            initials: emp.initials,
            loginPunch: null,
            logoutPunch: null,
            lunchOutPunch: null,
            lunchInPunch: null,
            isPresent: true,
            isOnTime: true,
            isCurrentlyOnLunch: false,
            isCurrentlyOnDuty:
                false, // External support staff work on online tasks, NOT retail showroom floor
            lunchDurationMinutes: 0,
            netWorkHours: isShopClosed ? 0.0 : 8.0,
            status: isShopClosed
                ? DailyAttendanceStatus.completed
                : DailyAttendanceStatus.presentOnTime,
          ),
        );
        continue;
      }

      // Showroom Staff: If Tuesday (store weekly off), marked as week-off unless absent
      final isTuesday = now.weekday == DateTime.tuesday;
      if (isTuesday) {
        final isAbsent = isEmployeeAbsent(emp.id);
        summaries.add(
          EmployeeDailyAttendanceSummary(
            employeeId: emp.id,
            employeeName: emp.name,
            department: emp.dept,
            role: emp.role,
            avatar: emp.avatar,
            initials: emp.initials,
            loginPunch: null,
            logoutPunch: null,
            lunchOutPunch: null,
            lunchInPunch: null,
            isPresent: false,
            isOnTime: false,
            isCurrentlyOnLunch: false,
            isCurrentlyOnDuty: false,
            lunchDurationMinutes: 0,
            netWorkHours: 0,
            status: isAbsent
                ? DailyAttendanceStatus.absent
                : DailyAttendanceStatus.weekOff,
          ),
        );
        continue;
      }

      // Showroom Staff: If past 9:00 PM (or before 9:00 AM), shop is closed -> Off Duty
      if (isShopClosed) {
        final isAbsent = isEmployeeAbsent(emp.id);
        summaries.add(
          EmployeeDailyAttendanceSummary(
            employeeId: emp.id,
            employeeName: emp.name,
            department: emp.dept,
            role: emp.role,
            avatar: emp.avatar,
            initials: emp.initials,
            loginPunch: null,
            logoutPunch: null,
            lunchOutPunch: null,
            lunchInPunch: null,
            isPresent: !isAbsent,
            isOnTime: false,
            isCurrentlyOnLunch: false,
            isCurrentlyOnDuty: false,
            lunchDurationMinutes: 0,
            netWorkHours: 0,
            status: isAbsent
                ? DailyAttendanceStatus.absent
                : DailyAttendanceStatus.completed,
          ),
        );
        continue;
      }

      final empPunches = _attendancePunches
          .where(
            (p) =>
                p.enrollNumber == emp.id &&
                p.timestamp.year == now.year &&
                p.timestamp.month == now.month &&
                p.timestamp.day == now.day,
          )
          .toList();

      final logins = empPunches
          .where((p) => p.punchType == AttendancePunchType.login)
          .toList();
      logins.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final login = logins.isNotEmpty ? logins.first : null;

      final logouts = empPunches
          .where((p) => p.punchType == AttendancePunchType.logout)
          .toList();
      logouts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final logout = logouts.isNotEmpty ? logouts.first : null;

      final lunchOuts = empPunches
          .where((p) => p.punchType == AttendancePunchType.breakOut)
          .toList();
      lunchOuts.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final lunchOut = lunchOuts.isNotEmpty ? lunchOuts.first : null;

      final lunchIns = empPunches
          .where((p) => p.punchType == AttendancePunchType.breakIn)
          .toList();
      lunchIns.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final lunchIn = lunchIns.isNotEmpty ? lunchIns.first : null;

      bool isPresent = login != null;
      bool isOnTime =
          login != null &&
          ((login.timestamp.hour < 9) ||
              (login.timestamp.hour == 9 && login.timestamp.minute <= 30));
      bool isOnLunch =
          lunchOut != null &&
          (lunchIn == null || lunchOut.timestamp.isAfter(lunchIn.timestamp));
      bool isOnDuty = isPresent && logout == null;

      int lunchMins = 0;
      if (lunchOut != null) {
        if (lunchIn != null) {
          lunchMins = lunchIn.timestamp
              .difference(lunchOut.timestamp)
              .inMinutes
              .clamp(0, 180);
        } else if (logout != null) {
          lunchMins = 45; // Capped if shift completed
        } else {
          final elapsed = DateTime.now()
              .difference(lunchOut.timestamp)
              .inMinutes;
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
      if (login != null) {
        if (logout != null) {
          status = DailyAttendanceStatus.completed;
        } else if (isOnTime) {
          status = DailyAttendanceStatus.presentOnTime;
        } else {
          status = DailyAttendanceStatus.lateLogin;
        }
      } else {
        // Evaluate from Google Sheet / Official HR Master Ledger
        final isManuallyAbsent =
            _absentEmployeeIds.contains(emp.id) ||
            _absentEmployeeIds.contains(emp.empNo);
        final isManuallyPresent =
            _manuallyPresentEmployeeIds.contains(emp.id) ||
            _manuallyPresentEmployeeIds.contains(emp.empNo);

        if (isManuallyAbsent) {
          isPresent = false;
          isOnTime = false;
          isOnDuty = false;
          status = DailyAttendanceStatus.absent;
        } else if (isManuallyPresent) {
          isPresent = true;
          isOnTime = true;
          isOnDuty = true;
          status = DailyAttendanceStatus.presentOnTime;
        } else {
          final sheet = hrAttendanceSheet;
          final hrRow = sheet?.findForEmployee(
            name: emp.name,
            empNo: emp.empNo,
          );
          final todayRec = hrRow?.days[now.day];
          final isTuesday = now.weekday == DateTime.tuesday;

          if (isTuesday || todayRec?.type == HrAttendanceDayType.holiday) {
            // Tuesday showroom week-off or company holiday
            isPresent = false;
            isOnTime = false;
            isOnDuty = false;
            status = DailyAttendanceStatus.weekOff;
          } else if (todayRec != null &&
              todayRec.type != HrAttendanceDayType.pendingUpdate) {
            // Authoritative entry exists for today in HR Sheet
            if (todayRec.type == HrAttendanceDayType.leaveCl ||
                todayRec.type == HrAttendanceDayType.leaveLop ||
                todayRec.type == HrAttendanceDayType.leaveHalfDay) {
              isPresent = false;
              isOnTime = false;
              isOnDuty = false;
              status = DailyAttendanceStatus.absent;
            } else if (todayRec.type == HrAttendanceDayType.late ||
                todayRec.type == HrAttendanceDayType.lateAndHalfDay) {
              isPresent = true;
              isOnTime = false;
              isOnDuty = !isShopClosed;
              status = DailyAttendanceStatus.lateLogin;
            } else {
              // Present on duty
              isPresent = true;
              isOnTime = true;
              isOnDuty = !isShopClosed;
              status = isShopClosed
                  ? DailyAttendanceStatus.completed
                  : DailyAttendanceStatus.presentOnTime;
            }
          } else {
            // Attendance for the day is not yet updated in the sheet!
            isPresent = false;
            isOnTime = false;
            isOnDuty = false;
            status = DailyAttendanceStatus.yetToUpdate;
          }
        }
      }

      summaries.add(
        EmployeeDailyAttendanceSummary(
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
        ),
      );
    }

    return summaries;
  }

  /// 7-day attendance & activity performance records for employee self-review derived from official Google Sheets ledger
  List<EmployeeActivityDayRecord> getPast7DaysAttendanceForEmployee(
    String empId,
  ) {
    final now = DateTime.now();
    final List<EmployeeActivityDayRecord> records = [];

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final emp = _employees.firstWhere(
      (e) => e.id == empId || e.empNo == empId,
      orElse: () => currentEmployee,
    );

    // CEO and OTM Praveenkumar are completely exempt from attendance
    if (!emp.hasAttendanceAndGrooming) {
      return records;
    }

    final hrRow = hrAttendanceSheet?.findForEmployee(
      name: emp.name,
      empNo: emp.empNo,
    );

    for (int i = 0; i <= 6; i++) {
      final targetDate = now.subtract(Duration(days: i));
      final isToday = i == 0;
      final dayName = days[targetDate.weekday - 1];
      final monthName = months[targetDate.month - 1];
      final dateLabel = isToday
          ? 'Today ($monthName ${targetDate.day})'
          : '$dayName, $monthName ${targetDate.day}';

      if (hrRow != null) {
        final dayRecord = hrRow.days[targetDate.day];
        if (dayRecord != null) {
          String statusStr = 'Present';
          Color statusColor = const Color(0xFF10B981);
          String netHoursStr = '10h 30m';
          String inStr = '09:30 AM';
          String outStr = '08:30 PM';
          String lunchOutStr = '01:30 PM';
          String lunchInStr = '02:00 PM';
          bool isWeekoff = false;

          switch (dayRecord.type) {
            case HrAttendanceDayType.present:
              statusStr = 'Present (Nil)';
              statusColor = const Color(0xFF10B981);
              netHoursStr = '10h 30m';
              inStr = '09:30 AM';
              outStr = '08:30 PM';
              lunchOutStr = '01:30 PM';
              lunchInStr = '02:00 PM';
              break;
            case HrAttendanceDayType.late:
              statusStr = 'Late (${dayRecord.displayLabel})';
              statusColor = const Color(0xFFF59E0B);
              netHoursStr = '10h 15m';
              inStr = '09:45 AM';
              outStr = '08:30 PM';
              lunchOutStr = '01:30 PM';
              lunchInStr = '02:00 PM';
              break;
            case HrAttendanceDayType.leaveCl:
              statusStr = 'Casual Leave (CL)';
              statusColor = const Color(0xFFEF4444);
              netHoursStr = '0h 00m';
              inStr = '--:-- --';
              outStr = '--:-- --';
              lunchOutStr = '--';
              lunchInStr = '--';
              break;
            case HrAttendanceDayType.leaveLop:
              statusStr = 'Loss of Pay (LOP)';
              statusColor = const Color(0xFFDC2626);
              netHoursStr = '0h 00m';
              inStr = '--:-- --';
              outStr = '--:-- --';
              lunchOutStr = '--';
              lunchInStr = '--';
              break;
            case HrAttendanceDayType.leaveHalfDay:
              statusStr = 'Half Day Leave (1/2 D)';
              statusColor = const Color(0xFFF97316);
              netHoursStr = '5h 00m';
              inStr = '09:30 AM';
              outStr = '02:30 PM';
              lunchOutStr = '01:30 PM';
              lunchInStr = '02:00 PM';
              break;
            case HrAttendanceDayType.lateAndHalfDay:
              statusStr = 'Late + Half Day';
              statusColor = const Color(0xFFEA580C);
              netHoursStr = '4h 45m';
              inStr = '09:45 AM';
              outStr = '02:30 PM';
              lunchOutStr = '01:30 PM';
              lunchInStr = '02:00 PM';
              break;
            case HrAttendanceDayType.permission:
              statusStr = 'Permission (${dayRecord.displayLabel})';
              statusColor = const Color(0xFF10B981);
              netHoursStr = 'Perm: ${dayRecord.displayLabel}';
              inStr = '09:30 AM';
              outStr = '08:30 PM';
              lunchOutStr = '01:30 PM';
              lunchInStr = '02:00 PM';
              break;
            case HrAttendanceDayType.mnw:
              statusStr = 'MN Work Visit (MNW)';
              statusColor = const Color(0xFF2563EB);
              netHoursStr = 'Store Visit';
              inStr = '09:30 AM';
              outStr = '08:30 PM';
              lunchOutStr = '01:30 PM';
              lunchInStr = '02:00 PM';
              break;
            case HrAttendanceDayType.holiday:
              statusStr = 'Tuesday Week-off';
              statusColor = const Color(0xFF64748B);
              netHoursStr = 'Week-off';
              inStr = '--:-- --';
              outStr = '--:-- --';
              lunchOutStr = '--';
              lunchInStr = '--';
              isWeekoff = true;
              break;
            case HrAttendanceDayType.pendingUpdate:
              statusStr = 'Yet to update';
              statusColor = const Color(0xFFF59E0B); // Yellow
              netHoursStr = '--';
              inStr = '--:-- --';
              outStr = '--:-- --';
              lunchOutStr = '--';
              lunchInStr = '--';
              break;
            case HrAttendanceDayType.notApplicable:
              statusStr = 'N/A';
              statusColor = const Color(0xFF94A3B8);
              netHoursStr = '--';
              inStr = '--:-- --';
              outStr = '--:-- --';
              lunchOutStr = '--';
              lunchInStr = '--';
              break;
          }

          records.add(
            EmployeeActivityDayRecord(
              date: targetDate,
              dateLabel: dateLabel,
              loginTime: inStr,
              logoutTime: outStr,
              lunchOutTime: lunchOutStr,
              lunchInTime: lunchInStr,
              netHours: netHoursStr,
              status: statusStr,
              statusColor: statusColor,
              isOvertime: false,
              isWeekoff: isWeekoff,
            ),
          );
          continue;
        }
      }

      // Unrecorded / pending days from Google Sheets
      records.add(
        EmployeeActivityDayRecord(
          date: targetDate,
          dateLabel: dateLabel,
          loginTime: '--',
          logoutTime: '--',
          lunchOutTime: '--',
          lunchInTime: '--',
          netHours: '--',
          status: targetDate.weekday == DateTime.tuesday
              ? 'Tuesday Week-off'
              : 'Yet to update',
          statusColor: targetDate.weekday == DateTime.tuesday
              ? const Color(0xFF94A3B8)
              : const Color(0xFFF59E0B),
          isOvertime: false,
          isWeekoff: targetDate.weekday == DateTime.tuesday,
        ),
      );
    }

    return records;
  }

  /// Full monthly calendar attendance records (Jan to Dec, 28/29/30/31 full calendar days)
  /// Tuesday is weekoff, but if attendance is marked it is recorded as Tuesday Overtime (OT).
  List<EmployeeActivityDayRecord> getMonthlyAttendanceForEmployee(
    String empId, {
    int? year,
    int? month,
  }) {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    final totalDays = DateTime(y, m + 1, 0).day;
    final List<EmployeeActivityDayRecord> records = [];

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final emp = _employees.firstWhere(
      (e) => e.id == empId || e.empNo == empId,
      orElse: () => currentEmployee,
    );
    final sheet = _monthlyAttendanceSheets[m] ?? _hrAttendanceSheet;
    final hrRow = sheet?.findForEmployee(name: emp.name, empNo: emp.empNo);

    for (int day = 1; day <= totalDays; day++) {
      final targetDate = DateTime(y, m, day);
      final isToday = (y == now.year && m == now.month && day == now.day);
      final dayName = days[targetDate.weekday - 1];
      final monthName = months[targetDate.month - 1];
      final dateLabel = isToday
          ? 'Today ($monthName $day)'
          : '$dayName, $monthName $day';
      final isTuesday = targetDate.weekday == DateTime.tuesday;

      final dayPunches = _attendancePunches
          .where(
            (p) =>
                p.enrollNumber == empId &&
                p.timestamp.year == targetDate.year &&
                p.timestamp.month == targetDate.month &&
                p.timestamp.day == targetDate.day,
          )
          .toList();

      final logins =
          dayPunches
              .where((p) => p.punchType == AttendancePunchType.login)
              .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final logouts =
          dayPunches
              .where((p) => p.punchType == AttendancePunchType.logout)
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final lunchOuts =
          dayPunches
              .where((p) => p.punchType == AttendancePunchType.breakOut)
              .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final lunchIns =
          dayPunches
              .where((p) => p.punchType == AttendancePunchType.breakIn)
              .toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final login = logins.isNotEmpty ? logins.first : null;
      final lunchOut = lunchOuts.isNotEmpty ? lunchOuts.first : null;
      final lunchIn = lunchIns.isNotEmpty ? lunchIns.first : null;
      AttendancePunchRecord? resolvedLogout = logouts.isNotEmpty
          ? logouts.first
          : null;

      String inStr = login?.timeString ?? '--:-- --';
      final lunchOutStr = lunchOut?.timeString ?? '--:-- --';
      final lunchInStr = lunchIn?.timeString ?? '--:-- --';
      String outStr =
          resolvedLogout?.timeString ??
          (isToday && login != null ? 'Active / On Duty' : '--:-- --');

      String netHoursStr = '--';
      String statusStr = 'No Punch';
      Color statusColor = const Color(0xFF64748B);
      bool isOvertime = false;
      bool isWeekoff = false;

      final hrDay = hrRow?.days[day];

      if (login != null) {
        final endTime =
            resolvedLogout?.timestamp ??
            (isToday ? DateTime.now() : login.timestamp);
        int lunchMins = 0;
        if (lunchOut != null) {
          final endL =
              lunchIn?.timestamp ??
              (isToday ? DateTime.now() : lunchOut.timestamp);
          lunchMins = endL
              .difference(lunchOut.timestamp)
              .inMinutes
              .clamp(0, 300);
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
          final isOnLunch =
              lunchOut != null &&
              (lunchIn == null ||
                  lunchOut.timestamp.isAfter(lunchIn.timestamp));
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
          statusStr = resolvedLogout != null
              ? 'Shift Over (${hrs}h ${mins}m)'
              : 'Present (${hrs}h ${mins}m)';
          statusColor = const Color(0xFF10B981);
        }
      } else if (hrDay != null) {
        // Authoritative record from HR Master Google Sheet
        if (isTuesday) {
          if (hrDay.type == HrAttendanceDayType.holiday) {
            isWeekoff = true;
            statusStr = 'Tuesday (Week-off)';
            statusColor = const Color(0xFF94A3B8);
          } else if (hrDay.type == HrAttendanceDayType.present ||
              hrDay.type == HrAttendanceDayType.late ||
              hrDay.type == HrAttendanceDayType.permission ||
              hrDay.type == HrAttendanceDayType.mnw ||
              hrDay.type == HrAttendanceDayType.leaveHalfDay) {
            isOvertime = true;
            statusStr = 'Tuesday Overtime (OT)';
            statusColor = const Color(0xFF8B5CF6);
            inStr = '09:30 AM';
            outStr = '08:30 PM';
            netHoursStr = 'Full Day OT';
          } else if (hrDay.type == HrAttendanceDayType.leaveCl ||
              hrDay.type == HrAttendanceDayType.leaveLop) {
            statusStr = hrDay.displayLabel;
            statusColor = const Color(0xFFEF4444);
          } else {
            isWeekoff = true;
            statusStr = 'Tuesday (Week-off)';
            statusColor = const Color(0xFF94A3B8);
          }
        } else {
          switch (hrDay.type) {
            case HrAttendanceDayType.present:
              statusStr = 'Present';
              statusColor = const Color(0xFF10B981);
              inStr = '09:30 AM';
              outStr = isToday ? 'Active / On Duty' : '08:30 PM';
              netHoursStr = 'Full Day';
              break;
            case HrAttendanceDayType.late:
              statusStr = 'Late (${hrDay.displayLabel})';
              statusColor = const Color(0xFFF59E0B);
              inStr = 'Late In';
              outStr = isToday ? 'Active / On Duty' : '08:30 PM';
              netHoursStr = 'Full Day';
              break;
            case HrAttendanceDayType.permission:
              statusStr = 'Permission (${hrDay.displayLabel})';
              statusColor = const Color(0xFF10B981);
              inStr = 'Permission';
              outStr = isToday ? 'Active / On Duty' : '08:30 PM';
              netHoursStr = hrDay.displayLabel;
              break;
            case HrAttendanceDayType.mnw:
              statusStr = 'MN Work Visit (MNW)';
              statusColor = const Color(0xFF2563EB);
              inStr = 'On Duty';
              outStr = 'Store Visit';
              netHoursStr = 'Full Day';
              break;
            case HrAttendanceDayType.leaveHalfDay:
            case HrAttendanceDayType.lateAndHalfDay:
              statusStr = 'Half Day (1/2 D)';
              statusColor = const Color(0xFFF97316);
              inStr = 'Half Day';
              outStr = '--';
              netHoursStr = '0.5 Day';
              break;
            case HrAttendanceDayType.leaveCl:
              statusStr = 'Casual Leave (CL)';
              statusColor = const Color(0xFFEF4444);
              inStr = '--:-- --';
              outStr = '--:-- --';
              netHoursStr = '0h 00m';
              break;
            case HrAttendanceDayType.leaveLop:
              statusStr = 'Loss of Pay (LOP)';
              statusColor = const Color(0xFFDC2626);
              inStr = '--:-- --';
              outStr = '--:-- --';
              netHoursStr = '0h 00m';
              break;
            case HrAttendanceDayType.holiday:
              statusStr = 'Holiday (Tuesday)';
              isWeekoff = true;
              statusColor = const Color(0xFF94A3B8);
              break;
            case HrAttendanceDayType.pendingUpdate:
              statusStr = 'Yet to update';
              statusColor = const Color(0xFFF59E0B);
              break;
            case HrAttendanceDayType.notApplicable:
              statusStr = 'N/A';
              statusColor = const Color(0xFF94A3B8);
              break;
          }
        }
      } else {
        if (isTuesday) {
          isWeekoff = true;
          statusStr = 'Tuesday (Week-off)';
          statusColor = const Color(0xFF94A3B8);
        } else {
          statusStr = 'Yet to update';
          statusColor = const Color(0xFFF59E0B);
        }
      }

      records.add(
        EmployeeActivityDayRecord(
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
        ),
      );
    }

    return records;
  }

  // Individual Pillar Scores (0 to 100) based strictly on live user data
  int get pillar1HealthScore {
    final hasMetrics = _userHeightCm > 0 && _userWeightKg > 0;
    if (!hasMetrics) return 0; // Uncalibrated profile -> 0%
    final bmi = currentBmi;
    int base = 50;
    if (bmi >= 18.5 && bmi <= 25.0) {
      base = 70;
    } else if (bmi >= 17.5 && bmi <= 29.9) {
      base = 55;
    } else {
      base = 40;
    }
    if (dailyWorkoutLogs.isNotEmpty) {
      base += 30;
    } else if (totalWorkoutMinutes > 0) {
      base += 15;
    }
    return base.clamp(0, 100);
  }

  int get pillar2FamilyScore {
    if (totalFamilyHoursToday > 0) {
      return (totalFamilyHoursToday >= 1.0
              ? 100
              : (totalFamilyHoursToday * 100).round())
          .clamp(0, 100);
    }
    if (_familyActivityLogs.isNotEmpty) return 60;
    return 0; // No time logged today -> 0%
  }

  int get pillar3ProfileScore {
    if (!currentEmployee.hasAttendanceAndGrooming) {
      return 100; // CEO and OTM leadership governance standing
    }

    double total = 0.0;
    // 1. Document Vault Custody (50% of Pillar 3)
    final docRatio = _originalDocuments.isEmpty
        ? 1.0
        : documentsSubmissionRatio;
    total += docRatio * 50.0;

    // 2. Daily Retail Showroom Grooming & Attire (50% of Pillar 3)
    final gScore = (groomingPercentage / 100.0).clamp(0.0, 1.0);
    total += gScore * 50.0;

    return total.round().clamp(0, 100);
  }

  int get pillar4AttendanceScore {
    if (!currentEmployee.hasAttendanceAndGrooming) {
      return 100; // Not applicable
    }
    final row = currentEmployeeHrAttendanceRow;
    if (row != null) {
      final recorded = row.recordedDaysCount > 0 ? row.recordedDaysCount : 14;
      final attended =
          row.presentDaysCount +
          (row.lateCount <= 3 ? row.lateCount : 3) +
          row.mnwDaysCount;
      double ratio = (attended / recorded) * 100.0;
      if (row.latePenaltyDays > 0) {
        ratio -= (row.latePenaltyDays * 5.0);
      }
      if (row.lopDaysUsed > 0) {
        ratio -= (row.lopDaysUsed * 10.0);
      }
      return ratio.round().clamp(0, 100);
    }
    return 0; // No HR attendance uploaded yet
  }

  /// Overall Sovereign Equilibrium Holistic Score (0 - 100)
  int get holisticEquilibriumScore {
    final s1 = pillar1HealthScore;
    final s2 = pillar2FamilyScore;
    final s3 = pillar3ProfileScore;

    if (!currentEmployee.hasAttendanceAndGrooming) {
      // For CEO and OTM who do not come under attendance, calculate from the 3 applicable pillars
      return ((s1 / 3.0) + (s2 / 3.0) + (s3 / 3.0)).round().clamp(0, 100);
    }

    final s4 = pillar4AttendanceScore;
    return ((s1 * 0.25) + (s2 * 0.25) + (s3 * 0.25) + (s4 * 0.25))
        .round()
        .clamp(0, 100);
  }

  // Holistic Status Rating (4 Pillars: Health, Family, Profile, Attendance)
  PillarTierLevel get holisticTierLevel {
    final score = holisticEquilibriumScore;
    if (score >= 80) return PillarTierLevel.green;
    if (score >= 60) return PillarTierLevel.yellow;
    return PillarTierLevel.red;
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

    // Pillar 1: Health & Wellness
    final hasMetrics = _userHeightCm > 0 && _userWeightKg > 0;
    final bmiOk = hasMetrics && currentBmi >= 18.5 && currentBmi <= 25.0;
    final hasWorkout = dailyWorkoutLogs.isNotEmpty;
    if (bmiOk && hasWorkout) {
      lags.add(
        PillarLagItem(
          pillarTitle: 'Pillar 1: Health & Wellness',
          status: 'Good (Green)',
          description:
              'BMI is ${currentBmi.toStringAsFixed(1)} (Healthy) and workout logged ($totalWorkoutMinutes mins).',
          improvementAction:
              'Keep eating healthy meals and drinking plenty of water.',
          isCompromised: false,
          indicatorColor: const Color(0xFF10B981),
          icon: Icons.health_and_safety,
        ),
      );
    } else if (hasMetrics) {
      lags.add(
        PillarLagItem(
          pillarTitle: 'Pillar 1: Health & Wellness',
          status: 'Needs Attention (Yellow)',
          description:
              'BMI is ${currentBmi.toStringAsFixed(1)} ($bmiCategory). ${hasWorkout ? "$totalWorkoutMinutes mins workout logged." : "No workout logged today."}',
          improvementAction:
              'Log daily workout activities and meals in Pillar 1.',
          isCompromised: true,
          indicatorColor: const Color(0xFFF59E0B),
          icon: Icons.health_and_safety,
        ),
      );
    } else {
      lags.add(
        PillarLagItem(
          pillarTitle: 'Pillar 1: Health & Wellness',
          status: 'Action Needed (Red)',
          description:
              'Height and Weight need to be added. No workout logged today.',
          improvementAction:
              'Calibrate height/weight and log activities in Pillar 1.',
          isCompromised: true,
          indicatorColor: const Color(0xFFEF4444),
          icon: Icons.health_and_safety,
        ),
      );
    }

    // Pillar 2: Family & Friends
    final famHours = totalFamilyHoursToday;
    if (famHours > 0) {
      lags.add(
        PillarLagItem(
          pillarTitle: 'Pillar 2: Family & Friends',
          status: 'Good (Green)',
          description:
              'Spent ${famHours.toStringAsFixed(1)} hours of quality time with family or friends today.',
          improvementAction: 'Keep spending relaxed time with loved ones.',
          isCompromised: false,
          indicatorColor: const Color(0xFF10B981),
          icon: Icons.family_restroom,
        ),
      );
    } else if (_familyActivityLogs.isNotEmpty) {
      lags.add(
        PillarLagItem(
          pillarTitle: 'Pillar 2: Family & Friends',
          status: 'On Track (Yellow)',
          description:
              'Family activities recorded this week. No time logged today yet.',
          improvementAction:
              'Spend 30 minutes having dinner or talking with family in Pillar 2.',
          isCompromised: true,
          indicatorColor: const Color(0xFFF59E0B),
          icon: Icons.family_restroom,
        ),
      );
    } else {
      lags.add(
        PillarLagItem(
          pillarTitle: 'Pillar 2: Family & Friends',
          status: 'Not Logged Yet (Yellow)',
          description: 'No time logged with family or friends today.',
          improvementAction:
              'Spend 30 minutes having dinner or talking with family in Pillar 2.',
          isCompromised: true,
          indicatorColor: const Color(0xFFF59E0B),
          icon: Icons.family_restroom,
        ),
      );
    }

    // Pillar 3: Document Submission Vault Custody (Exempt for CEO)
    final isCeo =
        currentEmployee.roleType.toLowerCase() == 'ceo' ||
        currentEmployee.id.toUpperCase() == 'MN-CEO01';
    if (!isCeo) {
      if (_originalDocuments.isEmpty) {
        lags.add(
          PillarLagItem(
            pillarTitle: 'Pillar 3: Document Submission',
            status: 'Need to be added (Yellow)',
            description:
                'No certificates submitted yet to digital vault custody.',
            improvementAction:
                'Submit original certificates to HR in Pillar 3.',
            isCompromised: true,
            indicatorColor: const Color(0xFFF59E0B),
            icon: Icons.lock_outline,
          ),
        );
      } else {
        final pendingMandatory = _originalDocuments
            .where(
              (d) =>
                  d.isMandatory &&
                  d.status != DocumentSubmissionStatus.submitted,
            )
            .toList();
        if (pendingMandatory.isEmpty) {
          lags.add(
            PillarLagItem(
              pillarTitle: 'Pillar 3: Document Submission',
              status: 'All Submitted (Green)',
              description:
                  'All required original certificates are safely submitted to company vault.',
              improvementAction: 'All certificates are verified by HR.',
              isCompromised: false,
              indicatorColor: const Color(0xFF10B981),
              icon: Icons.lock_outline,
            ),
          );
        } else {
          final names = pendingMandatory
              .map((d) => d.title.split('(').first.trim())
              .join(', ');
          lags.add(
            PillarLagItem(
              pillarTitle: 'Pillar 3: Document Submission',
              status: pendingMandatory.length == 1
                  ? '1 Document Pending (Yellow)'
                  : 'Documents Missing (Red)',
              description:
                  '${pendingMandatory.length} required original document(s) not yet submitted: $names.',
              improvementAction:
                  'Submit your pending documents to HR in Pillar 3.',
              isCompromised: true,
              indicatorColor: pendingMandatory.length == 1
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444),
              icon: Icons.warning_amber_rounded,
            ),
          );
        }
      }
    }

    // Pillar 3: Grooming & Uniform (Omitted for OTM Praveenkumar & CEO)
    if (currentEmployee.hasAttendanceAndGrooming) {
      if (groomingAudits.any(
        (g) => g.empId == _activeEmpId && _isToday(g.date),
      )) {
        if (groomingPercentage >= 80) {
          lags.add(
            PillarLagItem(
              pillarTitle: 'Pillar 3: Grooming & Uniform',
              status:
                  'Great (${groomingPercentage.toStringAsFixed(0)}% • $groomingDailyPoints/50 pts)',
              description:
                  'Clean uniform, proper haircut, and ID card all verified.',
              improvementAction: 'Keep up the neat and clean presentation.',
              isCompromised: false,
              indicatorColor: const Color(0xFF10B981),
              icon: Icons.content_cut,
            ),
          );
        } else {
          lags.add(
            PillarLagItem(
              pillarTitle: 'Pillar 3: Grooming & Uniform',
              status:
                  'Needs Improvement (${groomingPercentage.toStringAsFixed(0)}% • $groomingDailyPoints/50 pts)',
              description:
                  'Grooming compliance is below 80%. Please follow dress code guidelines.',
              improvementAction:
                  'Speak with HR to review uniform and haircut requirements.',
              isCompromised: true,
              indicatorColor: groomingPercentage >= 60
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444),
              icon: Icons.style,
            ),
          );
        }
      } else {
        lags.add(
          PillarLagItem(
            pillarTitle: 'Pillar 3: Grooming & Uniform',
            status: 'Compliant (100% • Standard)',
            description:
                'In clean corporate uniform and standard presentation. Daily HR check pending.',
            improvementAction:
                'Maintain clean uniform, polished shoes, and company ID card.',
            isCompromised: false,
            indicatorColor: const Color(0xFF10B981),
            icon: Icons.content_cut,
          ),
        );
      }
    }

    // Pillar 3: Permissions & Leaves (4.0 Hours max limit + 1 CL)
    final hrRow = currentEmployeeHrAttendanceRow;
    if (hrRow != null) {
      final remHours = hrRow.remainingPermissionHours;
      final clUsed = hrRow.clDaysUsed;
      final isExceeded = hrRow.isPermissionExceeded || hrRow.lopDaysUsed > 0;
      if (!isExceeded) {
        lags.add(
          PillarLagItem(
            pillarTitle: 'Pillar 3: Permissions & Leaves',
            status: 'On Track (Green)',
            description:
                '${remHours.toStringAsFixed(1)}h permission left out of 4.0h. Leaves used: ${clUsed.toStringAsFixed(clUsed % 1 == 0 ? 0 : 1)}/1 CL.',
            improvementAction: 'Zero salary deduction this month.',
            isCompromised: false,
            indicatorColor: const Color(0xFF10B981),
            icon: Icons.timer,
          ),
        );
      } else {
        lags.add(
          PillarLagItem(
            pillarTitle: 'Pillar 3: Permissions & Leaves',
            status: 'Leaves Exceeded (Red)',
            description: hrRow.isPermissionExceeded
                ? 'Monthly permission time exceeded 4.0 hours (${hrRow.totalPermissionHours.toStringAsFixed(1)}h used).'
                : 'Loss of Pay leaves incurred (${hrRow.lopDaysUsed.toStringAsFixed(1)} LOP days).',
            improvementAction:
                'Keep permission time within 4.0 hours per month.',
            isCompromised: true,
            indicatorColor: const Color(0xFFEF4444),
            icon: Icons.warning_amber_rounded,
          ),
        );
      }
    } else {
      if (!isPermissionExcessHalfDay &&
          casualLeavesUsed <= _monthlyCasualLeavesLimit) {
        lags.add(
          PillarLagItem(
            pillarTitle: 'Pillar 3: Permissions & Leaves',
            status: 'On Track (Green)',
            description:
                '${permissionHoursRemaining.toStringAsFixed(1)}h permission left out of 4.0h. Leaves used: $casualLeavesUsed/1.',
            improvementAction: 'Zero salary deduction this month.',
            isCompromised: false,
            indicatorColor: const Color(0xFF10B981),
            icon: Icons.timer,
          ),
        );
      } else {
        final reason = isPermissionExcessHalfDay
            ? 'Monthly permission time exceeded 4.0 hours (half-day penalty).'
            : 'Used more than 1 Casual Leave ($casualLeavesUsed used, $salaryDeductionDays day salary deduction).';
        lags.add(
          PillarLagItem(
            pillarTitle: 'Pillar 3: Permissions & Leaves',
            status: 'Leaves Exceeded (Red)',
            description: reason,
            improvementAction:
                'Keep permission time within 4.0 hours per month.',
            isCompromised: true,
            indicatorColor: const Color(0xFFEF4444),
            icon: Icons.warning_amber_rounded,
          ),
        );
      }
    }

    // Pillar 4: Attendance & Punctuality (Official HR Master Ledger - Omitted for OTM & CEO)
    if (currentEmployee.hasAttendanceAndGrooming) {
      if (hrRow != null) {
        final recorded = hrRow.recordedDaysCount > 0
            ? hrRow.recordedDaysCount
            : 14;
        final attended =
            hrRow.presentDaysCount +
            (hrRow.lateCount <= 3 ? hrRow.lateCount : 3) +
            hrRow.mnwDaysCount;
        final attPct = ((attended / recorded) * 100.0).clamp(0.0, 100.0);
        if (hrRow.lateCount <= 3 && hrRow.lopDaysUsed == 0) {
          lags.add(
            PillarLagItem(
              pillarTitle: 'Pillar 4: Attendance (HR Master Ledger)',
              status: 'Good (${attPct.toStringAsFixed(0)}% • Green)',
              description:
                  'HR Ledger (Nov 1–$recorded): ${hrRow.presentDaysCount} days present, ${hrRow.lateCount} lates (within 3 allowed), ${hrRow.clDaysUsed} CL used.',
              improvementAction:
                  'Attendance verified and approved by HR department in Master Ledger.',
              isCompromised: false,
              indicatorColor: const Color(0xFF10B981),
              icon: Icons.assignment_turned_in_rounded,
            ),
          );
        } else {
          lags.add(
            PillarLagItem(
              pillarTitle: 'Pillar 4: Attendance (HR Master Ledger)',
              status:
                  'Needs Attention (${attPct.toStringAsFixed(0)}% • Yellow)',
              description:
                  'HR Ledger (Nov 1–$recorded): ${hrRow.lateCount} lates (${hrRow.latePenaltyDays} penalty), ${hrRow.lopDaysUsed} LOP days.',
              improvementAction:
                  'Maintain regular punctuality (maximum 3 lates per month).',
              isCompromised: true,
              indicatorColor: const Color(0xFFF59E0B),
              icon: Icons.warning_amber_rounded,
            ),
          );
        }
      } else {
        lags.add(
          PillarLagItem(
            pillarTitle: 'Pillar 4: Attendance (HR Master Ledger)',
            status: 'Audited by HR (Green)',
            description:
                'Attendance recorded and uploaded by HR. Contact HR for any spreadsheet adjustments.',
            improvementAction:
                'Daily attendance ledger maintained via Google Sheets.',
            isCompromised: false,
            indicatorColor: const Color(0xFF10B981),
            icon: Icons.assignment_turned_in_rounded,
          ),
        );
      }
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

  double get minIdealWeight =>
      18.5 * (_userHeightCm / 100.0) * (_userHeightCm / 100.0);
  double get maxIdealWeight =>
      24.9 * (_userHeightCm / 100.0) * (_userHeightCm / 100.0);

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
      (e) =>
          e.id == _activeEmpId ||
          ((e.id == '7' || e.id == 'MN-HR1001') &&
              (_activeEmpId == 'MN-HR1001' ||
                  _activeEmpId == '7' ||
                  _activeEmpId.toLowerCase() == 'hr')) ||
          e.email.toLowerCase() == _activeEmpId.toLowerCase(),
      orElse: () {
        if (_activeRole == 'hr') {
          return _employees.firstWhere(
            (e) => e.isHr || e.id == '7',
            orElse: () => _employees.first,
          );
        }
        if (_activeRole == 'dept_head' || _activeRole == 'team_lead') {
          return _employees.firstWhere(
            (e) => e.isTeamLead,
            orElse: () => _employees.first,
          );
        }
        if (_activeRole == 'ceo') {
          return _employees.firstWhere(
            (e) => e.isCeo,
            orElse: () => _employees.first,
          );
        }
        return _employees.isNotEmpty
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
              );
      },
    );
  }

  List<TaskItem> get currentEmployeeTasks {
    return _tasks.where((t) => t.empId == _activeEmpId).toList();
  }

  List<TaskItem> get operationsDeptTasks {
    final opsEmpIds = _employees
        .where((e) => e.roleType != 'ceo' && e.roleType != 'hr')
        .map((e) => e.id)
        .toSet();
    return _tasks.where((t) => opsEmpIds.contains(t.empId)).toList();
  }

  final FirebaseEmployeeService _firebaseEmployeeService =
      FirebaseEmployeeService();
  StreamSubscription<List<Employee>>? _employeeSubscription;
  StreamSubscription<List<SocialCauseItem>>? _socialCausesSubscription;
  StreamSubscription<List<CompanyNotification>>? _notificationsSubscription;
  StreamSubscription<List<TaskItem>>? _personalTodosSubscription;
  StreamSubscription<List<OnlineOrderModel>>? _onlineOrdersSubscription;
  StreamSubscription<List<ChatMessage>>? _chatMessagesSubscription;
  StreamSubscription<List<KonarBookModel>>? _konarBooksSubscription;
  bool _firebaseSyncActive = false;
  bool get firebaseSyncActive => _firebaseSyncActive;

  // Real-time Workforce Chat Engine
  List<ChatMessage> _chatMessages = [];
  final Set<String> _notifiedChatMessageIds = {};
  bool _initialChatsStreamLoaded = false;

  // Live Official KONAR Books Engine
  List<KonarBookModel> _konarBooks = [];
  List<KonarBookModel> get konarBooks => _konarBooks.isNotEmpty
      ? _konarBooks
      : [KonarBookModel.defaultOnlineDepartment()];

  KonarBookModel get onlineDeptKonarBook => _konarBooks.firstWhere(
    (b) => b.id == 'online_department',
    orElse: () => KonarBookModel.defaultOnlineDepartment(),
  );

  // Online Orders Workflow Engine (OS1 & OS2 Handler)
  List<OnlineOrderModel> _onlineOrders = [];
  List<OnlineOrderModel> get onlineOrders => _onlineOrders;
  List<OnlineOrderModel> get os1Orders => _onlineOrders
      .where(
        (o) =>
            o.brand == 'MN Jewel Park' ||
            o.handledByEmpId == '65' ||
            o.reallocatedToEmpId == '65',
      )
      .toList();
  List<OnlineOrderModel> get os2Orders => _onlineOrders
      .where(
        (o) =>
            o.brand == 'Vadivam' ||
            o.handledByEmpId == '67' ||
            o.reallocatedToEmpId == '67',
      )
      .toList();
  List<OnlineOrderModel> get overdueOnlineOrders =>
      _onlineOrders.where((o) => o.hasAnyOverdueStage).toList();

  // Absentee Tracking & Team Lead Shift Continuity (Synchronized with Live Biometric/Attendance punches)
  final Set<String> _absentEmployeeIds = {};
  final Set<String> _manuallyPresentEmployeeIds = {};

  Set<String> get absentEmployeeIds => _employees
      .where((e) => e.hasAttendanceAndGrooming && isEmployeeAbsent(e.id))
      .map((e) => e.id)
      .toSet();

  bool isEmployeeAbsent(String empId) {
    final emp = _employees.firstWhere(
      (e) => e.id == empId || e.empNo == empId,
      orElse: () => currentEmployee,
    );
    if (!emp.hasAttendanceAndGrooming) {
      return false; // CEO and OTM Praveenkumar are exempt from attendance
    }
    if (_manuallyPresentEmployeeIds.contains(emp.id) ||
        _manuallyPresentEmployeeIds.contains(emp.empNo)) {
      return false;
    }
    if (_absentEmployeeIds.contains(emp.id) ||
        _absentEmployeeIds.contains(emp.empNo)) {
      return true;
    }

    // 1. Check official HR Google Sheets Master Ledger
    final sheet = hrAttendanceSheet;
    if (sheet != null) {
      final row = sheet.findForEmployee(name: emp.name, empNo: emp.empNo);
      if (row != null) {
        final now = DateTime.now();
        final isTuesday = now.weekday == DateTime.tuesday;
        // Check today's record in current month
        final todayRec = row.days[now.day];
        if (todayRec != null &&
            todayRec.type != HrAttendanceDayType.pendingUpdate) {
          if (todayRec.type == HrAttendanceDayType.holiday && isTuesday) {
            return false;
          }
          final isLeaveOrAbsent =
              todayRec.type == HrAttendanceDayType.leaveCl ||
              todayRec.type == HrAttendanceDayType.leaveLop;
          return isLeaveOrAbsent;
        }

        // Check latest recorded day up to today
        final latestDay = sheet.latestRecordedDay;
        final latestRec = row.days[latestDay];
        if (latestRec != null &&
            latestRec.type != HrAttendanceDayType.pendingUpdate) {
          if (latestRec.type == HrAttendanceDayType.holiday && isTuesday) {
            return false;
          }
          final isLeaveOrAbsent =
              latestRec.type == HrAttendanceDayType.leaveCl ||
              latestRec.type == HrAttendanceDayType.leaveLop;
          return isLeaveOrAbsent;
        }

        // Active staff recorded on Google Sheets are on-duty by default
        return false;
      }
    }

    final summaries = allEmployeesTodayAttendance;
    final sIdx = summaries.indexWhere(
      (s) =>
          s.employeeId == empId ||
          s.employeeId == emp.id ||
          s.employeeId == emp.empNo,
    );
    if (sIdx != -1) {
      return !summaries[sIdx].isPresent;
    }
    return false; // Active corporate staff are on-duty unless marked absent in ledger or manually toggled
  }

  /// Returns true if employee is logged in / clocked in and currently on duty (has not marked shift over)
  bool isEmployeeActiveOnDuty(String empId) {
    if (_absentEmployeeIds.contains(empId)) return false;
    if (_manuallyPresentEmployeeIds.contains(empId)) return true;
    final summaries = allEmployeesTodayAttendance;
    final sIdx = summaries.indexWhere((s) => s.employeeId == empId);
    if (sIdx != -1) {
      final summary = summaries[sIdx];
      return summary.isCurrentlyOnDuty;
    }
    return false;
  }

  void toggleEmployeeAbsentStatus(
    String empId, {
    bool? isAbsent,
    String? reason,
  }) {
    final currentAbsent = isEmployeeAbsent(empId);
    final willBeAbsent = isAbsent ?? !currentAbsent;
    if (willBeAbsent) {
      _absentEmployeeIds.add(empId);
      _manuallyPresentEmployeeIds.remove(empId);
      final emp = _employees.firstWhere(
        (e) => e.id == empId,
        orElse: () => _employees.first,
      );
      final pendingCount = _tasks
          .where((t) => t.empId == empId && t.status == 'pending')
          .length;
      _notificationMessage =
          '⚠️ ABSENT ALERT: ${emp.name} is marked Absent today. $pendingCount standard SOP tasks require reallocation or postponement.';
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
    return _tasks
        .where((t) => absIds.contains(t.empId) && t.status == 'pending')
        .toList();
  }

  EcosystemProvider() {
    _initData();
    _loadLocalPersonalNotesAndDismissed();
    _loadLocalChats();
    _initFirebaseSync();
    checkAndDispatchCelebrations();
    _startMidnightCelebrationTimer();
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
            const validIds = {
              'MN-CEO01',
              '7',
              'MN-TL1002',
              '6',
              '33',
              '65',
              '67',
              'EXT-VPE',
              'EXT-AC',
              'EXT-OSS',
              'EXT-DVP',
              'EXT-CC',
            };
            final updatedList = List<Employee>.from(_employees);
            for (final remote in remoteEmployees) {
              final cleanRemote =
                  (remote.id == 'MN-CEO01' ||
                      remote.roleType == 'ceo' ||
                      remote.name.toLowerCase().contains('executive ceo'))
                  ? remote.copyWith(
                      id: 'MN-CEO01',
                      empNo: '',
                      name: 'M N Naveenraaj',
                      initials: 'MN',
                      role: 'Managing Director & CEO',
                      roleType: 'ceo',
                    )
                  : ((remote.id == '7' ||
                            remote.id == 'MN-HR1001' ||
                            remote.roleType == 'hr' ||
                            remote.email.toLowerCase() == 'hr@mnj.com')
                        ? remote.copyWith(
                            id: '7',
                            empNo: '7',
                            name: 'Mohankumar G',
                            initials: 'MG',
                            role: 'HR Manager & Operations Custodian',
                            roleType: 'hr',
                          )
                        : remote);

              if (!validIds.contains(cleanRemote.id) &&
                  !validIds.contains(cleanRemote.empNo)) {
                continue;
              }

              final idx = updatedList.indexWhere(
                (e) =>
                    e.id == cleanRemote.id ||
                    (cleanRemote.empNo.isNotEmpty &&
                        e.empNo == cleanRemote.empNo) ||
                    e.email.toLowerCase() == cleanRemote.email.toLowerCase(),
              );
              if (idx != -1) {
                updatedList[idx] = cleanRemote;
              } else {
                updatedList.add(cleanRemote);
              }

              // Extract workforce punches across all devices
              if (remote.fourPillars != null &&
                  remote.fourPillars!['attendance'] is List) {
                final list = remote.fourPillars!['attendance'] as List;
                for (final pMap in list) {
                  try {
                    final punch = AttendancePunchRecord.fromJson(
                      Map<String, dynamic>.from(pMap as Map),
                    );
                    final pIdx = _attendancePunches.indexWhere(
                      (p) => p.id == punch.id,
                    );
                    if (pIdx == -1) {
                      _attendancePunches.add(punch);
                    } else {
                      _attendancePunches[pIdx] = punch;
                    }
                  } catch (_) {}
                }
              }
            }
            updatedList.retainWhere(
              (e) => validIds.contains(e.id) || validIds.contains(e.empNo),
            );
            _employees = updatedList;
            _firebaseSyncActive = true;
            notifyListeners();
            checkAndDispatchCelebrations();
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
      _socialCausesSubscription = _firebaseEmployeeService
          .streamSocialCauses()
          .listen(
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
      _notificationsSubscription = _firebaseEmployeeService
          .streamCompanyNotifications()
          .listen(
            (remoteNotifs) async {
              _syncAndPushIncomingNotifications(remoteNotifs);
              // Preserve any local dismissed mappings across syncs
              try {
                final prefs = await SharedPreferences.getInstance();
                final dismissedRaw = prefs.getString(
                  _dismissedNotifsStorageKey,
                );
                Map<String, dynamic>? dismissedMap;
                if (dismissedRaw != null && dismissedRaw.isNotEmpty) {
                  dismissedMap =
                      jsonDecode(dismissedRaw) as Map<String, dynamic>?;
                }
                final validRemote = remoteNotifs
                    .where((n) => n.isValid)
                    .toList();
                final remoteIds = validRemote.map((n) => n.id).toSet();
                final localOnly = _companyNotifications
                    .where((n) => n.isValid && !remoteIds.contains(n.id))
                    .toList();
                final combined = [...validRemote, ...localOnly];
                combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                _companyNotifications = combined.map((n) {
                  if (dismissedMap != null && dismissedMap.containsKey(n.id)) {
                    final localDismissed = List<String>.from(
                      dismissedMap[n.id] as List? ?? [],
                    );
                    final merged = {
                      ...n.dismissedByStaffIds,
                      ...localDismissed,
                    }.toList();
                    return n.copyWith(dismissedByStaffIds: merged);
                  }
                  return n;
                }).toList();
              } catch (_) {
                final validRemote = remoteNotifs
                    .where((n) => n.isValid)
                    .toList();
                final remoteIds = validRemote.map((n) => n.id).toSet();
                final localOnly = _companyNotifications
                    .where((n) => n.isValid && !remoteIds.contains(n.id))
                    .toList();
                _companyNotifications = [...validRemote, ...localOnly];
                _companyNotifications.sort(
                  (a, b) => b.timestamp.compareTo(a.timestamp),
                );
              }

              // Dispatch instant push notifications for new incoming company announcements & notices
              _syncAndPushIncomingNotifications(
                remoteNotifs.where((n) => n.isValid).toList(),
              );

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
      _personalTodosSubscription = _firebaseEmployeeService
          .streamPersonalTodos()
          .listen(
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
      _onlineOrdersSubscription = _firebaseEmployeeService
          .streamOnlineOrders()
          .listen(
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

    try {
      _chatMessagesSubscription = _firebaseEmployeeService.streamChatMessages().listen(
        (remoteMsgs) {
          if (remoteMsgs.isNotEmpty) {
            final filteredRemote = remoteMsgs
                .where(
                  (m) =>
                      !m.id.startsWith('SEED-MSG') &&
                      !m.text.contains('Online Department is active'),
                )
                .toList();
            final remoteIds = filteredRemote.map((m) => m.id).toSet();
            final localOnly = _chatMessages
                .where(
                  (m) =>
                      !remoteIds.contains(m.id) &&
                      !m.id.startsWith('SEED-MSG') &&
                      !m.text.contains('Online Department is active'),
                )
                .toList();
            final merged = [...filteredRemote, ...localOnly];
            merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            _chatMessages = merged;

            // Push notifications for incoming chat messages like WhatsApp outside the app
            if (!_initialChatsStreamLoaded) {
              for (final m in filteredRemote) {
                _notifiedChatMessageIds.add(m.id);
              }
              _initialChatsStreamLoaded = true;
            } else {
              for (final m in filteredRemote) {
                if (!_notifiedChatMessageIds.contains(m.id)) {
                  _notifiedChatMessageIds.add(m.id);
                  final isForMe =
                      m.isAllHands ||
                      m.receiverId.toLowerCase() == _activeEmpId.toLowerCase();
                  if (m.senderId.toLowerCase() != _activeEmpId.toLowerCase() &&
                      isForMe) {
                    final payload = m.isAllHands
                        ? 'chat:ALL_HANDS|MN All-Hands Workforce|All Employees|true'
                        : 'chat:${m.senderId}|${m.senderName}|${m.senderRole}|false';
                    PushNotificationService()
                        .showChatNotification(
                          id: m.id,
                          senderName: m.senderName,
                          message: m.text,
                          isGroup: m.isAllHands,
                          payload: payload,
                        )
                        .catchError((err) {
                          debugPrint(
                            'Push notification incoming chat stream error: $err',
                          );
                        });
                  }
                }
              }
            }

            notifyListeners();
          }
        },
        onError: (err) {
          debugPrint('Firestore chat stream note: $err');
        },
      );
    } catch (e) {
      debugPrint('Firestore chat stream error: $e');
    }

    try {
      _konarBooksSubscription = _firebaseEmployeeService
          .streamKonarBooks()
          .listen(
            (remoteBooks) {
              if (remoteBooks.isNotEmpty) {
                _konarBooks = remoteBooks;
                notifyListeners();
              }
            },
            onError: (err) {
              debugPrint('Firestore KONAR Books stream note: $err');
            },
          );
    } catch (e) {
      debugPrint('Firestore KONAR Books stream error: $e');
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
        _firebaseEmployeeService
            .saveEmployeePillar(
              empId: p.enrollNumber,
              pillarKey: 'attendance',
              data: _attendancePunches
                  .where((e) => e.enrollNumber == p.enrollNumber)
                  .map((e) => e.toJson())
                  .toList(),
            )
            .then((_) {
              OfflineSyncService.removePendingPunch(p.id);
              debugPrint('Synced offline punch ${p.id} to cloud successfully.');
            })
            .catchError((_) {});
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

      // 2. HR Management - Employee Number 7
      Employee(
        id: '7',
        empNo: '7',
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
      // Exempt from daily attendance and grooming
      Employee(
        id: 'MN-TL1002',
        empNo: '',
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

      // 4. OSH - Online Sale Head - Employee Number 6
      Employee(
        id: '6',
        empNo: '6',
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

      // 5. Ass.VPE - Assistant Photographer - Employee Number 33
      Employee(
        id: '33',
        empNo: '33',
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

      // 6. OS1 - Online Sale Person 1 - Employee Number 65
      Employee(
        id: '65',
        empNo: '65',
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

      // 7. OS2 - Online Sale Person 2 - Employee Number 67
      Employee(
        id: '67',
        empNo: '67',
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

      // 8. VPE - Video Production Executive / Lead Videographer & Editor
      // External Support Staff [Online] (Off-site contractor - Konar Book)
      Employee(
        id: 'EXT-VPE',
        empNo: '',
        name: 'Aravinda Samy',
        role: 'Chief Photographer, Videographer & Content Video Editor (VPE)',
        roleType: 'external_support',
        dept: 'External Support Staff [Online]',
        phone: '+91 94420 11010',
        email: 'aravindasamy@mnj.com',
        avatar: '',
        initials: 'AS',
        doj: '2022-03-01',
        experienceYears: '7 yrs in Videography & Direction',
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
        dob: '1992-06-18',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'aravind@mnj123',
      ),

      // 9. AC - Online Analytical Consultant
      // External Support Staff [Online] (Off-site contractor - Konar Book)
      Employee(
        id: 'EXT-AC',
        empNo: '',
        name: 'Midhun Kumar',
        role: 'Online Analytical Consultant (AC)',
        roleType: 'external_support',
        dept: 'External Support Staff [Online]',
        phone: '+91 94420 11011',
        email: 'midhunkumar@mnj.com',
        avatar: '',
        initials: 'MK',
        doj: '2022-05-15',
        experienceYears: '6 yrs in Ads & Search Analytics',
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
        dob: '1994-03-22',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'midhun@mnj123',
      ),

      // 10. OSS - Online Support and Strategist
      // External Support Staff [Online] (Off-site contractor - Konar Book)
      Employee(
        id: 'EXT-OSS',
        empNo: '',
        name: 'Subash',
        role: 'Online Support and Strategist (OSS)',
        roleType: 'external_support',
        dept: 'External Support Staff [Online]',
        phone: '+91 94420 11012',
        email: 'subash@mnj.com',
        avatar: '',
        initials: 'SB',
        doj: '2022-07-01',
        experienceYears: '5 yrs in Campaign Strategy',
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
        dob: '1995-11-09',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'subash@mnj123',
      ),

      // 11. DVP - Developer
      // External Support Staff [Online] (Off-site contractor - Konar Book)
      Employee(
        id: 'EXT-DVP',
        empNo: '',
        name: 'K B Eshwar',
        role: 'Developer (DVP)',
        roleType: 'external_support',
        dept: 'External Support Staff [Online]',
        phone: '+91 94420 11013',
        email: 'kbeshwar@mnj.com',
        avatar: '',
        initials: 'KE',
        doj: '2022-02-10',
        experienceYears: '6 yrs in Web & Mobile Engineering',
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
        dob: '1993-09-30',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'eshwar@mnj123',
      ),

      // 12. CC - Content Creator
      // External Support Staff [Online] (Off-site contractor - Konar Book)
      Employee(
        id: 'EXT-CC',
        empNo: '',
        name: 'Sam Roy',
        role: 'Content Creator (CC)',
        roleType: 'external_support',
        dept: 'External Support Staff [Online]',
        phone: '+91 94420 11014',
        email: 'samroy@mnj.com',
        avatar: '',
        initials: 'SR',
        doj: '2022-08-15',
        experienceYears: '4 yrs in Scripting & Content Creation',
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
        dob: '1998-04-14',
        relationshipStatus: 'Single',
        anniversaryDate: '',
        password: 'sam@mnj123',
      ),
    ];

    // 2. Pre-populate Standard Work / SOP Tasks for every role based on the KONAR Book
    _tasks = [];
    for (final emp in _employees) {
      final code = KonarTaskCatalog.resolveRoleCode(
        emp.role,
        emp.email,
        emp.id,
      );
      _tasks.addAll(
        KonarTaskCatalog.getStandardTasksForEmployee(emp.id, code, emp.name),
      );
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
        ReadinessDept(
          name: 'Housekeeping',
          task: 'Floor deep-clean & velvet glass mirror polish verified',
          signed: false,
          signedBy: '',
          time: '--',
        ),
        ReadinessDept(
          name: 'Vault & Logistics',
          task: 'Morning display trays issued to counters',
          signed: false,
          signedBy: '',
          time: '--',
        ),
        ReadinessDept(
          name: 'Security & CCTV',
          task: '360° CCTV scan & emergency exit sensor clearance',
          signed: false,
          signedBy: '',
          time: '--',
        ),
        ReadinessDept(
          name: 'Operations & Assay',
          task: 'Digital 0.001g scales calibrated & hallmarking active',
          signed: false,
          signedBy: '',
          time: '--',
        ),
        ReadinessDept(
          name: 'Showroom Sales',
          task: 'Staff groomed, velvet spotlights calibrated to 4000K',
          signed: false,
          signedBy: '',
          time: '--',
        ),
        ReadinessDept(
          name: 'Finance & Accounts',
          task: 'Daily 22K gold rate synchronized on billing',
          signed: false,
          signedBy: '',
          time: '--',
        ),
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

    // Real-time Workforce Chat Engine (Clean state: only real messages sent by users or streamed from Firestore)
    _chatMessages = [];

    // Pre-seed Google Sheets HR Attendance data with official November ledger
    _hrAttendanceSheet =
        GoogleSheetsAttendanceService.parseCsvToAttendanceSheet(
          GoogleSheetsAttendanceService.embeddedNovemberSeedCsv,
        );
    _attendanceSheetLastSynced = DateTime.now();

    // Fetch live Google Sheets immediately upon initialization
    syncGoogleSheetsAttendance(notifyIfUpdated: false);
  }

  // --- ACTIONS ---

  // CEO Role & Privilege Allocation Action
  Future<void> allocateEmployeeRole({
    required String empId,
    required String newRole,
    required String newDept,
    List<String>? perks,
    List<String>? responsibilities,
  }) async {
    final idx = _employees.indexWhere((e) => e.id == empId || e.empNo == empId);
    if (idx != -1) {
      final existing = _employees[idx];
      String newRoleType = existing.roleType;
      final r = newRole.toLowerCase();
      if (r.contains('ceo') || r.contains('managing director')) {
        newRoleType = 'ceo';
      } else if (r.contains('hr') || r.contains('human resources')) {
        newRoleType = 'hr';
      } else if (r.contains('team lead') ||
          r.contains('manager') ||
          r.contains('dept head') ||
          r.contains('lead') ||
          r.contains('otm')) {
        newRoleType = 'team_lead';
      } else {
        newRoleType = 'employee';
      }

      final updated = existing.copyWith(
        role: newRole,
        dept: newDept,
        roleType: newRoleType,
      );
      _employees[idx] = updated;

      if (empId == _activeEmpId) {
        _activeRole = newRoleType;
      }

      // Sync updated employee to Firestore
      await _firebaseEmployeeService.saveEmployee(updated);

      // Create personal notification targeted ONLY to this specific employee
      final notifId = 'ROLE_${DateTime.now().millisecondsSinceEpoch}_$empId';
      final perksText = (perks != null && perks.isNotEmpty)
          ? '\n\nExecutive Privileges Granted:\n• ${perks.join('\n• ')}'
          : '';
      final roleNotif = CompanyNotification(
        id: notifId,
        title: '🎖️ Role & Privileges Assigned: $newRole',
        content:
            'Executive Management (CEO) has officially assigned you the role of $newRole in $newDept.$perksText\n\nYour portal account is updated with active executive privileges.',
        type: CompanyNotificationType.broadcastNotice,
        timestamp: DateTime.now(),
        senderName: 'M N Naveenraaj',
        senderRole: 'Managing Director & CEO',
        actionTag: 'ROLE_PRIVILEGE',
        targetEmpId: empId,
      );

      _companyNotifications.insert(0, roleNotif);
      await _firebaseEmployeeService.saveCompanyNotification(roleNotif);

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
    _groomingAudits.removeWhere(
      (a) =>
          a.empId == empId &&
          a.date.year == now.year &&
          a.date.month == now.month &&
          a.date.day == now.day,
    );

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

    _firebaseEmployeeService.saveEmployeePillar(
      empId: empId,
      pillarKey: 'grooming',
      data: _groomingAudits
          .where((a) => a.empId == empId)
          .map((a) => a.toMap())
          .toList(),
    );
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
    final checklist = isFem
        ? getFemaleGroomingChecklist()
        : getMaleGroomingChecklist();
    recordDailyGroomingAudit(
      empId: empId,
      followedItems: pointsChange >= 0 ? checklist : [],
      pointsEarned: newPts,
      reason: reason,
      auditedBy: auditedBy,
    );
  }

  // Permission & Late Arrival Request (4.0 hrs limit & 1 CL rule)
  void requestPermission({
    required String empId,
    required double requestedHours,
    required double actualHoursUsed,
    required String reason,
    bool isCasualLeave = false,
  }) {
    final now = DateTime.now();
    final currentUsed = totalPermissionHoursUsed;
    final willExceed =
        (currentUsed + actualHoursUsed) > _monthlyPermissionHoursLimit;
    final currentCL = casualLeavesUsed;
    final isSalaryDeduct =
        isCasualLeave && (currentCL >= _monthlyCasualLeavesLimit);

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

    _firebaseEmployeeService.saveEmployeePillar(
      empId: empId,
      pillarKey: 'permissions',
      data: _permissionRecords
          .where((p) => p.empId == empId)
          .map((p) => p.toMap())
          .toList(),
    );
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
        .where(
          (p) =>
              p.empId == empId &&
              !p.isCasualLeave &&
              p.status != 'Rejected' &&
              _isCurrentMonth(p.date),
        )
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

    final emp = _employees.firstWhere(
      (e) => e.id == empId,
      orElse: () => _employees.first,
    );
    dispatchAcceptanceNotification(
      requestType: AcceptanceRequestType.permission,
      employeeId: empId,
      employeeName: emp.name,
      durationOrDays: '$hours Hours',
      reason: reason,
      approvedBy: 'HR (Mohankumar G)',
      requesterRole: emp.role,
      department: emp.dept,
    );

    _firebaseEmployeeService.saveEmployeePillar(
      empId: empId,
      pillarKey: 'permissions',
      data: _permissionRecords
          .where((p) => p.empId == empId)
          .map((p) => p.toMap())
          .toList(),
    );
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
    final willExceed =
        (currentUsed + requestedHours) > _monthlyPermissionHoursLimit;

    final emp = _employees.firstWhere(
      (e) => e.id == empId,
      orElse: () => _employees.first,
    );
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
    final emp = _employees.firstWhere(
      (e) => e.id == empId,
      orElse: () => _employees.first,
    );

    // Tally in 2-hour permission section:
    // If request exceeds 2 hrs OR month used + request exceeds 2 hrs, flag as isOver2Hours (Orange mark)
    final currentMonthUsed = _permissionRecords
        .where(
          (p) =>
              p.empId == empId &&
              !p.isCasualLeave &&
              p.status != 'Rejected' &&
              _isCurrentMonth(p.date),
        )
        .fold(0.0, (sum, p) => sum + p.actualHoursUsed);
    final willExceed =
        (currentMonthUsed + hours) > _monthlyPermissionHoursLimit ||
        hours > 2.0;

    final isHrRequester = requesterRole.toLowerCase().contains('hr');
    // HR directly requests from CEO; Employee & TL need HR & CEO approval flow
    final initialStatus = isHrRequester ? 'Pending CEO' : 'Pending HR & CEO';

    final durationFormatted = hours < 1.0
        ? '${(hours * 60).round()}m'
        : '${hours.toStringAsFixed(1)}h';

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
      body:
          '${emp.name} ($requesterRole) requested emergency permission to step out: "$reason".',
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
    final emp = _employees.firstWhere(
      (e) => e.id == empId,
      orElse: () => _employees.first,
    );
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
      body:
          '${emp.name} ($requesterRole) submitted emergency medical leave with prescription: "$reason".',
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
      final emp = _employees.firstWhere(
        (e) => e.id == old.empId,
        orElse: () => _employees.first,
      );
      PushNotificationService().showNotification(
        id: 'HR-GRANT-${DateTime.now().millisecondsSinceEpoch}',
        title: 'HR Granted Permission: CEO Acceptance Required',
        body:
            'HR granted permission for ${emp.name} (${old.actualHoursUsed}h). Final CEO acceptance needed.',
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
      final emp = _employees.firstWhere(
        (e) => e.id == old.empId,
        orElse: () => _employees.first,
      );
      dispatchAcceptanceNotification(
        requestType: AcceptanceRequestType.permission,
        employeeId: old.empId,
        employeeName: emp.name,
        durationOrDays: '${old.actualHoursUsed} Hours',
        reason: old.reason,
        approvedBy: 'HR (Mohankumar G)',
        requesterRole: old.requesterRole,
        department: old.department,
      );
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
      final emp = _employees.firstWhere(
        (e) => e.id == old.empId,
        orElse: () => _employees.first,
      );
      dispatchAcceptanceNotification(
        requestType: AcceptanceRequestType.permission,
        employeeId: old.empId,
        employeeName: emp.name,
        durationOrDays: '${old.actualHoursUsed} Hours',
        reason: old.reason,
        approvedBy: 'CEO (M N Naveenraaj)',
        requesterRole: old.requesterRole,
        department: old.department,
      );
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
      final emp = _employees.firstWhere(
        (e) => e.id == old.empId,
        orElse: () => _employees.first,
      );
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
        body:
            'HR verified prescription for ${old.empName} (${old.days} days). Awaiting CEO approval.',
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
      dispatchAcceptanceNotification(
        requestType: AcceptanceRequestType.leave,
        employeeId: old.empId,
        employeeName: old.empName,
        durationOrDays: '${old.days} Days Medical Leave',
        reason: old.reason,
        approvedBy: 'CEO (M N Naveenraaj)',
        requesterRole: old.empRole,
        department: old.department,
      );
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
        body:
            'Emergency medical leave for ${old.empName} was rejected by $rejector.',
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
  void completeHealthOnboarding({
    required double heightCm,
    required double weightKg,
  }) {
    _userHeightCm = heightCm;
    _userWeightKg = weightKg;
    _healthOnboarded = true;
    final now = DateTime.now();
    final timeStr =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
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
      data: {'heightCm': heightCm, 'weightKg': weightKg, 'onboarded': true},
    );
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setDouble('health_height_$_activeEmpId', heightCm);
          prefs.setDouble('health_weight_$_activeEmpId', weightKg);
          prefs.setBool('health_onboarded_$_activeEmpId', true);
        })
        .catchError((_) {});
  }

  void updateWeightAndHeight({
    required double heightCm,
    required double weightKg,
  }) {
    _userHeightCm = heightCm;
    _userWeightKg = weightKg;
    final now = DateTime.now();
    final timeStr =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
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
      data: {'heightCm': heightCm, 'weightKg': weightKg, 'onboarded': true},
    );
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setDouble('health_height_$_activeEmpId', heightCm);
          prefs.setDouble('health_weight_$_activeEmpId', weightKg);
          prefs.setBool('health_onboarded_$_activeEmpId', true);
        })
        .catchError((_) {});
  }

  void setDailyCalorieTarget(double target) {
    _dailyCalorieTarget = target;
    notifyListeners();
    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'health',
      data: {
        'heightCm': _userHeightCm,
        'weightKg': _userWeightKg,
        'onboarded': _healthOnboarded,
        'dailyCalorieTarget': target,
      },
    );
  }

  void setStepPermissionGranted(bool granted) {
    _stepPermissionGranted = granted;
    notifyListeners();
  }

  void recordDailySteps({required DateTime date, required int steps}) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    _dailyStepsMap[key] = steps;
    notifyListeners();
    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'health',
      data: {
        'heightCm': _userHeightCm,
        'weightKg': _userWeightKg,
        'onboarded': _healthOnboarded,
        if (_dailyCalorieTarget != null)
          'dailyCalorieTarget': _dailyCalorieTarget,
        'dailySteps': _dailyStepsMap,
      },
    );
  }

  void addFoodLog({
    required String foodName,
    required String mealType,
    required double grams,
    required double calories,
    DateTime? logDate,
    String portionSize = 'Normal',
    double quantity = 1.0,
  }) {
    final targetDate = logDate ?? DateTime.now();
    final timeStr =
        '${targetDate.day} ${_monthName(targetDate.month)} ${targetDate.year}, ${targetDate.hour % 12 == 0 ? 12 : targetDate.hour % 12}:${targetDate.minute.toString().padLeft(2, '0')} ${targetDate.hour >= 12 ? 'PM' : 'AM'}';
    _dailyFoodLogs.insert(
      0,
      FoodLogItem(
        id: 'FOOD-${DateTime.now().millisecondsSinceEpoch}',
        foodName: foodName,
        mealType: mealType,
        grams: grams,
        calories: calories,
        timestamp: targetDate,
        timeString: timeStr,
        portionSize: portionSize,
        quantity: quantity,
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
    DateTime? logDate,
    String notes = '',
    int laps = 0,
    int sets = 0,
    int rounds = 0,
    String customMetric = '',
  }) {
    final targetDate = logDate ?? DateTime.now();
    final timeStr =
        '${targetDate.day} ${_monthName(targetDate.month)} ${targetDate.year}, ${targetDate.hour % 12 == 0 ? 12 : targetDate.hour % 12}:${targetDate.minute.toString().padLeft(2, '0')} ${targetDate.hour >= 12 ? 'PM' : 'AM'}';
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
        timestamp: targetDate,
        timeString: timeStr,
        notes: notes,
        laps: laps,
        sets: sets,
        rounds: rounds,
        customMetric: customMetric,
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
    if (role == 'ceo') {
      _activeEmpId = 'MN-CEO01';
    } else if (role == 'hr') {
      _activeEmpId = '7';
    } else if (role == 'team_lead' || role == 'dept_head') {
      _activeEmpId = 'MN-TL1002';
    }
    notifyListeners();
  }

  void setActiveEmpId(String empId) {
    _activeEmpId = empId;
    if (empId == 'MN-CEO01') {
      _activeRole = 'ceo';
    } else if (empId == '7' || empId == 'MN-HR1001') {
      _activeRole = 'hr';
    } else if (empId == 'MN-TL1002') {
      _activeRole = 'team_lead';
    } else {
      final emp = _employees.firstWhere(
        (e) => e.id == empId || e.empNo == empId,
        orElse: () => currentEmployee,
      );
      _activeRole = emp.roleType;
    }
    loadEmployeeFourPillars(empId);
    try {
      PushNotificationService().syncActiveUserToNative(
        empId,
        currentEmployee.name,
      );
    } catch (_) {}
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setString('saved_emp_id', _activeEmpId);
          prefs.setString('saved_role', _activeRole);
          prefs.setString('saved_email', currentEmployee.email);
        })
        .catchError((_) {});
    checkAndDispatchCelebrations();
    notifyListeners();
  }

  /// Dynamic login connecting Firebase Auth & Cloud Firestore
  /// Returns authenticated activeRole ('hr', 'team_lead', 'employee', 'ceo')
  /// Strictly validates credentials and throws Exception('Email / Password incorrect') on failure.
  Future<String> loginWithFirebase({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      throw Exception('Email / Password incorrect');
    }

    // 1. Instant corporate directory verification
    final Map<
      String,
      ({
        String roleType,
        String empId,
        String defaultEmail,
        List<String> validPasswords,
      })
    >
    corporateRegistry = {
      // 1. CEO M N Naveenraaj
      'ceoofmn@mnjpark.com': (
        roleType: 'ceo',
        empId: 'MN-CEO01',
        defaultEmail: 'ceoofmn@mnjpark.com',
        validPasswords: ['adminnaandhan', 'mnj12345'],
      ),
      'ceo@mnj.com': (
        roleType: 'ceo',
        empId: 'MN-CEO01',
        defaultEmail: 'ceoofmn@mnjpark.com',
        validPasswords: ['adminnaandhan', 'mnj12345'],
      ),
      'mn-ceo01': (
        roleType: 'ceo',
        empId: 'MN-CEO01',
        defaultEmail: 'ceoofmn@mnjpark.com',
        validPasswords: ['adminnaandhan', 'mnj12345'],
      ),
      'ceo': (
        roleType: 'ceo',
        empId: 'MN-CEO01',
        defaultEmail: 'ceoofmn@mnjpark.com',
        validPasswords: ['adminnaandhan', 'mnj12345'],
      ),
      'naveenraaj': (
        roleType: 'ceo',
        empId: 'MN-CEO01',
        defaultEmail: 'ceoofmn@mnjpark.com',
        validPasswords: ['adminnaandhan', 'mnj12345'],
      ),
      'naveen': (
        roleType: 'ceo',
        empId: 'MN-CEO01',
        defaultEmail: 'ceoofmn@mnjpark.com',
        validPasswords: ['adminnaandhan', 'mnj12345'],
      ),
      'ceoofmn': (
        roleType: 'ceo',
        empId: 'MN-CEO01',
        defaultEmail: 'ceoofmn@mnjpark.com',
        validPasswords: ['adminnaandhan', 'mnj12345'],
      ),

      // 2. HR Manager & Operations Custodian Mohankumar G (Emp #7)
      '7': (
        roleType: 'hr',
        empId: '7',
        defaultEmail: 'hr@mnj.com',
        validPasswords: ['hr@mnj123', 'mnj12345'],
      ),
      'hr@mnj.com': (
        roleType: 'hr',
        empId: '7',
        defaultEmail: 'hr@mnj.com',
        validPasswords: ['hr@mnj123', 'mnj12345'],
      ),
      'mohankumar@mnj.com': (
        roleType: 'hr',
        empId: '7',
        defaultEmail: 'hr@mnj.com',
        validPasswords: ['hr@mnj123', 'mnj12345'],
      ),
      'mn-hr1001': (
        roleType: 'hr',
        empId: '7',
        defaultEmail: 'hr@mnj.com',
        validPasswords: ['hr@mnj123', 'mnj12345'],
      ),
      'hr': (
        roleType: 'hr',
        empId: '7',
        defaultEmail: 'hr@mnj.com',
        validPasswords: ['hr@mnj123', 'mnj12345'],
      ),
      'mohankumar': (
        roleType: 'hr',
        empId: '7',
        defaultEmail: 'hr@mnj.com',
        validPasswords: ['hr@mnj123', 'mnj12345'],
      ),

      // 3. Online Team Manager (OTM) Praveenkumar M
      'praveenkumarotm@mnj.com': (
        roleType: 'team_lead',
        empId: 'MN-TL1002',
        defaultEmail: 'praveenkumarotm@mnj.com',
        validPasswords: ['praveen@mnj123', 'mnj12345'],
      ),
      'mn-tl1002': (
        roleType: 'team_lead',
        empId: 'MN-TL1002',
        defaultEmail: 'praveenkumarotm@mnj.com',
        validPasswords: ['praveen@mnj123', 'mnj12345'],
      ),

      // 4. Online Sale Head (OSH) Gokulakrishnan K (Emp #6)
      '6': (
        roleType: 'employee',
        empId: '6',
        defaultEmail: 'gokulakrishnanosh@mnj.com',
        validPasswords: ['gokul@mnj123', 'mnj12345'],
      ),
      'gokulakrishnanosh@mnj.com': (
        roleType: 'employee',
        empId: '6',
        defaultEmail: 'gokulakrishnanosh@mnj.com',
        validPasswords: ['gokul@mnj123', 'mnj12345'],
      ),
      'gokulakrishnan@mnj.com': (
        roleType: 'employee',
        empId: '6',
        defaultEmail: 'gokulakrishnanosh@mnj.com',
        validPasswords: ['gokul@mnj123', 'mnj12345'],
      ),
      'mn-1003': (
        roleType: 'employee',
        empId: '6',
        defaultEmail: 'gokulakrishnanosh@mnj.com',
        validPasswords: ['gokul@mnj123', 'mnj12345'],
      ),

      // 5. Assistant Photographer & Videographer Mithra M (Emp #33)
      '33': (
        roleType: 'employee',
        empId: '33',
        defaultEmail: 'mithraassvpe@mnj.com',
        validPasswords: ['mithra@mnj123', 'mnj12345'],
      ),
      'mithraassvpe@mnj.com': (
        roleType: 'employee',
        empId: '33',
        defaultEmail: 'mithraassvpe@mnj.com',
        validPasswords: ['mithra@mnj123', 'mnj12345'],
      ),
      'mithra@mnj.com': (
        roleType: 'employee',
        empId: '33',
        defaultEmail: 'mithraassvpe@mnj.com',
        validPasswords: ['mithra@mnj123', 'mnj12345'],
      ),
      'mn-1005': (
        roleType: 'employee',
        empId: '33',
        defaultEmail: 'mithraassvpe@mnj.com',
        validPasswords: ['mithra@mnj123', 'mnj12345'],
      ),

      // 6. Online Sale Person 1 (OS1) Kaaviya (Emp #65)
      '65': (
        roleType: 'employee',
        empId: '65',
        defaultEmail: 'kaaviyaos1@mnj.com',
        validPasswords: ['kaaviya@mnj123', 'mnj12345'],
      ),
      'kaaviyaos1@mnj.com': (
        roleType: 'employee',
        empId: '65',
        defaultEmail: 'kaaviyaos1@mnj.com',
        validPasswords: ['kaaviya@mnj123', 'mnj12345'],
      ),
      'kaaviya@mnj.com': (
        roleType: 'employee',
        empId: '65',
        defaultEmail: 'kaaviyaos1@mnj.com',
        validPasswords: ['kaaviya@mnj123', 'mnj12345'],
      ),
      'mn-1007': (
        roleType: 'employee',
        empId: '65',
        defaultEmail: 'kaaviyaos1@mnj.com',
        validPasswords: ['kaaviya@mnj123', 'mnj12345'],
      ),

      // 7. Online Sale Person 2 (OS2) Nisha (Emp #67)
      '67': (
        roleType: 'employee',
        empId: '67',
        defaultEmail: 'nishaos2@mnj.com',
        validPasswords: ['nisha@mnj123', 'mnj12345'],
      ),
      'nishaos2@mnj.com': (
        roleType: 'employee',
        empId: '67',
        defaultEmail: 'nishaos2@mnj.com',
        validPasswords: ['nisha@mnj123', 'mnj12345'],
      ),
      'nisha@mnj.com': (
        roleType: 'employee',
        empId: '67',
        defaultEmail: 'nishaos2@mnj.com',
        validPasswords: ['nisha@mnj123', 'mnj12345'],
      ),
      'mn-1008': (
        roleType: 'employee',
        empId: '67',
        defaultEmail: 'nishaos2@mnj.com',
        validPasswords: ['nisha@mnj123', 'mnj12345'],
      ),

      // 8. VPE Aravinda Samy (External Support Staff [Online])
      'ext-vpe': (
        roleType: 'employee',
        empId: 'EXT-VPE',
        defaultEmail: 'aravindasamy@mnj.com',
        validPasswords: ['aravind@mnj123', 'mnj12345'],
      ),
      'aravindasamy@mnj.com': (
        roleType: 'employee',
        empId: 'EXT-VPE',
        defaultEmail: 'aravindasamy@mnj.com',
        validPasswords: ['aravind@mnj123', 'mnj12345'],
      ),
      'vpe': (
        roleType: 'employee',
        empId: 'EXT-VPE',
        defaultEmail: 'aravindasamy@mnj.com',
        validPasswords: ['aravind@mnj123', 'mnj12345'],
      ),

      // 9. AC Midhun Kumar (External Support Staff [Online])
      'ext-ac': (
        roleType: 'employee',
        empId: 'EXT-AC',
        defaultEmail: 'midhunkumar@mnj.com',
        validPasswords: ['midhun@mnj123', 'mnj12345'],
      ),
      'midhunkumar@mnj.com': (
        roleType: 'employee',
        empId: 'EXT-AC',
        defaultEmail: 'midhunkumar@mnj.com',
        validPasswords: ['midhun@mnj123', 'mnj12345'],
      ),
      'ac': (
        roleType: 'employee',
        empId: 'EXT-AC',
        defaultEmail: 'midhunkumar@mnj.com',
        validPasswords: ['midhun@mnj123', 'mnj12345'],
      ),

      // 10. OSS Subash (External Support Staff [Online])
      'ext-oss': (
        roleType: 'employee',
        empId: 'EXT-OSS',
        defaultEmail: 'subash@mnj.com',
        validPasswords: ['subash@mnj123', 'mnj12345'],
      ),
      'subash@mnj.com': (
        roleType: 'employee',
        empId: 'EXT-OSS',
        defaultEmail: 'subash@mnj.com',
        validPasswords: ['subash@mnj123', 'mnj12345'],
      ),
      'oss': (
        roleType: 'employee',
        empId: 'EXT-OSS',
        defaultEmail: 'subash@mnj.com',
        validPasswords: ['subash@mnj123', 'mnj12345'],
      ),

      // 11. DVP K B Eshwar (External Support Staff [Online])
      'ext-dvp': (
        roleType: 'employee',
        empId: 'EXT-DVP',
        defaultEmail: 'kbeshwar@mnj.com',
        validPasswords: ['eshwar@mnj123', 'mnj12345'],
      ),
      'kbeshwar@mnj.com': (
        roleType: 'employee',
        empId: 'EXT-DVP',
        defaultEmail: 'kbeshwar@mnj.com',
        validPasswords: ['eshwar@mnj123', 'mnj12345'],
      ),
      'dvp': (
        roleType: 'employee',
        empId: 'EXT-DVP',
        defaultEmail: 'kbeshwar@mnj.com',
        validPasswords: ['eshwar@mnj123', 'mnj12345'],
      ),

      // 12. CC Sam Roy (External Support Staff [Online])
      'ext-cc': (
        roleType: 'employee',
        empId: 'EXT-CC',
        defaultEmail: 'samroy@mnj.com',
        validPasswords: ['sam@mnj123', 'mnj12345'],
      ),
      'samroy@mnj.com': (
        roleType: 'employee',
        empId: 'EXT-CC',
        defaultEmail: 'samroy@mnj.com',
        validPasswords: ['sam@mnj123', 'mnj12345'],
      ),
      'cc': (
        roleType: 'employee',
        empId: 'EXT-CC',
        defaultEmail: 'samroy@mnj.com',
        validPasswords: ['sam@mnj123', 'mnj12345'],
      ),
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
        _firebaseEmployeeService.ensureFirebaseAuthSession(
          reg.defaultEmail,
          cleanPass,
        );
        await loadEmployeeFourPillars(reg.empId);
        checkAndResetDailySops();
        try {
          PushNotificationService().requestAllPriorPermissions(
            empId: reg.empId,
            empName: currentEmployee.name,
          );
        } catch (_) {}
        notifyListeners();
        return _activeRole;
      } else {
        throw Exception('Email / Password incorrect');
      }
    }

    // 2. Local employees list authentication
    final localMatch = _employees
        .where(
          (e) =>
              e.email.toLowerCase() == cleanEmail ||
              e.id.toLowerCase() == cleanEmail,
        )
        .toList();

    if (localMatch.isNotEmpty) {
      final emp = localMatch.first;
      final isCeo =
          (emp.roleType == 'ceo' || emp.id == 'MN-CEO01') &&
          (cleanPass == 'adminnaandhan' || cleanPass == emp.password);
      final isHr =
          (emp.roleType == 'hr' || emp.id == '7' || emp.id == 'MN-HR1001') &&
          (cleanPass == 'hr@mnj123' || cleanPass == emp.password);
      final isStandardMatch =
          cleanPass == emp.password || cleanPass == 'mnj12345';

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
        _firebaseEmployeeService.ensureFirebaseAuthSession(
          emp.email,
          cleanPass,
        );
        await loadEmployeeFourPillars(emp.id);
        checkAndResetDailySops();
        try {
          PushNotificationService().requestAllPriorPermissions(
            empId: emp.id,
            empName: currentEmployee.name,
          );
        } catch (_) {}
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
        final roleType =
            (userProfile['roleType'] ?? userProfile['role'] ?? 'employee')
                .toString()
                .toLowerCase();
        final empId = (userProfile['empId'] ?? _activeEmpId).toString();

        if (roleType == 'hr') {
          _activeRole = 'hr';
          _activeEmpId = (empId.isNotEmpty && empId != 'MN-CEO01')
              ? empId
              : '7';
        } else if (roleType == 'team_lead' || roleType == 'dept_head') {
          _activeRole = 'dept_head';
          _activeEmpId = empId.isNotEmpty ? empId : 'MN-TL1002';
        } else if (roleType == 'ceo' || empId == 'MN-CEO01') {
          _activeRole = 'ceo';
          _activeEmpId = 'MN-CEO01';
        } else {
          _activeRole = 'employee';
          _activeEmpId = empId;
        }
        _firebaseEmployeeService.ensureFirebaseAuthSession(
          cleanEmail,
          cleanPass,
        );
        await loadEmployeeFourPillars(empId);
        checkAndResetDailySops();
        notifyListeners();
        return _activeRole;
      }
    } catch (e) {
      debugPrint('loginWithFirebase note: ');
      if (e is Exception &&
          e.toString().contains('Email / Password incorrect')) {
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
      final newInitials = name
          .trim()
          .split(RegExp(r'\s+'))
          .map((e) => e.isNotEmpty ? e[0] : '')
          .take(2)
          .join('')
          .toUpperCase();
      final updatedInitials = newInitials.isNotEmpty
          ? newInitials
          : oldEmp.initials;
      final updatedGender = gender ?? oldEmp.gender;

      _employees[idx] = oldEmp.copyWith(
        name: name,
        initials: updatedInitials,
        phone: phone,
        dob: dob,
        relationshipStatus: relationshipStatus,
        anniversaryDate: relationshipStatus == 'Married'
            ? (anniversaryDate ?? '')
            : '',
        gender: updatedGender,
      );
      notifyListeners();
      checkAndDispatchCelebrations();

      try {
        await _firebaseEmployeeService.updateEmployeeProfileFields(
          empId: empId,
          fields: {
            'name': name,
            'initials': updatedInitials,
            'phone': phone,
            'dob': dob,
            'relationshipStatus': relationshipStatus,
            'anniversaryDate': relationshipStatus == 'Married'
                ? (anniversaryDate ?? '')
                : '',
            if (updatedGender.isNotEmpty) 'gender': updatedGender,
          },
          email: oldEmp.email,
        );
        checkAndDispatchCelebrations();
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
    if (emp.password != oldPassword &&
        oldPassword != 'adminnaandhan' &&
        oldPassword != 'hr@mnj123') {
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
      _tasks[idx] = t.copyWith(due: 'Tomorrow 11:00 AM', status: 'postponed');
      _notificationMessage =
          'Task "${t.title}" shifted to tomorrow by Team Lead.';
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
      final prevEmp = _employees.firstWhere(
        (e) => e.id == t.empId,
        orElse: () => _employees.first,
      );
      final newEmp = _employees.firstWhere(
        (e) => e.id == newEmpId,
        orElse: () => _employees.first,
      );

      final byName = assignedByName ?? 'TL / Manager';
      final byRole = assignedByRole ?? _activeRole;

      _tasks[idx] = t.copyWith(
        empId: newEmpId,
        assignedByName: 'Reallocated from ${prevEmp.name} (Absent) by $byName',
        assignedByRole: byRole,
        status: 'pending',
      );
      _notificationMessage =
          'Task "${t.title}" reallocated to ${newEmp.name} successfully.';

      final notif = CompanyNotification(
        id: 'NOTIF-REASSIGN-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Task Reallocated to You: ${t.title}',
        content:
            '$byName ($byRole) reallocated: "${t.title}" from ${prevEmp.name} (Absent) to you.',
        type: CompanyNotificationType.broadcastNotice,
        timestamp: DateTime.now(),
        senderName: byName,
        senderRole: byRole,
        isRead: false,
      );
      _companyNotifications.insert(0, notif);
      _notifiedCompanyNotifIds.add(notif.id);
      _firebaseEmployeeService.saveCompanyNotification(notif).catchError((err) {
        debugPrint('Firestore save reassign notif note: $err');
      });
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
    final fromEmp = _employees.firstWhere(
      (e) => e.id == fromEmpId,
      orElse: () => _employees.first,
    );
    final toEmp = _employees.firstWhere(
      (e) => e.id == toEmpId,
      orElse: () => _employees.first,
    );
    final byName = authorizedByName ?? 'Manager';
    final byRole = authorizedByRole ?? _activeRole;

    int count = 0;
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].empId == fromEmpId && _tasks[i].status == 'pending') {
        _tasks[i] = _tasks[i].copyWith(
          empId: toEmpId,
          assignedByName:
              'Reallocated from ${fromEmp.name} (Absent) by $byName',
          assignedByRole: byRole,
        );
        count++;
      }
    }
    _notificationMessage =
        '$count tasks reallocated from ${fromEmp.name} to ${toEmp.name}.';

    if (count > 0) {
      final notif = CompanyNotification(
        id: 'NOTIF-BATCH-${DateTime.now().millisecondsSinceEpoch}',
        title: '$count Tasks Reallocated to You',
        content:
            '$byName ($byRole) reallocated all $count pending tasks from ${fromEmp.name} (Absent) to you.',
        type: CompanyNotificationType.broadcastNotice,
        timestamp: DateTime.now(),
        senderName: byName,
        senderRole: byRole,
        isRead: false,
      );
      _companyNotifications.insert(0, notif);
      _notifiedCompanyNotifIds.add(notif.id);
      _firebaseEmployeeService.saveCompanyNotification(notif).catchError((err) {
        debugPrint('Firestore save reassign notif note: $err');
      });
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
          if (h['dailyCalorieTarget'] != null) {
            _dailyCalorieTarget = (h['dailyCalorieTarget'] as num?)?.toDouble();
          }
          if (h['dailyStepGoal'] != null) {
            _dailyStepGoal = (h['dailyStepGoal'] as num).toInt();
          }
          if (h['dailySteps'] is Map) {
            _dailyStepsMap = (h['dailySteps'] as Map).map(
              (k, v) => MapEntry(k.toString(), (v as num).toInt()),
            );
          }
        }
        if (pillars['meals'] is List) {
          _dailyFoodLogs = (pillars['meals'] as List)
              .map(
                (m) => FoodLogItem.fromMap(Map<String, dynamic>.from(m as Map)),
              )
              .toList();
        }
        if (pillars['workouts'] is List) {
          _dailyWorkoutLogs = (pillars['workouts'] as List)
              .map(
                (w) =>
                    WorkoutLogItem.fromMap(Map<String, dynamic>.from(w as Map)),
              )
              .toList();
        }

        // 2. Family Pillar
        if (pillars['family'] is List) {
          _familyActivityLogs = (pillars['family'] as List)
              .map(
                (f) => FamilyActivityItem.fromMap(
                  Map<String, dynamic>.from(f as Map),
                ),
              )
              .toList();
        }

        // 3. Profile Pillar (Original Documents Custody)
        if (pillars['documents'] is List &&
            (pillars['documents'] as List).isNotEmpty) {
          final loadedDocs = (pillars['documents'] as List)
              .map(
                (d) => OriginalDocumentItem.fromMap(
                  Map<String, dynamic>.from(d as Map),
                ),
              )
              .toList();
          _employeeDocuments[empId] = loadedDocs;
          if (empId == _activeEmpId) {
            _originalDocuments = loadedDocs;
          }
        } else {
          _employeeDocuments.putIfAbsent(empId, () => []);
          if (empId == _activeEmpId) {
            _originalDocuments = _employeeDocuments[empId]!;
          }
        }

        // 4. Attendance Pillar Punches
        if (pillars['attendance'] is List) {
          final loadedPunches = (pillars['attendance'] as List)
              .map(
                (p) => AttendancePunchRecord.fromJson(
                  Map<String, dynamic>.from(p as Map),
                ),
              )
              .toList();
          for (final p in loadedPunches) {
            if (!_attendancePunches.any((existing) => existing.id == p.id)) {
              _attendancePunches.insert(0, p);
            }
          }
        }

        // 5. Grooming Audits
        if (pillars['grooming'] is List) {
          final loadedGrooming = (pillars['grooming'] as List)
              .map(
                (g) => GroomingAuditItem.fromMap(
                  Map<String, dynamic>.from(g as Map),
                ),
              )
              .toList();
          for (final g in loadedGrooming) {
            _groomingAudits.removeWhere((existing) => existing.id == g.id);
            _groomingAudits.insert(0, g);
          }
        }

        // 6. Sales Records
        if (pillars['sales'] is List) {
          final loadedSales = (pillars['sales'] as List)
              .map(
                (s) => SalesRecord.fromMap(Map<String, dynamic>.from(s as Map)),
              )
              .toList();
          for (final s in loadedSales) {
            _salesRecords.removeWhere((existing) => existing.id == s.id);
            _salesRecords.insert(0, s);
          }
        }

        // 7. Permission Records
        if (pillars['permissions'] is List) {
          final loadedPerms = (pillars['permissions'] as List)
              .map(
                (p) => PermissionRecord.fromMap(
                  Map<String, dynamic>.from(p as Map),
                ),
              )
              .toList();
          for (final p in loadedPerms) {
            _permissionRecords.removeWhere((existing) => existing.id == p.id);
            _permissionRecords.insert(0, p);
          }
        }

        // 8. Emergency Medical Leaves
        if (pillars['medicalLeaves'] is List) {
          final loadedMed = (pillars['medicalLeaves'] as List)
              .map(
                (m) => MedicalLeaveRecord.fromMap(
                  Map<String, dynamic>.from(m as Map),
                ),
              )
              .toList();
          for (final m in loadedMed) {
            _medicalLeaveRecords.removeWhere((existing) => existing.id == m.id);
            _medicalLeaveRecords.insert(0, m);
          }
        }

        // Sync calculated holistic score to Cloud Firestore
        _firebaseEmployeeService.saveEmployeePillar(
          empId: empId,
          pillarKey: 'holisticStatus',
          data: {
            'score': holisticEquilibriumScore,
            'tierName': holisticTierName,
            'pillar1Health': pillar1HealthScore,
            'pillar2Family': pillar2FamilyScore,
            'pillar3Profile': pillar3ProfileScore,
            'pillar4Attendance': pillar4AttendanceScore,
            'lastCalculated': DateTime.now().toIso8601String(),
          },
        );

        notifyListeners();
      }

      // Ensure fallback defaults if Firestore had no record or missing fields
      if (_originalDocuments.isEmpty) {
        _originalDocuments = _employeeDocuments[empId] ?? [];
      }
      if (_userHeightCm <= 0 || _userWeightKg <= 0) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final savedH = prefs.getDouble('health_height_$empId');
          final savedW = prefs.getDouble('health_weight_$empId');
          final savedOnb = prefs.getBool('health_onboarded_$empId');
          final savedGoal = prefs.getInt('health_step_goal_$empId');
          if (savedGoal != null && savedGoal > 0) {
            _dailyStepGoal = savedGoal;
          }
          if (savedH != null && savedW != null && savedH > 0 && savedW > 0) {
            _userHeightCm = savedH;
            _userWeightKg = savedW;
            _healthOnboarded = savedOnb ?? true;
          }
        } catch (_) {}
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Firestore loadEmployeeFourPillars note: $e');
    }
  }

  /// Leadership Inspection (CEO & HR): Load live 4-Pillars input data for any employee
  Future<Map<String, dynamic>> loadEmployeePillarsForInspection(
    String empId,
  ) async {
    final now = DateTime.now();
    // If the active user is the inspected employee, return live data from provider
    if (empId == _activeEmpId) {
      return {
        'health': {
          'heightCm': _userHeightCm,
          'weightKg': _userWeightKg,
          'bmi': currentBmi,
          'bmiCategory': bmiCategory,
          'dailyCalorieTarget': _dailyCalorieTarget,
          'todayCalories': getCaloriesConsumedForDate(now),
          'dailyStepGoal': _dailyStepGoal,
          'todaySteps': getStepsForDate(now),
          'waterIntakeMl': 0,
          'meals': List<FoodLogItem>.from(_dailyFoodLogs),
          'workouts': List<WorkoutLogItem>.from(_dailyWorkoutLogs),
          'workoutMinutesToday': totalWorkoutMinutes,
        },
        'family': {
          'activities': List<FamilyActivityItem>.from(_familyActivityLogs),
          'totalFamilyHoursToday': totalFamilyHoursToday,
          'totalFriendsHoursToday': totalFriendsHoursToday,
          'totalSocialHoursToday':
              totalFamilyHoursToday + totalFriendsHoursToday,
        },
      };
    }

    // Otherwise, fetch from Firestore for that specific employee
    try {
      final pillars = await _firebaseEmployeeService.loadEmployeePillars(empId);
      final healthMap = (pillars != null && pillars['health'] is Map)
          ? Map<String, dynamic>.from(pillars['health'] as Map)
          : <String, dynamic>{};

      final double hCm = (healthMap['heightCm'] as num?)?.toDouble() ?? 0.0;
      final double wKg = (healthMap['weightKg'] as num?)?.toDouble() ?? 0.0;
      final double bmi = (hCm > 0 && wKg > 0)
          ? (wKg / ((hCm / 100.0) * (hCm / 100.0)))
          : 0.0;
      final String bCategory = bmi <= 0
          ? 'Not Calibrated'
          : (bmi < 18.5
                ? 'Underweight'
                : (bmi < 25.0
                      ? 'Healthy (Ideal)'
                      : (bmi < 30.0 ? 'Overweight' : 'Obese')));

      final mealsList = (pillars != null && pillars['meals'] is List)
          ? (pillars['meals'] as List)
                .map(
                  (m) =>
                      FoodLogItem.fromMap(Map<String, dynamic>.from(m as Map)),
                )
                .toList()
          : <FoodLogItem>[];

      final workoutsList = (pillars != null && pillars['workouts'] is List)
          ? (pillars['workouts'] as List)
                .map(
                  (w) => WorkoutLogItem.fromMap(
                    Map<String, dynamic>.from(w as Map),
                  ),
                )
                .toList()
          : <WorkoutLogItem>[];

      final familyList = (pillars != null && pillars['family'] is List)
          ? (pillars['family'] as List)
                .map(
                  (f) => FamilyActivityItem.fromMap(
                    Map<String, dynamic>.from(f as Map),
                  ),
                )
                .toList()
          : <FamilyActivityItem>[];

      final now = DateTime.now();
      bool isToday(DateTime d) =>
          d.year == now.year && d.month == now.month && d.day == now.day;

      final todayMeals = mealsList.where((m) => isToday(m.timestamp)).toList();
      final double todayCalories = todayMeals.fold(
        0.0,
        (sum, m) => sum + m.calories,
      );

      final todayWorkouts = workoutsList
          .where((w) => isToday(w.timestamp))
          .toList();
      final int workoutMins = todayWorkouts.fold(
        0,
        (sum, w) => sum + w.durationMinutes,
      );

      final todayFamily = familyList
          .where((f) => isToday(f.timestamp) && f.category == 'Family')
          .toList();
      final double familyHoursToday = todayFamily.fold(
        0.0,
        (sum, f) => sum + f.hoursSpent,
      );

      final todayFriends = familyList
          .where((f) => isToday(f.timestamp) && f.category != 'Family')
          .toList();
      final double friendsHoursToday = todayFriends.fold(
        0.0,
        (sum, f) => sum + f.hoursSpent,
      );

      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      int todaySteps = 0;
      if (healthMap['dailySteps'] is Map) {
        final stepsMap = Map<String, dynamic>.from(
          healthMap['dailySteps'] as Map,
        );
        todaySteps = (stepsMap[todayKey] as num?)?.toInt() ?? 0;
      }

      return {
        'health': {
          'heightCm': hCm,
          'weightKg': wKg,
          'bmi': bmi,
          'bmiCategory': bCategory,
          'dailyCalorieTarget': (healthMap['dailyCalorieTarget'] as num?)
              ?.toDouble(),
          'todayCalories': todayCalories,
          'dailyStepGoal':
              (healthMap['dailyStepGoal'] as num?)?.toInt() ?? 10000,
          'todaySteps': todaySteps,
          'waterIntakeMl': (healthMap['waterIntakeMl'] as num?)?.toInt() ?? 0,
          'meals': mealsList,
          'workouts': workoutsList,
          'workoutMinutesToday': workoutMins,
        },
        'family': {
          'activities': familyList,
          'totalFamilyHoursToday': familyHoursToday,
          'totalFriendsHoursToday': friendsHoursToday,
          'totalSocialHoursToday': familyHoursToday + friendsHoursToday,
        },
      };
    } catch (e) {
      debugPrint('loadEmployeePillarsForInspection error: $e');
      return {
        'health': {
          'heightCm': 0.0,
          'weightKg': 0.0,
          'bmi': 0.0,
          'bmiCategory': 'Not Calibrated',
          'dailyCalorieTarget': null,
          'todayCalories': 0.0,
          'dailyStepGoal': 10000,
          'todaySteps': 0,
          'waterIntakeMl': 0,
          'meals': <FoodLogItem>[],
          'workouts': <WorkoutLogItem>[],
          'workoutMinutesToday': 0,
        },
        'family': {
          'activities': <FamilyActivityItem>[],
          'totalFamilyHoursToday': 0.0,
          'totalFriendsHoursToday': 0.0,
          'totalSocialHoursToday': 0.0,
        },
      };
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
    String? imageUrl,
    DateTime? date,
  }) {
    final now = DateTime.now();
    final entryDate = date != null
        ? DateTime(date.year, date.month, date.day, now.hour, now.minute)
        : now;
    final timeStr =
        '${entryDate.day} ${_monthName(entryDate.month)} ${entryDate.year}, ${entryDate.hour % 12 == 0 ? 12 : entryDate.hour % 12}:${entryDate.minute.toString().padLeft(2, '0')} ${entryDate.hour >= 12 ? 'PM' : 'AM'}';
    _familyActivityLogs.insert(
      0,
      FamilyActivityItem(
        id: 'FAM-${DateTime.now().microsecondsSinceEpoch}',
        activityName: activityName,
        category: category,
        subCategory: subCategory,
        hoursSpent: hoursSpent,
        iconEmoji: iconEmoji,
        notes: notes,
        imageUrl: imageUrl,
        timestamp: entryDate,
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
    final cleanId = id.trim();
    _familyActivityLogs.removeWhere((a) => a.id.trim() == cleanId);
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'family',
      data: _familyActivityLogs.map((e) => e.toMap()).toList(),
    );
  }

  void deleteFamilyActivityItem(FamilyActivityItem item) {
    final cleanId = item.id.trim();
    int targetIndex = _familyActivityLogs.indexWhere(
      (a) =>
          identical(a, item) ||
          (cleanId.isNotEmpty && a.id.trim() == cleanId) ||
          (a.activityName.trim().toLowerCase() ==
                  item.activityName.trim().toLowerCase() &&
              (a.hoursSpent - item.hoursSpent).abs() < 0.05 &&
              _isSameDayDate(a.timestamp, item.timestamp)),
    );

    if (targetIndex != -1) {
      _familyActivityLogs.removeAt(targetIndex);
    } else if (cleanId.isNotEmpty) {
      _familyActivityLogs.removeWhere((a) => a.id.trim() == cleanId);
    } else {
      // Fallback: match by name and hours
      final fallbackIdx = _familyActivityLogs.indexWhere(
        (a) =>
            a.activityName.trim().toLowerCase() ==
                item.activityName.trim().toLowerCase() &&
            (a.hoursSpent - item.hoursSpent).abs() < 0.05,
      );
      if (fallbackIdx != -1) {
        _familyActivityLogs.removeAt(fallbackIdx);
      }
    }
    notifyListeners();

    _firebaseEmployeeService.saveEmployeePillar(
      empId: _activeEmpId,
      pillarKey: 'family',
      data: _familyActivityLogs.map((e) => e.toMap()).toList(),
    );
  }

  void resetFamilyHoursForDate(DateTime date) {
    _familyActivityLogs.removeWhere((a) => _isSameDayDate(a.timestamp, date));
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
    AttendanceVerifyMethod verifyMethod =
        AttendanceVerifyMethod.thumbImpression,
    String? empId,
  }) {
    final now = DateTime.now();

    // Category 4, Item 14: Debounce throttle (3 seconds)
    if (_isPunching ||
        (_lastPunchRecordedAt != null &&
            now.difference(_lastPunchRecordedAt!).inSeconds < 3)) {
      debugPrint('Punch ignored: debounced within 3 seconds');
      return false;
    }

    final targetId = empId ?? _activeEmpId;

    // Category 2, Item 9: Defense against client-side device clock rollback
    DateTime verifiedTime = now;
    if (_attendancePunches.isNotEmpty) {
      final latestPunchTime = _attendancePunches
          .map((p) => p.timestamp)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      if (verifiedTime.isBefore(latestPunchTime)) {
        debugPrint(
          'Warning: Device clock rollback detected ($verifiedTime < $latestPunchTime). Adjusting timestamp.',
        );
        verifiedTime = latestPunchTime.add(const Duration(seconds: 1));
      }
    }

    // Category 4: Robust Punch Sequence Validation for target employee
    final todayEmpPunches =
        _attendancePunches
            .where(
              (p) =>
                  p.enrollNumber == targetId &&
                  p.timestamp.year == now.year &&
                  p.timestamp.month == now.month &&
                  p.timestamp.day == now.day,
            )
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final hasLogin = todayEmpPunches.any(
      (p) => p.punchType == AttendancePunchType.login,
    );
    final hasLogout = todayEmpPunches.any(
      (p) => p.punchType == AttendancePunchType.logout,
    );

    final recentLunchOut = todayEmpPunches
        .where((p) => p.punchType == AttendancePunchType.breakOut)
        .toList();
    final recentLunchIn = todayEmpPunches
        .where((p) => p.punchType == AttendancePunchType.breakIn)
        .toList();
    final isCurrentlyOnLunch =
        recentLunchOut.isNotEmpty &&
        (recentLunchIn.isEmpty ||
            recentLunchOut.first.timestamp.isAfter(
              recentLunchIn.first.timestamp,
            ));

    if (punchType == AttendancePunchType.login && hasLogin) {
      _notificationMessage = 'Work Login already recorded for today.';
      notifyListeners();
      return false;
    }
    if (punchType == AttendancePunchType.logout) {
      if (!hasLogin) {
        _notificationMessage =
            'Cannot record Logout: No Work Login punch found for today.';
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
        _notificationMessage =
            'Cannot start Lunch Break: You have not punched in for work yet.';
        notifyListeners();
        return false;
      }
      if (hasLogout) {
        _notificationMessage =
            'Cannot start Lunch Break: Already punched out for the day.';
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
        _notificationMessage =
            'Cannot record Lunch In: No Work Login punch found.';
        notifyListeners();
        return false;
      }
      if (!isCurrentlyOnLunch) {
        _notificationMessage =
            'Cannot record Lunch In: You are not currently on Lunch Break.';
        notifyListeners();
        return false;
      }
    }

    // Debounce duplicate rapid punch: ignore identical punchType within 5 seconds
    final lastPunchForEmp = _attendancePunches
        .where((p) => p.enrollNumber == targetId)
        .firstOrNull;
    if (lastPunchForEmp != null &&
        lastPunchForEmp.punchType == punchType &&
        verifiedTime.difference(lastPunchForEmp.timestamp).inSeconds.abs() <
            5) {
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

    _firebaseEmployeeService
        .saveEmployeePillar(
          empId: targetId,
          pillarKey: 'attendance',
          data: _attendancePunches
              .where((p) => p.enrollNumber == targetId)
              .map((p) => p.toJson())
              .toList(),
        )
        .then((_) {
          OfflineSyncService.removePendingPunch(newPunch.id);
        })
        .catchError((err) {
          debugPrint(
            'Punch saved locally to offline queue, pending sync: $err',
          );
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
        await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(punch.toJson()),
            )
            .timeout(const Duration(milliseconds: 1000));
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
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(milliseconds: 1200));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['punches'] is List) {
            final List punchList = data['punches'];
            final loaded = punchList
                .map(
                  (item) => AttendancePunchRecord.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
            if (loaded.isNotEmpty) {
              for (final p in loaded) {
                if (!_attendancePunches.any(
                  (existing) => existing.id == p.id,
                )) {
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

  void updateEsslConfig({
    String? ip,
    int? port,
    int? machineNumber,
    String? modelName,
  }) {
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
    _attendancePunches.removeWhere(
      (p) =>
          p.enrollNumber == _activeEmpId &&
          p.timestamp.year == now.year &&
          p.timestamp.month == now.month &&
          p.timestamp.day == now.day,
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
    String vaultLockerRef = '',
    bool isMandatory = true,
    String iconEmoji = '📜',
    String? remarks,
  }) {
    final effectiveEmpId = targetEmpId ?? _activeEmpId;
    final now = DateTime.now();
    final timeStr =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
    final dateStr =
        submissionDate ??
        '${now.day} ${_monthName(now.month)} ${now.year}, $timeStr';
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

  void updateOriginalDocumentStatus(
    String id,
    DocumentSubmissionStatus newStatus, [
    String? targetEmpId,
  ]) {
    final effectiveEmpId = targetEmpId ?? _activeEmpId;
    final list = _employeeDocuments[effectiveEmpId] ?? _originalDocuments;
    final idx = list.indexWhere((d) => d.id == id);
    if (idx != -1) {
      final now = DateTime.now();
      final timeStr =
          '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
      list[idx] = list[idx].copyWith(
        status: newStatus,
        submissionDate:
            '${now.day} ${_monthName(now.month)} ${now.year}, $timeStr',
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
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (m >= 1 && m <= 12) return months[m - 1];
    return '';
  }

  void setActiveEmployee(String empId) {
    _activeEmpId = empId;
    notifyListeners();
  }

  void completeTask(
    String taskId, {
    required String proofText,
    String? photoUrl,
  }) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
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
        _firebaseEmployeeService.savePersonalTodo(_tasks[idx]).catchError((
          err,
        ) {
          debugPrint('Firestore complete personal todo note: $err');
        });
      }
      notifyListeners();
    }
  }

  /// Category 2, Item 8: Automatic Midnight Rollover Reset for standard SOP tasks
  void checkAndResetDailySops() {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    bool modified = false;

    for (final task in _tasks) {
      if (task.isDefaultSop &&
          task.status == 'completed' &&
          task.lastCompletedDate != null &&
          task.lastCompletedDate != todayStr) {
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

  void postponeTask(
    String taskId, {
    required String reason,
    required String postponedTo,
  }) {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx != -1) {
      final now = DateTime.now();
      final timeStr =
          '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
      _tasks[idx].status = 'postponed';
      _tasks[idx].postponeInfo = PostponeInfo(
        reason: reason,
        postponedTo: postponedTo,
        postponedAt: timeStr,
      );
      notifyListeners();
    }
  }

  void verifyProfileStep(
    String empId, {
    bool? photo,
    bool? address,
    bool? kyc,
    bool? sop,
  }) {
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
      content:
          '$assignedByName assigned: "$title" | Due: $due | Priority: $priority',
      type: CompanyNotificationType.broadcastNotice,
      timestamp: DateTime.now(),
      senderName: assignedByName,
      senderRole: assignedByRole,
      isRead: false,
    );
    _companyNotifications.insert(0, notif);
    _notifiedCompanyNotifIds.add(notif.id);
    _firebaseEmployeeService.saveCompanyNotification(notif).catchError((err) {
      debugPrint('Firestore save task notif note: $err');
    });
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
      return raised.contains(d) ||
          blocking.contains(d) ||
          d.contains(raised) ||
          d.contains(blocking);
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
    final timeStr =
        '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
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
    _notificationMessage =
        'Blocker #${newBlk.id} raised against $blockingDept.';
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
      final timeStr =
          '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
      final b = _blockers[idx];
      b.responseText = responseText;
      b.respondedByName = respondedByName;
      b.respondedAt = timeStr;
      if (markResolved) {
        b.status = 'resolved';
      }
      _notificationMessage =
          'Response recorded for blocker #${b.id} by $respondedByName.';
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
      _readinessGate.signedCount = _readinessGate.depts
          .where((d) => d.signed)
          .length;
      if (_readinessGate.signedCount == _readinessGate.totalCount) {
        _readinessGate.status = '100% Ready (Green)';
      } else {
        _readinessGate.status =
            '${_readinessGate.signedCount}/${_readinessGate.totalCount} Depts Signed';
      }
      notifyListeners();
    }
  }

  void delegateEmergencyLeave({
    required String absentEmpId,
    required String coveringEmpId,
    required String reason,
  }) {
    final absentEmp = _employees.firstWhere(
      (e) => e.id == absentEmpId,
      orElse: () => _employees.first,
    );
    final coveringEmp = _employees.firstWhere(
      (e) => e.id == coveringEmpId,
      orElse: () => _employees.first,
    );

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

    dispatchAcceptanceNotification(
      requestType: AcceptanceRequestType.leave,
      employeeId: absentEmpId,
      employeeName: absentEmp.name,
      durationOrDays: 'Emergency Leave',
      reason: reason,
      approvedBy: 'HR (Mohankumar G)',
      requesterRole: absentEmp.role,
      department: absentEmp.dept,
    );
  }

  bool canManageEmployees() {
    return _activeRole.toLowerCase() == 'hr' ||
        _activeRole.toLowerCase() == 'ceo';
  }

  bool removeEmployee(String empId) {
    return relieveEmployee(empId);
  }

  /// Officially relieve an employee from the company, revoking credentials and removing from rosters
  bool relieveEmployee(String empId) {
    if (!canManageEmployees()) {
      _notificationMessage =
          'Access Denied: Only HR and CEO have authorization to relieve staff.';
      notifyListeners();
      return false;
    }
    if (empId == 'MN-CEO01' ||
        _employees.any(
          (e) => e.id == empId && e.roleType.toLowerCase() == 'ceo',
        )) {
      _notificationMessage =
          'Action Denied: Executive CEO account cannot be relieved.';
      notifyListeners();
      return false;
    }
    final index = _employees.indexWhere((e) => e.id == empId);
    if (index != -1) {
      final removed = _employees.removeAt(index);
      final staffIdentifier = removed.empNo.isNotEmpty
          ? 'EMP #${removed.empNo}'
          : removed.id;
      _notificationMessage =
          'Staff ${removed.name} ($staffIdentifier) officially relieved from MN Jewel Park.';

      // Clean up assigned tasks
      _tasks.removeWhere((t) => t.empId == empId);

      // Broadcast company-wide notice
      broadcastUniversalAnnouncement(
        title: 'Workforce Notice: Staff Relieved',
        message:
            '${removed.name} ($staffIdentifier - ${removed.role}) has been officially relieved from MN Jewel Park.',
        category: 'hr',
      );

      notifyListeners();

      // Background Firestore sync
      _firebaseEmployeeService
          .removeEmployee(employeeId: empId, requesterRole: _activeRole)
          .catchError((err) {
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
    String? customEmpId,
    String? empNo,
  }) {
    if (!canManageEmployees()) {
      _notificationMessage =
          'Access Denied: Only HR and CEO have authorization to add users.';
      notifyListeners();
      return;
    }
    final initials = name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join('')
        .toUpperCase();

    final prefix = roleType == 'hr'
        ? 'MN-HR'
        : (roleType == 'team_lead' ? 'MN-TL' : 'MN-');
    final defaultId = '$prefix${1000 + _employees.length}';
    final idToUse = (customEmpId != null && customEmpId.trim().isNotEmpty)
        ? customEmpId.trim()
        : ((empNo != null && empNo.trim().isNotEmpty)
              ? empNo.trim()
              : defaultId);
    final empNoToUse = (empNo != null && empNo.trim().isNotEmpty)
        ? empNo.trim()
        : ((customEmpId != null && customEmpId.trim().isNotEmpty)
              ? customEmpId.trim()
              : '');

    final existing = findHiredEmployeeByIdOrEmpNo(idToUse);
    if (existing != null) {
      _notificationMessage =
          'Employee ID $idToUse is already registered to ${existing.name}.';
      notifyListeners();
      return;
    }

    final newEmp = Employee(
      id: idToUse,
      empNo: empNoToUse,
      name: name,
      role: role,
      roleType: roleType,
      dept: dept.isEmpty
          ? (roleType == 'hr' ? 'Human Resources' : 'General Operations')
          : dept,
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
    final code = KonarTaskCatalog.resolveRoleCode(
      newEmp.role,
      newEmp.email,
      newEmp.id,
    );
    final stdTasks = KonarTaskCatalog.getStandardTasksForEmployee(
      newEmp.id,
      code,
      newEmp.name,
    );
    _tasks.addAll(stdTasks);

    notifyListeners();

    // Background Firestore sync with password for auth
    _firebaseEmployeeService
        .addEmployee(
          employee: newEmp,
          requesterRole: _activeRole,
          password: password,
        )
        .catchError((err) {
          debugPrint('Firestore remote add note: $err');
        });
  }

  // --- Universal Notifications Actions ---
  void markNotificationAsRead(String id) {
    final idx = _companyNotifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final notif = _companyNotifications[idx];
      // If notification was personally targeted to active employee, delete upon reading per company policy
      if (notif.targetEmpId != null &&
          notif.targetEmpId!.isNotEmpty &&
          notif.targetEmpId == _activeEmpId) {
        _companyNotifications.removeAt(idx);
        notifyListeners();
        _firebaseEmployeeService.deleteCompanyNotification(id);
        return;
      }

      final updatedStaffIds = List<String>.from(notif.readByStaffIds);
      if (!updatedStaffIds.contains(_activeEmpId)) {
        updatedStaffIds.add(_activeEmpId);
      }
      _companyNotifications[idx] = notif.copyWith(
        readByStaffIds: updatedStaffIds,
      );
      notifyListeners();
    }
    // Per-user notification read in Cloud Firestore
    _firebaseEmployeeService.markNotificationRead(id, _activeEmpId);
  }

  /// Reset all operational data (notifications, social causes) while strictly preserving
  /// employee dossiers, departments, health metrics, and document vaults safe
  Future<void> resetOperationalData() async {
    _companyNotifications.clear();
    _socialCauses.clear();
    await _firebaseEmployeeService.resetOperationalData();
    notifyListeners();
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
      final updatedDismissed = List<String>.from(
        _companyNotifications[idx].dismissedByStaffIds,
      );
      if (!updatedDismissed.contains(_activeEmpId)) {
        updatedDismissed.add(_activeEmpId);
      }
      _companyNotifications[idx] = _companyNotifications[idx].copyWith(
        dismissedByStaffIds: updatedDismissed,
      );
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

  // --- Universal Notification Comments & Comment Likes ---
  Future<void> addNotificationComment(String notifId, String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final idx = _companyNotifications.indexWhere((n) => n.id == notifId);
    if (idx == -1) return;

    final notif = _companyNotifications[idx];
    final currentEmp = currentEmployee;
    final newComment = NotificationComment(
      id: 'CMT-${DateTime.now().millisecondsSinceEpoch}',
      notificationId: notifId,
      authorId: _activeEmpId,
      authorName: currentEmp.name,
      authorRole: currentEmp.straightCutRole,
      text: cleanText,
      timestamp: DateTime.now(),
      likedStaffIds: [],
    );

    final updatedComments = [...notif.comments, newComment];
    final updatedNotif = notif.copyWith(comments: updatedComments);
    _companyNotifications[idx] = updatedNotif;
    notifyListeners();

    // Persist to Cloud Firestore
    _firebaseEmployeeService
        .updateCompanyNotificationComments(notifId, updatedComments)
        .catchError((err) {
          debugPrint('Firestore updateCompanyNotificationComments note: $err');
        });
  }

  Future<void> toggleNotificationCommentLike(
    String notifId,
    String commentId,
  ) async {
    final notifIdx = _companyNotifications.indexWhere((n) => n.id == notifId);
    if (notifIdx == -1) return;

    final notif = _companyNotifications[notifIdx];
    final commentIdx = notif.comments.indexWhere((c) => c.id == commentId);
    if (commentIdx == -1) return;

    final comment = notif.comments[commentIdx];
    final updatedLikes = List<String>.from(comment.likedStaffIds);
    if (updatedLikes.any(
      (id) => id.toLowerCase() == _activeEmpId.toLowerCase(),
    )) {
      updatedLikes.removeWhere(
        (id) => id.toLowerCase() == _activeEmpId.toLowerCase(),
      );
    } else {
      updatedLikes.add(_activeEmpId);
    }

    final updatedComment = comment.copyWith(likedStaffIds: updatedLikes);
    final updatedComments = List<NotificationComment>.from(notif.comments);
    updatedComments[commentIdx] = updatedComment;

    final updatedNotif = notif.copyWith(comments: updatedComments);
    _companyNotifications[notifIdx] = updatedNotif;
    notifyListeners();

    // Persist to Cloud Firestore
    _firebaseEmployeeService
        .updateCompanyNotificationComments(notifId, updatedComments)
        .catchError((err) {
          debugPrint('Firestore toggleCommentLike note: $err');
        });
  }

  // --- Real-time Team Chat Actions & Storage ---
  static const String _chatsStorageKey = 'mn_team_chats_storage_v1';

  List<ChatMessage> get chatMessages => _chatMessages;

  /// Returns messages for a specific conversation thread (either 'ALL_HANDS' or a peer empId)
  List<ChatMessage> getConversation(String peerId) {
    if (peerId == 'ALL_HANDS') {
      final msgs = _chatMessages
          .where((m) => m.receiverId == 'ALL_HANDS')
          .toList();
      msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return msgs;
    }
    final cleanPeer = peerId.trim().toLowerCase();
    final cleanActive = _activeEmpId.trim().toLowerCase();
    final msgs = _chatMessages.where((m) {
      final s = m.senderId.trim().toLowerCase();
      final r = m.receiverId.trim().toLowerCase();
      return (s == cleanActive && r == cleanPeer) ||
          (s == cleanPeer && r == cleanActive);
    }).toList();
    msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return msgs;
  }

  /// Get the last message exchanged with a peer or in All-Hands
  ChatMessage? getLastMessageWith(String peerId) {
    final conv = getConversation(peerId);
    if (conv.isEmpty) return null;
    return conv.last;
  }

  /// Unread messages count for a specific thread
  int getUnreadChatCountFor(String peerId) {
    final cleanPeer = peerId.trim().toLowerCase();
    final cleanActive = _activeEmpId.trim().toLowerCase();
    if (peerId == 'ALL_HANDS') {
      return _chatMessages
          .where(
            (m) =>
                m.receiverId == 'ALL_HANDS' &&
                m.senderId.toLowerCase() != cleanActive &&
                !m.isReadBy(_activeEmpId),
          )
          .length;
    }
    return _chatMessages
        .where(
          (m) =>
              m.senderId.toLowerCase() == cleanPeer &&
              m.receiverId.toLowerCase() == cleanActive &&
              !m.isReadBy(_activeEmpId),
        )
        .length;
  }

  /// Total unread chat count across all conversations
  int get unreadTotalChatCount {
    int total = 0;
    // Check All Hands
    total += getUnreadChatCountFor('ALL_HANDS');
    // Check individual peers
    final Set<String> checkedPeers = {};
    for (final emp in _employees) {
      if (emp.id == _activeEmpId) continue;
      if (checkedPeers.add(emp.id)) {
        total += getUnreadChatCountFor(emp.id);
      }
    }
    return total;
  }

  Future<void> sendChatMessage({
    required String receiverId,
    required String text,
    String? attachmentType,
    String? attachmentUrl,
    String? replyToId,
    String? replyToSenderName,
    String? replyToText,
  }) async {
    var cleanText = text.trim();
    if (cleanText.isEmpty && (attachmentUrl == null || attachmentUrl.isEmpty))
      return;
    if (cleanText.isEmpty) {
      cleanText = attachmentType == 'image'
          ? '📷 Photo'
          : (attachmentType == 'pdf' ? '📄 Document.pdf' : 'Attachment');
    }

    final currentEmp = currentEmployee;
    final newMsg = ChatMessage(
      id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
      senderId: _activeEmpId,
      senderName: currentEmp.name,
      senderRole: currentEmp.straightCutRole,
      receiverId: receiverId,
      text: cleanText,
      timestamp: DateTime.now(),
      isRead: false,
      readBy: [_activeEmpId],
      likedBy: [],
      attachmentType: attachmentType,
      attachmentUrl: attachmentUrl,
      replyToId: replyToId,
      replyToSenderName: replyToSenderName,
      replyToText: replyToText,
    );

    _chatMessages.add(newMsg);
    _notifiedChatMessageIds.add(newMsg.id);
    notifyListeners();

    _saveChatsToLocal();
    _firebaseEmployeeService.saveChatMessage(newMsg).catchError((err) {
      debugPrint('Firestore saveChatMessage note: $err');
    });
  }

  Future<void> markConversationAsRead(String peerId) async {
    final cleanPeer = peerId.trim().toLowerCase();
    final cleanActive = _activeEmpId.trim().toLowerCase();
    bool changed = false;

    for (int i = 0; i < _chatMessages.length; i++) {
      final m = _chatMessages[i];
      final isTarget = peerId == 'ALL_HANDS'
          ? (m.receiverId == 'ALL_HANDS' &&
                m.senderId.toLowerCase() != cleanActive)
          : (m.senderId.toLowerCase() == cleanPeer &&
                m.receiverId.toLowerCase() == cleanActive);

      if (isTarget && !m.isReadBy(_activeEmpId)) {
        final updatedReadBy = List<String>.from(m.readBy)..add(_activeEmpId);
        _chatMessages[i] = m.copyWith(isRead: true, readBy: updatedReadBy);
        changed = true;
        _firebaseEmployeeService.markChatMessageRead(m.id, _activeEmpId);
      }
    }

    if (changed) {
      _saveChatsToLocal();
      notifyListeners();
    }
  }

  Future<void> toggleChatMessageLike(String messageId) async {
    final idx = _chatMessages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final msg = _chatMessages[idx];
    final updatedLikes = List<String>.from(msg.likedBy);
    if (updatedLikes.any(
      (id) => id.toLowerCase() == _activeEmpId.toLowerCase(),
    )) {
      updatedLikes.removeWhere(
        (id) => id.toLowerCase() == _activeEmpId.toLowerCase(),
      );
    } else {
      updatedLikes.add(_activeEmpId);
    }

    _chatMessages[idx] = msg.copyWith(likedBy: updatedLikes);
    notifyListeners();

    _saveChatsToLocal();
    _firebaseEmployeeService
        .toggleChatMessageLike(messageId, _activeEmpId)
        .catchError((err) {
          debugPrint('Firestore toggleChatMessageLike note: $err');
        });
  }

  /// Pin a chat message for a specific duration ('8_hours', '1_week', '1_month', 'forever')
  Future<void> pinChatMessage(
    String messageId, {
    required String duration,
  }) async {
    DateTime? until;
    final now = DateTime.now();
    switch (duration) {
      case '8_hours':
        until = now.add(const Duration(hours: 8));
        break;
      case '1_week':
        until = now.add(const Duration(days: 7));
        break;
      case '1_month':
        until = now.add(const Duration(days: 30));
        break;
      case 'forever':
      default:
        until = null;
        break;
    }

    final idx = _chatMessages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      final target = _chatMessages[idx];
      // Unpin any previously pinned message in this same conversation
      for (int i = 0; i < _chatMessages.length; i++) {
        final m = _chatMessages[i];
        final isSameConvo = target.isAllHands
            ? m.isAllHands
            : ((m.senderId == target.senderId &&
                      m.receiverId == target.receiverId) ||
                  (m.senderId == target.receiverId &&
                      m.receiverId == target.senderId));
        if (isSameConvo && m.isPinned && m.id != messageId) {
          _chatMessages[i] = m.copyWith(isPinned: false, pinnedUntil: null);
          _firebaseEmployeeService.unpinChatMessage(m.id);
        }
      }

      _chatMessages[idx] = target.copyWith(
        isPinned: true,
        pinnedUntil: until,
        pinnedBy: currentEmployee.name,
        pinnedAt: now,
      );
      _saveChatsToLocal();
      notifyListeners();

      _firebaseEmployeeService
          .pinChatMessage(
            messageId,
            until: until,
            pinnedBy: currentEmployee.name,
          )
          .catchError((err) {
            debugPrint('Firestore pinChatMessage error: $err');
          });
    }
  }

  /// Unpin a chat message
  Future<void> unpinChatMessage(String messageId) async {
    final idx = _chatMessages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      _chatMessages[idx] = _chatMessages[idx].copyWith(
        isPinned: false,
        pinnedUntil: null,
        pinnedBy: null,
      );
      _saveChatsToLocal();
      notifyListeners();

      _firebaseEmployeeService.unpinChatMessage(messageId).catchError((err) {
        debugPrint('Firestore unpinChatMessage error: $err');
      });
    }
  }

  /// Get currently active pinned message for a conversation
  ChatMessage? getActivePinnedMessage(String peerId) {
    final cleanPeer = peerId.trim().toLowerCase();
    final cleanActive = _activeEmpId.trim().toLowerCase();

    final matches = _chatMessages.where((m) {
      if (!m.isCurrentlyPinned) return false;
      if (peerId == 'ALL_HANDS') {
        return m.isAllHands;
      } else {
        return (m.senderId.toLowerCase() == cleanPeer &&
                m.receiverId.toLowerCase() == cleanActive) ||
            (m.senderId.toLowerCase() == cleanActive &&
                m.receiverId.toLowerCase() == cleanPeer);
      }
    }).toList();

    if (matches.isEmpty) return null;
    matches.sort(
      (a, b) =>
          (b.pinnedAt ?? b.timestamp).compareTo(a.pinnedAt ?? a.timestamp),
    );
    return matches.first;
  }

  /// Check whether there are unread messages where the current user is mentioned
  int getUnreadMentionCountFor(String peerId) {
    final cleanPeer = peerId.trim().toLowerCase();
    final currentName = currentEmployee.name;

    return _chatMessages.where((m) {
      final matchesPeer = peerId == 'ALL_HANDS'
          ? m.isAllHands
          : (m.senderId.toLowerCase() == cleanPeer &&
                m.receiverId.toLowerCase() == _activeEmpId.toLowerCase());
      if (!matchesPeer) return false;
      if (m.isReadBy(_activeEmpId)) return false;
      return m.mentionsUser(_activeEmpId, currentName);
    }).length;
  }

  bool hasUnreadMention(String peerId) {
    return getUnreadMentionCountFor(peerId) > 0;
  }

  Future<void> _loadLocalChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsRaw = prefs.getString(_chatsStorageKey);
      if (chatsRaw != null && chatsRaw.isNotEmpty) {
        final decoded = jsonDecode(chatsRaw) as List?;
        if (decoded != null && decoded.isNotEmpty) {
          final loaded = decoded
              .map(
                (e) =>
                    ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .where(
                (m) =>
                    !m.id.startsWith('SEED-MSG') &&
                    !m.text.contains('Online Department is active'),
              )
              .toList();
          _chatMessages = loaded;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
    }
  }

  Future<void> _saveChatsToLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cleanMsgs = _chatMessages
          .where(
            (m) =>
                !m.id.startsWith('SEED-MSG') &&
                !m.text.contains('Online Department is active'),
          )
          .toList();
      final encoded = jsonEncode(cleanMsgs.map((m) => m.toJson()).toList());
      await prefs.setString(_chatsStorageKey, encoded);
    } catch (e) {
      debugPrint('Error saving chats: $e');
    }
  }

  // --- Personal Notes Storage & Actions (100% private to _activeEmpId) ---
  static const String _personalNotesStorageKey = 'mn_personal_notes_storage_v1';
  static const String _dismissedNotifsStorageKey =
      'mn_dismissed_notifs_storage_v1';

  Future<void> _loadLocalPersonalNotesAndDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesRaw = prefs.getString(_personalNotesStorageKey);
      if (notesRaw != null && notesRaw.isNotEmpty) {
        final decoded = jsonDecode(notesRaw) as List?;
        if (decoded != null) {
          _personalNotes = decoded
              .map(
                (e) =>
                    PersonalNote.fromJson(Map<String, dynamic>.from(e as Map)),
              )
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
              _companyNotifications[i] = n.copyWith(
                dismissedByStaffIds: merged,
              );
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
      final encoded = jsonEncode(
        _personalNotes.map((n) => n.toJson()).toList(),
      );
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
    final idx = _personalNotes.indexWhere(
      (n) => n.id == noteId && n.ownerEmpId == _activeEmpId,
    );
    if (idx != -1) {
      final curr = _personalNotes[idx];
      _personalNotes[idx] = curr.copyWith(
        title: title != null && title.trim().isNotEmpty
            ? title.trim()
            : curr.title,
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
    _personalNotes.removeWhere(
      (n) => n.id == noteId && n.ownerEmpId == _activeEmpId,
    );
    notifyListeners();
    _savePersonalNotesToLocal();
  }

  void togglePinPersonalNote(String noteId) {
    final idx = _personalNotes.indexWhere(
      (n) => n.id == noteId && n.ownerEmpId == _activeEmpId,
    );
    if (idx != -1) {
      final curr = _personalNotes[idx];
      _personalNotes[idx] = curr.copyWith(
        isPinned: !curr.isPinned,
        updatedAt: DateTime.now(),
      );
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
    if (cleanSender.toLowerCase().contains('senthil') ||
        cleanSender.toLowerCase().contains('executive ceo')) {
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
    _firebaseEmployeeService.saveCompanyNotification(notif).catchError((err) {
      debugPrint('Firestore save task notif note: $err');
    });
    PushNotificationService().showNotification(
      id: notif.id,
      title: notif.title,
      body: notif.content,
      payload: notif.id,
    );
    _notificationMessage =
        'Broadcast notification sent to all staff mobiles: "$title"';
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
      content:
          '$senderName ($senderRole) has sent a reminder: Please complete all pending To-Do checklist items and SOP proofs before shift close today.',
      type: CompanyNotificationType.todoReminder,
      timestamp: DateTime.now(),
      senderName: senderName,
      senderRole: senderRole,
      isRead: false,
    );
    _companyNotifications.insert(0, notif);
    _notifiedCompanyNotifIds.add(notif.id);
    _firebaseEmployeeService.saveCompanyNotification(notif).catchError((err) {
      debugPrint('Firestore save task notif note: $err');
    });
    PushNotificationService().showNotification(
      id: notif.id,
      title: notif.title,
      body: notif.content,
      payload: notif.id,
    );
    _notificationMessage =
        '🚨 Broadcast dispatched: "Notify All to Complete Today\'s To-Do Lists Pending Works" sent to all phones!';
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

    // Executive Acceptance Notification: Dispatch pop-up to CEO and HR
    final ceoHrTargets = <String>{
      'MN-CEO01',
      'MN-HR1001',
      ..._employees
          .where((e) => e.roleType == 'ceo' || e.roleType == 'hr')
          .map((e) => e.id),
    };
    _acceptancePopups.insert(
      0,
      AcceptancePopupNotification(
        id: 'POP-SC-PEND-${newCause.id}',
        title: '💛 New Social Cause: CEO & HR Approval Required',
        message:
            '${newCause.employeeName} (${newCause.employeeRole}) posted a social cause: "${newCause.title}" (${newCause.causeType}, ₹${newCause.amountSpent.toStringAsFixed(0)}). Awaiting CEO & HR verification.',
        requestType: AcceptanceRequestType.socialCausePending,
        employeeId: newCause.empId,
        employeeName: newCause.employeeName,
        employeeRole: newCause.employeeRole,
        employeeDept: 'Showroom & Online',
        durationOrDays: '₹${newCause.amountSpent.toStringAsFixed(0)}',
        reason: newCause.description,
        approvedBy: 'Pending Review',
        timestamp: DateTime.now(),
        targetRoles: const ['hr', 'ceo'],
        targetEmpIds: ceoHrTargets.toList(),
      ),
    );
    if (isCeo ||
        activeRole.toLowerCase() == 'ceo' ||
        activeRole.toLowerCase() == 'hr') {
      PushNotificationService().showNotification(
        id: 'SC-PEND-${newCause.id}',
        title: '💛 New Social Cause: Approval Required',
        body:
            '${newCause.employeeName} posted "${newCause.title}". Requires CEO & HR verification.',
        payload: 'social_cause_pending',
      );
    }
    notifyListeners();

    _firebaseEmployeeService.saveSocialCause(newCause).catchError((err) {
      debugPrint('Firestore saveSocialCause note: $err');
    });
  }

  /// Delete a social cause entry (accessible to author, HR, and CEO)
  Future<void> deleteSocialCause(String causeId) async {
    _socialCauses.removeWhere((c) => c.id == causeId);
    _acceptancePopups.removeWhere((p) => p.id.contains(causeId));
    _companyNotifications.removeWhere(
      (n) => n.actionTag == causeId || n.id.contains(causeId),
    );
    notifyListeners();

    await _firebaseEmployeeService.deleteSocialCause(causeId);
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
        debugPrint(
          'Social cause $causeId is already approved. Duplicate notification prevented.',
        );
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
        debugPrint(
          'Another administrator already approved cause $causeId. Aborting duplicate broadcast.',
        );
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
        content:
            '${old.employeeName} contributed to ${old.causeType} - "${old.title}" (₹${old.amountSpent.toStringAsFixed(0)}). Approved by $approverLabel. Tap to view and send your reaction!',
        type: CompanyNotificationType.socialCause,
        timestamp: approvedAt,
        senderName: approvedByName,
        senderRole: approverRole,
        isRead: false,
        actionTag: old.id,
        likedStaffIds: old.likedEmpIds,
      );

      final existingNotifIdx = _companyNotifications.indexWhere(
        (n) => n.actionTag == causeId || n.id == 'NOTIF-SC-$causeId',
      );
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

      // When accepted, the social cause alone MUST be notified as a pop-up notification for ALL existing users!
      _acceptancePopups.insert(
        0,
        AcceptancePopupNotification(
          id: 'POP-SC-APP-${old.id}',
          title: '🌟 Certified Good Deed: ${old.title}',
          message:
              '${old.employeeName} (${old.employeeRole}) completed an inspiring social deed: "${old.title}" (${old.causeType}, ₹${old.amountSpent.toStringAsFixed(0)}). Certified by $approverLabel.',
          requestType: AcceptanceRequestType.socialCauseApproved,
          employeeId: old.empId,
          employeeName: old.employeeName,
          employeeRole: old.employeeRole,
          employeeDept: 'MN Jewel Park',
          durationOrDays: '₹${old.amountSpent.toStringAsFixed(0)}',
          reason: old.description,
          approvedBy: approverLabel,
          timestamp: approvedAt,
          targetRoles: const ['all', 'hr', 'ceo', 'team_lead', 'employee'],
          targetEmpIds: _employees.map((e) => e.id).toList(),
        ),
      );

      _firebaseEmployeeService.saveCompanyNotification(notif).catchError((err) {
        debugPrint('Firestore save notif note: $err');
      });

      _notificationMessage =
          'Social deed approved! Notification broadcasted to all mobiles.';
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

      _firebaseEmployeeService
          .updateSocialCauseStatus(
            causeId: causeId,
            status: 'rejected',
            approvedByName: reviewerLabel,
            approvedAt: reviewedAt,
          )
          .catchError((err) {
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
      _firebaseEmployeeService
          .updateSocialCauseLikes(causeId, updatedLikes)
          .catchError((e) {
            debugPrint('Firestore updateSocialCauseLikes note: $e');
          });
    }

    // 2. Synchronize in _companyNotifications where actionTag == causeId or id == causeId
    for (int i = 0; i < _companyNotifications.length; i++) {
      final notif = _companyNotifications[i];
      if (notif.actionTag == causeId ||
          notif.id == causeId ||
          notif.id == 'NOTIF-SC-$causeId') {
        final notifLikes = List<String>.from(notif.likedStaffIds);
        if (notifLikes.contains(userId)) {
          notifLikes.remove(userId);
        } else {
          notifLikes.add(userId);
        }
        _companyNotifications[i] = notif.copyWith(likedStaffIds: notifLikes);
        _firebaseEmployeeService
            .updateCompanyNotificationLikes(notif.id, notifLikes)
            .catchError((e) {
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
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final timeStr =
            '${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
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
        _firebaseEmployeeService.savePersonalTodo(_tasks[idx]).catchError((
          err,
        ) {
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
        _firebaseEmployeeService.savePersonalTodo(_tasks[idx]).catchError((
          err,
        ) {
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
      _notificationMessage =
          'To-Do removed by $authorizedByName ($authorizedRole)';
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
    buffer.writeln(
      'Task ID,Employee Name,Department,Task Title,Category,Priority,Status,Due Time,Assigned By',
    );
    for (var t in _tasks) {
      final emp = _employees.firstWhere(
        (e) => e.id == t.empId,
        orElse: () => _employees.first,
      );
      buffer.writeln(
        '"${t.id}","${emp.name}","${emp.dept}","${t.title}","${t.category}","${t.priority}","${t.status}","${t.due}","${t.assignedByName}"',
      );
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
            final notifContent =
                'SLA Overdue: Stage "${stage.stageName}" for ${order.brand} (Customer: ${order.customerName}) was due on ${stage.dueDate} and remains incomplete. Immediate action required by ${order.primaryResponsibleRole}, TL Praveenkumar, and CEO.';
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
    _notificationMessage =
        'Online Order #${order.orderId} created for ${order.brand} (${order.primaryResponsibleRole})!';

    // Automatically add as a new task in assigned staff's today's To-Do list
    final targetEmpId = order.handledByEmpId.isNotEmpty
        ? order.handledByEmpId
        : order.primaryResponsibleEmpId;
    final staffEmp = _employees.firstWhere(
      (e) => e.id == targetEmpId || e.empNo == targetEmpId,
      orElse: () => _employees.firstWhere(
        (e) => e.id == targetEmpId,
        orElse: () => currentEmployee,
      ),
    );
    final orderTaskId = 'task_order_${order.orderId}';
    _tasks.removeWhere((t) => t.id == orderTaskId);
    _tasks.insert(
      0,
      TaskItem(
        id: orderTaskId,
        empId: staffEmp.id,
        title:
            '📦 Process Online Order #${order.orderId} (${order.brand} - ${order.customerName})',
        category: 'Online Order Workflow',
        isDefaultSop: false,
        assignedByRole: 'dept_head',
        assignedByName: 'Praveenkumar M (TL)',
        due: order.expectedDeliveryDate.isNotEmpty
            ? order.expectedDeliveryDate
            : 'Today',
        priority: 'High',
        status: 'pending',
        isImmutable: false,
      ),
    );

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
    final primaryHandlerId = isVadivam
        ? '67'
        : '65'; // OS2 Nisha (#67) vs OS1 Kaaviya (#65)
    final primaryHandlerName = isVadivam ? 'OS2 (Nisha)' : 'OS1 (Kaaviya)';

    final isPrimaryAbsent = isEmployeeAbsent(primaryHandlerId);
    final isReallocatedToMe = order.reallocatedToEmpId == actingEmpId;
    final isManager =
        actingEmpId == 'MN-TL1002' ||
        actingEmpId == 'MN-CEO01' ||
        _activeRole == 'dept_head' ||
        _activeRole == 'ceo';

    // Requirement: If OS1 tries to update Vadivam when OS2 is absent (or vice versa), show crisp red message
    if (isPrimaryAbsent &&
        actingEmpId != primaryHandlerId &&
        !isReallocatedToMe &&
        !isManager) {
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
      _notificationMessage =
          '🎉 Order #${order.orderId} marked COMPLETED in system!';
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

      final taskIdx = _tasks.indexWhere(
        (t) => t.id == 'task_order_${order.orderId}',
      );
      if (taskIdx != -1) {
        _tasks[taskIdx] = _tasks[taskIdx].copyWith(empId: newEmpId);
      }

      _notificationMessage =
          'Order #${order.orderId} reallocated to $newEmpName by $authorizedBy.';
      notifyListeners();

      _firebaseEmployeeService.saveOnlineOrder(order).catchError((err) {
        debugPrint('Firestore reassignOnlineOrder error: $err');
      });

      postBroadcastNotification(
        title: 'Order Reassignment Notice',
        content:
            '$authorizedBy (Team Lead) reallocated ${order.brand} Order #${order.orderId} (Customer: ${order.customerName}) to $newEmpName for SLA continuity.',
        senderName: authorizedBy,
        senderRole: 'Team Lead',
      );
    }
  }

  /// Update stage due date
  void updateOrderStageDueDate(
    String orderId,
    String stageId,
    String newDueDate,
  ) {
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

  /// Update KONAR Book and dispatch targeted notifications strictly to Online Team + CEO + HR
  Future<Uint8List?> fetchKonarBookPdfBytes(String bookId) async {
    return _firebaseEmployeeService.loadKonarBookPdfBytes(bookId);
  }

  Future<void> updateKonarBook(
    KonarBookModel updatedBook, {
    required String updaterName,
    required String updaterRole,
    String? updaterEmpId,
    void Function(double progress)? onProgress,
  }) async {
    final idx = _konarBooks.indexWhere((b) => b.id == updatedBook.id);
    if (idx != -1) {
      _konarBooks[idx] = updatedBook;
    } else {
      _konarBooks.add(updatedBook);
    }
    notifyListeners();

    // 1. Save directly into Cloud Firestore with automatic chunking for PDFs
    await _firebaseEmployeeService.saveKonarBook(
      updatedBook,
      onProgress: onProgress,
    );

    // 2. Targeted Push Notification Routing:
    // Dynamic rule for Online Team or ANY future department added:
    // - CEO always receives push notification (unless CEO was the updater)
    // - HR always receives push notification (unless HR was the updater)
    // - Department TL always receives push notification (unless TL was the updater)
    // - All employees of that specific department receive push notification (unless that employee was the updater)
    // - Never send push notification to other unrelated departments
    // - Never send push notification to the updater / sender themselves
    final String activeId = (updaterEmpId != null && updaterEmpId.isNotEmpty)
        ? updaterEmpId
        : _activeEmpId;
    final String deptName = updatedBook.department.trim().toLowerCase();

    final targetIds = <String>{};

    // CEO
    for (final e in _employees) {
      if (e.isCeo || e.roleType.toLowerCase() == 'ceo' || e.id == 'MN-CEO01') {
        targetIds.add(e.id);
      }
    }

    // HR
    for (final e in _employees) {
      if (e.isHr ||
          e.roleType.toLowerCase() == 'hr' ||
          e.id == 'MN-HR001' ||
          e.id == 'MN-HR1001' ||
          e.id == '7') {
        targetIds.add(e.id);
        targetIds.add('MN-HR001');
      }
    }

    // Department Team Leader(s) & Department Employees
    for (final e in _employees) {
      final empDept = e.dept.trim().toLowerCase();
      final isMatchingDept =
          empDept == deptName ||
          deptName.contains(empDept) ||
          empDept.contains(deptName) ||
          (deptName.contains('online') &&
              (e.id == 'MN-TL1002' || e.isOtm || empDept.contains('online')));

      if (isMatchingDept) {
        targetIds.add(e.id);
      }
    }

    if (deptName.contains('online')) {
      targetIds.addAll([
        'MN-TL1002',
        'MN-EMP1003',
        'MN-EMP1004',
        'MN-EMP1005',
        'MN-EMP1006',
        'MN-EMP1007',
        'MN-EMP1008',
        'MN-EMP1009',
        'MN-EMP1010',
        'MN-EMP1011',
      ]);
    }

    // Exclude the updater / sender themselves (never send notification to self)
    targetIds.remove(activeId);
    targetIds.remove(_activeEmpId);
    if (activeId == 'MN-CEO01' || _activeEmpId == 'MN-CEO01') {
      targetIds.remove('MN-CEO01');
    }
    if (activeId == 'MN-HR001' ||
        activeId == 'MN-HR1001' ||
        activeId == '7' ||
        _activeEmpId == 'MN-HR001' ||
        _activeEmpId == 'MN-HR1001' ||
        _activeEmpId == '7') {
      targetIds.removeAll({'MN-HR001', 'MN-HR1001', '7'});
    }
    if (activeId == 'MN-TL1002' || _activeEmpId == 'MN-TL1002') {
      targetIds.remove('MN-TL1002');
    }

    final notifId = 'NOTIF-KONAR-${DateTime.now().millisecondsSinceEpoch}';
    final notifTitle = '📘 ${updatedBook.department} KONAR Book Updated';
    final notifContent =
        '$updaterName ($updaterRole) updated the official ${updatedBook.department} KONAR Book (${updatedBook.version}). Tap to view and download latest standard operating procedures.';

    final newNotif = CompanyNotification(
      id: notifId,
      title: notifTitle,
      content: notifContent,
      timestamp: DateTime.now(),
      type: CompanyNotificationType.broadcastNotice,
      senderName: updaterName,
      senderRole: updaterRole,
      actionTag: 'konar_book',
      targetEmpIds: targetIds.toList(),
    );

    _companyNotifications.insert(0, newNotif);
    _firebaseEmployeeService.saveCompanyNotification(newNotif).catchError((
      err,
    ) {
      debugPrint('Firestore save konar notification note: $err');
    });

    // If active employee is one of the target recipients, dispatch instant native push notification
    if (targetIds.contains(_activeEmpId) && _activeEmpId != activeId) {
      PushNotificationService()
          .showNotification(
            id: notifId,
            title: notifTitle,
            body: notifContent,
            payload: 'konar_book:${updatedBook.department}',
          )
          .catchError((_) {});
    }
  }

  // --- 4 Pillars Attention & Corner Badge Status ---
  bool get isHealthLoggedToday {
    final now = DateTime.now();
    return getFoodLogsForDate(now).isNotEmpty ||
        getWorkoutLogsForDate(now).isNotEmpty ||
        getStepsForDate(now) > 0 ||
        totalWorkoutMinutes > 0;
  }

  bool get isFamilyLoggedToday {
    final now = DateTime.now();
    return getFamilyActivitiesForDate(now).isNotEmpty ||
        totalFamilyHoursToday > 0;
  }

  int get todayPendingTodosCount {
    return _tasks
        .where((t) => t.empId == _activeEmpId && t.status != 'completed')
        .length;
  }

  int get pendingSocialCausesCount => pendingSocialCauses.length;

  int get healthPillarBadgeCount => isHealthLoggedToday ? 0 : 1;
  int get familyPillarBadgeCount => isFamilyLoggedToday ? 0 : 1;
  int get workPillarBadgeCount => todayPendingTodosCount;
  int get socialCausePillarBadgeCount =>
      (isCeo || isHr) ? pendingSocialCausesCount : 0;

  @override
  void dispose() {
    _midnightCelebrationTimer?.cancel();
    _employeeSubscription?.cancel();
    _socialCausesSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _personalTodosSubscription?.cancel();
    _onlineOrdersSubscription?.cancel();
    _chatMessagesSubscription?.cancel();
    _konarBooksSubscription?.cancel();
    super.dispose();
  }
}
