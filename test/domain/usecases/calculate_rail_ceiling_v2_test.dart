import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_rail_ceiling_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateRailCeilingV2', () {
    late CalculateRailCeilingV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateRailCeilingV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('3x4 room, 100mm rails', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'railWidth': 1.0, // 100mm
          'ceilingType': 0.0,
          'inputMode': 1.0, // room mode
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 3 * 4 = 12 sqm
        expect(result.values['area'], equals(12.0));
        // Rail step = 0.100 + 0.016 = 0.116
        expect(result.values['railStep'], closeTo(0.116, 0.01));
        // Rails count = ceil(3 / 0.116) = 26
        expect(result.values['railsCount'], equals(26.0));
      });

      test('larger room needs more rails', () {
        final smallInputs = {
          'roomWidth': 2.0,
          'roomLength': 3.0,
          'railWidth': 1.0,
          'inputMode': 1.0,
        };
        final largeInputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'railWidth': 1.0,
          'inputMode': 1.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['railsCount'],
          greaterThan(smallResult.values['railsCount']!),
        );
      });
    });

    group('Rail widths', () {
      test('84mm rails: step = 0.100', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'railWidth': 0.0, // 84mm
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Rail step = 0.084 + 0.016 = 0.100
        expect(result.values['railStep'], closeTo(0.100, 0.01));
      });

      test('100mm rails: step = 0.116', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'railWidth': 1.0, // 100mm
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Rail step = 0.100 + 0.016 = 0.116
        expect(result.values['railStep'], closeTo(0.116, 0.01));
      });

      test('150mm rails: step = 0.166', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'railWidth': 2.0, // 150mm
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Rail step = 0.150 + 0.016 = 0.166
        expect(result.values['railStep'], closeTo(0.166, 0.01));
      });

      test('wider rails = fewer rails needed', () {
        final narrow = calculator({
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'railWidth': 0.0, // 84mm
          'inputMode': 1.0,
        }, emptyPriceList);
        final wide = calculator({
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'railWidth': 2.0, // 150mm
          'inputMode': 1.0,
        }, emptyPriceList);

        expect(
          wide.values['railsCount'],
          lessThan(narrow.values['railsCount']!),
        );
      });
    });

    group('Rail length calculations', () {
      test('rail length = railsCount * roomLength * 1.05', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'railWidth': 1.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);
        final railsCount = result.values['railsCount']!;
        final roomLength = result.values['roomLength']!;

        expect(result.values['railLength'], closeTo(railsCount * roomLength * 1.05, 0.1));
      });

      test('rail length includes 5% waste', () {
        final inputs = {
          'roomWidth': 2.0,
          'roomLength': 5.0,
          'railWidth': 1.0, // 100mm
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);
        final railsCount = result.values['railsCount']!;

        // Without waste: railsCount * 5
        // With waste: railsCount * 5 * 1.05
        expect(result.values['railLength'], closeTo(railsCount * 5 * 1.05, 0.1));
      });
    });

    group('Stringer calculations', () {
      test('stringers every 1.2m along width', () {
        final inputs = {
          'roomWidth': 3.6, // 3 rows (0-1.2, 1.2-2.4, 2.4-3.6)
          'roomLength': 4.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // ceil(3.6 / 1.2) = 3
        expect(result.values['stringerRows'], equals(3.0));
      });

      test('stringer length = rows * roomLength * 1.10', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);
        final stringerRows = result.values['stringerRows']!;
        final roomLength = result.values['roomLength']!;

        expect(result.values['stringerLength'], closeTo(stringerRows * roomLength * 1.10, 0.1));
      });
    });

    group('Wall profile calculations', () {
      test('wall profile = perimeter * 1.10', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);
        final perimeter = result.values['perimeter']!;

        expect(result.values['wallProfileLength'], closeTo(perimeter * 1.10, 0.1));
      });

      test('perimeter calculated correctly', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 5.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 2 * (3 + 5) = 16
        expect(result.values['perimeter'], equals(16.0));
      });
    });

    group('Hangers calculations', () {
      test('hangers = stringerRows * hangersPerRow', () {
        final inputs = {
          'roomWidth': 2.4, // 2 stringer rows
          'roomLength': 3.6, // 3 hangers per row
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // stringerRows = ceil(2.4 / 1.2) = 2
        // hangersPerRow = ceil(3.6 / 1.2) = 3
        // hangers = 2 * 3 = 6
        expect(result.values['hangersCount'], equals(6.0));
      });

      test('more hangers for larger room', () {
        final smallInputs = {
          'roomWidth': 2.0,
          'roomLength': 2.0,
          'inputMode': 1.0,
        };
        final largeInputs = {
          'roomWidth': 5.0,
          'roomLength': 6.0,
          'inputMode': 1.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['hangersCount'],
          greaterThan(smallResult.values['hangersCount']!),
        );
      });
    });

    group('Input modes', () {
      test('room mode calculates area from dimensions', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 3.0,
          'roomLength': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(15.0));
        expect(result.values['roomWidth'], equals(3.0));
        expect(result.values['roomLength'], equals(5.0));
      });

      test('manual mode uses area and calculates square dimensions', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 16.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(16.0));
        expect(result.values['roomWidth'], closeTo(4.0, 0.01));
        expect(result.values['roomLength'], closeTo(4.0, 0.01));
      });
    });

    group('Ceiling types', () {
      test('stores ceiling type correctly', () {
        final aluminum = calculator({
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'ceilingType': 0.0,
          'inputMode': 1.0,
        }, emptyPriceList);
        final steel = calculator({
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'ceilingType': 1.0,
          'inputMode': 1.0,
        }, emptyPriceList);
        final plastic = calculator({
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'ceilingType': 2.0,
          'inputMode': 1.0,
        }, emptyPriceList);

        expect(aluminum.values['ceilingType'], equals(0.0));
        expect(steel.values['ceilingType'], equals(1.0));
        expect(plastic.values['ceilingType'], equals(2.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{
          'roomWidth': 3.0,
          'roomLength': 4.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['inputMode'], equals(1.0)); // room mode
        expect(result.values['ceilingType'], equals(0.0)); // aluminum
        expect(result.values['railWidth'], equals(1.0)); // 100mm
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

      test('handles small room', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 1.0,
          'roomLength': 1.5,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(1.5));
        expect(result.values['railsCount'], greaterThan(0));
        expect(result.values['hangersCount'], greaterThan(0));
      });

      test('handles large bathroom', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 5.0,
          'roomLength': 8.0,
          'railWidth': 2.0, // 150mm
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(40.0));
        expect(result.values['railsCount'], greaterThan(0));
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
          'area': -12.0,
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
    });

    group('Price calculations', () {
      test('calculates total price when prices available', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'inputMode': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'rail', name: 'Рейка', price: 150.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'stringer', name: 'Стрингер', price: 200.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'wall_profile', name: 'Пристенный профиль', price: 100.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'hanger', name: 'Подвес', price: 30.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical bathroom ceiling', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 2.0,
          'roomLength': 2.5,
          'ceilingType': 0.0, // aluminum
          'railWidth': 1.0, // 100mm
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 2 * 2.5 = 5
        expect(result.values['area'], equals(5.0));
        // Rail step = 0.116
        // Rails = ceil(2 / 0.116) = 18
        expect(result.values['railsCount'], equals(18.0));
        // Perimeter = 2 * (2 + 2.5) = 9
        expect(result.values['perimeter'], equals(9.0));
      });

      test('kitchen ceiling with 150mm rails', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'ceilingType': 1.0, // steel
          'railWidth': 2.0, // 150mm
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 3 * 4 = 12
        expect(result.values['area'], equals(12.0));
        // Rail step = 0.166
        // Rails = ceil(3 / 0.166) = 19
        expect(result.values['railsCount'], equals(19.0));
        // Stringer rows = ceil(3 / 1.2) = 3
        expect(result.values['stringerRows'], equals(3.0));
      });

      test('manual mode calculation', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 9.0,
          'ceilingType': 2.0, // plastic
          'railWidth': 0.0, // 84mm
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 9
        expect(result.values['area'], equals(9.0));
        // sqrt(9) = 3
        expect(result.values['roomWidth'], closeTo(3.0, 0.01));
        expect(result.values['roomLength'], closeTo(3.0, 0.01));
        // Perimeter = 2 * (3 + 3) = 12
        expect(result.values['perimeter'], closeTo(12.0, 0.01));
      });
    });
  });
}
