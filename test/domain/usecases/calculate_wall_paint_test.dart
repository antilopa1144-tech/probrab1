import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wall_paint.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateWallPaint', () {
    late CalculateWallPaint calculator;

    setUp(() {
      calculator = CalculateWallPaint();
    });

    test('calculates paint needed correctly with 10% reserve', () {
      final inputs = {
        'area': 40.0, // 40 м²
        'layers': 2.0,
        'consumption': 0.15, // кг/м²
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Краска = 40 * 0.15 * 2 * 1.1 = 13.2 кг
      expect(result.values['paintNeeded'], closeTo(13.2, 0.1));
    });

    test('calculates primer needed correctly', () {
      final inputs = {
        'area': 40.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка = 40 * 0.1 * 1.1 = 4.4 кг
      expect(result.values['primerNeeded'], closeTo(4.4, 0.1));
    });

    test('subtracts windows and doors area', () {
      final inputs = {
        'area': 50.0,
        'layers': 2.0,
        'windowsArea': 6.0,
        'doorsArea': 4.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь = 50 - 6 - 4 = 40 м²
      expect(result.values['usefulArea'], equals(40.0));
    });

    test('handles single layer correctly', () {
      final inputs = {
        'area': 40.0,
        'layers': 1.0,
        'consumption': 0.15,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Краска = 40 * 0.15 * 1 * 1.1 = 6.6 кг
      expect(result.values['paintNeeded'], closeTo(6.6, 0.1));
    });

    test('handles three layers correctly', () {
      final inputs = {
        'area': 40.0,
        'layers': 3.0,
        'consumption': 0.15,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Краска = 40 * 0.15 * 3 * 1.1 = 19.8 кг
      expect(result.values['paintNeeded'], closeTo(19.8, 0.1));
    });

    test('uses default values when not provided', () {
      final inputs = {
        'area': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: layers=2, consumption=0.15
      expect(result.values['layers'], equals(2.0));
      expect(result.values['paintNeeded'], closeTo(13.2, 0.1));
    });

    test('does not allow negative useful area', () {
      final inputs = {
        'area': 20.0,
        'windowsArea': 15.0,
        'doorsArea': 10.0, // больше чем площадь
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['usefulArea'], equals(0.0));
    });

    test('handles zero area', () {
      final inputs = {
        'area': 0.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['usefulArea'], equals(0.0));
      expect(result.values['paintNeeded'], equals(0.0));
    });

    test('calculates total price with price list', () {
      final inputs = {
        'area': 40.0,
        'layers': 2.0,
      };
      final priceList = [
        PriceItem()
          ..sku = 'paint'
          ..name = 'Краска'
          ..price = 500
          ..unit = 'л',
      ];

      final result = calculator(inputs, priceList);

      expect(result.totalPrice, isNotNull);
      expect(result.totalPrice!, greaterThan(0));
    });

    test('handles high consumption rate', () {
      final inputs = {
        'area': 40.0,
        'layers': 2.0,
        'consumption': 0.25, // текстурная краска
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Краска = 40 * 0.25 * 2 * 1.1 = 22 кг
      expect(result.values['paintNeeded'], closeTo(22.0, 0.1));
    });
  });
}
