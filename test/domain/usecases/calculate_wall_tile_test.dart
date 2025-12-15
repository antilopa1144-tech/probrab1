import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wall_tile.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateWallTile', () {
    test('calculates tiles needed correctly', () {
      final calculator = CalculateWallTile();
      final inputs = {
        'area': 30.0, // 30 м²
        'tileWidth': 30.0, // 30 см
        'tileHeight': 30.0, // 30 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь плитки: 0.3 * 0.3 = 0.09 м²
      // Количество: 30 / 0.09 * 1.1 = ~367 шт
      expect(result.values['tilesNeeded'], greaterThan(360));
      expect(result.values['tilesNeeded'], lessThan(380));
      expect(result.values['area'], closeTo(30.0, 1.5));
    });

    test('subtracts windows and doors area', () {
      final calculator = CalculateWallTile();
      final inputs = {
        'area': 30.0,
        'windowsArea': 5.0,
        'doorsArea': 2.0,
        'tileWidth': 30.0,
        'tileHeight': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь: 30 - 5 - 2 = 23 м²
      expect(result.values['usefulArea'], closeTo(23.0, 1.2));
    });

    test('calculates grout needed', () {
      final calculator = CalculateWallTile();
      final inputs = {
        'area': 30.0,
        'jointWidth': 3.0, // 3 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Затирка: 30 * 1.5 * 0.3 = 13.5 кг
      expect(result.values['groutNeeded'], closeTo(13.5, 0.7));
    });

    test('calculates glue needed', () {
      final calculator = CalculateWallTile();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей: 30 * 4 = 120 кг
      expect(result.values['glueNeeded'], closeTo(120.0, 6.0));
    });

    test('calculates crosses needed', () {
      final calculator = CalculateWallTile();
      final inputs = {
        'area': 30.0,
        'tileWidth': 30.0,
        'tileHeight': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крестики: количество плиток * 4
      final tilesNeeded = result.values['tilesNeeded']!;
      expect(result.values['crossesNeeded'], equals(tilesNeeded * 4));
    });

    test('uses default values when missing', () {
      final calculator = CalculateWallTile();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 30x30 см, шов 3 мм
      expect(result.values['tilesNeeded'], greaterThan(0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateWallTile();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });
  });
}
