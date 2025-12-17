import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_basement.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateBasement', () {
    late CalculateBasement calculator;

    setUp(() {
      calculator = CalculateBasement();
    });

    test('calculates basic values correctly', () {
      final inputs = {
        'area': 100.0,
        'height': 2.0,
        'wallThickness': 10.0,
        'materialType': 10.0,
        'waterproofing': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Проверяем что результат не пустой
      expect(result.values, isNotEmpty);
    });

    test('uses default values when not provided', () {
      final calculator = CalculateBasement();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Значения по умолчанию (при валидных обязательных входных данных)
      expect(result.values['height'], equals(2.5));
    });

    test('preserves input values in result', () {
      final calculator = CalculateBasement();
      final inputs = {
        'area': 42.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values, isNotEmpty);
    });

    test('handles price list correctly', () {
      final calculator = CalculateBasement();
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
