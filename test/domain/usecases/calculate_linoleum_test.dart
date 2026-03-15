import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_linoleum.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateLinoleum', () {
    test('calculates linoleum area and cuts correctly', () {
      final calculator = CalculateLinoleum();
      final inputs = {
        'inputMode': 1.0,
        'area': 30.0,
        'roomWidth': 3.0,
        'rollWidth': 3.0,
        'withGlue': 1.0,
        'withPlinth': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['linoleumAreaNeeded'], closeTo(31.0, 1.6));
      expect(result.values['cutsNeeded'], equals(1.0));
      expect(result.values['area'], closeTo(30.0, 1.5));
    });

    test('calculates glue needed', () {
      final calculator = CalculateLinoleum();
      final inputs = {
        'inputMode': 1.0,
        'area': 30.0,
        'roomWidth': 3.0,
        'withGlue': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['glueNeededKg'], closeTo(12.0, 0.6));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateLinoleum();
      final inputs = {
        'inputMode': 1.0,
        'area': 30.0,
        'roomWidth': 3.0,
        'withPlinth': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['plinthLengthMeters'], greaterThan(0));
    });

    test('uses provided perimeter', () {
      final calculator = CalculateLinoleum();
      final inputs = {
        'inputMode': 1.0,
        'area': 30.0,
        'roomWidth': 3.0,
        'perimeter': 22.0,
        'withPlinth': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['plinthLengthMeters'], closeTo(22.16, 0.2));
    });

    test('uses default roll width when missing', () {
      final calculator = CalculateLinoleum();
      final inputs = {'inputMode': 1.0, 'area': 30.0, 'roomWidth': 3.0};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['linoleumAreaNeeded'], greaterThan(0));
    });

    test('handles overlap parameter gracefully', () {
      final calculator = CalculateLinoleum();
      final inputs = {
        'inputMode': 1.0,
        'area': 30.0,
        'roomWidth': 3.0,
        'overlap': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['linoleumAreaNeeded'], greaterThanOrEqualTo(30.0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateLinoleum();
      final inputs = {'inputMode': 1.0, 'area': 0.0, 'roomWidth': 3.0};
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    group('validation messages', () {
      test('area mode requires room width through shared field message', () {
        final calculator = CalculateLinoleum();

        final error = calculator.validateInputs({
          'inputMode': 1.0,
          'area': 20.0,
          'roomWidth': 0.0,
          'patternRepeatCm': 30.0,
        });

        expect(error, equals('Поле "ширина комнаты" должно быть больше нуля'));
      });
    });
  });
}
