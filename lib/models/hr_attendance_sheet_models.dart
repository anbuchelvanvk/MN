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
  holiday, // Gray - H, O, L, I, D, A, Y (Tuesday/Company Holiday)
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
        return const Color(0xFFFEF9C3); // Soft Yellow
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
        return const Color(0xFFFACC15); // Yellow border
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
        return const Color(0xFFB45309); // Deep amber / yellow
      case HrAttendanceDayType.present:
        return const Color(0xFF0F172A);
    }
  }

  static HrAttendanceDayRecord parse(int day, String raw, {bool isColumnHoliday = false}) {
    final clean = raw.trim();
    final lower = clean.toLowerCase();

    // If whole column is a Tuesday/Company Holiday across the showroom
    if (isColumnHoliday && (clean.isEmpty || RegExp(r'^[holiday]$', caseSensitive: false).hasMatch(clean))) {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw.isEmpty ? 'H' : raw,
        type: HrAttendanceDayType.holiday,
        displayLabel: 'Holiday (Tuesday)',
      );
    }

    // Unrecorded / Empty cell (Attendance for the day not yet updated)
    if (clean.isEmpty) {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: '',
        type: HrAttendanceDayType.pendingUpdate,
        displayLabel: 'Yet to update',
      );
    }

    // Explicit NIL / nil -> Employee was present on duty (no remarks)
    if (lower == 'nil' || lower == 'p' || lower == 'present') {
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

    // Holiday check: column holiday, explicit holiday text, or holiday vertical letters
    if (lower == 'holiday' ||
        lower == 'tuesday' ||
        lower == 'tue' ||
        lower == 'sunday' ||
        lower == 'sun' ||
        lower == 'weekly off' ||
        lower == 'off' ||
        lower == 'h' ||
        (isColumnHoliday && RegExp(r'^[holiday]$', caseSensitive: false).hasMatch(clean))) {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.holiday,
        displayLabel: 'Holiday (Tuesday)',
      );
    }

    // Late & Half Day combined (Orange) - e.g. "l- & 1/2d", "l-1 1/2d", "late + half day"
    final isHalfDayText = lower.contains('1/2') || lower.contains('half') || lower.contains('0.5');
    final isLateText = lower.contains('l-') || lower.contains('late') || RegExp(r'\bl\s*[-:]?\s*\d+\b').hasMatch(lower);
    if (isHalfDayText && isLateText) {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.lateAndHalfDay,
        displayLabel: 'Late + Half Day',
      );
    }

    // Late coming (Yellow: l-1, l-2, l 1, l - 1, late-1...)
    final lateMatch = RegExp(r'^(?:l|late)\s*[-:]?\s*(\d+)$').firstMatch(lower);
    if (lateMatch != null || lower == 'late') {
      final lateNum = lateMatch?.group(1);
      final label = lateNum != null ? 'L-$lateNum' : clean.toUpperCase();
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.late,
        displayLabel: label,
      );
    }

    // Leaves (Red)
    if (lower == 'cl' || lower == 'c.l.' || lower == 'c/l' || lower == 'casual leave' || lower == 'l' || lower == 'leave') {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.leaveCl,
        displayLabel: 'CL (Casual Leave)',
      );
    }
    if (lower == 'lop' || lower == 'l.o.p.' || lower == 'loss of pay' || lower == 'a' || lower == 'absent') {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.leaveLop,
        displayLabel: lower == 'a' || lower == 'absent' ? 'Absent (LOP)' : 'LOP (Loss of Pay)',
      );
    }
    if (lower == '1/2 d' ||
        lower == '1/2d' ||
        lower == '1/2' ||
        lower == '1/2 day' ||
        lower == 'half day' ||
        lower == 'half-day' ||
        lower == 'halfday' ||
        lower == '0.5d' ||
        lower == '0.5' ||
        lower == '0.5 day') {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.leaveHalfDay,
        displayLabel: 'Half Day Leave',
      );
    }

    // MNW (Dark Blue)
    if (lower == 'mnw' ||
        lower == 'm.n.w' ||
        lower == 'mn work' ||
        lower == 'on duty' ||
        lower == 'od' ||
        lower == 'tour' ||
        lower == 'expo' ||
        lower == 'camp') {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.mnw,
        displayLabel: 'MNW (Official Duty)',
      );
    }

    // Work From Home (WFH)
    if (lower == 'wfh' || lower == 'work from home') {
      return HrAttendanceDayRecord(
        day: day,
        rawValue: raw,
        type: HrAttendanceDayType.present,
        displayLabel: 'WFH (Present)',
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

  static double _parsePermissionMinutes(String rawText) {
    var text = rawText.replaceAll(RegExp(r'[()[\]]'), '').trim();
    text = text.replaceFirst(RegExp(r'^(?:perm(?:ission)?|p)\s*[-:]?\s*'), '').trim();
    if (text.isEmpty) return 0.0;

    // 1. Composite: e.g. "1h 30m", "1 hr 30 mins", "2h 15m"
    final compositeMatch = RegExp(r'^(\d+)\s*h(?:our|ours|r|rs)?\s*(\d+)\s*m(?:in|ins|inute|inutes)?$').firstMatch(text);
    if (compositeMatch != null) {
      final h = int.tryParse(compositeMatch.group(1)!) ?? 0;
      final m = int.tryParse(compositeMatch.group(2)!) ?? 0;
      return (h * 60 + m).toDouble();
    }

    // 2. Colon formatted: e.g. "1:58 m" or "1:58"
    final timeMatch = RegExp(r'^(\d+):(\d+)\s*(?:m|min|mins)?$').firstMatch(text);
    if (timeMatch != null) {
      final h = int.tryParse(timeMatch.group(1)!) ?? 0;
      final m = int.tryParse(timeMatch.group(2)!) ?? 0;
      return (h * 60 + m).toDouble();
    }

    // 3. Hours: e.g. "2 h", "4 h", "1.5 hrs"
    final hourMatch = RegExp(r'^((?:\d*\.)?\d+)\s*h(?:our|ours|r|rs)?$').firstMatch(text);
    if (hourMatch != null) {
      final h = double.tryParse(hourMatch.group(1)!) ?? 0.0;
      return h * 60.0;
    }

    // 4. Minutes: e.g. "38 m", "47 m", "45 mins"
    final minMatch = RegExp(r'^(\d+)\s*m(?:in|ins|inute|inutes)?$').firstMatch(text);
    if (minMatch != null) {
      return (double.tryParse(minMatch.group(1)!) ?? 0.0);
    }
    return 0.0;
  }
}

/// Unassigned or assigned employee entry parsed directly from Google Sheets
class GoogleSheetEmployeeEntry {
  final int sNo;
  final String empNo;
  final String name;

  const GoogleSheetEmployeeEntry({
    required this.sNo,
    required this.empNo,
    required this.name,
  });
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
    final sortedDays = days.keys.toList()..sort();
    for (final day in sortedDays) {
      final d = days[day]!;
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
    final sortedDays = days.keys.toList()..sort();
    for (final day in sortedDays) {
      final d = days[day]!;
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
  /// Only active registered employees are exposed in app views (excluding unassigned roster entries)
  static const Set<String> activeEmpNos = {'6', '7', '33', '65', '67'};
  List<HrEmployeeAttendanceRow> get employees =>
      rows.where((r) => activeEmpNos.contains(r.empNo.trim())).toList();
  List<HrEmployeeAttendanceRow> get allSheetRows => rows;

  /// All non-empty employee entries present in the Google Sheet
  List<GoogleSheetEmployeeEntry> get allSheetStaff => rows
      .where((r) => r.empNo.trim().isNotEmpty && r.name.trim().isNotEmpty)
      .map((r) => GoogleSheetEmployeeEntry(
            sNo: r.sNo,
            empNo: r.empNo.trim(),
            name: r.name.trim(),
          ))
      .toList();

  /// Filters sheet rows for the active registered employees
  List<HrEmployeeAttendanceRow> getActiveRowsFor(Iterable<String> activeNos, Iterable<String> activeNames) {
    final cleanNos = activeNos.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    final cleanNames = activeNames.map((n) => n.trim().toLowerCase()).where((n) => n.isNotEmpty).toSet();
    return rows.where((r) {
      if (cleanNos.contains(r.empNo.trim())) return true;
      final rName = r.name.trim().toLowerCase();
      return cleanNames.any((cn) => cn == rName || cn.contains(rName) || rName.contains(cn));
    }).toList();
  }

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
    final cleanName = name.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    final cleanNo = empNo?.trim().toLowerCase();

    // 1. Try matching by EMP.NO (exact or normalized numeric digits)
    if (cleanNo != null && cleanNo.isNotEmpty) {
      final matchNo = rows.where((r) {
        final rNo = r.empNo.trim().toLowerCase();
        if (rNo == cleanNo) return true;
        final rDigits = rNo.replaceAll(RegExp(r'[^0-9]'), '');
        final cleanDigits = cleanNo.replaceAll(RegExp(r'[^0-9]'), '');
        if (rDigits.isNotEmpty && cleanDigits.isNotEmpty) {
          final intR = int.tryParse(rDigits);
          final intClean = int.tryParse(cleanDigits);
          if (intR != null && intClean != null && intR == intClean) return true;
        }
        return false;
      }).toList();
      if (matchNo.isNotEmpty) return matchNo.first;
    }

    // 2. Try exact name match (normalized spacing)
    final exact = rows.where((r) => r.name.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase() == cleanName).toList();
    if (exact.isNotEmpty) return exact.first;

    // 3. Try partial name match (e.g. "Gokulakrishnan K" vs "Gokulakrishnan")
    final partial = rows.where((r) {
      final rn = r.name.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
      return cleanName.contains(rn) || rn.contains(cleanName);
    }).toList();
    if (partial.isNotEmpty) return partial.first;

    return null;
  }
}
