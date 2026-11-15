import 'dart:math';
import 'package:flutter/material.dart';

/// Attendance Status Types matching MN Jewel Park HR Master Excel
enum HrAttendanceDayType {
  present, // Normal / nil - fully present on duty (no remarks)
  late, // Yellow - l-1, l-2, l-3... (3 allowed/month)
  leaveCl, // Red - cl (Casual/Common Leave - 1/month)
  leaveLop, // Red - lop (Loss of Pay - 2nd day onwards)
  leaveHalfDay, // Red - 1/2 d (deducted from CL if available, else LOP)
  permission, // Green - 38m, 1:58m, 2h... (total 4.0 Hours quota)
  lateAndHalfDay, // Orange - l- & 1/2d (both late and half day leave)
  mnw, // Dark Blue - MNW (Official client/store visit outside)
  holiday, // Gray - H, O, L, I, D, A, Y (Sunday/Company Holiday)
  notApplicable, // - (Not joined yet)
  pendingUpdate, // Empty cell - awaiting HR update (sheet updated up to 14th)
}

/// Represents a single day's attendance record from the HR Sheet
class HrAttendanceDayRecord {
  final int day;
  final String rawValue;
  final HrAttendanceDayType type;
  final double permissionMinutes;
  final String displayLabel;

  HrAttendanceDayRecord({
    required this.day,
    required this.rawValue,
    required this.type,
    this.permissionMinutes = 0.0,
    required this.displayLabel,
  });

  Color get backgroundColor {
    switch (type) {
      case HrAttendanceDayType.late:
        return const Color(0xFFFEF9C3); // Soft Yellow
      case HrAttendanceDayType.leaveCl:
      case HrAttendanceDayType.leaveLop:
      case HrAttendanceDayType.leaveHalfDay:
        return const Color(0xFFFEE2E2); // Soft Red
      case HrAttendanceDayType.permission:
        return const Color(0xFFDCFCE7); // Soft Green
      case HrAttendanceDayType.lateAndHalfDay:
        return const Color(0xFFFFEDD5); // Soft Orange
      case HrAttendanceDayType.mnw:
        return const Color(0xFFDBEAFE); // Soft Dark Blue
      case HrAttendanceDayType.holiday:
        return const Color(0xFFF1F5F9); // Soft Gray
      case HrAttendanceDayType.notApplicable:
        return const Color(0xFFF8FAFC);
      case HrAttendanceDayType.pendingUpdate:
        return const Color(0xFFF8FAFC); // Neutral soft slate
      case HrAttendanceDayType.present:
        return Colors.white;
    }
  }

  Color get borderColor {
    switch (type) {
      case HrAttendanceDayType.late:
        return const Color(0xFFFACC15); // Yellow border
      case HrAttendanceDayType.leaveCl:
      case HrAttendanceDayType.leaveLop:
      case HrAttendanceDayType.leaveHalfDay:
        return const Color(0xFFF87171); // Red border
      case HrAttendanceDayType.permission:
        return const Color(0xFF4ADE80); // Green border
      case HrAttendanceDayType.lateAndHalfDay:
        return const Color(0xFFFB923C); // Orange border
      case HrAttendanceDayType.mnw:
        return const Color(0xFF3B82F6); // Dark Blue border
      case HrAttendanceDayType.holiday:
        return const Color(0xFFCBD5E1); // Gray border
      case HrAttendanceDayType.notApplicable:
        return const Color(0xFFE2E8F0);
      case HrAttendanceDayType.pendingUpdate:
        return const Color(0xFFE2E8F0); // Faint border
      case HrAttendanceDayType.present:
        return const Color(0xFFE2E8F0);
    }
  }

  Color get textColor {
    switch (type) {
      case HrAttendanceDayType.late:
        return const Color(0xFF854D0E); // Deep amber
      case HrAttendanceDayType.leaveCl:
      case HrAttendanceDayType.leaveLop:
      case HrAttendanceDayType.leaveHalfDay:
        return const Color(0xFF991B1B); // Deep red
      case HrAttendanceDayType.permission:
        return const Color(0xFF166534); // Deep green
      case HrAttendanceDayType.lateAndHalfDay:
        return const Color(0xFF9A3412); // Deep orange
      case HrAttendanceDayType.mnw:
        return const Color(0xFF1E40AF); // Deep blue
      case HrAttendanceDayType.holiday:
        return const Color(0xFF64748B); // Slate
      case HrAttendanceDayType.notApplicable:
        return const Color(0xFF94A3B8);
      case HrAttendanceDayType.pendingUpdate:
        return const Color(0xFF94A3B8); // Muted slate 400
      case HrAttendanceDayType.present:
        return const Color(0xFF0F172A);
    }
  }

