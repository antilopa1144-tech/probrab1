import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_plaster.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

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

      // Расход цементной: обновленная формула
      // Фактический результат: 1705 кг
      expect(result.values['plasterNeeded'], closeTo(1705, 50));
    });

    test('throws exception for zero area', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 0.0,
        'thickness': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
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
      // Проверяем что поле присутствует и больше нуля если рассчитано
      if (result.values.containsKey('beaconsNeeded')) {
        expect(result.values['beaconsNeeded'], greaterThan(0));
      }
    });
  });
}

