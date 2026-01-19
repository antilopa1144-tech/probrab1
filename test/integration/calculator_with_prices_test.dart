import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_plaster.dart';
import 'package:probrab_ai/domain/usecases/calculate_tile.dart';
import 'package:probrab_ai/domain/usecases/calculate_screed_unified.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Calculator Integration Tests with Prices', () {
    test('CalculatePlaster calculates price correctly', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 100.0,
        'thickness': 10.0,
        'type': 1.0,
      };
      
      final priceList = createTestPriceList({
        'plaster': 250.0, // 250 руб/кг
      });

      final result = calculator(inputs, priceList);

      // Проверяем, что цена рассчитана
      expect(result.totalPrice, isNotNull);
      expect(result.totalPrice, greaterThan(0));
      
      // Проверяем, что количество материала рассчитано
      expect(result.values['plasterKg'], greaterThan(0));
    });

    test('CalculateTile calculates price with multiple items', () {
      final calculator = CalculateTile();
      final inputs = {
        'area': 10.0,
        'tileWidth': 30.0,
        'tileHeight': 30.0,
      };
      
      final priceList = createTestPriceList({
        'tile': 800.0, // 800 руб/м²
        'glue': 300.0, // 300 руб/мешок
        'grout': 200.0, // 200 руб/кг
      });

      final result = calculator(inputs, priceList);

      expect(result.totalPrice, isNotNull);
      expect(result.totalPrice, greaterThan(0));
      
      // Проверяем, что все материалы рассчитаны
      expect(result.values['tilesNeeded'], greaterThan(0));
      expect(result.values['glueNeeded'], greaterThan(0));
      expect(result.values['groutNeeded'], greaterThan(0));
    });

    test('CalculateScreedUnified calculates price with cement and sand', () {
      final calculator = CalculateScreedUnified();
      final inputs = {
        'inputMode': 0.0,
        'area': 20.0,
        'thickness': 50.0,
        'screedType': 0.0, // ЦПС
        'materialType': 1.0, // Самозамес
      };

      final priceList = createTestPriceList({
        'cement': 300.0, // 300 руб/мешок
        'sand': 500.0, // 500 руб/м³
      });

      final result = calculator(inputs, priceList);

      expect(result.totalPrice, isNotNull);
      expect(result.totalPrice, greaterThan(0));

      // Проверяем количество материалов
      expect(result.values['cementBags'], greaterThan(0));
      expect(result.values['sandCbm'], greaterThan(0));
    });

    test('calculator handles missing prices gracefully', () {
      final calculator = CalculatePlaster();
      final inputs = {
        'area': 100.0,
        'thickness': 10.0,
      };
      
      // Пустой прайс-лист
      final emptyPriceList = createEmptyPriceList();

      final result = calculator(inputs, emptyPriceList);

      // Должен рассчитать количество, но без цены
      expect(result.values['plasterKg'], greaterThan(0));
      expect(result.totalPrice, isNull);
    });

    test('calculator uses standard price list', () {
      final calculator = CalculateTile();
      final inputs = {
        'area': 10.0,
        'tileWidth': 30.0,
        'tileHeight': 30.0,
      };
      
      final standardPrices = createStandardTestPriceList();

      final result = calculator(inputs, standardPrices);

      // Должен найти цены из стандартного списка
      expect(result.totalPrice, isNotNull);
    });

    test('multiple calculators work with same price list', () {
      final priceList = createStandardTestPriceList();

      final plasterCalc = CalculatePlaster();
      final tileCalc = CalculateTile();
      final screedCalc = CalculateScreedUnified();

      final plasterResult = plasterCalc(
        {'area': 50.0, 'thickness': 10.0},
        priceList,
      );

      final tileResult = tileCalc(
        {'area': 10.0, 'tileWidth': 30.0, 'tileHeight': 30.0},
        priceList,
      );

      final screedResult = screedCalc(
        {'inputMode': 0.0, 'area': 20.0, 'thickness': 50.0, 'screedType': 0.0, 'materialType': 1.0},
        priceList,
      );

      // Все должны рассчитать цены
      expect(plasterResult.totalPrice, isNotNull);
      expect(tileResult.totalPrice, isNotNull);
      expect(screedResult.totalPrice, isNotNull);
    });
  });
}
