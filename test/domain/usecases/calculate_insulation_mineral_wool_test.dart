import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_insulation_mineral_wool.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateInsulationMineralWool', () {
    test('calculates volume correctly', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0, // 20 м²
        'thickness': 100.0, // 100 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 20 * 0.1 = 2 м³
      expect(result.values['volume'], equals(2.0));
      expect(result.values['area'], equals(20.0));
    });

    test('calculates sheets needed', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
        'thickness': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь плиты: 0.72 м²
      // Количество: 20 / 0.72 * 1.05 = 29.17 → 30 плит
      expect(result.values['sheetsNeeded'], equals(30.0));
    });

    test('calculates weight', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
        'thickness': 100.0,
        'density': 50.0, // 50 кг/м³
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Вес: 2 м³ * 50 = 100 кг
      expect(result.values['weight'], equals(100.0));
    });

    test('calculates vapor barrier area', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
        'thickness': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Пароизоляция: 20 * 1.1 = 22 м²
      expect(result.values['vaporBarrierArea'], equals(22.0));
    });

    test('calculates fasteners needed', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
        'thickness': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крепёж: 20 * 5 = 100 шт
      expect(result.values['fastenersNeeded'], equals(100.0));
    });

    test('uses default thickness when missing', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 100 мм
      expect(result.values['thickness'], equals(100.0));
      expect(result.values['volume'], equals(2.0)); // 20 * 0.1
    });

    test('uses default density when missing', () {
      final calculator = CalculateInsulationMineralWool();
      final inputs = {
        'area': 20.0,
        'thickness': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 50 кг/м³
      // Вес: 2 * 50 = 100 кг
      expect(result.values['weight'], equals(100.0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateInsulationMineralWool();
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
