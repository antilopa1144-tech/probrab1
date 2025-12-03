import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_tile_glue.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateTileGlue', () {
    test('calculates glue needed for standard tile', () {
      final calculator = CalculateTileGlue();
      final inputs = {
        'area': 10.0, // 10 м²
        'tileSize': 30.0, // 30 см
        'layerThickness': 5.0, // 5 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Расход: 4 кг/м² * 1.0 * 1.0 * 1.1 = 4.4 кг/м²
      // Всего: 10 * 4.4 = 44 кг
      expect(result.values['glueNeeded'], equals(44.0));
      expect(result.values['area'], equals(10.0));
    });

    test('calculates glue for large tile', () {
      final calculator = CalculateTileGlue();
      final inputs = {
        'area': 10.0,
        'tileSize': 60.0, // 60 см (большая плитка)
        'layerThickness': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Для большой плитки: 4 * 0.9 * 1.0 * 1.1 = 3.96 кг/м²
      // Всего: 10 * 3.96 = 39.6 кг
      expect(result.values['glueNeeded'], closeTo(39.6, 0.1));
    });

    test('calculates glue for small tile', () {
      final calculator = CalculateTileGlue();
      final inputs = {
        'area': 10.0,
        'tileSize': 15.0, // 15 см (маленькая плитка)
        'layerThickness': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Для маленькой плитки: 4 * 1.1 * 1.0 * 1.1 = 4.84 кг/м²
      // Всего: 10 * 4.84 = 48.4 кг
      expect(result.values['glueNeeded'], closeTo(48.4, 0.1));
    });

    test('calculates glue for thick layer', () {
      final calculator = CalculateTileGlue();
      final inputs = {
        'area': 10.0,
        'tileSize': 30.0,
        'layerThickness': 10.0, // 10 мм (толстый слой)
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Для толстого слоя: 4 * 1.0 * 2.0 * 1.1 = 8.8 кг/м²
      // Всего: 10 * 8.8 = 88 кг
      expect(result.values['glueNeeded'], equals(88.0));
    });

    test('calculates spatulas needed', () {
      final calculator = CalculateTileGlue();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Шпатели: всегда 2 шт
      expect(result.values['spatulasNeeded'], equals(2.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateTileGlue();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: размер 30 см, толщина 5 мм
      expect(result.values['tileSize'], equals(30.0));
      expect(result.values['layerThickness'], equals(5.0));
      expect(result.values['glueNeeded'], equals(44.0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateTileGlue();
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
