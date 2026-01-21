import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_cassette_ceiling_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateCassetteCeilingV2', () {
    late CalculateCassetteCeilingV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateCassetteCeilingV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('4x5 room, 600x600 cassettes', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'cassetteSize': 0.0, // 600x600
          'ceilingType': 0.0,
          'inputMode': 1.0, // room mode
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 4 * 5 = 20 sqm
        expect(result.values['area'], equals(20.0));
        // Cassettes = ceil(20 * 1.05 / 0.36) = ceil(58.33) = 59
        expect(result.values['cassettesCount'], equals(59.0));
        // Perimeter = 2 * (4 + 5) = 18
        expect(result.values['perimeter'], equals(18.0));
      });

      test('larger room needs more cassettes', () {
        final smallInputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'cassetteSize': 0.0,
          'inputMode': 1.0,
        };
        final largeInputs = {
          'roomWidth': 6.0,
          'roomLength': 8.0,
          'cassetteSize': 0.0,
          'inputMode': 1.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['cassettesCount'],
          greaterThan(smallResult.values['cassettesCount']!),
        );
      });
    });

    group('Cassette sizes', () {
      test('600x600 cassettes: area = 0.36 sqm', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'cassetteSize': 0.0, // 600x600
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['cassetteArea'], equals(0.36));
        // Area = 12, cassettes = ceil(12 * 1.05 / 0.36) = 36 (due to floating point)
        expect(result.values['cassettesCount'], equals(36.0));
      });

      test('600x1200 cassettes: area = 0.72 sqm', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'cassetteSize': 1.0, // 600x1200
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['cassetteArea'], equals(0.72));
        // Area = 12, cassettes = ceil(12 * 1.05 / 0.72) = ceil(17.5) = 18
        expect(result.values['cassettesCount'], equals(18.0));
      });

      test('300x300 cassettes: area = 0.09 sqm', () {
        final inputs = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'cassetteSize': 2.0, // 300x300
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['cassetteArea'], equals(0.09));
        // Area = 12, cassettes = ceil(12 * 1.05 / 0.09) = 141 (due to floating point)
        expect(result.values['cassettesCount'], equals(141.0));
      });

      test('larger cassettes = fewer cassettes needed', () {
        final small = calculator({
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'cassetteSize': 2.0, // 300x300
          'inputMode': 1.0,
        }, emptyPriceList);
        final large = calculator({
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'cassetteSize': 1.0, // 600x1200
          'inputMode': 1.0,
        }, emptyPriceList);

        expect(
          large.values['cassettesCount'],
          lessThan(small.values['cassettesCount']!),
        );
      });
    });

    group('Main profile calculations', () {
      test('main profile = 2.0 m.p. per sqm (SNiP norm)', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 20 sqm, main profile = 20 * 2.0 = 40 m.p.
        expect(result.values['mainProfileLength'], equals(40.0));
      });

      test('larger room needs more main profile', () {
        final smallInputs = {
          'roomWidth': 3.0,
          'roomLength': 3.0,
          'inputMode': 1.0,
        };
        final largeInputs = {
          'roomWidth': 6.0,
          'roomLength': 8.0,
          'inputMode': 1.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['mainProfileLength'],
          greaterThan(smallResult.values['mainProfileLength']!),
        );
      });
    });

    group('Cross profile calculations', () {
      test('cross profile = 1.35 m.p. per sqm (SNiP norm)', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'cassetteSize': 0.0, // 600x600
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 20 sqm, cross profile = 20 * 1.35 = 27 m.p.
        expect(result.values['crossProfileLength'], equals(27.0));
      });

      test('cross profile independent of cassette size', () {
        final inputs600x600 = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'cassetteSize': 0.0, // 600x600
          'inputMode': 1.0,
        };
        final inputs600x1200 = {
          'roomWidth': 3.0,
          'roomLength': 4.0,
          'cassetteSize': 1.0, // 600x1200
          'inputMode': 1.0,
        };

        final result1 = calculator(inputs600x600, emptyPriceList);
        final result2 = calculator(inputs600x1200, emptyPriceList);

        // Both should be area * 1.35 = 12 * 1.35 = 16.2
        expect(result1.values['crossProfileLength'], equals(16.2));
        expect(result2.values['crossProfileLength'], equals(16.2));
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
      test('hangers = 2.5 per sqm (SNiP norm)', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 20, hangers = ceil(20 * 2.5) = ceil(50) = 50
        expect(result.values['hangersCount'], equals(50.0));
      });

      test('more hangers for larger room', () {
        final smallInputs = {
          'roomWidth': 2.0,
          'roomLength': 2.0,
          'inputMode': 1.0,
        };
        final largeInputs = {
          'roomWidth': 6.0,
          'roomLength': 8.0,
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
          'roomWidth': 4.0,
          'roomLength': 6.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(24.0));
        expect(result.values['roomWidth'], equals(4.0));
        expect(result.values['roomLength'], equals(6.0));
      });

      test('manual mode uses area and calculates square dimensions', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 25.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(25.0));
        expect(result.values['roomWidth'], closeTo(5.0, 0.01));
        expect(result.values['roomLength'], closeTo(5.0, 0.01));
      });
    });

    group('Ceiling types', () {
      test('stores ceiling type correctly', () {
        final metal = calculator({
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'ceilingType': 0.0,
          'inputMode': 1.0,
        }, emptyPriceList);
        final mirror = calculator({
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'ceilingType': 1.0,
          'inputMode': 1.0,
        }, emptyPriceList);
        final perforated = calculator({
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'ceilingType': 2.0,
          'inputMode': 1.0,
        }, emptyPriceList);

        expect(metal.values['ceilingType'], equals(0.0));
        expect(mirror.values['ceilingType'], equals(1.0));
        expect(perforated.values['ceilingType'], equals(2.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{
          'roomWidth': 4.0,
          'roomLength': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['inputMode'], equals(1.0)); // room mode
        expect(result.values['ceilingType'], equals(0.0)); // metal
        expect(result.values['cassetteSize'], equals(0.0)); // 600x600
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
          'roomWidth': 1.5,
          'roomLength': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(3.0));
        expect(result.values['cassettesCount'], greaterThan(0));
        expect(result.values['hangersCount'], greaterThan(0));
      });

      test('handles large office', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 10.0,
          'roomLength': 15.0,
          'cassetteSize': 1.0, // 600x1200
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['area'], equals(150.0));
        expect(result.values['cassettesCount'], greaterThan(0));
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
          'area': -20.0,
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
          'roomLength': 5.0,
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
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'inputMode': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'cassette', name: 'Кассета', price: 250.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'main_profile', name: 'Основной профиль', price: 120.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'cross_profile', name: 'Поперечный профиль', price: 80.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'wall_profile', name: 'Пристенный профиль', price: 60.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'hanger', name: 'Подвес', price: 25.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'inputMode': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical office ceiling with 600x600', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 6.0,
          'roomLength': 8.0,
          'ceilingType': 0.0, // metal
          'cassetteSize': 0.0, // 600x600
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 6 * 8 = 48
        expect(result.values['area'], equals(48.0));
        // Cassettes = ceil(48 * 1.05 / 0.36) = 141 (due to floating point)
        expect(result.values['cassettesCount'], equals(141.0));
        // Perimeter = 2 * (6 + 8) = 28
        expect(result.values['perimeter'], equals(28.0));
        // Main profile = 48 * 2.0 = 96
        expect(result.values['mainProfileLength'], equals(96.0));
        // Cross profile = 48 * 1.35 = 64.8
        expect(result.values['crossProfileLength'], equals(64.8));
        // Hangers = ceil(48 * 2.5) = 120
        expect(result.values['hangersCount'], equals(120.0));
      });

      test('bathroom ceiling with 300x300', () {
        final inputs = {
          'inputMode': 1.0,
          'roomWidth': 2.0,
          'roomLength': 3.0,
          'ceilingType': 1.0, // mirror
          'cassetteSize': 2.0, // 300x300
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 2 * 3 = 6
        expect(result.values['area'], equals(6.0));
        // Cassettes = ceil(6 * 1.05 / 0.09) = 71 (due to floating point)
        expect(result.values['cassettesCount'], equals(71.0));
      });

      test('manual mode calculation', () {
        final inputs = {
          'inputMode': 0.0,
          'area': 16.0,
          'ceilingType': 2.0, // perforated
          'cassetteSize': 1.0, // 600x1200
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 16
        expect(result.values['area'], equals(16.0));
        // sqrt(16) = 4
        expect(result.values['roomWidth'], closeTo(4.0, 0.01));
        expect(result.values['roomLength'], closeTo(4.0, 0.01));
        // Perimeter = 2 * (4 + 4) = 16
        expect(result.values['perimeter'], closeTo(16.0, 0.01));
        // Cassettes = ceil(16 * 1.05 / 0.72) = ceil(23.33) = 24
        expect(result.values['cassettesCount'], equals(24.0));
      });
    });
  });
}
