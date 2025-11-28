import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_soft_roofing.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateSoftRoofing', () {
    test('calculates rolls needed correctly', () {
      final calculator = CalculateSoftRoofing();
      final inputs = {
        'area': 50.0, // 50 м²
        'slope': 30.0, // 30 градусов
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь рулона: 10 м²
      // Реальная площадь с учётом уклона больше
      expect(result.values['rollsNeeded'], greaterThan(0));
      expect(result.values['area'], equals(50.0));
    });

    test('calculates real area with slope', () {
      final calculator = CalculateSoftRoofing();
      final inputs = {
        'area': 50.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Реальная площадь должна быть больше проекции
      expect(result.values['realArea'], greaterThan(50.0));
    });

    test('calculates underlayment area', () {
      final calculator = CalculateSoftRoofing();
      final inputs = {
        'area': 50.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Подкладочный ковёр: реальная площадь * 1.1
      final realArea = result.values['realArea']!;
      expect(result.values['underlaymentArea'], closeTo(realArea * 1.1, 0.1));
    });

    test('calculates nails needed', () {
      final calculator = CalculateSoftRoofing();
      final inputs = {
        'area': 50.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Гвозди: ~10 шт на м² реальной площади
      expect(result.values['nailsNeeded'], greaterThan(500));
    });

    test('calculates mastic needed', () {
      final calculator = CalculateSoftRoofing();
      final inputs = {
        'area': 50.0,
        'slope': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Мастика: реальная площадь * 0.5
      final realArea = result.values['realArea']!;
      expect(result.values['masticNeeded'], closeTo(realArea * 0.5, 0.1));
    });

    test('estimates ridge length when missing', () {
      final calculator = CalculateSoftRoofing();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Конёк должен быть рассчитан
      expect(result.values['ridgeStripLength'], greaterThan(0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateSoftRoofing();
      final inputs = {
        'area': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: уклон 30°
      expect(result.values['rollsNeeded'], greaterThan(0));
    });

    test('handles zero area', () {
      final calculator = CalculateSoftRoofing();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['rollsNeeded'], equals(0.0));
      expect(result.values['nailsNeeded'], equals(0.0));
    });
  });
}
