import 'package:flutter/material.dart';

/// Categories of social causes and charitable deeds
class SocialCauseType {
  static const String foodDonation = 'Food Donation';
  static const String eyeDonation = 'Eye Donation';
  static const String bloodDonation = 'Blood Donation';
  static const String elderlyAssistance = 'Elderly Assistance';
  static const String educationSupport = 'Education Support';
  static const String medicalHelp = 'Medical Help';
  static const String clothDonation = 'Cloth & Essentials';
  static const String treePlanting = 'Tree Plantation & Nature';
  static const String otherKindness = 'Other Act of Kindness';

  static const List<String> all = [
    foodDonation,
    eyeDonation,
    bloodDonation,
    elderlyAssistance,
    educationSupport,
    medicalHelp,
    clothDonation,
    treePlanting,
    otherKindness,
  ];

  static IconData getIcon(String type) {
    switch (type) {
      case foodDonation:
        return Icons.restaurant_outlined;
      case eyeDonation:
        return Icons.visibility_outlined;
      case bloodDonation:
        return Icons.water_drop_outlined;
      case elderlyAssistance:
        return Icons.elderly_outlined;
      case educationSupport:
        return Icons.menu_book_outlined;
      case medicalHelp:
        return Icons.medical_services_outlined;
      case clothDonation:
        return Icons.checkroom_outlined;
      case treePlanting:
        return Icons.park_outlined;
      default:
        return Icons.favorite_outline;
    }
  }

  static Color getColor(String type) {
    switch (type) {
      case foodDonation:
        return const Color(0xFFF59E0B);
      case eyeDonation:
        return const Color(0xFF38BDF8);
      case bloodDonation:
        return const Color(0xFFEF4444);
      case elderlyAssistance:
        return const Color(0xFFA855F7);
      case educationSupport:
        return const Color(0xFF10B981);
      case medicalHelp:
        return const Color(0xFF06B6D4);
      case clothDonation:
        return const Color(0xFFEC4899);
      case treePlanting:
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFFE2C992);
    }
  }
}

/// A social deed posted by an employee, awaiting or granted HR/CEO approval
class SocialCauseItem {
  final String id;
  final String empId;
  final String employeeName;
  final String employeeRole;
  final String causeType;
  final String title;
  final String description;
  final double amountSpent;
  final String? imageUrl;
  final DateTime date;
  final String status; // 'pending', 'approved', 'rejected'
  final String? approvedByName;
  final DateTime? approvedAt;
  final int heartsCount;
  final bool isHeartedByCurrentUser;

  SocialCauseItem({
    required this.id,
    required this.empId,
    required this.employeeName,
    required this.employeeRole,
    required this.causeType,
    required this.title,
    required this.description,
    required this.amountSpent,
    this.imageUrl,
    required this.date,
    this.status = 'pending',
    this.approvedByName,
    this.approvedAt,
    this.heartsCount = 0,
    this.isHeartedByCurrentUser = false,
  });

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  SocialCauseItem copyWith({
    String? id,
    String? empId,
    String? employeeName,
    String? employeeRole,
    String? causeType,
    String? title,
    String? description,
    double? amountSpent,
    String? imageUrl,
    DateTime? date,
    String? status,
    String? approvedByName,
    DateTime? approvedAt,
    int? heartsCount,
    bool? isHeartedByCurrentUser,
  }) {
    return SocialCauseItem(
      id: id ?? this.id,
      empId: empId ?? this.empId,
      employeeName: employeeName ?? this.employeeName,
      employeeRole: employeeRole ?? this.employeeRole,
      causeType: causeType ?? this.causeType,
      title: title ?? this.title,
      description: description ?? this.description,
      amountSpent: amountSpent ?? this.amountSpent,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      status: status ?? this.status,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      heartsCount: heartsCount ?? this.heartsCount,
      isHeartedByCurrentUser: isHeartedByCurrentUser ?? this.isHeartedByCurrentUser,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'empId': empId,
    'employeeName': employeeName,
    'employeeRole': employeeRole,
    'causeType': causeType,
    'title': title,
    'description': description,
    'amountSpent': amountSpent,
    'imageUrl': imageUrl,
    'date': date.toIso8601String(),
    'status': status,
    'approvedByName': approvedByName,
    'approvedAt': approvedAt?.toIso8601String(),
    'heartsCount': heartsCount,
  };

  factory SocialCauseItem.fromJson(Map<String, dynamic> json) => SocialCauseItem(
    id: json['id']?.toString() ?? '',
    empId: json['empId']?.toString() ?? '',
    employeeName: json['employeeName']?.toString() ?? 'Staff Member',
    employeeRole: json['employeeRole']?.toString() ?? 'MN Jewel Park Staff',
    causeType: json['causeType']?.toString() ?? SocialCauseType.foodDonation,
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    amountSpent: (json['amountSpent'] as num?)?.toDouble() ?? 0.0,
    imageUrl: json['imageUrl']?.toString(),
    date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
    status: json['status']?.toString() ?? 'pending',
    approvedByName: json['approvedByName']?.toString(),
    approvedAt: json['approvedAt'] != null ? DateTime.tryParse(json['approvedAt'].toString()) : null,
    heartsCount: (json['heartsCount'] as int?) ?? 0,
  );
}

