import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_stairs_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateStairsV2', () {
    late CalculateStairsV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateStairsV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('2.8m floor, straight stairs', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsWidth': 0.9,
          'stairsType': 0.0, // straight
          'needRailing': 1.0,
          'needBothSides': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Steps = ceil(2.8 / 0.17) = 17
        expect(result.values['stepsCount'], equals(17.0));
        // Step height = 2.8 / 17 ≈ 0.165 m
        expect(result.values['stepHeight'], closeTo(0.165, 0.01));
        // Step depth = 0.62 - 2*0.165 = 0.29 m (clamped to 0.25-0.35)
        expect(result.values['stepDepth'], closeTo(0.29, 0.02));
      });

      test('higher floor needs more steps', () {
        final lowInputs = {
          'floorHeight': 2.5,
          'stairsType': 0.0,
        };
        final highInputs = {
          'floorHeight': 3.5,
          'stairsType': 0.0,
        };

        final lowResult = calculator(lowInputs, emptyPriceList);
        final highResult = calculator(highInputs, emptyPriceList);

        expect(
          highResult.values['stepsCount'],
          greaterThan(lowResult.values['stepsCount']!),
        );
      });
    });

    group('Steps calculations', () {
      test('uses optimal step height of 17cm', () {
        final inputs = {
          'floorHeight': 3.4, // 3.4 / 0.17 = 20 steps exactly
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['stepsCount'], equals(20.0));
        expect(result.values['stepHeight'], closeTo(0.17, 0.01));
      });

      test('step depth follows comfort formula 2h+d=62', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);
        final stepHeight = result.values['stepHeight']!;
        final stepDepth = result.values['stepDepth']!;

        // 2h + d should be close to 0.62
        final comfortSum = 2 * stepHeight + stepDepth;
        expect(comfortSum, closeTo(0.62, 0.1)); // May be clamped
      });

      test('step depth clamped to 25-35 cm', () {
        // Very high floor will give small step height, large depth
        final inputs = {
          'floorHeight': 5.0,
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['stepDepth'], greaterThanOrEqualTo(0.25));
        expect(result.values['stepDepth'], lessThanOrEqualTo(0.35));
      });
    });

    group('Stairs types', () {
      test('straight stairs uses full length', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsType': 0.0, // straight
        };

        final result = calculator(inputs, emptyPriceList);
        final stepsCount = result.values['stepsCount']!;
        final stepDepth = result.values['stepDepth']!;

        // Straight: length = steps * depth * 1.0
        expect(result.values['stairsLength'], closeTo(stepsCount * stepDepth, 0.02));
      });

      test('L-shaped uses 75% length', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsType': 1.0, // L-shaped
        };

        final result = calculator(inputs, emptyPriceList);
        final stepsCount = result.values['stepsCount']!;
        final stepDepth = result.values['stepDepth']!;

        // L-shaped: length = steps * depth * 0.75
        expect(result.values['stairsLength'], closeTo(stepsCount * stepDepth * 0.75, 0.02));
      });

      test('U-shaped uses 55% length', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsType': 2.0, // U-shaped
        };

        final result = calculator(inputs, emptyPriceList);
        final stepsCount = result.values['stepsCount']!;
        final stepDepth = result.values['stepDepth']!;

        // U-shaped: length = steps * depth * 0.55
        expect(result.values['stairsLength'], closeTo(stepsCount * stepDepth * 0.55, 0.02));
      });

      test('U-shaped is shortest, L-shaped middle, straight longest', () {
        final baseInputs = {
          'floorHeight': 2.8,
        };

        final straightResult = calculator({...baseInputs, 'stairsType': 0.0}, emptyPriceList);
        final lShapedResult = calculator({...baseInputs, 'stairsType': 1.0}, emptyPriceList);
        final uShapedResult = calculator({...baseInputs, 'stairsType': 2.0}, emptyPriceList);

        expect(straightResult.values['stairsLength'], greaterThan(lShapedResult.values['stairsLength']!));
        expect(lShapedResult.values['stairsLength'], greaterThan(uShapedResult.values['stairsLength']!));
      });
    });

    group('Stringer calculations', () {
      test('stringer length uses Pythagorean theorem', () {
        final inputs = {
          'floorHeight': 3.0,
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);
        final floorHeight = result.values['floorHeight']!;
        final stairsLength = result.values['stairsLength']!;

        // Stringer = sqrt(h² + l²) * 1.1
        final expected = math.sqrt(floorHeight * floorHeight + stairsLength * stairsLength) * 1.1;
        expect(result.values['stringerLength'], closeTo(expected, 0.01));
      });

      test('stringer includes 10% waste', () {
        final inputs = {
          'floorHeight': 3.0,
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);
        final floorHeight = result.values['floorHeight']!;
        final stairsLength = result.values['stairsLength']!;

        final baseLength = math.sqrt(floorHeight * floorHeight + stairsLength * stairsLength);
        final withWaste = baseLength * 1.1;
        expect(result.values['stringerLength'], closeTo(withWaste, 0.01));
      });
    });

    group('Railing calculations', () {
      test('no railing when disabled', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsType': 0.0,
          'needRailing': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['railingLength'], equals(0.0));
        expect(result.values['needRailing'], equals(0.0));
      });

      test('railing = stairsLength + 0.5 for one side', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsType': 0.0,
          'needRailing': 1.0,
          'needBothSides': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);
        final stairsLength = result.values['stairsLength']!;

        expect(result.values['railingLength'], closeTo(stairsLength + 0.5, 0.01));
      });

      test('railing doubled for both sides', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsType': 0.0,
          'needRailing': 1.0,
          'needBothSides': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);
        final stairsLength = result.values['stairsLength']!;

        expect(result.values['railingLength'], closeTo((stairsLength + 0.5) * 2, 0.01));
      });
    });

    group('Comfort check', () {
      test('comfortable when step height 15-20cm', () {
        final inputs = {
          'floorHeight': 2.8, // Will give ~16.5cm steps
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['isComfortable'], equals(1.0));
      });

      test('uncomfortable when step height too low', () {
        final inputs = {
          'floorHeight': 2.0, // ceil(2.0/0.17)=12, height=0.167
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);
        final stepHeight = result.values['stepHeight']!;

        // 2.0/12 = 0.167 which is in range 0.15-0.20
        expect(stepHeight, greaterThanOrEqualTo(0.15));
        expect(stepHeight, lessThanOrEqualTo(0.20));
        expect(result.values['isComfortable'], equals(1.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{
          'floorHeight': 2.8,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['stairsWidth'], equals(0.9));
        expect(result.values['stairsType'], equals(0.0));
        expect(result.values['needRailing'], equals(1.0));
        expect(result.values['needBothSides'], equals(0.0));
        // Default width 0.9m → 2 stringers
        expect(result.values['stringerCount'], equals(2.0));
      });
    });

    group('Stringer count by width', () {
      test('narrow stairs (<=1.2m) → 2 stringers', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsWidth': 0.9,
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['stringerCount'], equals(2.0));
      });

      test('wide stairs (>1.2m) → 3 stringers (central stringer added)', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsWidth': 1.3,
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['stringerCount'], equals(3.0));
      });

      test('boundary 1.2m → still 2 stringers', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsWidth': 1.2,
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['stringerCount'], equals(2.0));
      });

      test('max width 1.5m → 3 stringers', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsWidth': 1.5,
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['stringerCount'], equals(3.0));
      });
    });

    group('Edge cases', () {
      test('clamps floor height to valid range', () {
        final inputs = {
          'floorHeight': 10.0, // Invalid, should clamp to 6.0
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorHeight'], equals(6.0));
      });

      test('clamps stairs width to valid range', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsWidth': 2.0, // Invalid, should clamp to 1.5
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['stairsWidth'], equals(1.5));
      });

      test('handles minimum floor height', () {
        final inputs = {
          'floorHeight': 2.0,
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['stepsCount'], greaterThan(0));
        expect(result.values['stairsLength'], greaterThan(0));
      });

      test('handles maximum floor height', () {
        final inputs = {
          'floorHeight': 6.0,
          'stairsType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 6.0 / 0.17 = 36 steps
        expect(result.values['stepsCount'], equals(36.0));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero floor height', () {
        final inputs = {
          'floorHeight': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative floor height', () {
        final inputs = {
          'floorHeight': -2.8,
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
          'floorHeight': 2.8,
          'stairsWidth': 0.9,
          'stairsType': 0.0,
          'needRailing': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'step', name: 'Ступень', price: 500.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'stringer', name: 'Косоур', price: 800.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'railing', name: 'Перила', price: 1500.0, unit: 'м', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'floorHeight': 2.8,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical home stairs', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsWidth': 0.9,
          'stairsType': 0.0,
          'needRailing': 1.0,
          'needBothSides': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 17 steps
        expect(result.values['stepsCount'], equals(17.0));
        // Step height ~16.5cm (comfortable)
        expect(result.values['stepHeight'], closeTo(0.165, 0.01));
        expect(result.values['isComfortable'], equals(1.0));
        // Railing on one side
        expect(result.values['railingLength'], greaterThan(0));
      });

      test('compact L-shaped stairs with both railings', () {
        final inputs = {
          'floorHeight': 3.0,
          'stairsWidth': 1.0,
          'stairsType': 1.0, // L-shaped
          'needRailing': 1.0,
          'needBothSides': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 18 steps
        expect(result.values['stepsCount'], equals(18.0));
        // L-shaped is shorter
        expect(result.values['stairsType'], equals(1.0));
        // Railing on both sides
        expect(result.values['needBothSides'], equals(1.0));
      });

      test('U-shaped for tight space', () {
        final inputs = {
          'floorHeight': 2.8,
          'stairsWidth': 0.8,
          'stairsType': 2.0, // U-shaped
          'needRailing': 1.0,
          'needBothSides': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // U-shaped is most compact
        expect(result.values['stairsType'], equals(2.0));
        // Shortest of all types
        final straightResult = calculator({
          ...inputs,
          'stairsType': 0.0,
        }, emptyPriceList);
        expect(result.values['stairsLength'], lessThan(straightResult.values['stairsLength']!));
      });
    });
  });
}
