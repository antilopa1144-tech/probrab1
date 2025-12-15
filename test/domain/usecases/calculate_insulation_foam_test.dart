import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_insulation_foam.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateInsulationFoam', () {
    test('calculates volume correctly', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 20.0, // 20 м²
        'thickness': 50.0, // 50 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 20 * 0.05 = 1 м³
      expect(result.values['volume'], equals(1.0));
      expect(result.values['area'], closeTo(20.0, 1.0));
    });

    test('calculates sheets needed', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 20.0,
        'thickness': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа: 0.5 м²
      // Количество: 20 / 0.5 * 1.05 = 42 листа
      expect(result.values['sheetsNeeded'], closeTo(42.0, 2.1));
    });

    test('calculates weight', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 20.0,
        'thickness': 50.0,
        'density': 25.0, // 25 кг/м³
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Вес: 1 м³ * 25 = 25 кг
      expect(result.values['weight'], closeTo(25.0, 1.2));
    });

    test('calculates glue needed', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей: 20 * 5 = 100 кг
      expect(result.values['glueNeeded'], closeTo(100.0, 5.0));
    });

    test('calculates fasteners needed', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крепёж: 20 * 5 = 100 шт
      expect(result.values['fastenersNeeded'], closeTo(100.0, 5.0));
    });

    test('calculates mesh area', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Сетка: 20 * 1.1 = 22 м²
      expect(result.values['meshArea'], closeTo(22.0, 1.1));
    });

    test('uses default thickness when missing', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 50 мм
      expect(result.values['thickness'], closeTo(50.0, 2.5));
      expect(result.values['volume'], equals(1.0)); // 20 * 0.05
    });

    test('uses default density when missing', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 20.0,
        'thickness': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 25 кг/м³
      expect(result.values['weight'], closeTo(25.0, 1.2));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateInsulationFoam();
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
