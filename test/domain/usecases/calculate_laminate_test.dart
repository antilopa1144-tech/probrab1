import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_laminate.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateLaminate', () {
    late CalculateLaminate calculator;

    setUp(() {
      calculator = CalculateLaminate();
    });

    test('calculates packs needed correctly with 7% reserve', () {
      final inputs = {
        'area': 20.0, // 20 м²
        'packArea': 2.0, // 2 м² в упаковке
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Количество = ceil(20 / 2 * 1.07) = ceil(10.7) = 11 упаковок
      expect(result.values['packsNeeded'], equals(11.0));
    });

    test('calculates underlay area with 5% reserve', () {
      final inputs = {
        'area': 20.0,
        'packArea': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Подложка = 20 * 1.05 = 21 м²
      expect(result.values['underlayArea'], equals(21.0));
    });

    test('calculates plinth length from perimeter with 5% reserve', () {
      final inputs = {
        'area': 20.0,
        'packArea': 2.0,
        'perimeter': 18.0, // заданный периметр
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Плинтус = 18 * 1.05 = 18.9 м
      expect(result.values['plinthLength'], equals(18.9));
    });

    test('estimates plinth length when perimeter not provided', () {
      final inputs = {
        'area': 16.0, // 4x4 м комната
        'packArea': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр ≈ 4 * sqrt(16) = 16 м, с запасом 5% = 16.8 м
      expect(result.values['plinthLength'], closeTo(16.8, 0.1));
    });

    test('calculates wedges needed', () {
      final inputs = {
        'area': 20.0,
        'packArea': 2.0,
        'perimeter': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клинья = ceil(20 / 0.5) = ceil(40) = 40 шт
      expect(result.values['wedgesNeeded'], equals(40.0));
    });

    test('handles small room correctly', () {
      final inputs = {
        'area': 6.0, // маленькая комната
        'packArea': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // ceil(6 / 2 * 1.07) = ceil(3.21) = 4 упаковки
      expect(result.values['packsNeeded'], equals(4.0));
    });

    test('handles large room correctly', () {
      final inputs = {
        'area': 100.0, // большой зал
        'packArea': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // ceil(100 / 2.5 * 1.07) = ceil(42.8) = 43 упаковки
      expect(result.values['packsNeeded'], equals(43.0));
    });

    test('calculates total price with price list', () {
      final inputs = {
        'area': 20.0,
        'packArea': 2.0,
        'perimeter': 18.0,
      };
      final priceList = [
        PriceItem(
          sku: 'laminate',
          name: 'Ламинат',
          price: 1000,
          unit: 'м²',
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      // 11 упаковок * 1000 = 11000 руб
      expect(result.totalPrice, equals(11000.0));
    });

    test('throws exception for zero area', () {
      final inputs = {
        'area': 0.0,
        'packArea': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      // Калькулятор должен выбросить исключение при area <= 0
      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<Exception>()),
      );
    });

    test('uses default pack area when not provided', () {
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию packArea = 2.0
      // ceil(20 / 2 * 1.07) = ceil(10.7) = 11
      expect(result.values['packsNeeded'], equals(11.0));
    });
  });
}
