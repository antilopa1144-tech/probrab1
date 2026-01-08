import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_doors_install_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateDoorsInstallV2', () {
    late CalculateDoorsInstallV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateDoorsInstallV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('3 doors calculation', () {
        final inputs = {
          'doorsCount': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['doorsCount'], equals(3.0));
        expect(result.values['framesCount'], equals(3.0));
        expect(result.values['handlesCount'], equals(3.0));
      });

      test('more doors = more materials', () {
        final few = calculator({
          'doorsCount': 2.0,
        }, emptyPriceList);

        final many = calculator({
          'doorsCount': 8.0,
        }, emptyPriceList);

        expect(
          many.values['hingesCount'],
          greaterThan(few.values['hingesCount']!),
        );
        expect(
          many.values['foamCans'],
          greaterThan(few.values['foamCans']!),
        );
      });

      test('frames count equals doors count', () {
        final inputs = {
          'doorsCount': 5.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['framesCount'], equals(result.values['doorsCount']));
      });
    });

    group('Door types', () {
      test('interior door (type 0) has 2 hinges', () {
        final inputs = {
          'doorsCount': 1.0,
          'doorType': 0.0, // interior
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['hingesCount'], equals(2.0));
      });

      test('entrance door (type 1) has 3 hinges', () {
        final inputs = {
          'doorsCount': 1.0,
          'doorType': 1.0, // entrance
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['hingesCount'], equals(3.0));
      });

      test('glass door (type 2) has 2 hinges', () {
        final inputs = {
          'doorsCount': 1.0,
          'doorType': 2.0, // glass
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['hingesCount'], equals(2.0));
      });

      test('multiple entrance doors get 3 hinges each', () {
        final inputs = {
          'doorsCount': 4.0,
          'doorType': 1.0, // entrance
        };

        final result = calculator(inputs, emptyPriceList);

        // 4 doors × 3 hinges = 12 hinges
        expect(result.values['hingesCount'], equals(12.0));
      });
    });

    group('Handles calculation', () {
      test('one handle set per door', () {
        final inputs = {
          'doorsCount': 6.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['handlesCount'], equals(6.0));
      });
    });

    group('Foam calculation', () {
      test('1 can per 2 doors, rounded up', () {
        // 1 door = 1 can
        final one = calculator({'doorsCount': 1.0}, emptyPriceList);
        expect(one.values['foamCans'], equals(1.0));

        // 2 doors = 1 can
        final two = calculator({'doorsCount': 2.0}, emptyPriceList);
        expect(two.values['foamCans'], equals(1.0));

        // 3 doors = 2 cans
        final three = calculator({'doorsCount': 3.0}, emptyPriceList);
        expect(three.values['foamCans'], equals(2.0));

        // 4 doors = 2 cans
        final four = calculator({'doorsCount': 4.0}, emptyPriceList);
        expect(four.values['foamCans'], equals(2.0));

        // 5 doors = 3 cans
        final five = calculator({'doorsCount': 5.0}, emptyPriceList);
        expect(five.values['foamCans'], equals(3.0));
      });
    });

    group('Casing calculation', () {
      test('casing enabled by default', () {
        final inputs = {
          'doorsCount': 1.0,
          'doorHeight': 2.0,
          'doorWidth': 0.8,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['needCasing'], equals(1.0));
        expect(result.values['casingMeters'], greaterThan(0));
      });

      test('no casing when disabled', () {
        final inputs = {
          'doorsCount': 3.0,
          'needCasing': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['casingMeters'], equals(0.0));
      });

      test('casing length with 10% waste', () {
        final inputs = {
          'doorsCount': 1.0,
          'doorHeight': 2.0,
          'doorWidth': 0.8,
          'needCasing': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter = 2*2.0 + 0.8 = 4.8 m
        // Both sides = 4.8 * 2 = 9.6 m
        // With 10% waste = 9.6 * 1.1 = 10.56 m
        expect(result.values['casingMeters'], closeTo(10.56, 0.1));
      });

      test('larger doors need more casing', () {
        final small = calculator({
          'doorsCount': 1.0,
          'doorHeight': 1.9,
          'doorWidth': 0.7,
          'needCasing': 1.0,
        }, emptyPriceList);

        final large = calculator({
          'doorsCount': 1.0,
          'doorHeight': 2.3,
          'doorWidth': 1.0,
          'needCasing': 1.0,
        }, emptyPriceList);

        expect(
          large.values['casingMeters'],
          greaterThan(small.values['casingMeters']!),
        );
      });
    });

    group('Threshold calculation', () {
      test('no threshold by default', () {
        final inputs = {
          'doorsCount': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['needThreshold'], equals(0.0));
        expect(result.values['thresholdCount'], equals(0.0));
      });

      test('threshold count equals doors count when enabled', () {
        final inputs = {
          'doorsCount': 5.0,
          'needThreshold': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['thresholdCount'], equals(5.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['doorsCount'], equals(3.0));
        expect(result.values['doorHeight'], equals(2.0));
        expect(result.values['doorWidth'], equals(0.8));
        expect(result.values['doorType'], equals(0.0)); // interior
        expect(result.values['needCasing'], equals(1.0)); // yes
        expect(result.values['needThreshold'], equals(0.0)); // no
      });
    });

    group('Edge cases', () {
      test('clamps doors count to valid range', () {
        final tooMany = calculator({
          'doorsCount': 50.0, // max 15
        }, emptyPriceList);

        expect(tooMany.values['doorsCount'], equals(15.0));

        final tooFew = calculator({
          'doorsCount': 0.0, // min 1
        }, emptyPriceList);

        expect(tooFew.values['doorsCount'], equals(1.0));
      });

      test('clamps door dimensions to valid range', () {
        final inputs = {
          'doorHeight': 3.0, // max 2.4
          'doorWidth': 2.0, // max 1.2
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['doorHeight'], equals(2.4));
        expect(result.values['doorWidth'], equals(1.2));
      });

      test('handles minimum dimensions', () {
        final inputs = {
          'doorsCount': 1.0,
          'doorHeight': 1.8,
          'doorWidth': 0.6,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['doorHeight'], equals(1.8));
        expect(result.values['doorWidth'], equals(0.6));
      });
    });

    group('Price calculations', () {
      test('calculates total price when prices available', () {
        final inputs = {
          'doorsCount': 3.0,
          'needCasing': 1.0,
          'needThreshold': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'door', name: 'Дверь', price: 5000.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'door_frame', name: 'Коробка', price: 2000.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'hinge', name: 'Петля', price: 300.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'handle', name: 'Ручка', price: 800.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'foam', name: 'Пена', price: 400.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'casing', name: 'Наличник', price: 150.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'threshold', name: 'Порог', price: 500.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'doorsCount': 3.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });

      test('price includes casing only when enabled', () {
        final priceList = [
          const PriceItem(sku: 'casing', name: 'Наличник', price: 150.0, unit: 'м', imageUrl: ''),
        ];

        final without = calculator({
          'doorsCount': 3.0,
          'needCasing': 0.0,
        }, priceList);

        final with_ = calculator({
          'doorsCount': 3.0,
          'needCasing': 1.0,
        }, priceList);

        expect(with_.totalPrice, greaterThan(without.totalPrice ?? 0));
      });

      test('price includes threshold only when enabled', () {
        final priceList = [
          const PriceItem(sku: 'threshold', name: 'Порог', price: 500.0, unit: 'шт', imageUrl: ''),
        ];

        final without = calculator({
          'doorsCount': 3.0,
          'needThreshold': 0.0,
        }, priceList);

        final with_ = calculator({
          'doorsCount': 3.0,
          'needThreshold': 1.0,
        }, priceList);

        expect(with_.totalPrice, greaterThan(without.totalPrice ?? 0));
      });
    });

    group('Full scenario tests', () {
      test('3 interior doors with casing', () {
        final inputs = {
          'doorsCount': 3.0,
          'doorHeight': 2.0,
          'doorWidth': 0.8,
          'doorType': 0.0, // interior
          'needCasing': 1.0,
          'needThreshold': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['doorsCount'], equals(3.0));
        expect(result.values['framesCount'], equals(3.0));
        expect(result.values['hingesCount'], equals(6.0)); // 3 doors × 2 hinges
        expect(result.values['handlesCount'], equals(3.0));
        expect(result.values['foamCans'], equals(2.0)); // ceil(3/2)
        expect(result.values['casingMeters'], greaterThan(0));
        expect(result.values['thresholdCount'], equals(0.0));
      });

      test('entrance door with threshold', () {
        final inputs = {
          'doorsCount': 1.0,
          'doorHeight': 2.1,
          'doorWidth': 0.9,
          'doorType': 1.0, // entrance
          'needCasing': 1.0,
          'needThreshold': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['hingesCount'], equals(3.0)); // entrance has 3 hinges
        expect(result.values['thresholdCount'], equals(1.0));
      });

      test('many glass doors without extras', () {
        final inputs = {
          'doorsCount': 10.0,
          'doorType': 2.0, // glass
          'needCasing': 0.0,
          'needThreshold': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['hingesCount'], equals(20.0)); // 10 × 2
        expect(result.values['foamCans'], equals(5.0)); // ceil(10/2)
        expect(result.values['casingMeters'], equals(0.0));
        expect(result.values['thresholdCount'], equals(0.0));
      });
    });
  });
}
