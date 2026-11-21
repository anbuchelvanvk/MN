class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String receiverId; // Specific empId or 'ALL_HANDS' for group broadcast
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final List<String> likedBy;
  final String? attachmentType;
  final String? attachmentUrl;
  final String? replyToId;
  final String? replyToSenderName;
  final String? replyToText;
  final bool isPinned;
  final DateTime? pinnedUntil;
  final String? pinnedBy;
  final DateTime? pinnedAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.readBy = const [],
    this.likedBy = const [],
    this.attachmentType,
    this.attachmentUrl,
    this.replyToId,
    this.replyToSenderName,
    this.replyToText,
    this.isPinned = false,
    this.pinnedUntil,
    this.pinnedBy,
    this.pinnedAt,
  });

  bool get isAllHands => receiverId == 'ALL_HANDS';
  bool isSentBy(String empId) => senderId.toLowerCase() == empId.toLowerCase();
  bool isReadBy(String empId) => isRead || readBy.any((id) => id.toLowerCase() == empId.toLowerCase());
  bool isLikedBy(String empId) => likedBy.any((id) => id.toLowerCase() == empId.toLowerCase());
  int get likesCount => likedBy.length;

  /// Check if the message is currently active as pinned (considers expiry duration)
  bool get isCurrentlyPinned {
    if (!isPinned) return false;
    if (pinnedUntil == null) return true; // Forever
    return pinnedUntil!.isAfter(DateTime.now());
  }

  /// Check whether this message tags or @mentions the given user
  bool mentionsUser(String userEmpId, String userName) {
    if (senderId.toLowerCase() == userEmpId.toLowerCase()) return false;
    final lowerText = text.toLowerCase();
    if (lowerText.contains('@all') || lowerText.contains('@everyone') || lowerText.contains('@team')) {
      return true;
    }

    final cleanName = userName.trim().toLowerCase();
    if (cleanName.isEmpty) return false;

    if (lowerText.contains('@$cleanName')) return true;

    // Check individual name parts (e.g. '@naveenraaj', '@praveenkumar', '@kaaviya', '@mohankumar')
    final tokens = cleanName.split(RegExp(r'\s+')).where((t) => t.length > 2);
    for (final t in tokens) {
      if (lowerText.contains('@$t')) return true;
    }
    return false;
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? receiverId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    List<String>? readBy,
    List<String>? likedBy,
    String? attachmentType,
    String? attachmentUrl,
    String? replyToId,
    String? replyToSenderName,
    String? replyToText,
    bool? isPinned,
    DateTime? pinnedUntil,
    String? pinnedBy,
    DateTime? pinnedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      likedBy: likedBy ?? this.likedBy,
      attachmentType: attachmentType ?? this.attachmentType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      replyToId: replyToId ?? this.replyToId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToText: replyToText ?? this.replyToText,
      isPinned: isPinned ?? this.isPinned,
      pinnedUntil: pinnedUntil ?? this.pinnedUntil,
      pinnedBy: pinnedBy ?? this.pinnedBy,
      pinnedAt: pinnedAt ?? this.pinnedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'senderRole': senderRole,
    'receiverId': receiverId,
    'text': text,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'isRead': isRead,
    'readBy': readBy,
    'likedBy': likedBy,
    'attachmentType': attachmentType,
    'attachmentUrl': attachmentUrl,
    'replyToId': replyToId,
    'replyToSenderName': replyToSenderName,
    'replyToText': replyToText,
    'isPinned': isPinned,
    'pinnedUntil': pinnedUntil?.toIso8601String(),
    'pinnedBy': pinnedBy,
    'pinnedAt': pinnedAt?.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? 'MSG-${DateTime.now().millisecondsSinceEpoch}',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? '',
      senderRole: json['senderRole']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? 'ALL_HANDS',
      text: json['text']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString())?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0))
          : DateTime.fromMillisecondsSinceEpoch(0),
      isRead: json['isRead'] == true,
      readBy: (json['readBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
      likedBy: (json['likedBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
      attachmentType: json['attachmentType']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      replyToId: json['replyToId']?.toString(),
      replyToSenderName: json['replyToSenderName']?.toString(),
      replyToText: json['replyToText']?.toString(),
      isPinned: json['isPinned'] == true,
      pinnedUntil: json['pinnedUntil'] != null
          ? DateTime.tryParse(json['pinnedUntil'].toString())
          : null,
      pinnedBy: json['pinnedBy']?.toString(),
      pinnedAt: json['pinnedAt'] != null
          ? DateTime.tryParse(json['pinnedAt'].toString())
          : null,
    );
  }
}
