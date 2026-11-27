import '../../core/widgets/pillar_hero_card.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../models/health_models.dart';
import '../../providers/ecosystem_provider.dart';
import '../../services/food_api_service.dart';
import '../../core/widgets/mn_app_bar.dart';
import 'auto_steps_panel.dart';
import '../../core/widgets/pillar_kit.dart';

class HealthPillarScreen extends StatefulWidget {
  const HealthPillarScreen({super.key});

  @override
  State<HealthPillarScreen> createState() => _HealthPillarScreenState();
}

class _HealthPillarScreenState extends State<HealthPillarScreen> {
  int _selectedGridIndex = 0; // 0: Calories, 1: Workout, 2: Weight / Height, 3: BMI

  // Food Search state & Public Open Food API integration
  final TextEditingController _foodSearchController = TextEditingController();
  String _selectedCategory = 'All';
  Timer? _searchDebounceTimer;
  List<FoodItem> _apiSearchResults = [];
  bool _isSearchingApi = false;

  // First-time onboarding controllers
  final TextEditingController _initialHeightController = TextEditingController();
  final TextEditingController _initialWeightController = TextEditingController();

  // Weight/Height update controllers
  final TextEditingController _updateHeightController = TextEditingController();
  final TextEditingController _updateWeightController = TextEditingController();

