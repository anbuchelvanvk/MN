/// Activity log item for Pillar 2 (Family & Harmony)
class FamilyActivityItem {
  final String id;
  final String activityName;
  final String category; // 'Family' or 'Friends & Colleagues'
  final String subCategory; // e.g. 'Kids & Parenting', 'Spouse', 'Elders', 'Peers', etc.
  final double hoursSpent;
  final String iconEmoji;
  final String? notes;
  final DateTime timestamp;
  final String timeString;

  FamilyActivityItem({
    required this.id,
    required this.activityName,
    required this.category,
    this.subCategory = 'General',
    required this.hoursSpent,
    this.iconEmoji = '❤️',
    this.notes,
    required this.timestamp,
    required this.timeString,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'activityName': activityName,
    'category': category,
    'subCategory': subCategory,
    'hoursSpent': hoursSpent,
    'iconEmoji': iconEmoji,
    'notes': notes,
    'timestamp': timestamp.toIso8601String(),
    'timeString': timeString,
  };

  Map<String, dynamic> toMap() => toJson();

  factory FamilyActivityItem.fromMap(Map<String, dynamic> map) => FamilyActivityItem(
    id: map['id'] ?? '',
    activityName: map['activityName'] ?? '',
    category: map['category'] ?? 'Family',
    subCategory: map['subCategory'] ?? 'General',
    hoursSpent: (map['hoursSpent'] as num?)?.toDouble() ?? 1.0,
    iconEmoji: map['iconEmoji'] ?? '❤️',
    notes: map['notes'],
    timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) ?? DateTime.now() : DateTime.now(),
    timeString: map['timeString'] ?? '',
  );
}

/// Pre-configured recommended activity templates
class FamilyActivityPreset {
  final String name;
  final String category; // 'Family' or 'Friends & Colleagues'
  final String subCategory;
  final double defaultHours;
  final String iconEmoji;
  final String description;

  const FamilyActivityPreset({
    required this.name,
    required this.category,
    required this.subCategory,
    required this.defaultHours,
    required this.iconEmoji,
    required this.description,
  });

  static const List<FamilyActivityPreset> familyPresets = [
    FamilyActivityPreset(
      name: 'Family Dinner',
      category: 'Family',
      subCategory: 'Evening Meal',
      defaultHours: 1.0,
      iconEmoji: '🍽️',
      description: 'Shared evening meal time without digital distractions',
    ),
    FamilyActivityPreset(
      name: 'Kids Homework',
      category: 'Family',
      subCategory: 'Kids & Parenting',
      defaultHours: 1.5,
      iconEmoji: '📚',
      description: 'Academic tutoring, school project help & storytelling',
    ),
    FamilyActivityPreset(
      name: 'Park Outing',
      category: 'Family',
      subCategory: 'Recreation',
      defaultHours: 2.0,
      iconEmoji: '🏞️',
      description: 'Outdoor fresh air walk, jogging & playground games',
    ),
    FamilyActivityPreset(
      name: 'Parents Care',
      category: 'Family',
      subCategory: 'Elders Care',
      defaultHours: 1.5,
      iconEmoji: '🩺',
      description: 'Doctor appointments, medicines check-in & elder talks',
    ),
    FamilyActivityPreset(
      name: 'Movie Night',
      category: 'Family',
      subCategory: 'Entertainment',
      defaultHours: 2.0,
      iconEmoji: '🎬',
      description: 'Family cinema or carrom, chess, ludo board games',
    ),
    FamilyActivityPreset(
      name: 'Family Cooking',
      category: 'Family',
      subCategory: 'Teamwork',
      defaultHours: 1.0,
      iconEmoji: '🍳',
      description: 'Preparing homemade meals & snacks as a family',
    ),
    FamilyActivityPreset(
      name: 'Bedtime Stories',
      category: 'Family',
      subCategory: 'Kids & Parenting',
      defaultHours: 0.5,
      iconEmoji: '🛏️',
      description: 'Heart-to-heart night conversations and gratitude',
    ),
    FamilyActivityPreset(
      name: 'Weekend Drive',
      category: 'Family',
      subCategory: 'Travel',
      defaultHours: 3.0,
      iconEmoji: '🚗',
      description: 'Sightseeing, temple visit or weekend getaway',
    ),
    FamilyActivityPreset(
      name: 'Family Prayer',
      category: 'Family',
      subCategory: 'Spiritual',
      defaultHours: 0.5,
      iconEmoji: '🛕',
      description: 'Evening puja, meditation & spiritual gratitude',
    ),
  ];

  static const List<FamilyActivityPreset> friendsColleaguesPresets = [
    FamilyActivityPreset(
      name: 'Chai Break',
      category: 'Friends & Colleagues',
      subCategory: 'Casual Hangout',
      defaultHours: 0.5,
      iconEmoji: '☕',
      description: 'De-stressing coffee/chai talk with peers & friends',
    ),
    FamilyActivityPreset(
      name: 'Team Lunch',
      category: 'Friends & Colleagues',
      subCategory: 'Dining',
      defaultHours: 1.0,
      iconEmoji: '🍱',
      description: 'Bonding over delicious food during breaks or after work',
    ),
    FamilyActivityPreset(
      name: 'Sports & Gym',
      category: 'Friends & Colleagues',
      subCategory: 'Fitness & Sports',
      defaultHours: 1.5,
      iconEmoji: '🏸',
      description: 'Cardio workout, cricket, badminton or gym session',
    ),
    FamilyActivityPreset(
      name: 'Evening Hangout',
      category: 'Friends & Colleagues',
      subCategory: 'Recreation',
      defaultHours: 1.5,
      iconEmoji: '🍕',
      description: 'Unwinding after work with hearty laughs and chats',
    ),
    FamilyActivityPreset(
      name: 'Peer Mentoring',
      category: 'Friends & Colleagues',
      subCategory: 'Career Growth',
      defaultHours: 1.0,
      iconEmoji: '💡',
      description: 'Collaborative learning, brainstorming and skill growth',
    ),
    FamilyActivityPreset(
      name: 'Celebrations',
      category: 'Friends & Colleagues',
      subCategory: 'Social Celebration',
      defaultHours: 2.5,
      iconEmoji: '🎉',
      description: 'Colleague birthdays, promotions or festive gatherings',
    ),
    FamilyActivityPreset(
      name: 'Gaming Session',
      category: 'Friends & Colleagues',
      subCategory: 'Entertainment',
      defaultHours: 1.5,
      iconEmoji: '🎮',
      description: 'Weekend online or board gaming session with friends',
    ),
  ];
}
