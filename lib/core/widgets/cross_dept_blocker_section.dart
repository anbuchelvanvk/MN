import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import 'liquid_glass.dart';
import '../../models/ecosystem_models.dart';
import '../../providers/ecosystem_provider.dart';

class CrossDeptBlockerSection extends StatefulWidget {
  final String department;
  final bool isCeoView; // When true (CEO or HR), shows ALL enterprise tickets with complete updates

  const CrossDeptBlockerSection({
    super.key,
    required this.department,
    this.isCeoView = false,
  });

  static const List<String> standardDepts = [
    'Workshop',
    'Assay & Hallmarking',
    'Showroom Sales',
    'Online Department',
    'Vault & Logistics',
    'Billing & Accounts',
  ];

  static void showRaiseBlockerDialog(BuildContext context, {required String defaultFromDept}) {
    final eco = Provider.of<EcosystemProvider>(context, listen: false);
    final activeEmp = eco.currentEmployee;
    String fromDept = standardDepts.contains(defaultFromDept) ? defaultFromDept : standardDepts.first;
    String toDept = standardDepts.firstWhere((d) => d != fromDept, orElse: () => standardDepts[1]);
    final issueController = TextEditingController();
    String slaDue = '04:00 PM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.fromBorderSide(BorderSide(color: AppColors.sandGold, width: 1.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Raise Blocker',
                        style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('From:', style: TextStyle(fontSize: 11, color: AppColors.sandLight)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: fromDept,
                              dropdownColor: AppColors.burgundySurface,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                              ),
                              items: standardDepts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                              onChanged: (v) {
                                if (v != null) setModalState(() => fromDept = v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Against:', style: TextStyle(fontSize: 11, color: AppColors.sandLight)),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: toDept,
                              dropdownColor: AppColors.burgundySurface,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                              ),
                              items: standardDepts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                              onChanged: (v) {
                                if (v != null) setModalState(() => toDept = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Problem / Reason:', style: TextStyle(fontSize: 11, color: AppColors.sandLight)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: issueController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'e.g. Awaiting customer ring size confirmation for custom order #ORD-901...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Expected Time:', style: TextStyle(fontSize: 11, color: AppColors.sandLight)),
                      DropdownButton<String>(
                        value: slaDue,
                        dropdownColor: AppColors.burgundySurface,
                        style: const TextStyle(color: AppColors.goldBright, fontSize: 11.5, fontWeight: FontWeight.bold),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: '02:00 PM', child: Text('02:00 PM Today')),
                          DropdownMenuItem(value: '04:00 PM', child: Text('04:00 PM Today')),
                          DropdownMenuItem(value: '06:00 PM', child: Text('06:00 PM Today')),
                          DropdownMenuItem(value: 'End of Shift', child: Text('End of Shift')),
                        ],
                        onChanged: (v) {
                          if (v != null) setModalState(() => slaDue = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LiquidGlassButton(
                    label: 'Escalate Blocker Ticket',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.ragRed,
                    onPressed: () {
                      if (issueController.text.trim().isEmpty) return;
                      eco.raiseBlocker(
                        raisedByDept: fromDept,
                        raisedByName: '${activeEmp.name} (${activeEmp.straightCutRole})',
                        blockingDept: toDept,
                        issue: issueController.text.trim(),
                        slaDue: slaDue,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Blocker ticket raised against $toDept!'),
                          backgroundColor: AppColors.ragRed,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void showAnswerWhyDialog(BuildContext context, Blocker blocker) {
    final eco = Provider.of<EcosystemProvider>(context, listen: false);
    final activeEmp = eco.currentEmployee;
    final answerController = TextEditingController(text: blocker.responseText ?? '');
    bool markResolved = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.fromBorderSide(BorderSide(color: AppColors.sandGold, width: 1.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Respond to Blocker Ticket',
                        style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Raised by ${blocker.raisedByDept} (${blocker.raisedByName}):',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFFCA5A5)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          blocker.issue,
                          style: const TextStyle(fontSize: 11.5, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Reply & Solution:',
                    style: TextStyle(fontSize: 11, color: AppColors.sandLight),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: answerController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Explain why and when it will be done.',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: markResolved,
                        activeColor: AppColors.ragGreen,
                        onChanged: (val) {
                          setModalState(() => markResolved = val ?? false);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Mark blocker as fully resolved right now',
                          style: TextStyle(fontSize: 11.5, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LiquidGlassButton(
                    label: markResolved ? 'Submit Answer & Resolve' : 'Submit Operational Response',
                    icon: Icons.send,
                    color: markResolved ? AppColors.ragGreen : AppColors.goldPrimary,
                    onPressed: () {
                      if (answerController.text.trim().isEmpty) return;
                      eco.respondToBlocker(
                        blockerId: blocker.id,
                        responseText: answerController.text.trim(),
                        respondedByName: '${activeEmp.name} (${activeEmp.straightCutRole})',
                        markResolved: markResolved,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Response submitted to ${blocker.raisedByDept}!'),
                          backgroundColor: AppColors.ragGreen,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  State<CrossDeptBlockerSection> createState() => _CrossDeptBlockerSectionState();
}

class _CrossDeptBlockerSectionState extends State<CrossDeptBlockerSection> {
  String _activeFilter = 'all'; // 'all', 'active', 'responded', 'late', 'resolved'

  @override
  Widget build(BuildContext context) {
    final eco = Provider.of<EcosystemProvider>(context);

    // Filter logic:
    // When isCeoView is true (CEO Suite and HR Portal): shows ALL enterprise tickets with all updates
    // When false (TL and Ground Staff): strictly shows tickets involving their department
    final List<Blocker> baseTickets = widget.isCeoView
        ? eco.blockers
        : eco.blockersForDepartment(widget.department);

    final allCount = baseTickets.length;
    final activeCount = baseTickets.where((b) => b.status != 'resolved' && (b.responseText == null || b.responseText!.isEmpty)).length;
    final respondedCount = baseTickets.where((b) => b.responseText != null && b.responseText!.isNotEmpty && b.status != 'resolved').length;
    final lateCount = baseTickets.where((b) => b.isLate || b.isOverdue).length;
    final resolvedCount = baseTickets.where((b) => b.status == 'resolved').length;

    final List<Blocker> filteredTickets = baseTickets.where((b) {
      if (_activeFilter == 'active') {
        return b.status != 'resolved' && (b.responseText == null || b.responseText!.isEmpty);
      } else if (_activeFilter == 'responded') {
        return b.responseText != null && b.responseText!.isNotEmpty && b.status != 'resolved';
      } else if (_activeFilter == 'late') {
        return b.isLate || b.isOverdue;
      } else if (_activeFilter == 'resolved') {
        return b.status == 'resolved';
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blocker Tickets',
                    style: GoogleFonts.cinzel(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandGold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Track and resolve issues between teams',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            LiquidGlassButton(
              label: '+ Raise Blocker',
              color: AppColors.ragRed,
              height: 30,
              onPressed: () => CrossDeptBlockerSection.showRaiseBlockerDialog(context, defaultFromDept: widget.department),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filter Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('all', 'All ($allCount)'),
              _filterChip('active', 'Awaiting Reply ($activeCount)'),
              _filterChip('responded', 'Responded ($respondedCount)'),
              _filterChip('late', 'Late / Overdue ($lateCount)', isAlert: lateCount > 0),
              _filterChip('resolved', 'Resolved ($resolvedCount)'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (filteredTickets.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    _activeFilter == 'late' ? Icons.verified : Icons.handshake_outlined,
                    color: AppColors.ragGreen,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _activeFilter == 'late'
                        ? 'No Late Blockers'
                        : (_activeFilter == 'all' ? 'Zero Active Blockers' : 'No Tickets in Filter'),
                    style: GoogleFonts.cinzel(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.isCeoView
                        ? 'All cross-department tickets are progressing smoothly within SLA.'
                        : 'Your unit has no pending blockers in this view.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ...filteredTickets.map((blk) {
            final isTargetDept = blk.blockingDept.toLowerCase().contains(widget.department.toLowerCase()) ||
                widget.department.toLowerCase().contains(blk.blockingDept.toLowerCase());
            final isRaisingDept = blk.raisedByDept.toLowerCase().contains(widget.department.toLowerCase()) ||
                widget.department.toLowerCase().contains(blk.raisedByDept.toLowerCase());
            final isResolved = blk.status == 'resolved';
            final hasResponse = blk.responseText != null && blk.responseText!.isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: blk.isLate
                      ? const Color(0xFFEF4444)
                      : (isResolved ? AppColors.ragGreen.withOpacity(0.5) : AppColors.sandBorder),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Route & Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${blk.raisedByDept}  ➔  ${blk.blockingDept}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: blk.isLate
                              ? const Color(0xFFEF4444).withOpacity(0.2)
                              : (isResolved
                                  ? AppColors.ragGreen.withOpacity(0.2)
                                  : (hasResponse ? Colors.cyan.withOpacity(0.2) : AppColors.goldPrimary.withOpacity(0.2))),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: blk.isLate
                                ? const Color(0xFFEF4444)
                                : (isResolved
                                    ? AppColors.ragGreen
                                    : (hasResponse ? Colors.cyan : AppColors.goldPrimary)),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          blk.isLate
                              ? 'OVERDUE / LATE'
                              : (isResolved ? 'RESOLVED' : (hasResponse ? 'RESPONDED' : 'AWAITING REPLY')),
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: blk.isLate
                                ? const Color(0xFFFCA5A5)
                                : (isResolved
                                    ? AppColors.ragGreen
                                    : (hasResponse ? Colors.cyanAccent : AppColors.goldBright)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Deliverable Impact / Issue
                  Text(
                    blk.issue,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFFE2E8F0), height: 1.3),
                  ),
                  const SizedBox(height: 6),

                  // Timestamps & SLA
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('Raised at ${blk.time} by ${blk.raisedByName}', style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                      const Spacer(),
                      Text('Target SLA: ${blk.slaDue}', style: const TextStyle(fontSize: 9.5, color: AppColors.goldBright, fontWeight: FontWeight.w600)),
                    ],
                  ),

                  // Response Card from blocking team
                  if (hasResponse) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.reply, size: 12, color: AppColors.goldBright),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Response from ${blk.blockingDept} (${blk.respondedByName ?? "Team Lead"}):',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.goldBright),
                                ),
                              ),
                              if (blk.respondedAt != null)
                                Text(
                                  blk.respondedAt!,
                                  style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            blk.responseText!,
                            style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action Buttons
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      // "Answer Why" / "Update Answer"
                      // Permitted for blocking department, and also CEO/HR for executive responses
                      if (!isResolved && (isTargetDept || widget.isCeoView)) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldPrimary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.reply, size: 13),
                          label: Text(
                            hasResponse ? 'Update Answer' : 'Answer Why',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => CrossDeptBlockerSection.showAnswerWhyDialog(context, blk),
                        ),
                      ],

                      // "Resolve" button for raising team, CEO, HR, or blocking team
                      if (!isResolved && (isRaisingDept || widget.isCeoView || isTargetDept)) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.ragGreen,
                            side: BorderSide(color: AppColors.ragGreen.withOpacity(0.6), width: 1.0),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check, size: 13, color: AppColors.ragGreen),
                          label: const Text('Resolve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            eco.resolveBlocker(blk.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Blocker #${blk.id} marked as resolved!'),
                                backgroundColor: AppColors.ragGreen,
                              ),
                            );
                          },
                        ),
                      ],

                      // "Mark Late" for testing or executive escalation
                      if (!isResolved && !blk.isLate) ...[
                        TextButton(
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                          child: const Text('Mark Late', style: TextStyle(fontSize: 9.5, color: Color(0xFFEF4444))),
                          onPressed: () {
                            eco.markBlockerLate(blk.id, true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ticket marked as late / overdue past SLA.')),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _filterChip(String filterKey, String label, {bool isAlert = false}) {
    final isSelected = _activeFilter == filterKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (isAlert ? Colors.white : AppColors.burgundyBg)
                : (isAlert ? const Color(0xFFFCA5A5) : AppColors.sandLight),
          ),
        ),
        selected: isSelected,
        selectedColor: isAlert ? const Color(0xFFEF4444) : AppColors.sandGold,
        backgroundColor: Colors.white.withOpacity(0.06),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isAlert ? const Color(0xFFEF4444).withOpacity(0.5) : AppColors.sandBorder,
            width: 0.8,
          ),
        ),
        onSelected: (_) => setState(() => _activeFilter = filterKey),
      ),
    );
  }
}
