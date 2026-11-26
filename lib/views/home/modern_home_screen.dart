import '../../core/widgets/add_todo_dialog.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/services/konar_pdf_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../../core/widgets/mn_brand_logo.dart';
import '../../core/widgets/birthday_crown.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../models/konar_book_model.dart';
import '../media/creative_media_review_board_screen.dart';
import '../notes/personal_notes_screen.dart';
import '../orders/online_orders_handler_screen.dart';
import '../pillars/attendance_pillar_screen.dart';
import '../pillars/health_pillar_screen.dart';
import '../pillars/family_pillar_screen.dart';
import '../pillars/profile_pillar_screen.dart';
import '../pillars/social_cause_pillar_screen.dart';
import '../../core/widgets/company_notification_sheet.dart';
import '../../core/widgets/cross_dept_blocker_section.dart';
import '../../core/widgets/task_action_dialogs.dart';
import '../../models/task_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../chat/floating_chat_window.dart';
import '../auth/pillars_popup_dialog.dart';
import '../employee/employee_profile_screen.dart';
import '../konar/konar_book_detail_screen.dart';
import '../konar/konar_books_directory_screen.dart';

/// Modern Home Page Screen matching the official MN Family App redesign specification.
/// Features the sticky chat dock at the bottom-right that stays pinned while scrolling.
class ModernHomeScreen extends StatefulWidget {
  final bool isEmbedded;
  const ModernHomeScreen({super.key, this.isEmbedded = false});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'all'; // 'all', 'pending', 'completed', 'assigned'
  int _todoShowCount = 10;
  bool _chatDockOpen = false;

