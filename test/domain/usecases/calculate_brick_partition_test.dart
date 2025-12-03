import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_brick_partition.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateBrickPartition', () {
    test('calculates bricks needed for half-brick wall', () {
      final calculator = CalculateBrickPartition();
      final inputs = {
        'area': 10.0, // 10 м²
        'thickness': 0.5, // полкирпича
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Для полкирпича: ~61.5 шт/м²
      // 10 * 61.5 * 1.05 = ~646 шт
      expect(result.values['bricksNeeded'], greaterThan(600));
      expect(result.values['bricksNeeded'], lessThan(700));
      expect(result.values['area'], equals(10.0));
    });

    test('calculates bricks needed for full brick wall', () {
      final calculator = CalculateBrickPartition();
      final inputs = {
        'area': 10.0,
        'thickness': 1.0, // кирпич
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Для кирпича: ~128 шт/м²
      // 10 * 128 * 1.05 = ~1344 шт
      expect(result.values['bricksNeeded'], greaterThan(1300));
      expect(result.values['bricksNeeded'], lessThan(1400));
    });

    test('calculates mortar volume', () {
      final calculator = CalculateBrickPartition();
      final inputs = {
        'area': 10.0,
        'thickness': 0.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Раствор: 10 * 0.02 * 0.5 * 1.1 = 0.11 м³
      expect(result.values['mortarVolume'], closeTo(0.11, 0.01));
    });

    test('calculates cement and sand needed', () {
      final calculator = CalculateBrickPartition();
      final inputs = {
        'area': 10.0,
        'thickness': 0.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Цемент и песок должны быть рассчитаны
      expect(result.values['cementNeeded'], greaterThan(0));
      expect(result.values['sandNeeded'], greaterThan(0));
    });

    test('uses default thickness when missing', () {
      final calculator = CalculateBrickPartition();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 0.5 (полкирпича)
      expect(result.values['bricksNeeded'], greaterThan(600));
      expect(result.values['bricksNeeded'], lessThan(700));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateBrickPartition();
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
