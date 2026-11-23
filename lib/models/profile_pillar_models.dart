import 'package:flutter/material.dart';

/// Ring 3: Grooming inspection item audited by HR
class GroomingAuditItem {
  final String id;
  final String empId;
  final DateTime date;
  final String category; // 'Daily Attire & Grooming Audit'
  final int pointsChange; // Retained for compatibility
  final int pointsEarned; // Points earned out of 50 max (e.g. 40, 50)
  final int maxPoints; // Max daily points (default 50)
  final List<String> followedItems; // List of criteria items followed
  final String reason;
  final String auditedBy;
  final bool isApproved;

  GroomingAuditItem({
    required this.id,
    required this.empId,
    required this.date,
    required this.category,
    required this.pointsChange,
    int? pointsEarned,
    this.maxPoints = 50,
    this.followedItems = const [],
    required this.reason,
    this.auditedBy = 'HR Department',
    this.isApproved = true,
  }) : pointsEarned = pointsEarned ?? pointsChange.clamp(0, maxPoints);

  double get percentage =>
      maxPoints > 0 ? ((pointsEarned / maxPoints) * 100.0).clamp(0.0, 100.0) : 0.0;

  String get dateFormatted {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empId': empId,
      'date': date.toIso8601String(),
      'category': category,
      'pointsChange': pointsChange,
      'pointsEarned': pointsEarned,
      'maxPoints': maxPoints,
      'followedItems': followedItems,
      'reason': reason,
      'auditedBy': auditedBy,
      'isApproved': isApproved,
    };
  }

  factory GroomingAuditItem.fromMap(Map<String, dynamic> map) {
    return GroomingAuditItem(
      id: map['id']?.toString() ?? '',
      empId: map['empId']?.toString() ?? '',
      date: map['date'] != null ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now() : DateTime.now(),
      category: map['category']?.toString() ?? 'Daily Attire & Grooming Audit',
      pointsChange: (map['pointsChange'] as num?)?.toInt() ?? 50,
      pointsEarned: (map['pointsEarned'] as num?)?.toInt() ?? 50,
      maxPoints: (map['maxPoints'] as num?)?.toInt() ?? 50,
      followedItems: map['followedItems'] is List ? List<String>.from((map['followedItems'] as List).map((e) => e.toString())) : const [],
      reason: map['reason']?.toString() ?? 'Standard Grooming Compliance',
      auditedBy: map['auditedBy']?.toString() ?? 'HR Department',
      isApproved: map['isApproved'] as bool? ?? true,
    );
  }
}

/// Ring 5: Permission & Late Arrival request with auto 4-hr balance & 1 CL rule
class PermissionRecord {
  final String id;
  final String empId;
  final DateTime date;
  final double requestedHours; // e.g. 4.0 hrs
  final double actualHoursUsed; // e.g. 1.0 hr
  final String reason;
  final String status; // 'Approved', 'Pending', 'Pending HR & CEO', 'Granted by HR (Pending CEO Approval)', 'Pending CEO', 'Rejected'
  final bool isHalfDayTriggered; // True if monthly > 4 hrs
  final bool isCasualLeave; // True if taken as CL (max 1/month)
  final bool isSalaryDeducted; // True if exceeding 1 CL
  final String grantedBy; // 'HR Direct Grant' or 'Employee Request'
  final bool isEmergency;

  bool get hrEndorsed => hrApprovedBy != null && hrApprovedBy!.isNotEmpty;
  final String? employeeName;
  final String? department;
  final String? requesterRole; // 'Employee', 'Team Lead', 'HR', 'CEO'
  final bool isOver4Hours; // True if requested > 4h or monthly balance exceeded (Orange flag)
  bool get isOver2Hours => isOver4Hours; // Backwards compatibility alias
  final String? hrApprovedBy;
  final String? ceoApprovedBy;

