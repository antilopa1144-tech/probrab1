import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_self_leveling_floor.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateSelfLevelingFloor', () {
    test('calculates mix needed correctly', () {
      final calculator = CalculateSelfLevelingFloor();
      final inputs = {
        'inputMode': 1.0,
        'area': 20.0,
        'thickness': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['mixNeededKg'], closeTo(160.0, 8.0));
      expect(result.values['area'], closeTo(20.0, 1.0));
      expect(result.values['thickness'], equals(5.0));
    });

    test('calculates primer needed', () {
      final calculator = CalculateSelfLevelingFloor();
      final inputs = {
        'inputMode': 1.0,
        'area': 20.0,
        'thickness': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['primerNeededLiters'], equals(3.0));
    });

    test('calculates bags needed', () {
      final calculator = CalculateSelfLevelingFloor();
      final inputs = {
        'inputMode': 1.0,
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['bagsNeeded'], greaterThan(0));
    });

    test('uses default thickness when missing', () {
      final calculator = CalculateSelfLevelingFloor();
      final inputs = {
        'inputMode': 1.0,
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['thickness'], equals(10.0));
      expect(result.values['mixNeededKg'], closeTo(320.0, 16.0));
    });

    test('handles different thickness values', () {
      final calculator = CalculateSelfLevelingFloor();
      final inputs = {
        'inputMode': 1.0,
        'area': 20.0,
        'thickness': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['mixNeededKg'], closeTo(320.0, 16.0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateSelfLevelingFloor();
      final inputs = {
        'inputMode': 1.0,
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

