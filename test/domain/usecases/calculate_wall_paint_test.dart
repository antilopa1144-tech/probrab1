import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_wall_paint.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateWallPaint', () {
    late CalculateWallPaint calculator;

    setUp(() {
      calculator = CalculateWallPaint();
    });

    test('calculates paint needed correctly with 8% reserve', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 40.0, // 40 м?
        'perimeter': 20.0,
        'layers': 2.0,
        'consumption': 0.15, // л/м?
        'reserve': 8.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // После roundBulk ожидаем 15 л
      expect(result.values['paintNeededLiters'], closeTo(15.0, 0.8));
    });

    test('calculates primer needed correctly', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 40.0,
        'perimeter': 20.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['primerNeededLiters'], equals(5.5));
    });

    test('subtracts windows and doors area', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 50.0,
        'perimeter': 28.0,
        'layers': 2.0,
        'windowsArea': 6.0,
        'doorsArea': 4.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['usefulArea'], closeTo(40.0, 2.0));
    });

    test('handles single layer correctly', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 40.0,
        'perimeter': 20.0,
        'layers': 1.0,
        'consumption': 0.15,
        'reserve': 8.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['paintNeededLiters'], equals(8.0));
    });

    test('handles three layers correctly', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 40.0,
        'perimeter': 20.0,
        'layers': 3.0,
        'consumption': 0.15,
        'reserve': 8.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['paintNeededLiters'], closeTo(21.0, 1.1));
    });

    test('uses default values when not provided', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 40.0,
        'perimeter': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['layers'], equals(2.0));
      expect(result.values['paintNeededLiters'], closeTo(12.0, 0.6));
    });

    test('does not allow negative useful area', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 20.0,
        'perimeter': 18.0,
        'windowsArea': 15.0,
        'doorsArea': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['usefulArea'], equals(0.0));
    });

    test('throws exception for zero area', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 0.0,
        'perimeter': 10.0,
        'layers': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<Exception>()),
      );
    });

    test('calculates total price with price list', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 40.0,
        'perimeter': 20.0,
        'layers': 2.0,
      };
      final priceList = [
        const PriceItem(
          sku: 'paint',
          name: 'Краска',
          price: 500,
          unit: 'л',
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      expect(result.totalPrice, isNotNull);
      expect(result.totalPrice, greaterThan(0));
    });

    test('handles high consumption rate', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 40.0,
        'perimeter': 20.0,
        'layers': 2.0,
        'consumption': 0.25,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['paintNeededLiters'], closeTo(24.0, 1.2));
    });
  });
}

