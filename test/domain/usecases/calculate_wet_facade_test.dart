import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wet_facade.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateWetFacade', () {
    test('calculates insulation volume correctly', () {
      final calculator = CalculateWetFacade();
      final inputs = {
        'area': 100.0, // 100 м²
        'insulationThickness': 100.0, // 100 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 100 * 0.1 = 10 м³
      expect(result.values['insulationVolume'], equals(10.0));
      expect(result.values['area'], equals(100.0));
    });

    test('calculates sheets needed for foam', () {
      final calculator = CalculateWetFacade();
      final inputs = {
        'area': 100.0,
        'insulationThickness': 100.0,
        'insulationType': 2.0, // пенопласт
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа пенопласта: 0.5 м²
      // Количество: 100 / 0.5 * 1.05 = 210 листов
      expect(result.values['sheetsNeeded'], equals(210.0));
    });

    test('calculates sheets needed for mineral wool', () {
      final calculator = CalculateWetFacade();
      final inputs = {
        'area': 100.0,
        'insulationThickness': 100.0,
        'insulationType': 1.0, // минвата
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа минваты: 0.72 м²
      // Количество: 100 / 0.72 * 1.05 = ~146 листов
      expect(result.values['sheetsNeeded'], greaterThan(140));
      expect(result.values['sheetsNeeded'], lessThan(150));
    });

    test('calculates glue needed', () {
      final calculator = CalculateWetFacade();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей: 100 * 5 = 500 кг
      expect(result.values['glueNeeded'], equals(500.0));
    });

    test('calculates fasteners needed', () {
      final calculator = CalculateWetFacade();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крепёж: 100 * 5 = 500 шт
      expect(result.values['fastenersNeeded'], equals(500.0));
    });

    test('calculates mesh area', () {
      final calculator = CalculateWetFacade();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Сетка: 100 * 1.1 = 110 м²
      expect(result.values['meshArea'], equals(110.0));
    });

    test('calculates plaster and finish needed', () {
      final calculator = CalculateWetFacade();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Штукатурка: 100 * 5 = 500 кг
      expect(result.values['plasterNeeded'], equals(500.0));
      // Финиш: 100 * 0.5 = 50 кг
      expect(result.values['finishNeeded'], equals(50.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateWetFacade();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: толщина 100 мм, тип 2 (пенопласт)
      expect(result.values['insulationThickness'], equals(100.0));
      expect(result.values['sheetsNeeded'], equals(210.0)); // пенопласт
    });

    test('throws exception for zero area', () {
      final calculator = CalculateWetFacade();
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
