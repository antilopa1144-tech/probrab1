import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_unified_roofing.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateUnifiedRoofing', () {
    late CalculateUnifiedRoofing calculator;

    setUp(() {
      calculator = CalculateUnifiedRoofing();
    });

    test('calculates basic values correctly', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'roofingType': 0.0, // Металлочерепица
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values, isNotEmpty);
      expect(result.values['area'], equals(100.0));
    });

    test('uses default values when area is provided', () {
      final inputs = {'area': 100.0};
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values, isNotEmpty);
      expect(result.values['area'], equals(100.0));
      // slope is used but not stored in values
      expect(result.values['realArea'], greaterThan(100.0)); // due to slope factor
    });

    test('handles price list correctly', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'roofingType': 0.0,
      };
      final priceList = [
        const PriceItem(
          sku: 'metal-tile-1',
          name: 'Металлочерепица',
          unit: 'м²',
          price: 500.0,
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      expect(result.values, isNotEmpty);
    });
  });

  group('CalculateUnifiedRoofing - Roofing Types', () {
    late CalculateUnifiedRoofing calculator;
    final emptyPriceList = <PriceItem>[];

    setUp(() {
      calculator = CalculateUnifiedRoofing();
    });

    test('calculates metal tile (type 0) correctly', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'roofingType': 0.0,
        'sheetWidth': 1.18,
        'sheetLength': 2.5,
      };

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['sheetsNeeded'], greaterThan(0));
      expect(result.values['waterproofingArea'], greaterThan(0));
      expect(result.values['battensLength'], greaterThan(0));
    });

    test('calculates soft roofing (type 1) correctly', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'roofingType': 1.0,
      };

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['packsNeeded'], greaterThan(0));
      expect(result.values['underlaymentArea'], greaterThan(0));
      expect(result.values['deckingArea'], greaterThan(0));
    });

    test('calculates profiled sheet (type 2) correctly', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'roofingType': 2.0,
        'sheetWidth': 1.15,
        'sheetLength': 3.0,
      };

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['sheetsNeeded'], greaterThan(0));
      expect(result.values['battensLength'], greaterThan(0));
    });

    test('calculates ondulin (type 3) correctly', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'roofingType': 3.0,
      };

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['sheetsNeeded'], greaterThan(0));
      expect(result.values['nailsNeeded'], greaterThan(0));
      expect(result.values['ridgeElements'], greaterThan(0));
    });

    test('calculates slate (type 4) correctly', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'roofingType': 4.0,
      };

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['sheetsNeeded'], greaterThan(0));
      expect(result.values['nailsNeeded'], greaterThan(0));
    });

    test('calculates ceramic tile (type 5) correctly', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'roofingType': 5.0,
      };

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['tilesNeeded'], greaterThan(0));
      expect(result.values['battensLength'], greaterThan(0));
    });
  });

  group('CalculateUnifiedRoofing - Slope calculations', () {
    late CalculateUnifiedRoofing calculator;
    final emptyPriceList = <PriceItem>[];

    setUp(() {
      calculator = CalculateUnifiedRoofing();
    });

    test('slope affects real area calculation', () {
      final inputsFlat = {
        'area': 100.0,
        'slope': 0.0,
        'roofingType': 0.0,
      };

      final inputsSteep = {
        'area': 100.0,
        'slope': 45.0,
        'roofingType': 0.0,
      };

      final resultFlat = calculator(inputsFlat, emptyPriceList);
      final resultSteep = calculator(inputsSteep, emptyPriceList);

      // Крутой уклон = большая реальная площадь
      expect(resultSteep.values['realArea'], greaterThan(resultFlat.values['realArea']!));
    });

    test('validates slope boundaries affect realArea', () {
      final inputsMin = {
        'area': 100.0,
        'slope': 5.0,
        'roofingType': 0.0,
      };

      final inputsMax = {
        'area': 100.0,
        'slope': 60.0,
        'roofingType': 0.0,
      };

      final resultMin = calculator(inputsMin, emptyPriceList);
      final resultMax = calculator(inputsMax, emptyPriceList);

      // Both should calculate, with different realArea values
      expect(resultMin.values['realArea'], greaterThan(100.0));
      expect(resultMax.values['realArea'], greaterThan(resultMin.values['realArea']!));
    });
  });

  group('CalculateUnifiedRoofing - Additional elements', () {
    late CalculateUnifiedRoofing calculator;
    final emptyPriceList = <PriceItem>[];

    setUp(() {
      calculator = CalculateUnifiedRoofing();
    });

    test('calculates ridge length correctly', () {
      final inputsWithRidge = {
        'area': 100.0,
        'slope': 30.0,
        'roofingType': 0.0,
        'ridgeLength': 15.0,
      };

      final result = calculator(inputsWithRidge, emptyPriceList);

      expect(result.values['ridgeLength'], equals(15.0));
    });

    test('calculates valley length correctly', () {
      final inputsWithValley = {
        'area': 100.0,
        'slope': 30.0,
        'roofingType': 0.0,
        'valleyLength': 8.0,
      };

      final result = calculator(inputsWithValley, emptyPriceList);

      expect(result.values['valleyLength'], equals(8.0));
    });

    test('waterproofing includes 10% margin', () {
      final inputs = {
        'area': 100.0,
        'slope': 0.0, // Flat for easy calculation
        'roofingType': 0.0,
      };

      final result = calculator(inputs, emptyPriceList);

      // При 0 уклоне realArea = area, waterproofing = realArea * 1.1
      expect(result.values['waterproofingArea'], closeTo(110.0, 1.0));
    });
  });

  group('CalculateUnifiedRoofing - Price calculations', () {
    late CalculateUnifiedRoofing calculator;

    setUp(() {
      calculator = CalculateUnifiedRoofing();
    });

    test('calculates total price for metal tile', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'roofingType': 0.0,
      };
      final priceList = [
        const PriceItem(
          sku: 'metal_tile',
          name: 'Металлочерепица',
          unit: 'лист',
          price: 500.0,
          imageUrl: '',
        ),
        const PriceItem(
          sku: 'waterproofing',
          name: 'Гидроизоляция',
          unit: 'м²',
          price: 50.0,
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      expect(result.totalPrice, greaterThan(0));
    });

    test('calculates total price for soft roofing', () {
      final inputs = {
        'area': 100.0,
        'slope': 30.0,
        'roofingType': 1.0,
      };
      final priceList = [
        const PriceItem(
          sku: 'soft_roofing',
          name: 'Мягкая кровля',
          unit: 'упак',
          price: 1200.0,
          imageUrl: '',
        ),
      ];

      final result = calculator(inputs, priceList);

      // Price should be calculated when material matches
      expect(result.values['packsNeeded'], greaterThan(0));
    });
  });
}
