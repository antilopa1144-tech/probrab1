import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_mdf_panels.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateMdfPanels', () {
    test('calculates panels needed correctly', () {
      final calculator = CalculateMdfPanels();
      final inputs = {
        'area': 30.0, // 30 м²
        'panelWidth': 20.0, // 20 см
        'panelLength': 260.0, // 260 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь панели: 0.2 * 2.6 = 0.52 м²
      // Количество: 30 / 0.52 * 1.1 = ~64 панели
      expect(result.values['panelsNeeded'], greaterThan(60));
      expect(result.values['panelsNeeded'], lessThan(70));
      expect(result.values['area'], equals(30.0));
    });

    test('calculates clamps needed', () {
      final calculator = CalculateMdfPanels();
      final inputs = {
        'area': 30.0,
        'panelWidth': 20.0,
        'panelLength': 260.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Кляймеры: количество панелей * 4
      final panelsNeeded = result.values['panelsNeeded']!;
      expect(result.values['clampsNeeded'], equals(panelsNeeded * 4));
    });

    test('calculates corners and plinth length', () {
      final calculator = CalculateMdfPanels();
      final inputs = {
        'area': 30.0,
        'perimeter': 22.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Уголки и плинтус: равны периметру
      expect(result.values['cornersLength'], equals(22.0));
      expect(result.values['plinthLength'], equals(22.0));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateMdfPanels();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['cornersLength'], greaterThan(0));
    });

    test('uses default panel dimensions when missing', () {
      final calculator = CalculateMdfPanels();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: ширина 20 см, длина 260 см
      expect(result.values['panelsNeeded'], greaterThan(0));
    });

    test('handles zero area', () {
      final calculator = CalculateMdfPanels();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['panelsNeeded'], equals(0.0));
      expect(result.values['clampsNeeded'], equals(0.0));
    });
  });
}