  PermissionRecord({
    required this.id,
    required this.empId,
    required this.date,
    required this.requestedHours,
    required this.actualHoursUsed,
    required this.reason,
    this.status = 'Approved',
    this.isHalfDayTriggered = false,
    this.isCasualLeave = false,
    this.isSalaryDeducted = false,
    this.grantedBy = 'HR Direct Grant',
    this.isEmergency = false,
    this.employeeName,
    this.department,
    this.requesterRole,
    bool isOver4Hours = false,
    bool isOver2Hours = false,
    this.hrApprovedBy,
    this.ceoApprovedBy,
  }) : isOver4Hours = isOver4Hours || isOver2Hours;

  /// Hours saved back to the employee's account
  double get creditedBackHours => (requestedHours - actualHoursUsed).clamp(0.0, requestedHours);

  /// Status helper getters
  bool get isPendingHr =>
      status == 'Pending' || status == 'Pending HR' || status == 'Pending HR & CEO';

  bool get isPendingCeo =>
      status == 'Pending CEO' ||
      status == 'Granted by HR (Pending CEO Approval)' ||
      (status == 'Pending HR & CEO' && requesterRole != 'HR');

  bool get isOrangeFlagged => isOver4Hours || requestedHours > 4.0 || isHalfDayTriggered;

  String get dateFormatted {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empId': empId,
      'date': date.toIso8601String(),
      'requestedHours': requestedHours,
      'actualHoursUsed': actualHoursUsed,
      'reason': reason,
      'status': status,
      'isHalfDayTriggered': isHalfDayTriggered,
      'isCasualLeave': isCasualLeave,
      'isSalaryDeducted': isSalaryDeducted,
      'grantedBy': grantedBy,
      'isEmergency': isEmergency,
      'employeeName': employeeName,
      'department': department,
      'requesterRole': requesterRole,
      'isOver4Hours': isOver4Hours,
      'hrApprovedBy': hrApprovedBy,
      'ceoApprovedBy': ceoApprovedBy,
    };
  }

  factory PermissionRecord.fromMap(Map<String, dynamic> map) {
    return PermissionRecord(
      id: map['id']?.toString() ?? '',
      empId: map['empId']?.toString() ?? '',
      date: map['date'] != null ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now() : DateTime.now(),
      requestedHours: (map['requestedHours'] as num?)?.toDouble() ?? 1.0,
      actualHoursUsed: (map['actualHoursUsed'] as num?)?.toDouble() ?? 1.0,
      reason: map['reason']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Approved',
      isHalfDayTriggered: map['isHalfDayTriggered'] as bool? ?? false,
      isCasualLeave: map['isCasualLeave'] as bool? ?? false,
      isSalaryDeducted: map['isSalaryDeducted'] as bool? ?? false,
      grantedBy: map['grantedBy']?.toString() ?? 'HR Direct Grant',
      isEmergency: map['isEmergency'] as bool? ?? false,
      employeeName: map['employeeName']?.toString(),
      department: map['department']?.toString(),
      requesterRole: map['requesterRole']?.toString(),
      isOver4Hours: map['isOver4Hours'] as bool? ?? false,
      hrApprovedBy: map['hrApprovedBy']?.toString(),
      ceoApprovedBy: map['ceoApprovedBy']?.toString(),
    );
  }
}

/// Emergency Medical Leave Record with Mandatory Doctor Prescription (Compressed <= 150 KB)
class MedicalLeaveRecord {
  final String id;
  final String empId;
  final String empName;
  final String empRole;
  final String department;
  final DateTime date;
  final int days; // Number of days requested
  final String reason;
  final String prescriptionBase64; // Compressed <= 150 KB
  final String status; // 'Pending HR & CEO', 'Granted by HR (Pending CEO Approval)', 'Pending CEO', 'Approved', 'Rejected'
  final String? hrApprovedBy;
  final String? ceoApprovedBy;
  final DateTime? reviewedAt;
  final bool isEmergency;

  bool get hrEndorsed => hrApprovedBy != null && hrApprovedBy!.isNotEmpty;

