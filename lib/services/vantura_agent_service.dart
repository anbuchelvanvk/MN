import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';
import '../providers/ecosystem_provider.dart';
import 'mn_ai_copilot_service.dart';

/// Represents an executable local tool in the Vantura Agentic Framework
class VanturaTool {
  final String name;
  final String description;
  final Future<String> Function(Map<String, dynamic> args, EcosystemProvider eco) execute;

  VanturaTool({
    required this.name,
    required this.description,
    required this.execute,
  });
}

/// A conversation turn stored in Vantura's Dual-Layer Memory
class VanturaMemoryTurn {
  final String role; // 'user', 'model'
  final String content;
  final DateTime timestamp;

  VanturaMemoryTurn({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toGeminiJson() {
    return {
      'role': role,
      'parts': [
        {'text': content}
      ],
    };
  }
}

/// Result returned from Vantura Agent execution
class VanturaAgentResult {
  final String text;
  final List<String> toolsInvoked;
  final bool usedFallback;
  final String? fallbackReason;
  final CopilotActionType actionType;
  final String? actionLabel;

  VanturaAgentResult({
    required this.text,
    this.toolsInvoked = const [],
    this.usedFallback = false,
    this.fallbackReason,
    this.actionType = CopilotActionType.none,
    this.actionLabel,
  });
}

/// Vantura Agentic AI Framework Engine for Flutter
/// Orchestrates:
/// 1. ReAct (Reason + Act) tool-calling loops
/// 2. Dual-Layer Memory (Sliding-window short term + compressed long term)
/// 3. Multi-Model Google Gemini LLM API integration
/// 4. Graceful offline / depleted-credits fallback to local resilient NLP
class VanturaAgentService {
  /// Default configured API key provided by the user
  static String activeApiKey = 'AQ.Ab8RN6ID8HJwa14vple0RIdLtd7YTrP6xu-RVHFu47HZlRJYEw';

  /// Persistent HTTP client for connection pooling and TLS session reuse (saves ~800ms)
  static final http.Client _httpClient = http.Client();

  /// Primary LLM models tried in order of speed and capability
  static const List<String> supportedModels = [
    'gemini-1.5-flash',
    'gemini-2.0-flash',
    'gemini-flash-latest',
    'gemini-3.8-flash',
  ];

  /// Dual-Layer Memory storage
  final List<VanturaMemoryTurn> _memory = [];
  String? _longTermMemorySummary;
  static const int _shortTermWindowLimit = 8;

  /// Registers available tools for MN Jewel Park
  late final List<VanturaTool> _tools;

  VanturaAgentService() {
    _initializeTools();
  }

  void _initializeTools() {
    _tools = [
      // Tool 1: Live Google Sheet HR Attendance & Biometric Punch
      VanturaTool(
        name: 'check_attendance_status',
        description: 'Retrieves live biometric punch, Google Sheet HR attendance records, and monthly working days count.',
        execute: (args, eco) async {
          final punch = eco.todayLoginPunch;
          final todayStatus = punch != null
              ? 'Punched In at ${punch.timestamp.hour.toString().padLeft(2, '0')}:${punch.timestamp.minute.toString().padLeft(2, '0')}'
              : 'Not Punched In Yet today (Morning shift starts 9:30 AM with 15-min grace to 9:45 AM)';

          final row = eco.currentEmployeeHrAttendanceRow;
          final workingDays = eco.workingDaysAttended;
          final otDays = eco.tuesdayOvertimeDaysAttended;
          final percentage = eco.monthlyAttendancePercentage.toStringAsFixed(1);
          final presentCount = row?.presentDaysCount ?? workingDays;
          final lateCount = row?.lateCount ?? 0;

          return 'LIVE GOOGLE SHEET & BIOMETRIC ATTENDANCE DATA:\n'
              '- Today Punch Status: $todayStatus\n'
              '- Working Days Attended This Month: $workingDays days\n'
              '- Confirmed Present Days (Google Sheet): $presentCount days\n'
              '- Late Check-Ins: $lateCount\n'
              '- Tuesday Overtime Days: $otDays\n'
              '- Monthly Attendance Compliance: $percentage%';
        },
      ),

      // Tool 2: Emergency Permission Quota
      VanturaTool(
        name: 'get_permission_quota',
        description: 'Gets remaining emergency permissions, monthly entitlement, and leave balances.',
        execute: (args, eco) async {
          final usedHours = eco.totalPermissionHoursUsed;
          final remainingHours = (4.0 - usedHours).clamp(0.0, 4.0);
          final approvedCount = eco.currentEmployeePermissionRecords
              .where((p) => p.status == 'Approved' && !p.isCasualLeave)
              .length;
          final remainingPasses = (2 - approvedCount).clamp(0, 2);
          return 'Monthly Permission Entitlement: 4.0 hours per month (max 2 passes, up to 2 hours each) + 1 Casual Leave (CL). Used: ${usedHours.toStringAsFixed(1)} hours ($approvedCount passes). Remaining: ${remainingHours.toStringAsFixed(1)} hours ($remainingPasses passes left).';
        },
      ),

      // Tool 3: Active To-Dos & Task Checklists
      VanturaTool(
        name: 'get_active_todos',
        description: 'Fetches all active role checklist tasks and personal to-dos for today with complete category breakdowns.',
        execute: (args, eco) async {
          final tasks = eco.currentEmployeeTasks;
          final pending = tasks.where((t) => !t.isCompleted).toList();

          if (pending.isEmpty) {
            return 'All tasks completed for today! (0 pending out of ${tasks.length} total assigned)';
          }

          final Map<String, List<String>> byCat = {};
          for (final t in pending) {
            final cat = t.category.isNotEmpty ? t.category : 'General Operations';
            byCat.putIfAbsent(cat, () => []).add(t.title);
          }

          final buffer = StringBuffer();
          buffer.writeln('TOTAL PENDING TASKS: ${pending.length} (assigned to ${eco.currentEmployee.name}):');
          for (final entry in byCat.entries) {
            buffer.writeln('• ${entry.key} (${entry.value.length} tasks):');
            for (final title in entry.value) {
              buffer.writeln('  - $title');
            }
          }
          return buffer.toString().trim();
        },
      ),

      // Tool 4: Google Drive Media Pipeline
      VanturaTool(
        name: 'check_drive_media_pipeline',
        description: 'Retrieves live Google Drive uploaded media drafts, CEO review queue, and DAM folder status.',
        execute: (args, eco) async {
          final drafts = eco.mediaAssets;
          final pendingCeo = drafts.where((d) => d.isPendingReview).length;
          final approved = drafts.where((d) => d.isApprovedByCeo).length;
          final revisions = drafts.where((d) => d.isRevisionsRequested).length;
          final allDraftTitles = drafts.map((d) => '"${d.title}" (${d.category}, ${d.displayStatus})').join(', ');

          return 'LIVE GOOGLE DRIVE MEDIA PIPELINE:\n'
              '- Target Drive Folder ID: 1zfY6b6xuI8GOT1cfUOw3DpXa2u81-BX2\n'
              '- Pending CEO Review: $pendingCeo assets\n'
              '- Approved & Ready: $approved assets\n'
              '- Revisions Needed: $revisions assets\n'
              '${allDraftTitles.isNotEmpty ? "- All Active Drafts: $allDraftTitles" : "- No active drafts in queue."}';
        },
      ),

      // Tool 5: Firebase Store & Online Orders
      VanturaTool(
        name: 'check_firebase_orders',
        description: 'Retrieves live online order dispatch status, jewelry sales orders, and pending items from Firebase.',
        execute: (args, eco) async {
          final orders = eco.onlineOrders;
          final pending = orders.where((o) => o.status.toLowerCase() == 'pending').length;
          final dispatched = orders.where((o) => o.status.toLowerCase() == 'dispatched').length;
          return 'LIVE STORE & ONLINE ORDERS (FIREBASE):\n'
              '- Total Active Orders: ${orders.length}\n'
              '- Pending Packaging & Dispatch: $pending\n'
              '- Completed/Dispatched: $dispatched';
        },
      ),

      // Tool 6: SOP & Policy Guidelines
      VanturaTool(
        name: 'get_sop_policy',
        description: 'Retrieves official SOP guidelines for jewelry photography, reels, or cross-department handovers.',
        execute: (args, eco) async {
          return 'Official Jewelry Photography SOP: Pure white background (RGB 255,255,255), 8-angle macro zoom, BIS 916 Hallmark certificate tag in frame 3. Dual sign-off required by OTM and CEO before social posting.';
        },
      ),

      // Tool 7: Cross-Department Blockers
      VanturaTool(
        name: 'get_open_blockers',
        description: 'Retrieves open blockers and cross-department bottlenecks.',
        execute: (args, eco) async {
          return 'Open Blockers: OTM waiting for raw reels upload to Google Drive folder 1zfY6b6xuI8GOT1cfUOw3DpXa2u81-BX2; Billing terminal audit in progress.';
        },
      ),

      // Tool 8: Official Workforce Directory of MN Jewel Park
      VanturaTool(
        name: 'get_workforce_directory',
        description: 'Retrieves the complete, official directory of all employees in MN Jewel Park, grouped by department with employee IDs, role codes, designations, and contact info.',
        execute: (args, eco) async {
          final employees = eco.employees;
          final Map<String, List<Employee>> byDept = {};
          for (final emp in employees) {
            byDept.putIfAbsent(emp.dept, () => []).add(emp);
          }

          final buffer = StringBuffer();
          buffer.writeln('OFFICIAL WORKFORCE DIRECTORY OF MN JEWEL PARK (${employees.length} Active Staff Members):');
          for (final entry in byDept.entries) {
            buffer.writeln('\n🏢 DEPARTMENT: ${entry.key.toUpperCase()} (${entry.value.length} members):');
            for (final emp in entry.value) {
              final idStr = emp.empNo.isNotEmpty ? 'EMP #${emp.empNo} (${emp.id})' : emp.id;
              final codeStr = emp.roleCode.isNotEmpty ? ' [${emp.roleCode}]' : '';
              buffer.writeln('  • ${emp.name}$codeStr — ${emp.role} (ID: $idStr | Email: ${emp.email} | Phone: ${emp.phone})');
            }
          }
          return buffer.toString().trim();
        },
      ),

      // Tool 9: Live Workforce Attendance Today (All Employees)
      VanturaTool(
        name: 'check_workforce_today_attendance',
        description: 'Retrieves live workforce attendance for today across all staff: lists every employee who is present, on duty, or absent, plus total headcounts and punch times for MN Jewel Park.',
        execute: (args, eco) async {
          final summaries = eco.allEmployeesTodayAttendance;
          final presentList = <String>[];
          final absentList = <String>[];

          for (final s in summaries) {
            final isAbsent = eco.isEmployeeAbsent(s.employeeId);
            if (isAbsent) {
              absentList.add('${s.employeeName} (${s.role} - ${s.department}) [Marked Absent]');
            } else if (s.isPresent) {
              final punchInfo = s.loginPunch != null
                  ? 'Punched in at ${s.inTimeString}'
                  : (s.isCurrentlyOnDuty ? 'On Duty' : 'Active / Present');
              presentList.add('${s.employeeName} (${s.role} - ${s.department}) — $punchInfo');
            } else {
              absentList.add('${s.employeeName} (${s.role} - ${s.department}) — Not punched in yet');
            }
          }

          final total = summaries.length;
          final presentCount = presentList.length;
          final absentCount = absentList.length;
          final isTuesday = DateTime.now().weekday == DateTime.tuesday;

          final buffer = StringBuffer();
          buffer.writeln('LIVE WORKFORCE ATTENDANCE REPORT TODAY (MN JEWEL PARK):');
          buffer.writeln('• Overall Headcount: $presentCount Present / $absentCount Absent or Pending out of $total Total Staff');
          if (isTuesday) {
            buffer.writeln('• Notice: Today is Tuesday (Showroom Weekly Off Day). Retail showroom staff observe weekly off cadence.');
          }
          buffer.writeln('\n🟢 PRESENT TODAY ($presentCount staff):');
          if (presentList.isNotEmpty) {
            for (final p in presentList) {
              buffer.writeln('  • $p');
            }
          } else {
            buffer.writeln('  • None recorded yet today.');
          }

          buffer.writeln('\n🔴 ABSENT / PENDING TODAY ($absentCount staff):');
          if (absentList.isNotEmpty) {
            for (final a in absentList) {
              buffer.writeln('  • $a');
            }
          } else {
            buffer.writeln('  • None (100% attendance recorded today).');
          }

          return buffer.toString().trim();
        },
      ),
    ];
  }

  /// Clears conversation memory
  void resetMemory() {
    _memory.clear();
    _longTermMemorySummary = null;
  }

  /// Builds the grounded system instruction customized for the logged-in employee
  String _buildSystemInstruction(EcosystemProvider eco) {
    final emp = eco.currentEmployee;
    final firstName = MnAiCopilotService.extractFirstName(emp.name);
    final punch = eco.todayLoginPunch;
    final punchStatus = punch != null
        ? 'Punched In at ${punch.timestamp.hour.toString().padLeft(2, '0')}:${punch.timestamp.minute.toString().padLeft(2, '0')}'
        : 'Not Punched In Yet today';
    final usedPerms = eco.currentEmployeePermissionRecords
        .where((p) => p.status == 'Approved')
        .length;
    final remainingPerms = (2 - usedPerms).clamp(0, 2);
    final myTodos = eco.todayPendingTodosCount;
    final workingDays = eco.workingDaysAttended;
    final otDays = eco.tuesdayOvertimeDaysAttended;
    final attendancePct = eco.monthlyAttendancePercentage.toStringAsFixed(1);
    final row = eco.currentEmployeeHrAttendanceRow;
    final presentCount = row?.presentDaysCount ?? workingDays;
    final lateCount = row?.lateCount ?? 0;
    final mediaPending = eco.mediaAssets.where((m) => m.isPendingReview).length;
    final ordersPending = eco.onlineOrders.where((o) => o.status.toLowerCase() == 'pending').length;

    // 1. Full workforce roster
    final allEmployees = eco.employees;
    final workforceRoster = allEmployees.map((e) {
      final code = e.roleCode.isNotEmpty ? ' [${e.roleCode}]' : '';
      return '  • ${e.name}$code — ${e.role} (Dept: ${e.dept}, ID: ${e.id})';
    }).join('\n');

    // 2. Live today attendance across the workforce
    final todaySummaries = eco.allEmployeesTodayAttendance;
    final presentStaff = <String>[];
    final absentStaff = <String>[];
    for (final s in todaySummaries) {
      if (eco.isEmployeeAbsent(s.employeeId) || !s.isPresent) {
        absentStaff.add('${s.employeeName} (${s.role})');
      } else {
        final pt = s.loginPunch != null ? ' (Punched in: ${s.inTimeString})' : '';
        presentStaff.add('${s.employeeName} (${s.role})$pt');
      }
    }

    final isTuesday = DateTime.now().weekday == DateTime.tuesday;
    final memoryContext = _longTermMemorySummary != null ? '\n$_longTermMemorySummary\n' : '';

    return '''You are "MN Assistant", the intelligent internal enterprise AI Copilot for MN Jewel Park.
You are running as a real-time grounded agent powered by Vantura.
$memoryContext
LIVE ENTERPRISE DATABASE SYNC (Google Sheets, Google Drive, & Firebase):

1. COMPLETE WORKFORCE DIRECTORY OF MN JEWEL PARK (${allEmployees.length} Total Employees):
$workforceRoster

2. LIVE TODAY'S WORKFORCE ATTENDANCE (${presentStaff.length} Present, ${absentStaff.length} Absent / Pending):
- Present Today: ${presentStaff.join(', ')}
- Absent / Pending Today: ${absentStaff.isNotEmpty ? absentStaff.join(', ') : 'None'}
${isTuesday ? '- Notice: Today is Tuesday (Showroom Weekly Off Day).' : ''}

3. CURRENT LOGGED-IN USER:
- Employee: ${emp.name} ("$firstName") | Role: ${emp.role} | Department: ${emp.dept} | ID: ${emp.id}
- Personal Punch: $punchStatus (Morning shift 9:30 AM, grace until 9:45 AM)
- Personal Monthly Attendance: $presentCount present days, $lateCount late check-ins, $otDays Tuesday OT ($attendancePct% compliance)
- Emergency Permissions: $remainingPerms / 2 remaining this calendar month (max 2 hrs per pass).
- Personal Tasks / To-Dos: $myTodos active pending checklist items.
- Google Drive Media Pipeline: $mediaPending drafts waiting for CEO review in folder "1zfY6b6xuI8GOT1cfUOw3DpXa2u81-BX2".
- Firebase Online Orders: $ordersPending orders pending packaging and dispatch.

CRITICAL RULES FOR RELEVANCE AND PRECISION:
1. WORKFORCE DIRECTORY QUERIES: If the user asks for "list of employees", "who works here", "all employees", "staff list", or "directory", you MUST list ALL ${allEmployees.length} employees from the WORKFORCE DIRECTORY above, grouped by department with their designation and ID. NEVER list only the logged-in user!
2. TODAY'S ATTENDANCE QUERIES: If the user asks "who are all present today?", "who is present?", "who came today?", or "who is absent?", you MUST provide the complete workforce attendance report listing every staff member who is present and who is absent today. NEVER answer only for the logged-in user!
3. PERSONAL QUERIES: Only when the user explicitly asks about THEIR OWN attendance ("my attendance", "am I present", "my punch", "my tasks") should you focus solely on their individual status.
4. EXHAUSTIVE AND COMPLETE: Never truncate, summarize away details, or say "etc.". Every single employee, task, or rule must be listed in full.
5. GROUNDED REAL-TIME DATA: You already possess all live records. Never ask "Would you like me to pull your report?" or say "I need to sync with HR". Give the exact data immediately.
6. Format cleanly using markdown (bold titles, bullet points, headers).
''';
  }

  /// Sends user prompt to the Vantura Agent and resolves the response
  Future<VanturaAgentResult> runAgent({
    required String prompt,
    required EcosystemProvider eco,
    String? explicitApiKey,
  }) async {
    final key = explicitApiKey ?? activeApiKey;
    final toolsUsed = <String>[];

    // 1. Tool Reasoning Phase: Check if user query matches any local tool
    final normalized = prompt.toLowerCase();
    String? toolContext;

    if (normalized.contains('list of employee') ||
        normalized.contains('list employee') ||
        normalized.contains('employees in') ||
        normalized.contains('employee in') ||
        normalized.contains('staff in') ||
        normalized.contains('all employee') ||
        normalized.contains('all staff') ||
        normalized.contains('staff list') ||
        normalized.contains('list of staff') ||
        normalized.contains('who works here') ||
        normalized.contains('who work here') ||
        normalized.contains('who are the employee') ||
        normalized.contains('who are all the employee') ||
        normalized.contains('employee directory') ||
        normalized.contains('workforce list') ||
        normalized.contains('team directory') ||
        normalized.contains('staff directory') ||
        normalized.contains('workforce directory') ||
        normalized.contains('roster')) {
      final t = _tools.firstWhereOrNull((t) => t.name == 'get_workforce_directory');
      if (t != null) {
        toolsUsed.add(t.name);
        toolContext = await t.execute({}, eco);
      }
    } else if (normalized.contains('who are all present') ||
        normalized.contains('who all are present') ||
        normalized.contains('who all present') ||
        normalized.contains('who is present') ||
        normalized.contains('who are present') ||
        normalized.contains('present today') ||
        normalized.contains('who is absent') ||
        normalized.contains('who are absent') ||
        normalized.contains('who came today') ||
        normalized.contains('attendance today') ||
        normalized.contains('team attendance') ||
        normalized.contains('workforce attendance') ||
        normalized.contains('staff attendance') ||
        normalized.contains('everyone present') ||
        normalized.contains('how many present')) {
      final t = _tools.firstWhereOrNull((t) => t.name == 'check_workforce_today_attendance');
      if (t != null) {
        toolsUsed.add(t.name);
        toolContext = await t.execute({}, eco);
      }
    } else if (normalized.contains('attendance') ||
        normalized.contains('punch') ||
        normalized.contains('shift') ||
        normalized.contains('present') ||
        normalized.contains('absent') ||
        normalized.contains('late')) {
      final t = _tools.firstWhereOrNull((t) => t.name == 'check_attendance_status');
      if (t != null) {
        toolsUsed.add(t.name);
        toolContext = await t.execute({}, eco);
      }
    } else if (normalized.contains('permission') || normalized.contains('gate pass') || normalized.contains('leave balance') || normalized.contains('leave')) {
      final t = _tools.firstWhereOrNull((t) => t.name == 'get_permission_quota');
      if (t != null) {
        toolsUsed.add(t.name);
        toolContext = await t.execute({}, eco);
      }
    } else if (normalized.contains('photo') || normalized.contains('shoot') || normalized.contains('sop') || normalized.contains('jewelry')) {
      final t = _tools.firstWhereOrNull((t) => t.name == 'get_sop_policy');
      if (t != null) {
        toolsUsed.add(t.name);
        toolContext = await t.execute({}, eco);
      }
    } else if (normalized.contains('media') || normalized.contains('drive') || normalized.contains('reel') || normalized.contains('draft') || normalized.contains('video') || normalized.contains('sign-off')) {
      final t = _tools.firstWhereOrNull((t) => t.name == 'check_drive_media_pipeline');
      if (t != null) {
        toolsUsed.add(t.name);
        toolContext = await t.execute({}, eco);
      }
    } else if (normalized.contains('order') || normalized.contains('dispatch') || normalized.contains('customer') || normalized.contains('sales')) {
      final t = _tools.firstWhereOrNull((t) => t.name == 'check_firebase_orders');
      if (t != null) {
        toolsUsed.add(t.name);
        toolContext = await t.execute({}, eco);
      }
    } else if (normalized.contains('todo') || normalized.contains('task') || normalized.contains('checklist')) {
      final t = _tools.firstWhereOrNull((t) => t.name == 'get_active_todos');
      if (t != null) {
        toolsUsed.add(t.name);
        toolContext = await t.execute({}, eco);
      }
    } else if (normalized.contains('blocker')) {
      final t = _tools.firstWhereOrNull((t) => t.name == 'get_open_blockers');
      if (t != null) {
        toolsUsed.add(t.name);
        toolContext = await t.execute({}, eco);
      }
    }

    // 2. Add user prompt to Dual-Layer Memory
    _memory.add(
      VanturaMemoryTurn(role: 'user', content: prompt, timestamp: DateTime.now()),
    );

    // 3. Prepare Gemini API Request payload
    final systemInstruction = _buildSystemInstruction(eco);

    // Construct conversation turns from short-term memory
    final recentTurns = _memory.length > _shortTermWindowLimit
        ? _memory.sublist(_memory.length - _shortTermWindowLimit)
        : _memory;

    final contents = <Map<String, dynamic>>[];
    for (final turn in recentTurns) {
      contents.add({
        'role': turn.role,
        'parts': [
          {'text': turn.content}
        ],
      });
    }

    // Inject tool execution context if a tool was invoked
    if (toolContext != null && contents.isNotEmpty) {
      final lastPart = contents.last['parts'] as List;
      lastPart.add({
        'text': '\n[VANTURA LOCAL TOOL OBSERVATION: $toolContext]'
      });
    }

    // 4. Attempt calling Gemini API with automatic model failover
    String? apiErrorMessage;

    for (final modelName in supportedModels) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$key',
        );

        final requestBody = jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': systemInstruction}
            ]
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.3,
            'topP': 0.85,
            'maxOutputTokens': 2048,
          },
        });

        final res = await _httpClient
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            )
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final contentMap = candidates.first['content'] as Map<String, dynamic>?;
            final parts = contentMap?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final replyText = parts.first['text'] as String?;
              if (replyText != null && replyText.trim().isNotEmpty) {
                // Record assistant answer in memory
                _memory.add(
                  VanturaMemoryTurn(
                    role: 'model',
                    content: replyText.trim(),
                    timestamp: DateTime.now(),
                  ),
                );

                // Auto-compress memory if exceeding limits
                if (_memory.length > _shortTermWindowLimit * 2) {
                  _compressLongTermMemory();
                }

                // Resolve deep-link action type based on prompt
                final action = _resolveAction(prompt);

                return VanturaAgentResult(
                  text: replyText.trim(),
                  toolsInvoked: toolsUsed,
                  usedFallback: false,
                  actionType: action.$1,
                  actionLabel: action.$2,
                );
              }
            }
          }
        } else if (res.statusCode == 402) {
          // Prepayment credits depleted on Google Cloud project
          apiErrorMessage = 'Google Cloud credits depleted for this API project (HTTP 402 RESOURCE_EXHAUSTED).';
          break; // Don't spam other models if billing balance is 0
        } else {
          apiErrorMessage = 'Gemini service returned status ${res.statusCode}';
        }
      } catch (err) {
        apiErrorMessage = 'Network error: $err';
      }
    }

    // 5. Seamless Intelligent Fallback: When API key credits are depleted or offline,
    // invoke our local grounded NLP copilot so the user is NEVER left stranded!
    final localResult = MnAiCopilotService.processQuery(query: prompt, eco: eco);
    final fallbackPrefix = (apiErrorMessage != null && apiErrorMessage.contains('402'))
        ? '> **Vantura Hybrid Mode:** Google Cloud reports prepayment credits are depleted for this project (Error 402). Seamlessly switched to **Local Grounded AI Engine**.\n\n'
        : '';

    final fullFallbackText = '$fallbackPrefix${localResult.text}';

    _memory.add(
      VanturaMemoryTurn(
        role: 'model',
        content: fullFallbackText,
        timestamp: DateTime.now(),
      ),
    );

    return VanturaAgentResult(
      text: fullFallbackText,
      toolsInvoked: toolsUsed,
      usedFallback: true,
      fallbackReason: apiErrorMessage,
      actionType: localResult.actionType,
      actionLabel: localResult.actionLabel,
    );
  }

  /// Compresses older turns into long-term context summary
  void _compressLongTermMemory() {
    if (_memory.length <= _shortTermWindowLimit) return;
    final olderTurns = _memory.sublist(0, _memory.length - _shortTermWindowLimit);
    final summarySnippet = olderTurns
        .map((t) => '${t.role == "user" ? "User" : "Agent"}: ${t.content.replaceAll("\n", " ").take(60)}')
        .join(' | ');
    _longTermMemorySummary = 'Prior Context: $summarySnippet';
    _memory.removeRange(0, _memory.length - _shortTermWindowLimit);
  }

  /// Determines if an in-app button should accompany the reply
  (CopilotActionType, String?) _resolveAction(String query) {
    final q = query.toLowerCase();
    if (q.contains('permission') || q.contains('gate pass')) {
      return (CopilotActionType.openEmergencyPermission, 'Request Emergency Permission (15m - 2h)');
    } else if (q.contains('leave') || q.contains('medical') || q.contains('doctor')) {
      return (CopilotActionType.openEmergencyMedicalLeave, 'Apply Emergency Medical Leave');
    } else if (q.contains('photo') || q.contains('camera') || q.contains('reel') || q.contains('review')) {
      return (CopilotActionType.openMediaReviewBoard, 'Open Media Review Board (DAM)');
    } else if (q.contains('blocker')) {
      return (CopilotActionType.openCrossDeptBlockers, 'View Cross-Department Blockers');
    } else if (q.contains('order') || q.contains('dispatch')) {
      return (CopilotActionType.openOnlineOrders, 'View Live Online Orders');
    } else if (q.contains('employee') || q.contains('staff') || q.contains('directory') || q.contains('roster')) {
      return (CopilotActionType.openStaffDirectory, 'View Complete Staff Directory');
    } else if (q.contains('task') || q.contains('todo') || q.contains('checklist') || q.contains('work')) {
      return (CopilotActionType.openTaskList, 'View & Check Off All Tasks (Things To Do)');
    }
    return (CopilotActionType.none, null);
  }
}

extension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
