import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_strip_foundation.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateStripFoundation', () {
    test('calculates concrete volume correctly', () {
      final calculator = CalculateStripFoundation();
      final inputs = {
        'perimeter': 40.0, // 40 м периметр
        'width': 0.5, // 50 см ширина
        'height': 0.6, // 60 см высота
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 40 * 0.5 * 0.6 = 12 м³
      expect(result.values['concreteVolume'], equals(12.0));
    });

    test('calculates rebar weight', () {
      final calculator = CalculateStripFoundation();
      final inputs = {
        'perimeter': 40.0,
        'width': 0.5,
        'height': 0.6,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 12 м³
      // Арматура: 12 * 0.01 * 7850 = 942 кг
      expect(result.values['rebarWeight'], closeTo(942, 10));
    });

    test('calculates cement bags', () {
      final calculator = CalculateStripFoundation();
      final inputs = {
        'perimeter': 40.0,
        'width': 0.5,
        'height': 0.6,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Мешки: 12 * 7 = 84 мешка
      expect(result.values['bagsCement'], equals(84.0));
    });

    test('handles zero inputs', () {
      final calculator = CalculateStripFoundation();
      final inputs = {
        'perimeter': 0.0,
        'width': 0.0,
        'height': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['concreteVolume'], equals(0.0));
      expect(result.values['rebarWeight'], equals(0.0));
      expect(result.values['bagsCement'], equals(0.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateStripFoundation();
      final inputs = {
        'perimeter': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию width и height = 0, объём = 0
      expect(result.values['concreteVolume'], equals(0.0));
    });

    test('handles different foundation sizes', () {
      final calculator = CalculateStripFoundation();
      final inputs = {
        'perimeter': 30.0,
        'width': 0.4,
        'height': 0.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 30 * 0.4 * 0.5 = 6 м³
      expect(result.values['concreteVolume'], equals(6.0));
      expect(result.values['bagsCement'], equals(42.0)); // 6 * 7
    });
  });
}
