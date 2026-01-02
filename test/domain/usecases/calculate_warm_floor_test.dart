import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_warm_floor.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateWarmFloor', () {
    late CalculateWarmFloor calculator;

    setUp(() {
      calculator = CalculateWarmFloor();
    });

    test('calculates useful area correctly (70% of total)', () {
      final inputs = {
        'area': 20.0, // 20 м²
        'power': 150.0,
        'type': 2.0, // мат
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь = 20 * 0.7 = 14 м²
      expect(result.values['usefulArea'], closeTo(14.0, 0.7));
    });

    test('calculates total power correctly', () {
      final inputs = {
        'area': 20.0,
        'power': 150.0, // Вт/м²
        'type': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Мощность = 14 * 150 = 2100 Вт
      expect(result.values['totalPower'], closeTo(2100.0, 105.0));
    });

    test('calculates cable length for cable type', () {
      final inputs = {
        'area': 20.0,
        'power': 150.0,
        'type': 1.0, // кабель
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Кабель = totalPower / 18 = (14 * 150) / 18 ≈ 116.67 м
      // usefulArea = 20 * 0.7 = 14 м², totalPower = 14 * 150 = 2100 Вт
      expect(result.values['cableLength'], closeTo(116.67, 5.0));
      expect(result.values['matArea'], equals(0.0));
    });

    test('calculates mat area for mat type', () {
      final inputs = {
        'area': 20.0,
        'power': 150.0,
        'type': 2.0, // мат
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Мат = 14 м²
      expect(result.values['matArea'], closeTo(14.0, 0.7));
      expect(result.values['cableLength'], equals(0.0));
    });

    test('handles thermostats correctly', () {
      final inputs = {
        'area': 20.0,
        'power': 150.0,
        'type': 2.0,
        'thermostats': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['thermostats'], equals(2.0));
    });

    test('calculates insulation area equal to total area', () {
      final inputs = {
        'area': 20.0,
        'power': 150.0,
        'type': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Теплоизоляция = вся площадь пола
      expect(result.values['insulationArea'], closeTo(20.0, 1.0));
    });

    test('uses default values when not provided', () {
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: power=150, type=2 (мат), thermostats=1
      // Полезная площадь = 14 м²
      expect(result.values['totalPower'], closeTo(2100.0, 105.0)); // 14 * 150
      expect(result.values['matArea'], closeTo(14.0, 0.7));
      expect(result.values['thermostats'], equals(1.0));
    });

    test('throws exception for zero area', () {
      final inputs = {
        'area': 0.0,
        'power': 150.0,
        'type': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });

    test('handles different power values', () {
      final inputs100 = {
        'inputMode': 1.0, // По площади
        'area': 20.0,
        'roomType': 0.0, // Пользовательская мощность
        'power': 100.0, // низкая мощность
        'type': 2.0,
        'usefulAreaPercent': 70.0, // 70% полезной площади
      };
      final inputs200 = {
        'inputMode': 1.0,
        'area': 20.0,
        'roomType': 0.0,
        'power': 200.0, // высокая мощность
        'type': 2.0,
        'usefulAreaPercent': 70.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result100 = calculator(inputs100, emptyPriceList);
      final result200 = calculator(inputs200, emptyPriceList);

      // 100 Вт/м²: 20 * 0.7 * 100 = 1400 Вт
      expect(result100.values['totalPower'], equals(1400.0));

      // 200 Вт/м²: 20 * 0.7 * 200 = 2800 Вт
      expect(result200.values['totalPower'], equals(2800.0));
    });

    test('preserves area in results', () {
      final inputs = {
        'area': 25.5,
        'power': 150.0,
        'type': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['area'], closeTo(25.5, 1.3));
    });

    test('handles large room', () {
      final inputs = {
        'area': 100.0, // большая комната
        'power': 150.0,
        'type': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь = 70 м²
      // Мощность = 70 * 150 = 10500 Вт
      expect(result.values['usefulArea'], closeTo(70.0, 3.5));
      expect(result.values['totalPower'], closeTo(10500.0, 525.0));
    });
  });
}
