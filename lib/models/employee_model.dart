import 'konar_tasks_catalog.dart';

class ProfileCompletion {
  int percentage;
  bool isAuthorized;
  bool photoVerified;
  bool addressVerified;
  bool kycVerified;
  bool sopRolesAcknowledged;
  String? authorizedDate;

  ProfileCompletion({
    required this.percentage,
    required this.isAuthorized,
    required this.photoVerified,
    required this.addressVerified,
    required this.kycVerified,
    required this.sopRolesAcknowledged,
    this.authorizedDate,
  });

  void recalculate() {
    int count = 0;
    if (photoVerified) count++;
    if (addressVerified) count++;
    if (kycVerified) count++;
    if (sopRolesAcknowledged) count++;

    percentage = ((count / 4) * 100).round();
    isAuthorized = (percentage == 100);
    if (isAuthorized && authorizedDate == null) {
      authorizedDate = 'Authorized Today';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'percentage': percentage,
      'isAuthorized': isAuthorized,
      'photoVerified': photoVerified,
      'addressVerified': addressVerified,
      'kycVerified': kycVerified,
      'sopRolesAcknowledged': sopRolesAcknowledged,
      'authorizedDate': authorizedDate,
    };
  }

  factory ProfileCompletion.fromMap(Map<String, dynamic> map) {
    return ProfileCompletion(
      percentage: map['percentage'] ?? 0,
      isAuthorized: map['isAuthorized'] ?? false,
      photoVerified: map['photoVerified'] ?? false,
      addressVerified: map['addressVerified'] ?? false,
      kycVerified: map['kycVerified'] ?? false,
      sopRolesAcknowledged: map['sopRolesAcknowledged'] ?? false,
      authorizedDate: map['authorizedDate'],
    );
  }
}

/// Granular Feature & Module Access Permissions for Role-Based Access Control (RBAC)
class RolePermissions {
  final bool canAccessCeoSuite;
  final bool canAccessHrPortal;
  final bool canAccessDeptHeadPortal;
  final bool canManageOrders;
  final bool canAccessKonarBooks;
  final bool canAssignTasksToOthers;
  final bool canExportAudit;
  final bool canManageRoles;

  // 7 Pillars Access
  final bool canAccessAttendancePillar;
  final bool canAccessHealthPillar;
  final bool canAccessFamilyPillar;
  final bool canAccessProfilePillar;
  final bool canAccessSocialCausePillar;
  final bool canAccessTierPillar;
  final bool canAccessWorkPillar;

  const RolePermissions({
    this.canAccessCeoSuite = false,
    this.canAccessHrPortal = false,
    this.canAccessDeptHeadPortal = false,
    this.canManageOrders = false,
    this.canAccessKonarBooks = true,
    this.canAssignTasksToOthers = false,
    this.canExportAudit = false,
    this.canManageRoles = false,
    this.canAccessAttendancePillar = true,
    this.canAccessHealthPillar = true,
    this.canAccessFamilyPillar = true,
    this.canAccessProfilePillar = true,
    this.canAccessSocialCausePillar = true,
    this.canAccessTierPillar = true,
    this.canAccessWorkPillar = true,
  });

