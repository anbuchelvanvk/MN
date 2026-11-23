import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:share_plus/share_plus.dart';
import '../../core/services/konar_pdf_service.dart';
import '../../core/widgets/logout_confirm_dialog.dart';
import '../../models/konar_book_model.dart';
import '../media/creative_media_review_board_screen.dart';
import '../notes/personal_notes_screen.dart';
import '../orders/online_orders_handler_screen.dart';
import '../pillars/attendance_pillar_screen.dart';
import '../../core/widgets/company_notification_sheet.dart';
import '../../core/widgets/cross_dept_blocker_section.dart';
import '../../core/widgets/task_action_dialogs.dart';
import '../../models/task_model.dart';
import '../../providers/ecosystem_provider.dart';
import '../chat/chat_hub_screen.dart';
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

                      // Personal To-Do List Section with Timeline
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final canvasWidth = math.max(availableWidth, 480.0);
        return SizedBox(
          width: availableWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: canvasWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Branding: Diamond Crest Logo + Maroon Divider + Welcome / MN Family
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: CustomPaint(
                          painter: _MnDiamondLogoPainter(),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Vertical Maroon Divider Bar
                      Container(
                        width: 3.0,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFF881337),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Welcome / MN Family Text
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Welcome',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B),
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'MN Family',
                            style: GoogleFonts.outfit(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF881337),
                              letterSpacing: -0.3,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Right Actions: Status Pill + Notification Bell + Hamburger Menu + User Avatar
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Floating Notification Pill: Appears when a company notification arrives, else hidden
                      _buildFloatingNotificationPill(context, eco),

                      // Notification Bell Icon with Red Badge Dot
                      Builder(
                        builder: (ctx) => InkWell(
                          onTap: () => _onBellTapped(context, eco),
                          onLongPress: () => CompanyNotificationSheet.show(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 20,
                                  color: Color(0xFF1E293B),
                                ),
                                if (eco.activeCompanyNotifications.isNotEmpty)
                                  Positioned(
                                    top: 7,
                                    right: 7,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Hamburger Menu Button (Opens Drawer)
                      Builder(
                        builder: (ctx) => InkWell(
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.menu_rounded,
                              size: 20,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Profile Avatar (Navigates to Profile)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(19),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _UserAvatar(emp: emp, size: 38, radius: 19),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
              constraints: const BoxConstraints(maxWidth: 155),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
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
    final healthCalorie =
        '${todayCal.round()} / ${targetCal.round()} Cal';

    // Calorie Growth / Reduction Remark vs Yesterday (or vs Target)
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayCal = eco.getCaloriesConsumedForDate(yesterday);
    final String calorieRemark;
    final Color calorieRemarkColor;
    final IconData calorieRemarkIcon;
    if (yesterdayCal > 0) {
      final diff = todayCal - yesterdayCal;
      final pct = ((diff.abs() / yesterdayCal) * 100).toStringAsFixed(1);
      if (diff > 0) {
        calorieRemark = '+$pct%';
        calorieRemarkColor = const Color(0xFF10B981);
        calorieRemarkIcon = Icons.arrow_upward_rounded;
      } else if (diff < 0) {
        calorieRemark = '-$pct%';
        calorieRemarkColor = const Color(0xFFEF4444);
        calorieRemarkIcon = Icons.arrow_downward_rounded;
      } else {
        calorieRemark = '0.0%';
        calorieRemarkColor = const Color(0xFF64748B);
        calorieRemarkIcon = Icons.horizontal_rule_rounded;
      }
    } else if (todayCal > 0) {
      final diff = todayCal - targetCal;
      final pct = ((diff.abs() / targetCal) * 100).toStringAsFixed(1);
      if (diff >= 0) {
        calorieRemark = '+$pct%';
        calorieRemarkColor = const Color(0xFF10B981);
        calorieRemarkIcon = Icons.arrow_upward_rounded;
      } else {
        calorieRemark = '-$pct%';
        calorieRemarkColor = const Color(0xFFF59E0B);
        calorieRemarkIcon = Icons.arrow_downward_rounded;
      }
    } else {
      calorieRemark = '0.0%';
      calorieRemarkColor = const Color(0xFF64748B);
      calorieRemarkIcon = Icons.horizontal_rule_rounded;
    }

    // Nutrient Segregation: Protein, Fats, Carbs, Fibre from overall monthly intake
    final monthFoodLogs = eco.dailyFoodLogs
        .where((f) =>
            f.timestamp.year == now.year && f.timestamp.month == now.month)
        .toList();
    final monthCalories =
        monthFoodLogs.fold(0.0, (sum, f) => sum + f.calories);

    // Standard nutritional macro proportions: Protein 20% (4 kcal/g), Fats 25% (9 kcal/g), Carbs 50% (4 kcal/g), Fibre 14g/1000kcal
    final double proteinGrams = (monthCalories * 0.20) / 4.0;
    final double fatsGrams = (monthCalories * 0.25) / 9.0;
    final double carbsGrams = (monthCalories * 0.50) / 4.0;
    final double fibreGrams = (monthCalories / 1000.0) * 14.0;

    // Monthly Target (Proportional to days in month with entries, or daily baseline)
    final double targetMultiplier =
        (monthCalories > targetCal * 1.5) ? currentDay.toDouble() : 1.0;
    final double effectiveTargetCal = targetCal * targetMultiplier;
    final double targetProteinGrams = (effectiveTargetCal * 0.20) / 4.0;
    final double targetFatsGrams = (effectiveTargetCal * 0.25) / 9.0;
    final double targetCarbsGrams = (effectiveTargetCal * 0.50) / 4.0;
    final double targetFibreGrams = (effectiveTargetCal / 1000.0) * 14.0;

    String formatMacro(double actual, double target) {
      final act = actual >= 100
          ? actual.round().toString()
          : actual.toStringAsFixed(1);
      final tgt = target >= 100
          ? target.round().toString()
          : target.toStringAsFixed(1);
      return '~${act}g / ${tgt}g';
    }

    final healthNutrientPills = [
      _buildMicroNutrientPill(
        label: 'Protein',
        val: formatMacro(proteinGrams, targetProteinGrams),
        iconColor: const Color(0xFF4338CA),
      ),
      const SizedBox(width: 8),
      _buildMicroNutrientPill(
        label: 'Fats',
        val: formatMacro(fatsGrams, targetFatsGrams),
        iconColor: const Color(0xFFDC2626),
      ),
      const SizedBox(width: 8),
      _buildMicroNutrientPill(
        label: 'Carbs',
        val: formatMacro(carbsGrams, targetCarbsGrams),
        iconColor: const Color(0xFFD97706),
      ),
      const SizedBox(width: 8),
      _buildMicroNutrientPill(
        label: 'Fibre',
        val: formatMacro(fibreGrams, targetFibreGrams),
        iconColor: const Color(0xFF0D9488),
      ),
    ];

    // Day Small Circle: Today's BMI & Category
    final currentBmi = eco.currentBmi;
    final healthBadgeValue = currentBmi > 0 ? currentBmi.toStringAsFixed(1) : '--';
    final healthBadgeSub = currentBmi > 0
        ? (eco.bmiCategory.toLowerCase().contains('overweight')
            ? 'OVERWEIGHT'
            : eco.bmiCategory.toLowerCase().contains('healthy')
                ? 'HEALTHY'
                : eco.bmiCategory.toUpperCase())
        : 'NOT SET';
    final healthBadgeColor = currentBmi <= 0
        ? const Color(0xFF94A3B8)
        : (currentBmi >= 18.5 && currentBmi < 25.0)
            ? const Color(0xFF059669)
            : const Color(0xFFEF4444);

    // Daily Step Count Subcard
    final todaySteps = eco.getStepsForDate(now);
    final stepsFormatted = todaySteps.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    // Total calories after deduction from steps/workouts that burn calories
    final caloriesBurnedFromSteps = todaySteps * 0.045;
    final caloriesBurnedFromWorkouts = eco.getCaloriesBurnedForDate(now);
    final totalBurned = (caloriesBurnedFromSteps + caloriesBurnedFromWorkouts).round();
    final netCalories = math.max(0, (todayCal - totalBurned).round());
    final healthNetCalorieTag = '$netCalories Cal';

    // Walked distance automatically calculated from steps (average 0.762 m / step)
    final walkedKm = (todaySteps * 0.000762).toStringAsFixed(1);
    final healthWalkedDistance = '$walkedKm km';


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
    final todayFamilyLogs = eco.getFamilyActivitiesForDate(now).length;
    String hrs(double h) =>
        h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(1);

    // Work detail
    final pendingTasks = myTasks.where((t) => t.status == 'pending').length;
    final postponedTasks = myTasks.where((t) => t.status == 'postponed').length;

    // Social detail
    final approvedCauses =
        monthSocialCauses.where((c) => c.status == 'approved').length;
    final pendingCauses =
        monthSocialCauses.where((c) => c.status == 'pending').length;
    String rupees(double v) => '\u20B9${v.toStringAsFixed(0)}';

    return Column(
      children: [
        // Row 1: Health & Family Time
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Health Performance',
                percentage: healthPercentage,
                percentColor: healthPercentColor,
                calorie: healthCalorie,
                growth: calorieRemark,
                growthColor: calorieRemarkColor,
                growthIcon: calorieRemarkIcon,
                badgeValue: healthBadgeValue,
                badgeSub: healthBadgeSub,
                badgeTop: 'Current BMI',
                badgeColor: healthBadgeColor,
                steps: stepsFormatted,
                ringColor: healthPercentColor,
                subcardTitle: 'Daily Step Count',
                subcardCalorie: healthNetCalorieTag,
                subcardDistance: healthWalkedDistance,
                customNutrientPills: healthNutrientPills,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Family Time',
                percentage: familyPercentage,
                percentColor: familyPercentColor,
                calorie: '${hrs(monthFamilyHours)}h this month',
                growth: '',
                badgeValue: familyBadgeValue,
                badgeSub: 'HOURS TODAY',
                badgeTop: '',
                badgeColor: const Color(0xFFEF4444),
                steps: '$todayFamilyLogs',
                ringLabel: 'Logs',
                ringColor: const Color(0xFFEF4444),
                subcardTitle: 'This Month',
                subcardCalorie: 'Family ${hrs(monthFamilyHours)}h',
                subcardDistance: 'Friends ${hrs(monthFriendsHours)}h',
                customNutrientPills: const [],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 2: Work Performance (Green 100%) & Social Cause
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Total Work Performance',
                percentage: workPercentage,
                percentColor: workPercentColor,
                calorie: '$completedTasks / $totalTasks tasks done',
                growth: '',
                badgeValue: '$todayWorkRate%',
                badgeSub: 'COMPLETED',
                badgeTop: 'Today Work',
                badgeColor: const Color(0xFF059669),
                steps: '$pendingTasks',
                ringLabel: 'Pending',
                ringColor: const Color(0xFF059669),
                isWorkGreen: true,
                subcardTitle: "Today's Tasks",
                subcardCalorie: '$todayCompleted / ${todayTasks.length} done',
                subcardDistance: '$postponedTasks postponed',
                customNutrientPills: const [],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Social Cause Spent',
                percentage: socialPercentage,
                percentColor: socialPercentColor,
                calorie: '${rupees(monthSocialAmount)} this month',
                growth: '',
                badgeValue: rupees(todaySocialAmount),
                badgeSub: 'SPENT',
                badgeTop: 'Today Spent',
                badgeColor: const Color(0xFFEF4444),
                steps: '${monthSocialCauses.length}',
                ringLabel: 'Causes',
                ringColor: const Color(0xFFEF4444),
                subcardTitle: 'This Month',
                subcardCalorie: '$approvedCauses approved',
                subcardDistance: '$pendingCauses pending',
                customNutrientPills: const [],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String percentage,
    required Color percentColor,
    required String calorie,
    required String growth,
    required String badgeValue,
    required String badgeSub,
    required String badgeTop,
    required Color badgeColor,
    required String steps,
    required Color ringColor,
    bool isWorkGreen = false,
    String subcardTitle = '',
    String subcardCalorie = '',
    String subcardDistance = '',
    String ringLabel = 'Steps',
    List<Widget>? customNutrientPills,
    Color? growthColor,
    IconData? growthIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFE4E6).withOpacity(0.95),
          width: 1.5,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color(0xFFFFF6F7),
          ],
          stops: [0.70, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top section: Title, Percentage, Calories + Circular Ring Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        percentage,
                        style: GoogleFonts.outfit(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: percentColor,
                          letterSpacing: -0.5,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            calorie,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          if (growth.isNotEmpty) const SizedBox(width: 4),
                          if (growth.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                growthIcon ?? Icons.arrow_upward_rounded,
                                size: 13,
                                color: growthColor ?? const Color(0xFF10B981),
                              ),
                              Text(
                                growth,
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: growthColor ?? const Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Right Circular Ring Badge (Enlarged, bold, readable)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: badgeColor, width: 3.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (badgeTop.isNotEmpty)
                        Text(
                          badgeTop,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            height: 1.0,
                          ),
                        ),
                      Text(
                        badgeValue,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: badgeTop.isEmpty ? 22 : 18,
                          fontWeight: FontWeight.w900,
                          color: badgeColor,
                          height: 1.1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          badgeSub,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: badgeTop.isEmpty ? 9.5 : 8.5,
                            fontWeight: FontWeight.w800,
                            color: badgeTop.isEmpty ? const Color(0xFF64748B) : badgeColor,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // Nutrient Mini Pills Row (Scrollable, enlarged, legible)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: customNutrientPills ?? const [],
            ),
          ),

          if (customNutrientPills == null || customNutrientPills.isNotEmpty)
            const SizedBox(height: 11),

          // Bottom Workout & Physical Activity Container (Clean, no truncated filler words)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Concentric Ring with Steps
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(48, 48),
                        painter: _ConcentricRingPainter(ringColor: ringColor),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                steps,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1E293B),
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                ringLabel,
                                style: GoogleFonts.outfit(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Subcard Details (Customizable per pillar, e.g. Daily Step Count)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subcardTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444), // Coral red badge matching Image 4 & 5
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x24EF4444),
                                    blurRadius: 4,
                                    offset: Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: Text(
                                subcardCalorie,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            if (subcardDistance.isNotEmpty) const SizedBox(width: 8),
                            if (subcardDistance.isNotEmpty)
                            Text(
                              subcardDistance,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF334155),
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroNutrientPill({
    required String label,
    required String val,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.compare_arrows_rounded, size: 14, color: iconColor),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF334155),
                  height: 1.1,
                ),
              ),
              Text(
                val,
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
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
      final file = await KonarPdfService.saveKonarPdfLocally(book, eco: eco);
      if (share) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Official ${book.department} KONAR Book - MN Jewel Park',
          subject: '${book.department} Official KONAR Book',
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Saved: ${file.path.split(RegExp(r'[\\/]')).last}'),
            backgroundColor: const Color(0xFF0F766E),
            action: SnackBarAction(
              label: 'Share',
              textColor: const Color(0xFFFDE68A),
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ),
        );
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
                  'Official ${_deptLabel(eco.currentEmployee.dept)} Konar Book',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF881337),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
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
                            Text(
                              'View Full Book',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
                            Text(
                              'Download Book',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
              _UserAvatar(emp: emp, size: 48, radius: 16),
              const SizedBox(width: 12),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal To-Do List',
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
            width: 70,
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
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
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
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // White Capsule Input Bar: [ (face)  Type Here  (clip) ]
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
                    value: eco,
                    child: const ChatHubScreen(),
                  ),
                ),
              );
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 18,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Smile Reaction Icon
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF1F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_reaction_outlined,
                      size: 16,
                      color: Color(0xFF881337),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Hint Text
                  Text(
                    'Type Here',
                    style: GoogleFonts.outfit(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Paperclip Icon
                  const Icon(
                    Icons.attach_file_rounded,
                    size: 20,
                    color: Color(0xFF881337),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Sapphire Blue Speech Bubble Button with Group Silhouettes
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
                    value: eco,
                    child: const ChatHubScreen(),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(30),
            child: SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Speech Bubble with Tail Painter
                  CustomPaint(
                    size: const Size(58, 58),
                    painter: _ChatBubbleTailPainter(
                      color: const Color(0xFF1553A3),
                      strokeColor: Colors.white,
                      strokeWidth: 2.8,
                    ),
                  ),

                  // Group Silhouettes Icon (Pure White)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 3, right: 3),
                    child: Icon(
                      Icons.groups_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ],
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
                  _UserAvatar(emp: emp, size: 50, radius: 16),
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
                  ListTile(
                    leading: const Icon(Icons.home_outlined, color: Color(0xFF881337)),
                    title: Text('Home Dashboard', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.forum_outlined, color: Color(0xFF881337)),
                    title: Text('Team Chat Hub', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider<EcosystemProvider>.value(
                            value: eco,
                            child: const ChatHubScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
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
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: Color(0xFF881337)),
                    title: Text('Employee Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.fact_check_outlined, color: Color(0xFF881337)),
                    title: Text('My Attendance', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AttendancePillarScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF881337)),
                    title: Text('Online Orders', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OnlineOrdersHandlerScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sticky_note_2_outlined, color: Color(0xFF881337)),
                    title: Text('Personal Notes', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PersonalNotesScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.video_collection_outlined, color: Color(0xFF881337)),
                    title: Text('Media Review Board', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreativeMediaReviewBoardScreen()),
                      );
                    },
                  ),
                  const Divider(height: 24),
                  ListTile(
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
                  ),
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
          fontSize: 8.5,
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

/// Concentric rings with footsteps icon painter
class _ConcentricRingPainter extends CustomPainter {
  final Color ringColor;
  _ConcentricRingPainter({required this.ringColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final outerPaint = Paint()
      ..color = ringColor.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final innerPaint = Paint()
      ..color = ringColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Outer Arc (~270 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2 - 3),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      outerPaint,
    );

    // Inner Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width / 2 - 7),
      -math.pi * 0.65,
      math.pi * 1.3,
      false,
      innerPaint,
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


/// Profile picture for the signed-in employee: their uploaded photo when it is
/// a web URL, otherwise their initials. (Replaces a shared mock photo that was
/// shown for every user.)
class _UserAvatar extends StatelessWidget {
  final dynamic emp;
  final double size;
  final double radius;
  const _UserAvatar({required this.emp, this.size = 38, this.radius = 19});

  @override
  Widget build(BuildContext context) {
    final String avatar = (emp?.avatar as String?)?.trim() ?? '';
    final String initials = ((emp?.initials as String?) ?? '').trim();
    final fallback = Container(
      color: const Color(0xFF881337),
      alignment: Alignment.center,
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
          color: Colors.white,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: avatar.startsWith('http')
            ? Image.network(
                avatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }
}
