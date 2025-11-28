import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_roofing_metal.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateRoofingMetal', () {
    late CalculateRoofingMetal calculator;

    setUp(() {
      calculator = CalculateRoofingMetal();
    });

    test('calculates sheets needed correctly with 10% reserve', () {
      final inputs = {
        'area': 100.0, // 100 м² проекции
        'slope': 30.0, // 30 градусов
        'sheetWidth': 1.18,
        'sheetLength': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа = 1.18 * 2.5 = 2.95 м²
      // Реальная площадь = 100 / cos(30°) ≈ 115.5 м²
      // Листов = ceil(115.5 / 2.95 * 1.1) ≈ 44
      expect(result.values['sheetsNeeded'], greaterThanOrEqualTo(40));
      expect(result.values['sheetsNeeded'], lessThanOrEqualTo(50));
    });

    test('calculates real area with slope factor', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Реальная площадь = 100 / cos(30°) = 100 / 0.866 ≈ 115.5
      final expectedRealArea = 100 / cos(30 * pi / 180);
      expect(result.values['realArea'], closeTo(expectedRealArea, 1.0));
    });

    test('calculates screws needed (8 per m²)', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Саморезы ≈ realArea * 8
      final realArea = result.values['realArea']!;
      expect(result.values['screwsNeeded'], closeTo(realArea * 8, 10));
    });

    test('calculates waterproofing area with 10% overlap', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Гидроизоляция = realArea * 1.1
      final realArea = result.values['realArea']!;
      expect(result.values['waterproofingArea'], closeTo(realArea * 1.1, 1.0));
    });

    test('uses provided ridge length', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'ridgeLength': 12.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['ridgeLength'], equals(12.0));
    });

    test('estimates ridge length when not provided', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию ridgeLength = sqrt(area) = 10
      expect(result.values['ridgeLength'], equals(10.0));
    });

    test('handles valley length', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'valleyLength': 8.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['valleyLength'], equals(8.0));
    });

    test('handles flat slope correctly', () {
      final inputs = {
        'area': 100.0,
        'slope': 0.0, // плоская крыша
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // При 0° уклона realArea = area
      expect(result.values['realArea'], equals(100.0));
    });

    test('handles steep slope correctly', () {
      final inputs = {
        'area': 100.0,
        'slope': 45.0, // крутая крыша
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // При 45° realArea = 100 / cos(45°) ≈ 141.4
      final expectedRealArea = 100 / cos(45 * pi / 180);
      expect(result.values['realArea'], closeTo(expectedRealArea, 1.0));
    });

    test('uses default values when not provided', () {
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: slope=30, sheetWidth=1.18, sheetLength=2.5
      expect(result.values['realArea'], greaterThan(100.0));
    });

    test('handles zero area', () {
      final inputs = {
        'area': 0.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['area'], equals(0.0));
      expect(result.values['realArea'], equals(0.0));
      expect(result.values['sheetsNeeded'], equals(0.0));
    });

    test('preserves area in results', () {
      final inputs = {
        'area': 150.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['area'], equals(150.0));
    });

    test('calculates eave length from perimeter', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'perimeter': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['eaveLength'], equals(50.0));
    });

    test('estimates perimeter when not provided', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию perimeter = 4 * sqrt(area) = 40
      expect(result.values['eaveLength'], equals(40.0));
    });
  });
}