  MedicalLeaveRecord({
    required this.id,
    required this.empId,
    required this.empName,
    required this.empRole,
    required this.department,
    required this.date,
    required this.days,
    required this.reason,
    required this.prescriptionBase64,
    this.status = 'Pending HR & CEO',
    this.hrApprovedBy,
    this.ceoApprovedBy,
    this.reviewedAt,
    this.isEmergency = true,
  });

  bool get isPendingHr =>
      status == 'Pending' || status == 'Pending HR' || status == 'Pending HR & CEO';

  bool get isPendingCeo =>
      status == 'Pending CEO' ||
      status == 'Granted by HR (Pending CEO Approval)' ||
      (status == 'Pending HR & CEO' && empRole != 'HR' && empRole != 'HR Manager');

  String get dateFormatted {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  MedicalLeaveRecord withPrescription(String base64) => MedicalLeaveRecord(
        id: id,
        empId: empId,
        empName: empName,
        empRole: empRole,
        department: department,
        date: date,
        days: days,
        reason: reason,
        prescriptionBase64: base64,
        status: status,
        hrApprovedBy: hrApprovedBy,
        ceoApprovedBy: ceoApprovedBy,
        reviewedAt: reviewedAt,
        isEmergency: isEmergency,
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empId': empId,
      'empName': empName,
      'empRole': empRole,
      'department': department,
      'date': date.toIso8601String(),
      'days': days,
      'reason': reason,
      'prescriptionBase64': prescriptionBase64,
      'status': status,
      'hrApprovedBy': hrApprovedBy,
      'ceoApprovedBy': ceoApprovedBy,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'isEmergency': isEmergency,
    };
  }

  factory MedicalLeaveRecord.fromMap(Map<String, dynamic> map) {
    return MedicalLeaveRecord(
      id: map['id']?.toString() ?? '',
      empId: map['empId']?.toString() ?? '',
      empName: map['empName']?.toString() ?? '',
      empRole: map['empRole']?.toString() ?? '',
      department: map['department']?.toString() ?? '',
      date: map['date'] != null ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now() : DateTime.now(),
      days: (map['days'] as num?)?.toInt() ?? 1,
      reason: map['reason']?.toString() ?? '',
      prescriptionBase64: map['prescriptionBase64']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Pending HR & CEO',
      hrApprovedBy: map['hrApprovedBy']?.toString(),
      ceoApprovedBy: map['ceoApprovedBy']?.toString(),
      reviewedAt: map['reviewedAt'] != null ? DateTime.tryParse(map['reviewedAt'].toString()) : null,
      isEmergency: map['isEmergency'] as bool? ?? true,
    );
  }
}

/// Ring 4: Individual Sales Log for Jewellery Consultants
class SalesRecord {
  final String id;
  final String empId;
  final String billNumber;
  final DateTime date;
  final String itemCategory; // '22K Gold Jewellery', 'Diamond & Solitaire', 'Polki & Antique', 'Silver Artifacts'
  final double amountInInr;
  final double weightGrams;
  final String customerName;

  SalesRecord({
    required this.id,
    required this.empId,
    required this.billNumber,
    required this.date,
    required this.itemCategory,
    required this.amountInInr,
    required this.weightGrams,
    required this.customerName,
  });

  String get formattedAmount {
    if (amountInInr >= 100000) {
      return '₹${(amountInInr / 100000).toStringAsFixed(2)} Lakhs';
    }
    return '₹${amountInInr.toStringAsFixed(0)}';
  }

  String get dateFormatted {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empId': empId,
      'billNumber': billNumber,
      'date': date.toIso8601String(),
      'itemCategory': itemCategory,
      'amountInInr': amountInInr,
      'weightGrams': weightGrams,
      'customerName': customerName,
    };
  }

  factory SalesRecord.fromMap(Map<String, dynamic> map) {
    return SalesRecord(
      id: map['id']?.toString() ?? '',
      empId: map['empId']?.toString() ?? '',
      billNumber: map['billNumber']?.toString() ?? '',
      date: map['date'] != null ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now() : DateTime.now(),
      itemCategory: map['itemCategory']?.toString() ?? '22K Gold Jewellery',
      amountInInr: (map['amountInInr'] as num?)?.toDouble() ?? 0.0,
      weightGrams: (map['weightGrams'] as num?)?.toDouble() ?? 0.0,
      customerName: map['customerName']?.toString() ?? '',
    );
  }
}

