import '../../core/widgets/task_action_dialogs.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../core/widgets/cross_dept_blocker_section.dart';
import '../../core/widgets/quick_pillar_nav_row.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/role_app_bar.dart';
import '../../models/task_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../auth/pillars_popup_dialog.dart';
import '../pillars/social_cause_pillar_screen.dart';
import '../../core/widgets/company_notification_sheet.dart';
import '../pillars/attendance_pillar_screen.dart';

import 'employee_profile_screen.dart';
import 'employee_subpages.dart';
import '../orders/online_orders_handler_screen.dart';
import '../notes/personal_notes_screen.dart';

class EmployeePortalScreen extends StatefulWidget {
  const EmployeePortalScreen({super.key});

  @override
  State<EmployeePortalScreen> createState() => _EmployeePortalScreenState();
}

class _EmployeePortalScreenState extends State<EmployeePortalScreen> {
  int _activeBottomNav = 0; // 0: Home, 1: Tasks, 2: Academy, 3: Profile
  String _taskFilter = 'all'; // 'all', 'pending', 'postponed', 'completed'

  @override
  void initState() {
    super.initState();
    // Display the 4-button closable popup once the user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PillarsPopupDialog.show(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final emp = eco.currentEmployee;
    final allTasks = eco.currentEmployeeTasks;

    final filteredTasks = allTasks.where((t) {
      if (_taskFilter == 'all') return true;
      return t.status == _taskFilter;
    }).toList();

    final pendingCount = allTasks.where((t) => t.isPending).length;

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: RoleAppBar(
        roleName: 'Employee',
        userName: '${emp.name} (${emp.straightCutRole})',
        roleColor: AppColors.goldPrimary,
        roleIcon: Icons.person_outline,
        onBellPressed: () => CompanyNotificationSheet.show(context),
      ),
      body: IndexedStack(
        index: _activeBottomNav,
        children: [
          // Screen 0: Home Dashboard
          _buildHomeDashboard(context, eco, emp, pendingCount, filteredTasks),

          // Screen 1: Full Tasks (Things To Do)
          _buildFullTasksScreen(context, eco, emp, filteredTasks),

          // Screen 2: Social Cause (Pillar 5)
          const SocialCausePillarScreen(isStandalone: false),

          // Screen 3: Digital Vault & Profile Audit
          _buildProfileVaultScreen(context, eco, emp),
        ],
      ),
      bottomNavigationBar: _buildGlassBottomNav(context),
    );
  }

  Widget _buildGlassBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.burgundySurface,
        border: Border(
          top: BorderSide(
            color: AppColors.sandBorder,
            width: 1.2,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _navItem(0, Icons.dashboard_outlined, 'Home')),
              Expanded(child: _navItem(1, Icons.checklist_outlined, 'SOP Tasks')),
              Expanded(child: _navItem(2, Icons.volunteer_activism_outlined, 'Social Cause')),
              Expanded(child: _navItem(3, Icons.badge_outlined, 'ID Vault')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = _activeBottomNav == index;
    return InkWell(
      onTap: () => setState(() => _activeBottomNav = index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.magentaSubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.magentaPrimary : AppColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.magentaPrimary : AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDashboard(
    BuildContext context,
    EcosystemProvider eco,
    dynamic emp,
    int pendingCount,
    List<TaskItem> filteredTasks,
  ) {
    return RefreshIndicator(
      color: AppColors.sandGold,
      backgroundColor: AppColors.burgundyCard,
      onRefresh: () => eco.refreshAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Profile Card with Profile Navigation
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: LiquidGlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.goldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.goldPrimary.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            emp.initials,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    emp.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                LiquidGlassPill(
                                  label: 'On Track',
                                  color: AppColors.ragGreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              emp.role,
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _smallTag(Icons.diamond_outlined, emp.dept),
                                _smallTag(Icons.badge_outlined, 'ID: ${emp.id}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const QuickPillarNavRow(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Vertical Segmented Navigation Grid (Aesthetic 2-column view - no horizontal sliding required)
          Container(
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.apps_rounded, size: 15, color: AppColors.magentaPrimary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'WORKSPACE PORTALS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: 0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Direct Access',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    _verticalActionTile(
                      'Things To Do',
                      Icons.checklist,
                      pendingCount > 0 ? '$pendingCount' : '',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
                            value: eco,
                            child: const EmployeeThingsToDoScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _verticalActionTile(
                      'Social Cause',
                      Icons.volunteer_activism_outlined,
                      'Pillar 5',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
                            value: eco,
                            child: const EmployeeSocialCauseScreen(),
                          ),
                        ),
                      ),
                    ),
                    if (emp.hasAttendanceAndGrooming) ...[
                      const SizedBox(height: 8),
                      _verticalActionTile(
                        'Attendance Ledger',
                        Icons.fingerprint,
                        '',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
                              value: eco,
                              child: const AttendancePillarScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _verticalActionTile(
                      'Digital ID Vault',
                      Icons.badge_outlined,
                      '',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
                            value: eco,
                            child: const EmployeeDigitalIdScreen(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _verticalActionTile(
                      'Personal Notes',
                      Icons.lock_outline_rounded,
                      'Private',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
                            value: eco,
                            child: const PersonalNotesScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Online Orders Handler (Dedicated Quick Access for OS1, OS2 & Sales Team)
          if (emp.id == '65' || emp.id == '67' || emp.role.toLowerCase().contains('sales') || emp.role.toLowerCase().contains('online')) ...[
            LiquidGlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 16,
              borderColor: const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFFF59E0B), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Online Orders',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Track & manage customer orders',
                          style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.magentaPrimary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OnlineOrdersHandlerScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Today's Operational Agenda Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            "Today's Tasks",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${filteredTasks.length})',
                          style: const TextStyle(fontSize: 12, color: AppColors.magentaPrimary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Daily SOP Routines',
                      style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _activeBottomNav = 1),
                child: const Text('View All', style: TextStyle(fontSize: 12, color: AppColors.magentaPrimary)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Task List
          ...filteredTasks.take(4).map((task) => _taskCard(context, eco, task)),
          const SizedBox(height: 20),

          // Cross-Department Blocker Escalation
          CrossDeptBlockerSection(department: emp.dept),
          const SizedBox(height: 20),

          // Logout Button with confirmation
          LogoutConfirmDialog.buildButton(context),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

  Widget _buildFullTasksScreen(
    BuildContext context,
    EcosystemProvider eco,
    dynamic emp,
    List<TaskItem> filteredTasks,
  ) {
    final allTasks = eco.currentEmployeeTasks;
    return RefreshIndicator(
      color: AppColors.sandGold,
      backgroundColor: AppColors.burgundyCard,
      onRefresh: () => eco.refreshAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily SOP Tasks',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Operational Deliverables',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 14, color: Colors.white),
                label: const Text(
                  'Add To-Do',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.magentaPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 2,
                ),
                onPressed: () => _showAddTodoDialog(context, eco, emp),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Segmented 2-Column Grid (No horizontal sliding required)
          Container(
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, size: 16, color: AppColors.magentaPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'TASK STATUS FILTERS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Direct Access',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final pendingCount = allTasks.where((t) => t.isPending).length;
                    final completedCount = allTasks.where((t) => t.isCompleted).length;
                    final postponedCount = allTasks.where((t) => t.status == 'postponed').length;

                    return Column(
                      children: [
                        _verticalFilterTile('all', 'All Tasks', Icons.checklist_outlined, '${allTasks.length}'),
                        const SizedBox(height: 8),
                        _verticalFilterTile('pending', 'Pending Tasks', Icons.pending_actions_outlined, pendingCount > 0 ? '$pendingCount' : ''),
                        const SizedBox(height: 8),
                        _verticalFilterTile('postponed', 'Postponed', Icons.update_outlined, postponedCount > 0 ? '$postponedCount' : ''),
                        const SizedBox(height: 8),
                        _verticalFilterTile('completed', 'Completed', Icons.check_circle_outline, completedCount > 0 ? '$completedCount' : ''),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Render filtered list
          if (filteredTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No $_taskFilter tasks found.',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            ...filteredTasks.map((task) => _taskCard(context, eco, task)),
        ],
      ),
    ),
  );
}

  void _showCannotDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.burgundyCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.sandGold),
        ),
        title: Row(
          children: const [
            Icon(Icons.shield_outlined, color: AppColors.sandGold, size: 22),
            SizedBox(width: 8),
            Text(
              'HR Removal Required',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Per MN Jewel Park operational guidelines, employees cannot delete assigned or personal to-do tasks directly.',
              style: TextStyle(fontSize: 12, color: AppColors.sandLight, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.burgundySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'To remove this to-do, please contact HR Administration:',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 13, color: AppColors.sandGold),
                      SizedBox(width: 6),
                      Text('Mohankumar G (HR): +91 94433 11000', style: TextStyle(fontSize: 11, color: AppColors.sandLight)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email_outlined, size: 13, color: AppColors.sandGold),
                      SizedBox(width: 6),
                      Text('Email: hr@mnj.com', style: TextStyle(fontSize: 11, color: AppColors.sandLight)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(color: AppColors.sandGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context, EcosystemProvider eco, dynamic emp) {
    final titleCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final dueCtrl = TextEditingController();
    String selectedPriority = 'Standard';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.sandGold),
          ),
          title: Row(
            children: const [
              Icon(Icons.add_task, color: AppColors.sandGold, size: 20),
              SizedBox(width: 8),
              Text(
                'Add Personal To-Do',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('To-Do Title / Task', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                  decoration: InputDecoration(
                    hintText: 'e.g. Call customer Mr. Vignesh regarding bridal bangle...',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                const SizedBox(height: 6),
                TextField(
                  controller: categoryCtrl,
                  style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                  decoration: InputDecoration(
                    hintText: 'e.g. Customer Follow-up, Daily Check, Inventory...',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Due Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: dueCtrl,
                            style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                            decoration: InputDecoration(
                              hintText: '05:00 PM',
                              hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              filled: true,
                              fillColor: AppColors.burgundySurface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Priority', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                          const SizedBox(height: 6),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.burgundySurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.sandBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedPriority,
                                dropdownColor: AppColors.burgundyCard,
                                style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                                items: const [
                                  DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                                  DropdownMenuItem(value: 'High', child: Text('High')),
                                  DropdownMenuItem(value: 'Critical SLA', child: Text('Critical SLA')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setDialogState(() => selectedPriority = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Note: To remove this task later, please contact HR.',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.magentaPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a task title')),
                  );
                  return;
                }
                eco.addEmployeePersonalTodo(
                  empId: emp.id,
                  title: title,
                  category: categoryCtrl.text.trim().isEmpty ? 'General' : categoryCtrl.text.trim(),
                  dueTime: dueCtrl.text.trim().isEmpty ? '06:00 PM' : dueCtrl.text.trim(),
                  priority: selectedPriority,
                );
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF10B981),
                    content: Text('Personal to-do added successfully!'),
                  ),
                );
              },
              child: const Text('Add To-Do', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileVaultScreen(
    BuildContext context,
    EcosystemProvider eco,
    dynamic emp,
  ) {
    return RefreshIndicator(
      color: AppColors.sandGold,
      backgroundColor: AppColors.burgundyCard,
      onRefresh: () => eco.refreshAllData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Digital Smart ID Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.magentaPrimary.withOpacity(0.35), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.magentaPrimary),
                            color: Colors.black,
                          ),
                          child: ClipOval(
                            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'MN JEWEL PARK',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const Text(
                      'STAFF SMART ID',
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary, letterSpacing: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.magentaPrimary,
                      child: Text(emp.initials, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          Text(emp.role, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text('EMP ID: ${emp.id}', style: const TextStyle(fontSize: 11, color: AppColors.magentaPrimary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.sandBorder, height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Dept: ${emp.dept}', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                    Text('DOJ: ${emp.doj}', style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                    const Text('Status: VERIFIED', style: TextStyle(fontSize: 10.5, color: AppColors.ragGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Personal Profile & Password Actions Card
          LiquidGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.manage_accounts_outlined, color: AppColors.magentaPrimary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Personal Details & Security',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    LiquidGlassPill(label: 'CONFIDENTIAL', color: AppColors.magentaPrimary),
                  ],
                ),
                const SizedBox(height: 12),
                _personalInfoRow('Mobile Phone', emp.phone.isNotEmpty ? emp.phone : '+91 94420 11000'),
                _personalInfoRow('Official Email', emp.email),
                _personalInfoRow('Date of Birth (DOB)', emp.dob.isNotEmpty ? emp.dob : '1996-05-15'),
                _personalInfoRow('Relationship', emp.relationshipStatus.isNotEmpty ? emp.relationshipStatus : 'Single'),
                if (emp.relationshipStatus == 'Married')
                  _personalInfoRow('Anniversary Date', emp.anniversaryDate.isNotEmpty ? emp.anniversaryDate : '2022-01-20'),
                const SizedBox(height: 14),
                LiquidGlassButton(
                  label: 'Edit Profile & Change Password',
                  icon: Icons.edit_note,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Profile Clearance Checklist Card
          LiquidGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enterprise Compliance & KYC Checklist',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                _clearanceRow('1. Biometric Photo Identity', emp.profileCompletion.photoVerified),
                _clearanceRow('2. Residential Address Proof & Aadhaar', emp.profileCompletion.addressVerified),
                _clearanceRow('3. Government Tax KYC & PAN Card', emp.profileCompletion.kycVerified),
                _clearanceRow('4. Daily SOP Role Responsibilities Signed', emp.profileCompletion.sopRolesAcknowledged),
                const SizedBox(height: 12),
                LiquidGlassButton(
                  label: 'Update Clearance Status',
                  icon: Icons.edit_note,
                  onPressed: () => _openProfileWizard(context, eco, emp),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Logout Button with confirmation
          LogoutConfirmDialog.buildButton(context),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

  Widget _personalInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _clearanceRow(String title, bool verified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          Icon(
            verified ? Icons.check_circle : Icons.cancel_outlined,
            size: 16,
            color: verified ? AppColors.ragGreen : AppColors.ragRed,
          ),
        ],
      ),
    );
  }

  Widget _verticalActionTile(String label, IconData icon, String badge, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.magentaSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.magentaPrimary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppColors.magentaSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.magentaPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _verticalFilterTile(String filter, String label, IconData icon, String badge) {
    final isSelected = _taskFilter == filter;
    return InkWell(
      onTap: () => setState(() => _taskFilter = filter),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.magentaGradient : null,
          color: isSelected ? null : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.magentaPrimary.withOpacity(0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.magentaSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.magentaPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badge.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.25) : AppColors.magentaSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.magentaPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isSelected ? Colors.white.withOpacity(0.8) : const Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _smallTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.magentaSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.sandBorder, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: AppColors.magentaPrimary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _taskCard(BuildContext context, EcosystemProvider eco, TaskItem task) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (task.isCompleted) {
      statusColor = AppColors.ragGreen;
      statusLabel = 'Completed';
      statusIcon = Icons.check_circle;
    } else if (task.isPostponed) {
      statusColor = AppColors.ragRed;
      statusLabel = 'Postponed';
      statusIcon = Icons.schedule;
    } else {
      statusColor = AppColors.ragYellow;
      statusLabel = 'Pending';
      statusIcon = Icons.pending;
    }

    return InkWell(
      onTap: () => TaskActionDialogs.handleTaskTap(context, eco, task),
      borderRadius: BorderRadius.circular(16),
      child: LiquidGlassCard(
        padding: const EdgeInsets.all(13),
        borderRadius: 16,
        borderColor: task.isPending
            ? AppColors.magentaPrimary.withOpacity(0.25)
            : (task.isCompleted ? AppColors.ragGreen.withOpacity(0.3) : AppColors.sandBorder),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                LiquidGlassPill(label: statusLabel, color: statusColor, icon: statusIcon),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${task.due}',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _showCannotDeleteDialog(context),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.delete_outline, size: 12, color: Color(0xFFEF4444)),
                            SizedBox(width: 2),
                            Text(
                              'Remove',
                              style: TextStyle(fontSize: 9, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            task.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: task.isCompleted ? const Color(0xFF94A3B8) : AppColors.textDark,
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              decorationColor: task.isCompleted ? AppColors.ragGreen : null,
              decorationThickness: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.category,
                  style: const TextStyle(fontSize: 9.5, color: AppColors.goldBright, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'By: ${task.assignedByName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),

          // Attached Proof View
          if (task.proof != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.ragGreen.withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      task.proof!.photoUrl ?? '',
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 42,
                        height: 42,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.image, size: 18, color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified, size: 12, color: AppColors.ragGreen),
                            const SizedBox(width: 4),
                            Text(
                              'Verified at ${task.proof!.timestamp}',
                              style: const TextStyle(fontSize: 10, color: AppColors.ragGreen, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.proof!.content,
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Postponed Reason View
          if (task.postponeInfo != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.ragRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.ragRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.ragRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rescheduled to: ${task.postponeInfo!.postponedTo}',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.ragRed),
                        ),
                        Text(
                          'Reason: ${task.postponeInfo!.reason}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Interactive Action Buttons
          if (task.isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LiquidGlassButton(
                    label: 'Complete Task',
                    icon: Icons.check_circle_outline,
                    height: 36,
                    onPressed: () => TaskActionDialogs.showCompletionModal(context, eco, task),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LiquidGlassButton(
                    label: 'Postpone',
                    icon: Icons.history_toggle_off,
                    isPrimary: false,
                    height: 36,
                    onPressed: () => _openPostponeDialog(context, eco, task),
                  ),
                ),
              ],
            ),
          ] else if (task.isCompleted) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle, size: 14, color: AppColors.ragGreen),
                    SizedBox(width: 5),
                    Text(
                      'Completed & Verified',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.ragGreen),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => TaskActionDialogs.showRevertDialog(context, eco, task),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.undo, size: 11, color: Color(0xFFEF4444)),
                        SizedBox(width: 3),
                        Text(
                          'Uncheck',
                          style: TextStyle(fontSize: 9.5, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
  }

  // --- DIALOGS ---

  void _openPostponeDialog(BuildContext context, EcosystemProvider eco, TaskItem task) {
    String selectedReason = 'Late bridal custom sizing order delayed workshop furnace shutdown.';
    String rescheduleTime = 'Tomorrow 08:30 AM';

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
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
              ),
              decoration: const BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Postpone Operational Task',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Text(
                    'Postponing requires operational SLA justification for Dept Head review.',
                    style: TextStyle(fontSize: 11, color: AppColors.ragRed),
                  ),
                  const SizedBox(height: 12),

                  const Text('Select Reason:', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    dropdownColor: AppColors.burgundySurface,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textDark),
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.magentaSubtle,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Late bridal custom sizing order delayed workshop furnace shutdown.',
                        child: Text('Custom sizing delay'),
                      ),
                      DropdownMenuItem(
                        value: 'Customer rescheduled appointment / bridal trial postponed.',
                        child: Text('Customer rescheduled'),
                      ),
                      DropdownMenuItem(
                        value: 'Government BIS Hallmarking Portal Latency.',
                        child: Text('Hallmarking delay'),
                      ),
                      DropdownMenuItem(
                        value: 'Supplier Raw Ingot Bar delayed in transit.',
                        child: Text('Supplier material delay'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedReason = val);
                    },
                  ),
                  const SizedBox(height: 10),

                  const Text('New Time:', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: rescheduleTime,
                    style: const TextStyle(color: AppColors.textDark, fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.magentaSubtle,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.magentaPrimary)),
                    ),
                    onChanged: (v) => rescheduleTime = v,
                  ),
                  const SizedBox(height: 16),
                  LiquidGlassButton(
                    label: 'Confirm Postponement',
                    icon: Icons.schedule,
                    color: AppColors.ragRed,
                    onPressed: () {
                      eco.postponeTask(task.id, reason: selectedReason, postponedTo: rescheduleTime);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Task postponed and logged for executive review.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
          },
        );
      },
    );
  }

  void _openProfileWizard(BuildContext context, EcosystemProvider eco, dynamic emp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final pc = emp.profileCompletion;
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Profile Verification Wizard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  Text('Progress: ${pc.percentage}% • ${pc.isAuthorized ? "VERIFIED" : "ACTION REQUIRED"}', style: const TextStyle(fontSize: 11.5, color: AppColors.magentaPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('1. Photo Identity Verified', style: TextStyle(color: AppColors.textDark, fontSize: 12.5)),
                    subtitle: const Text('Biometric pass verified', style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
                    value: pc.photoVerified,
                    activeColor: AppColors.magentaPrimary,
                    onChanged: (v) {
                      eco.verifyProfileStep(emp.id, photo: v);
                      setModalState(() {});
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('2. Residential Address Proof', style: TextStyle(color: AppColors.textDark, fontSize: 12.5)),
                    subtitle: const Text('Utility bill & Aadhaar copy verified', style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
                    value: pc.addressVerified,
                    activeColor: AppColors.magentaPrimary,
                    onChanged: (v) {
                      eco.verifyProfileStep(emp.id, address: v);
                      setModalState(() {});
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('3. Government Tax KYC & PAN Card', style: TextStyle(color: AppColors.textDark, fontSize: 12.5)),
                    subtitle: const Text('PAN linked to payroll portal', style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
                    value: pc.kycVerified,
                    activeColor: AppColors.magentaPrimary,
                    onChanged: (v) {
                      eco.verifyProfileStep(emp.id, kyc: v);
                      setModalState(() {});
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('4. Predefined Daily SOP Responsibilities', style: TextStyle(color: AppColors.textDark, fontSize: 12.5)),
                    subtitle: const Text('Digitally signed and acknowledged', style: TextStyle(color: AppColors.textSecondary, fontSize: 10.5)),
                    value: pc.sopRolesAcknowledged,
                    activeColor: AppColors.magentaPrimary,
                    onChanged: (v) {
                      eco.verifyProfileStep(emp.id, sop: v);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  LiquidGlassButton(
                    label: 'Save & Close Wizard',
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

}