  // Date selection & center date navigation state
  DateTime _selectedDate = DateTime.now();
  bool _hasCheckedTargetCaloriePopup = false;

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return _isSameDay(d, now);
  }

  bool _isPastDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    return target.isBefore(today) || target.isAfter(today);
  }

  String _formatDayLabel(DateTime d) {
    if (_isToday(d)) return 'Today (${d.day} ${_months[d.month - 1].substring(0, 3)})';
    return '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1].substring(0, 3)}';
  }

  String _formatDayShort(DateTime d) {
    if (_isToday(d)) return 'Today';
    return '${d.day} ${_months[d.month - 1].substring(0, 3)}';
  }

  void _checkAndShowTargetCaloriePopup(BuildContext context) {
    if (_hasCheckedTargetCaloriePopup) return;
    _hasCheckedTargetCaloriePopup = true;
    final eco = context.read<EcosystemProvider>();
    if (eco.healthOnboarded && !eco.hasSetDailyCalorieTarget) {
      _showDailyCalorieTargetModal(context, eco, isFirstTime: true);
    }
  }

  @override
  void initState() {
    super.initState();
    final eco = context.read<EcosystemProvider>();
    _updateHeightController.text = eco.userHeightCm > 0 ? eco.userHeightCm.toStringAsFixed(0) : '';
    _updateWeightController.text = eco.userWeightKg > 0 ? eco.userWeightKg.toStringAsFixed(1) : '';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndShowTargetCaloriePopup(context);
        context.read<EcosystemProvider>().syncAutoSteps();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _foodSearchController.dispose();
    _initialHeightController.dispose();
    _initialWeightController.dispose();
    _updateHeightController.dispose();
    _updateWeightController.dispose();
    super.dispose();
  }

  void _onFoodSearchChanged(String query) {
    setState(() {});
    _searchDebounceTimer?.cancel();
    final q = query.trim();

    if (q.length < 2) {
      setState(() {
        _apiSearchResults = [];
        _isSearchingApi = false;
      });
      return;
    }

    // Debounce network request to public open-source API by 350ms
    _searchDebounceTimer = Timer(const Duration(milliseconds: 350), () async {
      setState(() {
        _isSearchingApi = true;
      });

      final onlineFoods = await FoodApiService.searchOnline(q);

      if (mounted && _foodSearchController.text.trim() == q) {
        setState(() {
          _apiSearchResults = onlineFoods;
          _isSearchingApi = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: MnAppBar(
        title: 'Health',
        subtitle: 'Food, activity, steps and BMI',
        actions: [
          MnHeaderPill(
            icon: Icons.tune_rounded,
            label: 'Recalibrate',
            onTap: () => _showRecalibrateConfirmDialog(context, eco),
          ),
        ],
      ),
      body: SafeArea(
        child: (eco.healthOnboarded || eco.isCeo || eco.activeRole.toLowerCase() == 'ceo' || eco.activeRole.toLowerCase() == 'hr')
            ? _buildMainDashboard(context, eco)
            : _buildFirstTimeOnboarding(context, eco),
      ),
    );
  }

  // =========================================================================
  // 1. FIRST-TIME ONBOARDING: HEIGHT, WEIGHT & BMI CALIBRATION
  // =========================================================================

  Widget _buildFirstTimeOnboarding(BuildContext context, EcosystemProvider eco) {
    final heightVal = double.tryParse(_initialHeightController.text) ?? 0.0;
    final weightVal = double.tryParse(_initialWeightController.text) ?? 0.0;
    final hasBoth = heightVal > 0 && weightVal > 0;
    final hM = heightVal / 100.0;
    final liveBmi = (hasBoth && hM > 0) ? weightVal / (hM * hM) : 0.0;
    final liveCategory = !hasBoth
        ? 'Enter metrics'
        : (liveBmi < 18.5
            ? 'Underweight'
            : (liveBmi < 25.0 ? 'Healthy (Ideal)' : (liveBmi < 30.0 ? 'Overweight' : 'Obese')));
    final minIdeal = 18.5 * hM * hM;
    final maxIdeal = 24.9 * hM * hM;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.burgundySurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.sandGold, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_outlined,
                        color: AppColors.sandGold,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'FIRST-TIME HEALTH CALIBRATION',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome ${eco.currentEmployee.name}! Please enter your baseline biometric parameters to calibrate your daily health targets and BMI profile.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.sandPrimary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Physical Baseline Metrics',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Height (cm)',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.sandLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _initialHeightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandLight,
                                ),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.burgundySurface,
                                  prefixIcon: const Icon(Icons.height, size: 18, color: AppColors.sandGold),
                                  suffixText: 'cm',
                                  suffixStyle: const TextStyle(color: AppColors.sandPrimary, fontSize: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weight (kg)',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.sandLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _initialWeightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandLight,
                                ),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: AppColors.burgundySurface,
                                  prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 18, color: AppColors.sandGold),
                                  suffixText: 'kg',
                                  suffixStyle: const TextStyle(color: AppColors.sandPrimary, fontSize: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.burgundySurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CALCULATED BMI',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hasBoth ? liveBmi.toStringAsFixed(1) : '--',
                                    style: GoogleFonts.outfit(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.sandGold,
                                    ),
                                  ),
                                ],
                              ),
                              Flexible(
                                child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: hasBoth
                                      ? ((liveBmi >= 18.5 && liveBmi < 25.0)
                                          ? AppColors.ragGreen.withOpacity(0.2)
                                          : AppColors.ragYellow.withOpacity(0.2))
                                      : AppColors.burgundySurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: hasBoth
                                        ? ((liveBmi >= 18.5 && liveBmi < 25.0)
                                            ? AppColors.ragGreen
                                            : AppColors.ragYellow)
                                        : AppColors.sandBorder,
                                  ),
                                ),
                                child: Text(
                                  liveCategory,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: hasBoth
                                        ? ((liveBmi >= 18.5 && liveBmi < 25.0)
                                            ? AppColors.ragGreen
                                            : AppColors.ragYellow)
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(color: AppColors.sandBorder, height: 1),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.straighten, size: 14, color: AppColors.sandPrimary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  hasBoth
                                      ? 'Ideal Weight Range for ${heightVal.toStringAsFixed(0)} cm: ${minIdeal.toStringAsFixed(1)} kg – ${maxIdeal.toStringAsFixed(1)} kg'
                                      : 'Enter height and weight above to calculate ideal range',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.sandLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    LiquidGlassButton(
                      label: 'Save Baseline & Enter Dashboard',
                      icon: Icons.check_circle_outline,
                      height: 48,
                      onPressed: () {
                        final metricError = EcosystemProvider.validateBodyMetrics(heightVal, weightVal);
                        if (metricError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.burgundyPrimary,
                              content: Text(metricError),
                            ),
                          );
                          return;
                        }

                        eco.completeHealthOnboarding(heightCm: heightVal, weightKg: weightVal);
                        _updateHeightController.text = heightVal.toStringAsFixed(0);
                        _updateWeightController.text = weightVal.toStringAsFixed(1);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.burgundyPrimary,
                            content: Text('Height and weight saved. Your health dashboard is ready.'),
                          ),
                        );

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _showDailyCalorieTargetModal(context, eco, isFirstTime: true);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 2. MAIN HEALTH DASHBOARD: 4 GRIDS (Calories, Workout, Weight/Height, BMI)
  // =========================================================================

  Widget _buildHealthHero(EcosystemProvider eco) {
    final now = DateTime.now();
    final cal = eco.getCaloriesConsumedForDate(now);
    final target = eco.dailyCalorieTarget > 0 ? eco.dailyCalorieTarget : 2000.0;
    final steps = eco.getStepsForDate(now);
    final bmi = eco.currentBmi;
    final meals = eco.dailyFoodLogs
        .where((f) => f.timestamp.year == now.year && f.timestamp.month == now.month && f.timestamp.day == now.day)
        .length;
    final left = (target - cal).round();
    String fmt(num v) => v.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return PillarHeroCard(
      icon: Icons.local_fire_department_rounded,
      eyebrow: 'Today',
      headline: '${fmt(cal)} of ${fmt(target)} kcal',
      caption: left >= 0 ? '${fmt(left)} kcal left for today' : '${fmt(-left)} kcal over today\'s target',
      progress: target > 0 ? cal / target : 0,
      ringLabel: '${(target > 0 ? (cal / target * 100) : 0).clamp(0, 999).round()}%',
      stats: [
        PillarHeroStat(fmt(steps), 'Steps'),
        PillarHeroStat(bmi > 0 ? bmi.toStringAsFixed(1) : '--', 'BMI'),
        PillarHeroStat('$meals', meals == 1 ? 'Meal logged' : 'Meals logged'),
      ],
    );
  }

  Widget _buildMainDashboard(BuildContext context, EcosystemProvider eco) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHealthHero(eco),
          const SizedBox(height: 16),

          // 1. Horizontal Date Strip (Date is first)
          _buildHorizontalDateStrip(eco),
          const SizedBox(height: 16),

          // 2. Pillar 1 Modules (the four boxes)
          _buildTheFourGrids(eco),
          const SizedBox(height: 18),

          // 3. Module options & active content below
          _buildActiveGridContent(context, eco),
          const SizedBox(height: 18),

          // 4. Daily Step Count & Tracker
          _buildDailyStepTrackerCard(context, eco),
          const SizedBox(height: 14),

          // 5. Daily Calorie Target
          _buildCalorieTargetHeaderCard(context, eco),
          const SizedBox(height: 14),

          // 6. Protein, carbs, fat, fibre
          _buildNutritionCard(eco),
          const SizedBox(height: 14),

          // 7. Water and sleep (typed in)
          _buildWaterSleepCard(context, eco),

          // 6. Leadership: View Employee Health Activities Gateway
          if (eco.isCeo || eco.activeRole.toLowerCase() == 'ceo' || eco.activeRole.toLowerCase() == 'hr') ...[
            const SizedBox(height: 20),
            _buildStaffHealthActivitiesGateway(context, eco),
          ],
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // =========================================================================
  // NUTRITION (macros) and WATER & SLEEP
  // =========================================================================

  Widget _buildNutritionCard(EcosystemProvider eco) {
    final m = eco.macrosForDate(_selectedDate);
    final g = eco.macroGoals;
    Widget bar(String label, double value, double goal, Color color, Key key) {
      final pct = goal > 0 ? (value / goal) : 0.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$label:', style: kitBody(13)),
              const SizedBox(width: 6),
              Text('${(pct * 100).round()}%', key: key, style: kitTitle(13.5)),
              const Spacer(),
              Text('${value.round()}/${goal.round()} g', style: kitBody(11)),
            ],
          ),
          const SizedBox(height: 6),
          KitBar(progress: pct, color: color, height: 6),
        ],
      );
    }

    return KitCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const KitIcon(Icons.restaurant_rounded, Color(0xFFF97316)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nutrition', style: kitTitle(16)),
                    Text('${_formatDayLabel(_selectedDate)} · estimated from your meals', style: kitBody(12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: bar('Protein', m.protein, g.protein, const Color(0xFFE11D48), const Key('macro_protein'))),
              const SizedBox(width: 16),
              Expanded(child: bar('Carb', m.carbs, g.carbs, const Color(0xFFF59E0B), const Key('macro_carbs'))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: bar('Fat', m.fat, g.fat, const Color(0xFF8B5CF6), const Key('macro_fat'))),
              const SizedBox(width: 16),
              Expanded(child: bar('Fibre', m.fibre, g.fibre, const Color(0xFF10B981), const Key('macro_fibre'))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            eco.userWeightKg > 0
                ? 'Goals set from your ${eco.dailyCalorieTarget.round()} kcal target and ${eco.userWeightKg.toStringAsFixed(0)} kg weight. Recalibrate to change them.'
                : 'Goals set from your ${eco.dailyCalorieTarget.round()} kcal target. Recalibrate to change them.',
            key: const Key('macro_goal_basis'),
            style: kitBody(11.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterSleepCard(BuildContext context, EcosystemProvider eco) {
    final water = eco.getWaterForDate(_selectedDate);
    final sleep = eco.getSleepMinutesForDate(_selectedDate);
    final waterGoal = eco.waterGoalGlasses;
    final sleepGoal = eco.sleepGoalMinutes;
    final past = _isPastDate(_selectedDate);
    String hm(int mins) => '${mins ~/ 60}h ${mins % 60}m';

    Future<void> editSleep() async {
      if (past) return;
      var h = sleep ~/ 60, mi = (sleep % 60) ~/ 5 * 5;
      final ok = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, set) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('How long did you sleep?', style: kitTitle(18)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: h,
                        decoration: const InputDecoration(labelText: 'Hours'),
                        items: [for (var i = 0; i <= 14; i++) DropdownMenuItem(value: i, child: Text('$i h'))],
                        onChanged: (v) => set(() => h = v ?? h),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: mi,
                        decoration: const InputDecoration(labelText: 'Minutes'),
                        items: [for (var i = 0; i < 60; i += 5) DropdownMenuItem(value: i, child: Text('$i m'))],
                        onChanged: (v) => set(() => mi = v ?? mi),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(key: const Key('sleep_save'), onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
              ],
            ),
          ),
        ),
      );
      if (ok == true) eco.setSleepMinutesForDate(_selectedDate, h * 60 + mi);
    }

    // Change the daily water / sleep goal (kept for every day after).
    Future<void> editGoals() async {
      var glasses = waterGoal;
      var gh = sleepGoal ~/ 60, gm = (sleepGoal % 60) ~/ 15 * 15;
      final ok = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, set) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Your daily goals', style: kitTitle(18)),
                  const SizedBox(height: 4),
                  Text('Change them any time.', style: kitBody(12.5)),
                  const SizedBox(height: 16),
                  Text('Water', style: kitTitle(14)),
                  Row(
                    children: [
                      IconButton(
                        key: const Key('water_goal_minus'),
                        onPressed: glasses > 1 ? () => set(() => glasses--) : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      Expanded(
                        child: Text('$glasses glasses',
                            key: const Key('water_goal_value'), textAlign: TextAlign.center, style: kitTitle(16)),
                      ),
                      IconButton(
                        key: const Key('water_goal_plus'),
                        onPressed: glasses < 30 ? () => set(() => glasses++) : null,
                        icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF0EA5E9)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Sleep', style: kitTitle(14)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: gh,
                          decoration: const InputDecoration(labelText: 'Hours'),
                          items: [for (var i = 1; i <= 14; i++) DropdownMenuItem(value: i, child: Text('$i h'))],
                          onChanged: (v) => set(() => gh = v ?? gh),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: gm,
                          decoration: const InputDecoration(labelText: 'Minutes'),
                          items: [for (final i in const [0, 15, 30, 45]) DropdownMenuItem(value: i, child: Text('$i m'))],
                          onChanged: (v) => set(() => gm = v ?? gm),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    key: const Key('goals_save'),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Save goals'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (ok == true) {
        if (glasses != waterGoal) eco.setWaterGoalGlasses(glasses);
        final mins = gh * 60 + gm;
        if (mins != sleepGoal) eco.setSleepGoalMinutes(mins);
      }
    }

    Widget row({
      required IconData icon,
      required Color color,
      required String title,
      required String value,
      required double progress,
      required Widget trailing,
    }) =>
        Row(
          children: [
            KitRing(
              progress: progress,
              color: color,
              size: 54,
              stroke: 5,
              center: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: kitTitle(15)),
                  Text(value, style: kitBody(13)),
                ],
              ),
            ),
            trailing,
          ],
        );

    return KitCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Water & sleep', style: kitTitle(14))),
              TextButton.icon(
                key: const Key('health_goals_edit'),
                onPressed: editGoals,
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: const Text('Edit goals'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          row(
            icon: Icons.local_drink_rounded,
            color: const Color(0xFF0EA5E9),
            title: 'Water',
            value: '$water of $waterGoal glasses',
            progress: water / waterGoal,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('water_minus'),
                  onPressed: past || water == 0 ? null : () => eco.setWaterForDate(_selectedDate, water - 1),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                IconButton(
                  key: const Key('water_plus'),
                  onPressed: past ? null : () => eco.setWaterForDate(_selectedDate, water + 1),
                  icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF0EA5E9)),
                ),
              ],
            ),
          ),
          const Divider(height: 22),
          row(
            icon: Icons.bedtime_rounded,
            color: const Color(0xFF6366F1),
            title: 'Sleep',
            value: '${hm(sleep)} of ${hm(sleepGoal)}',
            progress: sleep / sleepGoal,
            trailing: KitChipButton(
              buttonKey: const Key('sleep_edit'),
              label: sleep == 0 ? 'Add' : 'Edit',
              icon: Icons.edit_rounded,
              onTap: past ? () {} : editSleep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffHealthActivitiesGateway(BuildContext context, EcosystemProvider eco) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.sandGold.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.health_and_safety_rounded, color: AppColors.sandGold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMPLOYEE HEALTH ACTIVITIES',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandLight,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Inspect team calorie targets, BMI, workouts & meals',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sandGold,
              foregroundColor: AppColors.burgundyBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmployeeHealthActivitiesScreen()),
              );
            },
            child: Text(
              'Inspect',
              style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TOP CARD: DAILY CALORIE TARGET (Consumed vs Goal, Progress Bar, Tap to Edit)
  // =========================================================================

  Widget _buildCalorieTargetHeaderCard(BuildContext context, EcosystemProvider eco) {
    final targetKcal = eco.dailyCalorieTarget;
    final consumedKcal = eco.getCaloriesConsumedForDate(_selectedDate);
    final burnedKcal = eco.getCaloriesBurnedForDate(_selectedDate);
    final netKcal = consumedKcal - burnedKcal;
    final pctConsumed = targetKcal > 0 ? (consumedKcal / targetKcal) : 0.0;
    final displayPct = (pctConsumed * 100).round();
    final leftKcal = (targetKcal - consumedKcal);

    final Color progressColor;
    final String progressStatus;
    if (displayPct < 50) {
      progressColor = const Color(0xFF0EA5E9);
      progressStatus = displayPct == 0 ? 'Nothing logged yet' : 'Just getting started';
    } else if (displayPct <= 90) {
      progressColor = const Color(0xFF10B981);
      progressStatus = 'On track';
    } else if (displayPct <= 105) {
      progressColor = const Color(0xFFF59E0B);
      progressStatus = 'Target reached';
    } else {
      progressColor = const Color(0xFFEF4444);
      progressStatus = 'Over target';
    }

    return KitCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      onTap: () => _showDailyCalorieTargetModal(context, eco, isFirstTime: false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              KitIcon(Icons.local_fire_department_rounded, progressColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calories today', style: kitTitle(16)),
                    Text('${_formatDayLabel(_selectedDate)} · $progressStatus', style: kitBody(12.5)),
                  ],
                ),
              ),
              KitChipButton(
                label: 'Target',
                icon: Icons.tune_rounded,
                onTap: () => _showDailyCalorieTargetModal(context, eco, isFirstTime: false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              KitRing(
                progress: pctConsumed,
                color: progressColor,
                size: 104,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$displayPct%', style: kitValue(22).copyWith(color: progressColor)),
                    Text('eaten', style: kitBody(11)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(kitNumber(consumedKcal), style: kitValue(34)),
                    ),
                    Text('of ${kitNumber(targetKcal)} kcal', style: kitBody(13)),
                    const SizedBox(height: 8),
                    Text(
                      leftKcal >= 0 ? '${kitNumber(leftKcal)} kcal left' : '${kitNumber(-leftKcal)} kcal over',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: leftKcal >= 0 ? AppColors.textDark : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          KitMiniStatRow([
            KitMiniStat(
              value: kitNumber(consumedKcal),
              label: 'Eaten',
              color: const Color(0xFFF97316),
              icon: Icons.restaurant_rounded,
            ),
            KitMiniStat(
              value: kitNumber(burnedKcal),
              label: 'Burned',
              color: const Color(0xFF10B981),
              icon: Icons.bolt_rounded,
            ),
            KitMiniStat(
              value: '${netKcal >= 0 ? '+' : '−'}${kitNumber(netKcal.abs())}',
              label: 'Net',
              color: const Color(0xFF6366F1),
              icon: Icons.balance_rounded,
            ),
          ]),
        ],
      ),
    );
  }

  // =========================================================================
  // HORIZONTAL DATE STRIP: CENTER DATE CAROUSEL WITH +/- 3 DAYS & MONTH NAV
  // =========================================================================

  /// Anything health-related logged on [d]: meals, workouts, steps, water or sleep.
  bool _hasHealthLog(EcosystemProvider eco, DateTime d) =>
      eco.getFoodLogsForDate(d).isNotEmpty ||
      eco.getWorkoutLogsForDate(d).isNotEmpty ||
      eco.getStepsForDate(d) > 0 ||
      eco.getWaterForDate(d) > 0 ||
      eco.getSleepMinutesForDate(d) > 0;

  /// One date card (same as Family): ring shows whether that day was logged.
  /// Tap it to open the month calendar.
  Widget _buildHorizontalDateStrip(EcosystemProvider eco) {
    final d = _selectedDate;
    final logged = _hasHealthLog(eco, d);
    final isToday = _isToday(d);
    final color = logged ? const Color(0xFF10B981) : (isToday ? AppColors.primary : const Color(0xFFEF4444));
    return KitCard(
      key: const Key('health_date_button'),
      onTap: () => _openHealthCalendar(eco),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 3)),
            child: Text('${d.day}', style: kitValue(18).copyWith(color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${d.day} ${_months[d.month - 1]} ${d.year}', style: kitTitle(16)),
                Text(
                  isToday ? 'Today · tap to pick another day' : (logged ? 'Health logged that day' : 'Nothing logged that day'),
                  style: kitBody(12.5),
                ),
              ],
            ),
          ),
          if (!isToday)
            TextButton(
              key: const Key('health_date_today'),
              onPressed: () => setState(() => _selectedDate = DateTime.now()),
              child: const Text('Today'),
            ),
          const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
        ],
      ),
    );
  }

  /// Month calendar: green ring = something logged that day,
  /// red ring = a past day with nothing logged.
  Future<void> _openHealthCalendar(EcosystemProvider eco) async {
    var month = DateTime(_selectedDate.year, _selectedDate.month);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final first = DateTime(month.year, month.month, 1);
          final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
          final lead = first.weekday % 7; // Sunday first
          final canNext = DateTime(month.year, month.month + 1).isBefore(DateTime(today.year, today.month + 1));
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => set(() => month = DateTime(month.year, month.month - 1)),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text('${_months[month.month - 1]} ${month.year}',
                            textAlign: TextAlign.center, style: kitTitle(17)),
                      ),
                      IconButton(
                        onPressed: canNext ? () => set(() => month = DateTime(month.year, month.month + 1)) : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final w in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                        Expanded(child: Center(child: Text(w, style: kitBody(12)))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    children: [
                      for (var i = 0; i < lead; i++) const SizedBox(),
                      for (var day = 1; day <= daysInMonth; day++)
                        Builder(builder: (_) {
                          final date = DateTime(month.year, month.month, day);
                          final future = date.isAfter(todayOnly);
                          final has = !future && _hasHealthLog(eco, date);
                          final ring = future
                              ? const Color(0xFFE5D5DE)
                              : (has ? const Color(0xFF10B981) : (date == todayOnly ? AppColors.primary : const Color(0xFFEF4444)));
                          final selected = _isSameDay(date, _selectedDate);
                          return InkWell(
                            key: Key('health_cal_day_$day'),
                            customBorder: const CircleBorder(),
                            onTap: future ? null : () => Navigator.pop(ctx, date),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected ? ring.withOpacity(0.15) : null,
                                border: Border.all(color: ring, width: selected ? 3 : 2),
                              ),
                              child: Text('$day',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: future ? AppColors.textMuted : AppColors.textDark,
                                  )),
                            ),
                          );
                        }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    children: [
                      _calLegend(const Color(0xFF10B981), 'Logged'),
                      _calLegend(const Color(0xFFEF4444), 'Not logged'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Widget _calLegend(Color c, String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: 2.5)),
          ),
          const SizedBox(width: 5),
          Text(t, style: kitBody(12)),
        ],
      );

  // =========================================================================
  // DAILY STEP COUNT TRACKER CARD & PHONE PEDOMETER PERMISSION
  // =========================================================================

  static String _fmtSteps(int n) {
    final str = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return buf.toString();
  }

  Widget _buildDailyStepTrackerCard(BuildContext context, EcosystemProvider eco) {
    final recordedSteps = eco.getStepsForDate(_selectedDate);
    final int stepGoal = eco.dailyStepGoal;
    final pct = stepGoal > 0 ? recordedSteps / stepGoal : 0.0;
    final reached = pct >= 1.0;
    const green = Color(0xFF10B981);
    final color = reached ? green : AppColors.primary;
    final left = (stepGoal - recordedSteps).clamp(0, stepGoal);
    final source = eco.stepSourceFor(_selectedDate);

    return KitCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const KitIcon(Icons.directions_walk_rounded, green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Steps', style: kitTitle(16)),
                    Text(_formatDayLabel(_selectedDate), style: kitBody(12.5)),
                  ],
                ),
              ),
              KitChipButton(
                label: 'Log Steps',
                icon: Icons.edit_rounded,
                onTap: () => _openStepCountRecordingDialog(context, eco),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              KitRing(
                progress: pct,
                color: color,
                size: 104,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(pct * 100).clamp(0, 999).round()}%', style: kitValue(22).copyWith(color: color)),
                    Text('of goal', style: kitBody(11)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(kitNumber(recordedSteps), style: kitValue(34)),
                    ),
                    Text('of ${kitNumber(stepGoal)} steps', style: kitBody(13)),
                    const SizedBox(height: 8),
                    Text(
                      reached ? 'Goal reached — great walking! 🎉' : '${kitNumber(left)} to go',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: reached ? green : AppColors.textDark,
                      ),
                    ),
                    if (recordedSteps > 0) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          KitPill(
                            source == 'phone' ? 'From phone' : 'Typed in',
                            const Color(0xFF64748B),
                            icon: source == 'phone' ? Icons.phone_android_rounded : Icons.edit_rounded,
                          ),
                          if (eco.isUnusualSteps(recordedSteps))
                            const KitPill('Unusually high — please check', Color(0xFFD97706),
                                icon: Icons.warning_amber_rounded),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AutoStepsPanel(),
          const SizedBox(height: 10),
          KitListRow(
            icon: Icons.flag_rounded,
            color: AppColors.primary,
            title: 'Daily goal',
            subtitle: '${kitNumber(stepGoal)} steps a day',
            onTap: () => _openSetStepGoalDialog(context, eco),
            trailing: KitChipButton(
              label: 'Set Goal',
              icon: Icons.tune_rounded,
              onTap: () => _openSetStepGoalDialog(context, eco),
            ),
          ),
        ],
      ),
    );
  }

  void _openSetStepGoalDialog(BuildContext context, EcosystemProvider eco) {
    if (_isPastDate(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ragRed,
          content: Text('Cannot edit step targets for past dates. Previous dates are view only.'),
        ),
      );
      return;
    }
    int targetGoal = eco.dailyStepGoal;
    final controller = TextEditingController(text: targetGoal.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final presets = [4000, 5000, 6000, 8000, 10000, 12000];

            return AlertDialog(
              backgroundColor: AppColors.burgundyCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.sandGold),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.sandGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.flag_rounded, color: AppColors.sandGold, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Daily Step Target Goal',
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set your daily walking step goal. A higher goal increases endurance and daily metabolic balance.',
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandPrimary),
                    ),
                    const SizedBox(height: 14),

                    // Quick Preset Chips
                    Text(
                      'QUICK PRESETS',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: presets.map((preset) {
                        final isSel = targetGoal == preset;
                        return ChoiceChip(
                          label: Text(
                            '$preset steps',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              color: isSel ? AppColors.burgundyBg : AppColors.sandLight,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.sandGold,
                          backgroundColor: AppColors.burgundySurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSel ? AppColors.sandGold : AppColors.sandBorder,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                targetGoal = preset;
                                controller.text = preset.toString();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Custom input field
                    Text(
                      'CUSTOM STEP TARGET',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.burgundySurface,
                        hintText: 'e.g. 7500',
                        hintStyle: GoogleFonts.outfit(color: AppColors.sandPrimary.withOpacity(0.5)),
                        suffixText: 'steps / day',
                        suffixStyle: GoogleFonts.outfit(color: AppColors.sandGold, fontSize: 11),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandGold, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (parsed != null && parsed > 0) {
                          setDialogState(() {
                            targetGoal = parsed;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.outfit(color: AppColors.sandPrimary, fontSize: 12),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sandGold,
                    foregroundColor: AppColors.burgundyBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    final entered = int.tryParse(controller.text) ?? targetGoal;
                    if (entered > 0) {
                      eco.setDailyStepGoal(entered);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Daily step goal updated to $entered steps!',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Save Goal',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.burgundyBg,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTheFourGrids(EcosystemProvider eco) {
    final dayConsumed = eco.getCaloriesConsumedForDate(_selectedDate);
    final dayFoodLogs = eco.getFoodLogsForDate(_selectedDate);
    final dayWorkoutMins = eco.getWorkoutMinutesForDate(_selectedDate);
    final dayWorkoutLogs = eco.getWorkoutLogsForDate(_selectedDate);
    final day = _formatDayShort(_selectedDate);
    String plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

    Widget tile(int index, IconData icon, Color color, String label, String value, String? unit, String caption) =>
        KitStatTile(
          icon: icon,
          color: color,
          label: label,
          value: value,
          unit: unit,
          caption: caption,
          selected: _selectedGridIndex == index,
          onTap: () => setState(() => _selectedGridIndex = index),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSectionHeader('Today at a glance', subtitle: 'Tap a card to see its details below'),
        const SizedBox(height: 12),
        KitTileGrid(children: [
          tile(0, Icons.restaurant_menu_rounded, const Color(0xFFF97316), 'Calories', kitNumber(dayConsumed), 'kcal',
              '${plural(dayFoodLogs.length, 'meal')} · $day'),
          tile(1, Icons.fitness_center_rounded, const Color(0xFF10B981), 'Workout', '$dayWorkoutMins', 'min',
              '${plural(dayWorkoutLogs.length, 'session')} · $day'),
          tile(2, Icons.monitor_weight_rounded, const Color(0xFF6366F1), 'Weight / Height',
              eco.userWeightKg > 0 ? eco.userWeightKg.toStringAsFixed(1) : '—', eco.userWeightKg > 0 ? 'kg' : null,
              eco.userHeightCm > 0 ? 'Height ${eco.userHeightCm.toStringAsFixed(0)} cm' : 'Not set yet'),
          tile(3, Icons.speed_rounded, eco.bmiColor, 'BMI', eco.currentBmi > 0 ? eco.currentBmi.toStringAsFixed(1) : '—',
              null, eco.currentBmi > 0 ? eco.bmiCategory : 'Add weight & height'),
        ]),
      ],
    );
  }


  // =========================================================================
  // 3. ACTIVE GRID CONTENT ROUTER
  // =========================================================================

  Widget _buildActiveGridContent(BuildContext context, EcosystemProvider eco) {
    switch (_selectedGridIndex) {
      case 0:
        return _buildCaloriesSection(context, eco);
      case 1:
        return _buildWorkoutSection(context, eco);
      case 2:
        return _buildWeightHeightSection(context, eco);
      case 3:
      default:
        return _buildBmiSection(context, eco);
    }
  }

  // -------------------------------------------------------------------------
  // GRID 1: CALORIES MODULE (Hybrid Open-Source API + Instant Local Catalog)
  // -------------------------------------------------------------------------

  Widget _buildCaloriesSection(BuildContext context, EcosystemProvider eco) {
    final queryText = _foodSearchController.text.trim();
    final selectedDateLogs = eco.getFoodLogsForDate(_selectedDate);
    final selectedDateCalories = eco.getCaloriesConsumedForDate(_selectedDate);

    // 1. Only retrieve food items when user has actually typed something to search
    List<FoodItem> localResults = [];
    if (queryText.isNotEmpty) {
      localResults = FoodDatabase.search(queryText);
      if (_selectedCategory != 'All') {
        final filtered = localResults.where((item) => item.category == _selectedCategory).toList();
        if (filtered.isNotEmpty) {
          localResults = filtered;
        }
      }
    }

    // 2. Combine with public open API search results (avoiding duplicates)
    final existingNames = localResults.map((e) => e.name.toLowerCase()).toSet();
    final combinedResults = <FoodItem>[...localResults];
    if (queryText.isNotEmpty) {
      for (var onlineItem in _apiSearchResults) {
        if (!existingNames.contains(onlineItem.name.toLowerCase())) {
          if (_selectedCategory == 'All' || onlineItem.category == _selectedCategory) {
            combinedResults.add(onlineItem);
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header & Public Open Database Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CALORIES & NUTRITIONAL INTAKE',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.ragGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Search Indian and international dishes',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: AppColors.sandPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.sandGold, size: 28),
              tooltip: 'Add Custom Food',
              onPressed: () => _openAddCustomFoodDialog(context, eco),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Food Search Input with Live API Debouncing Indicator
        Container(
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: TextField(
            controller: _foodSearchController,
            style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 13),
            onChanged: _onFoodSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search Tamil & Indian food — idli, meen kuzhambu, இட்லி…',
              hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: AppColors.sandGold, size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSearchingApi)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.sandGold,
                        ),
                      ),
                    ),
                  if (_foodSearchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.sandPrimary, size: 18),
                      onPressed: () {
                        _foodSearchController.clear();
                        _onFoodSearchChanged('');
                      },
                    ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              'All',
              'Fast Food & Global',
              'Breakfast',
              'Main Course',
              'Lentils & Curries',
              'Dairy & Sides',
              'Snacks & Beverages',
              'Fruits & Healthy',
              'Sweets & Desserts',
            ].map((cat) {
              final isCatSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isCatSelected,
                  selectedColor: AppColors.magentaPrimary,
                  backgroundColor: AppColors.pureWhite,
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: isCatSelected ? FontWeight.bold : FontWeight.w500,
                    color: isCatSelected ? Colors.white : AppColors.textDark,
                  ),
                  side: BorderSide(
                    color: isCatSelected ? AppColors.magentaPrimary : const Color(0xFFE2E8F0),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Food Database Search Results (Combines Instant + Public API)
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: queryText.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.burgundySurface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.sandGold, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'POPULAR EVERYDAY INDIAN FOODS & BEVERAGES',
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sandGold,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: FoodDatabase.catalog.take(25).length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.sandBorder, height: 1),
                        itemBuilder: (ctx, idx) {
                          final item = FoodDatabase.catalog[idx];
                          return Material(type: MaterialType.transparency, child: ListTile(
                            dense: true,
                            leading: Text(item.iconEmoji, style: const TextStyle(fontSize: 20)),
                            title: Text(
                              item.name,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.sandLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${item.caloriesPer100g.toStringAsFixed(0)} kcal / 100g • ${item.servingUnit}',
                              style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.burgundySurface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                              ),
                              child: Text(
                                '+ Log',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandGold,
                                ),
                              ),
                            ),
                            onTap: () => _openLogFoodDialog(context, eco, item),
                          ));
                        },
                      ),
                    ),
                  ],
                )
              : combinedResults.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isSearchingApi
                                  ? 'Searching public open food database API...'
                                  : 'No matching food items found.\nTap "+" above to log a custom food item.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.sandPrimary),
                            ),
                            if (!_isSearchingApi && queryText.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _openAddCustomFoodDialog(
                                  context,
                                  eco,
                                  initialName: queryText,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.burgundySurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.sandGold, width: 0.9),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add_circle_outline, size: 16, color: AppColors.sandGold),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Log "$queryText" as custom food',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.sandGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: combinedResults.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.sandBorder, height: 1),
                  itemBuilder: (ctx, idx) {
                    final item = combinedResults[idx];
                    final isOnline = item.id.startsWith('api_');

                    return Material(type: MaterialType.transparency, child: ListTile(
                      dense: true,
                      leading: Text(item.iconEmoji, style: const TextStyle(fontSize: 20)),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.sandLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isOnline)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.burgundySurface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                              ),
                              child: Text(
                                'Open API',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: AppColors.sandGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${item.caloriesPer100g.toStringAsFixed(0)} kcal / 100g • ${item.servingUnit}',
                        style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.burgundySurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                        ),
                        child: Text(
                          '+ Log',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                          ),
                        ),
                      ),
                      onTap: () => _openLogFoodDialog(context, eco, item),
                    ));
                  },
                ),
        ),
        const SizedBox(height: 18),

        // Selected Date's Food Log Diary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                "INTAKE DIARY • ${_formatDayLabel(_selectedDate).toUpperCase()} (${selectedDateLogs.length})",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandGold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Total: ${selectedDateCalories.toInt()} kcal',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.sandLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (selectedDateLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Center(
              child: Text(
                'No meals logged for ${_formatDayLabel(_selectedDate)}.\nSelect an item from the catalog above to add.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.sandPrimary),
              ),
            ),
          )
        else
          Column(
            children: selectedDateLogs.map((log) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.burgundySurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: Text(
                        log.mealType,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.foodName,
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.sandLight,
                            ),
                          ),
                          Text(
                            '${log.portionSize} • ${log.quantity != 1.0 ? "Qty: ${log.quantity % 1 == 0 ? log.quantity.toInt() : log.quantity.toStringAsFixed(1)} • " : ""}${log.grams.toStringAsFixed(0)}g • ${log.timeString}',
                            style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${log.calories.toStringAsFixed(0)} kcal',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.ragRed),
                      onPressed: () => eco.deleteFoodLog(log.id),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _openLogFoodDialog(BuildContext context, EcosystemProvider eco, FoodItem item) {
    if (_isPastDate(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ragRed,
          content: Text('Cannot log meals for past dates. Previous dates are view & delete only.'),
        ),
      );
      return;
    }
    final hour = DateTime.now().hour;
    String selectedMealType = (hour < 11)
        ? 'Breakfast'
        : (hour < 16)
            ? 'Lunch'
            : (hour < 19)
                ? 'Snack'
                : 'Dinner';

    String selectedPortion = 'Normal';
    double quantity = 1.0;
    final quantityController = TextEditingController(text: '1.0');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            double baseGrams;
            String portionLabel;
            if (selectedPortion == 'Small') {
              baseGrams = item.smallPortionGrams;
              portionLabel = item.smallPortionLabel;
            } else if (selectedPortion == 'Big') {
              baseGrams = item.bigPortionGrams;
              portionLabel = item.bigPortionLabel;
            } else {
              baseGrams = item.normalPortionGrams;
              portionLabel = item.normalPortionLabel;
            }

            final totalGrams = baseGrams * quantity;
            final calculatedKcal = item.caloriesForGrams(totalGrams);

            return Dialog(
              backgroundColor: AppColors.burgundyCard,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.sandGold, width: 1.2),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(item.iconEmoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.caloriesPer100g.toStringAsFixed(0)} kcal / 100g • ${item.category}',
                                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandPrimary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.sandPrimary, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.sandBorder, height: 1),
                      const SizedBox(height: 12),

                      // 1. Meal Category Selection (Required first)
                      Text(
                        '1. Choose Meal Timing',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sandGold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _mealTypeButton(
                            label: 'Breakfast',
                            icon: '🌅',
                            isSelected: selectedMealType == 'Breakfast',
                            onTap: () => setDialogState(() => selectedMealType = 'Breakfast'),
                          ),
                          const SizedBox(width: 6),
                          _mealTypeButton(
                            label: 'Lunch',
                            icon: '☀️',
                            isSelected: selectedMealType == 'Lunch',
                            onTap: () => setDialogState(() => selectedMealType = 'Lunch'),
                          ),
                          const SizedBox(width: 6),
                          _mealTypeButton(
                            label: 'Snack',
                            icon: '☕',
                            isSelected: selectedMealType == 'Snack',
                            onTap: () => setDialogState(() => selectedMealType = 'Snack'),
                          ),
                          const SizedBox(width: 6),
                          _mealTypeButton(
                            label: 'Dinner',
                            icon: '🌙',
                            isSelected: selectedMealType == 'Dinner',
                            onTap: () => setDialogState(() => selectedMealType = 'Dinner'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2. Portion Size Selection
                      Text(
                        item.isBeverage ? '2. Cup / Serving Size' : '2. Portion Size',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sandGold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _portionOptionCard(
                              label: item.smallPortionLabel,
                              sublabel: 'Small',
                              isSelected: selectedPortion == 'Small',
                              onTap: () => setDialogState(() => selectedPortion = 'Small'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _portionOptionCard(
                              label: item.normalPortionLabel,
                              sublabel: 'Normal',
                              isSelected: selectedPortion == 'Normal',
                              onTap: () => setDialogState(() => selectedPortion = 'Normal'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _portionOptionCard(
                              label: item.bigPortionLabel,
                              sublabel: 'Big / Large',
                              isSelected: selectedPortion == 'Big',
                              onTap: () => setDialogState(() => selectedPortion = 'Big'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. Quantity Stepper
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.burgundySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.sandGold.withOpacity(0.35)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '3. Quantity / Count',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.sandGold,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$portionLabel x ${quantity % 1 == 0 ? quantity.toInt() : quantity.toStringAsFixed(1)} = ${totalGrams.toInt()}g total',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      color: AppColors.sandPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.burgundyCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 28),
                                    icon: const Icon(Icons.remove, size: 15, color: AppColors.sandGold),
                                    onPressed: quantity > 0.5
                                        ? () {
                                            setDialogState(() {
                                              quantity = ((quantity - 0.5) * 10).round() / 10.0;
                                              if (quantity < 0.5) quantity = 0.5;
                                              quantityController.text = quantity % 1 == 0
                                                  ? quantity.toInt().toString()
                                                  : quantity.toStringAsFixed(1);
                                            });
                                          }
                                        : null,
                                  ),
                                  SizedBox(
                                    width: 44,
                                    child: TextField(
                                      controller: quantityController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.sandLight,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (val) {
                                        final parsed = double.tryParse(val.trim());
                                        if (parsed != null && parsed > 0) {
                                          setDialogState(() {
                                            quantity = parsed;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 26, minHeight: 28),
                                    icon: const Icon(Icons.add, size: 15, color: AppColors.sandGold),
                                    onPressed: () {
                                      setDialogState(() {
                                        quantity = ((quantity + 0.5) * 10).round() / 10.0;
                                        quantityController.text = quantity % 1 == 0
                                            ? quantity.toInt().toString()
                                            : quantity.toStringAsFixed(1);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4. Live Calculated Energy Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.burgundySurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.sandGold.withOpacity(0.6)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CALCULATED ENERGY',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandGold,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${totalGrams.toInt()}g • $selectedMealType',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.sandPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  calculatedKcal.toStringAsFixed(0),
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.sandGold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'kcal',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandLight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.sandBorder),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(color: AppColors.sandPrimary, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: Text(
                                'Add to Diary ($selectedMealType)',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.sandGold,
                                foregroundColor: AppColors.burgundyBg,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                eco.addFoodLog(
                                  foodName: item.name,
                                  mealType: selectedMealType,
                                  grams: totalGrams,
                                  calories: calculatedKcal,
                                  logDate: _selectedDate,
                                  portionSize: portionLabel,
                                  quantity: quantity,
                                );
                                Navigator.pop(ctx);
                                final qtyDisplay = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toStringAsFixed(1);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.burgundyPrimary,
                                    content: Text('Logged $qtyDisplay x ${item.name} (${calculatedKcal.toInt()} kcal) for ${_formatDayLabel(_selectedDate)}'),
                                  ),
                                );
                              },
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
      },
    );
  }

  void _openAddCustomFoodDialog(BuildContext context, EcosystemProvider eco, {String? initialName}) {
    if (_isPastDate(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ragRed,
          content: Text('Cannot log meals for past dates. Previous dates are view & delete only.'),
        ),
      );
      return;
    }
    final nameCtrl = TextEditingController(text: initialName ?? '');
    final kcalCtrl = TextEditingController();
    final gramsCtrl = TextEditingController();
    String meal = 'Lunch';

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.sandGold, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Custom Food Item',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Food Name',
                    labelStyle: const TextStyle(color: AppColors.sandPrimary, fontSize: 12),
                    hintText: 'e.g. Millet Dosa / Protein Shake',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: gramsCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Grams',
                          hintText: 'e.g. 100',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          labelStyle: const TextStyle(color: AppColors.sandPrimary, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.burgundySurface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: kcalCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Total Calories',
                          hintText: 'e.g. 150',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          labelStyle: const TextStyle(color: AppColors.sandPrimary, fontSize: 12),
                          filled: true,
                          fillColor: AppColors.burgundySurface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.sandPrimary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sandGold,
                        foregroundColor: AppColors.burgundyBg,
                      ),
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty) return;
                        final g = double.tryParse(gramsCtrl.text.trim());
                        final kcal = double.tryParse(kcalCtrl.text.trim());
                        if (g == null || kcal == null || g <= 0 || kcal < 0 || kcal > 10000) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.ragRed,
                              content: Text('Enter a valid weight (grams) and calories (0-10000).'),
                            ),
                          );
                          return;
                        }
                        eco.addFoodLog(
                          foodName: nameCtrl.text.trim(),
                          mealType: meal,
                          grams: g,
                          calories: kcal,
                          logDate: _selectedDate,
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save & Log'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // GRID 2: WORKOUT MODULE (Activity, MET Calculation, Steps, Time Allocation)
  // -------------------------------------------------------------------------

  Widget _buildWorkoutSection(BuildContext context, EcosystemProvider eco) {
    final selectedDateWorkouts = eco.getWorkoutLogsForDate(_selectedDate);
    final selectedDateWorkoutMins = eco.getWorkoutMinutesForDate(_selectedDate);
    final selectedDateWorkoutSteps = eco.getWorkoutStepsForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORKOUT & PHYSICAL ACTIVITY',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Track steps, walk duration & stamina allocations',
                    style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandPrimary),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Record Session',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sandGold,
                foregroundColor: AppColors.burgundyBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _openRecordWorkoutDialog(context, eco),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Text(
          'QUICK LOG FAVORITE EXERCISE',
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 85,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: WorkoutDatabase.activities.length,
            itemBuilder: (ctx, idx) {
              final act = WorkoutDatabase.activities[idx];
              final displayName = act.name.replaceAll(' / Jogging', '');
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openRecordWorkoutDialog(context, eco, presetActivity: act),
                child: Container(
                  width: 125,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.burgundyCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(act.icon, color: AppColors.sandGold, size: 22),
                      const SizedBox(height: 6),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "WORKOUTS • ${_formatDayLabel(_selectedDate).toUpperCase()} (${selectedDateWorkouts.length})",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.sandGold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${selectedDateWorkoutMins}m • $selectedDateWorkoutSteps steps',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.sandLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (selectedDateWorkouts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Center(
              child: Text(
                'No workout sessions recorded for ${_formatDayLabel(_selectedDate)}.\nTap "Record Session" above to add your activity.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 12, color: AppColors.sandPrimary),
              ),
            ),
          )
        else
          Column(
            children: selectedDateWorkouts.map((w) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.burgundySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                      ),
                      child: const Icon(Icons.directions_run, color: AppColors.sandGold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                w.activityName,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.burgundySurface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.sandBorder),
                                ),
                                child: Text(
                                  w.intensity,
                                  style: const TextStyle(fontSize: 11, color: AppColors.sandPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${w.durationMinutes} mins • ${w.laps > 0 ? '${w.laps} laps • ' : ''}${w.sets > 0 ? '${w.sets} sets • ' : ''}${w.rounds > 0 ? '${w.rounds} rounds • ' : ''}${w.steps > 0 ? '${w.steps} steps • ' : ''}${w.distanceKm > 0 ? '${w.distanceKm.toStringAsFixed(1)} km • ' : ''}${w.customMetric.isNotEmpty ? '${w.customMetric} • ' : ''}${w.timeAllocation}',
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                          ),
                          if (w.notes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                w.notes,
                                style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.sandPrimary),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${w.caloriesBurned.toStringAsFixed(0)} kcal',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.ragRed),
                          onPressed: () => eco.deleteWorkoutLog(w.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _openRecordWorkoutDialog(BuildContext context, EcosystemProvider eco, {WorkoutActivityType? presetActivity}) {
    if (_isPastDate(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ragRed,
          content: Text('Cannot log workouts for past dates. Previous dates are view & delete only.'),
        ),
      );
      return;
    }
    WorkoutActivityType selectedActivity = presetActivity ?? WorkoutDatabase.activities.first;
    int durationMinutes = 30;
    String intensity = 'Moderate';
    String timeAllocation = 'Morning Routine';
    final durationController = TextEditingController(text: durationMinutes.toString());
    final notesController = TextEditingController();

    // Exclusive controllers and states based on activity category:
    final stepsController = TextEditingController(text: selectedActivity.metricCategory == WorkoutMetricCategory.walking ? '3000' : (selectedActivity.metricCategory == WorkoutMetricCategory.running ? '3500' : ''));
    final distanceController = TextEditingController(text: selectedActivity.metricCategory == WorkoutMetricCategory.running ? '3.0' : (selectedActivity.metricCategory == WorkoutMetricCategory.cycling ? '8.0' : ''));
    final lapsController = TextEditingController(text: '20'); // Swimming laps
    final setsController = TextEditingController(text: '12'); // Gym sets / Badminton games
    final roundsController = TextEditingController(text: '10'); // Yoga rounds / Surya Namaskars

    String strokeStyle = 'Freestyle / Crawl';
    String walkingPace = 'Moderate (5.0 km/h)';
    String runningStyle = 'Steady Jogging';
    String cyclingMode = 'Road Cycling';
    String targetMuscle = 'Full Body & Core';
    String yogaStyle = 'Hatha Yoga & Asanas';
    String badmintonFormat = 'Doubles Rally Match';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final dur = int.tryParse(durationController.text) ?? 30;
            final calculatedKcal = selectedActivity.calculateCalories(
              weightKg: eco.userWeightKg,
              minutes: dur,
            );

            final category = selectedActivity.metricCategory;

            return Dialog(
              backgroundColor: AppColors.pureWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(selectedActivity.icon, color: AppColors.magentaPrimary, size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record Workout Session',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'MET formula calibrated for ${eco.userWeightKg.toStringAsFixed(1)} kg body weight',
                                  style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 12),

                      // Activity Type Dropdown
                      Text(
                        'Activity Type',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<WorkoutActivityType>(
                        value: selectedActivity,
                        isExpanded: true,
                        dropdownColor: AppColors.pureWhite,
                        style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12.5),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        items: WorkoutDatabase.activities.map((act) {
                          return DropdownMenuItem(
                            value: act,
                            child: Row(
                              children: [
                                Icon(act.icon, size: 16, color: AppColors.magentaPrimary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(act.name, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() {
                              selectedActivity = v;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Health Time Allocation
                      Text(
                        'Health Time Allocation',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        value: timeAllocation,
                        isExpanded: true,
                        isDense: true,
                        dropdownColor: AppColors.pureWhite,
                        style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12.5),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        selectedItemBuilder: (context) {
                          return [
                            'Morning Routine (06:00 - 08:30)',
                            'Mid-day Break',
                            'Evening Routine (18:00 - 20:30)',
                            'Night Routine (Post-Dinner)',
                          ].map((e) => Text(e, overflow: TextOverflow.ellipsis, maxLines: 1)).toList();
                        },
                        items: const [
                          DropdownMenuItem(value: 'Morning Routine', child: Text('Morning Routine (06:00 - 08:30)')),
                          DropdownMenuItem(value: 'Mid-day Break', child: Text('Mid-day Break')),
                          DropdownMenuItem(value: 'Evening Routine', child: Text('Evening Routine (18:00 - 20:30)')),
                          DropdownMenuItem(value: 'Night Routine', child: Text('Night Routine (Post-Dinner)')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => timeAllocation = v);
                        },
                      ),
                      const SizedBox(height: 12),

                      // DYNAMIC ACTIVITY-EXCLUSIVE FIELDS
                      // 1. SWIMMING (LAPS): Duration + Laps Count + Stroke Style (NO steps!)
                      if (category == WorkoutMetricCategory.swimming) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _numberInputField(
                                label: 'Duration (mins)',
                                controller: durationController,
                                suffix: 'mins',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _numberInputField(
                                label: 'Laps Count',
                                controller: lapsController,
                                suffix: 'laps',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Stroke Style',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: strokeStyle,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12),
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'Freestyle / Crawl', child: Text('Freestyle / Front Crawl')),
                            DropdownMenuItem(value: 'Breaststroke', child: Text('Breaststroke')),
                            DropdownMenuItem(value: 'Backstroke', child: Text('Backstroke')),
                            DropdownMenuItem(value: 'Butterfly', child: Text('Butterfly')),
                            DropdownMenuItem(value: 'Mixed Medley', child: Text('Mixed Medley')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => strokeStyle = v);
                          },
                        ),
                      ]
                      // 2. BRISK WALKING: Duration + Step Count + Pace
                      else if (category == WorkoutMetricCategory.walking) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _numberInputField(
                                label: 'Duration (mins)',
                                controller: durationController,
                                suffix: 'mins',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _numberInputField(
                                label: 'Step Count',
                                controller: stepsController,
                                suffix: 'steps',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Walking Pace',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: walkingPace,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12),
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'Casual Walk (4.0 km/h)', child: Text('Casual Walk (~4.0 km/h)')),
                            DropdownMenuItem(value: 'Moderate (5.0 km/h)', child: Text('Moderate Pace (~5.0 km/h)')),
                            DropdownMenuItem(value: 'Power Walk (6.2 km/h)', child: Text('Power Walk (~6.2 km/h)')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => walkingPace = v);
                          },
                        ),
                      ]
                      // 3. RUNNING: Duration + Step Count + Distance + Running Style
                      else if (category == WorkoutMetricCategory.running) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _numberInputField(
                                label: 'Duration (mins)',
                                controller: durationController,
                                suffix: 'mins',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _numberInputField(
                                label: 'Cadence (steps)',
                                controller: stepsController,
                                suffix: 'steps',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _numberInputField(
                                label: 'Distance (km)',
                                controller: distanceController,
                                suffix: 'km',
                                isDecimal: true,
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Running Style',
                                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 5),
                                  DropdownButtonFormField<String>(
                                    value: runningStyle,
                                    isExpanded: true,
                                    dropdownColor: AppColors.pureWhite,
                                    style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12),
                                    decoration: _inputDecoration(),
                                    items: const [
                                      DropdownMenuItem(value: 'Steady Jogging', child: Text('Jogging')),
                                      DropdownMenuItem(value: 'Paced Running', child: Text('Paced Run')),
                                      DropdownMenuItem(value: 'Interval Sprinting', child: Text('Sprints')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) setDialogState(() => runningStyle = v);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ]
                      // 4. CYCLING: Duration + Distance + Mode (NO steps!)
                      else if (category == WorkoutMetricCategory.cycling) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _numberInputField(
                                label: 'Duration (mins)',
                                controller: durationController,
                                suffix: 'mins',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _numberInputField(
                                label: 'Distance (km)',
                                controller: distanceController,
                                suffix: 'km',
                                isDecimal: true,
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Cycling Terrain / Mode',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: cyclingMode,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12),
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'Road Cycling', child: Text('Outdoor Road Cycling')),
                            DropdownMenuItem(value: 'Stationary Spin Bike', child: Text('Stationary / Spin Bike')),
                            DropdownMenuItem(value: 'Trail / Incline Riding', child: Text('Trail / Incline Riding')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => cyclingMode = v);
                          },
                        ),
                      ]
                      // 5. GYM & WEIGHTS: Duration + Sets + Target Muscle (NO steps!)
                      else if (category == WorkoutMetricCategory.gym) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _numberInputField(
                                label: 'Duration (mins)',
                                controller: durationController,
                                suffix: 'mins',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _numberInputField(
                                label: 'Sets Completed',
                                controller: setsController,
                                suffix: 'sets',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Target Muscle Focus',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: targetMuscle,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12),
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'Full Body & Core', child: Text('Full Body & Core')),
                            DropdownMenuItem(value: 'Chest & Triceps', child: Text('Chest & Triceps')),
                            DropdownMenuItem(value: 'Back & Biceps', child: Text('Back & Biceps')),
                            DropdownMenuItem(value: 'Legs & Quads', child: Text('Legs & Lower Body')),
                            DropdownMenuItem(value: 'Shoulders & Traps', child: Text('Shoulders & Arms')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => targetMuscle = v);
                          },
                        ),
                      ]
                      // 6. YOGA: Duration + Rounds + Practice Style (NO steps!)
                      else if (category == WorkoutMetricCategory.yoga) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _numberInputField(
                                label: 'Duration (mins)',
                                controller: durationController,
                                suffix: 'mins',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _numberInputField(
                                label: 'Rounds / Asanas',
                                controller: roundsController,
                                suffix: 'rounds',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Practice Style',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: yogaStyle,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12),
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'Hatha Yoga & Asanas', child: Text('Hatha Yoga & Postures')),
                            DropdownMenuItem(value: 'Surya Namaskar (Sun Salutations)', child: Text('Surya Namaskar Series')),
                            DropdownMenuItem(value: 'Pranayama & Meditation', child: Text('Pranayama & Breathwork')),
                            DropdownMenuItem(value: 'Flexibility & Stretches', child: Text('Flexibility & Deep Stretches')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => yogaStyle = v);
                          },
                        ),
                      ]
                      // 7. BADMINTON: Duration + Games / Sets + Format (NO steps!)
                      else if (category == WorkoutMetricCategory.badminton) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _numberInputField(
                                label: 'Duration (mins)',
                                controller: durationController,
                                suffix: 'mins',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _numberInputField(
                                label: 'Sets / Games',
                                controller: setsController,
                                suffix: 'games',
                                onChanged: () => setDialogState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Match Format',
                          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: badmintonFormat,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12),
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'Doubles Rally Match', child: Text('Doubles Rally Match')),
                            DropdownMenuItem(value: 'Singles Competitive', child: Text('Singles Competitive')),
                            DropdownMenuItem(value: 'Casual Warmup Rally', child: Text('Casual Warmup Rally')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => badmintonFormat = v);
                          },
                        ),
                      ]
                      // 8. GENERAL / DEFAULT: Duration + Intensity
                      else ...[
                        _numberInputField(
                          label: 'Duration (mins)',
                          controller: durationController,
                          suffix: 'mins',
                          onChanged: () => setDialogState(() {}),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Session Intensity',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: intensity,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12.5),
                          decoration: _inputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'Light', child: Text('Light Pace')),
                            DropdownMenuItem(value: 'Moderate', child: Text('Moderate Pace')),
                            DropdownMenuItem(value: 'Vigorous', child: Text('Vigorous Pace')),
                          ],
                          onChanged: (v) {
                            if (v != null) setDialogState(() => intensity = v);
                          },
                        ),
                      ],
                      const SizedBox(height: 14),

                      // Optional workout notes
                      TextField(
                        controller: notesController,
                        style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Optional workout notes (e.g. morning park session)...',
                          hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Estimated Calories Burned Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEA580C), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ESTIMATED CALORIES BURNED',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF9A3412),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Calibrated with MET metabolic formula',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      color: const Color(0xFFC2410C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              flex: 0,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    calculatedKcal.toStringAsFixed(0),
                                    style: GoogleFonts.outfit(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFC2410C),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'kcal',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFEA580C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                              label: Text(
                                'Save Workout',
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.magentaPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 2,
                              ),
                              onPressed: () {
                                final d = int.tryParse(durationController.text) ?? 30;
                                final s = int.tryParse(stepsController.text) ?? 0;
                                final dist = double.tryParse(distanceController.text) ?? 0.0;
                                final l = int.tryParse(lapsController.text) ?? 0;
                                final st = int.tryParse(setsController.text) ?? 0;
                                final r = int.tryParse(roundsController.text) ?? 0;

                                String customMeta = '';
                                if (category == WorkoutMetricCategory.swimming) {
                                  customMeta = 'Stroke: $strokeStyle';
                                } else if (category == WorkoutMetricCategory.walking) {
                                  customMeta = 'Pace: $walkingPace';
                                } else if (category == WorkoutMetricCategory.running) {
                                  customMeta = 'Style: $runningStyle';
                                } else if (category == WorkoutMetricCategory.cycling) {
                                  customMeta = 'Mode: $cyclingMode';
                                } else if (category == WorkoutMetricCategory.gym) {
                                  customMeta = 'Focus: $targetMuscle';
                                } else if (category == WorkoutMetricCategory.yoga) {
                                  customMeta = 'Style: $yogaStyle';
                                } else if (category == WorkoutMetricCategory.badminton) {
                                  customMeta = 'Format: $badmintonFormat';
                                }

                                eco.addWorkoutLog(
                                  activityName: selectedActivity.name,
                                  durationMinutes: d,
                                  steps: (category == WorkoutMetricCategory.walking || category == WorkoutMetricCategory.running) ? s : 0,
                                  distanceKm: dist,
                                  caloriesBurned: calculatedKcal,
                                  intensity: intensity,
                                  timeAllocation: timeAllocation,
                                  logDate: _selectedDate,
                                  notes: notesController.text.trim(),
                                  laps: category == WorkoutMetricCategory.swimming ? l : 0,
                                  sets: (category == WorkoutMetricCategory.gym || category == WorkoutMetricCategory.badminton) ? st : 0,
                                  rounds: category == WorkoutMetricCategory.yoga ? r : 0,
                                  customMetric: customMeta,
                                );
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.burgundyPrimary,
                                    content: Text('Logged ${selectedActivity.name} (${d}m = ${calculatedKcal.toInt()} kcal) for ${_formatDayLabel(_selectedDate)}!'),
                                  ),
                                );
                              },
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
      },
    );
  }

  // -------------------------------------------------------------------------
  // GRID 3: WEIGHT / HEIGHT MODULE (Update whenever needed & View History)
  // -------------------------------------------------------------------------

  Widget _buildWeightHeightSection(BuildContext context, EcosystemProvider eco) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'UPDATE WEIGHT & HEIGHT',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.sandLight,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          'Update your weight and height whenever needed to recalibrate BMI',
          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandPrimary),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Height (cm)',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sandLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _updateHeightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.outfit(
                            color: AppColors.sandLight,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.burgundySurface,
                            prefixIcon: const Icon(Icons.height, size: 18, color: AppColors.sandGold),
                            suffixText: 'cm',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight (kg)',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sandLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _updateWeightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.outfit(
                            color: AppColors.sandLight,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppColors.burgundySurface,
                            prefixIcon: const Icon(Icons.monitor_weight_outlined, size: 18, color: AppColors.sandGold),
                            suffixText: 'kg',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  ActionChip(
                    label: const Text('-0.5 kg'),
                    backgroundColor: AppColors.burgundySurface,
                    labelStyle: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.sandGold),
                    onPressed: () {
                      final curW = double.tryParse(_updateWeightController.text) ?? eco.userWeightKg;
                      _updateWeightController.text = (curW - 0.5).clamp(20.0, 300.0).toStringAsFixed(1);
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    label: const Text('+0.5 kg'),
                    backgroundColor: AppColors.burgundySurface,
                    labelStyle: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.sandGold),
                    onPressed: () {
                      final curW = double.tryParse(_updateWeightController.text) ?? eco.userWeightKg;
                      _updateWeightController.text = (curW + 0.5).clamp(20.0, 300.0).toStringAsFixed(1);
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.sandGold,
                        foregroundColor: AppColors.burgundyBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      onPressed: () {
                        final h = double.tryParse(_updateHeightController.text) ?? eco.userHeightCm;
                        final w = double.tryParse(_updateWeightController.text) ?? eco.userWeightKg;
                        final metricError = EcosystemProvider.validateBodyMetrics(h, w);
                        if (metricError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(backgroundColor: AppColors.ragRed, content: Text(metricError)),
                          );
                          return;
                        }

                        eco.updateWeightAndHeight(heightCm: h, weightKg: w);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.burgundyPrimary,
                            content: Text('Updated metrics: ${w.toStringAsFixed(1)} kg, ${h.toStringAsFixed(0)} cm. BMI recalculated!'),
                          ),
                        );
                      },
                      child: Text(
                        'Save BMI',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'BIOMETRIC HISTORY LOG',
          style: GoogleFonts.outfit(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: AppColors.sandGold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        Column(
          children: eco.weightHistory.map((rec) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.burgundyCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sandBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, size: 16, color: AppColors.sandPrimary),
                      const SizedBox(width: 8),
                      Text(
                        rec.dateString,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.sandLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${rec.weightKg.toStringAsFixed(1)} kg • ${rec.heightCm.toStringAsFixed(0)} cm',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.sandPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.burgundySurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                    ),
                    child: Text(
                      'BMI ${rec.bmi.toStringAsFixed(1)}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // GRID 4: BMI MODULE (Live Calculation, WHO Spectrum & Ideal Range)
  // -------------------------------------------------------------------------

  Widget _buildBmiSection(BuildContext context, EcosystemProvider eco) {
    final bmi = eco.currentBmi;
    final cat = eco.bmiCategory;
    final minIdeal = eco.minIdealWeight;
    final maxIdeal = eco.maxIdealWeight;
    final userW = eco.userWeightKg;
    final color = eco.bmiColor;

    String advice;
    if (bmi < 18.5) {
      advice = 'You are currently underweight. Eating more nutritious food and protein is recommended.';
    } else if (bmi < 25.0) {
      advice = 'Great job! Your weight is in a healthy range. Keep drinking water and staying active.';
    } else if (bmi < 30.0) {
      advice = 'Slightly above healthy weight. A 30-minute daily walk and lighter meals can help.';
    } else {
      advice = 'Above healthy weight. Regular walking, healthy food and light exercise are recommended.';
    }

    // Position of the marker on a 15–35 scale.
    final markerPos = ((bmi.clamp(15.0, 35.0) - 15.0) / 20.0);
    const bands = [
      (15.0, 18.5, Color(0xFFFBBF24), 'Under'),
      (18.5, 25.0, Color(0xFF10B981), 'Healthy'),
      (25.0, 30.0, Color(0xFFF97316), 'Over'),
      (30.0, 35.0, Color(0xFFEF4444), 'Obese'),
    ];
    final toGo = userW > maxIdeal ? userW - maxIdeal : (userW < minIdeal ? minIdeal - userW : 0.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSectionHeader('Body mass index', subtitle: 'Weight (kg) ÷ height (m)², WHO ranges'),
        const SizedBox(height: 12),
        KitCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your BMI', style: kitBody(13)),
                        const SizedBox(height: 2),
                        Text(bmi > 0 ? bmi.toStringAsFixed(1) : '—', style: kitValue(44).copyWith(color: color)),
                      ],
                    ),
                  ),
                  KitPill(cat, color, icon: Icons.circle, solid: false),
                ],
              ),
              const SizedBox(height: 18),
              // Scale with marker
              LayoutBuilder(builder: (context, c) {
                final w = c.maxWidth;
                return Column(
                  children: [
                    SizedBox(
                      height: 22,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 7,
                            child: Row(
                              children: [
                                for (var i = 0; i < bands.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 3),
                                  Expanded(
                                    flex: ((bands[i].$2 - bands[i].$1) * 10).round(),
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: bands[i].$3,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (bmi > 0)
                            Positioned(
                              left: (w * markerPos - 11).clamp(0.0, w - 22),
                              top: 0,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color, width: 4),
                                  boxShadow: AppColors.softShadow,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var i = 0; i < bands.length; i++)
                          Expanded(
                            flex: ((bands[i].$2 - bands[i].$1) * 10).round(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bands[i].$4,
                                    style: GoogleFonts.outfit(
                                        fontSize: 11, fontWeight: FontWeight.w700, color: bands[i].$3)),
                                Text(
                                  i == 0 ? '<18.5' : (i == 3 ? '30+' : '${bands[i].$1}–${(bands[i].$2 - 0.1).toStringAsFixed(1)}'),
                                  style: GoogleFonts.outfit(fontSize: 10.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              KitMiniStatRow([
                KitMiniStat(
                  value: '${userW.toStringAsFixed(1)} kg',
                  label: 'Now',
                  color: color,
                  icon: Icons.monitor_weight_rounded,
                ),
                KitMiniStat(
                  value: '${minIdeal.toStringAsFixed(0)}–${maxIdeal.toStringAsFixed(0)} kg',
                  label: 'Healthy for ${eco.userHeightCm.toStringAsFixed(0)} cm',
                  color: const Color(0xFF10B981),
                  icon: Icons.verified_rounded,
                ),
                KitMiniStat(
                  value: toGo > 0 ? '${toGo.toStringAsFixed(1)} kg' : 'On target',
                  label: userW > maxIdeal ? 'To lose' : (userW < minIdeal && toGo > 0 ? 'To gain' : 'Keep it up'),
                  color: const Color(0xFF6366F1),
                  icon: Icons.flag_rounded,
                ),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.tips_and_updates_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(advice, style: kitBody(12.5).copyWith(color: AppColors.textDark))),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Update weight or height'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => setState(() => _selectedGridIndex = 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showRecalibrateConfirmDialog(BuildContext context, EcosystemProvider eco) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.sandGold),
          ),
          title: Text(
            'Recalibrate Health Profile?',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.sandLight),
          ),
          content: Text(
            'This will re-open the initial setup screen to re-enter your baseline height and weight.',
            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.sandPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.sandPrimary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sandGold,
                foregroundColor: AppColors.burgundyBg,
              ),
              onPressed: () {
                eco.resetHealthOnboarding();
                Navigator.pop(ctx);
              },
              child: const Text('Reset to Baseline Setup'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // HELPER MODALS: CALORIE TARGET, PEDOMETER PERMISSION, STEP RECORDING
  // =========================================================================

  void _showDailyCalorieTargetModal(BuildContext context, EcosystemProvider eco, {bool isFirstTime = false}) {
    final suggested = eco.suggestedDailyCalories;
    final currentTarget = eco.hasSetDailyCalorieTarget ? eco.dailyCalorieTarget : suggested;
    final targetCtrl = TextEditingController(text: currentTarget.toInt().toString());

    showDialog(
      context: context,
      barrierDismissible: !isFirstTime,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setDState) {
            final val = double.tryParse(targetCtrl.text) ?? currentTarget;
            return Dialog(
              backgroundColor: AppColors.burgundyCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: AppColors.sandGold, width: 1.4),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(22),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.burgundySurface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.sandGold),
                            ),
                            child: const Icon(Icons.local_fire_department, color: AppColors.sandGold, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isFirstTime ? 'SET DAILY CALORIE TARGET' : 'EDIT DAILY CALORIE GOAL',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandLight,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isFirstTime
                                      ? 'Calibrated from your height & weight'
                                      : 'Adjust your daily expected calorie intake',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    color: AppColors.sandPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isFirstTime)
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.sandPrimary, size: 20),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.sandBorder, height: 1),
                      const SizedBox(height: 14),

                      // Formula suggestion explanation
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.burgundySurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.sandBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.sandGold, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Based on your height (${eco.userHeightCm.toStringAsFixed(0)} cm) & weight (${eco.userWeightKg.toStringAsFixed(1)} kg), we suggest ${suggested.toInt()} kcal/day.',
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  color: AppColors.sandLight,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Target Calories (kcal/day)',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: targetCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(
                          color: AppColors.sandLight,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        onChanged: (_) => setDState(() {}),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.burgundySurface,
                          suffixText: 'kcal',
                          suffixStyle: const TextStyle(color: AppColors.sandGold, fontWeight: FontWeight.bold, fontSize: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.sandGold, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _calorieChip(
                            label: 'Suggested (${suggested.toInt()})',
                            isSelected: val.toInt() == suggested.toInt(),
                            onTap: () {
                              setDState(() {
                                targetCtrl.text = suggested.toInt().toString();
                              });
                            },
                          ),
                          _calorieChip(
                            label: 'Light Deficit (${(suggested - 250).toInt()})',
                            isSelected: val.toInt() == (suggested - 250).toInt(),
                            onTap: () {
                              setDState(() {
                                targetCtrl.text = (suggested - 250).toInt().toString();
                              });
                            },
                          ),
                          _calorieChip(
                            label: 'Active (${(suggested + 250).toInt()})',
                            isSelected: val.toInt() == (suggested + 250).toInt(),
                            onTap: () {
                              setDState(() {
                                targetCtrl.text = (suggested + 250).toInt().toString();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sandGold,
                          foregroundColor: AppColors.burgundyBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          final target = double.tryParse(targetCtrl.text) ?? suggested;
                          if (target < 800 || target > 6000) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: AppColors.burgundyPrimary,
                                content: Text('Please enter a realistic calorie target (800 - 6000 kcal).'),
                              ),
                            );
                            return;
                          }
                          eco.setDailyCalorieTarget(target);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.burgundyPrimary,
                              content: Text('Daily calorie target updated to ${target.toInt()} kcal!'),
                            ),
                          );
                        },
                        child: Text(
                          isFirstTime ? 'Save Target & Start Tracking' : 'Update Calorie Target',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _calorieChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sandGold : AppColors.burgundySurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.sandGold : AppColors.sandBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.burgundyBg : AppColors.sandLight,
          ),
        ),
      ),
    );
  }

  void _openStepCountRecordingDialog(BuildContext context, EcosystemProvider eco) {
    if (_isPastDate(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ragRed,
          content: Text('Cannot log steps for past dates. Previous dates are view only.'),
        ),
      );
      return;
    }
    final curSteps = eco.getStepsForDate(_selectedDate);
    final ctrl = TextEditingController(text: curSteps > 0 ? curSteps.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.sandGold),
          ),
          title: Text(
            'Record Steps for ${_formatDayLabel(_selectedDate)}',
            style: GoogleFonts.outfit(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.sandLight),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter total steps walked on this date:',
                style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.sandPrimary),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.burgundySurface,
                  suffixText: 'steps',
                  suffixStyle: const TextStyle(color: AppColors.sandGold),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.sandPrimary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sandGold,
                foregroundColor: AppColors.burgundyBg,
              ),
              onPressed: () async {
                final s = int.tryParse(ctrl.text.replaceAll(',', '').trim()) ?? 0;
                // Checkpoint: very high numbers are usually a typo.
                if (eco.isUnusualSteps(s)) {
                  final sure = await showDialog<bool>(
                    context: ctx,
                    builder: (c) => AlertDialog(
                      icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
                      title: const Text('That is a lot of steps'),
                      content: Text(
                        '${_fmtSteps(s)} steps is more than ${_fmtSteps(EcosystemProvider.unusualStepsPerDay)} in one day. '
                        'Is it correct? It will be marked "Unusually high".',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Fix it')),
                        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes, save')),
                      ],
                    ),
                  );
                  if (sure != true || !ctx.mounted) return;
                }
                eco.recordDailySteps(date: _selectedDate, steps: s);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.burgundyPrimary,
                    content: Text('Saved $s steps for ${_formatDayLabel(_selectedDate)}'),
                  ),
                );
              },
              child: const Text('Save Steps'),
            ),
          ],
        );
      },
    );
  }

  Widget _mealTypeButton({
    required String label,
    required String icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.sandGold : AppColors.burgundySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? AppColors.burgundyBg : AppColors.sandLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _portionOptionCard({
    required String label,
    required String sublabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.sandGold.withOpacity(0.18) : AppColors.burgundySurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              sublabel,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.sandGold : AppColors.sandLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: isSelected ? AppColors.sandLight : AppColors.sandPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberInputField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    bool isDecimal = false,
    required VoidCallback onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: isDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
          style: GoogleFonts.outfit(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600),
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    );
  }
}

/// Dedicated Screen to view employee health activities for CEO & HR
class EmployeeHealthActivitiesScreen extends StatefulWidget {
  const EmployeeHealthActivitiesScreen({super.key});

  @override
  State<EmployeeHealthActivitiesScreen> createState() => _EmployeeHealthActivitiesScreenState();
}

class _EmployeeHealthActivitiesScreenState extends State<EmployeeHealthActivitiesScreen> {
  String? _inspectedStaffId;
  Map<String, dynamic>? _inspectedHealthData;
  bool _isLoadingInspectedHealth = false;

  Future<void> _fetchInspectedStaffHealth(String empId, EcosystemProvider eco) async {
    setState(() {
      _inspectedStaffId = empId;
      _isLoadingInspectedHealth = true;
    });
    final res = await eco.loadEmployeePillarsForInspection(empId);
    if (mounted) {
      setState(() {
        _inspectedHealthData = res['health'] as Map<String, dynamic>?;
        _isLoadingInspectedHealth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final teamMembers = eco.employees.where((e) => !e.isCeo).toList();

    if (_inspectedStaffId == null && teamMembers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _inspectedStaffId == null) {
          _fetchInspectedStaffHealth(teamMembers.first.id, eco);
        }
      });
    }

    final selectedStaff = teamMembers.firstWhere(
      (e) => e.id == _inspectedStaffId,
      orElse: () => teamMembers.isNotEmpty ? teamMembers.first : eco.currentEmployee,
    );

    final health = _inspectedHealthData ?? {};
    final double hCm = (health['heightCm'] as num?)?.toDouble() ?? 0.0;
    final double wKg = (health['weightKg'] as num?)?.toDouble() ?? 0.0;
    final double liveBmi = (health['bmi'] as num?)?.toDouble() ?? 0.0;
    final String liveBmiCat = (health['bmiCategory'] as String?) ?? 'Not Calibrated';
    final double? calTarget = (health['dailyCalorieTarget'] as num?)?.toDouble();
    final double todayKcal = (health['todayCalories'] as num?)?.toDouble() ?? 0.0;
    final int stepGoal = (health['dailyStepGoal'] as num?)?.toInt() ?? 10000;
    final int todaySteps = (health['todaySteps'] as num?)?.toInt() ?? 0;
    final int workoutMins = (health['workoutMinutesToday'] as num?)?.toInt() ?? 0;
    final meals = (health['meals'] as List?)?.cast<FoodLogItem>() ?? <FoodLogItem>[];
    final workouts = (health['workouts'] as List?)?.cast<WorkoutLogItem>() ?? <WorkoutLogItem>[];

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: const MnAppBar(
        title: 'Staff Health',
        subtitle: 'Health activity logged by the team',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Employee Horizontal Selector
              Text(
                'SELECT EMPLOYEE',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sandGold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: teamMembers.map((emp) {
                    final isSel = emp.id == selectedStaff.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _fetchInspectedStaffHealth(emp.id, eco),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.magentaPrimary : AppColors.burgundySurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? AppColors.sandGold : AppColors.sandBorder,
                              width: isSel ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: isSel ? Colors.white : AppColors.sandGold.withOpacity(0.2),
                                child: Text(
                                  emp.initials,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? AppColors.magentaPrimary : AppColors.sandGold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                emp.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSel ? Colors.white : AppColors.sandLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Staff Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.magentaPrimary,
                      child: Text(
                        selectedStaff.initials,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedStaff.name,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                            ),
                          ),
                          Text(
                            selectedStaff.role.isNotEmpty ? selectedStaff.role : selectedStaff.dept,
                            style: GoogleFonts.outfit(fontSize: 11, color: AppColors.sandPrimary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Text(
                        calTarget != null && calTarget > 0 ? '${calTarget.toStringAsFixed(0)} kcal Target' : 'No Target Set',
                        style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (_isLoadingInspectedHealth)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.sandGold),
                  ),
                )
              else ...[
                // Metrics Grid (Calories, BMI, Steps, Exercise)
                Row(
                  children: [
                    Expanded(
                      child: _metricTile(
                        icon: Icons.local_fire_department_rounded,
                        title: 'CALORIES TODAY',
                        value: '${todayKcal.toInt()} kcal',
                        subText: calTarget != null ? 'Goal: ${calTarget.toInt()}' : 'No Goal Set',
                        accentColor: const Color(0xFFF97316),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricTile(
                        icon: Icons.monitor_weight_outlined,
                        title: 'BIOMETRIC BMI',
                        value: liveBmi > 0 ? liveBmi.toStringAsFixed(1) : 'Pending',
                        subText: (wKg > 0 && hCm > 0) ? '${wKg.toInt()}kg • ${hCm.toInt()}cm' : liveBmiCat,
                        accentColor: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _metricTile(
                        icon: Icons.directions_walk_rounded,
                        title: 'DAILY STEPS',
                        value: '$todaySteps steps',
                        subText: 'Target: $stepGoal',
                        accentColor: const Color(0xFF06B6D4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _metricTile(
                        icon: Icons.fitness_center_rounded,
                        title: 'EXERCISE TODAY',
                        value: '$workoutMins mins',
                        subText: '${workouts.length} workouts logged',
                        accentColor: const Color(0xFFBE185D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Logged Workouts & Exercises
                Text(
                  'LOGGED WORKOUTS & EXERCISES (${workouts.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sandGold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (workouts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.burgundyCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.sandBorder),
                    ),
                    child: Center(
                      child: Text(
                        'No workout sessions recorded yet by ${selectedStaff.name}.',
                        style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...workouts.map((w) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.burgundyCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: Row(
                        children: [
                          const Text('💪', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.activityName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandLight,
                                  ),
                                ),
                                Text(
                                  '${w.durationMinutes} mins • ${w.intensity} • ${w.caloriesBurned.toInt()} kcal • ${w.timeString}',
                                  style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 18),

                // Logged Meals & Food Intake
                Text(
                  'LOGGED MEALS & FOOD INTAKE (${meals.length})',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sandGold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (meals.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.burgundyCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.sandBorder),
                    ),
                    child: Center(
                      child: Text(
                        'No meal intake recorded yet by ${selectedStaff.name}.',
                        style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ...meals.map((m) {
                    final qtyDisplay = m.quantity != 1.0 ? 'Qty: ${m.quantity % 1 == 0 ? m.quantity.toInt() : m.quantity.toStringAsFixed(1)} • ' : '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.burgundyCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.sandBorder),
                      ),
                      child: Row(
                        children: [
                          const Text('🍽️', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.foodName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandLight,
                                  ),
                                ),
                                Text(
                                  '${m.mealType} • $qtyDisplay${m.portionSize} (${m.grams.toInt()}g) • ${m.timeString}',
                                  style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${m.calories.toInt()} kcal',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF97316),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricTile({
    required IconData icon,
    required String title,
    required String value,
    required String subText,
    required Color accentColor,
  }) {
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
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sandPrimary,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.sandLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subText,
            style: GoogleFonts.outfit(fontSize: 11, color: accentColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
