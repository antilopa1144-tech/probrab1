import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_plaster.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculatePlaster', () {
    test('calculates plaster needed correctly', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 100.0, // 100 м² площадь стен
        'thickness': 10.0, // 10 мм
        'type': 1.0, // гипсовая
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Расход гипсовой штукатурки: ~8.5 кг/м² на 10 мм толщины
      // Формула: area * consumptionPer10mm * (thickness / 10) * 1.1
      // 100 м² * 8.5 * (10 / 10) * 1.1 = 935 кг
      expect(result.values['plasterKg'], closeTo(935, 10));
      expect(result.values['plasterBags'], equals(32)); // 935 / 30 = 31.2 -> ceil = 32
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

      // Расход цементной: 17.0 кг/м² на 10 мм толщины
      // 50 * 17.0 * (20 / 10) * 1.1 = 1870 кг
      expect(result.values['plasterKg'], closeTo(1870, 50));
      expect(result.values['plasterBags'], equals(75)); // 1870 / 25 = 74.8 -> ceil = 75
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
      expect(result.values['plasterKg'], greaterThan(0));
      expect(result.values['plasterBags'], greaterThan(0));
    });

    test('calculates beacons needed', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 100.0,
        'thickness': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Маяки: ~1 шт на 2.5 м² площади
      // 100 / 2.5 = 40
      expect(result.values['beacons'], equals(40));
      expect(result.values['beaconSize'], equals(10)); // 10 мм для слоя >= 10 мм
    });

    test('calculates primer liters', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 100.0,
        'thickness': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: 0.1 л/м² * 1.1 = 0.11 л/м²
      // 100 * 0.11 = 11 л -> ceil
      expect(result.values['primerLiters'], equals(11));
    });

    test('calculates rule size', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 100.0,
        'thickness': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Правило: 1.5 м
      expect(result.values['ruleSize'], equals(1.5));
    });

    test('beacon size depends on thickness', () {
      final calculator = CalculatePlaster();
      final emptyPriceList = <PriceItem>[];

      // Толщина < 10 мм -> маяки 6 мм
      var result = calculator({'area': 50.0, 'thickness': 9.0}, emptyPriceList);
      expect(result.values['beaconSize'], equals(6));

      // Толщина >= 10 мм -> маяки 10 мм
      result = calculator({'area': 50.0, 'thickness': 10.0}, emptyPriceList);
      expect(result.values['beaconSize'], equals(10));

      result = calculator({'area': 50.0, 'thickness': 15.0}, emptyPriceList);
      expect(result.values['beaconSize'], equals(10));
    });

    test('calculates mesh area for thick layers', () {
      final calculator = CalculatePlaster();
      final emptyPriceList = <PriceItem>[];

      // Толщина <= 30 мм -> нет сетки
      var result = calculator({'area': 50.0, 'thickness': 30.0}, emptyPriceList);
      expect(result.values.containsKey('meshArea'), isFalse);

      // Толщина > 30 мм -> сетка нужна
      result = calculator({'area': 50.0, 'thickness': 35.0}, emptyPriceList);
      expect(result.values['meshArea'], closeTo(55, 1)); // 50 * 1.1 = 55
    });
  });
}
