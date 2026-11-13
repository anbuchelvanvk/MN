import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

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
  });

  bool isReadBy(String empId) {
    return isRead || readByStaffIds.contains(empId);
  }

  bool isDismissedBy(String empId) {
    return dismissedByStaffIds.contains(empId);
  }

  bool isLikedBy(String empId) => likedStaffIds.contains(empId);
  int get likesCount => likedStaffIds.length;
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
    );
  }

  IconData get icon {
    switch (type) {
      case CompanyNotificationType.birthday:
        return FontAwesomeIcons.cakeCandles;
      case CompanyNotificationType.anniversary:
        return FontAwesomeIcons.champagneGlasses;
      case CompanyNotificationType.socialCause:
        return FontAwesomeIcons.handHoldingHeart;
      case CompanyNotificationType.broadcastNotice:
        return FontAwesomeIcons.bullhorn;
      case CompanyNotificationType.todoReminder:
        return FontAwesomeIcons.clockRotateLeft;
    }
  }

  Color get color {
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
    );
  }
}
