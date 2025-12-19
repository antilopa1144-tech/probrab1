import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_paint_universal.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculatePaintUniversal', () {
    late CalculatePaintUniversal calculator;

    setUp(() {
      calculator = CalculatePaintUniversal();
    });

    group('Walls only (paintType=0)', () {
      test('calculates correctly with area input mode', () {
        final inputs = {
          'paintType': 0.0, // walls only
          'inputMode': 0.0, // by area
          'wallArea': 50.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        expect(result.values['wallArea'], equals(50.0));
        expect(result.values['ceilingArea'], equals(0.0));
        expect(result.values['totalArea'], equals(50.0));
        // Paint: (0.12*1.2 + 1*0.12) * 50 * 1.1 = 0.264 * 55 = 14.52
        expect(result.values['paintLiters'], closeTo(14.5, 1.0));
        // Primer: 0.12 * 50 * 1.1 = 6.6, rounds to 7
        expect(result.values['primerLiters'], closeTo(7.0, 1.0));
      });

      test('calculates correctly with room dimensions input mode', () {
        final inputs = {
          'paintType': 0.0, // walls only
          'inputMode': 1.0, // by dimensions
          'length': 5.0,
          'width': 4.0,
          'height': 2.7,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Wall area = (5 + 4) * 2 * 2.7 = 48.6
        expect(result.values['wallArea'], closeTo(48.6, 0.5));
        expect(result.values['ceilingArea'], equals(0.0));
        expect(result.values['totalArea'], closeTo(48.6, 0.5));
      });

      test('subtracts doors and windows from walls', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 50.0,
          'doorsWindows': 10.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Useful area = 50 - 10 = 40
        expect(result.values['wallArea'], equals(40.0));
        expect(result.values['totalArea'], equals(40.0));
      });
    });

    group('Ceiling only (paintType=1)', () {
      test('calculates correctly with area input mode', () {
        final inputs = {
          'paintType': 1.0, // ceiling only
          'inputMode': 0.0, // by area
          'ceilingArea': 30.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        expect(result.values['wallArea'], equals(0.0));
        expect(result.values['ceilingArea'], equals(30.0));
        expect(result.values['totalArea'], equals(30.0));
      });

      test('calculates correctly with room dimensions', () {
        final inputs = {
          'paintType': 1.0, // ceiling only
          'inputMode': 1.0, // by dimensions
          'length': 5.0,
          'width': 4.0,
          'height': 2.7,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Ceiling area = 5 * 4 = 20
        expect(result.values['ceilingArea'], equals(20.0));
        expect(result.values['wallArea'], equals(0.0));
        expect(result.values['totalArea'], equals(20.0));
      });

      test('does not subtract doors/windows from ceiling', () {
        final inputs = {
          'paintType': 1.0, // ceiling only
          'inputMode': 0.0,
          'ceilingArea': 30.0,
          'doorsWindows': 10.0, // should not affect ceiling
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        expect(result.values['ceilingArea'], equals(30.0));
        expect(result.values['totalArea'], equals(30.0));
      });
    });

    group('Walls and ceiling (paintType=2)', () {
      test('calculates both surfaces with area input mode', () {
        final inputs = {
          'paintType': 2.0, // walls and ceiling
          'inputMode': 0.0, // by area
          'wallArea': 50.0,
          'ceilingArea': 20.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        expect(result.values['wallArea'], equals(50.0));
        expect(result.values['ceilingArea'], equals(20.0));
        expect(result.values['totalArea'], equals(70.0));
      });

      test('calculates both surfaces with room dimensions', () {
        final inputs = {
          'paintType': 2.0, // walls and ceiling
          'inputMode': 1.0, // by dimensions
          'length': 5.0,
          'width': 4.0,
          'height': 2.7,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Wall area = (5 + 4) * 2 * 2.7 = 48.6
        // Ceiling area = 5 * 4 = 20
        expect(result.values['wallArea'], closeTo(48.6, 0.5));
        expect(result.values['ceilingArea'], equals(20.0));
        expect(result.values['totalArea'], closeTo(68.6, 0.5));
      });

      test('subtracts openings only from walls, not ceiling', () {
        final inputs = {
          'paintType': 2.0, // walls and ceiling
          'inputMode': 0.0,
          'wallArea': 50.0,
          'ceilingArea': 20.0,
          'doorsWindows': 10.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Walls: 50 - 10 = 40, Ceiling: 20 (unchanged)
        expect(result.values['wallArea'], equals(40.0));
        expect(result.values['ceilingArea'], equals(20.0));
        expect(result.values['totalArea'], equals(60.0));
      });
    });

    group('Layers calculation', () {
      test('calculates single layer correctly', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 1.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: (0.12 * 1.2) * 40 * 1.1 = 0.144 * 44 = 6.336
        expect(result.values['paintLiters'], closeTo(6.34, 0.5));
        expect(result.values['layers'], equals(1.0));
      });

      test('calculates three layers correctly', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 3.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: (0.144 + 2*0.12) * 40 * 1.1 = 0.384 * 44 = 16.896
        expect(result.values['paintLiters'], closeTo(16.9, 0.5));
        expect(result.values['layers'], equals(3.0));
      });

      test('calculates four layers correctly', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 4.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: (0.144 + 3*0.12) * 40 * 1.1 = 0.504 * 44 = 22.176
        // roundBulk(22.176) -> ceil(22.176) = 23.0 (since 10 < 22.176 < 100)
        expect(result.values['paintLiters'], equals(23.0));
        expect(result.values['layers'], equals(4.0));
      });
    });

    group('Reserve calculation', () {
      test('applies reserve percentage correctly', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 20.0, // 20% reserve
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: (0.144 + 0.12) * 40 * 1.2 = 0.264 * 48 = 12.672
        expect(result.values['paintLiters'], closeTo(12.7, 0.5));
      });

      test('works with zero reserve', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: 0.264 * 40 * 1.0 = 10.56
        expect(result.values['paintLiters'], closeTo(10.6, 0.5));
      });
    });

    group('Auxiliary materials', () {
      test('calculates rollers, brushes, and tape', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 100.0,
          'layers': 2.0,
          'reserve': 10.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Rollers: 100 / 50 = 2
        expect(result.values['rollersNeeded'], equals(2.0));
        // Brushes: 100 / 40 = 2.5, ceil to 3, clamp(2, 10)
        expect(result.values['brushesNeeded'], closeTo(3.0, 0.5));
        // Tape: calculated from estimated perimeter
        expect(result.values['tapeMeters'], greaterThan(0));
      });

      test('ensures minimum 2 brushes for small areas', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 10.0,
          'layers': 2.0,
          'reserve': 10.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        expect(result.values['brushesNeeded'], equals(2.0));
      });
    });

    group('Error handling', () {
      test('returns error for zero total area', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 0.0,
          'layers': 2.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        expect(result.values['error'], equals(1.0));
      });

      test('prevents negative useful area from large openings', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 20.0,
          'doorsWindows': 30.0, // more than wall area
          'layers': 2.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        expect(result.values['error'], equals(1.0));
      });
    });

    group('Price calculation', () {
      test('calculates total price with price list', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 10.0,
        };
        final priceList = [
          const PriceItem(
            sku: 'paint',
            name: 'Краска',
            price: 500,
            unit: 'л',
            imageUrl: '',
          ),
          const PriceItem(
            sku: 'primer',
            name: 'Грунтовка',
            price: 300,
            unit: 'л',
            imageUrl: '',
          ),
          const PriceItem(
            sku: 'tape',
            name: 'Малярный скотч',
            price: 50,
            unit: 'м',
            imageUrl: '',
          ),
        ];

        final result = calculator.calculate(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });
    });

    group('Default values', () {
      test('uses default values when not provided', () {
        final inputs = {
          'inputMode': 0.0,
          'wallArea': 40.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        expect(result.values['layers'], equals(2.0));
        expect(result.values['paintLiters'], greaterThan(0));
      });
    });
  });
}
