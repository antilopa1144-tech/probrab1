import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';

void main() {
  group('CalculatorRegistry', () {
    test('has all expected calculators', () {
      final calculators = CalculatorRegistry.catalogCalculators;

      // Should have multiple calculators
      expect(calculators.length, greaterThan(10));

      // Check some key calculators exist
      expect(CalculatorRegistry.exists('mixes_plaster'), isTrue);
      expect(CalculatorRegistry.exists('walls_wallpaper'), isTrue);
      expect(CalculatorRegistry.exists('floors_tile'), isTrue);
    });

    test('all calculators have valid definitions', () {
      final calculators = CalculatorRegistry.catalogCalculators;

      for (final calc in calculators) {
        // Each calculator should have required fields
        expect(calc.id, isNotEmpty);
        expect(calc.titleKey, isNotEmpty);
        expect(calc.useCase, isNotNull);
      }
    });

    test('calculator lookup by id works', () {
      final plaster = CalculatorRegistry.getById('mixes_plaster');
      expect(plaster, isNotNull);
      expect(plaster!.id, 'mixes_plaster');

      final nonexistent = CalculatorRegistry.getById('nonexistent_calc');
      expect(nonexistent, isNull);
    });

    test('calculators have unique ids', () {
      final calculators = CalculatorRegistry.catalogCalculators;
      final ids = calculators.map((c) => c.id).toSet();

      // All IDs should be unique
      expect(ids.length, calculators.length);
    });

    test('exists returns false for non-existent calculator', () {
      expect(CalculatorRegistry.exists('nonexistent_id'), isFalse);
      expect(CalculatorRegistry.exists(''), isFalse);
    });

    test('all calculators have categories', () {
      final calculators = CalculatorRegistry.catalogCalculators;

      for (final calc in calculators) {
        expect(calc.category, isNotNull);
      }
    });

    test('all calculators have subcategory keys', () {
      final calculators = CalculatorRegistry.catalogCalculators;

      for (final calc in calculators) {
        expect(calc.subCategoryKey, isNotEmpty);
      }
    });

    test('getById returns null for empty string', () {
      final result = CalculatorRegistry.getById('');
      expect(result, isNull);
    });

    test('plaster calculator has correct structure', () {
      final plaster = CalculatorRegistry.getById('mixes_plaster');
      expect(plaster, isNotNull);
      expect(plaster!.id, 'mixes_plaster');
      expect(plaster.titleKey, isNotEmpty);
      expect(plaster.useCase, isNotNull);
      expect(plaster.fields, isNotNull);
    });

    test('wallpaper calculator has correct structure', () {
      final wallpaper = CalculatorRegistry.getById('walls_wallpaper');
      expect(wallpaper, isNotNull);
      expect(wallpaper!.id, 'walls_wallpaper');
      expect(wallpaper.titleKey, isNotEmpty);
      expect(wallpaper.useCase, isNotNull);
    });

    test('tile calculator has correct structure', () {
      final tile = CalculatorRegistry.getById('floors_tile');
      expect(tile, isNotNull);
      expect(tile!.id, 'floors_tile');
      expect(tile.titleKey, isNotEmpty);
      expect(tile.useCase, isNotNull);
    });

    test('gypsum board calculator exists', () {
      expect(CalculatorRegistry.exists('gypsum_board'), isTrue);
      final gypsum = CalculatorRegistry.getById('gypsum_board');
      expect(gypsum, isNotNull);
    });

    test('catalogCalculators returns consistent list', () {
      final list1 = CalculatorRegistry.catalogCalculators;
      final list2 = CalculatorRegistry.catalogCalculators;

      // Lists should have same content
      expect(list1.length, list2.length);
      for (var i = 0; i < list1.length; i++) {
        expect(list1[i].id, list2[i].id);
      }
    });
  });
}
