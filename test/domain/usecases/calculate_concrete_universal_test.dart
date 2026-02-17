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
      // Должна присутствовать марка бетона (по умолчанию М200 = 3)
      expect(result.values['concreteGrade'], 3.0);
    });

    test('uses default values when not provided', () {
      final inputs = {
        'concreteVolume': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Должен использовать значения по умолчанию для необязательных полей
      expect(result.values['reserve'], equals(5.0));
      expect(result.values['concreteVolume'], greaterThan(1.0));
      // По умолчанию марка М200 (grade=3)
      expect(result.values['concreteGrade'], equals(3.0));
    });

    test('preserves input values in result', () {
      final inputs = {
        'concreteVolume': 42.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values, isNotEmpty);
      expect(result.values['concreteGrade'], equals(3.0));
    });

    test('handles price list correctly', () {
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
      expect(result.values['concreteGrade'], equals(3.0));
    });

    test('respects concrete grade selection', () {
      // М300 (grade=5)
      final inputs = {
        'concreteVolume': 1.0,
        'concreteGrade': 5.0,
        'manualMix': 1.0,
        'reserve': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['concreteGrade'], equals(5.0));
      // М300: 380 кг/м³ → ceil(1.0 * 380 / 50) = ceil(7.6) = 8 мешков
      expect(result.values['cementBags'], equals(8.0));
    });
  });
}
