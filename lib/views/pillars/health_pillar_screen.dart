import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../models/health_models.dart';
import '../../providers/ecosystem_provider.dart';
import '../../services/food_api_service.dart';

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
      appBar: AppBar(
        backgroundColor: AppColors.burgundyBg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.sandPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'HEALTH PILLAR • DAILY',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.sandLight,
            letterSpacing: 0.8,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showRecalibrateConfirmDialog(context, eco),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh, size: 14, color: AppColors.sandGold),
                      const SizedBox(width: 4),
                      Text(
                        'Recalibrate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: eco.healthOnboarded
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
                      style: GoogleFonts.plusJakartaSans(
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
                      style: GoogleFonts.plusJakartaSans(
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
                      style: GoogleFonts.plusJakartaSans(
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.sandLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _initialHeightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.plusJakartaSans(
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.sandLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _initialWeightController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.plusJakartaSans(
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
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textMuted,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hasBoth ? liveBmi.toStringAsFixed(1) : '--',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.sandGold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
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
                                  style: GoogleFonts.plusJakartaSans(
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
                        if (heightVal <= 50 || weightVal <= 20) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.burgundyPrimary,
                              content: Text('Please enter valid height and weight values.'),
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
                            content: Text('Biometrics calibrated & stored successfully! Welcome to Pillar 1.'),
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

  Widget _buildMainDashboard(BuildContext context, EcosystemProvider eco) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCalorieTargetHeaderCard(context, eco),
          const SizedBox(height: 14),
          _buildHorizontalDateStrip(eco),
          const SizedBox(height: 14),
          _buildDailyStepTrackerCard(context, eco),
          const SizedBox(height: 16),
          _buildTheFourGrids(eco),
          const SizedBox(height: 20),
          _buildActiveGridContent(context, eco),
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
    final displayPct = (pctConsumed * 100).toInt();

    final Color progressColor;
    final String progressStatus;
    if (displayPct < 50) {
      progressColor = const Color(0xFF38BDF8); // Sky blue
      progressStatus = 'Intake Starting';
    } else if (displayPct <= 90) {
      progressColor = const Color(0xFF10B981); // Vibrant green
      progressStatus = 'On Track (Healthy)';
    } else if (displayPct <= 105) {
      progressColor = const Color(0xFFF59E0B); // Amber gold
      progressStatus = 'Target Reached';
    } else {
      progressColor = const Color(0xFFEF4444); // Red
      progressStatus = 'Over Target';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _showDailyCalorieTargetModal(context, eco, isFirstTime: false),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.burgundyCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.sandBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: progressColor.withOpacity(0.5)),
                  ),
                  child: Icon(Icons.local_fire_department, color: progressColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'DAILY CALORIE TARGET',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_outlined, size: 14, color: AppColors.sandGold),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatDayLabel(_selectedDate)} • $progressStatus • Tap to adjust target',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppColors.sandPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: progressColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    '$displayPct%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: progressColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${consumedKcal.toInt()}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.sandLight,
                      ),
                    ),
                    Text(
                      ' of ${targetKcal.toInt()} kcal',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sandPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${burnedKcal.toInt()} burned • ${netKcal >= 0 ? '+' : ''}${netKcal.toInt()} net',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sandGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pctConsumed.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.burgundySurface,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // HORIZONTAL DATE STRIP: CENTER DATE CAROUSEL WITH +/- 3 DAYS & MONTH NAV
  // =========================================================================

  Widget _buildHorizontalDateStrip(EcosystemProvider eco) {
    // Current center is _selectedDate: 3 days before and 3 days after [-3, -2, -1, 0, 1, 2, 3]
    final days = List.generate(7, (i) => _selectedDate.add(Duration(days: i - 3)));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.sandGold, size: 24),
                tooltip: 'Previous 7 Days',
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                  });
                },
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2025, 1, 1),
                    lastDate: DateTime(2027, 12, 31),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.sandGold,
                            onPrimary: AppColors.burgundyBg,
                            surface: AppColors.burgundyCard,
                            onSurface: AppColors.sandLight,
                          ),
                          dialogBackgroundColor: AppColors.burgundyCard,
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.sandGold, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${_months[_selectedDate.month - 1]} ${_selectedDate.year}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: AppColors.sandPrimary, size: 18),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isToday(_selectedDate))
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        setState(() {
                          _selectedDate = DateTime.now();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.burgundySurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Today',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: AppColors.sandGold, size: 24),
                    tooltip: 'Next 7 Days',
                    onPressed: () {
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 7));
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 7 Days centered strip: Tapping moves that date directly to the center
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((date) {
              final isSelected = _isSameDay(date, _selectedDate);
              final isCurrentToday = _isToday(date);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.magentaPrimary
                            : (isCurrentToday ? AppColors.burgundySurface : Colors.transparent),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.sandGold
                              : (isCurrentToday ? AppColors.sandGold.withOpacity(0.4) : AppColors.sandBorder.withOpacity(0.4)),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.magentaPrimary.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _weekdays[date.weekday - 1],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isCurrentToday ? AppColors.sandGold : AppColors.sandPrimary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date.day.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.sandLight,
                            ),
                          ),
                          if (isCurrentToday) ...[
                            const SizedBox(height: 2),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : AppColors.sandGold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // DAILY STEP COUNT TRACKER CARD & PHONE PEDOMETER PERMISSION
  // =========================================================================

  Widget _buildDailyStepTrackerCard(BuildContext context, EcosystemProvider eco) {
    final recordedSteps = eco.getStepsForDate(_selectedDate);
    final int stepGoal = eco.dailyStepGoal;
    final pct = (recordedSteps / stepGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: const Icon(Icons.directions_walk, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY STEP COUNT TRACKER',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatDayLabel(_selectedDate)} • Goal: $stepGoal steps',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandPrimary),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _openStepCountRecordingDialog(context, eco),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.sandGold.withOpacity(0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, size: 12, color: AppColors.sandGold),
                      const SizedBox(width: 4),
                      Text(
                        'Log Steps',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$recordedSteps steps',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.sandLight,
                ),
              ),
              Text(
                '${(pct * 100).toInt()}% of daily goal',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: pct >= 1.0 ? const Color(0xFF10B981) : AppColors.sandGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.burgundySurface,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 1.0 ? const Color(0xFF10B981) : AppColors.sandGold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // SEPARATE DEDICATED SECTION TO ADD / EDIT GOAL STEPS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.burgundySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sandGold.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.sandGold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.flag_rounded, size: 16, color: AppColors.sandGold),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY STEP TARGET GOAL',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sandGold,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '$stepGoal steps / day',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sandLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _openSetStepGoalDialog(context, eco),
                  icon: const Icon(Icons.tune, size: 13, color: AppColors.burgundyBg),
                  label: Text(
                    'Set Goal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.burgundyBg,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sandGold,
                    foregroundColor: AppColors.burgundyBg,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSetStepGoalDialog(BuildContext context, EcosystemProvider eco) {
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
                      style: GoogleFonts.plusJakartaSans(
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
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandPrimary),
                    ),
                    const SizedBox(height: 14),

                    // Quick Preset Chips
                    Text(
                      'QUICK PRESETS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.burgundySurface,
                        hintText: 'e.g. 7500',
                        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.sandPrimary.withOpacity(0.5)),
                        suffixText: 'steps / day',
                        suffixStyle: GoogleFonts.plusJakartaSans(color: AppColors.sandGold, fontSize: 11),
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
                    style: GoogleFonts.plusJakartaSans(color: AppColors.sandPrimary, fontSize: 12),
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
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
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
                    style: GoogleFonts.plusJakartaSans(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PILLAR 1 MODULES',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.sandGold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _gridTile(
              index: 0,
              title: 'Calories',
              value: '${dayConsumed.toInt()} kcal',
              subtitle: '${dayFoodLogs.length} meals • ${_formatDayShort(_selectedDate)}',
              icon: Icons.restaurant_menu,
              iconColor: const Color(0xFFF97316),
            ),
            _gridTile(
              index: 1,
              title: 'Workout',
              value: '$dayWorkoutMins mins',
              subtitle: '${dayWorkoutLogs.length} sessions • ${_formatDayShort(_selectedDate)}',
              icon: Icons.fitness_center,
              iconColor: const Color(0xFF10B981),
            ),
            _gridTile(
              index: 2,
              title: 'Weight / Height',
              value: eco.userWeightKg > 0 ? '${eco.userWeightKg.toStringAsFixed(1)} kg' : '0.0 kg',
              subtitle: eco.userHeightCm > 0 ? 'Occasional (${eco.userHeightCm.toStringAsFixed(0)} cm)' : 'Occasional Cadence',
              icon: Icons.straighten,
              iconColor: AppColors.sandGold,
            ),
            _gridTile(
              index: 3,
              title: 'BMI',
              value: eco.currentBmi > 0 ? eco.currentBmi.toStringAsFixed(1) : '0.0',
              subtitle: '${eco.bmiCategory} (Derived)',
              icon: Icons.speed,
              iconColor: eco.bmiColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _gridTile({
    required int index,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedGridIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _selectedGridIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.magentaPrimary : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.magentaPrimary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.magentaPrimary.withOpacity(0.25) : const Color(0x0A0F172A),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? Colors.white.withOpacity(0.4) : iconColor.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: isSelected ? Colors.white : iconColor, size: 18),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
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
                    style: GoogleFonts.plusJakartaSans(
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
                      Text(
                        'Public Open Food API Active • Global & Indian Dishes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppColors.sandPrimary,
                          fontWeight: FontWeight.w600,
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
            style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
            onChanged: _onFoodSearchChanged,
            decoration: InputDecoration(
              hintText: 'Type something to search food (e.g. Pizza, Dosa, Rice)...',
              hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 12),
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
                  labelStyle: GoogleFonts.plusJakartaSans(
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
                          Text(
                            'POPULAR EVERYDAY INDIAN FOODS & BEVERAGES',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandGold,
                              letterSpacing: 0.5,
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
                          return ListTile(
                            dense: true,
                            leading: Text(item.iconEmoji, style: const TextStyle(fontSize: 20)),
                            title: Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.sandLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${item.caloriesPer100g.toStringAsFixed(0)} kcal / 100g • ${item.servingUnit}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandGold,
                                ),
                              ),
                            ),
                            onTap: () => _openLogFoodDialog(context, eco, item),
                          );
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
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.sandPrimary),
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
                                        style: GoogleFonts.plusJakartaSans(
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

                    return ListTile(
                      dense: true,
                      leading: Text(item.iconEmoji, style: const TextStyle(fontSize: 20)),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
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
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.5,
                                  color: AppColors.sandGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${item.caloriesPer100g.toStringAsFixed(0)} kcal / 100g • ${item.servingUnit}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                          ),
                        ),
                      ),
                      onTap: () => _openLogFoodDialog(context, eco, item),
                    );
                  },
                ),
        ),
        const SizedBox(height: 18),

        // Selected Date's Food Log Diary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "INTAKE DIARY • ${_formatDayLabel(_selectedDate).toUpperCase()} (${selectedDateLogs.length})",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.sandGold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Total: ${selectedDateCalories.toInt()} kcal',
              style: GoogleFonts.plusJakartaSans(
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
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.sandPrimary),
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.sandLight,
                            ),
                          ),
                          Text(
                            '${log.portionSize} • ${log.quantity > 1 ? 'Qty: ${log.quantity} • ' : ''}${log.grams.toStringAsFixed(0)}g • ${log.timeString}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${log.calories.toStringAsFixed(0)} kcal',
                      style: GoogleFonts.plusJakartaSans(
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
    final hour = DateTime.now().hour;
    String selectedMealType = (hour < 11)
        ? 'Breakfast'
        : (hour < 16)
            ? 'Lunch'
            : (hour < 19)
                ? 'Snack'
                : 'Dinner';

    String selectedPortion = 'Normal';
    int quantity = 1;

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
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.caloriesPer100g.toStringAsFixed(0)} kcal / 100g • ${item.category}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandPrimary),
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
                        style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(
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
                        padding: const EdgeInsets.all(12),
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
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.sandGold,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$portionLabel x $quantity = ${totalGrams.toInt()}g total',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: AppColors.sandPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    icon: const Icon(Icons.remove, size: 16, color: AppColors.sandGold),
                                    onPressed: quantity > 1
                                        ? () => setDialogState(() => quantity--)
                                        : null,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text(
                                      quantity.toString(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.sandLight,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    icon: const Icon(Icons.add, size: 16, color: AppColors.sandGold),
                                    onPressed: () => setDialogState(() => quantity++),
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
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandGold,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${totalGrams.toInt()}g • $selectedMealType',
                                  style: GoogleFonts.plusJakartaSans(
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
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.sandGold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'kcal',
                                  style: GoogleFonts.plusJakartaSans(
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
                                style: GoogleFonts.plusJakartaSans(color: AppColors.sandPrimary, fontSize: 12),
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
                                style: GoogleFonts.plusJakartaSans(
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.burgundyPrimary,
                                    content: Text('Logged $quantity x ${item.name} (${calculatedKcal.toInt()} kcal) for ${_formatDayLabel(_selectedDate)}'),
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
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
                        style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
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
                        style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
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
                        final g = double.tryParse(gramsCtrl.text) ?? 100.0;
                        final kcal = double.tryParse(kcalCtrl.text) ?? 150.0;
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
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Track steps, walk duration & stamina allocations',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandPrimary),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Record Session',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.sandGold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${selectedDateWorkoutMins}m • $selectedDateWorkoutSteps steps',
              style: GoogleFonts.plusJakartaSans(
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
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.sandPrimary),
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
                                style: GoogleFonts.plusJakartaSans(
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
                                  style: const TextStyle(fontSize: 9, color: AppColors.sandPrimary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${w.durationMinutes} mins • ${w.laps > 0 ? '${w.laps} laps • ' : ''}${w.sets > 0 ? '${w.sets} sets • ' : ''}${w.rounds > 0 ? '${w.rounds} rounds • ' : ''}${w.steps > 0 ? '${w.steps} steps • ' : ''}${w.distanceKm > 0 ? '${w.distanceKm.toStringAsFixed(1)} km • ' : ''}${w.customMetric.isNotEmpty ? '${w.customMetric} • ' : ''}${w.timeAllocation}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                          ),
                          if (w.notes.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                w.notes,
                                style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.sandPrimary),
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
                          style: GoogleFonts.plusJakartaSans(
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
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'MET formula calibrated for ${eco.userWeightKg.toStringAsFixed(1)} kg body weight',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
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
                        style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 12.5),
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
                        style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 12.5),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: strokeStyle,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 12),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: walkingPace,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 12),
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
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 5),
                                  DropdownButtonFormField<String>(
                                    value: runningStyle,
                                    isExpanded: true,
                                    dropdownColor: AppColors.pureWhite,
                                    style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 12),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: cyclingMode,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 12),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: targetMuscle,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 12),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: yogaStyle,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 12),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 5),
                        DropdownButtonFormField<String>(
                          value: badmintonFormat,
                          isExpanded: true,
                          dropdownColor: AppColors.pureWhite,
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 12),
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
                          style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 12.5),
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
                        style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Optional workout notes (e.g. morning park session)...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11),
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
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF9A3412),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Calibrated with MET metabolic formula',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
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
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFC2410C),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'kcal',
                                    style: GoogleFonts.plusJakartaSans(
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
                                style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
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
                                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.sandLight,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          'Update your weight and height whenever needed to recalibrate BMI',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandPrimary),
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sandLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _updateHeightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.sandLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _updateWeightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.plusJakartaSans(
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
                    labelStyle: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.sandGold),
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
                    labelStyle: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.sandGold),
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
                        if (h <= 50 || w <= 20) return;

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
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
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
          style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.sandLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${rec.weightKg.toStringAsFixed(1)} kg • ${rec.heightCm.toStringAsFixed(0)} cm',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.sandPrimary),
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
                      style: GoogleFonts.plusJakartaSans(
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

    String advice;
    if (bmi < 18.5) {
      advice = 'You are currently underweight. Eating more nutritious food and protein is recommended.';
    } else if (bmi < 25.0) {
      advice = 'Great job! Your weight and health are in a healthy range. Keep drinking water and staying active.';
    } else if (bmi < 30.0) {
      advice = 'Slightly above healthy weight. A 30-minute daily walk and lighter meals can help.';
    } else {
      advice = 'Above healthy weight. Regular daily walking, healthy foods, and light exercise are recommended.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'BODY MASS INDEX (BMI) ANALYTICS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.sandLight,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          'Calculated using standard World Health Organization formula: Weight (kg) / Height (m)²',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandPrimary),
        ),
        const SizedBox(height: 14),

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT BMI SCORE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bmi.toStringAsFixed(1),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: eco.bmiColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: eco.bmiColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: eco.bmiColor,
                          ),
                        ),
                        Text(
                          'WHO Standard',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: eco.bmiColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 18,
                        child: Container(
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFBBF24),
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: 65,
                        child: Container(
                          height: 8,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: 50,
                        child: Container(
                          height: 8,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: 40,
                        child: Container(
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('<18.5 Underweight', style: GoogleFonts.plusJakartaSans(fontSize: 8.5, color: AppColors.textMuted)),
                      Text('18.5 - 24.9 Normal', style: GoogleFonts.plusJakartaSans(fontSize: 8.5, color: const Color(0xFF10B981))),
                      Text('25 - 29.9 Overweight', style: GoogleFonts.plusJakartaSans(fontSize: 8.5, color: AppColors.textMuted)),
                      Text('≥30 Obese', style: GoogleFonts.plusJakartaSans(fontSize: 8.5, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.sandBorder, height: 1),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: AppColors.sandGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Current: ${userW.toStringAsFixed(1)} kg • Ideal for ${eco.userHeightCm.toStringAsFixed(0)} cm: ${minIdeal.toStringAsFixed(1)} kg – ${maxIdeal.toStringAsFixed(1)} kg',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.sandLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.sandPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      advice,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.sandPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          icon: const Icon(Icons.edit, size: 16, color: AppColors.sandGold),
          label: Text(
            'Adjust Weight / Height to Recalculate',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.sandGold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.sandGold),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () {
            setState(() {
              _selectedGridIndex = 2;
            });
          },
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
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.sandLight),
          ),
          content: Text(
            'This will re-open the initial setup screen to re-enter your baseline height and weight.',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.sandPrimary),
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
                                  style: GoogleFonts.plusJakartaSans(
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
                                  style: GoogleFonts.plusJakartaSans(
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
                                style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: targetCtrl,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.burgundyBg : AppColors.sandLight,
          ),
        ),
      ),
    );
  }

  void _openStepCountRecordingDialog(BuildContext context, EcosystemProvider eco) {
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
            style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.sandLight),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter total steps walked on this date:',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.sandPrimary),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.sandLight),
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
              onPressed: () {
                final s = int.tryParse(ctrl.text) ?? 0;
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.sandGold : AppColors.sandLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
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
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: isDecimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
          style: GoogleFonts.plusJakartaSans(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600),
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