  late AnimationController _notifAnimController;
  Timer? _notifDismissTimer;
  String? _lastAnimatedNotifId;
  bool _isFloatingNotifVisible = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _notifAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      reverseDuration: const Duration(milliseconds: 500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final eco = context.read<EcosystemProvider>();
      if (eco.activeCompanyNotifications.isNotEmpty) {
        final firstNotif = eco.activeCompanyNotifications.first;
        _lastAnimatedNotifId = firstNotif.id;
        _triggerFloatingNotification();
      }
    });
  }

  void _triggerFloatingNotification() {
    _notifDismissTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isExiting = false;
      _isFloatingNotifVisible = true;
    });
    _notifAnimController.forward(from: 0.0);

    // Show for 6 seconds, then ease out
    _notifDismissTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) {
        _dismissFloatingNotification();
      }
    });
  }

  void _dismissFloatingNotification() {
    if (!mounted || !_isFloatingNotifVisible) return;
    setState(() {
      _isExiting = true;
    });
    _notifAnimController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isFloatingNotifVisible = false;
          _isExiting = false;
        });
      }
    });
  }

  void _onBellTapped(BuildContext context, EcosystemProvider eco) {
    if (eco.activeCompanyNotifications.isEmpty) {
      CompanyNotificationSheet.show(context);
      return;
    }

    if (_isFloatingNotifVisible && !_isExiting) {
      // If already floating, tapping bell opens the notification center sheet
      CompanyNotificationSheet.show(context);
    } else {
      // Re-trigger the floating dropdown from the bell icon for 5 seconds!
      _triggerFloatingNotification();
    }
  }

  @override
  void dispose() {
    _notifDismissTimer?.cancel();
    _notifAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final emp = eco.currentEmployee;

    // Detect new incoming notifications and trigger the 5-second floating dropdown
    final activeNotifs = eco.activeCompanyNotifications;
    if (activeNotifs.isNotEmpty) {
      final currentId = activeNotifs.first.id;
      if (_lastAnimatedNotifId != currentId) {
        _lastAnimatedNotifId = currentId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _triggerFloatingNotification();
          }
        });
      }
    }

    final content = Scaffold(
      backgroundColor: AppColors.canvas,
      drawer: _buildAppDrawer(context, eco, emp),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // 1. Scrollable Main Content
            Positioned.fill(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.white,
                onRefresh: () => eco.refreshAllData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.only(bottom: 110), // clearance for the chat dock
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top of Home: header, the 4 pillar cards and quick actions
                      // fit on one screen; text here does not grow with the
                      // phone's large-font setting.
                      MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHero(context, eco, emp),
                            const SizedBox(height: 12),
                            _sectionHeader('Your month', trailing: 'Tap a card for details'),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: _buildPillarsGrid(context, eco),
                            ),
                            const SizedBox(height: 14),
                            _buildQuickActions(context, eco),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Department Konar Book
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildKonarBookBanner(context, eco),
                      ),
                      const SizedBox(height: 24),

                      // To-Do List Section with Timeline
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildPersonalTodoListSection(context, eco),
                      ),
                      const SizedBox(height: 26),

                      // Cross-Department Blocker Escalation
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CrossDeptBlockerSection(
                          department: emp.dept.isNotEmpty ? emp.dept : 'Online Department',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Sticky chat dock (pinned bottom-right, never moves on scroll)
            Positioned(
              right: 14,
              bottom: 16 + (widget.isEmbedded ? 0 : MediaQuery.of(context).padding.bottom),
              child: _buildStickyChatDock(context, eco),
            ),
          ],
        ),
      ),
    );

    return content;
  }

  // ==========================================
  // HERO HEADER (brand, actions, greeting, today strip)
  // ==========================================
  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _todayLabel() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final n = DateTime.now();
    return '${days[n.weekday - 1]}, ${n.day} ${months[n.month - 1]}';
  }

  /// Display role for the signed-in user (CEO, HR, OTM, role acronym...).
  static String _roleLabel(dynamic emp) {
    final bool hasLoggedInUser = emp != null && emp.name.isNotEmpty && emp.name != 'Guest User';
    if (!hasLoggedInUser) return 'Not signed in';
    if (emp.isCeo) return 'CEO';
    if (emp.isHr) return 'HR';
    if (emp.isOtm) return 'OTM';
    if (emp.roleAcronym.isNotEmpty && emp.roleAcronym != 'Employee') return emp.roleAcronym;
    if (emp.straightCutRole.isNotEmpty) return emp.straightCutRole;
    return emp.role.isNotEmpty ? emp.role : 'Employee';
  }

  Widget _buildHero(BuildContext context, EcosystemProvider eco, dynamic emp) {
    final birthdayToday = eco.isLoggedIn && isBirthdayToday('${emp.dob}', parse: EcosystemProvider.parseDob);
    final topInset = MediaQuery.of(context).padding.top;
    final bool hasLoggedInUser = emp != null && emp.name.isNotEmpty && emp.name != 'Guest User';
    final String name = hasLoggedInUser ? emp.name : 'Guest';
    final String role = _roleLabel(emp);

    final now = DateTime.now();
    final steps = eco.getStepsForDate(now);
    final pendingTasks = eco.currentEmployeeTasks
        .where((t) => t.status == 'pending' || t.status == 'postponed')
        .length;
    final famToday = eco.totalFamilyHoursToday;
    String fmtSteps(int v) => v.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    String fmtHours(double h) =>
        h == h.roundToDouble() ? '${h.toStringAsFixed(0)}h' : '${h.toStringAsFixed(1)}h';

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Decorative gold glow + rings
          Positioned(
            right: -70,
            top: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)]),
              ),
            ),
          ),
          Positioned(
            left: -60,
            bottom: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x14FFFFFF), width: 28),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand + actions
                Row(
                  children: [
                    const MnBrandLogo(size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Welcome',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFFD6E5),
                              height: 1.1,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'MN Family',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    MnGlassIconButton(
                      icon: Icons.notifications_none_rounded,
                      tooltip: 'Notifications',
                      onTap: () => _onBellTapped(context, eco),
                      onLongPress: () => CompanyNotificationSheet.show(context),
                      dot: eco.activeCompanyNotifications.isNotEmpty,
                      size: 36,
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (ctx) => MnGlassIconButton(
                        icon: Icons.menu_rounded,
                        tooltip: 'Menu',
                        onTap: () => Scaffold.of(ctx).openDrawer(),
                        size: 36,
                      ),
                    ),
                  ],
                ),
                // Latest notification slides in under the bell for a few seconds
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _buildFloatingNotificationPill(context, eco),
                  ),
                ),
                const SizedBox(height: 8),

                // Greeting + avatar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_greeting()},',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFFFD6E5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (birthdayToday)
                                Container(
                                  key: const Key('birthday_chip'),
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFFFFE082), Color(0xFFF59E0B)]),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '🎂 Happy birthday',
                                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF7C2D12)),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: AppColors.goldGradientBright,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  role,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.midnight,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFFFFD6E5)),
                                  const SizedBox(width: 5),
                                  Text(
                                    _todayLabel(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFFD6E5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Profile photo (opens profile). On their birthday: a crown.
                    BirthdayCrown(
                      show: birthdayToday,
                      size: 60,
                      child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.goldGradientBright,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.indigoDeep,
                            ),
                            child: EmployeeAvatar(avatar: emp.avatar, initials: emp.initials, size: 52),
                          ),
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Today strip
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x1FFFFFFF)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _heroStat(Icons.directions_walk_rounded, fmtSteps(steps), 'Steps today'),
                        const VerticalDivider(color: Color(0x26FFFFFF), width: 1, thickness: 1),
                        _heroStat(Icons.task_alt_rounded, '$pendingTasks', 'To-dos open'),
                        const VerticalDivider(color: Color(0x26FFFFFF), width: 1, thickness: 1),
                        _heroStat(Icons.favorite_rounded, fmtHours(famToday), 'Family today'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.heroAccent),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFD6E5),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // QUICK ACTIONS
  // ==========================================
  Widget _buildQuickActions(BuildContext context, EcosystemProvider eco) {
    final emp = eco.currentEmployee;
    final items = <(IconData, String, Color, VoidCallback)>[
      (Icons.fingerprint_rounded, 'Attendance', const Color(0xFF0E9F6E),
          () => _open(context, const AttendancePillarScreen())),
      (Icons.menu_book_rounded, 'Konar Book', AppColors.goldDeep,
          () => _open(
                context,
                KonarBookDetailScreen(
                  department: emp.dept.isNotEmpty ? emp.dept : 'Online Department',
                ),
              )),
      (Icons.sticky_note_2_rounded, 'Notes', AppColors.violet,
          () => _open(context, const PersonalNotesScreen())),
      (Icons.shopping_bag_rounded, 'Orders', const Color(0xFFD97706),
          () => _open(context, const OnlineOrdersHandlerScreen())),
      (Icons.video_collection_rounded, 'Media', const Color(0xFF2563EB),
          () => _open(context, const CreativeMediaReviewBoardScreen())),
    ];
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (icon, label, color, onTap) = items[i];
          return SizedBox(
            width: 78,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, size: 20, color: color),
                      ),
                      const SizedBox(height: 7),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.midnight,
              ),
            ),
          ),
          if (trailing != null)
            Flexible(
              child: Text(
              trailing,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // FLOATING NOTIFICATION PILL
  // Floats out from the bell icon for 5 seconds, then eases out with a dropdown animation
  // ==========================================
  /// Drops leading emojis/symbols so the pill stays short.
  static String _shortNoticeTitle(String title) {
    final t = title.trimLeft();
    final i = t.indexOf(RegExp(r'[A-Za-z0-9஀-௿]'));
    return (i > 0 ? t.substring(i) : t).trim();
  }

  Widget _buildFloatingNotificationPill(BuildContext context, EcosystemProvider eco) {
    final activeNotifs = eco.activeCompanyNotifications;
    if (activeNotifs.isEmpty || !_isFloatingNotifVisible) {
      return const SizedBox.shrink();
    }

    final latestNotif = activeNotifs.first;

    return AnimatedBuilder(
      animation: _notifAnimController,
      builder: (context, child) {
        final val = _notifAnimController.value;
        if (val <= 0.0 && !_isFloatingNotifVisible) {
          return const SizedBox.shrink();
        }

        final double opacity;
        final double scale;
        final double slideX;
        final double slideY;

        if (!_isExiting) {
          // Entrance phase: emerges from the bell icon on the right with gentle scale & bounce
          opacity = Curves.easeOutCubic.transform(val);
          scale = 0.75 + (0.25 * Curves.easeOutBack.transform(val));
          slideX = 24.0 * (1.0 - Curves.easeOutBack.transform(val));
          slideY = -4.0 * (1.0 - Curves.easeOutBack.transform(val));
        } else {
          // Exit phase: ease-out dropdown animation! Drops down +16px in Y while smoothly fading away
          opacity = Curves.easeOut.transform(val);
          scale = 0.92 + (0.08 * val);
          slideX = 0.0;
          slideY = 16.0 * (1.0 - Curves.easeOutCubic.transform(val));
        }

        return Transform.translate(
          offset: Offset(slideX, slideY),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.centerRight,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 6.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _notifDismissTimer?.cancel();
              CompanyNotificationSheet.show(context);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 230),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2.5),
                  ),
                  const BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing Red Indicator Dot
                  Container(
                    width: 6.5,
                    height: 6.5,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.45),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),

                  // Notification title: one short line
                  Flexible(
                    child: Text(
                      _shortNoticeTitle(latestNotif.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15),
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 4 PILLAR METRIC CARDS (2x2 GRID)
  // Month in Big Circle, Day in Small Circle from Firebase
  // ==========================================
  Widget _buildPillarsGrid(BuildContext context, EcosystemProvider eco) {
    final now = DateTime.now();
    final currentDay = now.day > 0 ? now.day : 1;

    // 1. HEALTH PILLAR (100% Dynamic from Firebase Health Data):
    // Consistency of health inputs logged this month up to today (food, workouts, steps, weights)
    final loggedDaysSet = <int>{};
    for (final f in eco.dailyFoodLogs) {
      if (f.timestamp.year == now.year &&
          f.timestamp.month == now.month &&
          f.timestamp.day <= currentDay) {
        loggedDaysSet.add(f.timestamp.day);
      }
    }
    for (final w in eco.dailyWorkoutLogs) {
      if (w.timestamp.year == now.year &&
          w.timestamp.month == now.month &&
          w.timestamp.day <= currentDay) {
        loggedDaysSet.add(w.timestamp.day);
      }
    }
    final monthPrefix =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-';
    eco.dailyStepsMap.forEach((key, steps) {
      if (key.startsWith(monthPrefix) && steps > 0) {
        final dayPart = int.tryParse(key.substring(key.length - 2));
        if (dayPart != null && dayPart <= currentDay) {
          loggedDaysSet.add(dayPart);
        }
      }
    });
    for (final wh in eco.weightHistory) {
      if (wh.date.year == now.year &&
          wh.date.month == now.month &&
          wh.date.day <= currentDay) {
        loggedDaysSet.add(wh.date.day);
      }
    }

    final int healthConsistency;
    if (loggedDaysSet.isEmpty) {
      healthConsistency = 0;
    } else {
      healthConsistency =
          ((loggedDaysSet.length / currentDay) * 100).clamp(0, 100).round();
    }
    final healthPercentage = '$healthConsistency%';
    final Color healthPercentColor;
    if (healthConsistency >= 80) {
      healthPercentColor = const Color(0xFF059669); // Green (>=80%)
    } else if (healthConsistency >= 50) {
      healthPercentColor = const Color(0xFFF59E0B); // Yellow / Amber (50-79%)
    } else {
      healthPercentColor = const Color(0xFFEF4444); // Red (<50%)
    }

    // Calories: Actual consumed today vs Target from Firebase
    final todayCal = eco.getCaloriesConsumedForDate(now);
    final targetCal =
        eco.dailyCalorieTarget > 0 ? eco.dailyCalorieTarget : 1550.0;
    // Day Small Circle: Today's BMI & Category
    final currentBmi = eco.currentBmi;
    final healthBadgeValue = currentBmi > 0 ? currentBmi.toStringAsFixed(1) : '--';
    // Daily Step Count Subcard
    final todaySteps = eco.getStepsForDate(now);
    final stepsFormatted = todaySteps.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    // 2. FAMILY TIME PILLAR:
    // Month Big Circle: Total family time of the month
    final monthFamilyHours = eco.familyActivityLogs
        .where((a) =>
            a.category == 'Family' &&
            a.timestamp.month == now.month &&
            a.timestamp.year == now.year)
        .fold(0.0, (sum, a) => sum + a.hoursSpent);
    final familyPercentage = monthFamilyHours > 0
        ? '${((monthFamilyHours / 30.0) * 100).clamp(0, 100).round()}%'
        : '0%';
    final familyPercentColor = const Color(0xFFEF4444);

    // Day Small Circle: Total family time of the day
    final familyHoursToday = eco.totalFamilyHoursToday;
    final familyBadgeValue = familyHoursToday > 0
        ? (familyHoursToday == familyHoursToday.roundToDouble()
            ? familyHoursToday.toStringAsFixed(0)
            : familyHoursToday.toStringAsFixed(1))
        : '0';

    // 3. WORK PERFORMANCE PILLAR:
    // Month Big Circle: Total work performance of the month
    final myTasks = eco.currentEmployeeTasks;
    final completedTasks = myTasks.where((t) => t.status == 'completed').length;
    final totalTasks = myTasks.length;
    final String workPercentage;
    if (totalTasks > 0) {
      workPercentage = '${((completedTasks / totalTasks) * 100).round()}%';
    } else {
      workPercentage = '0%';
    }
    final workPercentColor = const Color(0xFF059669);

    // Day Small Circle: Today's work performance
    final todayTasks = myTasks.where((t) {
      final due = t.due.toLowerCase();
      return due.contains('today') || due.contains('am') || due.contains('pm');
    }).toList();
    final todayCompleted = todayTasks.where((t) => t.status == 'completed').length;
    final todayWorkRate = todayTasks.isNotEmpty
        ? ((todayCompleted / todayTasks.length) * 100).round()
        : 0;

    // 4. SOCIAL CAUSE SPENT PILLAR:
    // Month Big Circle: Total social cause spent in the month
    final monthSocialCauses = eco.currentEmployeeSocialCauses
        .where((c) => c.date.month == now.month && c.date.year == now.year)
        .toList();
    // Progress toward the person's own monthly amount goal (approved deeds).
    final monthApprovedAmount =
        eco.myApprovedSocialCauses(now).fold(0.0, (sum, c) => sum + c.amountSpent);
    final socialMonthGoal = eco.socialAmountGoalForMonth(now);
    final socialPercentage = socialMonthGoal > 0
        ? '${((monthApprovedAmount / socialMonthGoal) * 100).clamp(0, 100).round()}%'
        : '0%';
    final socialPercentColor = const Color(0xFFEF4444);

    // Day Small Circle: Today's social cause spent
    final todaySocialCauses = eco.currentEmployeeSocialCauses
        .where((c) =>
            c.date.year == now.year &&
            c.date.month == now.month &&
            c.date.day == now.day)
        .toList();
    final todaySocialAmount =
        todaySocialCauses.fold(0.0, (sum, c) => sum + c.amountSpent);

    // Family detail
    final monthFriendsHours = eco.familyActivityLogs
        .where((a) =>
            a.category != 'Family' &&
            a.timestamp.month == now.month &&
            a.timestamp.year == now.year)
        .fold(0.0, (sum, a) => sum + a.hoursSpent);
    String hrs(double h) =>
        h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1);

    // Work detail
    final pendingTasks = myTasks.where((t) => t.status == 'pending').length;
    final postponedTasks = myTasks.where((t) => t.status == 'postponed').length;

    // Social detail
    final approvedCauses =
        monthSocialCauses.where((c) => c.status == 'approved').length;
    String rupees(double v) => '\u20B9${v.toStringAsFixed(0)}';

    final bmiColor = currentBmi <= 0
        ? const Color(0xFF94A3B8)
        : (currentBmi >= 18.5 && currentBmi < 25.0)
            ? const Color(0xFF059669)
            : const Color(0xFFE11D48);

    final cards = <Widget>[
      _pillarCard(
        title: 'Health',
        icon: Icons.favorite_rounded,
        accent: healthPercentColor,
        percent: healthPercentage,
        caption: 'logging consistency',
        ringValue: healthBadgeValue,
        ringLabel: 'BMI',
        ringColor: bmiColor,
        stats: [
          ('Steps', stepsFormatted),
          ('Kcal', '${todayCal.round()}/${targetCal.round()}'),
        ],
        onTap: () => _open(context, const HealthPillarScreen()),
        tint: const Color(0xFF0E9F6E),
      ),
      _pillarCard(
        title: 'Family Time',
        icon: Icons.family_restroom_rounded,
        accent: familyPercentColor,
        percent: familyPercentage,
        caption: '${hrs(monthFamilyHours)}h of 30h this month',
        ringValue: '${familyBadgeValue}h',
        ringLabel: 'Today',
        ringColor: familyPercentColor,
        stats: [
          ('Family', '${hrs(monthFamilyHours)}h'),
          ('Friends', '${hrs(monthFriendsHours)}h'),
        ],
        onTap: () => _open(context, const FamilyPillarScreen()),
        tint: AppColors.violet,
      ),
      _pillarCard(
        title: 'Work',
        icon: Icons.work_rounded,
        accent: workPercentColor,
        percent: workPercentage,
        caption: '$completedTasks of $totalTasks tasks done',
        ringValue: '$todayWorkRate%',
        ringLabel: 'Today',
        ringColor: workPercentColor,
        stats: [
          ('Pending', '$pendingTasks'),
          ('Later', '$postponedTasks'),
        ],
        onTap: () => _open(context, const ProfilePillarScreen()),
        tint: AppColors.primary,
      ),
      _pillarCard(
        title: 'Social Cause',
        icon: Icons.volunteer_activism_rounded,
        accent: socialPercentColor,
        percent: socialPercentage,
        caption: '${rupees(monthApprovedAmount)} of ${rupees(socialMonthGoal)} goal',
        ringValue: rupees(todaySocialAmount),
        ringLabel: 'Today',
        ringColor: socialPercentColor,
        stats: [
          ('Causes', '${monthSocialCauses.length}'),
          ('Approved', '$approvedCauses'),
        ],
        onTap: () => _open(context, const SocialCausePillarScreen()),
        tint: const Color(0xFFB7791F),
      ),
    ];

    // Same height for all four cards; text scaling is capped so the fixed
    // card height can never overflow on phones with large font settings.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  /// One pillar summary card. All four share this layout and a fixed height.
  Widget _pillarCard({
    required String title,
    required IconData icon,
    required Color accent,
    required String percent,
    required String caption,
    required String ringValue,
    required String ringLabel,
    required Color ringColor,
    required List<(String, String)> stats,
    required VoidCallback onTap,
    Color tint = AppColors.primary,
  }) {
    const ink = AppColors.midnight;
    const muted = AppColors.textMuted;
    final pct = (int.tryParse(percent.replaceAll('%', '')) ?? 0).clamp(0, 100) / 100.0;
    return SizedBox(
      height: 158,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
              border: Border.all(color: AppColors.line),
              boxShadow: AppColors.softShadow,
            ),
            child: Stack(
              children: [
                // Soft tinted corner, clipped to the card's rounded edge
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(23),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -34,
                          top: -34,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tint.withOpacity(0.06),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, c) {
                    final ring = c.maxWidth < 165 ? 46.0 : 52.0;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [tint, Color.lerp(tint, Colors.black, 0.25)!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                  boxShadow: [
                                    BoxShadow(color: tint.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                                  ],
                                ),
                                child: Icon(icon, size: 15, color: Colors.white),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: ink,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Color(0xFFCBB8C4)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Month progress ring with percentage
                              SizedBox(
                                width: ring,
                                height: ring,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox.expand(
                                      child: CircularProgressIndicator(
                                        value: pct,
                                        strokeWidth: 5,
                                        strokeCap: StrokeCap.round,
                                        backgroundColor: tint.withOpacity(0.10),
                                        valueColor: AlwaysStoppedAnimation(accent),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          percent,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: ink,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Today value
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ringLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: muted,
                                      ),
                                    ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        ringValue,
                                        style: GoogleFonts.outfit(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: ringColor,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: muted,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: tint.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                for (int i = 0; i < stats.length; i++) ...[
                                  if (i > 0)
                                    Container(width: 1, height: 12, margin: const EdgeInsets.symmetric(horizontal: 6), color: tint.withOpacity(0.2)),
                                  Expanded(
                                    // Width follows text length, so a long stat
                                    // (Calories 0/1850) is not shrunk to fit half.
                                    flex: (stats[i].$1.length + stats[i].$2.length + 1).clamp(4, 40),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: i == 0 ? Alignment.centerLeft : Alignment.centerRight,
                                      child: Text.rich(
                                        TextSpan(children: [
                                          TextSpan(
                                            text: '${stats[i].$1} ',
                                            style: GoogleFonts.outfit(fontSize: 10.5, color: muted, fontWeight: FontWeight.w500),
                                          ),
                                          TextSpan(
                                            text: stats[i].$2,
                                            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800, color: ink),
                                          ),
                                        ]),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // KONAR BOOK BANNER
  // ==========================================
  static String _deptLabel(String dept) {
    final d = dept.trim();
    return (d.isEmpty || d.toLowerCase() == 'none') ? 'Department' : d;
  }

  /// The Konar Book for the signed-in employee's own department.
  KonarBookModel _myKonarBook(EcosystemProvider eco) {
    final dept = eco.currentEmployee.dept.toLowerCase();
    final raw = eco.konarBooks.firstWhere(
      (b) => b.department.toLowerCase() == dept,
      orElse: () => eco.onlineDeptKonarBook,
    );
    final isOnline = raw.id == 'online_department' ||
        raw.id == 'online_dept' ||
        raw.department.toLowerCase().contains('online');
    if (isOnline &&
        (raw.sections.length != 5 ||
            !raw.sections.first.title.contains('01 PURPOSE'))) {
      return KonarBookModel.defaultOnlineDepartment();
    }
    return raw;
  }

  Future<void> _downloadKonarBook(
    BuildContext context,
    EcosystemProvider eco, {
    required bool share,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final book = _myKonarBook(eco);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Preparing ${book.department} Konar Book PDF...'),
        backgroundColor: const Color(0xFF881337),
        duration: const Duration(seconds: 2),
      ),
    );
    try {
      if (share) {
        await KonarPdfService.shareKonarPdf(book, eco: eco);
      } else {
        final saved = await KonarPdfService.downloadKonarPdf(book, eco: eco);
        if (saved != null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Konar Book saved.'),
              backgroundColor: Color(0xFF0F766E),
            ),
          );
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not prepare the Konar Book PDF: $e')),
      );
    }
  }

  Widget _buildKonarBookBanner(BuildContext context, EcosystemProvider eco) {
    // The CEO looks after every department's book.
    final allBooks = eco.isCeo || eco.activeRole.toLowerCase() == 'ceo';
    final bookCount = eco.konarBooks.length;
    final missing = !allBooks && eco.konarBookForDept(eco.currentEmployee.dept) == null;
    void openBook() => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => allBooks
                ? const KonarBooksDirectoryScreen()
                : KonarBookDetailScreen(
                    department: eco.currentEmployee.dept.isNotEmpty
                        ? eco.currentEmployee.dept
                        : 'Online Department',
                  ),
          ),
        );

    Widget roundAction(IconData icon, String tip, VoidCallback onTap) => Tooltip(
          message: tip,
          child: Material(
            color: const Color(0x1FFFFFFF),
            shape: const CircleBorder(side: BorderSide(color: Color(0x33FFD6E5))),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, size: 20, color: AppColors.heroAccent),
              ),
            ),
          ),
        );

    return Material(
      color: AppColors.indigoDeep,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: openBook,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: AppColors.heroGradient,
            boxShadow: const [
              BoxShadow(color: Color(0x332A0F22), blurRadius: 20, offset: Offset(0, 8)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 58,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CustomPaint(painter: _KonarBookIconPainter()),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      allBooks ? 'All Konar Books' : '${_deptLabel(eco.currentEmployee.dept)} Konar Book',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      allBooks
                          ? '$bookCount department${bookCount == 1 ? '' : 's'} • view, add and manage'
                          : (missing ? 'Not uploaded yet • tap for details' : 'Your department handbook • tap to open'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFFFD6E5)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (allBooks || missing)
                roundAction(Icons.arrow_forward_rounded, allBooks ? 'Open all books' : 'Details', openBook)
              else ...[
                roundAction(Icons.file_download_outlined, 'Download PDF',
                    () => _downloadKonarBook(context, eco, share: false)),
                const SizedBox(width: 6),
                roundAction(Icons.share_outlined, 'Share PDF',
                    () => _downloadKonarBook(context, eco, share: true)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalTodoListSection(
    BuildContext context,
    EcosystemProvider eco,
  ) {
    final emp = eco.currentEmployee;
    final allTasks = eco.currentEmployeeTasks;
    final pending = allTasks.where((t) => t.status == 'pending' || t.status == 'postponed').toList();
    final completed = allTasks.where((t) => t.status == 'completed').toList();
    final assigned = allTasks
        .where((t) =>
            !t.isDefaultSop &&
            t.assignedByRole != 'employee' &&
            !t.assignedByName.startsWith('Self'))
        .toList();
    final List<TaskItem> visible;
    switch (_selectedFilter) {
      case 'pending':
        visible = pending;
        break;
      case 'completed':
        visible = completed;
        break;
      case 'assigned':
        visible = assigned;
        break;
      default:
        visible = allTasks;
    }
    final shown = visible.take(_todoShowCount).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header: Avatar + Title + Counts + Add Button
          Row(
            children: [
              // Avatar
              EmployeeAvatar(avatar: emp.avatar, initials: emp.initials, size: 48, radius: 16),
              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To-Do List',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF881337),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pending.length} pending,  ${completed.length} completed',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // "+ Add To Do" Pill Button
              InkWell(
                onTap: () => _showAddPersonalTodoDialog(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFE4E6),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 14,
                        color: Color(0xFF881337),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add To Do',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF881337),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Filter Pills Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterPill(
                  label: 'Show All (${allTasks.length})',
                  filterKey: 'all',
                  isSelected: _selectedFilter == 'all',
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  label: 'Pending (${pending.length})',
                  filterKey: 'pending',
                  isSelected: _selectedFilter == 'pending',
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  label: 'Completed (${completed.length})',
                  filterKey: 'completed',
                  isSelected: _selectedFilter == 'completed',
                ),
                const SizedBox(width: 8),
                _buildFilterPill(
                  label: 'Assigned (${assigned.length})',
                  filterKey: 'assigned',
                  isSelected: _selectedFilter == 'assigned',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Timeline To-Do items with vertical dashed line
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  _selectedFilter == 'all'
                      ? 'No tasks yet. Tap "Add To Do" to create one.'
                      : 'Nothing here right now.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          for (int i = 0; i < shown.length; i++)
            _buildTimelineItem(
              time: shown[i].due,
              date: shown[i].category,
              title: shown[i].title,
              isCompleted: shown[i].status == 'completed',
              isLast: i == shown.length - 1,
              onTap: () => TaskActionDialogs.handleTaskTap(context, eco, shown[i]),
            ),
          if (visible.length > shown.length)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _todoShowCount += 10),
                child: Text(
                  'Show ${visible.length - shown.length} more',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF881337),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddPersonalTodoDialog(BuildContext context) {
    showAddPersonalTodoDialog(context, context.read<EcosystemProvider>());
  }

  Widget _buildFilterPill({
    required String label,
    required String filterKey,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() {
        _selectedFilter = filterKey;
        _todoShowCount = 10;
      }),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF881337) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String date,
    required String title,
    required bool isCompleted,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  date,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF756A80),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Dashed Node + Line
          Column(
            children: [
              // Circular Node with Checkmark
              Container(
                width: 26,
                height: 26,
                // Done = filled green tick; to do = empty ring (no tick)
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? const Color(0xFF059669) : Colors.white,
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF059669)
                        : const Color(0xFFE7A4BA),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),

              // Dashed connecting line
              if (!isLast)
                Expanded(
                  child: CustomPaint(
                    size: const Size(2, 40),
                    painter: _DashedLinePainter(color: const Color(0xFF94A3B8)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Task Title
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 24),
              child: InkWell(
                onTap: onTap,
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BOTTOM NUTRIENT METRIC SECTION
  // ==========================================
  Widget _buildStickyChatDock(BuildContext context, EcosystemProvider eco) {
    void open(FloatingChatStart start) => FloatingChatWindow.show(context, start: start);

    Widget capsuleButton(IconData icon, String tip, VoidCallback onTap) => Tooltip(
          message: tip,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(color: Color(0xFFFFF1F4), shape: BoxShape.circle),
              child: Icon(icon, size: 19, color: const Color(0xFF881337)),
            ),
          ),
        );

    final unread = eco.unreadTotalChatCount;

    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Capsule: [emoji] Type here [attach] [all chats]. Hidden until the
          // chat bubble is tapped; tapping the bubble again hides it.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1).animate(anim),
                alignment: Alignment.centerRight,
                child: child,
              ),
            ),
            child: !_chatDockOpen
                ? const SizedBox.shrink(key: ValueKey('chat_capsule_hidden'))
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
            key: const ValueKey('chat_capsule'),
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0x22881337), blurRadius: 18, offset: Offset(0, 5)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                capsuleButton(Icons.add_reaction_outlined, 'Emoji', () => open(FloatingChatStart.allHandsEmoji)),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => open(FloatingChatStart.allHands),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Type here',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF756A80),
                      ),
                    ),
                  ),
                ),
                capsuleButton(Icons.attach_file_rounded, 'Attach', () => open(FloatingChatStart.allHandsAttach)),
                const SizedBox(width: 4),
                capsuleButton(Icons.forum_rounded, 'All chats', () => open(FloatingChatStart.hub)),
              ],
            ),
          ),
                  ),
          ),
          // Chat bubble: shows / hides the chat capsule
          Tooltip(
            message: _chatDockOpen ? 'Hide chat' : 'Team chat',
            child: InkWell(
              key: const Key('home_chat_bubble'),
              onTap: () => setState(() => _chatDockOpen = !_chatDockOpen),
              borderRadius: BorderRadius.circular(30),
              child: SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(58, 58),
                      painter: _ChatBubbleTailPainter(
                        color: const Color(0xFF2563EB),
                        strokeColor: Colors.white,
                        strokeWidth: 2.8,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3, right: 3),
                      child: Icon(_chatDockOpen ? Icons.close_rounded : Icons.groups_rounded,
                          size: 28, color: Colors.white),
                    ),
                    if (unread > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // NAVIGATION DRAWER (ACCESSIBLE VIA HAMBURGER)
  // ==========================================
  Widget _buildAppDrawer(BuildContext context, EcosystemProvider eco, dynamic emp) {
    final bool hasLoggedInUser = emp != null &&
        emp.name.isNotEmpty &&
        emp.name != 'Guest User';
    final String drawerName = hasLoggedInUser ? emp.name : 'Guest';
    final String drawerRole;
    if (hasLoggedInUser) {
      if (emp.isCeo) {
        drawerRole = 'CEO';
      } else if (emp.isHr) {
        drawerRole = 'HR';
      } else if (emp.isOtm) {
        drawerRole = 'OTM';
      } else if (emp.roleAcronym.isNotEmpty && emp.roleAcronym != 'Employee') {
        drawerRole = emp.roleAcronym;
      } else if (emp.straightCutRole.isNotEmpty) {
        drawerRole = emp.straightCutRole;
      } else {
        drawerRole = emp.role.isNotEmpty ? emp.role : 'Employee';
      }
    } else {
      drawerRole = 'Not signed in';
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
              child: Row(
                children: [
                  EmployeeAvatar(avatar: emp.avatar, initials: emp.initials, size: 50, radius: 16),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          drawerName,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          drawerRole,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: const Color(0xFFFDE68A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  Material(type: MaterialType.transparency, child: ListTile(
                    leading: const Icon(Icons.home_outlined, color: Color(0xFF881337)),
                    title: Text('Home Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.pop(context),
                  )),
                  Material(type: MaterialType.transparency, child: ListTile(
                    key: const ValueKey('drawer_pillars'),
                    leading: const Icon(Icons.auto_awesome_mosaic_rounded, color: Color(0xFF881337)),
                    title: Text('My Pillars', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    subtitle: Text('Health, Family, Work, Attendance, Social', style: GoogleFonts.outfit(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(context);
                      PillarsPopupDialog.show(context);
                    },
                  )),
                  Material(type: MaterialType.transparency, child: ListTile(
                    leading: const Icon(Icons.forum_outlined, color: Color(0xFF881337)),
                    title: Text('Team Chat Hub', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      FloatingChatWindow.show(context);
                    },
                  )),
                  Material(type: MaterialType.transparency, child: ListTile(
                    leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF881337)),
                    title: Text('${_deptLabel(emp.dept)} Konar Book', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KonarBookDetailScreen(
                            department: emp.dept.isNotEmpty ? emp.dept : 'Online Department',
                          ),
                        ),
                      );
                    },
                  )),
                  Material(type: MaterialType.transparency, child: ListTile(
                    leading: const Icon(Icons.person_outline, color: Color(0xFF881337)),
                    title: Text('Employee Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                      );
                    },
                  )),
                  Material(type: MaterialType.transparency, child: ListTile(
                    leading: const Icon(Icons.fact_check_outlined, color: Color(0xFF881337)),
                    title: Text('My Attendance', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendancePillarScreen()),
                      );
                    },
                  )),
                  Material(type: MaterialType.transparency, child: ListTile(
                    leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF881337)),
                    title: Text('Online Orders', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OnlineOrdersHandlerScreen()),
                      );
                    },
                  )),
                  Material(type: MaterialType.transparency, child: ListTile(
                    leading: const Icon(Icons.sticky_note_2_outlined, color: Color(0xFF881337)),
                    title: Text('Personal Notes', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PersonalNotesScreen()),
                      );
                    },
                  )),
                  Material(type: MaterialType.transparency, child: ListTile(
                    leading: const Icon(Icons.video_collection_outlined, color: Color(0xFF881337)),
                    title: Text('Media Review Board', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreativeMediaReviewBoardScreen()),
                      );
                    },
                  )),
                  const Divider(height: 24),
                  Material(type: MaterialType.transparency, child: ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                    title: Text(
                      'Logout',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      LogoutConfirmDialog.show(context);
                    },
                  )),
                ],
              ),
            ),

            // App Version Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'MN Family • v1.1',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CUSTOM PAINTERS FOR PIXEL-PERFECT GRAPHICS
