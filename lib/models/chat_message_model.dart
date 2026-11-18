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
  });

  bool get isAllHands => receiverId == 'ALL_HANDS';
  bool isSentBy(String empId) => senderId.toLowerCase() == empId.toLowerCase();
  bool isReadBy(String empId) => isRead || readBy.any((id) => id.toLowerCase() == empId.toLowerCase());
  bool isLikedBy(String empId) => likedBy.any((id) => id.toLowerCase() == empId.toLowerCase());
  int get likesCount => likedBy.length;

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
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'senderRole': senderRole,
    'receiverId': receiverId,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'readBy': readBy,
    'likedBy': likedBy,
    'attachmentType': attachmentType,
    'attachmentUrl': attachmentUrl,
    'replyToId': replyToId,
    'replyToSenderName': replyToSenderName,
    'replyToText': replyToText,
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
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] == true,
      readBy: (json['readBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
      likedBy: (json['likedBy'] as List?)?.map((e) => e.toString()).toList() ?? [],
      attachmentType: json['attachmentType']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      replyToId: json['replyToId']?.toString(),
      replyToSenderName: json['replyToSenderName']?.toString(),
      replyToText: json['replyToText']?.toString(),
    );
  }
}
