import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_gkl_partition.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateGklPartition', () {
    test('calculates sheets needed correctly', () {
      final calculator = CalculateGklPartition();
      final inputs = {
        'area': 12.0, // 12 м²
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь листа: 3 м²
      // Количество: 12 / 3 * 2 * 1.1 = 8.8 → 9 листов
      expect(result.values['sheetsNeeded'], equals(9.0));
      expect(result.values['area'], equals(12.0));
    });

    test('calculates screws needed', () {
      final calculator = CalculateGklPartition();
      final inputs = {
        'area': 12.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Саморезы: 9 листов * 30 = 270 шт
      final sheetsNeeded = result.values['sheetsNeeded']!;
      expect(result.values['screwsNeeded'], equals(sheetsNeeded * 30));
    });

    test('calculates putty needed', () {
      final calculator = CalculateGklPartition();
      final inputs = {
        'area': 12.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Шпаклёвка: 12 * 2 * 1.5 = 36 кг
      expect(result.values['puttyNeeded'], equals(36.0));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateGklPartition();
      final inputs = {
        'area': 12.0, // комната 3x4 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['studsLength'], greaterThan(0));
      expect(result.values['guideLength'], greaterThan(0));
    });

    test('uses provided perimeter', () {
      final calculator = CalculateGklPartition();
      final inputs = {
        'area': 12.0,
        'perimeter': 14.0, // периметр 14 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Направляющий профиль: 14 * 2 = 28 м
      expect(result.values['guideLength'], equals(28.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateGklPartition();
      final inputs = {
        'area': 12.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 2 слоя, высота 2.5 м
      expect(result.values['layers'], equals(2.0));
      expect(result.values['sheetsNeeded'], greaterThan(0));
    });

    test('handles zero area', () {
      final calculator = CalculateGklPartition();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['sheetsNeeded'], equals(0.0));
      expect(result.values['puttyNeeded'], equals(0.0));
    });
  });
}
