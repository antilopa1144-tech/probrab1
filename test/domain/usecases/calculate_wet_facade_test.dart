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
      expect(result.values['area'], closeTo(100.0, 5.0));
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
      expect(result.values['sheetsNeeded'], closeTo(210.0, 10.5));
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
      expect(result.values['glueNeeded'], closeTo(500.0, 25.0));
    });

    test('calculates fasteners needed', () {
      final calculator = CalculateWetFacade();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крепёж: 100 * 5 = 500 шт
      expect(result.values['fastenersNeeded'], closeTo(500.0, 25.0));
    });

    test('calculates mesh area', () {
      final calculator = CalculateWetFacade();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Сетка: 100 * 1.1 = 110 м²
      expect(result.values['meshArea'], closeTo(110.0, 5.5));
    });

    test('calculates plaster and finish needed', () {
      final calculator = CalculateWetFacade();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Штукатурка: 100 * 5 = 500 кг
      expect(result.values['plasterNeeded'], closeTo(500.0, 25.0));
      // Финиш: 100 * 0.5 = 50 кг
      expect(result.values['finishNeeded'], closeTo(50.0, 2.5));
    });

    test('uses default values when missing', () {
      final calculator = CalculateWetFacade();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: толщина 100 мм, тип 2 (пенопласт)
      expect(result.values['insulationThickness'], closeTo(100.0, 5.0));
      expect(result.values['sheetsNeeded'], closeTo(210.0, 10.5)); // пенопласт
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
