import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_laminate.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateLaminate', () {
    test('calculates packs needed correctly', () {
      final calculator = CalculateLaminate();
      final inputs = {
        'area': 20.0, // 20 м²
        'packArea': 2.0, // 2 м² в упаковке
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Количество: 20 / 2 * 1.05 = 10.5, округляем до 11
      expect(result.values['packsNeeded'], equals(11.0));
      expect(result.values['area'], equals(20.0));
    });

    test('calculates underlay area with margin', () {
      final calculator = CalculateLaminate();
      final inputs = {
        'area': 20.0,
        'packArea': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Подложка: 20 * 1.1 = 22 м²
      expect(result.values['underlayArea'], equals(22.0));
    });

    test('calculates plinth length from perimeter', () {
      final calculator = CalculateLaminate();
      final inputs = {
        'area': 20.0,
        'perimeter': 18.0, // периметр комнаты
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['plinthLength'], equals(18.0));
    });

    test('estimates plinth length when perimeter missing', () {
      final calculator = CalculateLaminate();
      final inputs = {
        'area': 20.0, // комната 4x5 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Оценка: 4 * sqrt(20/4) = 4 * sqrt(5) ≈ 8.94
      // Но формула: 4 * sqrt(area / 4) = 4 * sqrt(5) ≈ 8.94
      expect(result.values['plinthLength'], greaterThan(0));
      expect(result.values['plinthLength'], lessThan(20));
    });

    test('calculates wedges needed', () {
      final calculator = CalculateLaminate();
      final inputs = {
        'area': 20.0,
        'perimeter': 18.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клинья: 18 * 4 = 72 шт
      expect(result.values['wedgesNeeded'], equals(72.0));
    });

    test('handles zero area', () {
      final calculator = CalculateLaminate();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['packsNeeded'], equals(0.0));
      expect(result.values['underlayArea'], equals(0.0));
    });

    test('uses default pack area when missing', () {
      final calculator = CalculateLaminate();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 2.0 м² в упаковке
      // 20 / 2 * 1.05 = 10.5 → 11
      expect(result.values['packsNeeded'], equals(11.0));
    });

    test('handles different pack sizes', () {
      final calculator = CalculateLaminate();
      final inputs = {
        'area': 20.0,
        'packArea': 1.5, // меньшая упаковка
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // 20 / 1.5 * 1.05 = 14
      expect(result.values['packsNeeded'], equals(14.0));
    });
  });
}