  RolePermissions copyWith({
    bool? canAccessCeoSuite,
    bool? canAccessHrPortal,
    bool? canAccessDeptHeadPortal,
    bool? canManageOrders,
    bool? canAccessKonarBooks,
    bool? canAssignTasksToOthers,
    bool? canExportAudit,
    bool? canManageRoles,
    bool? canAccessAttendancePillar,
    bool? canAccessHealthPillar,
    bool? canAccessFamilyPillar,
    bool? canAccessProfilePillar,
    bool? canAccessSocialCausePillar,
    bool? canAccessTierPillar,
    bool? canAccessWorkPillar,
  }) {
    return RolePermissions(
      canAccessCeoSuite: canAccessCeoSuite ?? this.canAccessCeoSuite,
      canAccessHrPortal: canAccessHrPortal ?? this.canAccessHrPortal,
      canAccessDeptHeadPortal: canAccessDeptHeadPortal ?? this.canAccessDeptHeadPortal,
      canManageOrders: canManageOrders ?? this.canManageOrders,
      canAccessKonarBooks: canAccessKonarBooks ?? this.canAccessKonarBooks,
      canAssignTasksToOthers: canAssignTasksToOthers ?? this.canAssignTasksToOthers,
      canExportAudit: canExportAudit ?? this.canExportAudit,
      canManageRoles: canManageRoles ?? this.canManageRoles,
      canAccessAttendancePillar: canAccessAttendancePillar ?? this.canAccessAttendancePillar,
      canAccessHealthPillar: canAccessHealthPillar ?? this.canAccessHealthPillar,
      canAccessFamilyPillar: canAccessFamilyPillar ?? this.canAccessFamilyPillar,
      canAccessProfilePillar: canAccessProfilePillar ?? this.canAccessProfilePillar,
      canAccessSocialCausePillar: canAccessSocialCausePillar ?? this.canAccessSocialCausePillar,
      canAccessTierPillar: canAccessTierPillar ?? this.canAccessTierPillar,
      canAccessWorkPillar: canAccessWorkPillar ?? this.canAccessWorkPillar,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'canAccessCeoSuite': canAccessCeoSuite,
      'canAccessHrPortal': canAccessHrPortal,
      'canAccessDeptHeadPortal': canAccessDeptHeadPortal,
      'canManageOrders': canManageOrders,
      'canAccessKonarBooks': canAccessKonarBooks,
      'canAssignTasksToOthers': canAssignTasksToOthers,
      'canExportAudit': canExportAudit,
      'canManageRoles': canManageRoles,
      'canAccessAttendancePillar': canAccessAttendancePillar,
      'canAccessHealthPillar': canAccessHealthPillar,
      'canAccessFamilyPillar': canAccessFamilyPillar,
      'canAccessProfilePillar': canAccessProfilePillar,
      'canAccessSocialCausePillar': canAccessSocialCausePillar,
      'canAccessTierPillar': canAccessTierPillar,
      'canAccessWorkPillar': canAccessWorkPillar,
    };
  }

  factory RolePermissions.fromMap(Map<String, dynamic>? map, {String roleType = 'employee', String roleCode = 'GEN'}) {
    if (map == null || map.isEmpty) {
      return RolePermissions.defaultForRole(roleType: roleType, roleCode: roleCode);
    }
    return RolePermissions(
      canAccessCeoSuite: map['canAccessCeoSuite'] ?? (roleType == 'ceo' || roleCode == 'CEO'),
      canAccessHrPortal: map['canAccessHrPortal'] ?? (roleType == 'hr' || roleCode == 'HR'),
      canAccessDeptHeadPortal: map['canAccessDeptHeadPortal'] ??
          (roleType == 'team_lead' || roleType == 'dept_head' || roleCode == 'OTM' || roleCode == 'TL'),
      canManageOrders: map['canManageOrders'] ?? (['OSH', 'OS1', 'OS2', 'ECE', 'OTM', 'TL', 'CEO'].contains(roleCode)),
      canAccessKonarBooks: map['canAccessKonarBooks'] ?? true,
      canAssignTasksToOthers: map['canAssignTasksToOthers'] ??
          (roleType == 'ceo' || roleType == 'hr' || roleType == 'team_lead' || roleCode == 'OTM' || roleCode == 'TL'),
      canExportAudit: map['canExportAudit'] ??
          (roleType == 'ceo' || roleType == 'hr' || roleType == 'team_lead' || roleCode == 'OTM' || roleCode == 'TL'),
      canManageRoles: map['canManageRoles'] ?? (roleType == 'ceo' || roleCode == 'CEO'),
      canAccessAttendancePillar: map['canAccessAttendancePillar'] ?? true,
      canAccessHealthPillar: map['canAccessHealthPillar'] ?? true,
      canAccessFamilyPillar: map['canAccessFamilyPillar'] ?? true,
      canAccessProfilePillar: map['canAccessProfilePillar'] ?? true,
      canAccessSocialCausePillar: map['canAccessSocialCausePillar'] ?? true,
      canAccessTierPillar: map['canAccessTierPillar'] ?? true,
      canAccessWorkPillar: map['canAccessWorkPillar'] ?? true,
    );
  }

