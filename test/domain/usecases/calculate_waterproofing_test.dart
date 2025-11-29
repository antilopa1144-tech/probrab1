import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_waterproofing.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateWaterproofing', () {
    test('calculates total area correctly', () {
      final calculator = CalculateWaterproofing();
      final inputs = {
        'floorArea': 5.0, // 5 м²
        'wallHeight': 0.3, // 30 см
        'perimeter': 10.0, // 10 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь стен: 10 * 0.3 = 3 м²
      // Общая площадь: 5 + 3 = 8 м²
      expect(result.values['totalArea'], equals(8.0));
      expect(result.values['floorArea'], equals(5.0));
      expect(result.values['wallArea'], equals(3.0));
    });

    test('calculates material needed', () {
      final calculator = CalculateWaterproofing();
      final inputs = {
        'floorArea': 5.0,
        'wallHeight': 0.3,
        'perimeter': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Материал: 8 * 2 * 1.1 = 17.6 кг
      expect(result.values['materialNeeded'], equals(17.6));
    });

    test('calculates primer needed', () {
      final calculator = CalculateWaterproofing();
      final inputs = {
        'floorArea': 5.0,
        'wallHeight': 0.3,
        'perimeter': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: 8 * 0.2 * 1.1 = 1.76 кг
      expect(result.values['primerNeeded'], equals(1.76));
    });

    test('calculates tape length', () {
      final calculator = CalculateWaterproofing();
      final inputs = {
        'floorArea': 5.0,
        'perimeter': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Лента: равна периметру
      expect(result.values['tapeLength'], equals(10.0));
    });

    test('uses default wall height when missing', () {
      final calculator = CalculateWaterproofing();
      final inputs = {
        'floorArea': 5.0,
        'perimeter': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 0.3 м
      expect(result.values['wallHeight'], equals(0.3));
      // Площадь стен: 10 * 0.3 = 3 м²
      expect(result.values['wallArea'], equals(3.0));
    });

    test('handles different wall heights', () {
      final calculator = CalculateWaterproofing();
      final inputs = {
        'floorArea': 5.0,
        'wallHeight': 0.5, // 50 см
        'perimeter': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь стен: 10 * 0.5 = 5 м²
      // Общая площадь: 5 + 5 = 10 м²
      expect(result.values['totalArea'], equals(10.0));
    });

    test('handles zero floor area', () {
      final calculator = CalculateWaterproofing();
      final inputs = {
        'floorArea': 0.0,
        'perimeter': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['totalArea'], equals(3.0)); // только стены
      expect(result.values['materialNeeded'], greaterThan(0));
    });

    test('handles zero perimeter', () {
      final calculator = CalculateWaterproofing();
      final inputs = {
        'floorArea': 5.0,
        'perimeter': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Только пол
      expect(result.values['totalArea'], equals(5.0));
      expect(result.values['wallArea'], equals(0.0));
      expect(result.values['tapeLength'], equals(0.0));
    });
  });
}
