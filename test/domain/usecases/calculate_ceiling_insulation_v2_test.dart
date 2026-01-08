import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_ceiling_insulation_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateCeilingInsulationV2', () {
    late CalculateCeilingInsulationV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateCeilingInsulationV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('20 sqm, 100mm thickness, all options enabled', () {
        final inputs = {
          'area': 20.0,
          'thickness': 100.0,
          'insulationType': 0.0,
          'inputMode': 0.0, // manual
          'needVaporBarrier': 1.0,
          'needMembrane': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Insulation area = 20 * 1.1 = 22 sqm
        expect(result.values['insulationArea'], closeTo(22.0, 0.1));
        // Pack area = 6 * (100/100) = 6 sqm
        expect(result.values['packArea'], closeTo(6.0, 0.1));
        // Packs = ceil(22/6) = 4
        expect(result.values['insulationPacks'], equals(4.0));
        // Vapor barrier = 20 * 1.15 = 23 sqm
        expect(result.values['vaporBarrierArea'], closeTo(23.0, 0.1));
        // Membrane = 20 * 1.15 = 23 sqm
        expect(result.values['membraneArea'], closeTo(23.0, 0.1));
      });

      test('larger area needs more packs', () {
        final smallInputs = {
          'area': 10.0,
          'thickness': 100.0,
          'inputMode': 0.0,
        };
        final largeInputs = {
          'area': 50.0,
          'thickness': 100.0,
          'inputMode': 0.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['insulationPacks'],
          greaterThan(smallResult.values['insulationPacks']!),
        );
      });
    });

    group('Input modes', () {
      test('manual mode uses area directly', () {
        final inputs = {
          'area': 30.0,
          'inputMode': 0.0, // manual
          'roomWidth': 4.0, // ignored
          'roomLength': 5.0, // ignored
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(30.0));
      });

      test('room mode calculates area from dimensions', () {
        final inputs = {
          'area': 99.0, // ignored in room mode
          'inputMode': 1.0, // room
          'roomWidth': 4.0,
          'roomLength': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 4 * 5 = 20
        expect(result.values['area'], equals(20.0));
        expect(result.values['roomWidth'], equals(4.0));
        expect(result.values['roomLength'], equals(5.0));
      });

      test('room mode with different dimensions', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 6.0,
          'roomLength': 8.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 6 * 8 = 48
        expect(result.values['area'], equals(48.0));
      });
    });

    group('Thickness calculations', () {
      test('100mm thickness: pack area = 6 sqm', () {
        final inputs = {
          'area': 20.0,
          'thickness': 100.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['packArea'], closeTo(6.0, 0.1));
      });

      test('200mm thickness: pack area = 3 sqm (half)', () {
        final inputs = {
          'area': 20.0,
          'thickness': 200.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 6 * (100/200) = 3
        expect(result.values['packArea'], closeTo(3.0, 0.1));
      });

      test('50mm thickness: pack area = 12 sqm (double)', () {
        final inputs = {
          'area': 20.0,
          'thickness': 50.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 6 * (100/50) = 12
        expect(result.values['packArea'], closeTo(12.0, 0.1));
      });

      test('thicker insulation needs more packs for same area', () {
        final thinInputs = {
          'area': 30.0,
          'thickness': 50.0,
          'inputMode': 0.0,
        };
        final thickInputs = {
          'area': 30.0,
          'thickness': 200.0,
          'inputMode': 0.0,
        };

        final thinResult = calculator(thinInputs, emptyPriceList);
        final thickResult = calculator(thickInputs, emptyPriceList);

        expect(
          thickResult.values['insulationPacks'],
          greaterThan(thinResult.values['insulationPacks']!),
        );
      });
    });

    group('Pack calculations', () {
      test('exact pack fit', () {
        // 12 sqm with 10% waste = 13.2, pack area 6 = ceil(13.2/6) = 3
        final inputs = {
          'area': 12.0,
          'thickness': 100.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationPacks'], equals(3.0));
      });

      test('rounds up partial packs', () {
        // 10 sqm with 10% waste = 11, pack area 6 = ceil(11/6) = 2
        final inputs = {
          'area': 10.0,
          'thickness': 100.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationPacks'], equals(2.0));
      });
    });

    group('Waste percentages', () {
      test('insulation has 10% waste', () {
        final inputs = {
          'area': 100.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 100 * 1.1 = 110
        expect(result.values['insulationArea'], closeTo(110.0, 0.1));
      });

      test('vapor barrier has 15% waste', () {
        final inputs = {
          'area': 100.0,
          'inputMode': 0.0,
          'needVaporBarrier': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 100 * 1.15 = 115
        expect(result.values['vaporBarrierArea'], closeTo(115.0, 0.1));
      });

      test('membrane has 15% waste', () {
        final inputs = {
          'area': 100.0,
          'inputMode': 0.0,
          'needMembrane': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 100 * 1.15 = 115
        expect(result.values['membraneArea'], closeTo(115.0, 0.1));
      });
    });

    group('Optional materials', () {
      test('no vapor barrier when disabled', () {
        final inputs = {
          'area': 20.0,
          'inputMode': 0.0,
          'needVaporBarrier': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['vaporBarrierArea'], equals(0.0));
      });

      test('no membrane when disabled', () {
        final inputs = {
          'area': 20.0,
          'inputMode': 0.0,
          'needMembrane': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['membraneArea'], equals(0.0));
      });

      test('both enabled', () {
        final inputs = {
          'area': 20.0,
          'inputMode': 0.0,
          'needVaporBarrier': 1.0,
          'needMembrane': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['vaporBarrierArea'], greaterThan(0));
        expect(result.values['membraneArea'], greaterThan(0));
      });

      test('both disabled', () {
        final inputs = {
          'area': 20.0,
          'inputMode': 0.0,
          'needVaporBarrier': 0.0,
          'needMembrane': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['vaporBarrierArea'], equals(0.0));
        expect(result.values['membraneArea'], equals(0.0));
      });
    });

    group('Insulation types', () {
      test('stores insulation type correctly', () {
        final mineralWool = calculator({
          'area': 20.0,
          'inputMode': 0.0,
          'insulationType': 0.0,
        }, emptyPriceList);
        final styrofoam = calculator({
          'area': 20.0,
          'inputMode': 0.0,
          'insulationType': 1.0,
        }, emptyPriceList);
        final extruded = calculator({
          'area': 20.0,
          'inputMode': 0.0,
          'insulationType': 2.0,
        }, emptyPriceList);

        expect(mineralWool.values['insulationType'], equals(0.0));
        expect(styrofoam.values['insulationType'], equals(1.0));
        expect(extruded.values['insulationType'], equals(2.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['thickness'], equals(100.0));
        expect(result.values['insulationType'], equals(0.0));
        expect(result.values['inputMode'], equals(0.0));
        expect(result.values['needVaporBarrier'], equals(1.0));
        expect(result.values['needMembrane'], equals(1.0));
      });
    });

    group('Edge cases', () {
      test('clamps area to valid range', () {
        final inputs = {
          'area': 2000.0, // Invalid, should clamp to 1000
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(1000.0));
      });

      test('clamps thickness to valid range', () {
        final inputs = {
          'area': 20.0,
          'thickness': 500.0, // Invalid, should clamp to 300
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['thickness'], equals(300.0));
      });

      test('clamps room dimensions to valid range', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 100.0, // Invalid, should clamp to 50
          'roomLength': 100.0, // Invalid, should clamp to 50
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['roomWidth'], equals(50.0));
        expect(result.values['roomLength'], equals(50.0));
      });

      test('handles minimum area', () {
        final inputs = {
          'area': 1.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['insulationPacks'], greaterThanOrEqualTo(1));
      });

      test('handles very thin insulation', () {
        final inputs = {
          'area': 20.0,
          'thickness': 20.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Pack area = 6 * (100/20) = 30
        expect(result.values['packArea'], closeTo(30.0, 0.1));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero area in manual mode', () {
        final inputs = {
          'area': 0.0,
          'inputMode': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative area', () {
        final inputs = {
          'area': -20.0,
          'inputMode': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero room width', () {
        final inputs = {
          'roomWidth': 0.0,
          'roomLength': 5.0,
          'inputMode': 1.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero room length', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 0.0,
          'inputMode': 1.0,
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
          'area': 20.0,
          'inputMode': 0.0,
          'needVaporBarrier': 1.0,
          'needMembrane': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'insulation', name: 'Минвата', price: 500.0, unit: 'упак', imageUrl: ''),
          const PriceItem(sku: 'vapor_barrier', name: 'Пароизоляция', price: 50.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'membrane', name: 'Мембрана', price: 80.0, unit: 'м²', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'area': 20.0,
          'inputMode': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical room insulation', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'thickness': 100.0,
          'insulationType': 0.0,
          'needVaporBarrier': 1.0,
          'needMembrane': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 4 * 5 = 20
        expect(result.values['area'], equals(20.0));
        // Insulation = 20 * 1.1 = 22
        expect(result.values['insulationArea'], closeTo(22.0, 0.1));
        // Packs = ceil(22/6) = 4
        expect(result.values['insulationPacks'], equals(4.0));
        // Vapor = 20 * 1.15 = 23
        expect(result.values['vaporBarrierArea'], closeTo(23.0, 0.1));
        // Membrane = 20 * 1.15 = 23
        expect(result.values['membraneArea'], closeTo(23.0, 0.1));
      });

      test('large attic with thick insulation', () {
        final inputs = {
          'area': 100.0,
          'inputMode': 0.0,
          'thickness': 200.0,
          'insulationType': 0.0,
          'needVaporBarrier': 1.0,
          'needMembrane': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Insulation = 100 * 1.1 = 110
        expect(result.values['insulationArea'], closeTo(110.0, 0.1));
        // Pack area = 6 * (100/200) = 3
        expect(result.values['packArea'], closeTo(3.0, 0.1));
        // Packs = ceil(110/3) = 37
        expect(result.values['insulationPacks'], equals(37.0));
      });

      test('small room with thin insulation, no extras', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 2.0,
          'roomLength': 3.0,
          'thickness': 50.0,
          'insulationType': 1.0, // styrofoam
          'needVaporBarrier': 0.0,
          'needMembrane': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 2 * 3 = 6
        expect(result.values['area'], equals(6.0));
        // Pack area = 6 * (100/50) = 12
        expect(result.values['packArea'], closeTo(12.0, 0.1));
        // Insulation = 6 * 1.1 = 6.6, packs = ceil(6.6/12) = 1
        expect(result.values['insulationPacks'], equals(1.0));
        // No vapor or membrane
        expect(result.values['vaporBarrierArea'], equals(0.0));
        expect(result.values['membraneArea'], equals(0.0));
      });
    });
  });
}
