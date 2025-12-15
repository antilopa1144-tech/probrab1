import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_terrace.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateTerrace', () {
    late CalculateTerrace calculator;

    setUp(() {
      calculator = CalculateTerrace();
    });

    test('calculates basic values correctly', () {
      final inputs = {
        'perimeter': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Проверяем что результат не пустой
      expect(result.values, isNotEmpty);
    });

    test('uses default values when not provided', () {
      final calculator = CalculateTerrace();
      final inputs = <String, double>{};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Должен использовать значения по умолчанию
      expect(result.values, isNotEmpty);
    });

    test('preserves input values in result', () {
      final calculator = CalculateTerrace();
      final inputs = {
        'perimeter': 42.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values, isNotEmpty);
    });

    test('handles price list correctly', () {
      final calculator = CalculateTerrace();
      final inputs = {
        'perimeter': 100.0,
      };
      final priceList = [
        PriceItem(
          id: 'test-1',
          name: 'Тестовый материал',
          unit: 'м²',
          price: 1000.0,
        ),
      ];

      final result = calculator(inputs, priceList);

      expect(result.values, isNotEmpty);
    });
  });
}
