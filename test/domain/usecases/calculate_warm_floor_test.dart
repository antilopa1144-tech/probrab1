import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_warm_floor.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateWarmFloor', () {
    test('calculates cable type correctly', () {
      final calculator = CalculateWarmFloor();
      final inputs = {
        'area': 20.0, // 20 м²
        'power': 150.0, // 150 Вт/м²
        'type': 1.0, // кабель
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь: 20 * 0.7 = 14 м²
      expect(result.values['usefulArea'], equals(14.0));
      // Длина кабеля: 14 * 4 = 56 м
      expect(result.values['cableLength'], equals(56.0));
      expect(result.values['matArea'], equals(0.0));
    });

    test('calculates mat type correctly', () {
      final calculator = CalculateWarmFloor();
      final inputs = {
        'area': 20.0,
        'power': 150.0,
        'type': 2.0, // мат
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Полезная площадь: 14 м²
      expect(result.values['usefulArea'], equals(14.0));
      // Площадь мата: 14 м²
      expect(result.values['matArea'], equals(14.0));
      expect(result.values['cableLength'], equals(0.0));
    });

    test('calculates total power', () {
      final calculator = CalculateWarmFloor();
      final inputs = {
        'area': 20.0,
        'power': 150.0,
        'type': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Мощность: 14 * 150 = 2100 Вт
      expect(result.values['totalPower'], equals(2100.0));
    });

    test('calculates thermostats', () {
      final calculator = CalculateWarmFloor();
      final inputs = {
        'area': 20.0,
        'thermostats': 2.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['thermostats'], equals(2.0));
    });

    test('calculates insulation area', () {
      final calculator = CalculateWarmFloor();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Теплоизоляция: равна площади пола
      expect(result.values['insulationArea'], equals(20.0));
    });

    test('uses default values when missing', () {
      final calculator = CalculateWarmFloor();
      final inputs = {
        'area': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: мощность 150 Вт/м², тип 2 (мат), термостат 1
      expect(result.values['power'], equals(150.0));
      expect(result.values['matArea'], greaterThan(0));
      expect(result.values['thermostats'], equals(1.0));
    });

    test('handles zero area', () {
      final calculator = CalculateWarmFloor();
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['usefulArea'], equals(0.0));
      expect(result.values['totalPower'], equals(0.0));
      expect(result.values['matArea'], equals(0.0));
    });
  });
}