  factory RolePermissions.defaultForRole({required String roleType, required String roleCode}) {
    final rt = roleType.toLowerCase().trim();
    final rc = roleCode.toUpperCase().trim();

    if (rt == 'ceo' || rc == 'CEO') {
      return const RolePermissions(
        canAccessCeoSuite: true,
        canAccessHrPortal: true,
        canAccessDeptHeadPortal: true,
        canManageOrders: true,
        canAccessKonarBooks: true,
        canAssignTasksToOthers: true,
        canExportAudit: true,
        canManageRoles: true,
        canAccessAttendancePillar: true,
        canAccessHealthPillar: true,
        canAccessFamilyPillar: true,
        canAccessProfilePillar: true,
        canAccessSocialCausePillar: true,
        canAccessTierPillar: true,
        canAccessWorkPillar: true,
      );
    }

    if (rt == 'hr' || rc == 'HR') {
      return const RolePermissions(
        canAccessCeoSuite: false,
        canAccessHrPortal: true,
        canAccessDeptHeadPortal: false,
        canManageOrders: false,
        canAccessKonarBooks: true,
        canAssignTasksToOthers: true,
        canExportAudit: true,
        canManageRoles: false,
        canAccessAttendancePillar: true,
        canAccessHealthPillar: true,
        canAccessFamilyPillar: true,
        canAccessProfilePillar: true,
        canAccessSocialCausePillar: true,
        canAccessTierPillar: true,
        canAccessWorkPillar: true,
      );
    }

    if (rt == 'team_lead' || rt == 'dept_head' || rc == 'OTM' || rc == 'TL') {
      return const RolePermissions(
        canAccessCeoSuite: false,
        canAccessHrPortal: false,
        canAccessDeptHeadPortal: true,
        canManageOrders: true,
        canAccessKonarBooks: true,
        canAssignTasksToOthers: true,
        canExportAudit: true,
        canManageRoles: false,
        canAccessAttendancePillar: true,
        canAccessHealthPillar: true,
        canAccessFamilyPillar: true,
        canAccessProfilePillar: true,
        canAccessSocialCausePillar: true,
        canAccessTierPillar: true,
        canAccessWorkPillar: true,
      );
    }

    final isOrderManager = ['OSH', 'OS1', 'OS2', 'ECE'].contains(rc);
    return RolePermissions(
      canAccessCeoSuite: false,
      canAccessHrPortal: false,
      canAccessDeptHeadPortal: false,
      canManageOrders: isOrderManager,
      canAccessKonarBooks: true,
      canAssignTasksToOthers: false,
      canExportAudit: false,
      canManageRoles: false,
      canAccessAttendancePillar: true,
      canAccessHealthPillar: true,
      canAccessFamilyPillar: true,
      canAccessProfilePillar: true,
      canAccessSocialCausePillar: true,
      canAccessTierPillar: true,
      canAccessWorkPillar: true,
    );
  }
}

class TrainingStep {
  final int id;
  final String title;
  final String desc;
  bool done;
  String? verifiedBy;

  TrainingStep({
    required this.id,
    required this.title,
    required this.desc,
    required this.done,
    this.verifiedBy,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'desc': desc,
    'done': done,
    'verifiedBy': verifiedBy,
  };

  factory TrainingStep.fromMap(Map<String, dynamic> map) => TrainingStep(
    id: map['id'] ?? 0,
    title: map['title'] ?? '',
    desc: map['desc'] ?? '',
    done: map['done'] ?? false,
    verifiedBy: map['verifiedBy'],
  );
}

class DailyReview {
  final String day;
  final String date;
  final String learnings;
  final String trainerRating;

  DailyReview({
    required this.day,
    required this.date,
    required this.learnings,
    required this.trainerRating,
  });

  Map<String, dynamic> toMap() => {
    'day': day,
    'date': date,
    'learnings': learnings,
    'trainerRating': trainerRating,
  };

