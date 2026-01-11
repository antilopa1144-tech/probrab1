import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_three_d_panels_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateThreeDPanelsV2', () {
    late CalculateThreeDPanelsV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateThreeDPanelsV2();
      emptyPriceList = <PriceItem>[];
    });

    group('validation', () {
      test('returns error for area below minimum', () {
        final error = calculator.validateInputs({
          'inputMode': 0.0,
          'area': 2.0,
        });
        expect(error, isNotNull);
        expect(error, contains('3 м²'));
      });

      test('returns error for area above maximum', () {
        final error = calculator.validateInputs({
          'inputMode': 0.0,
          'area': 200.0,
        });
        expect(error, isNotNull);
        expect(error, contains('150 м²'));
      });

      test('returns error for length below minimum in dimensions mode', () {
        final error = calculator.validateInputs({
          'inputMode': 1.0,
          'length': 0.5,
          'height': 2.5,
        });
        expect(error, isNotNull);
        expect(error, contains('Длина'));
      });

      test('returns error for height below minimum in dimensions mode', () {
        final error = calculator.validateInputs({
          'inputMode': 1.0,
          'length': 4.0,
          'height': 1.5,
        });
        expect(error, isNotNull);
        expect(error, contains('Высота'));
      });

      test('returns error for invalid panel size', () {
        final error = calculator.validateInputs({
          'inputMode': 0.0,
          'area': 12.0,
          'panelSize': 20.0,
        });
        expect(error, isNotNull);
        expect(error, contains('панели'));
      });

      test('returns null for valid inputs', () {
        final error = calculator.validateInputs({
          'inputMode': 0.0,
          'area': 12.0,
          'panelSize': 50.0,
        });
        expect(error, isNull);
      });
    });

    group('calculation by area', () {
      test('calculates panels count correctly', () {
        final result = calculator({
          'inputMode': 0.0,
          'area': 12.0,
          'panelSize': 50.0,
        }, emptyPriceList);

        // Площадь панели: 0.5 × 0.5 = 0.25 м²
        // Количество: ceil(12 / 0.25 × 1.1) = ceil(52.8) = 53 шт
        expect(result.values['area'], equals(12.0));
        expect(result.values['panelArea'], equals(0.25));
        expect(result.values['panelsCount'], equals(53.0));
      });

      test('calculates glue amount correctly', () {
        final result = calculator({
          'inputMode': 0.0,
          'area': 12.0,
          'panelSize': 50.0,
        }, emptyPriceList);

        // Клей: 12 × 5.0 = 60 кг
        expect(result.values['glueKg'], equals(60.0));
      });

      test('calculates primer amount correctly', () {
        final result = calculator({
          'inputMode': 0.0,
          'area': 12.0,
          'panelSize': 50.0,
        }, emptyPriceList);

        // Грунтовка: 12 × 0.18 = 2.16 л
        expect(result.values['primerLiters'], equals(2.16));
      });

      test('calculates putty amount correctly', () {
        final result = calculator({
          'inputMode': 0.0,
          'area': 12.0,
          'panelSize': 50.0,
        }, emptyPriceList);

        // Шпаклёвка: 12 × 1.0 = 12 кг
        expect(result.values['puttyKg'], equals(12.0));
      });

      test('calculates paint only when paintable', () {
        final resultWithoutPaint = calculator({
          'inputMode': 0.0,
          'area': 12.0,
          'paintable': 0.0,
        }, emptyPriceList);
        expect(resultWithoutPaint.values['paintLiters'], equals(0.0));

        final resultWithPaint = calculator({
          'inputMode': 0.0,
          'area': 12.0,
          'paintable': 1.0,
        }, emptyPriceList);
        // Краска: 12 × 0.24 = 2.88 л
        expect(resultWithPaint.values['paintLiters'], equals(2.88));
      });

      test('calculates varnish only when withVarnish', () {
        final resultWithVarnish = calculator({
          'inputMode': 0.0,
          'area': 12.0,
          'withVarnish': 1.0,
        }, emptyPriceList);
        // Лак: 12 × 0.08 = 0.96 л
        expect(resultWithVarnish.values['varnishLiters'], equals(0.96));

        final resultWithoutVarnish = calculator({
          'inputMode': 0.0,
          'area': 12.0,
          'withVarnish': 0.0,
        }, emptyPriceList);
        expect(resultWithoutVarnish.values['varnishLiters'], equals(0.0));
      });

      test('calculates molding length for area mode', () {
        final result = calculator({
          'inputMode': 0.0,
          'area': 16.0,
          'panelSize': 50.0,
        }, emptyPriceList);

        // Периметр для площади: 4 × sqrt(16) = 16 м
        expect(result.values['moldingLength'], equals(16.0));
      });
    });

    group('calculation by dimensions', () {
      test('calculates area from dimensions correctly', () {
        final result = calculator({
          'inputMode': 1.0,
          'length': 4.0,
          'height': 3.0,
          'panelSize': 50.0,
        }, emptyPriceList);

        expect(result.values['area'], equals(12.0));
      });

      test('calculates molding length for dimensions mode', () {
        final result = calculator({
          'inputMode': 1.0,
          'length': 4.0,
          'height': 2.7,
          'panelSize': 50.0,
        }, emptyPriceList);

        // Периметр: (4 + 2.7) × 2 = 13.4 м
        expect(result.values['moldingLength'], equals(13.4));
      });
    });

    group('different panel sizes', () {
      test('calculates correctly for small panels (30cm)', () {
        final result = calculator({
          'inputMode': 0.0,
          'area': 9.0,
          'panelSize': 30.0,
        }, emptyPriceList);

        // Площадь панели: 0.3 × 0.3 = 0.09 м²
        expect(result.values['panelArea'], equals(0.09));
        // Проверяем что количество панелей рассчитано с запасом
        expect(result.values['panelsCount'], greaterThan(100.0));
      });

      test('calculates correctly for large panels (100cm)', () {
        final result = calculator({
          'inputMode': 0.0,
          'area': 10.0,
          'panelSize': 100.0,
        }, emptyPriceList);

        // Площадь панели: 1.0 × 1.0 = 1.0 м²
        expect(result.values['panelArea'], equals(1.0));
        // Проверяем что количество панелей рассчитано с запасом
        expect(result.values['panelsCount'], greaterThanOrEqualTo(11.0));
      });
    });

    group('edge cases', () {
      test('handles minimum valid area', () {
        final result = calculator({
          'inputMode': 0.0,
          'area': 3.0,
          'panelSize': 50.0,
        }, emptyPriceList);

        expect(result.values['area'], equals(3.0));
        expect(result.values['panelsCount'], greaterThan(0));
      });

      test('handles maximum valid area', () {
        final result = calculator({
          'inputMode': 0.0,
          'area': 150.0,
          'panelSize': 50.0,
        }, emptyPriceList);

        expect(result.values['area'], equals(150.0));
        expect(result.values['panelsCount'], greaterThan(0));
      });

      test('default values are applied when area is provided', () {
        final result = calculator({
          'area': 12.0,
        }, emptyPriceList);

        expect(result.values['area'], equals(12.0));
        expect(result.values['panelSizeCm'], equals(50.0)); // default panel size
      });
    });
  });
}
