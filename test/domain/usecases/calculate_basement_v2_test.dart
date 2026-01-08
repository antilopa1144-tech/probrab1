import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_basement_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateBasementV2', () {
    late CalculateBasementV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateBasementV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('10x8m basement, 2.5m depth', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
          'depth': 2.5,
          'wallThickness': 0.3,
        };

        final result = calculator(inputs, emptyPriceList);

        // Floor area = 10 * 8 = 80 sqm
        expect(result.values['floorArea'], equals(80.0));
        // Perimeter = 2 * (10 + 8) = 36 m
        expect(result.values['perimeter'], equals(36.0));
        // Wall area = 36 * 2.5 = 90 sqm
        expect(result.values['wallArea'], equals(90.0));
      });

      test('larger basement needs more materials', () {
        final small = calculator({
          'length': 5.0,
          'width': 4.0,
          'depth': 2.0,
        }, emptyPriceList);

        final large = calculator({
          'length': 15.0,
          'width': 12.0,
          'depth': 3.0,
        }, emptyPriceList);

        expect(
          large.values['floorArea'],
          greaterThan(small.values['floorArea']!),
        );
        expect(
          large.values['concreteVolume'],
          greaterThan(small.values['concreteVolume']!),
        );
      });
    });

    group('Concrete calculations', () {
      test('concrete includes floor and walls with waste', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
          'depth': 2.5,
          'wallThickness': 0.3,
        };

        final result = calculator(inputs, emptyPriceList);

        // Floor volume = 80 * 0.15 = 12 cbm
        // Wall volume = 90 * 0.3 = 27 cbm
        // Total = (12 + 27) * 1.05 = 40.95 cbm
        expect(result.values['concreteVolume'], closeTo(40.95, 0.1));
      });

      test('thicker walls = more concrete', () {
        final thin = calculator({
          'length': 10.0,
          'width': 8.0,
          'depth': 2.5,
          'wallThickness': 0.2,
        }, emptyPriceList);

        final thick = calculator({
          'length': 10.0,
          'width': 8.0,
          'depth': 2.5,
          'wallThickness': 0.5,
        }, emptyPriceList);

        expect(
          thick.values['concreteVolume'],
          greaterThan(thin.values['concreteVolume']!),
        );
      });

      test('deeper basement = more concrete', () {
        final shallow = calculator({
          'length': 10.0,
          'width': 8.0,
          'depth': 2.0,
        }, emptyPriceList);

        final deep = calculator({
          'length': 10.0,
          'width': 8.0,
          'depth': 3.5,
        }, emptyPriceList);

        expect(
          deep.values['concreteVolume'],
          greaterThan(shallow.values['concreteVolume']!),
        );
      });
    });

    group('Waterproofing calculations', () {
      test('waterproof with 15% overlap', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
          'depth': 2.5,
          'needWaterproof': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Waterproof = (80 + 90) * 1.15 = 195.5 sqm
        expect(result.values['waterproofArea'], closeTo(195.5, 0.1));
      });

      test('no waterproof when disabled', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
          'needWaterproof': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['waterproofArea'], equals(0.0));
      });
    });

    group('Insulation calculations', () {
      test('insulation with 10% waste', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
          'depth': 2.5,
          'needInsulation': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Insulation = (80 + 90) * 1.1 = 187 sqm
        expect(result.values['insulationArea'], closeTo(187.0, 0.1));
      });

      test('no insulation when disabled', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
          'needInsulation': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['insulationArea'], equals(0.0));
      });
    });

    group('Drainage calculations', () {
      test('drainage with 10% waste', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
          'needDrainage': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter = 36 m
        // Drainage = 36 * 1.1 = 39.6 m
        expect(result.values['drainageLength'], closeTo(39.6, 0.1));
      });

      test('no drainage when disabled', () {
        final inputs = {
          'length': 10.0,
          'width': 8.0,
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

        expect(result.values['length'], equals(10.0));
        expect(result.values['width'], equals(8.0));
        expect(result.values['depth'], equals(2.5));
        expect(result.values['wallThickness'], equals(0.3));
        expect(result.values['basementType'], equals(0.0)); // technical
        expect(result.values['needWaterproof'], equals(1.0)); // yes
        expect(result.values['needInsulation'], equals(0.0)); // no by default
        expect(result.values['needDrainage'], equals(1.0)); // yes
      });
    });

    group('Edge cases', () {
      test('clamps dimensions to valid range', () {
        final inputs = {
          'length': 50.0, // Invalid, should clamp to 30
          'width': 50.0, // Invalid, should clamp to 20
          'depth': 10.0, // Invalid, should clamp to 4
          'wallThickness': 1.0, // Invalid, should clamp to 0.5
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['length'], equals(30.0));
        expect(result.values['width'], equals(20.0));
        expect(result.values['depth'], equals(4.0));
        expect(result.values['wallThickness'], equals(0.5));
      });

      test('handles minimum dimensions', () {
        final inputs = {
          'length': 3.0,
          'width': 3.0,
          'depth': 1.5,
          'wallThickness': 0.2,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['length'], equals(3.0));
        expect(result.values['width'], equals(3.0));
        expect(result.values['depth'], equals(1.5));
        expect(result.values['floorArea'], greaterThan(0));
      });

      test('handles large basement', () {
        final inputs = {
          'length': 30.0,
          'width': 20.0,
          'depth': 4.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorArea'], equals(600.0));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero length', () {
        final inputs = {
          'length': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative length', () {
        final inputs = {
          'length': -10.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero width', () {
        final inputs = {
          'width': 0.0,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for zero depth', () {
        final inputs = {
          'depth': 0.0,
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
          'depth': 2.5,
          'needWaterproof': 1.0,
          'needInsulation': 1.0,
          'needDrainage': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'concrete', name: 'Бетон', price: 5000.0, unit: 'м³', imageUrl: ''),
          const PriceItem(sku: 'waterproof', name: 'Гидроизоляция', price: 300.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'insulation', name: 'Утеплитель', price: 400.0, unit: 'м²', imageUrl: ''),
          const PriceItem(sku: 'drainage', name: 'Дренаж', price: 500.0, unit: 'м.п.', imageUrl: ''),
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
      test('technical basement with waterproof and drainage', () {
        final inputs = {
          'length': 12.0,
          'width': 10.0,
          'depth': 2.5,
          'wallThickness': 0.3,
          'basementType': 0.0, // technical
          'needWaterproof': 1.0,
          'needInsulation': 0.0,
          'needDrainage': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorArea'], equals(120.0));
        expect(result.values['insulationArea'], equals(0.0));
        expect(result.values['waterproofArea'], greaterThan(0));
        expect(result.values['drainageLength'], greaterThan(0));
      });

      test('living basement with full options', () {
        final inputs = {
          'length': 8.0,
          'width': 6.0,
          'depth': 2.8,
          'wallThickness': 0.3,
          'basementType': 1.0, // living
          'needWaterproof': 1.0,
          'needInsulation': 1.0,
          'needDrainage': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['basementType'], equals(1.0));
        expect(result.values['insulationArea'], greaterThan(0));
        expect(result.values['waterproofArea'], greaterThan(0));
        expect(result.values['drainageLength'], greaterThan(0));
      });

      test('garage basement minimal', () {
        final inputs = {
          'length': 6.0,
          'width': 4.0,
          'depth': 2.2,
          'basementType': 2.0, // garage
          'needWaterproof': 1.0,
          'needInsulation': 0.0,
          'needDrainage': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['basementType'], equals(2.0));
        expect(result.values['floorArea'], equals(24.0));
        expect(result.values['insulationArea'], equals(0.0));
        expect(result.values['drainageLength'], equals(0.0));
      });
    });
  });
}
