import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_ceiling_paint.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateCeilingPaint', () {
    test('calculates paint needed correctly', () {
      final calculator = CalculateCeilingPaint();
      final inputs = {
        'area': 30.0, // 30 м²
        'layers': 2.0,
        'consumption': 0.12, // 0.12 кг/м²
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Краска: 30 * 0.12 * 2 * 1.1 = 7.92 кг
      expect(result.values['paintNeeded'], equals(7.92));
      expect(result.values['area'], equals(30.0));
    });

    test('calculates primer needed', () {
      final calculator = CalculateCeilingPaint();
      final inputs = {
        'area': 30.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: 30 * 0.1 * 1.1 = 3.3 кг
      expect(result.values['primerNeeded'], equals(3.3));
    });

    test('uses default consumption when missing', () {
      final calculator = CalculateCeilingPaint();
      final inputs = {
        'area': 30.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 0.12 кг/м²
      // 30 * 0.12 * 2 * 1.1 = 7.92 кг
      expect(result.values['paintNeeded'], equals(7.92));
    });

    test('uses default layers when missing', () {
      final calculator = CalculateCeilingPaint();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 2 слоя
      expect(result.values['layers'], equals(2.0));
      expect(result.values['paintNeeded'], greaterThan(0));
    });

    test('handles different consumption rates', () {
      final calculator = CalculateCeilingPaint();
      final inputs = {
        'area': 30.0,
        'layers': 2.0,
        'consumption': 0.15, // больший расход
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // 30 * 0.15 * 2 * 1.1 = 9.9 кг
      expect(result.values['paintNeeded'], equals(9.9));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateCeilingPaint();
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
