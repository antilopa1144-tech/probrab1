import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_roofing_metal.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateRoofingMetal', () {
    test('calculates sheets needed correctly', () {
      final calculator = CalculateRoofingMetal();
      final inputs = {
        'area': 50.0, // 50 м²
        'slope': 30.0, // 30 градусов
        'sheetWidth': 1.18, // 1.18 м
        'sheetLength': 2.5, // 2.5 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа: 1.18 * 2.5 = 2.95 м²
      // Реальная площадь с учётом уклона больше
      expect(result.values['sheetsNeeded'], greaterThan(0));
      expect(result.values['area'], equals(50.0));
    });

    test('calculates real area with slope', () {
      final calculator = CalculateRoofingMetal();
      final inputs = {
        'area': 50.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Реальная площадь должна быть больше проекции
      expect(result.values['realArea'], greaterThan(50.0));
    });

    test('calculates screws needed', () {
      final calculator = CalculateRoofingMetal();
      final inputs = {
        'area': 50.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Саморезы: ~8 шт на м² реальной площади
      expect(result.values['screwsNeeded'], greaterThan(400));
    });

    test('calculates waterproofing area', () {
      final calculator = CalculateRoofingMetal();
      final inputs = {
        'area': 50.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Гидроизоляция: реальная площадь * 1.1
      final realArea = result.values['realArea']!;
      expect(result.values['waterproofingArea'], closeTo(realArea * 1.1, 0.1));
    });

    test('estimates ridge length when missing', () {
      final calculator = CalculateRoofingMetal();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Конёк должен быть рассчитан
      expect(result.values['ridgeLength'], greaterThan(0));
    });

    test('uses provided ridge and valley lengths', () {
      final calculator = CalculateRoofingMetal();
      final inputs = {
        'area': 50.0,
        'ridgeLength': 10.0,
        'valleyLength': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['ridgeLength'], equals(10.0));
      expect(result.values['valleyLength'], equals(5.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateRoofingMetal();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: уклон 30°, ширина 1.18 м, длина 2.5 м
      expect(result.values['sheetsNeeded'], greaterThan(0));
    });

    test('handles zero area', () {
      final calculator = CalculateRoofingMetal();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['sheetsNeeded'], equals(0.0));
      expect(result.values['screwsNeeded'], equals(0.0));
    });
  });
}
