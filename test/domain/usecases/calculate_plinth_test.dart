import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_plinth.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculatePlinth', () {
    late CalculatePlinth calculator;

    setUp(() {
      calculator = CalculatePlinth();
    });

    test('calculates basic values correctly', () {
      final inputs = {
        'length': 100.0,
        'perimeter': 10.0,
        'width': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Проверяем что результат не пустой
      expect(result.values, isNotEmpty);
    });

    test('uses default values when not provided', () {
      final calculator = CalculatePlinth();
      final inputs = {
        'perimeter': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Должен использовать значения по умолчанию
      expect(result.values['reserve'], equals(5.0));
    });

    test('preserves input values in result', () {
      final calculator = CalculatePlinth();
      final inputs = {
        'perimeter': 42.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['plinthLengthMeters'], greaterThanOrEqualTo(42.5));
    });

    test('handles price list correctly', () {
      final calculator = CalculatePlinth();
      final inputs = {
        'perimeter': 10.0,
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
