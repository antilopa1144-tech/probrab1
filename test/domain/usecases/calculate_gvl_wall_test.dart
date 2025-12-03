import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_gvl_wall.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateGvlWall', () {
    test('calculates sheets needed correctly', () {
      final calculator = CalculateGvlWall();
      final inputs = {
        'area': 15.0, // 15 м²
        'layers': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа: 3 м²
      // Количество: 15 / 3 * 1 * 1.1 = 6 листов
      expect(result.values['sheetsNeeded'], equals(6.0));
      expect(result.values['area'], equals(15.0));
    });

    test('calculates with multiple layers', () {
      final calculator = CalculateGvlWall();
      final inputs = {
        'area': 15.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // 15 / 3 * 2 * 1.1 = 11 листов
      expect(result.values['sheetsNeeded'], equals(11.0));
      expect(result.values['layers'], equals(2.0));
    });

    test('calculates screws needed', () {
      final calculator = CalculateGvlWall();
      final inputs = {
        'area': 15.0,
        'layers': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Саморезы: 6 * 30 = 180 шт
      final sheetsNeeded = result.values['sheetsNeeded']!;
      expect(result.values['screwsNeeded'], equals(sheetsNeeded * 30));
    });

    test('calculates putty needed', () {
      final calculator = CalculateGvlWall();
      final inputs = {
        'area': 15.0,
        'layers': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Шпаклёвка: 15 * 1 * 1.5 = 22.5 кг
      expect(result.values['puttyNeeded'], equals(22.5));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateGvlWall();
      final inputs = {
        'area': 15.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['studsLength'], greaterThan(0));
      expect(result.values['guideLength'], greaterThan(0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateGvlWall();
      final inputs = {
        'area': 15.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 1 слой, высота 2.5 м
      expect(result.values['layers'], equals(1.0));
      expect(result.values['sheetsNeeded'], greaterThan(0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateGvlWall();
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
