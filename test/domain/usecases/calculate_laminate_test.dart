import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_laminate.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateLaminate', () {
    late CalculateLaminate calculator;

    setUp(() {
      calculator = CalculateLaminate();
    });

    test('calculates packs needed correctly with 5% reserve', () {
      final inputs = {
        'area': 20.0, // 20 м²
        'packArea': 2.0, // 2 м² в упаковке
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Количество = ceil(20 / 2 * 1.05) = ceil(10.5) = 11 упаковок
      expect(result.values['packsNeeded'], equals(11.0));
    });

    test('calculates underlay area with 10% reserve', () {
      final inputs = {
        'area': 20.0,
        'packArea': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Подложка = 20 * 1.1 = 22 м²
      expect(result.values['underlayArea'], equals(22.0));
    });

    test('calculates plinth length from perimeter', () {
      final inputs = {
        'area': 20.0,
        'packArea': 2.0,
        'perimeter': 18.0, // заданный периметр
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['plinthLength'], equals(18.0));
    });

    test('estimates plinth length when perimeter not provided', () {
      final inputs = {
        'area': 16.0, // 4x4 м комната
        'packArea': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр ≈ 4 * sqrt(16/4) = 4 * 2 = 8 м
      expect(result.values['plinthLength'], closeTo(8.0, 0.1));
    });

    test('calculates wedges needed', () {
      final inputs = {
        'area': 20.0,
        'packArea': 2.0,
        'perimeter': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клинья = ceil(20 * 4) = 80 шт
      expect(result.values['wedgesNeeded'], equals(80.0));
    });

    test('handles small room correctly', () {
      final inputs = {
        'area': 6.0, // маленькая комната
        'packArea': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // ceil(6 / 2 * 1.05) = ceil(3.15) = 4 упаковки
      expect(result.values['packsNeeded'], equals(4.0));
    });

    test('handles large room correctly', () {
      final inputs = {
        'area': 100.0, // большой зал
        'packArea': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // ceil(100 / 2.5 * 1.05) = ceil(42) = 42 упаковки
      expect(result.values['packsNeeded'], equals(42.0));
    });

    test('calculates total price with price list', () {
      final inputs = {
        'area': 20.0,
        'packArea': 2.0,
        'perimeter': 18.0,
      };
      final priceList = [
        PriceItem()
          ..sku = 'laminate'
          ..name = 'Ламинат'
          ..price = 1000
          ..unit = 'м²',
      ];

      final result = calculator(inputs, priceList);

      // 11 упаковок * 1000 = 11000 руб
      expect(result.totalPrice, equals(11000.0));
    });

    test('handles zero area', () {
      final inputs = {
        'area': 0.0,
        'packArea': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['area'], equals(0.0));
      expect(result.values['packsNeeded'], equals(0.0));
    });

    test('uses default pack area when not provided', () {
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию packArea = 2.0
      // ceil(20 / 2 * 1.05) = 11
      expect(result.values['packsNeeded'], equals(11.0));
    });
  });
}
