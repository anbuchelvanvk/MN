import 'package:flutter/material.dart';

/// Punch type corresponding to eSSL biometric event state
enum AttendancePunchType {
  login,     // Check-In (eSSL AttState = 0)
  logout,    // Check-Out (eSSL AttState = 1)
  breakOut,  // Break-Out (eSSL AttState = 2)
  breakIn,   // Break-In (eSSL AttState = 3)
}

/// Verification mode supported by eSSL / ZKTeco device
enum AttendanceVerifyMethod {
  thumbImpression, // Fingerprint / Thumb (VerifyMethod = 1)
  face,            // Facial Biometric (VerifyMethod = 4)
  rfidCard,        // RFID Smart Card (VerifyMethod = 3)
  pin,             // Security PIN (VerifyMethod = 2)
}

/// Single punch record from eSSL biometric terminal
class AttendancePunchRecord {
  final String id;
  final String enrollNumber; // Staff ID (e.g. 'MN-1024')
  final DateTime timestamp;
  final AttendancePunchType punchType;
  final AttendanceVerifyMethod verifyMethod;
  final String terminalIp;
  final String terminalName;
  final int workCode;
  final bool isValid;

  AttendancePunchRecord({
    required this.id,
    required this.enrollNumber,
    required this.timestamp,
    required this.punchType,
    this.verifyMethod = AttendanceVerifyMethod.thumbImpression,
    this.terminalIp = '192.168.1.201:4370',
    this.terminalName = 'In-App Attendance Terminal #1',
    this.workCode = 0,
    this.isValid = true,
  });

  factory AttendancePunchRecord.fromJson(Map<String, dynamic> json) {
    AttendancePunchType type;
    final typeStr = json['punchType']?.toString().toLowerCase() ?? '';
    if (typeStr.contains('logout')) {
      type = AttendancePunchType.logout;
    } else if (typeStr.contains('breakout')) {
      type = AttendancePunchType.breakOut;
    } else if (typeStr.contains('breakin')) {
      type = AttendancePunchType.breakIn;
    } else {
      type = AttendancePunchType.login;
    }

    AttendanceVerifyMethod method;
    final methodStr = json['verifyMethod']?.toString().toLowerCase() ?? '';
    if (methodStr.contains('face')) {
      method = AttendanceVerifyMethod.face;
    } else if (methodStr.contains('card') || methodStr.contains('rfid')) {
      method = AttendanceVerifyMethod.rfidCard;
    } else if (methodStr.contains('pin')) {
      method = AttendanceVerifyMethod.pin;
    } else {
      method = AttendanceVerifyMethod.thumbImpression;
    }

    return AttendancePunchRecord(
      id: json['id']?.toString() ?? 'PUNCH-${DateTime.now().millisecondsSinceEpoch}',
      enrollNumber: json['enrollNumber']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      punchType: type,
      verifyMethod: method,
      terminalIp: json['terminalIp']?.toString() ?? '192.168.1.201:4370',
      terminalName: json['terminalName']?.toString() ?? 'In-App Attendance Terminal #1',
      workCode: json['workCode'] is int ? json['workCode'] : 0,
      isValid: json['isValid'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enrollNumber': enrollNumber,
      'timestamp': timestamp.toIso8601String(),
      'punchType': punchType.name,
      'verifyMethod': verifyMethod.name,
      'terminalIp': terminalIp,
      'terminalName': terminalName,
      'workCode': workCode,
      'isValid': isValid,
    };
  }

  String get timeString {
    final h = timestamp.hour;
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final formattedH = (h % 12 == 0 ? 12 : h % 12).toString().padLeft(2, '0');
    return '$formattedH:$m:$s $period';
  }

  String get dateString {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year}';
  }

  String get punchTypeLabel {
    switch (punchType) {
      case AttendancePunchType.login:
        return 'Work Login (Check-In)';
      case AttendancePunchType.logout:
        return 'Work Logout (Check-Out)';
      case AttendancePunchType.breakOut:
        return 'Break Out';
      case AttendancePunchType.breakIn:
        return 'Break In';
    }
  }

