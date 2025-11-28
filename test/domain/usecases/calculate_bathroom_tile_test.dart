import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_bathroom_tile.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateBathroomTile', () {
    late CalculateBathroomTile calculator;

    setUp(() {
      calculator = CalculateBathroomTile();
    });

    test('calculates total tiles for walls and floor', () {
      final inputs = {
        'wallArea': 20.0, // 20 м² стен
        'floorArea': 5.0, // 5 м² пол
        'tileWidth': 30.0,
        'tileHeight': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь плитки = 0.3 * 0.3 = 0.09 м²
      // Стены: ceil(20 / 0.09 * 1.1) = ceil(244.4) = 245
      // Пол: ceil(5 / 0.09 * 1.1) = ceil(61.1) = 62
      // Всего: 245 + 62 = 307
      expect(result.values['totalTiles'], greaterThanOrEqualTo(300));
      expect(result.values['totalTiles'], lessThanOrEqualTo(320));
    });

    test('calculates grout needed correctly', () {
      final inputs = {
        'wallArea': 20.0,
        'floorArea': 5.0,
        'jointWidth': 3.0, // 3 мм шов
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Затирка = 25 м² * 1.5 * 0.3 = 11.25 кг
      expect(result.values['groutNeeded'], closeTo(11.25, 0.5));
    });

    test('calculates glue needed correctly', () {
      final inputs = {
        'wallArea': 20.0,
        'floorArea': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей = 25 м² * 4 = 100 кг
      expect(result.values['glueNeeded'], equals(100.0));
    });

    test('calculates crosses needed correctly', () {
      final inputs = {
        'wallArea': 9.0, // упрощённый расчёт
        'floorArea': 0.0,
        'tileWidth': 30.0,
        'tileHeight': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крестики = totalTiles * 4
      final tiles = result.values['totalTiles']!;
      expect(result.values['crossesNeeded'], equals(tiles * 4));
    });

    test('calculates waterproofing area correctly', () {
      final inputs = {
        'wallArea': 20.0,
        'floorArea': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Гидроизоляция = пол + 30% стен = 5 + 20*0.3 = 11 м²
      expect(result.values['waterproofingArea'], equals(11.0));
    });

    test('handles only wall area', () {
      final inputs = {
        'wallArea': 20.0,
        'floorArea': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['wallArea'], equals(20.0));
      expect(result.values['floorArea'], equals(0.0));
      expect(result.values['totalTiles'], greaterThan(0));
    });

    test('handles only floor area', () {
      final inputs = {
        'wallArea': 0.0,
        'floorArea': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['wallArea'], equals(0.0));
      expect(result.values['floorArea'], equals(10.0));
      expect(result.values['totalTiles'], greaterThan(0));
    });

    test('handles different tile sizes', () {
      final inputsSmall = {
        'wallArea': 10.0,
        'floorArea': 0.0,
        'tileWidth': 20.0, // 20x20
        'tileHeight': 20.0,
      };
      final inputsLarge = {
        'wallArea': 10.0,
        'floorArea': 0.0,
        'tileWidth': 60.0, // 60x60
        'tileHeight': 60.0,
      };
      final emptyPriceList = <PriceItem>[];

      final resultSmall = calculator(inputsSmall, emptyPriceList);
      final resultLarge = calculator(inputsLarge, emptyPriceList);

      // Маленькая плитка требует больше штук
      expect(
        resultSmall.values['totalTiles']!,
        greaterThan(resultLarge.values['totalTiles']!),
      );
    });

    test('uses default values when not provided', () {
      final inputs = {
        'wallArea': 10.0,
        'floorArea': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: tileWidth=30, tileHeight=30, jointWidth=3
      expect(result.values['totalTiles'], greaterThan(0));
      expect(result.values['groutNeeded'], greaterThan(0));
    });

    test('handles zero areas', () {
      final inputs = {
        'wallArea': 0.0,
        'floorArea': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['totalTiles'], equals(0.0));
      expect(result.values['glueNeeded'], equals(0.0));
    });

    test('preserves areas in results', () {
      final inputs = {
        'wallArea': 18.5,
        'floorArea': 4.2,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['wallArea'], equals(18.5));
      expect(result.values['floorArea'], equals(4.2));
    });
  });
}
