import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_slab_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateSlabV2', () {
    late CalculateSlabV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateSlabV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('10x8m slab, 30cm thickness', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
          'thickness': 0.3,
          'slabType': 0.0, // monolithic
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 10 * 8 = 80 sqm
        expect(result.values['slabArea'], equals(80.0));
        // Concrete = 80 * 0.3 * 1.02 = 24.48 m³
        expect(result.values['concreteVolume'], closeTo(24.48, 0.1));
        // Reinforcement = 24.48 * 90 = 2203.2 kg
        expect(result.values['reinforcementWeight'], closeTo(2203.2, 10));
      });

      test('larger slab needs more materials', () {
        final smallInputs = {
          'length': 6.0,
          'width': 6.0,
          'thickness': 0.3,
        };
        final largeInputs = {
          'length': 12.0,
          'width': 10.0,
          'thickness': 0.3,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['slabArea'],
          greaterThan(smallResult.values['slabArea']!),
        );
        expect(
          largeResult.values['concreteVolume'],
          greaterThan(smallResult.values['concreteVolume']!),
        );
      });
    });

    group('Slab types', () {
      test('monolithic slab: standard concrete', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
          'thickness': 0.3,
          'slabType': 0.0, // monolithic
        };

        final result = calculator(inputs, emptyPriceList);

        // Base concrete = 80 * 0.3 * 1.02 = 24.48 m³
        expect(result.values['concreteVolume'], closeTo(24.48, 0.1));
      });

      test('ribbed slab: +15% concrete', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
          'thickness': 0.3,
          'slabType': 1.0, // ribbed
        };

        final result = calculator(inputs, emptyPriceList);

        // Concrete = 80 * 0.3 * 1.15 * 1.02 = 28.152 m³
        expect(result.values['concreteVolume'], closeTo(28.15, 0.1));
      });

      test('floating slab: standard concrete', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
          'thickness': 0.3,
          'slabType': 2.0, // floating
        };

        final result = calculator(inputs, emptyPriceList);

        // Same as monolithic = 24.48 m³
        expect(result.values['concreteVolume'], closeTo(24.48, 0.1));
      });

      test('ribbed slab uses more concrete than monolithic', () {
        final monolithic = calculator({
          'length': 10.0,
          'width': 8.0,
          'thickness': 0.3,
          'slabType': 0.0,
        }, emptyPriceList);

        final ribbed = calculator({
          'length': 10.0,
          'width': 8.0,
          'thickness': 0.3,
          'slabType': 1.0,
        }, emptyPriceList);

        expect(
          ribbed.values['concreteVolume'],
          greaterThan(monolithic.values['concreteVolume']!),
        );
      });
    });

    group('Thickness variations', () {
      test('thicker slab needs more concrete', () {
        final thinInputs = {
          'length': 10.0,
          'width': 8.0,
          'thickness': 0.2,
        };
        final thickInputs = {
          'length': 10.0,
          'width': 8.0,
          'thickness': 0.5,
        };

        final thinResult = calculator(thinInputs, emptyPriceList);
        final thickResult = calculator(thickInputs, emptyPriceList);

        expect(
          thickResult.values['concreteVolume'],
          greaterThan(thinResult.values['concreteVolume']!),
        );
      });

      test('concrete scales with thickness', () {
        final thin = calculator({
          'length': 10.0,
          'width': 10.0,
          'thickness': 0.2,
        }, emptyPriceList);

        final thick = calculator({
          'length': 10.0,
          'width': 10.0,
          'thickness': 0.4,
        }, emptyPriceList);

        // Double thickness = double concrete (approximately)
        expect(
          thick.values['concreteVolume']! / thin.values['concreteVolume']!,
          closeTo(2.0, 0.01),
        );
      });
    });

    group('Sand and gravel', () {
      test('sand layer calculated correctly', () {
        final inputs = {
          'length': 10.0,
          'width': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Sand = 100 * 0.2 * 1.1 = 22 m³
        expect(result.values['sandVolume'], closeTo(22.0, 0.1));
      });

      test('gravel layer calculated correctly', () {
        final inputs = {
          'length': 10.0,
          'width': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Gravel = 100 * 0.15 * 1.1 = 16.5 m³
        expect(result.values['gravelVolume'], closeTo(16.5, 0.1));
      });

      test('larger slab needs more sand and gravel', () {
        final smallInputs = {
          'length': 6.0,
          'width': 6.0,
        };
        final largeInputs = {
          'length': 12.0,
          'width': 10.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['sandVolume'],
          greaterThan(smallResult.values['sandVolume']!),
        );
        expect(
          largeResult.values['gravelVolume'],
          greaterThan(smallResult.values['gravelVolume']!),
        );
      });
    });

    group('Reinforcement', () {
      test('reinforcement calculated correctly', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
          'thickness': 0.3,
          'slabType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Concrete = 24.48 m³
        // Reinforcement = 24.48 * 90 = 2203.2 kg
        expect(result.values['reinforcementWeight'], closeTo(2203.2, 10));
      });

      test('more concrete = more reinforcement', () {
        final smallInputs = {
          'length': 6.0,
          'width': 6.0,
          'thickness': 0.3,
        };
        final largeInputs = {
          'length': 12.0,
          'width': 10.0,
          'thickness': 0.3,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['reinforcementWeight'],
          greaterThan(smallResult.values['reinforcementWeight']!),
        );
      });
    });

    group('Waterproofing', () {
      test('waterproof calculated when needed', () {
        final inputs = {
          'length': 10.0,
          'width': 10.0,
          'needWaterproof': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Waterproof = 100 * 1.15 = 115 sqm
        expect(result.values['waterproofArea'], closeTo(115.0, 0.1));
      });

      test('no waterproof when not needed', () {
        final inputs = {
          'length': 10.0,
          'width': 10.0,
          'needWaterproof': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['waterproofArea'], equals(0.0));
      });
    });

    group('Insulation', () {
      test('insulation calculated when needed', () {
        final inputs = {
          'length': 10.0,
          'width': 10.0,
          'needInsulation': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Insulation = 100 * 1.05 = 105 sqm
        expect(result.values['insulationArea'], closeTo(105.0, 0.1));
      });

      test('no insulation when not needed', () {
        final inputs = {
          'length': 10.0,
          'width': 10.0,
          'needInsulation': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], equals(0.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['length'], equals(10.0));
        expect(result.values['width'], equals(8.0));
        expect(result.values['thickness'], equals(0.3));
        expect(result.values['slabType'], equals(0.0)); // monolithic
        expect(result.values['needWaterproof'], equals(1.0)); // yes
        expect(result.values['needInsulation'], equals(1.0)); // yes
      });
    });

    group('Edge cases', () {
      test('clamps dimensions to valid range', () {
        final inputs = {
          'length': 100.0, // Invalid, should clamp to 50
          'width': 100.0, // Invalid, should clamp to 30
          'thickness': 1.0, // Invalid, should clamp to 0.5
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['length'], equals(50.0));
        expect(result.values['width'], equals(30.0));
        expect(result.values['thickness'], equals(0.5));
      });

      test('handles minimum dimensions', () {
        final inputs = {
          'length': 3.0,
          'width': 3.0,
          'thickness': 0.2,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['slabArea'], equals(9.0));
        expect(result.values['concreteVolume'], greaterThan(0));
      });

      test('handles large slab', () {
        final inputs = {
          'length': 30.0,
          'width': 20.0,
          'thickness': 0.4,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['slabArea'], equals(600.0));
        expect(result.values['concreteVolume'], greaterThan(0));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero length', () {
        final inputs = {
          'length': 0.0,
          'width': 8.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative length', () {
        final inputs = {
          'length': -10.0,
          'width': 8.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero width', () {
        final inputs = {
          'length': 10.0,
          'width': 0.0,
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
          'length': 10.0,
          'width': 8.0,
          'thickness': 0.3,
          'needWaterproof': 1.0,
          'needInsulation': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'concrete', name: 'Бетон', price: 5000.0, unit: 'м³', imageUrl: ''),
          const PriceItem(sku: 'reinforcement', name: 'Арматура', price: 50.0, unit: 'кг', imageUrl: ''),
          const PriceItem(sku: 'sand', name: 'Песок', price: 800.0, unit: 'м³', imageUrl: ''),
          const PriceItem(sku: 'gravel', name: 'Щебень', price: 1200.0, unit: 'м³', imageUrl: ''),
          const PriceItem(sku: 'waterproof', name: 'Гидроизоляция', price: 200.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'insulation', name: 'Утеплитель', price: 300.0, unit: 'м²', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical house foundation slab', () {
        final inputs = {
          'length': 12.0,
          'width': 10.0,
          'thickness': 0.3,
          'slabType': 0.0, // monolithic
          'needWaterproof': 1.0,
          'needInsulation': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 12 * 10 = 120 sqm
        expect(result.values['slabArea'], equals(120.0));
        // Concrete = 120 * 0.3 * 1.02 = 36.72 m³
        expect(result.values['concreteVolume'], closeTo(36.72, 0.1));
        // Reinforcement = 36.72 * 90 = 3304.8 kg
        expect(result.values['reinforcementWeight'], closeTo(3304.8, 10));
        // Sand = 120 * 0.2 * 1.1 = 26.4 m³
        expect(result.values['sandVolume'], closeTo(26.4, 0.1));
        // Gravel = 120 * 0.15 * 1.1 = 19.8 m³
        expect(result.values['gravelVolume'], closeTo(19.8, 0.1));
        // Waterproof = 120 * 1.15 = 138 sqm
        expect(result.values['waterproofArea'], closeTo(138.0, 0.1));
        // Insulation = 120 * 1.05 = 126 sqm
        expect(result.values['insulationArea'], closeTo(126.0, 0.1));
      });

      test('garage slab with ribs', () {
        final inputs = {
          'length': 6.0,
          'width': 4.0,
          'thickness': 0.25,
          'slabType': 1.0, // ribbed
          'needWaterproof': 1.0,
          'needInsulation': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 6 * 4 = 24 sqm
        expect(result.values['slabArea'], equals(24.0));
        // Concrete = 24 * 0.25 * 1.15 * 1.02 = 7.038 m³
        expect(result.values['concreteVolume'], closeTo(7.04, 0.1));
        // No insulation
        expect(result.values['insulationArea'], equals(0.0));
      });

      test('shed floating slab, no extras', () {
        final inputs = {
          'length': 4.0,
          'width': 3.0,
          'thickness': 0.2,
          'slabType': 2.0, // floating
          'needWaterproof': 0.0,
          'needInsulation': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 4 * 3 = 12 sqm
        expect(result.values['slabArea'], equals(12.0));
        // Concrete = 12 * 0.2 * 1.02 = 2.448 m³
        expect(result.values['concreteVolume'], closeTo(2.45, 0.1));
        // No waterproof
        expect(result.values['waterproofArea'], equals(0.0));
        // No insulation
        expect(result.values['insulationArea'], equals(0.0));
      });
    });
  });
}
