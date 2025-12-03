import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_self_leveling_floor.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateSelfLevelingFloor', () {
    test('calculates mix needed correctly', () {
      final calculator = CalculateSelfLevelingFloor();
      final inputs = {
        'area': 20.0, // 20 м²
        'thickness': 5.0, // 5 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Расход: 1.5 кг/м² на 1 мм
      // 20 * 1.5 * 5 * 1.1 = 165 кг
      expect(result.values['mixNeeded'], equals(165.0));
      expect(result.values['area'], equals(20.0));
      expect(result.values['thickness'], equals(5.0));
    });

    test('calculates primer needed', () {
      final calculator = CalculateSelfLevelingFloor();
      final inputs = {
        'area': 20.0,
        'thickness': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: 20 * 0.2 * 1.1 = 4.4 кг
      expect(result.values['primerNeeded'], equals(4.4));
    });

    test('calculates rollers needed', () {
      final calculator = CalculateSelfLevelingFloor();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Валик: всегда 1 шт
      expect(result.values['rollersNeeded'], equals(1.0));
    });

    test('uses default thickness when missing', () {
      final calculator = CalculateSelfLevelingFloor();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 5 мм
      expect(result.values['thickness'], equals(5.0));
      // 20 * 1.5 * 5 * 1.1 = 165 кг
      expect(result.values['mixNeeded'], equals(165.0));
    });

    test('handles different thickness values', () {
      final calculator = CalculateSelfLevelingFloor();
      final inputs = {
        'area': 20.0,
        'thickness': 10.0, // 10 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // 20 * 1.5 * 10 * 1.1 = 330 кг
      expect(result.values['mixNeeded'], equals(330.0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateSelfLevelingFloor();
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
