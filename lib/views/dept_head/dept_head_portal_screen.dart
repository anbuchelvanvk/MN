import '../../core/widgets/export_audit_modal.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../core/widgets/assign_tasks_to_others_modal.dart';
import '../../core/widgets/quick_pillar_nav_row.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../core/widgets/role_app_bar.dart';
import '../../providers/ecosystem_provider.dart';
import '../auth/pillars_popup_dialog.dart';
import '../employee/employee_profile_screen.dart';
import '../orders/online_orders_handler_screen.dart';
import 'dept_head_subpages.dart';
import 'monthly_scorecard_screen.dart';
import '../notes/personal_notes_screen.dart';
import '../chat/chat_hub_screen.dart';
import '../../core/widgets/daily_pending_actions_dialog.dart';
import '../../core/widgets/birthday_celebration_dialog.dart';
import '../konar/konar_book_detail_screen.dart';
import '../media/creative_media_review_board_screen.dart';
import '../home/modern_home_screen.dart';
import '../../core/widgets/employee_avatar.dart';

class DeptHeadPortalScreen extends StatefulWidget {
  const DeptHeadPortalScreen({super.key});

  @override
  State<DeptHeadPortalScreen> createState() => _DeptHeadPortalScreenState();
}

class _DeptHeadPortalScreenState extends State<DeptHeadPortalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        context.read<EcosystemProvider>().setLoggedIn(true);
        await BirthdayCelebrationDialog.showIfNeeded(context);
        if (mounted) {
          await PillarsPopupDialog.show(context);
          if (mounted) {
            await Future.delayed(const Duration(milliseconds: 250));
            if (mounted) {
              await DailyPendingActionsDialog.showIfNeeded(context);
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final opsTasks = eco.operationsDeptTasks;
    final openCount = opsTasks.where((t) => t.isPending).length;
    final postponedCount = opsTasks.where((t) => t.isPostponed).length;
    final teamMembers = eco.myTeamMembers;
    final teamAbsentees = teamMembers.where((m) => eco.isEmployeeAbsent(m.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: RoleAppBar(
        roleName: 'Team Lead',
        userName: '${eco.currentEmployee.name} (Team Lead)',
        roleColor: AppColors.statusBlue,
        roleIcon: Icons.shield_outlined,
        onExportPressed: () => ExportAuditModal.showTeamLead(context),
      ),
      body: RefreshIndicator(
        color: AppColors.sandGold,
        backgroundColor: AppColors.burgundyCard,
        onRefresh: () => eco.refreshAllData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lead Hero Card with Profile Navigation
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: LiquidGlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: EmployeeAvatar(avatar: eco.currentEmployee.avatar, initials: eco.currentEmployee.initials, size: 50),
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
                                      eco.currentEmployee.name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.magentaSubtle,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.magentaBorder, width: 0.8),
                                    ),
                                    child: Text(
                                      'ID: ${eco.currentEmployee.id}',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.magentaPrimary,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                eco.currentEmployee.role.isNotEmpty
                                    ? eco.currentEmployee.role
                                    : 'Team Lead',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.magentaSubtle,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.sandBorder, width: 0.8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.group, size: 10, color: AppColors.magentaPrimary),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${teamMembers.length} Members',
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (eco.currentEmployee.dept.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.magentaSubtle,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.sandBorder, width: 0.8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.business_center_outlined, size: 10, color: AppColors.magentaPrimary),
                                          const SizedBox(width: 4),
                                          Text(
                                            eco.currentEmployee.dept,
                                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
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

            // Vertical Segmented Navigation Grid (Aesthetic 2-column view - Direct Access right below profile & pillars)
            Container(
              key: const ValueKey('dept_head_tabs_scroll'),
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
                      const Icon(Icons.apps_rounded, size: 16, color: AppColors.magentaPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'TEAM TOOLS',
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
                        '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      _verticalTabTile(const ModernHomeScreen(), 'Home Dashboard', Icons.dashboard_customize_outlined, ''),
                      const SizedBox(height: 8),
                      _verticalTabTile(const ChatHubScreen(), 'Team Chat', Icons.chat_bubble_outline_rounded, eco.unreadTotalChatCount > 0 ? '${eco.unreadTotalChatCount}' : ''),
                      const SizedBox(height: 8),
                      _verticalTabTile(const CreativeMediaReviewBoardScreen(), 'Media Review Board', Icons.video_collection_outlined, eco.pendingMediaApprovalsCount > 0 ? '${eco.pendingMediaApprovalsCount}' : ''),
                      const SizedBox(height: 8),
                      _verticalTabTile(
                        KonarBookDetailScreen(
                          department: eco.currentEmployee.dept.isNotEmpty
                              ? eco.currentEmployee.dept
                              : 'Online Department',
                        ),
                        'KONAR Book',
                        Icons.menu_book_rounded,
                        '',
                      ),
                      const SizedBox(height: 8),
                      _verticalTabTile(
                        const MonthlyScorecardScreen(),
                        'Monthly Scorecard',
                        Icons.assessment_outlined,
                        '',
                      ),
                      const SizedBox(height: 8),
                      _verticalTabTile(const TlTeamTasksScreen(), 'Team Tasks', Icons.assignment_outlined, opsTasks.isNotEmpty ? '${opsTasks.length}' : ''),
                      const SizedBox(height: 8),
                      _verticalTabTile(const TlMyTasksScreen(), 'My Tasks', Icons.task_alt_outlined, ''),
                      const SizedBox(height: 8),
                      _verticalTabTile(const TlTeamDirectoryScreen(), 'Team', Icons.group_outlined, '${teamMembers.length}'),
                      const SizedBox(height: 8),
                      _verticalTabTile(const TlBlockerTicketsScreen(), 'Blocker Tickets', Icons.shield_outlined, ''),
                      const SizedBox(height: 8),
                      _verticalTabTile(const TlTeamAttendanceScreen(), 'Team Attendance', Icons.schedule_outlined, ''),
                      const SizedBox(height: 8),
                      _verticalTabTile(const PersonalNotesScreen(), 'Personal Notes', Icons.lock_outline_rounded, 'Private'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3 KPIs
            Row(
              children: [
                LiquidMetricCard(
                  label: 'Active Tasks',
                  value: '$openCount',
                  icon: Icons.checklist,
                  color: AppColors.goldPrimary,
                  onTap: () {
                    final eco = context.read<EcosystemProvider>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
                          value: eco,
                          child: const TlTeamTasksScreen(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                LiquidMetricCard(
                  label: 'Postponed',
                  value: '$postponedCount',
                  icon: Icons.history_toggle_off,
                  color: AppColors.ragRed,
                  onTap: () {
                    final eco = context.read<EcosystemProvider>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
                          value: eco,
                          child: const TlTeamTasksScreen(),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                LiquidMetricCard(
                  label: 'Absent Staff',
                  value: '${teamAbsentees.length} Absent',
                  icon: Icons.person_off_outlined,
                  color: teamAbsentees.isEmpty ? AppColors.ragGreen : AppColors.ragRed,
                  onTap: () {
                    final eco = context.read<EcosystemProvider>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
                          value: eco,
                          child: const TlAbsenteesScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Absentee Alert Banner (Visible when any team member is absent)
            if (teamAbsentees.isNotEmpty) ...[
              LiquidGlassCard(
                borderRadius: 14,
                padding: const EdgeInsets.all(12),
                backgroundColor: const Color(0xFFFFF1F2),
                borderColor: const Color(0xFFFECDD3),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.ragRed, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Absentee Notice (${teamAbsentees.length})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Reallocate SOP Tasks',
                            style: TextStyle(fontSize: 11.5, color: AppColors.ragRed),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => AssignTasksToOthersModal.show(context),
                      child: const Text('Resolve', style: TextStyle(color: AppColors.magentaPrimary, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Primary Action Buttons
            Row(
              children: [
                Expanded(
                  child: LiquidGlassButton(
                    label: 'Assign Tasks to Others',
                    icon: Icons.assignment_ind_outlined,
                    onPressed: () => AssignTasksToOthersModal.show(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LiquidGlassButton(
                    label: 'Nudge Team',
                    icon: Icons.campaign_outlined,
                    isPrimary: false,
                    onPressed: () => _nudgeTeam(context, eco),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Online Orders Handler Quick Access (Exclusively for Online Department Team Leads)
            if (eco.currentEmployee.dept.toLowerCase().contains('online')) ...[
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnlineOrdersHandlerScreen()),
                ),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.whiteBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sandBorder, width: 1.1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.magentaSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: AppColors.magentaPrimary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Online Orders',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Workflow Checklist',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.magentaPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('Open', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_ios, size: 9, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // User Requirement: Overdue for the online order red pop-up / alert banner
              if (eco.overdueOnlineOrders.isNotEmpty) ...[
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnlineOrdersHandlerScreen()),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.ragRedBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.ragRed, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.ragRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Overdue for Online Orders (${eco.overdueOnlineOrders.length} Orders)',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SLA due dates passed for ${eco.overdueOnlineOrders.map((o) => "#${o.orderId} (${o.brand})").join(", ")}. Tap to review & reassign.',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.ragRed),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.ragRed),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],

            // Logout Button with confirmation
            LogoutConfirmDialog.buildButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
  }

  Widget _verticalTabTile(Widget destination, String label, IconData icon, String badge) {
    return InkWell(
      onTap: () {
        final eco = context.read<EcosystemProvider>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
              value: eco,
              child: destination,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.magentaSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: AppColors.magentaPrimary,
              ),
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
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.magentaPrimary,
                  ),
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

  void _nudgeTeam(BuildContext context, EcosystemProvider eco) {
    final msgController = TextEditingController(
      text: 'Shift Alert: Please verify your attendance, complete pending deliverables, and upload task proofs before deadline.',
    );
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.magentaSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_outlined, color: AppColors.magentaPrimary, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Nudge Team Members',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send a quick reminder to all team members on duty.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 12),
                const Text('Message:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 6),
                TextField(
                  controller: msgController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    'Upload Proofs Before 4PM',
                    'Morning Briefing Starting',
                    'Follow Up Hot Leads',
                  ].map((preset) {
                    return InkWell(
                      onTap: () => setDialogState(() => msgController.text = preset),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.magentaSubtle,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.magentaBorder),
                        ),
                        child: Text(
                          preset,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.magentaPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.magentaPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final text = msgController.text.trim();
                  if (text.isNotEmpty) {
                    eco.postBroadcastNotification(
                      title: 'Shift Nudge from Team Lead',
                      content: text,
                      senderName: eco.currentEmployee.name,
                      senderRole: eco.currentEmployee.role,
                    );
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF10B981),
                      content: Text('Nudge sent to team members on duty!'),
                    ),
                  );
                },
                child: const Text('Send Nudge', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
