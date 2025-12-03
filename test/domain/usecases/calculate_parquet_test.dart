import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_parquet.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateParquet', () {
    test('calculates planks needed correctly', () {
      final calculator = CalculateParquet();
      final inputs = {
        'area': 20.0, // 20 м²
        'plankWidth': 7.0, // 7 см
        'plankLength': 40.0, // 40 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь планки: 0.07 * 0.40 = 0.028 м²
      // Количество: 20 / 0.028 * 1.05 = ~750 планок
      expect(result.values['planksNeeded'], greaterThan(700));
      expect(result.values['planksNeeded'], lessThan(800));
      expect(result.values['area'], equals(20.0));
    });

    test('calculates varnish needed', () {
      final calculator = CalculateParquet();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Лак: 20 * 0.1 * 3 = 6 л
      expect(result.values['varnishNeeded'], equals(6.0));
    });

    test('calculates primer needed', () {
      final calculator = CalculateParquet();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: 20 * 0.08 = 1.6 л
      expect(result.values['primerNeeded'], equals(1.6));
    });

    test('calculates glue needed', () {
      final calculator = CalculateParquet();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей: 20 * 1.5 = 30 кг
      expect(result.values['glueNeeded'], equals(30.0));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateParquet();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['plinthLength'], greaterThan(0));
    });

    test('uses provided perimeter', () {
      final calculator = CalculateParquet();
      final inputs = {
        'area': 20.0,
        'perimeter': 18.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['plinthLength'], equals(18.0));
    });

    test('uses default plank dimensions when missing', () {
      final calculator = CalculateParquet();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 7x40 см
      expect(result.values['planksNeeded'], greaterThan(0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateParquet();
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
