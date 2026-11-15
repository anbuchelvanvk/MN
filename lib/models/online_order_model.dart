/// Represents a single checklist item in an online order workflow
class OrderChecklistItem {
  final String id;
  final String stageId;
  final String title;
  bool isCompleted;
  String? completedAt;
  String? completedByEmpId;

  OrderChecklistItem({
    required this.id,
    required this.stageId,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
    this.completedByEmpId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'stageId': stageId,
    'title': title,
    'isCompleted': isCompleted,
    'completedAt': completedAt,
    'completedByEmpId': completedByEmpId,
  };

  factory OrderChecklistItem.fromMap(Map<String, dynamic> map) => OrderChecklistItem(
    id: map['id'] ?? '',
    stageId: map['stageId'] ?? '',
    title: map['title'] ?? '',
    isCompleted: map['isCompleted'] ?? false,
    completedAt: map['completedAt'],
    completedByEmpId: map['completedByEmpId'],
  );
}

/// Represents one of the 5 distinct subcategory workflow stages
class OrderStageInfo {
  final int index;
  final String stageId;
  final String stageName;
  String dueDate; // YYYY-MM-DD
  final int totalItems;

  OrderStageInfo({
    required this.index,
    required this.stageId,
    required this.stageName,
    required this.dueDate,
    required this.totalItems,
  });

  Map<String, dynamic> toMap() => {
    'index': index,
    'stageId': stageId,
    'stageName': stageName,
    'dueDate': dueDate,
    'totalItems': totalItems,
  };

  factory OrderStageInfo.fromMap(Map<String, dynamic> map) => OrderStageInfo(
    index: map['index'] ?? 1,
    stageId: map['stageId'] ?? '',
    stageName: map['stageName'] ?? '',
    dueDate: map['dueDate'] ?? '',
    totalItems: map['totalItems'] ?? 0,
  );
}

/// Represents an Online Order handled by OS1 (MN Jewel Park) or OS2 (Vadivam)
class OnlineOrderModel {
  final String orderId;
  final String customerName;
  final String salesChannel; // WhatsApp, Website, Instagram, Direct Call, Showroom
  final String handledByEmpId; // 'MN-1007' (OS1 Kaaviya), 'MN-1008' (OS2 Nisha), etc.
  final String handledByName;
  final String brand; // 'Vadivam' or 'MN Jewel Park'
  final String expectedDeliveryDate; // YYYY-MM-DD
  final String createdAt;
  final String? jewelleryCategory; // 'Pendant', 'Chain', 'Bracelet', 'Earrings'
  final Map<String, dynamic>? jewelleryRequirements;
  String status; // 'active', 'completed', 'overdue', 'reallocated'
  String? reallocatedToEmpId;
  String? reallocatedToName;
  String? reallocatedByEmpId;

  Map<String, OrderStageInfo> stages;
  List<OrderChecklistItem> checklist;

  OnlineOrderModel({
    required this.orderId,
    required this.customerName,
    required this.salesChannel,
    required this.handledByEmpId,
    required this.handledByName,
    required this.brand,
    required this.expectedDeliveryDate,
    required this.createdAt,
    this.jewelleryCategory,
    this.jewelleryRequirements,
    this.status = 'active',
    this.reallocatedToEmpId,
    this.reallocatedToName,
    this.reallocatedByEmpId,
    required this.stages,
    required this.checklist,
  });

  /// Check if Vadivam (OS2 Nisha) or MN Jewel Park (OS1 Kaaviya) is responsible
  String get primaryResponsibleRole => brand == 'Vadivam' ? 'OS2 (Nisha)' : 'OS1 (Kaaviya)';
  String get primaryResponsibleEmpId => brand == 'Vadivam' ? '67' : '65';

  int get completedCount => checklist.where((c) => c.isCompleted).length;
  int get totalCount => checklist.length; // 38 total items
  double get progressPercentage => totalCount == 0 ? 0.0 : completedCount / totalCount;

  int stageCompletedCount(String stageId) =>
      checklist.where((c) => c.stageId == stageId && c.isCompleted).length;

  bool isStageCompleted(String stageId) {
    final items = checklist.where((c) => c.stageId == stageId).toList();
    if (items.isEmpty) return false;
    return items.every((c) => c.isCompleted);
  }

