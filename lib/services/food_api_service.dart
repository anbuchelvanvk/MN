import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/health_models.dart';

/// Food search: the built-in Tamil & Indian dish list first, then packaged
/// foods sold in India from Open Food Facts (free public database).
class FoodApiService {
  static final Map<String, List<FoodItem>> _cache = {};

  /// Searches the local Tamil/Indian list, then Open Food Facts India.
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

    // 2. Open Food Facts — packaged foods sold in India (biscuits, snacks,
    //    ready mixes, drinks...). Free, no key. Only items with real
    //    calorie data are shown.
    try {
      final offUrl = Uri.parse(
        'https://in.openfoodfacts.org/cgi/search.pl?search_terms=${Uri.encodeComponent(q)}'
        '&search_simple=1&action=process&json=1&page_size=20&sort_by=unique_scans_n'
        '&tagtype_0=countries&tag_contains_0=contains&tag_0=india'
        '&fields=code,product_name,product_name_en,generic_name,brands,nutriments,serving_quantity,serving_size,categories',
      );
      final response = await http.get(
        offUrl,
        headers: {
          'User-Agent': 'MNFamilyApp/1.1 (Android; food search)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foodsList = data['products'] as List<dynamic>? ?? [];

        for (var item in foodsList) {
          if (results.length >= 30) break;
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

          // Skip products without trustworthy calorie data.
          if (calories100g <= 0 || calories100g > 950) continue;

          double servingGrams = 100.0;
          if (item['serving_quantity'] != null) {
            final sq = (item['serving_quantity'] as num?)?.toDouble() ?? 0.0;
            if (sq > 0) servingGrams = sq;
          }
          String servingUnit = (item['serving_size'] as String? ?? '').trim();
          if (servingUnit.isEmpty) {
            servingUnit = '${servingGrams.toInt()}g serving';
          }

          final brand = ((item['brands'] as String?) ?? '').split(',').first.trim();
          final cleanedName = _toTitleCase(
            brand.isNotEmpty && !rawName.toLowerCase().contains(brand.toLowerCase()) ? '$brand $rawName' : rawName,
          );
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