/// CEO Role Allocation Definition with Perks & Responsibilities
class RoleAllocationConfig {
  final String roleName; // 'Dept Head', 'HR', 'Employee', 'CEO (Admin)'
  final String department;
  final List<String> responsibilities;
  final List<String> perks;
  final Color badgeColor;
  final IconData icon;

  const RoleAllocationConfig({
    required this.roleName,
    required this.department,
    required this.responsibilities,
    required this.perks,
    required this.badgeColor,
    required this.icon,
  });

  static const List<String> availableDepartments = [
    'Online Department',
    'HR & Administration',
  ];

  static const List<String> standardRoles = [
    'Employee',
    'Dept Head',
    'HR',
    'CEO (Admin)'
  ];

  static Map<String, RoleAllocationConfig> defaultRoleProfiles = {
    'CEO (Admin)': const RoleAllocationConfig(
      roleName: 'CEO (Admin)',
      department: 'Executive CEO Office',
      responsibilities: [
        'Universal directive injection across all units',
        'Executive role & privilege allocation',
        'Full financial & gold vault audit authorization',
        'Strategic showroom expansion and procurement oversight',
        'Emergency operational overrides'
      ],
      perks: [
        'Executive suite clearance with zero access restrictions',
        'Direct override on special jewellery discount pricing',
        'Executive travel & protocol allowance',
        'Supreme company governance authority'
      ],
      badgeColor: Color(0xFFD4AF37), // Sand Gold
      icon: Icons.workspace_premium,
    ),
    'Dept Head': const RoleAllocationConfig(
      roleName: 'Dept Head',
      department: 'Gold Jewellery',
      responsibilities: [
        'Assigning tasks & shift responsibilities to floor staff',
        'Counter gold weight balance check & morning readiness gate',
        'Shift handover sign-offs and incident mitigation',
        'First-tier approval of staff permission slips'
      ],
      perks: [
        'Task delegation privileges over junior employees',
        'Authorizing customer negotiation discounts up to 3%',
        'Priority schedule flexibility',
        'Departmental performance commission bonus'
      ],
      badgeColor: Color(0xFF3B82F6), // Royal Blue
      icon: Icons.shield_outlined,
    ),
    'HR': const RoleAllocationConfig(
      roleName: 'HR',
      department: 'HR & Admin',
      responsibilities: [
        'Grooming audits & uniform standards enforcement (+/- points)',
        'Managing 26-day attendance ratio & in-app biometric sync',
        'Leave & permission tracking (2 hr monthly balance & 1 CL rule)',
        'Original certificates custody in company safe vault'
      ],
      perks: [
        'Company-wide grooming point evaluation & salary deduction control',
        'Staff onboarding and probation clearance authority',
        'Direct hotline to CEO Office',
        'HR confidential personnel locker access'
      ],
      badgeColor: Color(0xFF10B981), // Emerald Green
      icon: Icons.manage_accounts,
    ),
    'Employee': const RoleAllocationConfig(
      roleName: 'Employee',
      department: 'Sales Operations',
      responsibilities: [
        'Customer luxury jewelry consultation & sales closure',
        'Daily grooming, uniform, and personal presentation compliance',
        'Punctual in-app thumb impression login before 09:30 AM',
        'Completing shift handover checklist before counter exit'
      ],
      perks: [
        'Monthly sales commission tier qualification',
        '4.0 hours flexible monthly emergency permission balance',
        '1 paid Casual Leave per calendar month',
        'Access to MN Family Wellness & Tier Rewards'
      ],
      badgeColor: Color(0xFF8B5CF6), // Purple
      icon: Icons.person_outline,
    ),
  };
}
