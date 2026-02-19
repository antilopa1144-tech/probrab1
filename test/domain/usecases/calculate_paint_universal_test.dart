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
        // Paint: (0.12*1.2 + 1*0.12) * 50 * 1.1 + 0.3 = 0.264 * 55 + 0.3 = 14.52 + 0.3 = 14.82
        // roundBulk(14.82) = 15.0 (10-100 range => ceil)
        expect(result.values['paintLiters'], equals(15.0));
        // Primer: 0.15 * 50 * 1.1 = 8.25 => roundBulk => 9.0
        expect(result.values['primerLiters'], closeTo(9.0, 1.0));
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

      test('applies 15% ceiling premium to paint consumption', () {
        // Ceiling-only: paint gets 1.15x vs same area walls-only
        final ceilingInputs = {
          'paintType': 1.0, // ceiling
          'inputMode': 0.0,
          'ceilingArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
        };
        final wallInputs = {
          'paintType': 0.0, // walls
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
        };
        final emptyPriceList = <PriceItem>[];

        final ceilingResult =
            calculator.calculate(ceilingInputs, emptyPriceList);
        // Need a fresh instance to avoid caching
        final calculator2 = CalculatePaintUniversal();
        final wallResult = calculator2.calculate(wallInputs, emptyPriceList);

        // Wall: (0.10*1.2 + 0.10) * 40 + 0.3 = 0.22 * 40 + 0.3 = 9.1
        // Ceiling: (0.10*1.2 + 0.10) * 1.15 * 40 + 0.3 = 0.253 * 40 + 0.3 = 10.42
        // Ceiling paint should be higher than wall paint (both before rounding)
        final ceilingPaint = ceilingResult.values['paintLiters']!;
        final wallPaint = wallResult.values['paintLiters']!;
        expect(ceilingPaint, greaterThan(wallPaint));
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

      test('ceiling portion uses 15% extra paint vs wall portion', () {
        // With both walls and ceiling, verify ceiling part costs more per m^2
        final inputs = {
          'paintType': 2.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'ceilingArea': 40.0, // same area as walls
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Wall: 0.22 * 40 = 8.8
        // Ceiling: 0.22 * 1.15 * 40 = 10.12
        // Total raw: 8.8 + 10.12 = 18.92 + 0.3 = 19.22
        // roundBulk(19.22) = 20.0
        expect(result.values['paintLiters'], equals(20.0));
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

        // Paint: (0.12 * 1.2) * 40 * 1.1 + 0.3 = 0.144 * 44 + 0.3 = 6.336 + 0.3 = 6.636
        // roundBulk(6.636) = 7.0 (1-10 range => ceil to 0.5)
        expect(result.values['paintLiters'], equals(7.0));
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

        // Paint: (0.144 + 2*0.12) * 40 * 1.1 + 0.3 = 0.384 * 44 + 0.3 = 16.896 + 0.3 = 17.196
        // roundBulk(17.196) = 18.0 (10-100 range => ceil)
        expect(result.values['paintLiters'], equals(18.0));
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

        // Paint: (0.144 + 3*0.12) * 40 * 1.1 + 0.3 = 0.504 * 44 + 0.3 = 22.176 + 0.3 = 22.476
        // roundBulk(22.476) = 23.0 (10-100 range => ceil)
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

        // Paint: (0.144 + 0.12) * 40 * 1.2 + 0.3 = 0.264 * 48 + 0.3 = 12.672 + 0.3 = 12.972
        // roundBulk(12.972) = 13.0 (10-100 range => ceil)
        expect(result.values['paintLiters'], equals(13.0));
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

        // Paint: 0.264 * 40 * 1.0 + 0.3 = 10.56 + 0.3 = 10.86
        // roundBulk(10.86) = 11.0 (10-100 range => ceil)
        expect(result.values['paintLiters'], equals(11.0));
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

      test('primer always included with 0.15 l/m2 rate', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Primer: 0.15 * 40 * 1.0 = 6.0
        // roundBulk(6.0) = 6.0
        expect(result.values['primerLiters'], equals(6.0));
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

      test('surfacePrep defaults to 1 (primed)', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        expect(result.values['surfacePrep'], equals(1.0));
      });

      test('colorIntensity defaults to 1 (light)', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        expect(result.values['colorIntensity'], equals(1.0));
      });
    });

    group('Surface preparation', () {
      test('primed surface (1) gives base consumption (1.0x)', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
          'surfacePrep': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: (0.10*1.2 + 0.10) * 1.0 * 40 + 0.3 = 0.22 * 40 + 0.3 = 9.1
        // roundBulk(9.1) = 9.5 (1-10 range => ceil to 0.5)
        expect(result.values['paintLiters'], equals(9.5));
        expect(result.values['surfacePrep'], equals(1.0));
      });

      test('raw/new surface (2) gives 1.2x consumption', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
          'surfacePrep': 2.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: (0.10*1.2 + 0.10) * 1.2 * 40 + 0.3 = 0.264 * 40 + 0.3 = 10.56 + 0.3 = 10.86
        // roundBulk(10.86) = 11.0 (10-100 range => ceil)
        expect(result.values['paintLiters'], equals(11.0));
        expect(result.values['surfacePrep'], equals(2.0));
      });

      test('previously painted surface (3) gives 0.95x consumption', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
          'surfacePrep': 3.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: (0.10*1.2 + 0.10) * 0.95 * 40 + 0.3 = 0.209 * 40 + 0.3 = 8.36 + 0.3 = 8.66
        // roundBulk(8.66) = 9.0 (1-10 range => ceil to 0.5)
        expect(result.values['paintLiters'], equals(9.0));
        expect(result.values['surfacePrep'], equals(3.0));
      });

      test('raw surface gives more paint than primed surface', () {
        final baseInputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 100.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final primedInputs = {...baseInputs, 'surfacePrep': 1.0};
        final rawInputs = {...baseInputs, 'surfacePrep': 2.0};

        final primedResult =
            calculator.calculate(primedInputs, emptyPriceList);
        final calculator2 = CalculatePaintUniversal();
        final rawResult = calculator2.calculate(rawInputs, emptyPriceList);

        expect(
          rawResult.values['paintLiters'],
          greaterThan(primedResult.values['paintLiters']!),
        );
      });
    });

    group('Color intensity', () {
      test('light/white color (1) gives base consumption (1.0x)', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
          'colorIntensity': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: 0.22 * 1.0 * 40 + 0.3 = 9.1
        // roundBulk(9.1) = 9.5
        expect(result.values['paintLiters'], equals(9.5));
        expect(result.values['colorIntensity'], equals(1.0));
      });

      test('bright/saturated color (2) gives 1.15x consumption', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
          'colorIntensity': 2.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: 0.22 * 1.15 * 40 + 0.3 = 0.253 * 40 + 0.3 = 10.12 + 0.3 = 10.42
        // roundBulk(10.42) = 11.0 (10-100 range => ceil)
        expect(result.values['paintLiters'], equals(11.0));
        expect(result.values['colorIntensity'], equals(2.0));
      });

      test('dark color (3) gives 1.3x consumption', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
          'colorIntensity': 3.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: 0.22 * 1.3 * 40 + 0.3 = 0.286 * 40 + 0.3 = 11.44 + 0.3 = 11.74
        // roundBulk(11.74) = 12.0 (10-100 range => ceil)
        expect(result.values['paintLiters'], equals(12.0));
        expect(result.values['colorIntensity'], equals(3.0));
      });

      test('dark color consumes more paint than light', () {
        final baseInputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 80.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
        };
        final emptyPriceList = <PriceItem>[];

        final lightInputs = {...baseInputs, 'colorIntensity': 1.0};
        final darkInputs = {...baseInputs, 'colorIntensity': 3.0};

        final lightResult =
            calculator.calculate(lightInputs, emptyPriceList);
        final calculator2 = CalculatePaintUniversal();
        final darkResult = calculator2.calculate(darkInputs, emptyPriceList);

        expect(
          darkResult.values['paintLiters'],
          greaterThan(lightResult.values['paintLiters']!),
        );
      });
    });

    group('Ceiling premium', () {
      test('ceiling gets 15% more paint per m2 than walls', () {
        // Compare walls-only vs ceiling-only with identical area
        final wallInputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 50.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
        };
        final ceilingInputs = {
          'paintType': 1.0,
          'inputMode': 0.0,
          'ceilingArea': 50.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
        };
        final emptyPriceList = <PriceItem>[];

        final wallResult =
            calculator.calculate(wallInputs, emptyPriceList);
        final calculator2 = CalculatePaintUniversal();
        final ceilingResult =
            calculator2.calculate(ceilingInputs, emptyPriceList);

        // Wall: 0.22 * 50 + 0.3 = 11.3 => roundBulk = 12.0
        // Ceiling: 0.22 * 1.15 * 50 + 0.3 = 12.95 => roundBulk = 13.0
        expect(ceilingResult.values['paintLiters'],
            greaterThan(wallResult.values['paintLiters']!));
      });

      test('walls+ceiling: ceiling portion adds 15% premium', () {
        // Walls 40m2, ceiling 20m2 with defaults
        final inputs = {
          'paintType': 2.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'ceilingArea': 20.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Wall paint: 0.22 * 40 = 8.8
        // Ceiling paint: 0.22 * 1.15 * 20 = 5.06
        // Total: 8.8 + 5.06 + 0.3 = 14.16
        // roundBulk(14.16) = 15.0 (10-100 range => ceil)
        expect(result.values['paintLiters'], equals(15.0));
      });
    });

    group('Roller absorption', () {
      test('adds 0.3L for roller absorption regardless of area', () {
        // Small area: roller absorption should be visible proportion
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 5.0,
          'layers': 1.0,
          'reserve': 0.0,
          'consumption': 0.10,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint without roller: 0.12 * 5 = 0.6
        // Paint with roller: 0.6 + 0.3 = 0.9
        // roundBulk(0.9) = 0.9 (< 1 range => ceil to 0.1)
        expect(result.values['paintLiters'], equals(0.9));
      });

      test('roller absorption is constant regardless of area', () {
        // Large area: roller absorption is negligible proportion
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 200.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint without roller: 0.22 * 200 = 44
        // Paint with roller: 44 + 0.3 = 44.3
        // roundBulk(44.3) = 45.0 (10-100 range => ceil)
        expect(result.values['paintLiters'], equals(45.0));
      });
    });

    group('Combined multipliers', () {
      test('dark color + raw surface = 1.2 x 1.3 = 1.56x multiplier', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
          'surfacePrep': 2.0, // raw (1.2x)
          'colorIntensity': 3.0, // dark (1.3x)
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: 0.22 * 1.2 * 1.3 * 40 + 0.3 = 0.3432 * 40 + 0.3 = 13.728 + 0.3 = 14.028
        // roundBulk(14.028) = 15.0 (10-100 range => ceil)
        expect(result.values['paintLiters'], equals(15.0));
      });

      test('repainted surface + bright color = 0.95 x 1.15', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
          'surfacePrep': 3.0, // repainted (0.95x)
          'colorIntensity': 2.0, // bright (1.15x)
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: 0.22 * 0.95 * 1.15 * 40 + 0.3 = 0.24035 * 40 + 0.3 = 9.614 + 0.3 = 9.914
        // roundBulk(9.914) = 10.0 (1-10 range => ceil to 0.5 => (9.914*2).ceil()/2 = (19.828).ceil()/2 = 20/2 = 10.0)
        expect(result.values['paintLiters'], equals(10.0));
      });

      test('dark color + raw surface + ceiling = maximum multiplier', () {
        // Worst case scenario: dark on raw ceiling
        final inputs = {
          'paintType': 1.0, // ceiling only
          'inputMode': 0.0,
          'ceilingArea': 40.0,
          'layers': 2.0,
          'reserve': 0.0,
          'consumption': 0.10,
          'surfacePrep': 2.0, // raw (1.2x)
          'colorIntensity': 3.0, // dark (1.3x)
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: 0.22 * 1.2 * 1.3 * 1.15 * 40 + 0.3
        // = 0.22 * 1.794 * 40 + 0.3
        // = 0.39468 * 40 + 0.3
        // = 15.7872 + 0.3 = 16.0872
        // roundBulk(16.0872) = 17.0 (10-100 range => ceil)
        expect(result.values['paintLiters'], equals(17.0));
      });
    });

    group('Practical scenarios', () {
      test('standard room 5x4x2.7, walls+ceiling, new surface, dark color',
          () {
        final inputs = {
          'paintType': 2.0, // walls and ceiling
          'inputMode': 1.0, // by dimensions
          'length': 5.0,
          'width': 4.0,
          'height': 2.7,
          'doorsWindows': 5.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
          'surfacePrep': 2.0, // new/raw surface (1.2x)
          'colorIntensity': 3.0, // dark color (1.3x)
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Wall area = (5 + 4) * 2 * 2.7 = 48.6, minus 5 openings = 43.6
        // Ceiling area = 5 * 4 = 20
        // Total area = 43.6 + 20 = 63.6
        expect(result.values['wallArea'], closeTo(43.6, 0.5));
        expect(result.values['ceilingArea'], equals(20.0));
        expect(result.values['totalArea'], closeTo(63.6, 0.5));

        // basePaintConsumption = 0.12*1.2 + 0.12 = 0.264
        // Wall paint = 0.264 * 1.2 * 1.3 * 43.6 = 0.41184 * 43.6 = 17.956...
        // Ceiling paint = 0.264 * 1.2 * 1.3 * 1.15 * 20 = 0.47361... * 20 = 9.472...
        // Raw paint = 17.956 + 9.472 = 27.428
        // With reserve: 27.428 * 1.1 + 0.3 = 30.171 + 0.3 = 30.471
        // roundBulk(30.471) = 31.0 (10-100 range => ceil)
        expect(result.values['paintLiters'], closeTo(31.0, 1.0));

        // Primer: 0.15 * 63.6 * 1.1 = 10.494
        // roundBulk(10.494) = 11.0
        expect(result.values['primerLiters'], closeTo(11.0, 1.0));

        // Verify new output keys
        expect(result.values['surfacePrep'], equals(2.0));
        expect(result.values['colorIntensity'], equals(3.0));
      });

      test('small bathroom ceiling, primed, white paint', () {
        final inputs = {
          'paintType': 1.0, // ceiling only
          'inputMode': 0.0,
          'ceilingArea': 4.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.10,
          'surfacePrep': 1.0, // primed
          'colorIntensity': 1.0, // white
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // Paint: 0.22 * 1.0 * 1.0 * 1.15 * 4 * 1.1 + 0.3 = 1.1132 + 0.3 = 1.4132
        // roundBulk(1.4132) = 1.5 (1-10 range => ceil to 0.5)
        expect(result.values['paintLiters'], equals(1.5));
        expect(result.values['totalArea'], equals(4.0));
      });

      test('large hall walls, repainted surface, light color', () {
        final inputs = {
          'paintType': 0.0,
          'inputMode': 0.0,
          'wallArea': 200.0,
          'layers': 3.0,
          'reserve': 15.0,
          'consumption': 0.12,
          'surfacePrep': 3.0, // repainted (0.95x)
          'colorIntensity': 1.0, // light
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // basePaint = 0.144 + 2*0.12 = 0.384
        // Wall paint = 0.384 * 0.95 * 1.0 * 200 = 72.96
        // With reserve: 72.96 * 1.15 + 0.3 = 83.904 + 0.3 = 84.204
        // roundBulk(84.204) = 85.0
        expect(result.values['paintLiters'], equals(85.0));
      });
    });

    group('Output keys', () {
      test('result contains all expected keys', () {
        final inputs = {
          'paintType': 2.0,
          'inputMode': 0.0,
          'wallArea': 40.0,
          'ceilingArea': 20.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
          'surfacePrep': 1.0,
          'colorIntensity': 1.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator.calculate(inputs, emptyPriceList);

        // All original keys preserved
        expect(result.values.containsKey('totalArea'), isTrue);
        expect(result.values.containsKey('wallArea'), isTrue);
        expect(result.values.containsKey('ceilingArea'), isTrue);
        expect(result.values.containsKey('paintLiters'), isTrue);
        expect(result.values.containsKey('primerLiters'), isTrue);
        expect(result.values.containsKey('tapeMeters'), isTrue);
        expect(result.values.containsKey('rollersNeeded'), isTrue);
        expect(result.values.containsKey('brushesNeeded'), isTrue);
        expect(result.values.containsKey('layers'), isTrue);
        // New keys
        expect(result.values.containsKey('surfacePrep'), isTrue);
        expect(result.values.containsKey('colorIntensity'), isTrue);
      });
    });
  });
}
