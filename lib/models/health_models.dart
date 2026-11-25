import 'package:flutter/material.dart';
import 'tamil_indian_foods.dart';

/// Pre-configured nutritional food item with calories per 100g
class FoodItem {
  final String id;
  final String name;
  final String category; // 'Breakfast', 'Main Course', 'Lentils & Curries', 'Dairy & Sides', 'Snacks & Beverages', 'Fruits & Healthy'
  final double caloriesPer100g;
  final double defaultServingGrams;
  final String servingUnit; // e.g. 'piece (50g)', 'medium dosa (100g)', 'bowl (150g)', 'cup (200ml)'
  final String iconEmoji;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.defaultServingGrams,
    required this.servingUnit,
    this.iconEmoji = '🍽️',
  });

  bool get isBeverage =>
      category == 'Snacks & Beverages' ||
      name.toLowerCase().contains('tea') ||
      name.toLowerCase().contains('coffee') ||
      name.toLowerCase().contains('chai') ||
      name.toLowerCase().contains('kaapi') ||
      name.toLowerCase().contains('juice') ||
      name.toLowerCase().contains('milk') ||
      name.toLowerCase().contains('lassi') ||
      name.toLowerCase().contains('mor') ||
      name.toLowerCase().contains('water');

  double get smallPortionGrams => isBeverage ? 100.0 : defaultServingGrams * 0.7;
  double get normalPortionGrams => isBeverage ? 150.0 : defaultServingGrams;
  double get bigPortionGrams => isBeverage ? 250.0 : defaultServingGrams * 1.4;

  String get smallPortionLabel => isBeverage ? 'Small Cup (~100ml)' : 'Small (~${smallPortionGrams.toInt()}g)';
  String get normalPortionLabel => isBeverage ? 'Regular Cup (~150ml)' : 'Normal (~${normalPortionGrams.toInt()}g)';
  String get bigPortionLabel => isBeverage ? 'Mug / Glass (~250ml)' : 'Big / Large (~${bigPortionGrams.toInt()}g)';

  double caloriesForGrams(double grams) {
    return (grams / 100.0) * caloriesPer100g;
  }
}

/// Food entry logged by user in their daily intake
class FoodLogItem {
  final String id;
  final String foodName;
  final String mealType; // 'Breakfast', 'Lunch', 'Snack', 'Dinner'
  final double grams;
  final double calories;
  final DateTime timestamp;
  final String timeString;
  final String portionSize; // 'Small', 'Normal', 'Big', 'Cup', 'Mug'
  final double quantity; // 0.5, 1.0, 1.5, 2.0...

  FoodLogItem({
    required this.id,
    required this.foodName,
    required this.mealType,
    required this.grams,
    required this.calories,
    required this.timestamp,
    required this.timeString,
    this.portionSize = 'Normal',
    this.quantity = 1.0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'foodName': foodName,
    'mealType': mealType,
    'grams': grams,
    'calories': calories,
    'timestamp': timestamp.toIso8601String(),
    'timeString': timeString,
    'portionSize': portionSize,
    'quantity': quantity,
  };

  factory FoodLogItem.fromMap(Map<String, dynamic> map) => FoodLogItem(
    id: map['id'] ?? '',
    foodName: map['foodName'] ?? '',
    mealType: map['mealType'] ?? 'Lunch',
    grams: (map['grams'] as num?)?.toDouble() ?? 100.0,
    calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
    timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) ?? DateTime.now() : DateTime.now(),
    timeString: map['timeString'] ?? '',
    portionSize: map['portionSize'] ?? 'Normal',
    quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
  );
}

/// Workout session entry logged by user
class WorkoutLogItem {
  final String id;
  final String activityName; // 'Brisk Walk', 'Jogging / Running', 'Cycling', 'Gym / Weights', 'Yoga / Pranayama', 'Swimming', 'Badminton'
  final int durationMinutes;
  final int steps;
  final double distanceKm;
  final double caloriesBurned;
  final String intensity; // 'Light', 'Moderate', 'Vigorous'
  final String timeAllocation; // 'Morning (06:00 - 08:00)', 'Afternoon Break', 'Post-Shift Evening', 'Night'
  final DateTime timestamp;
  final String timeString;
  final String notes;
  final int laps;
  final int sets;
  final int rounds;
  final String customMetric;

