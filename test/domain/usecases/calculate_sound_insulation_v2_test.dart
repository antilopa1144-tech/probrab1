import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_sound_insulation_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateSoundInsulationV2', () {
    late CalculateSoundInsulationV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateSoundInsulationV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('20 sqm wall, mineral wool, with gypsum and profile', () {
        final inputs = {
          'area': 20.0,
          'thickness': 50.0,
          'insulationType': 0.0, // mineral wool
          'surfaceType': 0.0, // wall
          'needGypsum': 1.0,
          'needProfile': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Insulation = 20 * 1.1 = 22 sqm
        expect(result.values['insulationArea'], closeTo(22.0, 0.1));
        // No membrane for mineral wool
        expect(result.values['membraneArea'], equals(0.0));
        // Gypsum = 20 * 1.1 = 22 sqm
        expect(result.values['gypsumArea'], closeTo(22.0, 0.1));
        // No hangers for wall
        expect(result.values['hangersCount'], equals(0.0));
      });

      test('larger area needs more materials', () {
        final smallInputs = {
          'area': 10.0,
          'insulationType': 0.0,
        };
        final largeInputs = {
          'area': 50.0,
          'insulationType': 0.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['insulationArea'],
          greaterThan(smallResult.values['insulationArea']!),
        );
        expect(
          largeResult.values['gypsumArea'],
          greaterThan(smallResult.values['gypsumArea']!),
        );
      });
    });

    group('Insulation types', () {
      test('mineral wool: only insulation, no membrane', () {
        final inputs = {
          'area': 20.0,
          'insulationType': 0.0, // mineral wool
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['membraneArea'], equals(0.0));
      });

      test('membrane: only membrane, no insulation', () {
        final inputs = {
          'area': 20.0,
          'insulationType': 1.0, // membrane
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], equals(0.0));
        expect(result.values['membraneArea'], greaterThan(0));
      });

      test('combined: both insulation and membrane', () {
        final inputs = {
          'area': 20.0,
          'insulationType': 2.0, // combined
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['membraneArea'], greaterThan(0));
      });

      test('membrane has more waste than insulation', () {
        final inputs = {
          'area': 20.0,
          'insulationType': 2.0, // combined
        };

        final result = calculator(inputs, emptyPriceList);

        // Membrane 15% vs insulation 10%
        expect(
          result.values['membraneArea'],
          greaterThan(result.values['insulationArea']!),
        );
      });
    });

    group('Waste percentages', () {
      test('insulation has 10% waste', () {
        final inputs = {
          'area': 100.0,
          'insulationType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 100 * 1.1 = 110
        expect(result.values['insulationArea'], closeTo(110.0, 0.1));
      });

      test('membrane has 15% waste', () {
        final inputs = {
          'area': 100.0,
          'insulationType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 100 * 1.15 = 115
        expect(result.values['membraneArea'], closeTo(115.0, 0.1));
      });

      test('gypsum has 10% waste', () {
        final inputs = {
          'area': 100.0,
          'needGypsum': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 100 * 1.1 = 110
        expect(result.values['gypsumArea'], closeTo(110.0, 0.1));
      });
    });

    group('Surface types', () {
      test('wall uses 0.6m profile spacing', () {
        final inputs = {
          'area': 12.0, // 12 / 0.6 = 20 rows
          'surfaceType': 0.0, // wall
          'needProfile': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // rows = ceil(12/0.6) = 20, length = 20 * 3 * 1.1 = 66
        expect(result.values['profileLength'], closeTo(66.0, 0.1));
        // No hangers for wall
        expect(result.values['hangersCount'], equals(0.0));
      });

      test('ceiling uses 0.4m profile spacing', () {
        final inputs = {
          'area': 12.0, // 12 / 0.4 = 30 rows
          'surfaceType': 1.0, // ceiling
          'needProfile': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // rows = ceil(12/0.4) = 30, length = 30 * 3 * 1.1 = 99
        expect(result.values['profileLength'], closeTo(99.0, 0.1));
        // Hangers for ceiling = ceil(12/1.2) = 10
        expect(result.values['hangersCount'], equals(10.0));
      });

      test('floor uses 0.6m profile spacing like wall', () {
        final inputs = {
          'area': 12.0,
          'surfaceType': 2.0, // floor
          'needProfile': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Same as wall: rows = ceil(12/0.6) = 20, length = 20 * 3 * 1.1 = 66
        expect(result.values['profileLength'], closeTo(66.0, 0.1));
        // No hangers for floor
        expect(result.values['hangersCount'], equals(0.0));
      });

      test('ceiling needs more profile than wall', () {
        final baseInputs = {
          'area': 20.0,
          'needProfile': 1.0,
        };

        final wallResult = calculator({...baseInputs, 'surfaceType': 0.0}, emptyPriceList);
        final ceilingResult = calculator({...baseInputs, 'surfaceType': 1.0}, emptyPriceList);

        expect(
          ceilingResult.values['profileLength'],
          greaterThan(wallResult.values['profileLength']!),
        );
      });
    });

    group('Hangers calculations', () {
      test('hangers only for ceiling with profile', () {
        final inputs = {
          'area': 24.0,
          'surfaceType': 1.0, // ceiling
          'needProfile': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 24 / 1.2 = 20 hangers
        expect(result.values['hangersCount'], equals(20.0));
      });

      test('no hangers for wall even with profile', () {
        final inputs = {
          'area': 24.0,
          'surfaceType': 0.0, // wall
          'needProfile': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['hangersCount'], equals(0.0));
      });

      test('no hangers for ceiling without profile', () {
        final inputs = {
          'area': 24.0,
          'surfaceType': 1.0, // ceiling
          'needProfile': 0.0, // no profile
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['hangersCount'], equals(0.0));
      });
    });

    group('Optional materials', () {
      test('no gypsum when disabled', () {
        final inputs = {
          'area': 20.0,
          'needGypsum': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['gypsumArea'], equals(0.0));
      });

      test('no profile when disabled', () {
        final inputs = {
          'area': 20.0,
          'needProfile': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['profileLength'], equals(0.0));
      });

      test('all options enabled', () {
        final inputs = {
          'area': 20.0,
          'insulationType': 2.0, // combined
          'needGypsum': 1.0,
          'needProfile': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['membraneArea'], greaterThan(0));
        expect(result.values['gypsumArea'], greaterThan(0));
        expect(result.values['profileLength'], greaterThan(0));
      });

      test('all options disabled except core', () {
        final inputs = {
          'area': 20.0,
          'insulationType': 0.0,
          'needGypsum': 0.0,
          'needProfile': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['membraneArea'], equals(0.0));
        expect(result.values['gypsumArea'], equals(0.0));
        expect(result.values['profileLength'], equals(0.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['thickness'], equals(50.0));
        expect(result.values['insulationType'], equals(0.0)); // mineral wool
        expect(result.values['surfaceType'], equals(0.0)); // wall
        expect(result.values['needGypsum'], equals(1.0));
        expect(result.values['needProfile'], equals(1.0));
      });
    });

    group('Edge cases', () {
      test('clamps area to valid range', () {
        final inputs = {
          'area': 1000.0, // Invalid, should clamp to 500
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(500.0));
      });

      test('clamps thickness to valid range', () {
        final inputs = {
          'area': 20.0,
          'thickness': 300.0, // Invalid, should clamp to 200
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['thickness'], equals(200.0));
      });

      test('handles minimum area', () {
        final inputs = {
          'area': 1.0,
          'insulationType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], greaterThan(0));
      });

      test('handles maximum area', () {
        final inputs = {
          'area': 500.0,
          'insulationType': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 500 * 1.1 = 550
        expect(result.values['insulationArea'], closeTo(550.0, 0.1));
        // 500 * 1.15 = 575
        expect(result.values['membraneArea'], closeTo(575.0, 0.1));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero area', () {
        final inputs = {
          'area': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative area', () {
        final inputs = {
          'area': -20.0,
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
          'insulationType': 2.0, // combined
          'needGypsum': 1.0,
          'needProfile': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'insulation', name: 'Минвата', price: 200.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'membrane', name: 'Мембрана', price: 150.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'gypsum', name: 'Гипсокартон', price: 350.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'profile', name: 'Профиль', price: 50.0, unit: 'м', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'area': 20.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical wall sound insulation', () {
        final inputs = {
          'area': 30.0,
          'thickness': 50.0,
          'insulationType': 0.0, // mineral wool
          'surfaceType': 0.0, // wall
          'needGypsum': 1.0,
          'needProfile': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Insulation = 30 * 1.1 = 33
        expect(result.values['insulationArea'], closeTo(33.0, 0.1));
        // No membrane
        expect(result.values['membraneArea'], equals(0.0));
        // Gypsum = 30 * 1.1 = 33
        expect(result.values['gypsumArea'], closeTo(33.0, 0.1));
        // Profile: rows = ceil(30/0.6) = 50, length = 50 * 3 * 1.1 = 165
        expect(result.values['profileLength'], closeTo(165.0, 0.1));
        // No hangers for wall
        expect(result.values['hangersCount'], equals(0.0));
      });

      test('ceiling with combined insulation', () {
        final inputs = {
          'area': 24.0,
          'thickness': 100.0,
          'insulationType': 2.0, // combined
          'surfaceType': 1.0, // ceiling
          'needGypsum': 1.0,
          'needProfile': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Insulation = 24 * 1.1 = 26.4
        expect(result.values['insulationArea'], closeTo(26.4, 0.1));
        // Membrane = 24 * 1.15 = 27.6
        expect(result.values['membraneArea'], closeTo(27.6, 0.1));
        // Gypsum = 24 * 1.1 = 26.4
        expect(result.values['gypsumArea'], closeTo(26.4, 0.1));
        // Profile: rows = ceil(24/0.4) = 60, length = 60 * 3 * 1.1 = 198
        expect(result.values['profileLength'], closeTo(198.0, 0.1));
        // Hangers = ceil(24/1.2) = 20
        expect(result.values['hangersCount'], equals(20.0));
      });

      test('floor with membrane only', () {
        final inputs = {
          'area': 18.0,
          'thickness': 30.0,
          'insulationType': 1.0, // membrane only
          'surfaceType': 2.0, // floor
          'needGypsum': 0.0,
          'needProfile': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // No insulation for membrane type
        expect(result.values['insulationArea'], equals(0.0));
        // Membrane = 18 * 1.15 = 20.7
        expect(result.values['membraneArea'], closeTo(20.7, 0.1));
        // No gypsum
        expect(result.values['gypsumArea'], equals(0.0));
        // No profile
        expect(result.values['profileLength'], equals(0.0));
        // No hangers for floor
        expect(result.values['hangersCount'], equals(0.0));
      });
    });
  });
}
