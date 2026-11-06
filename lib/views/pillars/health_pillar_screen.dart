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

  @override
  void initState() {
    super.initState();
    final eco = context.read<EcosystemProvider>();
    _updateHeightController.text = eco.userHeightCm > 0 ? eco.userHeightCm.toStringAsFixed(0) : '';
    _updateWeightController.text = eco.userWeightKg > 0 ? eco.userWeightKg.toStringAsFixed(1) : '';
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
          'HEALTH PILLAR',
          style: GoogleFonts.cinzel(
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
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
                      style: GoogleFonts.cinzel(
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
                      style: GoogleFonts.cinzel(
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
                                    style: GoogleFonts.cinzel(
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
          _buildDailySummaryBanner(eco),
          const SizedBox(height: 16),
          _buildTheFourGrids(eco),
          const SizedBox(height: 20),
          _buildActiveGridContent(context, eco),
        ],
      ),
    );
  }

  Widget _buildDailySummaryBanner(EcosystemProvider eco) {
    const targetCalories = 2000.0;
    final pctConsumed = (eco.totalCaloriesConsumed / targetCalories).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.burgundySurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                ),
                child: const Icon(Icons.favorite, color: AppColors.sandGold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Vitality Status • ${eco.currentEmployee.name}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Net Balance: ${eco.netCalories >= 0 ? '+' : ''}${eco.netCalories.toInt()} kcal (${eco.totalCaloriesConsumed.toInt()} in / ${eco.totalCaloriesBurned.toInt()} burned)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.sandPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pctConsumed,
              minHeight: 6,
              backgroundColor: AppColors.burgundySurface,
              valueColor: AlwaysStoppedAnimation<Color>(
                pctConsumed > 1.0 ? AppColors.ragYellow : AppColors.sandGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTheFourGrids(EcosystemProvider eco) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PILLAR 1 MODULES',
          style: GoogleFonts.cinzel(
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
              value: '${eco.totalCaloriesConsumed.toInt()} kcal',
              subtitle: '${eco.dailyFoodLogs.length} meals logged',
              icon: Icons.restaurant_menu,
              iconColor: const Color(0xFFF97316),
            ),
            _gridTile(
              index: 1,
              title: 'Workout',
              value: '${eco.totalWorkoutMinutes} mins',
              subtitle: '${eco.totalWorkoutSteps} steps • ${eco.totalCaloriesBurned.toInt()} kcal',
              icon: Icons.fitness_center,
              iconColor: const Color(0xFF10B981),
            ),
            _gridTile(
              index: 2,
              title: 'Weight / Height',
              value: eco.userWeightKg > 0 ? '${eco.userWeightKg.toStringAsFixed(1)} kg' : '0.0 kg',
              subtitle: eco.userHeightCm > 0 ? '${eco.userHeightCm.toStringAsFixed(0)} cm (tap to update)' : 'Need to be added',
              icon: Icons.straighten,
              iconColor: AppColors.sandGold,
            ),
            _gridTile(
              index: 3,
              title: 'BMI',
              value: eco.currentBmi > 0 ? eco.currentBmi.toStringAsFixed(1) : '0.0',
              subtitle: eco.bmiCategory,
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
          color: isSelected ? AppColors.burgundyPrimary : AppColors.burgundyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppColors.sandGold.withOpacity(0.12) : Colors.black.withOpacity(0.2),
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
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: iconColor.withOpacity(0.5)),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.sandGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
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
                    color: AppColors.sandLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.sandLight : AppColors.sandGold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    color: AppColors.sandPrimary,
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
                    style: GoogleFonts.cinzel(
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
                  selectedColor: AppColors.burgundyPrimary,
                  backgroundColor: AppColors.burgundySurface,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: isCatSelected ? FontWeight.bold : FontWeight.normal,
                    color: isCatSelected ? AppColors.sandGold : AppColors.sandPrimary,
                  ),
                  side: BorderSide(
                    color: isCatSelected ? AppColors.sandGold : AppColors.sandBorder,
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search, size: 30, color: AppColors.sandGold),
                        const SizedBox(height: 10),
                        Text(
                          'Type something...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Search for any dish, food or ingredient to view calories',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
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

        // Today's Food Log Diary
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "TODAY'S INTAKE DIARY (${eco.dailyFoodLogs.length})",
              style: GoogleFonts.cinzel(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.sandGold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Total: ${eco.totalCaloriesConsumed.toInt()} kcal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.sandLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (eco.dailyFoodLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Center(
              child: Text(
                'No meals logged yet today.\nSelect an item from the catalog above to add.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.sandPrimary),
              ),
            ),
          )
        else
          Column(
            children: eco.dailyFoodLogs.map((log) {
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
                            '${log.grams.toStringAsFixed(0)}g • ${log.timeString}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${log.calories.toStringAsFixed(0)} kcal',
                      style: GoogleFonts.cinzel(
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
    double grams = item.defaultServingGrams;
    String mealType = 'Breakfast';
    final gramsController = TextEditingController(text: grams.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final enteredGrams = double.tryParse(gramsController.text) ?? item.defaultServingGrams;
            final calculatedKcal = item.caloriesForGrams(enteredGrams);

            return Dialog(
              backgroundColor: AppColors.burgundyCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.sandGold, width: 1.2),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(item.iconEmoji, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.cinzel(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandLight,
                                ),
                              ),
                              Text(
                                'Baseline: ${item.caloriesPer100g.toStringAsFixed(0)} kcal per 100g',
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.sandBorder, height: 1),
                    const SizedBox(height: 14),

                    Text(
                      'Meal Timing',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sandLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: mealType,
                      isExpanded: true,
                      dropdownColor: AppColors.burgundySurface,
                      style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12.5),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.sandPrimary),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.burgundySurface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast (Morning)')),
                        DropdownMenuItem(value: 'Lunch', child: Text('Lunch (Mid-day)')),
                        DropdownMenuItem(value: 'Snacks', child: Text('Evening Snacks & Tea')),
                        DropdownMenuItem(value: 'Dinner', child: Text('Dinner (Night)')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => mealType = v);
                      },
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Intake Quantity / Weight (Grams)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.sandLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: gramsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.sandLight,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.burgundySurface,
                        suffixText: 'grams',
                        suffixStyle: const TextStyle(color: AppColors.sandPrimary, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      children: <double>{
                        item.defaultServingGrams,
                        item.defaultServingGrams * 2,
                        100.0,
                        150.0,
                        200.0,
                      }.map((g) {
                        return ActionChip(
                          label: Text('${g.toInt()}g'),
                          backgroundColor: AppColors.burgundySurface,
                          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.sandGold),
                          side: const BorderSide(color: AppColors.sandBorder),
                          onPressed: () {
                            setDialogState(() {
                              gramsController.text = g.toInt().toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.burgundySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Calculated Energy:',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.sandLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${calculatedKcal.toStringAsFixed(0)} kcal',
                            style: GoogleFonts.cinzel(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.plusJakartaSans(color: AppColors.sandPrimary, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sandGold,
                            foregroundColor: AppColors.burgundyBg,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            final g = double.tryParse(gramsController.text) ?? item.defaultServingGrams;
                            if (g <= 0) return;
                            eco.addFoodLog(
                              foodName: item.name,
                              mealType: mealType,
                              grams: g,
                              calories: item.caloriesForGrams(g),
                            );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.burgundyPrimary,
                                content: Text('Logged ${item.name} (${g.toInt()}g = ${item.caloriesForGrams(g).toInt()} kcal)'),
                              ),
                            );
                          },
                          child: Text(
                            'Add to Daily Intake',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
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
                  style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
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
                    style: GoogleFonts.cinzel(
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
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: WorkoutDatabase.activities.length,
            itemBuilder: (ctx, idx) {
              final act = WorkoutDatabase.activities[idx];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openRecordWorkoutDialog(context, eco, presetActivity: act),
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(10),
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
                        act.name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                        maxLines: 1,
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
              "TODAY'S WORKOUTS (${eco.dailyWorkoutLogs.length})",
              style: GoogleFonts.cinzel(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.sandGold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${eco.totalWorkoutMinutes}m • ${eco.totalWorkoutSteps} steps',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.sandLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (eco.dailyWorkoutLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Center(
              child: Text(
                'No workout sessions recorded yet today.\nTap "Record Session" above to add your activity.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.sandPrimary),
              ),
            ),
          )
        else
          Column(
            children: eco.dailyWorkoutLogs.map((w) {
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
                            '${w.durationMinutes} mins • ${w.steps > 0 ? '${w.steps} steps • ' : ''}${w.timeAllocation}',
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
                          style: GoogleFonts.cinzel(
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
    int stepCount = selectedActivity.name.contains('Walk') ? 3000 : 0;
    double distanceKm = selectedActivity.name.contains('Walk') ? 2.0 : 0.0;
    String intensity = 'Moderate';
    String timeAllocation = 'Morning (06:00 - 08:00)';
    final durationController = TextEditingController(text: durationMinutes.toString());
    final stepsController = TextEditingController(text: stepCount > 0 ? stepCount.toString() : '');
    final notesController = TextEditingController();

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

            return Dialog(
              backgroundColor: AppColors.burgundyCard,
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
                          Icon(selectedActivity.icon, color: AppColors.sandGold, size: 26),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Record Workout Session',
                                  style: GoogleFonts.cinzel(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandLight,
                                  ),
                                ),
                                Text(
                                  'MET formula calibrated for ${eco.userWeightKg.toStringAsFixed(1)} kg body weight',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.sandPrimary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.sandBorder, height: 1),
                      const SizedBox(height: 12),

                      Text(
                        'Activity Type',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sandLight,
                        ),
                      ),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<WorkoutActivityType>(
                        value: selectedActivity,
                        isExpanded: true,
                        dropdownColor: AppColors.burgundySurface,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12.5),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.sandPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.burgundySurface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: WorkoutDatabase.activities.map((act) {
                          return DropdownMenuItem(
                            value: act,
                            child: Text(act.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() {
                              selectedActivity = v;
                              if (v.name.contains('Walk') && stepsController.text.isEmpty) {
                                stepsController.text = '';
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Health Time Allocation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sandLight,
                        ),
                      ),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        value: timeAllocation,
                        isExpanded: true,
                        dropdownColor: AppColors.burgundySurface,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12.5),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.sandPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.burgundySurface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Morning (06:00 - 08:00)', child: Text('Morning Routine', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Afternoon Break', child: Text('Mid-day Break', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Post-Shift Evening', child: Text('Evening Routine', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Night Routine', child: Text('Night Routine', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => timeAllocation = v);
                        },
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Duration (mins)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.sandLight,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                TextField(
                                  controller: durationController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
                                  onChanged: (_) => setDialogState(() {}),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.burgundySurface,
                                    suffixText: 'm',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                Text(
                                  'Step Count',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.sandLight,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                TextField(
                                  controller: stepsController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 13),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.burgundySurface,
                                    hintText: 'e.g. 4000',
                                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                    suffixText: 'steps',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Session Intensity',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sandLight,
                        ),
                      ),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        value: intensity,
                        isExpanded: true,
                        dropdownColor: AppColors.burgundySurface,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12.5),
                        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.sandPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.burgundySurface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Light', child: Text('Light Pace', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Moderate', child: Text('Moderate Pace', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'Vigorous', child: Text('Vigorous Pace', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => intensity = v);
                        },
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: notesController,
                        style: GoogleFonts.plusJakartaSans(color: AppColors.sandLight, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Optional workout notes (e.g. brisk park loop)...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 11),
                          filled: true,
                          fillColor: AppColors.burgundySurface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.burgundySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimated Energy Burned:',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.sandLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${calculatedKcal.toStringAsFixed(0)} kcal',
                              style: GoogleFonts.cinzel(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF10B981),
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
                                side: const BorderSide(color: AppColors.sandBorder),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
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
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.sandGold,
                                foregroundColor: AppColors.burgundyBg,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 11),
                              ),
                              onPressed: () {
                              final d = int.tryParse(durationController.text) ?? 30;
                              final s = int.tryParse(stepsController.text) ?? 0;
                              eco.addWorkoutLog(
                                activityName: selectedActivity.name,
                                durationMinutes: d,
                                steps: s,
                                distanceKm: distanceKm,
                                caloriesBurned: selectedActivity.calculateCalories(
                                  weightKg: eco.userWeightKg,
                                  minutes: d,
                                ),
                                intensity: intensity,
                                timeAllocation: timeAllocation,
                                notes: notesController.text.trim(),
                              );
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.burgundyPrimary,
                                  content: Text('Logged ${selectedActivity.name} session (${d}m)!'),
                                ),
                              );
                            },
                            child: Text(
                              'Save Workout',
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
          style: GoogleFonts.cinzel(
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
          style: GoogleFonts.cinzel(
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
          style: GoogleFonts.cinzel(
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
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
                        style: GoogleFonts.cinzel(
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
            style: GoogleFonts.cinzel(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.sandLight),
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
}
