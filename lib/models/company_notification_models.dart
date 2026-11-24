import 'package:flutter/material.dart';
import '../core/utils/attendance_date_label.dart';

enum CompanyNotificationType {
  birthday,
  anniversary,
  socialCause,
  broadcastNotice,
  todoReminder,
}

class CompanyNotification {
  final String id;
  final String title;
  final String content;
  final CompanyNotificationType type;
  final DateTime timestamp;
  final String senderName;
  final String senderRole;
  final bool isRead;
  final List<String> readByStaffIds;
  final String? actionTag;
  final List<String> likedStaffIds;
  final List<String> dismissedByStaffIds;
  final String? targetEmpId;
  final List<String> targetEmpIds;
  final List<NotificationComment> comments;

  CompanyNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.senderName,
    required this.senderRole,
    this.isRead = false,
    this.readByStaffIds = const [],
    this.actionTag,
    this.likedStaffIds = const [],
    this.dismissedByStaffIds = const [],
    this.targetEmpId,
    this.targetEmpIds = const [],
    this.comments = const [],
  });

  bool isReadBy(String empId) {
    return isRead || readByStaffIds.contains(empId);
  }

  bool isDismissedBy(String empId) {
    return dismissedByStaffIds.contains(empId);
  }

  /// Whether notification is targeted for a specific employee or set of employees
  bool isTargetedFor(String empId) {
    if (targetEmpIds.isNotEmpty) {
      return targetEmpIds.contains(empId);
    }
    if (targetEmpId != null && targetEmpId!.trim().isNotEmpty) {
      return targetEmpId == empId;
    }
    return true;
  }

  /// Only notifications with real non-empty title or content are valid (prevents blank/dead stubs)
  bool get isValid => title.trim().isNotEmpty && content.trim().isNotEmpty;

  bool isLikedBy(String empId) => likedStaffIds.contains(empId);
  int get likesCount => likedStaffIds.length;
  int get commentsCount => comments.length;
  bool get isCeoReacted => likedStaffIds.any((id) => id == 'MN-CEO01' || id.toLowerCase().contains('ceo'));

  CompanyNotification copyWith({
    String? id,
    String? title,
    String? content,
    CompanyNotificationType? type,
    DateTime? timestamp,
    String? senderName,
    String? senderRole,
    bool? isRead,
    List<String>? readByStaffIds,
    String? actionTag,
    List<String>? likedStaffIds,
    List<String>? dismissedByStaffIds,
    String? targetEmpId,
    List<String>? targetEmpIds,
    List<NotificationComment>? comments,
  }) {
    return CompanyNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      isRead: isRead ?? this.isRead,
      readByStaffIds: readByStaffIds ?? this.readByStaffIds,
      actionTag: actionTag ?? this.actionTag,
      likedStaffIds: likedStaffIds ?? this.likedStaffIds,
      dismissedByStaffIds: dismissedByStaffIds ?? this.dismissedByStaffIds,
      targetEmpId: targetEmpId ?? this.targetEmpId,
      targetEmpIds: targetEmpIds ?? this.targetEmpIds,
      comments: comments ?? this.comments,
    );
  }

  IconData get icon {
    if (actionTag == 'PERM_ACCEPTED') return Icons.check_circle_outline_rounded;
    if (actionTag == 'LEAVE_ACCEPTED') return Icons.event_available_rounded;
    if (actionTag == 'ATTENDANCE' || actionTag == 'ATTENDANCE_UPDATE') return Icons.fingerprint_rounded;
    switch (type) {
      case CompanyNotificationType.birthday:
        return Icons.cake_outlined;
      case CompanyNotificationType.anniversary:
        return Icons.celebration_outlined;
      case CompanyNotificationType.socialCause:
        return Icons.volunteer_activism_outlined;
      case CompanyNotificationType.broadcastNotice:
        return Icons.campaign_outlined;
      case CompanyNotificationType.todoReminder:
        return Icons.history_rounded;
    }
  }

  Color get color {
    if (actionTag == 'PERM_ACCEPTED' || actionTag == 'LEAVE_ACCEPTED') {
      return const Color(0xFF10B981); // Emerald Green for official acceptance
    }
    if (actionTag == 'ATTENDANCE' || actionTag == 'ATTENDANCE_UPDATE') {
      return const Color(0xFFD97706); // Warm Amber/Gold for Attendance
    }
    switch (type) {
      case CompanyNotificationType.birthday:
        return const Color(0xFFEC4899); // Pink
      case CompanyNotificationType.anniversary:
        return const Color(0xFFF59E0B); // Amber / Gold
      case CompanyNotificationType.socialCause:
        return const Color(0xFF10B981); // Emerald Green
      case CompanyNotificationType.broadcastNotice:
        return const Color(0xFF6366F1); // Indigo
      case CompanyNotificationType.todoReminder:
        return const Color(0xFFEF4444); // Urgent Red / Coral
    }
  }

  String get categoryLabel {
    if (actionTag == 'PERM_ACCEPTED') return 'Permission Acceptance';
    if (actionTag == 'LEAVE_ACCEPTED') return 'Leave Acceptance';
    if (actionTag == 'ATTENDANCE' || actionTag == 'ATTENDANCE_UPDATE') return 'Attendance Update';
    switch (type) {
      case CompanyNotificationType.birthday:
        return 'Birthday Celebration';
      case CompanyNotificationType.anniversary:
        return 'Special Day Milestone';
      case CompanyNotificationType.socialCause:
        return 'Social Cause Deed';
      case CompanyNotificationType.broadcastNotice:
        return 'Management Broadcast';
      case CompanyNotificationType.todoReminder:
        return 'To-Do Reminder';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'senderName': senderName,
    'senderRole': senderRole,
    'isRead': isRead,
    'readByStaffIds': readByStaffIds,
    'actionTag': actionTag,
    'likedStaffIds': likedStaffIds,
    'dismissedByStaffIds': dismissedByStaffIds,
    'targetEmpId': targetEmpId,
    'targetEmpIds': targetEmpIds,
    'comments': comments.map((c) => c.toJson()).toList(),
  };

  factory CompanyNotification.fromJson(Map<String, dynamic> json) {
    CompanyNotificationType type;
    final tStr = json['type']?.toString().toLowerCase() ?? '';
    if (tStr.contains('birthday')) {
      type = CompanyNotificationType.birthday;
    } else if (tStr.contains('anniversary')) {
      type = CompanyNotificationType.anniversary;
    } else if (tStr.contains('social')) {
      type = CompanyNotificationType.socialCause;
    } else if (tStr.contains('todo') || tStr.contains('task')) {
      type = CompanyNotificationType.todoReminder;
    } else {
      type = CompanyNotificationType.broadcastNotice;
    }

    String rawSender = json['senderName']?.toString() ?? 'MN Jewel Park';
    String rawRole = json['senderRole']?.toString() ?? 'Administration';
    String rawTitle = json['title']?.toString() ?? '';
    String rawContent = json['content']?.toString() ?? '';

    // Sanitize any legacy CEO names across notification records
    if (rawSender.toLowerCase().contains('senthil') ||
        rawSender.toLowerCase().contains('executive ceo') ||
        rawRole.toLowerCase().contains('ceo & founder')) {
      rawSender = 'M N Naveenraaj';
      rawRole = 'Managing Director & CEO';
    }

    rawTitle = rawTitle
        .replaceAll('Dr. K. Senthil Nathan', 'M N Naveenraaj')
        .replaceAll('Senthil Nathan', 'M N Naveenraaj')
        .replaceAll('Senthil', 'M N Naveenraaj')
        .replaceAll('CEO & Founder', 'Managing Director & CEO');

    rawContent = rawContent
        .replaceAll('Dr. K. Senthil Nathan', 'M N Naveenraaj')
        .replaceAll('Senthil Nathan', 'M N Naveenraaj')
        .replaceAll('Senthil', 'M N Naveenraaj')
        .replaceAll('CEO & Founder', 'Managing Director & CEO');

    // Attendance updates saved by older builds used labels like "November 1, 22".
    if (rawTitle.trim().endsWith('Attendance Update')) {
      final cleaned = cleanLegacyAttendanceNotification(rawTitle, rawContent);
      rawTitle = cleaned.$1;
      rawContent = cleaned.$2;
    }

    return CompanyNotification(
      id: json['id']?.toString() ?? 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      title: rawTitle,
      content: rawContent,
      type: type,
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now() : DateTime.now(),
      senderName: rawSender,
      senderRole: rawRole,
      isRead: json['isRead'] == true,
      readByStaffIds: (json['readByStaffIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      actionTag: json['actionTag']?.toString(),
      likedStaffIds: (json['likedStaffIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      dismissedByStaffIds: (json['dismissedByStaffIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      targetEmpId: json['targetEmpId']?.toString(),
      targetEmpIds: (json['targetEmpIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
      comments: (json['comments'] as List?)
              ?.map((c) => NotificationComment.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList() ??
          [],
    );
  }
}

class NotificationComment {
  final String id;
  final String notificationId;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String text;
  final DateTime timestamp;
  final List<String> likedStaffIds;

  NotificationComment({
    required this.id,
    required this.notificationId,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.text,
    required this.timestamp,
    this.likedStaffIds = const [],
  });

  bool isLikedBy(String staffId) =>
      likedStaffIds.any((id) => id.toLowerCase() == staffId.toLowerCase());
  int get likesCount => likedStaffIds.length;

  NotificationComment copyWith({
    String? id,
    String? notificationId,
    String? authorId,
    String? authorName,
    String? authorRole,
    String? text,
    DateTime? timestamp,
    List<String>? likedStaffIds,
  }) {
    return NotificationComment(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      likedStaffIds: likedStaffIds ?? this.likedStaffIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'notificationId': notificationId,
        'authorId': authorId,
        'authorName': authorName,
        'authorRole': authorRole,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'likedStaffIds': likedStaffIds,
      };

  factory NotificationComment.fromJson(Map<String, dynamic> json) {
    return NotificationComment(
      id: json['id']?.toString() ?? 'CMT-${DateTime.now().millisecondsSinceEpoch}',
      notificationId: json['notificationId']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? 'Staff Member',
      authorRole: json['authorRole']?.toString() ?? 'Team Member',
      text: json['text']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      likedStaffIds: (json['likedStaffIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class CelebrationEvent {
  final String employeeId;
  final String employeeName;
  final bool isFemale;
  final String type; // 'birthday' or 'anniversary'
  final String message; // Personalized message for the celebrant
  final String othersMessage; // Broadcast message for colleagues
  final String date;

  CelebrationEvent({
    this.employeeId = '',
    required this.employeeName,
    this.isFemale = false,
    required this.type,
    required this.message,
    String? othersMessage,
    required this.date,
  }) : othersMessage = othersMessage ??
            (type == 'birthday'
                ? "🎉 Today is $employeeName's Birthday, wish ${isFemale ? 'her' : 'him'} the best! 🎂"
                : "💍 Today is $employeeName's Wedding Anniversary, wish them the best! 💐");

  /// Dynamically selects the display message based on whether the logged in user
  /// is the celebrant or a colleague.
  String displayMessage(String activeEmpId, String activeEmpName) {
    final cleanActiveId = activeEmpId.trim().toLowerCase();
    final cleanEmpId = employeeId.trim().toLowerCase();
    final cleanActiveName = activeEmpName.trim().toLowerCase();
    final cleanEmpName = employeeName.trim().toLowerCase();

    final bool isSelf = (cleanEmpId.isNotEmpty && cleanActiveId == cleanEmpId) ||
        (cleanEmpName.isNotEmpty &&
            (cleanActiveName == cleanEmpName ||
                cleanActiveName.contains(cleanEmpName) ||
                cleanEmpName.contains(cleanActiveName)));

    return isSelf ? message : othersMessage;
  }
}
