import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_electrics.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateElectrics', () {
    test('calculates sockets automatically', () {
      final calculator = CalculateElectrics();
      final inputs = {
        'area': 40.0, // 40 м²
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Розетки: 40 / 4 = 10 шт
      expect(result.values['sockets'], equals(10.0));
      expect(result.values['area'], closeTo(40.0, 2.0));
    });

    test('calculates switches automatically', () {
      final calculator = CalculateElectrics();
      final inputs = {
        'area': 40.0,
        'rooms': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Выключатели: 3 * 1.5 = 5 шт
      expect(result.values['switches'], equals(5.0));
    });

    test('uses provided sockets and switches', () {
      final calculator = CalculateElectrics();
      final inputs = {
        'area': 40.0,
        'sockets': 15.0,
        'switches': 8.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['sockets'], closeTo(15.0, 0.8));
      expect(result.values['switches'], equals(8.0));
    });

    test('calculates wire length', () {
      final calculator = CalculateElectrics();
      final inputs = {
        'area': 40.0,
        'sockets': 10.0,
        'switches': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Провод: (10 * 3 + 5 * 2) * 1.2 = 48 м
      expect(result.values['wireLength'], closeTo(48.0, 2.4));
    });

    test('calculates cable channel length', () {
      final calculator = CalculateElectrics();
      final inputs = {
        'area': 40.0,
        'sockets': 10.0,
        'switches': 5.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Кабель-каналы: 48 * 0.5 = 24 м
      expect(result.values['cableChannelLength'], closeTo(24.0, 1.2));
    });

    test('calculates circuit breakers', () {
      final calculator = CalculateElectrics();
      final inputs = {
        'area': 40.0,
        'rooms': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Автоматы: 3 + 1 = 4 шт
      expect(result.values['circuitBreakers'], equals(4.0));
    });

    test('calculates junction boxes', () {
      final calculator = CalculateElectrics();
      final inputs = {
        'area': 40.0,
        'rooms': 3.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Коробки: по количеству комнат
      expect(result.values['junctionBoxes'], equals(3.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateElectrics();
      final inputs = {
        'area': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 1 комната
      expect(result.values['rooms'], equals(1.0));
      expect(result.values['sockets'], greaterThan(0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateElectrics();
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
