import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculate_linoleum_v2.dart';

void main() {
  group('CalculateLinoleumV2', () {
    late CalculateLinoleumV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateLinoleumV2();
      emptyPriceList = <PriceItem>[];
    });

    test('uses canonical strip planning for area input', () {
      final result = calculator({
        'area': 20.0,
        'rollWidth': 3.0,
        'needTape': 1.0,
        'needPlinth': 1.0,
      }, emptyPriceList);

      expect(result.values['area'], equals(20.0));
      expect(result.values['roomWidth']!, closeTo(4.47, 0.02));
      expect(result.values['roomLength']!, closeTo(4.47, 0.02));
      expect(result.values['linearMeters']!, closeTo(9.2, 0.01));
      expect(result.values['areaWithWaste']!, closeTo(27.6, 0.01));
      expect(result.values['rollsNeeded']!, closeTo(0.368, 0.01));
      expect(result.values['tapeLength']!, closeTo(22.36, 0.05));
      expect(result.values['plinthPieces'], equals(8.0));
    });

    test('larger roll width reduces purchase length', () {
      final narrowResult = calculator({
        'area': 50.0,
        'rollWidth': 2.0,
        'needTape': 0.0,
        'needPlinth': 0.0,
      }, emptyPriceList);
      final wideResult = calculator({
        'area': 50.0,
        'rollWidth': 5.0,
        'needTape': 0.0,
        'needPlinth': 0.0,
      }, emptyPriceList);

      expect(
        wideResult.values['linearMeters']!,
        lessThan(narrowResult.values['linearMeters']!),
      );
      expect(
        wideResult.values['rollsNeeded']!,
        lessThan(narrowResult.values['rollsNeeded']!),
      );
    });

    test('room dimensions take priority over area', () {
      final result = calculator({
        'area': 30.0,
        'roomWidth': 4.0,
        'roomLength': 5.0,
        'rollWidth': 3.0,
        'needTape': 0.0,
        'needPlinth': 0.0,
      }, emptyPriceList);

      expect(result.values['area'], equals(20.0));
      expect(result.values['roomWidth'], equals(4.0));
      expect(result.values['roomLength'], equals(5.0));
      expect(result.values['linearMeters']!, closeTo(10.2, 0.01));
      expect(result.values['areaWithWaste']!, closeTo(30.6, 0.01));
    });

    test('calculates tape and plinth from room dimensions', () {
      final result = calculator({
        'roomWidth': 4.0,
        'roomLength': 5.0,
        'rollWidth': 3.0,
        'needTape': 1.0,
        'needPlinth': 1.0,
      }, emptyPriceList);

      expect(result.values['tapeLength']!, closeTo(23.0, 0.01));
      expect(result.values['plinthLength']!, closeTo(17.1, 0.01));
      expect(result.values['plinthPieces'], equals(8.0));
    });

    test('supports pattern repeat as canonical input', () {
      final plain = calculator({
        'roomWidth': 4.0,
        'roomLength': 5.0,
        'rollWidth': 2.0,
        'needTape': 0.0,
        'needPlinth': 0.0,
      }, emptyPriceList);
      final patterned = calculator({
        'roomWidth': 4.0,
        'roomLength': 5.0,
        'rollWidth': 2.0,
        'hasPattern': 1.0,
        'patternRepeatCm': 30.0,
        'needTape': 0.0,
        'needPlinth': 0.0,
      }, emptyPriceList);

      expect(
        patterned.values['linearMeters']!,
        greaterThan(plain.values['linearMeters']!),
      );
      expect(patterned.values['patternRepeatCm'], equals(30.0));
    });

    test('returns zero accessories when disabled', () {
      final result = calculator({
        'area': 20.0,
        'rollWidth': 3.0,
        'needTape': 0.0,
        'needPlinth': 0.0,
      }, emptyPriceList);

      expect(result.values['tapeLength'], equals(0.0));
      expect(result.values['plinthLength'], equals(0.0));
      expect(result.values['plinthPieces'], equals(0.0));
      expect(result.values['needTape'], equals(0.0));
      expect(result.values['needPlinth'], equals(0.0));
    });

    test('uses canonical defaults when values are omitted', () {
      final result = calculator({'area': 20.0}, emptyPriceList);

      expect(result.values['rollWidth'], equals(3.0));
      expect(result.values['needTape'], equals(1.0));
      expect(result.values['needPlinth'], equals(1.0));
    });

    test('clamps roll width to valid range', () {
      final result = calculator({
        'area': 20.0,
        'rollWidth': 10.0,
      }, emptyPriceList);

      expect(result.values['rollWidth'], equals(5.0));
    });

    test('throws exception for invalid geometry', () {
      expect(
        () => calculator({'area': 0.0}, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
      expect(
        () => calculator({'area': -5.0}, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('calculates total price when prices are available', () {
      final result = calculator(
        {
          'roomWidth': 4.0,
          'roomLength': 5.0,
          'rollWidth': 3.0,
          'needTape': 1.0,
          'needPlinth': 1.0,
        },
        [
          const PriceItem(
            sku: 'linoleum',
            name: 'Линолеум',
            price: 350.0,
            unit: 'м²',
            imageUrl: '',
          ),
          const PriceItem(
            sku: 'tape',
            name: 'Скотч',
            price: 50.0,
            unit: 'м',
            imageUrl: '',
          ),
          const PriceItem(
            sku: 'plinth',
            name: 'Плинтус',
            price: 150.0,
            unit: 'шт',
            imageUrl: '',
          ),
        ],
      );

      expect(result.totalPrice, isNotNull);
      expect(result.totalPrice!, greaterThan(0));
    });

    test('returns null price when prices are missing', () {
      final result = calculator({'area': 20.0}, emptyPriceList);
      expect(result.totalPrice, isNull);
    });

    group('validation messages', () {
      test('area or room dimensions requirement uses shared helper', () {
        final calculator = CalculateLinoleumV2();

        final error = calculator.validateInputs({
          'area': 0.0,
          'roomWidth': 0.0,
          'roomLength': 0.0,
        });

        expect(
          error,
          equals('Необходимо указать площадь или размеры помещения'),
        );
      });
    });
  });
}
