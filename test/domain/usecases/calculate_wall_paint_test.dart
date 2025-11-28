import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wall_paint.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateWallPaint', () {
    test('calculates paint needed correctly', () {
      final calculator = CalculateWallPaint();
      final inputs = {
        'area': 50.0, // 50 м²
        'layers': 2.0, // 2 слоя
        'consumption': 0.15, // 0.15 кг/м²
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Краска: 50 * 0.15 * 2 * 1.1 = 16.5 кг
      expect(result.values['paintNeeded'], equals(16.5));
      expect(result.values['usefulArea'], equals(50.0));
    });

    test('subtracts windows and doors area', () {
      final calculator = CalculateWallPaint();
      final inputs = {
        'area': 50.0,
        'windowsArea': 5.0,
        'doorsArea': 2.0,
        'layers': 2.0,
        'consumption': 0.15,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь: 50 - 5 - 2 = 43 м²
      expect(result.values['usefulArea'], equals(43.0));
      // Краска: 43 * 0.15 * 2 * 1.1 = 14.19 кг
      expect(result.values['paintNeeded'], closeTo(14.19, 0.1));
    });

    test('calculates primer needed', () {
      final calculator = CalculateWallPaint();
      final inputs = {
        'area': 50.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: 50 * 0.1 * 1.1 = 5.5 кг
      expect(result.values['primerNeeded'], equals(5.5));
    });

    test('uses default consumption when missing', () {
      final calculator = CalculateWallPaint();
      final inputs = {
        'area': 50.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 0.15 кг/м²
      // 50 * 0.15 * 2 * 1.1 = 16.5 кг
      expect(result.values['paintNeeded'], equals(16.5));
    });

    test('uses default layers when missing', () {
      final calculator = CalculateWallPaint();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 2 слоя
      expect(result.values['layers'], equals(2.0));
      expect(result.values['paintNeeded'], greaterThan(0));
    });

    test('handles zero area', () {
      final calculator = CalculateWallPaint();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['usefulArea'], equals(0.0));
      expect(result.values['paintNeeded'], equals(0.0));
      expect(result.values['primerNeeded'], equals(0.0));
    });

    test('handles negative useful area', () {
      final calculator = CalculateWallPaint();
      final inputs = {
        'area': 10.0,
        'windowsArea': 15.0, // больше общей площади
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь должна быть >= 0
      expect(result.values['usefulArea'], equals(0.0));
      expect(result.values['paintNeeded'], equals(0.0));
    });

    test('handles different consumption rates', () {
      final calculator = CalculateWallPaint();
      final inputs = {
        'area': 50.0,
        'consumption': 0.2, // больший расход
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Краска: 50 * 0.2 * 2 * 1.1 = 22 кг
      expect(result.values['paintNeeded'], equals(22.0));
    });
  });
}
