import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_plumbing.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculatePlumbing', () {
    test('calculates points automatically', () {
      final calculator = CalculatePlumbing();
      final inputs = {
        'rooms': 2.0, // 2 санузла
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Точки: 2 * 3 = 6 шт
      expect(result.values['points'], equals(6.0));
      expect(result.values['rooms'], equals(2.0));
    });

    test('calculates pipe length automatically', () {
      final calculator = CalculatePlumbing();
      final inputs = {'rooms': 2.0};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Трубы: 6 точек * 5 = 30 м
      expect(result.values['pipeLength'], closeTo(30.0, 1.5));
    });

    test('uses provided pipe length', () {
      final calculator = CalculatePlumbing();
      final inputs = {'rooms': 2.0, 'pipeLength': 25.0};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['pipeLength'], closeTo(25.0, 1.2));
    });

    test('calculates fittings needed', () {
      final calculator = CalculatePlumbing();
      final inputs = {'rooms': 2.0};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Фитинги: 6 * 3 = 18 шт
      expect(result.values['fittingsNeeded'], closeTo(18.0, 0.9));
    });

    test('calculates taps needed', () {
      final calculator = CalculatePlumbing();
      final inputs = {'rooms': 2.0};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Краны: по количеству точек
      expect(result.values['tapsNeeded'], equals(6.0));
    });

    test('calculates mixers needed', () {
      final calculator = CalculatePlumbing();
      final inputs = {'rooms': 2.0};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Смесители: 6 * 0.7 = 4 шт
      expect(result.values['mixersNeeded'], equals(4.0));
    });

    test('calculates toilets, sinks, showers', () {
      final calculator = CalculatePlumbing();
      final inputs = {'rooms': 2.0};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По 1 на санузел
      expect(result.values['toiletsNeeded'], equals(2.0));
      expect(result.values['sinksNeeded'], equals(2.0));
      expect(result.values['showersNeeded'], equals(2.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculatePlumbing();
      final inputs = <String, double>{};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 1 санузел
      expect(result.values['rooms'], equals(1.0));
      expect(result.values['points'], equals(3.0));
    });

    test('handles zero rooms', () {
      final calculator = CalculatePlumbing();
      final inputs = {'rooms': 0.0};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['rooms'], equals(0.0));
      expect(result.values['points'], equals(0.0));
      expect(result.values['pipeLength'], equals(0.0));
    });

    test('supports screen room counters and hot water toggle', () {
      final calculator = CalculatePlumbing();
      final inputs = {
        'bathroomsCount': 1.0,
        'toiletsCount': 1.0,
        'kitchensCount': 1.0,
        'avgPipeLength': 5.0,
        'needHotWater': 1.0,
      };
      final result = calculator(inputs, <PriceItem>[]);

      expect(result.values['points'], equals(9.0));
      expect(result.values['coldWaterLength'], closeTo(51.75, 0.01));
      expect(result.values['hotWaterLength'], closeTo(41.4, 0.01));
      expect(result.values['sewerLength'], closeTo(34.65, 0.01));
      expect(result.values['fittingsNeeded'], equals(36.0));
      expect(result.values['ballValvesNeeded'], equals(18.0));
    });

    test('disables hot water in screen path', () {
      final calculator = CalculatePlumbing();
      final inputs = {
        'bathroomsCount': 2.0,
        'toiletsCount': 0.0,
        'kitchensCount': 1.0,
        'avgPipeLength': 4.0,
        'needHotWater': 0.0,
      };
      final result = calculator(inputs, <PriceItem>[]);

      expect(result.values['points'], equals(11.0));
      expect(result.values['hotWaterLength'], equals(0.0));
      expect(result.values['ballValvesNeeded'], equals(11.0));
      expect(result.values['fittingsNeeded'], equals(44.0));
    });

    group('validation messages', () {
      test('negative bathrooms count uses shared helper', () {
        final calculator = CalculatePlumbing();

        final error = calculator.validateInputs({'bathroomsCount': -1.0});

        expect(
          error,
          equals('Поле "количество санузлов" не может быть отрицательным'),
        );
      });
    });
  });
}
