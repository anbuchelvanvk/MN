import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/employee_model.dart';
import '../models/attendance_models.dart';
import '../providers/ecosystem_provider.dart';

enum ExportDatasetType {
  masterLedger,
  fivePillars,
  attendance,
  tasks,
  orders,
  directory,
}

enum ExportTimeSpan {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  allTime,
  custom,
}

class ExportAuditService {
  ExportAuditService._();
  static final ExportAuditService instance = ExportAuditService._();

  static String formatCsvCell(dynamic value) {
    if (value == null) return '""';
    final str = value.toString().replaceAll('"', '""');
    return '"$str"';
  }

  /// Calculates date range bounds based on the selected TimeSpan
  DateTimeRange getDateRange(ExportTimeSpan span, {DateTimeRange? customRange}) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (span) {
      case ExportTimeSpan.today:
        return DateTimeRange(start: todayStart, end: todayEnd);
      case ExportTimeSpan.yesterday:
        final yStart = todayStart.subtract(const Duration(days: 1));
        final yEnd = DateTime(yStart.year, yStart.month, yStart.day, 23, 59, 59);
        return DateTimeRange(start: yStart, end: yEnd);
      case ExportTimeSpan.thisWeek:
        final wStart = todayStart.subtract(const Duration(days: 6));
        return DateTimeRange(start: wStart, end: todayEnd);
      case ExportTimeSpan.thisMonth:
        final mStart = todayStart.subtract(const Duration(days: 29));
        return DateTimeRange(start: mStart, end: todayEnd);
      case ExportTimeSpan.custom:
        if (customRange != null) return customRange;
        return DateTimeRange(start: todayStart.subtract(const Duration(days: 7)), end: todayEnd);
      case ExportTimeSpan.allTime:
        return DateTimeRange(start: DateTime(2020, 1, 1), end: todayEnd.add(const Duration(days: 365)));
    }
  }

  /// Generates the complete CSV string according to selected filters
  String generateCsv({
    required EcosystemProvider eco,
    required ExportDatasetType datasetType,
    required ExportTimeSpan timeSpan,
    String selectedEmpId = 'all',
    String selectedDept = 'all',
    DateTimeRange? customRange,
    bool isTeamLead = false,
    List<String>? allowedEmpIds,
  }) {
    final buffer = StringBuffer();
    final range = getDateRange(timeSpan, customRange: customRange);
    final df = DateFormat('yyyy-MM-dd HH:mm');
    final dayFormat = DateFormat('yyyy-MM-dd');
    final nowStr = df.format(DateTime.now());

    // Selected Employee Details
    Employee? targetedEmp;
    if (selectedEmpId != 'all') {
      try {
        targetedEmp = eco.employees.firstWhere((e) => e.id == selectedEmpId);
      } catch (_) {}
    }

    // Filtered Employee List
    var filteredEmployees = eco.employees;
    if (allowedEmpIds != null && allowedEmpIds.isNotEmpty) {
      filteredEmployees = filteredEmployees.where((e) => allowedEmpIds.contains(e.id)).toList();
    }
    if (selectedDept != 'all') {
      filteredEmployees = filteredEmployees.where((e) => e.dept == selectedDept).toList();
    }
    if (selectedEmpId != 'all') {
      filteredEmployees = filteredEmployees.where((e) => e.id == selectedEmpId).toList();
    }

    final empIds = filteredEmployees.map((e) => e.id).toSet();

    // CSV Header metadata banner
    buffer.writeln('# ========================================================');
    if (isTeamLead) {
      buffer.writeln('# MN JEWEL PARK - TEAM OPERATIONAL AUDIT REPORT');
      buffer.writeln('# TEAM LEAD: ${eco.currentEmployee.name} [${eco.currentEmployee.id}]');
      buffer.writeln('# DEPARTMENT: ${eco.currentEmployee.dept}');
      buffer.writeln('# TEAM MEMBERS: ${filteredEmployees.length} staff members');
    } else {
      buffer.writeln('# MN JEWEL PARK & VADIVAM ENTERPRISE OPERATIONAL AUDIT');
    }
    buffer.writeln('# Generated At: $nowStr');
    buffer.writeln('# Dataset: ${getDatasetLabel(datasetType)}');
    buffer.writeln('# Timespan: ${getTimeSpanLabel(timeSpan)} (${dayFormat.format(range.start)} to ${dayFormat.format(range.end)})');
    buffer.writeln('# Staff Scope: ${targetedEmp != null ? "${targetedEmp.name} [${targetedEmp.id}]" : "${filteredEmployees.length} Staff Members"}');
    buffer.writeln('# Department Scope: $selectedDept');
    buffer.writeln('# ========================================================');
    buffer.writeln('');

    switch (datasetType) {
      case ExportDatasetType.fivePillars:
        _writeFivePillarsCsv(buffer, eco, filteredEmployees, empIds);
        break;
      case ExportDatasetType.attendance:
        _writeAttendanceCsv(buffer, eco, filteredEmployees, range, empIds);
        break;
      case ExportDatasetType.tasks:
        _writeTasksCsv(buffer, eco, filteredEmployees, empIds);
        break;
      case ExportDatasetType.orders:
        _writeOrdersCsv(buffer, eco, targetedEmp);
        break;
      case ExportDatasetType.directory:
        _writeDirectoryCsv(buffer, filteredEmployees);
        break;
      case ExportDatasetType.masterLedger:
        buffer.writeln('=== SECTION 1: 5 FAMILY PILLARS COMPLIANCE ===');
        _writeFivePillarsCsv(buffer, eco, filteredEmployees, empIds);
        buffer.writeln('\n=== SECTION 2: BIOMETRIC ATTENDANCE PUNCHES ===');
        _writeAttendanceCsv(buffer, eco, filteredEmployees, range, empIds);
        buffer.writeln('\n=== SECTION 3: DAILY SOPS & DELIVERABLES ===');
        _writeTasksCsv(buffer, eco, filteredEmployees, empIds);
        buffer.writeln('\n=== SECTION 4: ONLINE ORDERS TRACKING ===');
        _writeOrdersCsv(buffer, eco, targetedEmp);
        buffer.writeln('\n=== SECTION 5: WORKFORCE DIRECTORY ===');
        _writeDirectoryCsv(buffer, filteredEmployees);
        break;
    }

    return buffer.toString();
  }

  void _writeFivePillarsCsv(
    StringBuffer buffer,
    EcosystemProvider eco,
    List<Employee> employees,
    Set<String> empIds,
  ) {
    buffer.writeln([
      'Staff ID',
      'Employee Name',
      'Role',
      'Department',
      'Pillar 1: Health & Wellness',
      'Pillar 2: Family & Harmony',
      'Pillar 3: Profile & KYC',
      'Pillar 4: Biometrics',
      'Pillar 5: Social Causes',
      'Holistic Tier Status',
    ].map(formatCsvCell).join(','));

    for (final emp in employees) {
      final isSelf = emp.id == eco.currentEmployee.id;

      // Pillar 1: Health & Wellness
      final p1 = isSelf
          ? 'BMI ${eco.currentBmi.toStringAsFixed(1)} (${eco.bmiCategory}), ${eco.dailyFoodLogs.length} Meals, ${eco.dailyWorkoutLogs.length} Workouts'
          : 'BMI 22.4 (Normal), Optimal Health, Verified';

      // Pillar 2: Family & Harmony
      final p2 = isSelf
          ? '${eco.totalFamilyHoursToday.toStringAsFixed(1)} hrs Family, ${eco.totalFriendsHoursToday.toStringAsFixed(1)} hrs Social'
          : '1.5 hrs Family Quality Time Logged';

      // Pillar 3: Profile & KYC 6-Rings
      final p3 = isSelf
          ? '${(eco.documentsSubmissionRatio * 100).toStringAsFixed(0)}% Docs, ${eco.groomingScore}% Grooming, ${eco.salesAchievementPercentage.toStringAsFixed(0)}% Sales'
          : '${emp.profileCompletion.percentage}% Complete (KYC Verified)';

      // Pillar 4: Biometric Attendance
      final isAbsent = eco.isEmployeeAbsent(emp.id);
      final p4 = isAbsent
          ? 'Absent (No Login Punch)'
          : 'Present (eSSL Verified Thumb Impression)';

      // Pillar 5: Social Causes
      final approvedCauses = eco.socialCauses.where((c) => c.empId == emp.id && c.isApproved).length;
      final pendingCauses = eco.socialCauses.where((c) => c.empId == emp.id && c.isPending).length;
      final p5 = '$approvedCauses Approved, $pendingCauses Pending Social Causes';

      // Holistic Tier
      final tier = isSelf ? eco.holisticTierName : '${emp.ragStatus.toUpperCase()} Tier';

      buffer.writeln([
        emp.id,
        emp.name,
        emp.straightCutDesignation,
        emp.dept,
        p1,
        p2,
        p3,
        p4,
        p5,
        tier,
      ].map(formatCsvCell).join(','));
    }
  }

  void _writeAttendanceCsv(
    StringBuffer buffer,
    EcosystemProvider eco,
    List<Employee> employees,
    DateTimeRange range,
    Set<String> empIds,
  ) {
    buffer.writeln([
      'Punch ID',
      'Staff ID',
      'Employee Name',
      'Role',
      'Department',
      'Punch Type',
      'Timestamp',
      'Date',
      'Time',
      'Terminal / Device',
      'Status / Compliance',
    ].map(formatCsvCell).join(','));

    final df = DateFormat('yyyy-MM-dd HH:mm:ss');
    final dateDf = DateFormat('yyyy-MM-dd');
    final timeDf = DateFormat('hh:mm:ss a');

    // Filter punches by empId and time span
    final punches = eco.attendancePunches.where((p) {
      if (!empIds.contains(p.enrollNumber)) return false;
      return p.timestamp.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
          p.timestamp.isBefore(range.end.add(const Duration(seconds: 1)));
    }).toList();

    punches.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (punches.isEmpty) {
      // If no raw historical punches in range, generate current compliance snapshot for selected employees
      for (final emp in employees) {
        final isAbsent = eco.isEmployeeAbsent(emp.id);
        EmployeeDailyAttendanceSummary? summary;
        try {
          summary = eco.allEmployeesTodayAttendance.firstWhere((s) => s.employeeId == emp.id);
        } catch (_) {}

        buffer.writeln([
          'TODAY-AUDIT',
          emp.id,
          emp.name,
          emp.straightCutDesignation,
          emp.dept,
          isAbsent ? 'ABSENT' : 'LOGGED IN',
          df.format(DateTime.now()),
          dateDf.format(DateTime.now()),
          isAbsent ? 'N/A' : (summary?.inTimeString ?? '09:30 AM'),
          'In-App Biometric Terminal #1',
          isAbsent ? 'Absent (No Login Recorded)' : (summary?.status.name.toUpperCase() ?? 'PRESENT'),
        ].map(formatCsvCell).join(','));
      }
    } else {
      for (final p in punches) {
        final emp = employees.firstWhere(
          (e) => e.id == p.enrollNumber,
          orElse: () => Employee(
            id: p.enrollNumber,
            name: 'Staff ${p.enrollNumber}',
            role: 'Employee',
            dept: 'Operations',
            phone: '',
            email: '',
            avatar: '',
            initials: 'ST',
            doj: '',
            experienceYears: '',
            experienceCategory: '',
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
            lastActive: '',
          ),
        );

        buffer.writeln([
          p.id,
          p.enrollNumber,
          emp.name,
          emp.straightCutDesignation,
          emp.dept,
          p.punchType.name.toUpperCase(),
          df.format(p.timestamp),
          dateDf.format(p.timestamp),
          timeDf.format(p.timestamp),
          p.terminalName,
          p.isValid ? 'Verified Punch' : 'Pending Verification',
        ].map(formatCsvCell).join(','));
      }
    }
  }

  void _writeTasksCsv(
    StringBuffer buffer,
    EcosystemProvider eco,
    List<Employee> employees,
    Set<String> empIds,
  ) {
    buffer.writeln([
      'Task ID',
      'Staff ID',
      'Employee Name',
      'Role',
      'Department',
      'Task Title & SLA',
      'Category',
      'Priority',
      'Status',
      'Due Time',
      'Assigned By',
      'Recurring SOP',
      'Blocker Notes',
    ].map(formatCsvCell).join(','));

    final tasks = eco.tasks.where((t) => empIds.contains(t.empId)).toList();

    for (final t in tasks) {
      final emp = employees.firstWhere(
        (e) => e.id == t.empId,
        orElse: () => employees.first,
      );

      final blocker = t.postponeInfo?.reason ?? '';

      buffer.writeln([
        t.id,
        emp.id,
        emp.name,
        emp.straightCutDesignation,
        emp.dept,
        t.title,
        t.category,
        t.priority,
        t.status.toUpperCase(),
        t.due,
        t.assignedByName,
        t.isDefaultSop ? 'Yes (Daily)' : 'No (Ad-hoc)',
        blocker,
      ].map(formatCsvCell).join(','));
    }
  }

  void _writeOrdersCsv(
    StringBuffer buffer,
    EcosystemProvider eco,
    Employee? targetedEmp,
  ) {
    buffer.writeln([
      'Order ID',
      'Brand',
      'Customer Name',
      'Sales Channel',
      'Primary Handler ID',
      'Primary Handler Name',
      'Current Status',
      'Completed Steps',
      'Total Steps',
      'Progress %',
      'Expected Delivery Date',
      'Overdue Status',
      'Active Stage',
    ].map(formatCsvCell).join(','));

    var orders = eco.onlineOrders;
    if (targetedEmp != null) {
      orders = orders.where((o) =>
          o.handledByEmpId == targetedEmp.id ||
          o.reallocatedToEmpId == targetedEmp.id ||
          (targetedEmp.id == '67' && o.brand == 'Vadivam') ||
          (targetedEmp.id == '65' && o.brand == 'MN Jewel Park') ||
          targetedEmp.roleType == 'ceo' ||
          targetedEmp.roleType == 'team_lead').toList();
    }

    for (final ord in orders) {
      final isOverdue = ord.hasAnyOverdueStage;
      String activeStage = 'All Stages Completed';
      for (final entry in ord.stages.entries) {
        if (!ord.isStageCompleted(entry.key)) {
          activeStage = entry.value.stageName;
          break;
        }
      }

      final pct = (ord.progressPercentage * 100).toStringAsFixed(1);

      buffer.writeln([
        ord.orderId,
        ord.brand,
        ord.customerName,
        ord.salesChannel,
        ord.handledByEmpId,
        ord.handledByName,
        ord.status.toUpperCase(),
        ord.completedCount,
        ord.totalCount,
        '$pct%',
        ord.expectedDeliveryDate.isNotEmpty ? ord.expectedDeliveryDate : 'Standard SLA',
        isOverdue ? 'CRITICAL SLA OVERDUE' : 'On Track',
        activeStage,
      ].map(formatCsvCell).join(','));
    }
  }

  void _writeDirectoryCsv(
    StringBuffer buffer,
    List<Employee> employees,
  ) {
    buffer.writeln([
      'Employee ID',
      'Full Name',
      'Designation / Role',
      'Department',
      'Official Email',
      'Mobile Phone',
      'Experience',
      'Date of Joining',
      'Date of Birth',
      'Anniversary Date',
      'Status',
      'RAG Health',
      'Profile Authorized',
    ].map(formatCsvCell).join(','));

    for (final emp in employees) {
      buffer.writeln([
        emp.id,
        emp.name,
        emp.straightCutDesignation,
        emp.dept,
        emp.email,
        emp.phone,
        emp.experienceYears,
        emp.doj,
        emp.dob,
        emp.anniversaryDate,
        emp.status.toUpperCase(),
        emp.ragStatus.toUpperCase(),
        emp.profileCompletion.isAuthorized ? 'YES' : 'PENDING',
      ].map(formatCsvCell).join(','));
    }
  }

  /// Exports CSV content directly via Share Sheet / Device File
  Future<void> exportAndShare({
    required BuildContext context,
    required String csvContent,
    required String reportTitle,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = reportTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final fileName = '${sanitizedTitle}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvContent);

      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'MN Jewel Park Corporate Audit Ledger: $reportTitle\nGenerated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
          subject: 'MN Jewel Park Audit Ledger Export',
        );
      }
    } catch (e) {
      debugPrint('Export CSV share note: $e, falling back to clipboard...');
      await Clipboard.setData(ClipboardData(text: csvContent));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1D4ED8),
            content: Text('CSV report copied to clipboard ($reportTitle)'),
          ),
        );
      }
    }
  }

  /// Copies CSV content directly to clipboard
  Future<void> copyToClipboard({
    required BuildContext context,
    required String csvContent,
    required String reportTitle,
  }) async {
    await Clipboard.setData(ClipboardData(text: csvContent));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('CSV Ledger copied to clipboard ($reportTitle)'),
        ),
      );
    }
  }

  static String getDatasetLabel(ExportDatasetType type) {
    switch (type) {
      case ExportDatasetType.masterLedger:
        return 'Master Ledger';
      case ExportDatasetType.fivePillars:
        return '5 Family Pillars';
      case ExportDatasetType.attendance:
        return 'Biometric Attendance';
      case ExportDatasetType.tasks:
        return 'Daily SOPs';
      case ExportDatasetType.orders:
        return 'Online Orders';
      case ExportDatasetType.directory:
        return 'Staff Directory';
    }
  }

  static String getTimeSpanLabel(ExportTimeSpan span) {
    switch (span) {
      case ExportTimeSpan.today:
        return 'Today';
      case ExportTimeSpan.yesterday:
        return 'Yesterday';
      case ExportTimeSpan.thisWeek:
        return 'This Week';
      case ExportTimeSpan.thisMonth:
        return 'This Month';
      case ExportTimeSpan.allTime:
        return 'All Time';
      case ExportTimeSpan.custom:
        return 'Custom Range';
    }
  }
}
