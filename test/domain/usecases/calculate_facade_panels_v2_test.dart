import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_facade_panels_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateFacadePanelsV2', () {
    late CalculateFacadePanelsV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateFacadePanelsV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('40m perimeter, 3m height, 10sqm openings', () {
        final inputs = {
          'wallLength': 40.0,
          'wallHeight': 3.0,
          'openingsArea': 10.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Gross = 40 * 3 = 120, Wall = 120 - 10 = 110 sqm
        expect(result.values['grossArea'], equals(120.0));
        expect(result.values['wallArea'], equals(110.0));
      });

      test('larger house needs more materials', () {
        final small = calculator({
          'wallLength': 30.0,
          'wallHeight': 2.5,
        }, emptyPriceList);

        final large = calculator({
          'wallLength': 60.0,
          'wallHeight': 4.0,
        }, emptyPriceList);

        expect(
          large.values['panelsArea'],
          greaterThan(small.values['panelsArea']!),
        );
      });

      test('openings reduce wall area', () {
        final noOpenings = calculator({
          'wallLength': 40.0,
          'wallHeight': 3.0,
          'openingsArea': 0.0,
        }, emptyPriceList);

        final withOpenings = calculator({
          'wallLength': 40.0,
          'wallHeight': 3.0,
          'openingsArea': 20.0,
        }, emptyPriceList);

        expect(
          noOpenings.values['wallArea'],
          greaterThan(withOpenings.values['wallArea']!),
        );
      });
    });

    group('Panels calculation', () {
      test('panels area with 10% waste', () {
        final inputs = {
          'wallLength': 40.0,
          'wallHeight': 3.0,
          'openingsArea': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Wall = 120 sqm, Panels = 120 * 1.1 = 132 sqm
        expect(result.values['panelsArea'], closeTo(132.0, 0.1));
      });
    });

    group('Profile calculation', () {
      test('profile enabled by default', () {
        final inputs = {
          'wallLength': 40.0,
          'wallHeight': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['needProfile'], equals(1.0));
        expect(result.values['profileLength'], greaterThan(0));
      });

      test('no profile when disabled', () {
        final inputs = {
          'wallLength': 40.0,
          'wallHeight': 3.0,
          'needProfile': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['profileLength'], equals(0.0));
      });

      test('profile length based on 0.6m step', () {
        final inputs = {
          'wallLength': 12.0, // 12/0.6 = 20 verticals
          'wallHeight': 3.0,
          'needProfile': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 20 verticals * 3m * 1.1 = 66m
        expect(result.values['profileLength'], closeTo(66.0, 0.1));
      });
    });

    group('Insulation calculation', () {
      test('insulation enabled by default', () {
        final inputs = {
          'wallLength': 40.0,
          'wallHeight': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['needInsulation'], equals(1.0));
        expect(result.values['insulationArea'], greaterThan(0));
      });

      test('no insulation when disabled', () {
        final inputs = {
          'wallLength': 40.0,
          'wallHeight': 3.0,
          'needInsulation': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], equals(0.0));
      });

      test('insulation with 5% waste', () {
        final inputs = {
          'wallLength': 40.0,
          'wallHeight': 3.0,
          'openingsArea': 0.0,
          'needInsulation': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Wall = 120, Insulation = 120 * 1.05 = 126 sqm
        expect(result.values['insulationArea'], closeTo(126.0, 0.1));
      });
    });

    group('Corners calculation', () {
      test('corners based on height and 3m profile', () {
        final inputs = {
          'wallHeight': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 4 corners * 3m / 3m = 4 profiles
        expect(result.values['cornersCount'], equals(4.0));
      });

      test('taller walls need more corner profiles', () {
        final short = calculator({
          'wallHeight': 3.0,
        }, emptyPriceList);

        final tall = calculator({
          'wallHeight': 6.0,
        }, emptyPriceList);

        expect(
          tall.values['cornersCount'],
          greaterThan(short.values['cornersCount']!),
        );
      });
    });

    group('Starters calculation', () {
      test('starters based on perimeter and 3m profiles', () {
        final inputs = {
          'wallLength': 30.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // 30m / 3m = 10 starters
        expect(result.values['startersCount'], equals(10.0));
      });

      test('longer perimeter needs more starters', () {
        final short = calculator({
          'wallLength': 30.0,
        }, emptyPriceList);

        final long = calculator({
          'wallLength': 60.0,
        }, emptyPriceList);

        expect(
          long.values['startersCount'],
          greaterThan(short.values['startersCount']!),
        );
      });
    });

    group('Panel types', () {
      test('vinyl panels (type 0) is default', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['panelType'], equals(0.0));
      });

      test('accepts metal panels (type 1)', () {
        final inputs = {
          'panelType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['panelType'], equals(1.0));
      });

      test('accepts fiber panels (type 2)', () {
        final inputs = {
          'panelType': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['panelType'], equals(2.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallLength'], equals(40.0));
        expect(result.values['wallHeight'], equals(3.0));
        expect(result.values['openingsArea'], equals(10.0));
        expect(result.values['panelType'], equals(0.0));
        expect(result.values['needInsulation'], equals(1.0));
        expect(result.values['needProfile'], equals(1.0));
      });
    });

    group('Edge cases', () {
      test('clamps dimensions to valid range', () {
        final inputs = {
          'wallLength': 500.0, // max 200
          'wallHeight': 20.0, // max 10
          'openingsArea': 100.0, // max 50
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallLength'], equals(200.0));
        expect(result.values['wallHeight'], equals(10.0));
        expect(result.values['openingsArea'], equals(50.0));
      });

      test('handles minimum dimensions', () {
        final inputs = {
          'wallLength': 10.0,
          'wallHeight': 2.0,
          'openingsArea': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallArea'], greaterThan(0));
        expect(result.values['panelsArea'], greaterThan(0));
      });
    });

    group('Price calculations', () {
      test('calculates price when prices available', () {
        final inputs = {
          'wallLength': 40.0,
          'wallHeight': 3.0,
          'needInsulation': 1.0,
          'needProfile': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'facade_panel', name: 'Панели', price: 500.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'profile', name: 'Профиль', price: 100.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'insulation', name: 'Утеплитель', price: 200.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'corner', name: 'Угол', price: 300.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'starter', name: 'Стартовая', price: 150.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'wallLength': 40.0,
          'wallHeight': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });

      test('price includes only enabled options', () {
        final priceList = [
          const PriceItem(sku: 'insulation', name: 'Утеплитель', price: 200.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'profile', name: 'Профиль', price: 100.0, unit: 'м', imageUrl: ''),
        ];

        final withAll = calculator({
          'wallLength': 40.0,
          'needInsulation': 1.0,
          'needProfile': 1.0,
        }, priceList);

        final withoutOptions = calculator({
          'wallLength': 40.0,
          'needInsulation': 0.0,
          'needProfile': 0.0,
        }, priceList);

        expect(withAll.totalPrice, greaterThan(withoutOptions.totalPrice ?? 0));
      });
    });

    group('Full scenario tests', () {
      test('small house with all options', () {
        final inputs = {
          'wallLength': 30.0,
          'wallHeight': 2.5,
          'openingsArea': 8.0,
          'panelType': 0.0,
          'needInsulation': 1.0,
          'needProfile': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallArea'], closeTo(67.0, 0.1)); // 75 - 8
        expect(result.values['panelsArea'], greaterThan(0));
        expect(result.values['profileLength'], greaterThan(0));
        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['cornersCount'], greaterThan(0));
        expect(result.values['startersCount'], greaterThan(0));
      });

      test('large house without insulation', () {
        final inputs = {
          'wallLength': 80.0,
          'wallHeight': 4.0,
          'openingsArea': 25.0,
          'panelType': 1.0, // metal
          'needInsulation': 0.0,
          'needProfile': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallArea'], closeTo(295.0, 0.1)); // 320 - 25
        expect(result.values['insulationArea'], equals(0.0));
        expect(result.values['profileLength'], greaterThan(0));
      });

      test('renovation without profile', () {
        final inputs = {
          'wallLength': 40.0,
          'wallHeight': 3.0,
          'openingsArea': 10.0,
          'panelType': 2.0, // fiber
          'needInsulation': 1.0,
          'needProfile': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['profileLength'], equals(0.0));
        expect(result.values['insulationArea'], greaterThan(0));
      });
    });
  });
}
