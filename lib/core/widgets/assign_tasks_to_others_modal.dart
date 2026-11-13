import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import 'liquid_glass.dart';
import '../../models/employee_model.dart';
import '../../models/task_model.dart';
import '../../providers/ecosystem_provider.dart';

class AssignTasksToOthersModal extends StatefulWidget {
  final String? initialAbsentEmpId;

  const AssignTasksToOthersModal({
    super.key,
    this.initialAbsentEmpId,
  });

  static Future<void> show(BuildContext context, {String? defaultAbsentEmpId}) {
    final eco = Provider.of<EcosystemProvider>(context, listen: false);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
        value: eco,
        child: AssignTasksToOthersModal(initialAbsentEmpId: defaultAbsentEmpId),
      ),
    );
  }

  @override
  State<AssignTasksToOthersModal> createState() => _AssignTasksToOthersModalState();
}

class _AssignTasksToOthersModalState extends State<AssignTasksToOthersModal> {
  String? _selectedAbsentEmpId;
  final Map<String, String> _selectedTargetColleagueByTask = {};
  String? _batchTargetColleagueId;

  // Search and Department Filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedDeptFilter = 'All'; // 'All' or specific department

  // New ad-hoc task form state
  bool _showNewTaskForm = false;
  final _newTitleController = TextEditingController();
  String _newPriority = 'Critical SLA';
  String _newDue = '04:00 PM';
  String? _newAssigneeId;

  @override
  void initState() {
    super.initState();
    _selectedAbsentEmpId = widget.initialAbsentEmpId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newTitleController.dispose();
    super.dispose();
  }

  bool _isTeamMemberOf(Employee e, Employee tl) {
    final isCeo = e.roleType == 'ceo' || e.role.toLowerCase().contains('ceo') || e.id.toUpperCase().contains('CEO');
    final isHr = e.roleType == 'hr' || e.role.toLowerCase().contains('hr') || e.id.toUpperCase().contains('HR');
    if (isCeo || isHr || e.id == tl.id) return false;

    final tlDept = tl.dept.toLowerCase().trim();
    final empDept = e.dept.toLowerCase().trim();

    // Direct department match
    if (empDept == tlDept) return true;

    // Online operations umbrella for Praveenkumaar / Online TL
    if (tlDept.contains('online') || tlDept.contains('design') || tl.id == 'MN-TL1002') {
      return empDept.contains('online') ||
             empDept.contains('media') ||
             empDept.contains('creative') ||
             empDept.contains('catalog') ||
             empDept.contains('sales') ||
             empDept.contains('analytics') ||
             empDept.contains('campaign') ||
             empDept.contains('technology') ||
             empDept.contains('listing') ||
             empDept.contains('design');
    }

    // Other department hierarchy match (e.g., Accounts, Inventory, Showroom floor)
    if (tlDept.isNotEmpty && (empDept.contains(tlDept) || tlDept.contains(empDept))) {
      return true;
    }

    return false;
  }

  List<String> _getDepartments(EcosystemProvider eco, bool isCeoOrHr, Employee activeEmp) {
    if (!isCeoOrHr) {
      final deptName = activeEmp.dept.contains('Online') ? 'Online Department' : activeEmp.dept;
      return [deptName];
    }
    final depts = <String>{'All'};
    for (final e in eco.employees) {
      if (e.dept.isNotEmpty && e.roleType != 'ceo') {
        depts.add(e.dept);
      }
    }
    final list = depts.toList()..sort();
    return list;
  }

