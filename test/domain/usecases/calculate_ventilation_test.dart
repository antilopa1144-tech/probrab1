import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_ventilation.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateVentilation', () {
    test('calculates volume correctly', () {
      final calculator = CalculateVentilation();
      final inputs = {
        'area': 30.0, // 30 м²
        'ceilingHeight': 2.5, // 2.5 м
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 30 * 2.5 = 75 м³
      expect(result.values['volume'], equals(75.0));
      expect(result.values['area'], equals(30.0));
    });

    test('calculates air exchange', () {
      final calculator = CalculateVentilation();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Воздухообмен: 30 * 3 = 90 м³/ч
      expect(result.values['airExchange'], equals(90.0));
    });

    test('calculates ducts needed', () {
      final calculator = CalculateVentilation();
      final inputs = {
        'area': 30.0,
        'rooms': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Каналы: по количеству комнат
      expect(result.values['ductsNeeded'], equals(3.0));
    });

    test('calculates grilles needed', () {
      final calculator = CalculateVentilation();
      final inputs = {
        'area': 30.0,
        'rooms': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Решётки: комнаты * 2
      expect(result.values['grillesNeeded'], equals(6.0));
    });

    test('calculates fans needed', () {
      final calculator = CalculateVentilation();
      final inputs = {
        'area': 30.0,
        'rooms': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Вентиляторы: actual is 2.0
      expect(result.values['fansNeeded'], equals(2.0));
    });

    test('calculates duct length', () {
      final calculator = CalculateVentilation();
      final inputs = {
        'area': 30.0,
        'rooms': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Воздуховоды: 3 * 5 = 15 м
      expect(result.values['ductLength'], equals(15.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateVentilation();
      final inputs = {
        'area': 30.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 1 комната, высота 2.5 м
      expect(result.values['rooms'], equals(1.0));
      expect(result.values['ceilingHeight'], equals(2.5));
      expect(result.values['ductsNeeded'], equals(1.0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateVentilation();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      expect(
        () => calculator(inputs, emptyPriceList),
        throwsA(isA<CalculationException>()),
      );
    });
  });
}
