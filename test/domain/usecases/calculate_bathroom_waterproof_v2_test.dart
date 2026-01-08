import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_bathroom_waterproof_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateBathroomWaterproofV2', () {
    late CalculateBathroomWaterproofV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateBathroomWaterproofV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('2.5x1.8m bathroom, 0.2m wall height', () {
        final inputs = {
          'length': 2.5,
          'width': 1.8,
          'wallHeight': 0.2,
        };

        final result = calculator(inputs, emptyPriceList);

        // Floor area = 2.5 * 1.8 = 4.5 sqm
        expect(result.values['floorArea'], equals(4.5));
        // Perimeter = 2 * (2.5 + 1.8) = 8.6 m
        expect(result.values['perimeter'], equals(8.6));
        // Wall area = 8.6 * 0.2 = 1.72 sqm
        expect(result.values['wallArea'], closeTo(1.72, 0.01));
      });

      test('larger bathroom needs more materials', () {
        final small = calculator({
          'length': 2.0,
          'width': 1.5,
        }, emptyPriceList);

        final large = calculator({
          'length': 4.0,
          'width': 3.0,
        }, emptyPriceList);

        expect(
          large.values['totalArea'],
          greaterThan(small.values['totalArea']!),
        );
        expect(
          large.values['waterproofKg'],
          greaterThan(small.values['waterproofKg']!),
        );
      });
    });

    group('Waterproof type calculations', () {
      test('liquid waterproof - 1.5 kg/sqm per layer', () {
        final inputs = {
          'length': 2.0,
          'width': 2.0,
          'wallHeight': 0.2,
          'waterproofType': 0.0, // liquid
          'layers': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Floor = 4 sqm, Wall = 2*(2+2)*0.2 = 1.6 sqm
        // Total = (4 + 1.6) * 1.1 = 6.16 sqm
        // Waterproof = 6.16 * 1.5 * 2 = 18.48 kg
        expect(result.values['waterproofKg'], closeTo(18.48, 0.1));
      });

      test('roll waterproof - 1.0 sqm/sqm', () {
        final inputs = {
          'length': 2.0,
          'width': 2.0,
          'wallHeight': 0.2,
          'waterproofType': 1.0, // roll
          'layers': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Total = 6.16 sqm
        // Waterproof = 6.16 * 1.0 * 1 = 6.16 kg (units)
        expect(result.values['waterproofKg'], closeTo(6.16, 0.1));
      });

      test('cement waterproof - 3.0 kg/sqm per layer', () {
        final inputs = {
          'length': 2.0,
          'width': 2.0,
          'wallHeight': 0.2,
          'waterproofType': 2.0, // cement
          'layers': 2.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Waterproof = 6.16 * 3.0 * 2 = 36.96 kg
        expect(result.values['waterproofKg'], closeTo(36.96, 0.1));
      });

      test('cement uses more material than liquid', () {
        final liquid = calculator({
          'length': 2.5,
          'width': 1.8,
          'waterproofType': 0.0,
        }, emptyPriceList);

        final cement = calculator({
          'length': 2.5,
          'width': 1.8,
          'waterproofType': 2.0,
        }, emptyPriceList);

        expect(
          cement.values['waterproofKg'],
          greaterThan(liquid.values['waterproofKg']!),
        );
      });
    });

    group('Layer calculations', () {
      test('more layers = more waterproof material', () {
        final oneLayers = calculator({
          'length': 2.5,
          'width': 1.8,
          'layers': 1.0,
        }, emptyPriceList);

        final threeLayers = calculator({
          'length': 2.5,
          'width': 1.8,
          'layers': 3.0,
        }, emptyPriceList);

        expect(
          threeLayers.values['waterproofKg'],
          greaterThan(oneLayers.values['waterproofKg']!),
        );
        // 3 layers should be 3x the 1 layer amount
        expect(
          threeLayers.values['waterproofKg'],
          closeTo(oneLayers.values['waterproofKg']! * 3, 0.01),
        );
      });

      test('default is 2 layers', () {
        final inputs = {
          'length': 2.5,
          'width': 1.8,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['layers'], equals(2.0));
      });
    });

    group('Primer calculations', () {
      test('primer with 0.2 l/sqm consumption', () {
        final inputs = {
          'length': 2.0,
          'width': 2.0,
          'wallHeight': 0.2,
          'needPrimer': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Total area = 6.16 sqm
        // Primer = 6.16 * 0.2 = 1.232 liters
        expect(result.values['primerLiters'], closeTo(1.232, 0.01));
      });

      test('no primer when disabled', () {
        final inputs = {
          'length': 2.5,
          'width': 1.8,
          'needPrimer': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['primerLiters'], equals(0.0));
      });

      test('primer enabled by default', () {
        final inputs = {
          'length': 2.5,
          'width': 1.8,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['needPrimer'], equals(1.0));
        expect(result.values['primerLiters'], greaterThan(0));
      });
    });

    group('Tape calculations', () {
      test('tape with 30% extra for corners and joints', () {
        final inputs = {
          'length': 2.0,
          'width': 2.0,
          'needTape': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Perimeter = 8 m
        // Tape = 8 * 1.3 = 10.4 m
        expect(result.values['tapeMeters'], closeTo(10.4, 0.1));
      });

      test('no tape when disabled', () {
        final inputs = {
          'length': 2.5,
          'width': 1.8,
          'needTape': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['tapeMeters'], equals(0.0));
      });

      test('tape enabled by default', () {
        final inputs = {
          'length': 2.5,
          'width': 1.8,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['needTape'], equals(1.0));
        expect(result.values['tapeMeters'], greaterThan(0));
      });
    });

    group('Wall height calculations', () {
      test('higher walls = more total area', () {
        final low = calculator({
          'length': 2.5,
          'width': 1.8,
          'wallHeight': 0.1,
        }, emptyPriceList);

        final high = calculator({
          'length': 2.5,
          'width': 1.8,
          'wallHeight': 0.5,
        }, emptyPriceList);

        expect(
          high.values['wallArea'],
          greaterThan(low.values['wallArea']!),
        );
        expect(
          high.values['totalArea'],
          greaterThan(low.values['totalArea']!),
        );
      });

      test('default wall height is 0.2m', () {
        final inputs = {
          'length': 2.5,
          'width': 1.8,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['wallHeight'], equals(0.2));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{};

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['length'], equals(2.5));
        expect(result.values['width'], equals(1.8));
        expect(result.values['wallHeight'], equals(0.2));
        expect(result.values['waterproofType'], equals(0.0)); // liquid
        expect(result.values['layers'], equals(2.0));
        expect(result.values['needPrimer'], equals(1.0)); // yes
        expect(result.values['needTape'], equals(1.0)); // yes
      });
    });

    group('Area waste factor', () {
      test('applies 10% waste to total area', () {
        final inputs = {
          'length': 2.0,
          'width': 2.0,
          'wallHeight': 0.1, // minimum wall height
        };

        final result = calculator(inputs, emptyPriceList);

        // Floor = 4 sqm, Wall = 8 * 0.1 = 0.8 sqm
        // Total = (4 + 0.8) * 1.1 = 5.28 sqm
        expect(result.values['totalArea'], closeTo(5.28, 0.01));
      });
    });

    group('Edge cases', () {
      test('clamps dimensions to valid range', () {
        final inputs = {
          'length': 20.0, // Invalid, should clamp to 10
          'width': 20.0, // Invalid, should clamp to 10
          'wallHeight': 1.0, // Invalid, should clamp to 0.5
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['length'], equals(10.0));
        expect(result.values['width'], equals(10.0));
        expect(result.values['wallHeight'], equals(0.5));
      });

      test('handles minimum dimensions', () {
        final inputs = {
          'length': 1.0,
          'width': 1.0,
          'wallHeight': 0.1,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['length'], equals(1.0));
        expect(result.values['width'], equals(1.0));
        expect(result.values['floorArea'], greaterThan(0));
      });

      test('handles maximum dimensions', () {
        final inputs = {
          'length': 10.0,
          'width': 10.0,
          'wallHeight': 0.5,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorArea'], equals(100.0));
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
          'length': -2.0,
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

      test('throws exception for negative width', () {
        final inputs = {
          'width': -1.5,
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
          'length': 2.5,
          'width': 1.8,
          'needPrimer': 1.0,
          'needTape': 1.0,
        };
        final priceList = [
          const PriceItem(sku: 'waterproof', name: 'Гидроизоляция', price: 500.0, unit: 'кг', imageUrl: ''),
          const PriceItem(sku: 'primer', name: 'Грунтовка', price: 200.0, unit: 'л', imageUrl: ''),
          const PriceItem(sku: 'waterproof_tape', name: 'Лента', price: 50.0, unit: 'м.п.', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'length': 2.5,
          'width': 1.8,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });

      test('price includes only enabled options', () {
        final priceList = [
          const PriceItem(sku: 'waterproof', name: 'Гидроизоляция', price: 500.0, unit: 'кг', imageUrl: ''),
          const PriceItem(sku: 'primer', name: 'Грунтовка', price: 200.0, unit: 'л', imageUrl: ''),
          const PriceItem(sku: 'waterproof_tape', name: 'Лента', price: 50.0, unit: 'м.п.', imageUrl: ''),
        ];

        final withAll = calculator({
          'length': 2.5,
          'width': 1.8,
          'needPrimer': 1.0,
          'needTape': 1.0,
        }, priceList);

        final withoutPrimer = calculator({
          'length': 2.5,
          'width': 1.8,
          'needPrimer': 0.0,
          'needTape': 1.0,
        }, priceList);

        expect(
          withAll.totalPrice,
          greaterThan(withoutPrimer.totalPrice!),
        );
      });
    });

    group('Full scenario tests', () {
      test('small bathroom with liquid waterproof', () {
        final inputs = {
          'length': 2.0,
          'width': 1.5,
          'wallHeight': 0.2,
          'waterproofType': 0.0, // liquid
          'layers': 2.0,
          'needPrimer': 1.0,
          'needTape': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorArea'], equals(3.0));
        expect(result.values['waterproofKg'], greaterThan(0));
        expect(result.values['primerLiters'], greaterThan(0));
        expect(result.values['tapeMeters'], greaterThan(0));
      });

      test('large bathroom with cement waterproof', () {
        final inputs = {
          'length': 5.0,
          'width': 4.0,
          'wallHeight': 0.3,
          'waterproofType': 2.0, // cement
          'layers': 3.0,
          'needPrimer': 1.0,
          'needTape': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['floorArea'], equals(20.0));
        expect(result.values['waterproofType'], equals(2.0));
        expect(result.values['layers'], equals(3.0));
        expect(result.values['waterproofKg'], greaterThan(100)); // cement uses a lot
      });

      test('roll waterproof without extras', () {
        final inputs = {
          'length': 3.0,
          'width': 2.5,
          'wallHeight': 0.15,
          'waterproofType': 1.0, // roll
          'layers': 1.0,
          'needPrimer': 0.0,
          'needTape': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['waterproofType'], equals(1.0));
        expect(result.values['primerLiters'], equals(0.0));
        expect(result.values['tapeMeters'], equals(0.0));
      });
    });
  });
}
