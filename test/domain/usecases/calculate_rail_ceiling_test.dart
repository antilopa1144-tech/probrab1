import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_rail_ceiling.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateRailCeiling', () {
    test('calculates rails needed correctly', () {
      final calculator = CalculateRailCeiling();
      final inputs = {
        'area': 20.0, // 20 м²
        'railWidth': 10.0, // 10 см
        'railLength': 300.0, // 300 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь рейки: 0.1 * 3.0 = 0.3 м²
      // Количество: 20 / 0.3 * 1.05 = ~70 реек
      expect(result.values['railsNeeded'], greaterThan(65));
      expect(result.values['railsNeeded'], lessThan(75));
      expect(result.values['area'], equals(20.0));
    });

    test('calculates guide length', () {
      final calculator = CalculateRailCeiling();
      final inputs = {
        'area': 20.0,
        'perimeter': 18.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Направляющие: равны периметру
      expect(result.values['guideLength'], equals(18.0));
    });

    test('calculates hangers needed', () {
      final calculator = CalculateRailCeiling();
      final inputs = {
        'area': 20.0,
        'perimeter': 18.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Подвесы: 18 / 0.6 = 30 шт
      expect(result.values['hangersNeeded'], equals(30.0));
    });

    test('calculates corner length', () {
      final calculator = CalculateRailCeiling();
      final inputs = {
        'area': 20.0,
        'perimeter': 18.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Уголки: равны периметру
      expect(result.values['cornerLength'], equals(18.0));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateRailCeiling();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['guideLength'], greaterThan(0));
    });

    test('uses default rail dimensions when missing', () {
      final calculator = CalculateRailCeiling();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: ширина 10 см, длина 300 см
      expect(result.values['railsNeeded'], greaterThan(0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateRailCeiling();
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
