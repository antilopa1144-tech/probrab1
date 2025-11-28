import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_siding.dart';
import 'package:probrab_ai/data/models/price_item.dart';

void main() {
  group('CalculateSiding', () {
    late CalculateSiding calculator;

    setUp(() {
      calculator = CalculateSiding();
    });

    test('calculates panels needed correctly with 10% reserve', () {
      final inputs = {
        'area': 100.0, // 100 м²
        'panelWidth': 20.0, // 20 см
        'panelLength': 300.0, // 300 см
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Площадь панели = 0.2 * 3.0 = 0.6 м²
      // Панели = ceil(100 / 0.6 * 1.1) = ceil(183.3) = 184
      expect(result.values['panelsNeeded'], greaterThanOrEqualTo(180));
      expect(result.values['panelsNeeded'], lessThanOrEqualTo(190));
    });

    test('calculates j-profile length from perimeter', () {
      final inputs = {
        'area': 100.0,
        'perimeter': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['jProfileLength'], equals(40.0));
    });

    test('calculates corner length correctly', () {
      final inputs = {
        'area': 100.0,
        'corners': 4.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Углы = 4 * 2.5 = 10 м
      expect(result.values['cornerLength'], equals(10.0));
    });

    test('calculates start and finish strips from perimeter', () {
      final inputs = {
        'area': 100.0,
        'perimeter': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['startStripLength'], equals(40.0));
      expect(result.values['finishStripLength'], equals(40.0));
    });

    test('calculates screws needed (8 per panel)', () {
      final inputs = {
        'area': 60.0, // 60 м²
        'panelWidth': 20.0,
        'panelLength': 300.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Саморезы = panelsNeeded * 8
      final panels = result.values['panelsNeeded']!;
      expect(result.values['screwsNeeded'], equals(panels * 8));
    });

    test('uses provided soffit length', () {
      final inputs = {
        'area': 100.0,
        'soffitLength': 20.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['soffitLength'], equals(20.0));
    });

    test('estimates soffit length when not provided', () {
      final inputs = {
        'area': 100.0,
        'perimeter': 40.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 10% от периметра = 4 м
      expect(result.values['soffitLength'], equals(4.0));
    });

    test('estimates perimeter when not provided', () {
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: 4 * sqrt(100/4) = 4 * 5 = 20 м
      expect(result.values['jProfileLength'], closeTo(20.0, 1.0));
    });

    test('handles different panel sizes', () {
      final inputsSmall = {
        'area': 100.0,
        'panelWidth': 15.0, // узкие панели
        'panelLength': 300.0,
      };
      final inputsWide = {
        'area': 100.0,
        'panelWidth': 30.0, // широкие панели
        'panelLength': 300.0,
      };
      final emptyPriceList = <PriceItem>[];

      final resultSmall = calculator(inputsSmall, emptyPriceList);
      final resultWide = calculator(inputsWide, emptyPriceList);

      // Узкие панели требуют больше штук
      expect(resultSmall.values['panelsNeeded']!, 
             greaterThan(resultWide.values['panelsNeeded']!));
    });

    test('uses default values when not provided', () {
      final inputs = {
        'area': 100.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // По умолчанию: panelWidth=20, panelLength=300, corners=4
      expect(result.values['panelsNeeded'], greaterThan(0));
      expect(result.values['cornerLength'], equals(10.0)); // 4 * 2.5
    });

    test('handles zero area', () {
      final inputs = {
        'area': 0.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['area'], equals(0.0));
      expect(result.values['panelsNeeded'], equals(0.0));
    });

    test('preserves area in results', () {
      final inputs = {
        'area': 150.0,
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      expect(result.values['area'], equals(150.0));
    });

    test('handles multiple corners', () {
      final inputs = {
        'area': 100.0,
        'corners': 8.0, // сложная форма дома
      };
      final emptyPriceList = <PriceItem>[];

      final result = calculator(inputs, emptyPriceList);

      // Углы = 8 * 2.5 = 20 м
      expect(result.values['cornerLength'], equals(20.0));
    });
  });
}
