import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_plaster.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculatePlaster', () {
    test('calculates plaster needed correctly', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 100.0, // 100 м²
        'thickness': 10.0, // 10 мм
        'type': 1.0, // гипсовая
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Расход гипсовой штукатурки: ~8.5 кг/м² на 1 мм толщины
      // Формула: area * consumptionPerMm * (thickness / 10) * 1.1
      // 100 м² * 8.5 * (10 / 10) * 1.1 = 935 кг
      expect(result.values['plasterNeeded'], closeTo(935, 10));
      expect(result.values['area'], equals(100.0));
    });

    test('calculates cement plaster correctly', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 50.0,
        'thickness': 20.0,
        'type': 2.0, // цементная
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Расход цементной: ~10 кг/м² на 1 мм толщины
      // Формула: area * consumptionPerMm * (thickness / 10) * 1.1
      // 50 * 10 * (20 / 10) * 1.1 = 1100 кг
      expect(result.values['plasterNeeded'], closeTo(1100, 10));
    });

    test('handles zero area', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 0.0,
        'thickness': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['plasterNeeded'], equals(0.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: толщина 10 мм, тип 1 (гипсовая)
      expect(result.values['plasterNeeded'], greaterThan(0));
    });

    test('calculates beacons needed', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 100.0,
        'perimeter': 40.0, // периметр
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Маяки: ~1 шт на 1.5 м ширины, периметр 40 м / 1.5 = ~27
      expect(result.values['beaconsNeeded'], greaterThan(0));
    });
  });
}

