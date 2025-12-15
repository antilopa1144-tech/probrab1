import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_gasblock_partition.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateGasblockPartition', () {
    test('calculates blocks needed correctly', () {
      final calculator = CalculateGasblockPartition();
      final inputs = {
        'area': 12.0, // 12 м²
        'blockWidth': 20.0, // 20 см
        'blockLength': 60.0, // 60 см
        'blockHeight': 25.0, // 25 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь блока: 0.6 * 0.25 = 0.15 м²
      // Количество: 12 / 0.15 * 1.05 = 84 блока
      expect(result.values['blocksNeeded'], closeTo(84.0, 4.2));
      expect(result.values['area'], closeTo(12.0, 0.6));
    });

    test('calculates glue needed', () {
      final calculator = CalculateGasblockPartition();
      final inputs = {
        'area': 12.0,
        'blockWidth': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Объём: 12 * 0.2 = 2.4 м³
      // Клей: 2.4 * 25 * 1.1 = 66 кг
      expect(result.values['glueNeeded'], closeTo(66.0, 3.3));
    });

    test('calculates reinforcement length', () {
      final calculator = CalculateGasblockPartition();
      final inputs = {
        'area': 12.0,
        'height': 2.5, // высота стены
        'perimeter': 14.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Армирование должно быть рассчитано
      expect(result.values['reinforcementLength'], greaterThan(0));
    });

    test('uses default block dimensions when missing', () {
      final calculator = CalculateGasblockPartition();
      final inputs = {
        'area': 12.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 20x60x25 см
      expect(result.values['blocksNeeded'], greaterThan(0));
    });

    test('estimates perimeter when missing', () {
      final calculator = CalculateGasblockPartition();
      final inputs = {
        'area': 12.0,
        'height': 2.5,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Периметр должен быть рассчитан
      expect(result.values['reinforcementLength'], greaterThan(0));
    });

    test('throws exception for zero area', () {
      final calculator = CalculateGasblockPartition();
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
