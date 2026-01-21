import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_underfloor_heating.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateUnderfloorHeating', () {
    test('calculates electric mat correctly', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 15.0,
        'systemType': 1.0, // electric mat
        'roomType': 2.0, // living room
        'usefulAreaPercent': 72.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Heating area: 15 * 0.72 = 10.8 м²
      expect(result.values['heatingArea'], closeTo(10.8, 0.1));
      expect(result.values['matArea'], closeTo(10.8, 0.1));
      // Power: 10.8 * 120 = 1296 Вт
      expect(result.values['totalPower'], closeTo(1296, 10));
    });

    test('calculates electric cable correctly', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 20.0,
        'systemType': 2.0, // electric cable
        'roomType': 2.0, // living room
        'usefulAreaPercent': 70.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Heating area: 20 * 0.70 = 14 м²
      expect(result.values['heatingArea'], closeTo(14.0, 0.1));
      // Power: 14 * 120 = 1680 Вт
      // Cable length: 1680 / 18 = 93.3 м
      expect(result.values['cableLength'], closeTo(93.3, 1.0));
      // Montage tape: 14 * 2 = 28 м
      expect(result.values['montageTapeLength'], closeTo(28.0, 0.5));
    });

    test('calculates infrared film correctly', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 12.0,
        'systemType': 3.0, // IR film
        'roomType': 2.0, // living room
        'usefulAreaPercent': 75.0,
        'filmWidth': 1.0, // 80 cm (default)
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Heating area: 12 * 0.75 = 9 м²
      expect(result.values['heatingArea'], closeTo(9.0, 0.1));
      expect(result.values['filmArea'], closeTo(9.0, 0.1));
      // Film width: 80 cm
      expect(result.values['filmWidthCm'], equals(80.0));
      // Linear meters: 9 / 0.8 = 11.25 м.п.
      expect(result.values['filmLinearMeters'], closeTo(11.25, 0.1));
      // Film strips: 11.25 / 5 = 3 (ceil)
      expect(result.values['filmStrips'], equals(3.0));
      // Contact clips: 3 * 2 = 6
      expect(result.values['contactClips'], equals(6.0));
      // Reflective substrate = full area
      expect(result.values['reflectiveSubstrate'], equals(12.0));
    });

    test('calculates infrared film with 50cm width', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 10.0,
        'systemType': 3.0, // IR film
        'roomType': 2.0, // living room
        'usefulAreaPercent': 80.0,
        'filmWidth': 0.0, // 50 cm
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Heating area: 10 * 0.80 = 8 м²
      expect(result.values['heatingArea'], closeTo(8.0, 0.1));
      // Film width: 50 cm
      expect(result.values['filmWidthCm'], equals(50.0));
      // Linear meters: 8 / 0.5 = 16 м.п.
      expect(result.values['filmLinearMeters'], closeTo(16.0, 0.1));
      // Film strips: 16 / 5 = 4 (ceil)
      expect(result.values['filmStrips'], equals(4.0));
      // Contact clips: 4 * 2 = 8
      expect(result.values['contactClips'], equals(8.0));
    });

    test('calculates infrared film with 100cm width', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 15.0,
        'systemType': 3.0, // IR film
        'roomType': 2.0, // living room
        'usefulAreaPercent': 72.0,
        'filmWidth': 2.0, // 100 cm
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Heating area: 15 * 0.72 = 10.8 м²
      expect(result.values['heatingArea'], closeTo(10.8, 0.1));
      // Film width: 100 cm
      expect(result.values['filmWidthCm'], equals(100.0));
      // Linear meters: 10.8 / 1.0 = 10.8 м.п.
      expect(result.values['filmLinearMeters'], closeTo(10.8, 0.1));
      // Film strips: 10.8 / 5 = 3 (ceil)
      expect(result.values['filmStrips'], equals(3.0));
      // Contact clips: 3 * 2 = 6
      expect(result.values['contactClips'], equals(6.0));
    });

    test('calculates water-based system correctly', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 25.0,
        'systemType': 4.0, // water-based
        'roomType': 2.0, // living room
        'usefulAreaPercent': 72.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Heating area: 25 * 0.72 = 18 м²
      expect(result.values['heatingArea'], closeTo(18.0, 0.1));
      // Pipe step for living room: 150mm = 0.15m
      // Pipe per m²: 1 / 0.15 = 6.67 м/м²
      // Pipe length: 18 * 6.67 * 1.15 ≈ 138 м
      expect(result.values['pipeLength'], closeTo(138.0, 5.0));
      // Loop count: 138 / 100 = 2 (ceil)
      expect(result.values['loopCount'], equals(2.0));
      expect(result.values['collectorOutputs'], equals(2.0));
      // Insulation area = full area
      expect(result.values['insulationArea'], equals(25.0));
      // Screed volume: 25 * 0.08 = 2 м³
      expect(result.values['screedVolume'], closeTo(2.0, 0.1));
    });

    test('calculates bathroom with higher power', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 6.0,
        'systemType': 1.0, // electric mat
        'roomType': 1.0, // bathroom - 180 Вт/м²
        'usefulAreaPercent': 72.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Heating area: 6 * 0.72 = 4.32 м²
      expect(result.values['heatingArea'], closeTo(4.32, 0.1));
      // Power: 4.32 * 180 = 778 Вт
      expect(result.values['totalPower'], closeTo(778, 10));
    });

    test('calculates balcony with highest power', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 4.0,
        'systemType': 1.0, // electric mat
        'roomType': 4.0, // balcony - 200 Вт/м²
        'usefulAreaPercent': 80.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Heating area: 4 * 0.80 = 3.2 м²
      expect(result.values['heatingArea'], closeTo(3.2, 0.1));
      // Power: 3.2 * 200 = 640 Вт
      expect(result.values['totalPower'], closeTo(640, 10));
    });

    test('uses default values when missing', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Default: electric mat (1), living room (2), 72% useful area
      expect(result.values['systemType'], equals(1.0));
      expect(result.values['roomType'], equals(2.0));
      expect(result.values['heatingArea'], closeTo(7.2, 0.1)); // 10 * 0.72
      expect(result.values['matArea'], closeTo(7.2, 0.1));
    });

    test('includes common materials for all systems', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 15.0,
        'systemType': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Common materials
      expect(result.values['thermostatCount'], equals(1.0));
      expect(result.values['sensorCount'], equals(1.0));
      expect(result.values['corrugatedTubeLength'], equals(2.5));
    });

    test('adds insulation when requested for electric systems', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 20.0,
        'systemType': 1.0, // electric mat
        'addInsulation': 1.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['insulationArea'], equals(20.0));
    });

    test('water-based always includes insulation', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 20.0,
        'systemType': 4.0, // water-based
        'addInsulation': 0.0, // not requested, but should be included
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['insulationArea'], equals(20.0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('water-based uses different pipe step for balcony', () {
      final calculator = CalculateUnderfloorHeating();
      final inputs = {
        'area': 4.0,
        'systemType': 4.0, // water-based
        'roomType': 4.0, // balcony - 100mm step
        'usefulAreaPercent': 80.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Pipe step for balcony: 100mm = 0.1m
      // Pipe per m²: 1 / 0.1 = 10 м/м²
      // Heating area: 4 * 0.8 = 3.2 м²
      // Pipe length: 3.2 * 10 * 1.15 = 36.8 м
      expect(result.values['pipeLength'], closeTo(36.8, 1.0));
      expect(result.values['pipeStep'], equals(100.0));
    });
  });
}
