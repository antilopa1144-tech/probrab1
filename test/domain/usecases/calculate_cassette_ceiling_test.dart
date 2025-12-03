import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_cassette_ceiling.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateCassetteCeiling', () {
    test('calculates cassettes needed correctly', () {
      final calculator = CalculateCassetteCeiling();
      final inputs = {
        'area': 20.0, // 20 м²
        'cassetteSize': 60.0, // 60 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь кассеты: 0.6 * 0.6 = 0.36 м²
      // Количество: 20 / 0.36 * 1.05 = ~59 кассет
      expect(result.values['cassettesNeeded'], greaterThan(55));
      expect(result.values['cassettesNeeded'], lessThan(65));
      expect(result.values['area'], equals(20.0));
    });

    test('calculates guide length', () {
      final calculator = CalculateCassetteCeiling();
      final inputs = {
        'area': 20.0,
        'perimeter': 18.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Профили: равны периметру
      expect(result.values['guideLength'], equals(18.0));
    });

    test('calculates hangers needed', () {
      final calculator = CalculateCassetteCeiling();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Подвесы: 20 / (1.2 * 1.2) = ~14 шт
      expect(result.values['hangersNeeded'], greaterThan(10));
      expect(result.values['hangersNeeded'], lessThan(20));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateCassetteCeiling();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['guideLength'], greaterThan(0));
    });

    test('uses default cassette size when missing', () {
      final calculator = CalculateCassetteCeiling();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 60x60 см
      expect(result.values['cassettesNeeded'], greaterThan(0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateCassetteCeiling();
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
