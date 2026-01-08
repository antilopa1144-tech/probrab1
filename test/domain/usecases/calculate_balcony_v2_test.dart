import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_balcony_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateBalconyV2', () {
    late CalculateBalconyV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateBalconyV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('3x1.2m balcony, 2.5m height', () {
        final inputs = {
          'length': 3.0,
          'width': 1.2,
          'height': 2.5,
        };

        final result = calculator(inputs, emptyPriceList);

        // Floor area = 3.0 * 1.2 = 3.6 sqm
        expect(result.values['floorArea'], closeTo(3.6, 0.01));
        // Ceiling area = 3.6 sqm
        expect(result.values['ceilingArea'], closeTo(3.6, 0.01));
        // Wall area = 2 * 1.2 * 2.5 + 3.0 * 2.5 = 6.0 + 7.5 = 13.5 sqm
        expect(result.values['wallArea'], closeTo(13.5, 0.01));
      });

      test('larger balcony needs more materials', () {
        final small = calculator({
          'length': 2.0,
          'width': 1.0,
          'height': 2.5,
        }, emptyPriceList);

        final large = calculator({
          'length': 6.0,
          'width': 2.0,
          'height': 2.5,
        }, emptyPriceList);

        expect(
          large.values['floorArea'],
          greaterThan(small.values['floorArea']!),
        );
        expect(
          large.values['wallArea'],
          greaterThan(small.values['wallArea']!),
        );
      });
    });

    group('Balcony types', () {
      test('open balcony: no glazing, no ceiling finishing', () {
        final inputs = {
          'length': 3.0,
          'width': 1.2,
          'balconyType': 0.0, // open
          'needFloorFinishing': 1.0,
          'needWallFinishing': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['glazingLength'], equals(0.0));
        // Finishing = (floor + walls) * 1.1, no ceiling
        // = (3.6 + 13.5) * 1.1 = 18.81 sqm
        expect(result.values['finishingArea'], closeTo(18.81, 0.1));
      });

      test('glazed balcony: has glazing, ceiling included', () {
        final inputs = {
          'length': 3.0,
          'width': 1.2,
          'balconyType': 1.0, // glazed
          'needFloorFinishing': 1.0,
          'needWallFinishing': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Glazing = length + 2 * width = 3.0 + 2.4 = 5.4 m
        expect(result.values['glazingLength'], closeTo(5.4, 0.01));
        // Finishing = (floor + walls + ceiling) * 1.1
        // = (3.6 + 13.5 + 3.6) * 1.1 = 22.77 sqm
        expect(result.values['finishingArea'], closeTo(22.77, 0.1));
        // No insulation for glazed
        expect(result.values['insulationArea'], equals(0.0));
      });

      test('warm balcony: has insulation', () {
        final inputs = {
          'length': 3.0,
          'width': 1.2,
          'height': 2.5,
          'balconyType': 2.0, // warm
          'needInsulation': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Insulation = (floor + ceiling + walls) * 1.1
        // = (3.6 + 3.6 + 13.5) * 1.1 = 22.77 sqm
        expect(result.values['insulationArea'], closeTo(22.77, 0.1));
      });

      test('warm balcony without insulation option', () {
        final inputs = {
          'length': 3.0,
          'width': 1.2,
          'balconyType': 2.0, // warm
          'needInsulation': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], equals(0.0));
      });
    });

    group('Area calculations', () {
      test('wall area is 3 sides only', () {
        final inputs = {
          'length': 4.0,
          'width': 1.5,
          'height': 2.5,
        };

        final result = calculator(inputs, emptyPriceList);

        // Wall area = 2 * width * height + length * height
        // = 2 * 1.5 * 2.5 + 4.0 * 2.5 = 7.5 + 10.0 = 17.5 sqm
        expect(result.values['wallArea'], closeTo(17.5, 0.01));
      });

      test('taller balcony = more wall area', () {
        final low = calculator({
          'length': 3.0,
          'width': 1.2,
          'height': 2.2,
        }, emptyPriceList);

        final high = calculator({
          'length': 3.0,
          'width': 1.2,
          'height': 3.0,
        }, emptyPriceList);

        expect(
          high.values['wallArea'],
          greaterThan(low.values['wallArea']!),
        );
        // Floor/ceiling should be same
        expect(high.values['floorArea'], equals(low.values['floorArea']));
      });
    });

    group('Glazing calculations', () {
      test('П-shaped glazing calculated correctly', () {
        final inputs = {
          'length': 4.0,
          'width': 1.5,
          'balconyType': 1.0, // glazed
        };

        final result = calculator(inputs, emptyPriceList);

        // Glazing = length + 2 * width = 4.0 + 3.0 = 7.0 m
        expect(result.values['glazingLength'], closeTo(7.0, 0.01));
      });

      test('no glazing for open balcony', () {
        final inputs = {
          'length': 4.0,
          'width': 1.5,
          'balconyType': 0.0, // open
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['glazingLength'], equals(0.0));
      });
    });

    group('Finishing calculations', () {
      test('finishing includes 10% waste', () {
        final inputs = {
          'length': 3.0,
          'width': 1.2,
          'height': 2.5,
          'balconyType': 1.0, // glazed
          'needFloorFinishing': 1.0,
          'needWallFinishing': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Base = floor + walls + ceiling = 3.6 + 13.5 + 3.6 = 20.7
        // With waste = 20.7 * 1.1 = 22.77
        expect(result.values['finishingArea'], closeTo(22.77, 0.1));
      });

      test('no floor finishing when disabled', () {
        final withFloor = calculator({
          'length': 3.0,
          'width': 1.2,
          'balconyType': 1.0,
          'needFloorFinishing': 1.0,
          'needWallFinishing': 0.0,
        }, emptyPriceList);

        final withoutFloor = calculator({
          'length': 3.0,
          'width': 1.2,
          'balconyType': 1.0,
          'needFloorFinishing': 0.0,
          'needWallFinishing': 0.0,
        }, emptyPriceList);

        expect(
          withFloor.values['finishingArea'],
          greaterThan(withoutFloor.values['finishingArea']!),
        );
      });

      test('no wall finishing when disabled', () {
        final withWalls = calculator({
          'length': 3.0,
          'width': 1.2,
          'balconyType': 1.0,
          'needFloorFinishing': 0.0,
          'needWallFinishing': 1.0,
        }, emptyPriceList);

        final withoutWalls = calculator({
          'length': 3.0,
          'width': 1.2,
          'balconyType': 1.0,
          'needFloorFinishing': 0.0,
          'needWallFinishing': 0.0,
        }, emptyPriceList);

        expect(
          withWalls.values['finishingArea'],
          greaterThan(withoutWalls.values['finishingArea']!),
        );
      });
    });

    group('Insulation calculations', () {
      test('insulation includes 10% waste', () {
        final inputs = {
          'length': 4.0,
          'width': 1.5,
          'height': 2.5,
          'balconyType': 2.0, // warm
          'needInsulation': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Floor = 6.0 sqm, ceiling = 6.0 sqm
        // Walls = 2 * 1.5 * 2.5 + 4.0 * 2.5 = 17.5 sqm
        // Total = (6.0 + 6.0 + 17.5) * 1.1 = 32.45 sqm
        expect(result.values['insulationArea'], closeTo(32.45, 0.1));
      });

      test('no insulation for glazed balcony', () {
        final inputs = {
          'length': 3.0,
          'width': 1.2,
          'balconyType': 1.0, // glazed (not warm)
          'needInsulation': 1.0, // even if enabled
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], equals(0.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['length'], equals(3.0));
        expect(result.values['width'], equals(1.2));
        expect(result.values['height'], equals(2.5));
        expect(result.values['balconyType'], equals(1.0)); // glazed
        expect(result.values['needInsulation'], equals(1.0));
        expect(result.values['needFloorFinishing'], equals(1.0));
        expect(result.values['needWallFinishing'], equals(1.0));
      });
    });

    group('Edge cases', () {
      test('clamps dimensions to valid range', () {
        final inputs = {
          'length': 20.0, // Invalid, should clamp to 10
          'width': 5.0, // Invalid, should clamp to 3
          'height': 5.0, // Invalid, should clamp to 3.5
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['length'], equals(10.0));
        expect(result.values['width'], equals(3.0));
        expect(result.values['height'], equals(3.5));
      });

      test('handles minimum dimensions', () {
        final inputs = {
          'length': 1.0,
          'width': 0.5,
          'height': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['length'], equals(1.0));
        expect(result.values['width'], equals(0.5));
        expect(result.values['height'], equals(2.0));
        expect(result.values['floorArea'], greaterThan(0));
      });

      test('handles large balcony', () {
        final inputs = {
          'length': 10.0,
          'width': 3.0,
          'height': 3.5,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorArea'], equals(30.0));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero length', () {
        final inputs = {
          'length': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative length', () {
        final inputs = {
          'length': -3.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero width', () {
        final inputs = {
          'width': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero height', () {
        final inputs = {
          'height': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });
    });

    group('Price calculations', () {
      test('calculates total price when prices available', () {
        final inputs = {
          'length': 3.0,
          'width': 1.2,
          'balconyType': 2.0, // warm
          'needInsulation': 1.0,
          'needFloorFinishing': 1.0,
          'needWallFinishing': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'balcony_glazing', name: 'Остекление балкона', price: 5000.0, unit: 'м.п.', imageUrl: ''),
          const PriceItem(sku: 'insulation', name: 'Утеплитель', price: 300.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'finishing_material', name: 'Отделка', price: 800.0, unit: 'м²', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'length': 3.0,
          'width': 1.2,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('standard glazed balcony', () {
        final inputs = {
          'length': 3.0,
          'width': 1.2,
          'height': 2.5,
          'balconyType': 1.0, // glazed
          'needFloorFinishing': 1.0,
          'needWallFinishing': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorArea'], closeTo(3.6, 0.01));
        expect(result.values['glazingLength'], closeTo(5.4, 0.01));
        expect(result.values['insulationArea'], equals(0.0));
      });

      test('warm balcony with full finishing', () {
        final inputs = {
          'length': 4.0,
          'width': 1.5,
          'height': 2.7,
          'balconyType': 2.0, // warm
          'needInsulation': 1.0,
          'needFloorFinishing': 1.0,
          'needWallFinishing': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['glazingLength'], closeTo(7.0, 0.01));
        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['finishingArea'], greaterThan(0));
      });

      test('open balcony with minimal finishing', () {
        final inputs = {
          'length': 2.5,
          'width': 1.0,
          'height': 2.5,
          'balconyType': 0.0, // open
          'needFloorFinishing': 1.0,
          'needWallFinishing': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['glazingLength'], equals(0.0));
        expect(result.values['insulationArea'], equals(0.0));
        // Only floor finishing = 2.5 * 1.1 = 2.75 sqm
        expect(result.values['finishingArea'], closeTo(2.75, 0.1));
      });
    });
  });
}
