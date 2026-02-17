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

    test('uses default wall height 1.2m when missing', () {
      final calculator = CalculateWaterproofing();
      final inputs = {
        'floorArea': 5.0,
        'perimeter': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Default wallHeight = 1.2 м (СП 29.13330), wallArea = 10 * 1.2 = 12.0
      expect(result.values['wallArea'], equals(12.0));
      expect(result.values['totalArea'], equals(17.0));
    });

    test('handles explicit wall height 0.5', () {
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

      // Default wallHeight = 1.2, wallArea = 10 * 1.2 = 12.0, totalArea = 0 + 12 = 12.0
      expect(result.values['totalArea'], equals(12.0));
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
      // wallArea = 8.944 * 1.2 = 10.733 → rounded to 10.73
      // totalArea = 5.0 + 10.73 = 15.73
      expect(result.values['totalArea'], closeTo(15.73, 0.1));
      expect(result.values['wallArea'], closeTo(10.73, 0.1));
      expect(result.values['tapeLength'], closeTo(8.94, 0.01));
    });
  });
}
