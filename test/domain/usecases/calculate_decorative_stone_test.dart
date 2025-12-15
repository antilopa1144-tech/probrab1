import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_decorative_stone.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateDecorativeStone', () {
    test('calculates stones needed correctly', () {
      final calculator = CalculateDecorativeStone();
      final inputs = {
        'area': 10.0, // 10 м²
        'stoneWidth': 20.0, // 20 см
        'stoneHeight': 5.0, // 5 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь камня: 0.2 * 0.05 = 0.01 м²
      // Количество: 10 / 0.01 * 1.15 = 1150 камней
      expect(result.values['stonesNeeded'], closeTo(1150.0, 57.5));
      expect(result.values['area'], equals(10.0));
    });

    test('calculates glue needed', () {
      final calculator = CalculateDecorativeStone();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей: 10 * 5 = 50 кг
      expect(result.values['glueNeeded'], closeTo(50.0, 2.5));
    });

    test('calculates grout needed', () {
      final calculator = CalculateDecorativeStone();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Затирка: 10 * 2 = 20 кг
      expect(result.values['groutNeeded'], closeTo(20.0, 1.0));
    });

    test('calculates primer needed', () {
      final calculator = CalculateDecorativeStone();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: 10 * 0.2 = 2 кг
      expect(result.values['primerNeeded'], equals(2.0));
    });

    test('uses default stone dimensions when missing', () {
      final calculator = CalculateDecorativeStone();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 20x5 см
      expect(result.values['stonesNeeded'], closeTo(1150.0, 57.5));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateDecorativeStone();
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