  static HrAttendanceDayRecord parse(int day, String raw, {bool isColumnHoliday = false}) {
    final clean = raw.trim();
    final lower = clean.toLowerCase();

    // If whole column is a Sunday/Company Holiday across the showroom
    if (isColumnHoliday && (clean.isEmpty || RegExp(r'^[holiday]$', caseSensitive: false).hasMatch(clean))) {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw.isEmpty ? 'H' : raw,
        type: HrAttendanceDayType.holiday,
        displayLabel: 'Holiday (Sunday)',
      );
    }

    // Unrecorded / Empty cell (HR has only updated up to the 14th)
    if (clean.isEmpty) {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: '',
        type: HrAttendanceDayType.pendingUpdate,
        displayLabel: 'Pending HR Update',
      );
    }

    // Explicit NIL / nil -> Employee was present on duty (no remarks)
    if (lower == 'nil') {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.present,
        displayLabel: 'Present',
      );
    }

    if (lower == '-') {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.notApplicable,
        displayLabel: 'N/A',
      );
    }

    // Holiday letters (H, O, L, I, D, A, Y)
    if (RegExp(r'^[holiday]$', caseSensitive: false).hasMatch(clean)) {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.holiday,
        displayLabel: 'Holiday ($clean)',
      );
    }

    // Late & Half Day combined (Orange)
    if (lower.contains('1/2') && (lower.contains('l-') || lower.contains('late'))) {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.lateAndHalfDay,
        displayLabel: 'Late + Half Day',
      );
    }

    // Late coming (Yellow: l-1, l-2, l-3...)
    if (RegExp(r'^l-\d+$').hasMatch(lower) || lower == 'late') {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.late,
        displayLabel: clean.toUpperCase(),
      );
    }

    // Leaves (Red)
    if (lower == 'cl') {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.leaveCl,
        displayLabel: 'CL (Casual Leave)',
      );
    }
    if (lower == 'lop') {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.leaveLop,
        displayLabel: 'LOP (Loss of Pay)',
      );
    }
    if (lower == '1/2 d' || lower == '1/2d' || lower == 'half day') {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.leaveHalfDay,
        displayLabel: 'Half Day Leave',
      );
    }

    // MNW (Dark Blue)
    if (lower == 'mnw') {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.mnw,
        displayLabel: 'MNW (Official Duty)',
      );
    }

    // Permission (Green: 38 m, 1:58 m, 2 h, 4 h, etc.)
    final minutes = _parsePermissionMinutes(lower);
    if (minutes > 0) {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.permission,
        permissionMinutes: minutes,
        displayLabel: clean,
      );
    }

    // Default fallback
    return HrAttendanceDayRecord(
      day: day,
      rawValue: raw,
      type: HrAttendanceDayType.present,
      displayLabel: clean,
    );
  }

  static double _parsePermissionMinutes(String text) {
    // e.g. "1:58 m" or "1:58"
    final timeMatch = RegExp(r'^(\d+):(\d+)\s*(?:m|min)?$').firstMatch(text);
    if (timeMatch != null) {
      final h = int.tryParse(timeMatch.group(1)!) ?? 0;
      final m = int.tryParse(timeMatch.group(2)!) ?? 0;
      return (h * 60 + m).toDouble();
    }
    // e.g. "2 h", "4 h"
    final hourMatch = RegExp(r'^(\d+(?:\.\d+)?)\s*h(?:our|ours)?$').firstMatch(text);
    if (hourMatch != null) {
      final h = double.tryParse(hourMatch.group(1)!) ?? 0.0;
      return h * 60.0;
    }
    // e.g. "38 m", "47 m"
    final minMatch = RegExp(r'^(\d+)\s*m(?:in|ins)?$').firstMatch(text);
    if (minMatch != null) {
      return (double.tryParse(minMatch.group(1)!) ?? 0.0);
    }
    return 0.0;
  }
}

/// Represents one employee row in the HR Attendance Sheet
class HrEmployeeAttendanceRow {
  final int sNo;
  final String empNo;
  final String name;
  final Map<int, HrAttendanceDayRecord> days;

  HrEmployeeAttendanceRow({
    required this.sNo,
    required this.empNo,
    required this.name,
    required this.days,
  });

  // --- Summary Calculations ---

  /// Total late count (l-1, l-2, l-3...)
  int get lateCount => days.values.where((d) => d.type == HrAttendanceDayType.late || d.type == HrAttendanceDayType.lateAndHalfDay).length;

  /// Max allowed lates without penalty
  static const int maxAllowedLates = 3;

  /// Penalties incurred for excess lates (> 3)
  int get latePenaltyDays => max(0, lateCount - maxAllowedLates);

  /// Casual Leaves used (max 1/month)
  double get clDaysUsed {
    double count = 0;
    for (final d in days.values) {
      if (d.type == HrAttendanceDayType.leaveCl) {
        count += 1.0;
      } else if (d.type == HrAttendanceDayType.leaveHalfDay || d.type == HrAttendanceDayType.lateAndHalfDay) {
        if (count < 1.0) {
          count = min(1.0, count + 0.5);
        }
      }
    }
    return min(1.0, count);
  }

