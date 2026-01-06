import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/constants/region_constants.dart';

void main() {
  group('RegionConstants', () {
    group('regions', () {
      test('contains expected regions', () {
        expect(RegionConstants.regions, contains('Москва'));
        expect(RegionConstants.regions, contains('Санкт-Петербург'));
        expect(RegionConstants.regions, contains('Екатеринбург'));
        expect(RegionConstants.regions, contains('Краснодар'));
        expect(RegionConstants.regions, contains('Регионы РФ'));
      });

      test('has 10 regions', () {
        expect(RegionConstants.regions.length, 10);
      });
    });

    group('priceCoefficients', () {
      test('Moscow has coefficient 1.0', () {
        expect(RegionConstants.priceCoefficients['Москва'], 1.0);
      });

      test('Saint Petersburg has coefficient 0.95', () {
        expect(RegionConstants.priceCoefficients['Санкт-Петербург'], 0.95);
      });

      test('all regions have coefficients', () {
        for (final region in RegionConstants.regions) {
          expect(
            RegionConstants.priceCoefficients.containsKey(region),
            isTrue,
            reason: 'Missing price coefficient for $region',
          );
        }
      });

      test('all coefficients are between 0 and 1', () {
        for (final entry in RegionConstants.priceCoefficients.entries) {
          expect(entry.value, greaterThan(0));
          expect(entry.value, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('laborCoefficients', () {
      test('Moscow has coefficient 1.0', () {
        expect(RegionConstants.laborCoefficients['Москва'], 1.0);
      });

      test('all regions have labor coefficients', () {
        for (final region in RegionConstants.regions) {
          expect(
            RegionConstants.laborCoefficients.containsKey(region),
            isTrue,
            reason: 'Missing labor coefficient for $region',
          );
        }
      });

      test('all labor coefficients are between 0 and 1', () {
        for (final entry in RegionConstants.laborCoefficients.entries) {
          expect(entry.value, greaterThan(0));
          expect(entry.value, lessThanOrEqualTo(1.0));
        }
      });
    });

    group('getPriceCoefficient', () {
      test('returns correct coefficient for known region', () {
        expect(RegionConstants.getPriceCoefficient('Москва'), 1.0);
        expect(RegionConstants.getPriceCoefficient('Санкт-Петербург'), 0.95);
        expect(RegionConstants.getPriceCoefficient('Екатеринбург'), 0.75);
      });

      test('returns default 0.65 for unknown region', () {
        expect(RegionConstants.getPriceCoefficient('Unknown'), 0.65);
        expect(RegionConstants.getPriceCoefficient(''), 0.65);
      });
    });

    group('getLaborCoefficient', () {
      test('returns correct coefficient for known region', () {
        expect(RegionConstants.getLaborCoefficient('Москва'), 1.0);
        expect(RegionConstants.getLaborCoefficient('Санкт-Петербург'), 0.90);
        expect(RegionConstants.getLaborCoefficient('Екатеринбург'), 0.60);
      });

      test('returns default 0.50 for unknown region', () {
        expect(RegionConstants.getLaborCoefficient('Unknown'), 0.50);
        expect(RegionConstants.getLaborCoefficient(''), 0.50);
      });
    });
  });
}
