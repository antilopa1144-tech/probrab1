import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_dsp.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateDsp', () {
    late CalculateDsp calculator;

    setUp(() {
      calculator = CalculateDsp();
    });

    test('calculates floor screed (M300 mix) correctly', () {
      final inputs = {
        'inputMode': 0.0, // by dimensions
        'length': 5.0,
        'width': 4.0,
        'height': 2.5,
        'applicationType': 0.0, // floor
        'mixType': 0.0, // M300
        'thickness': 40.0, // mm
        'bagWeight': 40.0, // kg
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Area = 5 * 4 = 20 m²
      expect(result.values['area'], equals(20.0));

      // Total weight = 20 * 40 * 2.0 = 1600 kg
      expect(result.values['totalWeightKg'], equals(1600.0));

      // Bags = ceil(1600 / 40) = 40 bags
      expect(result.values['bagsNeeded'], equals(40.0));

      // Mesh with 10% overlap = 20 * 1.1 = 22 m²
      expect(result.values['meshArea'], equals(22.0));

      // Perimeter = (5 + 4) * 2 = 18 m
      expect(result.values['tapeMeters'], equals(18.0));

      // Beacons = ceil(20 / 2) = 10
      expect(result.values['beaconsNeeded'], equals(10.0));
    });

    test('calculates wall plaster (M150 mix) correctly', () {
      final inputs = {
        'inputMode': 0.0, // by dimensions
        'length': 5.0,
        'width': 4.0,
        'height': 2.5,
        'applicationType': 1.0, // walls
        'mixType': 1.0, // M150
        'thickness': 20.0, // mm
        'bagWeight': 25.0, // kg
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Wall area = (5 + 4) * 2 * 2.5 = 45 m²
      expect(result.values['area'], equals(45.0));

      // Total weight = 45 * 20 * 1.8 = 1620 kg
      expect(result.values['totalWeightKg'], equals(1620.0));

      // Bags = ceil(1620 / 25) = 65 bags
      expect(result.values['bagsNeeded'], equals(65.0));

      // No mesh for walls
      expect(result.values['meshArea'], equals(0.0));

      // No damper tape for walls
      expect(result.values['tapeMeters'], equals(0.0));

      // No beacons for walls
      expect(result.values['beaconsNeeded'], equals(0.0));

      // Primer for walls: 45 * 0.2 = 9 liters, ceil(9/10) = 1 canister
      expect(result.values['primerCanisters'], equals(1.0));
      expect(result.values['primerLiters'], equals(9.0));
    });

    test('subtracts openings for wall application', () {
      final inputs = {
        'inputMode': 1.0, // by area
        'area': 50.0,
        'perimeter': 20.0,
        'applicationType': 1.0, // walls
        'mixType': 1.0, // M150
        'thickness': 15.0,
        'bagWeight': 40.0,
        'windowsArea': 6.0,
        'doorsArea': 4.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Useful area = 50 - 6 - 4 = 40 m²
      expect(result.values['area'], equals(40.0));
    });

    test('sets thickness warning for thin floor screed', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 20.0,
        'perimeter': 18.0,
        'applicationType': 0.0, // floor
        'mixType': 0.0,
        'thickness': 25.0, // less than 30mm
        'bagWeight': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['thicknessWarning'], equals(1.0));
    });

    test('does not set warning for adequate thickness', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 20.0,
        'perimeter': 18.0,
        'applicationType': 0.0, // floor
        'mixType': 0.0,
        'thickness': 50.0, // adequate thickness
        'bagWeight': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['thicknessWarning'], equals(0.0));
    });

    test('handles different bag weights correctly', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 20.0,
        'perimeter': 18.0,
        'applicationType': 0.0,
        'mixType': 0.0,
        'thickness': 40.0,
        'bagWeight': 50.0, // 50kg bags
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Total weight = 20 * 40 * 2.0 = 1600 kg
      // Bags = ceil(1600 / 50) = 32 bags
      expect(result.values['bagsNeeded'], equals(32.0));
    });

    test('throws exception for zero area', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 0.0,
        'perimeter': 10.0,
        'applicationType': 0.0,
        'mixType': 0.0,
        'thickness': 40.0,
        'bagWeight': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<Exception>()),
      );
    });

    test('validates thickness range', () {
      final inputs = {
        'inputMode': 1.0,
        'area': 20.0,
        'perimeter': 18.0,
        'applicationType': 0.0,
        'mixType': 0.0,
        'thickness': 250.0, // exceeds max
        'bagWeight': 40.0,
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
        'area': 20.0,
        'perimeter': 18.0,
        'applicationType': 0.0,
        'mixType': 0.0,
        'thickness': 40.0,
        'bagWeight': 40.0,
      };
      final priceList = [
        const PriceItem(
          sku: 'dsp_m300',
          name: 'Пескобетон М300',
          price: 200,
          unit: 'мешок',
          imageUrl: '',
        ),
        const PriceItem(
          sku: 'mesh_reinforcing',
          name: 'Сетка армирующая',
          price: 50,
          unit: 'м²',
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      expect(result.totalPrice, isNotNull);
      expect(result.totalPrice, greaterThan(0));
    });

    test('uses correct consumption for M300 vs M150', () {
      final inputsM300 = {
        'inputMode': 1.0,
        'area': 10.0,
        'perimeter': 12.0,
        'applicationType': 0.0,
        'mixType': 0.0, // M300
        'thickness': 40.0,
        'bagWeight': 40.0,
      };

      final inputsM150 = {
        'inputMode': 1.0,
        'area': 10.0,
        'perimeter': 12.0,
        'applicationType': 0.0,
        'mixType': 1.0, // M150
        'thickness': 40.0,
        'bagWeight': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final resultM300 = calculator(inputsM300, emptyPriceList);
      final resultM150 = calculator(inputsM150, emptyPriceList);

      // M300 uses 2.0 kg/m²/mm, M150 uses 1.8 kg/m²/mm
      expect(resultM300.values['totalWeightKg'], equals(800.0)); // 10 * 40 * 2.0
      expect(resultM150.values['totalWeightKg'], equals(720.0)); // 10 * 40 * 1.8
    });
  });
}
