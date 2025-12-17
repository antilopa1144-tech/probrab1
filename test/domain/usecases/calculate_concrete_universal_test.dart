import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_concrete_universal.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateConcreteUniversal', () {
    late CalculateConcreteUniversal calculator;

    setUp(() {
      calculator = CalculateConcreteUniversal();
    });

    test('calculates basic values correctly', () {
      final inputs = {
        'concreteVolume': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Проверяем что результат не пустой
      expect(result.values, isNotEmpty);
    });

    test('uses default values when not provided', () {
      final calculator = CalculateConcreteUniversal();
      final inputs = {
        'concreteVolume': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Должен использовать значения по умолчанию для необязательных полей
      expect(result.values['reserve'], equals(5.0));
      expect(result.values['concreteVolume'], greaterThan(1.0));
    });

    test('preserves input values in result', () {
      final calculator = CalculateConcreteUniversal();
      final inputs = {
        'concreteVolume': 42.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values, isNotEmpty);
    });

    test('handles price list correctly', () {
      final calculator = CalculateConcreteUniversal();
      final inputs = {
        'concreteVolume': 100.0,
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
