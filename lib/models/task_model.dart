class TaskProof {
  final String type; // 'photo' | 'note'
  final String content;
  final String? photoUrl;
  final String timestamp;

  TaskProof({
    required this.type,
    required this.content,
    this.photoUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'type': type,
    'content': content,
    'photoUrl': photoUrl,
    'timestamp': timestamp,
  };

  factory TaskProof.fromMap(Map<String, dynamic> map) => TaskProof(
    type: map['type']?.toString() ?? 'photo',
    content: map['content']?.toString() ?? '',
    photoUrl: map['photoUrl']?.toString(),
    timestamp: map['timestamp']?.toString() ?? '',
  );
}

class PostponeInfo {
  final String reason;
  final String postponedTo;
  final String postponedAt;

  PostponeInfo({
    required this.reason,
    required this.postponedTo,
    required this.postponedAt,
  });

  Map<String, dynamic> toMap() => {
    'reason': reason,
    'postponedTo': postponedTo,
    'postponedAt': postponedAt,
  };

  factory PostponeInfo.fromMap(Map<String, dynamic> map) => PostponeInfo(
    reason: map['reason']?.toString() ?? '',
    postponedTo: map['postponedTo']?.toString() ?? '',
    postponedAt: map['postponedAt']?.toString() ?? '',
  );
}

class TaskItem {
  final String id;
  final String empId;
  final String title;
  final String category;
  final bool isDefaultSop;
  final String assignedByRole; // 'system' | 'dept_head' | 'ceo' | 'employee'
  final String assignedByName;
  final String due;
  final String priority; // 'Critical SLA' | 'High' | 'Standard' | 'Normal'
  String status; // 'pending' | 'completed' | 'postponed'
  TaskProof? proof;
  PostponeInfo? postponeInfo;
  final bool isImmutable;
  String? lastCompletedDate; // 'YYYY-MM-DD' for daily recurring SOP reset check

  TaskItem({
    required this.id,
    required this.empId,
    required this.title,
    required this.category,
    required this.isDefaultSop,
    required this.assignedByRole,
    required this.assignedByName,
    required this.due,
    required this.priority,
    required this.status,
    this.proof,
    this.postponeInfo,
    this.isImmutable = true,
    this.lastCompletedDate,
  });

  TaskItem copyWith({
    String? id,
    String? empId,
    String? title,
    String? category,
    bool? isDefaultSop,
    String? assignedByRole,
    String? assignedByName,
    String? due,
    String? priority,
    String? status,
    TaskProof? proof,
    PostponeInfo? postponeInfo,
    bool? isImmutable,
    String? lastCompletedDate,
  }) {
    return TaskItem(
      id: id ?? this.id,
      empId: empId ?? this.empId,
      title: title ?? this.title,
      category: category ?? this.category,
      isDefaultSop: isDefaultSop ?? this.isDefaultSop,
      assignedByRole: assignedByRole ?? this.assignedByRole,
      assignedByName: assignedByName ?? this.assignedByName,
      due: due ?? this.due,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      proof: proof ?? this.proof,
      postponeInfo: postponeInfo ?? this.postponeInfo,
      isImmutable: isImmutable ?? this.isImmutable,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
    );
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isPostponed => status == 'postponed';

  Map<String, dynamic> toMap() => {
    'id': id,
    'empId': empId,
    'title': title,
    'category': category,
    'isDefaultSop': isDefaultSop,
    'assignedByRole': assignedByRole,
    'assignedByName': assignedByName,
    'due': due,
    'priority': priority,
    'status': status,
    'proof': proof?.toMap(),
    'postponeInfo': postponeInfo?.toMap(),
    'isImmutable': isImmutable,
    'lastCompletedDate': lastCompletedDate,
  };

  factory TaskItem.fromMap(Map<String, dynamic> map) => TaskItem(
    id: map['id']?.toString() ?? '',
    empId: map['empId']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    category: map['category']?.toString() ?? 'Personal SOP',
    isDefaultSop: map['isDefaultSop'] == true,
    assignedByRole: map['assignedByRole']?.toString() ?? 'employee',
    assignedByName: map['assignedByName']?.toString() ?? 'Self',
    due: map['due']?.toString() ?? '05:00 PM',
    priority: map['priority']?.toString() ?? 'Normal',
    status: map['status']?.toString() ?? 'pending',
    proof: map['proof'] is Map ? TaskProof.fromMap(Map<String, dynamic>.from(map['proof'] as Map)) : null,
    postponeInfo: map['postponeInfo'] is Map ? PostponeInfo.fromMap(Map<String, dynamic>.from(map['postponeInfo'] as Map)) : null,
    isImmutable: map['isImmutable'] == true,
    lastCompletedDate: map['lastCompletedDate']?.toString(),
  );
}
