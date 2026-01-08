import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_ventilation_v2.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateVentilationV2', () {
    late CalculateVentilationV2 calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateVentilationV2();
      emptyPriceList = <PriceItem>[];
    });

    group('Basic calculations', () {
      test('50 sqm, 2.7m ceiling, 4 rooms, supply ventilation', () {
        final inputs = {
          'roomArea': 50.0,
          'ceilingHeight': 2.7,
          'roomsCount': 4.0,
          'ventilationType': 1.0, // supply
          'needRecovery': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Volume = 50 * 2.7 = 135 m³
        expect(result.values['roomVolume'], closeTo(135.0, 0.1));
        // Airflow = 135 * 2.0 = 270 m³/h
        expect(result.values['airflowRequired'], closeTo(270.0, 0.1));
        // Grills = 4 * 2 = 8
        expect(result.values['grillsCount'], equals(8.0));
        // Fittings = 4 * 3 + 4 = 16
        expect(result.values['fittingsCount'], equals(16.0));
      });

      test('larger area needs more ducts', () {
        final smallInputs = {
          'roomArea': 30.0,
          'ceilingHeight': 2.7,
          'roomsCount': 3.0,
        };
        final largeInputs = {
          'roomArea': 100.0,
          'ceilingHeight': 2.7,
          'roomsCount': 6.0,
        };

        final smallResult = calculator(smallInputs, emptyPriceList);
        final largeResult = calculator(largeInputs, emptyPriceList);

        expect(
          largeResult.values['ductLength'],
          greaterThan(smallResult.values['ductLength']!),
        );
      });
    });

    group('Ventilation types', () {
      test('natural ventilation uses 1.0 exchange rate', () {
        final inputs = {
          'roomArea': 50.0,
          'ceilingHeight': 2.7,
          'roomsCount': 4.0,
          'ventilationType': 0.0, // natural
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['exchangeRate'], equals(1.0));
        // Airflow = 135 * 1.0 = 135 m³/h
        expect(result.values['airflowRequired'], closeTo(135.0, 0.1));
      });

      test('supply ventilation uses 2.0 exchange rate', () {
        final inputs = {
          'roomArea': 50.0,
          'ceilingHeight': 2.7,
          'roomsCount': 4.0,
          'ventilationType': 1.0, // supply
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['exchangeRate'], equals(2.0));
        // Airflow = 135 * 2.0 = 270 m³/h
        expect(result.values['airflowRequired'], closeTo(270.0, 0.1));
      });

      test('exhaust ventilation uses 1.5 exchange rate', () {
        final inputs = {
          'roomArea': 50.0,
          'ceilingHeight': 2.7,
          'roomsCount': 4.0,
          'ventilationType': 2.0, // exhaust
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['exchangeRate'], equals(1.5));
        // Airflow = 135 * 1.5 = 202.5 m³/h
        expect(result.values['airflowRequired'], closeTo(202.5, 0.1));
      });

      test('supply requires most airflow', () {
        final baseInputs = {
          'roomArea': 50.0,
          'ceilingHeight': 2.7,
          'roomsCount': 4.0,
        };

        final naturalResult = calculator({...baseInputs, 'ventilationType': 0.0}, emptyPriceList);
        final supplyResult = calculator({...baseInputs, 'ventilationType': 1.0}, emptyPriceList);
        final exhaustResult = calculator({...baseInputs, 'ventilationType': 2.0}, emptyPriceList);

        expect(supplyResult.values['airflowRequired'],
            greaterThan(exhaustResult.values['airflowRequired']!));
        expect(exhaustResult.values['airflowRequired'],
            greaterThan(naturalResult.values['airflowRequired']!));
      });
    });

    group('Duct calculations', () {
      test('duct length depends on rooms and area', () {
        final inputs = {
          'roomArea': 100.0,
          'ceilingHeight': 2.7,
          'roomsCount': 5.0,
          'ventilationType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Duct = 5 * 3 + (100 * 0.1) * 1.15 = 15 + 11.5 = 26.5 m
        expect(result.values['ductLength'], closeTo(26.5, 0.1));
      });

      test('duct length includes 15% waste on main duct', () {
        final inputs = {
          'roomArea': 100.0,
          'ceilingHeight': 2.7,
          'roomsCount': 1.0, // single room (minimum)
        };

        final result = calculator(inputs, emptyPriceList);

        // Duct = 1 * 3 + (100 * 0.1) * 1.15 = 3 + 11.5 = 14.5 m
        expect(result.values['ductLength'], closeTo(14.5, 0.1));
      });
    });

    group('Grills calculations', () {
      test('2 grills per room', () {
        final inputs = {
          'roomArea': 50.0,
          'ceilingHeight': 2.7,
          'roomsCount': 6.0,
          'ventilationType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Grills = 6 * 2 = 12
        expect(result.values['grillsCount'], equals(12.0));
      });

      test('single room has 2 grills', () {
        final inputs = {
          'roomArea': 20.0,
          'ceilingHeight': 2.7,
          'roomsCount': 1.0,
          'ventilationType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['grillsCount'], equals(2.0));
      });
    });

    group('Fittings calculations', () {
      test('3 fittings per room plus 4 base', () {
        final inputs = {
          'roomArea': 50.0,
          'ceilingHeight': 2.7,
          'roomsCount': 5.0,
          'ventilationType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Fittings = 5 * 3 + 4 = 19
        expect(result.values['fittingsCount'], equals(19.0));
      });

      test('single room has 7 fittings', () {
        final inputs = {
          'roomArea': 20.0,
          'ceilingHeight': 2.7,
          'roomsCount': 1.0,
          'ventilationType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Fittings = 1 * 3 + 4 = 7
        expect(result.values['fittingsCount'], equals(7.0));
      });
    });

    group('Recovery (recuperator)', () {
      test('no recuperator when disabled', () {
        final inputs = {
          'roomArea': 50.0,
          'ceilingHeight': 2.7,
          'roomsCount': 4.0,
          'ventilationType': 1.0,
          'needRecovery': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['recuperatorCount'], equals(0.0));
        expect(result.values['needRecovery'], equals(0.0));
      });

      test('1 recuperator when enabled', () {
        final inputs = {
          'roomArea': 50.0,
          'ceilingHeight': 2.7,
          'roomsCount': 4.0,
          'ventilationType': 1.0,
          'needRecovery': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['recuperatorCount'], equals(1.0));
        expect(result.values['needRecovery'], equals(1.0));
      });
    });

    group('Default values', () {
      test('uses default values when not specified', () {
        final inputs = <String, double>{
          'roomArea': 50.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['ceilingHeight'], equals(2.7));
        expect(result.values['roomsCount'], equals(4.0));
        expect(result.values['ventilationType'], equals(1.0)); // supply
        expect(result.values['needRecovery'], equals(0.0));
      });
    });

    group('Edge cases', () {
      test('clamps values to valid range', () {
        final inputs = {
          'roomArea': 1000.0, // Invalid, should clamp to 500
          'ceilingHeight': 10.0, // Invalid, should clamp to 5.0
          'roomsCount': 50.0, // Invalid, should clamp to 20
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['roomArea'], equals(500.0));
        expect(result.values['ceilingHeight'], equals(5.0));
        expect(result.values['roomsCount'], equals(20.0));
      });

      test('handles small area correctly', () {
        final inputs = {
          'roomArea': 15.0,
          'ceilingHeight': 2.5,
          'roomsCount': 1.0,
          'ventilationType': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.values['roomVolume'], greaterThan(0));
        expect(result.values['ductLength'], greaterThan(0));
      });

      test('handles large building correctly', () {
        final inputs = {
          'roomArea': 400.0,
          'ceilingHeight': 3.5,
          'roomsCount': 15.0,
          'ventilationType': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Volume = 400 * 3.5 = 1400 m³
        expect(result.values['roomVolume'], closeTo(1400.0, 0.1));
        // Airflow = 1400 * 2.0 = 2800 m³/h
        expect(result.values['airflowRequired'], closeTo(2800.0, 0.1));
      });
    });

    group('Validation errors', () {
      test('throws exception for zero area', () {
        final inputs = {
          'roomArea': 0.0,
          'ceilingHeight': 2.7,
        };

        expect(
          () => calculator(inputs, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });

      test('throws exception for negative area', () {
        final inputs = {
          'roomArea': -50.0,
          'ceilingHeight': 2.7,
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
          'roomArea': 50.0,
          'ceilingHeight': 2.7,
          'roomsCount': 4.0,
          'ventilationType': 1.0,
          'needRecovery': 0.0,
        };
        final priceList = [
          const PriceItem(sku: 'duct', name: 'Воздуховод', price: 150.0, unit: 'м', imageUrl: ''),
          const PriceItem(sku: 'grill', name: 'Решётка', price: 300.0, unit: 'шт', imageUrl: ''),
          const PriceItem(sku: 'fitting', name: 'Фитинг', price: 100.0, unit: 'шт', imageUrl: ''),
        ];

        final result = calculator(inputs, priceList);

        expect(result.totalPrice, isNotNull);
        expect(result.totalPrice, greaterThan(0));
      });

      test('returns null price when no prices available', () {
        final inputs = {
          'roomArea': 50.0,
          'ceilingHeight': 2.7,
        };

        final result = calculator(inputs, emptyPriceList);

        expect(result.totalPrice, isNull);
      });
    });

    group('Full scenario tests', () {
      test('typical apartment ventilation', () {
        final inputs = {
          'roomArea': 60.0,
          'ceilingHeight': 2.7,
          'roomsCount': 4.0,
          'ventilationType': 1.0, // supply
          'needRecovery': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Volume = 60 * 2.7 = 162 m³
        expect(result.values['roomVolume'], closeTo(162.0, 0.1));
        // Airflow = 162 * 2.0 = 324 m³/h
        expect(result.values['airflowRequired'], closeTo(324.0, 0.1));
        // Duct = 4 * 3 + (60 * 0.1) * 1.15 = 12 + 6.9 = 18.9 m
        expect(result.values['ductLength'], closeTo(18.9, 0.1));
        // Grills = 4 * 2 = 8
        expect(result.values['grillsCount'], equals(8.0));
        // Fittings = 4 * 3 + 4 = 16
        expect(result.values['fittingsCount'], equals(16.0));
      });

      test('large office with recovery', () {
        final inputs = {
          'roomArea': 200.0,
          'ceilingHeight': 3.0,
          'roomsCount': 10.0,
          'ventilationType': 1.0, // supply
          'needRecovery': 1.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Volume = 200 * 3.0 = 600 m³
        expect(result.values['roomVolume'], closeTo(600.0, 0.1));
        // Airflow = 600 * 2.0 = 1200 m³/h
        expect(result.values['airflowRequired'], closeTo(1200.0, 0.1));
        // Duct = 10 * 3 + (200 * 0.1) * 1.15 = 30 + 23 = 53 m
        expect(result.values['ductLength'], closeTo(53.0, 0.1));
        // Grills = 10 * 2 = 20
        expect(result.values['grillsCount'], equals(20.0));
        // Recuperator = 1
        expect(result.values['recuperatorCount'], equals(1.0));
      });

      test('small bathroom natural ventilation', () {
        final inputs = {
          'roomArea': 15.0,
          'ceilingHeight': 2.5,
          'roomsCount': 1.0,
          'ventilationType': 0.0, // natural
          'needRecovery': 0.0,
        };

        final result = calculator(inputs, emptyPriceList);

        // Volume = 15 * 2.5 = 37.5 m³
        expect(result.values['roomVolume'], closeTo(37.5, 0.1));
        // Airflow = 37.5 * 1.0 = 37.5 m³/h
        expect(result.values['airflowRequired'], closeTo(37.5, 0.1));
        // Minimal fittings
        expect(result.values['fittingsCount'], equals(7.0));
      });
    });
  });
}
