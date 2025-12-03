import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_linoleum.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateLinoleum', () {
    test('calculates rolls needed correctly', () {
      final calculator = CalculateLinoleum();
      final inputs = {
        'area': 30.0, // 30 м²
        'rollWidth': 3.0, // 3 м
        'rollLength': 30.0, // 30 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь рулона: 3 * 30 = 90 м²
      // Площадь с нахлёстом: 30 * 1.05 * 1.1 = 34.65 м²
      // Количество: 34.65 / 90 = 1 рулон
      expect(result.values['rollsNeeded'], greaterThanOrEqualTo(1.0));
      expect(result.values['area'], equals(30.0));
    });

    test('calculates glue needed', () {
      final calculator = CalculateLinoleum();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей: 30 * 0.3 = 9 кг
      expect(result.values['glueNeeded'], equals(9.0));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateLinoleum();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['plinthLength'], greaterThan(0));
    });

    test('uses provided perimeter', () {
      final calculator = CalculateLinoleum();
      final inputs = {
        'area': 30.0,
        'perimeter': 22.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['plinthLength'], equals(22.0));
    });

    test('uses default roll dimensions when missing', () {
      final calculator = CalculateLinoleum();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: ширина 3 м, длина 30 м
      expect(result.values['rollsNeeded'], greaterThan(0));
    });

    test('handles overlap correctly', () {
      final calculator = CalculateLinoleum();
      final inputs = {
        'area': 30.0,
        'overlap': 10.0, // 10 см нахлёст
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // С большим нахлёстом нужно больше рулонов
      expect(result.values['rollsNeeded'], greaterThanOrEqualTo(1.0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateLinoleum();
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