  factory DailyReview.fromMap(Map<String, dynamic> map) => DailyReview(
    day: map['day'] ?? '',
    date: map['date'] ?? '',
    learnings: map['learnings'] ?? '',
    trainerRating: map['trainerRating'] ?? '',
  );
}

class Employee {
  final String id;
  final String name;
  final String role;
  String _dept;
  String get dept {
    if (_dept.isNotEmpty) return _dept;
    if (roleType.toLowerCase() == 'ceo' || roleType.toLowerCase() == 'hr' || id.toUpperCase() == 'MN-CEO01' || id == '7' || id.toUpperCase() == 'MN-HR1001') {
      return 'Administration';
    }
    return 'Online Department';
  }
  set dept(String val) => _dept = val;
  final String phone;
  final String email;
  final String avatar;
  final String initials;
  final String doj;
  final String experienceYears;
  final String experienceCategory; // 'experienced' | 'fresher'
  int probationWeeks; // 2 for experienced, 4 for fresher
  String probationStatus; // 'active' | 'cleared'
  String probationEndDate;
  String? trainerName;
  String? trainerRole;
  ProfileCompletion profileCompletion;
  String status; // 'active' | 'onboarding'
  String ragStatus; // 'green' | 'yellow' | 'red'
  String lastActive;
  final String roleType; // 'employee' | 'team_lead' | 'hr' | 'ceo'
  Map<String, dynamic>? fourPillars;
  List<TrainingStep> trainingAgenda;
  List<DailyReview> dailyReviews;
  String dob;
  String relationshipStatus;
  String anniversaryDate;
  String password;
  final String gender; // 'male' | 'female'
  final String empNo; // Employee number from attendance roster (e.g. '7', '6', '33', etc.)
  String roleCode;
  RolePermissions permissions;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    String dept = 'Online Department',
    required this.phone,
    required this.email,
    required this.avatar,
    required this.initials,
    required this.doj,
    required this.experienceYears,
    required this.experienceCategory,
    this.probationWeeks = 0,
    this.probationStatus = 'cleared',
    this.probationEndDate = '',
    this.trainerName,
    this.trainerRole,
    required this.profileCompletion,
    required this.status,
    required this.ragStatus,
    required this.lastActive,
    this.roleType = 'employee',
    this.fourPillars,
    List<TrainingStep>? trainingAgenda,
    List<DailyReview>? dailyReviews,
    this.dob = '',
    this.relationshipStatus = 'Single',
    this.anniversaryDate = '',
    this.password = '',
    this.gender = '',
    this.empNo = '',
    String? roleCode,
    RolePermissions? permissions,
  })  : _dept = dept,
        roleCode = (roleCode != null && roleCode.isNotEmpty)
            ? roleCode
            : KonarTaskCatalog.resolveRoleCode(role, email, id, dept),
        permissions = permissions ??
            RolePermissions.defaultForRole(
              roleType: roleType,
              roleCode: (roleCode != null && roleCode.isNotEmpty)
                  ? roleCode
                  : KonarTaskCatalog.resolveRoleCode(role, email, id, dept),
            ),
        trainingAgenda = trainingAgenda ?? [],
        dailyReviews = dailyReviews ?? [];

  factory Employee.simple({
    required String id,
    required String name,
    required String role,
    String roleType = 'employee',
  }) {
    return Employee(
      id: id,
      name: name,
      role: role,
      roleType: roleType,
      phone: '',
      email: '',
      avatar: 'assets/images/default_avatar.png',
      initials: name.isNotEmpty ? name[0].toUpperCase() : '?',
      doj: '01/01/2026',
      experienceYears: '1',
      experienceCategory: 'experienced',
      status: 'active',
      ragStatus: 'green',
      lastActive: 'Active Now',
      profileCompletion: ProfileCompletion(
        percentage: 100,
        isAuthorized: true,
        photoVerified: true,
        addressVerified: true,
        kycVerified: true,
        sopRolesAcknowledged: true,
      ),
    );
  }

  /// OTM (Online Team Manager - Mr. Praveen Kumar) is not a regular employee
  /// and does not have daily attendance or grooming requirements.
  bool get isOtm =>
      (roleType.toLowerCase() == 'team_lead' && dept.toLowerCase().contains('online')) ||
      role.toLowerCase().contains('online team manager') ||
      id.toUpperCase() == 'MN-TL1002' ||
      email.toLowerCase().contains('praveenkumar');

  /// External Support Staff [Online] are hired by MN Jewel Park to work from outside of the company.
  /// They have certain tasks/milestones based on Konar Book, but NO attendance or grooming requirements.
  bool get isExternalSupport =>
      dept == 'External Support Staff [Online]' ||
      roleType.toLowerCase() == 'external_support' ||
      roleType.toLowerCase() == 'external' ||
      id.toUpperCase().startsWith('EXT-');

  /// Regular staff require attendance and grooming; CEO, Team Leads (Online & Offline), and External Support Staff are completely exempt.
  bool get hasAttendanceAndGrooming =>
      !isTeamLead &&
      !isOtm &&
      !isExternalSupport &&
      roleType.toLowerCase() != 'ceo' &&
      id.toUpperCase() != 'MN-CEO01' &&
      id.toUpperCase() != 'MN-TL1002';

  /// Clean display ID: Shows employee number for roster staff, MN-CEO01 for CEO, MN-TL1002 for OTM, EXT-* for external support
  String get displayEmpId {
    if (empNo.isNotEmpty) return empNo;
    if (roleType.toLowerCase() == 'ceo' || id.toUpperCase() == 'MN-CEO01') return 'MN-CEO01';
    if (id == 'MN-TL1002' || (role.toLowerCase().contains('online team manager') && name.toLowerCase().contains('praveen'))) {
      return 'MN-TL1002';
    }
    if (isExternalSupport) return id;
    return id;
  }

  bool get isFemale {
    if (gender.toLowerCase() == 'female') return true;
    if (gender.toLowerCase() == 'male') return false;
    return ['33', '65', '67'].contains(id.toLowerCase()) ||
        ['kaaviya', 'nisha', 'mithra'].any((n) => name.toLowerCase().contains(n));
  }

  String get genderDisplay => isFemale ? 'Female' : 'Male';

  String get mobile => phone;
  String get department => dept;
  bool get isCeo => roleType.toLowerCase() == 'ceo' || id == 'MN-CEO01' || name.toLowerCase().contains('naveenraaj');
  bool get isHr => (roleType.toLowerCase() == 'hr' || id == '7' || id == 'MN-HR1001') && !isCeo;
  bool get isTeamLead =>
      roleType.toLowerCase() == 'team_lead' ||
      roleType.toLowerCase() == 'dept_head' ||
      role.toLowerCase().contains('team lead') ||
      role.toLowerCase().contains('dept head') ||
      id == 'MN-TL1002';
  bool get isDeptHead => isTeamLead;

  /// Dropdown-safe gender value ('Male' / 'Female'); stored data may be lower-case.
  static String normalizeGender(String raw) =>
      raw.trim().toLowerCase() == 'female' ? 'Female' : 'Male';

  /// Dropdown-safe relationship status ('Single' / 'Married').
  static String normalizeRelationship(String raw) =>
      raw.trim().toLowerCase() == 'married' ? 'Married' : 'Single';

  // Granular Access Getters backed by RolePermissions
  bool get canAccessCeoSuite => permissions.canAccessCeoSuite;
  bool get canAccessHrPortal => permissions.canAccessHrPortal;
  bool get canAccessDeptHeadPortal => permissions.canAccessDeptHeadPortal;
  bool get canManageOrders => permissions.canManageOrders;
  bool get canAccessKonarBooks => permissions.canAccessKonarBooks;
  bool get canAssignTasksToOthers => permissions.canAssignTasksToOthers;
  bool get canExportAudit => permissions.canExportAudit;
  bool get canManageRoles => permissions.canManageRoles;

  // 7 Pillars Access Getters
  bool get canAccessAttendancePillar => permissions.canAccessAttendancePillar;
  bool get canAccessHealthPillar => permissions.canAccessHealthPillar;
  bool get canAccessFamilyPillar => permissions.canAccessFamilyPillar;
  bool get canAccessProfilePillar => permissions.canAccessProfilePillar;
  bool get canAccessSocialCausePillar => permissions.canAccessSocialCausePillar;
  bool get canAccessTierPillar => permissions.canAccessTierPillar;
  bool get canAccessWorkPillar => permissions.canAccessWorkPillar;

  /// Straight-cut short role acronym (e.g. 'CEO', 'HR', 'OTM', 'OSH', 'OS1', 'OS2', 'VPE', 'Ass.VPE', 'AC', 'OSS', 'DVP', 'CC')
  String get roleAcronym {
    final rt = roleType.toLowerCase();
    final r = role.toLowerCase();
    final e = email.toLowerCase();
    final i = id.toUpperCase();

    if (rt == 'ceo' || i == 'MN-CEO01' || r.contains('ceo') || e.contains('ceoofmn') || name.toLowerCase().contains('naveenraaj')) return 'CEO';
    if ((rt == 'hr' || i == '7' || i == 'MN-HR1001' || r.contains('hr') || e.contains('hr@')) && !name.toLowerCase().contains('naveenraaj')) return 'HR';
    if (i == 'MN-TL1002' || e.contains('praveenkumarotm') || r.contains('team manager') || r.contains('otm')) return 'OTM';
    if (e.contains('gokul') || r.contains('sale head') || r.contains('osh')) return 'OSH';
    if (e.contains('mithra') || r.contains('assistant photographer') || r.contains('ass.vpe')) return 'Ass.VPE';
    if (e.contains('aravind') || r.contains('chief photographer') || r.contains('vpe')) return 'VPE';
    if (e.contains('kaaviya') || r.contains('person 1') || r.contains('os1')) return 'OS1';
    if (e.contains('nisha') || r.contains('person 2') || r.contains('os2')) return 'OS2';
    if (e.contains('midhun') || r.contains('analytical') || r.contains('ac')) return 'AC';
    if (e.contains('subash') || r.contains('strategist') || r.contains('oss')) return 'OSS';
    if (e.contains('eshwar') || r.contains('developer') || r.contains('dvp')) return 'DVP';
    if (e.contains('samroy') || r.contains('content creator') || r.contains('cc')) return 'CC';
    if (r.contains('ece')) return 'ECE';

    // Extract inside parentheses if available, e.g. "Online Sale Person 1 (OS1)" -> "OS1"
    final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(role);
    if (parenMatch != null) {
      final code = parenMatch.group(1)!.trim();
      if (code.isNotEmpty && code.length <= 8) return code;
    }

    return straightCutRole;
  }

  /// Straight-cut short role name for headers, badges & strips (never wraps)
  String get straightCutRole {
    final rt = roleType.toLowerCase();
    final r = role.toLowerCase();
    if (rt == 'ceo' || id == 'MN-CEO01' || r.contains('ceo')) return 'CEO';
    if (rt == 'hr' || id == '7' || id == 'MN-HR1001' || r.contains('hr')) return 'HR Manager';
    if (rt == 'team_lead' || rt == 'dept_head' || id == 'MN-TL1002' || r.contains('lead') || r.contains('manager')) {
      return 'Team Lead';
    }
    if (roleCode.isNotEmpty && ['VPE', 'AC', 'OSS', 'DVP', 'CC', 'ECE', 'OSH', 'OS1', 'OS2', 'Ass.VPE'].contains(roleCode)) {
      return roleCode;
    }
    if (isExternalSupport) {
      if (r.contains('vpe') || r.contains('videographer') || r.contains('video') || r.contains('photographer')) return 'VPE';
      if (r.contains('ac') || r.contains('analytical')) return 'AC';
      if (r.contains('oss') || r.contains('strategist')) return 'OSS';
      if (r.contains('dvp') || r.contains('developer')) return 'DVP';
      if (r.contains('cc') || r.contains('content creator')) return 'CC';
      return 'External Support';
    }
    return role;
  }

  /// Straight-cut clean official designation without verbose department suffixes
  String get straightCutDesignation {
    final rt = roleType.toLowerCase();
    final r = role.toLowerCase();
    if (rt == 'ceo' || id == 'MN-CEO01' || r.contains('ceo')) return 'Managing Director & CEO';
    if (rt == 'hr' || id == '7' || id == 'MN-HR1001' || r.contains('hr')) return 'HR Manager';
    if (rt == 'team_lead' || rt == 'dept_head' || id == 'MN-TL1002' || r.contains('lead')) return 'Team Lead';
    if (isExternalSupport) {
      if (r.contains('vpe') || r.contains('videographer') || r.contains('photographer') || r.contains('video editor')) {
        return 'Chief Photographer & Video Editor (VPE)';
      }
      if (r.contains('e-commerce') || r.contains('ecommerce') || r.contains('ece')) return 'E-Commerce Executive (ECE)';
      if (r.contains('ac') || r.contains('analytical')) return 'Online Analytical Consultant (AC)';
      if (r.contains('oss') || r.contains('strategist')) return 'Online Support & Strategist (OSS)';
      if (r.contains('dvp') || r.contains('developer')) return 'Developer (DVP)';
      if (r.contains('cc') || r.contains('content creator')) return 'Content Creator (CC)';
      return 'External Support Staff [Online]';
    }
    return role;
  }

  Employee copyWith({
    String? id,
    String? name,
    String? role,
    String? dept,
    String? phone,
    String? email,
    String? avatar,
    String? initials,
    String? doj,
    String? experienceYears,
    String? experienceCategory,
    int? probationWeeks,
    String? probationStatus,
    String? probationEndDate,
    String? trainerName,
    String? trainerRole,
    ProfileCompletion? profileCompletion,
    String? status,
    String? ragStatus,
    String? lastActive,
    String? roleType,
    Map<String, dynamic>? fourPillars,
    List<TrainingStep>? trainingAgenda,
    List<DailyReview>? dailyReviews,
    String? dob,
    String? relationshipStatus,
    String? anniversaryDate,
    String? password,
    String? gender,
    String? empNo,
    String? roleCode,
    RolePermissions? permissions,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      dept: dept ?? this.dept,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      initials: initials ?? this.initials,
      doj: doj ?? this.doj,
      experienceYears: experienceYears ?? this.experienceYears,
      experienceCategory: experienceCategory ?? this.experienceCategory,
      probationWeeks: probationWeeks ?? this.probationWeeks,
      probationStatus: probationStatus ?? this.probationStatus,
      probationEndDate: probationEndDate ?? this.probationEndDate,
      trainerName: trainerName ?? this.trainerName,
      trainerRole: trainerRole ?? this.trainerRole,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      status: status ?? this.status,
      ragStatus: ragStatus ?? this.ragStatus,
      lastActive: lastActive ?? this.lastActive,
      roleType: roleType ?? this.roleType,
      fourPillars: fourPillars ?? this.fourPillars,
      trainingAgenda: trainingAgenda ?? this.trainingAgenda,
      dailyReviews: dailyReviews ?? this.dailyReviews,
      dob: dob ?? this.dob,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      password: password ?? this.password,
      gender: gender ?? this.gender,
      empNo: empNo ?? this.empNo,
      roleCode: roleCode ?? this.roleCode,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'dept': dept,
      'phone': phone,
      'email': email,
      'avatar': avatar,
      'initials': initials,
      'doj': doj,
      'experienceYears': experienceYears,
      'experienceCategory': experienceCategory,
      'probationWeeks': probationWeeks,
      'probationStatus': probationStatus,
      'probationEndDate': probationEndDate,
      'trainerName': trainerName,
      'trainerRole': trainerRole,
      'profileCompletion': profileCompletion.toMap(),
      'status': status,
      'ragStatus': ragStatus,
      'lastActive': lastActive,
      'roleType': roleType,
      'fourPillars': fourPillars ?? {},
      'trainingAgenda': trainingAgenda.map((s) => s.toMap()).toList(),
      'dailyReviews': dailyReviews.map((r) => r.toMap()).toList(),
      'dob': dob,
      'relationshipStatus': relationshipStatus,
      'anniversaryDate': anniversaryDate,
      'gender': gender,
      'empNo': empNo,
      'roleCode': roleCode,
      'permissions': permissions.toMap(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map, [String? docId]) {
    final docOrId = (docId ?? map['id']?.toString() ?? '').trim().toUpperCase();
    final email = (map['email']?.toString() ?? '').trim().toLowerCase();
    final rawName = (map['name'] as String? ?? '').trim();
    final rawRole = (map['role'] as String? ?? 'Online Team Member').trim();

    final isCeo = docOrId == 'MN-CEO01' ||
        email == 'ceoofmn@mnjpark.com' ||
        map['roleType'] == 'ceo';

    final isHr = docOrId == '7' ||
        docOrId == 'MN-HR1001' ||
        email == 'hr@mnj.com' ||
        map['roleType'] == 'hr';

    final detectedRoleType = isCeo
        ? 'ceo'
        : (isHr
            ? 'hr'
            : (map['roleType'] as String? ??
                (rawRole.toLowerCase().contains('head') || rawRole.toLowerCase().contains('lead')
                    ? 'team_lead'
                    : 'employee')));

    final resolvedId = docId ?? (map['id'] as String? ?? (isCeo ? 'MN-CEO01' : (isHr ? '7' : '')));
    final resolvedName = rawName.isNotEmpty
        ? rawName
        : (isCeo ? 'M N Naveenraaj' : (isHr ? 'Mohankumar G' : 'Online Staff'));

    final resolvedRole = isCeo
        ? 'Managing Director & CEO'
        : (isHr ? 'HR Manager & Operations Custodian' : rawRole);
    final rawDept = (map['dept'] as String?)?.trim() ?? '';
    final resolvedDept = rawDept.isNotEmpty
        ? rawDept
        : (isCeo ? 'Executive Board' : (isHr ? 'HR & Administration' : 'Online Department'));
    final resolvedInitials = isCeo
        ? 'MN'
        : (isHr
            ? 'MG'
            : (map['initials'] as String? ??
                (resolvedName.isNotEmpty ? resolvedName.substring(0, 1).toUpperCase() : 'MN')));

    final roleCode = (map['roleCode'] as String? ?? '').isNotEmpty
        ? (map['roleCode'] as String)
        : KonarTaskCatalog.resolveRoleCode(resolvedRole, email, resolvedId, resolvedDept);

    final permissions = RolePermissions.fromMap(
      map['permissions'] is Map ? Map<String, dynamic>.from(map['permissions'] as Map) : null,
      roleType: detectedRoleType,
      roleCode: roleCode,
    );

    return Employee(
      id: resolvedId,
      name: resolvedName,
      role: resolvedRole,
      dept: resolvedDept,
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      avatar: map['avatar'] as String? ?? '',
      initials: resolvedInitials,
      doj: map['doj'] as String? ?? '',
      experienceYears: map['experienceYears'] as String? ?? 'Fresher (0 yrs)',
      experienceCategory: map['experienceCategory'] as String? ?? 'fresher',
      probationWeeks: (map['probationWeeks'] as num?)?.toInt() ?? 0,
      probationStatus: map['probationStatus'] as String? ?? 'cleared',
      probationEndDate: map['probationEndDate'] as String? ?? 'Completed',
      trainerName: map['trainerName'] as String?,
      trainerRole: map['trainerRole'] as String?,
      roleType: detectedRoleType,
      fourPillars: map['fourPillars'] is Map ? Map<String, dynamic>.from(map['fourPillars'] as Map) : null,
      profileCompletion: map['profileCompletion'] != null && map['profileCompletion'] is Map
          ? ProfileCompletion.fromMap(Map<String, dynamic>.from(map['profileCompletion'] as Map))
          : ProfileCompletion(
              percentage: 0,
              isAuthorized: false,
              photoVerified: false,
              addressVerified: false,
              kycVerified: false,
              sopRolesAcknowledged: false,
            ),
      status: map['status'] as String? ?? 'active',
      ragStatus: map['ragStatus'] as String? ?? 'green',
      lastActive: map['lastActive'] as String? ?? 'Just now',
      trainingAgenda: (map['trainingAgenda'] as List<dynamic>?)
              ?.map((item) => TrainingStep.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      dailyReviews: (map['dailyReviews'] as List<dynamic>?)
              ?.map((item) => DailyReview.fromMap(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          [],
      dob: map['dob'] as String? ?? '',
      relationshipStatus: map['relationshipStatus'] as String? ?? 'Single',
      anniversaryDate: map['anniversaryDate'] as String? ?? '',
      password: '',
      gender: map['gender'] as String? ?? '',
      empNo: map['empNo'] as String? ?? '',
      roleCode: roleCode,
      permissions: permissions,
    );
  }
}
