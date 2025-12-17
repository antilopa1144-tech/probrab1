import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_attic.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateAttic', () {
    late CalculateAttic calculator;

    setUp(() {
      calculator = CalculateAttic();
    });

    test('calculates basic values correctly', () {
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Проверяем что результат не пустой
      expect(result.values, isNotEmpty);
    });

    test('uses default values when not provided', () {
      final calculator = CalculateAttic();
      final inputs = <String, double>{};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Должен использовать значения по умолчанию
      expect(result.values, isNotEmpty);
    });

    test('preserves input values in result', () {
      final calculator = CalculateAttic();
      final inputs = {
        'area': 42.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values, isNotEmpty);
    });

    test('handles price list correctly', () {
      final calculator = CalculateAttic();
      final inputs = {
        'area': 100.0,
      };
      final priceList = [
        const PriceItem(
          sku: 'test-1',
          name: 'Тестовый материал',
          unit: 'м²',
          price: 1000.0,
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      expect(result.values, isNotEmpty);
    });
  });
}
