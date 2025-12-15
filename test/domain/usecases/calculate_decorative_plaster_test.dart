import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_decorative_plaster.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateDecorativePlaster', () {
    test('calculates plaster needed correctly', () {
      final calculator = CalculateDecorativePlaster();
      final inputs = {
        'area': 50.0, // 50 м²
        'thickness': 2.0, // 2 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Штукатурка: 50 * 1.5 * 2 * 1.1 = 165 кг
      expect(result.values['plasterNeeded'], closeTo(165.0, 8.2));
      expect(result.values['usefulArea'], closeTo(50.0, 2.5));
    });

    test('subtracts windows and doors area', () {
      final calculator = CalculateDecorativePlaster();
      final inputs = {
        'area': 50.0,
        'windowsArea': 5.0,
        'doorsArea': 2.0,
        'thickness': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь: 50 - 5 - 2 = 43 м²
      expect(result.values['usefulArea'], closeTo(43.0, 2.1));
      // Штукатурка: 43 * 1.5 * 2 * 1.1 = 141.9 кг
      expect(result.values['plasterNeeded'], closeTo(141.9, 0.1));
    });

    test('calculates primer needed', () {
      final calculator = CalculateDecorativePlaster();
      final inputs = {
        'area': 50.0,
        'thickness': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: 50 * 0.15 * 1.1 = 8.25 кг
      expect(result.values['primerNeeded'], equals(8.25));
    });

    test('uses default thickness when missing', () {
      final calculator = CalculateDecorativePlaster();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 2 мм
      expect(result.values['thickness'], equals(2.0));
      // 50 * 1.5 * 2 * 1.1 = 165 кг
      expect(result.values['plasterNeeded'], closeTo(165.0, 8.2));
    });

    test('handles different thickness values', () {
      final calculator = CalculateDecorativePlaster();
      final inputs = {
        'area': 50.0,
        'thickness': 3.0, // 3 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // 50 * 1.5 * 3 * 1.1 = 247.5 кг
      expect(result.values['plasterNeeded'], closeTo(247.5, 12.4));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateDecorativePlaster();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('handles negative useful area', () {
      final calculator = CalculateDecorativePlaster();
      final inputs = {
        'area': 10.0,
        'windowsArea': 15.0, // больше общей площади
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь должна быть >= 0
      expect(result.values['usefulArea'], equals(0.0));
      expect(result.values['plasterNeeded'], equals(0.0));
    });
  });
}
