import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/health_models.dart';

/// Service that queries public open-source food databases (Open Food Facts & Open API)
/// to fetch real-world nutritional metrics and calories per 100g for any food.
class FoodApiService {
  static final Map<String, List<FoodItem>> _cache = {};

  /// Searches public open food databases for any food query (Multi-source: DummyJSON Recipes, TheMealDB, Open Food Facts)
  static Future<List<FoodItem>> searchOnline(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    if (_cache.containsKey(q)) {
      return _cache[q]!;
    }

    final results = <FoodItem>[];
    final seenNames = <String>{};

    // 0. Priority #1: Curated Indian & everyday database matches always served FIRST
    final localMatches = FoodDatabase.search(query);
    for (var f in localMatches) {
      final dedupeKey = f.name.toLowerCase();
      if (!seenNames.contains(dedupeKey)) {
        seenNames.add(dedupeKey);
        results.add(f);
      }
    }

    // 1. Query DummyJSON Recipes API (Lightning fast, reliable, includes calories)
    try {
      final dummyJsonUrl = Uri.parse(
        'https://dummyjson.com/recipes/search?q=${Uri.encodeComponent(q)}&limit=8',
      );
      final response = await http.get(dummyJsonUrl).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final recipes = data['recipes'] as List<dynamic>? ?? [];
        for (var r in recipes) {
          final name = (r['name'] as String? ?? '').trim();
          if (name.isEmpty) continue;
          final cleaned = _toTitleCase(name);
          final dedupeKey = cleaned.toLowerCase();
          if (seenNames.contains(dedupeKey)) continue;
          seenNames.add(dedupeKey);

          final calPerServing = (r['caloriesPerServing'] as num?)?.toDouble() ?? 250.0;
          final cuisine = (r['cuisine'] as String? ?? 'Global');
          final mealType = (r['mealType'] as List<dynamic>?)?.isNotEmpty == true
              ? r['mealType'][0].toString()
              : 'Meal';

          results.add(
            FoodItem(
              id: 'api_dj_${r['id']}_${results.length}',
              name: cleaned,
              category: _inferCategory(cleaned, '$cuisine $mealType'),
              caloriesPer100g: calPerServing > 0 ? calPerServing : 220.0,
              defaultServingGrams: 150.0,
              servingUnit: '1 serving (~${calPerServing.toInt()} kcal)',
              iconEmoji: _inferEmoji(cleaned),
            ),
          );
        }
      }
    } catch (_) {}