  /// Checks if any stage is past its due date while incomplete
  bool isStageOverdue(String stageId) {
    final stage = stages[stageId];
    if (stage == null || stage.dueDate.isEmpty) return false;
    if (isStageCompleted(stageId)) return false;

    try {
      final due = DateTime.parse(stage.dueDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return today.isAfter(DateTime(due.year, due.month, due.day));
    } catch (_) {
      return false;
    }
  }

  /// Returns list of all stage IDs that are currently overdue
  List<String> get overdueStageIds {
    return stages.keys.where((k) => isStageOverdue(k)).toList();
  }

  bool get hasAnyOverdueStage => overdueStageIds.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'customerName': customerName,
    'salesChannel': salesChannel,
    'handledByEmpId': handledByEmpId,
    'handledByName': handledByName,
    'brand': brand,
    'expectedDeliveryDate': expectedDeliveryDate,
    'createdAt': createdAt,
    'jewelleryCategory': jewelleryCategory,
    'jewelleryRequirements': jewelleryRequirements,
    'status': status,
    'reallocatedToEmpId': reallocatedToEmpId,
    'reallocatedToName': reallocatedToName,
    'reallocatedByEmpId': reallocatedByEmpId,
    'stages': stages.map((k, v) => MapEntry(k, v.toMap())),
    'checklist': checklist.map((c) => c.toMap()).toList(),
  };

  factory OnlineOrderModel.fromMap(Map<String, dynamic> map) {
    final rawStages = map['stages'] as Map? ?? {};
    final parsedStages = <String, OrderStageInfo>{};
    rawStages.forEach((k, v) {
      parsedStages[k.toString()] = OrderStageInfo.fromMap(Map<String, dynamic>.from(v as Map));
    });

    final rawChecklist = map['checklist'] as List? ?? [];
    final parsedChecklist = rawChecklist
        .map((c) => OrderChecklistItem.fromMap(Map<String, dynamic>.from(c as Map)))
        .toList();

    return OnlineOrderModel(
      orderId: map['orderId'] ?? '',
      customerName: map['customerName'] ?? '',
      salesChannel: map['salesChannel'] ?? 'WhatsApp',
      handledByEmpId: map['handledByEmpId'] ?? '',
      handledByName: map['handledByName'] ?? '',
      brand: map['brand'] ?? 'MN Jewel Park',
      expectedDeliveryDate: map['expectedDeliveryDate'] ?? '',
      createdAt: map['createdAt'] ?? '',
      jewelleryCategory: map['jewelleryCategory'],
      jewelleryRequirements: map['jewelleryRequirements'] != null
          ? Map<String, dynamic>.from(map['jewelleryRequirements'] as Map)
          : null,
      status: map['status'] ?? 'active',
      reallocatedToEmpId: map['reallocatedToEmpId'],
      reallocatedToName: map['reallocatedToName'],
      reallocatedByEmpId: map['reallocatedByEmpId'],
      stages: parsedStages.isNotEmpty ? parsedStages : createDefaultStages(),
      checklist: parsedChecklist.isNotEmpty ? parsedChecklist : createDefaultChecklist(),
    );
  }

  /// Default 5 Stages with SLA templates
  static Map<String, OrderStageInfo> createDefaultStages({DateTime? baseDate}) {
    final start = baseDate ?? DateTime.now();
    String fmt(DateTime dt) =>
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

    return {
      'stage1': OrderStageInfo(
        index: 1,
        stageId: 'stage1',
        stageName: 'Customer Verification',
        dueDate: fmt(start.add(const Duration(days: 1))),
        totalItems: 5,
      ),
      'stage2': OrderStageInfo(
        index: 2,
        stageId: 'stage2',
        stageName: 'Product Verification',
        dueDate: fmt(start.add(const Duration(days: 2))),
        totalItems: 9,
      ),
      'stage3': OrderStageInfo(
        index: 3,
        stageId: 'stage3',
        stageName: 'Payment & Billing',
        dueDate: fmt(start.add(const Duration(days: 3))),
        totalItems: 7,
      ),
      'stage4': OrderStageInfo(
        index: 4,
        stageId: 'stage4',
        stageName: 'Packing & Dispatch',
        dueDate: fmt(start.add(const Duration(days: 5))),
        totalItems: 10,
      ),
      'stage5': OrderStageInfo(
        index: 5,
        stageId: 'stage5',
        stageName: 'Delivery & Customer Closure',
        dueDate: fmt(start.add(const Duration(days: 7))),
        totalItems: 7,
      ),
    };
  }

