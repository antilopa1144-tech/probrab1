import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_heating.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateHeating', () {
    test('calculates volume correctly', () {
      final calculator = CalculateHeating();
      final inputs = {
        'area': 50.0, // 50 м²
        'ceilingHeight': 2.5, // 2.5 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 50 * 2.5 = 125 м³
      expect(result.values['volume'], closeTo(125.0, 6.2));
      expect(result.values['area'], closeTo(50.0, 2.5));
    });

    test('calculates total power based on volume', () {
      final calculator = CalculateHeating();
      final inputs = {
        'area': 50.0,
        // default ceilingHeight = 2.5
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Мощность: 50 * 2.5 * 41 = 5125 Вт (СНиП 41-01-2003: 41 Вт/м³)
      expect(result.values['totalPower'], closeTo(5125.0, 50.0));
    });

    test('calculates power correctly for high ceilings', () {
      final calculator = CalculateHeating();
      final inputs = {
        'area': 50.0,
        'ceilingHeight': 3.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Мощность: 50 * 3.5 * 41 = 7175 Вт (учитывает объём!)
      expect(result.values['totalPower'], closeTo(7175.0, 50.0));
      // Секции: 7175 / 180 = 39.86 → 40
      expect(result.values['totalSections'], equals(40.0));
    });

    test('calculates total sections', () {
      final calculator = CalculateHeating();
      final inputs = {
        'area': 50.0,
        'rooms': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Мощность: 50 * 2.5 * 41 = 5125 Вт, секции: 5125/180 = 28.5 → 29
      expect(result.values['totalSections'], equals(29.0));
      // По 15 секций на комнату (29/2 = 14.5 → 15)
      expect(result.values['sectionsPerRadiator'], equals(15.0));
    });

    test('calculates pipe length', () {
      final calculator = CalculateHeating();
      final inputs = {
        'area': 50.0,
        'rooms': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Трубы: 2 * 10 = 20 м
      expect(result.values['pipeLength'], closeTo(20.0, 1.0));
    });

    test('calculates fittings needed', () {
      final calculator = CalculateHeating();
      final inputs = {
        'area': 50.0,
        'rooms': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Фитинги: 2 * 5 = 10 шт
      expect(result.values['fittingsNeeded'], equals(10.0));
    });

    test('calculates valves needed', () {
      final calculator = CalculateHeating();
      final inputs = {
        'area': 50.0,
        'rooms': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Краны: 2 * 2 = 4 шт
      expect(result.values['valvesNeeded'], equals(4.0));
    });

    test('calculates thermostats needed', () {
      final calculator = CalculateHeating();
      final inputs = {
        'area': 50.0,
        'rooms': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Терморегуляторы: по количеству комнат
      expect(result.values['thermostatsNeeded'], equals(2.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateHeating();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 1 комната, высота 2.5 м
      expect(result.values['rooms'], equals(1.0));
      expect(result.values['ceilingHeight'], equals(2.5));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateHeating();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });
  });
}
