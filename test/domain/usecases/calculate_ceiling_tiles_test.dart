import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_ceiling_tiles.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateCeilingTiles', () {
    test('calculates tiles needed correctly', () {
      final calculator = CalculateCeilingTiles();
      final inputs = {
        'area': 20.0, // 20 м²
        'tileSize': 50.0, // 50 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь плитки: 0.5 * 0.5 = 0.25 м²
      // Количество: 20 / 0.25 * 1.1 = 88 плиток
      expect(result.values['tilesNeeded'], equals(88.0));
      expect(result.values['area'], equals(20.0));
    });

    test('calculates glue needed', () {
      final calculator = CalculateCeilingTiles();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей: 20 * 0.5 = 10 кг
      expect(result.values['glueNeeded'], equals(10.0));
    });

    test('calculates primer needed', () {
      final calculator = CalculateCeilingTiles();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: 20 * 0.1 = 2 кг
      expect(result.values['primerNeeded'], equals(2.0));
    });

    test('uses default tile size when missing', () {
      final calculator = CalculateCeilingTiles();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 50x50 см
      expect(result.values['tilesNeeded'], equals(88.0));
    });

    test('handles different tile sizes', () {
      final calculator = CalculateCeilingTiles();
      final inputs = {
        'area': 20.0,
        'tileSize': 60.0, // 60 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь плитки: 0.6 * 0.6 = 0.36 м²
      // Количество: 20 / 0.36 * 1.1 = ~62 плитки
      expect(result.values['tilesNeeded'], greaterThan(60));
      expect(result.values['tilesNeeded'], lessThan(65));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateCeilingTiles();
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
