import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculate_self_leveling_floor.dart';

void main() {
  group('CalculateSelfLevelingFloor', () {
    final calculator = CalculateSelfLevelingFloor();
    final emptyPriceList = <PriceItem>[];

    test('calculates mix needed correctly for default leveling mixture', () {
      final result = calculator({
        'inputMode': 1.0,
        'area': 20.0,
        'thickness': 5.0,
      }, emptyPriceList);

      expect(result.values['mixNeededKg'], closeTo(168.0, 0.01));
      expect(result.values['area'], closeTo(20.0, 0.01));
      expect(result.values['thickness'], equals(5.0));
      expect(result.values['bagsNeeded'], equals(7.0));
    });

    test('maps legacy consumption into canonical override', () {
      final result = calculator({
        'inputMode': 1.0,
        'area': 20.0,
        'thickness': 10.0,
        'consumption': 1.7,
      }, emptyPriceList);

      expect(result.values['mixNeededKg'], closeTo(357.0, 0.01));
      expect(result.values['bagsNeeded'], equals(15.0));
    });

    test('calculates primer and tape correctly', () {
      final result = calculator({
        'inputMode': 0.0,
        'length': 5.0,
        'width': 4.0,
        'thickness': 10.0,
        'bagWeight': 25.0,
      }, emptyPriceList);

      expect(result.values['primerNeededLiters'], equals(3.0));
      expect(result.values['damperTapeLengthMeters'], equals(18.0));
      expect(result.values['bagsNeeded'], equals(14.0));
    });

    test('calculates tool counts from domain inputs', () {
      final result = calculator({
        'inputMode': 1.0,
        'area': 120.0,
        'thickness': 10.0,
        'spikeRollerArea': 50.0,
        'spikeShoesCount': 2.0,
      }, emptyPriceList);

      expect(result.values['spikeRollers'], equals(3.0));
      expect(result.values['spikeShoesCount'], equals(2.0));
    });

    test('uses default thickness when missing', () {
      final result = calculator({
        'inputMode': 1.0,
        'area': 20.0,
      }, emptyPriceList);

      expect(result.values['thickness'], equals(10.0));
      expect(result.values['mixNeededKg'], closeTo(336.0, 0.01));
    });

    test('supports finish and fast mixtures', () {
      final finish = calculator({
        'inputMode': 1.0,
        'area': 20.0,
        'thickness': 10.0,
        'mixtureType': 1.0,
      }, emptyPriceList);
      final fast = calculator({
        'inputMode': 1.0,
        'area': 20.0,
        'thickness': 10.0,
        'mixtureType': 2.0,
      }, emptyPriceList);

      expect(finish.values['mixNeededKg'], closeTo(294.0, 0.01));
      expect(fast.values['mixNeededKg'], closeTo(378.0, 0.01));
    });

    test('throws exception for zero area', () {
      expect(
        () => calculator({'inputMode': 1.0, 'area': 0.0}, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    group('validation messages', () {
      test('thickness range uses shared helper', () {
        final calculator = CalculateSelfLevelingFloor();

        final error = calculator.validateInputs({
          'inputMode': 1.0,
          'area': 12.0,
          'thickness': 101.0,
        });

        expect(error, equals('Поле "толщина" должно быть от 3 до 100 мм'));
      });
    });
  });
}
