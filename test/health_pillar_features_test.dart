import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/models/health_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Health Pillar 1 - Calorie Target, Food Catalog, Workouts & Daily Steps Tests', () {
    late EcosystemProvider eco;

    setUp(() {
      eco = EcosystemProvider();
    });

    test('Calorie Target suggestion based on height and weight', () {
      eco.completeHealthOnboarding(heightCm: 175.0, weightKg: 70.0);
      expect(eco.hasSetDailyCalorieTarget, isFalse);

      final suggested = eco.suggestedDailyCalories;
      expect(suggested, greaterThanOrEqualTo(1800.0));
      expect(suggested, lessThanOrEqualTo(2500.0));

      // Setting daily calorie target stores in state
      eco.setDailyCalorieTarget(2100.0);
      expect(eco.hasSetDailyCalorieTarget, isTrue);
      expect(eco.dailyCalorieTarget, equals(2100.0));
    });

    test('Everyday Indian Food catalog priority and instant search', () {
      final teaResults = FoodDatabase.search('tea');
      expect(teaResults, isNotEmpty);
      expect(teaResults.first.name.toLowerCase().contains('tea') || teaResults.first.name.toLowerCase().contains('chai'), isTrue);

      final coffeeResults = FoodDatabase.search('coffee');
      expect(coffeeResults, isNotEmpty);
      expect(coffeeResults.first.name.toLowerCase().contains('coffee') || coffeeResults.first.name.toLowerCase().contains('kaapi'), isTrue);

      final idlyResults = FoodDatabase.search('idly');
      expect(idlyResults, isNotEmpty);
      expect(idlyResults.first.name.toLowerCase().contains('idly'), isTrue);

      final dosaResults = FoodDatabase.search('dosa');
      expect(dosaResults, isNotEmpty);
      expect(dosaResults.first.name.toLowerCase().contains('dosa'), isTrue);
    });

    test('Food logging with portion sizes, quantity stepper, and date filtering', () {
      final nov14 = DateTime(2026, 11, 14);
      final nov15 = DateTime(2026, 11, 15);

      // Log 2 cups of filter coffee on Nov 14 (150ml x 2 = 300g -> 210 kcal)
      eco.addFoodLog(
        foodName: 'Filter Coffee (South Indian Kaapi)',
        mealType: 'Breakfast',
        grams: 300.0,
        calories: 210.0,
        logDate: nov14,
        portionSize: 'Regular Cup (~150ml)',
        quantity: 2,
      );

      // Log 3 idlis on Nov 15 (150g -> 195 kcal)
      eco.addFoodLog(
        foodName: 'Steamed Idly (Traditional Rice Cake)',
        mealType: 'Breakfast',
        grams: 150.0,
        calories: 195.0,
        logDate: nov15,
        portionSize: 'Normal (~50g)',
        quantity: 3,
      );

      // Check Nov 14
      final logs14 = eco.getFoodLogsForDate(nov14);
      expect(logs14.length, equals(1));
      expect(logs14.first.foodName, contains('Filter Coffee'));
      expect(logs14.first.quantity, equals(2));
      expect(eco.getCaloriesConsumedForDate(nov14), equals(210.0));

      // Check Nov 15
      final logs15 = eco.getFoodLogsForDate(nov15);
      expect(logs15.length, equals(1));
      expect(logs15.first.foodName, contains('Idly'));
      expect(logs15.first.quantity, equals(3));
      expect(eco.getCaloriesConsumedForDate(nov15), equals(195.0));
    });

    test('Workout logging with activity-exclusive metrics (Swimming has NO steps)', () {
      final targetDate = DateTime(2026, 11, 14);

      // 1. Swimming: 20 laps, freestyle, duration 30 mins, 0 steps
      eco.addWorkoutLog(
        activityName: 'Swimming (Laps)',
        durationMinutes: 30,
        steps: 0,
        distanceKm: 0.0,
        caloriesBurned: 240.0,
        intensity: 'Moderate',
        timeAllocation: 'Morning Routine',
        logDate: targetDate,
        laps: 20,
        customMetric: 'Stroke: Freestyle / Crawl',
      );

      // 2. Brisk Walking: 3500 steps, duration 35 mins
      eco.addWorkoutLog(
        activityName: 'Brisk Walking',
        durationMinutes: 35,
        steps: 3500,
        distanceKm: 2.8,
        caloriesBurned: 160.0,
        intensity: 'Moderate',
        timeAllocation: 'Evening Routine',
        logDate: targetDate,
        customMetric: 'Pace: Moderate (5.0 km/h)',
      );

      final dateWorkouts = eco.getWorkoutLogsForDate(targetDate);
      expect(dateWorkouts.length, equals(2));

      final swim = dateWorkouts.firstWhere((w) => w.activityName.contains('Swim'));
      expect(swim.steps, equals(0)); // Crucial fix: NO steps for swimming!
      expect(swim.laps, equals(20));
      expect(swim.customMetric, contains('Freestyle'));

      final walk = dateWorkouts.firstWhere((w) => w.activityName.contains('Walk'));
      expect(walk.steps, equals(3500));
      expect(walk.laps, equals(0));

      expect(eco.getWorkoutMinutesForDate(targetDate), equals(65));
      expect(eco.getWorkoutStepsForDate(targetDate), equals(3500));
      expect(eco.getCaloriesBurnedForDate(targetDate), equals(400.0));
    });

    test('Daily Step Tracker recording and sensor permission workflow', () {
      final date = DateTime(2026, 11, 14);

      expect(eco.stepPermissionGranted, isFalse);
      expect(eco.getStepsForDate(date), equals(0));

      // User grants sensor permission
      eco.setStepPermissionGranted(true);
      expect(eco.stepPermissionGranted, isTrue);

      // Record steps for that date
      eco.recordDailySteps(date: date, steps: 7200);
      expect(eco.getStepsForDate(date), equals(7200));

      // Other date remains unaffected
      final otherDate = DateTime(2026, 11, 10);
      expect(eco.getStepsForDate(otherDate), equals(0));
    });
  });
}
