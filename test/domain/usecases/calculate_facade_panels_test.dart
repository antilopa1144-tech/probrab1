import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_facade_panels.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateFacadePanels', () {
    test('calculates panels needed correctly', () {
      final calculator = CalculateFacadePanels();
      final inputs = {
        'area': 100.0, // 100 м²
        'panelWidth': 50.0, // 50 см
        'panelHeight': 100.0, // 100 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь панели: 0.5 * 1.0 = 0.5 м²
      // Количество: 100 / 0.5 * 1.1 = 220 панелей
      expect(result.values['panelsNeeded'], equals(220.0));
      expect(result.values['area'], equals(100.0));
    });

    test('calculates fasteners needed', () {
      final calculator = CalculateFacadePanels();
      final inputs = {
        'area': 100.0,
        'panelWidth': 50.0,
        'panelHeight': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Крепления: 220 * 4 = 880 шт
      final panelsNeeded = result.values['panelsNeeded']!;
      expect(result.values['fastenersNeeded'], equals(panelsNeeded * 4));
    });

    test('calculates corners and start strip length', () {
      final calculator = CalculateFacadePanels();
      final inputs = {
        'area': 100.0,
        'perimeter': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Уголки и стартовая планка: равны периметру
      expect(result.values['cornersLength'], equals(40.0));
      expect(result.values['startStripLength'], equals(40.0));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateFacadePanels();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['cornersLength'], greaterThan(0));
      expect(result.values['startStripLength'], greaterThan(0));
    });

    test('uses default panel dimensions when missing', () {
      final calculator = CalculateFacadePanels();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 50x100 см
      expect(result.values['panelsNeeded'], greaterThan(0));
    });

    test('handles zero area', () {
      final calculator = CalculateFacadePanels();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['panelsNeeded'], equals(0.0));
      expect(result.values['fastenersNeeded'], equals(0.0));
    });
  });
}
