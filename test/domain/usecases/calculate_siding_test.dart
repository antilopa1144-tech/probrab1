import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_siding.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateSiding', () {
    test('calculates panels needed correctly', () {
      final calculator = CalculateSiding();
      final inputs = {
        'area': 100.0, // 100 м²
        'panelWidth': 20.0, // 20 см
        'panelLength': 300.0, // 300 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь панели: 0.2 * 3.0 = 0.6 м²
      // Количество: 100 / 0.6 * 1.1 = ~184 панели
      expect(result.values['panelsNeeded'], greaterThan(180));
      expect(result.values['panelsNeeded'], lessThan(190));
      expect(result.values['area'], equals(100.0));
    });

    test('calculates screws needed', () {
      final calculator = CalculateSiding();
      final inputs = {
        'area': 100.0,
        'panelWidth': 20.0,
        'panelLength': 300.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Саморезы: количество панелей * 8
      final panelsNeeded = result.values['panelsNeeded']!;
      expect(result.values['screwsNeeded'], equals(panelsNeeded * 8));
    });

    test('calculates corner length', () {
      final calculator = CalculateSiding();
      final inputs = {
        'area': 100.0,
        'corners': 4.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Углы: 4 * 2.5 = 10 м
      expect(result.values['cornerLength'], equals(10.0));
    });

    test('calculates profile and strip lengths', () {
      final calculator = CalculateSiding();
      final inputs = {
        'area': 100.0,
        'perimeter': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // J-профиль, стартовая и финишная планки: равны периметру
      expect(result.values['jProfileLength'], equals(40.0));
      expect(result.values['startStripLength'], equals(40.0));
      expect(result.values['finishStripLength'], equals(40.0));
    });

    test('calculates soffit length', () {
      final calculator = CalculateSiding();
      final inputs = {
        'area': 100.0,
        'perimeter': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Софиты: 40 * 0.1 = 4 м
      expect(result.values['soffitLength'], equals(4.0));
    });

    test('uses provided soffit length', () {
      final calculator = CalculateSiding();
      final inputs = {
        'area': 100.0,
        'perimeter': 40.0,
        'soffitLength': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['soffitLength'], equals(10.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateSiding();
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: ширина 20 см, длина 300 см, углы 4
      expect(result.values['panelsNeeded'], greaterThan(0));
      expect(result.values['cornerLength'], equals(10.0)); // 4 * 2.5
    });

    test('handles zero area', () {
      final calculator = CalculateSiding();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['panelsNeeded'], equals(0.0));
      expect(result.values['screwsNeeded'], equals(0.0));
    });
  });
}
