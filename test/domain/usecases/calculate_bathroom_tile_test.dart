import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_bathroom_tile.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateBathroomTile', () {
    test('calculates total tiles correctly', () {
      final calculator = CalculateBathroomTile();
      final inputs = {
        'wallArea': 20.0, // 20 м² стены
        'floorArea': 5.0, // 5 м² пол
        'tileWidth': 30.0, // 30 см
        'tileHeight': 30.0, // 30 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь плитки: 0.3 * 0.3 = 0.09 м²
      // Стены: 20 / 0.09 * 1.1 = ~245 шт
      // Пол: 5 / 0.09 * 1.1 = ~62 шт
      // Всего: ~307 шт
      expect(result.values['totalTiles'], greaterThan(300));
      expect(result.values['totalTiles'], lessThan(320));
      expect(result.values['wallArea'], equals(20.0));
      expect(result.values['floorArea'], equals(5.0));
    });

    test('calculates grout needed', () {
      final calculator = CalculateBathroomTile();
      final inputs = {
        'wallArea': 20.0,
        'floorArea': 5.0,
        'jointWidth': 3.0, // 3 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Затирка: 25 * 1.5 * 0.3 = 11.25 кг
      expect(result.values['groutNeeded'], closeTo(11.25, 0.1));
    });

    test('calculates glue needed', () {
      final calculator = CalculateBathroomTile();
      final inputs = {
        'wallArea': 20.0,
        'floorArea': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей: 25 * 4 = 100 кг
      expect(result.values['glueNeeded'], equals(100.0));
    });

    test('calculates crosses needed', () {
      final calculator = CalculateBathroomTile();
      final inputs = {
        'wallArea': 20.0,
        'floorArea': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крестики: количество плиток * 4
      final totalTiles = result.values['totalTiles']!;
      expect(result.values['crossesNeeded'], equals(totalTiles * 4));
    });

    test('calculates waterproofing area', () {
      final calculator = CalculateBathroomTile();
      final inputs = {
        'wallArea': 20.0,
        'floorArea': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Гидроизоляция: 5 + 20 * 0.3 = 11 м²
      expect(result.values['waterproofingArea'], equals(11.0));
    });

    test('uses default tile size when missing', () {
      final calculator = CalculateBathroomTile();
      final inputs = {
        'wallArea': 20.0,
        'floorArea': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 30x30 см
      expect(result.values['totalTiles'], greaterThan(0));
    });

    test('handles zero areas', () {
      final calculator = CalculateBathroomTile();
      final inputs = {
        'wallArea': 0.0,
        'floorArea': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['totalTiles'], equals(0.0));
      expect(result.values['glueNeeded'], equals(0.0));
    });
  });
}
