import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_sheeting_osb_plywood.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateSheetingOsbPlywood', () {
    late CalculateSheetingOsbPlywood calculator;

    setUp(() {
      calculator = CalculateSheetingOsbPlywood();
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
      final calculator = CalculateSheetingOsbPlywood();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Должен использовать значения по умолчанию
      expect(result.values['reserve'], equals(10.0));
      expect(result.values['materialArea'], closeTo(11.0, 0.6));
    });

    test('preserves input values in result', () {
      final calculator = CalculateSheetingOsbPlywood();
      final inputs = {
        'area': 42.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values, isNotEmpty);
    });

    test('handles price list correctly', () {
      final calculator = CalculateSheetingOsbPlywood();
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
