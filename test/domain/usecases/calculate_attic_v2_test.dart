import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_attic_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateAtticV2', () {
    late CalculateAtticV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateAtticV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('8x6m attic, 2.5m roof height', () {
        final inputs = {
          'floorLength': 8.0,
          'floorWidth': 6.0,
          'roofHeight': 2.5,
        };

        final result = calculator(inputs, emptyPriceList);

        // Floor area = 8 * 6 = 48 sqm
        expect(result.values['floorArea'], equals(48.0));
        // Roof multiplier = 1.4 + 2.5/10 = 1.65
        // Roof area = 48 * 1.65 = 79.2 sqm
        expect(result.values['roofArea'], closeTo(79.2, 0.1));
      });

      test('larger attic needs more materials', () {
        final small = calculator({
          'floorLength': 5.0,
          'floorWidth': 4.0,
        }, emptyPriceList);

        final large = calculator({
          'floorLength': 12.0,
          'floorWidth': 10.0,
        }, emptyPriceList);

        expect(
          large.values['floorArea'],
          greaterThan(small.values['floorArea']!),
        );
        expect(
          large.values['roofArea'],
          greaterThan(small.values['roofArea']!),
        );
      });
    });

    group('Attic types', () {
      test('cold attic: no insulation', () {
        final inputs = {
          'floorLength': 8.0,
          'floorWidth': 6.0,
          'atticType': 0.0, // cold
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], equals(0.0));
        expect(result.values['vaporBarrierArea'], equals(0.0));
        expect(result.values['gypsumArea'], equals(0.0));
      });

      test('warm attic: has insulation, no gypsum', () {
        final inputs = {
          'floorLength': 8.0,
          'floorWidth': 6.0,
          'atticType': 1.0, // warm
          'needGypsum': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['gypsumArea'], equals(0.0)); // gypsum only for living
      });

      test('living attic: has insulation and gypsum', () {
        final inputs = {
          'floorLength': 8.0,
          'floorWidth': 6.0,
          'atticType': 2.0, // living
          'needGypsum': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['gypsumArea'], greaterThan(0));
      });
    });

    group('Roof area calculations', () {
      test('higher roof = more roof area', () {
        final lowRoof = calculator({
          'floorLength': 8.0,
          'floorWidth': 6.0,
          'roofHeight': 1.5,
        }, emptyPriceList);

        final highRoof = calculator({
          'floorLength': 8.0,
          'floorWidth': 6.0,
          'roofHeight': 4.0,
        }, emptyPriceList);

        expect(
          highRoof.values['roofArea'],
          greaterThan(lowRoof.values['roofArea']!),
        );
        // Floor areas should be same
        expect(highRoof.values['floorArea'], equals(lowRoof.values['floorArea']));
      });

      test('roof multiplier calculation', () {
        final inputs = {
          'floorLength': 10.0,
          'floorWidth': 10.0,
          'roofHeight': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Floor = 100 sqm
        // Multiplier = 1.4 + 3.0/10 = 1.7
        // Roof = 100 * 1.7 = 170 sqm
        expect(result.values['roofArea'], closeTo(170.0, 0.1));
      });
    });

    group('Insulation calculations', () {
      test('insulation includes frontal walls and waste', () {
        final inputs = {
          'floorLength': 8.0,
          'floorWidth': 6.0,
          'roofHeight': 2.5,
          'atticType': 1.0, // warm
        };

        final result = calculator(inputs, emptyPriceList);

        // Roof = 48 * 1.65 = 79.2 sqm
        // Insulation = 79.2 * 1.2 (frontal) * 1.1 (waste) = 104.544 sqm
        expect(result.values['insulationArea'], closeTo(104.5, 0.5));
      });

      test('no insulation for cold attic', () {
        final inputs = {
          'atticType': 0.0, // cold
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], equals(0.0));
      });
    });

    group('Vapor barrier calculations', () {
      test('vapor barrier with 15% overlap', () {
        final inputs = {
          'floorLength': 8.0,
          'floorWidth': 6.0,
          'atticType': 1.0, // warm
          'needVaporBarrier': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Vapor barrier = insulation * 1.15
        final expectedVaporBarrier = result.values['insulationArea']! * 1.15;
        expect(result.values['vaporBarrierArea'], closeTo(expectedVaporBarrier, 0.1));
      });

      test('no vapor barrier when disabled', () {
        final inputs = {
          'atticType': 1.0, // warm
          'needVaporBarrier': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['vaporBarrierArea'], equals(0.0));
      });

      test('no vapor barrier for cold attic', () {
        final inputs = {
          'atticType': 0.0, // cold
          'needVaporBarrier': 1.0, // even if enabled
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['vaporBarrierArea'], equals(0.0));
      });
    });

    group('Membrane calculations', () {
      test('membrane with 15% overlap', () {
        final inputs = {
          'floorLength': 8.0,
          'floorWidth': 6.0,
          'roofHeight': 2.5,
          'needMembrane': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Membrane = roof * 1.15
        final expectedMembrane = result.values['roofArea']! * 1.15;
        expect(result.values['membraneArea'], closeTo(expectedMembrane, 0.1));
      });

      test('no membrane when disabled', () {
        final inputs = {
          'needMembrane': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['membraneArea'], equals(0.0));
      });
    });

    group('Gypsum calculations', () {
      test('gypsum with 10% waste for living attic', () {
        final inputs = {
          'floorLength': 8.0,
          'floorWidth': 6.0,
          'roofHeight': 2.5,
          'atticType': 2.0, // living
          'needGypsum': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Gypsum = roof * 1.1
        final expectedGypsum = result.values['roofArea']! * 1.1;
        expect(result.values['gypsumArea'], closeTo(expectedGypsum, 0.1));
      });

      test('no gypsum for warm attic', () {
        final inputs = {
          'atticType': 1.0, // warm (not living)
          'needGypsum': 1.0, // even if enabled
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['gypsumArea'], equals(0.0));
      });

      test('no gypsum when disabled', () {
        final inputs = {
          'atticType': 2.0, // living
          'needGypsum': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['gypsumArea'], equals(0.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorLength'], equals(8.0));
        expect(result.values['floorWidth'], equals(6.0));
        expect(result.values['roofHeight'], equals(2.5));
        expect(result.values['insulationThickness'], equals(150.0));
        expect(result.values['atticType'], equals(1.0)); // warm
        expect(result.values['needVaporBarrier'], equals(1.0));
        expect(result.values['needMembrane'], equals(1.0));
        expect(result.values['needGypsum'], equals(1.0));
      });
    });

    group('Edge cases', () {
      test('clamps dimensions to valid range', () {
        final inputs = {
          'floorLength': 50.0, // Invalid, should clamp to 20
          'floorWidth': 50.0, // Invalid, should clamp to 15
          'roofHeight': 10.0, // Invalid, should clamp to 5
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorLength'], equals(20.0));
        expect(result.values['floorWidth'], equals(15.0));
        expect(result.values['roofHeight'], equals(5.0));
      });

      test('handles minimum dimensions', () {
        final inputs = {
          'floorLength': 3.0,
          'floorWidth': 3.0,
          'roofHeight': 1.5,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorLength'], equals(3.0));
        expect(result.values['floorWidth'], equals(3.0));
        expect(result.values['roofHeight'], equals(1.5));
        expect(result.values['floorArea'], greaterThan(0));
      });

      test('handles large attic', () {
        final inputs = {
          'floorLength': 20.0,
          'floorWidth': 15.0,
          'roofHeight': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorArea'], equals(300.0));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero length', () {
        final inputs = {
          'floorLength': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative length', () {
        final inputs = {
          'floorLength': -8.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero width', () {
        final inputs = {
          'floorWidth': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero roof height', () {
        final inputs = {
          'roofHeight': 0.0,
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
          'floorLength': 8.0,
          'floorWidth': 6.0,
          'atticType': 2.0, // living
          'needVaporBarrier': 1.0,
          'needMembrane': 1.0,
          'needGypsum': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'insulation', name: 'Утеплитель', price: 300.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'vapor_barrier', name: 'Пароизоляция', price: 50.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'membrane', name: 'Мембрана', price: 80.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'gypsum_board', name: 'Гипсокартон', price: 400.0, unit: 'м²', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'floorLength': 8.0,
          'floorWidth': 6.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('cold attic - minimal materials', () {
        final inputs = {
          'floorLength': 10.0,
          'floorWidth': 8.0,
          'roofHeight': 2.0,
          'atticType': 0.0, // cold
          'needMembrane': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorArea'], equals(80.0));
        expect(result.values['insulationArea'], equals(0.0));
        expect(result.values['vaporBarrierArea'], equals(0.0));
        expect(result.values['gypsumArea'], equals(0.0));
        expect(result.values['membraneArea'], greaterThan(0));
      });

      test('warm attic with full insulation', () {
        final inputs = {
          'floorLength': 8.0,
          'floorWidth': 6.0,
          'roofHeight': 2.5,
          'insulationThickness': 200.0,
          'atticType': 1.0, // warm
          'needVaporBarrier': 1.0,
          'needMembrane': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['vaporBarrierArea'], greaterThan(0));
        expect(result.values['membraneArea'], greaterThan(0));
        expect(result.values['gypsumArea'], equals(0.0));
      });

      test('living attic with all materials', () {
        final inputs = {
          'floorLength': 12.0,
          'floorWidth': 10.0,
          'roofHeight': 3.0,
          'insulationThickness': 250.0,
          'atticType': 2.0, // living
          'needVaporBarrier': 1.0,
          'needMembrane': 1.0,
          'needGypsum': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorArea'], equals(120.0));
        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['vaporBarrierArea'], greaterThan(0));
        expect(result.values['membraneArea'], greaterThan(0));
        expect(result.values['gypsumArea'], greaterThan(0));
      });
    });
  });
}
