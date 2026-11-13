import 'package:flutter/material.dart';

class NoteColorOption {
  final String name;
  final Color bg;
  final Color border;
  final Color textDark;
  final Color accent;

  const NoteColorOption({
    required this.name,
    required this.bg,
    required this.border,
    required this.textDark,
    required this.accent,
  });
}

class PersonalNoteColors {
  static const List<NoteColorOption> options = [
    NoteColorOption(
      name: 'Classic White',
      bg: Color(0xFFFFFFFF),
      border: Color(0xFFE2E8F0),
      textDark: Color(0xFF0F172A),
      accent: Color(0xFF64748B),
    ),
    NoteColorOption(
      name: 'Rose Blush',
      bg: Color(0xFFFFF1F4),
      border: Color(0xFFFECDD3),
      textDark: Color(0xFF881337),
      accent: Color(0xFFE11D48),
    ),
    NoteColorOption(
      name: 'Warm Amber',
      bg: Color(0xFFFFFBEB),
      border: Color(0xFFFDE68A),
      textDark: Color(0xFF78350F),
      accent: Color(0xFFD97706),
    ),
    NoteColorOption(
      name: 'Mint Breeze',
      bg: Color(0xFFECFDF5),
      border: Color(0xFFA7F3D0),
      textDark: Color(0xFF064E3B),
      accent: Color(0xFF059669),
    ),
    NoteColorOption(
      name: 'Sky Azure',
      bg: Color(0xFFEFF6FF),
      border: Color(0xFFBFDBFE),
      textDark: Color(0xFF1E3A8A),
      accent: Color(0xFF2563EB),
    ),
    NoteColorOption(
      name: 'Royal Lavender',
      bg: Color(0xFFFAF5FF),
      border: Color(0xFFE9D5FF),
      textDark: Color(0xFF581C87),
      accent: Color(0xFF7C3AED),
    ),
  ];

  static NoteColorOption getOption(int index) {
    if (index < 0 || index >= options.length) return options[0];
    return options[index];
  }
}

class PersonalNote {
  final String id;
  final String ownerEmpId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int colorIndex;
  final bool isPinned;

  PersonalNote({
    required this.id,
    required this.ownerEmpId,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.colorIndex = 0,
    this.isPinned = false,
  });

  PersonalNote copyWith({
    String? id,
    String? ownerEmpId,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? colorIndex,
    bool? isPinned,
  }) {
    return PersonalNote(
      id: id ?? this.id,
      ownerEmpId: ownerEmpId ?? this.ownerEmpId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      colorIndex: colorIndex ?? this.colorIndex,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerEmpId': ownerEmpId,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'colorIndex': colorIndex,
    'isPinned': isPinned,
  };

  factory PersonalNote.fromJson(Map<String, dynamic> json) {
    return PersonalNote(
      id: json['id']?.toString() ?? 'NOTE-${DateTime.now().millisecondsSinceEpoch}',
      ownerEmpId: json['ownerEmpId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      colorIndex: json['colorIndex'] is int ? json['colorIndex'] as int : 0,
      isPinned: json['isPinned'] == true,
    );
  }
}

