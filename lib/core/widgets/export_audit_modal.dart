import '../../models/employee_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../../providers/ecosystem_provider.dart';
import '../../services/export_audit_service.dart';

class ExportAuditModal extends StatefulWidget {
  final bool isTeamLead;

  const ExportAuditModal({
    super.key,
    this.isTeamLead = false,
  });

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExportAuditModal(isTeamLead: false),
    );
  }

  static Future<void> showTeamLead(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExportAuditModal(isTeamLead: true),
    );
  }

  @override
  State<ExportAuditModal> createState() => _ExportAuditModalState();
}

class _ExportAuditModalState extends State<ExportAuditModal> {
  late ExportDatasetType _selectedDataset;
  ExportTimeSpan _selectedTimeSpan = ExportTimeSpan.thisWeek;
  String _selectedEmpId = 'all';
  String _selectedDept = 'all';
  DateTimeRange? _customRange;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedDataset = widget.isTeamLead ? ExportDatasetType.tasks : ExportDatasetType.masterLedger;
    final now = DateTime.now();
    _customRange = DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
  }

  List<Employee> _getTeamMembers(EcosystemProvider eco) {
    final leadDept = eco.currentEmployee.dept;
    return eco.employees.where((e) {
      final isCeo = e.roleType == 'ceo' || e.role.toLowerCase().contains('ceo') || e.id.toUpperCase().contains('CEO');
      final isHr = e.roleType == 'hr' || e.role.toLowerCase().contains('hr') || e.id.toUpperCase().contains('HR');
      if (isCeo || isHr) return false;
      return e.dept == leadDept || leadDept.toLowerCase().contains('online');
    }).toList();
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customRange,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.magentaPrimary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedTimeSpan = ExportTimeSpan.custom;
      });
    }
  }

  void _handleExport(EcosystemProvider eco, {bool copyOnly = false}) async {
    setState(() => _isExporting = true);

    try {
      final teamMembers = _getTeamMembers(eco);
      final allowedIds = widget.isTeamLead ? teamMembers.map((e) => e.id).toList() : null;

      final csvString = ExportAuditService.instance.generateCsv(
        eco: eco,
        datasetType: _selectedDataset,
        timeSpan: _selectedTimeSpan,
        selectedEmpId: _selectedEmpId,
        selectedDept: widget.isTeamLead ? eco.currentEmployee.dept : _selectedDept,
        customRange: _customRange,
        isTeamLead: widget.isTeamLead,
        allowedEmpIds: allowedIds,
      );

      final title = ExportAuditService.getDatasetLabel(_selectedDataset);

      if (copyOnly) {
        if (!mounted) return;
        await ExportAuditService.instance.copyToClipboard(
          context: context,
          csvContent: csvString,
          reportTitle: title,
        );
      } else {
        if (!mounted) return;
        await ExportAuditService.instance.exportAndShare(
          context: context,
          csvContent: csvString,
          reportTitle: title,
        );
      }

      if (!mounted) return;
      if (!copyOnly) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ragRed,
          content: Text('Export error: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showPreviewDialog(BuildContext context, EcosystemProvider eco) {
    final csvString = ExportAuditService.instance.generateCsv(
      eco: eco,
      datasetType: _selectedDataset,
      timeSpan: _selectedTimeSpan,
      selectedEmpId: _selectedEmpId,
      selectedDept: _selectedDept,
      customRange: _customRange,
    );

    final lines = csvString.split('\n');
    final previewLines = lines.take(50).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.code_rounded, size: 16, color: AppColors.magentaPrimary),
            const SizedBox(width: 8),
            Text(
              'Audit Preview (${lines.length} Lines)',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: SelectableText(
                  previewLines.join('\n'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: const Color(0xFFF8FAFC),
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleExport(eco, copyOnly: true);
            },
            child: Text('Copy CSV', style: GoogleFonts.plusJakartaSans(color: AppColors.magentaPrimary, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.magentaPrimary, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _handleExport(eco, copyOnly: false);
            },
            child: Text('Export File', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final df = DateFormat('dd MMM yyyy');

    // Build unique departments list
    final departments = <String>{'all', ...eco.employees.map((e) => e.dept)}.toList();

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 30),
      decoration: const BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.sandGold, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Modal Title Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sandGold.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.download_rounded, size: 16, color: AppColors.sandGold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isTeamLead ? 'Export Team Audit' : 'Export Audit Ledger',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                      ),
                      Text(
                        widget.isTeamLead ? 'Team Tasks & Attendance' : 'Corporate CSV Reports',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.sandPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.sandBorder, height: 1),

          // Scrollable Settings Form
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DATASET TYPE SELECTOR
                  _sectionTitle('1. Select Data', Icons.category_outlined),
                  const SizedBox(height: 8),
                  if (!widget.isTeamLead) ...[
                    _buildDatasetOption(
                      type: ExportDatasetType.masterLedger,
                      title: 'Master Ledger',
                      subtitle: 'All Enterprise Data',
                      icon: Icons.pie_chart_outline_rounded,
                      color: AppColors.goldBright,
                    ),
                    _buildDatasetOption(
                      type: ExportDatasetType.fivePillars,
                      title: '5 Family Pillars',
                      subtitle: 'Holistic Staff Compliance',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                  _buildDatasetOption(
                    type: ExportDatasetType.tasks,
                    title: widget.isTeamLead ? 'Team Tasks' : 'Daily SOPs',
                    subtitle: widget.isTeamLead ? 'Assigned SOP Deliverables' : 'Tasks & Deliverables',
                    icon: Icons.checklist_rounded,
                    color: AppColors.statusBlue,
                  ),
                  _buildDatasetOption(
                    type: ExportDatasetType.attendance,
                    title: widget.isTeamLead ? 'Team Attendance' : 'Biometric Attendance',
                    subtitle: widget.isTeamLead ? 'Member Punch Records' : 'Daily Punch Records',
                    icon: Icons.fingerprint_rounded,
                    color: AppColors.ragGreen,
                  ),
                  _buildDatasetOption(
                    type: ExportDatasetType.orders,
                    title: 'Online Orders',
                    subtitle: 'Order Workflow Status',
                    icon: Icons.shopping_bag_outlined,
                    color: const Color(0xFFF59E0B),
                  ),
                  _buildDatasetOption(
                    type: ExportDatasetType.directory,
                    title: widget.isTeamLead ? 'Team Directory' : 'Staff Directory',
                    subtitle: widget.isTeamLead ? 'Team Staff List' : 'Workforce Credentials',
                    icon: Icons.people_outline_rounded,
                    color: AppColors.sandGold,
                  ),

                  const SizedBox(height: 18),

                  // 2. TIMESPAN SELECTION
                  _sectionTitle('2. Time Span', Icons.calendar_today_outlined),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _timeSpanChip(ExportTimeSpan.today, 'Today'),
                      _timeSpanChip(ExportTimeSpan.yesterday, 'Yesterday'),
                      _timeSpanChip(ExportTimeSpan.thisWeek, 'This Week'),
                      _timeSpanChip(ExportTimeSpan.thisMonth, 'This Month'),
                      _timeSpanChip(ExportTimeSpan.allTime, 'All Time'),
                      _timeSpanChip(ExportTimeSpan.custom, 'Custom Range'),
                    ],
                  ),

                  if (_selectedTimeSpan == ExportTimeSpan.custom && _customRange != null) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _pickCustomRange(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.burgundySurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.sandGold, width: 1.1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.sandGold),
                            const SizedBox(width: 8),
                            Text(
                              'Selected: ${df.format(_customRange!.start)} - ${df.format(_customRange!.end)}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                            ),
                            const SizedBox(width: 8),
                            const Text('(Tap to change)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // 3. EMPLOYEE & DEPARTMENT SCOPE
                  _sectionTitle(widget.isTeamLead ? '3. Filter Team Members' : '3. Filter Staff', Icons.person_search_outlined),
                  const SizedBox(height: 8),

                  // Employee Dropdown
                  Builder(
                    builder: (context) {
                      final staffList = widget.isTeamLead ? _getTeamMembers(eco) : eco.employees;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.burgundySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sandBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedEmpId,
                            isExpanded: true,
                            dropdownColor: AppColors.burgundySurface,
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.sandPrimary),
                            items: [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text(
                                  widget.isTeamLead ? 'All Team Members (${staffList.length})' : 'All Staff Members',
                                  style: const TextStyle(color: AppColors.textDark, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              ...staffList.map(
                                (e) => DropdownMenuItem(
                                  value: e.id,
                                  child: Text(
                                    '[${e.id}] ${e.name} • ${e.straightCutRole}',
                                    style: const TextStyle(color: AppColors.sandLight, fontSize: 11.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedEmpId = val);
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  if (!widget.isTeamLead) ...[
                    const SizedBox(height: 8),
                    // Department Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.burgundySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDept,
                          isExpanded: true,
                          dropdownColor: AppColors.burgundySurface,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.sandPrimary),
                          items: departments.map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                d == 'all' ? 'All Departments' : 'Department: $d',
                                style: const TextStyle(color: AppColors.sandLight, fontSize: 11.5),
                              ),
                            ),
                          ).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedDept = val);
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // 4. ACTION BAR (Preview, Copy & Share)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.sandBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.visibility_outlined, size: 14, color: AppColors.sandGold),
                          label: const Text('Preview CSV', style: TextStyle(color: AppColors.sandGold, fontSize: 11.5)),
                          onPressed: () => _showPreviewDialog(context, eco),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.sandBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.content_copy_rounded, size: 14, color: AppColors.sandPrimary),
                          label: const Text('Copy CSV', style: TextStyle(color: AppColors.sandPrimary, fontSize: 11.5)),
                          onPressed: () => _handleExport(eco, copyOnly: true),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sandGold,
                        foregroundColor: AppColors.burgundyBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                      label: Text(
                        _isExporting ? 'Generating CSV...' : 'Export & Share',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      onPressed: _isExporting ? null : () => _handleExport(eco, copyOnly: false),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.sandGold),
        const SizedBox(width: 6),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.sandLight),
        ),
      ],
    );
  }

  Widget _buildDatasetOption({
    required ExportDatasetType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedDataset == type;
    return InkWell(
      onTap: () => setState(() => _selectedDataset = type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? color : AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      color: isSelected ? AppColors.textDark : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 16, color: color)
            else
              const Icon(Icons.radio_button_unchecked, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _timeSpanChip(ExportTimeSpan span, String label) {
    final isSelected = _selectedTimeSpan == span;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.sandGold,
      backgroundColor: AppColors.burgundySurface,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.sandLight,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
        width: 0.9,
      ),
      onSelected: (val) {
        if (val) {
          if (span == ExportTimeSpan.custom) {
            _pickCustomRange(context);
          } else {
            setState(() => _selectedTimeSpan = span);
          }
        }
      },
    );
  }
}
