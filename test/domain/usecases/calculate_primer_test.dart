import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_primer.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculatePrimer', () {
    test('calculates standard primer correctly', () {
      final calculator = CalculatePrimer();
      final inputs = {
        'area': 50.0, // 50 м²
        'layers': 1.0,
        'type': 1.0, // обычная
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Обычная: 0.1 л/м²
      // 50 * 0.1 * 1 * 1.1 = 5.5 л
      expect(result.values['primerNeeded'], equals(5.5));
      expect(result.values['area'], equals(50.0));
    });

    test('calculates deep penetration primer correctly', () {
      final calculator = CalculatePrimer();
      final inputs = {
        'area': 50.0,
        'layers': 1.0,
        'type': 2.0, // глубокого проникновения
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Глубокого проникновения: 0.15 л/м²
      // 50 * 0.15 * 1 * 1.1 = 8.25 л
      expect(result.values['primerNeeded'], equals(8.25));
    });

    test('calculates with multiple layers', () {
      final calculator = CalculatePrimer();
      final inputs = {
        'area': 50.0,
        'layers': 2.0,
        'type': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // 50 * 0.1 * 2 * 1.1 = 11 л
      expect(result.values['primerNeeded'], equals(11.0));
      expect(result.values['layers'], equals(2.0));
    });

    test('calculates rollers and trays needed', () {
      final calculator = CalculatePrimer();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Валики: 2 шт
      expect(result.values['rollersNeeded'], equals(2.0));
      // Кювета: 1 шт
      expect(result.values['traysNeeded'], equals(1.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculatePrimer();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 1 слой, тип 1 (обычная)
      expect(result.values['layers'], equals(1.0));
      expect(result.values['primerNeeded'], greaterThan(0));
    });

    test('handles zero area', () {
      final calculator = CalculatePrimer();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['primerNeeded'], equals(0.0));
    });
  });
}
