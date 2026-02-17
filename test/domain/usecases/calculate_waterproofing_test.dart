import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_waterproofing.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateWaterproofing', () {
    test('calculates total area correctly', () {
      final calculator = CalculateWaterproofing();
      final inputs = {
        'floorArea': 5.0,
        'wallHeight': 0.3,
        'perimeter': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

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

      // totalArea=8, consumptionPerLayer=1.5, layers=2, +10%
      // 8 * 1.5 * 2 * 1.1 = 26.4
      expect(result.values['materialNeeded'], closeTo(26.4, 1.0));
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

      // Default wallHeight = 0.5 м, wallArea = 10 * 0.5 = 5.0
      expect(result.values['wallArea'], equals(5.0));
    });

    test('handles different wall heights', () {
      final calculator = CalculateWaterproofing();
      final inputs = {
        'floorArea': 5.0,
        'wallHeight': 0.5,
        'perimeter': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

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

      // Default wallHeight = 0.5, wallArea = 10 * 0.5 = 5.0, totalArea = 0 + 5 = 5.0
      expect(result.values['totalArea'], equals(5.0));
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

      // estimatePerimeter(5) = 4*sqrt(5) ≈ 8.944
      // wallArea = 8.944 * 0.5 = 4.472 → rounded to 4.47
      // totalArea = 5.0 + 4.47 = 9.47
      expect(result.values['totalArea'], closeTo(9.47, 0.01));
      expect(result.values['wallArea'], closeTo(4.47, 0.01));
      expect(result.values['tapeLength'], closeTo(8.94, 0.01));
    });
  });
}
