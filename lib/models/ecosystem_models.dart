class HandoverStep {
  final String name;
  final String dept;
  String status; // 'done' | 'in_progress' | 'pending'
  String? completedBy;

  HandoverStep({
    required this.name,
    required this.dept,
    required this.status,
    this.completedBy,
  });
}

class Handover {
  final String id;
  final String batch;
  String stage;
  final String fromDept;
  final String toDept;
  final String assignedTo;
  String status; // 'in_progress' | 'completed'
  final String handoffTime;
  final List<HandoverStep> steps;

  Handover({
    required this.id,
    required this.batch,
    required this.stage,
    required this.fromDept,
    required this.toDept,
    required this.assignedTo,
    required this.status,
    required this.handoffTime,
    required this.steps,
  });
}

class Blocker {
  final String id;
  final String raisedByDept;
  final String raisedByName;
  final String blockingDept;
  final String issue;
  final String severity;
  String status; // 'active' | 'resolved'
  final String time;
  String? responseText; // The other department's answer explaining why
  String? respondedByName; // Who in the blocking team responded
  String? respondedAt;
  bool isLate; // Escalated as late/overdue past SLA
  String slaDue;

  Blocker({
    required this.id,
    required this.raisedByDept,
    required this.raisedByName,
    required this.blockingDept,
    required this.issue,
    required this.severity,
    required this.status,
    required this.time,
    this.responseText,
    this.respondedByName,
    this.respondedAt,
    this.isLate = false,
    this.slaDue = '04:00 PM',
  });

  bool get isOverdue => isLate || (status == 'active' && isLate);
}

class ReadinessDept {
  final String name;
  final String task;
  bool signed;
  String signedBy;
  String time;

  ReadinessDept({
    required this.name,
    required this.task,
    required this.signed,
    required this.signedBy,
    required this.time,
  });
}

class ReadinessGate {
  String status;
  final String targetTime;
  int signedCount;
  final int totalCount;
  final List<ReadinessDept> depts;

  ReadinessGate({
    required this.status,
    required this.targetTime,
    required this.signedCount,
    required this.totalCount,
    required this.depts,
  });
}

class Incident {
  final String id;
  final String title;
  final String reportedBy;
  final String dispatchedTo;
  final String severity;
  String status; // 'resolved' | 'active'
  final String time;
  final String resolution;

  Incident({
    required this.id,
    required this.title,
    required this.reportedBy,
    required this.dispatchedTo,
    required this.severity,
    required this.status,
    required this.time,
    required this.resolution,
  });
}

class ShiftHandover {
  final String id;
  final String shift;
  final String date;
  final String outgoingLead;
  final String incomingLead;
  final String pendingItems;
  final String status;

  ShiftHandover({
    required this.id,
    required this.shift,
    required this.date,
    required this.outgoingLead,
    required this.incomingLead,
    required this.pendingItems,
    required this.status,
  });
}

class DelayCause {
  final String cause;
  final int count;
  final String dept;
  final int pct;

  DelayCause({
    required this.cause,
    required this.count,
    required this.dept,
    required this.pct,
  });
}

class EmergencyDelegation {
  final String id;
  final String absentEmpId;
  final String absentEmpName;
  final String coveringEmpId;
  final String coveringEmpName;
  final String date;
  final int taskCount;
  final String reason;

  EmergencyDelegation({
    required this.id,
    required this.absentEmpId,
    required this.absentEmpName,
    required this.coveringEmpId,
    required this.coveringEmpName,
    required this.date,
    required this.taskCount,
    required this.reason,
  });
}
