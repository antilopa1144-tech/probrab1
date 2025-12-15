import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_mdf_panels.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

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
      expect(result.values['area'], closeTo(30.0, 1.5));
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
      expect(result.values['cornersLength'], closeTo(22.0, 1.1));
      expect(result.values['plinthLength'], closeTo(22.0, 1.1));
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

    test('throws exception for zero area', () {
      final calculator = CalculateMdfPanels();
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