// ==========================================

/// Diamond crest logo painter for MN Family
/// Dashed vertical line painter for timeline
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    double y = 4;
    const dashHeight = 4.0;
    const dashGap = 3.0;

    while (y < size.height - 4) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + dashHeight),
        paint,
      );
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Stylized Maroon Konar Book Graphic painter
class _KonarBookIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bookPaint = Paint()
      ..color = const Color(0xFF881337)
      ..style = PaintingStyle.fill;

    final goldBorderPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(4, 2, size.width - 12, size.height - 12),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
      bottomLeft: const Radius.circular(6),
    );

    // Book Cover
    canvas.drawRRect(rrect, bookPaint);
    canvas.drawRRect(rrect, goldBorderPaint);

    // Spine Line
    final spinePaint = Paint()
      ..color = const Color(0xFF6B0E2D)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(4, 2, 8, size.height - 12),
        topLeft: const Radius.circular(6),
        bottomLeft: const Radius.circular(6),
      ),
      spinePaint,
    );

    // Gold Center Square
    final squarePaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.42, size.height * 0.22, 16, 16),
        const Radius.circular(3),
      ),
      squarePaint,
    );

    // Bookmark Ribbon at Bottom
    final ribbonPath = Path()
      ..moveTo(size.width * 0.35, size.height - 10)
      ..lineTo(size.width * 0.35, size.height - 2)
      ..lineTo(size.width * 0.42, size.height - 5)
      ..lineTo(size.width * 0.49, size.height - 2)
      ..lineTo(size.width * 0.49, size.height - 10)
      ..close();

    final ribbonPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.fill;
    canvas.drawPath(ribbonPath, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular speech bubble with bottom-right tail painter
class _ChatBubbleTailPainter extends CustomPainter {
  final Color color;
  final Color strokeColor;
  final double strokeWidth;

  _ChatBubbleTailPainter({
    required this.color,
    this.strokeColor = Colors.white,
    this.strokeWidth = 2.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2 - 3.5;

    final path = Path();
    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    // Tail pointing down-right
    final tail = Path()
      ..moveTo(size.width * 0.70, size.height * 0.82)
      ..lineTo(size.width * 0.96, size.height * 0.98)
      ..lineTo(size.width * 0.88, size.height * 0.68)
      ..close();

    final combined = Path.combine(PathOperation.union, path, tail);

    // Drop Shadow
    final shadowPaint = Paint()
      ..color = const Color(0x28000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(combined.shift(const Offset(0, 3)), shadowPaint);

    // White Outer Stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(combined, strokePaint);

    // Blue Fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(combined, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
