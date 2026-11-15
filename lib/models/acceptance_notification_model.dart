import 'package:flutter/material.dart';

/// Categories of requests that trigger executive acceptance notifications
enum AcceptanceRequestType {
  permission,
  leave,
  socialCausePending,
  socialCauseApproved,
}

/// Represents an official acceptance notification dispatched to HR, CEO, and Team Lead (TL)
class AcceptancePopupNotification {
  final String id;
  final String title;
  final String message;
  final AcceptanceRequestType requestType;
  final String employeeId;
  final String employeeName;
  final String employeeRole;
  final String employeeDept;
  final String durationOrDays;
  final String reason;
  final String approvedBy;
  final DateTime timestamp;
  final List<String> targetRoles; // ['hr', 'ceo', 'team_lead', 'all']
  final List<String> targetEmpIds; // list of empIds that must be notified
  final Set<String> acknowledgedByEmpIds;

  AcceptancePopupNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.requestType,
    required this.employeeId,
    required this.employeeName,
    required this.employeeRole,
    this.employeeDept = 'Online Department',
    required this.durationOrDays,
    required this.reason,
    required this.approvedBy,
    required this.timestamp,
    this.targetRoles = const ['hr', 'ceo', 'team_lead'],
    this.targetEmpIds = const [],
    Set<String>? acknowledgedByEmpIds,
  }) : acknowledgedByEmpIds = acknowledgedByEmpIds ?? {};

  /// Checks whether this acceptance notification must be displayed to the given user
  bool isTargetedFor({required String empId, required String roleType}) {
    // Check if dismissed/acknowledged by this specific user
    if (acknowledgedByEmpIds.contains(empId)) return false;

    // Check if targeted to all users
    if (targetRoles.contains('all')) return true;

    // Check by roleType
    final rLower = roleType.toLowerCase();
    if (targetRoles.contains(rLower)) return true;
    if (rLower == 'dept_head' && targetRoles.contains('team_lead')) return true;

    // Check by specific empId
    if (targetEmpIds.contains(empId)) return true;

    // Check specific leadership IDs
    if (empId == 'MN-CEO01' && targetRoles.contains('ceo')) return true;
    if (empId == 'MN-HR1001' && targetRoles.contains('hr')) return true;
    if (empId == 'MN-TL1002' && targetRoles.contains('team_lead')) return true;

    // Check if it's the employee whose request was accepted
    if (empId == employeeId) return true;

    return false;
  }

  void acknowledgeBy(String empId) {
    acknowledgedByEmpIds.add(empId);
  }

  IconData get icon {
    switch (requestType) {
      case AcceptanceRequestType.permission:
        return Icons.timer_outlined;
      case AcceptanceRequestType.leave:
        return Icons.event_available_rounded;
      case AcceptanceRequestType.socialCausePending:
        return Icons.volunteer_activism_rounded;
      case AcceptanceRequestType.socialCauseApproved:
        return Icons.verified_rounded;
    }
  }

  Color get accentColor {
    switch (requestType) {
      case AcceptanceRequestType.socialCausePending:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981); // Emerald green acceptance color
    }
  }
}
