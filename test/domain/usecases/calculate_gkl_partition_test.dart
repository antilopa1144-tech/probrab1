import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_gkl_partition.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateGklPartition', () {
    late CalculateGklPartition calculator;

    setUp(() {
      calculator = CalculateGklPartition();
    });

    test('calculates sheets needed correctly with 10% reserve', () {
      final inputs = {
        'area': 12.0, // 12 м²
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Листов = ceil(12 / 3 * 2 * 1.1) = ceil(8.8) = 9 листов
      expect(result.values['sheetsNeeded'], equals(9.0));
    });

    test('calculates screws needed correctly', () {
      final inputs = {
        'area': 12.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // 30 саморезов на лист
      final sheets = result.values['sheetsNeeded']!;
      expect(result.values['screwsNeeded'], equals(sheets * 30));
    });

    test('calculates putty needed correctly', () {
      final inputs = {
        'area': 12.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Шпаклёвка = 12 * 2 * 1.5 = 36 кг
      expect(result.values['puttyNeeded'], equals(36.0));
    });

    test('calculates guide length correctly with perimeter', () {
      final inputs = {
        'area': 12.0,
        'layers': 2.0,
        'perimeter': 10.0, // заданный периметр
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Направляющие = периметр * 2 = 20 м
      expect(result.values['guideLength'], equals(20.0));
    });

    test('calculates studs length correctly', () {
      final inputs = {
        'area': 12.0,
        'layers': 2.0,
        'perimeter': 6.0, // 6 м периметр
        'height': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Стойки = ceil(6 / 0.6) * 2.5 = 10 * 2.5 = 25 м
      expect(result.values['studsLength'], equals(25.0));
    });

    test('handles single layer correctly', () {
      final inputs = {
        'area': 12.0,
        'layers': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Листов = ceil(12 / 3 * 1 * 1.1) = ceil(4.4) = 5 листов
      expect(result.values['sheetsNeeded'], equals(5.0));
    });

    test('uses default values when not provided', () {
      final inputs = {
        'area': 12.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию layers=2, height=2.5
      expect(result.values['sheetsNeeded'], equals(9.0));
    });

    test('handles zero area', () {
      final inputs = {
        'area': 0.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['area'], equals(0.0));
      expect(result.values['sheetsNeeded'], equals(0.0));
    });

    test('handles large partition', () {
      final inputs = {
        'area': 100.0, // большая перегородка
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // ceil(100 / 3 * 2 * 1.1) = ceil(73.3) = 74 листа
      expect(result.values['sheetsNeeded'], equals(74.0));
    });

    test('calculates total price with price list', () {
      final inputs = {
        'area': 12.0,
        'layers': 2.0,
      };
      final priceList = [
        PriceItem()
          ..sku = 'gkl'
          ..name = 'Гипсокартон'
          ..price = 400
          ..unit = 'лист',
      ];

      final result = calculator(inputs, priceList);

      // 9 листов * 400 = 3600 руб
      expect(result.totalPrice, equals(3600.0));
    });

    test('preserves area in results', () {
      final inputs = {
        'area': 15.5,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['area'], equals(15.5));
    });
  });
}
