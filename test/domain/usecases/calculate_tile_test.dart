import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_tile.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateTile', () {
    test('calculates tiles needed correctly', () {
      final calculator = CalculateTile();
      final inputs = {
        'inputMode': 1.0, // По площади
        'area': 10.0, // 10 м²
        'tileSize': 0.0, // Пользовательский размер
        'tileWidth': 30.0, // 30 см
        'tileHeight': 30.0, // 30 см
        'reserve': 10.0, // 10% запас
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь одной плитки: 0.3 * 0.3 = 0.09 м²
      // Количество: 10 / 0.09 * 1.1 = ~122 шт
      expect(result.values['tilesNeeded'], greaterThan(100));
      expect(result.values['tilesNeeded'], lessThan(130));
    });

    test('calculates grout and glue needed', () {
      final calculator = CalculateTile();
      final inputs = {
        'inputMode': 1.0, // По площади
        'area': 10.0,
        'tileSize': 0.0, // Пользовательский размер
        'tileWidth': 30.0,
        'tileHeight': 30.0,
        'jointWidth': 3.0, // 3 мм шов
        'reserve': 10.0, // 10% запас
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Затирка: 10 м² * 1.5 кг/м² * 0.3 = 4.5 кг
      expect(result.values['groutNeeded'], closeTo(4.5, 1));

      // Клей: 10 м² * 5.5 кг/м² = 55 кг (для плитки 30x30 используется расход 4.0)
      expect(result.values['glueNeeded'], closeTo(40.0, 5.0));
    });

    test('handles different tile sizes', () {
      final calculator = CalculateTile();
      final inputs = {
        'inputMode': 1.0, // По площади
        'area': 20.0,
        'tileSize': 60.0, // Квадратная плитка 60x60
        'reserve': 10.0, // 10% запас
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь плитки: 0.6 * 0.6 = 0.36 м²
      // Количество: 20 / 0.36 * 1.1 = ~62 шт
      expect(result.values['tilesNeeded'], greaterThan(50));
      expect(result.values['tilesNeeded'], lessThan(70));
    });

    test('calculates crosses needed', () {
      final calculator = CalculateTile();
      final inputs = {
        'inputMode': 1.0, // По площади
        'area': 10.0,
        'tileSize': 0.0, // Пользовательский размер
        'tileWidth': 30.0,
        'tileHeight': 30.0,
        'reserve': 10.0, // 10% запас
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крестики: ~4 шт на плитку
      final tilesNeeded = result.values['tilesNeeded']!;
      expect(result.values['crossesNeeded'], equals(tilesNeeded * 4));
    });
  });
}