    // 2. Query TheMealDB Public API
    try {
      final mealDbUrl = Uri.parse(
        'https://www.themealdb.com/api/json/v1/1/search.php?s=${Uri.encodeComponent(q)}',
      );
      final response = await http.get(mealDbUrl).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final meals = data['meals'] as List<dynamic>? ?? [];
        for (var m in meals) {
          if (results.length >= 12) break;
          final name = (m['strMeal'] as String? ?? '').trim();
          if (name.isEmpty) continue;
          final cleaned = _toTitleCase(name);
          final dedupeKey = cleaned.toLowerCase();
          if (seenNames.contains(dedupeKey)) continue;
          seenNames.add(dedupeKey);

          final cat = m['strCategory'] as String? ?? 'Main Course';
          final area = m['strArea'] as String? ?? '';

          results.add(
            FoodItem(
              id: 'api_mdb_${m['idMeal']}_${results.length}',
              name: cleaned,
              category: _inferCategory(cleaned, '$cat $area'),
              caloriesPer100g: 185.0,
              defaultServingGrams: 150.0,
              servingUnit: '1 plate (~280 kcal)',
              iconEmoji: _inferEmoji(cleaned),
            ),
          );
        }
      }
    } catch (_) {}

    // 3. Query Open Food Facts with standard mobile browser headers
    try {
      final offUrl = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(q)}&search_simple=1&action=process&json=1&page_size=8&sort_by=unique_scans_n',
      );
      final response = await http.get(
        offUrl,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foodsList = data['products'] as List<dynamic>? ?? [];

        for (var item in foodsList) {
          if (results.length >= 16) break;
          final rawName = (item['product_name'] as String? ??
                  item['product_name_en'] as String? ??
                  item['generic_name'] as String? ??
                  '')
              .trim();
          if (rawName.isEmpty) continue;

          double calories100g = 0.0;
          final nutriments = item['nutriments'] as Map<String, dynamic>? ?? {};

          if (nutriments['energy-kcal_100g'] != null) {
            calories100g = (nutriments['energy-kcal_100g'] as num).toDouble();
          } else if (nutriments['energy-kcal'] != null) {
            calories100g = (nutriments['energy-kcal'] as num).toDouble();
          } else if (nutriments['energy-kcal_value'] != null) {
            calories100g = (nutriments['energy-kcal_value'] as num).toDouble();
          } else if (nutriments['energy_100g'] != null) {
            final val = (nutriments['energy_100g'] as num).toDouble();
            if (val > 0) calories100g = val / 4.184;
          }

          if (calories100g <= 0 || calories100g > 950) calories100g = 195.0;

          double servingGrams = 100.0;
          if (item['serving_quantity'] != null) {
            final sq = (item['serving_quantity'] as num?)?.toDouble() ?? 0.0;
            if (sq > 0) servingGrams = sq;
          }
          String servingUnit = (item['serving_size'] as String? ?? '').trim();
          if (servingUnit.isEmpty) {
            servingUnit = '${servingGrams.toInt()}g serving';
          }

          final cleanedName = _toTitleCase(rawName);
          final dedupeKey = cleanedName.toLowerCase();
          if (seenNames.contains(dedupeKey)) continue;
          seenNames.add(dedupeKey);

          final cat = _inferCategory(cleanedName, item['categories'] as String? ?? '');

          results.add(
            FoodItem(
              id: 'api_off_${item['code'] ?? item['_id'] ?? results.length}',
              name: cleanedName,
              category: cat,
              caloriesPer100g: double.parse(calories100g.toStringAsFixed(1)),
              defaultServingGrams: servingGrams,
              servingUnit: servingUnit,
              iconEmoji: _inferEmoji(cleanedName),
            ),
          );
        }
      }
    } catch (_) {}

    if (results.isNotEmpty) {
      _cache[q] = results;
    }
    return results;
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    var clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length > 50) {
      clean = '${clean.substring(0, 47)}...';
    }
    final words = clean.split(' ');
    return words.map((w) {
      if (w.isEmpty) return '';
      if (w.length == 1) return w.toUpperCase();
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  static String _inferCategory(String name, String rawCategories) {
    final lower = '$name $rawCategories'.toLowerCase();
    if (lower.contains('pizza') ||
        lower.contains('burger') ||
        lower.contains('pasta') ||
        lower.contains('sandwich') ||
        lower.contains('noodle') ||
        lower.contains('fries') ||
        lower.contains('momo') ||
        lower.contains('taco') ||
        lower.contains('fast food')) {
      return 'Fast Food & Global';
    }
    if (lower.contains('beverage') ||
        lower.contains('drink') ||
        lower.contains('coffee') ||
        lower.contains('tea') ||
        lower.contains('soda') ||
        lower.contains('juice') ||
        lower.contains('snack') ||
        lower.contains('chip')) {
      return 'Snacks & Beverages';
    }
    if (lower.contains('fruit') ||
        lower.contains('vegetable') ||
        lower.contains('salad') ||
        lower.contains('healthy') ||
        lower.contains('nut') ||
        lower.contains('almond')) {
      return 'Fruits & Healthy';
    }
    if (lower.contains('dairy') ||
        lower.contains('milk') ||
        lower.contains('cheese') ||
        lower.contains('yogurt') ||
        lower.contains('curd')) {
      return 'Dairy & Sides';
    }
    if (lower.contains('chocolate') ||
        lower.contains('cake') ||
        lower.contains('cookie') ||
        lower.contains('biscuit') ||
        lower.contains('ice cream') ||
        lower.contains('dessert') ||
        lower.contains('sweet')) {
      return 'Sweets & Desserts';
    }
    if (lower.contains('breakfast') || lower.contains('cereal') || lower.contains('oat')) {
      return 'Breakfast';
    }
    if (lower.contains('curry') || lower.contains('dal') || lower.contains('gravy') || lower.contains('sambar')) {
      return 'Lentils & Curries';
    }
    return 'Main Course';
  }

  static String _inferEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('pizza')) return '🍕';
    if (lower.contains('burger')) return '🍔';
    if (lower.contains('pasta') || lower.contains('spaghetti') || lower.contains('macaroni')) return '🍝';
    if (lower.contains('fries') || lower.contains('french fries')) return '🍟';
    if (lower.contains('sandwich') || lower.contains('toast') || lower.contains('panini')) return '🥪';
    if (lower.contains('roll') || lower.contains('wrap') || lower.contains('shawarma') || lower.contains('burrito')) return '🌯';
    if (lower.contains('noodle') || lower.contains('ramen') || lower.contains('chow mein') || lower.contains('maggi')) return '🍜';
    if (lower.contains('momo') || lower.contains('dumpling')) return '🥟';
    if (lower.contains('taco')) return '🌮';
    if (lower.contains('dosa') || lower.contains('pancake') || lower.contains('crepe')) return '🥞';
    if (lower.contains('idli') || lower.contains('idly') || lower.contains('rice cake')) return '⚪';
    if (lower.contains('rice') || lower.contains('biryani') || lower.contains('pulao')) return '🍚';
    if (lower.contains('bread') || lower.contains('roti') || lower.contains('chapati') || lower.contains('naan') || lower.contains('parotta') || lower.contains('paratha')) return '🫓';
    if (lower.contains('chicken') || lower.contains('meat') || lower.contains('mutton') || lower.contains('tandoori')) return '🍗';
    if (lower.contains('fish') || lower.contains('prawn') || lower.contains('seafood') || lower.contains('salmon')) return '🐟';
    if (lower.contains('egg') || lower.contains('omelette') || lower.contains('omelet') || lower.contains('bhurji')) return '🥚';
    if (lower.contains('curd') || lower.contains('yogurt') || lower.contains('milk') || lower.contains('cheese') || lower.contains('dahi') || lower.contains('paneer')) return '🥛';
    if (lower.contains('apple')) return '🍎';
    if (lower.contains('banana')) return '🍌';
    if (lower.contains('mango')) return '🥭';
    if (lower.contains('orange')) return '🍊';
    if (lower.contains('watermelon')) return '🍉';
    if (lower.contains('fruit') || lower.contains('berries') || lower.contains('strawberry')) return '🍓';
    if (lower.contains('salad') || lower.contains('vegetable') || lower.contains('spinach') || lower.contains('cucumber')) return '🥗';
    if (lower.contains('tea') || lower.contains('coffee') || lower.contains('chai')) return '☕';
    if (lower.contains('coke') || lower.contains('cola') || lower.contains('juice') || lower.contains('soda') || lower.contains('shake') || lower.contains('drink')) return '🥤';
    if (lower.contains('ice cream') || lower.contains('gelato')) return '🍨';
    if (lower.contains('cake') || lower.contains('pastry') || lower.contains('brownie')) return '🍰';
    if (lower.contains('chocolate')) return '🍫';
    if (lower.contains('cookie') || lower.contains('biscuit')) return '🍪';
    if (lower.contains('soup') || lower.contains('dal') || lower.contains('sambar') || lower.contains('curry') || lower.contains('korma')) return '🥣';
    if (lower.contains('nut') || lower.contains('almond') || lower.contains('badam') || lower.contains('cashew') || lower.contains('peanut')) return '🥜';
    return '🍽️';
  }
}