  List<Employee> _getEligibleAssignees({
    required EcosystemProvider eco,
    required Employee activeEmp,
    required String? absentEmpId,
  }) {
    final isCeo = activeEmp.roleType == 'ceo' || activeEmp.role.toLowerCase().contains('ceo');
    final isHr = activeEmp.roleType == 'hr' || activeEmp.role.toLowerCase().contains('hr');

    // 1. Base eligibility:
    List<Employee> list = eco.employees.where((e) {
      // Must not be the absent employee themselves
      if (absentEmpId != null && e.id == absentEmpId) return false;

      // CEO & HR can assign to all department employees (excluding CEO themselves)
      if (isCeo || isHr) {
        if (e.roleType == 'ceo' || e.role.toLowerCase().contains('ceo')) return false;
        return true;
      }

      // Team Lead: for their department employees alone!
      return _isTeamMemberOf(e, activeEmp);
    }).toList();

    // 2. Department filter (for CEO & HR)
    if ((isCeo || isHr) && _selectedDeptFilter != 'All') {
      list = list.where((e) => e.dept.toLowerCase() == _selectedDeptFilter.toLowerCase()).toList();
    }

    // 3. Search query filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      final searched = list.where((e) {
        return e.name.toLowerCase().contains(q) ||
               e.id.toLowerCase().contains(q) ||
               e.role.toLowerCase().contains(q) ||
               e.dept.toLowerCase().contains(q) ||
               e.straightCutRole.toLowerCase().contains(q);
      }).toList();
      list = searched;
    }

    // Sort A-Z by name
    list.sort((a, b) => a.name.compareTo(b.name));

    return list;
  }

  String? _resolveDefaultAssigneeId({
    required EcosystemProvider eco,
    required List<Employee> assignees,
    required String? requestedId,
  }) {
    if (assignees.isEmpty) return null;
    if (requestedId != null && assignees.any((e) => e.id == requestedId)) {
      return requestedId;
    }
    // Prioritize active on duty employee
    final active = assignees.where((e) => eco.isEmployeeActiveOnDuty(e.id)).toList();
    if (active.isNotEmpty) {
      return active.first.id;
    }
    // Fall back to first off-duty employee
    return assignees.first.id;
  }

  List<DropdownMenuItem<String>> _buildCategorizedAssigneeDropdownItems({
    required EcosystemProvider eco,
    required List<Employee> assignees,
  }) {
    final activeAssignees = assignees.where((e) => eco.isEmployeeActiveOnDuty(e.id)).toList();
    final offDutyAssignees = assignees.where((e) => !eco.isEmployeeActiveOnDuty(e.id)).toList();

    final items = <DropdownMenuItem<String>>[];

    // 1. ACTIVE / LOGGED IN CATEGORY HEADER
    items.add(
      DropdownMenuItem<String>(
        enabled: false,
        value: '__cat_active_header__',
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'ACTIVE / ON DUTY STAFF (${activeAssignees.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Active recipients or placeholder
    if (activeAssignees.isNotEmpty) {
      for (final e in activeAssignees) {
        items.add(
          DropdownMenuItem<String>(
            value: e.id,
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 5, color: Color(0xFF10B981)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${e.name} (${e.straightCutRole}) • On Duty',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textDark, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          value: '__no_active_recipients__',
          child: Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No Active Recipients',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. OFF DUTY / ABSENT CATEGORY HEADER
    items.add(
      DropdownMenuItem<String>(
        enabled: false,
        value: '__cat_off_duty_header__',
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'OFF DUTY STAFF (${offDutyAssignees.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEF4444),
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Off duty recipients
    for (final e in offDutyAssignees) {
      items.add(
        DropdownMenuItem<String>(
          value: e.id,
          child: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 5, color: Color(0xFFEF4444)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${e.name} (${e.straightCutRole}) • Off Duty',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return items;
  }

  List<Widget> _buildAssigneeSelectedWidgets({
    required EcosystemProvider eco,
    required List<DropdownMenuItem<String>> items,
    required List<Employee> assignees,
  }) {
    return items.map<Widget>((item) {
      if (item.value == null || item.value!.startsWith('__')) {
        return const SizedBox.shrink();
      }
      final emp = assignees.firstWhere(
        (e) => e.id == item.value,
        orElse: () => assignees.first,
      );
      final isOnDuty = eco.isEmployeeActiveOnDuty(emp.id);
      final duty = isOnDuty ? 'On Duty' : 'Off Duty';
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '${emp.name} (${emp.straightCutRole}) • $duty',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isOnDuty ? FontWeight.w600 : FontWeight.normal,
            color: isOnDuty ? Colors.white : AppColors.sandLight,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final eco = Provider.of<EcosystemProvider>(context);
    final activeEmp = eco.currentEmployee;
    final isCeo = activeEmp.roleType == 'ceo' || activeEmp.role.toLowerCase().contains('ceo');
    final isHr = activeEmp.roleType == 'hr' || activeEmp.role.toLowerCase().contains('hr');
    final isCeoOrHr = isCeo || isHr;
    final departments = _getDepartments(eco, isCeoOrHr, activeEmp);

    // Get list of absent employees
    List<Employee> absentList = eco.employees.where((e) => eco.isEmployeeAbsent(e.id)).toList();

    // If Team Lead, filter to their department employees alone!
    if (!isCeo && !isHr) {
      absentList = absentList.where((e) => _isTeamMemberOf(e, activeEmp)).toList();
    } else if (_selectedDeptFilter != 'All') {
      absentList = absentList.where((e) => e.dept.toLowerCase() == _selectedDeptFilter.toLowerCase()).toList();
    }

    // Search query filter for absent staff
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      final searchedAbsent = absentList.where((e) {
        return e.name.toLowerCase().contains(q) ||
               e.id.toLowerCase().contains(q) ||
               e.role.toLowerCase().contains(q) ||
               e.dept.toLowerCase().contains(q) ||
               e.straightCutRole.toLowerCase().contains(q);
      }).toList();
      if (searchedAbsent.isNotEmpty) {
        absentList = searchedAbsent;
      }
    }

    // Sort absent staff alphabetically (A, B, C to Z name-wise arrangement)
    if (absentList.length > 1) {
      absentList.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    if (_selectedAbsentEmpId == null && absentList.isNotEmpty) {
      _selectedAbsentEmpId = absentList.first.id;
    } else if (_selectedAbsentEmpId != null && !absentList.any((e) => e.id == _selectedAbsentEmpId)) {
      _selectedAbsentEmpId = absentList.isNotEmpty ? absentList.first.id : null;
    }

    final selectedAbsentEmp = _selectedAbsentEmpId != null
        ? eco.employees.firstWhere((e) => e.id == _selectedAbsentEmpId, orElse: () => eco.employees.first)
        : null;

    final absentTasks = selectedAbsentEmp != null
        ? eco.tasks.where((t) => t.empId == selectedAbsentEmp.id && t.status == 'pending').toList()
        : <TaskItem>[];

    final eligibleAssignees = _getEligibleAssignees(
      eco: eco,
      activeEmp: activeEmp,
      absentEmpId: selectedAbsentEmp?.id,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: AppColors.burgundyBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.fromBorderSide(BorderSide(color: AppColors.sandGold, width: 1.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sandGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                  ),
                  child: const Icon(Icons.assignment_ind_outlined, color: AppColors.sandGold, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASSIGN TASKS TO OTHERS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Absentee Task Reassignment',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.sandLight, size: 20),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Authority Scope Pill
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.burgundySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    isCeo ? Icons.workspace_premium : (isHr ? Icons.verified_user : Icons.supervised_user_circle),
                    size: 14,
                    color: AppColors.sandGold,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCeo
                          ? 'CEO (${activeEmp.name})'
                          : (isHr
                              ? 'HR (${activeEmp.name})'
                              : 'Team Lead (${activeEmp.name})'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sandLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                    ),
                    icon: Icon(
                      _showNewTaskForm ? Icons.arrow_back : Icons.add,
                      size: 13,
                      color: AppColors.goldBright,
                    ),
                    label: Text(
                      _showNewTaskForm ? 'Absent Tasks' : 'New Task',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldBright,
                      ),
                    ),
                    onPressed: () => setState(() => _showNewTaskForm = !_showNewTaskForm),
                  ),
                ],
              ),
            ),
          ),

          // Search, Department Filter & Sort Hub
          _buildSearchAndFilterHub(context, eco, isCeoOrHr, activeEmp, departments),

          const Divider(color: AppColors.sandBorder, height: 12),

          // Body Content
          Expanded(
            child: _showNewTaskForm
                ? _buildNewTaskView(context, eco, activeEmp)
                : _buildAbsenteeReassignmentView(
                    context,
                    eco,
                    activeEmp,
                    absentList,
                    selectedAbsentEmp,
                    absentTasks,
                    eligibleAssignees,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHub(
    BuildContext context,
    EcosystemProvider eco,
    bool isCeoOrHr,
    Employee activeEmp,
    List<String> departments,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input bar
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.burgundySurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.sandBorder.withOpacity(0.8)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textDark, fontSize: 11.5),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                hintText: isCeoOrHr ? 'Search staff by name, role, dept...' : 'Search team members...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.sandGold),
                prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14, color: AppColors.sandLight),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        splashRadius: 14,
                        padding: EdgeInsets.zero,
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Department Filter (CEO / HR) or Team Scope Badge (TL)
          isCeoOrHr
              ? Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandBorder.withOpacity(0.6)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: departments.contains(_selectedDeptFilter) ? _selectedDeptFilter : 'All',
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.sandGold, size: 20),
                      dropdownColor: AppColors.burgundySurface,
                      style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                      items: departments.map((d) {
                        return DropdownMenuItem<String>(
                          value: d,
                          child: Text(
                            d == 'All' ? 'Dept: All' : 'Dept: $d',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: d == _selectedDeptFilter ? AppColors.magentaPrimary : AppColors.textSecondary,
                              fontWeight: d == _selectedDeptFilter ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedDeptFilter = val);
                      },
                    ),
                  ),
                )
              : Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.sandGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.groups, size: 16, color: AppColors.sandGold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${activeEmp.dept.contains("Online") ? "Online Dept" : activeEmp.dept} (My Team)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.sandLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAbsenteeReassignmentView(
    BuildContext context,
    EcosystemProvider eco,
    Employee activeEmp,
    List<Employee> absentList,
    Employee? selectedAbsentEmp,
    List<TaskItem> absentTasks,
    List<Employee> eligibleAssignees,
  ) {
    if (absentList.isEmpty) {
      final isFiltered = _searchQuery.isNotEmpty || _selectedDeptFilter != 'All';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isFiltered ? AppColors.sandGold.withOpacity(0.12) : AppColors.ragGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: isFiltered ? AppColors.sandGold.withOpacity(0.4) : AppColors.ragGreen.withOpacity(0.4)),
                ),
                child: Icon(
                  isFiltered ? Icons.search_off : Icons.check_circle_outline,
                  color: isFiltered ? AppColors.sandGold : AppColors.ragGreen,
                  size: 42,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isFiltered ? 'No Staff Found' : 'All Staff Present Today',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandGold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isFiltered
                    ? 'No absent employees matched your filter. Try adjusting your search query or department filter.'
                    : 'No absent staff members found. All daily SOP tasks are covered by active present team members.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              if (isFiltered)
                LiquidGlassButton(
                  label: 'Clear Filters',
                  icon: Icons.clear_all,
                  height: 38,
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _selectedDeptFilter = 'All';
                    });
                  },
                )
              else
                LiquidGlassButton(
                  label: 'Create Direct Task',
                  icon: Icons.add_task,
                  height: 38,
                  onPressed: () => setState(() => _showNewTaskForm = true),
                ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Absent Members Horizontal Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ABSENT STAFF (A TO Z)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandLight,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (absentList.length > 1) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.sandGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.sandGold.withOpacity(0.35)),
                  ),
                  child: Text(
                    '${absentList.length} Absent • A-Z Arranged',
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: absentList.map((emp) {
                final isSelected = emp.id == _selectedAbsentEmpId;
                final taskCount = eco.tasks.where((t) => t.empId == emp.id && t.status == 'pending').length;
                final firstLetter = emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '#';
                return GestureDetector(
                  onTap: () => setState(() => _selectedAbsentEmpId = emp.id),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE11D48) : AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFE11D48) : AppColors.sandBorder,
                        width: isSelected ? 1.4 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFE11D48).withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? Colors.white.withOpacity(0.25) : AppColors.magentaSubtle,
                            border: Border.all(color: isSelected ? Colors.white : AppColors.magentaBorder, width: 0.8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            firstLetter,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : AppColors.magentaPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp.name,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.textDark,
                              ),
                            ),
                            Text(
                              '$taskCount pending tasks',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Selected Absent Staff Summary Card & Batch Reassign
          if (selectedAbsentEmp != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFEF4444).withOpacity(0.2),
                    child: const Icon(Icons.person_off_outlined, color: Color(0xFFEF4444), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedAbsentEmp.name,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFEF4444)),
                              ),
                              child: const Text(
                                'ABSENT',
                                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.ragRed),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${selectedAbsentEmp.role} • ${selectedAbsentEmp.dept}',
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Batch Reassign Section (if tasks exist)
            if (absentTasks.isNotEmpty && eligibleAssignees.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.burgundySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.goldPrimary.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on, size: 14, color: AppColors.goldBright),
                        const SizedBox(width: 6),
                        Text(
                          'Reassign All (${absentTasks.length}) Tasks',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldBright,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final batchValue = _resolveDefaultAssigneeId(
                          eco: eco,
                          assignees: eligibleAssignees,
                          requestedId: _batchTargetColleagueId,
                        );
                        final batchItems = _buildCategorizedAssigneeDropdownItems(
                          eco: eco,
                          assignees: eligibleAssignees,
                        );
                        return Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: batchValue,
                                dropdownColor: AppColors.burgundySurface,
                                style: const TextStyle(color: AppColors.textDark, fontSize: 11),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: AppColors.cardSurface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: AppColors.sandBorder),
                                  ),
                                ),
                                items: batchItems,
                                selectedItemBuilder: (ctx) => _buildAssigneeSelectedWidgets(
                                  eco: eco,
                                  items: batchItems,
                                  assignees: eligibleAssignees,
                                ),
                                onChanged: (v) {
                                  if (v != null && !v.startsWith('__')) {
                                    setState(() => _batchTargetColleagueId = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.magentaPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.check, size: 14),
                              label: const Text('Reassign All', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                final targetId = _resolveDefaultAssigneeId(
                                  eco: eco,
                                  assignees: eligibleAssignees,
                                  requestedId: _batchTargetColleagueId,
                                );
                                if (targetId == null) return;
                                eco.batchReassignAbsentTasks(
                                  fromEmpId: selectedAbsentEmp.id,
                                  toEmpId: targetId,
                                  authorizedByName: activeEmp.name,
                                  authorizedByRole: activeEmp.role,
                                );
                                final targetEmp = eco.employees.firstWhere((e) => e.id == targetId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('All tasks reassigned to ${targetEmp.name}!'),
                                    backgroundColor: AppColors.ragGreen,
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Individual Tasks List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PENDING TASKS (${absentTasks.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (absentTasks.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Center(
                  child: Text(
                    'No pending tasks for ${selectedAbsentEmp.name}.',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: absentTasks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final task = absentTasks[idx];

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.burgundyCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.sandBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: task.priority == 'Critical SLA'
                                    ? const Color(0xFFEF4444).withOpacity(0.2)
                                    : AppColors.sandGold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: task.priority == 'Critical SLA' ? const Color(0xFFEF4444) : AppColors.sandGold,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                task.priority,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: task.priority == 'Critical SLA' ? AppColors.ragRed : AppColors.sandGold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text('Due: ${task.due}', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '• ${task.category}',
                                style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Reassign Picker & Action Buttons
                        if (eligibleAssignees.isNotEmpty) ...[
                          Builder(
                            builder: (context) {
                              final taskAssigneeValue = _resolveDefaultAssigneeId(
                                eco: eco,
                                assignees: eligibleAssignees,
                                requestedId: _selectedTargetColleagueByTask[task.id] ?? _batchTargetColleagueId,
                              );
                              final taskItems = _buildCategorizedAssigneeDropdownItems(
                                eco: eco,
                                assignees: eligibleAssignees,
                              );
                              return Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      value: taskAssigneeValue,
                                      dropdownColor: AppColors.burgundySurface,
                                      style: const TextStyle(color: AppColors.textDark, fontSize: 11),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                        filled: true,
                                        fillColor: AppColors.cardSurface,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.sandBorder),
                                        ),
                                      ),
                                      items: taskItems,
                                      selectedItemBuilder: (ctx) => _buildAssigneeSelectedWidgets(
                                        eco: eco,
                                        items: taskItems,
                                        assignees: eligibleAssignees,
                                      ),
                                      onChanged: (v) {
                                        if (v != null && !v.startsWith('__')) {
                                          setState(() => _selectedTargetColleagueByTask[task.id] = v);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.magentaPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.swap_horiz, size: 14),
                                    label: const Text('Assign', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      final newEmpId = _resolveDefaultAssigneeId(
                                        eco: eco,
                                        assignees: eligibleAssignees,
                                        requestedId: _selectedTargetColleagueByTask[task.id] ?? _batchTargetColleagueId,
                                      );
                                      if (newEmpId == null) return;
                                      eco.reassignTask(
                                        taskId: task.id,
                                        newEmpId: newEmpId,
                                        assignedByName: activeEmp.name,
                                        assignedByRole: activeEmp.role,
                                      );
                                      final newEmp = eco.employees.firstWhere((e) => e.id == newEmpId);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Task "${task.title}" reassigned to ${newEmp.name}!'),
                                          backgroundColor: AppColors.ragGreen,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.magentaSubtle,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 13, color: AppColors.sandGold),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No staff found matching "$_searchQuery". Clear search to reassign.'
                                        : 'No eligible assignees available.',
                                    style: const TextStyle(fontSize: 10, color: AppColors.sandGold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                            ),
                            icon: const Icon(Icons.schedule_send, size: 12, color: AppColors.textMuted),
                            label: const Text(
                              'Shift to Tomorrow',
                              style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                            ),
                            onPressed: () {
                              eco.shiftTaskToNextDay(task.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Task "${task.title}" shifted to tomorrow.'),
                                  backgroundColor: AppColors.sandGold,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildNewTaskView(BuildContext context, EcosystemProvider eco, Employee activeEmp) {
    final staffList = _getEligibleAssignees(
      eco: eco,
      activeEmp: activeEmp,
      absentEmpId: null,
    );

    if (_newAssigneeId == null || !staffList.any((e) => e.id == _newAssigneeId)) {
      _newAssigneeId = staffList.isNotEmpty ? staffList.first.id : null;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'DISPATCH NEW TASK TO OTHERS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.sandGold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),

          // Assignee dropdown
          const Text('Assign To Colleague', style: TextStyle(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (staffList.isNotEmpty)
            Builder(
              builder: (context) {
                final newAssigneeVal = _resolveDefaultAssigneeId(
                  eco: eco,
                  assignees: staffList,
                  requestedId: _newAssigneeId,
                );
                final newItems = _buildCategorizedAssigneeDropdownItems(
                  eco: eco,
                  assignees: staffList,
                );
                return DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: newAssigneeVal,
                  dropdownColor: AppColors.burgundySurface,
                  style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  ),
                  items: newItems,
                  selectedItemBuilder: (ctx) => _buildAssigneeSelectedWidgets(
                    eco: eco,
                    items: newItems,
                    assignees: staffList,
                  ),
                  onChanged: (v) {
                    if (v != null && !v.startsWith('__')) {
                      setState(() => _newAssigneeId = v);
                    }
                  },
                );
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.magentaSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.sandBorder.withOpacity(0.5)),
              ),
              child: Text(
                _searchQuery.isNotEmpty
                    ? 'No colleagues found matching "$_searchQuery". Clear search.'
                    : 'No eligible colleagues found for assignment.',
                style: const TextStyle(fontSize: 11, color: AppColors.sandGold),
              ),
            ),
          const SizedBox(height: 12),

          // Title
          const Text('Task Description', style: TextStyle(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _newTitleController,
            style: const TextStyle(color: AppColors.textDark, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'e.g. Verify Gold Hallmark or Settle Counter Register',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
              filled: true,
              fillColor: AppColors.burgundySurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
            ),
          ),
          const SizedBox(height: 12),

          // Priority & Due
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Priority', style: TextStyle(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _newPriority,
                      dropdownColor: AppColors.burgundySurface,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.burgundySurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Critical SLA', child: Text('Critical SLA')),
                        DropdownMenuItem(value: 'High Priority', child: Text('High Priority')),
                        DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _newPriority = v);
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
                    const Text('Due Time', style: TextStyle(fontSize: 11, color: AppColors.sandLight, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _newDue,
                      dropdownColor: AppColors.burgundySurface,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.burgundySurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      ),
                      items: const [
                        DropdownMenuItem(value: '12:00 PM', child: Text('12:00 PM')),
                        DropdownMenuItem(value: '02:00 PM', child: Text('02:00 PM')),
                        DropdownMenuItem(value: '04:00 PM', child: Text('04:00 PM')),
                        DropdownMenuItem(value: '06:00 PM', child: Text('06:00 PM')),
                        DropdownMenuItem(value: '08:00 PM', child: Text('08:00 PM')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _newDue = v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          LiquidGlassButton(
            label: 'Dispatch Task',
            icon: Icons.send,
            height: 42,
            onPressed: () {
              if (_newTitleController.text.trim().isEmpty || _newAssigneeId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter task description and select assignee.')),
                );
                return;
              }
              eco.assignTask(
                empId: _newAssigneeId!,
                title: _newTitleController.text.trim(),
                category: 'Manager Directive',
                priority: _newPriority,
                due: _newDue,
                assignedByRole: activeEmp.role,
                assignedByName: '${activeEmp.name} (${activeEmp.straightCutRole})',
              );
              Navigator.pop(context);
              final assignee = eco.employees.firstWhere((e) => e.id == _newAssigneeId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Task dispatched to ${assignee.name}!'),
                  backgroundColor: AppColors.ragGreen,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

