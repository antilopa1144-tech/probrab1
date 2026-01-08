import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_stretch_ceiling_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateStretchCeilingV2', () {
    late CalculateStretchCeilingV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateStretchCeilingV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('4x4 room, 4 lights', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 4.0,
          'lightsCount': 4.0,
          'ceilingType': 0.0,
          'inputMode': 1.0, // room mode
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 4 * 4 = 16 sqm
        expect(result.values['area'], equals(16.0));
        // Perimeter = 2 * (4 + 4) = 16 m
        expect(result.values['perimeter'], equals(16.0));
        // Profile = 16 * 1.1 = 17.6 m
        expect(result.values['profileLength'], closeTo(17.6, 0.1));
        // Lights = 4
        expect(result.values['lightsCount'], equals(4.0));
        // Corners = 4
        expect(result.values['cornersCount'], equals(4.0));
      });

      test('larger room needs more profile', () {
        final smallInputs = {
          'roomWidth': 3.0,
          'roomLength': 3.0,
          'inputMode': 1.0,
        };
        final largeInputs = {
          'roomWidth': 6.0,
          'roomLength': 6.0,
          'inputMode': 1.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['profileLength'],
          greaterThan(smallResult.values['profileLength']!),
        );
      });
    });

    group('Input modes', () {
      test('room mode calculates area from dimensions', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 5.0,
          'roomLength': 4.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 5 * 4 = 20
        expect(result.values['area'], equals(20.0));
        expect(result.values['roomWidth'], equals(5.0));
        expect(result.values['roomLength'], equals(4.0));
        // Perimeter = 2 * (5 + 4) = 18
        expect(result.values['perimeter'], equals(18.0));
      });

      test('manual mode uses area and calculates square dimensions', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 25.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(25.0));
        // sqrt(25) = 5
        expect(result.values['roomWidth'], closeTo(5.0, 0.1));
        expect(result.values['roomLength'], closeTo(5.0, 0.1));
        // Perimeter = 2 * (5 + 5) = 20
        expect(result.values['perimeter'], closeTo(20.0, 0.1));
      });

      test('manual mode with non-square area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 16.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // sqrt(16) = 4
        final side = math.sqrt(16.0);
        expect(result.values['roomWidth'], closeTo(side, 0.01));
        expect(result.values['roomLength'], closeTo(side, 0.01));
      });
    });

    group('Perimeter calculations', () {
      test('rectangular room perimeter', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 3.0,
          'roomLength': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 2 * (3 + 5) = 16
        expect(result.values['perimeter'], equals(16.0));
      });

      test('square room perimeter', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 4.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 2 * (4 + 4) = 16
        expect(result.values['perimeter'], equals(16.0));
      });
    });

    group('Profile calculations', () {
      test('profile has 10% waste', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 5.0,
          'roomLength': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter = 2 * (5 + 5) = 20
        // Profile = 20 * 1.1 = 22
        expect(result.values['profileLength'], closeTo(22.0, 0.1));
      });

      test('profile scales with perimeter', () {
        final inputs1 = {
          'inputMode': 1.0,
          'roomWidth': 3.0,
          'roomLength': 3.0,
        };
        final inputs2 = {
          'inputMode': 1.0,
          'roomWidth': 6.0,
          'roomLength': 6.0,
        };

        final result1 = calculator(inputs1, emptyPriceList);
        final result2 = calculator(inputs2, emptyPriceList);

        // Second room has double perimeter, so double profile
        expect(
          result2.values['profileLength'],
          closeTo(result1.values['profileLength']! * 2, 0.1),
        );
      });
    });

    group('Lights calculations', () {
      test('stores lights count', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 4.0,
          'lightsCount': 8.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['lightsCount'], equals(8.0));
      });

      test('zero lights is valid', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 4.0,
          'lightsCount': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['lightsCount'], equals(0.0));
      });

      test('many lights', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 4.0,
          'lightsCount': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['lightsCount'], equals(20.0));
      });
    });

    group('Corners', () {
      test('always 4 corners', () {
        final inputs1 = {
          'inputMode': 1.0,
          'roomWidth': 3.0,
          'roomLength': 3.0,
        };
        final inputs2 = {
          'inputMode': 1.0,
          'roomWidth': 10.0,
          'roomLength': 8.0,
        };

        final result1 = calculator(inputs1, emptyPriceList);
        final result2 = calculator(inputs2, emptyPriceList);

        expect(result1.values['cornersCount'], equals(4.0));
        expect(result2.values['cornersCount'], equals(4.0));
      });
    });

    group('Ceiling types', () {
      test('stores ceiling type correctly', () {
        final matte = calculator({
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 4.0,
          'ceilingType': 0.0,
        }, emptyPriceList);
        final glossy = calculator({
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 4.0,
          'ceilingType': 1.0,
        }, emptyPriceList);
        final satin = calculator({
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 4.0,
          'ceilingType': 2.0,
        }, emptyPriceList);
        final fabric = calculator({
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 4.0,
          'ceilingType': 3.0,
        }, emptyPriceList);

        expect(matte.values['ceilingType'], equals(0.0));
        expect(glossy.values['ceilingType'], equals(1.0));
        expect(satin.values['ceilingType'], equals(2.0));
        expect(fabric.values['ceilingType'], equals(3.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{
          'roomWidth': 4.0,
          'roomLength': 4.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['inputMode'], equals(1.0)); // room mode
        expect(result.values['ceilingType'], equals(0.0)); // matte
        expect(result.values['lightsCount'], equals(4.0));
      });
    });

    group('Edge cases', () {
      test('clamps area to valid range', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 1000.0, // Invalid, should clamp to 500
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(500.0));
      });

      test('clamps room dimensions to valid range', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 100.0, // Invalid, should clamp to 30
          'roomLength': 100.0, // Invalid, should clamp to 30
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['roomWidth'], equals(30.0));
        expect(result.values['roomLength'], equals(30.0));
      });

      test('clamps lights count to valid range', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 4.0,
          'lightsCount': 100.0, // Invalid, should clamp to 50
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['lightsCount'], equals(50.0));
      });

      test('handles minimum room size', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 0.5,
          'roomLength': 0.5,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], greaterThan(0));
        expect(result.values['perimeter'], greaterThan(0));
      });

      test('handles large room', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 20.0,
          'roomLength': 15.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 * 15 = 300
        expect(result.values['area'], equals(300.0));
        // 2 * (20 + 15) = 70
        expect(result.values['perimeter'], equals(70.0));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero area in manual mode', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative area', () {
        final inputs = {
          'inputMode': 0.0,
          'area': -16.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero room width', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 0.0,
          'roomLength': 4.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero room length', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 0.0,
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
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 4.0,
          'lightsCount': 4.0,
        };
        final priceList = [
          const PriceItem(sku: 'canvas', name: 'Полотно', price: 500.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'profile', name: 'Профиль', price: 200.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'light', name: 'Светильник', price: 300.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'corner', name: 'Угол', price: 50.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 4.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical living room', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 5.0,
          'roomLength': 4.0,
          'ceilingType': 1.0, // glossy
          'lightsCount': 6.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 5 * 4 = 20
        expect(result.values['area'], equals(20.0));
        // Perimeter = 2 * (5 + 4) = 18
        expect(result.values['perimeter'], equals(18.0));
        // Profile = 18 * 1.1 = 19.8
        expect(result.values['profileLength'], closeTo(19.8, 0.1));
        expect(result.values['lightsCount'], equals(6.0));
        expect(result.values['cornersCount'], equals(4.0));
      });

      test('small bathroom', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 2.0,
          'roomLength': 2.5,
          'ceilingType': 0.0, // matte
          'lightsCount': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 2 * 2.5 = 5
        expect(result.values['area'], equals(5.0));
        // Perimeter = 2 * (2 + 2.5) = 9
        expect(result.values['perimeter'], equals(9.0));
        // Profile = 9 * 1.1 = 9.9
        expect(result.values['profileLength'], closeTo(9.9, 0.1));
      });

      test('large hall with many lights', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 8.0,
          'roomLength': 10.0,
          'ceilingType': 2.0, // satin
          'lightsCount': 16.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 8 * 10 = 80
        expect(result.values['area'], equals(80.0));
        // Perimeter = 2 * (8 + 10) = 36
        expect(result.values['perimeter'], equals(36.0));
        // Profile = 36 * 1.1 = 39.6
        expect(result.values['profileLength'], closeTo(39.6, 0.1));
        expect(result.values['lightsCount'], equals(16.0));
      });

      test('manual mode calculation', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 36.0,
          'ceilingType': 3.0, // fabric
          'lightsCount': 4.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 36
        expect(result.values['area'], equals(36.0));
        // sqrt(36) = 6
        expect(result.values['roomWidth'], closeTo(6.0, 0.01));
        expect(result.values['roomLength'], closeTo(6.0, 0.01));
        // Perimeter = 2 * (6 + 6) = 24
        expect(result.values['perimeter'], closeTo(24.0, 0.01));
        // Profile = 24 * 1.1 = 26.4
        expect(result.values['profileLength'], closeTo(26.4, 0.1));
      });
    });
  });
}
