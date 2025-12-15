import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_3d_panels.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('Calculate3dPanels', () {
    test('calculates panels needed correctly', () {
      final calculator = Calculate3dPanels();
      final inputs = {
        'area': 20.0, // 20 м²
        'panelSize': 50.0, // 50 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь панели: 0.5 * 0.5 = 0.25 м²
      // Количество: 20 / 0.25 * 1.1 = 88 панелей
      expect(result.values['panelsNeeded'], closeTo(88.0, 4.4));
      expect(result.values['area'], closeTo(20.0, 1.0));
    });

    test('calculates glue needed', () {
      final calculator = Calculate3dPanels();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей: 20 * 5 = 100 кг
      expect(result.values['glueNeeded'], closeTo(100.0, 5.0));
    });

    test('calculates primer needed', () {
      final calculator = Calculate3dPanels();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: 20 * 0.18 = 3.6 л
      expect(result.values['primerNeeded'], equals(3.6));
    });

    test('uses default panel size when missing', () {
      final calculator = Calculate3dPanels();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 50x50 см
      expect(result.values['panelsNeeded'], closeTo(88.0, 4.4));
    });

    test('handles different panel sizes', () {
      final calculator = Calculate3dPanels();
      final inputs = {
        'area': 20.0,
        'panelSize': 60.0, // 60 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь панели: 0.6 * 0.6 = 0.36 м²
      // Количество: 20 / 0.36 * 1.1 = ~62 панели
      expect(result.values['panelsNeeded'], greaterThan(60));
      expect(result.values['panelsNeeded'], lessThan(65));
    });

    test('throws exception for zero area', () {
      final calculator = Calculate3dPanels();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      // Теперь должно выбрасываться исключение при нулевой площади
      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });
  });
}
