import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_brick_facing.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateBrickFacing', () {
    test('calculates bricks needed for half-brick', () {
      final calculator = CalculateBrickFacing();
      final inputs = {
        'area': 50.0, // 50 м²
        'thickness': 0.5, // полкирпича
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Для полкирпича: ~61.5 шт/м²
      // 50 * 61.5 * 1.05 = ~3230 шт
      expect(result.values['bricksNeeded'], greaterThan(3200));
      expect(result.values['bricksNeeded'], lessThan(3300));
      expect(result.values['area'], closeTo(50.0, 2.5));
    });

    test('subtracts windows and doors area', () {
      final calculator = CalculateBrickFacing();
      final inputs = {
        'area': 50.0,
        'windowsArea': 10.0,
        'doorsArea': 5.0,
        'thickness': 0.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь: 50 - 10 - 5 = 35 м²
      expect(result.values['usefulArea'], closeTo(35.0, 1.8));
    });

    test('calculates mortar volume', () {
      final calculator = CalculateBrickFacing();
      final inputs = {
        'area': 50.0,
        'thickness': 0.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Раствор: 50 * 0.02 * 0.5 * 1.1 = 0.55 м³ (фактически 0.53)
      expect(result.values['mortarVolume'], closeTo(0.53, 0.05));
    });

    test('calculates reinforcement length', () {
      final calculator = CalculateBrickFacing();
      final inputs = {
        'area': 50.0,
        'perimeter': 30.0,
        'wallHeight': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Армирование должно быть рассчитано
      expect(result.values['reinforcementLength'], greaterThan(0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateBrickFacing();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: толщина 0.5 (полкирпича)
      expect(result.values['bricksNeeded'], greaterThan(3200));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateBrickFacing();
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
