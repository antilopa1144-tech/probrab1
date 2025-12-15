import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_sound_insulation.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateSoundInsulation', () {
    test('calculates sheets needed for mineral wool', () {
      final calculator = CalculateSoundInsulation();
      final inputs = {
        'area': 15.0, // 15 м²
        'thickness': 50.0, // 50 мм
        'insulationType': 1.0, // минвата
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа минваты: 0.72 м²
      // Количество: 15 / 0.72 * 1.05 = ~22 листа
      expect(result.values['sheetsNeeded'], closeTo(22.0, 1.1));
      expect(result.values['area'], closeTo(15.0, 0.8));
    });

    test('calculates volume', () {
      final calculator = CalculateSoundInsulation();
      final inputs = {
        'area': 15.0,
        'thickness': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 15 * 0.05 = 0.75 м³
      expect(result.values['volume'], equals(0.75));
    });

    test('calculates fasteners needed', () {
      final calculator = CalculateSoundInsulation();
      final inputs = {
        'area': 15.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крепёж: 15 * 4 = 60 шт
      expect(result.values['fastenersNeeded'], closeTo(60.0, 3.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateSoundInsulation();
      final inputs = {
        'area': 15.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: толщина 50 мм, тип 1 (минвата)
      expect(result.values['thickness'], closeTo(50.0, 2.5));
      expect(result.values['sheetsNeeded'], greaterThan(0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateSoundInsulation();
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
