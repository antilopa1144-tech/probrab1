import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_putty.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculatePutty', () {
    test('calculates start putty correctly', () {
      final calculator = CalculatePutty();
      final inputs = {
        'area': 50.0, // 50 м²
        'layers': 2.0,
        'type': 1.0, // стартовая
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Стартовая: 1.5 кг/м²
      // 50 * 1.5 * 2 * 1.1 = 165 кг
      expect(result.values['puttyNeeded'], equals(165.0));
      expect(result.values['area'], equals(50.0));
      expect(result.values['layers'], equals(2.0));
    });

    test('calculates finish putty correctly', () {
      final calculator = CalculatePutty();
      final inputs = {
        'area': 50.0,
        'layers': 2.0,
        'type': 2.0, // финишная
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Финишная: 0.8 кг/м²
      // 50 * 0.8 * 2 * 1.1 = 88 кг
      expect(result.values['puttyNeeded'], equals(88.0));
    });

    test('calculates primer needed', () {
      final calculator = CalculatePutty();
      final inputs = {
        'area': 50.0,
        'type': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: 50 * 0.2 * 1.1 = 11 кг
      expect(result.values['primerNeeded'], equals(11.0));
    });

    test('calculates spatulas needed', () {
      final calculator = CalculatePutty();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Шпатели: всегда 3 шт
      expect(result.values['spatulasNeeded'], equals(3.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculatePutty();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 2 слоя, тип 1 (стартовая)
      expect(result.values['layers'], equals(2.0));
      expect(result.values['puttyNeeded'], greaterThan(0));
    });

    test('handles zero area', () {
      final calculator = CalculatePutty();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['puttyNeeded'], equals(0.0));
      expect(result.values['primerNeeded'], equals(0.0));
    });
  });
}
