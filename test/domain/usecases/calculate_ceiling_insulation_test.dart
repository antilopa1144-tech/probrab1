import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_ceiling_insulation.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateCeilingInsulation', () {
    test('calculates sheets needed for mineral wool', () {
      final calculator = CalculateCeilingInsulation();
      final inputs = {
        'area': 20.0, // 20 м²
        'insulationThickness': 100.0, // 100 мм
        'insulationType': 1.0, // минвата
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа минваты: 0.72 м²
      // Количество: 20 / 0.72 * 1.05 = ~30 листов
      expect(result.values['sheetsNeeded'], equals(30.0));
      expect(result.values['area'], equals(20.0));
    });

    test('calculates sheets needed for foam', () {
      final calculator = CalculateCeilingInsulation();
      final inputs = {
        'area': 20.0,
        'insulationThickness': 100.0,
        'insulationType': 2.0, // пенопласт
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа пенопласта: 0.5 м²
      // Количество: 20 / 0.5 * 1.05 = 42 листа
      expect(result.values['sheetsNeeded'], equals(42.0));
    });

    test('calculates volume', () {
      final calculator = CalculateCeilingInsulation();
      final inputs = {
        'area': 20.0,
        'insulationThickness': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 20 * 0.1 = 2 м³
      expect(result.values['volume'], equals(2.0));
    });

    test('calculates vapor barrier area', () {
      final calculator = CalculateCeilingInsulation();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Пароизоляция: 20 * 1.1 = 22 м²
      expect(result.values['vaporBarrierArea'], equals(22.0));
    });

    test('calculates fasteners needed', () {
      final calculator = CalculateCeilingInsulation();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крепёж: 20 * 4 = 80 шт
      expect(result.values['fastenersNeeded'], equals(80.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateCeilingInsulation();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: толщина 100 мм, тип 1 (минвата)
      expect(result.values['insulationThickness'], equals(100.0));
      expect(result.values['sheetsNeeded'], equals(30.0)); // минвата
    });

    test('handles zero area', () {
      final calculator = CalculateCeilingInsulation();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['volume'], equals(0.0));
      expect(result.values['sheetsNeeded'], equals(0.0));
    });
  });
}
