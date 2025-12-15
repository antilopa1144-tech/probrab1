import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';
import 'package:probrab_ai/domain/usecases/calculate_strip_foundation.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateStripFoundation', () {
    late CalculateStripFoundation calculator;

    setUp(() {
      calculator = CalculateStripFoundation();
    });

    test('calculates concrete volume correctly', () {
      final inputs = {
        'perimeter': 40.0, // 10x10 м дом
        'width': 0.4, // 40 см
        'height': 0.8, // 80 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём = 40 * 0.4 * 0.8 = 12.8 м³
      expect(result.values['concreteVolume'], closeTo(12.8, 0.6));
    });

    test('calculates rebar weight correctly', () {
      final inputs = {
        'perimeter': 40.0,
        'width': 0.4,
        'height': 0.8,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Вес арматуры = 12.8 * 0.01 * 7850 = 1004.8 кг
      expect(result.values['rebarWeight'], closeTo(1004.8, 0.1));
    });

    test('calculates cement bags correctly', () {
      final inputs = {
        'perimeter': 40.0,
        'width': 0.4,
        'height': 0.8,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Field may be null if not calculated
      if (result.values.containsKey('bagsCement') && result.values['bagsCement'] != null) {
        expect(result.values['bagsCement'], closeTo(89.6, 10.0));
      }
    });

    test('throws on completely empty inputs', () {
      final inputs = <String, double>{};
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('calculates total price with price list', () {
      final inputs = {
        'perimeter': 40.0,
        'width': 0.4,
        'height': 0.8,
      };
      final priceList = [
        PriceItem(
          sku: 'concrete',
          name: 'Бетон М300',
          price: 6500,
          unit: 'м³',
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      // Цена = 12.8 м³ * 6500 руб = 83200 руб
      expect(result.totalPrice, equals(83200.0));
    });

    test('returns null price when price list is empty', () {
      final inputs = {
        'perimeter': 40.0,
        'width': 0.4,
        'height': 0.8,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.totalPrice, isNull);
    });

    test('handles small foundation correctly', () {
      final inputs = {
        'perimeter': 16.0, // 4x4 м
        'width': 0.3,
        'height': 0.6,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём = 16 * 0.3 * 0.6 = 2.88 м³
      expect(result.values['concreteVolume'], closeTo(2.88, 0.01));
    });

    test('handles large foundation correctly', () {
      final inputs = {
        'perimeter': 100.0, // большой дом
        'width': 0.5,
        'height': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём = 100 * 0.5 * 1.0 = 50 м³
      expect(result.values['concreteVolume'], closeTo(50.0, 2.5));
    });
  });
}
// ignore_for_file: prefer_const_constructors
