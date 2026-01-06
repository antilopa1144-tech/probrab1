import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wall_paint.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateWallPaint', () {
    late CalculateWallPaint calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateWallPaint();
      emptyPriceList = <PriceItem>[];
    });

    group('validation', () {
      test('returns error for zero area in area mode', () {
        final error = calculator.validateInputs({
          'inputMode': 1.0,
          'area': 0.0,
        });
        expect(error, isNotNull);
        expect(error, contains('больше нуля'));
      });

      test('returns error for invalid layers', () {
        final error = calculator.validateInputs({
          'area': 20.0,
          'layers': 0.0,
        });
        expect(error, isNotNull);
        expect(error, contains('слоёв'));
      });

      test('returns null for valid inputs', () {
        final error = calculator.validateInputs({
          'inputMode': 1.0,
          'area': 20.0,
          'perimeter': 18.0,
          'layers': 2.0,
        });
        expect(error, isNull);
      });

      test('allows zero area in dimensions mode', () {
        // В режиме по размерам площадь вычисляется
        final error = calculator.validateInputs({
          'inputMode': 0.0,
          'area': 0.0,
        });
        expect(error, isNull);
      });
    });

    group('input mode - by dimensions', () {
      test('calculates area from room dimensions', () {
        final result = calculator({
          'inputMode': 0.0,
          'length': 5.0,
          'width': 4.0,
          'height': 2.5,
        }, emptyPriceList);

        // Площадь стен: (5+4)*2*2.5 = 45 м²
        expect(result.values['usefulArea'], closeTo(45.0, 1.0));
      });

      test('calculates paint for room dimensions', () {
        final result = calculator({
          'inputMode': 0.0,
          'length': 5.0,
          'width': 4.0,
          'height': 2.5,
          'layers': 2.0,
          'consumption': 0.12,
        }, emptyPriceList);

        // Площадь: 45 м²
        // Первый слой: 45 × 0.12 × 1.2 = 6.48 л
        // Второй слой: 45 × 0.12 = 5.4 л
        // Всего: ~11.88 л + 5% = ~12.5 л
        expect(result.values['paintNeededLiters'], greaterThan(10.0));
        expect(result.values['paintNeededLiters'], lessThan(15.0));
      });
    });

    group('input mode - by area', () {
      test('uses provided area directly', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 30.0,
          'perimeter': 20.0,
        }, emptyPriceList);

        expect(result.values['usefulArea'], closeTo(30.0, 1.0));
      });

      test('calculates paint for given area', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 30.0,
          'perimeter': 20.0,
          'layers': 2.0,
          'consumption': 0.12,
        }, emptyPriceList);

        expect(result.values['paintNeededLiters'], greaterThan(7.0));
        expect(result.values['paintNeededLiters'], lessThan(12.0));
      });
    });

    group('window and door deductions', () {
      test('deducts window area from total', () {
        final resultNoWindows = calculator({
          'inputMode': 1.0,
          'area': 40.0,
          'perimeter': 20.0,
          'windowsArea': 0.0,
        }, emptyPriceList);

        final resultWithWindows = calculator({
          'inputMode': 1.0,
          'area': 40.0,
          'perimeter': 20.0,
          'windowsArea': 5.0,
        }, emptyPriceList);

        expect(
          resultWithWindows.values['usefulArea'],
          lessThan(resultNoWindows.values['usefulArea']!),
        );
      });

      test('deducts door area from total', () {
        final resultNoDoors = calculator({
          'inputMode': 1.0,
          'area': 40.0,
          'perimeter': 20.0,
          'doorsArea': 0.0,
        }, emptyPriceList);

        final resultWithDoors = calculator({
          'inputMode': 1.0,
          'area': 40.0,
          'perimeter': 20.0,
          'doorsArea': 4.0,
        }, emptyPriceList);

        expect(
          resultWithDoors.values['usefulArea'],
          lessThan(resultNoDoors.values['usefulArea']!),
        );
      });

      test('handles combined deductions', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 50.0,
          'perimeter': 24.0,
          'windowsArea': 6.0,
          'doorsArea': 4.0,
        }, emptyPriceList);

        // 50 - 6 - 4 = 40 м²
        expect(result.values['usefulArea'], closeTo(40.0, 1.0));
      });
    });

    group('layers calculation', () {
      test('single layer uses 20% more paint', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 20.0,
          'perimeter': 18.0,
          'layers': 1.0,
          'consumption': 0.1,
          'reserve': 0.0,
        }, emptyPriceList);

        // 20 × 0.1 × 1.2 = 2.4 л
        expect(result.values['paintNeededLiters'], closeTo(2.4, 0.5));
        expect(result.values['layers'], equals(1.0));
      });

      test('multiple layers add normally after first', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 20.0,
          'perimeter': 18.0,
          'layers': 3.0,
          'consumption': 0.1,
          'reserve': 0.0,
        }, emptyPriceList);

        // Первый: 20 × 0.1 × 1.2 = 2.4 л
        // Остальные 2: 20 × 0.1 × 2 = 4 л
        // Всего: 6.4 л
        expect(result.values['paintNeededLiters'], closeTo(6.4, 1.0));
        expect(result.values['layers'], equals(3.0));
      });
    });

    group('reserve calculation', () {
      test('applies reserve percentage', () {
        final resultNoReserve = calculator({
          'inputMode': 1.0,
          'area': 20.0,
          'perimeter': 18.0,
          'reserve': 0.0,
        }, emptyPriceList);

        final resultWithReserve = calculator({
          'inputMode': 1.0,
          'area': 20.0,
          'perimeter': 18.0,
          'reserve': 10.0,
        }, emptyPriceList);

        expect(
          resultWithReserve.values['paintNeededLiters'],
          greaterThan(resultNoReserve.values['paintNeededLiters']!),
        );
      });

      test('default reserve is 5%', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 20.0,
          'perimeter': 18.0,
        }, emptyPriceList);

        expect(result.values['reserve'], equals(5.0));
      });
    });

    group('additional materials', () {
      test('calculates primer', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 50.0,
          'perimeter': 28.0,
        }, emptyPriceList);

        // 50 × 0.12 × 1.05 = 6.3 л
        expect(result.values['primerNeededLiters'], greaterThan(5.0));
        expect(result.values['primerNeededLiters'], lessThan(8.0));
      });

      test('calculates masking tape', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 40.0,
          'perimeter': 24.0,
        }, emptyPriceList);

        // 24 × 1.2 × 1.05 = ~30 м
        expect(result.values['tapeNeededMeters'], greaterThan(25.0));
        expect(result.values['tapeNeededMeters'], lessThan(35.0));
      });

      test('calculates rollers needed', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 100.0,
          'perimeter': 40.0,
        }, emptyPriceList);

        // 100 / 50 = 2 валика
        expect(result.values['rollersNeeded'], equals(2.0));
      });

      test('calculates brushes needed', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 80.0,
          'perimeter': 36.0,
        }, emptyPriceList);

        // 80 / 40 = 2 кисти
        expect(result.values['brushesNeeded'], equals(2.0));
      });
    });

    group('edge cases', () {
      test('handles minimum valid area', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 1.0,
          'perimeter': 4.0,
        }, emptyPriceList);

        expect(result.values['usefulArea'], greaterThan(0));
        expect(result.values['paintNeededLiters'], greaterThan(0));
      });

      test('returns error indicator when area becomes zero after deductions', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 10.0,
          'perimeter': 12.0,
          'windowsArea': 6.0,
          'doorsArea': 5.0,
        }, emptyPriceList);

        // Полезная площадь <= 0, должен вернуть ошибку
        expect(result.values['usefulArea'], equals(0.0));
        expect(result.values['error'], equals(1.0));
      });

      test('handles large area', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 500.0,
          'perimeter': 90.0,
        }, emptyPriceList);

        expect(result.values['paintNeededLiters'], greaterThan(50.0));
      });

      test('handles zero dimensions by using minimum values', () {
        // getInput clamps values to minValue (0.1), so zero is treated as 0.1
        final result = calculator({
          'inputMode': 0.0,
          'length': 0.0,
          'width': 4.0,
          'height': 2.5,
        }, emptyPriceList);

        // Should calculate with length = 0.1 (clamped minimum)
        // Area = (0.1 + 4.0) * 2 * 2.5 = 20.5 м²
        expect(result.values['usefulArea'], greaterThan(0));
      });
    });

    group('consumption rates', () {
      test('uses default consumption when not specified', () {
        final result = calculator({
          'inputMode': 1.0,
          'area': 20.0,
          'perimeter': 18.0,
        }, emptyPriceList);

        // Default consumption is 0.12 л/м²
        expect(result.values['paintNeededLiters'], greaterThan(0));
      });

      test('respects custom consumption rate', () {
        final resultLow = calculator({
          'inputMode': 1.0,
          'area': 20.0,
          'perimeter': 18.0,
          'consumption': 0.08,
        }, emptyPriceList);

        final resultHigh = calculator({
          'inputMode': 1.0,
          'area': 20.0,
          'perimeter': 18.0,
          'consumption': 0.20,
        }, emptyPriceList);

        expect(
          resultHigh.values['paintNeededLiters'],
          greaterThan(resultLow.values['paintNeededLiters']!),
        );
      });
    });
  });
}
