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
  final String dept;
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

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.dept,
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
    this.password = 'mnj12345',
  })  : trainingAgenda = trainingAgenda ?? [],
        dailyReviews = dailyReviews ?? [];

  String get mobile => phone;

  /// Straight-cut short role name for headers, badges & strips (never wraps)
  String get straightCutRole {
    final rt = roleType.toLowerCase();
    final r = role.toLowerCase();
    if (rt == 'ceo' || id == 'MN-CEO01' || r.contains('ceo')) return 'CEO';
    if (rt == 'hr' || id == 'MN-HR1001' || r.contains('hr')) return 'HR Manager';
    if (rt == 'team_lead' || rt == 'dept_head' || id == 'MN-TL1002' || r.contains('lead') || r.contains('manager')) {
      return 'Team Lead';
    }
    return role;
  }

  /// Straight-cut clean official designation without verbose department suffixes
  String get straightCutDesignation {
    final rt = roleType.toLowerCase();
    final r = role.toLowerCase();
    if (rt == 'ceo' || id == 'MN-CEO01' || r.contains('ceo')) return 'Managing Director & CEO';
    if (rt == 'hr' || id == 'MN-HR1001' || r.contains('hr')) return 'HR Manager';
    if (rt == 'team_lead' || rt == 'dept_head' || id == 'MN-TL1002' || r.contains('lead')) return 'Team Lead';
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
      'password': password,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map, [String? docId]) {
    final docOrId = (docId ?? map['id']?.toString() ?? '').trim().toUpperCase();
    final email = (map['email']?.toString() ?? '').trim().toLowerCase();
    final rawName = map['name'] as String? ?? '';
    final rawRole = (map['role'] as String? ?? 'Online Team Member');

    final isCeo = docOrId == 'MN-CEO01' ||
        email == 'ceoofmn@mnjpark.com' ||
        map['roleType'] == 'ceo' ||
        rawRole.toLowerCase().contains('managing director') ||
        rawRole.toLowerCase().contains('ceo') ||
        rawName.toLowerCase().contains('executive ceo') ||
        rawName.toLowerCase().contains('senthil');

    final isHr = docOrId == 'MN-HR1001' ||
        email == 'hr@mnj.com' ||
        map['roleType'] == 'hr' ||
        rawRole.toLowerCase().contains('hr manager') ||
        rawName.toLowerCase().contains('mohankumar') ||
        rawName.toLowerCase().contains('priyanka');

    final detectedRoleType = isCeo
        ? 'ceo'
        : (isHr
            ? 'hr'
            : (map['roleType'] as String? ??
                (rawRole.toLowerCase().contains('head') || rawRole.toLowerCase().contains('lead')
                    ? 'team_lead'
                    : 'employee')));

    final resolvedId = isCeo ? 'MN-CEO01' : (isHr ? 'MN-HR1001' : (docId ?? (map['id'] as String? ?? '')));
    final resolvedName = isCeo ? 'M N Naveenraaj' : (isHr ? 'Mohankumar G' : rawName);
    final resolvedRole = isCeo
        ? 'Managing Director & CEO'
        : (isHr ? 'HR Manager & Operations Custodian' : rawRole);
    final resolvedDept = isCeo ? 'Executive Board' : (map['dept'] as String? ?? 'Online Department');
    final resolvedInitials = isCeo
        ? 'MN'
        : (isHr
            ? 'MG'
            : (map['initials'] as String? ??
                (resolvedName.isNotEmpty ? resolvedName.substring(0, 1).toUpperCase() : 'MN')));

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
      password: map['password'] as String? ?? 'mnj12345',
    );
  }
}
