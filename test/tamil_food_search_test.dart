import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/models/health_models.dart';

void main() {
  String top(String q) => FoodDatabase.search(q).first.name;

  test('Tamil spellings find the right dishes', () {
    expect(top('idly'), contains('Idli'));
    expect(FoodDatabase.search('thosai').first.name.toLowerCase(), contains('dosa'));
    expect(top('meen kulambu'), contains('Meen Kuzhambu'));
    expect(top('puliyodharai'), contains('Puliyodharai'));
    expect(top('kothu parota'), contains('Kothu Parotta'));
    expect(top('jigarthanda'), contains('Jigarthanda'));
  });

  test('Tamil script search works', () {
    expect(top('இட்லி'), contains('Idli'));
    expect(top('பொங்கல்'), contains('Pongal'));
  });

  test('catalogue has no duplicate dish names', () {
    final names = FoodDatabase.allFoods.map((f) => f.name.toLowerCase()).toList();
    expect(names.toSet().length, names.length);
    expect(FoodDatabase.allFoods.length, greaterThan(280));
  });
}
