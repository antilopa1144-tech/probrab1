import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_pvc_panels.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculatePvcPanels', () {
    test('calculates panels needed correctly', () {
      final calculator = CalculatePvcPanels();
      final inputs = {
        'area': 30.0, // 30 м²
        'panelWidth': 25.0, // 25 см
        'panelLength': 300.0, // 300 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь панели: 0.25 * 3.0 = 0.75 м²
      // Количество: 30 / 0.75 * 1.1 = 44 панели
      expect(result.values['panelsNeeded'], closeTo(44.0, 2.2));
      expect(result.values['area'], closeTo(30.0, 1.5));
    });

    test('calculates screws needed', () {
      final calculator = CalculatePvcPanels();
      final inputs = {
        'area': 30.0,
        'panelWidth': 25.0,
        'panelLength': 300.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Саморезы: 44 * 6 = 264 шт
      final panelsNeeded = result.values['panelsNeeded']!;
      expect(result.values['screwsNeeded'], equals(panelsNeeded * 6));
    });

    test('calculates profile lengths', () {
      final calculator = CalculatePvcPanels();
      final inputs = {
        'area': 30.0,
        'perimeter': 22.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Профили: равны периметру
      expect(result.values['startProfileLength'], closeTo(22.0, 1.1));
      expect(result.values['finishProfileLength'], closeTo(22.0, 1.1));
      expect(result.values['cornerLength'], closeTo(22.0, 1.1));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculatePvcPanels();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['startProfileLength'], greaterThan(0));
    });

    test('uses default panel dimensions when missing', () {
      final calculator = CalculatePvcPanels();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: ширина 25 см, длина 300 см
      expect(result.values['panelsNeeded'], greaterThan(0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculatePvcPanels();
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