  WorkoutLogItem({
    required this.id,
    required this.activityName,
    required this.durationMinutes,
    required this.steps,
    required this.distanceKm,
    required this.caloriesBurned,
    required this.intensity,
    required this.timeAllocation,
    required this.timestamp,
    required this.timeString,
    this.notes = '',
    this.laps = 0,
    this.sets = 0,
    this.rounds = 0,
    this.customMetric = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'activityName': activityName,
    'durationMinutes': durationMinutes,
    'steps': steps,
    'distanceKm': distanceKm,
    'caloriesBurned': caloriesBurned,
    'intensity': intensity,
    'timeAllocation': timeAllocation,
    'timestamp': timestamp.toIso8601String(),
    'timeString': timeString,
    'notes': notes,
    'laps': laps,
    'sets': sets,
    'rounds': rounds,
    'customMetric': customMetric,
  };

  factory WorkoutLogItem.fromMap(Map<String, dynamic> map) => WorkoutLogItem(
    id: map['id'] ?? '',
    activityName: map['activityName'] ?? '',
    durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 30,
    steps: (map['steps'] as num?)?.toInt() ?? 0,
    distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
    caloriesBurned: (map['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
    intensity: map['intensity'] ?? 'Moderate',
    timeAllocation: map['timeAllocation'] ?? 'Morning',
    timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) ?? DateTime.now() : DateTime.now(),
    timeString: map['timeString'] ?? '',
    notes: map['notes'] ?? '',
    laps: (map['laps'] as num?)?.toInt() ?? 0,
    sets: (map['sets'] as num?)?.toInt() ?? 0,
    rounds: (map['rounds'] as num?)?.toInt() ?? 0,
    customMetric: map['customMetric'] ?? '',
  );
}

/// Weight and Height historical record
class WeightHeightRecord {
  final double weightKg;
  final double heightCm;
  final double bmi;
  final DateTime date;
  final String dateString;

  WeightHeightRecord({
    required this.weightKg,
    required this.heightCm,
    required this.bmi,
    required this.date,
    required this.dateString,
  });
}

/// Standardized Indian and Global Food Database
class FoodDatabase {
  static const List<FoodItem> catalog = [
    // =========================================================================
    // 1. EVERYDAY INDIAN STAPLES, TIFFINS, TEA & COFFEE (PRIORITY #1)
    // =========================================================================
    FoodItem(
      id: 'food_ind_chai_1',
      name: 'Tea / Masala Chai (Hot Milk Tea)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 60.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup (~150ml = 90 kcal)',
      iconEmoji: '☕',
    ),
    FoodItem(
      id: 'food_ind_coffee_1',
      name: 'Filter Coffee (South Indian Kaapi)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 70.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup (~150ml = 105 kcal)',
      iconEmoji: '☕',
    ),
    FoodItem(
      id: 'food_ind_chai_ginger',
      name: 'Ginger Cardamom Tea (Adrak Chai)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 58.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup (~150ml = 87 kcal)',
      iconEmoji: '🫖',
    ),
    FoodItem(
      id: 'food_ind_greentea',
      name: 'Green Tea / Black Tea (Zero Sugar)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 1.5,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup (~150ml = 2 kcal)',
      iconEmoji: '🍵',
    ),
    FoodItem(
      id: 'food_ind_blackcoffee',
      name: 'Black Coffee / Americano (No Sugar)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 2.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup (~150ml = 3 kcal)',
      iconEmoji: '☕',
    ),
    FoodItem(
      id: 'food_ind_coldcoffee',
      name: 'Cold Coffee (with Chilled Milk)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 75.0,
      defaultServingGrams: 250.0,
      servingUnit: '1 glass (~250ml = 188 kcal)',
      iconEmoji: '🧋',
    ),
    FoodItem(
      id: 'food_ind_idly',
      name: 'Idly (Steamed Rice & Urad Dal)',
      category: 'Breakfast',
      caloriesPer100g: 140.0,
      defaultServingGrams: 50.0,
      servingUnit: '1 normal idly (~50g = 70 kcal)',
      iconEmoji: '⚪',
    ),
    FoodItem(
      id: 'food_ind_plain_dosa',
      name: 'Plain Dosa (Crispy Golden Dosa)',
      category: 'Breakfast',
      caloriesPer100g: 165.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 medium dosa (~100g = 165 kcal)',
      iconEmoji: '🥞',
    ),
    FoodItem(
      id: 'food_ind_masala_dosa',
      name: 'Masala Dosa (with Potato Masala)',
      category: 'Breakfast',
      caloriesPer100g: 220.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 masala dosa (~150g = 330 kcal)',
      iconEmoji: '🌯',
    ),
    FoodItem(
      id: 'food_ind_ghee_dosa',
      name: 'Ghee Roast Dosa (Crispy Ney Roast)',
      category: 'Breakfast',
      caloriesPer100g: 250.0,
      defaultServingGrams: 120.0,
      servingUnit: '1 dosa (~120g = 300 kcal)',
      iconEmoji: '🥞',
    ),
    FoodItem(
      id: 'food_ind_rava_dosa',
      name: 'Onion Rava Dosa',
      category: 'Breakfast',
      caloriesPer100g: 210.0,
      defaultServingGrams: 130.0,
      servingUnit: '1 dosa (~130g = 273 kcal)',
      iconEmoji: '🥞',
    ),
    FoodItem(
      id: 'food_ind_vada',
      name: 'Medu Vada (Crispy Lentil Fritter)',
      category: 'Breakfast',
      caloriesPer100g: 290.0,
      defaultServingGrams: 50.0,
      servingUnit: '1 vada (~50g = 145 kcal)',
      iconEmoji: '🍩',
    ),
    FoodItem(
      id: 'food_ind_pongal',
      name: 'Ven Pongal (Ghee & Cashew Pongal)',
      category: 'Breakfast',
      caloriesPer100g: 160.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 240 kcal)',
      iconEmoji: '🍲',
    ),
    FoodItem(
      id: 'food_ind_poori',
      name: 'Poori with Potato Masala (Aloo Bhaji)',
      category: 'Breakfast',
      caloriesPer100g: 295.0,
      defaultServingGrams: 40.0,
      servingUnit: '1 poori (~40g = 118 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_ind_chapati',
      name: 'Chapati / Phulka (Whole Wheat Roti)',
      category: 'Main Course',
      caloriesPer100g: 275.0,
      defaultServingGrams: 40.0,
      servingUnit: '1 chapati (~40g = 110 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_ind_parotta',
      name: 'Parotta (Malabar Layered Flatbread)',
      category: 'Main Course',
      caloriesPer100g: 325.0,
      defaultServingGrams: 80.0,
      servingUnit: '1 parotta (~80g = 260 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_ind_upma',
      name: 'Rava Upma (Semolina & Vegetables)',
      category: 'Breakfast',
      caloriesPer100g: 140.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 210 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_ind_meals_thali',
      name: 'South Indian Full Meals (Thali with Rice, Sambar, Rasam, Curd)',
      category: 'Main Course',
      caloriesPer100g: 130.0,
      defaultServingGrams: 500.0,
      servingUnit: '1 full meal (~500g = 650 kcal)',
      iconEmoji: '🍱',
    ),
    FoodItem(
      id: 'food_ind_white_rice',
      name: 'Steamed White Rice (Ponni / Sona Masoori)',
      category: 'Main Course',
      caloriesPer100g: 130.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup cooked (~150g = 195 kcal)',
      iconEmoji: '🍚',
    ),
    FoodItem(
      id: 'food_ind_sambar_rice',
      name: 'Sambar Rice (Bisibelebath style)',
      category: 'Main Course',
      caloriesPer100g: 145.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 plate (~200g = 290 kcal)',
      iconEmoji: '🍛',
    ),
    FoodItem(
      id: 'food_ind_curd_rice',
      name: 'Curd Rice (Thayir Sadam with Mustard Seasoning)',
      category: 'Main Course',
      caloriesPer100g: 135.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 bowl (~200g = 270 kcal)',
      iconEmoji: '🍚',
    ),
    FoodItem(
      id: 'food_ind_lemon_rice',
      name: 'Lemon Rice (Elumichai Sadam)',
      category: 'Main Course',
      caloriesPer100g: 155.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 bowl (~200g = 310 kcal)',
      iconEmoji: '🍋',
    ),
    FoodItem(
      id: 'food_ind_chicken_biryani',
      name: 'Chicken Biryani (Seeraga Samba / Basmati)',
      category: 'Main Course',
      caloriesPer100g: 175.0,
      defaultServingGrams: 300.0,
      servingUnit: '1 portion (~300g = 525 kcal)',
      iconEmoji: '🍗',
    ),
    FoodItem(
      id: 'food_ind_mutton_biryani',
      name: 'Mutton Biryani',
      category: 'Main Course',
      caloriesPer100g: 200.0,
      defaultServingGrams: 300.0,
      servingUnit: '1 portion (~300g = 600 kcal)',
      iconEmoji: '🥩',
    ),
    FoodItem(
      id: 'food_ind_veg_biryani',
      name: 'Veg Dum Biryani (with Paneer & Vegetables)',
      category: 'Main Course',
      caloriesPer100g: 145.0,
      defaultServingGrams: 300.0,
      servingUnit: '1 portion (~300g = 435 kcal)',
      iconEmoji: '🍲',
    ),
    FoodItem(
      id: 'food_ind_sambar',
      name: 'Vegetable Sambar (Toor Dal, Drumstick, Veggies)',
      category: 'Lentils & Curries',
      caloriesPer100g: 65.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup (~150g = 98 kcal)',
      iconEmoji: '🍲',
    ),
    FoodItem(
      id: 'food_ind_rasam',
      name: 'Pepper Garlic Rasam',
      category: 'Lentils & Curries',
      caloriesPer100g: 30.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup (~150g = 45 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_ind_chutney_coconut',
      name: 'Coconut Chutney (Fresh Grated Coconut)',
      category: 'Dairy & Sides',
      caloriesPer100g: 220.0,
      defaultServingGrams: 40.0,
      servingUnit: '2 tbsp (~40g = 88 kcal)',
      iconEmoji: '🥥',
    ),
    FoodItem(
      id: 'food_ind_chutney_tomato',
      name: 'Tomato Kara Chutney',
      category: 'Dairy & Sides',
      caloriesPer100g: 115.0,
      defaultServingGrams: 40.0,
      servingUnit: '2 tbsp (~40g = 46 kcal)',
      iconEmoji: '🍅',
    ),
    FoodItem(
      id: 'food_ind_paneer_curry',
      name: 'Paneer Butter Masala',
      category: 'Lentils & Curries',
      caloriesPer100g: 215.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 323 kcal)',
      iconEmoji: '🧀',
    ),
    FoodItem(
      id: 'food_ind_chicken_curry',
      name: 'Chettinad Chicken Curry',
      category: 'Main Course',
      caloriesPer100g: 170.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 255 kcal)',
      iconEmoji: '🍗',
    ),
    FoodItem(
      id: 'food_ind_dal_tadka',
      name: 'Dal Tadka (Yellow Lentils with Cumin Tadka)',
      category: 'Lentils & Curries',
      caloriesPer100g: 110.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 165 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_ind_buttermilk',
      name: 'Spiced Buttermilk (Neer Mor with Ginger & Curry Leaves)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 20.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 glass (~200ml = 40 kcal)',
      iconEmoji: '🥛',
    ),
    FoodItem(
      id: 'food_ind_lassi',
      name: 'Sweet Lassi (Chilled Yogurt Drink)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 85.0,
      defaultServingGrams: 250.0,
      servingUnit: '1 glass (~250ml = 213 kcal)',
      iconEmoji: '🥛',
    ),
    FoodItem(
      id: 'food_ind_orange_juice',
      name: 'Fresh Orange / Mosambi Juice (No Added Sugar)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 45.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 glass (~200ml = 90 kcal)',
      iconEmoji: '🍊',
    ),
    FoodItem(
      id: 'food_ind_samosa',
      name: 'Samosa (Spiced Potato Pastry)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 280.0,
      defaultServingGrams: 75.0,
      servingUnit: '1 piece (~75g = 210 kcal)',
      iconEmoji: '🥟',
    ),
    FoodItem(
      id: 'food_ind_bajji',
      name: 'Onion Pakoda / Mirchi Bajji',
      category: 'Snacks & Beverages',
      caloriesPer100g: 310.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 small plate (~100g = 310 kcal)',
      iconEmoji: '🧅',
    ),
    FoodItem(
      id: 'food_ind_sundal',
      name: 'Sundal (Boiled Chickpeas with Coconut Seasoning)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 140.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 cup (~100g = 140 kcal)',
      iconEmoji: '🧆',
    ),

    // =========================================================================
    // 2. FAST FOOD, PIZZAS, BURGERS & GLOBAL FAVORITES
    // =========================================================================
    FoodItem(
      id: 'food_pizza_1',
      name: 'Margherita Pizza (Cheese & Tomato)',
      category: 'Fast Food & Global',
      caloriesPer100g: 266.0,
      defaultServingGrams: 107.0,
      servingUnit: '1 regular slice (~107g = 285 kcal)',
      iconEmoji: '🍕',
    ),
    FoodItem(
      id: 'food_pizza_2',
      name: 'Veggie Supreme Pizza (Peppers, Onion, Olives)',
      category: 'Fast Food & Global',
      caloriesPer100g: 240.0,
      defaultServingGrams: 110.0,
      servingUnit: '1 slice (~110g = 264 kcal)',
      iconEmoji: '🍕',
    ),
    FoodItem(
      id: 'food_pizza_3',
      name: 'Paneer Tikka Pizza (Tandoori Paneer)',
      category: 'Fast Food & Global',
      caloriesPer100g: 275.0,
      defaultServingGrams: 115.0,
      servingUnit: '1 slice (~115g = 316 kcal)',
      iconEmoji: '🍕',
    ),
    FoodItem(
      id: 'food_pizza_4',
      name: 'Chicken BBQ Pizza (Grilled Chicken & Mozzarella)',
      category: 'Fast Food & Global',
      caloriesPer100g: 290.0,
      defaultServingGrams: 120.0,
      servingUnit: '1 slice (~120g = 348 kcal)',
      iconEmoji: '🍕',
    ),
    FoodItem(
      id: 'food_pizza_5',
      name: 'Pepperoni Pizza (Spicy Pepperoni & Cheese)',
      category: 'Fast Food & Global',
      caloriesPer100g: 310.0,
      defaultServingGrams: 110.0,
      servingUnit: '1 slice (~110g = 341 kcal)',
      iconEmoji: '🍕',
    ),
    FoodItem(
      id: 'food_pizza_6',
      name: 'Cheese Burst Pizza (Stuffed Double Cheese)',
      category: 'Fast Food & Global',
      caloriesPer100g: 320.0,
      defaultServingGrams: 125.0,
      servingUnit: '1 slice (~125g = 400 kcal)',
      iconEmoji: '🍕',
    ),
    FoodItem(
      id: 'food_pizza_7',
      name: 'Mushroom & Sweet Corn Pizza',
      category: 'Fast Food & Global',
      caloriesPer100g: 235.0,
      defaultServingGrams: 110.0,
      servingUnit: '1 slice (~110g = 258 kcal)',
      iconEmoji: '🍕',
    ),
    FoodItem(
      id: 'food_pizza_8',
      name: 'Thin Crust Veggie Pizza',
      category: 'Fast Food & Global',
      caloriesPer100g: 230.0,
      defaultServingGrams: 90.0,
      servingUnit: '1 slice (~90g = 207 kcal)',
      iconEmoji: '🍕',
    ),
    FoodItem(
      id: 'food_burger_1',
      name: 'Veg Burger (Crispy Potato & Pea Patty)',
      category: 'Fast Food & Global',
      caloriesPer100g: 245.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 medium burger (~150g = 368 kcal)',
      iconEmoji: '🍔',
    ),
    FoodItem(
      id: 'food_burger_2',
      name: 'Chicken Burger (Grilled Patty with Mayo)',
      category: 'Fast Food & Global',
      caloriesPer100g: 255.0,
      defaultServingGrams: 170.0,
      servingUnit: '1 burger (~170g = 433 kcal)',
      iconEmoji: '🍔',
    ),
    FoodItem(
      id: 'food_burger_3',
      name: 'Double Cheese Burger',
      category: 'Fast Food & Global',
      caloriesPer100g: 295.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 large burger (~200g = 590 kcal)',
      iconEmoji: '🍔',
    ),
    FoodItem(
      id: 'food_burger_4',
      name: 'Paneer Tikka Burger',
      category: 'Fast Food & Global',
      caloriesPer100g: 270.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 burger (~160g = 432 kcal)',
      iconEmoji: '🍔',
    ),
    FoodItem(
      id: 'food_fries_1',
      name: 'French Fries (Crispy Salted)',
      category: 'Fast Food & Global',
      caloriesPer100g: 312.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 medium pack (~100g = 312 kcal)',
      iconEmoji: '🍟',
    ),
    FoodItem(
      id: 'food_fries_2',
      name: 'Peri Peri French Fries',
      category: 'Fast Food & Global',
      caloriesPer100g: 325.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 pack (~100g = 325 kcal)',
      iconEmoji: '🍟',
    ),
    FoodItem(
      id: 'food_sand_1',
      name: 'Veg Grilled Sandwich (Cheese & Chutney)',
      category: 'Fast Food & Global',
      caloriesPer100g: 230.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 whole sandwich (~160g = 368 kcal)',
      iconEmoji: '🥪',
    ),
    FoodItem(
      id: 'food_sand_2',
      name: 'Paneer Sandwich (Grilled with Veggies)',
      category: 'Fast Food & Global',
      caloriesPer100g: 250.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 whole sandwich (~160g = 400 kcal)',
      iconEmoji: '🥪',
    ),
    FoodItem(
      id: 'food_sand_3',
      name: 'Club Sandwich (Triple Layer Chicken & Egg)',
      category: 'Fast Food & Global',
      caloriesPer100g: 260.0,
      defaultServingGrams: 220.0,
      servingUnit: '1 plate (~220g = 572 kcal)',
      iconEmoji: '🥪',
    ),
    FoodItem(
      id: 'food_sand_4',
      name: 'Chicken Tikka Sandwich',
      category: 'Fast Food & Global',
      caloriesPer100g: 245.0,
      defaultServingGrams: 170.0,
      servingUnit: '1 whole sandwich (~170g = 416 kcal)',
      iconEmoji: '🥪',
    ),
    FoodItem(
      id: 'food_pasta_1',
      name: 'White Sauce Alfredo Pasta (Creamy Mushroom)',
      category: 'Fast Food & Global',
      caloriesPer100g: 210.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 standard bowl (~200g = 420 kcal)',
      iconEmoji: '🍝',
    ),
    FoodItem(
      id: 'food_pasta_2',
      name: 'Red Sauce Penne Arrabbiata (Spicy Tomato)',
      category: 'Fast Food & Global',
      caloriesPer100g: 165.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 bowl (~200g = 330 kcal)',
      iconEmoji: '🍝',
    ),
    FoodItem(
      id: 'food_pasta_3',
      name: 'Macaroni & Cheese (Baked)',
      category: 'Fast Food & Global',
      caloriesPer100g: 225.0,
      defaultServingGrams: 180.0,
      servingUnit: '1 bowl (~180g = 405 kcal)',
      iconEmoji: '🍝',
    ),
    FoodItem(
      id: 'food_garlic_1',
      name: 'Garlic Bread with Mozzarella Cheese',
      category: 'Fast Food & Global',
      caloriesPer100g: 340.0,
      defaultServingGrams: 60.0,
      servingUnit: '2 slices (~60g = 204 kcal)',
      iconEmoji: '🥖',
    ),
    FoodItem(
      id: 'food_momo_1',
      name: 'Steamed Vegetable Momos (with Chili Dip)',
      category: 'Fast Food & Global',
      caloriesPer100g: 180.0,
      defaultServingGrams: 120.0,
      servingUnit: '6 pieces (~120g = 216 kcal)',
      iconEmoji: '🥟',
    ),
    FoodItem(
      id: 'food_momo_2',
      name: 'Steamed Chicken Momos',
      category: 'Fast Food & Global',
      caloriesPer100g: 205.0,
      defaultServingGrams: 120.0,
      servingUnit: '6 pieces (~120g = 246 kcal)',
      iconEmoji: '🥟',
    ),
    FoodItem(
      id: 'food_roll_1',
      name: 'Paneer Kathi Roll / Frankie',
      category: 'Fast Food & Global',
      caloriesPer100g: 265.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 roll (~160g = 424 kcal)',
      iconEmoji: '🌯',
    ),
    FoodItem(
      id: 'food_roll_2',
      name: 'Chicken Shawarma Roll (with Garlic Toum)',
      category: 'Fast Food & Global',
      caloriesPer100g: 250.0,
      defaultServingGrams: 180.0,
      servingUnit: '1 roll (~180g = 450 kcal)',
      iconEmoji: '🌯',
    ),
    FoodItem(
      id: 'food_noodle_1',
      name: 'Vegetable Hakka Noodles',
      category: 'Fast Food & Global',
      caloriesPer100g: 175.0,
      defaultServingGrams: 180.0,
      servingUnit: '1 plate (~180g = 315 kcal)',
      iconEmoji: '🍜',
    ),
    FoodItem(
      id: 'food_noodle_2',
      name: 'Schezwan Noodles (Spicy Veg)',
      category: 'Fast Food & Global',
      caloriesPer100g: 190.0,
      defaultServingGrams: 180.0,
      servingUnit: '1 plate (~180g = 342 kcal)',
      iconEmoji: '🍜',
    ),
    FoodItem(
      id: 'food_noodle_3',
      name: 'Chicken Hakka Noodles',
      category: 'Fast Food & Global',
      caloriesPer100g: 210.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 plate (~200g = 420 kcal)',
      iconEmoji: '🍜',
    ),
    FoodItem(
      id: 'food_frice_1',
      name: 'Vegetable Fried Rice',
      category: 'Fast Food & Global',
      caloriesPer100g: 180.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 plate (~200g = 360 kcal)',
      iconEmoji: '🍚',
    ),
    FoodItem(
      id: 'food_frice_2',
      name: 'Egg Fried Rice',
      category: 'Fast Food & Global',
      caloriesPer100g: 195.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 plate (~200g = 390 kcal)',
      iconEmoji: '🍚',
    ),
    FoodItem(
      id: 'food_frice_3',
      name: 'Chicken Fried Rice',
      category: 'Fast Food & Global',
      caloriesPer100g: 215.0,
      defaultServingGrams: 220.0,
      servingUnit: '1 plate (~220g = 473 kcal)',
      iconEmoji: '🍚',
    ),

    // =========================================================================
    // 2. SOUTH & NORTH INDIAN BREAKFAST
    // =========================================================================
    FoodItem(
      id: 'food_1',
      name: 'Idly (Steamed Rice & Urad Dal)',
      category: 'Breakfast',
      caloriesPer100g: 140.0,
      defaultServingGrams: 50.0,
      servingUnit: '1 piece (~50g = 70 kcal)',
      iconEmoji: '⚪',
    ),
    FoodItem(
      id: 'food_2',
      name: 'Plain Dosa (Crispy)',
      category: 'Breakfast',
      caloriesPer100g: 165.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 medium dosa (~100g = 165 kcal)',
      iconEmoji: '🥞',
    ),
    FoodItem(
      id: 'food_3',
      name: 'Masala Dosa (with Aloo Masala)',
      category: 'Breakfast',
      caloriesPer100g: 220.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 masala dosa (~150g = 330 kcal)',
      iconEmoji: '🌯',
    ),
    FoodItem(
      id: 'food_dosa_ghee',
      name: 'Ghee Roast Dosa',
      category: 'Breakfast',
      caloriesPer100g: 250.0,
      defaultServingGrams: 120.0,
      servingUnit: '1 dosa (~120g = 300 kcal)',
      iconEmoji: '🥞',
    ),
    FoodItem(
      id: 'food_uthappam',
      name: 'Onion Uthappam',
      category: 'Breakfast',
      caloriesPer100g: 185.0,
      defaultServingGrams: 130.0,
      servingUnit: '1 uthappam (~130g = 240 kcal)',
      iconEmoji: '🥞',
    ),
    FoodItem(
      id: 'food_4',
      name: 'Medu Vada (Crispy Lentil Fritter)',
      category: 'Breakfast',
      caloriesPer100g: 290.0,
      defaultServingGrams: 50.0,
      servingUnit: '1 vada (~50g = 145 kcal)',
      iconEmoji: '🍩',
    ),
    FoodItem(
      id: 'food_5',
      name: 'Ven Pongal (Ghee & Moong Dal)',
      category: 'Breakfast',
      caloriesPer100g: 195.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 292 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_6',
      name: 'Rava Upma with Veggies',
      category: 'Breakfast',
      caloriesPer100g: 160.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup (~150g = 240 kcal)',
      iconEmoji: '🍲',
    ),
    FoodItem(
      id: 'food_poha',
      name: 'Poha (Flattened Rice with Peanuts & Veggies)',
      category: 'Breakfast',
      caloriesPer100g: 170.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 plate (~150g = 255 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_7',
      name: 'Poori (Deep Fried Wheat Bread)',
      category: 'Breakfast',
      caloriesPer100g: 380.0,
      defaultServingGrams: 40.0,
      servingUnit: '1 poori (~40g = 152 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_paratha_aloo',
      name: 'Aloo Paratha (with Butter)',
      category: 'Breakfast',
      caloriesPer100g: 260.0,
      defaultServingGrams: 120.0,
      servingUnit: '1 paratha (~120g = 312 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_paratha_paneer',
      name: 'Paneer Paratha',
      category: 'Breakfast',
      caloriesPer100g: 285.0,
      defaultServingGrams: 120.0,
      servingUnit: '1 paratha (~120g = 342 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_paratha_gobi',
      name: 'Gobi Paratha',
      category: 'Breakfast',
      caloriesPer100g: 240.0,
      defaultServingGrams: 110.0,
      servingUnit: '1 paratha (~110g = 264 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_appam',
      name: 'Appam (Fermented Rice Pancake)',
      category: 'Breakfast',
      caloriesPer100g: 125.0,
      defaultServingGrams: 75.0,
      servingUnit: '1 appam (~75g = 94 kcal)',
      iconEmoji: '🥞',
    ),
    FoodItem(
      id: 'food_idiyappam',
      name: 'Idiyappam (String Hoppers)',
      category: 'Breakfast',
      caloriesPer100g: 130.0,
      defaultServingGrams: 100.0,
      servingUnit: '3 pieces (~100g = 130 kcal)',
      iconEmoji: '⚪',
    ),
    FoodItem(
      id: 'food_puttu',
      name: 'Puttu (Steamed Rice Flour with Coconut)',
      category: 'Breakfast',
      caloriesPer100g: 190.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 portion (~100g = 190 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_chole_bhature',
      name: 'Chole Bhature',
      category: 'Breakfast',
      caloriesPer100g: 330.0,
      defaultServingGrams: 220.0,
      servingUnit: '1 bhatura + chole (~220g = 726 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_bread_omelette',
      name: 'Bread Omelette (Double Egg)',
      category: 'Breakfast',
      caloriesPer100g: 230.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 serving (~150g = 345 kcal)',
      iconEmoji: '🥪',
    ),

    // =========================================================================
    // 3. MAIN COURSES, RICE & BREADS
    // =========================================================================
    FoodItem(
      id: 'food_8',
      name: 'Chapati / Phulka (No Oil)',
      category: 'Main Course',
      caloriesPer100g: 260.0,
      defaultServingGrams: 35.0,
      servingUnit: '1 medium roti (~35g = 91 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_tandoori_roti',
      name: 'Tandoori Roti (Wheat)',
      category: 'Main Course',
      caloriesPer100g: 250.0,
      defaultServingGrams: 50.0,
      servingUnit: '1 roti (~50g = 125 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_butter_naan',
      name: 'Butter Naan',
      category: 'Main Course',
      caloriesPer100g: 320.0,
      defaultServingGrams: 90.0,
      servingUnit: '1 naan (~90g = 288 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_garlic_naan',
      name: 'Garlic Naan',
      category: 'Main Course',
      caloriesPer100g: 310.0,
      defaultServingGrams: 90.0,
      servingUnit: '1 naan (~90g = 279 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_11',
      name: 'Malabar Parotta (Layered Bread)',
      category: 'Main Course',
      caloriesPer100g: 340.0,
      defaultServingGrams: 80.0,
      servingUnit: '1 parotta (~80g = 272 kcal)',
      iconEmoji: '🥐',
    ),
    FoodItem(
      id: 'food_9',
      name: 'Steamed White Rice (Sona Masoori)',
      category: 'Main Course',
      caloriesPer100g: 130.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 medium cup (~150g = 195 kcal)',
      iconEmoji: '🍚',
    ),
    FoodItem(
      id: 'food_10',
      name: 'Brown Rice (Cooked)',
      category: 'Main Course',
      caloriesPer100g: 111.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 medium cup (~150g = 166 kcal)',
      iconEmoji: '🍚',
    ),
    FoodItem(
      id: 'food_jeera_rice',
      name: 'Basmati Jeera Rice',
      category: 'Main Course',
      caloriesPer100g: 165.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 cup (~160g = 264 kcal)',
      iconEmoji: '🍚',
    ),
    FoodItem(
      id: 'food_ghee_rice',
      name: 'Ghee Rice (Fragrant Basmati)',
      category: 'Main Course',
      caloriesPer100g: 210.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 cup (~160g = 336 kcal)',
      iconEmoji: '🍚',
    ),
    FoodItem(
      id: 'food_12',
      name: 'Curd Rice with Tadka',
      category: 'Main Course',
      caloriesPer100g: 155.0,
      defaultServingGrams: 180.0,
      servingUnit: '1 bowl (~180g = 279 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_sambar_rice',
      name: 'Sambar Rice (Bisibelebath style)',
      category: 'Main Course',
      caloriesPer100g: 150.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 plate (~200g = 300 kcal)',
      iconEmoji: '🍲',
    ),
    FoodItem(
      id: 'food_lemon_rice',
      name: 'Lemon Rice with Peanuts',
      category: 'Main Course',
      caloriesPer100g: 175.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 cup (~160g = 280 kcal)',
      iconEmoji: '🍚',
    ),
    FoodItem(
      id: 'food_tomato_rice',
      name: 'Tomato Rice',
      category: 'Main Course',
      caloriesPer100g: 160.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 cup (~160g = 256 kcal)',
      iconEmoji: '🍚',
    ),
    FoodItem(
      id: 'food_khichdi',
      name: 'Moong Dal Khichdi (with Ghee)',
      category: 'Main Course',
      caloriesPer100g: 140.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 bowl (~200g = 280 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_13',
      name: 'Chicken Dum Biryani',
      category: 'Main Course',
      caloriesPer100g: 195.0,
      defaultServingGrams: 250.0,
      servingUnit: '1 standard plate (~250g = 487 kcal)',
      iconEmoji: '🍗',
    ),
    FoodItem(
      id: 'food_mutton_biryani',
      name: 'Mutton Biryani (Hyd style)',
      category: 'Main Course',
      caloriesPer100g: 225.0,
      defaultServingGrams: 250.0,
      servingUnit: '1 plate (~250g = 562 kcal)',
      iconEmoji: '🍖',
    ),
    FoodItem(
      id: 'food_14',
      name: 'Vegetable Dum Biryani / Pulao',
      category: 'Main Course',
      caloriesPer100g: 160.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 plate (~200g = 320 kcal)',
      iconEmoji: '🍛',
    ),
    FoodItem(
      id: 'food_egg_biryani',
      name: 'Egg Biryani (with 2 Eggs)',
      category: 'Main Course',
      caloriesPer100g: 180.0,
      defaultServingGrams: 220.0,
      servingUnit: '1 plate (~220g = 396 kcal)',
      iconEmoji: '🍛',
    ),

    // =========================================================================
    // 4. LENTILS, CURRIES & PROTEINS
    // =========================================================================
    FoodItem(
      id: 'food_15',
      name: 'Vegetable Sambar (Toor Dal)',
      category: 'Lentils & Curries',
      caloriesPer100g: 65.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 small bowl (~150g = 97 kcal)',
      iconEmoji: '🍲',
    ),
    FoodItem(
      id: 'food_16',
      name: 'Dal Tadka (Yellow Lentil)',
      category: 'Lentils & Curries',
      caloriesPer100g: 115.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 172 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_dal_makhani',
      name: 'Dal Makhani (Black Lentil & Cream)',
      category: 'Lentils & Curries',
      caloriesPer100g: 175.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 262 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_rasam',
      name: 'Tomato Rasam',
      category: 'Lentils & Curries',
      caloriesPer100g: 40.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup (~150g = 60 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_17',
      name: 'Paneer Butter Masala',
      category: 'Lentils & Curries',
      caloriesPer100g: 235.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 352 kcal)',
      iconEmoji: '🧀',
    ),
    FoodItem(
      id: 'food_18',
      name: 'Palak Paneer (Spinach Gravy)',
      category: 'Lentils & Curries',
      caloriesPer100g: 165.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 247 kcal)',
      iconEmoji: '🥬',
    ),
    FoodItem(
      id: 'food_kadai_paneer',
      name: 'Kadai Paneer (Capsicum Gravy)',
      category: 'Lentils & Curries',
      caloriesPer100g: 190.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 285 kcal)',
      iconEmoji: '🥘',
    ),
    FoodItem(
      id: 'food_matar_paneer',
      name: 'Matar Paneer (Green Peas & Paneer)',
      category: 'Lentils & Curries',
      caloriesPer100g: 170.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 255 kcal)',
      iconEmoji: '🍲',
    ),
    FoodItem(
      id: 'food_chana_masala',
      name: 'Chana Masala (Spiced Chickpea Curry)',
      category: 'Lentils & Curries',
      caloriesPer100g: 140.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 bowl (~160g = 224 kcal)',
      iconEmoji: '🍲',
    ),
    FoodItem(
      id: 'food_rajma',
      name: 'Rajma Masala (Red Kidney Beans)',
      category: 'Lentils & Curries',
      caloriesPer100g: 130.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 bowl (~160g = 208 kcal)',
      iconEmoji: '🍲',
    ),
    FoodItem(
      id: 'food_aloo_gobi',
      name: 'Aloo Gobi Masala',
      category: 'Lentils & Curries',
      caloriesPer100g: 110.0,
      defaultServingGrams: 140.0,
      servingUnit: '1 bowl (~140g = 154 kcal)',
      iconEmoji: '🥔',
    ),
    FoodItem(
      id: 'food_bhindi',
      name: 'Bhindi Masala (Okra Stir-Fry)',
      category: 'Lentils & Curries',
      caloriesPer100g: 95.0,
      defaultServingGrams: 120.0,
      servingUnit: '1 bowl (~120g = 114 kcal)',
      iconEmoji: '🥗',
    ),
    FoodItem(
      id: 'food_veg_kurma',
      name: 'Mixed Vegetable Kurma',
      category: 'Lentils & Curries',
      caloriesPer100g: 120.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 180 kcal)',
      iconEmoji: '🍲',
    ),
    FoodItem(
      id: 'food_butter_chicken',
      name: 'Butter Chicken (Murgh Makhani)',
      category: 'Lentils & Curries',
      caloriesPer100g: 215.0,
      defaultServingGrams: 180.0,
      servingUnit: '1 bowl (~180g = 387 kcal)',
      iconEmoji: '🍗',
    ),
    FoodItem(
      id: 'food_19',
      name: 'Chettinad Chicken Curry',
      category: 'Lentils & Curries',
      caloriesPer100g: 175.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup (~150g = 262 kcal)',
      iconEmoji: '🍲',
    ),
    FoodItem(
      id: 'food_chicken_tikka_masala',
      name: 'Chicken Tikka Masala',
      category: 'Lentils & Curries',
      caloriesPer100g: 190.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 bowl (~160g = 304 kcal)',
      iconEmoji: '🍗',
    ),
    FoodItem(
      id: 'food_tandoori_chicken',
      name: 'Tandoori Chicken (Roasted)',
      category: 'Lentils & Curries',
      caloriesPer100g: 165.0,
      defaultServingGrams: 120.0,
      servingUnit: '1 leg piece (~120g = 198 kcal)',
      iconEmoji: '🍗',
    ),
    FoodItem(
      id: 'food_mutton_curry',
      name: 'Mutton Rogan Josh',
      category: 'Lentils & Curries',
      caloriesPer100g: 230.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 bowl (~160g = 368 kcal)',
      iconEmoji: '🍖',
    ),
    FoodItem(
      id: 'food_fish_curry',
      name: 'South Indian Fish Curry',
      category: 'Lentils & Curries',
      caloriesPer100g: 135.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 bowl (~160g = 216 kcal)',
      iconEmoji: '🐟',
    ),
    FoodItem(
      id: 'food_fish_fry',
      name: 'Fish Fry (Tawa Fried Kingfish)',
      category: 'Lentils & Curries',
      caloriesPer100g: 220.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 piece (~100g = 220 kcal)',
      iconEmoji: '🐟',
    ),
    FoodItem(
      id: 'food_prawn_curry',
      name: 'Prawn Masala Gravy',
      category: 'Lentils & Curries',
      caloriesPer100g: 145.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 217 kcal)',
      iconEmoji: '🦐',
    ),
    FoodItem(
      id: 'food_20',
      name: 'Boiled Egg (Large)',
      category: 'Lentils & Curries',
      caloriesPer100g: 155.0,
      defaultServingGrams: 50.0,
      servingUnit: '1 whole egg (~50g = 78 kcal)',
      iconEmoji: '🥚',
    ),
    FoodItem(
      id: 'food_21',
      name: 'Egg Omelette (1 Egg with Onions & Chili)',
      category: 'Lentils & Curries',
      caloriesPer100g: 190.0,
      defaultServingGrams: 70.0,
      servingUnit: '1 egg omelette (~70g = 133 kcal)',
      iconEmoji: '🍳',
    ),
    FoodItem(
      id: 'food_egg_bhurji',
      name: 'Egg Bhurji (Scrambled with Spices)',
      category: 'Lentils & Curries',
      caloriesPer100g: 180.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 bowl (~100g = 180 kcal)',
      iconEmoji: '🍳',
    ),
    FoodItem(
      id: 'food_egg_curry',
      name: 'Egg Curry (2 Eggs in Spiced Gravy)',
      category: 'Lentils & Curries',
      caloriesPer100g: 150.0,
      defaultServingGrams: 160.0,
      servingUnit: '1 bowl (~160g = 240 kcal)',
      iconEmoji: '🍲',
    ),

    // =========================================================================
    // 5. DAIRY & HEALTHY SIDES
    // =========================================================================
    FoodItem(
      id: 'food_22',
      name: 'Plain Homemade Curd (Dahi)',
      category: 'Dairy & Sides',
      caloriesPer100g: 62.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 small cup (~150g = 93 kcal)',
      iconEmoji: '🥛',
    ),
    FoodItem(
      id: 'food_23',
      name: 'Spiced Buttermilk (Neer Mor)',
      category: 'Dairy & Sides',
      caloriesPer100g: 30.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 glass (~200ml = 60 kcal)',
      iconEmoji: '🥛',
    ),
    FoodItem(
      id: 'food_greek_yogurt',
      name: 'Greek Yogurt (Unsweetened)',
      category: 'Dairy & Sides',
      caloriesPer100g: 85.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup (~150g = 127 kcal)',
      iconEmoji: '🥛',
    ),
    FoodItem(
      id: 'food_fresh_paneer',
      name: 'Raw Fresh Paneer Slices',
      category: 'Dairy & Sides',
      caloriesPer100g: 265.0,
      defaultServingGrams: 50.0,
      servingUnit: '50g cubes (= 132 kcal)',
      iconEmoji: '🧀',
    ),
    FoodItem(
      id: 'food_cow_milk',
      name: 'Whole Cow Milk',
      category: 'Dairy & Sides',
      caloriesPer100g: 65.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 glass (~200ml = 130 kcal)',
      iconEmoji: '🥛',
    ),
    FoodItem(
      id: 'food_skimmed_milk',
      name: 'Skimmed Milk (Low Fat)',
      category: 'Dairy & Sides',
      caloriesPer100g: 35.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 glass (~200ml = 70 kcal)',
      iconEmoji: '🥛',
    ),
    FoodItem(
      id: 'food_veg_raita',
      name: 'Cucumber & Mint Raita',
      category: 'Dairy & Sides',
      caloriesPer100g: 55.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 bowl (~100g = 55 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_boondi_raita',
      name: 'Boondi Raita',
      category: 'Dairy & Sides',
      caloriesPer100g: 110.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 bowl (~100g = 110 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_cheese_slice',
      name: 'Cheddar / Mozzarella Cheese Slice',
      category: 'Dairy & Sides',
      caloriesPer100g: 402.0,
      defaultServingGrams: 28.0,
      servingUnit: '1 slice (~28g = 112 kcal)',
      iconEmoji: '🧀',
    ),

    // =========================================================================
    // 6. SNACKS & BEVERAGES
    // =========================================================================
    FoodItem(
      id: 'food_samosa',
      name: 'Vegetable Samosa (Crispy Potato & Pea)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 310.0,
      defaultServingGrams: 75.0,
      servingUnit: '1 medium samosa (~75g = 232 kcal)',
      iconEmoji: '🥟',
    ),
    FoodItem(
      id: 'food_pakoda',
      name: 'Onion Pakoda (Crispy Fritters)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 325.0,
      defaultServingGrams: 80.0,
      servingUnit: '1 plate (~80g = 260 kcal)',
      iconEmoji: '🧆',
    ),
    FoodItem(
      id: 'food_pav_bhaji',
      name: 'Pav Bhaji (with 2 Buttered Pav)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 210.0,
      defaultServingGrams: 220.0,
      servingUnit: '1 plate (~220g = 462 kcal)',
      iconEmoji: '🫓',
    ),
    FoodItem(
      id: 'food_vada_pav',
      name: 'Vada Pav (Mumbai Burger)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 290.0,
      defaultServingGrams: 110.0,
      servingUnit: '1 piece (~110g = 319 kcal)',
      iconEmoji: '🍔',
    ),
    FoodItem(
      id: 'food_pani_puri',
      name: 'Pani Puri / Golgappa',
      category: 'Snacks & Beverages',
      caloriesPer100g: 160.0,
      defaultServingGrams: 120.0,
      servingUnit: '6 puris (~120g = 192 kcal)',
      iconEmoji: '🧆',
    ),
    FoodItem(
      id: 'food_bhel_puri',
      name: 'Bhel Puri / Sev Puri',
      category: 'Snacks & Beverages',
      caloriesPer100g: 195.0,
      defaultServingGrams: 120.0,
      servingUnit: '1 plate (~120g = 234 kcal)',
      iconEmoji: '🥗',
    ),
    FoodItem(
      id: 'food_potato_chips',
      name: 'Potato Chips (Salted)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 536.0,
      defaultServingGrams: 30.0,
      servingUnit: '1 small pack (~30g = 161 kcal)',
      iconEmoji: '🥔',
    ),
    FoodItem(
      id: 'food_banana_chips',
      name: 'Banana Chips (Coconut Oil Fried)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 520.0,
      defaultServingGrams: 40.0,
      servingUnit: '1 portion (~40g = 208 kcal)',
      iconEmoji: '🍌',
    ),
    FoodItem(
      id: 'food_masala_peanuts',
      name: 'Masala Roasted Peanuts',
      category: 'Snacks & Beverages',
      caloriesPer100g: 570.0,
      defaultServingGrams: 30.0,
      servingUnit: '1 handful (~30g = 171 kcal)',
      iconEmoji: '🥜',
    ),
    FoodItem(
      id: 'food_24',
      name: 'Tender Coconut Water',
      category: 'Snacks & Beverages',
      caloriesPer100g: 19.0,
      defaultServingGrams: 250.0,
      servingUnit: '1 coconut (~250ml = 47 kcal)',
      iconEmoji: '🥥',
    ),
    FoodItem(
      id: 'food_25',
      name: 'Filter Coffee (with Milk & 1 tsp Sugar)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 70.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 tumbler (~150ml = 105 kcal)',
      iconEmoji: '☕',
    ),
    FoodItem(
      id: 'food_26',
      name: 'Masala Chai (with Milk & 1 tsp Sugar)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 65.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 glass (~150ml = 97 kcal)',
      iconEmoji: '☕',
    ),
    FoodItem(
      id: 'food_27',
      name: 'Black Coffee / Green Tea (No Sugar)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 2.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 cup (~150ml = 3 kcal)',
      iconEmoji: '🍵',
    ),
    FoodItem(
      id: 'food_sweet_lassi',
      name: 'Sweet Lassi (Punjabi style)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 125.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 glass (~200ml = 250 kcal)',
      iconEmoji: '🥛',
    ),
    FoodItem(
      id: 'food_mango_lassi',
      name: 'Mango Lassi',
      category: 'Snacks & Beverages',
      caloriesPer100g: 140.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 glass (~200ml = 280 kcal)',
      iconEmoji: '🥭',
    ),
    FoodItem(
      id: 'food_mosambi_juice',
      name: 'Fresh Sweet Lime Juice (Mosambi)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 45.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 glass (~200ml = 90 kcal)',
      iconEmoji: '🥤',
    ),
    FoodItem(
      id: 'food_lemon_soda',
      name: 'Fresh Lemon Soda (Nimbu Pani)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 40.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 glass (~200ml = 80 kcal)',
      iconEmoji: '🥤',
    ),
    FoodItem(
      id: 'food_cold_coffee',
      name: 'Cold Coffee (with Milk & Sugar)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 95.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 glass (~200ml = 190 kcal)',
      iconEmoji: '☕',
    ),
    FoodItem(
      id: 'food_whey_protein',
      name: 'Whey Protein Shake (with Water)',
      category: 'Snacks & Beverages',
      caloriesPer100g: 120.0,
      defaultServingGrams: 30.0,
      servingUnit: '1 scoop (~30g = 120 kcal)',
      iconEmoji: '🥤',
    ),

    // =========================================================================
    // 7. FRUITS & HEALTHY FOODS
    // =========================================================================
    FoodItem(
      id: 'food_29',
      name: 'Fresh Apple (Sliced)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 52.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 medium fruit (~150g = 78 kcal)',
      iconEmoji: '🍎',
    ),
    FoodItem(
      id: 'food_28',
      name: 'Banana (Robusta / Yelakki)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 89.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 medium fruit (~100g = 89 kcal)',
      iconEmoji: '🍌',
    ),
    FoodItem(
      id: 'food_mango_ripe',
      name: 'Ripe Mango (Alphonso / Banganapalli)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 60.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 medium fruit (~150g = 90 kcal)',
      iconEmoji: '🥭',
    ),
    FoodItem(
      id: 'food_orange',
      name: 'Fresh Orange',
      category: 'Fruits & Healthy',
      caloriesPer100g: 47.0,
      defaultServingGrams: 130.0,
      servingUnit: '1 fruit (~130g = 61 kcal)',
      iconEmoji: '🍊',
    ),
    FoodItem(
      id: 'food_watermelon',
      name: 'Fresh Watermelon (Cubes)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 30.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 bowl (~200g = 60 kcal)',
      iconEmoji: '🍉',
    ),
    FoodItem(
      id: 'food_papaya',
      name: 'Papaya (Ripe Cubes)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 43.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 64 kcal)',
      iconEmoji: '🍈',
    ),
    FoodItem(
      id: 'food_pomegranate',
      name: 'Pomegranate Arils',
      category: 'Fruits & Healthy',
      caloriesPer100g: 83.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 cup (~100g = 83 kcal)',
      iconEmoji: '🍎',
    ),
    FoodItem(
      id: 'food_grapes',
      name: 'Fresh Grapes (Green / Black)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 69.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 cup (~100g = 69 kcal)',
      iconEmoji: '🍇',
    ),
    FoodItem(
      id: 'food_pineapple',
      name: 'Pineapple Slices',
      category: 'Fruits & Healthy',
      caloriesPer100g: 50.0,
      defaultServingGrams: 120.0,
      servingUnit: '1 bowl (~120g = 60 kcal)',
      iconEmoji: '🍍',
    ),
    FoodItem(
      id: 'food_guava',
      name: 'Fresh Guava',
      category: 'Fruits & Healthy',
      caloriesPer100g: 68.0,
      defaultServingGrams: 120.0,
      servingUnit: '1 fruit (~120g = 81 kcal)',
      iconEmoji: '🍈',
    ),
    FoodItem(
      id: 'food_strawberries',
      name: 'Fresh Strawberries',
      category: 'Fruits & Healthy',
      caloriesPer100g: 32.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 bowl (~100g = 32 kcal)',
      iconEmoji: '🍓',
    ),
    FoodItem(
      id: 'food_avocado',
      name: 'Fresh Avocado (Sliced)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 160.0,
      defaultServingGrams: 100.0,
      servingUnit: '1/2 medium fruit (~100g = 160 kcal)',
      iconEmoji: '🥑',
    ),
    FoodItem(
      id: 'food_31',
      name: 'Almonds / Badam (Raw)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 579.0,
      defaultServingGrams: 15.0,
      servingUnit: '10-12 pieces (~15g = 87 kcal)',
      iconEmoji: '🥜',
    ),
    FoodItem(
      id: 'food_walnuts',
      name: 'Walnuts / Akhrot (Raw Halves)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 654.0,
      defaultServingGrams: 15.0,
      servingUnit: '6-7 halves (~15g = 98 kcal)',
      iconEmoji: '🥜',
    ),
    FoodItem(
      id: 'food_cashews',
      name: 'Roasted Cashews',
      category: 'Fruits & Healthy',
      caloriesPer100g: 553.0,
      defaultServingGrams: 15.0,
      servingUnit: '1 handful (~15g = 83 kcal)',
      iconEmoji: '🥜',
    ),
    FoodItem(
      id: 'food_30',
      name: 'Rolled Oats Porridge (with Milk)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 110.0,
      defaultServingGrams: 200.0,
      servingUnit: '1 warm bowl (~200g = 220 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_grilled_chicken',
      name: 'Grilled Chicken Breast (Skinless)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 165.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 breast fillet (~150g = 247 kcal)',
      iconEmoji: '🍗',
    ),
    FoodItem(
      id: 'food_grilled_salmon',
      name: 'Grilled Salmon / Fish Fillet',
      category: 'Fruits & Healthy',
      caloriesPer100g: 208.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 fillet (~150g = 312 kcal)',
      iconEmoji: '🐟',
    ),
    FoodItem(
      id: 'food_tofu',
      name: 'Tofu Stir-Fry with Broccoli',
      category: 'Fruits & Healthy',
      caloriesPer100g: 80.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 120 kcal)',
      iconEmoji: '🥦',
    ),
    FoodItem(
      id: 'food_soya_chunks',
      name: 'Soya Chunks Curry (High Protein)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 125.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 bowl (~150g = 187 kcal)',
      iconEmoji: '🍲',
    ),
    FoodItem(
      id: 'food_sprouts_salad',
      name: 'Sprouted Moong Salad',
      category: 'Fruits & Healthy',
      caloriesPer100g: 70.0,
      defaultServingGrams: 120.0,
      servingUnit: '1 bowl (~120g = 84 kcal)',
      iconEmoji: '🥗',
    ),
    FoodItem(
      id: 'food_chana_sundal',
      name: 'Boiled Chickpeas / Chana Sundal',
      category: 'Fruits & Healthy',
      caloriesPer100g: 135.0,
      defaultServingGrams: 100.0,
      servingUnit: '1 cup (~100g = 135 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_32',
      name: 'Fresh Cucumber & Tomato Salad',
      category: 'Fruits & Healthy',
      caloriesPer100g: 20.0,
      defaultServingGrams: 150.0,
      servingUnit: '1 salad bowl (~150g = 30 kcal)',
      iconEmoji: '🥗',
    ),
    FoodItem(
      id: 'food_peanut_butter',
      name: 'Peanut Butter (Unsweetened)',
      category: 'Fruits & Healthy',
      caloriesPer100g: 588.0,
      defaultServingGrams: 20.0,
      servingUnit: '1 tablespoon (~20g = 117 kcal)',
      iconEmoji: '🥜',
    ),

    // =========================================================================
    // 8. SWEETS & DESSERTS
    // =========================================================================
    FoodItem(
      id: 'food_gulab_jamun',
      name: 'Gulab Jamun (in Sugar Syrup)',
      category: 'Sweets & Desserts',
      caloriesPer100g: 380.0,
      defaultServingGrams: 50.0,
      servingUnit: '1 piece (~50g = 190 kcal)',
      iconEmoji: '🍯',
    ),
    FoodItem(
      id: 'food_rasgulla',
      name: 'Rasgulla (Syrup Squeezed)',
      category: 'Sweets & Desserts',
      caloriesPer100g: 185.0,
      defaultServingGrams: 50.0,
      servingUnit: '1 piece (~50g = 92 kcal)',
      iconEmoji: '⚪',
    ),
    FoodItem(
      id: 'food_jalebi',
      name: 'Crispy Jalebi',
      category: 'Sweets & Desserts',
      caloriesPer100g: 390.0,
      defaultServingGrams: 50.0,
      servingUnit: '2 pieces (~50g = 195 kcal)',
      iconEmoji: '🥨',
    ),
    FoodItem(
      id: 'food_kheer',
      name: 'Rice Kheer / Payasam',
      category: 'Sweets & Desserts',
      caloriesPer100g: 175.0,
      defaultServingGrams: 120.0,
      servingUnit: '1 bowl (~120g = 210 kcal)',
      iconEmoji: '🥣',
    ),
    FoodItem(
      id: 'food_vanilla_icecream',
      name: 'Vanilla Ice Cream',
      category: 'Sweets & Desserts',
      caloriesPer100g: 207.0,
      defaultServingGrams: 80.0,
      servingUnit: '1 scoop (~80g = 165 kcal)',
      iconEmoji: '🍨',
    ),
    FoodItem(
      id: 'food_choc_icecream',
      name: 'Chocolate Ice Cream',
      category: 'Sweets & Desserts',
      caloriesPer100g: 216.0,
      defaultServingGrams: 80.0,
      servingUnit: '1 scoop (~80g = 173 kcal)',
      iconEmoji: '🍨',
    ),
    FoodItem(
      id: 'food_brownie',
      name: 'Chocolate Brownie',
      category: 'Sweets & Desserts',
      caloriesPer100g: 420.0,
      defaultServingGrams: 60.0,
      servingUnit: '1 square piece (~60g = 252 kcal)',
      iconEmoji: '🍫',
    ),
    FoodItem(
      id: 'food_dark_choc',
      name: 'Dark Chocolate (70% Cocoa)',
      category: 'Sweets & Desserts',
      caloriesPer100g: 598.0,
      defaultServingGrams: 20.0,
      servingUnit: '2 squares (~20g = 119 kcal)',
      iconEmoji: '🍫',
    ),
  ];

  /// Built-in catalogue plus the Tamil & Indian dish list, without duplicates.
  static final List<FoodItem> allFoods = () {
    final seen = <String>{};
    final out = <FoodItem>[];
    for (final f in [...tamilIndianFoods, ...catalog]) {
      final key = normaliseFoodText(f.name.split('(').first);
      if (seen.add(key)) out.add(f);
    }
    return out;
  }();

  /// Scored search across names (English or Tamil) and categories. Understands
  /// local spellings: idly/idli, dosai/thosai, sadam/rice, kulambu/kuzhambu...
  static List<FoodItem> search(String query) {
    if (query.trim().isEmpty) return allFoods;
    final q = normaliseFoodText(query);
    final rawQ = query.toLowerCase().trim();
    final tokens = q.split(' ').where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty && rawQ.isEmpty) return allFoods;

    final scored = <MapEntry<FoodItem, int>>[];
    for (final item in allFoods) {
      final name = normaliseFoodText(item.name);
      final rawName = item.name.toLowerCase();
      final cat = item.category.toLowerCase();

      int score = 0;
      if (name == q) {
        score = 100;
      } else if (name.startsWith(q)) {
        score = 85;
      } else if (name.contains(q) || rawName.contains(rawQ)) {
        score = 65;
      } else {
        int matched = 0;
        for (final t in tokens) {
          if (name.contains(t) || cat.contains(t)) matched++;
        }
        if (tokens.isNotEmpty && matched == tokens.length) {
          score = 45;
        } else if (matched > 0) {
          score = 10 * matched;
        }
      }
      if (score > 0) scored.add(MapEntry(item, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }
}

enum WorkoutMetricCategory {
  walking,
  running,
  swimming,
  cycling,
  gym,
  yoga,
  badminton,
  general,
}

/// Standard Metabolic Equivalent of Task (MET) calculations for Workouts
class WorkoutActivityType {
  final String name;
  final String defaultUnit;
  final double met;
  final IconData icon;
  final String description;
  final WorkoutMetricCategory metricCategory;

  const WorkoutActivityType({
    required this.name,
    required this.defaultUnit,
    required this.met,
    required this.icon,
    required this.description,
    this.metricCategory = WorkoutMetricCategory.general,
  });

  /// Calculates estimated burned calories: (MET * 3.5 * weightKg / 200) * minutes
  double calculateCalories({required double weightKg, required int minutes}) {
    if (minutes <= 0 || weightKg <= 0) return 0.0;
    return (met * 3.5 * weightKg / 200.0) * minutes;
  }
}

class WorkoutDatabase {
  static const List<WorkoutActivityType> activities = [
    WorkoutActivityType(
      name: 'Brisk Walking',
      defaultUnit: 'Steps / Km',
      met: 3.8,
      icon: Icons.directions_walk,
      description: 'Aerobic walking (approx 4.8 km/h). 1,000 steps ≈ 10 mins.',
      metricCategory: WorkoutMetricCategory.walking,
    ),
    WorkoutActivityType(
      name: 'Outdoor Running / Jogging',
      defaultUnit: 'Km / Mins',
      met: 8.0,
      icon: Icons.directions_run,
      description: 'High cardiovascular stamina training (~8.5 km/h).',
      metricCategory: WorkoutMetricCategory.running,
    ),
    WorkoutActivityType(
      name: 'Gym & Weight Training',
      defaultUnit: 'Minutes / Sets',
      met: 5.0,
      icon: Icons.fitness_center,
      description: 'Resistance training, muscle conditioning & core work.',
      metricCategory: WorkoutMetricCategory.gym,
    ),
    WorkoutActivityType(
      name: 'Yoga & Pranayama',
      defaultUnit: 'Minutes',
      met: 3.0,
      icon: Icons.self_improvement,
      description: 'Postural flexibility, spine alignment & mindfulness.',
      metricCategory: WorkoutMetricCategory.yoga,
    ),
    WorkoutActivityType(
      name: 'Cycling (Stationary / Road)',
      defaultUnit: 'Km / Mins',
      met: 6.8,
      icon: Icons.directions_bike,
      description: 'Leg strength and sustained aerobic cardio.',
      metricCategory: WorkoutMetricCategory.cycling,
    ),
    WorkoutActivityType(
      name: 'Swimming (Laps)',
      defaultUnit: 'Mins / Laps',
      met: 7.0,
      icon: Icons.pool,
      description: 'Zero-impact full body resistance & lung capacity.',
      metricCategory: WorkoutMetricCategory.swimming,
    ),
    WorkoutActivityType(
      name: 'Badminton / Court Sports',
      defaultUnit: 'Minutes / Games',
      met: 5.5,
      icon: Icons.sports_tennis,
      description: 'Agility, rapid reflexes & high-energy intervals.',
      metricCategory: WorkoutMetricCategory.badminton,
    ),
  ];
}