  /// Loss of pay days (explicit LOP + excess leaves beyond 1 CL)
  double get lopDaysUsed {
    double lops = 0;
    double clPool = 0;
    for (final d in days.values) {
      if (d.type == HrAttendanceDayType.leaveLop) {
        lops += 1.0;
      } else if (d.type == HrAttendanceDayType.leaveCl) {
        clPool += 1.0;
        if (clPool > 1.0) {
          lops += (clPool - 1.0);
          clPool = 1.0;
        }
      } else if (d.type == HrAttendanceDayType.leaveHalfDay || d.type == HrAttendanceDayType.lateAndHalfDay) {
        if (clPool < 1.0) {
          clPool += 0.5;
          if (clPool > 1.0) {
            lops += (clPool - 1.0);
            clPool = 1.0;
          }
        } else {
          lops += 0.5;
        }
      }
    }
    return lops;
  }

  /// Total permission minutes utilized this month
  double get totalPermissionMinutes {
    double mins = 0.0;
    for (final d in days.values) {
      if (d.type == HrAttendanceDayType.permission) {
        mins += d.permissionMinutes;
      }
    }
    return mins;
  }

  /// Total permission hours utilized
  double get totalPermissionHours => totalPermissionMinutes / 60.0;

  /// Standard monthly quota: 4.0 Hours
  static const double monthlyPermissionQuotaHours = 4.0;

  /// Remaining permission hours available this month
  double get remainingPermissionHours => max(0.0, monthlyPermissionQuotaHours - totalPermissionHours);

  /// Whether permission quota has been exceeded
  bool get isPermissionExceeded => totalPermissionHours > monthlyPermissionQuotaHours;

  /// Official work visits (MNW)
  int get mnwDaysCount => days.values.where((d) => d.type == HrAttendanceDayType.mnw).length;

  /// Full present on duty days (only days marked with 'nil')
  int get presentDaysCount => days.values.where((d) => d.type == HrAttendanceDayType.present).length;

  /// Days with records uploaded by HR
  int get recordedDaysCount => days.values.where((d) => d.type != HrAttendanceDayType.pendingUpdate).length;

  /// Days pending HR update
  int get pendingDaysCount => days.values.where((d) => d.type == HrAttendanceDayType.pendingUpdate).length;

  /// Human-friendly permission display e.g. "1h 58m"
  String get formattedPermissionUsed {
    final totalMins = totalPermissionMinutes.round();
    final h = totalMins ~/ 60;
    final m = totalMins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  /// Human-friendly remaining permission display
  String get formattedPermissionRemaining {
    final remMins = (remainingPermissionHours * 60).round();
    final h = remMins ~/ 60;
    final m = remMins % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }
}

/// Complete month attendance sheet result from Google Sheets
class HrMonthlyAttendanceSheet {
  final String monthTitle; // e.g. "NOVEMBER"
  final DateTime lastUpdated;
  final List<HrEmployeeAttendanceRow> rows;

  HrMonthlyAttendanceSheet({
    required this.monthTitle,
    required this.lastUpdated,
    required this.rows,
  });

  int get daysInMonth => 31;
  List<HrEmployeeAttendanceRow> get employees => rows;

  /// The highest day number with actual attendance records uploaded by HR
  int get latestRecordedDay {
    int maxDay = 0;
    for (final row in rows) {
      for (final entry in row.days.entries) {
        if (entry.value.type != HrAttendanceDayType.pendingUpdate &&
            entry.value.type != HrAttendanceDayType.holiday &&
            entry.value.type != HrAttendanceDayType.notApplicable) {
          if (entry.key > maxDay) {
            maxDay = entry.key;
          }
        }
      }
    }
    return maxDay > 0 ? maxDay : 14;
  }

  HrEmployeeAttendanceRow? findForEmployee({required String name, String? empNo}) {
    final cleanName = name.trim().toLowerCase();
    final cleanNo = empNo?.trim().toLowerCase();

    // 1. Try matching by EMP.NO
    if (cleanNo != null && cleanNo.isNotEmpty) {
      final matchNo = rows.where((r) => r.empNo.trim().toLowerCase() == cleanNo).toList();
      if (matchNo.isNotEmpty) return matchNo.first;
    }

    // 2. Try exact name match
    final exact = rows.where((r) => r.name.trim().toLowerCase() == cleanName).toList();
    if (exact.isNotEmpty) return exact.first;

    // 3. Try partial name match (e.g. "Gokulakrishnan K" vs "Gokulakrishnan")
    final partial = rows.where((r) {
      final rn = r.name.trim().toLowerCase();
      return cleanName.contains(rn) || rn.contains(cleanName);
    }).toList();
    if (partial.isNotEmpty) return partial.first;

    return null;
  }
}
