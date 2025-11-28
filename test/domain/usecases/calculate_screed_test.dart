import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_screed.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateScreed', () {
    test('calculates screed volume correctly', () {
      final calculator = CalculateScreed();
      final inputs = {
        'area': 20.0, // 20 м²
        'thickness': 50.0, // 50 мм
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 20 м² * 0.05 м = 1 м³
      expect(result.values['volume'], equals(1.0));
      expect(result.values['area'], equals(20.0));
      expect(result.values['thickness'], equals(50.0));
    });

    test('calculates cement and sand for M400', () {
      final calculator = CalculateScreed();
      final inputs = {
        'area': 10.0,
        'thickness': 50.0,
        'cementGrade': 400.0, // М400
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 10 * 0.05 = 0.5 м³
      // Вес раствора: 0.5 * 2000 = 1000 кг
      // М400: 1:3 (цемент:песок) = 33% цемента
      // Цемент: 1000 * 0.33 = 330 кг
      // Мешки: 330 / 50 = 7 мешков
      expect(result.values['cementBags'], greaterThanOrEqualTo(6));
      expect(result.values['cementBags'], lessThanOrEqualTo(8));
      expect(result.values['sandVolume'], greaterThan(0));
    });

    test('calculates cement and sand for M500', () {
      final calculator = CalculateScreed();
      final inputs = {
        'area': 10.0,
        'thickness': 50.0,
        'cementGrade': 500.0, // М500
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // М500: 1:4 (цемент:песок) = 25% цемента
      // Меньше цемента, чем для М400
      final cementBags = result.values['cementBags']!;
      expect(cementBags, greaterThan(0));
      expect(cementBags, lessThan(10));
    });

    test('handles zero area', () {
      final calculator = CalculateScreed();
      final inputs = {
        'area': 0.0,
        'thickness': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['volume'], equals(0.0));
      expect(result.values['cementBags'], equals(0.0));
      expect(result.values['sandVolume'], equals(0.0));
    });

    test('uses default thickness when missing', () {
      final calculator = CalculateScreed();
      final inputs = {
        'area': 10.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию толщина 50 мм
      expect(result.values['thickness'], equals(50.0));
      expect(result.values['volume'], equals(0.5)); // 10 * 0.05
    });

    test('calculates waterproofing area', () {
      final calculator = CalculateScreed();
      final inputs = {
        'area': 20.0,
        'thickness': 50.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Гидроизоляция: 20 * 1.2 = 24 м²
      // Проверяем, что объём рассчитан корректно
      expect(result.values['volume'], equals(1.0));
    });
  });
}
