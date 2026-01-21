import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_putty.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculatePutty', () {
    group('Basic calculations', () {
      test('calculates start putty with standard quality', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 50.0,
          'layers': 2.0,
          'type': 1.0, // start
          'qualityClass': 2.0, // standard (Q3)
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // Standard start: 1.5 kg/m²
        // 50 * 1.5 * 2 * 1.1 = 165 kg
        expect(result.values['puttyNeeded'], closeTo(165.0, 1.0));
        expect(result.values['consumptionPerLayer'], equals(1.5));
        expect(result.values['qualityClass'], equals(2.0));
      });

      test('calculates finish putty with standard quality', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 50.0,
          'layers': 1.0,
          'type': 2.0, // finish
          'qualityClass': 2.0, // standard
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // Standard finish: 0.8 kg/m²
        // 50 * 0.8 * 1 * 1.1 = 44 kg
        expect(result.values['puttyNeeded'], closeTo(44.0, 1.0));
        expect(result.values['consumptionPerLayer'], equals(0.8));
      });
    });

    group('Quality classes', () {
      test('economy class has higher consumption', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 20.0,
          'type': 1.0, // start
          'qualityClass': 1.0, // economy (Q1-Q2)
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // Economy start: 1.8 kg/m², default 1 layer
        // 20 * 1.8 * 1 * 1.1 = 39.6 kg
        expect(result.values['consumptionPerLayer'], equals(1.8));
        expect(result.values['layers'], equals(1.0)); // default for economy start
        expect(result.values['puttyNeeded'], closeTo(39.6, 0.5));
      });

      test('premium class has lower consumption but more layers', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 20.0,
          'type': 1.0, // start
          'qualityClass': 3.0, // premium (Q4)
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // Premium start: 1.2 kg/m², default 2 layers
        // 20 * 1.2 * 2 * 1.1 = 52.8 kg
        expect(result.values['consumptionPerLayer'], equals(1.2));
        expect(result.values['layers'], equals(2.0)); // default for premium start
        expect(result.values['puttyNeeded'], closeTo(52.8, 0.5));
      });

      test('premium finish has 2 default layers', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 30.0,
          'type': 2.0, // finish
          'qualityClass': 3.0, // premium (Q4)
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // Premium finish: 0.5 kg/m², default 2 layers
        // 30 * 0.5 * 2 * 1.1 = 33 kg
        expect(result.values['consumptionPerLayer'], equals(0.5));
        expect(result.values['layers'], equals(2.0));
        expect(result.values['puttyNeeded'], closeTo(33.0, 0.5));
      });

      test('economy finish has 1 default layer', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 30.0,
          'type': 2.0, // finish
          'qualityClass': 1.0, // economy
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // Economy finish: 1.0 kg/m², default 1 layer
        // 30 * 1.0 * 1 * 1.1 = 33 kg
        expect(result.values['consumptionPerLayer'], equals(1.0));
        expect(result.values['layers'], equals(1.0));
        expect(result.values['puttyNeeded'], closeTo(33.0, 0.5));
      });
    });

    group('Primer calculations', () {
      test('standard quality uses 2 primer coats', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 50.0,
          'type': 1.0,
          'qualityClass': 2.0, // standard
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // Standard: 2 coats
        // 50 * 0.2 * 2 = 20 L
        expect(result.values['primerNeeded'], closeTo(20.0, 0.5));
      });

      test('premium quality uses more primer coats', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 50.0,
          'layers': 3.0,
          'type': 1.0,
          'qualityClass': 3.0, // premium
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // Premium: layers + 1 coats = 4
        // 50 * 0.2 * 4 = 40 L
        expect(result.values['primerNeeded'], closeTo(40.0, 0.5));
      });
    });

    group('Sandpaper calculations', () {
      test('standard quality uses normal sandpaper amount', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 60.0,
          'qualityClass': 2.0, // standard
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 60 / 25 = 3 (ceil)
        expect(result.values['sandpaperSets'], equals(3.0));
      });

      test('premium quality uses 2x sandpaper', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 60.0,
          'qualityClass': 3.0, // premium
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // 60 / 25 * 2 = 5 (ceil)
        expect(result.values['sandpaperSets'], equals(5.0));
      });
    });

    group('Auxiliary materials', () {
      test('calculates spatulas needed', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 50.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['spatulasNeeded'], equals(3.0));
      });

      test('calculates water needed', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 20.0,
          'layers': 2.0,
          'type': 1.0,
          'qualityClass': 2.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // puttyNeeded * 0.4
        final puttyNeeded = result.values['puttyNeeded']!;
        expect(result.values['waterNeeded'], closeTo(puttyNeeded * 0.4, 0.1));
      });

      test('start putty includes mesh area', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 30.0,
          'type': 1.0, // start
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['meshArea'], equals(30.0));
      });

      test('finish putty does not include mesh area', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 30.0,
          'type': 2.0, // finish
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        expect(result.values.containsKey('meshArea'), isFalse);
      });
    });

    group('Default values', () {
      test('uses standard quality class by default', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 50.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // Default: standard (Q3), start type, 2 layers
        expect(result.values['qualityClass'], equals(2.0));
        expect(result.values['layers'], equals(2.0)); // standard start default
        expect(result.values['consumptionPerLayer'], equals(1.5)); // standard start
      });

      test('can override default layers', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 20.0,
          'layers': 3.0, // override
          'qualityClass': 1.0, // economy (default 1 layer)
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        // User specified 3 layers, should override economy default of 1
        expect(result.values['layers'], equals(3.0));
      });
    });

    group('Validation', () {
      test('throws exception for zero area', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 0.0,
        };
        final emptyPriceList = <PriceItem>[];

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative area', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': -10.0,
        };
        final emptyPriceList = <PriceItem>[];

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });
    });

    group('Price calculations', () {
      test('calculates total price when prices available', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 20.0,
          'type': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'putty_start', name: 'Start Putty', price: 15.0, unit: 'kg', imageUrl: ''),
          const PriceItem(sku: 'primer', name: 'Primer', price: 100.0, unit: 'L', imageUrl: ''),
          const PriceItem(sku: 'mesh', name: 'Mesh', price: 50.0, unit: 'm2', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final calculator = CalculatePutty();
        final inputs = {
          'area': 20.0,
        };
        final emptyPriceList = <PriceItem>[];

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });
  });
}
