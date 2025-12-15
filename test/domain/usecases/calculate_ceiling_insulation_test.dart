import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_ceiling_insulation.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

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
      expect(result.values['sheetsNeeded'], closeTo(30.0, 1.5));
      expect(result.values['area'], closeTo(20.0, 1.0));
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
      expect(result.values['sheetsNeeded'], closeTo(42.0, 2.1));
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
      expect(result.values['vaporBarrierArea'], closeTo(22.0, 1.1));
    });

    test('calculates fasteners needed', () {
      final calculator = CalculateCeilingInsulation();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крепёж: 20 * 4 = 80 шт
      expect(result.values['fastenersNeeded'], closeTo(80.0, 4.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateCeilingInsulation();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: толщина 100 мм, тип 1 (минвата)
      expect(result.values['insulationThickness'], closeTo(100.0, 5.0));
      expect(result.values['sheetsNeeded'], closeTo(30.0, 1.5)); // минвата
    });

    test('throws exception for zero area', () {
      final calculator = CalculateCeilingInsulation();
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
