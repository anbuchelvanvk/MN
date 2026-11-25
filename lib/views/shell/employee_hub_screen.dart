import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/add_todo_dialog.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../../providers/ecosystem_provider.dart';
import '../employee/employee_subpages.dart';
import '../konar/konar_book_detail_screen.dart';
import '../notes/personal_notes_screen.dart';
import '../orders/online_orders_handler_screen.dart';
import '../pillars/attendance_pillar_screen.dart';
import '../pillars/family_pillar_screen.dart';
import '../pillars/health_pillar_screen.dart';
import '../pillars/profile_pillar_screen.dart';
import '../pillars/social_cause_pillar_screen.dart';
import 'role_hub_widgets.dart';
import 'my_todo_list_card.dart';

/// Staff member's third tab: their day's work and every personal tool.
class EmployeeHubScreen extends StatelessWidget {
  const EmployeeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final me = eco.currentEmployee;
    final tasks = eco.currentEmployeeTasks;
    final open = tasks.where((t) => t.status == 'pending' || t.status == 'postponed').length;
    final done = tasks.where((t) => t.status == 'completed').length;
    final now = DateTime.now();
    final causes = eco.currentEmployeeSocialCauses
        .where((c) => c.date.year == now.year && c.date.month == now.month)
        .length;
    final isOnline = me.dept.toLowerCase().contains('online');

    final tools = <HubTool>[
      HubTool(Icons.checklist_rounded, 'My Tasks', '$open to do', AppColors.primary,
          () => openHubScreen(context, const EmployeeThingsToDoScreen())),
      HubTool(Icons.fingerprint_rounded, 'Attendance', 'Calendar & leaves', const Color(0xFF059669),
          () => openHubScreen(context, const AttendancePillarScreen())),
      HubTool(Icons.work_rounded, 'Work', 'Documents & grooming', const Color(0xFFD97706),
          () => openHubScreen(context, const ProfilePillarScreen())),
      HubTool(Icons.favorite_rounded, 'Health', 'Food, steps & BMI', const Color(0xFF0E9F6E),
          () => openHubScreen(context, const HealthPillarScreen())),
      HubTool(Icons.family_restroom_rounded, 'Family Time', 'Log time together', const Color(0xFFBE185D),
          () => openHubScreen(context, const FamilyPillarScreen())),
      HubTool(Icons.volunteer_activism_rounded, 'Social Cause', '$causes this month', const Color(0xFF0F766E),
          () => openHubScreen(context, const SocialCausePillarScreen())),
      HubTool(Icons.badge_rounded, 'Digital ID', 'Your staff card', const Color(0xFF334155),
          () => openHubScreen(context, const EmployeeDigitalIdScreen())),
      HubTool(Icons.menu_book_rounded, 'Konar Book', 'Department handbook', const Color(0xFF881337),
          () => openHubScreen(context, KonarBookDetailScreen(department: me.dept.isNotEmpty ? me.dept : 'Online Department'))),
      if (isOnline)
        HubTool(Icons.shopping_bag_rounded, 'Online Orders', 'Track & dispatch', const Color(0xFFEA580C),
            () => openHubScreen(context, const OnlineOrdersHandlerScreen())),
      HubTool(Icons.lock_rounded, 'Personal Notes', 'Private to you', const Color(0xFF5B5068),
          () => openHubScreen(context, const PersonalNotesScreen())),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: MnAppBar(
        title: 'My Work',
        subtitle: me.dept.isNotEmpty ? '${me.straightCutRole} • ${me.dept}' : me.straightCutRole,
        actions: [
          MnHeaderPill(
            icon: Icons.add_rounded,
            label: 'To-do',
            onTap: () => showAddPersonalTodoDialog(context, eco),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => eco.refreshAllData(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            HubStatsRow(stats: [
              HubStat(Icons.pending_actions_rounded, '$open', 'To do', const Color(0xFFD97706),
                  onTap: () => openHubScreen(context, const EmployeeThingsToDoScreen())),
              HubStat(Icons.task_alt_rounded, '$done', 'Done', AppColors.ragGreen,
                  onTap: () => openHubScreen(context, const EmployeeThingsToDoScreen())),
              HubStat(Icons.volunteer_activism_rounded, '$causes', 'Good deeds', const Color(0xFF0F766E),
                  onTap: () => openHubScreen(context, const SocialCausePillarScreen())),
            ]),
            const SizedBox(height: 16),
            const MyTodoListCard(),
            const SizedBox(height: 22),
            const MnSectionTitle('Everything for you'),
            const SizedBox(height: 12),
            HubToolGrid(tools: tools),
          ],
        ),
      ),
    );
  }
}