  /// Full 38 Items matching the specification photos
  static List<OrderChecklistItem> createDefaultChecklist() {
    return [
      // 1. Customer Verification (5 items)
      OrderChecklistItem(id: 'CV-1', stageId: 'stage1', title: 'Customer name recorded correctly'),
      OrderChecklistItem(id: 'CV-2', stageId: 'stage1', title: 'Active mobile number verified'),
      OrderChecklistItem(id: 'CV-3', stageId: 'stage1', title: 'Complete delivery address and PIN code confirmed'),
      OrderChecklistItem(id: 'CV-4', stageId: 'stage1', title: 'Landmark and alternate contact number collected'),
      OrderChecklistItem(id: 'CV-5', stageId: 'stage1', title: 'Order details, final price and delivery timeline confirmed in writing'),

      // 2. Product Verification (9 items)
      OrderChecklistItem(id: 'PV-1', stageId: 'stage2', title: 'Product code / SKU and design verified'),
      OrderChecklistItem(id: 'PV-2', stageId: 'stage2', title: 'Actual product physically checked against order'),
      OrderChecklistItem(id: 'PV-3', stageId: 'stage2', title: 'Product images shared for customer confirmation'),
      OrderChecklistItem(id: 'PV-4', stageId: 'stage2', title: 'Product video shared with customer'),
      OrderChecklistItem(id: 'PV-5', stageId: 'stage2', title: 'Size, length, colour and specifications verified'),
      OrderChecklistItem(id: 'PV-6', stageId: 'stage2', title: 'Physical stock confirmed and reserved'),
      OrderChecklistItem(id: 'PV-7', stageId: 'stage2', title: 'Actual product weight recorded'),
      OrderChecklistItem(id: 'PV-8', stageId: 'stage2', title: 'Purity, hallmark and HUID details verified, if applicable'),
      OrderChecklistItem(id: 'PV-9', stageId: 'stage2', title: 'Final price, value addition, stones and charges confirmed'),

      // 3. Payment & Billing (7 items)
      OrderChecklistItem(id: 'PB-1', stageId: 'stage3', title: 'Payment method and total amount confirmed'),
      OrderChecklistItem(id: 'PB-2', stageId: 'stage3', title: 'Payment received and verified through bank or payment gateway'),
      OrderChecklistItem(id: 'PB-3', stageId: 'stage3', title: 'Advance and balance payment reconciled, if applicable'),
      OrderChecklistItem(id: 'PB-4', stageId: 'stage3', title: 'Internal accounts verification completed'),
      OrderChecklistItem(id: 'PB-5', stageId: 'stage3', title: 'Customer billing details verified'),
      OrderChecklistItem(id: 'PB-6', stageId: 'stage3', title: 'Final invoice generated and checked'),
      OrderChecklistItem(id: 'PB-7', stageId: 'stage3', title: 'Invoice number and payment reference recorded'),

      // 4. Packing & Dispatch (10 items)
      OrderChecklistItem(id: 'PD-1', stageId: 'stage4', title: 'Product cleaned and final quality check completed'),
      OrderChecklistItem(id: 'PD-2', stageId: 'stage4', title: 'Product weight and design rechecked before packing'),
      OrderChecklistItem(id: 'PD-3', stageId: 'stage4', title: 'Applicable purity document prepared'),
      OrderChecklistItem(id: 'PD-4', stageId: 'stage4', title: 'Invoice and product details cross-checked'),
      OrderChecklistItem(id: 'PD-5', stageId: 'stage4', title: 'Product securely packed with protective packaging'),
      OrderChecklistItem(id: 'PD-6', stageId: 'stage4', title: 'Purity slip and invoice copy included'),
      OrderChecklistItem(id: 'PD-7', stageId: 'stage4', title: 'Packed parcel photographed and recorded'),
      OrderChecklistItem(id: 'PD-8', stageId: 'stage4', title: 'Dispatch date and courier details recorded'),
      OrderChecklistItem(id: 'PD-9', stageId: 'stage4', title: 'Tracking number captured and saved'),
      OrderChecklistItem(id: 'PD-10', stageId: 'stage4', title: 'Dispatch approved by authorised person'),

      // 5. Delivery & Customer Closure (7 items)
      OrderChecklistItem(id: 'DC-1', stageId: 'stage5', title: 'Dispatch confirmation sent to customer'),
      OrderChecklistItem(id: 'DC-2', stageId: 'stage5', title: 'Tracking details shared with customer'),
      OrderChecklistItem(id: 'DC-3', stageId: 'stage5', title: 'Delivery status monitored until completion'),
      OrderChecklistItem(id: 'DC-4', stageId: 'stage5', title: 'Delivery confirmation obtained'),
      OrderChecklistItem(id: 'DC-5', stageId: 'stage5', title: 'Customer satisfaction and feedback requested'),
      OrderChecklistItem(id: 'DC-6', stageId: 'stage5', title: 'Complaint, damage or return issue recorded if any'),
      OrderChecklistItem(id: 'DC-7', stageId: 'stage5', title: 'Order marked COMPLETED in system'),
    ];
  }
}
