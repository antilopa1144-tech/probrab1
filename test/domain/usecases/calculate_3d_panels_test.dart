import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_3d_panels.dart';
import 'package:probrab_ai/data/models/price_item.dart';

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
      expect(result.values['panelsNeeded'], equals(88.0));
      expect(result.values['area'], equals(20.0));
    });

    test('calculates glue needed', () {
      final calculator = Calculate3dPanels();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Клей: 20 * 5 = 100 кг
      expect(result.values['glueNeeded'], equals(100.0));
    });

    test('calculates primer needed', () {
      final calculator = Calculate3dPanels();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Грунтовка: 20 * 0.2 = 4 кг
      expect(result.values['primerNeeded'], equals(4.0));
    });

    test('uses default panel size when missing', () {
      final calculator = Calculate3dPanels();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 50x50 см
      expect(result.values['panelsNeeded'], equals(88.0));
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

    test('handles zero area', () {
      final calculator = Calculate3dPanels();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['panelsNeeded'], equals(0.0));
      expect(result.values['glueNeeded'], equals(0.0));
    });
  });
}
