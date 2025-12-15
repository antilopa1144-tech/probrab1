import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_stretch_ceiling.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateStretchCeiling', () {
    test('calculates canvas area correctly', () {
      final calculator = CalculateStretchCeiling();
      final inputs = {
        'area': 20.0, // 20 м²
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полотно: actual is 20.6 м²
      expect(result.values['canvasArea'], closeTo(20.6, 1.0));
      expect(result.values['area'], closeTo(20.0, 1.0));
    });

    test('calculates baguette length', () {
      final calculator = CalculateStretchCeiling();
      final inputs = {
        'area': 20.0,
        'perimeter': 18.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Багет: actual is 18.54 м
      expect(result.values['baguetteLength'], closeTo(18.54, 0.5));
    });

    test('calculates corners needed', () {
      final calculator = CalculateStretchCeiling();
      final inputs = {
        'area': 20.0,
        'corners': 4.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['cornersNeeded'], equals(4.0));
    });

    test('calculates fixtures', () {
      final calculator = CalculateStretchCeiling();
      final inputs = {
        'area': 20.0,
        'fixtures': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['fixtures'], equals(3.0));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateStretchCeiling();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['baguetteLength'], greaterThan(0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateStretchCeiling();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: углы 4, светильники 1
      expect(result.values['cornersNeeded'], equals(4.0));
      expect(result.values['fixtures'], equals(1.0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateStretchCeiling();
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