  Color get punchColor {
    switch (punchType) {
      case AttendancePunchType.login:
        return const Color(0xFF10B981); // Emerald Green
      case AttendancePunchType.logout:
        return const Color(0xFFEF4444); // Red
      case AttendancePunchType.breakOut:
        return const Color(0xFFF59E0B); // Amber
      case AttendancePunchType.breakIn:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  String get verifyMethodLabel {
    switch (verifyMethod) {
      case AttendanceVerifyMethod.thumbImpression:
        return 'Thumb Impression (Biometric)';
      case AttendanceVerifyMethod.face:
        return 'Facial Scan (AI Biometric)';
      case AttendanceVerifyMethod.rfidCard:
        return 'RFID Smart Badge';
      case AttendanceVerifyMethod.pin:
        return 'Security PIN';
    }
  }

  String get verifyMethodIcon {
    switch (verifyMethod) {
      case AttendanceVerifyMethod.thumbImpression:
        return '🫆';
      case AttendanceVerifyMethod.face:
        return '👤';
      case AttendanceVerifyMethod.rfidCard:
        return '🪪';
      case AttendanceVerifyMethod.pin:
        return '🔢';
    }
  }
}

/// Overall daily attendance compliance status
enum DailyAttendanceStatus {
  presentOnTime, // Logged in on or before shift start (Green)
  lateLogin,     // Logged in after shift start (Yellow)
  absent,        // No thumb login recorded (Red)
  onDuty,        // Currently working shift
  completed,     // Completed full shift and logged out
}

/// eSSL Hardware Device Live Configuration & State
class EsslDeviceConfig {
  final String deviceIp;
  final int port;
  final int machineNumber;
  final String modelName;
  final String firmwareVersion;
  final bool isConnected;
  final DateTime lastSyncTime;
  final int totalDeviceLogs;

  const EsslDeviceConfig({
    this.deviceIp = '192.168.1.201',
    this.port = 4370,
    this.machineNumber = 1,
    this.modelName = 'eSSL Security Optical Biometric Reader (TFT Series)',
    this.firmwareVersion = 'Ver 6.60 / ZK-TFT',
    this.isConnected = true,
    required this.lastSyncTime,
    this.totalDeviceLogs = 1428,
  });

  EsslDeviceConfig copyWith({
    String? deviceIp,
    int? port,
    int? machineNumber,
    String? modelName,
    String? firmwareVersion,
    bool? isConnected,
    DateTime? lastSyncTime,
    int? totalDeviceLogs,
  }) {
    return EsslDeviceConfig(
      deviceIp: deviceIp ?? this.deviceIp,
      port: port ?? this.port,
      machineNumber: machineNumber ?? this.machineNumber,
      modelName: modelName ?? this.modelName,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      isConnected: isConnected ?? this.isConnected,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      totalDeviceLogs: totalDeviceLogs ?? this.totalDeviceLogs,
    );
  }
}

/// Daily Attendance Summary for an employee (used by CEO, HR & Executive dashboards)
class EmployeeDailyAttendanceSummary {
  final String employeeId;
  final String employeeName;
  final String department;
  final String role;
  final String avatar;
  final String initials;
  final AttendancePunchRecord? loginPunch;
  final AttendancePunchRecord? logoutPunch;
  final AttendancePunchRecord? lunchOutPunch;
  final AttendancePunchRecord? lunchInPunch;
  final bool isPresent;
  final bool isOnTime;
  final bool isCurrentlyOnLunch;
  final bool isCurrentlyOnDuty;
  final int lunchDurationMinutes;
  final double netWorkHours;
  final DailyAttendanceStatus status;

  EmployeeDailyAttendanceSummary({
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.role,
    required this.avatar,
    required this.initials,
    this.loginPunch,
    this.logoutPunch,
    this.lunchOutPunch,
    this.lunchInPunch,
    required this.isPresent,
    required this.isOnTime,
    required this.isCurrentlyOnLunch,
    required this.isCurrentlyOnDuty,
    required this.lunchDurationMinutes,
    required this.netWorkHours,
    required this.status,
  });

  String get inTimeString => loginPunch?.timeString ?? '--:-- --';
  String get outTimeString => logoutPunch?.timeString ?? (isCurrentlyOnDuty ? 'On Duty' : '--:-- --');
  String get lunchOutTimeString => lunchOutPunch?.timeString ?? '--:-- --';
  String get lunchInTimeString => lunchInPunch?.timeString ?? '--:-- --';

  String get lunchSummary {
    if (lunchOutPunch == null) return 'No Break Taken';
    if (lunchInPunch == null) return 'On Lunch (${lunchOutPunch!.timeString})';
    return '${lunchOutPunch!.timeString} - ${lunchInPunch!.timeString} (${lunchDurationMinutes}m)';
  }

  String get workHoursFormatted {
    if (!isPresent) return '0h 0m';
    final h = netWorkHours.floor();
    final m = ((netWorkHours - h) * 60).round();
    return '${h}h ${m}m';
  }

  bool get isLeftEarly => logoutPunch != null && netWorkHours < 8.0;

  String get statusBadgeText {
    if (!isPresent) return 'Absent';
    if (isCurrentlyOnLunch) return 'On Lunch';
    if (logoutPunch != null) {
      return isLeftEarly ? 'Left Early' : 'Shift Over';
    }
    if (isOnTime) return 'On Duty';
    return 'Late In';
  }

  Color get statusBadgeColor {
    if (!isPresent) return const Color(0xFFEF4444);
    if (isCurrentlyOnLunch) return const Color(0xFF3B82F6);
    if (logoutPunch != null) {
      return isLeftEarly ? const Color(0xFFF59E0B) : const Color(0xFF8B5CF6);
    }
    if (isOnTime) return const Color(0xFF10B981);
    return const Color(0xFFEAB308);
  }
}

/// A day's activity record for the employee 7-day performance self-review table
class EmployeeActivityDayRecord {
  final DateTime date;
  final String dateLabel;
  final String loginTime;
  final String logoutTime;
  final String lunchOutTime;
  final String lunchInTime;
  final String netHours;
  final String status;
  final Color statusColor;
  final bool isOvertime;
  final bool isWeekoff;

  EmployeeActivityDayRecord({
    required this.date,
    required this.dateLabel,
    required this.loginTime,
    required this.logoutTime,
    required this.lunchOutTime,
    required this.lunchInTime,
    required this.netHours,
    required this.status,
    required this.statusColor,
    this.isOvertime = false,
    this.isWeekoff = false,
  });
}


