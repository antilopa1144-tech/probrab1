import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_gutters.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateGutters', () {
    test('calculates gutter length correctly', () {
      final calculator = CalculateGutters();
      final inputs = {
        'perimeter': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['gutterLength'], equals(40.0));
    });

    test('calculates downpipes automatically', () {
      final calculator = CalculateGutters();
      final inputs = {
        'perimeter': 40.0,
        'pipeHeight': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['downpipesCount'], equals(4.0));
      expect(result.values['downpipeLength'], equals(12.0));
    });

    test('uses provided downpipes count', () {
      final calculator = CalculateGutters();
      final inputs = {
        'perimeter': 40.0,
        'downpipes': 5.0,
        'pipeHeight': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['downpipesCount'], equals(5.0));
      expect(result.values['downpipeLength'], equals(15.0));
    });

    test('calculates corners', () {
      final calculator = CalculateGutters();
      final inputs = {
        'perimeter': 40.0,
        'corners': 4.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['corners'], equals(4.0));
    });

    test('calculates funnels', () {
      final calculator = CalculateGutters();
      final inputs = {
        'perimeter': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['funnels'], equals(4.0));
    });

    test('calculates elbows', () {
      final calculator = CalculateGutters();
      final inputs = {
        'perimeter': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['elbows'], equals(8.0));
    });

    test('calculates brackets', () {
      final calculator = CalculateGutters();
      final inputs = {
        'perimeter': 40.0,
        'pipeHeight': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['gutterBrackets'], greaterThan(60));
      expect(result.values['pipeBrackets'], equals(12.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateGutters();
      final inputs = {
        'perimeter': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['pipeHeight'], equals(3.0));
      expect(result.values['corners'], equals(4.0));
    });

    test('handles zero perimeter', () {
      final calculator = CalculateGutters();
      final inputs = {
        'perimeter': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['gutterLength'], equals(10.0));
      expect(result.values['downpipesCount'], equals(1.0));
    });
  });
}

