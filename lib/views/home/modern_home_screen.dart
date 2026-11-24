import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/services/konar_pdf_service.dart';
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
import '../employee/employee_profile_screen.dart';
import '../konar/konar_book_detail_screen.dart';

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

    // Float for 5 seconds, then ease out kind of dropdown
    _notifDismissTimer = Timer(const Duration(seconds: 5), () {
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

    final bottomOffset = widget.isEmbedded ? 74.0 : 18.0;

    final content = Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      drawer: _buildAppDrawer(context, eco, emp),
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Scrollable Main Content
            Positioned.fill(
              child: RefreshIndicator(
                color: const Color(0xFF881337),
                backgroundColor: Colors.white,
                onRefresh: () => eco.refreshAllData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 10,
                    bottom: widget.isEmbedded ? 140 : 110, // Extra clearance so sticky dock does not obscure bottom items
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar
                      _buildTopBar(context, eco, emp),
                      const SizedBox(height: 16),

                      // User Identity Header (Centered)
                      _buildIdentityHeader(emp),
                      const SizedBox(height: 20),

                      // 4 Pillar Metric Cards (2x2 Grid)
                      _buildPillarsGrid(context, eco),
                      const SizedBox(height: 18),

                      // Official Online Department Konar Book Banner
                      _buildKonarBookBanner(context, eco),
                      const SizedBox(height: 22),

                      // To-Do List Section with Timeline
                      _buildPersonalTodoListSection(context, eco),
                      const SizedBox(height: 26),


                      // Cross-Department Blocker Escalation
                      CrossDeptBlockerSection(
                        department: emp.dept.isNotEmpty ? emp.dept : 'Online Department',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // 2. STICKY CHAT DOCK (PINNED AT BOTTOM-RIGHT, NEVER MOVES ON SCROLL)
            Positioned(
              right: 14,
              bottom: bottomOffset,
              child: _buildStickyChatDock(context, eco),
            ),
          ],
        ),
      ),
    );

    return content;
  }

  // ==========================================
  // TOP APP BAR
  // ==========================================
  Widget _buildTopBar(BuildContext context, EcosystemProvider eco, dynamic emp) {
    // Laid out at real size (it used to be drawn at 480px and scaled down,
    // which made the logo, title and buttons ~25% smaller on phones).
    Widget roundButton({
      required IconData icon,
      required VoidCallback onTap,
      VoidCallback? onLongPress,
      bool dot = false,
    }) {
      return Material(
        color: const Color(0xFFFDF2F8),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 23, color: const Color(0xFF881337)),
                if (dot)
                  Positioned(
                    top: 9,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Brand: diamond crest + divider + Welcome / MN Family
            const SizedBox(
              width: 42,
              height: 42,
              child: CustomPaint(painter: _MnDiamondLogoPainter()),
            ),
            const SizedBox(width: 8),
            Container(
              width: 3,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF881337),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF756A80),
                      height: 1.1,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'MN Family',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF881337),
                        letterSpacing: -0.3,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            roundButton(
              icon: Icons.notifications_none_rounded,
              onTap: () => _onBellTapped(context, eco),
              onLongPress: () => CompanyNotificationSheet.show(context),
              dot: eco.activeCompanyNotifications.isNotEmpty,
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (ctx) => roundButton(
                icon: Icons.menu_rounded,
                onTap: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 8),
            // Profile photo (opens profile)
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF3C6D6), width: 1.5),
                  ),
                  child: EmployeeAvatar(avatar: emp.avatar, initials: emp.initials, size: 44),
                ),
              ),
            ),
          ],
        ),
        // Latest-notification pill slides in under the bell for a few seconds
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _buildFloatingNotificationPill(context, eco),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FLOATING NOTIFICATION PILL
  // Floats out from the bell icon for 5 seconds, then eases out with a dropdown animation
  // ==========================================
  Widget _buildFloatingNotificationPill(BuildContext context, EcosystemProvider eco) {
    final activeNotifs = eco.activeCompanyNotifications;
    if (activeNotifs.isEmpty || !_isFloatingNotifVisible) {
      return const SizedBox.shrink();
    }

    final latestNotif = activeNotifs.first;
    final bool hasLeadingEmoji = latestNotif.title.isNotEmpty &&
        (latestNotif.title.startsWith('🎉') ||
            latestNotif.title.startsWith('💍') ||
            latestNotif.title.startsWith('📋') ||
            latestNotif.title.startsWith('📢'));

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
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
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

                  // Clipboard or notification emoji matching user's image
                  if (!hasLeadingEmoji) ...[
                    const Text(
                      '📋',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Notification Title
                  Flexible(
                    child: Text(
                      latestNotif.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
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
  // IDENTITY HEADER
  // ==========================================
  Widget _buildIdentityHeader(dynamic emp) {
    // Read logged-in account holder's name; fallback to 'Iniya Praveen' for guest/unauthenticated
    final bool hasLoggedInUser = emp != null &&
        emp.name.isNotEmpty &&
        emp.name != 'Guest User';

    final String name = hasLoggedInUser ? emp.name : 'Guest';

    // Designation of the logged-in user: CEO, HR, OTM, or straight-cut role
    final String role;
    if (hasLoggedInUser) {
      if (emp.isCeo) {
        role = 'CEO';
      } else if (emp.isHr) {
        role = 'HR';
      } else if (emp.isOtm) {
        role = 'OTM';
      } else if (emp.roleAcronym.isNotEmpty && emp.roleAcronym != 'Employee') {
        role = emp.roleAcronym;
      } else if (emp.straightCutRole.isNotEmpty) {
        role = emp.straightCutRole;
      } else {
        role = emp.role.isNotEmpty ? emp.role : 'Employee';
      }
    } else {
      role = 'Not signed in';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          name,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF881337),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          role,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
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
    final monthSocialAmount =
        monthSocialCauses.fold(0.0, (sum, c) => sum + c.amountSpent);
    final socialPercentage = monthSocialAmount > 0
        ? '${((monthSocialAmount / 5000.0) * 100).clamp(0, 100).round()}%'
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
          ('Steps today', stepsFormatted),
          ('Calories', '${todayCal.round()} / ${targetCal.round()}'),
        ],
        onTap: () => _open(context, const HealthPillarScreen()),
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
          ('Postponed', '$postponedTasks'),
        ],
        onTap: () => _open(context, const ProfilePillarScreen()),
      ),
      _pillarCard(
        title: 'Social Cause',
        icon: Icons.volunteer_activism_rounded,
        accent: socialPercentColor,
        percent: socialPercentage,
        caption: '${rupees(monthSocialAmount)} of ₹5,000 goal',
        ringValue: rupees(todaySocialAmount),
        ringLabel: 'Today',
        ringColor: socialPercentColor,
        stats: [
          ('Causes', '${monthSocialCauses.length}'),
          ('Approved', '$approvedCauses'),
        ],
        onTap: () => _open(context, const SocialCausePillarScreen()),
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
          const SizedBox(height: 12),
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
  }) {
    const ink = Color(0xFF1E1B2E);
    const muted = Color(0xFF64748B);
    return SizedBox(
      height: 256,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF5D0E0), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0x14881337), blurRadius: 18, offset: Offset(0, 6)),
              ],
              color: Colors.white,
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final ring = c.maxWidth < 165 ? 54.0 : 62.0;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: icon + title + chevron
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(icon, size: 17, color: accent),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              // Wrap long titles onto a second line instead of cutting them off
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.fade,
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: ink,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Month percentage + today ring
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                percent,
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                  height: 1.0,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: ring,
                            height: ring,
                            padding: EdgeInsets.all(ring * 0.16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ringColor.withOpacity(0.06),
                              border: Border.all(color: ringColor, width: 2.5),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ringValue,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: ink,
                                      height: 1.05,
                                    ),
                                  ),
                                  Text(
                                    ringLabel,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: muted,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: muted,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF2F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < stats.length; i++) ...[
                              if (i > 0) const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      stats[i].$1,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(fontSize: 12, color: muted),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        stats[i].$2,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: ink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFFE4E6).withOpacity(0.8),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          // Stylized Maroon Book Graphic
          SizedBox(
            width: 52,
            height: 60,
            child: CustomPaint(
              painter: _KonarBookIconPainter(),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Action Buttons
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_deptLabel(eco.currentEmployee.dept)} Konar Book',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF881337),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Official department handbook',
                  style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // View Full Book Button
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KonarBookDetailScreen(
                              department: eco.currentEmployee.dept.isNotEmpty
                                  ? eco.currentEmployee.dept
                                  : 'Online Department',
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF881337),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              size: 13,
                              color: Color(0xFFFDE68A),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                              'View Full Book',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Download Book Button
                    InkWell(
                      onTap: () => _downloadKonarBook(context, eco, share: false),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF881337),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.file_download_outlined,
                              size: 13,
                              color: Color(0xFFFDE68A),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                              'Download Book',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Share Icon Button
                    InkWell(
                      onTap: () => _downloadKonarBook(context, eco, share: true),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFF881337),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.reply_rounded,
                          size: 16,
                          color: Color(0xFFFDE68A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PERSONAL TO-DO LIST SECTION (WITH TIMELINE)
  // ==========================================
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
                    color: const Color(0xFFFFF1F2),
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
    final titleController = TextEditingController();
    final eco = context.read<EcosystemProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add Personal To-Do',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF881337),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter to-do task details:',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'e.g. MN Jewel Park Reels Post',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF881337),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF881337),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final text = titleController.text.trim();
              if (text.isEmpty) return;
              eco.addEmployeePersonalTodo(
                empId: eco.activeEmpId,
                title: text,
                category: 'Personal',
                dueTime: '',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('To-Do "$text" added.'),
                  backgroundColor: const Color(0xFF881337),
                  duration: const Duration(seconds: 2),
                ),
              );
              Navigator.pop(ctx);
            },
            child: Text(
              'Add To-Do',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF059669)
                        : const Color(0xFFEF4444),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: isCompleted
                      ? const Color(0xFF059669)
                      : const Color(0xFFEF4444),
                ),
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
              decoration: const BoxDecoration(color: Color(0xFFFDF2F8), shape: BoxShape.circle),
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
          // Capsule: [emoji] Type here [attach] - each opens the floating chat
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFF3C6D6), width: 1.2),
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
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Chat bubble: opens the floating chat hub (all conversations)
          Tooltip(
            message: 'Team chat',
            child: InkWell(
              onTap: () => open(FloatingChatStart.hub),
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
                        color: const Color(0xFFBE185D),
                        strokeColor: Colors.white,
                        strokeWidth: 2.8,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 3, right: 3),
                      child: Icon(Icons.groups_rounded, size: 28, color: Colors.white),
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
                color: Color(0xFF881337),
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
                'MN Family App v2.0',
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
class _MnDiamondLogoPainter extends CustomPainter {
  const _MnDiamondLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF881337)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = size.width / 2 - 2;

    // Outer Diamond
    final outerPath = Path()
      ..moveTo(cx, cy - half)
      ..lineTo(cx + half, cy)
      ..lineTo(cx, cy + half)
      ..lineTo(cx - half, cy)
      ..close();
    canvas.drawPath(outerPath, strokePaint);

    // Inner Diamond
    final innerHalf = half * 0.72;
    final innerPath = Path()
      ..moveTo(cx, cy - innerHalf)
      ..lineTo(cx + innerHalf, cy)
      ..lineTo(cx, cy + innerHalf)
      ..lineTo(cx - innerHalf, cy)
      ..close();
    canvas.drawPath(innerPath, strokePaint);

    // Text "MN" in center
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'MN',
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF881337),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
      ..color = const Color(0xFF6B0E2B)
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
