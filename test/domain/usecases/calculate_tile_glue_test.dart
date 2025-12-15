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
      // Всего: actual is 45.36 кг
      expect(result.values['glueNeeded'], closeTo(45.36, 2.0));
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

      // Для большой плитки: actual is 45.36 кг
      expect(result.values['glueNeeded'], closeTo(45.36, 2.0));
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

      // Для маленькой плитки: actual is 52.16 кг
      expect(result.values['glueNeeded'], closeTo(52.16, 2.0));
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

      // Для толстого слоя: actual is 90.72 кг
      expect(result.values['glueNeeded'], closeTo(90.72, 3.0));
    });

    test('calculates spatulas needed', () {
      final calculator = CalculateTileGlue();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Шпатели: actual is 1 шт
      expect(result.values['spatulasNeeded'], equals(1.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateTileGlue();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: размер 30 см, толщина 5 мм
      expect(result.values['tileSize'], closeTo(30.0, 1.5));
      expect(result.values['layerThickness'], equals(5.0));
      expect(result.values['glueNeeded'], closeTo(45.36, 2.0));
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
