import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_insulation_foam.dart';
import 'package:probrab_ai/data/models/price_item.dart';

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
      expect(result.values['area'], equals(20.0));
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
      expect(result.values['sheetsNeeded'], equals(42.0));
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
      expect(result.values['weight'], equals(25.0));
    });

    test('calculates glue needed', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей: 20 * 5 = 100 кг
      expect(result.values['glueNeeded'], equals(100.0));
    });

    test('calculates fasteners needed', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крепёж: 20 * 5 = 100 шт
      expect(result.values['fastenersNeeded'], equals(100.0));
    });

    test('calculates mesh area', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Сетка: 20 * 1.1 = 22 м²
      expect(result.values['meshArea'], equals(22.0));
    });

    test('uses default thickness when missing', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 50 мм
      expect(result.values['thickness'], equals(50.0));
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
      expect(result.values['weight'], equals(25.0));
    });

    test('handles zero area', () {
      final calculator = CalculateInsulationFoam();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['volume'], equals(0.0));
      expect(result.values['sheetsNeeded'], equals(0.0));
      expect(result.values['weight'], equals(0.0));
    });
  });
}
