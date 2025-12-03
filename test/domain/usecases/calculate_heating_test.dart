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
      expect(result.values['volume'], equals(125.0));
      expect(result.values['area'], equals(50.0));
    });

    test('calculates total power', () {
      final calculator = CalculateHeating();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Мощность: 50 * 100 = 5000 Вт
      expect(result.values['totalPower'], equals(5000.0));
    });

    test('calculates total sections', () {
      final calculator = CalculateHeating();
      final inputs = {
        'area': 50.0,
        'rooms': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Секций на комнату: 25 / 2 = 13 секций
      // Всего: 13 * 2 = 26 секций
      expect(result.values['totalSections'], greaterThan(20));
      expect(result.values['totalSections'], lessThan(30));
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
      expect(result.values['pipeLength'], equals(20.0));
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
