import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_waterproofing.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

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

      expect(result.values['materialNeeded'], closeTo(17.6, 0.9));
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

      expect(result.values['wallArea'], equals(3.0));
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

      expect(result.values['totalArea'], equals(3.0));
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

      expect(result.values['totalArea'], equals(7.68));
      expect(result.values['wallArea'], equals(2.68));
      expect(result.values['tapeLength'], closeTo(8.94, 0.01));
    });
  });
}

