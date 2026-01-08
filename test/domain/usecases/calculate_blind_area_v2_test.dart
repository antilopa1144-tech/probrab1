import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_blind_area_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateBlindAreaV2', () {
    late CalculateBlindAreaV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateBlindAreaV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('10x8m house with 1m blind area', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 8.0,
          'blindAreaWidth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter = 2 * (10 + 8) = 36 m
        expect(result.values['perimeter'], equals(36.0));
        // Total area = 36 * 1 = 36 sqm
        expect(result.values['totalArea'], equals(36.0));
      });

      test('larger house has more area', () {
        final small = calculator({
          'houseLength': 8.0,
          'houseWidth': 6.0,
        }, emptyPriceList);

        final large = calculator({
          'houseLength': 15.0,
          'houseWidth': 12.0,
        }, emptyPriceList);

        expect(
          large.values['totalArea'],
          greaterThan(small.values['totalArea']!),
        );
      });

      test('wider blind area = more area', () {
        final narrow = calculator({
          'houseLength': 10.0,
          'houseWidth': 8.0,
          'blindAreaWidth': 0.8,
        }, emptyPriceList);

        final wide = calculator({
          'houseLength': 10.0,
          'houseWidth': 8.0,
          'blindAreaWidth': 1.5,
        }, emptyPriceList);

        expect(
          wide.values['totalArea'],
          greaterThan(narrow.values['totalArea']!),
        );
      });
    });

    group('Concrete blind area (type 0)', () {
      test('calculates concrete volume with 5% waste', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 10.0,
          'blindAreaWidth': 1.0,
          'thickness': 0.1, // 10 cm
          'blindAreaType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter = 40 m, Area = 40 sqm
        // Concrete = 40 * 0.1 * 1.05 = 4.2 m³
        expect(result.values['concreteVolume'], closeTo(4.2, 0.1));
      });

      test('thicker concrete = more volume', () {
        final thin = calculator({
          'houseLength': 10.0,
          'houseWidth': 8.0,
          'thickness': 0.08,
          'blindAreaType': 0.0,
        }, emptyPriceList);

        final thick = calculator({
          'houseLength': 10.0,
          'houseWidth': 8.0,
          'thickness': 0.15,
          'blindAreaType': 0.0,
        }, emptyPriceList);

        expect(
          thick.values['concreteVolume'],
          greaterThan(thin.values['concreteVolume']!),
        );
      });

      test('no paving area for concrete type', () {
        final inputs = {
          'blindAreaType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['pavingArea'], equals(0.0));
      });
    });

    group('Paving blind area (type 1)', () {
      test('calculates paving area with 10% waste', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 10.0,
          'blindAreaWidth': 1.0,
          'blindAreaType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 40 sqm, Paving = 40 * 1.1 = 44 sqm
        expect(result.values['pavingArea'], closeTo(44.0, 0.1));
      });

      test('no concrete volume for paving type', () {
        final inputs = {
          'blindAreaType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['concreteVolume'], equals(0.0));
      });
    });

    group('Soft blind area (type 2)', () {
      test('no concrete or paving for soft type', () {
        final inputs = {
          'blindAreaType': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['concreteVolume'], equals(0.0));
        expect(result.values['pavingArea'], equals(0.0));
      });

      test('still calculates sand and gravel', () {
        final inputs = {
          'blindAreaType': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['sandVolume'], greaterThan(0));
        expect(result.values['gravelVolume'], greaterThan(0));
      });
    });

    group('Sand calculations', () {
      test('10cm sand layer with 10% waste', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 10.0,
          'blindAreaWidth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 40 sqm
        // Sand = 40 * 0.10 * 1.1 = 4.4 m³
        expect(result.values['sandVolume'], closeTo(4.4, 0.1));
      });
    });

    group('Gravel calculations', () {
      test('15cm gravel layer with 10% waste', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 10.0,
          'blindAreaWidth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 40 sqm
        // Gravel = 40 * 0.15 * 1.1 = 6.6 m³
        expect(result.values['gravelVolume'], closeTo(6.6, 0.1));
      });
    });

    group('Membrane calculations', () {
      test('membrane with 15% overlap', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 10.0,
          'blindAreaWidth': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 40 sqm
        // Membrane = 40 * 1.15 = 46 sqm
        expect(result.values['membranArea'], closeTo(46.0, 0.1));
      });
    });

    group('Insulation option', () {
      test('no insulation by default', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 8.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['needInsulation'], equals(0.0));
        expect(result.values['insulationArea'], equals(0.0));
      });

      test('insulation with 10% waste when enabled', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 10.0,
          'blindAreaWidth': 1.0,
          'needInsulation': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Area = 40 sqm
        // Insulation = 40 * 1.1 = 44 sqm
        expect(result.values['insulationArea'], closeTo(44.0, 0.1));
      });
    });

    group('Drainage option', () {
      test('drainage enabled by default', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 8.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['needDrainage'], equals(1.0));
        // Drainage length = perimeter = 36 m
        expect(result.values['drainageLength'], equals(36.0));
      });

      test('no drainage when disabled', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 8.0,
          'needDrainage': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['drainageLength'], equals(0.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['houseLength'], equals(10.0));
        expect(result.values['houseWidth'], equals(8.0));
        expect(result.values['blindAreaWidth'], equals(1.0));
        expect(result.values['thickness'], equals(0.1));
        expect(result.values['blindAreaType'], equals(0.0)); // concrete
        expect(result.values['needInsulation'], equals(0.0)); // no
        expect(result.values['needDrainage'], equals(1.0)); // yes
      });
    });

    group('Edge cases', () {
      test('clamps dimensions to valid range', () {
        final inputs = {
          'houseLength': 50.0, // max 30
          'houseWidth': 30.0, // max 20
          'blindAreaWidth': 5.0, // max 2.0
          'thickness': 0.5, // max 0.2
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['houseLength'], equals(30.0));
        expect(result.values['houseWidth'], equals(20.0));
        expect(result.values['blindAreaWidth'], equals(2.0));
        expect(result.values['thickness'], equals(0.2));
      });

      test('handles minimum dimensions', () {
        final inputs = {
          'houseLength': 3.0,
          'houseWidth': 3.0,
          'blindAreaWidth': 0.6,
          'thickness': 0.05,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['houseLength'], equals(3.0));
        expect(result.values['houseWidth'], equals(3.0));
        expect(result.values['blindAreaWidth'], equals(0.6));
        expect(result.values['thickness'], equals(0.05));
      });
    });

    group('Price calculations', () {
      test('calculates price for concrete blind area', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 8.0,
          'blindAreaType': 0.0,
          'needInsulation': 0.0,
          'needDrainage': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'concrete', name: 'Бетон', price: 5000.0, unit: 'м³', imageUrl: ''),
          const PriceItem(sku: 'sand', name: 'Песок', price: 1000.0, unit: 'м³', imageUrl: ''),
          const PriceItem(sku: 'gravel', name: 'Щебень', price: 1500.0, unit: 'м³', imageUrl: ''),
          const PriceItem(sku: 'membrane', name: 'Мембрана', price: 100.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'drainage_pipe', name: 'Дренаж', price: 200.0, unit: 'м', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('calculates price for paving blind area', () {
        final inputs = {
          'blindAreaType': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'paving_tile', name: 'Плитка', price: 800.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'sand', name: 'Песок', price: 1000.0, unit: 'м³', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 8.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });

      test('includes insulation price when enabled', () {
        final priceList = [
          const PriceItem(sku: 'insulation_eps', name: 'Утеплитель', price: 500.0, unit: 'м²', imageUrl: ''),
        ];

        final without = calculator({
          'needInsulation': 0.0,
        }, priceList);

        final with_ = calculator({
          'needInsulation': 1.0,
        }, priceList);

        expect(with_.totalPrice, greaterThan(without.totalPrice ?? 0));
      });
    });

    group('Full scenario tests', () {
      test('concrete blind area with all options', () {
        final inputs = {
          'houseLength': 12.0,
          'houseWidth': 10.0,
          'blindAreaWidth': 1.2,
          'thickness': 0.12,
          'blindAreaType': 0.0,
          'needInsulation': 1.0,
          'needDrainage': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['perimeter'], equals(44.0));
        expect(result.values['totalArea'], closeTo(52.8, 0.1));
        expect(result.values['concreteVolume'], greaterThan(0));
        expect(result.values['sandVolume'], greaterThan(0));
        expect(result.values['gravelVolume'], greaterThan(0));
        expect(result.values['membranArea'], greaterThan(0));
        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['drainageLength'], equals(44.0));
      });

      test('paving blind area without extras', () {
        final inputs = {
          'houseLength': 8.0,
          'houseWidth': 6.0,
          'blindAreaWidth': 0.8,
          'blindAreaType': 1.0,
          'needInsulation': 0.0,
          'needDrainage': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['concreteVolume'], equals(0.0));
        expect(result.values['pavingArea'], greaterThan(0));
        expect(result.values['insulationArea'], equals(0.0));
        expect(result.values['drainageLength'], equals(0.0));
      });

      test('soft blind area with insulation', () {
        final inputs = {
          'houseLength': 10.0,
          'houseWidth': 8.0,
          'blindAreaType': 2.0,
          'needInsulation': 1.0,
          'needDrainage': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['concreteVolume'], equals(0.0));
        expect(result.values['pavingArea'], equals(0.0));
        expect(result.values['sandVolume'], greaterThan(0));
        expect(result.values['gravelVolume'], greaterThan(0));
        expect(result.values['insulationArea'], greaterThan(0));
      });
    });
  });
}
