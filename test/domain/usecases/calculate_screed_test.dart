import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_screed.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateScreed', () {
    late CalculateScreed calculator;

    setUp(() {
      calculator = CalculateScreed();
    });

    test('calculates volume correctly', () {
      final inputs = {
        'area': 20.0, // 20 м²
        'thickness': 50.0, // 50 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём = 20 * 0.05 = 1.0 м³
      expect(result.values['volume'], equals(1.0));
    });

    test('calculates cement bags for M400 correctly', () {
      final inputs = {
        'area': 20.0,
        'thickness': 50.0,
        'cementGrade': 400.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём = 1.0 м³
      // Плотность раствора = 2000 кг/м³
      // Общий вес = 2000 кг
      // Цемент М400: 33% = 660 кг
      // Мешки = ceil(660 / 50) ≈ 14 мешков
      expect(result.values['cementBags'], closeTo(14.0, 1.0));
    });

    test('calculates cement bags for M500 correctly', () {
      final inputs = {
        'area': 20.0,
        'thickness': 50.0,
        'cementGrade': 500.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Цемент М500: 25% ≈ 500 кг
      // Мешки = ceil(500 / 50) ≈ 10 мешков
      expect(result.values['cementBags'], closeTo(10.0, 1.0));
    });

    test('calculates sand volume correctly', () {
      final inputs = {
        'area': 20.0,
        'thickness': 50.0,
        'cementGrade': 400.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Песок: 67% = 1340 кг
      // Объём песка = 1340 / 1600 ≈ 0.84 м³
      expect(result.values['sandVolume'], closeTo(0.84, 0.1));
    });

    test('handles different thickness values', () {
      final inputs30mm = {
        'area': 20.0,
        'thickness': 30.0,
      };
      final inputs100mm = {
        'area': 20.0,
        'thickness': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result30 = calculator(inputs30mm, emptyPriceList);
      final result100 = calculator(inputs100mm, emptyPriceList);

      // 30 мм: объём = 0.6 м³
      expect(result30.values['volume'], equals(0.6));

      // 100 мм: объём = 2.0 м³
      expect(result100.values['volume'], equals(2.0));
    });

    test('throws exception for zero area', () {
      final inputs = {
        'area': 0.0,
        'thickness': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('uses default thickness when not provided', () {
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию thickness = 50 мм
      expect(result.values['thickness'], equals(50.0));
    });

    test('preserves area in results', () {
      final inputs = {
        'area': 25.5,
        'thickness': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['area'], equals(25.5));
    });

    test('calculates total price with price list', () {
      final inputs = {
        'area': 20.0,
        'thickness': 50.0,
      };
      final priceList = [
        const PriceItem(
          sku: 'cement',
          name: 'Цемент М400',
          price: 350,
          unit: 'мешок',
          imageUrl: '',
        ),
        const PriceItem(
          sku: 'sand',
          name: 'Песок',
          price: 500,
          unit: 'м³',
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      expect(result.totalPrice, isNotNull);
      expect(result.totalPrice, greaterThan(0));
    });

    test('handles large area correctly', () {
      final inputs = {
        'area': 200.0, // большой цех
        'thickness': 80.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём = 200 * 0.08 = 16 м³
      expect(result.values['volume'], equals(16.0));
      expect(result.values['cementBags'], greaterThan(100));
    });
  });
}
